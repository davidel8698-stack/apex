#!/bin/bash
# Creates git tag for completed phase, enabling rollback
# Usage: bash phase-tag.sh [phase_id]
source "$(dirname "$0")/_require-jq.sh"
require_jq

PHASE_ID=${1:-"unknown"}
TAG_NAME="apex/phase-${PHASE_ID}-complete"

# Check if tag already exists
if git tag -l "$TAG_NAME" | grep -q "$TAG_NAME"; then
  echo "⚠️ Tag $TAG_NAME already exists — skipping"
  exit 0
fi

# Create annotated tag
git tag -a "$TAG_NAME" -m "APEX: Phase $PHASE_ID verified and complete ($(date -I))" 2>/dev/null

if [ $? -eq 0 ]; then
  # Update STATE.json
  if [ -f .apex/STATE.json ]; then
    jq --arg phase "$PHASE_ID" --arg tag "$TAG_NAME" \
       '.phase_tags[$phase] = $tag' \
       .apex/STATE.json > /tmp/state_tag.json && mv /tmp/state_tag.json .apex/STATE.json
  fi
  echo "✅ Phase tag created: $TAG_NAME"
  echo "   Rollback available: git revert --no-commit HEAD..$TAG_NAME"
else
  echo "⚠️ Failed to create tag $TAG_NAME (not in git repo?)"
fi

exit 0