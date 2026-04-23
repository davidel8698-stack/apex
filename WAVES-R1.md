# WAVES-R1 — Batch Execution Schedule

**Source:** REMEDIATION-PLAN-R1.md (2026-04-23)
**Spec anchor:** apex-spec.md
**Scheduler:** Claude Opus 4.6 (Batch Scheduler mode)

---

## Wave 1

**R-IDs:** R-006, R-007, R-017, R-027, R-011 (verify), R-018 (verify), R-025 (verify)

**Rationale for grouping:** All modify independent files with zero overlap. Includes 3 verify-only items (R-011, R-018, R-025) that add no risk. The 4 active changes each touch exactly one file that no other R-ID in this wave touches.

**Independence proof:**
| R-ID | Files touched | Overlap with others |
|------|--------------|-------------------|
| R-006 | post-write.sh | None |
| R-007 | phase-tag.sh | None |
| R-017 | onboard.md | None |
| R-027 | ship.md | None |
| R-011 | start.md (verify only) | None |
| R-018 | build.md, refine.md (verify only) | None |
| R-025 | workflow .md files (verify only) | None |

No DAG edges between any pair. No entries in conflict matrix.

**Estimated scope:**
- `framework/hooks/post-write.sh` — add skipped-test detection section (~20 lines)
- `framework/hooks/phase-tag.sh` — add change_failure_rate computation (~10 lines)
- `framework/commands/apex/onboard.md` — replace L1-L4 prompt with friendly menu (~15 lines)
- `framework/commands/apex/ship.md` — add STRICT_MODE activation (~3 lines)
- Verify-only: start.md, build.md, refine.md, migrate-to-postgres.md, setup-ci-cd.md

**Verification gate:**
- Test suite: `test-hooks-blocking.sh`, `test-hooks-security.sh`, `test-guards.sh`
- Smoke test: (1) Write test file with `.skip(` → verify post-write blocks. (2) Complete a phase → verify all 4 DORA fields non-null in STATE.json. (3) Run onboard → verify no L1-L4 labels visible, friendly names shown. (4) Run ship → verify strict_mode=true set before verification.
- Spec anchors re-checked: F-006 "Skipped-test regression detection", F-007 "DORA self-monitoring", F-017 "User-facing complexity is a 4-button menu", F-027 "Strict mode before commitment", F-011 "Four primitives", F-018 "Build/refine different pipelines", F-025 "Security Invariants"
- Regression check: All existing hook tests pass. Onboard→start flow works. Ship creates release tags. Phase-tag creates annotated git tags.

**Abort conditions:** Any existing test in `test-hooks-blocking.sh` or `test-guards.sh` fails after changes. Revert all Wave 1 changes.

**Pre-requisites:** None — first wave.

---

## Wave 2

**R-IDs:** R-014, R-008

**Rationale for grouping:** R-014 touches only next.md (spec drift check). R-008 touches only DIRECTORY-CONTRACT.md and health-check.md (U-shaped guidelines). Zero file overlap. Both are low-blast-radius additions.

**Independence proof:**
| R-ID | Files touched | Overlap with others |
|------|--------------|-------------------|
| R-014 | next.md | None with R-008 |
| R-008 | DIRECTORY-CONTRACT.md, health-check.md | None with R-014 |

No DAG edges. No conflict matrix entries between them.

**Estimated scope:**
- `framework/commands/apex/next.md` — add spec drift hash check before executor dispatch (~10 lines, build stage section)
- `framework/DIRECTORY-CONTRACT.md` — add U-shaped prompt engineering guidelines section (~30 lines)
- `framework/commands/apex/health-check.md` — add agent prompt structure audit (~15 lines)

**Verification gate:**
- Test suite: health-check tests
- Smoke test: (1) Modify SPEC.md without /apex:spec → verify drift warning in next /apex:next. (2) Normal execution (no spec change) → no warning. (3) Empty spec_version (new project) → no warning. (4) Run health-check → verify agent prompt audit runs.
- Spec anchors re-checked: F-014 "SPEC_VERSION hash drift detection", F-008 "U-shaped attention awareness"
- Regression check: next.md orchestration advances tasks correctly. health-check passes.

