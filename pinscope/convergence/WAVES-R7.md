# PinScope Wave Map — PS-R7

> Dependency-ordered, write-serial-safe. Source: `REMEDIATION-PLAN-R7.md`.

## Wave order

| Wave | R-items | Rationale |
|------|---------|-----------|
| **W1** | R-701, R-702, R-703 | Visual overlay components — disjoint files, independent. |
| **W2** | R-704 | Tests + verification. |

## File ownership matrix (no conflicts)

| File | Owner | Wave |
|------|-------|------|
| `src/runtime/hooks/useViewportSize.ts`, `components/Rulers.tsx`, `components/Crosshair.tsx` | R-701 | W1 |
| `src/runtime/components/GridOverlay.tsx` | R-702 | W1 |
| `src/runtime/components/MeasurementTool.tsx`, `components/VoidBadges.tsx` | R-703 | W1 |
| `tests/unit/runtime/overlays.test.tsx` | R-704 | W2 |

No file has two owners → write-serial safe.

## Per-wave exit criteria

- **W1 done:** `tsc --noEmit` clean on `src/`.
- **W2 done:** `npx vitest run` green — all 202 PS-R1–R6 tests plus the overlay
  suite.

## Verification

AC-034/035/036/039/024 — RTL / happy-dom render + event tests. A claim without
a passing check stays `OPEN`.

## Circuit breaker

No green verification after 3 attempts, or a PS-R1–R6 regression → halt.
