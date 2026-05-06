#!/bin/bash
set -u
# Workflow recipe injection scanner — defense-in-depth layer.
# Hook type: Auto-PreToolUse:Read (shim — delegates to workflow-guard.cjs when node is present)
#            + explicit invocation by /apex:workflow.
#            Self-filters on path: scans only apex-workflows/* files; instant exit 0 for all others.
#
# R5-003: Spec names this guard as `apex-workflow-guard.js`. The canonical
# implementation now lives in framework/hooks/workflow-guard.cjs. This .sh
# remains for two reasons:
#   1. Hosts without `node` on PATH still need the protection.
#   2. ~/.claude/hooks/workflow-guard.sh is referenced by /apex:workflow and
#      (historically) by settings.json — keeping the file path stable
#      preserves those invocation sites.
#
# Behavior contract: byte-equivalent detection patterns to workflow-guard.cjs
# (both load from framework/test-fixtures/security-patterns.json).

source "$(dirname "$0")/_security-common.sh"

# R5-014: Source the shared fix-plan emitter and override `_sec_block` so
# every workflow-guard block also writes `.apex/FIX_PLAN.md`. Detection
# patterns and exit code below are unchanged. This wrapper only adds
# the fix-plan write before delegating to the original `_sec_block`.
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_fix-plan-emit.sh" ]; then
  source "$(dirname "$0")/_fix-plan-emit.sh"
fi
_sec_block_orig=$(declare -f _sec_block)
if [ -n "$_sec_block_orig" ] && command -v emit_fix_plan >/dev/null 2>&1; then
  _sec_block() {
    local _guard="$1" _pattern="$2" _matched="$3"
    emit_fix_plan \
      "workflow-guard" \
      "Workflow recipe injection blocked: $_pattern detected." \
      "Matched detail: $_matched" \
      "/apex:forensics -- diagnose where the injected workflow came from" \
      "/apex:rollback -- revert recent edits to the last green tag" \
      "/apex:recover -- reset and re-plan with a sanitized workflow" \
      2>/dev/null || true
    # Now call the original block writer (it does stderr + exit 2).
    echo "APEX $_guard: BLOCKED" >&2
    echo "Pattern: $_pattern" >&2
    echo "Matched: $_matched" >&2
    echo "" >&2
    echo "Security violation detected. Operation rejected." >&2
    exit 2
  }
fi

FILE="${1:-}"

# Hook context fallback: if no $1, try stdin (Claude Code PreToolUse passes JSON)
if [ -z "$FILE" ] && [ ! -t 0 ]; then
  FILE=$(cat 2>/dev/null | jq -r '.tool_input.file_path // empty' 2>/dev/null)
fi

# --- Delegate to the .cjs when node is present ------------------------------
if command -v node >/dev/null 2>&1; then
  CJS_PATH="$(dirname "$0")/workflow-guard.cjs"
  if [ -f "$CJS_PATH" ]; then
    if [ -n "$FILE" ]; then
      exec node "$CJS_PATH" "$FILE"
    else
      exec node "$CJS_PATH"
    fi
  fi
  # Fall through to native Bash if .cjs missing (degraded install).
fi

# --- Native Bash fallback (preservation contract: original R-006 logic) -----

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
