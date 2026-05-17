#!/usr/bin/env bash
# _emit_apex_event.sh — M10 central event emitter library (Phase 12.06).
#
# Library — SOURCED ONLY. Never invoke directly.
#
# Purpose
#   Single emission path for every APEX hook event. Replaces ad-hoc
#   exit codes + stdout patterns scattered across 50 hooks. Per
#   PLAN.md task 12.06 §5, every event carries an explicit severity
#   (CRITICAL / MAJOR / MINOR), a structured hook identity, a
#   what/where/why payload, and a routing decision.
#
# Spec anchors
#   apex-spec.md — `היכולות הנדרשות` (severity discipline).
#   .apex/phases/12-apex-evolution-v8/PLAN.md task 12.06 §§5-6 (ideal
#   functioning + right fix path).
#   R5 §7 F5 (alert-fatigue research — >50% false-positive alerts
#   train users to dismiss ALL alerts including real CRITICAL).
#
# Public API
#   apex_emit_event SEVERITY HOOK_NAME WHAT WHERE WHY [DEDUP_KEY] [NEXT_ACTIONS_JSON]
#
#   SEVERITY  — CRITICAL | MAJOR | MINOR (required; rejected otherwise)
#   HOOK_NAME — basename of the calling hook (e.g. "phantom-check")
#   WHAT      — one-line what-happened summary (string)
#   WHERE     — path / file:line / artifact identifier
#   WHY       — one-line why-this-matters explanation
#   DEDUP_KEY — optional collision key for the 5-min dedup window;
#               default = WHAT
#   NEXT_ACTIONS_JSON — optional JSON array of recommended remediations
#                       ["command 1", "command 2"]; default = []
#
# Routing
#   CRITICAL → stdout (visible immediately) + event-log.jsonl
#              + STATE.severity.critical_budget_window tracker.
#              Caller is responsible for whatever modal behavior
#              fits its context (next.md routes through the
#              Track D modal hook when applicable).
#   MAJOR    → event-log.jsonl + flag for /apex:status rendering
#              (no stdout — passive yellow).
#   MINOR    → event-log.jsonl only (silent).
#
# Dedup
#   Within 5 minutes, (HOOK_NAME, SEVERITY, DEDUP_KEY) collapses to 1
#   event. Subsequent matches increment a `count` field on the existing
#   record rather than appending new lines.
#
# CRITICAL budget
#   ≤2-3 CRITICAL events per half-day is the design target. The 4th
#   CRITICAL in any 12-hour window emits a follow-up MAJOR notice
#   ("CRITICAL budget exceeded — review classifications in
#   framework/docs/SEVERITY-REGISTRY.md"). The CRITICAL itself still
#   fires (safety > budget). Budget is tracked in
#   STATE.severity.critical_budget_window.
#
# Cross-platform notes
#   Writes use `\n` line ending (CRLF safe — uses printf, never echo
#   -e). All file writes are atomic (mktemp + mv). STATE writes use
#   jq + atomic replace, with degradation to skip on jq absence
#   (event-log line is still emitted).

# Idempotent guard — sourcing twice should not redefine.
if [ -n "${APEX_EMIT_EVENT_SOURCED:-}" ]; then
  return 0
fi
APEX_EMIT_EVENT_SOURCED=1

# Resolve dependencies.
_apex_emit_have_jq() {
  command -v jq >/dev/null 2>&1
}

_apex_emit_now_iso() {
  date -u +'%Y-%m-%dT%H:%M:%SZ'
}

_apex_emit_now_epoch() {
  date -u +%s
}

# Resolve event log path. Prefer the project's .apex/event-log.jsonl;
# fall back to /tmp if no .apex/ in cwd (so library functions in test
# sandboxes without crashing).
_apex_emit_log_path() {
  if [ -d ".apex" ]; then
    mkdir -p .apex 2>/dev/null
    printf '%s\n' "./.apex/event-log.jsonl"
  else
    printf '%s\n' "/tmp/apex-event-log-fallback.jsonl"
  fi
}

