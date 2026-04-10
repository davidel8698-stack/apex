#!/bin/bash
# v7: Added total tool-call cap per task + enhanced loop detection [R1, R7]
# R1: GSD Issue #456 (infinite loops), Superpowers recursive subagent
# R7: Retry limited to 3 (diminishing returns). Failed trajectories cost 4x+ tokens.
# Called after each tool use by executor
source "$(dirname "$0")/_require-jq.sh"
require_jq
source "$(dirname "$0")/_require-git.sh"

STATE_FILE=".apex/STATE.json"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# === CHECK 1: Consecutive no-change actions ===
GIT_DIFF_OUTPUT=$(git diff HEAD --stat 2>/dev/null)
if [ -z "$GIT_DIFF_OUTPUT" ]; then
  CURRENT_HASH="empty_$(date +%s%N)"
else
  CURRENT_HASH=$(echo "$GIT_DIFF_OUTPUT" | md5sum | cut -d' ' -f1)
fi
LAST_HASH=$(jq -r '.circuit_breaker.last_file_hash // ""' "$STATE_FILE" 2>/dev/null)
MAX_NO_CHANGE=$(jq -r '.circuit_breaker.max_allowed // 3' "$STATE_FILE" 2>/dev/null)

if [ "$CURRENT_HASH" = "$LAST_HASH" ] && [ -n "$LAST_HASH" ]; then
  COUNT=$(jq -r '.circuit_breaker.consecutive_no_change_actions // 0' "$STATE_FILE" 2>/dev/null)
  COUNT=$((COUNT + 1))

  jq --argjson count "$COUNT" \
     '.circuit_breaker.consecutive_no_change_actions = $count' \
     "$STATE_FILE" > /tmp/state_cb.json && mv /tmp/state_cb.json "$STATE_FILE"

  if [ "$COUNT" -ge "$MAX_NO_CHANGE" ]; then
    echo "🛑 CIRCUIT BREAKER: NO-CHANGE LOOP"
    echo "   $COUNT consecutive actions without file changes."
    echo "   Likely stuck in a loop."
    echo ""
    echo "   Options:"
    echo "   1. Take a completely different approach"
    echo "   2. Report: '⚠️ Blocked — need guidance'"
    echo "   3. /apex:recover to reset"

    jq '.circuit_breaker.triggered = true | .circuit_breaker.trigger_reason = "no_change_loop"' \
       "$STATE_FILE" > /tmp/state_cb.json && mv /tmp/state_cb.json "$STATE_FILE"
    exit 2
  fi
else
  # Files changed — reset no-change counter
  jq --arg hash "$CURRENT_HASH" \
     '.circuit_breaker.consecutive_no_change_actions = 0 | .circuit_breaker.last_file_hash = $hash | .circuit_breaker.triggered = false' \
     "$STATE_FILE" > /tmp/state_cb.json && mv /tmp/state_cb.json "$STATE_FILE"
fi

# === CHECK 2: v7 — Total tool calls per task (prevents token spirals) ===
# Executor maxTurns = 40. Cap at 80 (2x) to catch spiraling tasks.
MAX_TOOL_CALLS=$(jq -r '.circuit_breaker.max_tool_calls_per_task // 80' "$STATE_FILE" 2>/dev/null)
TOOL_CALLS=$(jq -r '.circuit_breaker.total_tool_calls_this_task // 0' "$STATE_FILE" 2>/dev/null)
TOOL_CALLS=$((TOOL_CALLS + 1))

jq --argjson calls "$TOOL_CALLS" \
   '.circuit_breaker.total_tool_calls_this_task = $calls' \
   "$STATE_FILE" > /tmp/state_cb.json && mv /tmp/state_cb.json "$STATE_FILE"

if [ "$TOOL_CALLS" -ge "$MAX_TOOL_CALLS" ]; then
  echo "🛑 CIRCUIT BREAKER: TOOL-CALL CAP REACHED"
  echo "   $TOOL_CALLS tool calls on this task (cap: $MAX_TOOL_CALLS)."
  echo "   R7: Failed trajectories cost 4x+ more tokens than successful ones."
  echo ""
  echo "   This task is consuming excessive resources."
  echo "   Options:"
  echo "   1. Report: '⚠️ Blocked — need manual intervention'"
  echo "   2. /apex:recover to reset and re-plan"

  jq '.circuit_breaker.triggered = true | .circuit_breaker.trigger_reason = "tool_call_cap"' \
     "$STATE_FILE" > /tmp/state_cb.json && mv /tmp/state_cb.json "$STATE_FILE"
  exit 2
fi

exit 0