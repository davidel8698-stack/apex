#!/bin/bash
set -u
# Workflow recipe injection scanner — defense-in-depth layer
# Hook type: Auto-wired PreToolUse:Read (framework/settings.json) + explicit invocation by /apex:workflow
#            Self-filters on path: scans only apex-workflows/* files; instant exit 0 for all others.
#
# Scans a workflow .md file for injection patterns before execution.
# Exit 2 = blocked (injection detected), Exit 0 = clean

source "$(dirname "$0")/_security-common.sh"

FILE="${1:-}"

# Hook context fallback: if no $1, try stdin (Claude Code PreToolUse passes JSON)
if [ -z "$FILE" ] && [ ! -t 0 ]; then
  FILE=$(cat 2>/dev/null | jq -r '.tool_input.file_path // empty' 2>/dev/null)
fi

# Self-filter: only scan workflow recipe files. Instant exit for everything else.
# Non-workflow Read operations must not incur file I/O cost.
if [ -n "$FILE" ] && ! echo "$FILE" | grep -q "apex-workflows/" 2>/dev/null; then
  exit 0
fi

if [ -z "$FILE" ]; then
  echo "APEX WORKFLOW GUARD: No file path provided" >&2
  exit 1
fi

if [ ! -f "$FILE" ]; then
  echo "APEX WORKFLOW GUARD: File not found: $FILE" >&2
  exit 1
fi

CONTENT=$(cat "$FILE")
NORMALIZED=$(_sec_normalize "$CONTENT")

# === DENY PATTERNS ===

# Instruction override attempts
if _sec_pattern_match "$NORMALIZED" "(ignore (all )?previous instructions|disregard previous)"; then
  _sec_block "WORKFLOW GUARD" "instruction override" "ignore/disregard previous instructions in $FILE"
fi

# Role hijacking
if _sec_pattern_match "$NORMALIZED" "you are now\s+.+"; then
  _sec_block "WORKFLOW GUARD" "role hijacking" "you are now ... in $FILE"
fi

# Hidden directives in HTML comments
if grep -qiE '<!--\s*(system|ignore|override|inject):' "$FILE" 2>/dev/null; then
  _sec_block "WORKFLOW GUARD" "hidden HTML directive" "<!-- system/ignore/override/inject: in $FILE"
fi

# System prompt framing
if echo "$NORMALIZED" | grep -qiE "^[[:space:]]*system:" 2>/dev/null; then
  _sec_block "WORKFLOW GUARD" "prompt framing" "system: at start of line in $FILE"
fi

# Executable code blocks with injection markers
if grep -qiE '```(system|ignore|override|inject)' "$FILE" 2>/dev/null; then
  _sec_block "WORKFLOW GUARD" "code block injection" '```system/ignore/override/inject in '"$FILE"
fi

# Priority injection at line start
if grep -qE "^[[:space:]]*(IMPORTANT|CRITICAL):" "$FILE" 2>/dev/null; then
  _sec_block "WORKFLOW GUARD" "priority injection" "IMPORTANT:/CRITICAL: at start of line in $FILE"
fi

# Zero-width characters (already stripped by normalize, but check raw file)
if grep -qP '[\x{200B}\x{200C}\x{200D}\x{FEFF}\x{00AD}]' "$FILE" 2>/dev/null; then
  _sec_block "WORKFLOW GUARD" "zero-width characters" "invisible characters detected in $FILE"
fi

exit 0
