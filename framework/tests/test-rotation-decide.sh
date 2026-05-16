#!/usr/bin/env bash
# R13-005 (F-305): _rotation-decide.sh — 10-case test battery.
#
# Cases:
#   (1) low utilization (20%, default budget)              → noop
#   (2) 60% with threshold 55                              → proactive_compact
#   (3) 70% with threshold 70 hard                         → hard_rotate
#   (4) phase_boundary trigger                             → proactive_compact
#   (5) task_batch met (tasks_since=6, threshold 6)        → warn_and_compact
#   (6) recovery_density met (rd=3, threshold 3)           → hard_rotate
#   (7) circuit-breaker HALT (drift cb_triggers>0)         → noop regardless
#   (8) priority order: 70% utilization (hard) wins
#       over phase_boundary (proactive)                    → hard_rotate
#   (9) unknown trigger type                               → noop (no crash)
#  (10) time_minutes mid-task: session_started=now,
#       threshold 40 min                                   → no fire (noop)
#
# Harness conventions (R10-008 + R11-003):
#   - LOCAL_PASS / LOCAL_FAIL are file-scope counters; harness_assert_local
#     bridges into the runner banner.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB="$REPO_ROOT/framework/hooks/_rotation-decide.sh"

# shellcheck source=_test-utils.sh
[ -f "$SCRIPT_DIR/_test-utils.sh" ] && source "$SCRIPT_DIR/_test-utils.sh"

if [ ! -f "$LIB" ]; then
  echo "FAIL: _rotation-decide.sh not found at $LIB" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not available — _rotation-decide requires jq"
  exit 0
fi

LOCAL_PASS=0
LOCAL_FAIL=0

_pass() { echo "  PASS: $1"; LOCAL_PASS=$((LOCAL_PASS + 1)); }
_fail() { echo "  FAIL: $1" >&2; LOCAL_FAIL=$((LOCAL_FAIL + 1)); }

# explicit-exit-trap: cleanup of mktemp working tree (R9-013 contract).
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Helper: write a STATE.json with the supplied jq expression overrides.
# Base shape exposes the fields the library reads; jq expression layered
# on top customizes per-case.
_write_state() {
  local out="$1" overrides="${2:-.}"
  cat > "$out.base" <<'JSON'
{
  "context": {
    "estimated_context_usage_pct": 0
  },
  "session": {
    "started_at": "2099-01-01T00:00:00Z",
    "tasks_since_last_rotation": 0,
    "phase_boundary_crossed": false,
    "drift_indicators": {
      "spec_drift_count": 0,
      "circuit_breaker_triggers": 0,
      "reflexion_total_attempts": 0,
      "low_confidence_results": 0,
      "recovery_density": 0
    }
  },
  "circuit_breaker": {
    "triggered": false
  }
}
JSON
  jq "$overrides" "$out.base" > "$out"
  rm -f "$out.base"
}

# Helper: write a CONTEXT_BUDGET with caller-supplied triggers array.
# The default mirrors framework/CONTEXT_BUDGET.default.json triggers
# (utilization 70 hard → utilization 55 proactive → phase → task_batch 6
#  → time 40 → recovery_density 3 → pattern legacy).
_write_budget() {
  local out="$1" triggers="${2:-default}"
  case "$triggers" in
    default)
      cat > "$out" <<'JSON'
{
  "rotation_triggers": [
    {"type": "utilization_pct", "value": 70, "action": "hard_rotate"},
    {"type": "utilization_pct", "value": 55, "action": "proactive_compact"},
    {"type": "phase_boundary", "action": "proactive_compact"},
    {"type": "task_batch", "value": 6, "action": "warn_and_compact"},
    {"type": "time_minutes", "value": 40, "action": "warn_and_compact"},
    {"type": "recovery_density", "value": 3, "action": "hard_rotate"},
    {"type": "pattern", "pattern": "repeated_tool_errors", "action": "warn_and_compact"}
  ]
}
JSON
      ;;
    unknown_only)
      cat > "$out" <<'JSON'
{
  "rotation_triggers": [
    {"type": "totally_unknown_xyz", "value": 1, "action": "hard_rotate"}
  ]
}
JSON
      ;;
  esac
}

