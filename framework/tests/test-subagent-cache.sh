#!/usr/bin/env bash
# R-DH-P7-03: subagent cache staleness probe.
#
# Closes L-DH-03 — Subagent-cache contamination methodology confound
# (detector-review/FINAL-CERTIFICATION.md §3 L-DH-03).
#
# Mechanism: parse sync-to-claude.sh's agent-delivery declarations
# (copy_tree for framework/agents/, copy_modules_specialists for
# framework/modules/apex-*/agent.md). For each declared destination,
# assert:
#   (1) install copy exists at expected path,
#   (2) `diff -q src dst` returns 0 (byte-equality), AND
#   (3) `[ src -nt dst ]` is FALSE (source NOT newer than dest —
#       catches the post-sync edit staleness pattern that
#       byte-equality alone would miss in the sync-then-edit CI path).
#
# Pre-flight SKIP: if ~/.claude/agents/ is absent (first-run before
# sync-to-claude.sh has ever executed), skip with a SKIP message.
#
# Design: audit-trail-review/PHASE-7-RITEM-R-DH-P7-03-DESIGN-R2.md
# Critic R2 PASS: audit-trail-review/PHASE-7-RITEM-R-DH-P7-03-CRITIC-R2.md

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FRAMEWORK_ROOT="$REPO_ROOT/framework"
CLAUDE_ROOT="$HOME/.claude"
SYNC_SH="$FRAMEWORK_ROOT/scripts/sync-to-claude.sh"

PASS=0
FAIL=0
SKIPPED=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
nope() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }
skip() { echo "  SKIP: $1"; SKIPPED=$((SKIPPED+1)); }

echo "=== R-DH-P7-03: subagent cache staleness probe ==="

# Pre-flight SKIP gate
if [ ! -d "$CLAUDE_ROOT/agents" ]; then
  skip "0a: ~/.claude/agents/ not present — first-run before sync"
  echo "── $PASS/$((PASS+FAIL)) passed (skipped: $SKIPPED)"
  exit 0
fi

if [ ! -f "$SYNC_SH" ]; then
  nope "0b: sync-to-claude.sh missing — cannot enumerate delivery"
  echo "── $PASS/$((PASS+FAIL)) passed (skipped: $SKIPPED)"
  exit 1
fi

ok "0a: ~/.claude/agents/ present"
ok "0b: sync-to-claude.sh present"

# Loop 1: every framework/agents/**/*.md (core + pre-flattened specialists)
while IFS= read -r src; do
  rel="${src#$FRAMEWORK_ROOT/}"
  dst="$CLAUDE_ROOT/${rel}"
  if [ ! -f "$dst" ]; then
    nope "$rel: install copy missing at $dst"
    continue
  fi
  if ! diff -q "$src" "$dst" >/dev/null 2>&1; then
    nope "$rel: byte-equality FAIL — source != install (cache stale)"
    continue
  fi
  if [ "$src" -nt "$dst" ]; then
    nope "$rel: mtime FAIL — source newer than install (post-sync edit; fresh-session required)"
    continue
  fi
  ok "$rel: synced + non-stale"
done < <(find "$FRAMEWORK_ROOT/agents" -type f -name '*.md' 2>/dev/null)

# Loop 2: flattened-specialists from modules/apex-*/agent.md
while IFS= read -r mod_dir; do
  mod_name="$(basename "$mod_dir")"
  case "$mod_name" in _*) continue ;; esac
  agent_src="$mod_dir/agent.md"
  [ -f "$agent_src" ] || continue
  short_name="${mod_name#apex-}"
  dst="$CLAUDE_ROOT/agents/specialist/${short_name}.md"
  rel="modules/$mod_name/agent.md → specialist/$short_name.md"
  if [ ! -f "$dst" ]; then
    nope "$rel: install copy missing"
    continue
  fi
  if ! diff -q "$agent_src" "$dst" >/dev/null 2>&1; then
    nope "$rel: byte-equality FAIL (specialist stale)"
    continue
  fi
  if [ "$agent_src" -nt "$dst" ]; then
    nope "$rel: mtime FAIL (source newer than install)"
    continue
  fi
  ok "$rel: synced + non-stale"
done < <(find "$FRAMEWORK_ROOT/modules" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

echo
echo "── $PASS/$((PASS+FAIL)) passed (skipped: $SKIPPED)"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
