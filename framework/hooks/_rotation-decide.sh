#!/usr/bin/env bash
# Hook type: library (not auto-wired; sourced by /apex:next Step F)
#
# R13-005 (F-305): Rotation decision library. Replaces the task-count
# proxy (`tasks_since_last_rotation >= 4`) in `/apex:next` Step F with a
# real consumer of `CONTEXT_BUDGET.rotation_triggers[]` driven by
# `STATE.context.estimated_context_usage_pct` (populated post-R12-001 by
# `_tokens-update.sh` on every SubagentStop) and supporting structured
# triggers per R2-C091.
#
# Spec anchors:
#   - "Configuration declarative = theatre until code consumes it."
#   - R2-C037 (HIGH): "Compact at 50-60% capacity, NOT 80-95%"
#   - R2-C188 (HIGH): "Hard budget: 50-60% of effective capacity per task phase"
#   - R2-C091 (HIGH): the 7 trigger types
#     (utilization%, phase_boundary, task_batch, time, quality_signal,
#      repeated_errors, recovery_density).
#
# Contract: `apex_rotation_decide <state_file> <budget_file>`
#   - Returns (via stdout) exactly one of: `proactive_compact`,
#     `warn_and_compact`, `hard_rotate`, `noop`.
#   - Iterates `rotation_triggers[]` in array order. **Priority = array
#     index; first match wins.** This is load-bearing — config authors
#     place high-severity triggers (utilization 70 hard_rotate) ahead of
#     lower-severity ones (task_batch warn_and_compact).
#   - **HALT-priority guard.** Before iterating, checks
#     `STATE.session.drift_indicators.circuit_breaker_triggers`. If
#     non-zero, returns `noop` regardless of pressure. The
#     circuit-breaker outranks rotation per R2 safety contract.
#   - Unknown trigger type: skip; log event `rotation.trigger.unknown`
#     to `.apex/event-log.jsonl`. No crash (backwards-compat).
#
# Per-trigger semantics:
#   - utilization_pct: fires when `estimated_context_usage_pct >= value`.
#   - phase_boundary:  fires when `STATE.session.phase_boundary_crossed == true`.
#   - task_batch:      fires when `STATE.session.tasks_since_last_rotation >= value`.
#   - time_minutes:    fires when minutes elapsed since session start
#                      `>= value` AND the caller is at a task boundary
#                      (gating happens at the caller — `/apex:next` Step F
#                      only sources this library at task-boundary moments).
#   - recovery_density: fires when
#                       `STATE.session.drift_indicators.recovery_density >= value`
#                       (R2-C091: "same test 3+ times" TDAD signal).
#   - pattern:         legacy; not consumed here (kept for back-compat,
#                      iterated as unknown-skip).
#
# Side effects: emits `rotation.decide.evaluated` / `rotation.trigger.unknown`
# events to `.apex/event-log.jsonl` (best-effort).
#
# Fail-safe: any jq/IO error returns `noop` (never blocks the pipeline).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
[ -f "$SCRIPT_DIR/_require-jq.sh" ] && source "$SCRIPT_DIR/_require-jq.sh"

