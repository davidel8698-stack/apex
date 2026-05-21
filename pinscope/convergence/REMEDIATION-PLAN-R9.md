# PinScope Remediation Plan — PS-R9 (terminal)

> Per `framework/docs/REMEDIATION-STYLE.md`. Scope: close the headless-
> verifiable remainder; reclassify the browser-only residual.

## Remediation R-901 — InfoPanel full section set
**Linked finding:** F-9-01 · **Severity:** P2 · **Spec anchor:** "InfoPanel"
(SPEC §8.1), AC-031/032/033.
### Ecosystem analysis
Rewrite `InfoPanel` with six collapsible sections (Dimensions, Spacing,
Typography, Appearance, Layout, Hierarchy). `CollapsibleSection` persists its
collapsed state to `localStorage`; `StyleRow` renders a swatch for color
values and `—` for empty ones. Existing `data-testid` hooks are preserved so
PS-R2's component tests keep passing.
### Execution plan
**Modify:** `src/runtime/components/InfoPanel.tsx`. **Rollback:** AC-031/032/033
tests fail or a PS-R2 test regresses.
### Acceptance criteria
- [ ] Appearance/Layout/Hierarchy sections render (AC-031).
- [ ] Section collapse persists via `localStorage` across remount (AC-032).
- [ ] Color values show a swatch; empty values show `—` (AC-033).
### Dependencies / Risk
None / Low–medium (must not regress PS-R2 InfoPanel tests).

## Remediation R-902 — Lazy screenshot capture
**Linked finding:** F-9-02 · **Severity:** P2 · **Spec anchor:** SPEC §4 +
resolution I-4, AC-076.
### Ecosystem analysis
`screenshot.ts` dynamically imports `html2canvas` so it never enters the
initial bundle. `html2canvas` is declared a runtime `dependency`.
### Execution plan
**Create:** `src/runtime/utils/screenshot.ts`. **Modify:** `package.json`
(add `html2canvas`). **Rollback:** AC-076 source/bundle check fails.
### Acceptance criteria
- [ ] `screenshot.ts` uses `import('html2canvas')`, never a static import;
  `html2canvas` is absent from the built `PinScope` entry (AC-076).
### Dependencies / Risk
None / Low.

## Remediation R-903 — APEX round-trip scenario + health check
**Linked finding:** F-9-03, F-9-04 · **Severity:** P2/P3 · **Spec anchor:**
SPEC §17, AC-106/107.
### Ecosystem analysis
`examples/roundtrip/` scripts the PinScope half of the APEX round-trip — a
structured Operation resolves a UI change deterministically in one round.
AC-106 is verified by running `framework/scripts/self-test.sh` (the core of
`/apex:health-check` TEST 0e) green with the Stage-1 PinScope edits in place.
### Execution plan
**Create:** `examples/roundtrip/scenario.ts`, `tests/unit/roundtrip.test.ts`.
**Verification:** `bash framework/scripts/self-test.sh`.
**Rollback:** self-test fails, or the round count exceeds 2.
### Acceptance criteria
- [ ] `self-test.sh` passes with the PinScope edits (AC-106).
- [ ] The scripted scenario resolves a change in ≤ 2 rounds (AC-107).
### Dependencies / Risk
None / Low–medium (self-test outcome).

## Remediation R-904 — Reclassify the browser-only residual + verify
**Linked finding:** F-9-05 · **Severity:** P3
### Ecosystem analysis
AC-061 (cross-origin iframe), AC-063 (`@media print`), AC-083 (visual
regression) genuinely need a browser engine — no honest headless check
exists. They move to `BLOCKED`, joining the existing browser-blocked set.
### Execution plan
**Modify:** `convergence/STATUS.md`. **Create:**
`tests/unit/runtime/infopanel.test.tsx`, `tests/unit/screenshot.test.ts`,
`convergence/CONVERGENCE-REPORT.md`.
**Verification:** `npm run typecheck` + `npx vitest run`.
**Circuit breaker:** no green verification after 3 attempts → halt.
### Acceptance criteria
- [ ] AC-031/032/033/076/106/107 verified; AC-061/063/083 `BLOCKED`;
  zero `OPEN` ACs remain; 241 prior tests still green.
### Dependencies / Risk
R-901..R-903 / Low.
