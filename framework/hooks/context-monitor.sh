#!/bin/bash
set -u
# v7: Real token counting from STATE.json instead of heuristic [R2]
# R2: compact at 50-60%, hard rotate at 70%, never exceed 75%
# Previous heuristic: AGENT_CALLS * 15000 — wildly inaccurate
source "$(dirname "$0")/_require-jq.sh"
require_jq
source "$(dirname "$0")/_state-update.sh"

export APEX_HOOK_SOURCE="context-monitor"

STATE_FILE=".apex/STATE.json"
BUDGET_FILE=".apex/CONTEXT_BUDGET.json"

# R13-006 (F-306): health-json mode — emit the 8-metric R2-C212 snapshot
# documented in framework/schemas/HEALTH_METRICS.schema.json.
#
# Activated by either:
#   APEX_CONTEXT_MONITOR_MODE=health-json    (env var)
#   context-monitor.sh --health-json         (argv flag)
#
# The mode is additive and disjoint from the default threshold-check
# behavior below: it short-circuits before STATE-mutation, prints the
# JSON snapshot to stdout, and exits 0. /apex:status calls this mode
# to render the Context Health block above the existing dashboard
# sections (autonomy ladder, DORA, autopilot).
#
# Stub-rendering contract:
#   - If STATE.tokens.total_input is 0 (counter unwired), gauge.status
#     is 'unmeasured' and gauge.pct is null — matches the schema's
#     `["integer", "null"]` enum for gauge.pct. status.md renders this
#     as "🟡 unmeasured (run /apex:next to wire counter)".
#   - If STATE.session.last_rotation_at is null, last_rotation.at and
#     ago_minutes are null and reason is null — status.md renders
#     "never".
#   - If STATE.context.last_mask_at is null, last_mask.at and
#     ago_minutes are null and blocks_masked is 0 — status.md renders
#     "never".
#   - If STATE.tokens.cache_writes is 0 (no cache adapter), cache_efficiency.status
#     is 'n/a' and hit_rate_pct is null — status.md renders "n/a".
#   - Phase 12 M16 (quality_rolling) is unconditionally 'n/a' until
#     M16 lands; status.md renders "n/a (Phase 12 M16 pending)".
_apex_emit_health_json() {
  local state_file="$1" budget_file="$2"
  if [ ! -f "$state_file" ]; then
    # Fresh-session stub: every metric in its zero / never / n/a form,
    # but still schema-conformant. The orchestrator may invoke this
    # mode before STATE.json exists during /apex:status pre-bootstrap.
    printf '{"gauge":{"status":"unmeasured","pct":null,"target_pct":55,"hard_pct":70},'
    printf '"budget_by_zone":{"stable_prefix":{"used":0,"budget":30000},"task_context":{"used":0,"budget":50000},"working_memory":{"used":0,"budget":60000},"gen_reserve":{"reserved":60000}},'
    printf '"cache_efficiency":{"status":"n/a","hit_rate_pct":null,"hits":0,"calls":0},'
    printf '"last_rotation":{"at":null,"ago_minutes":null,"reason":null},'
    printf '"last_mask":{"at":null,"ago_minutes":null,"blocks_masked":0},'
    printf '"drift_indicators":{"spec_drift_count":0,"circuit_breaker_triggers":0,"reflexion_attempts":0,"reflexion_attempts_max":0,"low_confidence_results":0},'
    printf '"quality_rolling":{"status":"n/a"},'
    printf '"alerts":[]}\n'
    return 0
  fi
  # Threshold defaults match the default-branch logic below (lines
  # 21–22): 55 proactive, 70 hard. Read from CONTEXT_BUDGET when
  # present.
  local target_pct hard_pct effective_capacity total_input cache_hits cache_writes
  local last_rotation_at rotation_reason last_mask_at mask_blocks
  local spec_drift cb_triggers refl_total refl_max low_conf
  local now_epoch rot_epoch mask_epoch
  target_pct=$(jq -r '.thresholds.proactive_compact_pct // 55' "$budget_file" 2>/dev/null || echo 55)
  hard_pct=$(jq -r '.thresholds.hard_rotate_pct // 70' "$budget_file" 2>/dev/null || echo 70)
  effective_capacity=$(jq -r '.capacity_tokens // 200000' "$budget_file" 2>/dev/null || echo 200000)
  [ "$effective_capacity" -le 0 ] 2>/dev/null && effective_capacity=200000

  total_input=$(jq -r '.tokens.total_input // 0' "$state_file" 2>/dev/null || echo 0)
  cache_hits=$(jq -r '.tokens.cache_hits // 0' "$state_file" 2>/dev/null || echo 0)
  cache_writes=$(jq -r '.tokens.cache_writes // 0' "$state_file" 2>/dev/null || echo 0)

  # Zone budgets default to CONTEXT_BUDGET.zone_budgets.{stable_prefix,
  # task_context, working_memory, gen_reserve}. When absent, fall back
  # to the canonical 30K/50K/60K/60K from the spec-quoted plan rendering.
  local zone_sp_budget zone_tc_budget zone_wm_budget zone_gr_reserved
  zone_sp_budget=$(jq -r '.zone_budgets.stable_prefix // 30000' "$budget_file" 2>/dev/null || echo 30000)
  zone_tc_budget=$(jq -r '.zone_budgets.task_context // 50000' "$budget_file" 2>/dev/null || echo 50000)
  zone_wm_budget=$(jq -r '.zone_budgets.working_memory // 60000' "$budget_file" 2>/dev/null || echo 60000)
  zone_gr_reserved=$(jq -r '.zone_budgets.gen_reserve // 60000' "$budget_file" 2>/dev/null || echo 60000)
  # Per-zone used: prefer STATE.tokens.zones.* when present (Phase 12
  # M11 deliverable); otherwise fall back to 0 — the stub-rendering
  # contract says callers SHOULD show 0/budget when no per-zone counter
  # has populated.
  local zone_sp_used zone_tc_used zone_wm_used
  zone_sp_used=$(jq -r '.tokens.zones.stable_prefix // 0' "$state_file" 2>/dev/null || echo 0)
  zone_tc_used=$(jq -r '.tokens.zones.task_context // 0' "$state_file" 2>/dev/null || echo 0)
  zone_wm_used=$(jq -r '.tokens.zones.working_memory // 0' "$state_file" 2>/dev/null || echo 0)

  # Gauge: status branches on total_input==0 (unmeasured) and
  # otherwise pct vs target/hard thresholds.
  local gauge_status gauge_pct_json
  if [ "$total_input" -gt 0 ] 2>/dev/null; then
    local pct=$((total_input * 100 / effective_capacity))
    if [ "$pct" -ge "$hard_pct" ]; then
      gauge_status="crit"
    elif [ "$pct" -ge "$target_pct" ]; then
      gauge_status="warn"
    else
      gauge_status="ok"
    fi
    gauge_pct_json="$pct"
  else
    gauge_status="unmeasured"
    gauge_pct_json="null"
  fi

  # Cache efficiency: status='n/a' if cache_writes==0 (no cache
  # adapter or no eligible writes yet); otherwise compute hit_rate.
  local cache_status cache_rate_json cache_calls
  cache_calls=$((cache_hits + cache_writes))
  if [ "$cache_calls" -le 0 ] 2>/dev/null; then
    cache_status="n/a"
    cache_rate_json="null"
  else
    local rate=$((cache_hits * 100 / cache_calls))
    if [ "$rate" -ge 75 ]; then
      cache_status="ok"
    elif [ "$rate" -ge 40 ]; then
      cache_status="warn"
    else
      cache_status="crit"
    fi
    cache_rate_json="$rate"
  fi

  # Last rotation: R13-005's STATE.session.last_rotation_at + rotation_reason.
  # ago_minutes computed from now-epoch when both timestamps present.
  last_rotation_at=$(jq -r '.session.last_rotation_at // ""' "$state_file" 2>/dev/null || echo "")
  rotation_reason=$(jq -r '.session.rotation_reason // ""' "$state_file" 2>/dev/null || echo "")
  now_epoch=$(date -u +%s 2>/dev/null || date +%s)
  local rot_at_json rot_ago_json rot_reason_json
  if [ -n "$last_rotation_at" ] && [ "$last_rotation_at" != "null" ]; then
    rot_epoch=$(date -u -d "$last_rotation_at" +%s 2>/dev/null || echo "")
    if [ -n "$rot_epoch" ]; then
      rot_ago_json=$(( (now_epoch - rot_epoch) / 60 ))
    else
      rot_ago_json="null"
    fi
    rot_at_json="\"$last_rotation_at\""
    rot_reason_json=$(printf '%s' "$rotation_reason" | jq -R '.')
  else
    rot_at_json="null"
    rot_ago_json="null"
    rot_reason_json="null"
  fi

  # Last mask: R13-002's STATE.context.last_mask_at + blocks_masked count.
  last_mask_at=$(jq -r '.context.last_mask_at // ""' "$state_file" 2>/dev/null || echo "")
  mask_blocks=$(jq -r '.context.last_mask_blocks // 0' "$state_file" 2>/dev/null || echo 0)
  local mask_at_json mask_ago_json
  if [ -n "$last_mask_at" ] && [ "$last_mask_at" != "null" ]; then
    mask_epoch=$(date -u -d "$last_mask_at" +%s 2>/dev/null || echo "")
    if [ -n "$mask_epoch" ]; then
      mask_ago_json=$(( (now_epoch - mask_epoch) / 60 ))
    else
      mask_ago_json="null"
    fi
    mask_at_json="\"$last_mask_at\""
  else
    mask_at_json="null"
    mask_ago_json="null"
  fi

  # Drift indicators: prefer STATE.session.drift_indicators (R13-005
  # canonical home); fall back to top-level STATE.drift_indicators for
  # legacy projects.
  spec_drift=$(jq -r '.session.drift_indicators.spec_drift_count // .drift_indicators.spec_drift_count // 0' "$state_file" 2>/dev/null || echo 0)
  cb_triggers=$(jq -r '.session.drift_indicators.circuit_breaker_triggers // .drift_indicators.circuit_breaker_triggers // 0' "$state_file" 2>/dev/null || echo 0)
  refl_total=$(jq -r '.session.drift_indicators.reflexion_total_attempts // .drift_indicators.reflexion_total_attempts // 0' "$state_file" 2>/dev/null || echo 0)
  refl_max=$(jq -r '.session.drift_indicators.reflexion_attempts_max // .drift_indicators.reflexion_attempts_max // 0' "$state_file" 2>/dev/null || echo 0)
  low_conf=$(jq -r '.session.drift_indicators.low_confidence_results // .drift_indicators.low_confidence_results // 0' "$state_file" 2>/dev/null || echo 0)

  # Alerts: derived from the metric states. Order = most-severe first.
  local alerts_json="["
  local first=1
  _append_alert() {
    if [ "$first" -eq 1 ]; then
      alerts_json="${alerts_json}$1"
      first=0
    else
      alerts_json="${alerts_json},$1"
    fi
  }
  if [ "$gauge_status" = "crit" ]; then
    _append_alert "\"context_fill_critical: hard_rotate threshold met\""
  elif [ "$gauge_status" = "unmeasured" ]; then
    _append_alert "\"counter_unwired: STATE.tokens.total_input is 0\""
  fi
  if [ "$cb_triggers" -gt 0 ] 2>/dev/null; then
    _append_alert "\"circuit_breaker_active: ${cb_triggers} trigger(s)\""
  fi
  if [ "$refl_max" -ge 5 ] 2>/dev/null; then
    _append_alert "\"reflexion_high: ${refl_total}/${refl_max} attempts on a single task\""
  fi
  alerts_json="${alerts_json}]"

  printf '{"gauge":{"status":"%s","pct":%s,"target_pct":%s,"hard_pct":%s},' \
    "$gauge_status" "$gauge_pct_json" "$target_pct" "$hard_pct"
  printf '"budget_by_zone":{"stable_prefix":{"used":%s,"budget":%s},"task_context":{"used":%s,"budget":%s},"working_memory":{"used":%s,"budget":%s},"gen_reserve":{"reserved":%s}},' \
    "$zone_sp_used" "$zone_sp_budget" "$zone_tc_used" "$zone_tc_budget" "$zone_wm_used" "$zone_wm_budget" "$zone_gr_reserved"
  printf '"cache_efficiency":{"status":"%s","hit_rate_pct":%s,"hits":%s,"calls":%s},' \
    "$cache_status" "$cache_rate_json" "$cache_hits" "$cache_calls"
  printf '"last_rotation":{"at":%s,"ago_minutes":%s,"reason":%s},' \
    "$rot_at_json" "$rot_ago_json" "$rot_reason_json"
  printf '"last_mask":{"at":%s,"ago_minutes":%s,"blocks_masked":%s},' \
    "$mask_at_json" "$mask_ago_json" "$mask_blocks"
  printf '"drift_indicators":{"spec_drift_count":%s,"circuit_breaker_triggers":%s,"reflexion_attempts":%s,"reflexion_attempts_max":%s,"low_confidence_results":%s},' \
    "$spec_drift" "$cb_triggers" "$refl_total" "$refl_max" "$low_conf"
  printf '"quality_rolling":{"status":"n/a"},'
  printf '"alerts":%s}\n' "$alerts_json"
}

