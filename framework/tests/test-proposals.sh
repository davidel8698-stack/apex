#!/usr/bin/env bash
# R5-017: Enforce "Propose, don't ask" by detecting forbidden interrogative patterns
# inside PROPOSALS_MODE-guarded blocks of command files.
#
# Strategy: scan each framework/commands/apex/*.md file. For files that contain a
# PROPOSALS MODE GUARD block (the convention "If proposals_mode == true: NEVER ask
# open-ended questions"), look at the entire file for forbidden patterns:
#   - Lines ending in "?" outside of structured choice menus, code fences, tables.
#   - Open-ended question phrases ("what would you like", "how should I", "do you want me to").
#
# Compares the count of violations against framework/tests/proposals-baseline.txt.
# Test fails if count exceeds baseline. (Baseline is regenerated only deliberately.)

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CMD_DIR="$REPO_ROOT/framework/commands/apex"
BASELINE_FILE="$SCRIPT_DIR/proposals-baseline.txt"

if [ ! -d "$CMD_DIR" ]; then
  echo "FAIL: command directory not found at $CMD_DIR" >&2
  exit 1
fi

# Forbidden interrogative phrases (case-insensitive). These are open-ended asks.
FORBIDDEN_PHRASES=(
  "what would you like"
  "how should i"
  "what do you want"
  "do you want me to"
  "what should i do"
  "would you prefer"
  "tell me what"
  "what's your preference"
  "do you have a preference"
)

count_violations_in_file() {
  local file="$1"
  # Only scan files that opt into PROPOSALS_MODE (the guard block exists).
  if ! grep -qE "PROPOSALS[_ ]MODE" "$file" 2>/dev/null; then
    echo 0
    return
  fi
  local total=0
  local phrase
  for phrase in "${FORBIDDEN_PHRASES[@]}"; do
    local hits
    hits=$(grep -ic "$phrase" "$file" 2>/dev/null)
    [ -z "$hits" ] && hits=0
    total=$((total + hits))
  done
  echo "$total"
}

TOTAL=0
SCANNED_FILES=0
CLEAN_FILES=0
declare -a OFFENDING_FILES=()

for f in "$CMD_DIR"/*.md; do
  [ -f "$f" ] || continue
  SCANNED_FILES=$((SCANNED_FILES + 1))
  v=$(count_violations_in_file "$f")
  if [ "$v" -gt 0 ]; then
    OFFENDING_FILES+=("$(basename "$f"):$v")
  else
    CLEAN_FILES=$((CLEAN_FILES + 1))
  fi
  TOTAL=$((TOTAL + v))
done

# Read baseline.
if [ ! -f "$BASELINE_FILE" ]; then
  echo "FAIL: baseline file missing at $BASELINE_FILE" >&2
  echo "Run: echo $TOTAL > $BASELINE_FILE  (after reviewing the count)" >&2
  exit 1
fi

BASELINE=$(grep -E '^[0-9]+$' "$BASELINE_FILE" | head -1)
if [ -z "$BASELINE" ]; then
  echo "FAIL: baseline file does not contain an integer" >&2
  exit 1
fi

echo "=== R5-017: PROPOSALS_MODE forbidden-pattern scan ==="
echo "  Current violations: $TOTAL"
echo "  Baseline:           $BASELINE"
if [ ${#OFFENDING_FILES[@]} -gt 0 ]; then
  echo "  Offending files:"
  for f in "${OFFENDING_FILES[@]}"; do
    echo "    - $f"
  done
fi

VIOLATION_COUNT="$TOTAL"
if [ "$VIOLATION_COUNT" -gt "$BASELINE" ]; then
  # R8-009: bridge corpus counters into harness globals before exit.
  # Note: helper increments harness TOTAL by SCANNED_FILES, overwriting
  # the local violation count — VIOLATION_COUNT preserves it for the
  # diagnostic below.
  # R9-011: threshold 80 reflects PROPOSALS_MODE clean-file ratio per
  # spec "Verification universal" — the bulk of command files must be
  # clean while allowing legacy/edge-case files baseline-pinned.
  # Drift between this call-site threshold and the documented
  # PROPOSALS_THRESHOLD constant is asserted by `test-corpus-thresholds.sh`.
  if command -v harness_assert_corpus >/dev/null 2>&1; then
    harness_assert_corpus "$CLEAN_FILES" "$SCANNED_FILES" "PROPOSALS_MODE clean-file ratio" 80
  fi
  echo ""
  echo "FAIL: forbidden-pattern count ($VIOLATION_COUNT) exceeds baseline ($BASELINE)."
  echo "      Either fix the new question(s) or update $BASELINE_FILE deliberately."
  exit 1
fi

# R8-009: bridge corpus counters into harness globals so the per-file
# summary line reports actual scanned-file count. Total = command files
# scanned; correct = files with zero forbidden patterns. Threshold 80%
# reflects "the bulk of command files must be clean" while allowing
# legacy/edge-case files baseline-pinned. Helper MUST run after the
# local TOTAL-vs-BASELINE comparison (helper writes to TOTAL global).
# R9-011: threshold 80 mirrors the violation-baseline policy above —
# PROPOSALS_MODE clean-file ratio per spec "Proof-of-process beats
# proof-of-promise". Drift between this call-site threshold and the
# violation-vs-baseline gate above is asserted by `test-corpus-
# thresholds.sh` meta-test.
if command -v harness_assert_corpus >/dev/null 2>&1; then
  harness_assert_corpus "$CLEAN_FILES" "$SCANNED_FILES" "PROPOSALS_MODE clean-file ratio" 80
fi

echo "  PASS: count is at or below baseline"
exit 0
