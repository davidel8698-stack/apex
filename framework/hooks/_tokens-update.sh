#!/usr/bin/env bash
# Hook type: library (not auto-wired; sourced by subagent-stop.sh)
#
# R12-001 (F-201): Real token-counter library.
#
# Exposes `apex_tokens_update <agent> <in> <out> [cache_r] [cache_c]` which
# atomically increments `.tokens.*` fields in `.apex/STATE.json` using the
# rename-temp atomic-write pattern established in `_state-update.sh`. The
# library is intentionally parallel to `_state-update.sh` rather than a
# wrapper: `_state-update.sh` owns the canonical state-mutation interface
# (with semantic-event dual-emit); this library owns the narrow token-
# accumulation contract that runs on every SubagentStop event.
#
# Spec anchors:
#   "Honest scope over marketing scope."
#   "Configuration declarative = theatre until code consumes it."
#   "State derives from disk."
#   "Fail-loud, never fail-silent."
#
# Cross-platform contract (Windows + bash):
#   - MUST NOT use `flock` (does not exist on Windows / OneDrive). The
#     rename-temp pattern is the only atomicity primitive used here.
#   - jq reads use `// 0` defaults so adapters that omit cache_* fields
#     do not break the parser.
#
# Idempotent: safe to call concurrently with `_state-update.sh` (both use
# rename-temp on disjoint key paths; final state is order-independent
# for monotonic-increment ops).

# apex_tokens_update <agent> <in> <out> [cache_r] [cache_c] [state_file]
#
# Args:
#   $1 — agent name (e.g., "architect", "executor")
#   $2 — input tokens (integer, default 0 if empty)
#   $3 — output tokens (integer, default 0 if empty)
#   $4 — cache_read_input_tokens (integer, default 0)
#   $5 — cache_creation_input_tokens (integer, default 0)
#   $6 — optional path to STATE.json (default `.apex/STATE.json`)
apex_tokens_update() {
  local agent="${1:-unknown}"
  local in="${2:-0}"
  local out="${3:-0}"
  local cache_r="${4:-0}"
  local cache_c="${5:-0}"
  local state_file="${6:-.apex/STATE.json}"

  # Default any blank arguments to 0 (graceful when adapter omits fields).
  [ -z "$in" ] && in=0
  [ -z "$out" ] && out=0
  [ -z "$cache_r" ] && cache_r=0
  [ -z "$cache_c" ] && cache_c=0

  if ! command -v jq >/dev/null 2>&1; then
    echo "⚠️ apex_tokens_update: jq not available; skipping token update" >&2
    return 0
  fi

  if [ ! -f "$state_file" ]; then
    # No state yet (fresh session pre-/apex:start) — no-op, not an error.
    return 0
  fi

  # Read current phase / unit for per-phase / per-task buckets. `// "_unknown"`
  # gives a stable bucket name when STATE has no active phase/task yet.
  local current_phase current_unit
  current_phase=$(jq -r '.current_phase // "_unknown"' "$state_file" 2>/dev/null | tr -d '\r')
  current_unit=$(jq -r '.current_unit // "_unknown"' "$state_file" 2>/dev/null | tr -d '\r')
  [ -z "$current_phase" ] && current_phase="_unknown"
  [ -z "$current_unit" ] && current_unit="_unknown"

  # Session baseline: set on first call only (do not overwrite on subsequent
  # invocations). Captures pre-invocation total_input+total_output so the
  # dashboard can distinguish "this session" from "project lifetime" deltas.
  local has_baseline
  has_baseline=$(jq -r '.tokens.session_start_at // ""' "$state_file" 2>/dev/null | tr -d '\r')
  local ts_now
  ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"

  # Rename-temp atomic-write pattern (verbatim port from _state-update.sh).
  local tmp="/tmp/_apex_tokens_$$_$(date +%s%N 2>/dev/null || date +%s).json"
  local err="/tmp/_apex_tokens_err_$$.txt"

  # Build jq expression: increment scalars, ensure by_agent/by_phase/by_task
  # buckets exist before incrementing nested counters.
  local jq_expr='
    .tokens.total_input = ((.tokens.total_input // 0) + ($in | tonumber))
    | .tokens.total_output = ((.tokens.total_output // 0) + ($out | tonumber))
    | .tokens.cache_hits = ((.tokens.cache_hits // 0) + (if ($cache_r | tonumber) > 0 then 1 else 0 end))
    | .tokens.cache_writes = ((.tokens.cache_writes // 0) + (if ($cache_c | tonumber) > 0 then 1 else 0 end))
    | .tokens.by_agent[$agent] = ((.tokens.by_agent[$agent] // {"calls":0,"tokens":0}))
    | .tokens.by_agent[$agent].calls = ((.tokens.by_agent[$agent].calls // 0) + 1)
    | .tokens.by_agent[$agent].tokens = ((.tokens.by_agent[$agent].tokens // 0) + ($in | tonumber) + ($out | tonumber))
    | .tokens.by_phase[$phase] = ((.tokens.by_phase[$phase] // {"calls":0,"tokens":0}))
    | .tokens.by_phase[$phase].tokens = ((.tokens.by_phase[$phase].tokens // 0) + ($in | tonumber) + ($out | tonumber))
    | .tokens.by_task[$unit] = ((.tokens.by_task[$unit] // {"calls":0,"tokens":0}))
    | .tokens.by_task[$unit].tokens = ((.tokens.by_task[$unit].tokens // 0) + ($in | tonumber) + ($out | tonumber))
  '
  if [ -z "$has_baseline" ]; then
    # First call of session — set session_start_at + session_baseline_total.
    jq_expr="$jq_expr
    | .tokens.session_start_at = \$ts
    | .tokens.session_baseline_total = ((.tokens.total_input // 0) + (.tokens.total_output // 0) - ((\$in | tonumber) + (\$out | tonumber)))
    "
  fi

  if jq \
      --arg agent "$agent" \
      --arg in "$in" \
      --arg out "$out" \
      --arg cache_r "$cache_r" \
      --arg cache_c "$cache_c" \
      --arg phase "$current_phase" \
      --arg unit "$current_unit" \
      --arg ts "$ts_now" \
      "$jq_expr" "$state_file" > "$tmp" 2>"$err"; then
    mv "$tmp" "$state_file"
    rm -f "$err"
    # Fire-and-forget event-log line for traceability.
    local state_dir
    state_dir=$(dirname "$state_file")
    printf '{"ts":"%s","type":"tokens_update","source":"%s","agent":"%s","in":%s,"out":%s,"cache_r":%s,"cache_c":%s}\n' \
      "$ts_now" \
      "${APEX_HOOK_SOURCE:-_tokens-update}" \
      "$agent" "$in" "$out" "$cache_r" "$cache_c" \
      >> "${state_dir}/event-log.jsonl" 2>/dev/null || true
    return 0
  else
    rm -f "$tmp"
    local jq_msg
    jq_msg=$(cat "$err" 2>/dev/null)
    rm -f "$err"
    echo "⚠️ apex_tokens_update failed for agent=$agent${jq_msg:+ — $jq_msg}" >&2
    return 1
  fi
}
