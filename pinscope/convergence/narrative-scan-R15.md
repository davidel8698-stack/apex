# Narrative Coverage Scan — PS-R15

- **Round:** 15
- **Spec:** pinscope/SPEC.md v2.0.0 (`sha256:1779526021db1f5bc7ffe36647e6deb08ba3f8234e82cee31dc0bca5357c7a45`, unchanged from R14)
- **Scope:** §1–§17 narrative claims vs. `pinscope/src`, `pinscope/tests`, the `framework/` files of §17, and `ac-matrix.json`.

## Coverage summary

52 normative narrative claims (2 non-normative: NC-03-01, NC-16-01).
**33 covered** by an Appendix-A AC whose check would fail on violation;
**19 uncovered**. Of the uncovered, **10 are already satisfied by the code**
(proposed as candidate ACs — paperwork only) and **9 are NOT satisfied** —
real un-AC'd code gaps raised as **blocking findings NF-15-01..09**. 6
strengthen proposals target ACs that exist but under-check their claim.

`uncovered_unsatisfied (9) == blocking_findings.length (9)` — the convergence
gate must not declare convergence while these 9 stand.

All 8 R14 blocking findings were re-checked against current code: every gap
still exists (no remediation landed). **One new blocking finding this round:**
NF-15-09 (NC-15-02) — R14 marked the `withPinScope` re-export `unknown`
without re-reading `src/index.ts`; a re-read this round confirms the gap.

## Blocking findings (9) — real un-AC'd code gaps, remediate this round

| ID | Claim | §  | Sev | Gap |
|----|-------|----|-----|-----|
| NF-15-01 | NC-07-01 | §7.1 | P1 | `<PinScope/>` mounts only PinBadges + InfoPanel; Rulers/Crosshair/GridOverlay/TopBar/CommandBar never rendered by the root. |
| NF-15-02 | NC-07-02 | §7.1 | P2 | `PinScopeProps` lacks `defaultGridMode` and `shortcutsEnabled`. |
| NF-15-03 | NC-07-03 | §7.1 | P2 | No `FloatingToggle` and no HUD-hidden branch — the hidden-HUD behaviour is unimplemented. |
| NF-15-04 | NC-08-07 | §8.6 | P2 | CommandBar height is a fixed 40px; no focus-driven expand to 120px. |
| NF-15-05 | NC-08-09 | §8.6 | P2 | CommandBar has no Tab branch and never uses `autocomplete.ts`. |
| NF-15-06 | NC-08-11 | §8.8 | P2 | StatePanel only toggles `data-state-override`; no host-stylesheet scan to auto-generate override rules. |
| NF-15-07 | NC-10-01 | §10-D | P2 | Snapshot persistence has no `/__pinscope/snapshot` dev-server endpoint. |
| NF-15-08 | NC-12-01 | §12 | P1 | Badge CSS (`::before`, z-index, color rules) carries no `!important`; hostile host CSS can override badges. |
| NF-15-09 | NC-15-02 | §15 | P1 | `src/index.ts` does not re-export `withPinScope` (§15 lists it; AC-091 does not check it). |

Each finding's `re_read` proof is in `narrative-scan-R15.json` — e.g. NF-15-08:
*"Read src/runtime/styles/badges.css.ts (full file): the sole `!important` rule
is `[data-pinscope-ui] { outline: none !important }`."*

## Claims by section

### §1, §4 — Mission & Stack
- NC-01-01 success-metric 95%≤2-rounds — covered AC-107 (population rate unmeasured, `unknown`).
- NC-04-01 dev bundle <80KB/<25KB — covered AC-073, satisfied.
- NC-04-02 prod bundle 0 bytes — covered AC-010/AC-074, satisfied.
- NC-04-03 React-hooks-only, no Redux/Zustand — uncovered, satisfied → candidate AC-NEW-01.

### §6 — Build-Time Module
- NC-06-01 plugin shape — covered AC-001.
- NC-06-02 PinScopeOptions defaults — uncovered, satisfied → AC-NEW-02.
- NC-06-03 buildStart/buildEnd lifecycle — uncovered, satisfied → AC-NEW-03.
- NC-06-04 babel plugin set — uncovered, satisfied → AC-NEW-04.
- NC-06-05 loc-absent skip — uncovered, satisfied → AC-NEW-05.
- NC-06-06 source map emitted — covered AC-011.
- NC-06-07 dirty-gated save — uncovered, satisfied → AC-NEW-06.
- NC-06-08 getOrAssign un-delete/last_seen refresh — uncovered, satisfied → AC-NEW-07.
- NC-06-09 deleted:true, ID never reused — covered AC-008.
- NC-06-10 moved element → new ID — uncovered, satisfied → AC-NEW-08.

