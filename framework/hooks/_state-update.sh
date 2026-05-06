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
