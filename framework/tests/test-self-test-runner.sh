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
#
# Dual scope: this file ALSO meta-tests framework/tests/run-all.sh, the
# aggregate test runner. R-020-001 and R-020-003 extended it with
# run-all.sh cases (the `# --- R-020-001 ... ---` block below). It asserts
# run-all.sh is honest about aggregate-run outcomes:
#   6. Retry-once-on-failure: a flaky fixture that fails then passes on
#      the retry counts as PASS and run-all.sh exits 0 (R-020-001).
#   7. The --json output populates the "flaky_tests" field with any
#      retry-recovered test and always emits the key (R-020-001).
#   8. Timing instrumentation: --json carries the additive "total_seconds"
#      field and a per-test "durations" map (R-020-003).

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

# --- R-020-001 (F-020-001): run-all.sh retry-once + flaky_tests ---
#
# These cases exercise the aggregate runner framework/tests/run-all.sh —
# its retry-once-on-failure path and the new "flaky_tests" --json field
# (added in R-020-001). To drive the runner deterministically WITHOUT
# depending on the real 72-test tree, each case builds a throwaway tests
# directory containing a copy of run-all.sh plus crafted stub test-*.sh
# files, and invokes run-all.sh against that directory (run-all.sh
# discovers tests by glob in its own SCRIPT_DIR, so a copy placed in the
# fixture dir runs the fixture tests).
#
# Spec anchors (R-020-001): "Fail-loud, never fail-silent.",
# "APEX must be transparent to itself.", IMP-036 ("0 regressions").

RUN_ALL="$REPO_ROOT/framework/tests/run-all.sh"

if [ -f "$RUN_ALL" ]; then
  ok "run-all.sh exists at $RUN_ALL"

  # Build a throwaway tests dir with a copy of run-all.sh and stubs.
  RA_FIXTURE="$(mktemp -d)"
  cp "$RUN_ALL" "$RA_FIXTURE/run-all.sh"

  # Stub 1 — always-PASS test (exit 0 on first attempt).
  cat > "$RA_FIXTURE/test-stub-pass.sh" <<'EOF'
exit 0
EOF

  # Stub 2 — FLAKY test: fails the first attempt, passes the retry. A
  # state file in the same dir records that the first attempt ran; the
  # second invocation sees it and exits 0.
  cat > "$RA_FIXTURE/test-stub-flaky.sh" <<'EOF'
marker="$(dirname "$0")/.stub-flaky-attempted"
if [ -f "$marker" ]; then
  exit 0
fi
: > "$marker"
exit 1
EOF

  # Stub 3 — HARD-FAIL test: exits non-zero on BOTH attempts.
  cat > "$RA_FIXTURE/test-stub-hardfail.sh" <<'EOF'
exit 1
EOF

  # --- Case A: a test that fails once then passes is recorded PASS and
  #     appears in flaky_tests; it is NOT in failed_names. ---
  rm -f "$RA_FIXTURE/.stub-flaky-attempted"
  RA_JSON_FLAKY="$(bash "$RA_FIXTURE/run-all.sh" --json --skip test-stub-hardfail.sh 2>/dev/null)"
  RA_RC_FLAKY=$?
  if echo "$RA_JSON_FLAKY" | grep -q '"flaky_tests":"[^"]*test-stub-flaky.sh'; then
    ok "retry-recovered test appears in flaky_tests (run-all.sh retry-once works)"
  else
    nope "retry-recovered test missing from flaky_tests — got: $RA_JSON_FLAKY"
  fi
  if echo "$RA_JSON_FLAKY" | grep -qE '"failed":0' \
     && [ "$RA_RC_FLAKY" -eq 0 ]; then
    ok "a flaky (retry-recovered) test counts as PASS, run-all.sh exits 0"
  else
    nope "flaky test did not count as PASS (rc=$RA_RC_FLAKY) — got: $RA_JSON_FLAKY"
  fi

  # --- Case B: a test that fails BOTH attempts is recorded FAIL, lands
  #     in failed_names, and drives a non-zero exit. ---
  RA_JSON_HARD="$(bash "$RA_FIXTURE/run-all.sh" --json --skip test-stub-flaky.sh 2>/dev/null)"
  RA_RC_HARD=$?
  if echo "$RA_JSON_HARD" | grep -q '"failed_names":"[^"]*test-stub-hardfail.sh' \
     && [ "$RA_RC_HARD" -ne 0 ]; then
    ok "a hard-failing test (fails both attempts) lands in failed_names, exit non-zero"
  else
    nope "hard-fail test not scored as FAIL (rc=$RA_RC_HARD) — got: $RA_JSON_HARD"
  fi

  # --- Case C: --json output always contains a flaky_tests key. ---
  RA_JSON_KEY="$(bash "$RA_FIXTURE/run-all.sh" --json --skip test-stub-flaky.sh --skip test-stub-hardfail.sh 2>/dev/null)"
  if echo "$RA_JSON_KEY" | grep -q '"flaky_tests":'; then
    ok "run-all.sh --json always emits a flaky_tests key"
  else
    nope "run-all.sh --json missing flaky_tests key — got: $RA_JSON_KEY"
  fi
  # Validate it is well-formed JSON when jq is available.
  if command -v jq >/dev/null 2>&1; then
    if echo "$RA_JSON_KEY" | jq -e 'has("flaky_tests")' >/dev/null 2>&1; then
      ok "run-all.sh --json is valid JSON with a flaky_tests field"
    else
      nope "run-all.sh --json failed jq has(\"flaky_tests\") check"
    fi
  fi

  # --- Case D (R-020-003 / F-020-003): timing instrumentation. The
  #     --json output carries an additive "total_seconds" field and a
  #     "durations" object; the human summary carries a per-test "(Ns)"
  #     suffix and a "total time:" line. The new keys are additive — the
  #     IMP-036 gate's keyed extraction ignores them. ---
  if echo "$RA_JSON_KEY" | grep -q '"total_seconds":'; then
    ok "run-all.sh --json emits an additive total_seconds field (R-020-003)"
  else
    nope "run-all.sh --json missing total_seconds key — got: $RA_JSON_KEY"
  fi
  if command -v jq >/dev/null 2>&1; then
    if echo "$RA_JSON_KEY" | jq -e 'has("total_seconds") and has("durations")' >/dev/null 2>&1; then
      ok "run-all.sh --json is valid JSON with total_seconds + durations (R-020-003)"
    else
      nope "run-all.sh --json failed jq total_seconds/durations check"
    fi
  fi
  RA_HUMAN="$(bash "$RA_FIXTURE/run-all.sh" --skip test-stub-flaky.sh --skip test-stub-hardfail.sh 2>/dev/null)"
  if echo "$RA_HUMAN" | grep -qE '\([0-9]+s\)' \
     && echo "$RA_HUMAN" | grep -q 'total time:'; then
    ok "run-all.sh human output shows per-test (Ns) suffix + total time line (R-020-003)"
  else
    nope "run-all.sh human output missing timing suffix or total time line"
  fi

  rm -rf "$RA_FIXTURE"
else
  nope "run-all.sh missing at $RUN_ALL — cannot exercise retry/flaky cases"
fi

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
