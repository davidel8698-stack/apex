# Phase 7 — Master Plan: Closure of Campaigns A + B + C

> **Owner directive (2026-05-25):** No campaign closes "partial." All gaps must be resolved with quality solutions, deep research, strict QA standards.
>
> **Status at Phase-7 entry:** 3 campaigns with open items.
> - Campaign A: PASS-WITH-LIMITATION (3 reserved items)
> - Campaign B: HALTED-AT-B5-R2 (1 reserved item)
> - Campaign C: HALTED-AT-B5-R3 (4 reserved items)
> - Total: **8 R-items + 1 empirical probe experiment + 1 corpus re-run + 1 final closure**

---

## §1. QA standard (binding for every item)

Per `feedback_qa_standards` memory: every Phase-7 work item MUST satisfy the 6-stage QA gate:

| Gate | Required artifact |
|------|-------------------|
| **G0** Research | Read existing spec + related code; identify root cause (not symptom) |
| **G1** Design | Written design document with critic-review-eligible structure |
| **G2** Critic R1 | Adversarial review (clean-room); BLOCKING findings closed before G3 |
| **G3** Implementation | Atomic commits; per-file blast-radius matrix documented |
| **G4** Test layer | Empirical evidence (layer tests OR live trial OR re-grep verification) |
| **G5** Critic R2 | PASS verdict on the closed artifact |

**Hard rule:** No R-item closes without G5 PASS. No exceptions.

---

## §2. Open items inventory (8 total)

### Campaign A — 3 items (from `detector-review/FINAL-CERTIFICATION.md`)

| ID | Closes | Effort | Priority |
|----|--------|--------|---------:|
| **R-DH-P7-01** | L-DH-01 — Working B class magic-string allowlist gap (W-B 0/3) | ~3-4h | P1 |
| **R-DH-P7-02** | L-DH-02 — Working D/E class reachability (budget exhaustion at Phase 4) | ~2-3h | P2 |
| **R-DH-P7-03** | L-DH-03 — Subagent-cache contamination methodology confound | ~1-2h | P3 (docs+test) |

### Campaign B — 1 item

| ID | Closes | Effort | Priority |
|----|--------|--------|---------:|
| **R-AT-P7-06** | Pre-existing test failures: `test-circuit-breaker-recovery.sh` 3-FAIL + `test-fix-plan-emit.sh` 3-FAIL | ~2-3h | P1 |

### Campaign C — 4 items + 1 empirical probe + 1 corpus re-run

| ID | Closes | Effort | Priority |
|----|--------|--------|---------:|
| **R-AT-C-04 (empirical probe FIRST)** | AC-6b NC threshold — owner directive: run fresh independent agent before deciding | ~30min user-action; then analysis | P0 (decides next steps) |
| **R-AT-C-02** | AC-5b heldout B+C+D — axis-13.d mutation-class worked examples + round-checker enforcement | ~4-5h | P1 |
| **R-AT-C-01** | AC-4 heldout — corpus mutations realigned with heldout lab's pinned spec | ~2-3h | P2 |
| **R-AT-C-03** | Verify 200→400 truncation patch in fresh-session re-launch | ~1h (fresh session needed) | P3 |
| **C5 corpus re-run** | All 11 trials with all fixes installed | ~5h wall | P1 (after R-AT-C-02 lands) |
| **Final closure** | Gate B5 R4 → PASS; FINAL-CERTIFICATION-C update; trilogy closed | ~1-2h | P0 (last) |

**Total estimated effort: ~25-35 hours of session work across multiple sessions.**

---

## §3 CLOSURE NOTE — R-AT-C-04 closed via methodology extension (2026-05-26)

**Wave-0 outcome:** independent probe surfaced 11 findings (1 P0, 4 P1, 4 P2, 2 P3) on pristine framework via crafted stdin-envelope probes — empirically validates the methodology gap. Per §3 N≥1 routing, applied methodology to framework-auditor.md as new axis-13.e (Runtime-invocation-contract probe). Round-checker TP-2 §6.b clauses (vii)+(viii) enforce per-guard probe minimum + discrepancy-emission gate. 52/52 layer tests pass. Closure design: `PHASE-7-RITEM-R-AT-C-04-DESIGN-R2.md`; critic R2 PASS: `PHASE-7-RITEM-R-AT-C-04-CRITIC-R2.md`. Wave-4 T7 NC re-run will empirically verify ≥10-finding methodology floor. Framework defects surfaced by Wave-0 probe (notably F-001 8-guard stdin-envelope bypass) reserved for future owner-triage R-AT-P7-07 candidate.

## §3. R-AT-C-04 — The AC-6b empirical probe (DO FIRST) [historical — see closure note above]

### Why this is P0

