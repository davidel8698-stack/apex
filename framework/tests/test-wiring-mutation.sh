#!/usr/bin/env bash
# R5-012: mutation-gate.sh wiring test.
#
# Spec anchor: "Mutation-gate" (failure-class #6 defense).
#
# Asserts:
#   1. framework/commands/apex/next.md contains an invocation of
#      mutation-gate.sh in the C/D-verify branch (after critic PASS).
#   2. The invocation is gated on verify_level in ["C", "D"].
#   3. HOOK-CLASSIFICATION.md row for mutation-gate.sh names /apex:next
#      as the invoker.
#   4. The mutation-gate.sh hook itself enforces verify_level C/D
#      filtering (defense-in-depth — even if next.md misroutes).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
NEXT_MD="$REPO_ROOT/framework/commands/apex/next.md"
HOOK="$REPO_ROOT/framework/hooks/mutation-gate.sh"
CLASSIFICATION="$REPO_ROOT/framework/HOOK-CLASSIFICATION.md"

if [ ! -f "$NEXT_MD" ] || [ ! -f "$HOOK" ] || [ ! -f "$CLASSIFICATION" ]; then
  echo "FAIL: required files missing" >&2
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

echo "=== R5-012: mutation-gate wiring tests ==="
echo

# 1. next.md invokes mutation-gate.sh
assert_pass "next.md invokes mutation-gate.sh" \
  "grep -E 'bash[[:space:]]+~/\.claude/hooks/mutation-gate\.sh' '$NEXT_MD'"

# 2. The invocation is inside a C/D-verify-level guard
assert_pass "mutation-gate invocation is C/D-gated" \
  "awk '/verify_level in \\[\"C\", \"D\"\\]/{flag=NR; next} flag && NR-flag<=4 && /mutation-gate.sh/{found=1} END{exit !found}' '$NEXT_MD'"

# 3. HOOK-CLASSIFICATION row references /apex:next as invoker
assert_pass "HOOK-CLASSIFICATION row names /apex:next as invoker" \
  "grep 'mutation-gate.sh' '$CLASSIFICATION' | grep '/apex:next'"

# 4. Hook body enforces C/D filter (defense-in-depth)
assert_pass "mutation-gate.sh hook itself filters verify_level C/D" \
  "grep -E 'VERIFY_LEVEL.*(C|D)' '$HOOK'"

# 5. The invocation passes both NEXT_UNIT and verify_level
assert_pass "invocation passes \${NEXT_UNIT} and \${verify_level}" \
  "grep -E 'mutation-gate\.sh \\\${NEXT_UNIT}.*\\\${verify_level}' '$NEXT_MD'"

echo
echo "=== Results: PASS=$PASS FAIL=$FAIL ==="
if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
exit 0
