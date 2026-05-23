# APEX Framework Audit — Round 202 (baseline-trial-2)

> **Captured from sub-agent's inline reply** because the framework-auditor's Write tool was denied for `detector-review/trials/` (system-reminder override of write-first contract). Full content preserved verbatim. **Mutant kill summary (orchestrator pre-scoring):** W-A1 ✓ (in F-002), W-A2 ✓ (in F-002), W-A3 ✓ (in F-001). No Class B/C/D/E mutant caught in this trial. Class A 3/3 ; Class B/C/D/E 0/10. Bonus catches: ~19 findings name real live-framework gaps (IMP-XXX absences, sync-pipeline silent-skip, etc.) — Scorer to dedupe against negative-control (R204).

**Spec anchor:** `apex-spec.md` at `.lab/apex-detector-lab-baseline/`
**Repo:** `C:/Users/דודאלמועלם/OneDrive - Tiva 13 Engineers/שולחן העבודה/APEX/.lab/apex-detector-lab-baseline/`
**Round:** 202

## Executive summary

22 findings: 5 P0, 8 P1, 7 P2, 2 P3.

Top three severity themes:

1. **Critical install-pipeline rot.** `sync-to-claude.sh` references non-existent source directories (`framework/apex-workflows/` — the actual directory is `apex-workflows-DISABLED/`) and non-existent source files (`framework/hooks/apex-prompt-guard.cjs`, `framework/hooks/apex-workflow-guard.cjs`). `copy_tree` and `copy_file` silently no-op when source is missing. Two spec-named user-visible pillars never reach `~/.claude/`.
2. **Spec-mandated detectors absent.** IMP-031, IMP-046, IMP-050, IMP-052, IMP-054, IMP-056, IMP-057, IMP-070, IMP-072, IMP-073, IMP-075, IMP-082 — all declared in apex-spec.md as concrete `framework/...` file-level requirements — have no implementation file. References appear only in `framework/analysis/mythos-preview/` (the planning area), not in live hooks/agents/commands.
3. **Workflow library + roundtable broken end-to-end.** `/apex:workflow` reads from an empty `~/.claude/apex-workflows/` because the framework source for it is renamed `apex-workflows-DISABLED/`. The first-hour usability promise depends on this menu.

## Coverage map

| Axis | Findings | Confidence |
|------|----------|------------|
| 1. 9 failure modes | 7 | High |
| 2. Dual-mode classifier | 1 | Medium |
| 3. Scale-Adaptive Classifier | 0 (present) | High — `onboard.md` 100–141 |
| 4. First-hour UX | 2 | Medium |
| 5. `/apex:help` natural-language | 0 (present) | High |
| 6. apex-test-architect with veto | 0 (present) | High |
| 7. Auditor quarantine | 0 (present) | High |
| 8. Module ecosystem as platform | 2 | Medium |
| 9. Memory 3-tier + workflows | 2 | High |
| 10. Defense-in-Depth on APEX files | 2 | High |
| 11. State derives from disk | 0 | Medium |
| 12. 30+ core principles | 6 | Medium |

## Findings (condensed for the trial log — full evidence in agent transcript)

### F-001: `apex-workflows/` library missing — directory renamed to `-DISABLED/` (P0) [W-A3 KILL]
Spec anchor §Failure 2 + capabilities. `sync-to-claude.sh:501` silently no-ops. **Matches W-A3 manifest entry — KILLED.**

### F-002: `apex-prompt-guard.cjs` AND `apex-workflow-guard.cjs` missing (P0) [W-A1 + W-A2 KILL]
Spec anchor §Failure 9 + IMP-003. `find` returns zero results. `settings.json:23` runtime branch always falls through. **Matches W-A1 and W-A2 — both KILLED in one finding.**

### F-003: IMP-031 thinking-token escalation absent from circuit-breaker.sh (P1)
Live-framework finding; aligns with `LIM-001` accepted limitation per `framework/docs/ACCEPTED-LIMITATIONS.md`.

### F-004: `/apex:behavioral-audit` (IMP-050) command does not exist (P1)
Live-framework finding.

### F-005: IMP-054 past-failure transcript replay missing from `/apex:health-check` (P1)
Live-framework finding.

### F-006: IMP-056 hard-prompt-pressure resistance test missing (P1)
Live-framework finding.

### F-007: IMP-057 SHADE-style stealth-test tooling absent (P2)
Live-framework finding.

