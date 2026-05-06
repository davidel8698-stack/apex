#!/bin/bash
# _agent-dispatch.sh — Agent invocation wrapper (R5-009).
#
# Hook type: Library — Sourced (or Command-Invoked utility)
#
# Purpose
#   Centralizes the "set environment for an agent invocation" contract
#   that quarantine-guard.sh (and any future agent-aware hook) reads.
#   Spec anchor: "Auditor quarantine" + "Information boundaries ARE
#   the architecture." Boundaries are structural, not declarative-in-
#   prose: every command that invokes auditor (or any other quarantined
#   agent in the future) MUST go through this dispatcher so the
#   APEX_ACTIVE_AGENT environment variable is set unconditionally.
#
# Usage
#   From a command .md (canonical pattern):
#     source ~/.claude/hooks/_agent-dispatch.sh
#     apex_dispatch_enter auditor
#     Task("auditor", AUDITOR_CONTEXT, model=resolve_model("auditor"))
#     apex_dispatch_exit
#
#   Or as an executable subcommand (when sourcing is impractical):
#     bash ~/.claude/hooks/_agent-dispatch.sh enter auditor
#     bash ~/.claude/hooks/_agent-dispatch.sh exit
#
#   The subcommand form prints `export` / `unset` lines on stdout so
#   callers can `eval "$(bash _agent-dispatch.sh enter auditor)"` if
#   needed. The sourced form is preferred — it mutates the caller's
#   environment directly.
#
# Contract
#   - apex_dispatch_enter <agent>: exports APEX_ACTIVE_AGENT=<agent>.
#   - apex_dispatch_exit: unsets APEX_ACTIVE_AGENT.
#   - The auditor preflight directive in framework/agents/auditor.md is
#     a second-layer defense: even if a future command forgets the
#     wrapper, the agent itself self-aborts with [QUARANTINE-FAIL].

apex_dispatch_enter() {
  local agent="${1:-}"
  if [ -z "$agent" ]; then
    echo "🚫 APEX DISPATCH: agent name required (usage: apex_dispatch_enter <agent>)" >&2
    return 2
  fi
  export APEX_ACTIVE_AGENT="$agent"
}

apex_dispatch_exit() {
  unset APEX_ACTIVE_AGENT
}

# Subcommand form — only fires when this file is executed (not sourced).
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  case "${1:-}" in
    enter)
      shift
      agent="${1:-}"
      if [ -z "$agent" ]; then
        echo "🚫 APEX DISPATCH: agent name required (usage: bash _agent-dispatch.sh enter <agent>)" >&2
        exit 2
      fi
      # Emit export line for eval-callers; also export in our own env.
      export APEX_ACTIVE_AGENT="$agent"
      echo "export APEX_ACTIVE_AGENT=\"$agent\""
      ;;
    exit)
      unset APEX_ACTIVE_AGENT
      echo "unset APEX_ACTIVE_AGENT"
      ;;
    *)
      echo "🚫 APEX DISPATCH: unknown subcommand '${1:-}'" >&2
      echo "   Usage: bash _agent-dispatch.sh enter <agent> | exit" >&2
      exit 2
      ;;
  esac
fi
