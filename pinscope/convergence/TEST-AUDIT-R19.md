# Test Audit: PS-R19

## Quarantine Compliance: CLEAN

Read only test files (`pinscope/tests/**`, `pinscope/convergence/lib/test/**`)
and `pinscope/convergence/ac-matrix.json`. No implementation/source file was
read. No file was written except this audit (via Bash heredoc — no Write tool).

## Test Files Reviewed: 39

`pinscope/tests/` (unit + integration) — 32 files:
- integration: pinscope.spec.ts, visual-regression.spec.ts
- unit: ast-transformer, claude-bridge, deployment, edge-utils, long-press,
  operation-builder, operation-parser, operation-perf, pin-map, plugin,
  production-stripper, property-shortcuts, roundtrip, screenshot
- unit/runtime: components, controls, edge-cases, element-walker, flow-wiring,
  history-persist-ownership, iframe-overlay, infopanel, overlays, perf,
  pinscope, pinscope-assembly, public-api, selection, shortcuts, snapshot
- unit/fixtures: transformer-cases.ts (AC-080 fixture table, 56 cases)

`pinscope/convergence/lib/test/` (engine) — 7 files:
- ac-eval, loop-logic, mutate, meta, render, schema, spec-hash (all `.test.mjs`)

## Quality Issues

| AC | File | Issue | Severity |
|----|------|-------|----------|
| AC-075 | `tests/unit/runtime/snapshot.test.tsx:107-118` | `snapshot performance (AC-075)` still exercises ONLY a flat 200-sibling tree — `<div data-pin="e_i">` siblings at depth 1 — under a loose flat **500 ms** bound, single un-averaged `createSnapshot()` call. No nesting-depth dimension and no hierarchy-traversal stress (`children_pins` / `computed_styles` walk). A snapshot walker whose cost is super-linear in DOM **depth** would still pass green. The bound is far above realistic capture cost, so only a catastrophic regression trips it. AC-075 is green but the test does not meaningfully exercise capture-time scaling. **Persisting R18 advisory — unaddressed in R19.** | WARN (advisory) |
| AC-065 | `tests/unit/edge-utils.test.ts:49` | `expect(HEAVY_PAGE_THRESHOLD).toBe(500)` asserts an implementation constant against a literal — a tautological re-spelling of the source that passes by construction. NOT vacuous overall: the same `describe` carries real behavioral checks (`isHeavyPage(600)===true`, `isHeavyPage(100)===false`, leading+trailing `throttle` timing, `shouldSkipBadge`), so AC-065's behavior is genuinely exercised. | WARN (minor — one tautological line, behavior still covered) |
| AC-064 | `tests/unit/long-press.test.ts:17,26-28` | Boundary cases import `LONG_PRESS_MS` / `MOBILE_BREAKPOINT` from the impl and assert against those same constants (`detector.end(1000 + LONG_PRESS_MS)`, `isCompactViewport(MOBILE_BREAKPOINT)`), so a wrong constant would not be caught at those lines. Mitigated: absolute-literal assertions are present (`detector.end(1100)==='tap'`, `isCompactViewport(500)===true`, `isCompactViewport(1024)===false`) — tap/long-press classification and compact-viewport detection are genuinely tested. | WARN (minor — partly self-referential, behavior still covered) |

## Coverage Map Match: 57/57 vitest-tag ACs found

All 57 `verify.kind: vitest-tag` criteria in `ac-matrix.json` have at least one
matching `(AC-NNN)`-titled test, satisfying `min_tests: 1` for each. The 14
non-vitest ACs (build-grep AC-010/AC-074; command AC-073/AC-084/AC-101; grep
AC-100/AC-102/AC-103/AC-104/AC-105; manual AC-061/AC-063/AC-082/AC-083/AC-106)
are out of this audit's scope by definition and were not assessed for test
quality. Note: `iframe-overlay.test.ts` carries `(AC-061)` titles, but AC-061 is
a `manual` criterion — those tests are not the matrix's verification path and
the loop does not count them; not an issue.

## Vacuous / Self-Mocking Scan: CLEAN

- No `expect(true).toBe(true)`-class vacuous assertions in any reviewed file.
  No `it.skip` / `describe.skip` / `.todo`.
- No test mocks the unit it claims to verify. `screenshot.test.ts` mocks
  `html2canvas` — a third-party dependency, NOT the SUT — to observe lazy-import
  timing; that is a legitimate behavioral probe (AC-076 was explicitly
  de-vacuated from a source-grep into a real red/green test).
- `roundtrip.test.ts` (AC-107) and `screenshot.test.ts` (AC-076) carry inline
  notes documenting their own escape from prior self-fulfilling forms; both now
  own their completeness/laziness predicates and include a genuine negative case.
- `vi.spyOn` / `vi.stubGlobal` uses target collaborators only (`HistoryManager`,
  `fetch`, `console.warn`), never the unit under test.
- Convergence engine tests use `node:assert/strict` with healthy assertion
  density; `meta.test.mjs` correctly enforces engine/vitest test isolation.
- Assertion density is healthy across the suite; every AC-tagged `it()` carries
  multiple behavioral assertions.

## Verdict: WARN

No vacuous assertions and no self-mocking anywhere — nothing FAIL-grade, nothing
blocks advancement. Three advisory issues stand, all WARN-class: the persisting
AC-075 nesting-depth gap (carried from R18, still unaddressed) plus two minor
self-referential / tautological-constant lines (AC-064, AC-065) whose ACs remain
behaviorally covered by sibling assertions. Per VERDICT RULES, minor gaps with no
vacuous or self-mocking tests = WARN.

## Summary

R19 convergence-confirmation audit: 39 test files + the AC-080 fixture reviewed.
All 57 vitest-tag ACs have a matching tagged test (coverage map 57/57). No
green-but-hollow AC — no vacuous or self-mocking test found. One persisting R18
advisory: AC-075's perf test still uses a flat 200-sibling tree under a loose
500 ms bound with no nesting depth. Two new minor notes (AC-064, AC-065 each
have one self-referential / tautological-constant line, behavior covered
elsewhere). Verdict WARN — advisory only, does not block advancement.
