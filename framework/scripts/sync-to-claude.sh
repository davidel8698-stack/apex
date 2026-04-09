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
#
# Safety guarantees
#   - Additive only — never deletes files from ~/.claude/
#   - Scoped to APEX — non-APEX files (GSD agents, user hooks,
#     settings.json) are never touched
#   - Only copies files that exist under framework/
#   - Creates destination directories if missing, never removes them

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_ROOT="$HOME/.claude"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
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

# Top-level files
copy_file "$FRAMEWORK_ROOT/apex-branding.md"        "$CLAUDE_ROOT/apex-branding.md"
copy_file "$FRAMEWORK_ROOT/apex-design-notes.md"    "$CLAUDE_ROOT/apex-design-notes.md"
copy_file "$FRAMEWORK_ROOT/apex-learnings.md"       "$CLAUDE_ROOT/apex-learnings.md"
copy_file "$FRAMEWORK_ROOT/apex-model-routing.json" "$CLAUDE_ROOT/apex-model-routing.json"

echo
log "done"
