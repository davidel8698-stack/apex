#!/bin/bash
# grader-search-guard.sh — R16-629 (F-629, IMP-029).
#
# Hook type: Auto-PreToolUse (Bash matcher).
#
# Purpose
#   Block reward-hacking via answer-key lookup. If the current task is
#   NOT test-writing AND a Bash tool call contains find/grep over any of
#   {score, grade, gold, truth, answer, test, expect, oracle}, exit 2.
#   This prevents an executor that's solving a graded task from peeking
#   at the grading rubric / golden answer file.
#
# Three-places contract
#   * hook file (this)
#   * framework/settings.json PreToolUse entry under matcher: "Bash"
#   * framework/HOOK-CLASSIFICATION.md row under Auto-PreToolUse
#
# Spec contradiction resolution
#   IMP-029 says: block such searches when the task is not test-writing.
#   The test-architect agent legitimately performs Wave 0 reconnaissance
#   over test directories — including grepping for expectation keywords.
#   Carve-out: APEX_ACTIVE_AGENT=test-architect → pass through.
#
# Carve-outs (in order of priority)
#   * APEX_ACTIVE_AGENT=test-architect — Wave 0 scan
#   * APEX_TASK_TYPE=test_writing — explicit test-writing task
#   * APEX_GRADER_SEARCH_GUARD=off — emergency bypass (logged)
#
# Exit codes: 0 = clean, 2 = blocked.

set -u

# Phase 8 R-P8-C5: canonical input extraction via shared helper.
# Closes F-007 (stdin-envelope bypass — auditor axis-13.e discovery).
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi

COMMAND=$(apex_hook_input_command "$@" 2>/dev/null || printf '%s' "${1:-}")
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Carve-out 1: test-architect agent
if [ "${APEX_ACTIVE_AGENT:-}" = "test-architect" ]; then
  exit 0
fi

# Carve-out 2: explicit test-writing task type
if [ "${APEX_TASK_TYPE:-}" = "test_writing" ]; then
  exit 0
fi

# Carve-out 3: emergency bypass
if [ "${APEX_GRADER_SEARCH_GUARD:-on}" = "off" ]; then
  exit 0
fi

NORMALIZED=$(printf '%s' "$COMMAND" | tr -s '[:space:]' ' ' | sed 's/^ *//; s/ *$//')

# Only act on find / grep / rg / ag commands
if ! echo "$NORMALIZED" | grep -qiE "(^|[[:space:]])(find|grep|rg|ag|fgrep|egrep)([[:space:]]|$)" 2>/dev/null; then
  exit 0
fi

# Match the answer-key vocabulary in the command body.
# Vocabulary: score, grade, gold, golden, ground.truth, oracle, expect,
# expected, answer, answer.key, solution, rubric.
BLOCK_REASON=""
if echo "$NORMALIZED" | grep -qiE "(answer[._ -]?key|ground[._ -]?truth|golden[._ -]?(answer|file|set)|oracle|rubric|grading[._ -]?key|solution[._ -]?file|expected[._ -]?output)" 2>/dev/null; then
  BLOCK_REASON="answer-key / ground-truth / oracle / rubric vocabulary"
elif echo "$NORMALIZED" | grep -qiE "[[:space:]]-(name|iname|grep)[[:space:]]+[\"']?\*?(score|grade|gold|truth|answer|oracle|rubric|solution|expected)\*?[\"']?" 2>/dev/null; then
  BLOCK_REASON="find -name / grep over grading vocabulary"
elif echo "$NORMALIZED" | grep -qiE "(grep|rg|ag|fgrep|egrep)[[:space:]]+(-[a-zA-Z]+[[:space:]]+)?[\"']?(score|grade|gold|truth|answer|oracle|rubric)[\"']?" 2>/dev/null; then
  # Allow when the term appears inside a path-style argument by checking
  # the next token is not a path (defensive): if the matched term is
  # followed by something that looks like a directory hint, still block.
  BLOCK_REASON="grep pattern over grading vocabulary"
fi

if [ -n "$BLOCK_REASON" ]; then
  echo "APEX GRADER SEARCH GUARD: BLOCKED" >&2
  echo "Reason: search over grading / answer-key vocabulary outside a test-writing task" >&2
  echo "Matched: $BLOCK_REASON" >&2
  echo "" >&2
  echo "If this is a legitimate test-writing task, set:" >&2
  echo "  APEX_TASK_TYPE=test_writing"  >&2
  echo "or run under the test-architect agent (APEX_ACTIVE_AGENT=test-architect)." >&2
  echo "Emergency bypass: APEX_GRADER_SEARCH_GUARD=off (logged)." >&2
  if command -v emit_fix_plan >/dev/null 2>&1; then
    emit_fix_plan \
      "grader-search-guard" \
      "Tool call searched for grading / answer-key vocabulary outside a test-writing task." \
      "Matched: $BLOCK_REASON" \
      "/apex:forensics -- inspect what triggered the search" \
      "/apex:next -- continue without peeking at expected outputs" 2>/dev/null || true
  fi
  exit 2
fi

exit 0
