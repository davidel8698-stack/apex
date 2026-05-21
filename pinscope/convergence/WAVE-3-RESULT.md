# Wave 3 Result — PS-R1

**Wave:** W3 — R-106 (test suite + install + verification)
**Status:** PASS

## Install
`npm install` — 98 packages, npm registry reachable (PONG 122 ms).
devDependencies trimmed to the PS-R1 set: `typescript`, `vite`, `vitest`,
`@babel` type packages, `@types/node`. `playwright` and `size-limit` are
deferred to the rounds whose ACs need them (AC-082/083, AC-073/074).

## Verification — falsifiable checks

| Check | Command | Result |
|-------|---------|--------|
| Strict typecheck | `npm run typecheck` (`tsc --noEmit`) | exit 0 → **AC-084** |
| Unit suite | `npx vitest run` | 4 files, **86 tests pass** |

Test files:
- `ast-transformer.test.ts` — **65 tests** (56-case fixture, ≥50 required, plus
  behavior cases) → **AC-080**
- `pin-map.test.ts` — 9 tests (monotonic ids, no reuse, reconcile, save schema)
- `plugin.test.ts` — 8 tests (plugin shape, transform gating)
- `production-stripper.test.ts` — 4 tests

## Closed by this wave
AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007, AC-008, AC-009,
AC-011, AC-012, AC-013, AC-080, AC-084.

AC-010 (prod-build 0-bytes) is **not** closed — it requires `examples/vite-react`,
deferred to a later round.
