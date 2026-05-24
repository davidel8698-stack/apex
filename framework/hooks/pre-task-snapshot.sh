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
# Self-filter (R8-008): when invoked via Claude Code's PreToolUse Bash
# matcher, the hook reads the stdin envelope and skips the snapshot
# when the user's command begins with `git status|log|show|diff|stash`.
# These are read-only or stash-management invocations whose intent is
# inspection or stash-list manipulation; a per-task auto-snapshot would
# clutter the stash list and risk colliding with user-named stashes.
# Standalone CLI invocations (no stdin envelope) continue to fire the
# snapshot — preserving the manual-rollback contract.
#
# Usage: bash pre-task-snapshot.sh [task_id]

source "$(dirname "$0")/_require-jq.sh"
require_jq
source "$(dirname "$0")/_state-update.sh"

export APEX_HOOK_SOURCE="pre-task-snapshot"

# --- R8-008: Self-filter on stdin envelope -----------------------------
# When invoked from settings.json's PreToolUse Bash matcher, Claude Code
# pipes a JSON envelope to stdin: {"tool_input":{"command":"<user cmd>"}}.
# Extract `.tool_input.command` and skip the snapshot when the command's
# first git subcommand is `status`, `log`, `show`, `diff`, or `stash`
# (read-only or stash-management — cannot mutate working tree, snapshot
# would be noise). Direct CLI invocation (no envelope on stdin) falls
# through to the snapshot path, preserving the standalone contract.
if [ ! -t 0 ]; then
  STDIN_ENV_BUF=$(cat 2>/dev/null || true)
  if [ -n "$STDIN_ENV_BUF" ] && command -v jq >/dev/null 2>&1; then
    USER_CMD=$(echo "$STDIN_ENV_BUF" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
    if [ -n "$USER_CMD" ]; then
      # Strip leading whitespace; capture the first two tokens.
      CMD_TRIM="${USER_CMD#"${USER_CMD%%[![:space:]]*}"}"
      FIRST_TOK="${CMD_TRIM%% *}"
      REST_AFTER_FIRST="${CMD_TRIM#"$FIRST_TOK"}"
      REST_TRIM="${REST_AFTER_FIRST#"${REST_AFTER_FIRST%%[![:space:]]*}"}"
      SECOND_TOK="${REST_TRIM%% *}"
      if [ "$FIRST_TOK" = "git" ]; then
        case "$SECOND_TOK" in
          status|log|show|diff|stash)
            # Skip snapshot — read-only or stash-management subcommand.
            exit 0
            ;;
        esac
      fi
    fi
  fi
fi
# --- end R8-008 self-filter --------------------------------------------

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

# --- R16-602S: task_start_sha persistence ------------------------------
# Capture the HEAD SHA at task entry and persist to a per-task path so
# executor (R-602) and critic (R-603) can read a single canonical source
# for "what was the repo state at task start?" Path convention per
# IMP-001 plan: .apex/phases/<phase>/<task_id>/task_start_sha. Per
# IMP-001 insight 8: keep the SHA capture as a separate write, not
# coupled to the stash-SHA path. Worktree-safe via `git -C "$REPO_ROOT"`.
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -n "$REPO_ROOT" ]; then
  task_start_sha=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "")
  CURRENT_PHASE=""
  if [ -f .apex/STATE.json ] && command -v jq >/dev/null 2>&1; then
    CURRENT_PHASE=$(jq -r '.current_phase // empty' .apex/STATE.json 2>/dev/null || echo "")
  fi
  [ -z "$CURRENT_PHASE" ] && CURRENT_PHASE="unknown"
  TASK_STATE_DIR=".apex/phases/${CURRENT_PHASE}/${TASK_ID}"
  mkdir -p "$TASK_STATE_DIR" 2>/dev/null || true
  if [ -d "$TASK_STATE_DIR" ]; then
    printf '%s' "$task_start_sha" > "$TASK_STATE_DIR/task_start_sha" 2>/dev/null || true
  fi
fi
# --- end R16-602S ------------------------------------------------------

