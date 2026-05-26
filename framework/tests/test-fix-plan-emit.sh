#!/usr/bin/env bash
# R5-014: Shared fix-plan emitter — every blocking guard produces FIX_PLAN.md.
#
# Spec anchor: "Failure produces a fix plan, never a 'go debug it'."
#
# Asserts:
#   1. _fix-plan-emit.sh exists and is sourceable.
#   2. emit_fix_plan writes .apex/FIX_PLAN.md with required sections.
#   3. Each blocking guard sources _fix-plan-emit.sh.
#   4. Triggering each blocking guard against a fixture produces FIX_PLAN.md.
#   5. circuit-breaker.sh writes both FIX_PLAN.md AND RECOVERY_MENU.md (alias).
#   6. walkthrough.md and recover.md reference FIX_PLAN.md.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOKS_DIR="$REPO_ROOT/framework/hooks"
HELPER="$HOOKS_DIR/_fix-plan-emit.sh"

if [ ! -f "$HELPER" ]; then
  echo "FAIL: _fix-plan-emit.sh not found at $HELPER" >&2
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

run_sandbox() {
  local sandbox; sandbox="$(mktemp -d)"
  ( cd "$sandbox" && git init -q && git config user.email t@a && git config user.name t && \
    echo init > init.txt && git add . && git commit -qm init )
  echo "$sandbox"
}

echo "=== R5-014: shared fix-plan emitter ==="
echo

# 1. Helper file exists
assert_pass "_fix-plan-emit.sh exists" "[ -f '$HELPER' ]"

# 2. Helper produces FIX_PLAN.md with required sections
SANDBOX_HELPER=$(run_sandbox)
mkdir -p "$SANDBOX_HELPER/.apex"
(
  cd "$SANDBOX_HELPER"
  # shellcheck source=/dev/null
  source "$HELPER"
  emit_fix_plan \
    "test-source" \
    "Test reason here." \
    "Test context here" \
    "/apex:foo -- one option" \
    "/apex:bar -- two option"
)
assert_pass "FIX_PLAN.md created" "[ -f '$SANDBOX_HELPER/.apex/FIX_PLAN.md' ]"
assert_pass "FIX_PLAN.md has Reason section" "grep -q '^## Reason' '$SANDBOX_HELPER/.apex/FIX_PLAN.md'"
assert_pass "FIX_PLAN.md has Recommended commands section" "grep -q '^## Recommended commands' '$SANDBOX_HELPER/.apex/FIX_PLAN.md'"
assert_pass "FIX_PLAN.md has Context section" "grep -q '^## Context' '$SANDBOX_HELPER/.apex/FIX_PLAN.md'"
assert_pass "FIX_PLAN.md cites the source" "grep -q 'test-source' '$SANDBOX_HELPER/.apex/FIX_PLAN.md'"
assert_pass "FIX_PLAN.md preserves the reason" "grep -q 'Test reason here' '$SANDBOX_HELPER/.apex/FIX_PLAN.md'"
assert_pass "FIX_PLAN.md lists at least one /apex command" "grep -q '/apex:' '$SANDBOX_HELPER/.apex/FIX_PLAN.md'"
rm -rf "$SANDBOX_HELPER"

# 3. --also-write-recovery-menu mirrors to RECOVERY_MENU.md
SANDBOX_ALIAS=$(run_sandbox)
mkdir -p "$SANDBOX_ALIAS/.apex"
(
  cd "$SANDBOX_ALIAS"
  # shellcheck source=/dev/null
  source "$HELPER"
  emit_fix_plan --also-write-recovery-menu \
    "circuit-breaker" \
    "Trip reason." \
    "Trip context" \
    "/apex:forensics -- diagnose"
)
assert_pass "alias flag also writes RECOVERY_MENU.md" "[ -f '$SANDBOX_ALIAS/.apex/RECOVERY_MENU.md' ]"
assert_pass "RECOVERY_MENU.md is identical to FIX_PLAN.md" "diff -q '$SANDBOX_ALIAS/.apex/FIX_PLAN.md' '$SANDBOX_ALIAS/.apex/RECOVERY_MENU.md' >/dev/null"
rm -rf "$SANDBOX_ALIAS"

