# R5-015: Plain-Language Mapping enforcement
# tag: slow
# (R-020-003: empirically-confirmed long pole; `run-all.sh --quick` skips it.)
# Greps user-facing sections of command files for known bare-jargon
# (jargon NOT followed by an opening parenthesis on the same line) and
# reports violations.
#
# Spec anchor: "משתמש לא-טכני יכול להצליח איתה בסשן ובשעה הראשונה"
# Spec anchor: "User-facing complexity is a 4-button menu, not a 14-toggle dashboard."
# Mapping doc: framework/docs/PLAIN-LANGUAGE-MAPPING.md
#
# Behavior: prints a prioritized violation list. Exits 0 on baseline
# (informational mode — see PLAIN-LANGUAGE-MAPPING.md "Test" section).
# This is a regression-watch test: the goal is that the count of
# bare-jargon hits does not increase after the R5-015 sweep is in place.

# Resolve framework root for source-of-truth checks BEFORE the harness changes cwd.
# The mapping doc and command source files live under framework/, not under the
# installed ~/.claude/ tree; the test asserts on framework/ to keep the contract
# anchored to the source of truth.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MAPPING_DOC="$REPO_ROOT/framework/docs/PLAIN-LANGUAGE-MAPPING.md"
FW_COMMANDS="$REPO_ROOT/framework/commands/apex"

# R4-004: self-source harness if run standalone
if [ -z "${COMMANDS_DIR:-}" ]; then
  source "$SCRIPT_DIR/_harness.sh"
  harness_setup
  STANDALONE=1
fi

echo "  R5-015: plain-language mapping (informational)"

# Test 1: mapping doc exists and has at least 10 mappings
if [ -f "$MAPPING_DOC" ]; then
  MAPPING_COUNT=$(grep -cE '^\| `?[A-Za-z]' "$MAPPING_DOC" 2>/dev/null || echo 0)
  TOTAL=$((TOTAL + 1))
  if [ "$MAPPING_COUNT" -ge 10 ]; then
    echo "  ✅ R5-015-a: PLAIN-LANGUAGE-MAPPING.md has $MAPPING_COUNT mappings (>=10)"
    PASS=$((PASS + 1))
  else
    echo "  ❌ R5-015-a: PLAIN-LANGUAGE-MAPPING.md has only $MAPPING_COUNT mappings (need >=10)"
    FAIL=$((FAIL + 1))
  fi
else
  TOTAL=$((TOTAL + 1))
  echo "  ❌ R5-015-a: PLAIN-LANGUAGE-MAPPING.md not found at $MAPPING_DOC"
  FAIL=$((FAIL + 1))
fi

# Test 2: bare-jargon scan (informational — produces a count, not a hard fail)
# JARGON_TERMS: each term must appear with an opening "(" on the same line
# in user-facing markdown to be considered correctly translated. Hits where
# the term appears without a paren-form on the same line are violations.
JARGON_TERMS="Nyquist Validation Layer|TDAD\b|AST-KB|Phantom Verification|phantom check"

if [ -d "$FW_COMMANDS" ]; then
  TOTAL_HITS=0
  VIOLATIONS=""
  # R6-015: extended scope from the R5-015 starter set (6 files) to every
  # user-facing command file (state-derived count from
  # `ls framework/commands/apex/*.md`). Excluded:
  #   - Underscore-prefixed helpers (_debate.md, _roundtable.md): internal
  #     orchestration primitives invoked by other commands; not surfaced
  #     directly to users. Intentionally technical.
  # All other commands are in scope, including the 6 originally-scanned
  # files (preservation contract: still scanned, still pass).
  SCAN_COUNT=0
  for FILE in "$FW_COMMANDS"/*.md; do
    [ -f "$FILE" ] || continue
    base=$(basename "$FILE")
    case "$base" in
      _*) continue ;;  # exclude underscore-prefixed helpers
    esac
    SCAN_COUNT=$((SCAN_COUNT + 1))
    # Find lines containing any jargon term.
    while IFS= read -r line; do
      # Strip leading line number/context. Skip empty.
      [ -z "$line" ] && continue
      # If the line ALSO contains "(" then assume parens-form is present.
      if printf '%s' "$line" | grep -qE "$JARGON_TERMS"; then
        if ! printf '%s' "$line" | grep -q "("; then
          TOTAL_HITS=$((TOTAL_HITS + 1))
          VIOLATIONS="$VIOLATIONS\n  $base: $(printf '%s' "$line" | head -c 120)"
        fi
      fi
    done < "$FILE"
  done

  TOTAL=$((TOTAL + 1))
  # R6-015 ratchet: budget lowered from 5 to 3. The lower bound is set by
  # what the codebase passes today after the R5-015 sweep + R6-006 / R6-016
  # numbered-proposal fixes + the post-R6-015 jargon translations in
  # fast.md / quick.md. Future rounds ratchet further.
  # R7 target: BUDGET=1
  # R8 target: BUDGET=0
  BUDGET=3
  if [ "$TOTAL_HITS" -le "$BUDGET" ]; then
    echo "  ✅ R5-015-b: bare-jargon hits in $SCAN_COUNT user-facing command files = $TOTAL_HITS (budget: $BUDGET)"
    PASS=$((PASS + 1))
  else
    echo "  ❌ R5-015-b: bare-jargon hits = $TOTAL_HITS (budget: $BUDGET)"
    printf '%b\n' "$VIOLATIONS"
    FAIL=$((FAIL + 1))
  fi
else
  TOTAL=$((TOTAL + 1))
  echo "  ⚠️ R5-015-b SKIP: $FW_COMMANDS not present"
fi

# Test 3: sweep-positive sentinels — paren-form is present in next.md.
# A correctly translated header places the technical term inside parens
# (either after or before the plain-language phrase). This test checks
# that "Wave 0" co-occurs with an opening paren on the same line in
# next.md, in either order.
TOTAL=$((TOTAL + 1))
NEXT_MD="$FW_COMMANDS/next.md"
if [ -f "$NEXT_MD" ] && grep -E 'Wave 0' "$NEXT_MD" 2>/dev/null | grep -q '(' ; then
  echo "  ✅ R5-015-c: next.md uses paren-form for Wave 0 (e.g., 'Step 0 (Wave 0)')"
  PASS=$((PASS + 1))
else
  echo "  ❌ R5-015-c: next.md missing paren-form for Wave 0"
  FAIL=$((FAIL + 1))
fi

# R4-004: standalone-mode cleanup (only fires when this test file was invoked directly)
if [ "${STANDALONE:-0}" = "1" ]; then
  harness_teardown
  harness_report
fi
