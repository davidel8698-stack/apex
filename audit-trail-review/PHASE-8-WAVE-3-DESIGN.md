# Wave 3 (R-P8-C11..C15) — design

> Combined design doc covering 5 R-items: owner-guard, ci-scan, test-deletion-guard, pre-task-snapshot, workflow-guard. These are the **grandfathered** hooks — they already have private stdin+argv extractors that work. Wave 3 replaces those private extractors with the shared helper to reach single-source-of-truth without changing behavior.

**Critical wave-3 constraint:** every pre-existing test must pass with byte-equivalent exit codes pre/post. The migration is purely consolidation — not a behavior change.

## G0 — research summary

| R-item | File | Lines | Existing pattern | Target API call |
|--------|------|-------|------------------|-----------------|
| C11 | `framework/hooks/owner-guard.sh` | L64-72 | argv-first then stdin-jq fallback for `.tool_input.file_path // .tool_input.path` | `apex_hook_input_filepath "$@"` (clean drop-in) |
| C12 | `framework/hooks/ci-scan.sh` | L122-142 | stdin-first JSON parse → self-filter; 3-shape routing (auto-PostToolUse / argv-dir / argv-file / default) | `apex_hook_input_filepath` only inside the no-argv branch (preserve 3-shape routing) |
| C13 | `framework/hooks/test-deletion-guard.sh` | L40-43 | stdin-only `PAYLOAD=$(cat)`; then jq queries on `.tool_name` AND `.tool_input` | `apex_hook_input_raw` (multi-field; helper-API documented use case) |
| C14 | `framework/hooks/pre-task-snapshot.sh` | L37-58 | stdin-only `.tool_input.command` extraction for self-filter; argv is TASK_ID (different semantic) | `apex_hook_input_command` **with no args** (preserves TASK_ID independence) |
| C15 | `framework/hooks/workflow-guard.sh` | L54-59 | argv-first then stdin-jq `.tool_input.file_path` | `apex_hook_input_filepath "$@"` (canonical Wave 2 drop-in) |

**Regression baselines (existing tests that must remain green identically):**

| Test file | Wave-3 hooks exercised | Mechanism |
|-----------|------------------------|-----------|
| `test-owner-guard.sh` | owner-guard ×~10 cases (5/6/7/8/9/10) | argv-style; FILEPATH always set via `$1` |
| `test-hooks-security.sh` | ci-scan S-11..S-14 (4 cases); workflow-guard S-7..S-10, S-8b (5 cases) | argv-style; FILE/ARG always set via `$1` |
| `test-pre-task-snapshot.sh` | pre-task-snapshot (4+ cases) | argv-style TASK_ID; stdin may or may not be present |
| `test-critic-git-trace.sh` | pre-task-snapshot (1 setup invocation) | argv-style |
| `test-audit-trail-layer.sh` | pre-task-snapshot pre-task-claims path (1 case) | argv-style TASK_ID |
| `test-hooks-blocking.sh` | pre-task-snapshot (B-5 grep-only contract) | source-grep, no invocation |
| `test-security-specialist.sh` | one of the 5 hooks (need verification) | argv |
| `test-ci-scan-wiring.sh` | ci-scan wiring (settings.json + 3-places) | grep-only |

**No test-deletion-guard dedicated tests exist** — the hook is stdin-only in production; layer test row will be added in G4.

**Helper API recap (from R-P8-A, landed `fd98082d`):**
- `apex_hook_input_command "$@"` → echoes `.tool_input.command` (argv-first)
- `apex_hook_input_filepath "$@"` → echoes `.tool_input.file_path // .tool_input.path` (argv-first)
- `apex_hook_input_tool_name "$@"` → echoes `.tool_name` (argv-first)
- `apex_hook_input_raw "$@"` → echoes argv-string OR full stdin payload (argv-first)

---

## G1 — per-hook migration design

### C11 — `framework/hooks/owner-guard.sh` (clean drop-in)

**Replace lines 64-72:**
```bash
FILEPATH="${1:-}"
if [ -z "$FILEPATH" ] && [ ! -t 0 ]; then
  if command -v jq >/dev/null 2>&1; then
    PAYLOAD=$(cat 2>/dev/null || true)
    if [ -n "$PAYLOAD" ]; then
      FILEPATH=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)
    fi
  fi
fi
```