# 4. Each blocking guard sources the helper
for g in path-guard.sh destructive-guard.sh workflow-guard.sh quarantine-guard.sh \
         schema-drift.sh phantom-check.sh post-write.sh circuit-breaker.sh; do
  assert_pass "$g sources _fix-plan-emit" \
    "grep -q '_fix-plan-emit' '$HOOKS_DIR/$g'"
done

# 5. Behavioral: trigger each blocking guard and assert FIX_PLAN.md.

# 5a. path-guard — block on .env file write
SANDBOX_PG=$(run_sandbox)
( cd "$SANDBOX_PG" && APEX_FIX_PLAN_FILE="$SANDBOX_PG/.apex/FIX_PLAN.md" mkdir -p .apex && \
  APEX_FIX_PLAN_FILE="$SANDBOX_PG/.apex/FIX_PLAN.md" bash "$HOOKS_DIR/path-guard.sh" ".env" >/dev/null 2>&1 )
EXIT_PG=$?
assert_pass "path-guard exits 2 on .env" "[ $EXIT_PG -eq 2 ]"
assert_pass "path-guard wrote FIX_PLAN.md" "[ -f '$SANDBOX_PG/.apex/FIX_PLAN.md' ]"
assert_pass "path-guard FIX_PLAN cites path-guard" "grep -q 'path-guard' '$SANDBOX_PG/.apex/FIX_PLAN.md'"
rm -rf "$SANDBOX_PG"

# 5b. destructive-guard — block on rm -rf /
SANDBOX_DG=$(run_sandbox)
( cd "$SANDBOX_DG" && mkdir -p .apex && \
  APEX_FIX_PLAN_FILE="$SANDBOX_DG/.apex/FIX_PLAN.md" bash "$HOOKS_DIR/destructive-guard.sh" "rm -rf /" >/dev/null 2>&1 )
EXIT_DG=$?
assert_pass "destructive-guard exits 2 on rm -rf /" "[ $EXIT_DG -eq 2 ]"
assert_pass "destructive-guard wrote FIX_PLAN.md" "[ -f '$SANDBOX_DG/.apex/FIX_PLAN.md' ]"
rm -rf "$SANDBOX_DG"

# 5c. quarantine-guard — block on impl path under auditor agent
SANDBOX_QG=$(run_sandbox)
( cd "$SANDBOX_QG" && mkdir -p .apex && \
  APEX_FIX_PLAN_FILE="$SANDBOX_QG/.apex/FIX_PLAN.md" \
  APEX_ACTIVE_AGENT=auditor bash "$HOOKS_DIR/quarantine-guard.sh" "src/foo.ts" >/dev/null 2>&1 )
EXIT_QG=$?
assert_pass "quarantine-guard exits 2 on auditor read of impl" "[ $EXIT_QG -eq 2 ]"
assert_pass "quarantine-guard wrote FIX_PLAN.md" "[ -f '$SANDBOX_QG/.apex/FIX_PLAN.md' ]"
rm -rf "$SANDBOX_QG"

# 5d. schema-drift — block on invalid JSON .apex/STATE.json
if command -v jq >/dev/null 2>&1; then
  SANDBOX_SD=$(run_sandbox)
  mkdir -p "$SANDBOX_SD/.apex"
  echo "not-json" > "$SANDBOX_SD/.apex/STATE.json"
  ( cd "$SANDBOX_SD" && \
    APEX_FIX_PLAN_FILE="$SANDBOX_SD/.apex/FIX_PLAN.md" \
    bash "$HOOKS_DIR/schema-drift.sh" "$SANDBOX_SD/.apex/STATE.json" >/dev/null 2>&1 )
  EXIT_SD=$?
  assert_pass "schema-drift exits 2 on invalid JSON" "[ $EXIT_SD -eq 2 ]"
  assert_pass "schema-drift wrote FIX_PLAN.md" "[ -f '$SANDBOX_SD/.apex/FIX_PLAN.md' ]"
  rm -rf "$SANDBOX_SD"
fi

# 5e. phantom-check — behavioral assertion (R6-001: BRE→ERE fix landed).
# A SUMMARY containing uncertainty language ("should pass") MUST cause
# phantom-check.sh to exit 2 and to write FIX_PLAN.md.
SANDBOX_PC=$(run_sandbox)
mkdir -p "$SANDBOX_PC/.apex"
printf 'Tests should pass.\n' > "$SANDBOX_PC/.apex/SUMMARY.md"
( cd "$SANDBOX_PC" && \
  APEX_FIX_PLAN_FILE="$SANDBOX_PC/.apex/FIX_PLAN.md" \
  bash "$HOOKS_DIR/phantom-check.sh" "$SANDBOX_PC/.apex/SUMMARY.md" >/dev/null 2>&1 )