# Invocation helper. Sources the library, calls apex_rotation_decide,
# echoes stdout. Suppresses stderr because event-log writes may noise it
# when running outside a project tree.
_call() {
  local state="$1" budget="$2"
  (
    # Run in a clean subshell so library-set vars don't bleed.
    # shellcheck disable=SC1090
    source "$LIB"
    apex_rotation_decide "$state" "$budget" 2>/dev/null
  ) | tr -d '\r' | head -n 1
}

# ---- Case (1): low utilization → noop ----
CASE1="$WORK/case1"; mkdir -p "$CASE1"
_write_state "$CASE1/STATE.json" '.context.estimated_context_usage_pct = 20'
_write_budget "$CASE1/BUDGET.json"
R1=$(_call "$CASE1/STATE.json" "$CASE1/BUDGET.json")
if [ "$R1" = "noop" ]; then
  _pass "(1) low utilization (20%) → noop"
else
  _fail "(1) low utilization → expected noop, got '$R1'"
fi

# ---- Case (2): 60% with threshold 55 → proactive_compact ----
CASE2="$WORK/case2"; mkdir -p "$CASE2"
_write_state "$CASE2/STATE.json" '.context.estimated_context_usage_pct = 60'
_write_budget "$CASE2/BUDGET.json"
R2=$(_call "$CASE2/STATE.json" "$CASE2/BUDGET.json")
if [ "$R2" = "proactive_compact" ]; then
  _pass "(2) 60% (≥55 threshold) → proactive_compact"
else
  _fail "(2) 60% → expected proactive_compact, got '$R2'"
fi

# ---- Case (3): 70% with hard threshold 70 → hard_rotate ----
CASE3="$WORK/case3"; mkdir -p "$CASE3"
_write_state "$CASE3/STATE.json" '.context.estimated_context_usage_pct = 70'
_write_budget "$CASE3/BUDGET.json"
R3=$(_call "$CASE3/STATE.json" "$CASE3/BUDGET.json")
if [ "$R3" = "hard_rotate" ]; then
  _pass "(3) 70% (≥70 hard threshold) → hard_rotate"
else
  _fail "(3) 70% → expected hard_rotate, got '$R3'"
fi

# ---- Case (4): phase_boundary → proactive_compact ----
CASE4="$WORK/case4"; mkdir -p "$CASE4"
_write_state "$CASE4/STATE.json" '.context.estimated_context_usage_pct = 10 | .session.phase_boundary_crossed = true'
_write_budget "$CASE4/BUDGET.json"
R4=$(_call "$CASE4/STATE.json" "$CASE4/BUDGET.json")
if [ "$R4" = "proactive_compact" ]; then
  _pass "(4) phase_boundary → proactive_compact"
else
  _fail "(4) phase_boundary → expected proactive_compact, got '$R4'"
fi

# ---- Case (5): task_batch met (tasks_since=6, threshold 6) → warn_and_compact ----
CASE5="$WORK/case5"; mkdir -p "$CASE5"
_write_state "$CASE5/STATE.json" '.context.estimated_context_usage_pct = 10 | .session.tasks_since_last_rotation = 6'
_write_budget "$CASE5/BUDGET.json"
R5=$(_call "$CASE5/STATE.json" "$CASE5/BUDGET.json")
if [ "$R5" = "warn_and_compact" ]; then
  _pass "(5) task_batch met (6≥6) → warn_and_compact"
else
  _fail "(5) task_batch met → expected warn_and_compact, got '$R5'"
fi