**Abort conditions:** next.md fails to advance tasks after change. Spec drift check fires false warnings on unchanged specs.

**Pre-requisites:** Wave 1 passed gate.

---

## Wave 3

**R-IDs:** R-015

**Rationale for grouping:** Solo wave — high blast radius. Rewrites the cockpit rendering in both next.md and status.md, replacing chronological event tail with decision-filtered query. Cockpit is the user's primary decision interface.

**Independence proof:** Solo wave — no internal conflicts.

**Estimated scope:**
- `framework/commands/apex/next.md` — replace cockpit tail with jq-filtered decision query (~25 lines, cockpit section lines 39-42)
- `framework/commands/apex/status.md` — same cockpit filter change (~15 lines)

**Verification gate:**
- Test suite: next.md orchestration test, status rendering test
- Smoke test: (1) Create pending_approval event in event-log.jsonl → verify cockpit shows it. (2) Create routine checkpoint events → verify cockpit filters them out when decisions pending. (3) Empty event log → cockpit falls back to recent events (not blank). (4) Verify cap at 5 items.
- Spec anchors re-checked: F-015 "Glass cockpit with 3-5 decision-required items"
- Regression check: next.md orchestration, status display, Live Ticker (tail -5) unaffected.

**Abort conditions:** Cockpit shows zero items when decisions are pending. next.md orchestration breaks.

**Pre-requisites:** Wave 2 passed gate. next.md spec drift check (R-014) is stable.

---

## Wave 4

**R-IDs:** R-023, R-024, R-021, R-028

**Rationale for grouping:** Four tiny additions to next.md (each <=5 lines), each in a completely different named section with zero line proximity. Grouped to avoid 4 single-item waves. Controlled deviation from strict "no overlap" — safe because changes are minimal, isolated to distinct sections, and independently revertable.

**Intra-wave serialization order:** R-023 → R-024 → R-021 → R-028

**Independence proof:**
| R-ID | Section of next.md | Other files | Line proximity |
|------|-------------------|-------------|---------------|
| R-023 | Cockpit header (after line 42) | None | display area |
| R-024 | Zone system section (executor dispatch) | DIRECTORY-CONTRACT.md | context engineering area |
| R-021 | verify_needed stage | None | verification area |
| R-028 | Build stage start | None | validation area |

No DAG edges between any pair. Conflict matrix notes no entries for these pairs (all single-R-ID files except next.md, where they touch disjoint sections).

**Estimated scope:**
- `framework/commands/apex/next.md` — 4 additions totaling ~16 lines across 4 sections
- `framework/DIRECTORY-CONTRACT.md` — add observation masking documentation (~15 lines)

**Verification gate:**
- Test suite: next.md orchestration test
- Smoke test: (1) /apex:next shows elapsed time in cockpit header. (2) Missing PLAN_META.json at verify → advisory warning. (3) Missing APEX.md at build start → advisory warning. (4) Zone system labeled "Observation Masking Protocol" in next.md.
- Spec anchors re-checked: F-023 "Total elapsed time", F-021 "Structural contract", F-028 "Two-tier methodology", F-024 "Observation masking"
- Regression check: next.md orchestration flow, context dispatch, verification stage all functional.

**Abort conditions:** Any next.md section change breaks orchestration flow. If ANY of the 4 changes causes failure, revert ALL 4 and re-attempt as individual waves.

**Pre-requisites:** Wave 3 passed gate. Cockpit filter (R-015) is stable before adding elapsed time.

---

## Wave 5

**R-IDs:** R-005

**Rationale for grouping:** Solo wave — largest next.md structural change. Adds Wave 0 orchestration block (Nyquist Validation Layer) before Wave 1 dispatch AND modifies test-architect.md with phase-level input mode. Core dispatch logic change warrants full isolation.

**Independence proof:** Solo wave — no internal conflicts.

