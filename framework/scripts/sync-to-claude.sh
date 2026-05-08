#!/usr/bin/env bash
# sync-to-claude.sh — Copy framework/ APEX files to ~/.claude/
#
# Adapter context (R5-025)
#   This is the canonical (Claude Code) sync. The contract every
#   APEX adapter implements is documented in
#   framework/adapters/adapter-contract.md. The Claude Code manifest
#   sits at framework/adapters/claude-code/adapter.json. Alternative
#   platforms ship their own sync script (e.g.
#   framework/scripts/sync-to-cursor.sh for Cursor). This script's
#   body logic is unchanged by R5-025 — only this comment block was
#   added.
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
# R8-003: deliver the modules tree (registry + per-module manifest +
# schema + agent.md) to ~/.claude/modules/ so agent-lint.sh and
# /apex:new-agent can resolve the manifest schema and registry on a
# ~/.claude/-only install (no framework checkout). The flatten above
# stays — it is the dispatcher contract; this tree-walk is the
# lint/registry contract. Two delivery paths, one source of truth.
# Spec anchors: "Module Ecosystem כ-Extension Model" + "Platform, Not
# Tool. ... Users must be able to create specialists we didn't
# anticipate."
copy_tree "$FRAMEWORK_ROOT/modules"       "$CLAUDE_ROOT/modules"
copy_tree "$FRAMEWORK_ROOT/commands/apex" "$CLAUDE_ROOT/commands/apex"
copy_tree "$FRAMEWORK_ROOT/hooks"         "$CLAUDE_ROOT/hooks"
# R5-002: explicit delivery anchor for the opt-in SQLite mirror helper. The
# copy_tree call above already covers it, but the explicit line documents
# the contract: _state-sqlite.sh is part of the canonical install.
copy_file "$FRAMEWORK_ROOT/hooks/_state-sqlite.sh" "$CLAUDE_ROOT/hooks/_state-sqlite.sh"
# R5-003: explicit delivery anchors for the dual-runtime security stack.
# copy_tree above walks `find -type f` so it already covers .cjs, but the
# explicit lines below document the contract: the spec-named CommonJS
# files (apex-prompt-guard.cjs, apex-workflow-guard.cjs, security.cjs;
# R6-014 added the `apex-` prefix to match the spec literal naming) are
# part of the canonical install and must reach ~/.claude/hooks/ alongside
# the .sh shims so settings.json's runtime-aware dispatch resolves to a
# real file.
copy_file "$FRAMEWORK_ROOT/hooks/apex-prompt-guard.cjs"   "$CLAUDE_ROOT/hooks/apex-prompt-guard.cjs"
copy_file "$FRAMEWORK_ROOT/hooks/apex-workflow-guard.cjs" "$CLAUDE_ROOT/hooks/apex-workflow-guard.cjs"
copy_file "$FRAMEWORK_ROOT/hooks/security.cjs"            "$CLAUDE_ROOT/hooks/security.cjs"
# R5-009: explicit delivery anchor for the agent-dispatch helper. The
# copy_tree call above already covers it, but the explicit line documents
# the contract: _agent-dispatch.sh is the structural enforcement point
# for the auditor quarantine (and any future agent-quarantined dispatch).
# Every command that invokes auditor sources this file.
copy_file "$FRAMEWORK_ROOT/hooks/_agent-dispatch.sh" "$CLAUDE_ROOT/hooks/_agent-dispatch.sh"
# R5-019: explicit delivery anchor for the Living Evidence Counter
# emitter. The copy_tree call above already covers it, but the
# explicit line documents the contract: _learnings-emit.sh is sourced
# by phase-tag.sh, phantom-check.sh, the critic agent, and the
# test-architect agent so writes to apex-learnings.md happen at every
# spec'd event-emitting site.
copy_file "$FRAMEWORK_ROOT/hooks/_learnings-emit.sh" "$CLAUDE_ROOT/hooks/_learnings-emit.sh"
# R5-014: explicit delivery anchor for the shared fix-plan emitter.
# The copy_tree call above already covers it, but the explicit line
# documents the contract: _fix-plan-emit.sh is sourced by every
# blocking guard (path-, destructive-, workflow-, quarantine-,
# schema-drift-, phantom-check-, post-write-, circuit-breaker-) so
# every exit-2 path produces a structured `.apex/FIX_PLAN.md`. Spec
# anchor: "Failure produces a fix plan, never a 'go debug it'."
copy_file "$FRAMEWORK_ROOT/hooks/_fix-plan-emit.sh" "$CLAUDE_ROOT/hooks/_fix-plan-emit.sh"
# R5-021: explicit delivery anchor for the agent-lint validator. The
# copy_tree call above already covers it, but the explicit line
# documents the contract: agent-lint.sh is invoked by /apex:new-agent
# (and by community authors directly) to validate a scaffolded module
# against the manifest schema + agent.md frontmatter contract before
# the module is registered or delivered.
copy_file "$FRAMEWORK_ROOT/hooks/agent-lint.sh" "$CLAUDE_ROOT/hooks/agent-lint.sh"
# R5-013: explicit delivery anchor for the one-file-one-owner guard.
# The copy_tree call above already covers it, but the explicit line
# documents the contract: owner-guard.sh is wired in settings.json as
# PreToolUse Write|Edit and reads .apex/phases/<phase>/WAVE_MAP.json
# at runtime, so it must reach ~/.claude/hooks/ before the live
# settings.json invokes it.
copy_file "$FRAMEWORK_ROOT/hooks/owner-guard.sh" "$CLAUDE_ROOT/hooks/owner-guard.sh"
# R5-016: explicit delivery anchor for the time-cadence decision gate.
# The copy_tree call above already covers it, but the explicit line
# documents the contract: decision-gate.sh is invoked by /apex:next at
# the top of each cycle and reads STATE.json elapsed/last-gate fields
# to fire the user-visible 60/90-minute checkpoint.
copy_file "$FRAMEWORK_ROOT/hooks/decision-gate.sh" "$CLAUDE_ROOT/hooks/decision-gate.sh"
# R5-003: the .cjs guards load detection patterns from the test-fixtures
# tree at runtime. The copy_tree call below covers it, but the explicit
# anchor documents the contract: the security-patterns fixture is a
# runtime dependency, not just a test artifact.
copy_file "$FRAMEWORK_ROOT/test-fixtures/security-patterns.json" "$CLAUDE_ROOT/test-fixtures/security-patterns.json"
copy_tree "$FRAMEWORK_ROOT/apex-skills"   "$CLAUDE_ROOT/apex-skills"
# R8-001: deliver the apex-workflows recipe library — _index.json + 30+
# recipe .md files consumed at runtime by /apex:workflow. Sibling to
# apex-skills tree-walk above. Spec anchor: "apex-workflows/ כ-library
# of pre-built recipes" + "30+ מתכונים מוכנים".
copy_tree "$FRAMEWORK_ROOT/apex-workflows" "$CLAUDE_ROOT/apex-workflows"
copy_tree "$FRAMEWORK_ROOT/schemas"       "$CLAUDE_ROOT/schemas"
copy_tree "$FRAMEWORK_ROOT/tests"           "$CLAUDE_ROOT/tests"
copy_tree "$FRAMEWORK_ROOT/test-fixtures"   "$CLAUDE_ROOT/test-fixtures"
# R7-003: total tree-walk delivery for framework/docs/. Replaces the
# per-doc copy_file anchor pattern that failed to scale across
# R5/R6 — every new doc had to be remembered by the maintainer, and
# discipline failed twice (F-003 in R7). The tree walk subsumes the
# two existing per-doc anchors below (kept commented for traceability,
# safe because copy_file is idempotent if a destination is overwritten
# with identical content). Coverage asserted by
# framework/tests/test-sync-doc-coverage.sh — file-count equality.
copy_tree "$FRAMEWORK_ROOT/docs"          "$CLAUDE_ROOT/docs"

