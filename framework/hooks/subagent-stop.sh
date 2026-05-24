#!/bin/bash
set -u
source "$(dirname "$0")/_require-jq.sh"
require_jq
# R12-001 (F-201): wire real token counter on every SubagentStop event.
# The library is parallel to _state-update.sh; do NOT replace _state-update.sh
# (canonical state-mutation interface — preserved as-is per do-not-touch zone).
# shellcheck disable=SC1091
source "$(dirname "$0")/_tokens-update.sh"

# Campaign B B2.1: source the central event-emitter for subagent_stop +
# transcript_imported boundary events. Sourced (not invoked) per the
# library convention; idempotent guard protects double-source.
# shellcheck disable=SC1091
source "$(dirname "$0")/_state-update.sh"

export APEX_HOOK_SOURCE="${APEX_HOOK_SOURCE:-subagent-stop}"

INPUT=$(cat)
AGENT=$(echo "$INPUT" | jq -r '.agent_name // empty')
AGENT_ID_ENV=$(echo "$INPUT" | jq -r '.agent_id // empty' 2>/dev/null | tr -d '\r')
ROUND_TAG_ENV=$(echo "$INPUT" | jq -r '.round_tag // empty' 2>/dev/null | tr -d '\r')

# R12-001 (F-201): extract usage.* fields from the SubagentStop payload and
# accumulate into STATE.tokens.* via apex_tokens_update. Every field defaults
# to 0 via jq `// 0` so older adapters that omit cache_* are graceful.
# Fail-soft: do not block hook on token-update error (the library logs and
# returns; subagent-stop's hallucination-guard MUST still run).
if [ -n "$AGENT" ]; then
  USAGE_IN=$(echo "$INPUT" | jq -r '.usage.input_tokens // 0' 2>/dev/null | tr -d '\r')
  USAGE_OUT=$(echo "$INPUT" | jq -r '.usage.output_tokens // 0' 2>/dev/null | tr -d '\r')
  USAGE_CACHE_R=$(echo "$INPUT" | jq -r '.usage.cache_read_input_tokens // 0' 2>/dev/null | tr -d '\r')
  USAGE_CACHE_C=$(echo "$INPUT" | jq -r '.usage.cache_creation_input_tokens // 0' 2>/dev/null | tr -d '\r')
  apex_tokens_update "$AGENT" "${USAGE_IN:-0}" "${USAGE_OUT:-0}" "${USAGE_CACHE_R:-0}" "${USAGE_CACHE_C:-0}" || true
fi

