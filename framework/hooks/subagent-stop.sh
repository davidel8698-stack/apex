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
