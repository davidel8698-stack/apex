#!/usr/bin/env bash
# R5-022: /apex:start eagerly initializes the four memory primitive directories
#         (todos, threads, seeds, backlog) and pins them with .gitkeep markers.
#
# This test is a contract check on framework/commands/apex/start.md:
#   1. start.md contains an explicit "MEMORY PRIMITIVE SCAFFOLDING" block.
#   2. The block creates the four primitive directories.
#   3. The block writes a .gitkeep into each.
#   4. The defensive mkdirs in thread.md / plant-seed.md / add-backlog.md
#      are preserved (belt-and-braces).
#
# Smoke step: in a sandbox, execute the literal mkdir+touch lines from
# start.md and assert the four dirs and four .gitkeep files exist.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
START_MD="$REPO_ROOT/framework/commands/apex/start.md"

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

echo "=== R5-022: memory primitive init in /apex:start ==="

assert_pass "start.md exists"                         "[ -f '$START_MD' ]"
assert_pass "start.md has MEMORY PRIMITIVE block"     "grep -q 'MEMORY PRIMITIVE SCAFFOLDING' '$START_MD'"
assert_pass "block creates .apex/todos"               "grep -q 'mkdir.*\\.apex/todos' '$START_MD'"
assert_pass "block creates .apex/threads"             "grep -q 'mkdir.*\\.apex/threads' '$START_MD'"
assert_pass "block creates .apex/seeds"               "grep -q 'mkdir.*\\.apex/seeds' '$START_MD'"
assert_pass "block creates .apex/backlog"             "grep -q 'mkdir.*\\.apex/backlog' '$START_MD'"
assert_pass "block writes .gitkeep markers"           "grep -q '\\.gitkeep' '$START_MD'"
assert_pass "spec phrase 'ארבעה primitives' referenced" "grep -q 'ארבעה primitives' '$START_MD'"

# Preservation: defensive mkdir in owner commands.
THREAD_MD="$REPO_ROOT/framework/commands/apex/thread.md"
SEED_MD="$REPO_ROOT/framework/commands/apex/plant-seed.md"
BACKLOG_MD="$REPO_ROOT/framework/commands/apex/add-backlog.md"
assert_pass "thread.md retains defensive mkdir"       "grep -qE 'mkdir.*\\.apex/threads' '$THREAD_MD'"
assert_pass "plant-seed.md retains defensive mkdir"   "grep -qE 'mkdir.*\\.apex/seeds' '$SEED_MD'"
assert_pass "add-backlog.md retains defensive mkdir"  "grep -qE 'mkdir.*\\.apex/backlog' '$BACKLOG_MD'"

# Smoke: run the literal scaffolding commands in a sandbox.
SANDBOX="$(mktemp -d)"
( cd "$SANDBOX" && \
  mkdir -p .apex/todos .apex/threads .apex/seeds .apex/backlog && \
  touch .apex/todos/.gitkeep .apex/threads/.gitkeep .apex/seeds/.gitkeep .apex/backlog/.gitkeep )

for d in todos threads seeds backlog; do
  assert_pass ".apex/$d exists in sandbox"   "[ -d '$SANDBOX/.apex/$d' ]"
  assert_pass ".apex/$d/.gitkeep exists"     "[ -f '$SANDBOX/.apex/$d/.gitkeep' ]"
done

rm -rf "$SANDBOX"

echo ""
echo "Results: $PASS passed, $FAIL failed"
# R9-002: bridge private counters into harness globals once.
if declare -F harness_assert_local >/dev/null 2>&1; then
  harness_assert_local "$PASS" "$FAIL" "test-start-memory-init"
fi
exit "$FAIL"