**With:**
```bash
# Phase 8 R-P8-C11: consolidate to shared input-extraction helper.
# Replaces the private argv+stdin extractor that previously lived here.
# Closes the F-001-family-adjacent consolidation gap surfaced by
# R-AT-P7-07 — fifteen hooks now share one canonical extractor.
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi
FILEPATH=$(apex_hook_input_filepath "$@" 2>/dev/null || printf '%s' "${1:-}")
```

**Correctness:** owner-guard's existing extractor and `apex_hook_input_filepath` use the SAME jq query (`.tool_input.file_path // .tool_input.path // empty`) and the SAME argv-first priority. Output is byte-equivalent.

**Regression baseline:** test-owner-guard.sh argv-style invocations (`bash owner-guard.sh "src/foo.ts"` etc.) all set $1 non-empty → helper returns argv → FILEPATH identical to pre-migration.

---

### C12 — `framework/hooks/ci-scan.sh` (3-shape routing preserved)

**The challenge:** ci-scan dispatches based on argv-vs-stdin presence:
- argv = dir → scan dir (test invocation pattern)
- argv = file → scan its parent dir (with self-filter)
- argv = absent + stdin envelope → extract `.tool_input.file_path`, self-filter, scan parent dir
- argv = absent + no stdin → default to `.github/workflows`

A bare `FILEPATH=$(apex_hook_input_filepath "$@")` would conflate these: if a dir path comes via argv, the case-glob would not match `.github/workflows/*` and the hook would exit 0 — breaking S-11..S-14 which pass dir paths via argv.

**Solution:** consolidate ONLY the stdin extraction block (L122-142), keep the argv branch (L145-161) untouched. The helper is called ONLY when there is no argv.

**Replace lines 122-142:**
```bash
WORKFLOWS_DIR=""
if [ -p /dev/stdin ] || [ ! -t 0 ]; then
  STDIN_BUF=$(cat 2>/dev/null || true)
  if [ -n "$STDIN_BUF" ] && command -v jq >/dev/null 2>&1; then
    HOOK_PATH=$(echo "$STDIN_BUF" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)
    if [ -n "$HOOK_PATH" ]; then
      case "$HOOK_PATH" in
        .github/workflows/*|*/.github/workflows/*)
          WORKFLOWS_DIR="$(dirname "$HOOK_PATH")"
          ;;
        *)
          exit 0
          ;;
      esac
    fi
  fi
fi
```

**With:**
```bash
# Phase 8 R-P8-C12: consolidate stdin extraction to shared helper.
# 3-shape routing (auto-PostToolUse / argv-dir / argv-file / default)
# preserved — helper is invoked only inside the no-argv branch so that
# argv-style test invocations bypass the self-filter exactly as before.
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi

WORKFLOWS_DIR=""
if [ -z "${1:-}" ]; then
  HOOK_PATH=""
  if command -v apex_hook_input_filepath >/dev/null 2>&1; then
    HOOK_PATH=$(apex_hook_input_filepath 2>/dev/null || true)
  fi
  if [ -n "$HOOK_PATH" ]; then
    case "$HOOK_PATH" in
      .github/workflows/*|*/.github/workflows/*)
        WORKFLOWS_DIR="$(dirname "$HOOK_PATH")"
        ;;
      *)
        exit 0
        ;;
    esac
  fi
fi
```

**Lines 144-161 (argv branch) remain byte-identical.**

**Correctness:**
- S-11 (`bash ci-scan.sh .github/workflows` — argv-style with dir): outer `[ -z "${1:-}" ]` is false → skip stdin path → fall through to argv branch L145 → unchanged behavior.
- S-12/S-13/S-14: same — all argv. Unchanged.
- Auto-PostToolUse production (no argv, stdin envelope with `.github/workflows/ci.yml`): outer is true → helper called → returns the file_path → case-glob matches → WORKFLOWS_DIR = `.github/workflows` → scan proceeds.
- Auto-PostToolUse outside workflows (no argv, stdin envelope with `src/foo.ts`): outer is true → helper returns `src/foo.ts` → case-glob fails → exit 0 (self-filter). Same as original.

---

### C13 — `framework/hooks/test-deletion-guard.sh` (multi-field via raw)

