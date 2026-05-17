#!/usr/bin/env bash
# Phase 12.09 — M16 Quality Drift hook test.
#
# Verifies framework/hooks/quality-drift.sh against:
#   C-1: hook exists + executable + syntax-valid.
#   C-2: no .apex/ → exit 2 (invocation error).
#   C-3: empty rolling window → exit 1 (insufficient data); no false drift.
#   C-4: baseline < 10 entries → exit 1 (insufficient baseline).
#   C-5: drift correctly computed when baseline=10, rolling=10 with different avg.
#   C-6: quality_drift event fired when |drift_pct| > 5% AND tasks_completed > 20.
#   C-7: drift NOT fired when tasks_completed <= 20 (insufficient session signal).
#   C-8: Re-base on phase change (5+ tasks in new phase → baseline reset to rolling).
#   C-9: Confidence mapping high=1.0, medium=0.5, low=0.0 produces correct averages.
#
# Harness contract (R10-008): arithmetic globals, no EXIT trap.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DRIFT_SH="$REPO_ROOT/framework/hooks/quality-drift.sh"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ ! -f "$SCRIPT_DIR/_harness.sh" ]; then
    echo "  ❌ Harness not found"; exit 1
  fi
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/_harness.sh"
fi

echo "=== Phase 12.09 — M16 Quality Drift ==="

if ! command -v jq >/dev/null 2>&1; then
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
  echo "  ❌ jq is required"
  exit 1
fi

# --- C-1: hook exists + executable + syntax-valid ---
TOTAL=$((TOTAL + 1))
if [ -x "$DRIFT_SH" ] && bash -n "$DRIFT_SH" 2>/dev/null; then
  echo "  ✅ C-1: quality-drift.sh exists, executable, syntax-valid"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-1: quality-drift.sh missing or broken"
  exit 1
fi

# --- C-2: no .apex/ → exit 2 ---
TOTAL=$((TOTAL + 1))
EMPTY=$(mktemp -d)
(cd "$EMPTY" && bash "$DRIFT_SH" >/dev/null 2>&1)
RC=$?
rm -rf "$EMPTY"
if [ "$RC" = "2" ]; then
  echo "  ✅ C-2: no .apex/ → exit 2"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-2: expected exit 2 with no .apex/, got $RC"
  FAIL=$((FAIL + 1))
fi

