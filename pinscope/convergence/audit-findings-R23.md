# Audit Findings — PS-R23

**Auditor:** spec-auditor (sub-agent inline, orchestrator-recorded)
**Round:** 23
**Date:** 2026-05-25
**ac-verify input:** 62 PASS · 6 UNAVAIL · 1 MANUAL (AC-106 CLOSED via attest)

> **Note on file authorship.** All three R23 sub-agents (spec-auditor,
> narrative-auditor, test-quality auditor) were sandbox-denied write access
> to `pinscope/convergence/` in this session. The orchestrator's main
> thread (with write permission) records the consolidated findings verbatim
> from the sub-agents' inline verdicts. The 6-finding consolidated view
> below applies cross-auditor reconciliation: where test-quality refuted
> or partial'd a spec-auditor finding, the test-quality verdict wins
> because test-quality actually read the test files line-by-line.

## Summary

- **AC findings (re-confirmed FAILs):** 0
- **Investigation findings:** 6 — **5 CONFIRMED + 1 SUSPECTED (carry-forward)**
- **Blocked (env-bound):** 6
- **Coverage:** 12 axes swept, all 5 §3-§17 sections + Appendix A re-read

## The headline finding

The user's question — "how could you find zero gaps?" — surfaced **two
P0 false-PASSes** that 22 rounds of standard ps-heal never caught:

- **F-23-01** — AC-073 bundle-size "verify" only checks `exit 0`, never KB
- **F-23-07** — AC-071 perf "verify" measures a synthetic loop, NOT the
  rAF callback its SPEC clause names

This is the **verify-clause-vs-test-mismatch** class. The SPEC says "perf
test measures the rAF callback duration" — but the test measures
something entirely different and always passes. R23 closes both.

## Investigation findings (detail)

### F-23-01 — AC-073 bundle-size false-PASS (P0 CONFIRMED)

**Axis:** 10 — Performance / matrix-rigor
**Spec:** §A.13 AC-073 "dev bundle < 80 KB minified / < 25 KB gzipped"
**Verify (current):** `command: 'cd pinscope && npm run size', expect_exit: 0`

`npm run size` runs size-limit reading the config in `package.json`.
The config has a single entry `{ limit: '80 KB', ... }` — no gzipped
sub-budget. exit 0 returns whenever the bundle is below that one limit.
A misconfigured limit (`'1 MB'`) silently passes while bundle bloats.

**Closure path:** R-23-01 — write `scripts/check-bundle-size.mjs` that
reads `dist/*.js`, computes actual gzip size, asserts BOTH 80 KB min
AND 25 KB gz. Update `npm run size` to invoke it.

### F-23-03 — AC-091/092 wrapper-contract tests presence-only (P2 CONFIRMED)

**Axis:** 11 — Integration surface / matrix-rigor
**Spec:** SPEC §I-1 deliberately scopes Webpack/Next.js to wrapper-only
in v1.0/v2.0. The stubs in `webpack.ts` / `next.ts` are spec-faithful.
**Verify (current):** tests check that `withPinScope` returns
`{ webpack: function }` and `PinScopeWebpackPlugin.apply` is defined.

Missing: (a) wrapper invokes host webpack fn with arg passthrough;
(b) input config immutability (spread-vs-return-same mutant survives);
(c) apply is no-op when `enabled:false`. The spec-faithful stub
satisfies the test even if `apply` threw.

**Closure path:** R-23-03 — strengthen AC-091/092 tests to assert
wrapper contract: spy on host webpack, frozen-input passthrough check,
no-op-when-disabled spy on `compiler.hooks`.

### F-23-05 — Dead shortcut IDs in SHORTCUTS table (P2 CONFIRMED)

**Axis:** 7 — Operation protocol
**Spec:** SPEC §8.11 names 13 shortcuts
**Code:** `src/runtime/hooks/useKeyboardShortcuts.ts` SHORTCUTS table has
all 13. PinScope.tsx handler object services 11. The remaining 2
(`'command'` Cmd+K, `'escape'`) are handled DIRECTLY in CommandBar.tsx
L72-84 and useSelectedElement.ts L73 — bypassing the dispatch entirely.

**Closure path:** R-23-05 — delete `'command'` and `'escape'` from
ShortcutId union and SHORTCUTS table. Add a footnote (SPEC §8.11 OR
README) noting that those two shortcuts are owned by CommandBar /
useSelectedElement direct, not by the dispatcher.

### F-23-06 — Dormant utility code (P2 CONFIRMED-PARTIAL-SCOPE)

**Axis:** 9 — Edge cases / dormant
**Initial scope:** delete iframe-overlay.ts, screenshot.ts, rect-math.ts
**Narrative-auditor deletion-safety review:** SCOPE CORRECTION REQUIRED