**Estimated scope:**
- `framework/commands/apex/next.md` — add Wave 0 block in build stage before Wave 1 dispatch (~30 lines)
- `framework/agents/test-architect.md` — add phase-level input mode (accepts PLAN_META.json, outputs WAVE_0_TEST_MAP.json) (~25 lines)

**Verification gate:**
- Test suite: next.md orchestration test, test-architect validation
- Smoke test: (1) Start L2+ phase → Wave 0 runs before Wave 1. (2) WAVE_0_TEST_MAP.json created at `.apex/phases/$PHASE/`. (3) Wave 0 veto → phase execution blocked with actionable message. (4) L1 project → Wave 0 skipped (minimal ceremony).
- Spec anchors re-checked: F-005 "Nyquist Validation Layer with Wave 0 enforcement"
- Regression check: Per-task test-architect still runs for C/D tasks (F.5 section). Phase dispatch timing unchanged for L1.

**Abort conditions:** Wave 0 blocks legitimate phase execution on any test project. Executor dispatch timing broken. Per-task test-architect (F.5) stops working.

**Pre-requisites:** Wave 4 passed gate. All previous next.md changes stable.

---

## Wave 6

**R-IDs:** R-012

**Rationale for grouping:** Solo wave — modifies next.md orchestration control flow (dream-cycle triggers). Affects when background agents spawn during time gates and context overflow.

**Independence proof:** Solo wave — no internal conflicts.

**Estimated scope:**
- `framework/commands/apex/next.md` — add dream-cycle trigger at 60-minute time gate and context-monitor WARNING_OVERFLOW path (~15 lines)

**Verification gate:**
- Test suite: next.md orchestration test
- Smoke test: (1) 60+ minutes elapsed + >10 files in memory primitives → dream-cycle triggers. (2) <10 files → dream-cycle skipped. (3) Pause/resume triggers still work unchanged.
- Spec anchors re-checked: F-012 "Memory Synthesis dream-cycle agent runs periodically"
- Regression check: next.md task advancement, time gate decisions, context-monitor flow.

**Abort conditions:** Dream-cycle trigger causes excessive token usage during normal execution. next.md task advancement breaks.

**Pre-requisites:** Wave 5 passed gate. Wave 0 (R-005) stable — dream-cycle must not interfere with Wave 0 dispatch.

---

## Wave 7

**R-IDs:** R-010

**Rationale for grouping:** Solo wave — audit+documentation pass across 3 files. Emoji consistency verification may require many scattered edits across next.md and status.md. Runs last so all functional changes are stable before cosmetic pass.

**Independence proof:** Solo wave — no internal conflicts.

**Estimated scope:**
- `framework/apex-branding.md` — add "Color Discipline" section with semantic emoji map (~20 lines)
- `framework/commands/apex/status.md` — verify/fix emoji consistency (~scattered edits)
- `framework/commands/apex/next.md` — verify/fix emoji consistency (~scattered edits)

**Verification gate:**
- Test suite: health-check tests (emoji audit added in Wave 2)
- Smoke test: (1) apex-branding.md has Color Discipline section. (2) Grep all command .md files: ✅ never used for unverified states. (3) session-log.sh emoji map matches branding canonical map.
- Spec anchors re-checked: F-010 "Color discipline"
- Regression check: status.md display, next.md output formatting unchanged in meaning.

**Abort conditions:** Emoji changes alter semantic meaning of existing outputs.

**Pre-requisites:** Wave 6 passed gate. All next.md functional changes stable before cosmetic pass.

---

## Execution Order

```
Wave 1 → Wave 2 → Wave 3 → Wave 4 → Wave 5 → Wave 6 → Wave 7
```

