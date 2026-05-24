# Wave Results — PS-R6

Both waves **PASS**.

## W1 — R-601 + R-602 edge-case implementations
- `src/runtime/managers/RuntimePinObserver.ts` — MutationObserver assigning
  `e_r{N}` ids to runtime-added elements.
- `src/runtime/utils/shadow-dom.ts` — marks shadow hosts `data-pin-shadow`.
- `src/runtime/utils/rect-math.ts` — `elementRect`, SVG-aware via
  `getBBox` + `getCTM`.
- `src/runtime/utils/throttle.ts` — leading+trailing throttle, heavy-page
  thresholds, small-badge skip.

## W2 — R-603 verification
Created `tests/unit/runtime/edge-cases.test.ts` and `tests/unit/edge-utils.test.ts`.

| Check | Command | Result |
|-------|---------|--------|
| Strict typecheck | `npm run typecheck` | exit 0 |
| Full suite | `npx vitest run` | 18 files, **202 tests pass** |

No regression: all 192 PS-R1–R5 tests still green. New (10): edge-cases (5 —
runtime-id observer incl. live MutationObserver, shadow-host marking),
edge-utils (5 — SVG rect math, throttle, heavy-page heuristics).

## Closed by this round
AC-025 (runtime `e_r{N}` ids), AC-060 (Shadow DOM marking), AC-062 (SVG-aware
rect), AC-065 (heavy-page throttle + small-badge skip).
