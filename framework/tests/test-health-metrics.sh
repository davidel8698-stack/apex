#!/usr/bin/env bash
# R13-006 (F-306): 8-metric Context Health dashboard — test battery.
#
# Cases (per REMEDIATION-PLAN-R13.md §"Files to create"):
#   (1) full STATE — every metric populated, gauge.status='ok' or
#       'warn'/'crit' by threshold, alerts may be empty
#   (2) pre-R12-001 STATE (total_input=0) — gauge.status='unmeasured',
#       gauge.pct=null, counter_unwired alert raised
#   (3) no rotation yet (last_rotation_at=null) — last_rotation
#       {at:null, ago_minutes:null, reason:null}
#   (4) no mask yet (last_mask_at=null) — last_mask
#       {at:null, ago_minutes:null, blocks_masked:0}
#   (5) cache disabled (cache_hits=0, cache_writes=0) —
#       cache_efficiency.status='n/a', hit_rate_pct=null
#   (6) terminal without color (TERM=dumb / NO_COLOR=1) — the
#       health-json mode itself is color-agnostic, but we exercise
#       the env-var path to confirm no ANSI codes leak into JSON
#   (7) alerts populated — gauge.status='crit' (90%) AND
#       circuit_breaker_triggers=1 → ≥2 alert items, severity-ordered
#   (8) Phase 12 M16 pending — quality_rolling.status=='n/a'
#       (unconditional invariant for R13)
#
# Harness conventions (R10-008 + R11-003):
#   - LOCAL_PASS / LOCAL_FAIL are file-scope counters;
#     harness_assert_local bridges into the runner banner.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/framework/hooks/context-monitor.sh"
SCHEMA="$REPO_ROOT/framework/schemas/HEALTH_METRICS.schema.json"

# shellcheck source=_test-utils.sh
[ -f "$SCRIPT_DIR/_test-utils.sh" ] && source "$SCRIPT_DIR/_test-utils.sh"

if [ ! -f "$HOOK" ]; then
  echo "FAIL: context-monitor.sh not found at $HOOK" >&2
  exit 1
fi
if [ ! -f "$SCHEMA" ]; then
  echo "FAIL: HEALTH_METRICS.schema.json not found at $SCHEMA" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not available — health-json mode requires jq"
  exit 0
fi

LOCAL_PASS=0
LOCAL_FAIL=0

_pass() { echo "  PASS: $1"; LOCAL_PASS=$((LOCAL_PASS + 1)); }
_fail() { echo "  FAIL: $1" >&2; LOCAL_FAIL=$((LOCAL_FAIL + 1)); }

# explicit-exit-trap: cleanup of mktemp working tree (R9-013 contract).
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Helper: scaffold a .apex/ tree inside a case dir.
_scaffold() {
  local d="$1" state_overrides="${2:-.}"
  mkdir -p "$d/.apex"
  cat > "$d/.apex/STATE.json.base" <<'JSON'
{
  "tokens": {
    "total_input": 0,
    "total_output": 0,
    "cache_hits": 0,
    "cache_writes": 0,
    "zones": {
      "stable_prefix": 0,
      "task_context": 0,
      "working_memory": 0
    }
  },
  "context": {
    "estimated_context_usage_pct": 0,
    "last_mask_at": null,
    "last_mask_blocks": 0
  },
  "session": {
    "last_rotation_at": null,
    "rotation_reason": null,
    "drift_indicators": {
      "spec_drift_count": 0,
      "circuit_breaker_triggers": 0,
      "reflexion_total_attempts": 0,
      "reflexion_attempts_max": 0,
      "low_confidence_results": 0
    }
  }
}
JSON
  jq "$state_overrides" "$d/.apex/STATE.json.base" > "$d/.apex/STATE.json"
  rm -f "$d/.apex/STATE.json.base"

  # Minimal CONTEXT_BUDGET.json matching the framework default-shape.
  cat > "$d/.apex/CONTEXT_BUDGET.json" <<'JSON'
{
  "capacity_tokens": 200000,
  "thresholds": {
    "proactive_compact_pct": 55,
    "hard_rotate_pct": 70
  },
  "zone_budgets": {
    "stable_prefix": 30000,
    "task_context": 50000,
    "working_memory": 60000,
    "gen_reserve": 60000
  }
}
JSON
}

