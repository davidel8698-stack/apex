#!/usr/bin/env bash
# R5-013: One-file-one-owner enforcement — owner-guard.sh.
#
# Spec anchors:
#   "One-file-one-owner עם git worktree isolation"
#   "Read-parallel, write-serial עם Vertical Slices Enforcement"
#
# Asserts:
#   1. owner-guard.sh exists, is executable, has the "Hook type:
#      Auto-PreToolUse" header (three-places contract part 1).
#   2. framework/settings.json wires it under PreToolUse Write|Edit
#      (three-places contract part 2).
#   3. framework/HOOK-CLASSIFICATION.md lists it under Auto-PreToolUse
#      (three-places contract part 3).
#   4. Fast-path: missing APEX_CURRENT_TASK_ID → exit 0.
#   5. Allowed write: path inside owns_files → exit 0.
#   6. Disallowed write: path NOT in owns_files → exit 1 (advisory mode)
#      AND .apex/FIX_PLAN.md is written.
#   7. APEX_OWNER_GUARD_BLOCKING=1 upgrades exit 1 to exit 2.
#   8. Wildcard owns_files=["*"] passes any path.
#   9. Legacy bare-string task entry (pre-R5-013 WAVE_MAP) → advisory
#      pass (exit 0) — backward compatibility for in-flight WAVE_MAP
#      files.
#  10. Glob ownership ("src/feature/**") matches subpaths.
#  11. sync-to-claude.sh declares an explicit delivery line for
#      owner-guard.sh.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOKS_DIR="$REPO_ROOT/framework/hooks"
GUARD="$HOOKS_DIR/owner-guard.sh"

# R7-009: shared IO helpers (jq_lines for CRLF-safe read loops).
# shellcheck source=_test-utils.sh
[ -f "$SCRIPT_DIR/_test-utils.sh" ] && source "$SCRIPT_DIR/_test-utils.sh"

if [ ! -f "$GUARD" ]; then
  echo "FAIL: owner-guard.sh not found at $GUARD" >&2
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

# Build a minimal STATE.json + WAVE_MAP.json fixture in the sandbox.
# Args: $1 = sandbox path, $2 = WAVE_MAP body (jq-compatible JSON literal)
write_fixtures() {
  local sandbox="$1"
  local wave_map_body="$2"
  mkdir -p "$sandbox/.apex/phases/01"
  cat > "$sandbox/.apex/STATE.json" <<EOF
{
  "current_phase": "01",
  "current_wave": 1
}
EOF
  printf '%s\n' "$wave_map_body" > "$sandbox/.apex/phases/01/WAVE_MAP.json"
}

echo "=== R5-013: owner-guard ==="
echo

# 1. Hook header
assert_pass "owner-guard.sh exists" "[ -f '$GUARD' ]"
assert_pass "header declares Auto-PreToolUse" "grep -q 'Hook type: Auto-PreToolUse' '$GUARD'"

# 2. settings.json wires it
SETTINGS="$REPO_ROOT/framework/settings.json"
assert_pass "settings.json invokes owner-guard.sh" \
  "grep -q 'owner-guard.sh' '$SETTINGS'"
# Confirm the matcher is Write|Edit (jq probe — robust against
# whitespace and ordering).
if command -v jq >/dev/null 2>&1; then
  assert_pass "settings.json owner-guard entry matches Write|Edit (jq)" \
    "[ \"\$(jq -r '.hooks.PreToolUse[] | select(.hooks[]?.command | tostring | contains(\"owner-guard.sh\")) | .matcher' '$SETTINGS')\" = 'Write|Edit' ]"
else
  echo "  SKIP: settings.json owner-guard entry matches Write|Edit (jq unavailable)"
fi

# 3. HOOK-CLASSIFICATION.md lists it
HOOK_CLASS="$REPO_ROOT/framework/HOOK-CLASSIFICATION.md"
assert_pass "HOOK-CLASSIFICATION.md lists owner-guard.sh" \
  "grep -q 'owner-guard.sh' '$HOOK_CLASS'"
