#!/bin/bash
# _require-jq.sh — jq availability guard for APEX hooks.
#
# Sourced by hooks that depend on jq. Fails loud with a clear message
# identifying the calling hook, instead of silently degrading.
#
# Usage (at the top of a hook, right after the shebang):
#   source "$(dirname "$0")/_require-jq.sh"
#   require_jq
#
# Behavior: if jq is not in PATH, prints the calling hook name to stderr
# and exits 2. No fallback, no hardcoded install paths.

require_jq() {
  if ! command -v jq &>/dev/null; then
    local caller="${BASH_SOURCE[1]:-unknown}"
    local hook_name
    hook_name="$(basename "$caller")"
    echo "🚫 APEX HOOK [$hook_name]: jq required but not in PATH" >&2
    echo "   Run /apex:health-check for environment diagnostics." >&2
    exit 2
  fi
}