# Helper: invoke context-monitor.sh --health-json from a case dir.
# Returns JSON on stdout. Runs in subshell so cd does not leak.
_call_health_json() {
  local case_dir="$1"
  (
    cd "$case_dir" || exit 1
    bash "$HOOK" --health-json 2>/dev/null
  )
}

# Helper: assert a jq filter on the JSON output equals expected value.
_assert_jq() {
  local label="$1" json="$2" filter="$3" expected="$4"
  local actual
  actual=$(printf '%s' "$json" | jq -r "$filter" 2>/dev/null)
  if [ "$actual" = "$expected" ]; then
    _pass "$label (jq '$filter' = '$expected')"
  else
    _fail "$label (jq '$filter' expected '$expected', got '$actual')"
  fi
}

# Helper: assert the JSON has all 8 top-level keys (schema-required).
_assert_8_keys() {
  local label="$1" json="$2"
  local keys
  keys=$(printf '%s' "$json" | jq -r 'keys | join(",")' 2>/dev/null)
  local expected="alerts,budget_by_zone,cache_efficiency,drift_indicators,gauge,last_mask,last_rotation,quality_rolling"
  if [ "$keys" = "$expected" ]; then
    _pass "$label — all 8 R2-C212 metric keys present"
  else
    _fail "$label — keys mismatch: expected '$expected', got '$keys'"
  fi
}

# ---- Case (1): full STATE — every metric populated ----
CASE1="$WORK/case1"
_scaffold "$CASE1" '
  .tokens.total_input = 94000
  | .tokens.cache_hits = 12
  | .tokens.cache_writes = 2
  | .tokens.zones.stable_prefix = 8000
  | .tokens.zones.task_context = 22000
  | .tokens.zones.working_memory = 14000
  | .context.last_mask_at = "2026-05-15T03:51:00Z"
  | .context.last_mask_blocks = 7
  | .session.last_rotation_at = "2026-05-15T03:14:00Z"
  | .session.rotation_reason = "phase_boundary"
  | .session.drift_indicators.reflexion_total_attempts = 2
  | .session.drift_indicators.reflexion_attempts_max = 9
'
JSON1=$(_call_health_json "$CASE1")
_assert_8_keys "(1) full STATE" "$JSON1"
_assert_jq "(1) gauge.status=='warn' at 47% (>55? no — 94K/200K=47%, so 'ok')" \
  "$JSON1" '.gauge.status' "ok"
_assert_jq "(1) cache_efficiency.hits=12" "$JSON1" '.cache_efficiency.hits' "12"
_assert_jq "(1) last_rotation.reason=phase_boundary" "$JSON1" '.last_rotation.reason' "phase_boundary"
_assert_jq "(1) last_mask.blocks_masked=7" "$JSON1" '.last_mask.blocks_masked' "7"

# ---- Case (2): pre-R12-001 STATE (total_input=0) ----
CASE2="$WORK/case2"
_scaffold "$CASE2" '.tokens.total_input = 0'
JSON2=$(_call_health_json "$CASE2")
_assert_jq "(2) gauge.status='unmeasured' when total_input=0" \
  "$JSON2" '.gauge.status' "unmeasured"
_assert_jq "(2) gauge.pct=null when unmeasured" \
  "$JSON2" '.gauge.pct' "null"
# Alert must include counter_unwired
ALERT2=$(printf '%s' "$JSON2" | jq -r '.alerts | map(select(startswith("counter_unwired"))) | length')
if [ "$ALERT2" = "1" ]; then
  _pass "(2) counter_unwired alert raised when gauge.status=unmeasured"
else
  _fail "(2) counter_unwired alert missing from .alerts (got $ALERT2 matches)"
fi

# ---- Case (3): no rotation yet ----
CASE3="$WORK/case3"
_scaffold "$CASE3" '.tokens.total_input = 30000 | .session.last_rotation_at = null'
JSON3=$(_call_health_json "$CASE3")
_assert_jq "(3) last_rotation.at=null when never rotated" \
  "$JSON3" '.last_rotation.at' "null"
_assert_jq "(3) last_rotation.ago_minutes=null when never rotated" \
  "$JSON3" '.last_rotation.ago_minutes' "null"
_assert_jq "(3) last_rotation.reason=null when never rotated" \
  "$JSON3" '.last_rotation.reason' "null"

# ---- Case (4): no mask yet ----
CASE4="$WORK/case4"
_scaffold "$CASE4" '.tokens.total_input = 30000 | .context.last_mask_at = null'
JSON4=$(_call_health_json "$CASE4")
_assert_jq "(4) last_mask.at=null when never masked" \
  "$JSON4" '.last_mask.at' "null"
