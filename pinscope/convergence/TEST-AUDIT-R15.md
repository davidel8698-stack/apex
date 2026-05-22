# Test Audit: PS-R15

## Quarantine Compliance: CLEAN
Read only test files and test-support fixtures within `pinscope/tests/**` and
`pinscope/convergence/lib/test/**`, plus the allowed `ac-matrix.json`. No
implementation/source file under `src/`, `examples/`, or `core/` was opened.
Findings about non-test code are inferred solely from the test files' own
import paths and assertion shapes.

## Test Files Reviewed
PinScope suite (35 files):
- tests/integration/pinscope.spec.ts, tests/integration/visual-regression.spec.ts
- tests/unit/ast-transformer.test.ts, claude-bridge.test.ts, deployment.test.ts,
  edge-utils.test.ts, long-press.test.ts, operation-builder.test.ts,
  operation-parser.test.ts, operation-perf.test.ts, pin-map.test.ts,
  plugin.test.ts, production-stripper.test.ts, property-shortcuts.test.ts,
  roundtrip.test.ts, screenshot.test.ts
- tests/unit/runtime/components.test.tsx, controls.test.tsx, edge-cases.test.ts,
  element-walker.test.ts, iframe-overlay.test.ts, infopanel.test.tsx,
  overlays.test.tsx, perf.test.tsx, pinscope.test.tsx, public-api.test.ts,
  selection.test.ts, shortcuts.test.tsx, snapshot.test.tsx
- tests/unit/fixtures/transformer-cases.ts (fixture)
Convergence engine suite (7 files):
- convergence/lib/test/ac-eval.test.mjs, loop-logic.test.mjs, meta.test.mjs,
  mutate.test.mjs, render.test.mjs, schema.test.mjs, spec-hash.test.mjs

## Quality Issues

| AC undermined | File | Issue | Severity |
|---|---|---|---|
| AC-076 | tests/unit/screenshot.test.ts | HOLLOW / SOURCE-GREP MASQUERADE. The test `fs.readFileSync`s `src/runtime/utils/screenshot.ts` and runs two regexes against the source *text*. It never imports, instantiates, or executes the module. It asserts on source-code shape, not on observable lazy-loading behavior — a refactor that keeps the dynamic-import token but breaks lazy loading would still pass; a working lazy import written differently would fail. AC-076 ("html2canvas loaded lazily") is green only because a string matches `/import\(['"]html2canvas['"]\)/`. This is not a behavioral test. | CRITICAL |
| AC-107 | tests/unit/roundtrip.test.ts | SELF-FULFILLING / HOLLOW. Imports `runScenario` from `../../examples/roundtrip/scenario.js` — an example-bundled scripted scenario, not the production runtime. `expect(result.rounds).toBe(1)` and `result.edit` assertions verify a value the example script itself produces; the test exercises a demo, not the round-trip code path the AC describes. A green AC-107 here demonstrates the example, not the framework's 2-round guarantee. | CRITICAL |
| AC-080 | tests/unit/ast-transformer.test.ts + tests/unit/fixtures/transformer-cases.ts | INFLATED COVERAGE. The fixture meets `length >= 50` but 44 of 52 cases are mechanically generated `<tag />` self-closing elements all with `expectPin: true`, mapped from a tag-name array. Only 6 cases exercise distinct behavior; only 2 are negative (`expectPin: false`). The "at least 50 pairs (AC-080)" assertion treats a count as coverage. Real input variety (nesting, props, children, whitespace, mixed pin/no-pin trees) is thin. | WARN |
| AC-090 | tests/unit/deployment.test.ts | LOW-VALUE ASSERTION. The "dynamically imports each built entry point" case asserts only `expect(mod).toBeTypeOf('object')` — any non-throwing ES module passes. It proves the file imports, not that the export map points at correct/working entry points. The sibling `existsSync` cases carry the real weight; this one is near-vacuous. | WARN |
| AC-092 | tests/unit/deployment.test.ts | THIN BEHAVIORAL COVERAGE. `PinScopeWebpackPlugin exposes a working apply method` asserts `typeof apply === 'function'` and `apply({hooks:{}})` `not.toThrow()`. "Working" is overstated — nothing verifies the plugin registers a hook or transforms anything. A no-op `apply(){}` body would pass identically. | WARN |
| AC-091 | tests/unit/runtime/public-api.test.ts | LOW ASSERTION DENSITY / SHALLOW. A single 10-line test checks `typeof === 'function'` on three exports. It confirms the names exist but exercises no behavior of the public API surface. Acceptable as a smoke test but it is the sole evidence for AC-091. | WARN |
| AC-061 | tests/unit/runtime/iframe-overlay.test.ts | IMPLEMENTATION-COUPLED FAKE (advisory). Cross-origin frames are simulated by `Object.defineProperty` on `contentDocument` to throw/return null. This is a reasonable jsdom workaround, but the test exercises detection against a test-authored fake rather than a real cross-origin frame; AC-061 is also matrix-tagged `manual` (needs two real origins), so the vitest evidence is partial by construction. No false PASS, but treat as supplementary only. | INFO |
| AC-070, AC-071, AC-075, AC-054, AC-072 | tests/unit/runtime/perf.test.tsx, tests/unit/runtime/snapshot.test.tsx, tests/unit/operation-perf.test.ts | TIMING-FRAGILE (advisory). Wall-clock budget assertions (`< 50ms`, `< 8ms`, `< 500ms`, `< 4ms`, `< 50ms`). These carry real behavioral assertions alongside the timing, so they are not hollow, but the timing thresholds are environment-dependent and can flip on a slow/loaded CI runner — a green PASS here is partly luck of the host. Not a false PASS today. | INFO |

No vacuous always-true assertions (`expect(true).toBe(true)`) and no self-mocking
of the unit under test were found. The convergence engine suite
(`convergence/lib/test/*.mjs`) is well-formed: pure-function tests with
dependency injection (`shell`, `resolve`, store interfaces), genuine PASS/FAIL
duals, and no source-grep or hollow patterns.

## Coverage Map Match
All 55 `vitest-tag` ACs in `ac-matrix.json` have at least one discoverable
tagged test (min_tests: 1 satisfied). The non-vitest ACs (AC-010, AC-061,
AC-063, AC-073, AC-074, AC-082, AC-083, AC-084, AC-100..AC-106) are verified by
build-grep/grep/command/manual kinds and are out of this audit's test-quality
scope. Two ACs are backed by tests that do not verify the AC's actual behavior
(AC-076 source-grep, AC-107 example-scenario) — counted as present but hollow.

## Verdict: FAIL
Two ACs are green ONLY because their tests are hollow: AC-076 is a source-text
grep that never executes the code, and AC-107 verifies a bundled example
script rather than the round-trip code path. Both are false PASSes — exactly
the green-but-hollow state the loop must not treat as converged. Five further
ACs (AC-080, AC-090, AC-091, AC-092 inflated/thin) warrant strengthening.

## Summary
R15 matrix shows 62 PASS / 0 FAIL, but two are false PASSes. AC-076's test
regex-greps `screenshot.ts` source text and never runs it — it would pass on
broken lazy-loading and fail on a correctly-refactored one. AC-107's test
drives `examples/roundtrip/scenario.js`, a scripted demo, asserting a value the
demo itself emits — not the framework round-trip. AC-080 inflates coverage (44
of 52 cases are identical generated `<tag/>` positives). AC-090/091/092 lean on
existence/`typeof`/`not.toThrow` checks with no behavioral assertion. Verdict
FAIL: do not treat AC-076 and AC-107 as converged on this evidence.
