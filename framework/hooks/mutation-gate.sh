#!/bin/bash
set -u
# Mutation testing gate — runs AFTER critic PASS for verify_level C/D tasks only.
# Critic judges correctness; this hook measures test quality.
# R4: 93% line coverage → only 59% mutation kill rate (34-point gap).
source "$(dirname "$0")/_require-jq.sh"
require_jq
source "$(dirname "$0")/_state-update.sh"

export APEX_HOOK_SOURCE="mutation-gate"

STATE_FILE=".apex/STATE.json"
TASK_ID="${1:-}"
VERIFY_LEVEL="${2:-}"

# Only run for C/D tasks
if [ "$VERIFY_LEVEL" != "C" ] && [ "$VERIFY_LEVEL" != "D" ]; then
  echo "SKIP: mutation testing only for verify_level C/D (got: $VERIFY_LEVEL)"
  exit 0
fi

# Detect changed files from latest commit
CHANGED_FILES=$(git diff --name-only HEAD~1 2>/dev/null | grep -E '\.(ts|tsx|js|jsx|py)$')
if [ -z "$CHANGED_FILES" ]; then
  echo "SKIP: no testable source files changed"
  exit 0
fi

# Detect stack and run appropriate mutation tool
KILL_RATE=0
TOOL_FOUND=0

# JS/TS: Stryker
if [ -f "package.json" ] && echo "$CHANGED_FILES" | grep -qE '\.(ts|tsx|js|jsx)$'; then
  if command -v npx &>/dev/null && npx stryker --version &>/dev/null 2>&1; then
    TOOL_FOUND=1
    MUTATE_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(ts|tsx|js|jsx)$' | tr '\n' ',' | sed 's/,$//')
    OUTPUT=$(npx stryker run --mutate "$MUTATE_FILES" --reporters clear-text 2>&1 | tail -30)
    KILL_RATE=$(echo "$OUTPUT" | grep -oP 'Mutation score.*?(\d+(\.\d+)?)%' | grep -oP '\d+(\.\d+)?' | tail -1)
  fi
fi

# Python: mutmut
if echo "$CHANGED_FILES" | grep -qE '\.py$'; then
  if command -v mutmut &>/dev/null; then
    TOOL_FOUND=1
    PY_FILES=$(echo "$CHANGED_FILES" | grep -E '\.py$' | tr '\n' ' ')
    OUTPUT=$(python3 -m mutmut run --paths-to-mutate $PY_FILES --no-progress 2>&1 | tail -20)
    KILLED=$(echo "$OUTPUT" | grep -oP 'Killed:\s*(\d+)' | grep -oP '\d+')
    TOTAL=$(echo "$OUTPUT" | grep -oP 'Total:\s*(\d+)' | grep -oP '\d+')
    if [ -n "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
      KILL_RATE=$((KILLED * 100 / TOTAL))
    fi
  fi
fi

if [ "$TOOL_FOUND" -eq 0 ]; then
  echo "ADVISORY: mutation testing tool not installed (Stryker for JS/TS, mutmut for Python)"
  echo "Install for better test quality verification. Continuing without mutation gate."
  exit 0
fi

# Determine threshold based on verify level
THRESHOLD=50
if [ "$VERIFY_LEVEL" = "D" ]; then
  THRESHOLD=70
fi

# Update STATE.json with mutation score
if [ -f "$STATE_FILE" ]; then
  _state_update --arg task "$TASK_ID" --argjson score "${KILL_RATE:-0}" \
    '.mutation_scores[$task] = $score' "$STATE_FILE"
fi

echo "Mutation kill rate: ${KILL_RATE:-0}% (threshold: ${THRESHOLD}%)"

if [ -n "$KILL_RATE" ] && [ "$KILL_RATE" -ge "$THRESHOLD" ]; then
  echo "PASS: mutation kill rate ${KILL_RATE}% meets threshold"
  exit 0
else
  echo "BELOW THRESHOLD: mutation kill rate ${KILL_RATE:-0}% below ${THRESHOLD}% minimum"
  echo "Top surviving mutants indicate weak test areas."
  exit 2
fi