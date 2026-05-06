#!/usr/bin/env bash
# R5-008: Quarantine guard regex tightening — anchored test paths only
# Verifies the regex no longer admits implementation files via substring match.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GUARD="$REPO_ROOT/framework/hooks/quarantine-guard.sh"

if [ ! -f "$GUARD" ]; then
  echo "FAIL: quarantine-guard.sh not found at $GUARD" >&2
  exit 1
fi

PASS=0
FAIL=0

run_case() {
  local label="$1" path="$2" expected="$3"  # expected: 0=allow, 2=block
  APEX_ACTIVE_AGENT=auditor bash "$GUARD" "$path" >/dev/null 2>&1
  local code=$?
  if [ "$code" -eq "$expected" ]; then
    echo "  PASS: $label (got $code)"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $label (expected $expected, got $code)"
    FAIL=$((FAIL+1))
  fi
}

echo "=== R5-008: Quarantine regex tightening ==="

# NEGATIVE cases — must NOT match (block, exit 2)
run_case "apex-spec.md is implementation"            "apex-spec.md"                              2
run_case "specialist agent is implementation"        "framework/agents/specialist/data.md"       2
run_case "docs/specification.md is implementation"   "docs/specification.md"                     2
run_case "specialist (no slash) blocked"             "specialist.md"                             2

# POSITIVE cases — must match (allow, exit 0)
run_case "framework tests directory allowed"         "framework/tests/test-hooks-prompt-guard.sh" 0
run_case ".test. file allowed"                       "src/foo.test.ts"                           0
run_case ".spec. file allowed"                       "src/foo.spec.ts"                           0
run_case "__tests__ dir allowed"                     "src/__tests__/y.js"                        0
run_case "test_ prefix allowed"                      "test_z.py"                                 0
run_case ".apex/ state allowed"                      ".apex/STATE.json"                          0

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit "$FAIL"