# Argv / env-var dispatch for health-json mode. Argv flag wins over
# env var when both present.
APEX_CONTEXT_MONITOR_MODE_EFFECTIVE="${APEX_CONTEXT_MONITOR_MODE:-default}"
if [ "${1:-}" = "--health-json" ]; then
  APEX_CONTEXT_MONITOR_MODE_EFFECTIVE="health-json"
fi
if [ "$APEX_CONTEXT_MONITOR_MODE_EFFECTIVE" = "health-json" ]; then
  _apex_emit_health_json "$STATE_FILE" "$BUDGET_FILE"
  exit 0
fi

if [ ! -f "$STATE_FILE" ]; then
  echo "✅ CONTEXT: No state file — fresh session"
  exit 0
fi

# v7 thresholds from CONTEXT_BUDGET.json (R2-validated)
WARNING_PCT=$(jq -r '.thresholds.proactive_compact_pct // 55' "$BUDGET_FILE" 2>/dev/null || echo 55)
CRITICAL_PCT=$(jq -r '.thresholds.hard_rotate_pct // 70' "$BUDGET_FILE" 2>/dev/null || echo 70)

# v7: Use ACTUAL token data from STATE.json (updated by orchestrator in Step G)
TOTAL_INPUT=$(jq -r '.tokens.total_input // 0' "$STATE_FILE" 2>/dev/null || echo 0)
TOTAL_OUTPUT=$(jq -r '.tokens.total_output // 0' "$STATE_FILE" 2>/dev/null || echo 0)