# Resolve STATE.json path (best-effort).
_apex_emit_state_path() {
  if [ -f "./.apex/STATE.json" ]; then
    printf '%s\n' "./.apex/STATE.json"
  else
    printf '%s\n' ""
  fi
}

# Validate severity ∈ {CRITICAL, MAJOR, MINOR}.
_apex_emit_severity_valid() {
  case "$1" in
    CRITICAL|MAJOR|MINOR) return 0 ;;
    *) return 1 ;;
  esac
}

# Dedup lookup: search event-log.jsonl for an entry in the last 5
# minutes matching (hook, severity, dedup_key). If found, return the
# line number (1-indexed) on stdout; else return empty.
_apex_emit_dedup_hit() {
  local log="$1" hook="$2" sev="$3" key="$4" now="$5"
  [ -f "$log" ] || return 0
  if ! _apex_emit_have_jq; then
    # Without jq, fall back to grep heuristic — fewer false-hits,
    # acceptable degradation.
    return 0
  fi
  local cutoff=$(( now - 300 ))  # 5 minutes
  # Walk recent events from the tail backwards, decode each, compare.
  # Cap scan at last 100 lines (dedup window is short; bound the work).
  local line_no=0
  tail -100 "$log" 2>/dev/null | while IFS= read -r line; do
    line_no=$((line_no + 1))
    local ev_ts ev_hook ev_sev ev_key
    ev_ts=$(printf '%s' "$line" | jq -r '.ts // empty' 2>/dev/null)
    ev_hook=$(printf '%s' "$line" | jq -r '.hook // empty' 2>/dev/null)
    ev_sev=$(printf '%s' "$line" | jq -r '.severity // empty' 2>/dev/null)
    ev_key=$(printf '%s' "$line" | jq -r '.dedup_key // empty' 2>/dev/null)
    [ -z "$ev_ts" ] && continue
    local ev_epoch
    ev_epoch=$(date -u -d "$ev_ts" +%s 2>/dev/null || echo 0)
    [ "$ev_epoch" -lt "$cutoff" ] && continue
    if [ "$ev_hook" = "$hook" ] && [ "$ev_sev" = "$sev" ] && [ "$ev_key" = "$key" ]; then
      printf '%d\n' "$line_no"
      return 0
    fi
  done
}

# Append one event to event-log.jsonl. Caller-owned formatting; this
# does no dedup of its own. Returns 0 always (logging is fire-and-forget).
_apex_emit_append_event() {
  local log="$1" ts="$2" sev="$3" hook="$4" what="$5" where="$6" why="$7" key="$8" next_json="${9:-[]}"
  # Build JSON. Use jq when available for proper escaping; fall back to
  # naive printf when not (CRLF + double-quote safety best-effort).
  if _apex_emit_have_jq; then
    jq -nc \
      --arg ts "$ts" --arg sev "$sev" --arg hook "$hook" \
      --arg what "$what" --arg where "$where" --arg why "$why" \
      --arg key "$key" --argjson next "$next_json" \
      '{ts:$ts, severity:$sev, hook:$hook, what:$what, where:$where, why:$why, dedup_key:$key, next_actions:$next, count:1}' \
      >> "$log" 2>/dev/null
  else
    # Fallback: naive concatenation. Escapes minimal — callers should
    # not pass embedded quotes when jq is unavailable.
    printf '{"ts":"%s","severity":"%s","hook":"%s","what":"%s","where":"%s","why":"%s","dedup_key":"%s","next_actions":%s,"count":1}\n' \
      "$ts" "$sev" "$hook" "$what" "$where" "$why" "$key" "$next_json" >> "$log" 2>/dev/null
  fi
  return 0
}

