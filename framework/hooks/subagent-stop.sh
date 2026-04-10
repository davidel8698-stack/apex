#!/bin/bash
source "$(dirname "$0")/_require-jq.sh"
require_jq

INPUT=$(cat)
AGENT=$(echo "$INPUT" | jq -r '.agent_name // empty')

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
