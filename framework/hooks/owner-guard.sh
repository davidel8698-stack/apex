#!/bin/bash
# owner-guard.sh — One-file-one-owner enforcement (R5-013).
#
# Hook type: Auto-PreToolUse (Write|Edit)
#
# Purpose
#   Prevents two parallel tasks within the same wave from writing the
#   same file. Spec anchors:
#     - "One-file-one-owner עם git worktree isolation"
#     - "Read-parallel, write-serial עם Vertical Slices Enforcement"
#
# Contract
#   - When APEX_CURRENT_TASK_ID is unset: fast-path exit 0. The guard
#     never blocks manual edits, ad-hoc shell writes, or any context
#     that has not opted into the owner-tracking dispatch (R5-013
#     ships advisory-by-default; the dispatch site that exports
#     APEX_CURRENT_TASK_ID is the authoritative opt-in).
#   - When APEX_CURRENT_TASK_ID is set:
#       Look up
#         .apex/phases/<current_phase>/WAVE_MAP.json
#       Find the task object (by id) inside the active wave and read
#       its owns_files[] list. If the targeted write path is in the
#       list (or owns_files is ["*"]), pass through (exit 0).
#       Otherwise emit a structured fix plan and exit:
#         - exit 1 (advisory) by default
#         - exit 2 (blocking) when APEX_OWNER_GUARD_BLOCKING=1
#       The HUMAN-DECISION flag in REMEDIATION-PLAN-R5.md §R5-013
#       defaults this guard to advisory mode so legitimate writes are
#       never blocked during the transition window.
#
# Schema source of truth
#   framework/schemas/WAVE_MAP.schema.json declares two task-entry
#   shapes:
#     1. legacy bare string task ID (no ownership info — pre-R5-013)
#     2. object form with `id` + optional `owns_files`
#   The legacy form is treated as "no ownership info" → advisory pass.
#
# Failure mode
#   Best-effort. If WAVE_MAP.json is missing, malformed, or jq is
#   unavailable, the guard exits 0 (does not block). Fail-loud only
#   when an explicit ownership violation is detected.
#
# Three-places contract (REMEDIATION-STYLE)
#   1. This file's `# Hook type:` header above.
#   2. framework/settings.json — PreToolUse Write|Edit entry.
#   3. framework/HOOK-CLASSIFICATION.md — Auto-PreToolUse table row.

set -u

# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_fix-plan-emit.sh" ]; then
  source "$(dirname "$0")/_fix-plan-emit.sh"
fi

# Fast-path: no task context → guard does not apply.
if [ -z "${APEX_CURRENT_TASK_ID:-}" ]; then
  exit 0
fi

# Resolve the path being written. Claude Code's PreToolUse Write|Edit
# invocation passes the target path as $1 in legacy hook form; the
# stdin JSON form (post-R-006 migration) carries it under
# .tool_input.file_path. Accept either.
#
# Phase 8 R-P8-C11: consolidate to shared input-extraction helper.
# Replaces the private argv+stdin extractor that previously lived here.
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi
FILEPATH=$(apex_hook_input_filepath "$@" 2>/dev/null || printf '%s' "${1:-}")

# Without a target path we cannot judge — pass through.
if [ -z "$FILEPATH" ]; then
  exit 0
fi

# Resolve repo root + the active WAVE_MAP.json. Bail out (exit 0) on
# anything that prevents a definitive ownership check.
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

REPO_ROOT=""
if command -v git >/dev/null 2>&1; then
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
fi
if [ -z "$REPO_ROOT" ]; then
  REPO_ROOT="$(pwd)"
fi

STATE_JSON="$REPO_ROOT/.apex/STATE.json"
if [ ! -f "$STATE_JSON" ]; then
  exit 0
fi

CURRENT_PHASE=$(jq -r '.current_phase // empty' "$STATE_JSON" 2>/dev/null || true)
if [ -z "$CURRENT_PHASE" ]; then
  exit 0
fi

CURRENT_WAVE=$(jq -r '.current_wave // empty' "$STATE_JSON" 2>/dev/null || true)
if [ -z "$CURRENT_WAVE" ]; then
  exit 0
fi

WAVE_MAP="$REPO_ROOT/.apex/phases/$CURRENT_PHASE/WAVE_MAP.json"
if [ ! -f "$WAVE_MAP" ]; then
  exit 0
fi

