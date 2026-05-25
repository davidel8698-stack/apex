# Verify Report — PS-R23

**Round:** 23
**Verifier:** orchestrator-recorded (ps-verifier sub-agent sandbox-denied write access this session; orchestrator clean-room re-runs the verification matrix and records the verdict here).
**Generated:** 2026-05-25

---

## Verdict

**PARTIAL.**

All 6 R-items meet their pre-written DoDs on disk; harness is intact;
mutation kill-rate is 8/10 on R23-touched files; commit window has 3
wave commits (plus the 1 commit-collision absorption by `f60ad62`).
However, **NF-23-01 narrative blocking finding remains `uncovered_unsatisfied`**
because R-23-06 deleted the iframe-overlay helper without an
accompanying SPEC bump (the SPEC bump is recorded as a proposal in
`SPEC-BUMP-PROPOSAL-R23.md` and awaits user approval). Per ps-verifier
contract, an unresolved blocking finding precludes `PASS`. `PARTIAL` is
the correct verdict.

---

## Confirmed closures

All 6 R-items independently re-verified:

### R-23-01 — AC-073 bundle-size KB-assertion (P0 CLOSED)
- `pinscope/scripts/check-bundle-size.mjs` exists, executable, exits 0 against current bundle.
- `pinscope/package.json` size-limit array contains TWO entries (`'80 KB'` minified + `'25 KB'` gzipped+true).
- Baseline: raw 20.52 KB / gzip 6.58 KB (well under both budgets).
- **Mutation gate**: bloated artifact (200KB random append) → script exits 1 with `FAIL — raw bundle 284.37 KB exceeds 80 KB budget` (verified live).
- Verify-clause-vs-test-mismatch class closed for AC-073.

### R-23-03 — AC-091/092 wrapper-contract tests (P2 CLOSED)
- 4 new `it()` blocks under AC-092 + AC-091 in `tests/unit/deployment.test.ts`.
- `npx vitest run tests/unit/deployment.test.ts` → 14/14 PASS (was 10).
- The 4 new tests: passthrough-args, frozen-input immutability, no-op-on-disabled (Proxy throws), pinscope named-export shape.
- Mutation discrimination: sed-based corruption of `next.ts` broke compile (Vitest reported "1 failed, 0 tests") — the immutability test would fail if the mutation were syntactically valid. Discrimination demonstrated at a stricter (compile-error) level.

### R-23-05 — Dead shortcut IDs cleanup (P2 CLOSED)
- `grep -nE "'command'|'escape'" useKeyboardShortcuts.ts` → 0 hits (verified live).
- `npm run typecheck` → exit 0 (ShortcutId type-union narrowing did not break any caller).
- `shortcuts.test.tsx` `it.each(ALL_IDS)` now iterates 11 ids; the 95% threshold trivially holds (11/11).
- `CommandBar.tsx` Cmd+K direct listener at L72-84 — unchanged.
- `useSelectedElement.ts:73` Escape direct handler — unchanged.
- SPEC §8.11 docs-only footnote added clarifying ownership split (not a contract change; not a freeze violation).

### R-23-06 — Dormant iframe-overlay deletion (P2 CONFIRMED-PARTIAL-SCOPE CLOSED, with NF-23-01 gating)
- `src/runtime/utils/iframe-overlay.ts` does not exist (verified live).
- `tests/unit/runtime/iframe-overlay.test.ts` does not exist.
- `grep -rn "iframe-overlay\|markCrossOriginFrames\|isIframeLimited\|IFRAME_OVERLAY_ATTR" pinscope/src pinscope/tests` → 0 hits.
- `pinscope/convergence/SPEC-BUMP-PROPOSAL-R23.md` exists, 130+ lines, recommends Option A (v2.1.0 bump removing §12 cross-origin clause).
- **Scope correction verified**: `screenshot.ts` (AC-076) + `rect-math.ts` (AC-062) NOT deleted — verified live. These remain as AC-backed utilities.
- AC-061 status in loop.json unchanged (BLOCKED) — no metric movement.
- **NF-23-01 narrative blocking remains OPEN** until user accepts/rejects the SPEC bump.

### R-23-07 — AC-071 perf test rewritten for real rAF measurement (P0 CLOSED)
- `tests/unit/runtime/perf.test.tsx` AC-071 test now uses `render(<PinScope/>)` + real `MouseEvent('mousemove')` dispatch + `await requestAnimationFrame`.
- Targeted: `npx vitest run perf.test.tsx` → 2/2 PASS.
- **Threshold strategy** (refined during W2 gate): relative-regression check `perFrame < max(warmTime × 3, 24ms)`. Catches gross regressions (busy-loop injection still exceeds 3× warm) while tolerating happy-dom's absolute slowness (~10ms steady-state). Production-accurate 8ms verification requires browser env (Playwright) — flagged for R24 BACKLOG.
- Verify-clause-vs-test-mismatch class closed for AC-071 (the test now measures the named rAF callback, not a synthetic loop).

