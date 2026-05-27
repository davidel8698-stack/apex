#!/bin/bash
# _hook-input.sh — Canonical input-extraction helper for APEX guard hooks.
#
# Spec equivalence: this file is the project-wide single source of truth for
# extracting tool-envelope input passed to PreToolUse/PostToolUse hooks. It
# closes the F-001 family of stdin-envelope-bypass vulnerabilities documented
# in `audit-trail-review/trials-c5-final/c5-T7-NC.md` (Phase 7 axis-13.e
# discovery) by providing a canonical argv→stdin→empty fallback chain.
#
# Sourced by guard hooks that need tool-input. Never executed directly.
#
# Usage (single-field — the common case, used by 14 of 15 hooks):
#   if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
#     source "$(dirname "$0")/_hook-input.sh"
#   fi
#   COMMAND=$(apex_hook_input_command "$@")
#   # ... then use $COMMAND as before
#
# Usage (multi-field — for hooks needing both .tool_name AND .tool_input,
# such as test-deletion-guard.sh):
#   PAYLOAD=$(apex_hook_input_raw "$@")
#   TOOL_NAME=$(echo "$PAYLOAD" | jq -r '.tool_name // empty' 2>/dev/null)
#   TOOL_INPUT=$(echo "$PAYLOAD" | jq -r '.tool_input // empty' 2>/dev/null)
#
# Provides 4 stdout-echo extractors (capture via $(...)):
#   apex_hook_input_command   "$@"  — echoes .tool_input.command
#   apex_hook_input_filepath  "$@"  — echoes .tool_input.file_path (or .path)
#   apex_hook_input_tool_name "$@"  — echoes .tool_name
#   apex_hook_input_raw       "$@"  — echoes the full stdin payload (for hooks doing custom jq)
#
# Algorithm per extractor (argv-first preserves all 27 argv-style test
# invocations across test-fix-plan-emit.sh + test-hooks-security.sh +
# test-hooks-blocking.sh covering 9 distinct hooks):
#   1. If $1 is non-empty → echo $1 (legacy argv contract).
#   2. Else if stdin is readable (not a TTY) → consume via `cat`, then jq.
#   3. Else → echo empty (caller fast-exits 0).
#
# Stdin handling — LAZY inside each function (NOT source-time):
#   Source-time read would block in CI environments where stdin is inherited
#   from a non-TTY non-EOF parent process. Lazy-inside-function is safe
#   because argv-first short-circuits the stdin probe in test invocations
#   that provide argv.
#
# Multi-field constraint: a SINGLE hook invocation can only consume stdin
# ONCE. If a hook needs multiple fields from the same envelope (e.g.,
# test-deletion-guard), use `apex_hook_input_raw "$@"` to capture the full
# payload into a local variable, then do its own jq parsing. Calling
# multiple single-field extractors in separate $(...) subshells will NOT
# share stdin payload — only the first call (per hook execution) sees the
# pipe data; subsequent calls see drained stdin and return empty.
#
# Function export: functions are NOT export -f'd. Bash $(...) subshells
# inherit functions from the parent shell automatically; no export needed.
#
# Naming convention: project-wide public API uses `apex_*` (no underscore
# prefix); module-scope state would use `_APEX_HOOK_*` (uppercase) but no
# module-scope state is needed in this lazy-pattern design. Compare with
# `_security-common.sh` which uses `_sec_*` for security-family internals.
#
# set -u compatibility: all variable references use ${VAR:-} default expansion.
# Header sets `set -u` so consumers that forget to do so still surface unbound
# variable bugs.

set -u

# ---------------------------------------------------------------------------
# Public extractors — all echo to stdout, all return 0, never exit.
# ---------------------------------------------------------------------------

apex_hook_input_command() {
  # Bash matcher: extract .tool_input.command, with argv fallback.
  if [ -n "${1:-}" ]; then
    printf '%s' "$1"
    return 0
  fi
  if [ ! -t 0 ] && command -v jq >/dev/null 2>&1; then
    local payload
    payload=$(cat 2>/dev/null || true)
    if [ -n "$payload" ]; then
      printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null
    fi
  fi
  return 0
}

apex_hook_input_filepath() {
  # Write/Edit matcher: extract .tool_input.file_path (or .path), with argv fallback.
  if [ -n "${1:-}" ]; then
    printf '%s' "$1"
    return 0
  fi
  if [ ! -t 0 ] && command -v jq >/dev/null 2>&1; then
    local payload
    payload=$(cat 2>/dev/null || true)
    if [ -n "$payload" ]; then
      printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null
    fi
  fi
  return 0
}

apex_hook_input_tool_name() {
  # Shape-routing extractor: echoes .tool_name from stdin envelope.
  # argv fallback supported for direct CLI invocations.
  if [ -n "${1:-}" ]; then
    printf '%s' "$1"
    return 0
  fi
  if [ ! -t 0 ] && command -v jq >/dev/null 2>&1; then
    local payload
    payload=$(cat 2>/dev/null || true)
    if [ -n "$payload" ]; then
      printf '%s' "$payload" | jq -r '.tool_name // empty' 2>/dev/null
    fi
  fi
  return 0
}

apex_hook_input_raw() {
  # Full stdin payload — for hooks doing custom jq queries beyond the 3 canonical fields.
  # argv fallback: a literal payload string passed as $1 is echoed verbatim.
  if [ -n "${1:-}" ]; then
    printf '%s' "$1"
    return 0
  fi
  if [ ! -t 0 ]; then
    cat 2>/dev/null || true
  fi
  return 0
}

# End _hook-input.sh — sourced module. Direct invocation (`bash _hook-input.sh`)
# is a no-op: no top-level code runs beyond function definitions, so no output
# is produced and exit code is 0.
