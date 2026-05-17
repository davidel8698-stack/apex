#!/usr/bin/env bash
# Atomic STATE.json update with error handling.
# Source this from any hook that updates .apex/STATE.json.
#
# Usage:
#   _state_update '.field = "value"'                          # simple expression
#   _state_update '.field = "value"' path/to/STATE.json       # custom file
#   _state_update --arg k v --argjson n 5 '.f[$k] = $n'      # with jq args
#   _state_update --arg k v '.f[$k] = $n' path/to/STATE.json # args + custom file

_state_update() {
  local jq_args=()
  local expr=""
  local state_file=".apex/STATE.json"

  # Parse arguments: collect --arg/--argjson pairs, then expr, then optional file
  while [ $# -gt 0 ]; do
    case "$1" in
      --arg|--argjson)
        jq_args+=("$1" "$2" "$3")
        shift 3
        ;;
      *)
        if [ -z "$expr" ]; then
          expr="$1"
        else
          state_file="$1"
        fi
        shift
        ;;
    esac
  done

  if [ -z "$expr" ]; then
    echo "⚠️ _state_update: no jq expression provided" >&2
    return 1
  fi

  local tmp="/tmp/_apex_state_$(date +%s%N).json"
  local err="/tmp/_apex_state_err_$$.txt"
  if jq "${jq_args[@]}" "$expr" "$state_file" > "$tmp" 2>"$err"; then
    mv "$tmp" "$state_file"
    rm -f "$err"
    # Append structured event to event-log.jsonl (fire-and-forget)
    local state_dir
    state_dir=$(dirname "$state_file")
    local safe_expr
    safe_expr=$(printf '%s' "$expr" | tr '"' "'" | tr '\n' ' ')
    local _ts_now
    _ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
    printf '{"ts":"%s","type":"state_mutation","source":"%s","expr":"%s"}\n' \
      "$_ts_now" \
      "${APEX_HOOK_SOURCE:-unknown}" \
      "$safe_expr" >> "${state_dir}/event-log.jsonl" 2>/dev/null || true
    # R6-004: Dual-emit semantic events for canonical-field mutations.
    # Detect the conservative pattern `.<field> = <value>` (with optional
    # whitespace around `=`) and append a matching semantic event so that
    # state-rebuild.sh can reconstruct the canonical fields from the event
    # log without parsing jq expression strings. Pipe-operator updates and
    # conditional jq forms are intentionally not matched (false-positive
    # avoidance per R6-004 risk assessment).
    case "$expr" in
      *.current_phase[\ ]*=*|*.current_phase=*)
        local _phase_val
        _phase_val=$(printf '%s' "$expr" | sed -nE 's/.*\.current_phase[[:space:]]*=[[:space:]]*"([^"]*)".*/\1/p')
        if [ -n "$_phase_val" ]; then
          printf '{"ts":"%s","type":"phase_set","source":"%s","current_phase":"%s"}\n' \
            "$_ts_now" "${APEX_HOOK_SOURCE:-unknown}" "$_phase_val" \
            >> "${state_dir}/event-log.jsonl" 2>/dev/null || true
        fi
        ;;
    esac
    case "$expr" in
      *.decision_mode[\ ]*=*|*.decision_mode=*)
        local _mode_val
        _mode_val=$(printf '%s' "$expr" | sed -nE 's/.*\.decision_mode[[:space:]]*=[[:space:]]*"([^"]*)".*/\1/p')
        if [ -n "$_mode_val" ]; then
          printf '{"ts":"%s","type":"decision_mode_set","source":"%s","decision_mode":"%s"}\n' \
            "$_ts_now" "${APEX_HOOK_SOURCE:-unknown}" "$_mode_val" \
            >> "${state_dir}/event-log.jsonl" 2>/dev/null || true
        fi
        ;;
    esac
    case "$expr" in
      *.complexity_level[\ ]*=*|*.complexity_level=*)
        local _cl_val
        _cl_val=$(printf '%s' "$expr" | sed -nE 's/.*\.complexity_level[[:space:]]*=[[:space:]]*([0-9]+).*/\1/p')
        if [ -n "$_cl_val" ]; then
          printf '{"ts":"%s","type":"complexity_set","source":"%s","complexity_level":%s}\n' \
            "$_ts_now" "${APEX_HOOK_SOURCE:-unknown}" "$_cl_val" \
            >> "${state_dir}/event-log.jsonl" 2>/dev/null || true
        fi
        ;;
    esac
    # R5-002: opt-in SQLite mirror. Fires only when APEX_SQLITE_MIRROR=1.
    # Never blocks the canonical write; fail-loud-and-skip on missing CLI.
    if [ "${APEX_SQLITE_MIRROR:-}" = "1" ]; then
      local _apex_sqlite_hook
      _apex_sqlite_hook="$(dirname "${BASH_SOURCE[0]}")/_state-sqlite.sh"
      if [ -f "$_apex_sqlite_hook" ]; then
        # shellcheck disable=SC1090
        source "$_apex_sqlite_hook"
        _state_sqlite_mirror "$state_file" "${state_dir}/event-log.jsonl" || true
      fi
    fi
  else
    rm -f "$tmp"
    local jq_msg
    jq_msg=$(cat "$err" 2>/dev/null)
    rm -f "$err"
    echo "⚠️ STATE update failed: $expr${jq_msg:+ — $jq_msg}" >&2
    return 1
  fi
}

