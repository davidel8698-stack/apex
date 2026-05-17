#!/bin/bash
set -u
source "$(dirname "$0")/_require-jq.sh"
require_jq
# R12-001 (F-201): wire real token counter on every SubagentStop event.
# The library is parallel to _state-update.sh; do NOT replace _state-update.sh
# (canonical state-mutation interface — preserved as-is per do-not-touch zone).
# shellcheck disable=SC1091
source "$(dirname "$0")/_tokens-update.sh"

export APEX_HOOK_SOURCE="${APEX_HOOK_SOURCE:-subagent-stop}"

INPUT=$(cat)
AGENT=$(echo "$INPUT" | jq -r '.agent_name // empty')

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

exit 0
