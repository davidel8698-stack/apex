#!/bin/bash
# v7: Added observation masking tracking [R2]
# R2: Simple deletion of old tool outputs gives 50% cost reduction at neutral/positive quality
source "$(dirname "$0")/_require-jq.sh"
require_jq

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p .apex/backups

cp .apex/STATE.json ".apex/backups/STATE_$TIMESTAMP.json" 2>/dev/null
cp .apex/AUTONOMY.json ".apex/backups/AUTONOMY_$TIMESTAMP.json" 2>/dev/null

PHASE=$(jq -r '.current_phase // empty' .apex/STATE.json 2>/dev/null)
[ -n "$PHASE" ] && cp ".apex/phases/$PHASE/PLAN.md" ".apex/backups/PLAN_${PHASE}_$TIMESTAMP.md" 2>/dev/null

# v7: Log observation masking stats for tracking [R2]
if [ -f .apex/STATE.json ]; then
  AGENT_CALLS=$(jq -r '[.tokens.by_agent | to_entries[]? | .value.calls] | add // 0' .apex/STATE.json 2>/dev/null || echo 0)
  echo "APEX: State backed up $TIMESTAMP | $AGENT_CALLS agent calls this session"
  echo "R2: Observation masking active — old tool outputs should be re-read, not cached."
else
  echo "APEX: State backed up $TIMESTAMP"
fi

exit 0