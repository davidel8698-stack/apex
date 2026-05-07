#!/usr/bin/env bash
# APEX Self-Test — verifies all framework mechanisms work.
# Usage: bash self-test.sh [pattern]
# Examples:
#   bash self-test.sh              # run all tests
#   bash self-test.sh guards       # run only test-guards.sh
#   bash self-test.sh schemas      # run only test-schemas.sh
#
# R7-001: each per-test `source` is wrapped in a subshell so a sourced
# `exit` cannot terminate the runner loop. Per-test counters are passed
# back via a sidecar tempfile (HARNESS_COUNTERS_FILE) and aggregated
# into cumulative totals reported once at the end via harness_report.

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="$SCRIPT_DIR/../tests"

if [ ! -f "$TEST_DIR/_harness.sh" ]; then
  echo "❌ Harness not found at $TEST_DIR/_harness.sh"
  exit 1
fi

source "$TEST_DIR/_harness.sh"

echo "▲ APEX Self-Test"
echo "━━━━━━━━━━━━━━━━"

harness_setup

PATTERN="${1:-*}"
FOUND=0

# Cumulative totals across all sourced test files.
CUM_PASS=0
CUM_FAIL=0
CUM_TOTAL=0
CUM_SKIP=0

# Per-file summary lines, emitted once at the end alongside harness_report.
PER_FILE_SUMMARY=""

for test_file in "$TEST_DIR"/test-${PATTERN}.sh; do
  [ -f "$test_file" ] || continue
  FOUND=$((FOUND + 1))
  TEST_NAME="$(basename "$test_file")"
  echo ""
  echo "━━━ $TEST_NAME ━━━"

  # R7-001: zero per-test counters in the parent so the subshell inherits
  # zeros (whether the test increments via assert_* or resets locally,
  # the final values inside the subshell represent per-file counts only).
  PASS=0
  FAIL=0
  TOTAL=0
  SKIP=0

  HARNESS_COUNTERS_FILE="$(mktemp)"
  export HARNESS_COUNTERS_FILE

  # Subshell-wrap the source. The EXIT trap writes per-test counters to
  # the sidecar file regardless of whether the test calls `exit` or
  # falls off the end. The subshell's exit code is captured for FAIL
  # detection; a non-zero subshell exit with no sidecar update is also
  # treated as a per-file FAIL.
  (
    trap 'harness_export_counters' EXIT
    source "$test_file"
  )
  subshell_rc=$?

  if [ -s "$HARNESS_COUNTERS_FILE" ]; then
    read -r SUB_PASS SUB_FAIL SUB_TOTAL SUB_SKIP < "$HARNESS_COUNTERS_FILE"
  else
    SUB_PASS=0
    SUB_FAIL=0
    SUB_TOTAL=0
    SUB_SKIP=0
  fi

  # Defensive defaults if any field was empty.
  : "${SUB_PASS:=0}"
  : "${SUB_FAIL:=0}"
  : "${SUB_TOTAL:=0}"
  : "${SUB_SKIP:=0}"

  # If the test file exited non-zero but reported no failures, surface
  # the discrepancy as a per-file FAIL so the runner exit reflects it.
  if [ "$subshell_rc" -ne 0 ] && [ "$SUB_FAIL" -eq 0 ]; then
    SUB_FAIL=$((SUB_FAIL + 1))
    SUB_TOTAL=$((SUB_TOTAL + 1))
    echo "  ⚠️  $TEST_NAME exited non-zero (rc=$subshell_rc) with no harness FAIL recorded — counted as 1 FAIL"
  fi

  CUM_PASS=$((CUM_PASS + SUB_PASS))
  CUM_FAIL=$((CUM_FAIL + SUB_FAIL))
  CUM_TOTAL=$((CUM_TOTAL + SUB_TOTAL))
  CUM_SKIP=$((CUM_SKIP + SUB_SKIP))

  PER_FILE_SUMMARY="${PER_FILE_SUMMARY}  ${TEST_NAME}: PASS=${SUB_PASS} FAIL=${SUB_FAIL} (rc=${subshell_rc})"$'\n'

  rm -f "$HARNESS_COUNTERS_FILE"
  unset HARNESS_COUNTERS_FILE
done

if [ "$FOUND" -eq 0 ]; then
  echo "❌ No test files matching pattern: test-${PATTERN}.sh"
  harness_teardown
  exit 1
fi

# Restore cumulative totals for harness_report (which prints
# "$PASS/$TOTAL passed, $FAIL failed" and exits "$FAIL").
PASS=$CUM_PASS
FAIL=$CUM_FAIL
TOTAL=$CUM_TOTAL
SKIP=$CUM_SKIP

echo ""
echo "━━━ Per-file summary (${FOUND} test files) ━━━"
printf '%s' "$PER_FILE_SUMMARY"

harness_teardown
harness_report