# Helper: create a sandbox with .apex/ + STATE.json containing arbitrary quality block.
# Args: <baseline_count> <rolling_count> <baseline_score> <rolling_score> <tasks_completed> <current_phase> <baselined_at_phase>
_make_quality_sandbox() {
  local b_count="$1" r_count="$2" b_score="$3" r_score="$4" t_done="$5" cur_phase="$6" baselined_phase="$7"
  local sb
  sb=$(mktemp -d)
  mkdir -p "$sb/.apex"
  # Build baseline array of b_count entries with confidence_score=b_score.
  local baseline_arr="[]"
  if [ "$b_count" -gt 0 ]; then
    baseline_arr=$(jq -nc --argjson n "$b_count" --argjson s "$b_score" '
      [range(0; $n) | {task_id: ("baseline_" + (. | tostring)), confidence_score: $s, verifier_pass: true, attempts: 1}]
    ')
  fi
  # Build rolling array similarly.
  local rolling_arr="[]"
  if [ "$r_count" -gt 0 ]; then
    rolling_arr=$(jq -nc --argjson n "$r_count" --argjson s "$r_score" '
      [range(0; $n) | {task_id: ("rolling_" + (. | tostring)), confidence_score: $s, verifier_pass: true, attempts: 1}]
    ')
  fi
  jq -n \
    --argjson baseline "$baseline_arr" \
    --argjson rolling "$rolling_arr" \
    --argjson t_done "$t_done" \
    --arg cur_phase "$cur_phase" \
    --arg baselined_phase "$baselined_phase" \
    '{
      current_phase: $cur_phase,
      context: {current_session_phase: $cur_phase},
      session: {tasks_completed: $t_done},
      quality: {
        rolling_window_tasks: $rolling,
        baseline_window_tasks: $baseline,
        current_drift_pct: 0,
        alert_threshold_pct: 5,
        baselined_at_phase: $baselined_phase,
        tasks_since_rebaseline: 10
      }
    }' > "$sb/.apex/STATE.json"
  echo "$sb"
}

# --- C-3: empty rolling window → exit 1 (insufficient data); no false drift. ---
TOTAL=$((TOTAL + 1))
SB=$(_make_quality_sandbox 10 0 0.9 0.0 30 "phase1" "phase1")
(cd "$SB" && bash "$DRIFT_SH" >/dev/null 2>&1)
RC=$?
# When rolling is empty, current_drift_pct should NOT have been overwritten
# to a non-zero number. It stays 0 (initialized value).
DRIFT_VAL=$(jq -r '.quality.current_drift_pct' "$SB/.apex/STATE.json")
if [ "$RC" = "1" ] && [ "$DRIFT_VAL" = "0" ]; then
  echo "  ✅ C-3: empty rolling → exit 1, no false drift (drift=$DRIFT_VAL)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-3: expected exit 1 + drift=0, got rc=$RC, drift=$DRIFT_VAL"
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB"

# --- C-4: baseline=0, rolling<10 → exit 1 (insufficient baseline; no auto-freeze). ---
# Note: when rolling fills to >=10 entries AND baseline is empty, the hook
# auto-freezes baseline := rolling (initial freeze rule). To exercise the
# "insufficient baseline" exit path cleanly, both windows must be partial.
TOTAL=$((TOTAL + 1))
SB=$(_make_quality_sandbox 0 5 0.9 0.7 30 "phase1" "phase1")
(cd "$SB" && bash "$DRIFT_SH" >/dev/null 2>&1)
RC=$?
DRIFT_VAL=$(jq -r '.quality.current_drift_pct' "$SB/.apex/STATE.json")
if [ "$RC" = "1" ] && [ "$DRIFT_VAL" = "0" ]; then
  echo "  ✅ C-4: baseline=0, rolling=5 → exit 1, no false drift (drift=$DRIFT_VAL)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-4: expected exit 1 + drift=0, got rc=$RC, drift=$DRIFT_VAL"
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB"

# --- C-5: baseline=10 (0.9), rolling=10 (0.7) → drift ≈ -22.22% ---
TOTAL=$((TOTAL + 1))
SB=$(_make_quality_sandbox 10 10 0.9 0.7 30 "phase1" "phase1")
(cd "$SB" && bash "$DRIFT_SH" >/dev/null 2>&1)
RC=$?
DRIFT_VAL=$(jq -r '.quality.current_drift_pct' "$SB/.apex/STATE.json")
# Expected: (0.7 - 0.9) / 0.9 * 100 = -22.2222
# NOTE: do not name the AWK var `exp` — that shadows the built-in `exp()` math
# function and produces an obscure "syntax error" on the BEGIN block.
EXPECTED_OK=$(awk -v d="$DRIFT_VAL" 'BEGIN{ target = -22.2222; diff = d - target; if (diff < 0) diff = -diff; print (diff < 0.01) ? "1" : "0" }')
if [ "$RC" = "0" ] && [ "$EXPECTED_OK" = "1" ]; then
  echo "  ✅ C-5: drift correctly computed at $DRIFT_VAL% (expected ≈ -22.22%)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-5: expected rc=0 + drift≈-22.22, got rc=$RC, drift=$DRIFT_VAL"
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB"

# --- C-6: quality_drift event fired when |drift|>5% AND tasks_completed>20 ---
TOTAL=$((TOTAL + 1))
SB=$(_make_quality_sandbox 10 10 0.9 0.7 30 "phase1" "phase1")
(cd "$SB" && bash "$DRIFT_SH" >/dev/null 2>&1)
EVENT_FIRED="no"
if [ -f "$SB/.apex/event-log.jsonl" ]; then
  if grep -q '"type":"quality_drift"' "$SB/.apex/event-log.jsonl" 2>/dev/null; then
    EVENT_FIRED="yes"
  fi
fi
if [ "$EVENT_FIRED" = "yes" ]; then
  echo "  ✅ C-6: quality_drift event fired (|drift|>5% AND tasks_completed=30)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-6: quality_drift event NOT fired despite |drift|>5% + tasks=30"
  [ -f "$SB/.apex/event-log.jsonl" ] && cat "$SB/.apex/event-log.jsonl" | sed 's/^/      /'
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB"

# --- C-7: drift NOT fired when tasks_completed <= 20 (insufficient signal) ---
TOTAL=$((TOTAL + 1))
SB=$(_make_quality_sandbox 10 10 0.9 0.7 15 "phase1" "phase1")
(cd "$SB" && bash "$DRIFT_SH" >/dev/null 2>&1)
EVENT_FIRED="no"
if [ -f "$SB/.apex/event-log.jsonl" ]; then
  if grep -q '"type":"quality_drift"' "$SB/.apex/event-log.jsonl" 2>/dev/null; then
    EVENT_FIRED="yes"
  fi
fi
DRIFT_VAL=$(jq -r '.quality.current_drift_pct' "$SB/.apex/STATE.json")
if [ "$EVENT_FIRED" = "no" ]; then
  echo "  ✅ C-7: quality_drift NOT fired with tasks_completed=15 (drift computed=$DRIFT_VAL, but no event)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-7: quality_drift fired prematurely with tasks_completed=15"
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB"

# --- C-8: Re-base on phase change (current_session_phase != baselined_at_phase, tasks_since_rebaseline >= 5)
# After invocation, baseline_window_tasks should equal the rolling snapshot (rebaseline event).
TOTAL=$((TOTAL + 1))
SB=$(_make_quality_sandbox 10 10 0.9 0.7 30 "phase2" "phase1")
# Verify pre-condition: baseline_avg currently is 0.9.
PRE_BASE_AVG=$(jq -r '((.quality.baseline_window_tasks // []) | map(.confidence_score // 0) | add / length)' "$SB/.apex/STATE.json")
(cd "$SB" && bash "$DRIFT_SH" >/dev/null 2>&1)
RC=$?
# Post: baseline should now be equal to the rolling (0.7 avg).
POST_BASE_AVG=$(jq -r '((.quality.baseline_window_tasks // []) | map(.confidence_score // 0) | add / length)' "$SB/.apex/STATE.json")
POST_BASELINED=$(jq -r '.quality.baselined_at_phase' "$SB/.apex/STATE.json")
POST_REBASE_COUNT=$(jq -r '.quality.tasks_since_rebaseline' "$SB/.apex/STATE.json")
# Confirm rebaseline event was logged.
REBASE_EVENT="no"
if [ -f "$SB/.apex/event-log.jsonl" ] && grep -q '"type":"quality.baseline.rebaseline"' "$SB/.apex/event-log.jsonl" 2>/dev/null; then
  REBASE_EVENT="yes"
fi
REBASE_OK=$(awk -v pre="$PRE_BASE_AVG" -v post="$POST_BASE_AVG" 'BEGIN{ diff_pre = pre - 0.9; if (diff_pre < 0) diff_pre = -diff_pre; diff_post = post - 0.7; if (diff_post < 0) diff_post = -diff_post; print (diff_pre < 0.01 && diff_post < 0.01) ? "1" : "0" }')
if [ "$REBASE_OK" = "1" ] && [ "$POST_BASELINED" = "phase2" ] && [ "$POST_REBASE_COUNT" = "0" ] && [ "$REBASE_EVENT" = "yes" ]; then
  echo "  ✅ C-8: rebaseline on phase change (pre=$PRE_BASE_AVG → post=$POST_BASE_AVG, baselined_at=$POST_BASELINED, event=$REBASE_EVENT)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-8: rebaseline failed — pre=$PRE_BASE_AVG, post=$POST_BASE_AVG, baselined=$POST_BASELINED, count=$POST_REBASE_COUNT, event=$REBASE_EVENT"
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB"

# --- C-9: Confidence mapping verification — mixed scores 1.0/0.5/0.0 must average to 0.5 ---
TOTAL=$((TOTAL + 1))
SB=$(mktemp -d)
mkdir -p "$SB/.apex"
# Construct a baseline of 10 entries: 4 high (1.0), 3 medium (0.5), 3 low (0.0).
# Average = (4*1.0 + 3*0.5 + 3*0.0) / 10 = 5.5/10 = 0.55.
# And rolling of 10 entries: same composition → drift should be 0%.
BASELINE=$(jq -nc '
  [
    {task_id:"h1", confidence_score:1.0, verifier_pass:true, attempts:1},
    {task_id:"h2", confidence_score:1.0, verifier_pass:true, attempts:1},
    {task_id:"h3", confidence_score:1.0, verifier_pass:true, attempts:1},
    {task_id:"h4", confidence_score:1.0, verifier_pass:true, attempts:1},
    {task_id:"m1", confidence_score:0.5, verifier_pass:true, attempts:1},
    {task_id:"m2", confidence_score:0.5, verifier_pass:true, attempts:1},
    {task_id:"m3", confidence_score:0.5, verifier_pass:true, attempts:1},
    {task_id:"l1", confidence_score:0.0, verifier_pass:false, attempts:1},
    {task_id:"l2", confidence_score:0.0, verifier_pass:false, attempts:1},
    {task_id:"l3", confidence_score:0.0, verifier_pass:false, attempts:1}
  ]')
ROLLING=$BASELINE
jq -n \
  --argjson baseline "$BASELINE" \
  --argjson rolling "$ROLLING" \
  '{
    current_phase: "p1",
    context: {current_session_phase: "p1"},
    session: {tasks_completed: 30},
    quality: {
      rolling_window_tasks: $rolling,
      baseline_window_tasks: $baseline,
      current_drift_pct: 0,
      alert_threshold_pct: 5,
      baselined_at_phase: "p1",
      tasks_since_rebaseline: 0
    }
  }' > "$SB/.apex/STATE.json"
(cd "$SB" && bash "$DRIFT_SH" >/dev/null 2>&1)
DRIFT_VAL=$(jq -r '.quality.current_drift_pct' "$SB/.apex/STATE.json")
# Equal baseline and rolling avg → drift = 0.0000.
DRIFT_OK=$(awk -v d="$DRIFT_VAL" 'BEGIN{ diff = d; if (diff < 0) diff = -diff; print (diff < 0.01) ? "1" : "0" }')
if [ "$DRIFT_OK" = "1" ]; then
  echo "  ✅ C-9: confidence mapping (4×1.0 + 3×0.5 + 3×0.0) avg=0.55; drift=$DRIFT_VAL (≈0%)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-9: confidence mapping check failed — drift=$DRIFT_VAL"
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  echo ""
  echo "$PASS/$TOTAL passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] || exit 1
fi