# M16 (Phase 12.09): append per-task quality signal to
# STATE.quality.rolling_window_tasks on verifier/critic return.
# Safe-or-noop on any read failure — never blocks the hook pipeline.
#
# Contract:
#   - Fires only when AGENT is `verifier` or `critic` (verification return).
#   - Reads .apex/phases/<current_phase>/<current_unit>-RESULT.json.
#   - Maps RESULT.json `confidence` → numeric (high=1.0, medium=0.5, low=0.0).
#   - Appends {task_id, confidence_score, verifier_pass, attempts} to
#     STATE.quality.rolling_window_tasks (FIFO, cap 10).
#   - Increments STATE.quality.tasks_since_rebaseline.
#   - Atomic write via rename-temp; jq absence → silent skip.
#
# Three-place contract: schema in STATE.schema.json, init in
# STATE-init.template.json + start.md, writer here. quality-drift.sh
# consumes the window.
APEX_QUALITY_AGENTS="verifier critic"
if [ -n "$AGENT" ] && echo "$APEX_QUALITY_AGENTS" | grep -qw "$AGENT"; then
  if command -v jq >/dev/null 2>&1 && [ -f .apex/STATE.json ]; then
    Q_PHASE=$(jq -r '.current_phase // ""' .apex/STATE.json 2>/dev/null | tr -d '\r')
    Q_UNIT=$(jq -r '.current_unit // ""' .apex/STATE.json 2>/dev/null | tr -d '\r')
    if [ -n "$Q_PHASE" ] && [ -n "$Q_UNIT" ]; then
      Q_RESULT=".apex/phases/${Q_PHASE}/${Q_UNIT}-RESULT.json"
      if [ -f "$Q_RESULT" ]; then
        Q_CONF=$(jq -r '.confidence // "medium"' "$Q_RESULT" 2>/dev/null | tr -d '\r')
        Q_STATUS=$(jq -r '.status // "unknown"' "$Q_RESULT" 2>/dev/null | tr -d '\r')
        Q_ATTEMPTS=$(jq -r '(.attempt_number // 1)' "$Q_RESULT" 2>/dev/null | tr -d '\r')
        # Map confidence → numeric (PLAN task 12.09 §10 non-obvious insight #1).
        case "$Q_CONF" in
          high)   Q_SCORE="1.0" ;;
          medium) Q_SCORE="0.5" ;;
          low)    Q_SCORE="0.0" ;;
          *)      Q_SCORE="0.5" ;;
        esac
        # verifier_pass = true when status == "success" or "pass"; else false.
        case "$Q_STATUS" in
          success|pass) Q_PASS="true" ;;
          *)            Q_PASS="false" ;;
        esac
        [ -z "$Q_ATTEMPTS" ] && Q_ATTEMPTS=1
        # Atomic append via rename-temp. Cap rolling_window at 10 (FIFO).
        Q_TMP=".apex/STATE.json.qappend.tmp"
        if jq \
            --arg task_id "$Q_UNIT" \
            --argjson score "$Q_SCORE" \
            --argjson pass "$Q_PASS" \
            --argjson attempts "$Q_ATTEMPTS" \
            '
            .quality = (.quality // {rolling_window_tasks: [], baseline_window_tasks: [], current_drift_pct: 0, alert_threshold_pct: 5, baselined_at_phase: null, tasks_since_rebaseline: 0})
            | .quality.rolling_window_tasks = ((.quality.rolling_window_tasks // []) + [{task_id: $task_id, confidence_score: $score, verifier_pass: $pass, attempts: $attempts}])
            | .quality.rolling_window_tasks = (.quality.rolling_window_tasks | if length > 10 then .[length-10:] else . end)
            | .quality.tasks_since_rebaseline = ((.quality.tasks_since_rebaseline // 0) + 1)
            ' .apex/STATE.json > "$Q_TMP" 2>/dev/null; then
          mv "$Q_TMP" .apex/STATE.json
        else
          rm -f "$Q_TMP"
        fi
      fi
    fi
  fi
fi

EXECUTOR_AGENTS="executor integration-specialist security-specialist data-specialist frontend-specialist"

if echo "$EXECUTOR_AGENTS" | grep -qw "$AGENT"; then
  TOOL_CALLS=$(echo "$INPUT" | jq -r '.tool_calls_count // 0')

  if [ "$TOOL_CALLS" -eq 0 ]; then
    echo "❌ APEX GUARD: $AGENT completed with 0 tool calls — hallucination"
    exit 2
  fi

  # Capture stderr and exit code separately so we can distinguish:
  #   exit 2 = git works, zero changes → real hallucination suspicion
  #   exit 1 = git error → advisory, cannot verify (NOT a hallucination verdict)
  #   exit 0 = git works, changes present → validated
  DIFF=$(git diff HEAD --stat 2>&1)
  GIT_EXIT=$?

  if [ $GIT_EXIT -ne 0 ]; then
    echo "⚠️ APEX GUARD: git error after $AGENT — cannot verify agent activity" >&2
    echo "   git exit code: $GIT_EXIT" >&2
    echo "   git stderr: $DIFF" >&2
    exit 1
  fi

  if [ -z "$DIFF" ]; then
    echo "❌ APEX GUARD: No git changes after $AGENT — possible hallucination"
    exit 2
  fi

  echo "✅ APEX: $AGENT validated ($TOOL_CALLS tool calls, diff non-empty)"
fi

# ---------------------------------------------------------------------
# Campaign B B2.1 — GAP-1 closure: emit subagent_stop boundary event and
# denormalise the matching agent_id's tool_call events into
# .apex/subagent-transcripts/<agent_name>-<round_tag>-<sha1_8>.jsonl so
# downstream consumers (round-checker TP-2, critic STEPs 1.6/1.7,
# verifier TP-3) can cross-reference claims to actual tool calls.
#
# Spec anchor: audit-trail-review/EXPERIMENT-PROTOCOL.md §6.1 + §6.2.
# Closes AC-1 (hard-FAIL per §12.2). Companion to pre-subagent-start.sh.
# ---------------------------------------------------------------------
if [ -n "$AGENT" ]; then
  REG=".apex/in-flight-subagents.jsonl"
  # Resolve the agent_id for this stop event. Preference order:
  #   1. envelope's own .agent_id (provided when Claude Code surfaces it)
  #   2. most-recent in_flight registry entry whose .agent_name matches
  RESOLVED_ID="$AGENT_ID_ENV"
  RESOLVED_ROUND="$ROUND_TAG_ENV"
  if [ -z "$RESOLVED_ID" ] && [ -f "$REG" ]; then
    REG_LINE=$(awk -v want="$AGENT" '
      {
        if (match($0, /"agent_name":"[^"]+"/) > 0) {
          name = substr($0, RSTART+14, RLENGTH-15)
          if (name == want && index($0, "\"status\":\"in_flight\"") > 0) last = $0
        }
      }
      END { if (last != "") print last }
    ' "$REG" 2>/dev/null)
    if [ -n "$REG_LINE" ]; then
      RESOLVED_ID=$(echo "$REG_LINE" | jq -r '.agent_id // empty' 2>/dev/null | tr -d '\r')
      [ -z "$RESOLVED_ROUND" ] && RESOLVED_ROUND=$(echo "$REG_LINE" | jq -r '.round_tag // empty' 2>/dev/null | tr -d '\r')
    fi
  fi

  if [ -n "$RESOLVED_ID" ]; then
    # Best-effort registry close — flip the most-recent in_flight line
    # for this agent_id to status=stopped. Atomic via tmp+mv.
    if [ -f "$REG" ]; then
      TMP_REG="${REG}.tmp.$$"
      jq -c --arg id "$RESOLVED_ID" '
        if .agent_id == $id and .status == "in_flight"
        then .status = "stopped" | .stopped_at = (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
        else . end' "$REG" > "$TMP_REG" 2>/dev/null \
          && mv "$TMP_REG" "$REG" \
          || rm -f "$TMP_REG"
    fi

    # Filename suffix = last 8 chars of agent_id (the sha1 prefix
    # synthesised by pre-subagent-start.sh).
    SUFFIX=$(printf '%s' "$RESOLVED_ID" | awk -F- '{print $NF}')
    [ -z "$RESOLVED_ROUND" ] && RESOLVED_ROUND="NOROUND-$(date -u +%s 2>/dev/null || echo 0)"
    RESOLVED_ROUND_SAN=$(printf '%s' "$RESOLVED_ROUND" | tr -c 'A-Za-z0-9._-' '_' | head -c 64)
    AGENT_SAN=$(printf '%s' "$AGENT" | tr -c 'A-Za-z0-9._-' '_' | head -c 64)
    OUT_FILE=".apex/subagent-transcripts/${AGENT_SAN}-${RESOLVED_ROUND_SAN}-${SUFFIX}.jsonl"

    mkdir -p .apex/subagent-transcripts 2>/dev/null || true

    # Denormalise: every event-log line with matching .agent_id between
    # this agent's subagent_start and (this) subagent_stop boundaries.
    # Implementation: scan event-log.jsonl from the most-recent
    # subagent_start of this agent_id; emit every event with agent_id ==
    # RESOLVED_ID, terminate at the next subagent_stop (which is THIS
    # emission — so the boundary marker also lands in the transcript).
    #
    # The transcript file is OVERWRITTEN per stop event so a re-emitted
    # stop (rare) doesn't double the content.
    if [ -f .apex/event-log.jsonl ]; then
      START_LINE=$(grep -n '"type":"subagent_start"' .apex/event-log.jsonl 2>/dev/null \
        | awk -F: -v id="$RESOLVED_ID" '
            { rest = substr($0, index($0, ":")+1)
              if (index(rest, "\"agent_id\":\"" id "\"") > 0) lastline = $1 }
            END { if (lastline != "") print lastline }')
      if [ -n "$START_LINE" ]; then
        TAIL_FROM=$((START_LINE))
        sed -n "${TAIL_FROM},\$p" .apex/event-log.jsonl 2>/dev/null \
          | jq -c --arg id "$RESOLVED_ID" 'select(.agent_id == $id)' 2>/dev/null \
          > "$OUT_FILE" 2>/dev/null || true
      fi
    fi
    # Always create the file (even empty) so the AC-1 acceptance test
    # has a concrete artifact to assert against. Empty transcript →
    # caught by the B2.6 count guard if the envelope claimed tool calls.
    [ ! -f "$OUT_FILE" ] && : > "$OUT_FILE"

    # Emit boundary + transcript_imported events.
    TC_COUNT_OBS=$(wc -l < "$OUT_FILE" 2>/dev/null | tr -d ' ')
    [ -z "$TC_COUNT_OBS" ] && TC_COUNT_OBS=0
    TC_CLAIMED=$(echo "$INPUT" | jq -r '.tool_calls_count // 0' 2>/dev/null | tr -d '\r')
    [ -z "$TC_CLAIMED" ] && TC_CLAIMED=0

    _emit_apex_event "subagent_stop" .apex \
      agent_name "$AGENT" \
      agent_id "$RESOLVED_ID" \
      round_tag "$RESOLVED_ROUND" \
      tool_calls_count "$TC_CLAIMED" \
      observed_tool_call_lines "$TC_COUNT_OBS" \
      imported_transcript_path "$OUT_FILE"

    _emit_apex_event "transcript_imported" .apex \
      source_agent_id "$RESOLVED_ID" \
      target_path "$OUT_FILE" \
      entries_count "$TC_COUNT_OBS"

    # Campaign B B2.6 — sub-agent count guard (closes AC-9, GAP-5).
    # Cross-reference the envelope's claimed tool_calls_count against
    # the observed tool_call line count in the just-written transcript.
    # When the delta exceeds the small drift tolerance, emit a P0
    # `subagent_count_mismatch` event so the orchestrator (round-checker
    # step 7 / framework-auditor Axis 13) sees the lying sub-agent.
    #
    # Drift tolerance (frozen audit-trail-review/EXPERIMENT-PROTOCOL.md
    # §13): ±2 entries. The tolerance absorbs the transcript-import
    # race where the final tool_call event from the child might not
    # yet have flushed to event-log when SubagentStop fires.
    #
    # Graceful no-op: claimed=0 AND observed=0 = legitimate noop sub-
    # agent (e.g. an Explore agent that returned only narrative). The
    # mismatch fires only when claimed > 0 AND observed << claimed.
    DRIFT_TOL=2
    OBS_TC_COUNT=$(grep -c '"type":"tool_call"' "$OUT_FILE" 2>/dev/null | tr -d ' ')
    [ -z "$OBS_TC_COUNT" ] && OBS_TC_COUNT=0
    case "$TC_CLAIMED" in ''|*[!0-9]*) TC_CLAIMED=0 ;; esac
    case "$OBS_TC_COUNT" in ''|*[!0-9]*) OBS_TC_COUNT=0 ;; esac
    DELTA=$(( TC_CLAIMED - OBS_TC_COUNT ))
    DELTA_ABS=$DELTA
    [ "$DELTA_ABS" -lt 0 ] && DELTA_ABS=$(( -DELTA_ABS ))
    if [ "$TC_CLAIMED" -gt 0 ] && [ "$DELTA_ABS" -gt "$DRIFT_TOL" ]; then
      _emit_apex_event "subagent_count_mismatch" .apex \
        agent_name "$AGENT" \
        agent_id "$RESOLVED_ID" \
        claimed_count "$TC_CLAIMED" \
        observed_count "$OBS_TC_COUNT" \
        delta "$DELTA" \
        drift_tolerance "$DRIFT_TOL" \
        severity "P0" \
        note "lying_subagent_or_transcript_loss"
      echo "🛑 APEX GUARD (B2.6 count): subagent '${AGENT}' claimed ${TC_CLAIMED} tool calls; observed ${OBS_TC_COUNT} in transcript (delta=${DELTA}, tol=±${DRIFT_TOL}). P0 emitted." >&2
    fi
  else
    # Graceful path: SubagentStop fired but no matching registry entry
    # (pre-subagent-start.sh was disabled, hook order missed, or
    # cross-platform shim). Emit a degraded subagent_stop without
    # agent_id so the operator can spot the gap in dashboards.
    _emit_apex_event "subagent_stop" .apex \
      agent_name "$AGENT" \
      agent_id "" \
      tool_calls_count "$(echo "$INPUT" | jq -r '.tool_calls_count // 0' 2>/dev/null | tr -d '\r')" \
      note "no_matching_subagent_start_in_registry"
  fi
fi

exit 0
