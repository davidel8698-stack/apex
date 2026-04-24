#!/usr/bin/env bash
# APEX Self-Test Harness — assert helpers, setup/teardown, coverage scanner.

PASS=0; FAIL=0; TOTAL=0; SKIP=0

harness_setup() {
  TEMP_REPO=$(mktemp -d)
  ORIG_DIR="$(pwd)"
  cd "$TEMP_REPO"
  git init -q && git config user.email "test@apex" && git config user.name "APEX"
  echo "init" > init.txt && git add . && git commit -qm "init"
  mkdir -p .apex/phases/01
  # NOTE: Tests run against installed hooks/commands ($HOME/.claude/), not framework source.
  # After modifying framework/hooks/ or framework/commands/, re-install before running self-test.
  HOOKS_DIR="$HOME/.claude/hooks"
  SCHEMAS_DIR="$HOME/.claude/schemas"
  COMMANDS_DIR="$HOME/.claude/commands/apex"
  TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

harness_teardown() {
  cd "$ORIG_DIR" 2>/dev/null || cd /tmp
  rm -rf "$TEMP_REPO"
}

assert_exit() {
  TOTAL=$((TOTAL + 1))
  local expected="$1" actual="$2" msg="$3"
  if [ "$expected" -eq "$actual" ] 2>/dev/null; then
    echo "  ✅ $msg"; PASS=$((PASS + 1))
  else
    echo "  ❌ $msg (expected exit $expected, got $actual)"; FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  TOTAL=$((TOTAL + 1))
  local file="$1" pattern="$2" msg="$3"
  if grep -qiE "$pattern" "$file" 2>/dev/null; then
    echo "  ✅ $msg"; PASS=$((PASS + 1))
  else
    echo "  ❌ $msg ('$pattern' not in $(basename "$file"))"; FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  TOTAL=$((TOTAL + 1))
  local file="$1" pattern="$2" msg="$3"
  if ! grep -qiE "$pattern" "$file" 2>/dev/null; then
    echo "  ✅ $msg"; PASS=$((PASS + 1))
  else
    echo "  ❌ $msg ('$pattern' found in $(basename "$file"))"; FAIL=$((FAIL + 1))
  fi
}

assert_jq() {
  TOTAL=$((TOTAL + 1))
  local file="$1" expr="$2" msg="$3"
  if jq -e "$expr" "$file" >/dev/null 2>&1; then
    echo "  ✅ $msg"; PASS=$((PASS + 1))
  else
    echo "  ❌ $msg (jq failed on $(basename "$file"))"; FAIL=$((FAIL + 1))
  fi
}

coverage_scan() {
  echo ""
  echo "━━━ Coverage Scan ━━━"
  local UNTESTED=0

  for hook in "$HOOKS_DIR"/*.sh; do
    [ -f "$hook" ] || continue
    local HOOK_NAME=$(basename "$hook" .sh)
    [[ "$HOOK_NAME" == _* ]] && continue
    if ! grep -rq "$HOOK_NAME" "$TEST_DIR"/test-*.sh 2>/dev/null; then
      echo "  ⚠️  UNTESTED HOOK: $HOOK_NAME.sh"
      UNTESTED=$((UNTESTED + 1))
    fi
  done

  for cmd in "$COMMANDS_DIR"/*.md; do
    [ -f "$cmd" ] || continue
    local CMD_NAME=$(basename "$cmd" .md)
    [[ "$CMD_NAME" == _* ]] && continue
    if ! grep -rq "$CMD_NAME" "$TEST_DIR"/test-*.sh 2>/dev/null; then
      echo "  ⚠️  UNTESTED COMMAND: $CMD_NAME.md"
      UNTESTED=$((UNTESTED + 1))
    fi
  done

  for schema in "$SCHEMAS_DIR"/*.json; do
    [ -f "$schema" ] || continue
    local SCHEMA_NAME=$(basename "$schema")
    if ! grep -rq "$SCHEMA_NAME" "$TEST_DIR"/test-*.sh 2>/dev/null; then
      echo "  ⚠️  UNTESTED SCHEMA: $SCHEMA_NAME"
      UNTESTED=$((UNTESTED + 1))
    fi
  done

  if [ "$UNTESTED" -gt 0 ]; then
    echo ""
    echo "  ⚠️  $UNTESTED components have no test coverage."
  else
    echo "  ✅ All components have test coverage"
  fi
}

harness_report() {
  coverage_scan
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "  APEX self-test: $PASS/$TOTAL passed, $FAIL failed"
  if [ "$FAIL" -gt 0 ]; then
    echo "  ❌ INFRASTRUCTURE DEGRADED"
  else
    echo "  ✅ ALL MECHANISMS VERIFIED"
  fi
  echo "═══════════════════════════════════════════════"
  exit "$FAIL"
}
