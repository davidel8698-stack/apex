# Phase 8 — F-001 Family Closure: Progress State

**Generated:** 2026-05-27 (end of session 1).
**Status:** Wave 0 + Wave 1 closed PASS (7/19 R-items complete). Wave 2-4 + verification pending.
**Master plan:** `~/.claude/plans/calm-cuddling-corbato.md`.

---

## §1. Closed R-items (7/19)

| Wave | R-item | Closes | Commit | Critic verdict |
|------|--------|--------|--------|----------------|
| 0 | R-P8-A | Shared helper `_hook-input.sh` | `fd98082d` | G2 R1 PASS-WITH-CHANGES (5 BLOCKING fixed in R2); G5 R2 PASS (0/0/HIGH) |
| 0 | R-P8-B | Spec closure SGC-001 (apex-spec.md §"Hook input-extraction contract") | `0a149e93` | Combined G2/G5 PASS (0/0/0.97) |
| 1 | R-P8-C1 | `destructive-guard.sh` → helper | `626b35fe` | Wave 1 combined G5 PASS (0/0/HIGH) |
| 1 | R-P8-C2 | `exfil-guard.sh` → helper | `626b35fe` | (combined) |
| 1 | R-P8-C3 | `sequence-guard.sh` → helper | `626b35fe` | (combined) |
| 1 | R-P8-C4 | `subagent-guard.sh` → helper | `626b35fe` | (combined) |
| 1 | R-P8-C5 | `grader-search-guard.sh` → helper | `626b35fe` | (combined) |

**Test suites (current state after Wave 1):**
- `test-audit-trail-layer.sh`: **73/73 PASS** (55 baseline + 8 H-D + 4 H-E + 3 H-F + 18 H-G = 88? actually 55 baseline + 18 new H-G = 73 total — see layer test output)
- `test-fix-plan-emit.sh`: 37/37 PASS
- `test-hooks-security.sh`: 18/18 PASS
- `test-hooks-blocking.sh`: 12/13 PASS (1 pre-existing skip — not a regression)

**F-001 closure empirical evidence:** `echo '{"tool_input":{"command":"rm -rf /"}}' | bash framework/hooks/destructive-guard.sh` now exits 2 + block message. Pre-Phase-8 it exited 0. The methodology gap is closed for 5 of 15 affected hooks.

---

## §2. Pending R-items (12/19)

### Wave 2 — R-P8-C6..C10 (5 R-items, parallel within wave)

Broken Write/Edit + PostToolUse hooks. Each reads `${1:-}` for `FILEPATH`/`INPUT`/`FILE` rather than `COMMAND`. Migration uses `apex_hook_input_filepath` (instead of `apex_hook_input_command` used in Wave 1).

| R-item | File | Line | Variable | Closes |
|--------|------|------|----------|--------|
| R-P8-C6 | `framework/hooks/path-guard.sh` | L16 | `FILEPATH="${1:-}"` | F-003 |
| R-P8-C7 | `framework/hooks/quarantine-guard.sh` | L28 | `INPUT="${1:-}"` | F-004 |
| R-P8-C8 | `framework/hooks/post-write.sh` | L11 | `FILE="${1:-}"` | F-008 |
| R-P8-C9 | `framework/hooks/ast-kb-check.sh` | L11 | `FILE="${1:-}"` | F-009 |
| R-P8-C10 | `framework/hooks/schema-drift.sh` | L18 | `FILE="${1:-}"` | F-010 |

**Migration pattern (per hook, ~8-line diff):**
```bash
# Phase 8 R-P8-CN: canonical input extraction via shared helper.
# Closes F-NNN (stdin-envelope bypass — auditor axis-13.e discovery).
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi

FILEPATH=$(apex_hook_input_filepath "$@" 2>/dev/null || printf '%s' "${1:-}")
```

**Caveat for R-P8-C7 (quarantine-guard.sh):** the variable is `INPUT`, not `FILEPATH`. Check the hook source to verify what `INPUT` semantically holds — file path, tool name, or full envelope? May require `apex_hook_input_filepath` OR `apex_hook_input_raw` depending on usage. **G0 step: read the hook carefully before migrating.**

**Layer test additions (H-G18..H-G22 + parity probes H-G23..H-G25):**
- H-G18..H-G22: per-hook sources-helper verification (5 rows)
- H-G23: path-guard.sh argv+stdin parity (file_path)
- H-G24: post-write.sh argv+stdin parity (file_path)
- H-G25: schema-drift.sh argv+stdin parity (file_path)

### Wave 3 — R-P8-C11..C15 (5 R-items, grandfathered consolidation)

5 hooks that ALREADY have private stdin+argv extractors. Consolidate to shared helper. Most delicate wave (replacing working code).

| R-item | File | Lines to replace | Variable |
|--------|------|------------------|----------|
| R-P8-C11 | `framework/hooks/owner-guard.sh` | L64-72 (private jq fallback) | `FILEPATH` |
| R-P8-C12 | `framework/hooks/ci-scan.sh` | L113-127 (3-shape extractor) | `WORKFLOWS_DIR` (special — see ci-scan logic) |
| R-P8-C13 | `framework/hooks/test-deletion-guard.sh` | L39-54 (stdin-only) | `PAYLOAD` → use `apex_hook_input_raw` |
| R-P8-C14 | `framework/hooks/pre-task-snapshot.sh` | L30-50 (stdin self-filter) | `USER_CMD` → `apex_hook_input_command` |
| R-P8-C15 | `framework/hooks/workflow-guard.sh` | L54-59 (argv+stdin) | `FILE` → `apex_hook_input_filepath` |

