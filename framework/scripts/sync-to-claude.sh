#!/usr/bin/env bash
# sync-to-claude.sh — Copy framework/ APEX files to ~/.claude/
#
# Purpose
#   Deploy changes from the framework/ source-of-truth tree to the live
#   ~/.claude/ installation. Run after editing framework/ and testing
#   changes in a Claude Code session.
#
# Usage
#   bash framework/scripts/sync-to-claude.sh                  # perform sync (incl. settings.json merge)
#   bash framework/scripts/sync-to-claude.sh --dry-run        # preview only (shows settings.json diff)
#   bash framework/scripts/sync-to-claude.sh --skip-settings  # sync files but do NOT touch settings.json
#   bash framework/scripts/sync-to-claude.sh --clean          # detect orphaned APEX files in ~/.claude/
#
# Safety guarantees
#   - Additive for file trees — never deletes files from ~/.claude/
#   - settings.json merge is surgical: only APEX hooks (commands containing
#     ~/.claude/hooks/) are replaced. User/GSD hooks, permissions, env,
#     theme, and any other settings.json keys are preserved.
#   - --skip-settings preserves the legacy "never touch settings.json" behavior
#   - --clean mode detects orphans but only deletes with user confirmation
#   - Scoped to APEX — non-APEX agent/hook files (GSD, user) are never touched

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_ROOT="$HOME/.claude"

DRY_RUN=0
CLEAN_MODE=0
SKIP_SETTINGS=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
elif [[ "${1:-}" == "--clean" ]]; then
  CLEAN_MODE=1
elif [[ "${1:-}" == "--skip-settings" ]]; then
  SKIP_SETTINGS=1
fi

log() { printf '[sync] %s\n' "$*"; }

copy_file() {
  local src="$1"
  local dst="$2"
  if [[ ! -f "$src" ]]; then
    return
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] %s -> %s\n' "${src#$FRAMEWORK_ROOT/}" "${dst#$CLAUDE_ROOT/}"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  printf '[sync] copied: %s\n' "${dst#$CLAUDE_ROOT/}"
}

copy_tree() {
  local src_dir="$1"
  local dst_dir="$2"
  if [[ ! -d "$src_dir" ]]; then
    log "skip (missing dir): ${src_dir#$FRAMEWORK_ROOT/}"
    return
  fi
  while IFS= read -r -d '' f; do
    local rel="${f#$src_dir/}"
    copy_file "$f" "$dst_dir/$rel"
  done < <(find "$src_dir" -type f -print0)
}

