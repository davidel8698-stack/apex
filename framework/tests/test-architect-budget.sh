#!/usr/bin/env bash
# R13-003 (F-303): architect input-budget cap enforcement.
#
# Spec anchors:
#   R2-C194 (HIGH 5/5): "Orchestrator-specific budget: 10-15% MAX —
#   passes file paths and typed task specs, not file contents."
#   "Coordinator + fresh workers > monolithic." (apex-spec.md)
#
# Closes the F-303 spec-drift by asserting:
#   (a) Fixture-based size cap: the architect prompt body, measured by
#       byte count and converted at the ~4 chars/token approximation,
#       must remain ≤ 30000 tokens (≤ 120000 chars).
#   (b) Config sanity: CONTEXT_BUDGET.default.json has
#       per_agent_limits.architect.max_input == 30000 and
#       per_agent_limits.architect.target_input == 20000.
#   (c) Reminder presence: architect.md contains the "MUST stay under
#       30K" reminder string that R13-003 prepended in front of STEP 0.
#   (d) Commented placeholder: a real-call assertion is shipped as
#       SKIPPED. R12-001's token-counter library is now live, so the
#       hook layer can measure architect prompt size at runtime, but
#       R13-003 intentionally ships the assertion commented-out for
#       surface-minimal change. A future round activates it.
#
# Harness conventions (R10-008 + R11-003):
#   LOCAL_PASS / LOCAL_FAIL are file-scope counters (NOT named PASS/
#   FAIL — those are harness-owned globals). End-of-file calls
#   harness_assert_local to bridge into the runner banner.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$REPO_ROOT/framework/CONTEXT_BUDGET.default.json"
ARCHITECT_MD="$REPO_ROOT/framework/agents/architect.md"

# shellcheck source=_test-utils.sh
[ -f "$SCRIPT_DIR/_test-utils.sh" ] && source "$SCRIPT_DIR/_test-utils.sh"

LOCAL_PASS=0
LOCAL_FAIL=0

_pass() { echo "  PASS: $1"; LOCAL_PASS=$((LOCAL_PASS + 1)); }
_fail() { echo "  FAIL: $1" >&2; LOCAL_FAIL=$((LOCAL_FAIL + 1)); }

echo "=== R13-003: architect input-budget cap ==="

# Pre-flight: required artifacts exist.
if [ ! -f "$CONFIG" ]; then
  _fail "pre-flight: CONTEXT_BUDGET.default.json not found at $CONFIG"
  echo "test-architect-budget.sh: LOCAL_PASS=$LOCAL_PASS LOCAL_FAIL=$LOCAL_FAIL"
  exit 1
fi
if [ ! -f "$ARCHITECT_MD" ]; then
  _fail "pre-flight: agents/architect.md not found at $ARCHITECT_MD"
  echo "test-architect-budget.sh: LOCAL_PASS=$LOCAL_PASS LOCAL_FAIL=$LOCAL_FAIL"
  exit 1
fi

# ---- Test (b): config-sanity (run first; cheap, anchors the test) ----
if command -v jq >/dev/null 2>&1; then
  MAX_IN=$(jq -r '.per_agent_limits.architect.max_input' "$CONFIG" | tr -d '\r')
  TGT_IN=$(jq -r '.per_agent_limits.architect.target_input' "$CONFIG" | tr -d '\r')
  if [ "$MAX_IN" = "30000" ]; then
    _pass "test (b): per_agent_limits.architect.max_input == 30000"
  else
    _fail "test (b): per_agent_limits.architect.max_input expected 30000, got '$MAX_IN'"
  fi
  if [ "$TGT_IN" = "20000" ]; then
    _pass "test (b): per_agent_limits.architect.target_input == 20000"
  else
    _fail "test (b): per_agent_limits.architect.target_input expected 20000, got '$TGT_IN'"
  fi
else
  # jq-free fallback: grep the literal line. Sufficient for the file
  # format we author at; not a substitute for a real JSON validator.
  if grep -E '"architect"[[:space:]]*:[[:space:]]*\{[[:space:]]*"max_input"[[:space:]]*:[[:space:]]*30000,[[:space:]]*"target_input"[[:space:]]*:[[:space:]]*20000' "$CONFIG" >/dev/null 2>&1; then
    _pass "test (b): architect block matches max_input=30000 target_input=20000 (jq-less grep)"
  else
    _fail "test (b): architect block does not match 30000/20000 pattern (jq not available)"
  fi
fi

# ---- Test (c): reminder presence ----
if grep -q 'MUST stay under 30K' "$ARCHITECT_MD"; then
  _pass "test (c): 'MUST stay under 30K' reminder present in architect.md"
else
  _fail "test (c): 'MUST stay under 30K' reminder NOT found in architect.md"
fi

# ---- Test (a): fixture-based size cap ----
# Measure the architect prompt body by bytes; the conservative
# convention is 4 chars/token, so the 30000-token cap maps to 120000
# chars. The architect.md ships as the canonical fixture; the file is
# the actual prompt body the orchestrator dispatches.
ARCH_BYTES=$(wc -c < "$ARCHITECT_MD" | tr -d ' \r')
MAX_BYTES=120000
if [ "$ARCH_BYTES" -le "$MAX_BYTES" ]; then
  _pass "test (a): architect.md byte count $ARCH_BYTES <= $MAX_BYTES (30K tokens @ 4 chars/token)"
else
  _fail "test (a): architect.md byte count $ARCH_BYTES exceeds $MAX_BYTES (30K-token cap)"
fi

# ---- Test (d): commented placeholder for real-call assertion ----
# R12-001's _tokens-update.sh is live; a follow-up round may enable an
# end-to-end assertion that the architect's measured prompt size after
# a real /apex:next dispatch is ≤ 30000 tokens. R13-003 ships this
# assertion commented-out for surface-minimal change. The placeholder
# below documents the future-add and registers as SKIP.
#
# Future-add (when activated):
#   apex_tokens_update architect "$measured_input" 0 0 0 "$state_file"
#   measured_input=$(jq -r '.tokens.by_agent.architect.last_input' "$state_file")
#   [ "$measured_input" -le 30000 ] || _fail "real-call: measured architect input > 30K"
echo "  SKIP: test (d): real-call cap assertion shipped commented-out (R13-003 surface-minimal)"

# ---- Summary ----
echo ""
echo "test-architect-budget.sh: LOCAL_PASS=$LOCAL_PASS LOCAL_FAIL=$LOCAL_FAIL"
echo ""

if [ "${HARNESS_LOADED:-0}" = "1" ] || declare -F harness_assert_local >/dev/null 2>&1; then
  harness_assert_local "$LOCAL_PASS" "$LOCAL_FAIL" "test-architect-budget.sh"
fi

# Exit non-zero only on true failures.
exit "$LOCAL_FAIL"
