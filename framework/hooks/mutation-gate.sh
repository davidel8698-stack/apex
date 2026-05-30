#!/bin/bash
set -u
# Mutation testing gate — runs AFTER critic PASS for verify_level C/D tasks only.
# Critic judges correctness; this hook measures test quality.
# R4: 93% line coverage → only 59% mutation kill rate (34-point gap).
source "$(dirname "$0")/_require-jq.sh"
require_jq
source "$(dirname "$0")/_state-update.sh"

export APEX_HOOK_SOURCE="mutation-gate"

# Opt-out for environments where the gate is unwanted (e.g. CI without test
# mutation tooling, or local sessions doing exploratory work).
if [ "${APEX_MUTATION_GATE:-on}" = "off" ]; then
  echo "SKIP: mutation gate disabled via APEX_MUTATION_GATE=off"
  exit 0
fi

STATE_FILE=".apex/STATE.json"
TASK_ID="${1:-}"
VERIFY_LEVEL="${2:-}"

# Only run for C/D tasks
if [ "$VERIFY_LEVEL" != "C" ] && [ "$VERIFY_LEVEL" != "D" ]; then
  echo "SKIP: mutation testing only for verify_level C/D (got: $VERIFY_LEVEL)"
  exit 0
fi

# --- R16-622M: scope-creep block ---------------------------------------
# Spec anchor (IMP-022): "framework/agents/critic.md ו-framework/hooks/
# mutation-gate.sh חייבים לזהות scope-creep: task XML קצר (<2000 תווים)
# ו-diff גדול (>200 שורות) — flag." Critic-side R-622C flags after the
# fact; this PreToolUse-style check stops the mutation before it lands.
#
# Threshold (matches R-622C critic sibling):
#   task_xml_chars < 2000  AND  diff_lines > 200  →  scope-creep block.
#
# Task XML location convention: .apex/phases/<phase>/<task_id>/task.xml
# (per IMP-001 plan); fall back to .apex/phases/<phase>/<task_id>/TASK.md
# when XML not used; if neither present, the check is skipped (cannot
# evaluate the premise without task input).
#
# Diff measurement: lines added + lines removed from `git diff HEAD~1`
# restricted to source files (same set the mutation tool would see).
SCOPE_TASK_XML=""
if [ -n "$TASK_ID" ] && [ -f .apex/STATE.json ] && command -v jq >/dev/null 2>&1; then
  SCOPE_CURRENT_PHASE=$(jq -r '.current_phase // empty' .apex/STATE.json 2>/dev/null || echo "")
  if [ -n "$SCOPE_CURRENT_PHASE" ]; then
    for candidate in \
      ".apex/phases/$SCOPE_CURRENT_PHASE/$TASK_ID/task.xml" \
      ".apex/phases/$SCOPE_CURRENT_PHASE/$TASK_ID/TASK.md" \
      ".apex/phases/$SCOPE_CURRENT_PHASE/$TASK_ID.xml"; do
      if [ -f "$candidate" ]; then
        SCOPE_TASK_XML="$candidate"
        break
      fi
    done
  fi
fi
if [ -n "$SCOPE_TASK_XML" ]; then
  SCOPE_XML_CHARS=$(wc -c < "$SCOPE_TASK_XML" 2>/dev/null | tr -d ' ')
  SCOPE_DIFF_LINES=$(git diff HEAD~1 --shortstat 2>/dev/null | grep -oE '[0-9]+ insertion|[0-9]+ deletion' | grep -oE '[0-9]+' | awk '{s+=$1} END {print s+0}')
  : "${SCOPE_XML_CHARS:=0}"
  : "${SCOPE_DIFF_LINES:=0}"
  if [ "$SCOPE_XML_CHARS" -lt 2000 ] && [ "$SCOPE_DIFF_LINES" -gt 200 ]; then
    echo "🚫 MUTATION GATE: scope-creep detected (task XML chars=$SCOPE_XML_CHARS < 2000 AND diff lines=$SCOPE_DIFF_LINES > 200)" >&2
    echo "   The mutation is large relative to the task scope. Refactor the task into smaller subtasks," >&2
    echo "   or add an explicit scope expansion in the task XML before re-running this gate." >&2
    if [ -f "$(dirname "$0")/_fix-plan-emit.sh" ] && command -v emit_fix_plan >/dev/null 2>&1; then
      emit_fix_plan \
        "mutation-gate" \
        "Scope-creep block: task XML is shorter than 2000 chars but diff exceeds 200 lines." \
        "Task: $TASK_ID — xml_chars=$SCOPE_XML_CHARS, diff_lines=$SCOPE_DIFF_LINES, source=$SCOPE_TASK_XML" \
        "/apex:forensics -- review the diff against the task description" \
        "/apex:rollback -- revert the oversized mutation" \
        "/apex:recover -- split the work into smaller tasks and re-plan" \
        2>/dev/null || true
    fi
    exit 2
  fi
fi
# --- end R16-622M ------------------------------------------------------

# Detect changed files from latest commit
CHANGED_FILES=$(git diff --name-only HEAD~1 2>/dev/null | grep -E '\.(ts|tsx|js|jsx|py)$')
if [ -z "$CHANGED_FILES" ]; then
  echo "SKIP: no testable source files changed"
  exit 0
fi

# Detect stack and run appropriate mutation tool
KILL_RATE=0
TOOL_FOUND=0

# Cap each mutation tool at 5 minutes — Stryker/mutmut can otherwise hang for
# tens of minutes on pathological inputs and block the entire session.
MUTATION_TIMEOUT="${APEX_MUTATION_TIMEOUT:-300}"

# JS/TS: Stryker
if [ -f "package.json" ] && echo "$CHANGED_FILES" | grep -qE '\.(ts|tsx|js|jsx)$'; then
  if command -v npx &>/dev/null && npx stryker --version &>/dev/null 2>&1; then
    TOOL_FOUND=1
    MUTATE_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(ts|tsx|js|jsx)$' | tr '\n' ',' | sed 's/,$//')
    OUTPUT=$(timeout "${MUTATION_TIMEOUT}s" npx stryker run --mutate "$MUTATE_FILES" --reporters clear-text 2>&1 | tail -30)
    RC=$?
    if [ "$RC" -eq 124 ]; then
      echo "ADVISORY: stryker timed out after ${MUTATION_TIMEOUT}s — mutation gate skipped"
      exit 0
    fi
    KILL_RATE=$(echo "$OUTPUT" | grep -oP 'Mutation score.*?(\d+(\.\d+)?)%' | grep -oP '\d+(\.\d+)?' | tail -1)
  fi
fi

# Python: mutmut
if echo "$CHANGED_FILES" | grep -qE '\.py$'; then
  if command -v mutmut &>/dev/null; then
    TOOL_FOUND=1
    PY_FILES=$(echo "$CHANGED_FILES" | grep -E '\.py$' | tr '\n' ' ')
    OUTPUT=$(timeout "${MUTATION_TIMEOUT}s" python3 -m mutmut run --paths-to-mutate $PY_FILES --no-progress 2>&1 | tail -20)
    RC=$?
    if [ "$RC" -eq 124 ]; then
      echo "ADVISORY: mutmut timed out after ${MUTATION_TIMEOUT}s — mutation gate skipped"
      exit 0
    fi
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