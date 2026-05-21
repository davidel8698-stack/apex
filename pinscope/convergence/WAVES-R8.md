# PinScope Wave Map — PS-R8

> Dependency-ordered, write-serial-safe. Source: `REMEDIATION-PLAN-R8.md`.

## Wave order

| Wave | R-items | Rationale |
|------|---------|-----------|
| **W1** | R-801, R-802, R-803, R-804 | Control components — disjoint files, independent. |
| **W2** | R-805 | Tests + verification. |

## File ownership matrix (no conflicts)

| File | Owner | Wave |
|------|-------|------|
| `src/runtime/managers/SelectionManager.ts` | R-801 | W1 |
| `src/runtime/components/TopBar.tsx`, `StatePanel.tsx` | R-802 | W1 |
| `src/runtime/components/CommandBar.tsx` | R-803 | W1 |
| `src/runtime/hooks/useKeyboardShortcuts.ts`, `utils/long-press.ts` | R-804 | W1 |
| `tests/unit/runtime/controls.test.tsx`, `selection.test.ts`, `shortcuts.test.tsx`, `tests/unit/long-press.test.ts` | R-805 | W2 |

No file has two owners → write-serial safe.

## Per-wave exit criteria

- **W1 done:** `tsc --noEmit` clean on `src/`.
- **W2 done:** `npx vitest run` green — all 213 PS-R1–R7 tests plus the control
  suites.

## Verification

AC-037/038/040/041/043/064 — RTL / happy-dom render + event tests + pure-logic
unit tests. A claim without a passing check stays `OPEN`.

## Circuit breaker

No green verification after 3 attempts, or a PS-R1–R7 regression → halt.
