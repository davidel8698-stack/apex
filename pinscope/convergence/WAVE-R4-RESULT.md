# Wave Results — PS-R4

Both waves **PASS**.

## W1 — R-401 Next.js + Webpack wrappers
Created `src/plugin/next.ts` (`withPinScope` — config wrapper, composes any
existing `webpack` fn, no-op in production) and `src/plugin/webpack.ts`
(`PinScopeWebpackPlugin` — class with `apply`). Completes the `package.json`
export-map targets.

## W2 — R-402 dist build + size-limit + verification
`npm run build` (`tsc`) emits `dist/` — all five export-map subpaths now
resolve to real files. Added `size-limit` + `@size-limit/preset-small-lib`
with a runtime budget entry. A `pretest` script rebuilds `dist/` before every
`npm test` so the deployment suite always sees fresh artifacts.

Verification — falsifiable checks:

| Check | Command | Result |
|-------|---------|--------|
| Strict typecheck | `npm run typecheck` | exit 0 |
| Dev bundle size | `npx size-limit` | **1.21 kB** / 80 kB budget — exit 0 |
| Full suite | `npx vitest run` | 15 files, **188 tests pass** |

No regression: all 176 PS-R1–R3 tests still green. New (12): deployment (10 —
export-map resolution + Next/Webpack wrappers), runtime perf (2).

## Closed by this round
AC-070 (mount < 50 ms), AC-071 (hover per-frame < 8 ms), AC-073 (`size-limit`
< 80 KB), AC-090 (export map resolves), AC-092 (Next/Webpack wrappers).
