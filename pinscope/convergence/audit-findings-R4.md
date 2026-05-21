# PinScope Audit — PS-R4

> **Round:** PS-R4 · **North-Star:** `pinscope/SPEC.md` v2.0.0 · **Date:** 2026-05-21
> **Method:** re-audit — diff Appendix-A ACs against `pinscope/` after PS-R3.

## Reality baseline (post PS-R3)
33 ACs CLOSED (48%). Build module, runtime foundation, Operation Protocol
complete — 176 tests green. `src/plugin/next.ts`, `src/plugin/webpack.ts`
absent; no `dist/` build; no `size-limit` config.
*Re-read:* `ls pinscope/src/plugin/next.ts` → No such file or directory.

## Carry-forward verification (AP-006)
PS-R1–R3 closures re-confirmed: `npm test` green (176), typecheck clean.

## Findings — deployment surface + performance (headless-verifiable)

| Finding | ACs | Sev | Gap (re-read check) |
|---------|-----|-----|---------------------|
| F-4-01 | AC-092 | P2 | `src/plugin/next.ts` (`withPinScope`) + `webpack.ts` (`PinScopeWebpackPlugin`) absent |
| F-4-02 | AC-090 | P1 | export map targets `dist/plugin/next.js`, `dist/plugin/webpack.js` do not exist; no `dist/` build |
| F-4-03 | AC-073 | P0 | no `size-limit` config; dev bundle size unmeasured |
| F-4-04 | AC-070 | P1 | `<PinScope/>` mount time unmeasured |
| F-4-05 | AC-071 | P1 | hover→InfoPanel per-frame cost unmeasured |

## PS-R4 scope
Complete the deployment surface (`pinscope/next`, `pinscope/webpack`), produce
a `dist/` build so the export map resolves, add `size-limit`, and add the two
runtime performance checks. All five findings are **headless-verifiable**
(unit / `tsc` build / `size-limit` / happy-dom perf).

**Expected closures:** AC-070, AC-071, AC-073, AC-090, AC-092 (5) → 38/69 ≈ 55%.
`examples/vite-react` (AC-010, AC-074) and the Playwright e2e suite (AC-082)
are scheduled for PS-R5.