# ---- Case (6): recovery_density met (rd=3, threshold 3) → hard_rotate ----
CASE6="$WORK/case6"; mkdir -p "$CASE6"
_write_state "$CASE6/STATE.json" '.context.estimated_context_usage_pct = 10 | .session.drift_indicators.recovery_density = 3'
_write_budget "$CASE6/BUDGET.json"
R6=$(_call "$CASE6/STATE.json" "$CASE6/BUDGET.json")
if [ "$R6" = "hard_rotate" ]; then
  _pass "(6) recovery_density met (3≥3) → hard_rotate"
else
  _fail "(6) recovery_density met → expected hard_rotate, got '$R6'"
fi

# ---- Case (7): circuit-breaker HALT (drift.cb_triggers>0) → noop regardless ----
CASE7="$WORK/case7"; mkdir -p "$CASE7"
# Even with 99% utilization (would fire hard_rotate), HALT must win.
_write_state "$CASE7/STATE.json" '.context.estimated_context_usage_pct = 99 | .session.drift_indicators.circuit_breaker_triggers = 1'
_write_budget "$CASE7/BUDGET.json"
R7=$(_call "$CASE7/STATE.json" "$CASE7/BUDGET.json")
if [ "$R7" = "noop" ]; then
  _pass "(7) circuit-breaker HALT (cb_triggers=1) → noop regardless of 99% pressure"
else
  _fail "(7) HALT-priority → expected noop, got '$R7' (SAFETY INVARIANT)"
fi

# ---- Case (8): priority order: utilization 70 wins over phase_boundary ----
CASE8="$WORK/case8"; mkdir -p "$CASE8"
# Both fire: utilization is first in array (priority 0), phase_boundary is 3rd.
_write_state "$CASE8/STATE.json" '.context.estimated_context_usage_pct = 75 | .session.phase_boundary_crossed = true'
_write_budget "$CASE8/BUDGET.json"
R8=$(_call "$CASE8/STATE.json" "$CASE8/BUDGET.json")
if [ "$R8" = "hard_rotate" ]; then
  _pass "(8) priority order: 75% utilization wins over phase_boundary → hard_rotate"
else
  _fail "(8) priority order → expected hard_rotate (first-match-wins), got '$R8'"
fi

# ---- Case (9): unknown trigger type → noop (no crash) ----
CASE9="$WORK/case9"; mkdir -p "$CASE9"
_write_state "$CASE9/STATE.json" '.context.estimated_context_usage_pct = 99 | .session.phase_boundary_crossed = true'
_write_budget "$CASE9/BUDGET.json" unknown_only
R9=$(_call "$CASE9/STATE.json" "$CASE9/BUDGET.json")
if [ "$R9" = "noop" ]; then
  _pass "(9) unknown trigger type → noop (no crash, skipped silently)"
else
  _fail "(9) unknown trigger → expected noop, got '$R9'"
fi

# ---- Case (10): time_minutes mid-task → no fire (noop) ----
CASE10="$WORK/case10"; mkdir -p "$CASE10"
# session_started = now (UTC); mins_elapsed will be 0; threshold 40 → no fire.
NOW_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
_write_state "$CASE10/STATE.json" ".context.estimated_context_usage_pct = 10 | .session.started_at = \"$NOW_ISO\""
_write_budget "$CASE10/BUDGET.json"
R10=$(_call "$CASE10/STATE.json" "$CASE10/BUDGET.json")
if [ "$R10" = "noop" ]; then
  _pass "(10) time_minutes mid-task (session_started=now, threshold 40min) → noop"
else
  _fail "(10) time_minutes mid-task → expected noop, got '$R10'"
fi

# ---- Summary ----
echo ""
echo "test-rotation-decide.sh: LOCAL_PASS=$LOCAL_PASS LOCAL_FAIL=$LOCAL_FAIL"
echo ""

if [ "${HARNESS_LOADED:-0}" = "1" ] || declare -F harness_assert_local >/dev/null 2>&1; then
  harness_assert_local "$LOCAL_PASS" "$LOCAL_FAIL" "test-rotation-decide.sh"
fi

exit "$LOCAL_FAIL"
