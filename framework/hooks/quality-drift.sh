#!/usr/bin/env bash
# quality-drift.sh — M16 quality drift computation (Phase 12.09).
#
# Hook type: Command-Invoked (fired by /apex:next on PASS path; also
# safe to run standalone for ad-hoc inspection).
#
# Purpose
#   Compute quality_drift_pct from STATE.quality.{rolling_window_tasks,
#   baseline_window_tasks} and persist into STATE.quality.current_drift_pct.
#   Emits a `quality_drift` event to .apex/event-log.jsonl (consumed by
#   R12 F-205 rotation triggers) when |drift_pct| > alert_threshold_pct
#   AND tasks_completed > 20 (insufficient-data guard).
#
# This is the falsification mechanism for R2-C214 ("task#50 ≈ task#1
# quality") — without measured drift, all APEX promises about context
# preservation are unfalsifiable theatre.
#
# Drift formula
#   baseline_avg = avg(confidence_score over baseline_window_tasks)
#                  (null if baseline has fewer than 10 entries)
#   current_avg  = avg(confidence_score over rolling_window_tasks)
#   drift_pct    = ((current_avg - baseline_avg) / baseline_avg) * 100
#                  Sign: negative = degradation.
#
# Rebaseline contract
#   Baseline is FROZEN on first fill (10 tasks). It is re-frozen
#   (rebaseline) when:
#     1. STATE.context.current_session_phase differs from
#        STATE.quality.baselined_at_phase, AND
#     2. tasks_since_rebaseline >= 5 (avoids greenfield-vs-mature
#        distortion from PLAN task 12.09 §10 non-obvious insight #2).
#   On rebaseline: copy current rolling_window into baseline_window,
#   reset tasks_since_rebaseline to 0, update baselined_at_phase.
#
# Spec anchors
#   PLAN.md task 12.09 §5-6 (M16 quality drift contract).
#   R2-C214 "ultimate APEX metric" (task#50 ≈ task#1 quality).
#   framework/docs/PRIVACY-POLICY.md (drift is a counter — telemetry-safe).
#
# Usage
#   bash framework/hooks/quality-drift.sh
#
# Exit codes
#   0 = ok; STATE.quality.current_drift_pct updated (may be 0).
#   1 = insufficient data (baseline < 10 entries) — no drift computed.
#   2 = invocation error (no .apex/, jq missing, STATE.json missing).

set -uo pipefail

# ── Invocation guards ──
if [ ! -d ".apex" ]; then
  echo "🚫 quality-drift: no .apex/ in cwd" >&2
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "🚫 quality-drift: jq is required" >&2
  exit 2
fi

STATE_FILE=".apex/STATE.json"
if [ ! -f "$STATE_FILE" ]; then
  echo "🚫 quality-drift: STATE.json missing at $STATE_FILE" >&2
  exit 2
fi

EVENT_LOG=".apex/event-log.jsonl"
NOW_ISO="$(date -u +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date +'%Y-%m-%dT%H:%M:%SZ')"

# ── Read STATE.quality (defensive: legacy STATE without `quality` field
#    must work — use `// {}` fallback per do-not-touch zone). ──
ROLLING_LEN=$(jq -r '(.quality.rolling_window_tasks // []) | length' "$STATE_FILE" 2>/dev/null | tr -d '\r')
BASELINE_LEN=$(jq -r '(.quality.baseline_window_tasks // []) | length' "$STATE_FILE" 2>/dev/null | tr -d '\r')
ALERT_THRESHOLD=$(jq -r '(.quality.alert_threshold_pct // 5)' "$STATE_FILE" 2>/dev/null | tr -d '\r')
BASELINED_AT_PHASE=$(jq -r '(.quality.baselined_at_phase // "")' "$STATE_FILE" 2>/dev/null | tr -d '\r')
TASKS_SINCE_REBASELINE=$(jq -r '(.quality.tasks_since_rebaseline // 0)' "$STATE_FILE" 2>/dev/null | tr -d '\r')
CURRENT_PHASE=$(jq -r '(.context.current_session_phase // "")' "$STATE_FILE" 2>/dev/null | tr -d '\r')
TASKS_COMPLETED=$(jq -r '(.session.tasks_completed // 0)' "$STATE_FILE" 2>/dev/null | tr -d '\r')

