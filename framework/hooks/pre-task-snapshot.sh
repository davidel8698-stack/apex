#!/bin/bash
# Creates git stash snapshot before task execution for per-task rollback
# Usage: bash pre-task-snapshot.sh [task_id]

TASK_ID=${1:-"unknown"}
TIMESTAMP=$(date +%s)
STASH_MSG="apex-snapshot-${TASK_ID}-${TIMESTAMP}"

# Check if there's anything to stash
if git diff --quiet HEAD 2>/dev/null && git diff --cached --quiet HEAD 2>/dev/null; then
  # Clean working tree — create empty stash marker
  echo "✅ PRE-TASK SNAPSHOT: Working tree clean (no stash needed)"

  # Update STATE.json
  if [ -f .apex/STATE.json ] && command -v jq &>/dev/null; then
    jq --arg task "$TASK_ID" --arg stash "clean-${TIMESTAMP}" \
       '.snapshots.pre_task_stash = $stash | .snapshots.last_snapshot_task = $task' \
       .apex/STATE.json > /tmp/state_snap.json && mv /tmp/state_snap.json .apex/STATE.json
  fi
  exit 0
fi

# Stash current changes
git stash push -m "$STASH_MSG" --include-untracked 2>/dev/null

if [ $? -eq 0 ]; then
  # Immediately pop to restore working state — the stash remains in reflog
  git stash pop 2>/dev/null

  # Update STATE.json
  if [ -f .apex/STATE.json ] && command -v jq &>/dev/null; then
    jq --arg task "$TASK_ID" --arg stash "$STASH_MSG" \
       '.snapshots.pre_task_stash = $stash | .snapshots.last_snapshot_task = $task' \
       .apex/STATE.json > /tmp/state_snap.json && mv /tmp/state_snap.json .apex/STATE.json
  fi

  echo "✅ PRE-TASK SNAPSHOT: Saved for task $TASK_ID"
  echo "   Rollback: git stash list | grep '$STASH_MSG'"
else
  echo "⚠️ PRE-TASK SNAPSHOT: git stash failed — continuing without snapshot"
fi

exit 0
