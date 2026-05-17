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
# Exit codes
#   0 — every test exited 0
#   1 — at least one test failed
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
  # Run the test silently; capture exit code only.
  if bash "$test_file" >/dev/null 2>&1; then
    PASSED=$((PASSED + 1))
    [ "$JSON_OUT" -eq 0 ] && printf ' PASS\n'
  else
    FAILED=$((FAILED + 1))
    FAILED_NAMES="$FAILED_NAMES $base"
    [ "$JSON_OUT" -eq 0 ] && printf ' FAIL\n'
  fi
done

TOTAL=$((PASSED + FAILED))

if [ "$JSON_OUT" -eq 1 ]; then
  printf '{"total":%d,"passed":%d,"failed":%d,"skipped":%d,"failed_names":"%s"}\n' \
    "$TOTAL" "$PASSED" "$FAILED" "$SKIPPED" "$(echo "$FAILED_NAMES" | sed 's/^ //;s/"/\\"/g')"
else
  echo
  echo "═══════════════════════════════════════════════"
  echo "  framework/tests/run-all.sh — summary"
  echo "  total:   $TOTAL"
  echo "  passed:  $PASSED"
  echo "  failed:  $FAILED"
  echo "  skipped: $SKIPPED"
  if [ "$FAILED" -gt 0 ]; then
    echo "  FAILED tests:$FAILED_NAMES"
  fi
  echo "═══════════════════════════════════════════════"
fi

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
