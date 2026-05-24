#!/usr/bin/env bash
# Atomic STATE.json update with error handling.
# Source this from any hook that updates .apex/STATE.json.
#
# Usage:
#   _state_update '.field = "value"'                          # simple expression
#   _state_update '.field = "value"' path/to/STATE.json       # custom file
#   _state_update --arg k v --argjson n 5 '.f[$k] = $n'      # with jq args
#   _state_update --arg k v '.f[$k] = $n' path/to/STATE.json # args + custom file

_state_update() {
  local jq_args=()
  local expr=""
  local state_file=".apex/STATE.json"

  # Parse arguments: collect --arg/--argjson pairs, then expr, then optional file
  while [ $# -gt 0 ]; do
    case "$1" in
      --arg|--argjson)
        jq_args+=("$1" "$2" "$3")
        shift 3
        ;;
      *)
        if [ -z "$expr" ]; then
          expr="$1"
        else
          state_file="$1"
        fi
        shift
        ;;
    esac
  done

  if [ -z "$expr" ]; then
    echo "⚠️ _state_update: no jq expression provided" >&2
    return 1
  fi

  local tmp="/tmp/_apex_state_$(date +%s%N).json"
  local err="/tmp/_apex_state_err_$$.txt"
  if jq "${jq_args[@]}" "$expr" "$state_file" > "$tmp" 2>"$err"; then
    mv "$tmp" "$state_file"
    rm -f "$err"
    # Append structured event to event-log.jsonl (fire-and-forget)
    local state_dir
    state_dir=$(dirname "$state_file")
    local safe_expr
    safe_expr=$(printf '%s' "$expr" | tr '"' "'" | tr '\n' ' ')
    local _ts_now
    _ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
    # Campaign B B2.2: tag with schema_version="1" so the AC-2 validator
    # accepts these legacy-shaped direct emits. The state-mutation
    # variant is the highest-frequency event in the log (~83% of
    # entries in live samples) so the schema_version stamp here closes
    # the largest backward-compat gap.
    printf '{"schema_version":"1","ts":"%s","type":"state_mutation","source":"%s","expr":"%s"}\n' \
      "$_ts_now" \
      "${APEX_HOOK_SOURCE:-unknown}" \
      "$safe_expr" >> "${state_dir}/event-log.jsonl" 2>/dev/null || true
    # R6-004: Dual-emit semantic events for canonical-field mutations.
    # Detect the conservative pattern `.<field> = <value>` (with optional
    # whitespace around `=`) and append a matching semantic event so that
    # state-rebuild.sh can reconstruct the canonical fields from the event
    # log without parsing jq expression strings. Pipe-operator updates and
    # conditional jq forms are intentionally not matched (false-positive
    # avoidance per R6-004 risk assessment).
    case "$expr" in
      *.current_phase[\ ]*=*|*.current_phase=*)
        local _phase_val
        _phase_val=$(printf '%s' "$expr" | sed -nE 's/.*\.current_phase[[:space:]]*=[[:space:]]*"([^"]*)".*/\1/p')
        if [ -n "$_phase_val" ]; then
          printf '{"schema_version":"1","ts":"%s","type":"phase_set","source":"%s","current_phase":"%s"}\n' \
            "$_ts_now" "${APEX_HOOK_SOURCE:-unknown}" "$_phase_val" \
            >> "${state_dir}/event-log.jsonl" 2>/dev/null || true
        fi
        ;;
    esac
    case "$expr" in
      *.decision_mode[\ ]*=*|*.decision_mode=*)
        local _mode_val
        _mode_val=$(printf '%s' "$expr" | sed -nE 's/.*\.decision_mode[[:space:]]*=[[:space:]]*"([^"]*)".*/\1/p')
        if [ -n "$_mode_val" ]; then
          printf '{"schema_version":"1","ts":"%s","type":"decision_mode_set","source":"%s","decision_mode":"%s"}\n' \
            "$_ts_now" "${APEX_HOOK_SOURCE:-unknown}" "$_mode_val" \
            >> "${state_dir}/event-log.jsonl" 2>/dev/null || true
        fi
        ;;
    esac
    case "$expr" in
      *.complexity_level[\ ]*=*|*.complexity_level=*)
        local _cl_val
        _cl_val=$(printf '%s' "$expr" | sed -nE 's/.*\.complexity_level[[:space:]]*=[[:space:]]*([0-9]+).*/\1/p')
        if [ -n "$_cl_val" ]; then
          printf '{"schema_version":"1","ts":"%s","type":"complexity_set","source":"%s","complexity_level":%s}\n' \
            "$_ts_now" "${APEX_HOOK_SOURCE:-unknown}" "$_cl_val" \
            >> "${state_dir}/event-log.jsonl" 2>/dev/null || true
        fi
        ;;
    esac
    # R5-002: opt-in SQLite mirror. Fires only when APEX_SQLITE_MIRROR=1.
    # Never blocks the canonical write; fail-loud-and-skip on missing CLI.
    if [ "${APEX_SQLITE_MIRROR:-}" = "1" ]; then
      local _apex_sqlite_hook
      _apex_sqlite_hook="$(dirname "${BASH_SOURCE[0]}")/_state-sqlite.sh"
      if [ -f "$_apex_sqlite_hook" ]; then
        # shellcheck disable=SC1090
        source "$_apex_sqlite_hook"
        _state_sqlite_mirror "$state_file" "${state_dir}/event-log.jsonl" || true
      fi
    fi
  else
    rm -f "$tmp"
    local jq_msg
    jq_msg=$(cat "$err" 2>/dev/null)
    rm -f "$err"
    echo "⚠️ STATE update failed: $expr${jq_msg:+ — $jq_msg}" >&2
    return 1
  fi
}