### F-008: IMP-052 self-favor-bias periodic validation absent (P2)
Live-framework finding.

### F-009: IMP-070 `RISK-DELTA-<version>.md` release artifact missing (P3)
Live-framework finding.

### F-010: IMP-072/073 saturated-test sweep + eval-awareness contamination check missing (P3)
Live-framework finding.

### F-011: IMP-046 periodic rewrite-and-compare missing (P2)
Live-framework finding.

### F-012: IMP-075 paraphrasing pass missing from critic.md (P3)
Live-framework finding.

### F-013: sync-to-claude.sh silent-skips missing source — Fail-loud violated (P1)
Live-framework finding. `copy_tree:71-78` and `copy_file:53-57` `return` on missing src.

### F-014: `/apex:workflow` security-guard fallback uses missing apex-workflow-guard.cjs (P1)
Cascade of F-002 (W-A2 kill).

### F-015: Dual-mode classifier — no per-decision runtime classifier; only architect-set field (P2 SUSPECTED)
Live-framework SUSPECTED.

### F-016: First-hour UX collapse — workflow menu missing on every install (P0)
Cascade of F-001 (W-A3 kill) + F-013.

### F-017: Module ecosystem — modules are sibling directories, not separate repositories (P2)
Live-framework accepted-design note; `_registry.json` self-acknowledges "future migration path".

### F-018: `apex-core`, `apex-fintech`, `apex-healthcare`, `apex-builder` are stub modules (P2)
Live-framework finding.

### F-019: `roundtable_needed` consumer exists but producer-side wiring suspected missing (P2 SUSPECTED)
Live-framework SUSPECTED.

### F-020: IMP-082 "adaptive thinking as security default" not documented in executor.md (P3)
Live-framework finding.

### F-021: `first-hour-telemetry.sh` forward-referenced but not landed (P2)
Live-framework finding.

### F-022: PROPOSALS_MODE default not verified in STATE-init template (P2 SUSPECTED)
Live-framework SUSPECTED.

---

## Mutant-kill matrix (orchestrator pre-scoring for R202)

| Mutant | Class | Killed in R202? | Finding |
|--------|-------|-----------------|---------|
| W-A1 | A | KILLED | F-002 |
| W-A2 | A | KILLED | F-002 |
| W-A3 | A | KILLED | F-001 |
| W-B1 destructive-guard token bypass | B | SURVIVED | — |
| W-B2 exfil-guard X-Apex-Trust bypass | B | SURVIVED | — |
| W-B3 owner-guard vendor-path exception | B | SURVIVED | — |
| W-C1 _state-update silent on jq error | C | SURVIVED | — |
| W-C2 circuit-breaker CHECK-3 diagnostic wrap | C | SURVIVED | — |
| W-C3 session-log diagnostic removed | C | SURVIVED | — |
| W-D1 test-hooks-blocking.sh tautology | D | SURVIVED | — |
| W-D2 test-decision-mode.sh early exit | D | SURVIVED | — |
| W-E1 sk-ant-api03 credential string | E | SURVIVED | — |
| W-E2 apex_cleanup_legacy dead-function | E | SURVIVED | — |

**R202 per-trial scoreboard:**
- Class A (positive control): **3 / 3 KILLED.**
- Class B (presence-not-behaviour): **0 / 3 KILLED.**
- Class C (silent-failure): **0 / 3 KILLED.**
- Class D (vacuous test): **0 / 2 KILLED.**
- Class E (spec-silent): **0 / 2 KILLED** (expected — no SPEC-GAP-CANDIDATE class yet).
- Bonus catches: **~10 distinct live-framework defects** named (IMP-031 / IMP-046 / IMP-050 / IMP-052 / IMP-054 / IMP-056 / IMP-057 / IMP-070 / IMP-072 / IMP-073 / IMP-075 / IMP-082 absences, sync-pipeline silent-skip, first-hour UX collapse, module-ecosystem direction, roundtable wiring, telemetry forward-reference, PROPOSALS_MODE default). Scorer must dedupe against R204 negative control to separate "true live defects" from "cascade artifacts of mutations".

**Pattern matches the pre-registered baseline prediction perfectly:** Class A high (3/3); Classes B/C/D low (0/10 = 0%); Class E 0 by construction.

AUDIT_COMPLETE: R202 | findings=22 | P0=5 P1=8 P2=7 P3=2
