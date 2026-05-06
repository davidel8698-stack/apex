#!/usr/bin/env bash
# Hook type: Library — Sourced
#
# _adapter-detect.sh — Active-adapter detection for the runtime
# adapter-honesty banner (R6-017).
#
# Spec anchors:
#   "Multi-platform from day one."
#   "Honest scope over marketing scope."
#   "Honestly Scoped, Not Universally Promised."
#
# Purpose
#   Return the name of the active APEX adapter (e.g. "claude-code",
#   "cursor") so that runtime surfaces (`/apex:start`, `/apex:onboard`)
#   can read the matching `framework/adapters/<name>/adapter.json` and
#   decide whether to render the scope-honesty banner.
#
# Detection signals (checked in priority order)
#   1. `.apex/adapter` sidecar file in the project root — canonical
#      explicit override. The first non-blank line, trimmed, is the
#      adapter name. This is the only signal a non-Claude-Code host
#      can rely on portably.
#   2. APEX_ADAPTER environment variable — second-priority explicit
#      override (CI / dev-loop without a sidecar).
#   3. CURSOR_* environment markers — heuristic for Cursor.
#   4. Default: "claude-code" (the canonical reference host).
#
# Three-places contract
#   This helper lives in three places by the APEX delivery contract:
#     framework/hooks/_adapter-detect.sh         (source of truth)
#     ~/.claude/hooks/_adapter-detect.sh         (delivered by sync-to-claude.sh)
#     framework/HOOK-CLASSIFICATION.md           (registry row)
#
# Subcommands
#   active   — print the active adapter name to stdout, exit 0.
#
# Sourced usage
#   When sourced (no args), exposes `apex_adapter_active` as a function.

apex_adapter_active() {
  # 1. Sidecar file (canonical explicit signal).
  if [ -f "${APEX_PROJECT_ROOT:-.}/.apex/adapter" ]; then
    local val
    val=$(grep -v '^[[:space:]]*$' "${APEX_PROJECT_ROOT:-.}/.apex/adapter" 2>/dev/null \
          | head -n 1 \
          | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/\r$//')
    if [ -n "$val" ]; then
      printf '%s\n' "$val"
      return 0
    fi
  fi

  # 2. APEX_ADAPTER environment override.
  if [ -n "${APEX_ADAPTER:-}" ]; then
    printf '%s\n' "$APEX_ADAPTER"
    return 0
  fi

  # 3. Heuristic: any CURSOR_* env var implies Cursor host.
  if env | grep -q '^CURSOR_'; then
    printf 'cursor\n'
    return 0
  fi

  # 4. Default: claude-code (canonical reference host).
  printf 'claude-code\n'
  return 0
}

# When invoked directly (not sourced), dispatch on subcommand.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  case "${1:-active}" in
    active)
      apex_adapter_active
      exit $?
      ;;
    *)
      echo "usage: $(basename "$0") active" >&2
      exit 2
      ;;
  esac
fi
