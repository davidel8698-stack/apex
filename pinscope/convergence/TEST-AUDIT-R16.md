# Test Audit: PS-R16

## Quarantine Compliance: CLEAN

Only test files were read: `pinscope/tests/unit/*.test.ts(x)`,
`pinscope/tests/unit/runtime/*.test.tsx`, `pinscope/tests/integration/*.spec.ts`,
and `pinscope/convergence/lib/test/mutate.test.mjs`. The mapping file
`pinscope/convergence/ac-matrix.json` was read (data, not source). No
implementation or `src/` file was opened.

## Test Files Reviewed

Priority re-audit (R15-rewritten — independently re-verified):
- `pinscope/tests/unit/screenshot.test.ts` (AC-076)
- `pinscope/tests/unit/roundtrip.test.ts` (AC-107)

R15 R-item re-audit:
- `pinscope/tests/unit/runtime/pinscope-assembly.test.tsx` (R-15-01, §7.1 HUD assembly)
- `pinscope/tests/unit/runtime/overlays.test.tsx` (R-15-03 Rulers AC-034; R-15-05 badge CSS §12; Crosshair AC-035; VoidBadges AC-024)
- `pinscope/tests/unit/runtime/controls.test.tsx` (R-15-02 Crosshair §8.3; R-15-04 StatePanel §8.8 AC-040; R-15-07 CommandBar §8.6 AC-038)
- `pinscope/tests/unit/runtime/snapshot.test.tsx` (R-15-06 EndpointSnapshotStore §10-D; AC-042; AC-075)
- `pinscope/tests/unit/runtime/components.test.tsx` (PinBadges / InfoPanel)
- `pinscope/tests/unit/runtime/infopanel.test.tsx` (AC-031/032/033)

Corroborating reads:
- `pinscope/tests/unit/operation-builder.test.ts` (AC-052; delta-routing for R-15-09)
- `pinscope/tests/unit/operation-parser.test.ts` (AC-050/AC-081)
- `pinscope/tests/integration/pinscope.spec.ts`
- `pinscope/convergence/lib/test/mutate.test.mjs`

## R15 Rewrite Verification

**screenshot.test.ts (AC-076) — GENUINE.** The prior source-text grep is gone.
The rewrite mocks `html2canvas` with a factory that flips `moduleState.evaluated`
only when the module body first runs, then asserts (1) importing `screenshot.js`
leaves `evaluated === false`, and (2) calling `captureScreenshot` flips it and
invokes the spy exactly once with a PNG data URL. A static top-level import would
evaluate the mock at module-import time and fail assertion (1). This is a true
red/green dual on laziness — not hollow.

**roundtrip.test.ts (AC-107) — GENUINE.** The self-fulfilling
`runScenario`/`result.rounds === 1` demo import is gone. The rewrite drives the
production `parseCommand` -> `buildOperation` path and OWNS the completeness
predicate (`communicationRounds`) derived from the §9.3 Operation shape, not
imported from the demo. The negative cases (`? layout` -> 2 rounds; `select e_47`
-> throws) prove the assertion can fail. Not self-fulfilling.

## Quality Issues

| File | Issue | AC undermined | Severity |
|------|-------|---------------|----------|
| `controls.test.tsx` | The R-15-02 Crosshair disable-condition tests live under `describe('Crosshair disable conditions (R-15-02, §8.3)')`, which carries NO `AC-035` tag. AC-035 verification (`vitest-tag` tag `AC-035`) runs `--testNamePattern AC-035`, which matches only the `describe('Crosshair (AC-035)')` block in `overlays.test.tsx`. The §8.3 measuring/hud-hidden disable guards — exactly the conditional behavior most exposed to surviving mutants — are therefore excluded from the AC-035 verification run. Genuine tests, but invisible to the matrix. | AC-035 | WARN |
| `controls.test.tsx` | TopBar AC-037 has a single `it`. The `state` field is only ever asserted with `stateOverride={null}` -> `'none'`; the non-null branch (`stateOverride` populated) is never exercised, leaving a `stateOverride ? ... : 'none'` ternary un-asserted — a candidate for one of the R15 surviving mutants. | AC-037 | WARN |
| `snapshot.test.tsx` | AC-075 perf test asserts `< 500 ms` on a 200-element capture but only on a flat sibling tree; no nested/deep DOM. Adequate for the AC but does not bound worst-case. | AC-075 | WARN |
| `components.test.tsx` | PinBadges block has one `it` with three string-`toContain` assertions on the injected `<style>` text — it verifies the rule string exists, not that the badge renders/positions. Low behavioral density; the genuine badge-render coverage is the VoidBadges (AC-024) and badge-CSS (R-15-05) blocks in `overlays.test.tsx`, so AC-024 itself is unaffected. | (none — advisory) | WARN |

No vacuous assertions (`expect(true).toBe(true)`), no self-mocking, and no
hollow source-text greps were found. The R-15-05 badge-CSS block in
`overlays.test.tsx` does use string-pattern matching on `badgeCss`, but it also
parses the sheet into a real `CSSStyleSheet` and asserts
`getPropertyPriority('background') === 'important'` — a behavioral predicate, not
a grep. The R-15-06 EndpointSnapshotStore block asserts both the POST shape and
that a non-ok response rejects with a typed error (no swallowing). All R15
R-item tests are genuine behavioral tests.

## Coverage Map Match

Every R15-touched `vitest-tag` AC has a discoverable, genuine test:
AC-024, AC-031, AC-032, AC-033, AC-034, AC-035, AC-037, AC-038, AC-040, AC-042,
AC-050, AC-052, AC-075, AC-076, AC-081, AC-107 — 16/16 present and behavioral.
The only gap is taggability: the R-15-02 §8.3 Crosshair disable tests are not
reachable by the `AC-035` name-pattern filter.

## Verdict: WARN

All R15 rewrites (AC-076, AC-107) are confirmed genuine — no false PASS.
All R15 R-item tests are behavioral, not vacuous or self-mocking. The findings
are advisory: an untagged-but-genuine test block (AC-035 §8.3 guards) and two
under-asserted branches (AC-037 state field, AC-075 deep-tree perf) that align
with the R15 mutation check's 4 surviving mutants. None vacuous; none block
advancement.

## Summary

R15's two rewrites are genuine: screenshot.test.ts now behaviorally proves
html2canvas laziness; roundtrip.test.ts drives production primitives with an
owned completeness predicate and real negative cases. No vacuous or self-mocking
tests across the R15 R-item set. WARN: the R-15-02 Crosshair §8.3 disable tests
sit in an untagged describe block and so escape the `AC-035` vitest-tag filter;
TopBar AC-037 leaves the non-null `stateOverride` branch un-asserted — both
likely match surviving mutants. Verdict WARN, advisory only.