**Replace lines 40-43:**
```bash
PAYLOAD=""
if [ ! -t 0 ]; then
  PAYLOAD=$(cat 2>/dev/null || true)
fi
```

**With:**
```bash
# Phase 8 R-P8-C13: consolidate stdin extraction to shared helper.
# Multi-field hook (needs .tool_name + .tool_input), uses raw extractor
# per the helper-API contract documented in _hook-input.sh header.
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi

PAYLOAD=""
if command -v apex_hook_input_raw >/dev/null 2>&1; then
  PAYLOAD=$(apex_hook_input_raw 2>/dev/null || true)
fi
```

**Correctness:**
- Original reads stdin via `cat` when not TTY; helper does the same internally when no argv and not TTY. Equivalent payload retrieval.
- Original sets `PAYLOAD=""` first then conditionally populates; new code initialises empty then unconditionally calls helper which returns empty when stdin is empty/TTY. Equivalent end state.
- jq queries on lines 53-54 unchanged; they read from `PAYLOAD` identically.
- Degraded install (helper not sourced): `command -v apex_hook_input_raw` is false → PAYLOAD stays empty → existing L45 `[ -z "$PAYLOAD" ] && exit 0` → fail-safe.

**Regression baseline:** no dedicated test file; behavior verified via layer test H-G27 (new — multi-field parity probe).

---

### C14 — `framework/hooks/pre-task-snapshot.sh` (argv ≠ command — call helper with NO args)

**The challenge:** pre-task-snapshot has TWO conflicting argv conventions:
- CLI invocation pattern: `bash pre-task-snapshot.sh TASK_ID` — `$1` is task ID
- The self-filter wants `.tool_input.command` from stdin envelope (PreToolUse Bash matcher)

Calling `apex_hook_input_command "$@"` would mis-treat TASK_ID as the user command, breaking the self-filter. Solution: call helper with NO args; it falls through to stdin path.

**Replace lines 37-58:**
```bash
if [ ! -t 0 ]; then
  STDIN_ENV_BUF=$(cat 2>/dev/null || true)
  if [ -n "$STDIN_ENV_BUF" ] && command -v jq >/dev/null 2>&1; then
    USER_CMD=$(echo "$STDIN_ENV_BUF" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
    if [ -n "$USER_CMD" ]; then
      ... self-filter logic ...
    fi
  fi
fi
```

**With:**
```bash
# Phase 8 R-P8-C14: consolidate stdin extraction to shared helper.
# pre-task-snapshot's argv is TASK_ID (NOT the user command), so the
# helper is called with NO args — it falls through to the stdin path
# regardless of TASK_ID presence. Self-filter logic below is unchanged.
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi

USER_CMD=""
if command -v apex_hook_input_command >/dev/null 2>&1; then
  USER_CMD=$(apex_hook_input_command 2>/dev/null || true)
fi
if [ -n "$USER_CMD" ]; then
  # Strip leading whitespace; capture the first two tokens.
  CMD_TRIM="${USER_CMD#"${USER_CMD%%[![:space:]]*}"}"
  FIRST_TOK="${CMD_TRIM%% *}"
  REST_AFTER_FIRST="${CMD_TRIM#"$FIRST_TOK"}"
  REST_TRIM="${REST_AFTER_FIRST#"${REST_AFTER_FIRST%%[![:space:]]*}"}"
  SECOND_TOK="${REST_TRIM%% *}"
  if [ "$FIRST_TOK" = "git" ]; then
    case "$SECOND_TOK" in
      status|log|show|diff|stash)
        exit 0
        ;;
    esac
  fi
fi
```

**Correctness:**
- CLI invocation `bash pre-task-snapshot.sh "T-123"` with no stdin: helper called with no args → no $1 → stdin TTY → returns empty → USER_CMD empty → skip self-filter block → proceed to snapshot logic. TASK_ID still picked up at L66 (`TASK_ID=${1:-"unknown"}`). Identical to original.
- Stdin envelope with git status: helper called with no args → stdin piped → returns `.tool_input.command` = "git status ..." → USER_CMD set → self-filter parses, matches → exit 0. Identical to original.
- Stdin envelope with non-git command: USER_CMD non-empty but FIRST_TOK != "git" → self-filter skipped → proceed to snapshot. Identical.

