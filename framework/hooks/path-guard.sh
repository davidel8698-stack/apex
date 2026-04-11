#!/bin/bash
set -u
# Path traversal and sensitive file protection
# Hook type: PreToolUse (Write, Edit)

FILEPATH="${1:-}"

block() {
  echo "APEX PATH GUARD: BLOCKED" >&2
  echo "Path: $1" >&2
  echo "Matched: $2" >&2
  echo "" >&2
  echo "This path is on APEX's deny-list. Operation rejected." >&2
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
