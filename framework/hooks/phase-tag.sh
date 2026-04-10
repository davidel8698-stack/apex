#!/bin/bash
# Creates git tag for completed phase, enabling rollback
# Usage: bash phase-tag.sh [phase_id]
source "$(dirname "$0")/_require-jq.sh"
require_jq
source "$(dirname "$0")/_require-git.sh"
source "$(dirname "$0")/_state-update.sh"

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