**Regression baseline:** test-pre-task-snapshot.sh CLI-style invocations still work — TASK_ID handling is decoupled from the helper.

---

### C15 — `framework/hooks/workflow-guard.sh` (canonical Wave-2 drop-in)

**Replace lines 54-59:**
```bash
FILE="${1:-}"

# Hook context fallback: if no $1, try stdin (Claude Code PreToolUse passes JSON)
if [ -z "$FILE" ] && [ ! -t 0 ]; then
  FILE=$(cat 2>/dev/null | jq -r '.tool_input.file_path // empty' 2>/dev/null)
fi
```

**With:**
```bash
# Phase 8 R-P8-C15: consolidate to shared input-extraction helper.
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi
FILE=$(apex_hook_input_filepath "$@" 2>/dev/null || printf '%s' "${1:-}")
```

**Correctness:**
- test-hooks-security S-7..S-10 + S-8b all pass argv → helper short-circuits to `$1` → identical FILE → identical exit code.
- Production stdin envelope: helper extracts `.tool_input.file_path` → identical FILE.
- Note: original used `.tool_input.file_path` only; helper uses `.tool_input.file_path // .tool_input.path`. The `.path` fallback is a SUPERSET — workflow-guard now accepts both keys. This is forward-compatible (Claude Code current versions emit `file_path`; helper is robust to both).

---

## G3 — implementation plan

5 file edits (independent files, parallel-safe):

1. `framework/hooks/owner-guard.sh` — replace L64-72 with helper call
2. `framework/hooks/ci-scan.sh` — replace L122-142 stdin block with helper-inside-no-argv pattern
3. `framework/hooks/test-deletion-guard.sh` — replace L40-43 with helper raw call
4. `framework/hooks/pre-task-snapshot.sh` — replace L37-58 with helper command call (no args)
5. `framework/hooks/workflow-guard.sh` — replace L54-59 with canonical helper pattern

Net deltas: each ~+5 to +8 lines (helper source guard + helper call) vs. ~-5 to -8 lines (removed private extractor). Approximately net-neutral line count per hook.

---

## G4 — layer test additions (H-G26..H-G30)

5 sources-helper verification rows + skip-label update. No parity probes because:
- C11 owner-guard: parity requires WAVE_MAP.json fixture — heavy; existing test-owner-guard.sh already covers argv path. Defer to G5 manual probe.
- C12 ci-scan: parity requires .github/workflows fixture; existing test-hooks-security S-11..S-14 covers argv path. Defer.
- C13 test-deletion-guard: stdin-only, no argv path to compare against. Skipped (parity meaningless without two paths).
- C14 pre-task-snapshot: parity requires repo state for snapshot. Defer to G5 manual probe.
- C15 workflow-guard: argv path covered by test-hooks-security S-7..S-10; stdin path covered by G5 manual probe.

```bash
# H-G26..H-G30: Wave 3 (R-P8-C11..C15) per-hook helper-sourcing verification.
# Verifies each grandfathered hook now sources the shared _hook-input.sh
# instead of carrying a private extractor.
for HG_PAIR in "H-G26:owner-guard.sh" "H-G27:ci-scan.sh" \
               "H-G28:test-deletion-guard.sh" "H-G29:pre-task-snapshot.sh" \
               "H-G30:workflow-guard.sh"; do
  HG_ID="${HG_PAIR%%:*}"
  HG_HOOK="${HG_PAIR#*:}"
  if grep -q "source.*_hook-input.sh" "$HOOKS_DIR/$HG_HOOK" 2>/dev/null; then
    ok "$HG_ID: $HG_HOOK sources _hook-input.sh"
  else
    nope "$HG_ID: $HG_HOOK missing _hook-input.sh source"
  fi
done
```

Update skip label from `H-G0..H-G25` to `H-G0..H-G30`.

**Layer test count target:** 81 → 86 (+5 rows).

---

## G5 — critic R2 success criteria

