# Test Audit: PS-R18

## Quarantine Compliance: CLEAN
Only test files were read: `pinscope/tests/**` (unit + integration) and the
convergence engine's own `pinscope/convergence/lib/test/**`. `ac-matrix.json`
was read for AC mapping (allowed — not source). No implementation/source file
was opened. No write tool used; this artifact written via Bash heredoc.

## Test Files Reviewed
Full-read: `tests/unit/runtime/controls.test.tsx`,
`tests/unit/runtime/snapshot.test.tsx`, `tests/unit/runtime/perf.test.tsx`,
`tests/unit/operation-perf.test.ts`, `tests/unit/runtime/public-api.test.ts`,
`tests/unit/runtime/shortcuts.test.tsx`, `tests/unit/runtime/components.test.tsx`,
`tests/unit/production-stripper.test.ts`, `tests/integration/pinscope.spec.ts`,
`convergence/lib/test/meta.test.mjs`.
Suite-wide scan (vacuous-assertion / skip / assertion-density grep): all 31
unit+integration test files and all 7 `convergence/lib/test/*.test.mjs` engine
test files.

## Quality Issues

| AC | File | Issue | Severity |
|----|------|-------|----------|
| AC-075 | `tests/unit/runtime/snapshot.test.tsx:107-118` | `snapshot performance (AC-075)` still asserts only against a **flat 200-sibling tree** (`<div>` x200, no nesting) under a loose **500 ms** bound. No deep/nested DOM, no `computed_styles` / `children_pins` hierarchy traversal stress, and the bound is ~orders of magnitude above realistic capture cost — a regression would have to be catastrophic to trip it. AC-075 is green but the test does not meaningfully exercise capture-time scaling. Carried forward from R17; **still open**. | WARN (advisory) |

## Notes (resolved / non-blocking)

- **AC-037 — R17 advisory RESOLVED.** The R17 note flagged the TopBar non-null
  `stateOverride` branch as unexercised. R18 confirms `controls.test.tsx:67-90`
  (`TopBar <-> StatePanel wiring (R-17-03, F-17-03)`) now renders the full
  `<PinScope />` assembly, fires a real `[data-state-btn="hover"]` click on the
  live StatePanel, and asserts the TopBar `[data-field="state"]` readout flips
  from `none` to `hover` (`expect(stateField()).not.toContain('none')`). The
  non-null branch is genuinely driven end-to-end. AC-037's green is sound.
  No quality issue remains for AC-037.

- AC-072 (`operation-perf.test.ts`) and AC-070/AC-071 (`perf.test.tsx`) carry
  the same loose-bound / warm-once pattern as AC-075 but use repeated-run
  averaging (100-200 iterations) which materially tightens the signal; not
  flagged.

- Convergence engine tests (`convergence/lib/test/*.test.mjs`) use
  `node:assert/strict` (36/68/8/6/9/4 assert calls across files) — healthy
  assertion density, no vacuous patterns. `meta.test.mjs` correctly enforces
  the engine/vitest test isolation.

- Suite-wide grep found **no** `expect(true).toBe(true)`, no `it.skip` /
  `describe.skip` / `.todo`, no self-mocking (every test exercises the real
  imported unit; `vi.spyOn`/`vi.stubGlobal` target collaborators —
  `HistoryManager`, `fetch` — never the unit under test).

## Coverage Map Match
All 50 `vitest-tag` ACs in `ac-matrix.json` have >=1 backing test (tag-grep
counts 1-3 occurrences each, satisfying `min_tests: 1`). The 9 non-vitest ACs
(grep/build-grep/command/manual) are out of audit scope. 50/50 vitest ACs
backed.

## Verdict: WARN

## Summary
Independent R18 re-audit. R17's AC-037 advisory is RESOLVED — the
TopBar/StatePanel wiring test now drives the non-null `stateOverride` branch
through the real `<PinScope />` assembly. One advisory carries forward: AC-075's
snapshot-perf test still uses only a flat 200-sibling tree under a loose 500 ms
bound, so the AC is green without exercising capture-time scaling. No vacuous
assertions, no self-mocking, no skipped tests anywhere in the suite. WARN is
advisory and does not block advancement.