assert_pass "HOOK-CLASSIFICATION.md Auto-PreToolUse header carries a count (drift-resistant: any integer)" \
  "grep -qE '^## Auto-PreToolUse \\([0-9]+\\)\$' '$HOOK_CLASS'"

# 4. Fast-path: no APEX_CURRENT_TASK_ID
SANDBOX_FAST=$(run_sandbox)
( cd "$SANDBOX_FAST" && unset APEX_CURRENT_TASK_ID && bash "$GUARD" "src/foo.ts" >/dev/null 2>&1 )
EXIT_FAST=$?
assert_pass "fast-path exit 0 when APEX_CURRENT_TASK_ID is unset" "[ $EXIT_FAST -eq 0 ]"
rm -rf "$SANDBOX_FAST"

# 5. Allowed write
SANDBOX_OK=$(run_sandbox)
write_fixtures "$SANDBOX_OK" '{
  "waves": [{
    "wave_number": 1,
    "tasks": [
      {"id": "T1", "owns_files": ["src/foo.ts", "src/bar.ts"]},
      {"id": "T2", "owns_files": ["src/baz.ts"]}
    ]
  }],
  "generated_from_phase": "01",
  "generated_at": "2026-01-01T00:00:00Z"
}'
( cd "$SANDBOX_OK" && \
  APEX_FIX_PLAN_FILE="$SANDBOX_OK/.apex/FIX_PLAN.md" \
  APEX_CURRENT_TASK_ID=T1 bash "$GUARD" "src/foo.ts" >/dev/null 2>&1 )
EXIT_OK=$?
assert_pass "allowed write exits 0" "[ $EXIT_OK -eq 0 ]"
assert_pass "allowed write does NOT create FIX_PLAN.md" "[ ! -f '$SANDBOX_OK/.apex/FIX_PLAN.md' ]"
rm -rf "$SANDBOX_OK"

# 6. Disallowed write — advisory mode
SANDBOX_DENY=$(run_sandbox)
write_fixtures "$SANDBOX_DENY" '{
  "waves": [{
    "wave_number": 1,
    "tasks": [
      {"id": "T1", "owns_files": ["src/foo.ts"]},
      {"id": "T2", "owns_files": ["src/baz.ts"]}
    ]
  }],
  "generated_from_phase": "01",
  "generated_at": "2026-01-01T00:00:00Z"
}'
( cd "$SANDBOX_DENY" && \
  APEX_FIX_PLAN_FILE="$SANDBOX_DENY/.apex/FIX_PLAN.md" \
  APEX_CURRENT_TASK_ID=T1 bash "$GUARD" "src/baz.ts" >/dev/null 2>&1 )
EXIT_DENY=$?
assert_pass "disallowed write exits 1 in advisory mode" "[ $EXIT_DENY -eq 1 ]"
assert_pass "disallowed write writes FIX_PLAN.md" "[ -f '$SANDBOX_DENY/.apex/FIX_PLAN.md' ]"
assert_pass "FIX_PLAN.md cites owner-guard" "grep -q 'owner-guard' '$SANDBOX_DENY/.apex/FIX_PLAN.md'"
rm -rf "$SANDBOX_DENY"

# 7. Blocking mode upgrade
SANDBOX_BLOCK=$(run_sandbox)
write_fixtures "$SANDBOX_BLOCK" '{
  "waves": [{
    "wave_number": 1,
    "tasks": [
      {"id": "T1", "owns_files": ["src/foo.ts"]},
      {"id": "T2", "owns_files": ["src/baz.ts"]}
    ]
  }],
  "generated_from_phase": "01",
  "generated_at": "2026-01-01T00:00:00Z"
}'
( cd "$SANDBOX_BLOCK" && \
  APEX_FIX_PLAN_FILE="$SANDBOX_BLOCK/.apex/FIX_PLAN.md" \
  APEX_OWNER_GUARD_BLOCKING=1 APEX_CURRENT_TASK_ID=T1 \
  bash "$GUARD" "src/baz.ts" >/dev/null 2>&1 )
