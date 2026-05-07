#!/bin/bash
# turn-checkpoint.sh — Auto-Continuity Layer B (v7.1).
# Persists a fine-grained turn-level checkpoint inside long-running tasks so
# /apex:recover option 6 can continue from a near-by point instead of replaying
# the whole task or losing it entirely.
#
# Wired as: PostToolUse hook on Bash AND Write|Edit (every tool call) — see
# settings.json. Throttled by turn_checkpoint_interval (default: every 5 tool
# calls) so the disk write rate is bounded.
#
# Contract:
#   • exit 0 always — never blocks tool execution
#   • Hooks ordering: must run AFTER circuit-breaker.sh so
#     circuit_breaker.total_tool_calls_this_task is fresh.
#   • Side effects:
#       - .apex/TURN_CHECKPOINT.json — atomic temp+mv replace (not append)
#       - .apex/STATE.json — updates .turn_checkpoint mirror (single source)
#       - .apex/event-log.jsonl — appends turn_checkpoint_set event
#
# What it does NOT do:
#   • It does not write a working_summary — that requires conversational context
#     the hook cannot see. /apex:next Step G is responsible for refreshing
#     working_summary at task boundaries; this hook preserves whatever was
#     last set, or null on first checkpoint.
#   • It does not capture in-flight edits in detail. Doing so would require
#     intercepting Write/Edit before they complete; instead we record the
#     last_completed_tool name as a recovery hint.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_require-jq.sh"
require_jq
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_state-update.sh"

export APEX_HOOK_SOURCE="turn-checkpoint"

STATE_FILE=".apex/STATE.json"
BUDGET_FILE=".apex/CONTEXT_BUDGET.json"
FRAMEWORK_BUDGET_FILE="$HOME/.claude/CONTEXT_BUDGET.default.json"
CHECKPOINT_FILE=".apex/TURN_CHECKPOINT.json"

# Fail-soft when no APEX project here.
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# --- Read interval (CONTEXT_BUDGET.json overrides framework default) ---
read_interval() {
  local val=""
  if [ -f "$BUDGET_FILE" ]; then
    val=$(jq -r '.auto_continuity.turn_checkpoint_interval // empty' "$BUDGET_FILE" 2>/dev/null)
  fi
  if [ -z "$val" ] && [ -f "$FRAMEWORK_BUDGET_FILE" ]; then
    val=$(jq -r '.auto_continuity.turn_checkpoint_interval // empty' "$FRAMEWORK_BUDGET_FILE" 2>/dev/null)
  fi
  if [ -z "$val" ] || [ "$val" = "null" ]; then val=5; fi
  printf '%s' "$val"
}

INTERVAL=$(read_interval)
[ "$INTERVAL" -lt 1 ] 2>/dev/null && INTERVAL=5

# --- Read tool-call counter (set by circuit-breaker.sh) ---
TOOL_CALL_INDEX=$(jq -r '.circuit_breaker.total_tool_calls_this_task // 0' "$STATE_FILE" 2>/dev/null)
TOOL_CALL_INDEX=${TOOL_CALL_INDEX:-0}

# Skip if not at a checkpoint boundary (or if no tool calls yet)
if [ "$TOOL_CALL_INDEX" -lt 1 ] 2>/dev/null; then
  exit 0
fi
if [ "$((TOOL_CALL_INDEX % INTERVAL))" -ne 0 ] 2>/dev/null; then
  exit 0
fi

# --- Gather checkpoint payload ---
TASK_ID=$(jq -r '.current_unit // empty' "$STATE_FILE" 2>/dev/null)
[ -z "$TASK_ID" ] && TASK_ID="(unknown)"

# Preserve existing working_summary (only /apex:next Step G refreshes it)
PRIOR_SUMMARY=$(jq -r '.turn_checkpoint.working_summary // empty' "$STATE_FILE" 2>/dev/null)
if [ -z "$PRIOR_SUMMARY" ] || [ "$PRIOR_SUMMARY" = "null" ]; then
  PRIOR_SUMMARY=""
fi

# Best-effort detection of the most recent tool: read the last state_mutation
# event from event-log.jsonl. This is purely advisory (recovery hint).
LAST_TOOL=""
if [ -f .apex/event-log.jsonl ]; then
  LAST_TOOL=$(tail -50 .apex/event-log.jsonl 2>/dev/null | \
    jq -r 'select(.type == "state_mutation") | .source' 2>/dev/null | \
    tail -1)
fi
[ -z "$LAST_TOOL" ] && LAST_TOOL="unknown"

NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)

# --- Atomic write of TURN_CHECKPOINT.json (separate file for /apex:recover) ---
TMP_CKPT="${CHECKPOINT_FILE}.tmp.$$"
jq -n \
  --arg ts "$NOW_ISO" \
  --arg task_id "$TASK_ID" \
  --argjson idx "$TOOL_CALL_INDEX" \
  --arg summary "$PRIOR_SUMMARY" \
  --arg last_tool "$LAST_TOOL" \
  '{
    ts: $ts,
    task_id: $task_id,
    tool_call_index: $idx,
    in_flight_edits: [],
    working_summary: (if $summary == "" then null else $summary end),
    last_completed_tool: $last_tool
  }' > "$TMP_CKPT" 2>/dev/null
if [ -s "$TMP_CKPT" ] && jq empty "$TMP_CKPT" >/dev/null 2>&1; then
  mv "$TMP_CKPT" "$CHECKPOINT_FILE"
else
  rm -f "$TMP_CKPT"
  echo "⚠️ [turn-checkpoint] failed to write $CHECKPOINT_FILE (continuing)" >&2
  exit 0
fi

# --- Mirror to STATE.turn_checkpoint (single source for /apex:status & schema) ---
_state_update \
  --arg ts "$NOW_ISO" \
  --arg task_id "$TASK_ID" \
  --argjson idx "$TOOL_CALL_INDEX" \
  --arg summary "$PRIOR_SUMMARY" \
  --arg last_tool "$LAST_TOOL" \
  '.turn_checkpoint = {
    ts: $ts,
    task_id: $task_id,
    tool_call_index: $idx,
    in_flight_edits: [],
    working_summary: (if $summary == "" then null else $summary end),
    last_completed_tool: $last_tool
  }' "$STATE_FILE"

# --- Emit semantic event ---
_emit_apex_event turn_checkpoint_set .apex \
  task_id "$TASK_ID" \
  tool_call_index "$TOOL_CALL_INDEX" \
  last_completed_tool "$LAST_TOOL"

exit 0