# v7.1 Auto-Continuity Layer — emit a semantic event to .apex/event-log.jsonl
# with arbitrary flat string key/value fields. Used by new hooks (memory-watchdog,
# turn-checkpoint, session-auto-resume) for event types that don't fit the
# canonical .field = "value" dual-emit pattern. Fire-and-forget, never blocks.
#
# Known event types (v7.1):
#   memory_sample              — periodic Bun memory telemetry
#   auto_pause_requested       — memory-watchdog requested a pause
#   external_shutdown_requested — apex-watchdog.ps1 requested a shutdown
#   turn_checkpoint_set        — turn-checkpoint.sh wrote TURN_CHECKPOINT.json
#   session_auto_resumed       — session-auto-resume.sh detected auto-paused boot
#
# Usage:
#   _emit_apex_event <event_type> [<state_dir>] [<key1> <val1> [<key2> <val2> ...]]
#   state_dir defaults to .apex; pass "" to use the default while supplying key/values.
#
# Example:
#   _emit_apex_event memory_sample .apex rss_mb 412 commit_mb 1834
# R16-616 (F-616, IMP-016): _record_denied_error pushes a denied-class
# PostToolUse error event into STATE.recent_denied_error_window (FIFO, max 5).
# Pairs with sequence-guard.sh which reads the window in PreToolUse and tightens
# the deny pattern set for the next 5 calls.
#
# Usage:
#   _record_denied_error <category> [<tool>]
#     category ∈ unauthorized | forbidden | 403 | 401 | denied | missing_token
#     tool     optional tool name string
#
# Fire-and-forget; failures are silent (we never block the post-tool path).
# R16-610 (F-610, IMP-005): _record_tool_failure increments
# STATE.tool_failure_count whenever a PostToolUse event reports
# `is_error=true`. Read by exfil-guard.sh in PreToolUse — when the counter
# reaches the IMP-005 threshold (>=5), the hook activates an elevated deny
# set targeting DNS-based exfil, non-standard ports, base64-looking
# filenames, and side-channel /tmp/<encoded> writes.
#
# Usage:
#   _record_tool_failure
#
# Fire-and-forget; failures are silent (we never block the post-tool path).
_record_tool_failure() {
  _state_update \
    '.tool_failure_count = ((.tool_failure_count // 0) + 1)' \
    2>/dev/null || true
}

_record_denied_error() {
  local category="${1:-}"
  local tool="${2:-unknown}"
  if [ -z "$category" ]; then
    return 0
  fi
  # Normalize category to the schema enum
  case "$category" in
    unauthorized|forbidden|403|401|denied|missing_token) ;;
    *) return 0 ;;
  esac
  local _ts_now
  _ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
  # Append the new entry; trim to the last 5 so the array stays bounded.
  _state_update \
    --arg ts "$_ts_now" \
    --arg cat "$category" \
    --arg tool "$tool" \
    '.recent_denied_error_window = ((.recent_denied_error_window // []) + [{ts:$ts, category:$cat, tool:$tool}] | .[-5:])' \
    2>/dev/null || true
}

