#!/usr/bin/env bash
# R9-011: corpus-threshold anti-drift meta-test.
#
# Spec anchors:
#   "Verification universal, not TDD universal."
#   "Proof-of-process beats proof-of-promise."
#
# Asserts that each of the three corpus tests (test-decision-mode.sh,
# test-proposals.sh, test-roundtable-classifier.sh) has a
# `harness_assert_corpus` call-site threshold that MATCHES the local
# gate threshold encoded in the same file. Drift between the gate and
# the call-site threshold is silent today; this meta-test makes it
# loud.
#
# The anti-drift mapping (state-derived from the source files):
#
#   test-decision-mode.sh        gate: `[ "$PCT" -lt 90 ]`
#                                call: `harness_assert_corpus ... 90`
#                                expected match: gate==call==90
#
#   test-proposals.sh            gate: `[ "$VIOLATION_COUNT" -gt "$BASELINE" ]`
#                                call: `harness_assert_corpus ... 80`
#                                expected: call-site threshold 80 is
#                                          documented as the
#                                          PROPOSALS_MODE clean-file
#                                          ratio (no in-file numeric
#                                          gate to compare against —
#                                          this case asserts the
#                                          rationale-comment exists
#                                          near the call site).
#
#   test-roundtable-classifier.sh gate: `[ "$CORRECT" -ne "$LOCAL_TOTAL" ]`
#                                 call: `harness_assert_corpus ... 100`
#                                 expected: equality gate ⟺ 100% threshold.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR"

PASS=0
FAIL=0

ok()   { echo "  ✅ $1"; PASS=$((PASS+1)); }
nope() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }

echo "=== R9-011: corpus-threshold anti-drift meta-test ==="

# Helper: extract the FIRST numeric threshold passed to
# harness_assert_corpus in a given file. The argument layout is
# `harness_assert_corpus <correct> <total> <msg> <threshold>` so we
# grep the line and pull the trailing integer.
extract_call_threshold() {
  local file="$1"
  # Match the actual call (line begins with whitespace + the function
  # name + at least one quoted arg), not the `command -v` probe.
  grep -E '^[[:space:]]*harness_assert_corpus "' "$file" \
    | head -1 \
    | grep -oE '[0-9]+[[:space:]]*$' \
    | tr -d '[:space:]'
}

# --- Case 1: test-decision-mode.sh ---
DM="$TEST_DIR/test-decision-mode.sh"
if [ ! -f "$DM" ]; then
  nope "1: test-decision-mode.sh missing at $DM"
else
  GATE_DM=$(grep -oE 'PCT" -lt [0-9]+' "$DM" | head -1 | grep -oE '[0-9]+')
  CALL_DM=$(extract_call_threshold "$DM")
  if [ -n "$GATE_DM" ] && [ -n "$CALL_DM" ] && [ "$GATE_DM" = "$CALL_DM" ]; then
    ok "1: test-decision-mode.sh gate threshold ($GATE_DM) == call-site threshold ($CALL_DM)"
  else
    nope "1: test-decision-mode.sh threshold drift (gate=$GATE_DM call=$CALL_DM)"
  fi
  if grep -qE 'R9-011' "$DM"; then
    ok "1b: test-decision-mode.sh call-site has R9-011 rationale comment"
  else
    nope "1b: test-decision-mode.sh missing R9-011 rationale comment"
  fi
fi

# --- Case 2: test-proposals.sh ---
PR="$TEST_DIR/test-proposals.sh"
if [ ! -f "$PR" ]; then
  nope "2: test-proposals.sh missing at $PR"
else
  CALL_PR=$(extract_call_threshold "$PR")
  if [ "$CALL_PR" = "80" ]; then
    ok "2: test-proposals.sh call-site threshold is 80 (PROPOSALS_MODE clean-file ratio)"
  else
    nope "2: test-proposals.sh call-site threshold is $CALL_PR (expected 80)"
  fi
  if grep -qE 'R9-011' "$PR"; then
    ok "2b: test-proposals.sh call-site has R9-011 rationale comment"
  else
    nope "2b: test-proposals.sh missing R9-011 rationale comment"
  fi
fi

# --- Case 3: test-roundtable-classifier.sh ---
RT="$TEST_DIR/test-roundtable-classifier.sh"
if [ ! -f "$RT" ]; then
  nope "3: test-roundtable-classifier.sh missing at $RT"
else
  # Roundtable uses an inequality gate `-ne LOCAL_TOTAL` which
  # semantically equals 100% match. Encode this as: if the gate is an
  # `-ne` between CORRECT and LOCAL_TOTAL, the call-site threshold MUST
  # be 100.
  HAS_EQ_GATE=$(grep -cE 'CORRECT" -ne "\$LOCAL_TOTAL' "$RT")
  CALL_RT=$(extract_call_threshold "$RT")
  if [ "$HAS_EQ_GATE" -ge 1 ] && [ "$CALL_RT" = "100" ]; then
    ok "3: test-roundtable-classifier.sh equality gate ⟺ 100% call-site threshold"
  else
    nope "3: test-roundtable-classifier.sh threshold drift (eq_gate=$HAS_EQ_GATE call=$CALL_RT)"
  fi
  if grep -qE 'R9-011' "$RT"; then
    ok "3b: test-roundtable-classifier.sh call-site has R9-011 rationale comment"
  else
    nope "3b: test-roundtable-classifier.sh missing R9-011 rationale comment"
  fi
fi

echo ""
echo "=== Results: PASS=$PASS FAIL=$FAIL ==="
# R9-002: bridge private counters into harness globals once.
if declare -F harness_assert_local >/dev/null 2>&1; then
  harness_assert_local "$PASS" "$FAIL" "test-corpus-thresholds"
fi
if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
exit 0
