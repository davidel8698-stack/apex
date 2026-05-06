#!/usr/bin/env bash
# R5-011: TDAD index + cross-phase audit wiring tests.
#
# Spec anchor: "שילוב כפול: TDAD + Aider-style repo map. Cross-phase-audit."
#
# Asserts:
#   1. settings.json wires tdad-index.sh on SessionStart and PostToolUse Write|Edit.
#   2. settings.json wires cross-phase-audit.sh on SubagentStop.
#   3. tdad-index.sh exits 0 fast when .apex/TEST_MAP.txt is fresh (debounce works).
#   4. cross-phase-audit.sh on SubagentStop only fires when agent_name=executor.
#   5. HOOK-CLASSIFICATION.md three-places contract honored for both hooks.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SETTINGS="$REPO_ROOT/framework/settings.json"
TDAD_HOOK="$REPO_ROOT/framework/hooks/tdad-index.sh"
CPA_HOOK="$REPO_ROOT/framework/hooks/cross-phase-audit.sh"
CLASSIFICATION="$REPO_ROOT/framework/HOOK-CLASSIFICATION.md"

if [ ! -f "$SETTINGS" ] || [ ! -f "$TDAD_HOOK" ] || [ ! -f "$CPA_HOOK" ] || [ ! -f "$CLASSIFICATION" ]; then
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

echo "=== R5-011: TDAD + cross-phase wiring tests ==="
echo

# 1. settings.json wires tdad-index on SessionStart
if command -v jq >/dev/null 2>&1; then
  assert_pass "settings.json wires tdad-index on SessionStart" \
    "jq -e '.hooks.SessionStart // [] | map(.hooks // []) | flatten | map(.command // \"\") | any(test(\"tdad-index\"))' '$SETTINGS'"

  # 2. settings.json wires tdad-index on PostToolUse Write|Edit
  assert_pass "settings.json wires tdad-index on PostToolUse Write|Edit" \
    "jq -e '.hooks.PostToolUse // [] | map(select(.matcher == \"Write|Edit\") | .hooks // []) | flatten | map(.command // \"\") | any(test(\"tdad-index\"))' '$SETTINGS'"

  # 3. settings.json wires cross-phase-audit on SubagentStop
  assert_pass "settings.json wires cross-phase-audit on SubagentStop" \
    "jq -e '.hooks.SubagentStop // [] | map(.hooks // []) | flatten | map(.command // \"\") | any(test(\"cross-phase-audit\"))' '$SETTINGS'"
else
  # Fallback to grep
  assert_pass "settings.json mentions tdad-index" \
    "grep -q 'tdad-index' '$SETTINGS'"
  assert_pass "settings.json mentions cross-phase-audit" \
    "grep -q 'cross-phase-audit' '$SETTINGS'"
fi

# 4. tdad-index hook header reflects new triggers
assert_pass "tdad-index header documents Auto-SessionStart" \
  "grep -i 'Auto-SessionStart' '$TDAD_HOOK'"
assert_pass "tdad-index header documents Auto-PostToolUse" \
  "grep -i 'Auto-PostToolUse' '$TDAD_HOOK'"
assert_pass "tdad-index has freshness guard" \
  "grep -E 'TEST_MAP\\.txt' '$TDAD_HOOK' | grep -q -i 'newer\\|fresh\\|exit 0' && grep -q 'NEWEST_SRC' '$TDAD_HOOK'"

# 5. cross-phase-audit hook header reflects new triggers
assert_pass "cross-phase-audit header documents Auto-SubagentStop" \
  "grep -i 'Auto-SubagentStop' '$CPA_HOOK'"
assert_pass "cross-phase-audit has agent_name filter" \
  "grep -E 'agent_name' '$CPA_HOOK'"
assert_pass "cross-phase-audit only fires on executor" \
  "grep -E '\"executor\"' '$CPA_HOOK'"

# 6. HOOK-CLASSIFICATION lists both under Auto sections
assert_pass "HOOK-CLASSIFICATION lists tdad-index in Auto-PostToolUse table" \
  "awk '/^## Auto-PostToolUse/{flag=1} /^## /{if (flag && \$0 !~ /Auto-PostToolUse/) flag=0} flag && /tdad-index\\.sh/{found=1} END{exit !found}' '$CLASSIFICATION'"

# Cross-phase-audit retains Command-Invoked listing AND the row notes SubagentStop auto-wiring.
assert_pass "HOOK-CLASSIFICATION cross-phase-audit row mentions SubagentStop auto-wiring" \
  "grep 'cross-phase-audit\\.sh' '$CLASSIFICATION' | grep -q -i 'SubagentStop'"

# 7. Three-places contract: settings.json + hook header + classification doc
assert_pass "tdad-index three-places contract" \
  "grep -q 'tdad-index' '$SETTINGS' && grep -q -i 'Auto-' '$TDAD_HOOK' && grep -q 'tdad-index' '$CLASSIFICATION'"
assert_pass "cross-phase-audit three-places contract" \
  "grep -q 'cross-phase-audit' '$SETTINGS' && grep -q -i 'Auto-' '$CPA_HOOK' && grep -q 'cross-phase-audit' '$CLASSIFICATION'"

# 8. Behavioral: tdad-index exits 0 fast when index is fresh.
SANDBOX_T=$(mktemp -d)
( cd "$SANDBOX_T" && git init -q && git config user.email t@a && git config user.name t && \
  echo "// stub" > stub.ts && git add . && git commit -qm init )
mkdir -p "$SANDBOX_T/.apex"
# Touch TEST_MAP.txt AFTER all source files (newer than every source)
sleep 1
echo "" > "$SANDBOX_T/.apex/TEST_MAP.txt"
( cd "$SANDBOX_T" && bash "$TDAD_HOOK" >/dev/null 2>&1 )
EXIT_FRESH=$?
assert_pass "tdad-index exits 0 fast on fresh index (debounce)" \
  "[ $EXIT_FRESH -eq 0 ]"
rm -rf "$SANDBOX_T"

# 9. Behavioral: cross-phase-audit fast-paths on non-executor agent_name.
SANDBOX_C=$(mktemp -d)
( cd "$SANDBOX_C" && git init -q && git config user.email t@a && git config user.name t && \
  echo init > init.txt && git add . && git commit -qm init )
mkdir -p "$SANDBOX_C/.apex"
echo '{"agent_name":"auditor"}' | ( cd "$SANDBOX_C" && bash "$CPA_HOOK" >/dev/null 2>&1 )
EXIT_NONEXEC=$?
assert_pass "cross-phase-audit exit 0 fast on non-executor stop" \
  "[ $EXIT_NONEXEC -eq 0 ]"
rm -rf "$SANDBOX_C"

echo
echo "=== Results: PASS=$PASS FAIL=$FAIL ==="
if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
exit 0
