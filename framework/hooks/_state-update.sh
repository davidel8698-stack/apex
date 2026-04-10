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
  if jq "${jq_args[@]}" "$expr" "$state_file" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$state_file"
  else
    rm -f "$tmp"
    echo "⚠️ STATE update failed: $expr" >&2
    return 1
  fi
}
