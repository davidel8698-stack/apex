#!/usr/bin/env bash
# run-all.sh — Aggregate test runner for framework/tests/.
#
# Spec anchor (R16-636 / IMP-036): "APEX חייב לאכוף first-deployment
# gate לפני שגרסת framework חדשה מותקנת." The first-deployment gate in
# framework/scripts/sync-to-claude.sh invokes this script to capture a
# PASS/FAIL snapshot of every test-*.sh under framework/tests/.
#
# Usage
#   bash framework/tests/run-all.sh                  # run all tests, summary on stdout
#   bash framework/tests/run-all.sh --json           # machine-readable JSON summary
#   bash framework/tests/run-all.sh --skip <name>    # skip a test by basename (repeatable)
#   bash framework/tests/run-all.sh --quick          # only fast tests (skip those tagged "slow")
#
# Slow-test tagging policy (R-022-001 — single source of truth)
#   `--quick` is meant to be an HONEST fast subset of the full suite: a
#   test that takes longer than tests it skips makes `--quick`
#   incoherent. A test earns the `# tag: slow` header line when it
#   measures at or above the established tagged-set lower bound — the
#   shortest already-tagged test (`test-sync-coverage.sh`, ~37s) — under
#   aggregate `run-all.sh` load, as evidenced by the `--json`
#   `durations` map. The `# tag: slow` header line is the single opt-in
#   mechanism `--quick` honors; there is no central registry. Future
#   tagging decisions are made by checking the live `durations` map
#   against this rule, not by re-judging each test from prose. The
#   threshold is the RULE (relative to the tagged-set lower bound on
#   live evidence), deliberately not a frozen numeric constant — whole-
#   second `date +%s` figures vary across hosts, so a hard constant
#   would age badly and violate the "state-derived counts" style rule.
#
# Output
#   Human summary: each test line carries an "(Ns)" wall-time suffix and
#   the summary block prints a "total time:" figure (R-020-003).
#   --json: additive "total_seconds" integer and a "durations" object
#   mapping test basename to whole seconds, after the "flaky_tests"
#   field. Timing is whole-second resolution (win32-portable).
#
# Flake handling (R-020-001 / F-020-001)
#   A test that exits non-zero is retried EXACTLY ONCE before being
#   recorded as a FAIL. If the retry succeeds, the test is counted as a
#   PASS and its basename is recorded in the "flaky_tests" field of the
#   --json output (and a "flaky:" line of the human summary). A hard
#   FAIL is recorded only when BOTH attempts fail. The first (failing)
#   attempt's stdout+stderr is captured to a per-test file under a
#   run-scoped `mktemp -d` diagnostics directory so the failing
#   assertion is diagnosable; the diagnostics directory path is printed
#   when any test failed at least once. Retry-once pays its runtime
#   cost only on failing tests — the IMP-036 first-deployment gate can
#   then tell a flaky red (recovered on retry) from a hard red.
#
# Timing instrumentation (R-020-003 / F-020-003)
#   Each test is wall-clock timed with whole-second `date +%s`
#   resolution (sub-second tests show as "(0s)"; whole seconds avoid a
#   portability dependency on `date +%s%N`, unreliable on some win32
#   bash builds). The measurement spans the whole retry-inclusive step,
#   so a flaky test's retry cost is included. The human summary appends
#   an "(Ns)" suffix to each test line and prints a "total time:"
#   figure; the --json output carries an additive "total_seconds"
#   field and a "durations" object mapping basename to seconds. The
#   IMP-036 first-deployment gate ignores the additive keys. This makes
#   a slow run diagnosable rather than a black-box CI timeout.
#
# Exit codes
#   0 — every test exited 0 (a flaky test recovered on retry counts here)
#   1 — at least one test failed BOTH its attempts
#   2 — invocation error (tests dir missing, etc.)

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_DIR="$SCRIPT_DIR"

JSON_OUT=0
QUICK=0
SKIP_LIST=""

while [ $# -gt 0 ]; do
  case "$1" in
    --json) JSON_OUT=1 ;;
    --quick) QUICK=1 ;;
    --skip) shift; SKIP_LIST="$SKIP_LIST|$1" ;;
    *) echo "run-all.sh: unknown arg '$1'" >&2; exit 2 ;;
  esac
  shift
done

if [ ! -d "$TESTS_DIR" ]; then
  echo "run-all.sh: tests dir missing: $TESTS_DIR" >&2
  exit 2
fi

# Recursion guard for the first-deployment gate (R16-636): tests may
# themselves invoke sync-to-claude.sh, whose gate would recursively
# re-invoke run-all.sh. Exporting the marker here means any child
# sync-to-claude.sh invocation short-circuits its gate.
export APEX_FIRST_DEPLOYMENT_GATE_RUNNING=1

PASSED=0
FAILED=0
SKIPPED=0
FAILED_NAMES=""
FLAKY_NAMES=""

# R-020-003 (F-020-003): per-test timing accumulators. TOTAL_SECONDS is
# the sum of every test's retry-inclusive wall time; DURATIONS_JSON
# accumulates `"basename":seconds` pairs for the --json `durations`
# object. Whole-second `date +%s` resolution (see header comment).
TOTAL_SECONDS=0
DURATIONS_JSON=""

