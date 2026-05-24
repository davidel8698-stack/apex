# Wave Results — PS-R2

All four waves **PASS**.

## W1 — R-201 runtime primitives
Created `src/runtime/constants.ts`, `styles/badges.css.ts`,
`utils/element-walker.ts` (`escapeHud`, `findPinnedAncestor` — pure DOM
walking, unit-testable without `elementFromPoint`). `tsc` clean.

## W2 — R-202 runtime hooks
Created `src/runtime/hooks/useHoveredElement.ts`, `useDevState.ts`.
Scope adjustment: `useViewportSize` moved to PS-R3 — it is not consumed until
the Rulers land, and PS-R2 keeps zero dead code.

## W3 — R-203 + R-204 components & root
Created `components/PinBadges.tsx`, `components/InfoPanel.tsx`, `PinScope.tsx`.
Updated `src/index.ts` (adds `PinScope`, `useDevState`).
`tsc --noEmit` (strict) clean across the full `src/` tree.

## W4 — R-205 tests + DOM env + verification
Added devDependencies: `react`, `react-dom`, `@testing-library/react`,
`happy-dom`, `@types/react`, `@types/react-dom`. `vitest`
`environmentMatchGlobs` routes `tests/unit/runtime/**` to `happy-dom`; the
build-module suites stay on `node`.

Verification — falsifiable checks:

| Check | Command | Result |
|-------|---------|--------|
| Strict typecheck | `npm run typecheck` | exit 0 |
| Full suite | `npx vitest run` | 8 files, **100 tests pass** |

No regression: all 86 PS-R1 tests still green. New runtime tests (14):
`element-walker.test.ts` (7), `pinscope.test.tsx` (3), `components.test.tsx`
(3), `public-api.test.ts` (1).

## Closed by this round
AC-020, AC-021, AC-022, AC-026, AC-027, AC-091.

## Built but NOT closed (honest)
AC-023 (`PinBadges`) and AC-030 (`InfoPanel`) — components implemented and
unit-tested for render logic, but their SPEC `verify:` is **Playwright**
(real `::before` rendering / computed-style hover), not provisioned this
round. They stay `OPEN` until a Playwright round.
