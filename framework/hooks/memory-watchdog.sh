#!/bin/bash
# memory-watchdog.sh — Auto-Continuity Layer C (v7.1).
# Samples in-process Bun/Claude Code memory and signals an auto-pause request
# *before* OOM rather than discovering it after the runtime has died.
#
# Wired as: PostToolUse hook on Bash (every bash tool call) — see settings.json.
# Throttled internally by memory_sample_interval_seconds (default 30s) so it
# does not run on every single tool call.
#
# Contract:
#   • exit 0 always — never blocks tool execution
#   • fail-loud-and-skip — one stderr line on platform issues, then continue
#   • side effects:
#       - .apex/STATE.json: updates session.memory.* (sample_at, rss, commit, …)
#       - .apex/event-log.jsonl: appends one memory_sample event per real sample
#       - .apex/AUTO_PAUSE_REQUEST.flag: created when consecutive_over_threshold
#                                       reaches bun_memory_debounce_samples
#
# Triggered auto-pause is *consumed* by /apex:next Step F.4 (see plan §1).
# This hook never invokes /apex:pause itself — it only requests it.

set -u

# Plumbing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_require-jq.sh"
require_jq
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_state-update.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_require-platform-detect.sh"

export APEX_HOOK_SOURCE="memory-watchdog"

STATE_FILE=".apex/STATE.json"
BUDGET_FILE=".apex/CONTEXT_BUDGET.json"
FRAMEWORK_BUDGET_FILE="$HOME/.claude/CONTEXT_BUDGET.default.json"
PAUSE_FLAG=".apex/AUTO_PAUSE_REQUEST.flag"

# Fail-soft when no APEX project here (missing STATE.json = fresh / non-APEX cwd).
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# --- Read thresholds (CONTEXT_BUDGET.json overrides framework default) ---
read_threshold() {
  local key="$1" default_val="$2"
  local val=""
  if [ -f "$BUDGET_FILE" ]; then
    val=$(jq -r ".auto_continuity.${key} // empty" "$BUDGET_FILE" 2>/dev/null)
  fi
  if [ -z "$val" ] && [ -f "$FRAMEWORK_BUDGET_FILE" ]; then
    val=$(jq -r ".auto_continuity.${key} // empty" "$FRAMEWORK_BUDGET_FILE" 2>/dev/null)
  fi
  if [ -z "$val" ]; then val="$default_val"; fi
  printf '%s' "$val"
}

THRESHOLD_MB=$(read_threshold bun_memory_threshold_mb 2048)
WARN_PCT=$(read_threshold bun_memory_warn_pct 70)
DEBOUNCE_SAMPLES=$(read_threshold bun_memory_debounce_samples 3)
SAMPLE_INTERVAL=$(read_threshold memory_sample_interval_seconds 30)

# --- Throttle: skip if we sampled recently ---
LAST_SAMPLE_AT=$(jq -r '.session.memory.last_sample_at // empty' "$STATE_FILE" 2>/dev/null)
NOW_EPOCH=$(date +%s 2>/dev/null || echo 0)
if [ -n "$LAST_SAMPLE_AT" ] && [ "$LAST_SAMPLE_AT" != "null" ]; then
  # Convert ISO-8601 → epoch (best-effort cross-platform)
  LAST_EPOCH=$(date -d "$LAST_SAMPLE_AT" +%s 2>/dev/null || \
               python -c "import sys,datetime;print(int(datetime.datetime.strptime(sys.argv[1].rstrip('Z'),'%Y-%m-%dT%H:%M:%S').timestamp()))" "$LAST_SAMPLE_AT" 2>/dev/null || \
               echo 0)
  if [ "$LAST_EPOCH" -gt 0 ] && [ "$NOW_EPOCH" -gt 0 ]; then
    ELAPSED=$((NOW_EPOCH - LAST_EPOCH))
    if [ "$ELAPSED" -lt "$SAMPLE_INTERVAL" ]; then
      exit 0
    fi
  fi
fi

# --- Sample memory ---
SAMPLE=$(sample_bun_memory_mb)
RSS_MB=$(printf '%s' "$SAMPLE" | awk '{print $1}')
COMMIT_MB=$(printf '%s' "$SAMPLE" | awk '{print $2}')
RSS_MB=${RSS_MB:-0}
COMMIT_MB=${COMMIT_MB:-0}

