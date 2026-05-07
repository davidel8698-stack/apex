#!/usr/bin/env bash
# R7-003: sync-to-claude.sh delivers every file under framework/docs/ to
# ~/.claude/docs/ via a tree walk (no per-doc copy_file anchor required).
#
# Asserts the total-delivery contract surfaced by F-003 in R7:
#   1. The script names framework/docs as a copy_tree source.
#   2. Dry-run output mentions at least one file under docs/ for each
#      file in framework/docs/ (state-derived count, no literals).
#   3. A sandboxed sync (CLAUDE_ROOT=<tmp>) produces a docs/ directory
#      whose file-count equals ls framework/docs/ | wc -l.
#
# Source-of-truth: ls framework/docs/ — adding a new doc to the source
# tree automatically adds it to the assertion without test edits.
#
# Spec anchors:
#   "Information boundaries ARE the architecture."
#   Implicit framework->install delivery contract (R7 audit F-003).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SYNC_SH="$REPO_ROOT/framework/scripts/sync-to-claude.sh"
DOCS_DIR="$REPO_ROOT/framework/docs"

PASS=0
FAIL=0

ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
nope() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== R7-003: sync-to-claude.sh framework/docs/ tree-walk delivery ==="

# Pre-flight: required artifacts exist.
if [ ! -f "$SYNC_SH" ]; then
  nope "C-1: sync-to-claude.sh not found at $SYNC_SH"
  echo "$PASS/$((PASS+FAIL)) passed"
  exit 1
fi
ok "C-1: sync-to-claude.sh exists"

if [ ! -d "$DOCS_DIR" ]; then
  nope "C-2: framework/docs/ directory not found at $DOCS_DIR"
  echo "$PASS/$((PASS+FAIL)) passed"
  exit 1
fi
ok "C-2: framework/docs/ directory exists"

# C-3: sync script names framework/docs as a copy_tree source.
if grep -nE 'copy_tree.*docs' "$SYNC_SH" | grep -q 'framework.*docs\|FRAMEWORK_ROOT.*docs\|/docs"'; then
  ok "C-3: sync-to-claude.sh declares copy_tree for framework/docs"
else
  nope "C-3: sync-to-claude.sh missing copy_tree for framework/docs"
fi

# State-derived source count (file-count, not directory count).
DOC_FILE_COUNT=$(find "$DOCS_DIR" -type f | wc -l | tr -d ' ')

# C-4: dry-run output references docs/ at least once per source file.
# DRY_RUN of copy_tree iterates find -type f and prints one line per
# file via copy_file's dry-run branch.
DRY_OUT=$(bash "$SYNC_SH" --dry-run 2>&1 || true)
DOCS_LINES=$(printf '%s\n' "$DRY_OUT" | grep -E 'docs/' | wc -l | tr -d ' ')
if [ "$DOCS_LINES" -ge "$DOC_FILE_COUNT" ]; then
  ok "C-4: dry-run mentions docs/ at least $DOC_FILE_COUNT times (got $DOCS_LINES; source-derived)"
else
  nope "C-4: dry-run mentioned docs/ only $DOCS_LINES times (expected >= $DOC_FILE_COUNT from ls framework/docs/)"
fi

# C-5: sandboxed live sync produces target docs/ with equal file-count.
# We override CLAUDE_ROOT and HOME so sync-to-claude.sh writes only into
# the sandbox; --skip-settings avoids any settings.json side-effect.
SANDBOX="$(mktemp -d)"
TARGET="$SANDBOX/claude"
mkdir -p "$TARGET"
SANDBOX_OUT=$(HOME="$SANDBOX" bash "$SYNC_SH" --skip-settings 2>&1 || true)
SYNC_RC=$?
TARGET_DOCS="$SANDBOX/.claude/docs"
# Some shells/environments treat HOME inside the script as $HOME literal;
# the script computes CLAUDE_ROOT="$HOME/.claude". Verify post-sync.
if [ ! -d "$TARGET_DOCS" ]; then
  # Fall back to inspecting any .claude that materialised under SANDBOX.
  TARGET_DOCS=$(find "$SANDBOX" -type d -name docs -path '*/.claude/docs' -print -quit 2>/dev/null)
fi
if [ -d "$TARGET_DOCS" ]; then
  TARGET_COUNT=$(find "$TARGET_DOCS" -type f | wc -l | tr -d ' ')
  if [ "$TARGET_COUNT" -eq "$DOC_FILE_COUNT" ]; then
    ok "C-5: sandboxed sync delivered $TARGET_COUNT files to <target>/docs/ (equals ls framework/docs/)"
  else
    nope "C-5: sandboxed sync delivered $TARGET_COUNT files (expected $DOC_FILE_COUNT)"
  fi
else
  nope "C-5: sandboxed sync did not create docs/ under sandbox HOME=$SANDBOX (sync_rc=$SYNC_RC)"
fi
rm -rf "$SANDBOX"

# C-6: every file in framework/docs/ has the same basename in the sandboxed
# target — proves the walk is total, not partial. We re-run the sandbox
# capture only if the prior sandbox actually produced a docs/ tree.
SANDBOX2="$(mktemp -d)"
HOME="$SANDBOX2" bash "$SYNC_SH" --skip-settings >/dev/null 2>&1 || true
TARGET_DOCS2="$SANDBOX2/.claude/docs"
if [ -d "$TARGET_DOCS2" ]; then
  MISSING=0
  while IFS= read -r src_file; do
    bn=$(basename "$src_file")
    if [ ! -f "$TARGET_DOCS2/$bn" ]; then
      echo "      missing: $bn (source $src_file not delivered)"
      MISSING=$((MISSING+1))
    fi
  done < <(find "$DOCS_DIR" -maxdepth 1 -type f)
  if [ "$MISSING" -eq 0 ]; then
    ok "C-6: every framework/docs/ file landed in the sandboxed target/docs/"
  else
    nope "C-6: $MISSING file(s) missing in the sandboxed target"
  fi
else
  nope "C-6: sandbox replay produced no target/docs/ to inspect"
fi
rm -rf "$SANDBOX2"

TOTAL=$((PASS+FAIL))
echo ""
echo "$PASS/$TOTAL passed"
[ "$FAIL" -eq 0 ]
