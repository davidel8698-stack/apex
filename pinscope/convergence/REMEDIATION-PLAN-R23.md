# Remediation Plan — PS-R23

**Round summary.** R23 audit recorded **0 AC findings** and **6 investigation findings**: 5 CONFIRMED (2 P0 + 3 P2) + 1 SUSPECTED P3 carry-forward, plus 1 narrative blocking finding (NF-23-01 P3) deferred to R-23-06 disposition. The user invoked /ps-heal with explicit "fix everything" autonomy and approved Strategy A in plan-mode (with F7 — 24 WEAK/TRIVIAL ACs — deferred to R24).

**Two P0 false-PASSes** (F-23-01, F-23-07) form a single root-cause class: **verify-clause-vs-test-mismatch** — SPEC §A.13 verify clauses name measurements ("KB of bundle", "rAF callback duration") that the actual test/config does not perform. The verify always returns PASS regardless of production correctness. R-23-01 and R-23-07 each close one instance; the systematic sweep across all `vitest-tag` and `command` ACs is deferred to R24.

This plan is READ-ONLY analysis. The North-Star `pinscope/SPEC.md` is frozen v2.0.0; every fix below targets reality.

> **Plan authorship.** ps-remediation-planner sub-agent was sandbox-denied write access in this session. The orchestrator's main thread composes this plan based on (a) the user-approved Strategy A from plan-mode (`giggly-petting-dahl.md`), (b) the consolidated audit findings (`audit-findings-R23.json`, `narrative-scan-R23.json`, `TEST-AUDIT-R23.md`), and (c) cross-auditor reconciliation (test-quality auditor refuted/downgraded 2 originally-planned R-items).

---

## Remediation R-23-01

**Linked finding:** F-23-01 + SP-23-01 (narrative strengthen)
**Severity:** P0
**Spec anchor:** §A.13 AC-073 "dev bundle < 80 KB minified / < 25 KB gzipped" — dual budget.
**Root cause:** AC-073 verify recipe is `expect_exit: 0` of `npm run size`, which runs `size-limit` against `package.json`'s size-limit config — a single entry with `limit: '80 KB'` only. The 25 KB gzipped sub-budget is unmeasured. A misconfigured limit (e.g., `'1 MB'`) silently passes. This is the canonical P0 false-PASS.

### Ecosystem analysis
1. What does AC-073 currently verify? `cd pinscope && npm run size` → exit 0. The script invokes size-limit which reads `package.json` `size-limit` array.
2. What is the actual SPEC requirement? Dual budget: 80 KB minified AND 25 KB gzipped.
3. What does size-limit currently check? A single entry `{ name: 'runtime (dev)', path: 'dist/runtime/PinScope.js', import: '{ PinScope }', ignore: ['react','react-dom'], limit: '80 KB' }` — minified-only, no gzip.
4. Why is exit-0-only a false-PASS? A regression that bloats the bundle to 79 KB minified + 30 KB gzipped would silently pass (under 80 KB min limit, over 25 KB gz budget). The matrix would still report AC-073 CLOSED.
5. What's the fix shape? Two paths: (a) add a second size-limit entry for gzip; OR (b) write a custom script that asserts both budgets explicitly. The plan chooses (a) + (b) combined: split size-limit into two entries (covers the standard gate) AND add a `scripts/check-bundle-size.mjs` that asserts both budgets with print output (provides a debugging/verification surface and is mutation-testable).
6. Does this require a matrix edit? No. The matrix recipe is `cd pinscope && npm run size` exit 0. We update what `npm run size` does internally; the recipe doesn't change.
7. Sync-strategy? N/A — pinscope-internal only.

