# G5 Critic — R-DH-P7-03 (Subagent-cache staleness probe + fresh-session doc)

**Reviewer:** clean-room critic
**Date:** 2026-05-26
**Verdict:** **PASS**
**Mode:** closed-artifact review against DESIGN-R2.md §5 G5 criteria

---

## 1. G5 Criteria Verification Table

| # | Criterion | Status | Evidence |
|---|-----------|:------:|----------|
| 1 | `framework/tests/test-subagent-cache.sh` exists, runs PASS in isolation | PASS | `ls -la` confirms file at expected path (mode 755, 3507 bytes). Direct invocation: `26/26 passed (skipped: 0)`, exit 0. |
| 2 | Test enumerates ALL `framework/agents/**/*.md` (≥13) | PASS | `find framework/agents -type f -name '*.md'` → 18 files. Test output enumerates 18 of 18 (architect, auditor, critic, executor, narrative-auditor, planner, ps-{remediation-planner,scheduler,verifier,wave-executor}, spec-auditor, verifier, specialist/{batch-scheduler, batch-verifier, framework-auditor, remediation-planner, round-checker, wave-executor}). |
| 3 | Test enumerates flattened modules-specialists from `framework/modules/apex-*/agent.md` (≥6) | PASS | `find framework/modules -name 'agent.md'` → 6 files. Test output enumerates 6 of 6 (apex-data, apex-frontend, apex-integration, apex-memory-synthesis, apex-security, apex-test-architect) with `→ specialist/<short>.md` mapping. |
| 4 | Test asserts BOTH byte-equality AND mtime sanity per file | PASS | Source lines 64 (`diff -q "$src" "$dst"`) + 68 (`[ "$src" -nt "$dst" ]`) for Loop 1; lines 88 + 92 mirror for Loop 2. FAIL messages explicitly cite "byte-equality FAIL" and "mtime FAIL — source newer than install". |
| 5 | Pre-flight SKIP gate for absent `~/.claude/agents/` | PASS | Lines 40-45: `if [ ! -d "$CLAUDE_ROOT/agents" ]; then skip "0a: ..."; exit 0` — exits 0 (not 1) on absence, matching DESIGN-R2 §3.2 first-run handling. |
| 6 | SECURITY-RUNTIME.md has new §"Subagent cache invalidation" section | PASS | `framework/docs/SECURITY-RUNTIME.md:245` — `## Subagent cache invalidation — fresh-session requirement (R-DH-P7-03)`. Content covers: cache mechanism (lines 252-257), L-DH-03 confound reference (258-262), fresh-session operating requirement enumerating both delivery vectors (264-272), and `test-subagent-cache.sh` mitigation pattern citing both axes (274-285). |
| 7 | Closure notes in detector-review FINAL-CERT + PHASE-7-MASTER-PLAN | PASS | `detector-review/FINAL-CERTIFICATION.md:296` — §7 R-item 3 marked `**CLOSED 2026-05-26 (R-DH-P7-03)**` with full closure paragraph (test path, scope, 26/26 result, side-effect note re 4 drifted files, doc anchor, design+critic refs). `audit-trail-review/PHASE-7-MASTER-PLAN.md:161` — `### R-DH-P7-03 — Closes L-DH-03 (subagent-cache methodology) — CLOSED 2026-05-26` with mirror closure paragraph. |
| 8 | `run-all.sh` discovers the test (`test-*.sh` convention) | PASS | `framework/tests/run-all.sh:122` — `for test_file in "$TESTS_DIR"/test-*.sh; do`. New test filename `test-subagent-cache.sh` matches the glob; lexical ordering places it between existing tests. No manual registration required. |
| 9 | No regression in audit-trail layer (still 55/55) | PASS | Direct invocation `bash framework/tests/test-audit-trail-layer.sh` → `── 55/55 passed (skipped: 0)`, exit 0. Final assertion lines (H-D6 through H-F3) match the expected verdict-comparison set. |

**Bonus check (install-copy sync):** `diff -q framework/tests/test-subagent-cache.sh ~/.claude/tests/test-subagent-cache.sh` → identical (BYTE-EQUAL). Self-test discipline: the new test would itself FAIL if the install copy drifted, so this is also covered by the test's own contract (but `~/.claude/tests/` is not under the test's enumeration scope — install copy of the TEST itself is a separate artifact, manually verified here).

---

## 2. Confidence: 9/9 verified | 0 unverified | 0 missing

