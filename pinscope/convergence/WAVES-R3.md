# PinScope Wave Map — PS-R3

> Dependency-ordered, write-serial-safe. One file = one owner per wave.
> Source: `REMEDIATION-PLAN-R3.md`.

## Wave order

| Wave | R-items | Rationale |
|------|---------|-----------|
| **W1** | R-301 | Parser + shortcut resolution — pure, dependency root. |
| **W2** | R-302 | Operation builder — depends on the parser's `ParsedCommand`. |
| **W3** | R-303 | History + Claude bridge — depend on the `Operation` type. |
| **W4** | R-304 | Autocomplete + the full test/verification suite. |

## File ownership matrix (no conflicts)

| File | Owner | Wave |
|------|-------|------|
| `src/runtime/parsers/operation-parser.ts`, `property-shortcuts.ts` | R-301 | W1 |
| `src/runtime/parsers/operation-builder.ts` | R-302 | W2 |
| `src/runtime/managers/HistoryManager.ts`, `ClaudeBridge.ts` | R-303 | W3 |
| `src/runtime/parsers/autocomplete.ts`, `tests/unit/operation-*.test.ts`, `tests/unit/property-shortcuts.test.ts`, `tests/unit/claude-bridge.test.ts` | R-304 | W4 |

No file has two owners → write-serial safe.

## Per-wave exit criteria

- **W1–W3 done:** `tsc --noEmit` (strict) clean on `src/`.
- **W4 done:** `npm test` exits 0 — all 100 PS-R1/R2 tests still green plus the
  new Cluster-D suites; parser suite ≥ 30 cases; `npm run typecheck` clean.

## Verification

`verifier` re-runs the `verify:` of each claimed AC. All PS-R3 ACs are
headless-verifiable (unit / perf / node). A claim without a passing check stays
`OPEN`.

## Circuit breaker

No green `npm test` after 3 attempts, or any PS-R1/R2 test regressing without a
fix → halt and escalate.