# v7.1 Auto-Continuity Layer — emit a semantic event to .apex/event-log.jsonl
# with arbitrary flat string key/value fields. Used by new hooks (memory-watchdog,
# turn-checkpoint, session-auto-resume) for event types that don't fit the
# canonical .field = "value" dual-emit pattern. Fire-and-forget, never blocks.
#
# Known event types (v7.1):
#   memory_sample              — periodic Bun memory telemetry
#   auto_pause_requested       — memory-watchdog requested a pause
#   external_shutdown_requested — apex-watchdog.ps1 requested a shutdown
#   turn_checkpoint_set        — turn-checkpoint.sh wrote TURN_CHECKPOINT.json
#   session_auto_resumed       — session-auto-resume.sh detected auto-paused boot
#
# Usage:
#   _emit_apex_event <event_type> [<state_dir>] [<key1> <val1> [<key2> <val2> ...]]
#   state_dir defaults to .apex; pass "" to use the default while supplying key/values.
#
# Example:
#   _emit_apex_event memory_sample .apex rss_mb 412 commit_mb 1834
# R16-616 (F-616, IMP-016): _record_denied_error pushes a denied-class
# PostToolUse error event into STATE.recent_denied_error_window (FIFO, max 5).
# Pairs with sequence-guard.sh which reads the window in PreToolUse and tightens
# the deny pattern set for the next 5 calls.
#
# Usage:
#   _record_denied_error <category> [<tool>]
#     category ∈ unauthorized | forbidden | 403 | 401 | denied | missing_token
#     tool     optional tool name string
#
# Fire-and-forget; failures are silent (we never block the post-tool path).
_record_denied_error() {
  local category="${1:-}"
  local tool="${2:-unknown}"
  if [ -z "$category" ]; then
    return 0
  fi
  # Normalize category to the schema enum
  case "$category" in
    unauthorized|forbidden|403|401|denied|missing_token) ;;
    *) return 0 ;;
  esac
  local _ts_now
  _ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
  # Append the new entry; trim to the last 5 so the array stays bounded.
  _state_update \
    --arg ts "$_ts_now" \
    --arg cat "$category" \
    --arg tool "$tool" \
    '.recent_denied_error_window = ((.recent_denied_error_window // []) + [{ts:$ts, category:$cat, tool:$tool}] | .[-5:])' \
    2>/dev/null || true
}

_emit_apex_event() {
  if ! command -v jq >/dev/null 2>&1; then
    return 0
  fi
  local event_type="$1"
  local state_dir="${2:-.apex}"
  [ -z "$state_dir" ] && state_dir=".apex"
  shift 2 2>/dev/null || shift $#
  local _ts_now
  _ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
  local source="${APEX_HOOK_SOURCE:-unknown}"
  local jq_args=(--arg ts "$_ts_now" --arg type "$event_type" --arg src "$source")
  local filter='{ts:$ts,type:$type,source:$src}'
  while [ $# -ge 2 ]; do
    local k="$1" v="$2"
    # Sanitize jq variable name — only allow alphanumeric and underscore
    local safe_k
    safe_k=$(printf '%s' "$k" | tr -c 'A-Za-z0-9_' '_')
    jq_args+=(--arg "v_${safe_k}" "$v")
    filter="${filter} + {\"${k}\":\$v_${safe_k}}"
    shift 2
  done
  jq -c -n "${jq_args[@]}" "$filter" >> "${state_dir}/event-log.jsonl" 2>/dev/null || true
}
