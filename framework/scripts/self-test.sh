#!/usr/bin/env bash
# APEX Self-Test — verifies all framework mechanisms work.
# Usage: bash self-test.sh [pattern]
# Examples:
#   bash self-test.sh              # run all tests
#   bash self-test.sh guards       # run only test-guards.sh
#   bash self-test.sh schemas      # run only test-schemas.sh

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
for test_file in "$TEST_DIR"/test-${PATTERN}.sh; do
  [ -f "$test_file" ] || continue
  FOUND=$((FOUND + 1))
  echo ""
  echo "━━━ $(basename "$test_file") ━━━"
  source "$test_file"
done

if [ "$FOUND" -eq 0 ]; then
  echo "❌ No test files matching pattern: test-${PATTERN}.sh"
  harness_teardown
  exit 1
fi

harness_teardown
harness_report