# Read the owns_files list for the active task in the active wave.
# Returns:
#   - "__LEGACY__"     when the task entry is a bare string (no info)
#   - "__MISSING__"    when the task object exists but lacks owns_files
#   - "__NOT_FOUND__"  when no task with this id is in this wave
#   - JSON-encoded array of strings otherwise
OWNS_FILES_JSON=$(jq -c --arg wave "$CURRENT_WAVE" --arg id "$APEX_CURRENT_TASK_ID" '
  (.waves // []) as $w
  | ([ $w[] | select((.wave_number|tostring) == $wave) ] | first) as $current
  | if $current == null then "__NOT_FOUND__"
    else
      ($current.tasks // []) as $tasks
      | ([ $tasks[]
            | select( (type == "string" and . == $id)
                      or (type == "object" and .id == $id) )
         ] | first) as $task
      | if $task == null then "__NOT_FOUND__"
        elif ($task | type) == "string" then "__LEGACY__"
        elif ($task.owns_files // null) == null then "__MISSING__"
        else $task.owns_files
        end
    end
' "$WAVE_MAP" 2>/dev/null || echo "__NOT_FOUND__")

# Advisory pass-through cases — we cannot definitively say the write
# is unauthorized, so do not block.
case "$OWNS_FILES_JSON" in
  '"__LEGACY__"'|'"__MISSING__"'|'"__NOT_FOUND__"'|'')
    exit 0
    ;;
esac

# Wildcard ownership: ["*"] means "this task owns everything in the
# wave" — sole-task waves opt out of gating this way.
if [ "$OWNS_FILES_JSON" = '["*"]' ]; then
  exit 0
fi

# Normalize the targeted write path to a repo-relative form so the
# match works regardless of caller-supplied absolute vs relative path.
REL_PATH="$FILEPATH"
case "$FILEPATH" in
  /*)
    if [ -n "$REPO_ROOT" ] && [ "${FILEPATH#$REPO_ROOT/}" != "$FILEPATH" ]; then
      REL_PATH="${FILEPATH#$REPO_ROOT/}"
    fi
    ;;
esac

# Check membership. We compare against both the literal owns_files
# entries and against the absolute form (REPO_ROOT/<entry>) so the
# planner can declare paths in whichever style is convenient. Glob
# patterns ("*", "src/**") are honored via shell case-glob matching.
OWNED=0
while IFS= read -r entry; do
  # Strip trailing CR (Windows / Git autocrlf) before comparing.
  entry="${entry%$'\r'}"
  [ -z "$entry" ] && continue
  if [ "$entry" = "*" ]; then
    OWNED=1; break
  fi
  # Literal match against the relative or absolute form.
  if [ "$entry" = "$REL_PATH" ] || [ "$entry" = "$FILEPATH" ]; then
    OWNED=1; break
  fi
  # Glob match (case-glob). Entries like "src/feature/**" or
  # "src/feature/*" are matched against the path as a shell pattern.
  # Note: Bash case-glob '*' does NOT cross '/' by default, so we
  # also accept "**" as an explicit recursive marker by translating
  # it to a leading-wildcard test.
  case "$REL_PATH" in
    $entry) OWNED=1; break ;;
  esac
  case "$FILEPATH" in
    $entry) OWNED=1; break ;;
  esac
  # Recursive glob fallback: pattern ends with "/**" or contains
  # "/**/" — accept any path under the prefix.
  case "$entry" in
    *'/**')
      prefix="${entry%/**}"
      case "$REL_PATH" in
        "$prefix"/*) OWNED=1; break ;;
      esac
      ;;
  esac
done < <(printf '%s' "$OWNS_FILES_JSON" | jq -r '.[]?' 2>/dev/null || true)

if [ "$OWNED" -eq 1 ]; then
  exit 0
fi

# === Ownership violation — emit fix plan and exit. ===
{
  echo "APEX OWNER GUARD: $APEX_CURRENT_TASK_ID does not own $REL_PATH" >&2
  echo "Wave $CURRENT_WAVE owns_files for $APEX_CURRENT_TASK_ID: $OWNS_FILES_JSON" >&2
  echo "Spec: One-file-one-owner. Re-route this write to the owning task or split the wave." >&2
} 2>/dev/null || true

if command -v emit_fix_plan >/dev/null 2>&1; then
  emit_fix_plan \
    "owner-guard" \
    "Owner-guard rejected a write because $APEX_CURRENT_TASK_ID does not own $REL_PATH in wave $CURRENT_WAVE." \
    "Attempted Write/Edit to: $FILEPATH (active task: $APEX_CURRENT_TASK_ID, owns_files: $OWNS_FILES_JSON)" \
    "/apex:plan-phase $CURRENT_PHASE -- re-plan so the writing task owns this file" \
    "/apex:rollback -- revert any partial edits to the last green tag" \
    "/apex:forensics -- diagnose how the task picked up an unowned write" \
    2>/dev/null || true
fi

# Advisory by default per the human-decision flag in
# REMEDIATION-PLAN-R5.md §R5-013. Set APEX_OWNER_GUARD_BLOCKING=1 to
# upgrade to a hard block (exit 2).
if [ "${APEX_OWNER_GUARD_BLOCKING:-0}" = "1" ]; then
  exit 2
fi
exit 1
