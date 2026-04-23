#!/bin/bash
set -u
# Creates git tag for completed phase, enabling rollback
# Usage: bash phase-tag.sh [phase_id]
source "$(dirname "$0")/_require-jq.sh"
require_jq
source "$(dirname "$0")/_require-git.sh"
source "$(dirname "$0")/_state-update.sh"

export APEX_HOOK_SOURCE="phase-tag"

# G-2: Ensure CWD is project root so .apex/ paths resolve
cd "$(git rev-parse --show-toplevel)" || exit 2

PHASE_ID=${1:-"unknown"}
TAG_NAME="apex/phase-${PHASE_ID}-complete"

# Check if tag already exists
if git tag -l "$TAG_NAME" | grep -qF "$TAG_NAME"; then
  echo "⚠️ Tag $TAG_NAME already exists — skipping"
  exit 0
fi

# Create annotated tag — capture stderr + exit code for diagnostics on failure
TAG_OUTPUT=$(git tag -a "$TAG_NAME" -m "APEX: Phase $PHASE_ID verified and complete ($(date +%Y-%m-%d))" 2>&1)
TAG_EXIT=$?

# FILESYSTEM-LEVEL VERIFICATION — matches pre-task-snapshot.sh doctrine.
# Don't trust $? alone; confirm the tag is actually in git tag -l.
if git tag -l "$TAG_NAME" | grep -qF "$TAG_NAME"; then
  # Update STATE.json only after filesystem confirms the tag exists
  if [ -f .apex/STATE.json ]; then
    _state_update --arg phase "$PHASE_ID" --arg tag "$TAG_NAME" \
       '.phase_tags[$phase] = $tag'
  fi
  # DORA metric collection: lead_time + deployment_freq
  if [ -f .apex/STATE.json ]; then
    # Lead time: hours from phase PLAN_META created_at to now
    PLAN_META=".apex/phases/${PHASE_ID}/PLAN_META.json"
    if [ -f "$PLAN_META" ]; then
      CREATED_AT=$(jq -r '.created_at // empty' "$PLAN_META" 2>/dev/null)
      if [ -n "$CREATED_AT" ]; then
        CREATED_TS=$(date -d "$CREATED_AT" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${CREATED_AT%%.*}" +%s 2>/dev/null || echo "")
        NOW_TS=$(date +%s)
        if [ -n "$CREATED_TS" ]; then
          LEAD_HOURS=$(awk "BEGIN {printf \"%.1f\", ($NOW_TS - $CREATED_TS) / 3600}")
          # Update rolling average lead_time
          _state_update --argjson hours "$LEAD_HOURS" \
            --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            'if .dora.lead_time_avg == null then .dora.lead_time_avg = $hours
             else .dora.lead_time_avg = ((.dora.lead_time_avg + $hours) / 2)
             end | .dora.last_updated = $now'
        fi
      fi
    fi
    # Deployment freq: phases_completed / days since project created
    CREATED_AT_PROJ=$(jq -r '.created_at // empty' .apex/STATE.json 2>/dev/null)
    PHASES_DONE=$(jq -r '.phases_completed // 0' .apex/STATE.json 2>/dev/null)
    if [ -n "$CREATED_AT_PROJ" ] && [ "$PHASES_DONE" -gt 0 ] 2>/dev/null; then
      PROJ_TS=$(date -d "$CREATED_AT_PROJ" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${CREATED_AT_PROJ%%.*}" +%s 2>/dev/null || echo "")
      NOW_TS=$(date +%s)
      if [ -n "$PROJ_TS" ]; then
        DAYS_ELAPSED=$(awk "BEGIN {d=($NOW_TS - $PROJ_TS) / 86400; if(d<1) d=1; printf \"%.2f\", $PHASES_DONE / d}")
        _state_update --argjson freq "$DAYS_ELAPSED" \
          '.dora.deployment_freq = $freq'
      fi
    fi
    # Change failure rate: phases_failed / phases_completed
    PHASES_FAILED=$(jq -r '.phases_failed // 0' .apex/STATE.json 2>/dev/null)
    PHASES_DONE_CFR=$(jq -r '.phases_completed // 1' .apex/STATE.json 2>/dev/null)
    if [ "$PHASES_DONE_CFR" -gt 0 ] 2>/dev/null; then
      CFR=$(awk "BEGIN {printf \"%.2f\", $PHASES_FAILED / $PHASES_DONE_CFR}")
      _state_update --argjson cfr "$CFR" \
        '.dora.change_failure_rate = $cfr'
    fi
  fi
  echo "✅ Phase tag verified: $TAG_NAME"
  echo "   Rollback available: git revert --no-commit HEAD..$TAG_NAME"
  exit 0
else
  # Tag creation did not land — fail loud so the caller can decide.
  echo "🚫 PHASE TAG: creation unverified at filesystem level" >&2
  echo "   tag=$TAG_NAME phase=$PHASE_ID" >&2
  echo "   git exit code: $TAG_EXIT" >&2
  echo "   git stderr: $TAG_OUTPUT" >&2
  exit 2
fi
