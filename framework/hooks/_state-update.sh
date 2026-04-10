#!/usr/bin/env bash
# Atomic STATE.json update with error handling.
# Source this from any hook that updates .apex/STATE.json.
# Usage: _state_update '.field = "value"' [optional_state_file_path]

_state_update() {
  local expr="$1"
  local state_file="${2:-.apex/STATE.json}"
  local tmp="/tmp/_apex_state_$(date +%s%N).json"
  if jq "$expr" "$state_file" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$state_file"
  else
    rm -f "$tmp"
    echo "⚠️ STATE update failed: $expr" >&2
    return 1
  fi
}