# Compute percentage of threshold (commit_mb is the OOM-relevant metric)
if [ "$THRESHOLD_MB" -gt 0 ] 2>/dev/null; then
  WORKING_SET_PCT=$((COMMIT_MB * 100 / THRESHOLD_MB))
else
  WORKING_SET_PCT=0
fi
[ "$WORKING_SET_PCT" -gt 100 ] 2>/dev/null && WORKING_SET_PCT=100

# --- Read prior counters ---
PRIOR_HWM=$(jq -r '.session.memory.high_water_mark_mb // 0' "$STATE_FILE" 2>/dev/null)
PRIOR_HWM=${PRIOR_HWM:-0}
NEW_HWM=$PRIOR_HWM
[ "$COMMIT_MB" -gt "$PRIOR_HWM" ] 2>/dev/null && NEW_HWM=$COMMIT_MB

PRIOR_OVER=$(jq -r '.session.memory.consecutive_over_threshold // 0' "$STATE_FILE" 2>/dev/null)
PRIOR_OVER=${PRIOR_OVER:-0}
if [ "$COMMIT_MB" -ge "$THRESHOLD_MB" ] 2>/dev/null; then
  NEW_OVER=$((PRIOR_OVER + 1))
else
  NEW_OVER=0
fi

PRIOR_SAMPLES=$(jq -r '.session.memory.samples_taken // 0' "$STATE_FILE" 2>/dev/null)
PRIOR_SAMPLES=${PRIOR_SAMPLES:-0}
NEW_SAMPLES=$((PRIOR_SAMPLES + 1))

NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)

# --- Persist sample to STATE.json (single atomic update) ---
_state_update \
  --arg ts "$NOW_ISO" \
  --argjson rss "$RSS_MB" \
  --argjson commit "$COMMIT_MB" \
  --argjson pct "$WORKING_SET_PCT" \
  --argjson hwm "$NEW_HWM" \
  --argjson over "$NEW_OVER" \
  --argjson samples "$NEW_SAMPLES" \
  '.session.memory = {
    last_sample_at: $ts,
    rss_mb: $rss,
    commit_mb: $commit,
    working_set_pct: $pct,
    samples_taken: $samples,
    high_water_mark_mb: $hwm,
    consecutive_over_threshold: $over
  }' "$STATE_FILE"

# --- Emit semantic memory_sample event (for forensics & external watchdog) ---
_emit_apex_event memory_sample .apex \
  rss_mb "$RSS_MB" \
  commit_mb "$COMMIT_MB" \
  threshold_mb "$THRESHOLD_MB" \
  working_set_pct "$WORKING_SET_PCT" \
  consecutive_over "$NEW_OVER"

# --- Decision: do we request an auto-pause? ---
# Only fires if:
#   1. consecutive_over_threshold >= debounce_samples AND
#   2. AUTO_PAUSE_REQUEST.flag does not already exist (don't double-write)
if [ "$NEW_OVER" -ge "$DEBOUNCE_SAMPLES" ] 2>/dev/null && [ ! -f "$PAUSE_FLAG" ]; then
  cat > "$PAUSE_FLAG" <<EOF
REASON: memory_pressure
SOURCE: memory-watchdog
TS: $NOW_ISO
COMMIT_MB: $COMMIT_MB
THRESHOLD_MB: $THRESHOLD_MB
CONSECUTIVE_OVER: $NEW_OVER
NOTE: Bun runtime memory has been over the threshold for $NEW_OVER consecutive samples.
      /apex:next Step F.4 will consume this flag and run /apex:pause.
EOF
  _emit_apex_event auto_pause_requested .apex \
    reason "memory_pressure" \
    commit_mb "$COMMIT_MB" \
    threshold_mb "$THRESHOLD_MB" \
    consecutive_over "$NEW_OVER"
  echo "🛑 [memory-watchdog] Bun memory at ${COMMIT_MB}MB (threshold ${THRESHOLD_MB}MB, ${NEW_OVER} samples). Auto-pause requested." >&2
elif [ "$WORKING_SET_PCT" -ge "$WARN_PCT" ] 2>/dev/null; then
  # Warn-level: don't block, just notify
  echo "⚠️ [memory-watchdog] Bun memory at ${COMMIT_MB}MB (~${WORKING_SET_PCT}% of ${THRESHOLD_MB}MB). Auto-pause will trigger after ${DEBOUNCE_SAMPLES} consecutive samples over threshold." >&2
fi

exit 0