| File | Test consumer | AC | Verdict |
|---|---|---|---|
| `iframe-overlay.ts` | `iframe-overlay.test.ts` | AC-061 manual+BLOCKED (can't assert) | **SAFE TO DELETE** |
| `screenshot.ts` | `screenshot.test.ts` | AC-076 (vitest-tag, would regress) | **DO NOT DELETE** |
| `rect-math.ts` | `edge-utils.test.ts` | AC-062 (vitest-tag, would regress) | **DO NOT DELETE** |

`screenshot.ts` and `rect-math.ts` are tested-and-AC-backed; they are
documented utilities for future feature work, not dormancy that
misleads the convergence metric. Only `iframe-overlay.ts` is genuinely
unused-and-unverified-in-runtime.

**Closure path:** R-23-06 (scoped) — delete only iframe-overlay.ts +
its test file. Document NF-23-01 (see narrative-scan) separately.

### F-23-07 — AC-071 perf test does NOT measure rAF callback (P0 CONFIRMED — NEW)

**Axis:** 10 — Performance / matrix-rigor
**Spec:** §A.13 AC-071 "hover→InfoPanel update < 8 ms/frame.
**verify:** perf test measures the rAF callback duration."
**Test (current — perf.test.tsx L26-44):**
```ts
const runs = 100;
const start = performance.now();
for (let i = 0; i < runs; i++) {
  const pinned = findPinnedAncestor(span);
  pinned?.getBoundingClientRect();
}
const perFrame = (performance.now() - start) / runs;
expect(perFrame).toBeLessThan(8);
```

The test loop is a synthetic micro-benchmark of `findPinnedAncestor +
getBoundingClientRect` — a few microseconds total. It does NOT use
requestAnimationFrame, does NOT trigger React state update, does NOT
render the InfoPanel update, does NOT measure layout/paint. The
production hover→InfoPanel path involves: rAF schedule → React state
update → InfoPanel re-render → layout. The test bypasses all of it.

This is exactly the verify-clause-vs-test-mismatch pattern as F-23-01.
A real hover→InfoPanel update could exceed 8ms while this test always
passes.

**Closure path:** R-23-07 (NEW) — rewrite `tests/unit/runtime/perf.test.tsx`
AC-071 test to actually measure the production rAF callback in
`<PinScope/>`. Use RTL to render `<PinScope/>`, dispatch synthetic
mousemove events, hook into `performance.measure()` around the rAF
callback, assert under 8ms.

### F-22-01 — Compact-viewport FloatingToggle.onShow inert (P3 SUSPECTED — carry-forward)

**Axis:** 9 — Edge cases / hollow interaction
**Carry-forward from R22.** R-21-01's compact-viewport branch renders
`<FloatingToggle onShow={() => setHudVisible(true)} />`. But `hudVisible`
defaults to `true` and the `!hudVisible` branch fires first — so the
callback is functionally inert. The inline comment promises "the user
can re-expand by tapping it" but the code does not.

**AC impact:** AC-064 verifies resize round-trip, not compact-tap. No
visible AC failure. SUSPECTED P3, not loop-blocking.

**Closure path:** R23 backlog OR R-23-08 (small targeted fix +
test). Pending user decision.

## Carry-forward from initial plan-mode findings (downgraded by test-quality re-audit)

These were initially flagged but the test-quality auditor's
line-by-line re-read demonstrated they do NOT gate any green AC:

- **F-23-02 (AC-001 plugin shape `toBeDefined×4`)** — PARTIAL.
  Presence-only test, but AC-001's spec claim is "plugin shape" and
  behavior is covered by sibling AC-013 (transform) + AC-009
  (transformIndexHtml). **Polish opportunity, not gating.**
- **F-23-04a (AC-090 redundant `toBeDefined`)** — REFUTED. The sibling
  `it.each(subpaths)` reads `pkg.exports[sp]` as `path.join` arg, which
  throws on undefined. Redundant noise, not vacuous.
- **F-23-04b (AC-037 TopBar substring matching)** — REFUTED. The L81
  PRE-click + L87/88 POST-click pre/post pairing kills the hardcoded-
  string mutant. Actually SUBSTANTIVE.
- **F-23-04c (AC-053 HistoryManager partial entry)** — PARTIAL.
  Isolated `it` only asserts `raw_input`, but the adjacent R-20-05
  disjunct tests in the same describe block assert `parsed === null`
  and `result === 'applied'`. AC verdict is backed across the block.
  **Polish opportunity, not gating.**
- **F-23-04d (AC-107 redundant `toBeDefined`)** — REFUTED. The
  subsequent `.toHaveLength(1)` throws on undefined.

## Notes for R-remediation-planner

- 5 CONFIRMED + 1 SUSPECTED → expect 5 main R-items + 1 backlog disposition.
- F-23-06 must respect deletion scope correction (iframe-overlay only).
- F-23-07 closure must mutation-test: the rewritten AC-071 test must
  fail when the production rAF callback is artificially slowed (e.g.,
  inject `for (let i=0; i<1e8; i++);` into InfoPanel render). The
  current synthetic loop test passes unchanged under any production
  slowdown — that's the proof of false-PASS.
- F-23-01 closure must mutation-test: artificially bloat a dist chunk
  by 200KB → `npm run size` must exit 1.
- See also NF-23-01 (narrative-scan-R23) for the §12 iframe coverage
  gap that pairs with F-23-06.
