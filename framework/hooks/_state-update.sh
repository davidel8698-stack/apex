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
    printf '{"ts":"%s","type":"state_mutation","source":"%s","expr":"%s"}\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)" \
      "${APEX_HOOK_SOURCE:-unknown}" \
      "$safe_expr" >> "${state_dir}/event-log.jsonl" 2>/dev/null || true
  else
    rm -f "$tmp"
    local jq_msg
    jq_msg=$(cat "$err" 2>/dev/null)
    rm -f "$err"
    echo "⚠️ STATE update failed: $expr${jq_msg:+ — $jq_msg}" >&2
    return 1
  fi
}
