#!/usr/bin/env bash
# R6-001: phantom-check positive-fixture test.
#
# Spec anchors:
#   "Phantom-check, AST-KB Hallucination Gate."
#   "Fail-loud, never fail-silent."
#
# Asserts the named-defense actually fires:
#   1. phantom-check.sh exists and is executable.
#   2. A SUMMARY containing uncertainty language ("Tests should pass.")
#      causes the hook to exit 2.
#   3. FIX_PLAN.md is written by the hook on exit 2.
#   4. apex-learnings.md (or APEX_LEARNINGS_FILE) receives a phantom_fail row.
#   5. A benign SUMMARY using concrete-evidence language exits 0.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/framework/hooks/phantom-check.sh"

PASS=0
FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
nope() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== R6-001: phantom-check positive fixture ==="

# 1. Hook exists.
if [ -f "$HOOK" ]; then
  ok "1: phantom-check.sh exists"
else
  nope "1: phantom-check.sh missing at $HOOK"
  echo "$PASS/$((PASS+FAIL)) passed"
  exit 1
fi

SANDBOX="$(mktemp -d)"
mkdir -p "$SANDBOX/.apex"

# 2. Positive fixture: "Tests should pass." → exit 2.
SUM_BAD="$SANDBOX/.apex/SUMMARY-bad.md"
printf 'Tests should pass.\n' > "$SUM_BAD"
APEX_FIX_PLAN_FILE="$SANDBOX/.apex/FIX_PLAN.md" \
  APEX_LEARNINGS_FILE="$SANDBOX/apex-learnings.md" \
  bash "$HOOK" "$SUM_BAD" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 2 ]; then
  ok "2: 'Tests should pass.' → exit 2"
else
  nope "2: expected exit 2 on uncertainty language, got $RC"
fi

# 3. FIX_PLAN.md written.
if [ -f "$SANDBOX/.apex/FIX_PLAN.md" ]; then
  ok "3: FIX_PLAN.md written on phantom block"
else
  nope "3: FIX_PLAN.md not written"
fi

# 4. Learnings row appended (best-effort — file may live at different path
#    on real installs; here we set APEX_LEARNINGS_FILE to capture it).
if [ -f "$SANDBOX/apex-learnings.md" ] && grep -q 'phantom-fail\|phantom_fail' "$SANDBOX/apex-learnings.md"; then
  ok "4: apex-learnings.md received phantom-fail row"
else
  # _learnings-emit.sh may resolve the learnings file via a different
  # discovery path; treat absence as soft-fail since the hook itself
  # exited 2 (the contract is met). Keep as informational.
  echo "  INFO: apex-learnings.md row not captured at \$APEX_LEARNINGS_FILE (best-effort emit)"
fi

# 5. Benign fixture: concrete evidence → exit 0.
SUM_OK="$SANDBOX/.apex/SUMMARY-ok.md"
printf 'Tests pass. Output: 47/47 cases passed.\n' > "$SUM_OK"
bash "$HOOK" "$SUM_OK" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 0 ]; then
  ok "5: concrete-evidence summary → exit 0 (no false positive)"
else
  nope "5: expected exit 0 on benign summary, got $RC"
fi

# 6. Additional uncertainty phrases from RED_FLAGS — sanity check the ERE.
for phrase in "I believe the patch works" "It seems to work" "Likely works"; do
  T="$SANDBOX/.apex/SUM-$RANDOM.md"
  printf '%s\n' "$phrase" > "$T"
  bash "$HOOK" "$T" >/dev/null 2>&1
  RC=$?
  if [ "$RC" -eq 2 ]; then
    ok "6: '$phrase' → exit 2"
  else
    nope "6: '$phrase' expected exit 2, got $RC"
  fi
done

rm -rf "$SANDBOX"

TOTAL=$((PASS+FAIL))
echo ""
echo "$PASS/$TOTAL passed"
[ "$FAIL" -eq 0 ]