_assert_jq "(4) last_mask.blocks_masked=0 when never masked" \
  "$JSON4" '.last_mask.blocks_masked' "0"

# ---- Case (5): cache disabled (no cache adapter) ----
CASE5="$WORK/case5"
_scaffold "$CASE5" '.tokens.total_input = 30000 | .tokens.cache_hits = 0 | .tokens.cache_writes = 0'
JSON5=$(_call_health_json "$CASE5")
_assert_jq "(5) cache_efficiency.status='n/a' when cache_hits=0 AND cache_writes=0" \
  "$JSON5" '.cache_efficiency.status' "n/a"
_assert_jq "(5) cache_efficiency.hit_rate_pct=null when n/a" \
  "$JSON5" '.cache_efficiency.hit_rate_pct' "null"

# ---- Case (6): terminal without color (NO_COLOR env) ----
# health-json itself emits pure JSON; the test asserts no ANSI escape
# codes leak into the JSON regardless of terminal-color state. This
# pins the "color-agnostic data layer" invariant: only the renderer
# (status.md) consumes tput colors.
CASE6="$WORK/case6"
_scaffold "$CASE6" '.tokens.total_input = 30000'
JSON6=$(NO_COLOR=1 TERM=dumb _call_health_json "$CASE6")
if printf '%s' "$JSON6" | grep -q $'\x1b\['; then
  _fail "(6) health-json output contains ANSI escape codes — color leaked into data layer"
else
  _pass "(6) health-json output is ANSI-clean under NO_COLOR=1 TERM=dumb"
fi
_assert_8_keys "(6) NO_COLOR/dumb terminal still emits all 8 keys" "$JSON6"

# ---- Case (7): alerts populated (gauge crit + circuit-breaker) ----
CASE7="$WORK/case7"
_scaffold "$CASE7" '
  .tokens.total_input = 180000
  | .session.drift_indicators.circuit_breaker_triggers = 1
'
JSON7=$(_call_health_json "$CASE7")
_assert_jq "(7) gauge.status='crit' at 90% of 200K capacity" \
  "$JSON7" '.gauge.status' "crit"
ALERTS7_LEN=$(printf '%s' "$JSON7" | jq -r '.alerts | length')
if [ "$ALERTS7_LEN" -ge 2 ] 2>/dev/null; then
  _pass "(7) alerts has ≥2 items (gauge crit + circuit_breaker_triggers)"
else
  _fail "(7) expected ≥2 alerts, got $ALERTS7_LEN"
fi
# Severity ordering: context_fill_critical comes BEFORE circuit_breaker_active
ALERT7_FIRST=$(printf '%s' "$JSON7" | jq -r '.alerts[0]')
if printf '%s' "$ALERT7_FIRST" | grep -q '^context_fill_critical'; then
  _pass "(7) alerts severity-ordered: context_fill_critical first"
else
  _fail "(7) alerts misordered: first item was '$ALERT7_FIRST', expected context_fill_critical*"
fi

# ---- Case (8): Phase 12 M16 pending — quality_rolling.status='n/a' ----
# Invariant for all R13 outputs; M16 has not landed, so status MUST
# be 'n/a' for every case. Verify on case (1) which had full data.
_assert_jq "(8) quality_rolling.status='n/a' (Phase 12 M16 pending invariant)" \
  "$JSON1" '.quality_rolling.status' "n/a"

# ---- Bonus assertion: schema-shape sanity for the alerts array ----
# Per schema, alerts is an array of strings; verify type on case (1).
ALERTS1_TYPE=$(printf '%s' "$JSON1" | jq -r '.alerts | type')
if [ "$ALERTS1_TYPE" = "array" ]; then
  _pass "(schema-sanity) alerts is an array on full STATE"
else
  _fail "(schema-sanity) alerts type mismatch: $ALERTS1_TYPE"
fi

# ---- Summary ----
echo ""
echo "test-health-metrics.sh: LOCAL_PASS=$LOCAL_PASS LOCAL_FAIL=$LOCAL_FAIL"
echo ""

if [ "${HARNESS_LOADED:-0}" = "1" ] || declare -F harness_assert_local >/dev/null 2>&1; then
  harness_assert_local "$LOCAL_PASS" "$LOCAL_FAIL" "test-health-metrics.sh"
fi

exit "$LOCAL_FAIL"
