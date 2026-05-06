#!/usr/bin/env bash
# sync-to-cursor.sh — Adapter-driven sync from framework/ to a Cursor install (R5-025 stub).
#
# Purpose
#   Deliver APEX agents and commands into the Cursor-shaped tree. The
#   sync surface is constrained by framework/adapters/cursor/adapter.json
#   `delivers` field — initially `["agents", "commands"]`. Hooks and
#   apex-skills are deferred until Cursor exposes a comparable hook
#   primitive.
#
# Usage
#   bash framework/scripts/sync-to-cursor.sh                # perform sync
#   bash framework/scripts/sync-to-cursor.sh --dry-run      # preview only
#
# Spec anchor
#   "multi-agent framework ופלטפורמה לסוכני קוד … דרך thin adapters"
#   "Multi-platform from day one."
#
# Notes
#   - Stub status: this is the R5 commitment. Full feature parity with
#     Cursor's surfaces is a follow-up. The stub satisfies the brand
#     position by establishing the contract + a working agents/commands
#     delivery path.
#   - The script reads the adapter manifest for paths so that future
#     adjustments flow through one source of truth.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ADAPTER_JSON="$FRAMEWORK_ROOT/adapters/cursor/adapter.json"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

log() { printf '[sync-cursor] %s\n' "$*"; }

if [[ ! -f "$ADAPTER_JSON" ]]; then
  log "ERROR: adapter manifest missing at $ADAPTER_JSON"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  log "ERROR: jq not found — required to read adapter manifest"
  exit 1
fi

# Read paths from the adapter manifest. Tilde expansion is done in shell.
RAW_AGENTS=$(jq -r '.paths.agents // empty' "$ADAPTER_JSON")
RAW_COMMANDS=$(jq -r '.paths.commands // empty' "$ADAPTER_JSON")
DELIVERS=$(jq -r '.delivers // [] | join(",")' "$ADAPTER_JSON")
STATUS_FIELD=$(jq -r '.status // "stub"' "$ADAPTER_JSON")
HOOK_SUPPORT=$(jq -r '.hook_protocol.supported // "none"' "$ADAPTER_JSON")

expand_home() {
  local path="$1"
  case "$path" in
    "~"|"~/"*) printf '%s' "${path/#~/$HOME}" ;;
    *)         printf '%s' "$path" ;;
  esac
}

CURSOR_AGENTS=$(expand_home "$RAW_AGENTS")
CURSOR_COMMANDS=$(expand_home "$RAW_COMMANDS")

log "framework root: $FRAMEWORK_ROOT"
log "adapter manifest: $ADAPTER_JSON"
log "adapter status: $STATUS_FIELD"
log "hook support:   $HOOK_SUPPORT (deferred for Cursor — no PreToolUse/PostToolUse plane)"
log "delivers:       $DELIVERS"
if [[ $DRY_RUN -eq 1 ]]; then
  log "mode:           DRY RUN (no files will be written)"
else
  log "mode:           LIVE"
fi
echo

copy_file() {
  local src="$1"
  local dst="$2"
  if [[ ! -f "$src" ]]; then
    return
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] %s -> %s\n' "${src#$FRAMEWORK_ROOT/}" "$dst"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  printf '[sync-cursor] copied: %s\n' "$dst"
}

copy_tree() {
  local src_dir="$1"
  local dst_dir="$2"
  if [[ ! -d "$src_dir" ]]; then
    log "skip (missing dir): ${src_dir#$FRAMEWORK_ROOT/}"
    return
  fi
  if [[ -z "$dst_dir" ]]; then
    log "skip (no destination): ${src_dir#$FRAMEWORK_ROOT/}"
    return
  fi
  while IFS= read -r -d '' f; do
    local rel="${f#$src_dir/}"
    copy_file "$f" "$dst_dir/$rel"
  done < <(find "$src_dir" -type f -print0)
}

# Agents
if [[ ",$DELIVERS," == *",agents,"* ]]; then
  copy_tree "$FRAMEWORK_ROOT/agents" "$CURSOR_AGENTS"
else
  log "skip agents (not in delivers)"
fi

# Commands
if [[ ",$DELIVERS," == *",commands,"* ]]; then
  copy_tree "$FRAMEWORK_ROOT/commands/apex" "$CURSOR_COMMANDS"
else
  log "skip commands (not in delivers)"
fi

# Hooks: deferred for Cursor (no PreToolUse/PostToolUse plane).
if [[ ",$DELIVERS," == *",hooks,"* ]]; then
  log "WARNING: adapter declares hooks delivery but Cursor's hook plane is unmapped — skipping"
fi

# Skills: not yet delivered to Cursor.
if [[ ",$DELIVERS," == *",skills,"* ]]; then
  log "WARNING: adapter declares skills delivery — not implemented in this stub"
fi

echo
log "done — Cursor sync stub complete (status: $STATUS_FIELD)"
