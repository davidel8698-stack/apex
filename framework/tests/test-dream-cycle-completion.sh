#!/usr/bin/env bash
# R5-023: dream-cycle wrap emits both START and COMPLETE (or FAIL) entries
#         in event-log.jsonl, tied by a correlation id.
#
# Tests the _dream-cycle-emit.sh helper and contract checks on next.md.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HELPER="$REPO_ROOT/framework/hooks/_dream-cycle-emit.sh"
NEXT_MD="$REPO_ROOT/framework/commands/apex/next.md"

if [ ! -f "$HELPER" ]; then
  echo "FAIL: _dream-cycle-emit.sh not found at $HELPER" >&2
  exit 1
fi

PASS=0
FAIL=0

assert_pass() {
  local label="$1" cond="$2"
  if eval "$cond" >/dev/null 2>&1; then
    echo "  PASS: $label"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $label"
    FAIL=$((FAIL+1))
  fi
}

echo "=== R5-023: dream-cycle completion observability ==="

# --- Contract checks on next.md ---
assert_pass "next.md references _dream-cycle-emit.sh"  "grep -q '_dream-cycle-emit.sh' '$NEXT_MD'"
assert_pass "next.md has DREAM-CYCLE WRAP block"       "grep -q 'DREAM-CYCLE WRAP' '$NEXT_MD'"
# Two distinct wrap sites (pre-compact + periodic).
WRAP_COUNT=$(grep -c 'DREAM-CYCLE WRAP' "$NEXT_MD")
assert_pass "two wrap sites present (pre-compact + periodic)" "[ $WRAP_COUNT -ge 2 ]"
assert_pass "next.md emits dream_cycle_emit start"     "grep -q '_dream-cycle-emit.sh start' '$NEXT_MD'"
assert_pass "next.md emits dream_cycle_emit complete"  "grep -q '_dream-cycle-emit.sh complete' '$NEXT_MD'"
assert_pass "next.md emits dream_cycle_emit fail"      "grep -q '_dream-cycle-emit.sh fail' '$NEXT_MD'"

# --- Helper smoke test in a sandbox ---
SANDBOX="$(mktemp -d)"
mkdir -p "$SANDBOX/.apex"

# START
CID=$(cd "$SANDBOX" && bash "$HELPER" start "smoke-test")
assert_pass "start phase prints a correlation id"   "[ -n '$CID' ]"
assert_pass "start phase writes event-log.jsonl"    "[ -f '$SANDBOX/.apex/event-log.jsonl' ]"
assert_pass "event-log has dream_cycle_start"       "grep -q 'dream_cycle_start' '$SANDBOX/.apex/event-log.jsonl'"
assert_pass "event-log has correlation_id"          "grep -q '$CID' '$SANDBOX/.apex/event-log.jsonl'"

# COMPLETE
( cd "$SANDBOX" && bash "$HELPER" complete "$CID" 1234 "ok" )
assert_pass "complete phase writes dream_cycle_complete" "grep -q 'dream_cycle_complete' '$SANDBOX/.apex/event-log.jsonl'"
assert_pass "complete phase carries the same correlation id" "[ \$(grep -c '$CID' '$SANDBOX/.apex/event-log.jsonl') -ge 2 ]"

# FAIL (separate id to keep cases distinct)
CID2=$(cd "$SANDBOX" && bash "$HELPER" start "fail-test")
( cd "$SANDBOX" && bash "$HELPER" fail "$CID2" "synthetic failure" )
assert_pass "fail phase writes dream_cycle_fail"    "grep -q 'dream_cycle_fail' '$SANDBOX/.apex/event-log.jsonl'"
assert_pass "fail phase carries its correlation id" "[ \$(grep -c '$CID2' '$SANDBOX/.apex/event-log.jsonl') -ge 2 ]"

# Unknown phase → exit non-zero
( cd "$SANDBOX" && bash "$HELPER" bogus >/dev/null 2>&1 )
EXIT_BOGUS=$?
assert_pass "unknown phase exits non-zero (fail-loud)" "[ $EXIT_BOGUS -ne 0 ]"

# --- session-log.sh recognizes the new event types (icon case present) ---
SESSION_LOG="$REPO_ROOT/framework/hooks/session-log.sh"
assert_pass "session-log.sh has dream_cycle_start case"    "grep -q 'dream_cycle_start)' '$SESSION_LOG'"
assert_pass "session-log.sh has dream_cycle_complete case" "grep -q 'dream_cycle_complete)' '$SESSION_LOG'"
assert_pass "session-log.sh has dream_cycle_fail case"     "grep -q 'dream_cycle_fail)' '$SESSION_LOG'"

rm -rf "$SANDBOX"

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit "$FAIL"
