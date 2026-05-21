# PinScope Wave Map — PS-R2

> Dependency-ordered, write-serial-safe. One file = one owner per wave.
> Source: `REMEDIATION-PLAN-R2.md`.

## Wave order

| Wave | R-items | Rationale |
|------|---------|-----------|
| **W1** | R-201 | Runtime primitives (constants, badge CSS, element-walker) — React-free dependency root. |
| **W2** | R-202 | Runtime hooks — depend on R-201. |
| **W3** | R-203, R-204 | Components + PinScope root. Disjoint file ownership. Internal order: R-203 → R-204 (root imports the components). |
| **W4** | R-205 | Test suite + DOM-env devDependencies + `npm install` + verification. |

## File ownership matrix (no conflicts)

| File | Owner | Wave |
|------|-------|------|
| `src/runtime/constants.ts`, `styles/badges.css.ts`, `utils/element-walker.ts` | R-201 | W1 |
| `src/runtime/hooks/useViewportSize.ts`, `useHoveredElement.ts`, `useDevState.ts` | R-202 | W2 |
| `src/runtime/components/PinBadges.tsx`, `InfoPanel.tsx` | R-203 | W3 |
| `src/runtime/PinScope.tsx` | R-204 | W3 |
| `src/index.ts` | R-204 | W3 |
| `tests/unit/runtime/**`, `package.json`, `vitest.config.ts` | R-205 | W4 |

No file has two owners → write-serial safe. `src/index.ts` was created by PS-R1
(R-105) but is solely owned by R-204 this round.

## Per-wave exit criteria

- **W1–W3 done:** `tsc --noEmit` (strict) passes on the full `src/` tree.
- **W4 done:** `npm install` succeeds; `npm test` exits 0 with **all** PS-R1
  tests still green plus the new runtime tests; `npm run typecheck` exits 0.

## Verification

`verifier` + `critic` re-run the `verify:` check of every AC the round claims.
A claim without a passing check stays `OPEN` in `STATUS.md`. AC-023 and AC-030
are explicitly NOT claimed (Playwright `verify:` deferred).

## Circuit breaker

No green `npm test` after 3 attempts, or any PS-R1 test regressing without a
fix → halt and escalate (`circuit-breaker.sh` semantics).
