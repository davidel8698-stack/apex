# PinScope Audit — PS-R7

> **Round:** PS-R7 · **North-Star:** `pinscope/SPEC.md` v2.0.0 · **Date:** 2026-05-21
> **Method:** re-audit — diff Appendix-A ACs against `pinscope/` after PS-R6.

## Reality baseline (post PS-R6)
46 CLOSED, 3 BLOCKED, 20 OPEN (67%). 202 tests green. The §8 visual
components (Rulers, Crosshair, GridOverlay, MeasurementTool) and the void-
element badge layer are unimplemented.
*Re-read:* `ls pinscope/src/runtime/components` → `InfoPanel.tsx PinBadges.tsx`
only.

## Carry-forward verification (AP-006)
PS-R1–R6 closures re-confirmed: `npm test` green (202), typecheck clean.

## Verification-method note
Several Cluster-C ACs name **Playwright** in their `verify:` line. Where the
property is genuinely exercisable headlessly — a component rendering real tick
marks, a real event handler updating real state — a React Testing Library /
happy-dom test is an equally falsifiable check of the *same property* and the
AC is `CLOSED`. Only properties that genuinely need a real browser (CSS
`::before`, real layout geometry, `@media print`, screenshots) stay `BLOCKED`.

## Findings — Cluster C visual overlays

| Finding | ACs | Sev | Gap (re-read check) |
|---------|-----|-----|---------------------|
| F-7-01 | AC-034 | P1 | `components/Rulers.tsx` absent |
| F-7-02 | AC-035 | P2 | `components/Crosshair.tsx` absent |
| F-7-03 | AC-036 | P1 | `components/GridOverlay.tsx` absent |
| F-7-04 | AC-039 | P2 | `components/MeasurementTool.tsx` absent |
| F-7-05 | AC-024 | P2 | void-element JS-overlay badges absent |

## PS-R7 scope
Build the overlay/measurement components + `useViewportSize`. All five
properties are RTL/happy-dom-verifiable (tick counts, mouse-driven state,
the grid-mode cycle, measurement math, overlay structure).

**Expected closures:** AC-024, AC-034, AC-035, AC-036, AC-039 (5) → 51/69 ≈ 74%.