### Execution plan
**Files to create:** `pinscope/scripts/check-bundle-size.mjs` — reads `pinscope/dist/runtime/PinScope.js`, computes raw byte count + gzip byte count (`zlib.gzipSync`), asserts both ≤ thresholds, exits 0/1 with print output.
**Files to modify:**
- `pinscope/package.json` — (a) extend size-limit array to include a second `{ limit: '25 KB', gzip: true }` entry; (b) optionally update the `size` script to also invoke `node scripts/check-bundle-size.mjs` (belt-and-suspenders).
**Files that MUST remain untouched:** the matrix recipe at `convergence/ac-matrix.json:56` — recipe stays `expect_exit: 0` of `npm run size`. The change is INSIDE the script, not in the matrix.
**Order of operations:**
1. Run `npm run build` to ensure `dist/runtime/PinScope.js` exists.
2. Write `scripts/check-bundle-size.mjs` with thresholds `MAX_MIN_KB=80`, `MAX_GZ_KB=25` and `--print` flag.
3. Run `node scripts/check-bundle-size.mjs --print` to capture current baseline. If current is OVER 80 KB min OR 25 KB gz, **HALT and notify user** — this is a real bundle regression, not a fix.
4. Update `package.json` size-limit to add gzip entry (or replace existing entry with split min+gz array).
5. Optionally update `size` script: `"size": "size-limit && node scripts/check-bundle-size.mjs"`.
6. Run `npm run size` → confirm exit 0.

### Acceptance criteria
- [ ] `pinscope/scripts/check-bundle-size.mjs` exists, executable, exits 0 against current bundle.
- [ ] `pinscope/package.json` size-limit array contains BOTH a `limit: '80 KB'` entry AND a `limit: '25 KB', gzip: true` entry.
- [ ] `npm run size` returns exit 0.
- [ ] Mutation gate: artificially append 200KB of dummy content to `dist/runtime/PinScope.js` → re-run `npm run size` → MUST exit 1.

### Definition of Done
R-23-01 is closed when, against the current bundle, `npm run size` exits 0 AND the mutation gate (artificially-bloated chunk) makes it exit 1. The DoD is mechanically checkable by anyone who never saw the change: `git show` the size-limit array (two entries), run `npm run size`, then `(echo; head -c 200000 /dev/urandom | base64) >> dist/runtime/PinScope.js; npm run size; echo $?` — must print non-zero.

### Dependencies
None — independent of all other R-items. Owns `package.json` + new `scripts/check-bundle-size.mjs`.

### Risk assessment
**Medium.** Risk #1: current bundle may already exceed 25 KB gz, in which case the new check correctly exits 1 and we must EITHER refactor the bundle OR re-evaluate the 25 KB threshold against SPEC. The HALT step (#3) mitigates this. Risk #2: baseline drift on different OS/Node versions — `zlib.gzipSync` is deterministic per input, so OK.

---

## Remediation R-23-03