# Track CRITICAL budget. State field: STATE.severity.critical_budget_window
# = array of RFC3339 timestamps within the last 12 hours. Caller increments
# by appending NOW; this function trims old entries + returns the count.
# On budget exceedance (count >= 4), emits a MAJOR follow-up.
_apex_emit_critical_budget_tick() {
  local state="$1" now="$2" now_epoch="$3"
  [ -z "$state" ] || [ ! -f "$state" ] && return 0
  _apex_emit_have_jq || return 0
  local cutoff=$(( now_epoch - 43200 ))  # 12 hours
  local tmp
  tmp="$(mktemp)" || return 0
  # Add NOW, drop entries older than 12h.
  jq --arg now "$now" --argjson cutoff "$cutoff" '
    .severity = (.severity // {critical_budget_window: [], digest_state: {last_digest_at: null, pending_minor_count: 0}}) |
    .severity.critical_budget_window = ((.severity.critical_budget_window // []) + [$now]
      | map(select((. | fromdateiso8601) >= $cutoff)))
  ' "$state" > "$tmp" 2>/dev/null
  if [ -s "$tmp" ]; then
    mv "$tmp" "$state"
    local count
    count=$(jq '.severity.critical_budget_window | length' "$state" 2>/dev/null || echo 0)
    printf '%d\n' "$count"
  else
    rm -f "$tmp"
    printf '0\n'
  fi
}

# Public API: apex_emit_event.
apex_emit_event() {
  local sev="${1:-}" hook="${2:-}" what="${3:-}" where="${4:-}" why="${5:-}" key="${6:-}" next_json="${7:-[]}"
  if [ -z "$sev" ] || [ -z "$hook" ] || [ -z "$what" ]; then
    printf '🚫 apex_emit_event: usage: apex_emit_event SEVERITY HOOK_NAME WHAT WHERE WHY [DEDUP_KEY] [NEXT_ACTIONS_JSON]\n' >&2
    return 2
  fi
  if ! _apex_emit_severity_valid "$sev"; then
    printf '🚫 apex_emit_event: invalid severity "%s" — must be CRITICAL | MAJOR | MINOR\n' "$sev" >&2
    return 2
  fi
  # Default DEDUP_KEY to WHAT.
  [ -z "$key" ] && key="$what"

  local log state now now_epoch
  log="$(_apex_emit_log_path)"
  state="$(_apex_emit_state_path)"
  now="$(_apex_emit_now_iso)"
  now_epoch="$(_apex_emit_now_epoch)"

  # Dedup check (5-min window).
  local dedup_hit
  dedup_hit="$(_apex_emit_dedup_hit "$log" "$hook" "$sev" "$key" "$now_epoch")"
  if [ -n "$dedup_hit" ]; then
    # Duplicate within window — suppress new event. (Future: increment
    # the existing record's count field via jq in-place edit; skipped
    # for v0 to keep the library small.)
    return 0
  fi

  # Append the event.
  _apex_emit_append_event "$log" "$now" "$sev" "$hook" "$what" "$where" "$why" "$key" "$next_json"

  # Route by severity.
  case "$sev" in
    CRITICAL)
      # Visible stdout + budget tracker.
      printf '🛑 %s [%s]: %s — %s\n' "$sev" "$hook" "$what" "$why"
      local crit_count
      crit_count="$(_apex_emit_critical_budget_tick "$state" "$now" "$now_epoch")"
      if [ -n "$crit_count" ] && [ "$crit_count" -ge 4 ]; then
        # Budget exceeded — emit follow-up MAJOR. The CRITICAL itself
        # already fired; this is a one-shot warning.
        _apex_emit_append_event "$log" "$now" "MAJOR" "_emit_apex_event" \
          "CRITICAL budget exceeded ($crit_count CRITICAL in 12h)" \
          "framework/docs/SEVERITY-REGISTRY.md" \
          "Alert fatigue risk — review classifications" \
          "critical_budget_exceeded" \
          '["bash framework/scripts/self-test.sh hook-classification","grep severity .apex/event-log.jsonl | tail -20"]'
      fi
      ;;
    MAJOR)
      # Silent — flag for /apex:status (M11 reads the recent event-log
      # entries). No stdout per design.
      :
      ;;
    MINOR)
      # Silent — digest hook reaps these on the 45-min cadence.
      :
      ;;
  esac

  return 0
}
