#!/usr/bin/env bash
# R8-008: pre-task-snapshot self-filter test.
#
# Spec anchors:
#   "Information boundaries ARE the architecture."
#   pre-task-snapshot.sh stated purpose ("git stash snapshot before
#   task execution — enables per-task rollback").
#
# Three cases:
#   1. stdin envelope with `git status` → no snapshot, exit 0,
#      `git stash list` count does not gain a new apex-snapshot-* entry.
#   2. stdin envelope with `npm run build` → snapshot fires, the
#      stash list gains an apex-snapshot-* entry.
#   3. no stdin envelope (standalone CLI invocation) → snapshot fires
#      (preserves the pre-R8-008 standalone contract).
#
# All three cases run inside a freshly-initialized git repo sandbox
# with a dirty working tree (otherwise `git stash create` finds nothing
# to snapshot and exits cleanly without storing — which is correct
# behavior but not what we are validating here).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/framework/hooks/pre-task-snapshot.sh"

PASS=0
FAIL=0
SKIP=0
ok()   { echo "  ✅ $1"; PASS=$((PASS+1)); }
nope() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }
skip() { echo "  ⏭  $1"; SKIP=$((SKIP+1)); }

echo "=== R8-008: pre-task-snapshot self-filter test ==="

# 0. Sanity.
if [ ! -f "$HOOK" ]; then
  nope "0: pre-task-snapshot.sh missing at $HOOK"
  echo "$PASS/$((PASS+FAIL)) passed (skipped: $SKIP)"
  exit 1
fi
ok "0: pre-task-snapshot.sh exists"

if ! command -v jq >/dev/null 2>&1; then
  skip "1-3: jq not on PATH — self-filter requires jq for envelope parse"
  echo "$PASS/$((PASS+FAIL)) passed (skipped: $SKIP)"
  exit 0
fi

# 0a. Anchor checks — the self-filter literal is in place.
if grep -qE 'tool_input.command' "$HOOK"; then
  ok "0a: hook references tool_input.command (self-filter envelope read)"
else
  nope "0a: hook missing tool_input.command reference"
fi

# Build a sandbox git repo with a dirty working tree so `git stash
# create` has content to snapshot.
SANDBOX=$(mktemp -d 2>/dev/null || mktemp -d -t apex-snap)
cleanup() { rm -rf "$SANDBOX"; }

(
  cd "$SANDBOX"
  git init -q 2>/dev/null
  git config user.email "test@apex" 2>/dev/null
  git config user.name "APEX" 2>/dev/null
  echo "init" > init.txt
  git add . >/dev/null 2>&1
  git commit -qm "init" 2>/dev/null
  # Dirty working tree so stash create has content.
  echo "dirty" >> init.txt
)

count_snapshots() {
  ( cd "$SANDBOX" && git stash list 2>/dev/null | grep -c 'apex-snapshot-' )
}

# --- Case 1: stdin envelope with `git status` → SKIP snapshot --------
COUNT_BEFORE=$(count_snapshots)
(
  cd "$SANDBOX"
  echo '{"tool_input":{"command":"git status -s"}}' | bash "$HOOK" task-1 >/dev/null 2>&1
)
RC=$?
COUNT_AFTER=$(count_snapshots)
DELTA=$((COUNT_AFTER - COUNT_BEFORE))

if [ "$RC" -eq 0 ]; then
  ok "1a: hook exit 0 on git-status envelope (filter fired)"
else
  nope "1a: hook exit $RC on git-status envelope (expected 0)"
fi
if [ "$DELTA" -eq 0 ]; then
  ok "1b: stash list unchanged for git-status envelope ($DELTA new snapshot)"
else
  nope "1b: stash list gained $DELTA snapshot for git-status envelope (expected 0)"
fi

# --- Case 2: stdin envelope with `npm run build` → snapshot fires ---
COUNT_BEFORE=$(count_snapshots)
(
  cd "$SANDBOX"
  # Re-dirty the tree so the previous case (if any side-effect) does
  # not leave us with a clean tree.
  date +%s >> init.txt
  echo '{"tool_input":{"command":"npm run build"}}' | bash "$HOOK" task-2 >/dev/null 2>&1
)
RC=$?
COUNT_AFTER=$(count_snapshots)
DELTA=$((COUNT_AFTER - COUNT_BEFORE))

if [ "$RC" -eq 0 ]; then
  ok "2a: hook exit 0 on npm-build envelope (snapshot path)"
else
  nope "2a: hook exit $RC on npm-build envelope (expected 0)"
fi
if [ "$DELTA" -ge 1 ]; then
  ok "2b: stash list gained snapshot for npm-build envelope ($DELTA new entries)"
else
  nope "2b: stash list did NOT gain snapshot for npm-build envelope (delta=$DELTA)"
fi

# --- Case 3: no stdin envelope (CLI invocation) → snapshot fires ----
COUNT_BEFORE=$(count_snapshots)
(
  cd "$SANDBOX"
  date +%s >> init.txt
  # No stdin redirection — hook must default to firing the snapshot.
  bash "$HOOK" task-3 </dev/null >/dev/null 2>&1
)
RC=$?
COUNT_AFTER=$(count_snapshots)
DELTA=$((COUNT_AFTER - COUNT_BEFORE))

if [ "$RC" -eq 0 ]; then
  ok "3a: hook exit 0 on standalone CLI invocation"
else
  nope "3a: hook exit $RC on standalone CLI invocation (expected 0)"
fi
if [ "$DELTA" -ge 1 ]; then
  ok "3b: stash list gained snapshot for standalone CLI invocation ($DELTA new entries)"
else
  nope "3b: stash list did NOT gain snapshot for standalone CLI invocation (delta=$DELTA)"
fi

# --- Case 4: stdin envelope with `git stash push x` → SKIP snapshot -
COUNT_BEFORE=$(count_snapshots)
(
  cd "$SANDBOX"
  date +%s >> init.txt
  echo '{"tool_input":{"command":"git stash push -m wip"}}' | bash "$HOOK" task-4 >/dev/null 2>&1
)
RC=$?
COUNT_AFTER=$(count_snapshots)
DELTA=$((COUNT_AFTER - COUNT_BEFORE))

if [ "$RC" -eq 0 ]; then
  ok "4a: hook exit 0 on git-stash envelope (filter fired)"
else
  nope "4a: hook exit $RC on git-stash envelope (expected 0)"
fi
if [ "$DELTA" -eq 0 ]; then
  ok "4b: stash list unchanged for git-stash envelope (auto-snapshot suppressed)"
else
  nope "4b: stash list gained $DELTA snapshot for git-stash envelope (expected 0)"
fi

cleanup

# Bridge to harness globals so per-file summary reflects the actual
# assertion count (close the F-009 family on this file specifically).
if declare -F harness_assert_corpus >/dev/null 2>&1; then
  TOT=$((PASS + FAIL))
  harness_assert_corpus "$PASS" "$TOT" "pre-task-snapshot self-filter" 100
fi

TOTAL=$((PASS+FAIL))
echo ""
echo "$PASS/$TOTAL passed (skipped: $SKIP)"
[ "$FAIL" -eq 0 ]