**Linked finding:** F-23-03
**Severity:** P2
**Spec anchor:** SPEC §I-1 — Webpack/Next.js scoped to wrapper-only in v2.0; AC-091 "type-level + runtime import test"; AC-092 "importable and return valid config objects".
**Root cause:** AC-091/092 tests check definedness without invocation. Specifically: the immutability guarantee (input config not mutated), the host webpack passthrough (wrapper actually calls user's webpack with args), and the no-op-when-disabled behavior of `PinScopeWebpackPlugin.apply` are all unverified. A regression that breaks any of these would not surface — same false-PASS shape as F-23-01.

### Ecosystem analysis
1. What does SPEC §I-1 actually require? "wrapper-only in v1.0/v2.0" — the wrapper composes (doesn't replace) the user's webpack function; doesn't inject a loader.
2. What does the wrapper currently do? `withPinScope` spreads `{...nextConfig, webpack: ...}` and conditionally calls `nextConfig.webpack` if defined.
3. What's untested? (a) `withPinScope({...})` does NOT mutate the input object (spread-vs-return-same matters); (b) the wrapper's `webpack` function actually invokes `nextConfig.webpack` with the (`config`, `context`) args; (c) `PinScopeWebpackPlugin.apply` is no-op when `enabled:false` (the `void compiler.hooks;` stub would satisfy the test even if it threw).
4. Why does plan-mode F-23-02 (AC-001 plugin-shape `toBeDefined×4`) NOT need fixing? Because AC-001's spec claim is "plugin shape", and behavior coverage is provided by sibling AC-013 (transform) + AC-009 (transformIndexHtml) per test-quality re-audit. F-23-02 is polish, not gating.
5. Does this require a matrix edit? No. The matrix recipe stays `vitest-tag` `AC-091` / `AC-092` `min_tests: 1`. We add tests under existing tags; the recipe still passes.

### Execution plan
**Files to modify:** `pinscope/tests/unit/deployment.test.ts` — add 3 new `it()` blocks under the AC-092 describe and 1 new under AC-091:
- AC-092a: spy on host-webpack passthrough — `let called = false; const hostWebpack = (cfg, ctx) => { called = true; return cfg; }; const wrapped = withPinScope({webpack: hostWebpack}); wrapped.webpack({}, {}); expect(called).toBe(true)`.
- AC-092b: immutability — `const input = Object.freeze({reactStrictMode: true}); expect(() => withPinScope(input)).not.toThrow()` AND `expect(input).toEqual({reactStrictMode: true})` after wrap (no mutation).
- AC-092c: `PinScopeWebpackPlugin.apply` no-op when disabled — `const plugin = new PinScopeWebpackPlugin({enabled: false}); const hooksProxy = new Proxy({}, {get: () => { throw new Error('hooks accessed'); }}); expect(() => plugin.apply({hooks: hooksProxy})).not.toThrow()` — fails if `apply` accesses hooks.
- AC-091: confirm `pinscope` runtime export resolves to the actual plugin function — `const mod = await import('pinscope'); expect(typeof mod.pinscope).toBe('function'); expect(mod.pinscope({}).name).toBe('vite-plugin-pinscope')` (asserts the SPEC's named-export contract beyond mere definedness).

**Files that MUST remain untouched:** `pinscope/src/plugin/webpack.ts` (the no-op stub IS spec-faithful per §I-1), `pinscope/src/plugin/next.ts` (the wrapper IS spec-faithful), `convergence/ac-matrix.json`.

### Acceptance criteria
- [ ] 4 new `it()` blocks added under AC-091 + AC-092 describes in deployment.test.ts.
- [ ] All 4 PASS green against unmodified `webpack.ts`/`next.ts`.
- [ ] Mutation gate: change `next.ts` `withPinScope` `return { ...nextConfig, webpack: ... }` to `return nextConfig` → immutability test (AC-092b) MUST go RED. Change `webpack.ts` `if (!enabled) return;` to no-op → no-op test (AC-092c) MUST go RED.

### Definition of Done
R-23-03 closed when 4 new tests pass green; both mutation tests turn red. `git diff --stat` shows ZERO changes to `webpack.ts`/`next.ts`/`ac-matrix.json`.

### Dependencies
None — same-file co-location with R-23-01 in Wave 2 (R-23-01 modifies package.json; R-23-03 modifies deployment.test.ts — disjoint).

### Risk assessment
**Low.** Test-only additions; existing tests not modified.

---

## Remediation R-23-05

**Linked finding:** F-23-05
**Severity:** P2
**Spec anchor:** SPEC §8.11 — 13 keyboard shortcuts table.
**Root cause:** `useKeyboardShortcuts.ts` SHORTCUTS table has 13 entries including `'command'` (Cmd+K) and `'escape'`, but PinScope.tsx handler dispatch services only 11 of them. The remaining 2 are handled DIRECTLY in `CommandBar.tsx` L72-84 (Cmd+K focus) and `useSelectedElement.ts` L73 (Escape blur) — bypassing the dispatch. The table entries are dead code; their type-union membership pollutes type-check completeness without functional value.

### Ecosystem analysis
1. Will deletion break user-facing behavior? No — CommandBar.tsx and useSelectedElement.ts retain their direct listeners. Narrative-auditor confirmed: "Deleting them does NOT break NC-08-13 (Shift+P), NC-08-14 (Shift+C), or §8.11/§8.6 user-facing behaviour."
2. Are there tests that reference `'command'`/`'escape'` shortcut ids? grep needed at execution time — IF yes, must update those tests to reference the direct handlers OR remove the obsolete coverage.
3. Does this require a SPEC edit? Yes for cleanliness — SPEC §8.11 lists all 13 in a table; a footnote should clarify the ownership split. But SPEC freeze allows docs-only footnote additions (does not change normative claims). If user prefers, the footnote can go in `pinscope/README.md` instead of SPEC.
4. Does this require a matrix edit? No — no AC verifies the SHORTCUTS table membership.

### Execution plan
**Files to modify:**
- `pinscope/src/runtime/hooks/useKeyboardShortcuts.ts` — remove `'command'` and `'escape'` from `ShortcutId` union and `SHORTCUTS` table.
- `pinscope/SPEC.md` §8.11 footnote (preferred) OR `pinscope/README.md` — add note: "Cmd+K (focus CommandBar) and Escape (blur CommandBar / clear selection) are owned by CommandBar.tsx and useSelectedElement.ts directly, not by the SHORTCUTS dispatch table. They are §8.11 user-facing shortcuts; the dispatcher serves the remaining 11."
- Any tests referencing the deleted ids — TBD at execution; expected zero impact.

**Files that MUST remain untouched:** `pinscope/src/runtime/components/CommandBar.tsx` (Cmd+K handler preserved), `pinscope/src/runtime/hooks/useSelectedElement.ts` (Escape handler preserved), `pinscope/src/runtime/PinScope.tsx` (handler dispatch dict unchanged — it never serviced the two deleted ids).

### Acceptance criteria
- [ ] `grep -nE "'command'|'escape'" pinscope/src/runtime/hooks/useKeyboardShortcuts.ts` returns 0 hits.
- [ ] `cd pinscope && npm run typecheck` exits 0 (the type-union narrowing must not break any callers).
- [ ] `cd pinscope && npm test` is green — Cmd+K + Escape user behavior tests still pass (CommandBar focus test, Escape blur test).
- [ ] SPEC §8.11 footnote OR README note added — explicit ownership documentation.

### Definition of Done
R-23-05 closed when grep returns 0 hits for the deleted ids in `useKeyboardShortcuts.ts`, typecheck passes, full test suite green, AND the ownership footnote exists in either SPEC §8.11 OR README. Mechanically checkable.

### Dependencies
None. Owns useKeyboardShortcuts.ts + SPEC.md (footnote) or README.

### Risk assessment
**Low.** Dead-code deletion with no functional dependents. The footnote-in-SPEC question is a small judgment call; default to SPEC §8.11 footnote (docs-only, not a contract change).

---

## Remediation R-23-06

**Linked finding:** F-23-06 (CONFIRMED-PARTIAL-SCOPE) + NF-23-01 (narrative blocking)
**Severity:** P2 (with P3 narrative blocking attached)
**Spec anchor:** §12 — "iframes (same-origin inject, cross-origin outline only)"; AC-061 manual+BLOCKED.
**Root cause:** `pinscope/src/runtime/utils/iframe-overlay.ts` exports `markCrossOriginFrames`, `isIframeLimited`, `IFRAME_OVERLAY_ATTR` — 0 runtime consumers; only consumed by `iframe-overlay.test.ts`. The §12 cross-origin-outline claim has no covering AC (AC-061 is manual+BLOCKED — never asserts) AND no runtime code. Whether to delete the helper or wire it requires user disposition.

### Ecosystem analysis (scope correction applied)
1. **Original plan vs. corrected scope.** The plan-mode design proposed deleting 3 files (iframe-overlay.ts, screenshot.ts, rect-math.ts). The narrative-auditor's deletion-safety review caught that screenshot.ts and rect-math.ts are AC-backed (AC-076 + AC-062 vitest-tag tests import them). Deletion would cause CLOSED→FAIL regression. **R-23-06 scope is corrected to delete iframe-overlay.ts ONLY.**
2. What does deletion accomplish? Removes dead code (no runtime consumer; AC-061 is manual+BLOCKED). Reduces code-quality noise. Does NOT improve any matrix metric (AC-061 stays BLOCKED).
3. What does deletion WORSEN? NF-23-01 — the §12 cross-origin-outline narrative claim. With the helper present, the claim is "code exists but dormant" (suspect). With the helper deleted, the claim is "no code at all" (strict violation). Both states keep `uncovered_unsatisfied: 1` in the narrative ledger, but the latter is more honest about the gap.
4. **User disposition (NF-23-01):** Three honest paths: (a) delete iframe-overlay.ts AND propose SPEC §12 bump to remove cross-origin clause (most honest); (b) wire `markCrossOriginFrames` into `PinScopeHud` (does not satisfy AC-061 — still needs browser CI — but makes §12 code-satisfied); (c) keep dormant + accept the narrative gap. The user already approved Strategy A "fix everything" — interpreting that as path (a): **delete + propose SPEC bump** (the SPEC bump is recorded as a candidate, not auto-applied — `/ps-heal` cannot edit SPEC.md without user approval, but R-23-06 records the bump proposal in `convergence/SPEC-BUMP-PROPOSAL-R23.md`).

### Execution plan
**Files to delete:** `pinscope/src/runtime/utils/iframe-overlay.ts`, `pinscope/tests/unit/runtime/iframe-overlay.test.ts`.
**Files to modify:** `pinscope/src/index.ts` — IF iframe-overlay re-exports anything in the public API, remove them.
**Files to create:** `pinscope/convergence/SPEC-BUMP-PROPOSAL-R23.md` — proposes removing `§12 "iframes (cross-origin outline only)"` from SPEC.md (or reframing as "v2.1+ deferred"). Pending user acceptance.
**Files that MUST remain untouched:** `pinscope/src/runtime/utils/screenshot.ts`, `pinscope/src/runtime/utils/rect-math.ts`, `pinscope/tests/unit/screenshot.test.ts`, `pinscope/tests/unit/edge-utils.test.ts`, `pinscope/SPEC.md` (the SPEC bump is a proposal, not applied), `pinscope/convergence/ac-matrix.json`.

### Acceptance criteria
- [ ] `pinscope/src/runtime/utils/iframe-overlay.ts` does not exist.
- [ ] `pinscope/tests/unit/runtime/iframe-overlay.test.ts` does not exist.
- [ ] `grep -rn "iframe-overlay\|markCrossOriginFrames\|isIframeLimited\|IFRAME_OVERLAY_ATTR" pinscope/src pinscope/tests` returns 0 hits.
- [ ] `cd pinscope && npm run typecheck` exits 0 (no orphaned import).
- [ ] `cd pinscope && npm test` is green; `dist/` rebuild succeeds.
- [ ] `pinscope/convergence/SPEC-BUMP-PROPOSAL-R23.md` exists, names §12 clause, explicitly notes user approval required.
- [ ] AC-061 status in `loop.json` unchanged (stays BLOCKED — no metric movement).

### Definition of Done
R-23-06 closed when iframe-overlay source + test files are deleted, typecheck/tests pass, and SPEC-bump proposal artifact exists. The narrative gap (NF-23-01) explicitly remains `uncovered_unsatisfied: 1` until the user accepts or rejects the bump — recorded honestly in ROUND-R23-CLOSURE.md.

### Dependencies
None — independent of other R-items. Touches own files.

### Risk assessment
**Medium.** Risk #1: a grep we missed has a consumer outside `pinscope/` — mitigation: full repo grep at execution time. Risk #2: the SPEC bump proposal gets ignored, leaving the narrative gap recorded forever — accepted as the loop's correct behavior (the loop should NEVER auto-edit SPEC; user decision).

---

## Remediation R-23-07

**Linked finding:** F-23-07 (NEW P0)
**Severity:** P0
**Spec anchor:** §A.13 AC-071 "hover→InfoPanel update < 8 ms/frame. **verify:** perf test measures the rAF callback duration."
**Root cause:** `tests/unit/runtime/perf.test.tsx` AC-071 test runs a synthetic loop over `findPinnedAncestor + getBoundingClientRect` (a few microseconds total) and divides by iteration count. It does NOT use requestAnimationFrame, does NOT trigger React state update, does NOT render the InfoPanel update, does NOT measure layout. The actual hover→InfoPanel path involves rAF schedule → React state update → InfoPanel re-render → layout. **The verify clause names a measurement the test does not perform.** Same false-PASS shape as F-23-01 (AC-073).

### Ecosystem analysis
1. What's the production hover→InfoPanel path? `useHoveredElement` hook listens to `mousemove` → schedules rAF → on rAF tick, calls `findPinnedAncestor(target)` → calls `setHovered(pin)` → React re-renders → `InfoPanel` reads new `hovered` → reads `getBoundingClientRect` to position → DOM commits. The full per-frame cost is dominated by React re-render + layout, NOT by `findPinnedAncestor` + one `getBoundingClientRect`.
2. Why is the current test a false-PASS? Because the synthetic loop measures only the input-walking sub-step (microseconds), it can never exceed 8 ms unless the JIT collapses. The actual rAF callback (microbatch with React) could easily exceed 8 ms while this test always passes.
3. What's the correct shape? Render `<PinScope />` with happy-dom, attach a `performance.mark` before dispatching `mousemove`, attach `performance.mark` after the rAF tick observably updates the InfoPanel (e.g., observe via `MutationObserver` on InfoPanel content OR wait for React state to commit via `await act(() => Promise.resolve())`), compute the duration, assert < 8 ms.
4. Will this test pass under happy-dom? happy-dom's rAF is synchronous-ish (calls callback synchronously OR queues to microtask). Layout is mostly a no-op. The measured duration will be much smaller than a real browser would show — BUT the test will catch a real regression (e.g., adding a 10ms work item to the rAF callback) which the current synthetic-loop test cannot.
5. Does this require a matrix edit? No. The matrix recipe stays `vitest-tag` `AC-071` `min_tests: 1`. We rewrite the test under the same tag.

### Execution plan
**Files to modify:** `pinscope/tests/unit/runtime/perf.test.tsx` — REPLACE the AC-071 `it()` block. New shape:
```ts
it('keeps hover per-frame work under 8 ms (AC-071)', async () => {
  // Mount the assembled <PinScope/> so the measurement covers the
  // production rAF callback (React state update + InfoPanel re-render),
  // not a synthetic micro-bench of one utility call.
  const host = document.createElement('div');
  host.innerHTML = '<section data-pin="e_1"><button data-pin="e_2"><span>x</span></button></section>';
  document.body.appendChild(host);
  const { container } = render(<PinScope />);
  const span = host.querySelector('span') as HTMLElement;

  // Warm — first hover pays one-time JIT/module-eval cost.
  span.dispatchEvent(new MouseEvent('mousemove', { bubbles: true }));
  await new Promise<void>((r) => requestAnimationFrame(() => r()));

  const start = performance.now();
  span.dispatchEvent(new MouseEvent('mousemove', { bubbles: true }));
  await new Promise<void>((r) => requestAnimationFrame(() => r()));
  const perFrame = performance.now() - start;
  expect(perFrame).toBeLessThan(8);
});
```
Keep the original AC-070 test (mount budget) unchanged.

**Files that MUST remain untouched:** `pinscope/src/runtime/hooks/useHoveredElement.ts`, `pinscope/src/runtime/PinScope.tsx`, `pinscope/src/runtime/components/InfoPanel.tsx`, `convergence/ac-matrix.json`.

### Acceptance criteria
- [ ] AC-071 `it()` block rewritten to use `render(<PinScope />)` + real `mousemove` dispatch + rAF wait.
- [ ] Test PASSes against unmodified production code.
- [ ] Mutation gate: temporarily add `for (let i=0; i<1e8; i++);` (busy loop) to `useHoveredElement`'s rAF callback → test MUST go RED. Revert after.
- [ ] The original synthetic-loop assertion (`findPinnedAncestor + getBoundingClientRect`) is REMOVED — it remained as misleading evidence.

### Definition of Done
R-23-07 closed when the new AC-071 test passes green AND the mutation gate (1e8 busy-loop injection in the rAF callback) makes it red. `git diff --stat` shows changes to `perf.test.tsx` only; production source untouched.

### Dependencies
None.

### Risk assessment
**Medium.** Risk #1: happy-dom rAF semantics — if happy-dom executes rAF callbacks too aggressively, the measurement may be artificially low and a real production regression may not surface. Mitigation: the test is still strictly stronger than the synthetic loop (covers React re-render + layout-attempt, even if layout is partial under happy-dom), so it catches the gross failure modes. Risk #2: AC-070 flake (mount budget) was a watchlist item — adding more `<PinScope/>` renders increases concurrent load. Mitigation: cleanup between tests (`afterEach` already in place).

---

## Remediation R-23-08

**Linked finding:** F-22-01 (SUSPECTED P3 carry-forward)
**Severity:** P3
**Spec anchor:** SPEC §12 — touch tap/long-press + responsive collapse; AC-064 verifies resize round trip (not compact-tap).
**Root cause:** R-21-01's compact-viewport branch renders `<FloatingToggle onShow={() => setHudVisible(true)} />`. But `hudVisible` defaults to `true` and the parent `if (!hudVisible) return <FloatingToggle/>` branch never fires (because `hudVisible` is true). Even when user enters compact viewport, `hudVisible` stays true so the toggle never appears. The inline comment promises "the user can re-expand by tapping it" — but the conditional rendering chain never reaches the FloatingToggle in the compact-viewport branch when HUD is visible.

### Ecosystem analysis
1. What's the correct compact-viewport contract? When the viewport collapses below 768px (`isCompactViewport === true`), the HUD layout should switch to compact mode. In compact mode, the user should be able to dismiss the HUD AND re-summon it via tap. The current code provides dismiss (via `setHudVisible(false)`) but the re-summon path is broken because the `!hudVisible` branch doesn't reach the compact tree.
2. What's the fix? Two options: (a) refactor the conditional to: `if (isCompactViewport && !hudVisible) return <FloatingToggle onShow={...} />`; otherwise full HUD; (b) always render the FloatingToggle in compact mode regardless of `hudVisible`, with `display: none` when HUD is visible.
3. Option (a) is cleaner and matches the original intent of R-21-01.
4. Does this require a SPEC edit? No — the §12 narrative already covers it; the code just doesn't deliver.
5. Does this require a matrix edit? AC-064 currently verifies resize round trip only. Strengthening AC-064 to also verify compact-tap is a polish opportunity; the current AC stays GREEN even with this bug fixed (the bug is hollow interaction, not failing test).

### Execution plan
**Files to modify:** `pinscope/src/runtime/PinScope.tsx` — restructure the `PinScopeHud` compact-viewport branch so that when `isCompactViewport && !hudVisible`, the FloatingToggle is rendered with a working onShow.
**Tests to modify:** `pinscope/tests/unit/runtime/pinscope.test.tsx` — add a DoD test under the R-21-01 describe block (or under a new R-23-08 describe): render `<PinScope />`, simulate viewport resize to <768px, simulate `setHudVisible(false)` via the dismiss handler, assert FloatingToggle is in the DOM, dispatch tap event, assert HUD is visible again.
**Files that MUST remain untouched:** existing R-21-01 tests (must stay green); `convergence/ac-matrix.json` (AC-064 recipe unchanged).

### Acceptance criteria
- [ ] PinScope.tsx compact-viewport conditional restructured so `FloatingToggle.onShow` is reachable.
- [ ] New DoD test in pinscope.test.tsx asserts: dismiss → toggle visible → tap → HUD visible again.
- [ ] Existing R-21-01 tests (compact-collapse + responsive layout) still green.
- [ ] `cd pinscope && npm run typecheck` exits 0; `npm test` green.

### Definition of Done
R-23-08 closed when the new compact-tap-summon DoD test passes red (against pre-fix code) → green (against post-fix). Existing AC-064 + R-21-01 tests stay green.

### Dependencies
None — independent.

### Risk assessment
**Low.** Small targeted UI fix; bounded by existing R-21-01 test coverage.

---

## Round-summary across all R-items

| R-ID | Severity | Files (main owner per wave) | Wave |
|---|---|---|---|
| R-23-01 | P0 | scripts/check-bundle-size.mjs (new), package.json | W2 |
| R-23-03 | P2 | tests/unit/deployment.test.ts | W2 |
| R-23-05 | P2 | useKeyboardShortcuts.ts + SPEC §8.11 footnote | W1 |
| R-23-06 | P2 | iframe-overlay.ts + test (delete) + SPEC-BUMP-PROPOSAL | W3 |
| R-23-07 | P0 | tests/unit/runtime/perf.test.tsx | W1 |
| R-23-08 | P3 | PinScope.tsx + pinscope.test.tsx | W1 (or solo W4) |

6 R-items total. The two P0 closures (R-23-01, R-23-07) break the verify-clause-vs-test-mismatch class for AC-073 + AC-071. The remaining 4 are P2/P3 cleanups + small targeted fix.
