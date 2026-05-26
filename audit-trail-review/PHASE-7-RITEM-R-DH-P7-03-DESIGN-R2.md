# R-DH-P7-03 — Design R2 · BF-1/BF-2/BF-3 closure

**Supersedes:** `PHASE-7-RITEM-R-DH-P7-03-DESIGN.md` (R1).
**Critic R1 verdict:** `PHASE-7-RITEM-R-DH-P7-03-CRITIC-R1.md` — BLOCKING, 3 BFs.
**Date:** 2026-05-26.

R1 §1, §4-§7 carry forward. R2 rewrites §2 + §3 based on critic findings.

---

## §0. Critic R1 closure summary

| BF | Issue | R2 resolution |
|----|-------|---------------|
| **B-1** | Agent inventory wrong — `data/frontend/integration/security/memory-synthesis` are at `framework/modules/apex-*/agent.md`, NOT `framework/agents/specialist/`. Missing wave-executor + test-architect. | Test enumerates delivery dynamically by parsing `sync-to-claude.sh` `copy_tree` + `copy_modules_specialists` (mirrors R10-001 strategy used by `test-sync-coverage.sh`). |
| **B-2** | Core agents under `framework/agents/*.md` (13 files) omitted; same cache vulnerability. | Test iterates ALL `framework/agents/**/*.md` via the parsed `copy_tree "$FRAMEWORK_ROOT/agents"` declaration. |
| **B-3** | Test vacuous via sync-driven CI — sync-to-claude.sh produces install copies then runs run-all.sh, so byte-equality is trivially satisfied. | Test adds an mtime axis: `[ src -nt dst ]` MUST be FALSE (source NOT newer than install). Combined with byte-equality, this catches the "source edited after sync" staleness pattern. |

---

## §2. Design R2 (revised)

### Change A (REVISED per BF-1/BF-2/BF-3) — `framework/tests/test-subagent-cache.sh`

**Strategy:** mirror the R10-001 `test-sync-coverage.sh` pattern — parse `sync-to-claude.sh`'s own delivery declarations and iterate every emitted destination.

Test structure (~80 lines):

```bash
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
#       catches the post-edit staleness pattern that byte-equality
#       alone would miss in the sync-then-edit-then-test CI path).
#
# Pre-flight SKIP: if ~/.claude/agents/ is absent (first-run before
# sync-to-claude.sh has ever executed), skip with a SKIP message.

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
  skip "0: ~/.claude/agents/ not present — first-run before sync"
  echo "── $PASS/$((PASS+FAIL)) passed (skipped: $SKIPPED)"
  exit 0
fi

if [ ! -f "$SYNC_SH" ]; then
  nope "0: sync-to-claude.sh missing — cannot enumerate delivery"
  exit 1
fi

# Enumerate every framework/agents/**/*.md (covers both core + the
# pre-flattened specialists actually present in source tree)
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

# Enumerate flattened-specialists from modules
while IFS= read -r mod_dir; do
  mod_name="$(basename "$mod_dir")"
  case "$mod_name" in _*) continue ;; esac
  agent_src="$mod_dir/agent.md"
  [ -f "$agent_src" ] || continue
  short_name="${mod_name#apex-}"
  dst="$CLAUDE_ROOT/agents/specialist/${short_name}.md"
  if [ ! -f "$dst" ]; then
    nope "modules/$mod_name/agent.md → specialist/$short_name.md: install missing"
    continue
  fi
  if ! diff -q "$agent_src" "$dst" >/dev/null 2>&1; then
    nope "modules/$mod_name/agent.md: byte-equality FAIL (specialist stale)"
    continue
  fi
  if [ "$agent_src" -nt "$dst" ]; then
    nope "modules/$mod_name/agent.md: mtime FAIL (source newer than install)"
    continue
  fi
  ok "modules/$mod_name/agent.md → specialist/$short_name.md: synced + non-stale"
done < <(find "$FRAMEWORK_ROOT/modules" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

echo
echo "── $PASS/$((PASS+FAIL)) passed (skipped: $SKIPPED)"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
```

### Change B (unchanged) — `framework/docs/SECURITY-RUNTIME.md` append §"Subagent cache invalidation"

Same as R1 (the doc append is unchanged by the BF closures).

---

## §3. Blast radius (REVISED)

| File | Touched? | Lines | Consumers |
|------|---------:|------:|-----------|
| `framework/tests/test-subagent-cache.sh` | NEW | ~80 | run-all.sh CI run; framework-auditor regression gate |
| `framework/docs/SECURITY-RUNTIME.md` | MODIFIED (append) | +30 | Operators reading SECURITY-RUNTIME |
| `detector-review/FINAL-CERTIFICATION.md` §7 R-item 3 | MODIFIED (closure note) | +3 | Phase-7 closure tracking |
| `audit-trail-review/PHASE-7-MASTER-PLAN.md` §5 R-DH-P7-03 | MODIFIED (closure note) | +3 | Phase-7 closure tracking |

4 files.

---

## §5. G5 PASS criteria (REVISED)

1. ✅ test-subagent-cache.sh exists at `framework/tests/`, runs PASS in isolation.
2. ✅ Test enumerates ALL `framework/agents/**/*.md` (core + pre-flattened specialists) — count >= 13.
3. ✅ Test also enumerates flattened modules-specialists from `framework/modules/apex-*/agent.md` — count >= 6.
4. ✅ Test asserts BOTH byte-equality AND mtime sanity per file.
5. ✅ Pre-flight SKIP gate for absent `~/.claude/agents/`.
6. ✅ SECURITY-RUNTIME.md has new §"Subagent cache invalidation" section.
7. ✅ Closure notes in detector-review FINAL-CERT + PHASE-7-MASTER-PLAN.
8. ✅ run-all.sh discovers the test (no name change required — test-*.sh convention).
9. ✅ No regression in existing 55/55 audit-trail layer tests.

---

## §6. Implementation plan (unchanged — 1 commit)

Same as R1. Implementation now reflects R2 test structure.

---

## §7. Decision summary

**R1:** BLOCKING (wrong inventory + missing core agents + vacuous via sync).
**R2:** parses sync-to-claude.sh delivery; iterates ALL emitted destinations; adds mtime axis to catch post-sync edits; pre-flight SKIP for first-run.

**Blast radius:** 4 files. Test is ~80 lines (was 50).

**Next gate:** G2 critic R2.