# Effective capacity from CONTEXT_BUDGET.json (default 200K per R2 design)
EFFECTIVE_CAPACITY=$(jq -r '.capacity_tokens // 200000' "$BUDGET_FILE" 2>/dev/null || echo 200000)
# Guard against zero/invalid capacity to prevent division by zero
[ "$EFFECTIVE_CAPACITY" -le 0 ] 2>/dev/null && EFFECTIVE_CAPACITY=200000

if [ "$TOTAL_INPUT" -gt 0 ]; then
  # Real token data available — use it
  ESTIMATED_PCT=$((TOTAL_INPUT * 100 / EFFECTIVE_CAPACITY))
else
  # Fallback: count agent calls if token data not yet populated
  AGENT_CALLS=$(jq -r '
    [.tokens.by_agent | to_entries[]? | .value.calls] | add // 0' "$STATE_FILE" 2>/dev/null || echo 0)
  # Conservative heuristic: 20K per call (higher than the earlier 15K to be safe)
  ESTIMATED_USAGE=$((AGENT_CALLS * 20000))
  ESTIMATED_PCT=$((ESTIMATED_USAGE * 100 / EFFECTIVE_CAPACITY))
fi

# Update STATE.json with current estimate
_state_update --argjson pct "$ESTIMATED_PCT" \
   '.context.estimated_context_usage_pct = $pct' "$STATE_FILE"

if [ "$ESTIMATED_PCT" -ge "$CRITICAL_PCT" ]; then
  echo "CRITICAL_OVERFLOW"
  echo "⚠️ Context at ~${ESTIMATED_PCT}% (threshold: ${CRITICAL_PCT}%)"
  echo "R2: coding quality degrades severely above 70%."
  echo "Run /apex:resume for fresh context."
  exit 2
elif [ "$ESTIMATED_PCT" -ge "$WARNING_PCT" ]; then
  echo "WARNING_OVERFLOW"
  echo "⚠️ Context at ~${ESTIMATED_PCT}%. Proactive compact recommended."
  echo "R2: observation masking (deleting old tool outputs) is preferred over LLM summarization."
  exit 1
else
  echo "✅ CONTEXT: ~${ESTIMATED_PCT}% used (${TOTAL_INPUT} input tokens tracked)"
  exit 0
fi