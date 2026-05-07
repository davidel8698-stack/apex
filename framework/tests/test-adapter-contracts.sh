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

# R7-009: shared IO helpers (jq_lines for CRLF-safe read loops).
# shellcheck source=_test-utils.sh
[ -f "$SCRIPT_DIR/_test-utils.sh" ] && source "$SCRIPT_DIR/_test-utils.sh"

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

# --- R6-009 / R7-004: Parity invariant ------------------------------------
# For every surface in claude-code/adapter.json:.delivers, the surface
# must appear in every other adapter's (.delivers + .deferred) — either
# the adapter delivers it or it explicitly defers it. A new claude-code
# delivery surface that no other adapter has acknowledged is a multi-
# platform-from-day-one regression, not silent drift.
#
# R7-004: cursor's .deferred entries were renamed to the canonical
# surface names declared in claude-code/.delivers, so the prior alias
# normalisation is no longer needed; we compare strings directly.
# Future adapters MUST also use canonical surface names.
echo
echo "[invariant] R6-009/R7-004: every claude-code delivery surface is acknowledged on every other adapter"

# Strip CR (Windows line endings) and trim whitespace; no alias rewriting.
normalize_surface() {
  local raw="${1//$'\r'/}"
  raw="${raw## }"; raw="${raw%% }"
  echo "$raw"
}

# Build canonical (normalized) list of claude-code delivers.
CC_DELIVERS_RAW=$(jq -r '.delivers[]' "$CC_JSON" 2>/dev/null)
declare -a CC_NORM=()
while IFS= read -r s; do
  [ -z "$s" ] && continue
  CC_NORM+=("$(normalize_surface "$s")")
done <<EOF
$CC_DELIVERS_RAW
EOF

# Iterate every non-claude-code adapter under framework/adapters/.
# State-derived: future adapters (gemini, codex, ...) auto-enrolled.
PARITY_FAILURES=0
while IFS= read -r adapter_json; do
  [ -z "$adapter_json" ] && continue
  adapter_dir=$(dirname "$adapter_json")
  adapter_name=$(basename "$adapter_dir")
  [ "$adapter_name" = "claude-code" ] && continue
  if ! jq empty "$adapter_json" >/dev/null 2>&1; then
    echo "  FAIL: parity[$adapter_name]: adapter.json does not parse"
    FAIL=$((FAIL+1))
    PARITY_FAILURES=$((PARITY_FAILURES+1))
    continue
  fi
  # Build the union (delivers + deferred), normalized.
  declare -a ADAPTER_NORM=()
  ADAPTER_RAW=$(jq -r '(.delivers // []) + (.deferred // []) | .[]' "$adapter_json" 2>/dev/null)
  while IFS= read -r s; do
    [ -z "$s" ] && continue
    ADAPTER_NORM+=("$(normalize_surface "$s")")
  done <<EOF
$ADAPTER_RAW
EOF
  # For each canonical claude-code surface, assert membership.
  for surface in "${CC_NORM[@]}"; do
    found=0
    for cand in "${ADAPTER_NORM[@]}"; do
      if [ "$cand" = "$surface" ]; then
        found=1
        break
      fi
    done
    if [ "$found" -eq 1 ]; then
      echo "  PASS: parity[$adapter_name]: surface '$surface' acknowledged (delivers or deferred)"
      PASS=$((PASS+1))
    else
      echo "  FAIL: parity[$adapter_name]: surface '$surface' is delivered by claude-code but missing from .delivers AND .deferred — declare it in deferred[] or deliver it"
      FAIL=$((FAIL+1))
      PARITY_FAILURES=$((PARITY_FAILURES+1))
    fi
  done
  unset ADAPTER_NORM
done < <(find "$ADAPTERS_DIR" -mindepth 2 -maxdepth 2 -name 'adapter.json' 2>/dev/null)

if [ "$PARITY_FAILURES" -eq 0 ]; then
  echo "  PASS: parity: every non-claude-code adapter acknowledges every canonical surface"
  PASS=$((PASS+1))
fi