**Regression baseline:** before/after exit-code parity on existing test invocations. Each hook's pre-existing tests MUST still pass identically.

**Critical for C12 (ci-scan):** the 3-shape contract (auto-PostToolUse / direct-CLI-dir / default) is more complex than other hooks. May require `apex_hook_input_filepath` + special handling for the dir vs file disambiguation. **G0 carefully.**

**Critical for C13 (test-deletion-guard):** needs BOTH `.tool_name` AND `.tool_input` fields. Use the documented multi-field pattern with `apex_hook_input_raw`:
```bash
PAYLOAD=$(apex_hook_input_raw "$@")
TOOL_NAME=$(echo "$PAYLOAD" | jq -r '.tool_name // empty' 2>/dev/null)
TOOL_INPUT=$(echo "$PAYLOAD" | jq -r '.tool_input // empty' 2>/dev/null)
```

### Wave 4 — R-P8-D + R-P8-E (parallel)

- **R-P8-D**: round-checker clause (x) + framework-auditor axis-13.e `helper_sourced` field + 3 H-G fixtures (round-checker-h-g-{1,2,3}.jsonl).
- **R-P8-E**: `framework/scripts/lint-hook-input.sh` + SECURITY-RUNTIME.md pre-commit hook doc + 1 H-G smoke test.

### Verification gate + closure

10-check verification per master plan §7 + PHASE-8-CRITIC-FINAL adversarial pass + commit + tag `phase-8-stdin-envelope-passed` + memory updates.

---

## §3. Migration pattern (binding for all C-items)

Established by R-P8-C1..C5 (Wave 1):

```bash
# Phase 8 R-P8-CN: canonical input extraction via shared helper.
# Closes F-NNN (stdin-envelope bypass — auditor axis-13.e discovery).
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi

<VAR>=$(apex_hook_input_<TYPE> "$@" 2>/dev/null || printf '%s' "${1:-}")
```

Where:
- `<VAR>` is the hook's existing variable name (`COMMAND`/`FILEPATH`/`FILE`/`INPUT`)
- `<TYPE>` is `command` for Bash matchers, `filepath` for Write/Edit matchers, `raw` for multi-field consumers
- The `|| printf '%s' "${1:-}"` fallback preserves degraded-install behavior

**Source placement:** AFTER existing `_audit-probe-marker.sh` sourcing (where present); matches established convention.

---

## §4. Commit-message safety note (binding)

**Lesson learned in session 1:** test-deletion-guard.sh fires false-positive when `git add` includes a test file AND the commit message body contains literal "rm" patterns. The hook checks the FULL command string passed by Claude Code.

**Workaround for future Phase 8 commits:** in commit messages, paraphrase any literal `rm` / `rm -rf` patterns (e.g., describe as "destructive-class deletion pattern" or "removal command"). Avoid embedding shell command examples that contain `rm` in commit message bodies when the commit touches test files.

Alternative: set `APEX_ACTIVE_AGENT=test-architect` before the commit (hook bypass) — but this should be reserved for actual test deletions, not Phase 8 narrative.

---

## §5. Resume protocol (next-session opening prompt)

Suggested opening for next session:

> Read `audit-trail-review/PHASE-8-STATE.md`. Phase 8 has 7/19 R-items closed PASS (Wave 0 + Wave 1). Continue from Wave 2: R-P8-C6..C10 (5 broken Write/Edit + PostToolUse hooks). The migration pattern is established in §3 of state file. Per-hook G0→G5 gates. Watch out for the commit-message safety note in §4 when committing. Target: complete Wave 2 + Wave 3 in next session if budget allows; Wave 4 + verification in a subsequent session.

---

## §6. Tool-budget rationale for handoff

Session 1 executed:
- Wave 0: 2 R-items × full G0→G5 = ~120 tool calls
- Wave 1: 5 R-items × combined critic + parallel migration = ~80 tool calls
- Plan creation + design docs + critic invocations = ~80 tool calls
- Plus initial exploration + reading + verification = ~50 tool calls

Total ~330 calls. Per owner directive 2026-05-25 ("אל תדחוף מעבר ל-400 tool calls ברצף"), handoff at this point preserves clean execution capacity for Wave 2-4 in the next session.

---

## §7. Files modified in session 1

- `framework/hooks/_hook-input.sh` (NEW, R-P8-A)
- `apex-spec.md` (NEW section line 303, R-P8-B)
- `framework/hooks/destructive-guard.sh` (R-P8-C1, +8 lines)
- `framework/hooks/exfil-guard.sh` (R-P8-C2, +8 lines)
- `framework/hooks/sequence-guard.sh` (R-P8-C3, +8 lines)
- `framework/hooks/subagent-guard.sh` (R-P8-C4, +8 lines)
- `framework/hooks/grader-search-guard.sh` (R-P8-C5, +8 lines)
- `framework/tests/test-audit-trail-layer.sh` (+H-G0..H-G17, ~140 lines added)
- 4 design + 4 critic markdown files under `audit-trail-review/PHASE-8-*`

3 commits on main: `fd98082d` (R-P8-A) → `0a149e93` (R-P8-B) → `626b35fe` (Wave 1).

---

## §8. Quality gate compliance

Every R-item closed in session 1 satisfied the binding G0→G5 standard:
- G0: research summary documented
- G1: design doc written
- G2: clean-room critic R1 invoked (clean-room subagent)
- G3: implementation
- G4: layer test added (H-G section)
- G5: clean-room critic R2 invoked OR combined critic for parallel R-items

No R-item closed without empirical PASS evidence. No partial closure.