apex_rotation_decide() {
  local state_file="${1:-.apex/STATE.json}"
  local budget_file="${2:-framework/CONTEXT_BUDGET.default.json}"
  local event_log=".apex/event-log.jsonl"

  # Fall back to delivered budget under ~/.claude when running outside
  # the repo (sync layout).
  if [ ! -f "$budget_file" ]; then
    if [ -f "$HOME/.claude/CONTEXT_BUDGET.default.json" ]; then
      budget_file="$HOME/.claude/CONTEXT_BUDGET.default.json"
    fi
  fi

  if [ ! -f "$state_file" ] || [ ! -f "$budget_file" ]; then
    # Fail-safe: missing inputs → noop.
    printf 'noop\n'
    return 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    printf 'noop\n'
    return 0
  fi

  # HALT-priority guard. Circuit-breaker outranks rotation.
  local cb_triggers
  cb_triggers=$(jq -r '
    (.session.drift_indicators.circuit_breaker_triggers // 0)
  ' "$state_file" 2>/dev/null | tr -d '\r')
  if [ -n "${cb_triggers:-}" ] && [ "${cb_triggers}" -gt 0 ] 2>/dev/null; then
    printf 'noop\n'
    return 0
  fi

  # Also honor the boolean `circuit_breaker.triggered` flag (live HALT).
  local cb_live
  cb_live=$(jq -r '(.circuit_breaker.triggered // false)' "$state_file" 2>/dev/null | tr -d '\r')
  if [ "${cb_live:-false}" = "true" ]; then
    printf 'noop\n'
    return 0
  fi

  # Extract state values once.
  local pct tasks_since phase_boundary recovery_density session_started
  pct=$(jq -r '(.context.estimated_context_usage_pct // 0)' "$state_file" 2>/dev/null | tr -d '\r')
  tasks_since=$(jq -r '(.session.tasks_since_last_rotation // 0)' "$state_file" 2>/dev/null | tr -d '\r')
  phase_boundary=$(jq -r '(.session.phase_boundary_crossed // false)' "$state_file" 2>/dev/null | tr -d '\r')
  recovery_density=$(jq -r '(.session.drift_indicators.recovery_density // 0)' "$state_file" 2>/dev/null | tr -d '\r')
  session_started=$(jq -r '(.session.started_at // "")' "$state_file" 2>/dev/null | tr -d '\r')

  # Sanitize numeric reads (jq may return floats; integer-truncate for `-ge`).
  pct=${pct%.*}
  [ -z "$pct" ] && pct=0
  tasks_since=${tasks_since%.*}
  [ -z "$tasks_since" ] && tasks_since=0
  recovery_density=${recovery_density%.*}
  [ -z "$recovery_density" ] && recovery_density=0

  # Compute minutes-since-session-start (used by time_minutes triggers).
  local mins_elapsed=0
  if [ -n "$session_started" ] && [ "$session_started" != "null" ]; then
    local now_epoch start_epoch
    now_epoch=$(date -u +%s 2>/dev/null || echo 0)
    # Try GNU date first; fall back to BSD/Python; final fallback = 0.
    start_epoch=$(date -u -d "$session_started" +%s 2>/dev/null \
      || date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$session_started" +%s 2>/dev/null \
      || python3 -c "import sys,datetime; print(int(datetime.datetime.strptime(sys.argv[1].replace('Z','+0000'),'%Y-%m-%dT%H:%M:%S%z').timestamp()))" "$session_started" 2>/dev/null \
      || echo 0)
    if [ "${now_epoch:-0}" -gt 0 ] && [ "${start_epoch:-0}" -gt 0 ]; then
      mins_elapsed=$(( (now_epoch - start_epoch) / 60 ))
      [ "$mins_elapsed" -lt 0 ] && mins_elapsed=0
    fi
  fi

  # Read trigger array entries as compact JSON; jq's @json output is
  # newline-safe and shell-quoting-safe.
  local triggers_json
  triggers_json=$(jq -c '(.rotation_triggers // [])[]' "$budget_file" 2>/dev/null)
  if [ -z "$triggers_json" ]; then
    printf 'noop\n'
    return 0
  fi

  local decision="noop"
  local matched=0

  # Iterate priority order (array index = priority; first match wins).
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    local t_type t_value t_action
    t_type=$(printf '%s' "$entry" | jq -r '(.type // "")' 2>/dev/null | tr -d '\r')
    t_value=$(printf '%s' "$entry" | jq -r '(.value // empty)' 2>/dev/null | tr -d '\r')
    t_action=$(printf '%s' "$entry" | jq -r '(.action // "noop")' 2>/dev/null | tr -d '\r')

    case "$t_type" in
      utilization_pct)
        # Numeric compare; integer-truncate value.
        local v=${t_value%.*}
        [ -z "$v" ] && v=0
        if [ "${pct:-0}" -ge "$v" ] 2>/dev/null; then
          decision="$t_action"
          matched=1
        fi
        ;;
      phase_boundary)
        if [ "$phase_boundary" = "true" ]; then
          decision="$t_action"
          matched=1
        fi
        ;;
      task_batch)
        local v=${t_value%.*}
        [ -z "$v" ] && v=0
        if [ "${tasks_since:-0}" -ge "$v" ] 2>/dev/null; then
          decision="$t_action"
          matched=1
        fi
        ;;
      time_minutes)
        local v=${t_value%.*}
        [ -z "$v" ] && v=0
        if [ "${mins_elapsed:-0}" -ge "$v" ] 2>/dev/null; then
          decision="$t_action"
          matched=1
        fi
        ;;
      recovery_density)
        local v=${t_value%.*}
        [ -z "$v" ] && v=0
        if [ "${recovery_density:-0}" -ge "$v" ] 2>/dev/null; then
          decision="$t_action"
          matched=1
        fi
        ;;
      pattern)
        # Legacy entry — `repeated_tool_errors` was a v6/v7 placeholder
        # without a structured consumer here. Skip silently (do NOT
        # emit unknown; this is an expected legacy entry).
        :
        ;;
      "")
        :
        ;;
      *)
        # Unknown trigger type: log + skip. Backwards-compat (R13-005
        # Q10 non-obvious insight).
        local ts_now
        ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
        printf '{"ts":"%s","type":"rotation.trigger.unknown","source":"_rotation-decide","trigger_type":"%s"}\n' \
          "$ts_now" "$t_type" >> "$event_log" 2>/dev/null || true
        ;;
    esac

    if [ "$matched" -eq 1 ]; then
      break
    fi
  done <<<"$triggers_json"

  # Best-effort evaluation event for tracing.
  local ts_now
  ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
  printf '{"ts":"%s","type":"rotation.decide.evaluated","source":"_rotation-decide","decision":"%s","pct":%s,"tasks_since":%s,"mins_elapsed":%s}\n' \
    "$ts_now" "$decision" "${pct:-0}" "${tasks_since:-0}" "${mins_elapsed:-0}" \
    >> "$event_log" 2>/dev/null || true

  printf '%s\n' "$decision"
  return 0
}

# Allow invocation as `bash _rotation-decide.sh <state> <budget>` for
# tests; when sourced (no $1), do nothing (library mode).
if [ "${BASH_SOURCE[0]:-}" = "${0:-}" ]; then
  apex_rotation_decide "${1:-.apex/STATE.json}" "${2:-framework/CONTEXT_BUDGET.default.json}"
fi
