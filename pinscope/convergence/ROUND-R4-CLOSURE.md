# Round Closure — PS-R4

**Round:** PS-R4 — deployment surface + performance
**Status:** CONVERGED (round scope met)
**Date:** 2026-05-21

## Outcome
The deployment surface is complete (`pinscope/next`, `pinscope/webpack`), a
`dist/` build makes every export-map subpath resolve, `size-limit` guards the
bundle budget, and the two runtime performance checks pass. Verified by **188
passing tests**, a clean strict typecheck, and `size-limit` (1.21 kB / 80 kB).

## Acceptance criteria closed this round — 5
AC-070 (mount < 50 ms), AC-071 (hover per-frame < 8 ms), AC-073 (dev bundle
`size-limit`), AC-090 (export-map resolution), AC-092 (Next/Webpack wrappers).

## Convergence metric

| Round | Closed | Total | %   |
|-------|--------|-------|-----|
| PS-R1 | 20     | 69    | 29% |
| PS-R2 | 26     | 69    | 38% |
| PS-R3 | 33     | 69    | 48% |
| **PS-R4** | **38** | 69 | **55%** |

Monotonic increase 48% → 55%. ✓

## Circuit breaker
Not triggered. Verification green on the first attempt.

## Next round — PS-R5 (proposed)
`examples/vite-react` — a real Vite + React app instrumented with PinScope,
built in production mode to verify zero PinScope bytes reach `dist/` (AC-010,
AC-074). Author the Playwright e2e suite (§14 checklist) as a CI deliverable;
AC-082 and the other browser-dependent ACs move to `BLOCKED` once their
implementations + specs land.