### §7 — Runtime Core
- **NC-07-01 full §7.1 HUD tree mounted — uncovered, UNSATISFIED → BLOCKING NF-15-01 / AC-NEW-09.**
- **NC-07-02 props defaultGridMode/shortcutsEnabled — uncovered, UNSATISFIED → BLOCKING NF-15-02 / AC-NEW-10.**
- **NC-07-03 HUD-hidden → FloatingToggle — uncovered, UNSATISFIED → BLOCKING NF-15-03 / AC-NEW-11.**
- NC-07-04 badge z-index/colors — covered AC-023 (under-checks → strengthen).
- NC-07-05 void overlay + MutationObserver — covered AC-024/AC-025.
- NC-07-06 rAF-throttled hover — uncovered, satisfied → AC-NEW-12.

### §8 — Components
- NC-08-01 InfoPanel geometry — uncovered, satisfied → AC-NEW-13.
- NC-08-02 empty values render em-dash — covered AC-033.
- NC-08-03 Rulers multi-scale ticks + corner coords — covered AC-034 but code lacks 10/50/100/200 tick set and corner coords (under-checked → strengthen).
- NC-08-04 Crosshair full disable set — covered AC-035 but code lacks measurement-mode / HUD-hidden guards (under-checked → strengthen).
- NC-08-05 GridOverlay 4 modes / cycle / pattern — covered AC-036, satisfied.
- NC-08-06 TopBar geometry + fields — covered AC-037, satisfied.
- **NC-08-07 CommandBar expand to 120px — uncovered, UNSATISFIED → BLOCKING NF-15-04 / AC-NEW-14.**
- NC-08-08 CommandBar history → .pinscope/history.json (1000) — covered AC-053 but CommandBar history is in-component useRef, never persisted (under-checked → strengthen).
- **NC-08-09 CommandBar Tab autocomplete — uncovered, UNSATISFIED → BLOCKING NF-15-05 / AC-NEW-15.**
- NC-08-10 MeasurementTool Alt-hover sibling distances — covered AC-039 but no altKey handler (under-checked → strengthen).
- **NC-08-11 StatePanel stylesheet auto-generation — uncovered, UNSATISFIED → BLOCKING NF-15-06 / AC-NEW-16.**
- NC-08-12 SnapshotManager exactly 32 styles — covered AC-042 but count unpinned (under-checked → strengthen).

### §9–§11 — Schemas, Flows, Operations
- NC-09-01 PinMap schema — covered AC-006.
- NC-09-02 Operation §9.3 schema — covered AC-052.
- **NC-10-01 snapshot via /__pinscope/snapshot — uncovered, UNSATISFIED → BLOCKING NF-15-07 / AC-NEW-17.**
- NC-10-02 hover <8ms — covered AC-071.
- NC-11-01 operation grammar — covered AC-050.
- NC-11-02 shortcut properties — covered AC-051.

### §12 — Edge Cases
- **NC-12-01 z-index reserve + !important hardening — uncovered, UNSATISFIED → BLOCKING NF-15-08 / AC-NEW-18.** (z-index reserve is OK; the `!important` hardening is the gap.)
- NC-12-02 >500-element 30fps + <16×16 skip — covered AC-065; throttle utility exists, badge components do not wire it (`code_satisfied: unknown`, non-blocking as covered).

### §13–§15 — Performance, Testing, Deployment
- NC-13-01 mount <50ms — covered AC-070.
- NC-13-02 parse <4ms — covered AC-072.
- NC-14-01 transformer suite ≥50 — covered AC-080.
- NC-14-02 parser suite ≥30 — covered AC-081.
- NC-15-01 export subpaths — covered AC-090.
- **NC-15-02 src/index.ts re-exports withPinScope — uncovered, UNSATISFIED → BLOCKING NF-15-09 / AC-NEW-19.**

### §17 — APEX Integration
- NC-17-01..05 (apex-skill, ui-phase, ui-review, architect/frontend skill, apex-spec) — all covered AC-100/102/103/104/105, satisfied.
- NC-17-06 round-trip average <2 — covered AC-107 (aggregate metric unmeasured, `unknown`).

## Candidate ACs (19) — proposals, do NOT block

AC-NEW-01..08 (build, all satisfied, carried over) and AC-NEW-13 (InfoPanel
geometry, satisfied) and AC-NEW-12 (rAF throttle, satisfied) are pure
paperwork — code already passes. **AC-NEW-09, 10, 11, 14, 15, 16, 17, 18, 19
would each be born `OPEN`** (`code_satisfied: false`) — they mirror the 9
blocking findings. Adoption of all 19 is a separate user-approved SPEC bump.

## Strengthen proposals (6)

AC-023 (badge z-index/colors), AC-034 (multi-scale ticks + corner coords),
AC-035 (measurement-mode/HUD-hidden crosshair guards), AC-039 (Alt-hover
sibling distances), AC-042 (exact 32-key count), AC-053 (CommandBar history
persistence to .pinscope/history.json). Each covering AC asserts presence
where the §1–§17 claim asserts a fuller behaviour; see `proposed_verify` in the
JSON.

## Verdict

The narrative is **not fully AC-covered**. 9 normative behaviours are both
un-AC'd and unimplemented — convergence must not be declared this round until
NF-15-01..09 are remediated. The 19 candidate ACs and 6 strengthen proposals
are advisory only.