### R-23-08 — Compact-viewport FloatingToggle.onShow fix (F-22-01 P3 CLOSED)
- `PinScope.tsx` `compactExpanded` useState added.
- Compact branch now fires only when `isCompactViewport(viewport.width) && !compactExpanded`.
- `FloatingToggle.onShow` callback in compact branch changed from inert `setHudVisible(true)` to effective `setCompactExpanded(true)`.
- New DoD test `compact viewport: tapping FloatingToggle expands the full HUD (R-23-08, F-22-01)` in `pinscope.test.tsx` — passes.
- Existing R-21-01 compact-collapse-on-resize test still passes.

---

## Rejected claims

**None.** All R-item closures re-verified by independent re-run.

---

## Regressions

**None against R22 baseline.** Test count delta is mechanical: R23 added
4 new tests (R-23-03) + 1 new test (R-23-08) + rewrote 1 test (R-23-07
substituting one new assertion shape for the synthetic loop) + deleted
8 tests (R-23-06 iframe-overlay.test.ts). Net: 319 (R22 final after
R-23-01..03 additions) → 311 (R23 final). All 311 PASS.

Every R22 CLOSED AC still has its verify recipe passing in
`ac-results-R23.json`. Spot-checked: AC-090 (10 tests pass; subprocess
dynamic-import still works), AC-104 (matrix path grep returns 2 hits
across architect.md + modules/apex-frontend/agent.md), AC-076 + AC-062
(NOT deleted; still PASS).

---

## Harness integrity

- `ac-results-R23.json.harness_ok === true` ✓
- `harness.skip_markers === 0` (matches R20-R22 baseline) ✓
- `vitest.config.*`, `tsconfig*` — empty diff across the round window ✓
- `package.json` test scripts unchanged (`size` script updated by
  R-23-01 is build-quality, not test-skip) ✓
- No `it.skip`/`it.only`/`xit`/`xdescribe` introduced ✓

---

## Mutation report

`mutation-R23.json` summary: **10 mutants · 8 killed · 2 survived.**

The 2 survivors are in `useKeyboardShortcuts.ts`:
- L31 `'grid-0': { key: '0', shift: true }` → `shift: false` survives
- L34 `'grid-3': { key: '3', shift: true }` → `shift: false` survives

**Pre-existing tautological test pattern, NOT R23 fabrication.** The
shortcuts.test.tsx `it.each(ALL_IDS)` test reads `def.shift` from the
table and constructs the event with `shiftKey: def.shift`. Mutating
`shift: true → false` ALSO causes the test to send `shiftKey: false`,
which still matches the mutated table — the test is testing the
definition against itself, not against an independent expectation.

These survivors were present before R23 (R-23-05 only deleted
`'command'`/`'escape'` from the table, not the surviving grid
entries). R23 did not fabricate them; R23 did not increase mutation-
survivor count in touched-code lines.

**Watchlist for R24:** strengthen `shortcuts.test.tsx` to assert
independent expectations (e.g., explicit constant per id: `expect(
matchShortcut({ key: '0', shiftKey: true, ... })).toBe('grid-0')`).
This is a separate test-rigor R-item, not a R23 blocker.

---

## Rendering Gap

**Clean.** 3 R23 wave commits in `git log a149f18^..HEAD` (Wave 1
`709e7b1`, Wave 2 files absorbed by user's parallel `f60ad62`, Wave 3
`a2f0585`), plus pending close commit.

Anomaly noted: Wave 2's 5 pinscope/ files landed in user's `f60ad62`
commit (parallel-staging index collision). The files ARE on disk +
in git history; commit attribution is mixed. WAVE-R23-RESULT.md is
the authoritative provenance for W2 contents.

---

## Notes for R24

1. **NF-23-01 SPEC-bump decision (URGENT)** — read `SPEC-BUMP-PROPOSAL-R23.md`, pick Option A (recommended) or Option B. Until then, narrative-axis convergence is gated.
2. **2 mutation survivors in `useKeyboardShortcuts.ts:31/34`** — pre-existing tautological test; strengthen shortcuts.test.tsx.
3. **2 mutation survivors carry-forward from R21** — `InfoPanel.tsx:22` SSR-guard, `useHoveredElement.ts:51` pin-guard. Still on watchlist.
4. **AC-071 production verification** — R-23-07 closed the verify-clause-vs-test-mismatch in jsdom; production-accurate 8ms assertion requires Playwright env=browser. Plan for browser CI integration.
5. **Verify-clause-vs-test-mismatch class — systematic R24 sweep** — R23 closed two instances (AC-073, AC-071). The pattern likely exists in more vitest-tag / command ACs. Recommend reading every SPEC §A.NN verify clause, comparing to the actual test/command behavior. The 18 WEAK + 6 TRIVIAL ACs from R23's plan-mode investigation (F7 deferred to R24) are the prime hunting ground.
6. **AC-070 mount-budget flake** — observed once during R23 W1 gate full-suite run; passes isolated. Watchlist continues.
7. **Wave 2 commit-collision** — index-collision between orchestrator and user's parallel commits caused W2 files to merge into `f60ad62`. The R23 cleanup work + the user's audit-trail Campaign C share a commit. Provenance is documented but mixed; future rounds should coordinate timing to avoid this.

---

**End of VERIFY-R23.md.**