_emit_apex_event() {
  if ! command -v jq >/dev/null 2>&1; then
    return 0
  fi
  local event_type="$1"
  local state_dir="${2:-.apex}"
  [ -z "$state_dir" ] && state_dir=".apex"
  shift 2 2>/dev/null || shift $#
  local _ts_now
  _ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
  local source="${APEX_HOOK_SOURCE:-unknown}"
  # Campaign B B2.2 (closes AC-2): every newly-emitted entry carries
  # schema_version="1". Legacy entries already on disk lack this field —
  # the schema accepts them as v0 with a flag.
  local jq_args=(--arg sv "1" --arg ts "$_ts_now" --arg type "$event_type" --arg src "$source")
  local filter='{schema_version:$sv,ts:$ts,type:$type,source:$src}'
  while [ $# -ge 2 ]; do
    local k="$1" v="$2"
    # Sanitize jq variable name — only allow alphanumeric and underscore
    local safe_k
    safe_k=$(printf '%s' "$k" | tr -c 'A-Za-z0-9_' '_')
    jq_args+=(--arg "v_${safe_k}" "$v")
    filter="${filter} + {\"${k}\":\$v_${safe_k}}"
    shift 2
  done
  local line
  line=$(jq -c -n "${jq_args[@]}" "$filter" 2>/dev/null) || true
  if [ -z "$line" ]; then
    return 0
  fi
  # Campaign B B2.2 — validate-before-append. The validator is a
  # lightweight jq pass that checks the binding minimum (per
  # audit-trail-review/EXPERIMENT-PROTOCOL.md §5.2):
  #   * schema_version, ts, type, source all present and non-empty
  #   * type is in the v1 enum
  # Full JSON Schema validation requires an external validator (ajv) we
  # cannot assume; the jq pass catches the failures the campaign cares
  # about. Malformed entries route to .apex/event-log-rejected.jsonl —
  # never silently dropped. One stderr warning per rejection; never
  # block the producer.
  if _apex_validate_event_line "$line"; then
    printf '%s\n' "$line" >> "${state_dir}/event-log.jsonl" 2>/dev/null || true
  else
    local reason
    reason=$(_apex_validate_event_line_reason "$line")
    # Re-emit the original line with a rejection_reason field attached.
    jq -c --arg r "$reason" '. + {rejection_reason:$r}' <<< "$line" \
      >> "${state_dir}/event-log-rejected.jsonl" 2>/dev/null \
      || printf '%s\n' "$line" >> "${state_dir}/event-log-rejected.jsonl" 2>/dev/null || true
    echo "[_emit_apex_event] rejected (${reason}): $(printf '%s' "$line" | cut -c1-120)" >&2
  fi
}

# B2.2 validator helpers. Return 0 on valid, non-zero on invalid. Tied
# to schema enum in framework/schemas/EVENT-LOG-ENTRY.schema.json.
#
# The enum is broad-by-design: every type observed in the live
# framework today is accepted, plus Campaign B's additions
# (subagent_*, pre_task_claim*, tool_input_hash, log_rotated). Unknown
# types route to event-log-rejected.jsonl per §5.4 — but the cost of
# being too STRICT is silently lost events, which is worse than being
# permissive. Adding a new type = minor schema bump per §5.5.
_APEX_EVENT_TYPE_ENUM='tool_call tool_input_hash state_mutation phase_set decision_mode_set complexity_set subagent_start subagent_stop subagent_count_mismatch transcript_imported pre_task_claim pre_task_claim_diff memory_sample turn_checkpoint_set session_event session_auto_resumed auto_pause_requested external_shutdown_requested step_start self_heal_round_start self_heal_round_close self_heal_round_closed self_heal_step self_heal_step_done self_heal_wave self_heal_wave_done self_heal_closed self_heal_loop_close self_heal_loop_closed self_heal wave_done dora.collected dora.ship_delta rotation.decide.evaluated rotation.trigger.unknown log_rotated observation.mask.bypassed observation.mask.api_fallback observation.mask.fallback observation.mask.fired observation.mask.stub cognitive_debt.skip quality.baseline.frozen quality.baseline.rebaseline quality_drift snapshot.ok tokens_update module'

_apex_validate_event_line() {
  local line="$1"
  command -v jq >/dev/null 2>&1 || return 0  # validator no-op without jq
  local type src ts sv
  sv=$(printf '%s' "$line"   | jq -r '.schema_version // empty' 2>/dev/null)
  ts=$(printf '%s' "$line"   | jq -r '.ts // empty'             2>/dev/null)
  type=$(printf '%s' "$line" | jq -r '.type // empty'           2>/dev/null)
  src=$(printf '%s' "$line"  | jq -r '.source // empty'         2>/dev/null)
  [ -z "$sv" ]   && return 1
  [ -z "$ts" ]   && return 1
  [ -z "$type" ] && return 1
  [ -z "$src" ]  && return 1
  echo " $_APEX_EVENT_TYPE_ENUM " | grep -q " $type " || return 1
  return 0
}

_apex_validate_event_line_reason() {
  local line="$1"
  command -v jq >/dev/null 2>&1 || { echo "no_jq"; return 0; }
  local type src ts sv
  sv=$(printf '%s' "$line"   | jq -r '.schema_version // empty' 2>/dev/null)
  ts=$(printf '%s' "$line"   | jq -r '.ts // empty'             2>/dev/null)
  type=$(printf '%s' "$line" | jq -r '.type // empty'           2>/dev/null)
  src=$(printf '%s' "$line"  | jq -r '.source // empty'         2>/dev/null)
  [ -z "$sv" ]   && { echo "missing_schema_version"; return 0; }
  [ -z "$ts" ]   && { echo "missing_ts"; return 0; }
  [ -z "$type" ] && { echo "missing_type"; return 0; }
  [ -z "$src" ]  && { echo "missing_source"; return 0; }
  echo " $_APEX_EVENT_TYPE_ENUM " | grep -q " $type " || { echo "unknown_type:$type"; return 0; }
  echo "valid"
}