# R6-002 (subsumed by R7-003 tree walk above; kept as comment for
# traceability): the MODULE-ECOSYSTEM.md doc closes the literal-wording
# residue surfaced by F-002 and is referenced by `_registry.json`'s
# description text. The R7-003 tree walk above delivers it.
# copy_file "$FRAMEWORK_ROOT/docs/MODULE-ECOSYSTEM.md" "$CLAUDE_ROOT/docs/MODULE-ECOSYSTEM.md"
# R6-010 (subsumed by R7-003 tree walk above; kept as comment for
# traceability): the OWNS-FILES-CONTRACT.md doc is the single source of
# truth for `owns_files` semantics. The R7-003 tree walk above delivers it.
# copy_file "$FRAMEWORK_ROOT/docs/OWNS-FILES-CONTRACT.md" "$CLAUDE_ROOT/docs/OWNS-FILES-CONTRACT.md"
# R6-011: explicit delivery anchor for the frozen STATE.json init
# template consumed by state-rebuild.sh as the schema-complete base
# before overlaying event-log-derived semantic-event fields. The
# template MUST mirror the init block in framework/commands/apex/start.md;
# drift is detected by framework/tests/test-state-rebuild.sh strict-schema
# validation.
copy_file "$FRAMEWORK_ROOT/templates/STATE-init.template.json" "$CLAUDE_ROOT/templates/STATE-init.template.json"
# R6-017: explicit delivery anchor for the active-adapter detection
# helper. The copy_tree call above already covers it (under hooks/), but
# the explicit line documents the contract: _adapter-detect.sh is sourced
# (or invoked as `bash ... active`) by /apex:start and /apex:onboard at
# the ADAPTER HONESTY BANNER block to read the active adapter's manifest.
# Three-places contract: framework/hooks/, ~/.claude/hooks/, and
# framework/HOOK-CLASSIFICATION.md.
copy_file "$FRAMEWORK_ROOT/hooks/_adapter-detect.sh" "$CLAUDE_ROOT/hooks/_adapter-detect.sh"
# R6-017: deliver the adapter manifest tree so the runtime banner block
# in /apex:start and /apex:onboard can read .hook_protocol.supported,
# .deferred, and .display_name from the active adapter's manifest. The
# manifests live under framework/adapters/<name>/adapter.json; without
# this delivery the runtime banner cannot resolve manifest data and
# silently degrades to "no banner" — defeating the runtime-honesty
# contract. Spec anchors: "Multi-platform from day one." + "Honestly
# Scoped, Not Universally Promised."
copy_tree "$FRAMEWORK_ROOT/adapters" "$CLAUDE_ROOT/adapters"

