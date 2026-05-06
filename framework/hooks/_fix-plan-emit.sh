#!/bin/bash
# _fix-plan-emit.sh — Shared fix-plan generator (R5-014).
#
# Hook type: Library — Sourced
#
# Purpose
#   Every blocking guard (path-, destructive-, workflow-, quarantine-,
#   schema-drift-, phantom-check-, post-write-, circuit-breaker-) must,
#   on exit 2, write a structured `.apex/FIX_PLAN.md` so the user has a
#   concrete next action — not a stack of stderr lines. This file
#   centralizes that contract: one helper, one format, one path.
#
# Spec anchor
#   "Failure produces a fix plan, never a 'go debug it'."
#
# Predecessor / lineage
#   R5-005 (circuit-breaker.sh) wrote `.apex/RECOVERY_MENU.md` inline.
#   R5-014 generalizes that prototype: every blocking guard sources
#   this helper and calls `emit_fix_plan` with its specific reason and
#   recommended commands. circuit-breaker.sh is refactored to use the
#   shared helper too. RECOVERY_MENU.md is preserved as a backward-compat
#   alias path written alongside FIX_PLAN.md (recover.md still reads it).
#
# Usage
#   From a hook (canonical pattern, sourced):
#     # shellcheck source=/dev/null
#     source "$(dirname "$0")/_fix-plan-emit.sh"
#     emit_fix_plan \
#       "<source-name>" \
#       "<one-line reason>" \
#       "<context line — what was being attempted>" \
#       "<command 1> -- <one-line description>" \
#       "<command 2> -- <one-line description>" \
#       ...
#
#   The "<command N> -- <description>" pairs become the "Recommended
#   commands" bullets. Pass at least one. The first command is the
#   recommended default.
#
# Format written to .apex/FIX_PLAN.md:
#   # Fix Plan
#
#   ## Reason
#   <reason>
#
#   ## Context
#   - **Source:** <source-name>
#   - **Detected at:** <ISO 8601 UTC timestamp>
#   - **Attempted action:** <context>
#
#   ## Recommended commands
#   - `<command 1>` — <description 1>
#   - `<command 2>` — <description 2>
#   ...
#
#   ## How to undo
#   - Run `git status` then `git checkout -- <file>` to revert any unintended changes.
#   - Run `/apex:rollback` to revert to the last green tag.
#
# Backward compat
#   When the caller is `circuit-breaker.sh` (or any future caller that
#   wants the legacy alias), pass `--also-write-recovery-menu` as the
#   FIRST argument to mirror the file at `.apex/RECOVERY_MENU.md`. The
#   alias path is what `/apex:recover` historically read; keeping it in
#   place preserves the W1 contract.
#
# Failure mode
#   This helper is best-effort: if `.apex/` is unwritable (read-only FS,
#   missing directory, sandbox), the helper logs to stderr and returns
#   non-zero, but the caller's exit-2 path is unchanged. The detection
#   logic in each guard is the load-bearing part; the fix-plan write is
#   adjunct.

apex_fix_plan_path() {
  # Resolution order:
  #   1. APEX_FIX_PLAN_FILE env var (explicit override; used by tests).
  #   2. <repo-root>/.apex/FIX_PLAN.md when inside a git repo.
  #   3. ./.apex/FIX_PLAN.md fallback.
  if [ -n "${APEX_FIX_PLAN_FILE:-}" ]; then
    echo "$APEX_FIX_PLAN_FILE"
    return 0
  fi
  if command -v git >/dev/null 2>&1; then
    local root
    if root=$(git rev-parse --show-toplevel 2>/dev/null); then
      echo "$root/.apex/FIX_PLAN.md"
      return 0
    fi
  fi
  echo "./.apex/FIX_PLAN.md"
}

apex_recovery_menu_path() {
  # Sibling alias path for the W1 RECOVERY_MENU.md contract.
  if [ -n "${APEX_RECOVERY_MENU_FILE:-}" ]; then
    echo "$APEX_RECOVERY_MENU_FILE"
    return 0
  fi
  if command -v git >/dev/null 2>&1; then
    local root
    if root=$(git rev-parse --show-toplevel 2>/dev/null); then
      echo "$root/.apex/RECOVERY_MENU.md"
      return 0
    fi
  fi
  echo "./.apex/RECOVERY_MENU.md"
}

emit_fix_plan() {
  local also_recovery=0
  if [ "${1:-}" = "--also-write-recovery-menu" ]; then
    also_recovery=1
    shift
  fi

  local source_name="${1:-unknown}"
  local reason="${2:-}"
  local context="${3:-}"
  shift 3 2>/dev/null || true

  if [ -z "$reason" ]; then
    echo "🚫 emit_fix_plan: reason is required" >&2
    return 2
  fi

  local target
  target=$(apex_fix_plan_path)
  local target_dir
  target_dir=$(dirname "$target")

  if ! mkdir -p "$target_dir" 2>/dev/null; then
    echo "🚫 emit_fix_plan: cannot create $target_dir" >&2
    return 1
  fi

  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date 2>/dev/null || echo "unknown")

  # Build the fix-plan body in a single heredoc, then dispatch to the
  # one (or two) target paths. Recommended-command bullets are emitted
  # in a loop so we keep the writer simple and append-deterministic.
  {
    echo "# Fix Plan"
    echo ""
    echo "## Reason"
    echo "$reason"
    echo ""
    echo "## Context"
    echo "- **Source:** $source_name"
    echo "- **Detected at:** $now"
    if [ -n "$context" ]; then
      echo "- **Attempted action:** $context"
    fi
    echo ""
    echo "## Recommended commands"
    if [ "$#" -eq 0 ]; then
      # Defensive default: every fix plan must give the user at least
      # one actionable command, even if the caller forgot to pass one.
      echo "- \`/apex:forensics\` — diagnose what happened"
      echo "- \`/apex:rollback\` — revert to the last known-good state"
      echo "- \`/apex:recover\` — reset and re-plan from a clean slate"
    else
      local pair cmd desc
      for pair in "$@"; do
        # Split on the first " -- " separator. Bash parameter expansion
        # is portable here; no awk/sed needed for this trivial split.
        if [[ "$pair" == *" -- "* ]]; then
          cmd="${pair%% -- *}"
          desc="${pair#* -- }"
          echo "- \`$cmd\` — $desc"
        else
          # No description — emit just the command.
          echo "- \`$pair\`"
        fi
      done
    fi
    echo ""
    echo "## How to undo"
    echo "- Run \`git status\` then \`git checkout -- <file>\` to revert any unintended changes."
    echo "- Run \`/apex:rollback\` to revert to the last green tag."
  } > "$target" 2>/dev/null || {
    echo "🚫 emit_fix_plan: write to $target failed" >&2
    return 1
  }

  # Backward-compat alias for circuit-breaker.sh and any other caller
  # that still wants RECOVERY_MENU.md at the W1 path. Same content,
  # different filename.
  if [ "$also_recovery" -eq 1 ]; then
    local recovery_path
    recovery_path=$(apex_recovery_menu_path)
    cp "$target" "$recovery_path" 2>/dev/null || {
      echo "⚠️ emit_fix_plan: could not mirror to $recovery_path (continuing)" >&2
    }
  fi

  return 0
}

# Subcommand form — only fires when this file is executed (not sourced).
# Usage: bash _fix-plan-emit.sh <source> <reason> <context> [<cmd -- desc>]...
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  emit_fix_plan "$@"
fi