# copy_modules_specialists — Manifest-driven specialist delivery.
#
# Walks framework/modules/<name>/agent.md and copies each into the flat
# ~/.claude/agents/specialist/<short>.md, where <short> is the module name
# with the 'apex-' prefix stripped (apex-data -> data.md,
# apex-test-architect -> test-architect.md). This preserves the dispatcher
# contract: Task("data-specialist", ...) continues to resolve because Claude
# Code reads agent frontmatter `name` for routing, while the filename layout
# remains the pre-R5-001 flat shape that the runtime expects.
#
# Modules with no agent.md (stubs: apex-fintech, apex-healthcare, apex-builder,
# apex-core) are skipped silently — they contribute nothing to the live tree
# until promoted to active.
copy_modules_specialists() {
  local modules_root="$FRAMEWORK_ROOT/modules"
  local dst_dir="$CLAUDE_ROOT/agents/specialist"
  if [[ ! -d "$modules_root" ]]; then
    log "skip (missing dir): ${modules_root#$FRAMEWORK_ROOT/}"
    return
  fi
  local mod_dir mod_name short_name agent_src
  for mod_dir in "$modules_root"/*/; do
    [[ -d "$mod_dir" ]] || continue
    mod_name="$(basename "$mod_dir")"
    # Skip non-module entries (_schema, _registry.json sits at root not as a dir).
    case "$mod_name" in
      _*) continue ;;
    esac
    agent_src="$mod_dir/agent.md"
    [[ -f "$agent_src" ]] || continue
    # Strip leading 'apex-' to match the pre-migration flat-tree expectation.
    short_name="${mod_name#apex-}"
    copy_file "$agent_src" "$dst_dir/${short_name}.md"
  done
}

# merge_apex_hooks — Surgically replace APEX hook wirings in ~/.claude/settings.json.
#
# Claude Code's settings.json has a nested hooks structure:
#   .hooks.{PreToolUse,PostToolUse,PreCompact,SessionStart,...}[]
#     .matcher
#     .hooks[]
#       .type    (always "command")
#       .command (shell command string)
#
# An "APEX matcher group" is a .hooks.<event>[] entry where ALL its .hooks[]
# commands target ~/.claude/hooks/ (i.e. every command in the group is ours).
# All such groups are removed from the live settings and replaced with the
# groups from framework/settings.json.
#
# Non-APEX groups (user-authored, GSD, or mixed) are preserved byte-for-byte.
# Event types that APEX does not wire (PreCompact, SessionStart, etc.) are
# never touched.
#
# Top-level keys (permissions, env, statusLine, theme, ...) are preserved.
#
# If ~/.claude/settings.json does not exist, it is created as a copy of
# framework/settings.json.
#
# Idempotent: running twice produces the same result as running once.
merge_apex_hooks() {
  local src="$FRAMEWORK_ROOT/settings.json"
  local dst="$CLAUDE_ROOT/settings.json"

  if [[ ! -f "$src" ]]; then
    log "skip settings merge (missing framework/settings.json)"
    return
  fi

  if ! command -v jq >/dev/null 2>&1; then
    log "WARNING: jq not found — cannot merge settings.json safely. Skipping."
    log "         Install jq and re-run, or use --skip-settings if intentional."
    return
  fi

  mkdir -p "$CLAUDE_ROOT"

  # Bootstrap path: no existing settings.json → full copy.
  if [[ ! -f "$dst" ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] bootstrap: %s -> %s\n' "settings.json" "$dst"
      return
    fi
    cp "$src" "$dst"
    log "copied: settings.json (bootstrap — no prior file)"
    return
  fi

  # For each event type that APEX defines (PreToolUse, PostToolUse, ...):
  #   - drop live matcher groups where every command contains ~/.claude/hooks/
  #   - append APEX matcher groups from src
  # For event types APEX does not define: keep live as-is.
  # For top-level keys outside .hooks: keep live as-is.
  local merged
  merged=$(jq -s '
    .[0] as $u | .[1] as $a |
    ($a.hooks // {}) as $apex_hooks |
    $u
    | (.hooks //= {})
    | .hooks = (
        .hooks as $live |
        reduce ($apex_hooks | keys_unsorted[]) as $evt (
          $live;
          .[$evt] = (
            (($live[$evt] // []) | map(
              select(
                ((.hooks // []) | length) == 0
                or ((.hooks // []) | map((.command // "") | contains("~/.claude/hooks/")) | all | not)
              )
            ))
            + ($apex_hooks[$evt] // [])
          )
        )
      )
  ' "$dst" "$src")

  if [[ -z "$merged" ]]; then
    log "ERROR: settings merge produced empty output. Aborting settings update."
    return
  fi

  # Sanity: merged must be valid JSON and must preserve top-level keys.
  if ! echo "$merged" | jq . >/dev/null 2>&1; then
    log "ERROR: merged settings.json is not valid JSON. Aborting."
    return
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] settings.json merge preview (diff vs live):\n'
    diff <(jq -S . "$dst") <(echo "$merged" | jq -S .) || true
    printf '\n'
    return
  fi

  # Atomic write: temp file then mv
  local tmp="$dst.apex-merge.tmp"
  echo "$merged" | jq . > "$tmp"
  mv "$tmp" "$dst"
  log "merged: settings.json (APEX matcher groups updated; user/GSD groups and other keys preserved)"
}

log "framework root: $FRAMEWORK_ROOT"
log "claude root:    $CLAUDE_ROOT"
if [[ $DRY_RUN -eq 1 ]]; then
  log "mode:           DRY RUN (no changes will be made)"
else
  log "mode:           LIVE"
fi
echo

# Directory trees
copy_tree "$FRAMEWORK_ROOT/agents"        "$CLAUDE_ROOT/agents"
# R5-001: manifest-driven specialist delivery. Walks framework/modules/<name>/
# and delivers each agent.md into the flat live tree at
# ~/.claude/agents/specialist/<short>.md (apex- prefix stripped).
copy_modules_specialists
copy_tree "$FRAMEWORK_ROOT/commands/apex" "$CLAUDE_ROOT/commands/apex"
copy_tree "$FRAMEWORK_ROOT/hooks"         "$CLAUDE_ROOT/hooks"
# R5-002: explicit delivery anchor for the opt-in SQLite mirror helper. The
# copy_tree call above already covers it, but the explicit line documents
# the contract: _state-sqlite.sh is part of the canonical install.
copy_file "$FRAMEWORK_ROOT/hooks/_state-sqlite.sh" "$CLAUDE_ROOT/hooks/_state-sqlite.sh"
copy_tree "$FRAMEWORK_ROOT/apex-skills"   "$CLAUDE_ROOT/apex-skills"
copy_tree "$FRAMEWORK_ROOT/schemas"       "$CLAUDE_ROOT/schemas"
copy_tree "$FRAMEWORK_ROOT/tests"           "$CLAUDE_ROOT/tests"
copy_tree "$FRAMEWORK_ROOT/test-fixtures"   "$CLAUDE_ROOT/test-fixtures"

# Top-level files
copy_file "$FRAMEWORK_ROOT/apex-branding.md"        "$CLAUDE_ROOT/apex-branding.md"
copy_file "$FRAMEWORK_ROOT/apex-design-notes.md"    "$CLAUDE_ROOT/apex-design-notes.md"
copy_file "$FRAMEWORK_ROOT/apex-learnings.md"       "$CLAUDE_ROOT/apex-learnings.md"
copy_file "$FRAMEWORK_ROOT/apex-model-routing.json" "$CLAUDE_ROOT/apex-model-routing.json"
copy_file "$FRAMEWORK_ROOT/CONTEXT_BUDGET.default.json" "$CLAUDE_ROOT/CONTEXT_BUDGET.default.json"
copy_file "$FRAMEWORK_ROOT/scripts/self-test.sh"      "$CLAUDE_ROOT/scripts/self-test.sh"
copy_file "$FRAMEWORK_ROOT/scripts/validate-state.sh" "$CLAUDE_ROOT/scripts/validate-state.sh"
copy_file "$FRAMEWORK_ROOT/../CLAUDE-TEMPLATE.md"   "$CLAUDE_ROOT/CLAUDE-TEMPLATE.md"

# settings.json merge (surgical — preserves user/GSD hooks)
if [[ $SKIP_SETTINGS -eq 1 ]]; then
  log "skip settings.json (--skip-settings)"
elif [[ $CLEAN_MODE -ne 1 ]]; then
  merge_apex_hooks
fi

echo
log "done"

# --- Clean mode: detect orphaned APEX files in ~/.claude/ ---
if [[ $CLEAN_MODE -eq 1 ]]; then
  echo
  log "=== CLEAN MODE: scanning for orphaned APEX files ==="
  echo

  # Build list of all files that SHOULD exist (from framework source)
  EXPECTED_FILES=$(mktemp)
  # Directory trees
  for dir in agents commands/apex hooks apex-skills schemas tests test-fixtures; do
    if [ -d "$FRAMEWORK_ROOT/$dir" ]; then
      find "$FRAMEWORK_ROOT/$dir" -type f -print0 | while IFS= read -r -d '' f; do
        echo "${f#$FRAMEWORK_ROOT/}" >> "$EXPECTED_FILES"
      done
    fi
  done
  # Top-level files
  echo "apex-branding.md" >> "$EXPECTED_FILES"
  echo "apex-design-notes.md" >> "$EXPECTED_FILES"
  echo "apex-learnings.md" >> "$EXPECTED_FILES"
  echo "apex-model-routing.json" >> "$EXPECTED_FILES"
  echo "scripts/self-test.sh" >> "$EXPECTED_FILES"
  echo "scripts/validate-state.sh" >> "$EXPECTED_FILES"
  echo "CLAUDE-TEMPLATE.md" >> "$EXPECTED_FILES"

  # Scan deployed APEX directories for files NOT in the expected list
  ORPHANS=()
  for dir in agents/architect.md agents/critic.md agents/executor.md agents/planner.md agents/verifier.md \
             agents/specialist commands/apex hooks apex-skills schemas tests test-fixtures scripts; do
    deployed_dir="$CLAUDE_ROOT/$dir"
    [ -d "$deployed_dir" ] || continue
    while IFS= read -r -d '' deployed_file; do
      rel="${deployed_file#$CLAUDE_ROOT/}"
      if ! grep -qF "$rel" "$EXPECTED_FILES" 2>/dev/null; then
        # Skip non-APEX files (GSD agents, user hooks, etc.)
        case "$rel" in
          agents/gsd-*|hooks/gsd-*) continue ;;
        esac
        ORPHANS+=("$rel")
      fi
    done < <(find "$deployed_dir" -maxdepth 1 -type f -print0 2>/dev/null)
  done

  rm -f "$EXPECTED_FILES"

  if [ ${#ORPHANS[@]} -eq 0 ]; then
    log "No orphaned APEX files found. ~/.claude/ is clean."
  else
    log "Found ${#ORPHANS[@]} orphaned APEX file(s):"
    for orphan in "${ORPHANS[@]}"; do
      echo "  🗑️  $CLAUDE_ROOT/$orphan"
    done
    echo
    read -p "[clean] Delete these files? (y/N) " confirm
    if [[ "$confirm" == [yY] ]]; then
      for orphan in "${ORPHANS[@]}"; do
        rm -f "$CLAUDE_ROOT/$orphan"
        log "deleted: $orphan"
      done
      log "cleanup complete"
    else
      log "cleanup skipped (no files deleted)"
    fi
  fi
fi