EXIT_BLOCK=$?
assert_pass "APEX_OWNER_GUARD_BLOCKING=1 upgrades to exit 2" "[ $EXIT_BLOCK -eq 2 ]"
rm -rf "$SANDBOX_BLOCK"

# 8. Wildcard owns_files
SANDBOX_WILD=$(run_sandbox)
write_fixtures "$SANDBOX_WILD" '{
  "waves": [{
    "wave_number": 1,
    "tasks": [
      {"id": "Tonly", "owns_files": ["*"]}
    ]
  }],
  "generated_from_phase": "01",
  "generated_at": "2026-01-01T00:00:00Z"
}'
( cd "$SANDBOX_WILD" && \
  APEX_CURRENT_TASK_ID=Tonly bash "$GUARD" "anywhere/in/the/repo.txt" >/dev/null 2>&1 )
EXIT_WILD=$?
assert_pass "wildcard owns_files=['*'] passes" "[ $EXIT_WILD -eq 0 ]"
rm -rf "$SANDBOX_WILD"

# 9. Legacy bare-string task entry (pre-R5-013) → advisory pass
SANDBOX_LEGACY=$(run_sandbox)
write_fixtures "$SANDBOX_LEGACY" '{
  "waves": [{
    "wave_number": 1,
    "tasks": ["T1", "T2"]
  }],
  "generated_from_phase": "01",
  "generated_at": "2026-01-01T00:00:00Z"
}'
( cd "$SANDBOX_LEGACY" && \
  APEX_CURRENT_TASK_ID=T1 bash "$GUARD" "src/foo.ts" >/dev/null 2>&1 )
EXIT_LEGACY=$?
assert_pass "legacy bare-string task entry passes (backward compat)" "[ $EXIT_LEGACY -eq 0 ]"
rm -rf "$SANDBOX_LEGACY"

# 10. Glob ownership match
SANDBOX_GLOB=$(run_sandbox)
write_fixtures "$SANDBOX_GLOB" '{
  "waves": [{
    "wave_number": 1,
    "tasks": [
      {"id": "T1", "owns_files": ["src/feature/*"]},
      {"id": "T2", "owns_files": ["src/other/*"]}
    ]
  }],
  "generated_from_phase": "01",
  "generated_at": "2026-01-01T00:00:00Z"
}'
( cd "$SANDBOX_GLOB" && \
  APEX_CURRENT_TASK_ID=T1 bash "$GUARD" "src/feature/login.ts" >/dev/null 2>&1 )
EXIT_GLOB_OK=$?
assert_pass "glob ownership matches src/feature/login.ts" "[ $EXIT_GLOB_OK -eq 0 ]"
( cd "$SANDBOX_GLOB" && \
  APEX_CURRENT_TASK_ID=T1 bash "$GUARD" "src/other/logout.ts" >/dev/null 2>&1 )
EXIT_GLOB_DENY=$?
assert_pass "glob ownership rejects out-of-pattern path" "[ $EXIT_GLOB_DENY -eq 1 ]"
rm -rf "$SANDBOX_GLOB"

# 11. sync-to-claude delivery anchor
SYNC="$REPO_ROOT/framework/scripts/sync-to-claude.sh"
assert_pass "sync-to-claude.sh delivers owner-guard.sh" \
  "grep -q 'hooks/owner-guard.sh' '$SYNC'"

echo
echo "=== Results: PASS=$PASS FAIL=$FAIL ==="
# R9-002: bridge private counters into harness globals once.
if declare -F harness_assert_local >/dev/null 2>&1; then
  harness_assert_local "$PASS" "$FAIL" "test-owner-guard"
fi
if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
exit 0