EXIT_PC=$?
assert_pass "phantom-check exits 2 on uncertainty language (R6-001)" "[ $EXIT_PC -eq 2 ]"
assert_pass "phantom-check wrote FIX_PLAN.md (R6-001)" "[ -f '$SANDBOX_PC/.apex/FIX_PLAN.md' ]"
rm -rf "$SANDBOX_PC"

# 5f. post-write — block on hardcoded secret
SANDBOX_PW=$(run_sandbox)
mkdir -p "$SANDBOX_PW/.apex"
echo 'const password: "abcdef1234567890"' > "$SANDBOX_PW/leak.ts"
( cd "$SANDBOX_PW" && \
  APEX_FIX_PLAN_FILE="$SANDBOX_PW/.apex/FIX_PLAN.md" \
  bash "$HOOKS_DIR/post-write.sh" "$SANDBOX_PW/leak.ts" >/dev/null 2>&1 )
EXIT_PW=$?
assert_pass "post-write exits 2 on hardcoded secret" "[ $EXIT_PW -eq 2 ]"
assert_pass "post-write wrote FIX_PLAN.md" "[ -f '$SANDBOX_PW/.apex/FIX_PLAN.md' ]"
rm -rf "$SANDBOX_PW"

# 5g. circuit-breaker — alias path test (v8 IMP-V8-CB2 unhealthy fire branch)
# Phase-7 R-AT-P7-06: under v8 the cap-trip path requires BOTH the cap
# reached AND a failed health probe to fire exit 2. Set STALE_DELTA =
# TOTAL - TC_AT_CHANGE = 60 - 0 = 60 > 50 (probe 1 stagnant detection).
if command -v jq >/dev/null 2>&1; then
  SANDBOX_CB=$(run_sandbox)
  mkdir -p "$SANDBOX_CB/.apex"
  cat > "$SANDBOX_CB/.apex/STATE.json" <<'EOF'
{
  "circuit_breaker": {
    "consecutive_no_change_actions": 0,
    "max_allowed": 3,
    "last_file_hash": "",
    "max_tool_calls_per_task": 60,
    "total_tool_calls_this_task": 60,
    "tool_calls_at_last_change": 0,
    "cap_original": 60,
    "triggered": false
  }
}
EOF
  ( cd "$SANDBOX_CB" && bash "$HOOKS_DIR/circuit-breaker.sh" >/dev/null 2>&1 )
  EXIT_CB=$?
  assert_pass "circuit-breaker exits 2 on tool-call cap" "[ $EXIT_CB -eq 2 ]"
  assert_pass "circuit-breaker wrote FIX_PLAN.md (new path)" "[ -f '$SANDBOX_CB/.apex/FIX_PLAN.md' ]"
  assert_pass "circuit-breaker wrote RECOVERY_MENU.md (alias)" "[ -f '$SANDBOX_CB/.apex/RECOVERY_MENU.md' ]"
  rm -rf "$SANDBOX_CB"
fi

# 6. walkthrough.md and recover.md reference FIX_PLAN.md
WALKTHROUGH="$REPO_ROOT/framework/commands/apex/walkthrough.md"
RECOVER="$REPO_ROOT/framework/commands/apex/recover.md"
assert_pass "walkthrough.md references FIX_PLAN.md" "grep -q 'FIX_PLAN.md' '$WALKTHROUGH'"
assert_pass "recover.md references FIX_PLAN.md"     "grep -q 'FIX_PLAN.md' '$RECOVER'"
assert_pass "recover.md still references RECOVERY_MENU.md (backward compat)" "grep -q 'RECOVERY_MENU' '$RECOVER'"

echo
echo "=== Results: PASS=$PASS FAIL=$FAIL ==="
# R9-002: bridge private counters into harness globals once.
if declare -F harness_assert_local >/dev/null 2>&1; then
  harness_assert_local "$PASS" "$FAIL" "test-fix-plan-emit"
fi
if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
exit 0
