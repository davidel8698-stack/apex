#!/bin/bash
set -u
# v7: Real token counting from STATE.json instead of heuristic [R2]
# R2: compact at 50-60%, hard rotate at 70%, never exceed 75%
# Previous heuristic: AGENT_CALLS * 15000 — wildly inaccurate
source "$(dirname "$0")/_require-jq.sh"
require_jq
source "$(dirname "$0")/_state-update.sh"

export APEX_HOOK_SOURCE="context-monitor"

STATE_FILE=".apex/STATE.json"
BUDGET_FILE=".apex/CONTEXT_BUDGET.json"

if [ ! -f "$STATE_FILE" ]; then
  echo "✅ CONTEXT: No state file — fresh session"
  exit 0
fi

# v7 thresholds from CONTEXT_BUDGET.json (R2-validated)
WARNING_PCT=$(jq -r '.thresholds.proactive_compact_pct // 55' "$BUDGET_FILE" 2>/dev/null || echo 55)
CRITICAL_PCT=$(jq -r '.thresholds.hard_rotate_pct // 70' "$BUDGET_FILE" 2>/dev/null || echo 70)

# v7: Use ACTUAL token data from STATE.json (updated by orchestrator in Step G)
TOTAL_INPUT=$(jq -r '.tokens.total_input // 0' "$STATE_FILE" 2>/dev/null || echo 0)
TOTAL_OUTPUT=$(jq -r '.tokens.total_output // 0' "$STATE_FILE" 2>/dev/null || echo 0)

# Effective capacity from CONTEXT_BUDGET.json (default 200K per R2 design)
EFFECTIVE_CAPACITY=$(jq -r '.capacity_tokens // 200000' "$BUDGET_FILE" 2>/dev/null || echo 200000)
# Guard against zero/invalid capacity to prevent division by zero
[ "$EFFECTIVE_CAPACITY" -le 0 ] 2>/dev/null && EFFECTIVE_CAPACITY=200000

if [ "$TOTAL_INPUT" -gt 0 ]; then
  # Real token data available — use it
  ESTIMATED_PCT=$((TOTAL_INPUT * 100 / EFFECTIVE_CAPACITY))
else
  # Fallback: count agent calls if token data not yet populated
  AGENT_CALLS=$(jq -r '
    [.tokens.by_agent | to_entries[]? | .value.calls] | add // 0' "$STATE_FILE" 2>/dev/null || echo 0)
  # Conservative heuristic: 20K per call (higher than the earlier 15K to be safe)
  ESTIMATED_USAGE=$((AGENT_CALLS * 20000))
  ESTIMATED_PCT=$((ESTIMATED_USAGE * 100 / EFFECTIVE_CAPACITY))
fi

# Update STATE.json with current estimate
_state_update --argjson pct "$ESTIMATED_PCT" \
   '.context.estimated_context_usage_pct = $pct' "$STATE_FILE"

if [ "$ESTIMATED_PCT" -ge "$CRITICAL_PCT" ]; then
  echo "CRITICAL_OVERFLOW"
  echo "⚠️ Context at ~${ESTIMATED_PCT}% (threshold: ${CRITICAL_PCT}%)"
  echo "R2: coding quality degrades severely above 70%."
  echo "Run /apex:resume for fresh context."
  exit 2
elif [ "$ESTIMATED_PCT" -ge "$WARNING_PCT" ]; then
  echo "WARNING_OVERFLOW"
  echo "⚠️ Context at ~${ESTIMATED_PCT}%. Proactive compact recommended."
  echo "R2: observation masking (deleting old tool outputs) is preferred over LLM summarization."
  exit 1
else
  echo "✅ CONTEXT: ~${ESTIMATED_PCT}% used (${TOTAL_INPUT} input tokens tracked)"
  exit 0
fi