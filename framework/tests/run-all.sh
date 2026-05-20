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
  diag_file="$DIAG_DIR/$base.first.log"
  if bash "$test_file" >"$diag_file" 2>&1; then
    # First attempt passed.
    PASSED=$((PASSED + 1))
    [ "$JSON_OUT" -eq 0 ] && printf ' PASS\n'
  else
    # First attempt failed — preserve its output and retry exactly once.
    if bash "$test_file" >/dev/null 2>&1; then
      # Retry recovered: this test is flaky, not a hard failure. Counts
      # toward PASSED; recorded in FLAKY_NAMES for the IMP-036 gate.
      PASSED=$((PASSED + 1))
      FLAKY_NAMES="$FLAKY_NAMES $base"
      [ "$JSON_OUT" -eq 0 ] && printf ' PASS (flaky — recovered on retry)\n'
    else
      # Both attempts failed: a genuine hard FAIL.
      FAILED=$((FAILED + 1))
      FAILED_NAMES="$FAILED_NAMES $base"
      [ "$JSON_OUT" -eq 0 ] && printf ' FAIL\n'
    fi
  fi
done

TOTAL=$((PASSED + FAILED))

if [ "$JSON_OUT" -eq 1 ]; then
  printf '{"total":%d,"passed":%d,"failed":%d,"skipped":%d,"failed_names":"%s","flaky_tests":"%s"}\n' \
    "$TOTAL" "$PASSED" "$FAILED" "$SKIPPED" \
    "$(echo "$FAILED_NAMES" | sed 's/^ //;s/"/\\"/g')" \
    "$(echo "$FLAKY_NAMES" | sed 's/^ //;s/"/\\"/g')"
else
  echo
  echo "═══════════════════════════════════════════════"
  echo "  framework/tests/run-all.sh — summary"
  echo "  total:   $TOTAL"
  echo "  passed:  $PASSED"
  echo "  failed:  $FAILED"
  echo "  skipped: $SKIPPED"
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
