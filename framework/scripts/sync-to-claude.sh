#!/usr/bin/env bash
# sync-to-claude.sh — Copy framework/ APEX files to ~/.claude/
#
# Purpose
#   Deploy changes from the framework/ source-of-truth tree to the live
#   ~/.claude/ installation. Run after editing framework/ and testing
#   changes in a Claude Code session.
#
# Usage
#   bash framework/scripts/sync-to-claude.sh            # perform sync
#   bash framework/scripts/sync-to-claude.sh --dry-run  # preview only
#   bash framework/scripts/sync-to-claude.sh --clean    # detect orphaned APEX files in ~/.claude/
#
# Safety guarantees
#   - Additive only by default — never deletes files from ~/.claude/
#   - --clean mode detects orphans but only deletes with user confirmation
#   - Scoped to APEX — non-APEX files (GSD agents, user hooks,
#     settings.json) are never touched
#   - Only copies files that exist under framework/
#   - Creates destination directories if missing, never removes them

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_ROOT="$HOME/.claude"

DRY_RUN=0
CLEAN_MODE=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
elif [[ "${1:-}" == "--clean" ]]; then
  CLEAN_MODE=1
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
copy_tree "$FRAMEWORK_ROOT/commands/apex" "$CLAUDE_ROOT/commands/apex"
copy_tree "$FRAMEWORK_ROOT/hooks"         "$CLAUDE_ROOT/hooks"
copy_tree "$FRAMEWORK_ROOT/apex-skills"   "$CLAUDE_ROOT/apex-skills"
copy_tree "$FRAMEWORK_ROOT/schemas"       "$CLAUDE_ROOT/schemas"
copy_tree "$FRAMEWORK_ROOT/tests"           "$CLAUDE_ROOT/tests"
copy_tree "$FRAMEWORK_ROOT/test-fixtures"   "$CLAUDE_ROOT/test-fixtures"

# Top-level files
copy_file "$FRAMEWORK_ROOT/apex-branding.md"        "$CLAUDE_ROOT/apex-branding.md"
copy_file "$FRAMEWORK_ROOT/apex-design-notes.md"    "$CLAUDE_ROOT/apex-design-notes.md"
copy_file "$FRAMEWORK_ROOT/apex-learnings.md"       "$CLAUDE_ROOT/apex-learnings.md"
copy_file "$FRAMEWORK_ROOT/apex-model-routing.json" "$CLAUDE_ROOT/apex-model-routing.json"
copy_file "$FRAMEWORK_ROOT/scripts/self-test.sh"      "$CLAUDE_ROOT/scripts/self-test.sh"
copy_file "$FRAMEWORK_ROOT/scripts/validate-state.sh" "$CLAUDE_ROOT/scripts/validate-state.sh"
copy_file "$FRAMEWORK_ROOT/../CLAUDE-TEMPLATE.md"   "$CLAUDE_ROOT/CLAUDE-TEMPLATE.md"

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