All nine G5 criteria from DESIGN-R2.md §5 are independently filesystem-verified. The probe correctly enumerates 18 framework agents + 6 modules-flattened specialists (24 files + 2 pre-flight gates = 26 assertions, matching observed 26/26 PASS).

The test's design is sound under closed-artifact inspection:

- **Set-based enumeration** (loops over `find` output) ensures the probe scales with the framework rather than carrying a hardcoded inventory that can drift silently.
- **mtime axis** closes the post-sync-edit gap that byte-equality alone would miss only at the precise moment after a sync but before content drift — this is the actual cache-staleness pattern L-DH-03 documents.
- **SKIP gate semantics** (exit 0, not exit 1) match DESIGN-R2 §3.2: first-run-before-sync is a known state, not a defect.
- **Documentation** correctly frames the test as host-side cache-policy mitigation, not host-side cache enforcement (the test verifies disk state, not session state — and the doc says so explicitly at lines 283-285).

---

## 3. Diff / Artifact Analysis

No unexpected scope creep. Five artifacts touched, all on-spec for DESIGN-R2:

1. `framework/tests/test-subagent-cache.sh` — new file, 104 lines, mirrors DESIGN-R2 pseudocode.
2. `~/.claude/tests/test-subagent-cache.sh` — install-copy, byte-equal.
3. `framework/docs/SECURITY-RUNTIME.md` — appended §"Subagent cache invalidation" (no in-place edits to prior security sections; topic-shift note acknowledges the section boundary).
4. `detector-review/FINAL-CERTIFICATION.md:296` — §7 R-item 3 closure annotation only (no edits to other R-items in §7).
5. `audit-trail-review/PHASE-7-MASTER-PLAN.md:161` — closure paragraph on R-DH-P7-03 entry only.

No phantom language in test source, no silent catches, no hardcoded test-pass returns. Test failures emit explicit cause strings.

---

## 4. Edge-Case Coverage

| Edge case (from DESIGN-R2 §3) | Implemented? | Implementation site |
|-------------------------------|:------------:|---------------------|
| First-run (no `~/.claude/agents/`) | YES | Lines 41-45, SKIP + exit 0 |
| sync-to-claude.sh missing | YES | Lines 47-51, FAIL + exit 1 |
| Install copy missing for declared source | YES | Lines 60-63 (Loop 1), 84-87 (Loop 2) |
| Byte-equality drift | YES | Lines 64-67, 88-91 |
| Post-sync-edit mtime drift | YES | Lines 68-71, 92-95 |
| Module dirs prefixed `_` (private/skip) | YES | Line 78: `case "$mod_name" in _*) continue ;; esac` |
| Module without `agent.md` (orphan dir) | YES | Line 80: `[ -f "$agent_src" ] || continue` |

All edge cases from DESIGN-R2 §3.2 have explicit branches in the test source.

---

## 5. Verdict: PASS

All 9 G5 criteria verified by independent filesystem evidence. Test runs 26/26 in isolation, audit-trail layer holds at 55/55 (no regression), documentation section exists with required content, closure notes present in both designated locations, run-all auto-discovery is structurally guaranteed by the `test-*.sh` glob.

The probe correctly mechanises L-DH-03's mitigation: any future post-sync edit to an agent or module-specialist will produce a red CI signal *before* a fresh-session-dependent self-heal round consumes the stale cache. The doc names the host-side limitation honestly (disk vs session) rather than over-claiming.

R-DH-P7-03 is closed.

---

**Critic signature:** clean-room G5 review, evidence-based, no executor narrative consumed.
**Anchor files (absolute):**
- `C:\Users\דודאלמועלם\OneDrive - Tiva 13 Engineers\שולחן העבודה\APEX\framework\tests\test-subagent-cache.sh`
- `C:\Users\דודאלמועלם\OneDrive - Tiva 13 Engineers\שולחן העבודה\APEX\framework\docs\SECURITY-RUNTIME.md` (§ at line 245)
- `C:\Users\דודאלמועלם\OneDrive - Tiva 13 Engineers\שולחן העבודה\APEX\detector-review\FINAL-CERTIFICATION.md` (§7 item 3 at line 296)
- `C:\Users\דודאלמועלם\OneDrive - Tiva 13 Engineers\שולחן העבודה\APEX\audit-trail-review\PHASE-7-MASTER-PLAN.md` (entry at line 161)
- `C:\Users\דודאלמועלם\.claude\tests\test-subagent-cache.sh` (install copy, byte-equal)
