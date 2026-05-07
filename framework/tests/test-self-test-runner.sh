#!/usr/bin/env bash
# R7-001: meta-test for framework/scripts/self-test.sh.
#
# Spec anchors:
#   "Fail-loud, never fail-silent."
#   "Verification universal, not TDD universal."
#   "RESULT.json with verified_criteria[]/unverified_criteria[]."
#
# Asserts the runner is honest about per-file outcomes:
#   1. The runner sources every matching test file in the fixture tree
#      (no early-exit-on-source kills the loop).
#   2. harness_report runs exactly once at the end with cumulative totals
#      across more than one fixture file.
#   3. A deliberately-FAILing fixture causes the runner to exit non-zero.
#   4. A fixture that calls `exit 0` mid-file does not prevent later
#      fixtures from being sourced.
#   5. Pattern-mode invocation continues to work for the single-file case.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUNNER="$REPO_ROOT/framework/scripts/self-test.sh"
HARNESS="$REPO_ROOT/framework/tests/_harness.sh"

PASS=0
FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
nope() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== R7-001: self-test runner honesty ==="

# 0. Runner exists.
if [ -f "$RUNNER" ]; then
  ok "self-test.sh exists at $RUNNER"
else
  nope "self-test.sh missing at $RUNNER"
  echo
  echo "=== Results: PASS=$PASS FAIL=$FAIL ==="
  [ "$FAIL" -eq 0 ] && exit 0 || exit 1
fi

# 1. Subshell-wrapper anchor present.
if grep -qE '\(\s*$' "$RUNNER" && grep -qE 'source "\$test_file"' "$RUNNER"; then
  ok "self-test.sh contains subshell-wrapped source invocation"
else
  nope "self-test.sh does not contain subshell-wrapped source"
fi

# 2. harness_export_counters helper present in harness.
if grep -qE 'harness_export_counters' "$HARNESS"; then
  ok "_harness.sh defines harness_export_counters helper"
else
  nope "_harness.sh missing harness_export_counters helper"
fi

# 3. Build a fixture tree and run the runner against it.
FIXTURE_ROOT="$(mktemp -d)"
FIXTURE_TESTS="$FIXTURE_ROOT/tests"
FIXTURE_SCRIPTS="$FIXTURE_ROOT/scripts"
mkdir -p "$FIXTURE_TESTS" "$FIXTURE_SCRIPTS"

# Copy the harness so the fixture runner can source it.
cp "$HARNESS" "$FIXTURE_TESTS/_harness.sh"

# Fixture 1 — pure PASS that ends with `exit 0` (the bug case).
cat > "$FIXTURE_TESTS/test-fixture-a-pass.sh" <<'EOF'
echo "fixture-a: started"
TOTAL=$((TOTAL + 1))
PASS=$((PASS + 1))
echo "  PASS: fixture-a synthetic"
echo "fixture-a: about to exit 0 (sourced-exit hazard)"
exit 0
EOF

# Fixture 2 — must run AFTER fixture A despite A's `exit 0`.
cat > "$FIXTURE_TESTS/test-fixture-b-pass.sh" <<'EOF'
echo "fixture-b: started (this proves the runner did not halt at fixture-a)"
TOTAL=$((TOTAL + 1))
PASS=$((PASS + 1))
echo "  PASS: fixture-b synthetic"
EOF

# Fixture 3 — deliberate FAIL via FAIL=1 + exit 1.
cat > "$FIXTURE_TESTS/test-fixture-c-fail.sh" <<'EOF'
echo "fixture-c: started"
TOTAL=$((TOTAL + 1))
FAIL=$((FAIL + 1))
echo "  FAIL: fixture-c synthetic"
exit 1
EOF

# Build a stand-in runner that points at the fixture tests dir.
cp "$RUNNER" "$FIXTURE_SCRIPTS/self-test.sh"
chmod +x "$FIXTURE_SCRIPTS/self-test.sh"

# 4. PASS-only run (fixtures a + b) should exit 0 and source both files.
PASS_ONLY_OUT="$(bash "$FIXTURE_SCRIPTS/self-test.sh" 'fixture-[ab]-pass' 2>&1)"
PASS_ONLY_RC=$?

if echo "$PASS_ONLY_OUT" | grep -q "fixture-a: started"; then
  ok "runner sources fixture-a"
else
  nope "runner did not source fixture-a"
fi

if echo "$PASS_ONLY_OUT" | grep -q "fixture-b: started"; then
  ok "runner sources fixture-b after fixture-a's exit 0 (subshell isolation works)"
else
  nope "runner halted before fixture-b — subshell wrapper failed"
fi

if [ "$PASS_ONLY_RC" -eq 0 ]; then
  ok "PASS-only fixture run exits 0"
else
  nope "PASS-only fixture run exits $PASS_ONLY_RC (expected 0)"
fi

# 5. harness_report runs exactly once at the end.
REPORT_LINES="$(echo "$PASS_ONLY_OUT" | grep -cE 'APEX self-test: [0-9]+/[0-9]+ passed')"
if [ "$REPORT_LINES" -eq 1 ]; then
  ok "harness_report runs exactly once (cumulative totals at end)"
else
  nope "harness_report ran $REPORT_LINES times (expected 1)"
fi

# 6. Per-file summary block names more than one file.
if echo "$PASS_ONLY_OUT" | grep -q 'Per-file summary' \
   && echo "$PASS_ONLY_OUT" | grep -q 'test-fixture-a-pass.sh: PASS=' \
   && echo "$PASS_ONLY_OUT" | grep -q 'test-fixture-b-pass.sh: PASS='; then
  ok "per-file summary covers more than one fixture file"
else
  nope "per-file summary missing or covers only one fixture file"
fi

# 7. FAIL-included run (fixtures a + b + c) should exit non-zero.
FAIL_OUT="$(bash "$FIXTURE_SCRIPTS/self-test.sh" 'fixture-*' 2>&1)"
FAIL_RC=$?

if [ "$FAIL_RC" -ne 0 ]; then
  ok "FAIL fixture causes runner to exit non-zero (rc=$FAIL_RC)"
else
  nope "FAIL fixture did not propagate non-zero exit — runner is still dishonest"
fi

if echo "$FAIL_OUT" | grep -q "fixture-c: started"; then
  ok "runner sources fixture-c (the FAIL fixture)"
else
  nope "runner did not source fixture-c"
fi

# 8. Pattern-mode invocation against a non-matching pattern returns non-zero
#    with the "No test files matching pattern" diagnostic (regression check).
NOMATCH_OUT="$(bash "$FIXTURE_SCRIPTS/self-test.sh" 'phantom-check-no-such' 2>&1)"
NOMATCH_RC=$?
if [ "$NOMATCH_RC" -ne 0 ] && echo "$NOMATCH_OUT" | grep -q 'No test files matching pattern'; then
  ok "pattern-mode no-match returns non-zero with diagnostic"
else
  nope "pattern-mode no-match path regressed (rc=$NOMATCH_RC)"
fi

# Cleanup.
rm -rf "$FIXTURE_ROOT"

echo
echo "=== Results: PASS=$PASS FAIL=$FAIL ==="
# R9-002: bridge private counters into harness globals once.
if declare -F harness_assert_local >/dev/null 2>&1; then
  harness_assert_local "$PASS" "$FAIL" "test-self-test-runner"
fi
if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
exit 0