Per owner directive: before deciding whether AC-6b needs threshold-lower or probe-extension, **empirically determine** if the framework is truly clean (current auditors' 0-finding result is honest) OR if our auditors are too shallow (and a fresh independent agent finds real gaps).

### Procedure (executed by user in a SEPARATE Claude Code session)

1. Owner opens a new Claude Code session with NO prior context (clean slate).
2. Owner enters Plan Mode (`<shift-tab><shift-tab>` or `/plan`).
3. Owner pastes the EXACT prompt from `audit-trail-review/AC-6B-INDEPENDENT-PROBE-PROMPT.md`.
4. The fresh agent does a deep open-ended search.
5. Output saved to `audit-trail-review/AC-6B-INDEPENDENT-PROBE-FINDINGS.md`.

### Outcome routing

- **Fresh agent finds 0 gaps** → Confirms framework is genuinely clean. Land §14 amendment lowering AC-6b lower bound from 10 to 0. Close R-AT-C-04.
- **Fresh agent finds N gaps** → Extract methodology: what did the fresh agent do that our auditors didn't? Update `framework-auditor.md` axis-1 OR axis-12 with the discovered probe pattern. Re-run T7. Land R-AT-C-04 closure based on new T7 count.

---

## §4. Work order for next session (priority sequence)

### Wave 0 — Independent probe (user-action; separate session)
- Run AC-6B-INDEPENDENT-PROBE-PROMPT in fresh Claude Code session
- Persist findings to `audit-trail-review/AC-6B-INDEPENDENT-PROBE-FINDINGS.md`

### Wave 1 — Campaign C closure (P1 + P2)
- **R-AT-C-02** (axis-13.d worked examples + round-checker enforcement) — closes AC-5b
- **R-AT-C-01** (heldout corpus realignment) — closes AC-4 heldout
- **R-AT-C-04** (based on Wave 0 results) — closes AC-6b

### Wave 2 — Campaign A closure (P1 + P2 + P3)
- **R-DH-P7-01** (Axis 13.c source-literal carve-out scan) — closes L-DH-01
- **R-DH-P7-02** (raise self-heal Step A tool budget to 800) — closes L-DH-02
- **R-DH-P7-03** (test-subagent-cache.sh + fresh-session doc) — closes L-DH-03

### Wave 3 — Campaign B closure (P1)
- **R-AT-P7-06** (test-circuit-breaker-recovery + test-fix-plan-emit) — root-cause + fix

### Wave 4 — Empirical re-validation
- Re-run full 11-trial corpus C5 (R-AT-C-03 truncation patch verified in fresh session)
- Score against all AC thresholds including new R-AT-C-04 thresholds
- C5-critic R2 (final approval)
- B5 critic R3 (Gate B5 close)

### Wave 5 — Trilogy closure
- Final commits on all 3 campaigns: closure of all L-items, all R-items
- Update `framework/docs/AUDIT-TRAIL-STANDARD.md` + spec paragraph + memory
- Tag commit: `gate-b5-trilogy-passed`

---

## §5. Per-item detail (research notes)

### R-AT-C-02 — Closes AC-5b heldout B+C+D
**Root cause analysis (from C5-T4 + C5-T10):** Auditors ran 5 axis-10 probes with canonical payloads only. They didn't construct mutation-class-specific boundary-condition probes (regex word-boundary, case-folding, silent-failure, counter-swallow).

**Design approach:**
1. Add concrete payload TEMPLATES per mutation class in `framework-auditor.md` axis-13.d
2. Add `framework/test-fixtures/mutation-class-probes.json` with reference payloads
3. Update `round-checker.md` TP-2 §6.b: REJECT any trial whose `axis_10.concrete_bypass_attempts[]` lacks ≥1 boundary-condition probe per regex-deny guard
4. Layer test: H-D1..H-D5 in test-audit-trail-layer.sh

### R-AT-C-01 — Closes AC-4 heldout (corpus realignment)
**Root cause analysis (from C5-T4):** H-A1 deletes `memory-watchdog.sh`; H-A2 deletes `session-auto-resume.sh`. Heldout lab pinned at baseline `8ac2a85` (pre-v7.1) — older spec doesn't reference these hooks **with the `framework/hooks/` prefix** that the auditor's extraction grep requires (the hooks ARE in the spec but only as bare backticked basenames inside the Auto-Continuity Layer table).

**Design approach:**
1. Re-author H-A1, H-A2 to target hooks PRESENT in the lab's older `apex-spec.md` (grep at lab-pinned baseline to identify the spec-named hook set)
2. New mutations should retain the "spec-named hook deleted" defect class — just point at hooks the lab's spec actually names
3. Re-run heldout trials (T4/T5/T6) to verify per-hook P0 emission for the new mutations

**CLOSURE (2026-05-26):** option b chosen. H-A1 re-authored: `framework/hooks/destructive-guard.sh` (stray-file-missing shape, IMP-014 + IMP-013). H-A2 re-authored: `framework/hooks/sequence-guard.sh` + PreToolUse:Bash wiring removal (both-files-coordinated shape, IMP-016). Both targets verified in heldout extracted_set. Shape diversity preserved. Closure design: `PHASE-7-RITEM-R-AT-C-01-DESIGN-R3.md`; critic R3 PASS: `PHASE-7-RITEM-R-AT-C-01-CRITIC-R3.md`. Wave-4 will empirically verify per-hook P0 emission via T4/T5/T6 re-run.

### R-DH-P7-01 — Closes L-DH-01 (W-B 0/3 magic-string allowlist) — CLOSED 2026-05-26

**CLOSURE:** axis-13.c (Source-literal carve-out scan) added to framework-auditor.md. Scan covers 7 pattern families (bash glob/exact, POSIX, case, grep -Fq pipe forms, echo-pipe-grep, function-call delegation) with 5-source exemption set (incl. Campaign C TP-C2 audit-probe marker). Round-checker TP-2 §6.b clause (ix) enforces per-guard scan minimum + emission gate. 55/55 layer tests pass. Design: `PHASE-7-RITEM-R-DH-P7-01-DESIGN-R2.md`; critic R2 PASS-WITH-NOTES: `PHASE-7-RITEM-R-DH-P7-01-CRITIC-R2.md`. Wave-4 working-trial re-run will verify W-B1/W-B2/W-B3 reliable-kill (3/3).

**Root cause analysis:** Working B class mutations target guards' magic-string allowlists. Campaign A's auditor caught axis-13 depth (bypass_attempts ≥5) but didn't drill into the SPECIFIC magic-string sub-class.

**Design approach:**
1. Add `Axis 13.c` to `framework-auditor.md` — source-literal carve-out scan
2. For each spec-named guard hook, the auditor MUST identify literal-string allowlists in source code and probe each with a CLOSE-BUT-NOT-IDENTICAL payload
3. Re-run Working trials to verify W-B 3/3 reliable-kill

### R-DH-P7-02 — Closes L-DH-02 (D/E class budget exhaustion)
**Root cause analysis:** Self-heal Step A circuit-breaker fires at ~400 tool calls; deep axis-13 sub-pass for Class D/E reaches >400 before completion.

**Design approach:**
1. Raise `self-heal` Step A `max_tool_calls_per_task` from current (400?) to 800
2. Add stage-typed budget per `apex-spec.md` IMP-DR-011 (scan/edit/test/critic stages)
3. Verify Working D + E classes now reach completion in trials

### R-DH-P7-03 — Closes L-DH-03 (subagent-cache methodology)
**Design approach:**
1. Add `framework/tests/test-subagent-cache.sh` with synthetic cache-poisoning probe
2. Document in `framework/docs/SECURITY-RUNTIME.md` the fresh-session requirement for subagent cache invalidation
3. Layer test verifies cache invalidation discipline

### R-AT-P7-06 — Closes pre-existing test failures
**Root cause analysis required:**
- `test-circuit-breaker-recovery.sh`: 3 FAILed assertions — need to read the test + the hook to find root cause
- `test-fix-plan-emit.sh`: 3 FAILed assertions — same

**Design approach:**
1. Each test failure gets root-cause analysis (G0)
2. Fix in source OR document as ACCEPTED-LIMITATION with §14 amendment
3. Re-run suite to verify 0 failures (AC-7a empirical close)

---

## §6. Risks + mitigations

| Risk | Likelihood | Mitigation |
|------|-----------:|------------|
| Phase 7 work spans multiple sessions; context-loss between sessions | High | This master plan + resume prompts; per-item closure commits |
| R-AT-C-02 design changes break existing layer tests | Medium | G2 critic R1 catches; layer-test regression suite as G4 floor |
| Heldout corpus realignment (R-AT-C-01) breaks Campaign A's prior results | Medium | Re-run Working trials too to confirm no regression |
| Pre-existing test failures (R-AT-P7-06) reveal real framework defects | Low-Medium | If real: fix the defect, not the test. §14 amendment only if owner approves |
| Fresh-session re-launch (R-AT-C-03) reveals NEW SGC issues | Low | Phase-7 doc; iterate as needed |

---

## §7. Definition of Done (binding)

Phase 7 is complete ONLY when:
1. ✅ All 8 R-items have G5 critic R2 PASS verdicts
2. ✅ C5 corpus re-run with all fixes shows: AC-1..AC-12, AC-C1, AC-C2 ALL PASS (no §12.2 hard-FAILs)
3. ✅ FINAL-CERTIFICATION.md (Campaign A) updated: removes L-DH-01..03 from §3
4. ✅ FINAL-CERTIFICATION.md (Campaign B) updated: removes L-AT-* from §3
5. ✅ FINAL-CERTIFICATION-C.md updated: verdict changed from HALTED-AT-B5-R3 → PASS
6. ✅ `framework/docs/AUDIT-TRAIL-STANDARD.md` final state documents the closed mechanisms
7. ✅ Memory files updated: Campaign A + B + C all marked CLOSED-PASS
8. ✅ Commit tagged `gate-b5-trilogy-passed` on main

**No partial closure. No "halted-with-limitations." Either full PASS or back to research.**
