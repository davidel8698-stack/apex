# PinScope Wave Map — PS-R9 (terminal)

> Dependency-ordered, write-serial-safe. Source: `REMEDIATION-PLAN-R9.md`.

## Wave order

| Wave | R-items | Rationale |
|------|---------|-----------|
| **W1** | R-901, R-902, R-903 | InfoPanel rewrite, screenshot util, round-trip scenario — disjoint files. |
| **W2** | R-904 | Tests, reclassification, verification, terminal report. |

## File ownership matrix (no conflicts)

| File | Owner | Wave |
|------|-------|------|
| `src/runtime/components/InfoPanel.tsx` | R-901 | W1 |
| `src/runtime/utils/screenshot.ts`, `package.json` | R-902 | W1 |
| `examples/roundtrip/scenario.ts` | R-903 | W1 |
| `tests/unit/runtime/infopanel.test.tsx`, `tests/unit/screenshot.test.ts`, `tests/unit/roundtrip.test.ts`, `convergence/STATUS.md`, `convergence/CONVERGENCE-REPORT.md` | R-904 | W2 |

No file has two owners → write-serial safe.

## Per-wave exit criteria

- **W1 done:** `tsc --noEmit` clean on `src/`.
- **W2 done:** `npx vitest run` green — all 241 PS-R1–R8 tests plus the new
  suites; `bash framework/scripts/self-test.sh` outcome recorded.

## Verification

AC-031/032/033 (RTL InfoPanel), AC-076 (source/bundle analysis), AC-106
(`self-test.sh`), AC-107 (scripted scenario). AC-061/063/083 → `BLOCKED`.
A claim without a passing check stays `OPEN`.

## Circuit breaker

No green verification after 3 attempts, or a PS-R1–R8 regression → halt.
