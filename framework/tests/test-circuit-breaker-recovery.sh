#!/usr/bin/env bash
# R5-005: Circuit breaker emits .apex/RECOVERY_MENU.md on trip
# Trips both the no-change-loop branch and the tool-call-cap branch
# in a sandbox repo and asserts the menu file is well-formed.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/framework/hooks/circuit-breaker.sh"

if [ ! -f "$HOOK" ]; then
  echo "FAIL: circuit-breaker.sh not found at $HOOK" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not available — circuit breaker requires jq"
  exit 0
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

echo "=== R5-005: Circuit breaker recovery menu ==="

# --- Case A: no-change loop trip ---
# Strategy: produce a deterministic non-empty diff (so CURRENT_HASH is content-addressable),
# pre-load STATE.json with last_file_hash == that hash and counter just under threshold,
# then invoke the hook once — increment + threshold check fires.
SANDBOX_A="$(run_sandbox)"
mkdir -p "$SANDBOX_A/.apex"

# Create a tracked modification we can hash.
( cd "$SANDBOX_A" && echo "modified-content" > modified.txt && git add modified.txt )

# Compute the hash exactly the same way circuit-breaker.sh does.
DIFF_OUT=$(cd "$SANDBOX_A" && git diff HEAD --stat 2>/dev/null)
if command -v shasum >/dev/null 2>&1; then
  HASH=$(printf '%s\n' "$DIFF_OUT" | shasum -a 256 | cut -d' ' -f1)
elif command -v md5sum >/dev/null 2>&1; then
  HASH=$(printf '%s\n' "$DIFF_OUT" | md5sum | cut -d' ' -f1)
else
  HASH=""
fi

cat > "$SANDBOX_A/.apex/STATE.json" <<EOF
{
  "circuit_breaker": {
    "consecutive_no_change_actions": 2,
    "max_allowed": 3,
    "last_file_hash": "$HASH",
    "max_tool_calls_per_task": 80,
    "total_tool_calls_this_task": 0,
    "triggered": false
  }
}
EOF

( cd "$SANDBOX_A" && bash "$HOOK" >/dev/null 2>&1 )
EXIT_A=$?

assert_pass "no-change loop exits 2"        "[ $EXIT_A -eq 2 ]"
assert_pass "RECOVERY_MENU.md was written"  "[ -f '$SANDBOX_A/.apex/RECOVERY_MENU.md' ]"
assert_pass "menu mentions /apex:forensics" "grep -q '/apex:forensics' '$SANDBOX_A/.apex/RECOVERY_MENU.md'"
assert_pass "menu mentions /apex:rollback"  "grep -q '/apex:rollback' '$SANDBOX_A/.apex/RECOVERY_MENU.md'"
assert_pass "menu mentions /apex:recover"   "grep -q '/apex:recover' '$SANDBOX_A/.apex/RECOVERY_MENU.md'"
assert_pass "menu has Reason header"        "grep -q '^## Reason' '$SANDBOX_A/.apex/RECOVERY_MENU.md'"
assert_pass "menu has Options header"       "grep -q '^## Options' '$SANDBOX_A/.apex/RECOVERY_MENU.md'"

rm -rf "$SANDBOX_A"

# --- Case B: tool-call cap trip ---
SANDBOX_B="$(run_sandbox)"
mkdir -p "$SANDBOX_B/.apex"
cat > "$SANDBOX_B/.apex/STATE.json" <<'EOF'
{
  "circuit_breaker": {
    "consecutive_no_change_actions": 0,
    "max_allowed": 3,
    "last_file_hash": "",
    "max_tool_calls_per_task": 2,
    "total_tool_calls_this_task": 2,
    "triggered": false
  }
}
EOF

( cd "$SANDBOX_B" && bash "$HOOK" >/dev/null 2>&1 )
EXIT_B=$?

assert_pass "tool-call cap exits 2"             "[ $EXIT_B -eq 2 ]"
assert_pass "tool-cap menu was written"         "[ -f '$SANDBOX_B/.apex/RECOVERY_MENU.md' ]"
assert_pass "tool-cap menu has three options"   "grep -c '/apex:' '$SANDBOX_B/.apex/RECOVERY_MENU.md' | awk '{ exit (\$1 < 3) }'"

rm -rf "$SANDBOX_B"

# --- Case C: stderr names the menu file path ---
SANDBOX_C="$(run_sandbox)"
mkdir -p "$SANDBOX_C/.apex"
cat > "$SANDBOX_C/.apex/STATE.json" <<'EOF'
{
  "circuit_breaker": {
    "consecutive_no_change_actions": 0,
    "max_allowed": 3,
    "last_file_hash": "",
    "max_tool_calls_per_task": 1,
    "total_tool_calls_this_task": 1,
    "triggered": false
  }
}
EOF

STDERR_C=$(cd "$SANDBOX_C" && bash "$HOOK" 2>&1 1>/dev/null)
echo "$STDERR_C" | grep -q "RECOVERY_MENU.md" && {
  echo "  PASS: stderr names RECOVERY_MENU.md"
  PASS=$((PASS+1))
} || {
  echo "  FAIL: stderr does not name RECOVERY_MENU.md"
  FAIL=$((FAIL+1))
}

rm -rf "$SANDBOX_C"

# --- Case D: recover.md references the menu ---
RECOVER_MD="$REPO_ROOT/framework/commands/apex/recover.md"
assert_pass "recover.md mentions RECOVERY_MENU.md" "grep -q 'RECOVERY_MENU' '$RECOVER_MD'"

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit "$FAIL"