1. **Byte-equivalent regression:** each of `test-owner-guard.sh`, `test-hooks-security.sh`, `test-pre-task-snapshot.sh`, `test-audit-trail-layer.sh`, `test-fix-plan-emit.sh`, `test-hooks-blocking.sh`, `test-critic-git-trace.sh` exits 0 with the SAME pass count as pre-migration.
2. **Helper sourcing visible:** each of 5 hooks contains `source.*_hook-input.sh`.
3. **Private extractor removed:** each of 5 hooks NO LONGER contains the lines being replaced (no dead-code leftovers).
4. **ci-scan 3-shape routing preserved:**
   - argv-dir: `bash ci-scan.sh .github/workflows` → exit 0 (no findings)
   - argv-file: `bash ci-scan.sh .github/workflows/ci.yml` → file → parent dir → scan
   - stdin-envelope-workflows: scan
   - stdin-envelope-non-workflows: exit 0 (self-filter)
   - no-arg-no-stdin: default `.github/workflows`
5. **pre-task-snapshot argv/stdin independence:** TASK_ID set via argv; USER_CMD set via stdin; both independent (no conflation).
6. **test-deletion-guard multi-field:** Both `.tool_name` and `.tool_input` still resolved from stdin envelope.
7. **Layer test:** 81 → 86 PASS, exit 0.
8. **`bash -n`:** all 5 modified hooks pass syntax.
9. **Helper-missing degraded install:** all 5 hooks revert to legacy behavior cleanly.
10. **Commit-message safety** per PHASE-8-STATE §4 — no literal destructive-class tokens in commit body.

---

## Ecosystem 10-question gate

1. **What changes** — 5 grandfathered hooks consolidate their private extractors into shared helper. SSoT achieved across all 15 affected hooks (Wave 1+2+3 combined).
2. **Who calls / consumes** — Claude Code PreToolUse/PostToolUse runtime + dedicated test files (test-owner-guard, test-pre-task-snapshot, test-critic-git-trace, test-ci-scan-wiring, test-hooks-security, test-hooks-blocking, test-audit-trail-layer).
3. **What does it break** — Nothing if behavior is preserved per design. Wave-3 risk is regression-only (replacing working code), so design enforces byte-equivalence at the extraction-output layer.
4. **What spec/contract anchors** — `apex-spec.md` § "Hook input-extraction contract" (R-P8-B), `_hook-input.sh` header doc.
5. **What tests need updating** — `test-audit-trail-layer.sh` H-G section (+5 rows). No other tests need updating (regression-only wave).
6. **What documentation needs updating** — Phase 8 closure will update `AUDIT-TRAIL-STANDARD.md`.
7. **What rollback** — `git revert <wave-3-commit>` reverts all 5 hooks to private extractors; layer test rows revert to skip-block.
8. **What invariants must hold post-change** — Every pre-existing test passes identically; 3-shape routing in ci-scan preserved; argv-TASK_ID semantic in pre-task-snapshot preserved; multi-field consumption in test-deletion-guard preserved.
9. **Where does new logic live** — Helper (no change). Per-hook diffs are adapter blocks.
10. **What follow-up landmines** — Wave 4 needs the round-checker clause (x) to detect future regressions; CI lint hook (R-P8-E) prevents new hooks from re-introducing private extractors.

---

## Blast radius matrix

| Surface | Wave-3 in isolation | Cumulative Phase 8 |
|---------|---------------------|---------------------|
| `framework/hooks/_hook-input.sh` | unchanged | unchanged (Wave 0) |
| `framework/hooks/owner-guard.sh` | private extractor → helper | now SSoT-compliant |
| `framework/hooks/ci-scan.sh` | stdin extractor → helper inside no-argv branch | 3-shape routing preserved |
| `framework/hooks/test-deletion-guard.sh` | stdin extractor → helper raw | multi-field preserved |
| `framework/hooks/pre-task-snapshot.sh` | stdin self-filter extractor → helper (no args) | TASK_ID independence preserved |
| `framework/hooks/workflow-guard.sh` | argv+stdin extractor → helper | canonical pattern |
| `framework/tests/test-audit-trail-layer.sh` | +5 H-G rows | layer count 81 → 86 |
| 7 pre-existing test files | unchanged | identical pass counts |
| F-001 ecosystem | 5 grandfathered hooks now use SSoT helper | 15/15 affected hooks unified |
| Wave 4 dependency | unblocks round-checker clause (x) — all C-items must land before D | — |

**Rollback dependency:** Wave 3 commit is independent of Wave 4. Reverting Wave 3 leaves Waves 0/1/2 intact.
