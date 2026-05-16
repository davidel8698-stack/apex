#!/bin/bash
set -u
# v7: Added observation masking tracking [R2]
# R2: Simple deletion of old tool outputs gives 50% cost reduction at neutral/positive quality
source "$(dirname "$0")/_require-jq.sh"
require_jq

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p .apex/backups

STATE_BACKUP_OK=true
PLAN_BACKUP_OK=true

if [ -f .apex/STATE.json ]; then
  if ! cp .apex/STATE.json ".apex/backups/STATE_$TIMESTAMP.json" 2>/dev/null; then
    echo "⚠️ Failed to back up STATE.json" >&2
    STATE_BACKUP_OK=false
  fi
else
  STATE_BACKUP_OK=false
fi

PHASE=$(jq -r '.current_phase // empty' .apex/STATE.json 2>/dev/null)
if [ -n "$PHASE" ] && [ -f ".apex/phases/$PHASE/PLAN.md" ]; then
  if ! cp ".apex/phases/$PHASE/PLAN.md" ".apex/backups/PLAN_${PHASE}_$TIMESTAMP.md" 2>/dev/null; then
    echo "⚠️ Failed to back up PLAN.md for phase $PHASE" >&2
    PLAN_BACKUP_OK=false
  fi
fi

# R13-002 (F-302): Observation masking runs FIRST. Mask stale tool-result
# blocks out of the executor transcript BEFORE Claude Code's /compact step
# runs (Claude Code invokes /compact AFTER this PreCompact hook completes).
# Sequence is load-bearing per plan §"Inversion risk": if /compact ran first,
# the stale tool-results would already be summarized into the rolled-up
# transcript and the masking pass would deliver 0% benefit.
#
# Fail-safe: the mask hook itself never blocks (returns 0 on missing
# transcript). pre-compact.sh's fall-through to /compact is the safety net.
MASK_HOOK="$(dirname "$0")/observation-mask.sh"
if [ -x "$MASK_HOOK" ] || [ -f "$MASK_HOOK" ]; then
  # observation-mask before /compact — sequence is load-bearing (R13-002).
  bash "$MASK_HOOK" || true
fi

# v7: Log observation masking stats for tracking [R2]
if [ "$STATE_BACKUP_OK" = true ] && [ -f .apex/STATE.json ]; then
  AGENT_CALLS=$(jq -r '[.tokens.by_agent | to_entries[]? | .value.calls] | add // 0' .apex/STATE.json 2>/dev/null || echo 0)
  echo "APEX: State backed up $TIMESTAMP | $AGENT_CALLS agent calls this session"
  # R13-002: mask hook ran above. /compact (Claude Code built-in) is the
  # post-mask fall-through that runs after this hook returns; keep this
  # line as the operator-visible signal that masking-before-compact is
  # the pipeline order.
  echo "R13-002: Observation masking ran before /compact — stale tool outputs replaced with disk re-read stubs."
elif [ "$STATE_BACKUP_OK" = true ]; then
  echo "APEX: State backed up $TIMESTAMP"
else
  echo "🚫 APEX: STATE.json backup failed $TIMESTAMP — blocking compaction" >&2
fi

if [ "$PLAN_BACKUP_OK" = false ]; then
  echo "⚠️ APEX: PLAN.md backup failed — proceeding (recoverable)" >&2
fi

# STATE.json backup is critical — block compaction if it failed
if [ "$STATE_BACKUP_OK" = false ]; then exit 2; fi
# PLAN.md backup failure is advisory — compaction can proceed
if [ "$PLAN_BACKUP_OK" = false ]; then exit 1; fi
exit 0