**Justification:**
1. **Wave 1 first:** All independent hooks/commands with zero next.md involvement. Clears 7 R-IDs with zero risk to the critical path. Highest R-ID throughput per session.
2. **Waves 2-7 follow next.md serialization order** per conflict matrix: R-014 → R-015 → R-023/R-021/R-028/R-024 → R-005 → R-012 → R-010. Each wave builds on verified stable state of previous next.md changes.
3. **Wave 5 (R-005 Wave 0) after small changes:** Largest structural change runs after all small additions are stable — reduces diagnostic noise on failure.
4. **Wave 7 (R-010 emoji audit) last:** Cosmetic pass after all functional changes — avoids re-auditing files modified by later waves.

---

## Pending Human Decisions (8 R-IDs, outside all waves)

| R-ID | Priority | Decision needed | Recommendation |
|------|----------|----------------|----------------|
| R-001 | P0 | Workflow-guard: Read matcher (noisy) vs explicit invocation (less coverage)? | Explicit invocation in workflow.md |
| R-002 | P0 | Spec owner accepts SQLite→"JSONL-ready" amendment? | Accept amendment |
| R-003 | P0 | Physical repo separation deferred to post-v1? | Defer, document logical boundaries |
| R-004 | P0 | (1) peer-review vendors or generic MCP? (2) Exact 6 pillars for ui-phase? | Generic MCP adapter; spec clarification needed |
| R-013 | P1 | AST-KB: auto-fire PostToolUse (slow) vs manual invocation? | Advisory PostToolUse |
| R-016 | P2 | APEX_ACTIVE_AGENT env var check overhead on every Read\|Bash? | Accept (microseconds per check) |
| R-020 | P1 | External AI: specific vendors, generic MCP, or manual copy/paste? | Manual copy/paste for v1 |
| R-026 | P1 | Which manual hooks become structural in settings.json? | Only phantom-check.sh |

**Impact:** These 8 R-IDs include ALL 4 P0 findings. Resolving them unlocks Wave 8+ with the highest-priority remediations.

**Suggested DAG for post-decision waves:**
```
Decision resolved → R-001 (solo wave, P0, creates 3 security files)
Decision resolved → R-003 (WONTFIX docs) → R-004 (solo wave, P0, 6 commands)
Decision resolved → R-026 (settings.json) → R-013 (new hook) → R-016 (quarantine-guard + next.md)
Decision resolved → R-020 (peer-review command)
```

---

## Deferred to Next Round (R2)

| R-ID | Reason |
|------|--------|
| R-009 | WONTFIX v1 — blocked by R-003 (module separation). Natural outcome of physical repo split. Zero action possible now. |
| R-019 | WONTFIX — 60-minute gate is within spec range "60-90 minutes". No code change needed. |
| R-022 | SUBSUMED by R-001 — workflow-guard is a subset of R-001's defense-in-depth fix. Automatically resolved when R-001 executes. |

---

## Completeness Check

| R-ID | Disposition |
|------|------------|
| R-001 | Pending human decision |
| R-002 | Pending human decision (WONTFIX) |
| R-003 | Pending human decision (WONTFIX v1) |
| R-004 | Pending human decision |
| R-005 | **Wave 5** |
| R-006 | **Wave 1** |
| R-007 | **Wave 1** |
| R-008 | **Wave 2** |
| R-009 | Deferred (WONTFIX v1) |
| R-010 | **Wave 7** |
| R-011 | **Wave 1** (verify only) |
| R-012 | **Wave 6** |
| R-013 | Pending human decision |
| R-014 | **Wave 2** |
| R-015 | **Wave 3** |
| R-016 | Pending human decision |
| R-017 | **Wave 1** |
| R-018 | **Wave 1** (verify only) |
| R-019 | Deferred (WONTFIX) |
| R-020 | Pending human decision |
| R-021 | **Wave 4** |
| R-022 | Deferred (subsumed by R-001) |
| R-023 | **Wave 4** |
| R-024 | **Wave 4** |
| R-025 | **Wave 1** (verify only) |
| R-026 | Pending human decision |
| R-027 | **Wave 1** |
| R-028 | **Wave 4** |

**All 28 R-IDs accounted for.** 17 scheduled in 7 waves. 8 pending human decisions. 3 deferred.
No wave has internal conflicts. Wave order is consistent with the DAG.
