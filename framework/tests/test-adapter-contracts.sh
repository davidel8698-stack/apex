#!/usr/bin/env bash
# R5-025: adapter-contract validation.
#
# Spec anchors:
#   "multi-agent framework ופלטפורמה לסוכני קוד … דרך thin adapters"
#   "Multi-platform from day one."
#
# Asserts:
#   1. framework/adapters/adapter-contract.md exists.
#   2. framework/adapters/claude-code/adapter.json exists, valid JSON,
#      conforms to the contract (required fields, recognized enum values).
#   3. framework/adapters/cursor/adapter.json exists, valid JSON,
#      conforms to the contract.
#   4. framework/scripts/sync-to-cursor.sh runs in --dry-run without error.
#   5. framework/docs/MULTI-PLATFORM.md exists.
#   6. sync-to-claude.sh references the adapter contract in a comment.
#   7. At least one non-Claude-Code adapter is present (the multi-platform
#      day-one commitment).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ADAPTERS_DIR="$REPO_ROOT/framework/adapters"
CONTRACT_MD="$ADAPTERS_DIR/adapter-contract.md"
CC_JSON="$ADAPTERS_DIR/claude-code/adapter.json"
CURSOR_JSON="$ADAPTERS_DIR/cursor/adapter.json"
CURSOR_SH="$REPO_ROOT/framework/scripts/sync-to-cursor.sh"
MULTI_MD="$REPO_ROOT/framework/docs/MULTI-PLATFORM.md"
CLAUDE_SH="$REPO_ROOT/framework/scripts/sync-to-claude.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not available — adapter manifest validation requires jq"
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

validate_manifest() {
  local label="$1" file="$2"
  echo
  echo "[manifest] $label ($file)"
  assert_pass "$label: file exists"               "test -f '$file'"
  assert_pass "$label: parses as JSON"            "jq empty '$file' 2>/dev/null"
  assert_pass "$label: has schema_version"        "jq -e '.schema_version' '$file'"
  assert_pass "$label: has platform"              "jq -e '.platform' '$file'"
  assert_pass "$label: has display_name"          "jq -e '.display_name' '$file'"
  assert_pass "$label: status is recognized"      "jq -e '.status | IN(\"canonical\", \"active\", \"stub\")' '$file'"
  assert_pass "$label: has paths.agents"          "jq -e '.paths.agents' '$file'"
  assert_pass "$label: has paths.commands"        "jq -e '.paths.commands' '$file'"
  assert_pass "$label: has paths.settings"        "jq -e '.paths.settings' '$file'"
  assert_pass "$label: has settings_format"       "jq -e '.settings_format' '$file'"
  assert_pass "$label: hook_protocol.supported is recognized" \
    "jq -e '.hook_protocol.supported | IN(\"full\", \"partial\", \"none\")' '$file'"
  assert_pass "$label: agent_dispatch.convention present" \
    "jq -e '.agent_dispatch.convention' '$file'"
  assert_pass "$label: deferred is array"         "jq -e '.deferred | type == \"array\"' '$file'"
  assert_pass "$label: delivers is non-empty array" \
    "jq -e '.delivers | type == \"array\" and length > 0' '$file'"
}

echo "=== R5-025: adapter contract tests ==="

# --- Contract document + multi-platform doc ---
echo
echo "[docs] contract + multi-platform pages"
assert_pass "adapter-contract.md exists" "test -f '$CONTRACT_MD'"
assert_pass "MULTI-PLATFORM.md exists" "test -f '$MULTI_MD'"

# --- Manifest validation ---
validate_manifest "claude-code" "$CC_JSON"
validate_manifest "cursor"      "$CURSOR_JSON"

# --- claude-code-specific assertions ---
echo
echo "[canonical] claude-code adapter assertions"
assert_pass "claude-code: status == canonical" \
  "[ \"\$(jq -r '.status' '$CC_JSON')\" = 'canonical' ]"
assert_pass "claude-code: hook_protocol.supported == full" \
  "[ \"\$(jq -r '.hook_protocol.supported' '$CC_JSON')\" = 'full' ]"
assert_pass "claude-code: delivers includes hooks and settings" \
  "jq -e '(.delivers | index(\"hooks\")) and (.delivers | index(\"settings\"))' '$CC_JSON'"

# --- cursor-specific assertions ---
echo
echo "[active stub] cursor adapter assertions"
assert_pass "cursor: status == active" \
  "[ \"\$(jq -r '.status' '$CURSOR_JSON')\" = 'active' ]"
assert_pass "cursor: hook_protocol.supported == none" \
  "[ \"\$(jq -r '.hook_protocol.supported' '$CURSOR_JSON')\" = 'none' ]"
assert_pass "cursor: delivers includes agents and commands" \
  "jq -e '(.delivers | index(\"agents\")) and (.delivers | index(\"commands\"))' '$CURSOR_JSON'"

# --- Sync-to-cursor dry-run ---
echo
echo "[script] sync-to-cursor.sh dry-run"
assert_pass "sync-to-cursor.sh exists and is executable" \
  "test -f '$CURSOR_SH'"
DRY_OUT="$(bash "$CURSOR_SH" --dry-run 2>&1)"
DRY_RC=$?
assert_pass "sync-to-cursor.sh --dry-run exits 0" \
  "[ $DRY_RC -eq 0 ]"
assert_pass "sync-to-cursor.sh --dry-run prints adapter status" \
  "echo \"$DRY_OUT\" | grep -q 'adapter status'"

# --- sync-to-claude.sh annotation (R5-025 soft-append) ---
echo
echo "[annotation] sync-to-claude.sh references the adapter contract"
assert_pass "sync-to-claude.sh references adapter-contract.md" \
  "grep -q 'adapter-contract.md' '$CLAUDE_SH'"

# --- Multi-platform invariant: at least one non-Claude-Code adapter ---
echo
echo "[invariant] multi-platform from day one"
NON_CC_COUNT=$(find "$ADAPTERS_DIR" -mindepth 2 -maxdepth 2 -name 'adapter.json' \
  ! -path "*/claude-code/*" 2>/dev/null | wc -l)
assert_pass "at least one non-Claude-Code adapter exists" \
  "[ \"$NON_CC_COUNT\" -ge 1 ]"

echo
echo "=== Results: PASS=$PASS FAIL=$FAIL ==="
if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
exit 0
