#!/usr/bin/env bash
# R7-011: HOOK-CLASSIFICATION.md cardinality assertion.
#
# Spec anchor: "Proof-of-process beats proof-of-promise."
#
# Closes the third leg of the three-places contract for hooks (header
# in framework/hooks/<name>.sh, wiring in framework/settings.json,
# documentation in framework/HOOK-CLASSIFICATION.md). Asserts that the
# doc and the file system agree:
#
#   1. Every filename in `ls framework/hooks/` appears at least once
#      in the body of HOOK-CLASSIFICATION.md (existence check; the
#      preferred hard invariant — a missing filename is unambiguous
#      drift).
#   2. The unique count of hook filenames listed under the four
#      trigger-type tables (column "File") equals
#      `ls framework/hooks/ | wc -l`. The cardinality is computed by
#      extracting the first ` | `\``-delimited cell of every table row
#      whose first cell looks like a filename token; deduplicating
#      (tdad-index.sh is intentionally dual-listed).
#   3. The Total cell in the Category Totals table equals the same
#      file-system count.
#   4. The four v7.1 Auto-Continuity hooks each have at least one row
#      in the doc (regression sentinel for v7.1 specifically).
#
# State-derived: future additions to framework/hooks/ are caught
# automatically; the test does not hardcode a count.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOKS_DIR="$REPO_ROOT/framework/hooks"
DOC="$REPO_ROOT/framework/HOOK-CLASSIFICATION.md"

# R7-009: shared IO helpers (jq_lines for CRLF-safe read loops).
# shellcheck source=_test-utils.sh
[ -f "$SCRIPT_DIR/_test-utils.sh" ] && source "$SCRIPT_DIR/_test-utils.sh"

if [ ! -d "$HOOKS_DIR" ]; then
  echo "FAIL: hooks directory not found at $HOOKS_DIR" >&2
  exit 1
fi
if [ ! -f "$DOC" ]; then
  echo "FAIL: HOOK-CLASSIFICATION.md not found at $DOC" >&2
  exit 1
fi

PASS=0
FAIL=0

ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
nope() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== R7-011: HOOK-CLASSIFICATION.md cardinality ==="

# State-derived file count.
FS_COUNT=$(ls "$HOOKS_DIR" | wc -l | tr -d ' ')

# 1. Existence check — every hook filename appears at least once in the
#    doc body. This is the strongest invariant of the lot: a missing
#    filename is unambiguous drift, no parsing required.
MISSING=""
for f in "$HOOKS_DIR"/*; do
  name=$(basename "$f")
  if ! grep -qF "$name" "$DOC"; then
    MISSING="$MISSING $name"
  fi
done
if [ -z "$MISSING" ]; then
  ok "every filename in framework/hooks/ appears at least once in HOOK-CLASSIFICATION.md"
else
  nope "missing filenames in HOOK-CLASSIFICATION.md:$MISSING"
fi

# 2. Cardinality — count unique hook filenames in the doc's tables.
#    Anchor: lines starting with "| `" followed by a token containing
#    "." (filename). Extract the token between the first pair of
#    backticks, sort | uniq, and compare count.
DOC_UNIQUE_FILENAMES=$(grep -oE '^\| `[A-Za-z0-9_.-]+\.(sh|cjs|py)`' "$DOC" \
  | sed -E 's/^\| `//; s/`$//' \
  | sort -u)
DOC_UNIQUE_COUNT=$(printf '%s\n' "$DOC_UNIQUE_FILENAMES" | grep -c .)

if [ "$DOC_UNIQUE_COUNT" -eq "$FS_COUNT" ]; then
  ok "doc unique-filename count ($DOC_UNIQUE_COUNT) equals ls framework/hooks/ count ($FS_COUNT)"
else
  nope "cardinality drift: doc lists $DOC_UNIQUE_COUNT unique filenames but ls framework/hooks/ returns $FS_COUNT"
  echo "      (doc unique filenames:)"
  printf '%s\n' "$DOC_UNIQUE_FILENAMES" | sed 's/^/        /'
  echo "      (ls framework/hooks/ output:)"
  ls "$HOOKS_DIR" | sed 's/^/        /'
fi

# 3. Category Totals row matches the file-system count.
TOTAL_CELL=$(grep -oE '\| \*\*Total\*\* \| \*\*[0-9]+\*\*' "$DOC" \
  | grep -oE '[0-9]+' \
  | tail -1)
if [ -n "$TOTAL_CELL" ] && [ "$TOTAL_CELL" -eq "$FS_COUNT" ]; then
  ok "Category Totals row says $TOTAL_CELL (matches file-system count)"
else
  nope "Category Totals cell ('$TOTAL_CELL') does not match file-system count ($FS_COUNT)"
fi

# 4. v7.1 Auto-Continuity hooks named explicitly.
for v71 in memory-watchdog.sh session-auto-resume.sh turn-checkpoint.sh _require-platform-detect.sh; do
  if grep -qF "$v71" "$DOC"; then
    ok "v7.1 hook listed: $v71"
  else
    nope "v7.1 hook missing from doc: $v71"
  fi
done

# 5. The "Total files: 42" literal-only form must be gone (state-derived
#    phrasing required).
if grep -qE 'Total files:\s*42$' "$DOC"; then
  nope "doc still uses literal 'Total files: 42' (drift-prone form)"
else
  ok "literal 'Total files: 42' form is gone"
fi

TOTAL=$((PASS+FAIL))
echo ""
echo "Results: $PASS passed, $FAIL failed (of $TOTAL)"
exit "$FAIL"