# Sanitize numeric reads.
: "${ROLLING_LEN:=0}"
: "${BASELINE_LEN:=0}"
: "${TASKS_SINCE_REBASELINE:=0}"
: "${TASKS_COMPLETED:=0}"
[ -z "$ALERT_THRESHOLD" ] && ALERT_THRESHOLD=5

# ── Baseline initialization: when rolling has filled to 10 AND
#    baseline is empty (or has fewer than 10), freeze baseline = rolling
#    snapshot. This is the "first 10 tasks freeze baseline" rule. ──
NEEDS_INITIAL_FREEZE=0
if [ "$BASELINE_LEN" -lt 10 ] && [ "$ROLLING_LEN" -ge 10 ]; then
  NEEDS_INITIAL_FREEZE=1
fi

# ── Rebaseline guard: phase changed AND 5+ tasks completed since change.
#    Compares STATE.context.current_session_phase against
#    STATE.quality.baselined_at_phase. The 5-task gate prevents a fresh
#    phase from immediately rebaselining (greenfield-vs-mature distortion). ──
NEEDS_REBASELINE=0
if [ -n "$CURRENT_PHASE" ] \
  && [ -n "$BASELINED_AT_PHASE" ] \
  && [ "$CURRENT_PHASE" != "$BASELINED_AT_PHASE" ] \
  && [ "$TASKS_SINCE_REBASELINE" -ge 5 ] \
  && [ "$ROLLING_LEN" -ge 10 ]; then
  NEEDS_REBASELINE=1
fi

