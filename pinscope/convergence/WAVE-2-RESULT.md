# Wave 2 Result — PS-R1

**Wave:** W2 — R-102, R-103, R-104, R-105 (build-time module source)
**Status:** PASS

## Files created
| File | R-item | Contents |
|------|--------|----------|
| `src/plugin/stable-id-generator.ts` | R-102 | `stableKey(file,line,col)` |
| `src/plugin/pin-map.ts` | R-102 | `PinMap` class — load/save/getOrAssign + `reconcile()` (resolution I-2) |
| `src/plugin/ast-transformer.ts` | R-103 | `transformJSX` + `getElementName` |
| `src/plugin/production-stripper.ts` | R-104 | `stripPins(html)` |
| `src/plugin/index.ts` | R-105 | `pinscope()` Vite plugin factory |
| `src/index.ts` | R-105 | public API surface |

## Verify-caught gap (fixed within the wave)
`tsc --noEmit` first failed: `Cannot find name 'process'` /
`Cannot find module 'node:fs'`. Root cause — the build module runs in Node but
`@types/node` was absent. Added `@types/node@^22.5.0` to devDependencies and
reinstalled. This is the convergence loop working: verify caught the gap before
the round claimed the AC.

`tsc --noEmit` (strict) then clean on the full `src/` tree.

## Closed by this wave
Verified in W3 by the test suite — see `WAVE-3-RESULT.md`.
