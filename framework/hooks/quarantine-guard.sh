#!/bin/bash
set -u
# Auditor quarantine enforcement — agent-aware file access control
# Hook type: PreToolUse (Read|Bash)
#
# First agent-aware hook in APEX. Checks APEX_ACTIVE_AGENT env var.
# When auditor is active, only test files and .apex/ state files are allowed.
# Non-auditor context: instant pass-through (microsecond overhead).
# Exit 2 = blocked (quarantine violation), Exit 0 = allowed
#
# R5-014: On block, source `_fix-plan-emit.sh` and write `.apex/FIX_PLAN.md`
# so the user understands which agent was active and which file types are
# allowed under the quarantine. Detection logic below is unchanged.

# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_fix-plan-emit.sh" ]; then
  source "$(dirname "$0")/_fix-plan-emit.sh"
fi

ACTIVE_AGENT="${APEX_ACTIVE_AGENT:-}"

# Fast path: if not auditor, pass through immediately
if [ "$ACTIVE_AGENT" != "auditor" ]; then
  exit 0
fi

# Auditor is active — enforce quarantine.
# Phase 8 R-P8-C7: canonical input extraction via shared helper.
# Closes F-004 (stdin-envelope bypass — auditor axis-13.e discovery).
# quarantine-guard is registered for BOTH Read AND Bash matchers, so the
# envelope may carry either .tool_input.file_path OR .tool_input.command.
# Strategy: use raw extractor, then either parse JSON envelope (stdin path)
# or fall back to argv literal (test path) — single string in either case.
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi

INPUT=""
if [ -n "${1:-}" ]; then
  # Argv-first (legacy test contract preserved verbatim).
  INPUT="$1"
elif command -v apex_hook_input_raw >/dev/null 2>&1; then
  RAW=$(apex_hook_input_raw 2>/dev/null || true)
  if [ -n "$RAW" ] && command -v jq >/dev/null 2>&1 \
      && printf '%s' "$RAW" | jq -e . >/dev/null 2>&1; then
    INPUT=$(printf '%s' "$RAW" \
      | jq -r '.tool_input.file_path // .tool_input.command // empty' 2>/dev/null)
  else
    INPUT="$RAW"
  fi
fi

# Allow empty input (shouldn't happen, but safe)
[ -z "$INPUT" ] && exit 0

# Allow-list patterns for auditor — anchored to actual test files / test directories
# R5-008: regex tightened to avoid substring matches like "spec" → "specialist"/"specification"
# Matches: /test/, /tests/, /__tests__/, .test., .spec., paths starting with test_ (or /test_)
if echo "$INPUT" | grep -qE "(/test/|/tests/|/__tests__/|\.test\.|\.spec\.|^test_|/test_)" 2>/dev/null; then
  exit 0
fi

# APEX state files (auditor needs to read STATE.json, RESULT.json, etc.)
if echo "$INPUT" | grep -qE "(\.apex/|STATE\.json|RESULT\.json|SUMMARY\.md|CRITIC\.md|PLAN_META\.json)" 2>/dev/null; then
  exit 0
fi

# Package manifests (auditor may need to check dependencies)
if echo "$INPUT" | grep -qE "(package\.json|requirements\.txt|Cargo\.toml|go\.mod|pyproject\.toml)" 2>/dev/null; then
  exit 0
fi

# Everything else: blocked
echo "APEX QUARANTINE GUARD: BLOCKED" >&2
echo "Agent: auditor" >&2
echo "Path: $INPUT" >&2
echo "" >&2
echo "Auditor agent cannot access implementation files." >&2
echo "Only test files, .apex/ state, and package manifests are allowed." >&2
# R5-014: structured fix plan
if command -v emit_fix_plan >/dev/null 2>&1; then
  emit_fix_plan \
    "quarantine-guard" \
    "Auditor agent attempted to access an implementation file (only tests + .apex/ + package manifests allowed)." \
    "Blocked path: $INPUT" \
    "/apex:forensics -- inspect why the auditor crossed the quarantine" \
    "/apex:rollback -- discard the auditor's tainted findings" \
    "/apex:recover -- reset and re-run the auditor with the correct scope" \
    2>/dev/null || true
fi
exit 2
