# PinScope Wave Map — PS-R6

> Dependency-ordered, write-serial-safe. Source: `REMEDIATION-PLAN-R6.md`.

## Wave order

| Wave | R-items | Rationale |
|------|---------|-----------|
| **W1** | R-601, R-602 | Edge-case implementations — fully independent (disjoint files). |
| **W2** | R-603 | Tests + verification. |

## File ownership matrix (no conflicts)

| File | Owner | Wave |
|------|-------|------|
| `src/runtime/managers/RuntimePinObserver.ts` | R-601 | W1 |
| `src/runtime/utils/shadow-dom.ts`, `rect-math.ts`, `throttle.ts` | R-602 | W1 |
| `tests/unit/runtime/edge-cases.test.ts`, `tests/unit/edge-utils.test.ts` | R-603 | W2 |

No file has two owners → write-serial safe.

## Per-wave exit criteria

- **W1 done:** `tsc --noEmit` clean on `src/`.
- **W2 done:** `npx vitest run` green — all 192 PS-R1–R5 tests plus the new
  edge-case suites.

## Verification

AC-025 (happy-dom MutationObserver integration), AC-060 (shadow-root
integration), AC-062 (SVG-fixture unit), AC-065 (throttle perf/unit). All
headless. A claim without a passing check stays `OPEN`.

## Circuit breaker

No green verification after 3 attempts, or a PS-R1–R5 regression → halt.
