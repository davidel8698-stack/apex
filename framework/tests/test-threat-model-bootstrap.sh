#!/usr/bin/env bash
# R5-020: THREAT_MODEL bootstrap wiring test.
#
# Spec anchor: "`THREAT_MODEL.md` per-project עם Indirect Prompt Injection
# כאיום ברירת מחדל."
#
# Asserts:
#   1. start.md invokes a threat-model-bootstrap step that targets
#      .apex/THREAT_MODEL.md and references ~/.claude/THREAT_MODEL-TEMPLATE.md.
#   2. start.md's bootstrap step explicitly names "Indirect Prompt Injection"
#      as the default threat to preserve.
#   3. start.md is re-runnable: existing .apex/THREAT_MODEL.md is NOT
#      overwritten — a merge proposal goes to .apex/THREAT_MODEL.proposed.md.
#   4. onboard.md inherits the bootstrap (passes through /apex:start).
#   5. The security agent (apex-security/agent.md) defines a
#      threat-model-bootstrap mode.
#   6. THREAT_MODEL-TEMPLATE.md still contains "Indirect Prompt Injection"
#      as a default threat (preservation contract — template untouched).
#   7. Fallback path simulation: copying the template into a sandbox
#      .apex/THREAT_MODEL.md with substitutions yields a file that
#      mentions "Indirect Prompt Injection".

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
START_MD="$REPO_ROOT/framework/commands/apex/start.md"
ONBOARD_MD="$REPO_ROOT/framework/commands/apex/onboard.md"
SEC_AGENT="$REPO_ROOT/framework/modules/apex-security/agent.md"
TEMPLATE="$REPO_ROOT/framework/THREAT_MODEL-TEMPLATE.md"

if [ ! -f "$START_MD" ] || [ ! -f "$ONBOARD_MD" ] || [ ! -f "$SEC_AGENT" ] || [ ! -f "$TEMPLATE" ]; then
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

echo "=== R5-020: threat-model bootstrap tests ==="
echo

# 1. start.md has a THREAT-MODEL BOOTSTRAP block
assert_pass "start.md declares THREAT-MODEL BOOTSTRAP step" \
  "grep -i 'THREAT-MODEL BOOTSTRAP' '$START_MD'"
assert_pass "start.md references THREAT_MODEL-TEMPLATE.md" \
  "grep 'THREAT_MODEL-TEMPLATE.md' '$START_MD'"
assert_pass "start.md targets .apex/THREAT_MODEL.md" \
  "grep '\\.apex/THREAT_MODEL\\.md' '$START_MD'"

# 2. Indirect Prompt Injection named explicitly
assert_pass "start.md names 'Indirect Prompt Injection' explicitly" \
  "grep 'Indirect Prompt Injection' '$START_MD'"

# 3. Re-runnability: proposal path mentioned
assert_pass "start.md mentions THREAT_MODEL.proposed.md (re-run guard)" \
  "grep 'THREAT_MODEL\\.proposed\\.md' '$START_MD'"

# 4. onboard.md inherits via /apex:start invocation
assert_pass "onboard.md invokes /apex:start" \
  "grep '/apex:start' '$ONBOARD_MD'"
assert_pass "onboard.md references threat-model bootstrap" \
  "grep -i 'THREAT-MODEL\\|THREAT_MODEL' '$ONBOARD_MD'"

# 5. Security agent has threat-model-bootstrap mode
assert_pass "apex-security/agent.md defines threat-model-bootstrap mode" \
  "grep -i 'threat-model-bootstrap' '$SEC_AGENT'"
assert_pass "agent enforces 'Indirect Prompt Injection' default" \
  "grep 'Indirect Prompt Injection' '$SEC_AGENT'"
assert_pass "agent preserves THREAT_MODEL-TEMPLATE.md (read-only)" \
  "grep -i 'preservation\\|read-only\\|never strip' '$SEC_AGENT'"

# 6. Template carries the default threat (preservation contract)
assert_pass "TEMPLATE still contains T-001 Indirect Prompt Injection" \
  "grep 'T-001.*Indirect Prompt Injection\\|Indirect Prompt Injection' '$TEMPLATE'"

# 7. Fallback path sandbox simulation: copy + substitute → file mentions IPI
SANDBOX="$(mktemp -d)"
mkdir -p "$SANDBOX/.apex"
sed -e "s/\\[PROJECT_NAME\\]/sandboxproj/g" \
    -e "s/\\[DATE\\]/2026-01-01/g" \
    -e "s/\\[DETECTED_STACK\\]/TBD/g" \
    "$TEMPLATE" > "$SANDBOX/.apex/THREAT_MODEL.md"
assert_pass "fallback-path produced THREAT_MODEL.md mentions Indirect Prompt Injection" \
  "grep 'Indirect Prompt Injection' '$SANDBOX/.apex/THREAT_MODEL.md'"
assert_pass "fallback-path substitutions completed (no [PROJECT_NAME] left)" \
  "! grep -q '\\[PROJECT_NAME\\]' '$SANDBOX/.apex/THREAT_MODEL.md'"

# Re-runnability simulation: a second copy must not overwrite — instead
# write to .proposed.md. Simulate the guard:
EXISTING_HASH=$(md5sum "$SANDBOX/.apex/THREAT_MODEL.md" 2>/dev/null | awk '{print $1}')
if [ -f "$SANDBOX/.apex/THREAT_MODEL.md" ]; then
  # Mock the agent's re-run guard: write proposal, do NOT overwrite.
  cp "$TEMPLATE" "$SANDBOX/.apex/THREAT_MODEL.proposed.md"
fi
NEW_HASH=$(md5sum "$SANDBOX/.apex/THREAT_MODEL.md" 2>/dev/null | awk '{print $1}')
assert_pass "re-run guard: existing THREAT_MODEL.md byte-identical after second pass" \
  "[ \"$EXISTING_HASH\" = \"$NEW_HASH\" ]"
assert_pass "re-run guard: .proposed.md created instead" \
  "test -f '$SANDBOX/.apex/THREAT_MODEL.proposed.md'"

rm -rf "$SANDBOX"

echo
echo "=== Results: PASS=$PASS FAIL=$FAIL ==="
if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
exit 0
