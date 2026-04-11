#!/bin/bash
set -u
# Prompt injection detection — defense-in-depth layer
# Hook type: PreToolUse (agent dispatch / file write)

INPUT="${1:-}"

block() {
  echo "APEX PROMPT GUARD: BLOCKED" >&2
  echo "Pattern: $1" >&2
  echo "Matched: $2" >&2
  echo "" >&2
  echo "Suspected prompt injection detected. Input rejected." >&2
}

# Normalize: collapse whitespace, trim
NORMALIZED=$(echo "$INPUT" | tr -s ' ')

# === DENY PATTERNS ===

# Instruction override attempts
if echo "$NORMALIZED" | grep -qiE "(ignore (all )?previous instructions|disregard previous)" 2>/dev/null; then
  block "instruction override" "ignore/disregard previous instructions"
  exit 2
fi

# Role hijacking: "you are now" followed by content
if echo "$NORMALIZED" | grep -qiE "you are now\s+.+" 2>/dev/null; then
  block "role hijacking" "you are now ..."
  exit 2
fi

# System prompt framing: "system:" at start of a line
# grep processes input line-by-line, so ^ matches start of each line
if echo "$NORMALIZED" | grep -qiE "^[[:space:]]*system:" 2>/dev/null; then
  block "prompt framing" "system: at start of line"
  exit 2
fi

# Markdown code block injection: ```system
if echo "$NORMALIZED" | grep -qiE '```system' 2>/dev/null; then
  block "code block injection" '```system'
  exit 2
fi

# Priority injection: IMPORTANT: or CRITICAL: at start of line
if echo "$NORMALIZED" | grep -qE "^[[:space:]]*(IMPORTANT|CRITICAL):" 2>/dev/null; then
  block "priority injection" "IMPORTANT:/CRITICAL: at start of line"
  exit 2
fi

exit 0
