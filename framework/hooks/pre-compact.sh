#!/bin/bash
set -u
# v7: Added observation masking tracking [R2]
# R2: Simple deletion of old tool outputs gives 50% cost reduction at neutral/positive quality
source "$(dirname "$0")/_require-jq.sh"
require_jq

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p .apex/backups

BACKUP_OK=true

if [ -f .apex/STATE.json ]; then
  if ! cp .apex/STATE.json ".apex/backups/STATE_$TIMESTAMP.json" 2>/dev/null; then
    echo "⚠️ Failed to back up STATE.json" >&2
    BACKUP_OK=false
  fi
else
  BACKUP_OK=false
fi

PHASE=$(jq -r '.current_phase // empty' .apex/STATE.json 2>/dev/null)
if [ -n "$PHASE" ] && [ -f ".apex/phases/$PHASE/PLAN.md" ]; then
  if ! cp ".apex/phases/$PHASE/PLAN.md" ".apex/backups/PLAN_${PHASE}_$TIMESTAMP.md" 2>/dev/null; then
    echo "⚠️ Failed to back up PLAN.md for phase $PHASE" >&2
    BACKUP_OK=false
  fi
fi

# v7: Log observation masking stats for tracking [R2]
if [ "$BACKUP_OK" = true ] && [ -f .apex/STATE.json ]; then
  AGENT_CALLS=$(jq -r '[.tokens.by_agent | to_entries[]? | .value.calls] | add // 0' .apex/STATE.json 2>/dev/null || echo 0)
  echo "APEX: State backed up $TIMESTAMP | $AGENT_CALLS agent calls this session"
  echo "R2: Observation masking active — old tool outputs should be re-read, not cached."
elif [ "$BACKUP_OK" = true ]; then
  echo "APEX: State backed up $TIMESTAMP"
else
  echo "⚠️ APEX: Backup incomplete $TIMESTAMP — some files could not be copied" >&2
fi

if [ "$BACKUP_OK" = true ]; then exit 0; else exit 1; fi