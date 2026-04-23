#!/usr/bin/env bash
# Point-in-time STATE.json snapshot for consistent reads.
# Source this from any hook that needs multiple reads from STATE.json
# within a single invocation — ensures all reads see the same version.
#
# Usage:
#   source "$(dirname "$0")/_state-read.sh"
#   _state_snapshot                          # cache STATE.json
#   _state_snapshot path/to/STATE.json       # cache custom file
#   _state_read '.current_phase'             # read from cache
#   _state_read '.circuit_breaker.max_allowed // 3'

_APEX_STATE_CACHE=""
_APEX_STATE_FILE=""

_state_snapshot() {
  _APEX_STATE_FILE="${1:-.apex/STATE.json}"
  if [ ! -f "$_APEX_STATE_FILE" ]; then
    echo "⚠️ _state_snapshot: file not found — $_APEX_STATE_FILE" >&2
    return 1
  fi
  _APEX_STATE_CACHE=$(cat "$_APEX_STATE_FILE")
}

_state_read() {
  local filter="$1"
  if [ -z "$_APEX_STATE_CACHE" ]; then
    _state_snapshot || return 1
  fi
  echo "$_APEX_STATE_CACHE" | jq -r "$filter"
}