# Top-level files
copy_file "$FRAMEWORK_ROOT/apex-branding.md"        "$CLAUDE_ROOT/apex-branding.md"
copy_file "$FRAMEWORK_ROOT/apex-design-notes.md"    "$CLAUDE_ROOT/apex-design-notes.md"
copy_file "$FRAMEWORK_ROOT/apex-learnings.md"       "$CLAUDE_ROOT/apex-learnings.md"
copy_file "$FRAMEWORK_ROOT/apex-model-routing.json" "$CLAUDE_ROOT/apex-model-routing.json"
# R9-006: standalone session-timeline reconstruction tool. Failure 1
# treatment names "Standalone debugging discipline דרך __main__.py";
# the script must be reachable from the install root so users can
# invoke it (`python ~/.claude/apex-debug.py ...`) when /apex:forensics
# cannot run inside Claude. Spec anchor: Standalone debugging
# discipline + /apex:forensics.
copy_file "$FRAMEWORK_ROOT/apex-debug.py"           "$CLAUDE_ROOT/apex-debug.py"
# R9-001: bootstrap templates for /apex:start (Two-Tier Methodology) and
# threat-model-bootstrap. Consumers cite these by stable absolute path
# (~/.claude/<name>); preserve the top-level layout — do not move under
# a templates/ subdir.
copy_file "$FRAMEWORK_ROOT/APEX-TEMPLATE.md"          "$CLAUDE_ROOT/APEX-TEMPLATE.md"
copy_file "$FRAMEWORK_ROOT/PROJECT-APEX-TEMPLATE.md"  "$CLAUDE_ROOT/PROJECT-APEX-TEMPLATE.md"
copy_file "$FRAMEWORK_ROOT/THREAT_MODEL-TEMPLATE.md"  "$CLAUDE_ROOT/THREAT_MODEL-TEMPLATE.md"
copy_file "$FRAMEWORK_ROOT/CONTEXT_BUDGET.default.json" "$CLAUDE_ROOT/CONTEXT_BUDGET.default.json"
copy_file "$FRAMEWORK_ROOT/scripts/self-test.sh"      "$CLAUDE_ROOT/scripts/self-test.sh"
copy_file "$FRAMEWORK_ROOT/scripts/validate-state.sh" "$CLAUDE_ROOT/scripts/validate-state.sh"
# v7.1 Auto-Continuity Layer D — optional Windows external watchdog. Always
# copied to ~/.claude/scripts/; activation is opt-in via install-watchdog.ps1.
copy_file "$FRAMEWORK_ROOT/scripts/apex-watchdog.ps1"     "$CLAUDE_ROOT/scripts/apex-watchdog.ps1"
copy_file "$FRAMEWORK_ROOT/scripts/install-watchdog.ps1"  "$CLAUDE_ROOT/scripts/install-watchdog.ps1"
copy_file "$FRAMEWORK_ROOT/scripts/README-watchdog.md"    "$CLAUDE_ROOT/scripts/README-watchdog.md"
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
  # R8-003: `modules` added so the registry, manifest schema, and per-
  # module README/agent.md/manifest.json files delivered by the new
  # `copy_tree modules` line above are not flagged as orphans by --clean.
  for dir in agents commands/apex hooks apex-skills apex-workflows modules schemas tests test-fixtures; do
    if [ -d "$FRAMEWORK_ROOT/$dir" ]; then
      find "$FRAMEWORK_ROOT/$dir" -type f -print0 | while IFS= read -r -d '' f; do
        echo "${f#$FRAMEWORK_ROOT/}" >> "$EXPECTED_FILES"
      done
    fi
  done
  # R10-003 (F-104): mirror copy_modules_specialists' flatten-path
  # delivery into EXPECTED_FILES. The directory-tree loop above only
  # captures source-tree paths, but copy_modules_specialists synthesizes
  # destination paths at agents/specialist/<short>.md (where <short> is
  # the module name with the leading 'apex-' stripped — see line 112).
  # Without this sibling loop, those 6 active flatten outputs surface as
  # orphan candidates in --clean mode, which is a false-positive class
  # that risks user-driven self-deletion. The derivation rule MUST mirror
  # copy_modules_specialists exactly; re-deriving differently would
  # silently un-cover or over-cover.
  if [ -d "$FRAMEWORK_ROOT/modules" ]; then
    for mod_dir in "$FRAMEWORK_ROOT"/modules/*/; do
      [ -d "$mod_dir" ] || continue
      mod_name="$(basename "$mod_dir")"
      case "$mod_name" in
        _*) continue ;;
      esac
      [ -f "$mod_dir/agent.md" ] || continue
      short_name="${mod_name#apex-}"
      echo "agents/specialist/${short_name}.md" >> "$EXPECTED_FILES"
    done
  fi
  # Top-level files
  echo "apex-branding.md" >> "$EXPECTED_FILES"
  echo "apex-design-notes.md" >> "$EXPECTED_FILES"
  echo "apex-learnings.md" >> "$EXPECTED_FILES"
  echo "apex-model-routing.json" >> "$EXPECTED_FILES"
  # R9-006: standalone debugging tool lands at install root and must
  # not appear as orphan to --clean.
  echo "apex-debug.py" >> "$EXPECTED_FILES"
  # R9-001: templates land at install root and must not appear as orphans.
  echo "APEX-TEMPLATE.md" >> "$EXPECTED_FILES"
  echo "PROJECT-APEX-TEMPLATE.md" >> "$EXPECTED_FILES"
  echo "THREAT_MODEL-TEMPLATE.md" >> "$EXPECTED_FILES"
  echo "scripts/self-test.sh" >> "$EXPECTED_FILES"
  echo "scripts/validate-state.sh" >> "$EXPECTED_FILES"
  echo "scripts/apex-watchdog.ps1" >> "$EXPECTED_FILES"
  echo "scripts/install-watchdog.ps1" >> "$EXPECTED_FILES"
  echo "scripts/README-watchdog.md" >> "$EXPECTED_FILES"
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
    # R10-004 (F-106): per-orphan classification tag.
    #
    # Each orphan is annotated at print time with one of three tags so a
    # non-technical user can triage without understanding APEX rename
    # history:
    #   [flatten]       — agents/specialist/*.md path. Defensive tag:
    #                     after R10-003, the EXPECTED_FILES builder
    #                     flattens these and they should NOT surface.
    #                     If this tag ever fires on a real install, the
    #                     EXPECTED_FILES builder has regressed.
    #   [legacy-rename] — known historical residue from R6-014's hook
    #                     rename (hooks/prompt-guard.cjs and
    #                     hooks/workflow-guard.cjs). Safe to delete.
    #   [unknown]       — any other path. Investigate before deleting.
    #
    # The tag is print-only. The deletion loop below continues to use
    # $orphan (the rel-path), NEVER the annotated print line.
    for orphan in "${ORPHANS[@]}"; do
      case "$orphan" in
        agents/specialist/*.md)
          tag="[flatten]"
          ;;
        hooks/prompt-guard.cjs|hooks/workflow-guard.cjs)
          tag="[legacy-rename]"
          ;;
        *)
          tag="[unknown]"
          ;;
      esac
      echo "  🗑️  $tag $CLAUDE_ROOT/$orphan"
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
