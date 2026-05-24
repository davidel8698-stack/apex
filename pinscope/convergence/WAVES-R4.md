# PinScope Wave Map — PS-R4

> Dependency-ordered, write-serial-safe. Source: `REMEDIATION-PLAN-R4.md`.

## Wave order

| Wave | R-items | Rationale |
|------|---------|-----------|
| **W1** | R-401 | Next/Webpack wrapper source — completes the export-map targets. |
| **W2** | R-402 | `dist/` build, `size-limit`, perf + deployment tests, verification. |

## File ownership matrix (no conflicts)

| File | Owner | Wave |
|------|-------|------|
| `src/plugin/next.ts`, `src/plugin/webpack.ts` | R-401 | W1 |
| `package.json` (size-limit block + devDeps), `tests/unit/deployment.test.ts`, `tests/unit/runtime/perf.test.tsx` | R-402 | W2 |

No file has two owners → write-serial safe.

## Per-wave exit criteria

- **W1 done:** `tsc --noEmit` clean on `src/`.
- **W2 done:** `npm run build` emits `dist/`; `npx size-limit` exits 0;
  `npx vitest run` green — all 176 PS-R1–R3 tests plus the new suites.

## Verification

`verifier` re-runs the `verify:` of each claimed AC: AC-090 (export-map
resolution), AC-092 (wrapper unit tests), AC-073 (`size-limit`), AC-070/071
(happy-dom perf). All headless. A claim without a passing check stays `OPEN`.

## Circuit breaker

No green verification after 3 attempts, or a PS-R1–R3 regression → halt.
