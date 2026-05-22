# Test Audit: PS-R17

## Quarantine Compliance: CLEAN

Only test files were read: `pinscope/tests/**` and `pinscope/convergence/lib/test/**`,
plus the permitted `pinscope/convergence/ac-matrix.json`. No implementation or
source file was opened. All Bash commands operated within test directories.

## Test Files Reviewed

Convergence-confirmation focus — R15/R16-touched suites independently re-audited:

- `tests/unit/runtime/pinscope-assembly.test.tsx` (R-15-01, HUD §7.1 assembly)
- `tests/unit/runtime/flow-wiring.test.tsx` (R-16-01, §10 flow seams)
- `tests/unit/plugin.test.ts` (R-15-06/07, R-16-05/06/07, dev-server routes)
- `tests/unit/runtime/controls.test.tsx` (R-15 retag of AC-035; CommandBar fetch seam, F-16-08)
- `tests/unit/runtime/snapshot.test.tsx` (AC-042 / AC-075)
- `tests/unit/runtime/perf.test.tsx` (AC-070 / AC-071)
- `tests/unit/runtime/overlays.test.tsx` (AC-024/034/035/036/039)
- `tests/unit/runtime/components.test.tsx` (PinBadges / InfoPanel — untagged)
- `tests/unit/runtime/public-api.test.ts` (AC-091)
- `tests/unit/screenshot.test.ts` (AC-076)
- `tests/unit/convergence engine — meta.test.mjs` and sibling `.mjs` files (isolation guard)
- AC-tag census run across all 37 test files in scope.

## Quality Issues

| File | Issue | AC undermined | Severity |
|------|-------|---------------|----------|
| `tests/unit/runtime/snapshot.test.tsx:107-118` | AC-075 perf test builds 200 **flat sibling** `<div data-pin>` nodes (`parts.join('')` — zero nesting depth). It never exercises the deep-tree traversal cost that is the realistic worst case for `createSnapshot`; the `<500ms` bound is also very loose against a flat list. Re-checked from the R16 advisory: still under-asserted — coverage is shallow, not vacuous. | AC-075 | WARN |
| `tests/unit/runtime/controls.test.tsx:21-39` | AC-037 `TopBar` is rendered only with `stateOverride={null}`, asserting `field('state')` contains `'none'`. The non-null branch (e.g. `stateOverride="hover"`) is never rendered, so the conditional that surfaces an active state-override value in the TopBar is never executed. Re-checked from the R16 advisory: still under-asserted. AC-040 (StatePanel) exercises the override-setting path, but no test confirms TopBar *displays* a non-null override. | AC-037 | WARN |
| `tests/unit/runtime/components.test.tsx` | PinBadges / InfoPanel suite carries no `AC-` tag. Not a quality defect in the tests themselves (assertions are real and behavioral), noted only as untagged coverage — no AC depends on it. | (none) | INFO |

## Coverage Map Match

All `vitest-tag` ACs in `ac-matrix.json` have at least one tagged test present
(`min_tests: 1` satisfied for every tag); AC-tag census confirms ≥1 occurrence
for each of AC-001..AC-107 vitest-tag entries. R15/R16 additions verified as
substantive:

- `pinscope-assembly.test.tsx` — 7 behavioral tests; mounts the real `<PinScope/>`,
  asserts seven §7.1 `data-pinscope-*` nodes, toggle hide/restore, shortcut
  gating, and the production-guard null render. No self-mocking; no vacuous
  assertions.
- `flow-wiring.test.tsx` — Flows B/C/D drive the live root. Flow C parses a real
  command and asserts the §9.3 `Operation` JSON fields reaching a clipboard spy
  (`navigator.clipboard` is a real browser seam, legitimately stubbed). `fetch`
  is stubbed only to contain the dev-server network seam — not the unit under test.
- `plugin.test.ts` — route tests assert the HTTP **response body** `{ ok, count }`
  and on-disk file contents (kill mutants M3/M4/M5), and the nested-root test
  proves `mkdirSync({recursive:true})`. Strong, mutation-aware assertions.
- `controls.test.tsx` — AC-035 Crosshair retag includes a positive-control test
  ("renders normally with no disable props") so the guard is proven *conditional*,
  not always-off. The F-16-08 fetch-seam test spies real `globalThis.fetch`,
  asserts URL/method/body, and explicitly targets mutant M2.
- `screenshot.test.ts` (AC-076) — mocks the third-party `html2canvas` dependency
  (a legitimate seam), not the module under test; genuinely verifies lazy import.

No vacuous assertions (`expect(true).toBe(true)` etc.), no `.skip`/`.todo`, no
self-mocking of the unit under test found anywhere in scope. All `toBe(true)`
occurrences are real boolean predicate checks.

## Verdict: WARN

Two pre-existing R16 advisory items (AC-075 shallow perf tree, AC-037 untested
non-null `stateOverride` branch) remain under-asserted after the R15/R16 work —
neither was addressed this round. They are low-assertion-density / hollow-coverage
gaps, not vacuous or self-mocking tests, so per the VERDICT RULES this is WARN
(advisory, non-blocking). The R16 third advisory (AC-035 tag visibility) is
confirmed resolved: `controls.test.tsx` carries the `AC-035` tag with a real
3-test Crosshair suite. No FAIL-class defect found; the R15/R16 additions are
substantive and mutation-aware.

## Summary

R17 convergence-confirmation audit: 37 test files in scope, quarantine clean.
R15/R16 additions (HUD assembly, §10 flow wiring, plugin route bodies, fetch
seam, AC-035 retag) are all substantive — real behavioral assertions, no
self-mocking, no vacuous tests. Two carried-over advisories persist: AC-075
perf test uses a flat (non-nested) 200-node tree, and AC-037 never renders the
non-null `stateOverride` branch. Verdict WARN, advisory only — does not block
advancement.