# --- Campaign B B2.5: pre-task claims capture (GAP-7 closure) ----------
# Read the task's expected files[] and done_criteria[] from PLAN_META.json
# at task entry, freeze them into .apex/pre-task-claims/<task-id>.json,
# and emit a pre_task_claim event. critic STEP 0/1 can diff expected vs
# delivered at task close to catch scope-evasion AND scope-creep.
#
# Spec anchor: audit-trail-review/EXPERIMENT-PROTOCOL.md §5.3 (event
# types `pre_task_claim` + `pre_task_claim_diff`) + AC-11 (binding
# hard-FAIL — every Task() invocation in B5 must correspond to a
# pre_task_claim entry).
#
# Skip path: TASK_ID="unknown" (no -id arg passed) → no claim. The hook
# is invoked by Claude Code's PreToolUse Bash matcher (no task_id
# argument) AND by /apex:next via `bash pre-task-snapshot.sh $TASK_ID`
# (with the id). Only the named invocation triggers a claim.
if [ "$TASK_ID" != "unknown" ] && [ -n "$REPO_ROOT" ] && command -v jq >/dev/null 2>&1; then
  PLAN_META=".apex/phases/${CURRENT_PHASE}/PLAN_META.json"
  if [ -f "$PLAN_META" ]; then
    CLAIMS_DIR=".apex/pre-task-claims"
    mkdir -p "$CLAIMS_DIR" 2>/dev/null || true
    CLAIM_FILE="${CLAIMS_DIR}/${TASK_ID}.json"
    NOW_ISO=$(date -u +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)
    # Extract the matching task. Atomic via tmp+mv so a partial write
    # never leaves an unparseable claim file behind.
    TMP_CLAIM="${CLAIM_FILE}.tmp.$$"
    if jq --arg id "$TASK_ID" --arg phase "$CURRENT_PHASE" --arg ts "$NOW_ISO" \
        '
        (.tasks // []) | map(select(.id == $id)) | .[0] // null
        | if . == null
          then {task_id:$id, phase:$phase, expected_files:[], expected_done_criteria:[], recorded_at:$ts, source:"task_not_in_plan_meta"}
          else {
            task_id:$id,
            phase:$phase,
            expected_files:(.files // []),
            expected_done_criteria:(.done_criteria // []),
            verify_commands:(.verify_commands // []),
            recorded_at:$ts,
            source:"plan_meta"
          }
          end
        ' "$PLAN_META" > "$TMP_CLAIM" 2>/dev/null; then
      mv "$TMP_CLAIM" "$CLAIM_FILE" 2>/dev/null
      # Emit pre_task_claim event with the same data (denormalised for
      # easy event-log scanning).
      EFILES=$(jq -c '.expected_files // []' "$CLAIM_FILE" 2>/dev/null)
      EDONE=$(jq -c '.expected_done_criteria // []' "$CLAIM_FILE" 2>/dev/null)
      # _emit_apex_event treats every k/v as a string — pass JSON arrays
      # as their canonical JSON-stringified form so consumers can parse.
      _emit_apex_event "pre_task_claim" .apex \
        task_id "$TASK_ID" \
        phase "$CURRENT_PHASE" \
        expected_files "${EFILES:-[]}" \
        expected_done_criteria "${EDONE:-[]}" \
        recorded_at "$NOW_ISO"
    else
      rm -f "$TMP_CLAIM"
    fi
  fi
fi
# --- end Campaign B B2.5 -----------------------------------------------

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
STORE_ERR=$(git stash store -m "$STASH_MSG" "$STASH_SHA" 2>&1)

# FILESYSTEM-LEVEL VERIFICATION — matches critic.md rule.
# Don't trust $? alone; confirm the stash is actually in the list.
if git stash list | grep -qF "$STASH_MSG"; then
  update_state_stash "$STASH_MSG"
  echo "✅ PRE-TASK SNAPSHOT: Saved for task $TASK_ID"
  echo "   Rollback: git reset --hard HEAD && git stash apply \"stash^{/$STASH_MSG}\""

  # ORPHAN BRANCH COMMIT — persistent snapshot (non-blocking)
  # If orphan branch exists, commit the stash tree to it for browseable history.
  # Failure here does NOT affect the stash snapshot or exit code.
  if git rev-parse --verify apex/snapshots >/dev/null 2>&1; then
    TREE=$(git rev-parse "${STASH_SHA}^{tree}" 2>/dev/null)
    if [ -n "$TREE" ]; then
      PARENT=$(git rev-parse apex/snapshots 2>/dev/null)
      ORPHAN_SHA=$(git commit-tree "$TREE" -p "$PARENT" -m "snapshot: ${TASK_ID} ${TIMESTAMP}" 2>/dev/null)
      if [ -n "$ORPHAN_SHA" ]; then
        git update-ref refs/heads/apex/snapshots "$ORPHAN_SHA" 2>/dev/null
        echo "   Persistent snapshot: apex/snapshots ($(echo "$ORPHAN_SHA" | cut -c1-8))"
      fi
    fi
  fi

  exit 0
else
  # The stash did not land — fail loud so the caller can decide.
  update_state_stash_null
  echo "🚫 PRE-TASK SNAPSHOT: stash creation unverified at filesystem level" >&2
  echo "   task=$TASK_ID msg=$STASH_MSG sha=$STASH_SHA" >&2
  [ -n "$STORE_ERR" ] && echo "   git error: $STORE_ERR" >&2
  echo "   Aborting task to preserve data integrity." >&2
  exit 2
fi
