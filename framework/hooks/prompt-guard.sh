#!/bin/bash
set -u
# Prompt injection detection — defense-in-depth layer.
# Hook type: Auto-PreToolUse (shim — delegates to apex-prompt-guard.cjs when node is present).
#
# R5-003: Spec names this guard as `apex-prompt-guard.js`. The canonical
# implementation now lives in framework/hooks/apex-prompt-guard.cjs (R6-014
# renamed prompt-guard.cjs → apex-prompt-guard.cjs to match the spec literal
# `apex-` prefix; the .cjs/.js extension equivalence is documented in
# framework/docs/SECURITY-RUNTIME.md). This .sh remains for two reasons:
#   1. Hosts without `node` on PATH (rare but possible — minimal containers,
#      Bash-only forensic shells) still need the protection.
#   2. The path ~/.claude/hooks/prompt-guard.sh is referenced by command .md
#      files and (historically) by settings.json — keeping the .sh shim name
#      stable preserves those invocation sites (R6-014 preservation contract:
#      shim names unchanged; only the .cjs payload was renamed).
#
# Behavior contract: byte-equivalent detection patterns to apex-prompt-guard.cjs
# (both load from framework/test-fixtures/security-patterns.json — see
# security.cjs for the .cjs side). When node is available, this shim
# delegates so the canonical regex engine runs both branches identically.

# Campaign C TP-C2: source the audit-probe-marker helper. FIRST check
# below (before the .cjs delegation) allows legitimate framework-auditor
# probes through on the no-Node fallback path too.
# Spec anchor: audit-trail-review/FIX-DESIGN-C-R4.md §2 (closes CR-C-06).
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_audit-probe-marker.sh" ]; then
  source "$(dirname "$0")/_audit-probe-marker.sh"
fi

INPUT="${1:-}"

# Campaign C TP-C2 FIRST check — three-factor audit-probe carve-out.
# Runs BEFORE the .cjs delegation so the carve-out applies on both paths
# (Node-present and Node-less hosts). The .cjs has parallel logic via
# security.cjs auditProbe.check() — three-place contract maintained.
if type apex_check_audit_probe >/dev/null 2>&1; then
  if apex_check_audit_probe "$INPUT"; then
    exit 0
  fi
fi

# --- Delegate to the .cjs when node is present ------------------------------
if command -v node >/dev/null 2>&1; then
  CJS_PATH="$(dirname "$0")/apex-prompt-guard.cjs"
  if [ -f "$CJS_PATH" ]; then
    if [ -n "$INPUT" ]; then
      exec node "$CJS_PATH" "$INPUT"
    else
      # No argv → forward stdin to the .cjs (Claude Code hook protocol).
      exec node "$CJS_PATH"
    fi
  fi
  # Fall through to native Bash if .cjs missing (degraded install).
fi

# --- Native Bash fallback (preservation contract: original R-006 logic) -----

# R17-644 (F-644, IMP-003): emit a one-line stderr advisory when the Bash
# fallback runs (i.e. node was unavailable or the .cjs payload was missing).
# Placed AFTER the `if command -v node ... exec node ...` delegation so it
# fires only on the degraded path. The five free-text prompt-injection
# patterns below DO still fire; the missing capability is IMP-003 arg-name
# dispatch (path-typed shell-metachar / name-typed role-marker /
# >1000-char advisory) — which is only available via the .cjs path.
printf '[APEX SECURITY] IMP-003 arg-content validation (path-arg shell-metachar / name-arg role-marker / >1000-char advisory) requires Node.js. Current host has no node on PATH; falling back to the 5 free-text prompt-injection patterns. Install Node.js to enable full IMP-003 coverage. See framework/docs/SECURITY-RUNTIME.md §Node.js prerequisite for IMP-003.\n' >&2

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
