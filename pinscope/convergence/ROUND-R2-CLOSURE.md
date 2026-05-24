# Round Closure — PS-R2

**Round:** PS-R2 — runtime foundation (Cluster B) + public API
**Status:** CONVERGED (round scope met)
**Date:** 2026-05-21

## Outcome
The PinScope runtime foundation is built: the `<PinScope/>` root (portal,
production/disabled guards), `PinBadges`, `InfoPanel` (Dimensions / Spacing /
Typography), `useHoveredElement` (+ extracted `element-walker`), `useDevState`.
Verified by **100 passing tests** (86 PS-R1 carried forward with no regression
+ 14 new) and a clean strict typecheck.

## Acceptance criteria closed this round — 6
AC-020, AC-021, AC-022 (PinScope root) · AC-026, AC-027 (hover walker) ·
AC-091 (public API surface).

## Built but still OPEN — honest verification gap
- **AC-023** (`PinBadges` ::before) and **AC-030** (`InfoPanel` hover values)
  — the components exist and pass render-logic unit tests, but their SPEC
  `verify:` methods are Playwright (real browser CSS / layout). They remain
  `OPEN`; a dedicated Playwright + `examples/vite-react` round will close them.

## Convergence metric

| Round    | Closed | Total | %   |
|----------|--------|-------|-----|
| baseline | 0      | 69    | 0%  |
| PS-R1    | 20     | 69    | 29% |
| **PS-R2** | **26** | 69   | **38%** |

Monotonic increase 29% → 38%. ✓

## Circuit breaker
Not triggered. No finding stalled; no wave failed verification. `npm test`
green on the first verification attempt.

## Anti-pattern check
- **AP-006 "Unchecked Audit":** PS-R1's 20 closures were re-confirmed
  (`npm test` green, typecheck clean) before PS-R2 built on top — no closed AC
  trusted blindly across rounds.
- **No false closure:** AC-023 / AC-030 deliberately left `OPEN` rather than
  claimed from weak proxy checks.

## Scope note
`useViewportSize` was moved from PS-R2 to PS-R3 (it is first consumed by the
Rulers) to keep PS-R2 free of unexercised code.

## Next round — PS-R3 (proposed)
Two tracks:
1. **Cluster C visual tools** — Rulers, Crosshair, GridOverlay, TopBar
   (+ `useViewportSize`).
2. **Browser-verification track** — provision Playwright + `examples/vite-react`
   and close the accumulated browser-dependent ACs in a batch: AC-010, AC-023,
   AC-030, AC-034–037, AC-070–071.
Re-audit first per the loop contract.
