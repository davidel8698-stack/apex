#!/bin/bash
set -u
# Path traversal and sensitive file protection
# Hook type: PreToolUse (Write, Edit)
#
# R5-014: On block, source `_fix-plan-emit.sh` and write `.apex/FIX_PLAN.md`
# so the user has a structured next-action plan, not just a stderr stack.
# Detection logic below is unchanged — only the FIX_PLAN.md emission was
# added before each `exit 2`. Exit codes preserved.

# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_fix-plan-emit.sh" ]; then
  source "$(dirname "$0")/_fix-plan-emit.sh"
fi

# Phase 8 R-P8-C6: canonical input extraction via shared helper.
# Closes F-003 (stdin-envelope bypass — auditor axis-13.e discovery).
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi

FILEPATH=$(apex_hook_input_filepath "$@" 2>/dev/null || printf '%s' "${1:-}")

block() {
  echo "APEX PATH GUARD: BLOCKED" >&2
  echo "Path: $1" >&2
  echo "Matched: $2" >&2
  echo "" >&2
  echo "This path is on APEX's deny-list. Operation rejected." >&2
  # R5-014: structured fix plan
  if command -v emit_fix_plan >/dev/null 2>&1; then
    emit_fix_plan \
      "path-guard" \
      "Path-guard blocked a write/edit because the target path matched a deny pattern: $2." \
      "Attempted Write/Edit to: $1" \
      "/apex:forensics -- diagnose why this path was attempted" \
      "/apex:rollback -- revert any partial edits to the last green tag" \
      "/apex:recover -- reset and re-plan with a different target path" \
      2>/dev/null || true
  fi
}

# === DENY PATTERNS ===

# Parent directory traversal
if echo "$FILEPATH" | grep -qF "../" 2>/dev/null; then
  block "$FILEPATH" "parent traversal (../)"
  exit 2
fi

# Unix system directories
if echo "$FILEPATH" | grep -qE "^/(etc|usr|var|root|home)/" 2>/dev/null; then
  block "$FILEPATH" "Unix system directory"
  exit 2
fi

# Windows system directories (case-insensitive)
if echo "$FILEPATH" | grep -qiE "^[A-Za-z]:\\\\(Windows|Program Files)" 2>/dev/null; then
  block "$FILEPATH" "Windows system directory"
  exit 2
fi

# Sensitive files/directories
if echo "$FILEPATH" | grep -qiE "(\.env(\.local|\.production|\.staging)?$|credentials|\.ssh/|\.gnupg/)" 2>/dev/null; then
  block "$FILEPATH" "sensitive file/directory"
  exit 2
fi

exit 0
