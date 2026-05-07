#!/usr/bin/env bash
# R9-013: EXIT-trap collision meta-test.
#
# Spec anchor:
#   "Fail-loud, never fail-silent."
#
# The runner (framework/scripts/self-test.sh) installs an EXIT trap
# inside every per-test subshell to call `harness_export_counters` —
# this is what writes the per-file PASS/FAIL/TOTAL/SKIP sidecar that
# the parent reads back. Bash's EXIT-trap semantics overwrite (do NOT
# chain), so any user EXIT trap inside a test file SILENTLY clobbers
# the runner's trap and zeros out per-file counters.
#
# This meta-test scans `framework/tests/test-*.sh` for any line
# beginning with optional whitespace + `trap` + arbitrary args + the
# `EXIT` signal. For each match, the file MUST contain an explicit
# opt-in comment of the form `# explicit-exit-trap:` (case-insensitive)
# justifying the override. Any unjustified trap fails the meta-test
# loudly.
#
# The whitelist is comment-driven (NOT filename-driven) so future
# tests that need an explicit trap can opt in via the same comment
# without editing this file.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR"

PASS=0
FAIL=0
ok()   { echo "  ✅ $1"; PASS=$((PASS+1)); }
nope() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }

echo "=== R9-013: EXIT-trap collision meta-test ==="

# 1. Sanity: this meta-test itself MUST NOT install an EXIT trap at
#    file scope (heredoc bodies that contain `trap ... EXIT` as fixture
#    payload are exempt, because they are inside `<<'FIX' ... FIX`
#    blocks and never execute as the meta-test's own traps).
#    explicit-exit-trap: this self-check tolerates fixture heredocs
#    that contain the literal trap statement; the scan ignores them by
#    excluding lines inside any heredoc named FIX.
SELF="$SCRIPT_DIR/test-harness-exit-trap.sh"
SELF_HITS=$(awk '
  /^FIX$/        { in_heredoc=0; next }
  /<<.FIX.$|<<FIX$/ { in_heredoc=1; next }
  in_heredoc==0 && /^[[:space:]]*trap[[:space:]].*[[:space:]]EXIT([[:space:]]|$)/ { print }
' "$SELF" | wc -l)
if [ "$SELF_HITS" -eq 0 ]; then
  ok "0: meta-test has no executable EXIT trap of its own"
else
  nope "0: meta-test contains $SELF_HITS executable EXIT trap line(s) (would self-poison)"
fi

# 2. Scan every test-*.sh sibling for actual `trap ... EXIT` lines.
#    Match the *literal* trap statement form, not commentary.
#    Anchor: line begins with optional whitespace + "trap" + space.
SCAN_HITS=0
UNJUSTIFIED=0
for f in "$TEST_DIR"/test-*.sh; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  # Skip self.
  [ "$base" = "test-harness-exit-trap.sh" ] && continue
  if grep -qE '^[[:space:]]*trap[[:space:]].*[[:space:]]EXIT([[:space:]]|$)' "$f"; then
    SCAN_HITS=$((SCAN_HITS + 1))
    # Whitelist: file must contain the explicit opt-in comment.
    if grep -qiE 'explicit-exit-trap[[:space:]]*:' "$f"; then
      ok "trap-allowed: $base declares EXIT trap with explicit-exit-trap: opt-in comment"
    else
      nope "trap-violation: $base declares EXIT trap WITHOUT 'explicit-exit-trap:' opt-in comment"
      UNJUSTIFIED=$((UNJUSTIFIED + 1))
    fi
  fi
done

if [ "$SCAN_HITS" -eq 0 ]; then
  ok "1: no test-*.sh file declares its own EXIT trap (clean baseline)"
fi

# 3. Sanity: the runner's own EXIT-trap install is preserved.
RUNNER="$(cd "$TEST_DIR/../scripts" && pwd)/self-test.sh"
if [ -f "$RUNNER" ] && grep -qE "trap[[:space:]]+'harness_export_counters'[[:space:]]+EXIT" "$RUNNER"; then
  ok "2: runner self-test.sh installs harness_export_counters EXIT trap"
else
  nope "2: runner EXIT trap missing from $RUNNER (would silently break per-file counter export)"
fi

# 4. The whitelist MUST detect the explicit-comment form (positive
#    case verified by stamping a tmp fixture and re-running our scan
#    logic against it inline).
TMP_FIX=$(mktemp)
cat > "$TMP_FIX" <<'FIX'
#!/usr/bin/env bash
# explicit-exit-trap: stamped fixture for R9-013 meta-test self-check.
trap 'echo done' EXIT
echo "fixture body"
FIX
if grep -qE '^[[:space:]]*trap[[:space:]].*[[:space:]]EXIT([[:space:]]|$)' "$TMP_FIX" && \
   grep -qiE 'explicit-exit-trap[[:space:]]*:' "$TMP_FIX"; then
  ok "3: positive fixture (with opt-in comment) is recognised by scanner"
else
  nope "3: positive fixture not recognised — scanner regex broken"
fi
rm -f "$TMP_FIX"

# 5. Synthetic regression on a NEGATIVE fixture (no opt-in comment).
TMP_NEG=$(mktemp)
cat > "$TMP_NEG" <<'FIX'
#!/usr/bin/env bash
trap 'echo bye' EXIT
echo "fixture body"
FIX
if grep -qE '^[[:space:]]*trap[[:space:]].*[[:space:]]EXIT([[:space:]]|$)' "$TMP_NEG" && \
   ! grep -qiE 'explicit-exit-trap[[:space:]]*:' "$TMP_NEG"; then
  ok "4: negative fixture (no opt-in comment) would be flagged"
else
  nope "4: negative fixture not flagged — scanner regex permissive"
fi
rm -f "$TMP_NEG"

echo ""
echo "=== Results: PASS=$PASS FAIL=$FAIL ==="
# R9-002: bridge private counters into harness globals once.
if declare -F harness_assert_local >/dev/null 2>&1; then
  harness_assert_local "$PASS" "$FAIL" "test-harness-exit-trap"
fi
if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
exit 0
