#!/usr/bin/env bash
# R5-016: Time-based decision gate — decision-gate.sh.
#
# Spec anchor: "Decision gates פר 60-90 דקות."
#
# Asserts:
#   1. decision-gate.sh exists with the "Hook type: Command-Invoked"
#      header (three-places contract part 1).
#   2. framework/commands/apex/next.md invokes the hook at top of
#      cycle (three-places contract part 2).
#   3. framework/HOOK-CLASSIFICATION.md lists it under Command-Invoked
#      (three-places contract part 3).
#   4. At elapsed=65min, gate fires with three options (exit 1).
#   5. At elapsed=30min, gate exits 0 silently.
#   6. Debounce: re-running the hook immediately after a fired gate
#      does NOT re-fire (gate exits 0 because last_time_gate is now).
#   7. Gate cadence by complexity: complexity=1 → 90min interval (so
#      elapsed=80min, no prior gate → exits 0 even though > 60min).
#   8. FIX_PLAN.md contains three options (continue / pause / resume).
#   9. sync-to-claude.sh declares delivery anchor for decision-gate.sh.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOKS_DIR="$REPO_ROOT/framework/hooks"
HOOK="$HOOKS_DIR/decision-gate.sh"

# R7-009: shared IO helpers (jq_lines for CRLF-safe read loops).
# shellcheck source=_test-utils.sh
[ -f "$SCRIPT_DIR/_test-utils.sh" ] && source "$SCRIPT_DIR/_test-utils.sh"

if [ ! -f "$HOOK" ]; then
  echo "FAIL: decision-gate.sh not found at $HOOK" >&2
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

# Build a STATE.json with .session.started_at = (now - elapsed_minutes)
# and complexity_level. last_time_gate optionally seeded.
write_state() {
  local sandbox="$1"
  local elapsed_min="$2"
  local complexity="$3"
  local last_gate_offset="${4:-}"   # minutes ago, optional

  mkdir -p "$sandbox/.apex"
  local now_epoch start_epoch start_iso last_gate_iso
  now_epoch=$(date +%s)
  start_epoch=$(( now_epoch - elapsed_min * 60 ))
  start_iso=$(date -u -d "@${start_epoch}" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
              || date -u -r "${start_epoch}" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
              || echo "")
  if [ -z "$last_gate_offset" ]; then
    cat > "$sandbox/.apex/STATE.json" <<EOF
{
  "complexity_level": ${complexity},
  "session": {
    "started_at": "${start_iso}"
  }
}
EOF
  else
    local last_gate_epoch
    last_gate_epoch=$(( now_epoch - last_gate_offset * 60 ))
    last_gate_iso=$(date -u -d "@${last_gate_epoch}" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
                    || date -u -r "${last_gate_epoch}" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
                    || echo "")
    cat > "$sandbox/.apex/STATE.json" <<EOF
{
  "complexity_level": ${complexity},
  "session": {
    "started_at": "${start_iso}",
    "last_time_gate": "${last_gate_iso}"
  }
}
EOF
  fi
}

echo "=== R5-016: decision-gate ==="
echo

# 1. Header
assert_pass "decision-gate.sh exists" "[ -f '$HOOK' ]"
assert_pass "header declares Command-Invoked" "grep -q 'Hook type: Command-Invoked' '$HOOK'"

# 2. next.md invokes the hook at top of cycle
NEXT_MD="$REPO_ROOT/framework/commands/apex/next.md"
assert_pass "next.md invokes decision-gate.sh" \
  "grep -q 'decision-gate.sh' '$NEXT_MD'"
# Top-of-cycle: it appears BEFORE the existing CONTEXT OVERFLOW CHECK.
assert_pass "next.md invokes decision-gate before CONTEXT OVERFLOW CHECK" \
  "awk '/decision-gate.sh/{a=NR} /## CONTEXT OVERFLOW CHECK/{b=NR} END{exit !(a>0 && b>0 && a<b)}' '$NEXT_MD'"

# 3. HOOK-CLASSIFICATION.md lists it
# R7-011: assertion is now state-derived — the section header count and
# the totals-table count must agree with each other (the file-system
# vs. doc cardinality check lives in test-hook-classification.sh).
HOOK_CLASS="$REPO_ROOT/framework/HOOK-CLASSIFICATION.md"
assert_pass "HOOK-CLASSIFICATION.md lists decision-gate.sh" \
  "grep -q 'decision-gate.sh' '$HOOK_CLASS'"