# ── Apply freeze / rebaseline atomically via rename-temp ──
if [ "$NEEDS_INITIAL_FREEZE" -eq 1 ] || [ "$NEEDS_REBASELINE" -eq 1 ]; then
  TMP=".apex/STATE.json.qdrift.tmp"
  if jq \
      --arg phase "$CURRENT_PHASE" \
      '
      .quality = (.quality // {})
      | .quality.baseline_window_tasks = (.quality.rolling_window_tasks // [])
      | .quality.baselined_at_phase = $phase
      | .quality.tasks_since_rebaseline = 0
      ' "$STATE_FILE" > "$TMP" 2>/dev/null; then
    mv "$TMP" "$STATE_FILE"
    # Re-read post-update lengths/phase fields for downstream logic.
    BASELINE_LEN=$(jq -r '(.quality.baseline_window_tasks // []) | length' "$STATE_FILE" 2>/dev/null | tr -d '\r')
    BASELINED_AT_PHASE=$CURRENT_PHASE
    TASKS_SINCE_REBASELINE=0
    if [ "$NEEDS_INITIAL_FREEZE" -eq 1 ]; then
      printf '{"ts":"%s","type":"quality.baseline.frozen","source":"quality-drift","phase":"%s","window_size":%s}\n' \
        "$NOW_ISO" "$CURRENT_PHASE" "$BASELINE_LEN" >> "$EVENT_LOG" 2>/dev/null || true
    else
      printf '{"ts":"%s","type":"quality.baseline.rebaseline","source":"quality-drift","phase":"%s","window_size":%s}\n' \
        "$NOW_ISO" "$CURRENT_PHASE" "$BASELINE_LEN" >> "$EVENT_LOG" 2>/dev/null || true
    fi
  else
    rm -f "$TMP"
    echo "🚫 quality-drift: STATE update (freeze/rebaseline) failed" >&2
    exit 2
  fi
fi

# ── Insufficient data: baseline must have 10 entries to compute drift. ──
if [ "$BASELINE_LEN" -lt 10 ]; then
  echo "ℹ️  quality-drift: insufficient baseline data (have $BASELINE_LEN/10) — drift not computed" >&2
  exit 1
fi
# Same insufficiency for rolling — at least 1 entry needed for current_avg.
if [ "$ROLLING_LEN" -lt 1 ]; then
  echo "ℹ️  quality-drift: empty rolling window — drift not computed" >&2
  exit 1
fi

# ── Compute averages via jq (single source of truth). ──
BASELINE_AVG=$(jq -r '
  ((.quality.baseline_window_tasks // []) | map(.confidence_score // 0))
  | if length == 0 then 0 else (add / length) end
' "$STATE_FILE" 2>/dev/null | tr -d '\r')
CURRENT_AVG=$(jq -r '
  ((.quality.rolling_window_tasks // []) | map(.confidence_score // 0))
  | if length == 0 then 0 else (add / length) end
' "$STATE_FILE" 2>/dev/null | tr -d '\r')

# Defensive: if baseline_avg is 0, drift is undefined (division by zero).
# Treat as 0 drift but exit 1 so caller knows it's degenerate.
if [ -z "$BASELINE_AVG" ] || awk -v b="$BASELINE_AVG" 'BEGIN{exit !(b == 0)}'; then
  echo "ℹ️  quality-drift: baseline_avg is 0 — drift undefined (degenerate baseline)" >&2
  exit 1
fi

# Drift in percent.
DRIFT_PCT=$(awk -v c="$CURRENT_AVG" -v b="$BASELINE_AVG" 'BEGIN{ printf "%.4f", ((c - b) / b) * 100 }')

# ── Persist current_drift_pct atomically. ──
TMP=".apex/STATE.json.qdrift.tmp"
if jq \
    --argjson drift "$DRIFT_PCT" \
    '
    .quality = (.quality // {})
    | .quality.current_drift_pct = $drift
    ' "$STATE_FILE" > "$TMP" 2>/dev/null; then
  mv "$TMP" "$STATE_FILE"
else
  rm -f "$TMP"
  echo "🚫 quality-drift: STATE update (current_drift_pct) failed" >&2
  exit 2
fi

# ── Emit quality_drift event when threshold crossed AND tasks_completed > 20. ──
# Use absolute value for the threshold comparison (drift can be negative).
ABS_DRIFT=$(awk -v d="$DRIFT_PCT" 'BEGIN{ if (d < 0) d = -d; printf "%.4f", d }')
# awk-only boolean compare (handles floats).
EXCEEDS=$(awk -v a="$ABS_DRIFT" -v t="$ALERT_THRESHOLD" 'BEGIN{ print (a > t) ? "1" : "0" }')

if [ "$EXCEEDS" = "1" ] && [ "$TASKS_COMPLETED" -gt 20 ]; then
  printf '{"ts":"%s","type":"quality_drift","source":"quality-drift","drift_pct":%s,"baseline_avg":%s,"current_avg":%s,"alert_threshold_pct":%s,"tasks_completed":%s,"baseline_window_size":%s,"rolling_window_size":%s}\n' \
    "$NOW_ISO" "$DRIFT_PCT" "$BASELINE_AVG" "$CURRENT_AVG" "$ALERT_THRESHOLD" "$TASKS_COMPLETED" "$BASELINE_LEN" "$ROLLING_LEN" \
    >> "$EVENT_LOG" 2>/dev/null || true

  # Best-effort telemetry emit (opt-out gated by _telemetry-emit.sh).
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  if [ -f "$SCRIPT_DIR/_telemetry-emit.sh" ]; then
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/_telemetry-emit.sh"
    apex_telemetry_emit "quality_drift" "$CURRENT_PHASE" "{\"drift_pct\":${DRIFT_PCT},\"baseline_avg\":${BASELINE_AVG},\"current_avg\":${CURRENT_AVG},\"tasks_completed\":${TASKS_COMPLETED}}" || true
  fi

  echo "⚠️  quality-drift: ${DRIFT_PCT}% drift exceeds threshold ±${ALERT_THRESHOLD}% (baseline ${BASELINE_AVG} → current ${CURRENT_AVG})"
else
  echo "✅ quality-drift: ${DRIFT_PCT}% drift (baseline ${BASELINE_AVG} → current ${CURRENT_AVG})"
fi

exit 0