# Per-test diagnostics directory (R-020-001 / F-020-001). The first
# (failing) attempt of any test that fails at least once has its
# stdout+stderr captured here so the failing assertion is diagnosable
# instead of being discarded with `>/dev/null 2>&1`. Run-scoped: a
# single `mktemp -d` per aggregate run, cleaned only on a fully green
# run (kept when something failed, so a maintainer can inspect it).
DIAG_DIR="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/run-all-diag-$$")"
mkdir -p "$DIAG_DIR" 2>/dev/null || true

# Iterate over test-*.sh in stable lexical order.
for test_file in "$TESTS_DIR"/test-*.sh; do
  [ -f "$test_file" ] || continue
  base=$(basename "$test_file")
  # Honor --skip
  if [ -n "$SKIP_LIST" ] && echo "$SKIP_LIST" | grep -qE "(^|\\|)$base(\\||$)"; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  # Honor --quick (tests advertising `# tag: slow` in their header)
  if [ "$QUICK" -eq 1 ] && head -20 "$test_file" 2>/dev/null | grep -qE '^# tag:.*\bslow\b'; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  if [ "$JSON_OUT" -eq 0 ]; then
    printf '── %s ...' "$base"
  fi
  # Run the test once, capturing the first attempt's stdout+stderr to a
  # per-test diagnostics file (not discarded). On a non-zero exit, retry
  # EXACTLY ONCE. Record PASS if either attempt succeeds; record a hard
  # FAIL only if both attempts fail.
  #
  # R-020-003: capture a whole-second start timestamp here and compute
  # the elapsed delta after the retry-aware step, so the measurement
  # spans the full retry-inclusive duration of a flaky test.
  test_start=$(date +%s 2>/dev/null || echo 0)
  diag_file="$DIAG_DIR/$base.first.log"
  if bash "$test_file" >"$diag_file" 2>&1; then
    # First attempt passed.
    PASSED=$((PASSED + 1))
    test_result="PASS"
  else
    # First attempt failed — preserve its output and retry exactly once.
    if bash "$test_file" >/dev/null 2>&1; then
      # Retry recovered: this test is flaky, not a hard failure. Counts
      # toward PASSED; recorded in FLAKY_NAMES for the IMP-036 gate.
      PASSED=$((PASSED + 1))
      FLAKY_NAMES="$FLAKY_NAMES $base"
      test_result="PASS (flaky — recovered on retry)"
    else
      # Both attempts failed: a genuine hard FAIL.
      FAILED=$((FAILED + 1))
      FAILED_NAMES="$FAILED_NAMES $base"
      test_result="FAIL"
    fi
  fi
  # R-020-003: whole-second elapsed wall time for this (retry-inclusive)
  # test. A negative or unparseable delta clamps to 0.
  test_end=$(date +%s 2>/dev/null || echo 0)
  test_elapsed=$((test_end - test_start))
  [ "$test_elapsed" -lt 0 ] 2>/dev/null && test_elapsed=0
  TOTAL_SECONDS=$((TOTAL_SECONDS + test_elapsed))
  DURATIONS_JSON="$DURATIONS_JSON,\"$base\":$test_elapsed"
  [ "$JSON_OUT" -eq 0 ] && printf ' %s (%ss)\n' "$test_result" "$test_elapsed"
done

TOTAL=$((PASSED + FAILED))

if [ "$JSON_OUT" -eq 1 ]; then
  # R-020-003: "total_seconds" and "durations" are additive fields,
  # emitted after "flaky_tests". The IMP-036 gate's keyed extraction
  # ignores them. DURATIONS_JSON is built with a leading comma per
  # entry; stripping that leading comma yields a valid object body.
  printf '{"total":%d,"passed":%d,"failed":%d,"skipped":%d,"failed_names":"%s","flaky_tests":"%s","total_seconds":%d,"durations":{%s}}\n' \
    "$TOTAL" "$PASSED" "$FAILED" "$SKIPPED" \
    "$(echo "$FAILED_NAMES" | sed 's/^ //;s/"/\\"/g')" \
    "$(echo "$FLAKY_NAMES" | sed 's/^ //;s/"/\\"/g')" \
    "$TOTAL_SECONDS" \
    "${DURATIONS_JSON#,}"
else
  echo
  echo "═══════════════════════════════════════════════"
  echo "  framework/tests/run-all.sh — summary"
  echo "  total:   $TOTAL"
  echo "  passed:  $PASSED"
  echo "  failed:  $FAILED"
  echo "  skipped: $SKIPPED"
  # R-020-003: total wall time across every test (retry-inclusive),
  # shown as `Nm Ns` so a slow run is diagnosable rather than a
  # black-box CI timeout.
  echo "  total time: $((TOTAL_SECONDS / 60))m $((TOTAL_SECONDS % 60))s (${TOTAL_SECONDS}s)"
  if [ -n "$FLAKY_NAMES" ]; then
    echo "  flaky:$FLAKY_NAMES"
  fi
  if [ "$FAILED" -gt 0 ]; then
    echo "  FAILED tests:$FAILED_NAMES"
  fi
  echo "═══════════════════════════════════════════════"
fi

# Diagnostics retention: keep the per-test capture directory when any
# test failed at least once (hard FAIL or flaky retry-recovery), so the
# failing assertion can be inspected. Remove it on a fully clean run.
if [ "$FAILED" -gt 0 ] || [ -n "$FLAKY_NAMES" ]; then
  if [ "$JSON_OUT" -eq 0 ]; then
    echo "  per-test diagnostics (first-attempt output): $DIAG_DIR"
  fi
else
  rm -rf "$DIAG_DIR" 2>/dev/null || true
fi

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
