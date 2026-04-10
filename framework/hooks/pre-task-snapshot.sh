#!/bin/bash
set -u
# Creates a git stash snapshot before task execution for per-task rollback.
# Uses `git stash create` + `git stash store` so the working tree is NOT
# modified (unlike `git stash push`), and the named stash remains in
# `git stash list` for real rollback later.
#
# Filesystem-level verification: after store, greps `git stash list` for
# the expected message. If verification fails, exits 2 (fail-loud) so
# /apex:next can decide whether to proceed without a snapshot.
#
# Usage: bash pre-task-snapshot.sh [task_id]

source "$(dirname "$0")/_require-jq.sh"
require_jq
source "$(dirname "$0")/_state-update.sh"

# Validate STATE.json against schema before snapshot (soft mode — warn, don't block)
if [ -f .apex/STATE.json ] && [ -f ~/.claude/schemas/STATE.schema.json ] && [ -f ~/.claude/scripts/validate-state.sh ]; then
  bash ~/.claude/scripts/validate-state.sh --soft ~/.claude/schemas/STATE.schema.json .apex/STATE.json 2>&1 || true
fi

TASK_ID=${1:-"unknown"}
TIMESTAMP=$(date +%s)
STASH_MSG="apex-snapshot-${TASK_ID}-${TIMESTAMP}"

update_state_stash() {
  local stash_value="$1"
  if [ -f .apex/STATE.json ]; then
    _state_update --arg task "$TASK_ID" --arg stash "$stash_value" \
       '.snapshots.pre_task_stash = $stash | .snapshots.last_snapshot_task = $task'
  fi
}

update_state_stash_null() {
  if [ -f .apex/STATE.json ]; then
    _state_update --arg task "$TASK_ID" \
       '.snapshots.pre_task_stash = null | .snapshots.last_snapshot_task = $task'
  fi
}

source "$(dirname "$0")/_require-git.sh"

# Create a stash object WITHOUT touching the working tree.
# -u includes untracked files (matching previous --include-untracked semantic).
STASH_ERR=$(git stash create -u "$STASH_MSG" 2>&1)
STASH_EXIT=$?
STASH_SHA=$(echo "$STASH_ERR" | grep -E '^[0-9a-f]{40}$' | head -1)

if [ "$STASH_EXIT" -ne 0 ]; then
  # Git itself errored — fail loud (3-way exit: exit 1 = advisory git error)
  echo "⚠️ PRE-TASK SNAPSHOT: git stash create failed (exit $STASH_EXIT)" >&2
  echo "   $STASH_ERR" >&2
  update_state_stash_null
  exit 1
fi

if [ -z "$STASH_SHA" ]; then
  # Clean working tree — nothing to snapshot
  echo "✅ PRE-TASK SNAPSHOT: Working tree clean (no stash needed)"
  update_state_stash "clean-${TIMESTAMP}"
  exit 0
fi

# Store the stash object in the stash list with a named message
git stash store -m "$STASH_MSG" "$STASH_SHA" 2>/dev/null

# FILESYSTEM-LEVEL VERIFICATION — matches critic.md rule.
# Don't trust $? alone; confirm the stash is actually in the list.
if git stash list | grep -qF "$STASH_MSG"; then
  update_state_stash "$STASH_MSG"
  echo "✅ PRE-TASK SNAPSHOT: Saved for task $TASK_ID"
  echo "   Rollback: git reset --hard HEAD && git stash apply \"stash^{/$STASH_MSG}\""
  exit 0
else
  # The stash did not land — fail loud so the caller can decide.
  update_state_stash_null
  echo "🚫 PRE-TASK SNAPSHOT: stash creation unverified at filesystem level" >&2
  echo "   task=$TASK_ID msg=$STASH_MSG sha=$STASH_SHA" >&2
  echo "   Aborting task to preserve data integrity." >&2
  exit 2
fi