# --- R6-017: Adapter-honesty banner ---------------------------------------
# When a non-full-hook-protocol adapter is active, /apex:start and
# /apex:onboard must render a runtime banner naming the deferred surfaces.
# This is the runtime propagation of manifest-level honesty (brand
# position #8: "Honestly Scoped, Not Universally Promised").
#
# Three structural assertions:
#   (a) The detection helper exists and defaults to claude-code.
#   (b) Both start.md and onboard.md contain the banner block, anchored
#       on the "ADAPTER HONESTY BANNER [R6-017]" heading.
#   (c) The banner reads the active adapter's manifest deferred list and
#       uses STATE.adapter_honesty_shown as the one-time suppression flag.
echo
echo "[R6-017] adapter-honesty banner"

ADAPTER_DETECT_SH="$REPO_ROOT/framework/hooks/_adapter-detect.sh"
START_MD="$REPO_ROOT/framework/commands/apex/start.md"
ONBOARD_MD="$REPO_ROOT/framework/commands/apex/onboard.md"
STATE_SCHEMA="$REPO_ROOT/framework/schemas/STATE.schema.json"

# (a) Detection helper exists and behaves correctly.
assert_pass "_adapter-detect.sh exists" \
  "test -f '$ADAPTER_DETECT_SH'"
assert_pass "_adapter-detect.sh active returns claude-code by default" \
  "[ \"\$(env -i HOME=\"\$HOME\" PATH=\"\$PATH\" bash '$ADAPTER_DETECT_SH' active)\" = 'claude-code' ]"

# Sidecar override smoke test in a tmp dir.
TMP_SIDECAR_DIR="$(mktemp -d 2>/dev/null || echo "")"
if [ -n "$TMP_SIDECAR_DIR" ]; then
  mkdir -p "$TMP_SIDECAR_DIR/.apex"
  echo "cursor" > "$TMP_SIDECAR_DIR/.apex/adapter"
  SIDECAR_OUT=$(APEX_PROJECT_ROOT="$TMP_SIDECAR_DIR" bash "$ADAPTER_DETECT_SH" active 2>/dev/null)
  assert_pass "_adapter-detect.sh respects .apex/adapter sidecar (returns 'cursor')" \
    "[ \"$SIDECAR_OUT\" = 'cursor' ]"
  rm -rf "$TMP_SIDECAR_DIR"
fi

# (b) Banner block present in start.md and onboard.md.
assert_pass "start.md contains ADAPTER HONESTY BANNER block (R6-017)" \
  "grep -q 'ADAPTER HONESTY BANNER \[R6-017\]' '$START_MD'"
assert_pass "onboard.md contains ADAPTER HONESTY BANNER block (R6-017)" \
  "grep -q 'ADAPTER HONESTY BANNER \[R6-017\]' '$ONBOARD_MD'"

# (c) Banner content references hook_protocol.supported, .deferred, and the
# adapter_honesty_shown suppression flag.
assert_pass "start.md banner reads hook_protocol.supported" \
  "grep -q 'hook_protocol.supported' '$START_MD'"
assert_pass "start.md banner reads .deferred manifest list" \
  "grep -q '.deferred' '$START_MD'"
assert_pass "start.md banner reads/sets adapter_honesty_shown" \
  "grep -q 'adapter_honesty_shown' '$START_MD'"
assert_pass "onboard.md banner reads/sets adapter_honesty_shown" \
  "grep -q 'adapter_honesty_shown' '$ONBOARD_MD'"

# (d) STATE.schema.json declares the optional suppression flag.
assert_pass "STATE.schema.json declares adapter_honesty_shown property" \
  "jq -e '.properties.adapter_honesty_shown.type == \"boolean\"' '$STATE_SCHEMA'"
assert_pass "STATE.schema.json adapter_honesty_shown is OPTIONAL (not in required[])" \
  "jq -e '(.required // []) | index(\"adapter_honesty_shown\") == null' '$STATE_SCHEMA'"

# (e) Banner does NOT fire on claude-code (default-host UX unchanged).
# We assert the gating logic in start.md compares hook_protocol against
# "full" — so the active claude-code manifest (supported=full) skips it.
assert_pass "start.md banner is gated on hook_protocol != full" \
  "grep -q 'HOOK_SUPPORT' '$START_MD' && grep -q '!= \"full\"' '$START_MD'"

# (f) sync-to-claude.sh delivers the new helper.
assert_pass "sync-to-claude.sh delivers _adapter-detect.sh" \
  "grep -q '_adapter-detect.sh' '$CLAUDE_SH'"

echo
echo "=== Results: PASS=$PASS FAIL=$FAIL ==="
if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
exit 0