HC_HEADER_COUNT=$(grep -oE '## Command-Invoked / Event-Triggered \(([0-9]+)\)' "$HOOK_CLASS" | grep -oE '[0-9]+' | head -1)
HC_TABLE_COUNT=$(grep -oE '\| Command-Invoked / Event-Triggered \| ([0-9]+) \|' "$HOOK_CLASS" | grep -oE '[0-9]+' | head -1)
assert_pass "HOOK-CLASSIFICATION.md Command-Invoked count agrees with itself (header == totals table)" \
  "[ -n '$HC_HEADER_COUNT' ] && [ '$HC_HEADER_COUNT' = '$HC_TABLE_COUNT' ]"

# 4. Elapsed=65min, complexity 4 (60min interval) → fires
SANDBOX_FIRE=$(run_sandbox)
write_state "$SANDBOX_FIRE" 65 4
( cd "$SANDBOX_FIRE" && \
  APEX_FIX_PLAN_FILE="$SANDBOX_FIRE/.apex/FIX_PLAN.md" \
  bash "$HOOK" >/dev/null 2>&1 )
EXIT_FIRE=$?
assert_pass "elapsed=65 min (complexity 4) fires the gate (exit 1)" "[ $EXIT_FIRE -eq 1 ]"
assert_pass "fired gate writes FIX_PLAN.md" "[ -f '$SANDBOX_FIRE/.apex/FIX_PLAN.md' ]"
# 8. FIX_PLAN.md three-option content
assert_pass "FIX_PLAN.md mentions continue option" \
  "grep -qi 'continue' '$SANDBOX_FIRE/.apex/FIX_PLAN.md'"
assert_pass "FIX_PLAN.md mentions /apex:pause option" \
  "grep -q '/apex:pause' '$SANDBOX_FIRE/.apex/FIX_PLAN.md'"
assert_pass "FIX_PLAN.md mentions /apex:resume option" \
  "grep -q '/apex:resume' '$SANDBOX_FIRE/.apex/FIX_PLAN.md'"
# Debounce field updated.
if command -v jq >/dev/null 2>&1; then
  assert_pass "fired gate updated STATE.session.last_time_gate" \
    "[ \"\$(jq -r '.session.last_time_gate // empty' '$SANDBOX_FIRE/.apex/STATE.json')\" != '' ]"
fi
# 6. Debounce — immediate re-run does not re-fire
( cd "$SANDBOX_FIRE" && \
  APEX_FIX_PLAN_FILE="$SANDBOX_FIRE/.apex/FIX_PLAN.md" \
  bash "$HOOK" >/dev/null 2>&1 )
EXIT_DEBOUNCE=$?
assert_pass "debounce: immediate re-run exits 0 (no re-fire)" "[ $EXIT_DEBOUNCE -eq 0 ]"
rm -rf "$SANDBOX_FIRE"

# 5. Elapsed=30min, complexity 4 → silent
SANDBOX_QUIET=$(run_sandbox)
write_state "$SANDBOX_QUIET" 30 4
( cd "$SANDBOX_QUIET" && bash "$HOOK" >/dev/null 2>&1 )
EXIT_QUIET=$?
assert_pass "elapsed=30 min exits 0 silently" "[ $EXIT_QUIET -eq 0 ]"
assert_pass "elapsed=30 min does NOT write FIX_PLAN.md" \
  "[ ! -f '$SANDBOX_QUIET/.apex/FIX_PLAN.md' ]"
rm -rf "$SANDBOX_QUIET"

# 7. Cadence by complexity: complexity=1 → 90min interval. Elapsed=80
# min, no prior gate → exits 0 (interval not yet met).
SANDBOX_CADENCE=$(run_sandbox)
write_state "$SANDBOX_CADENCE" 80 1
( cd "$SANDBOX_CADENCE" && bash "$HOOK" >/dev/null 2>&1 )
EXIT_CADENCE=$?
assert_pass "complexity=1, elapsed=80 min: cadence not met (exit 0)" "[ $EXIT_CADENCE -eq 0 ]"
# And at elapsed=95 min the gate DOES fire for complexity=1.
SANDBOX_CADENCE2=$(run_sandbox)
write_state "$SANDBOX_CADENCE2" 95 1
( cd "$SANDBOX_CADENCE2" && \
  APEX_FIX_PLAN_FILE="$SANDBOX_CADENCE2/.apex/FIX_PLAN.md" \
  bash "$HOOK" >/dev/null 2>&1 )
EXIT_CADENCE2=$?
assert_pass "complexity=1, elapsed=95 min: cadence met (exit 1)" "[ $EXIT_CADENCE2 -eq 1 ]"
rm -rf "$SANDBOX_CADENCE" "$SANDBOX_CADENCE2"

# 9. sync-to-claude delivery
SYNC="$REPO_ROOT/framework/scripts/sync-to-claude.sh"
assert_pass "sync-to-claude.sh delivers decision-gate.sh" \
  "grep -q 'hooks/decision-gate.sh' '$SYNC'"

echo
echo "=== Results: PASS=$PASS FAIL=$FAIL ==="
if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
exit 0
