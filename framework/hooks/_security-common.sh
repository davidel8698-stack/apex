#!/bin/bash
# _security-common.sh — Shared security utilities for APEX guard hooks.
#
# Spec equivalence: this file + the five individual guard hooks
# (prompt-guard.sh, path-guard.sh, workflow-guard.sh, destructive-guard.sh,
# quarantine-guard.sh) collectively implement the `security.cjs` module
# described in apex-spec.md (Failure 9 — Defense-in-Depth Security Layer).
# See framework/security-policy.md for the full mechanism-to-file mapping.
#
# R5-003 dual-runtime note: The two named-as-`.js` guards (prompt-guard,
# workflow-guard) and the named `security.cjs` module are now also shipped
# as Node-runtime CommonJS files: `framework/hooks/apex-prompt-guard.cjs`,
# `apex-workflow-guard.cjs`, `security.cjs` (R6-014 added the `apex-` prefix
# to the two ported guards to match the spec literal naming; the .sh shim
# names — `prompt-guard.sh`, `workflow-guard.sh` — are preserved). Those files reimplement the
# same normalization (zero-width strip + whitespace collapse), pattern
# matching, and block-response formatting that this Bash library provides.
# Both runtimes load their detection patterns from
# `framework/test-fixtures/security-patterns.json` — single source of truth,
# so the .sh and .cjs branches cannot drift. The .sh shims (prompt-guard.sh,
# workflow-guard.sh) prefer the .cjs path when `node` is on PATH and fall
# back to the native Bash code below when it is not.
#
# Sourced by security hooks that need common normalization and pattern
# matching. Never executed directly.
#
# Usage (at the top of a guard hook):
#   source "$(dirname "$0")/_security-common.sh"
#
# Provides:
#   _sec_normalize <text>    — collapse whitespace, strip zero-width chars
#   _sec_pattern_match <text> <pattern> — test text against extended regex
#   _sec_block <guard_name> <pattern_name> <matched_detail> — formatted block message + exit 2

_sec_normalize() {
  local input="$1"
  # Strip zero-width characters: U+200B, U+200C, U+200D, U+FEFF, U+00AD
  local cleaned
  cleaned=$(printf '%s' "$input" | sed 's/\xE2\x80\x8B//g; s/\xE2\x80\x8C//g; s/\xE2\x80\x8D//g; s/\xEF\xBB\xBF//g; s/\xC2\xAD//g')
  # Collapse whitespace
  echo "$cleaned" | tr -s '[:space:]' ' '
}

_sec_pattern_match() {
  local text="$1"
  local pattern="$2"
  echo "$text" | grep -qiE "$pattern" 2>/dev/null
}

_sec_block() {
  local guard_name="$1"
  local pattern_name="$2"
  local matched="$3"
  echo "APEX $guard_name: BLOCKED" >&2
  echo "Pattern: $pattern_name" >&2
  echo "Matched: $matched" >&2
  echo "" >&2
  echo "Security violation detected. Operation rejected." >&2
  exit 2
}
