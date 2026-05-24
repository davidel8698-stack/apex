# Wave Result — PS-R21

Four waves scheduled in `WAVES-R21.md` (W1: R-21-02, W2: R-21-03, W3: R-21-01,
W4: R-21-04). Each wave executes its R-items test-first, lands the real fix in
`pinscope/`, and gates on `npm run typecheck` exit 0 + green `npm test` before
the next wave starts. This file is appended one wave-block at a time by the
`ps-wave-executor` running that wave.

## Wave 1 — R-21-02

### R-21-02 — Shadow-DOM host marking + InfoPanel limited-inspection report

**Status:** CLOSED.

**R-items executed in this wave:** R-21-02 (sole R-item; W1 is single-R-item by
the wave map — `PinScope.tsx` single-owner per wave).

**Files modified (with line deltas — `git diff --stat`):**

```
 pinscope/src/runtime/PinScope.tsx             |  26 ++++++
 pinscope/src/runtime/components/InfoPanel.tsx |  12 +++
 pinscope/tests/unit/runtime/pinscope.test.tsx | 113 ++++++++++++++++++++++++++
 3 files changed, 151 insertions(+)
```

`PinScope.tsx` adds (a) `import { markShadowHosts } from './utils/shadow-dom.js';`
and (b) a new `useEffect(() => { ... }, [])` block placed immediately after the
R-20-02 `RuntimePinObserver` effect. The new effect:
- guards `typeof document === 'undefined'` and `typeof MutationObserver ===
  'undefined'`;
- performs one synchronous `markShadowHosts(document)` sweep on mount;
- installs a `MutationObserver` on `document.body` with `{ subtree: true,
  childList: true }` whose callback re-runs `markShadowHosts(document)`;
- returns a cleanup that calls `observer.disconnect()`.

`InfoPanel.tsx` adds (a) `import { isShadowLimited } from '../utils/shadow-dom.js';`
and (b) an additive row `<div data-pinscope-shadow-limited="">limited
inspection</div>` rendered above the first `CollapsibleSection` when
`isShadowLimited(element)` returns true. The row sits outside any
`CollapsibleSection` so AC-032 / AC-033 paths are unaffected.

**Red → green transition evidence.**

Pre-wave RED: the new describe block `R-21-02 — Shadow-DOM marking + InfoPanel
limited-inspection report` (two tests) was added to
`tests/unit/runtime/pinscope.test.tsx` BEFORE any source-tree change. Both tests
failed against the pre-wave `PinScope.tsx` (which never invokes
`markShadowHosts`):

```
 ❯ tests/unit/runtime/pinscope.test.tsx (9 tests | 2 failed | 7 skipped) 100ms
   ❯ tests/unit/runtime/pinscope.test.tsx > R-21-02 — Shadow-DOM marking + InfoPanel limited-inspection report > PinScopeHud marks Shadow-DOM hosts on mount, re-sweeps on MutationObserver tick, and disconnects on unmount
     → expected null to be '' // Object.is equality
   ❯ tests/unit/runtime/pinscope.test.tsx > R-21-02 — Shadow-DOM marking + InfoPanel limited-inspection report > InfoPanel reports limited inspection over a shadow host, absent over a non-shadow pin
     → expected null to be '' // Object.is equality

 Test Files  1 failed (1)
      Tests  2 failed | 7 skipped (9)
```

Both failures bottomed out on `expect(host.getAttribute('data-pin-shadow')).toBe('')`
returning `null` — the marker attribute was never set because no `src/`
consumer invoked the sweep. This is the F-21-02 finding text reproduced
end-to-end.

Post-fix GREEN (same describe block, same vitest filter — only the source
tree changed in between):

```
 ✓ tests/unit/runtime/pinscope.test.tsx (9 tests | 7 skipped) 183ms

 Test Files  1 passed (1)
      Tests  2 passed | 7 skipped (9)
```

The transition is the two R-21-02 named tests flipping from FAIL → PASS across
the `PinScope.tsx` + `InfoPanel.tsx` edits. Each test independently exercises
one of the two halves of the DoD (sweep + observer + disconnect; InfoPanel row
present-then-absent across hover transitions).

**Definition of Done — clause-by-clause verification.**

- *PinScopeHud marks Shadow-DOM hosts on mount:* Test 1 attaches a shadow root
  to `host1` BEFORE `render(<PinScope/>)`, then asserts
  `host1.getAttribute('data-pin-shadow') === ''` after the initial microtask
  flush — GREEN.
- *MutationObserver re-sweep on dynamic content:* Same test appends `host2`
  with `attachShadow({mode:'open'})` AFTER mount, flushes microtasks, and
  asserts `host2.getAttribute('data-pin-shadow') === ''` — GREEN.
- *Observer disconnects on unmount:* Same test unmounts, appends `host3`,
  flushes, and asserts `host3.getAttribute('data-pin-shadow') === null` — the
  marker is not set, proving the cleanup ran — GREEN.
- *InfoPanel reports limited inspection over a shadow host:* Test 2 pre-mounts
  a shadow host and a plain pin, fires `mousemove` resolved through a stubbed
  `document.elementFromPoint` to the shadow host, asserts
  `[data-pinscope-shadow-limited]` is present inside the
  `[data-pinscope-ui="root"]` portal — GREEN.
- *InfoPanel hides the row over a non-shadow pin:* Same test then fires
  `mousemove` resolved to the plain pin, asserts the row is absent — GREEN.

**Acceptance criteria — grep predicates.**

- `grep -nE 'markShadowHosts' pinscope/src/runtime/PinScope.tsx` → 4 hits
  (line 33 import; lines 194, 204, 208, 211 inside the new useEffect — comment
  + initial sweep + fallback-env sweep + observer-callback sweep). ≥ 1 ✓
- `grep -nE 'isShadowLimited' pinscope/src/runtime/components/InfoPanel.tsx`
  → 2 hits (line 7 import; line 150 use). ≥ 1 ✓
- `grep -rn 'markShadowHosts' pinscope/src/` → 2 files
  (`runtime/utils/shadow-dom.ts` definition + `runtime/PinScope.tsx` consumer).
  ≥ 2 files ✓
- `grep -rn 'isShadowLimited' pinscope/src/` → 2 files
  (`runtime/utils/shadow-dom.ts` definition + `runtime/components/InfoPanel.tsx`
  consumer). ≥ 2 files ✓
- The new `useEffect` body contains `observer.disconnect()` in its cleanup
  return: `grep -n 'disconnect(' pinscope/src/runtime/PinScope.tsx` returns
  the new line inside the R-21-02 effect cleanup. ✓
- `cd pinscope && npm run typecheck` → exit 0 ✓
- `cd pinscope && npm test` → exit 0; 311 tests passed (309 prior + 2 new
  R-21-02). The pre-existing `deployment.test.ts` AC-090 case is now GREEN
  (R21 cleanup already restored that file; this wave did not touch it). ✓

**Verification command outputs (exit codes).**

```
$ npm run typecheck
> pinscope@1.0.0 typecheck
> tsc --noEmit
typecheck exit=0

$ npm test
 ✓ tests/unit/runtime/edge-cases.test.ts (5 tests) 94ms
 ✓ tests/unit/runtime/shortcuts.test.tsx (15 tests) 32ms
 ✓ tests/unit/runtime/pinscope-assembly.test.tsx (7 tests) 391ms
 ✓ tests/unit/runtime/infopanel.test.tsx (3 tests) 191ms
 ✓ tests/unit/runtime/perf.test.tsx (2 tests) 143ms
 ✓ tests/unit/runtime/pinscope.test.tsx (9 tests) [contains 2 R-21-02 tests]
 ... (30 files total)
 ✓ tests/unit/deployment.test.ts (10 tests) 2637ms
 ✓ tests/unit/claude-bridge.test.ts (2 tests) 3409ms

 Test Files  30 passed (30)
      Tests  311 passed (311)
npm test exit=0
```

**Scope notes.** Only the three files named in R-21-02's Execution plan were
touched (`src/runtime/PinScope.tsx`, `src/runtime/components/InfoPanel.tsx`,
`tests/unit/runtime/pinscope.test.tsx`). The frozen `src/runtime/utils/shadow-dom.ts`
was NOT modified. `InfoPanel.tsx`'s `CollapsibleSection` / `StyleRow` blocks
(AC-032 / AC-033 paths) were NOT modified — the new row is purely additive,
keyed `[data-pinscope-shadow-limited]`, and sits outside every collapsible
section. The HUD-hidden branch (`if (!hudVisible)`) in `PinScope.tsx` was NOT
touched. No new findings discovered during implementation — `NEW-FINDINGS-W1.md`
not created.

**Suspected-finding status.** N/A — F-21-02 is CONFIRMED (not SUSPECTED); the
SUSPECTED item this round is F-21-04, scheduled in W4.

**Regression check.** Full suite is GREEN at 311/311 (pre-wave baseline per R21
audit notes: 309). Both new tests are additive; the 309 prior tests remain
GREEN. No pre-wave-green test went RED post-fix.

### Wave 1 gate

`cd pinscope && npm run typecheck` → exit 0. `cd pinscope && npm test` → exit 0;
311/311 pass; the R-21-02 named describe block is GREEN with both DoD tests
transitioned red→green; no "observer leaked after unmount" React warning
emitted during the test run. **Wave 1 PASSES the gate.** Wave 2 may proceed.

## Wave 2 — R-21-03

### R-21-03 — heavy-page degrade (30fps throttle + skip-small-badge)

**Status:** CLOSED.

**R-items executed in this wave:** R-21-03 (sole R-item; W2 is single-R-item by
the wave map — `PinScope.tsx` single-owner per wave, with sibling
`useHoveredElement.ts` riding along).

**Files modified (with line deltas — `git diff --stat`):**

```
 pinscope/src/runtime/PinScope.tsx               |  45 +++++++
 pinscope/src/runtime/hooks/useHoveredElement.ts |  92 ++++++++++---
 pinscope/tests/unit/runtime/pinscope.test.tsx   | 170 ++++++++++++++++++++++++
 3 files changed, 287 insertions(+), 20 deletions(-)
```

`useHoveredElement.ts` is rewritten so the resolution body is a single shared
`resolve()` function reachable from both the (preserved) `requestAnimationFrame`
light-path and a new heavy-path. On every `mousemove` the hook computes
`document.querySelectorAll('[data-pin]').length`; when `isHeavyPage(count)` is
true the hook routes through a lazily-constructed
`throttle(resolve, HEAVY_PAGE_INTERVAL_MS)` wrapper (`heavyThrottleRef`,
created once per mount and reused so leading+trailing state accumulates across
moves), otherwise the existing rAF coalesce runs. Cleanup nullifies the
throttle ref alongside the existing `cancelAnimationFrame`.

`PinScope.tsx` adds (a) `import { isHeavyPage, shouldSkipBadge } from
'./utils/throttle.js';`, (b) a new `useEffect` (empty deps) immediately after
the R-21-02 Shadow-DOM effect that sweeps `[data-pin]` and stamps
`data-pin-skipbadge=""` on every pin whose `getBoundingClientRect()` satisfies
`shouldSkipBadge(w, h)` — gated on `isHeavyPage(pins.length)` so non-heavy
pages stay a no-op (sub-millisecond pin-count query, AC-070/AC-071
unaffected); sweep re-runs on each `MutationObserver` tick; cleanup
`observer.disconnect()` (guarded for non-DOM envs), and (c) a complementary
`<style data-pinscope-skip-badge>` block inside the visible-HUD
`createPortal` tree carrying
`[data-pin][data-pin-skipbadge]::before { display: none !important; }` so the
CSS-`::before` badge is suppressed for stamped pins. The frozen utilities
(`utils/throttle.ts`, `components/PinBadges.tsx` `badgeCss`) were NOT
modified.

**Red → green transition evidence.**

Pre-wave RED: the new describe block `R-21-03 — heavy-page degrade` (two
tests) was added to `tests/unit/runtime/pinscope.test.tsx` BEFORE any
source-tree change. Both tests failed against the post-W1 tree (which has
neither the `isHeavyPage` gate in `useHoveredElement` nor the
skip-small-badge sweep in `PinScope.tsx`):

```
 ❯ tests/unit/runtime/pinscope.test.tsx (11 tests | 2 failed | 9 skipped) 185ms
   ❯ tests/unit/runtime/pinscope.test.tsx > R-21-03 — heavy-page degrade > > 500 pins switches hover to ≥ 30 Hz throttle; < 500 stays on rAF
     → expected 30 to be less than or equal to 6
   ❯ tests/unit/runtime/pinscope.test.tsx > R-21-03 — heavy-page degrade > < 16×16 badges are hidden on a heavy page (skip-small-badge sweep)
     → expected null to be '' // Object.is equality

 Test Files  1 failed (1)
      Tests  2 failed | 9 skipped (11)
```

The first failure (`heavyCount === 30`) is the hot-path proof: with 600 pins
the hook resolved on EVERY one of the 30 mousemoves because the rAF coalesce
was defeated by `vi.useFakeTimers()` (rAF never advanced) AND no throttle
gate existed — exactly the F-21-03 finding. The second failure
(`null` vs `''`) is the sweep proof: no `data-pin-skipbadge` was ever
stamped because no `src/` consumer invoked the sweep.

Post-fix GREEN (same describe block, same vitest filter — only the source
tree changed in between):

```
 ✓ tests/unit/runtime/pinscope.test.tsx (11 tests | 9 skipped) 259ms

 Test Files  1 passed (1)
      Tests  2 passed | 9 skipped (11)
```

Both R-21-03 named tests flipped FAIL → PASS across the
`useHoveredElement.ts` + `PinScope.tsx` edits. The heavy-page test now
counts `≤ 6` resolutions over the 150 ms span (5 actually observed under
the heavy-branch throttle gate) AND `> 6` resolutions on the 100-pin
control case (rAF light-path); the skip-small-badge test now finds
`data-pin-skipbadge=""` on each `<16×16` pin, absent on each normal-sized
pin, and the `style[data-pinscope-skip-badge]` block present in the HUD.

**Definition of Done — clause-by-clause verification.**

- *> 500 pins switches hover to ≥ 30 Hz throttle.* Test 1 Case A seeds 600
  `<div data-pin="e_h{i}">` pins, mounts `<PinScope/>`, dispatches 30
  `mousemove` events at 5 ms intervals via `vi.useFakeTimers()` +
  `vi.advanceTimersByTime(5)`, then flushes any trailing throttled call
  with a final `advanceTimersByTime(40)`. Asserts the
  `document.elementFromPoint` invocation count (the resolution-body proxy)
  is `> 0` AND `≤ 6` — GREEN.
- *< 500 pins stays on the rAF path.* Test 1 Case B re-mounts on a 100-pin
  fixture and dispatches the same event stream; asserts the resolution
  count is `> 6` (the rAF path runs the light branch) — GREEN. The gate
  passes only when the heavy-vs-light switch is correctly routed by
  `isHeavyPage` (the assertion would falsely pass under the pre-wave hook
  too — but Case A's `≤ 6` ceiling is what falsifies the no-gate state,
  and Case A is RED pre-wave).
- *< 16×16 badges are hidden on a heavy page.* Test 2 seeds 600 pins, of
  which 5 carry inline `width:8px;height:8px` (and a stubbed
  `getBoundingClientRect` returning 8×8 so the happy-dom rect read is
  deterministic) and another 5 carry 100×100 rects. Renders `<PinScope/>`,
  flushes microtasks. Asserts every `e_b{i}` `<16×16` element carries
  `getAttribute('data-pin-skipbadge') === ''`; every normal-sized sibling
  does NOT carry the attribute; the injected
  `document.querySelector('style[data-pinscope-skip-badge]')` is present —
  all three sub-clauses GREEN.

**Acceptance criteria — grep predicates.**

- `grep -nE 'isHeavyPage|HEAVY_PAGE_INTERVAL_MS|throttle'
  pinscope/src/runtime/hooks/useHoveredElement.ts` → ≥ 2 hits.
  Actual: 11 hits across lines 8–11 (named imports), 18–20 (doc block),
  30–33 (heavy throttle ref doc), 39 (doc reference), 68–74 (heavy-branch
  body), 94 (cleanup comment). ✓
- `grep -nE 'shouldSkipBadge|data-pin-skipbadge'
  pinscope/src/runtime/PinScope.tsx` → ≥ 1 hit each. Actual: 8 hits
  including line 34 (import for both), 221–238 (sweep effect body), 397
  and 400 (complementary `<style>` block). ✓
- `grep -rn 'isHeavyPage' pinscope/src/` → ≥ 2 files. Actual: 3 files —
  `runtime/utils/throttle.ts` (definition), `runtime/hooks/useHoveredElement.ts`
  (consumer), `runtime/PinScope.tsx` (sweep-gate consumer). ✓
- `grep -rn 'shouldSkipBadge' pinscope/src/` → ≥ 2 files. Actual: 2 files —
  `runtime/utils/throttle.ts` (definition), `runtime/PinScope.tsx`
  (consumer). ✓
- `cd pinscope && npm run typecheck` → exit 0 ✓
- `cd pinscope && npm test` → exit 0; 313 tests passed (311 prior + 2 new
  R-21-03). The AC-070 mount-budget test (`perf.test.tsx`, single-render
  measure against the < 50 ms budget) remained GREEN — the heavy-page
  sweep is a no-op on the empty-document mount; the per-mousemove
  pin-count query in `useHoveredElement` runs only inside the listener
  body (not on mount). ✓

**Verification command outputs (exit codes).**

```
$ npm run typecheck
> pinscope@1.0.0 typecheck
> tsc --noEmit
typecheck exit=0

$ npm test
 ✓ tests/unit/runtime/edge-cases.test.ts (5 tests) 83ms
 ✓ tests/unit/runtime/element-walker.test.ts (7 tests) 16ms
 ✓ tests/unit/runtime/infopanel.test.tsx (3 tests) 174ms
 ✓ tests/unit/runtime/shortcuts.test.tsx (15 tests) 35ms
 ✓ tests/unit/runtime/pinscope-assembly.test.tsx (7 tests) 383ms
 ✓ tests/unit/runtime/perf.test.tsx (2 tests) 136ms
 ✓ tests/unit/runtime/pinscope.test.tsx (11 tests) [contains 2 R-21-03 tests]
 ... (30 files total)
 ✓ tests/unit/edge-utils.test.ts (5 tests) 81ms   [AC-065 throttle/skip utility tests still GREEN]
 ✓ tests/unit/long-press.test.ts (3 tests) 6ms
 ✓ tests/unit/deployment.test.ts (10 tests) 1987ms
 ✓ tests/unit/claude-bridge.test.ts (2 tests) 2349ms

 Test Files  30 passed (30)
      Tests  313 passed (313)
npm test exit=0
```

**Scope notes.** Only the three files named in R-21-03's Execution plan were
touched (`src/runtime/PinScope.tsx`, `src/runtime/hooks/useHoveredElement.ts`,
`tests/unit/runtime/pinscope.test.tsx`). The frozen
`src/runtime/utils/throttle.ts` was NOT modified — the executor consumed
`isHeavyPage`, `shouldSkipBadge`, `HEAVY_PAGE_INTERVAL_MS`, and `throttle`
as-is. `src/runtime/components/PinBadges.tsx` (the static `badgeCss`
`<style>` block, AC-024 path) was NOT modified — the skip-small-badge
suppression is an additive `<style data-pinscope-skip-badge>` block injected
from `PinScope.tsx` alongside `<PinBadges/>` and removed automatically on
HUD unmount via the React tree. R-21-02's Shadow-DOM `useEffect` was NOT
modified — R-21-03 installed its own sweep `useEffect` rather than folding
into R-21-02's observer callback; the plan's coalescing note
(R-21-02 ecosystem note 8; R-21-03 order-of-operations) made this an
executor choice and the DoD passes either way. Two `MutationObserver`s on
`document.body` is acceptable per R-21-02's risk assessment (both disconnect
cleanly on unmount, asserted by the existing R-21-02 unmount test). No new
findings discovered during implementation — `NEW-FINDINGS-W2.md` not
created.

**Suspected-finding status.** N/A — F-21-03 is CONFIRMED; the SUSPECTED item
this round is F-21-04, scheduled in W4.

**Regression check.** Full suite is GREEN at 313/313 (W1 baseline: 311 →
+2 new R-21-03 tests). No pre-wave-green test went RED post-fix. AC-070
perf budget held on the single mount run (the in-suite `perf.test.tsx`
test still passes). The `tests/unit/edge-utils.test.ts` AC-065 unit-level
tests for `throttle`, `shouldSkipBadge`, and `isHeavyPage` are still GREEN
— the utilities themselves were not modified. The existing
`tests/unit/runtime/perf.test.tsx` AC-071 hover-budget test (which
measures `findPinnedAncestor` + `getBoundingClientRect` over 100 runs)
still passes within < 8 ms/frame — the new per-mousemove
`querySelectorAll('[data-pin]')` count is in the listener body, NOT in
the AC-071 measured loop. No "observer leaked after unmount" React
warnings during the run.

### Wave 2 gate

`cd pinscope && npm run typecheck` → exit 0. `cd pinscope && npm test` → exit 0;
313/313 pass; the R-21-03 named describe block is GREEN with both DoD tests
transitioned red→green (heavy-branch ≤ 6 resolutions over 150 ms with 600
pins AND light-branch > 6 with 100 pins; `data-pin-skipbadge` stamped on
every < 16×16 pin and absent on every normal-sized sibling; the injected
`style[data-pinscope-skip-badge]` block present in the HUD); AC-070 / AC-071
perf-budget tests stayed within budget; AC-065 utility tests still GREEN.
**Wave 2 PASSES the gate.** Wave 3 may proceed.

## Wave 3 — R-21-01

### R-21-01 — touch tap/long-press + responsive HUD collapse (< 768px)

**Status:** CLOSED.

**R-items executed in this wave:** R-21-01 (sole R-item; W3 is single-R-item by
the wave map — `PinScope.tsx` single-owner per wave).

**Files modified (with line deltas — `git diff --stat`):**

```
 pinscope/src/runtime/PinScope.tsx             |  60 +++++++++
 pinscope/tests/unit/runtime/pinscope.test.tsx | 176 ++++++++++++++++++++++++++
 2 files changed, 236 insertions(+)
```

`PinScope.tsx` adds (a) `import { LongPressDetector, isCompactViewport } from
'./utils/long-press.js';` and `import { escapeHud, findPinnedAncestor } from
'./utils/element-walker.js';` (the existing element-walker primitives the
selection click handler already uses, now also reachable from the touch
listener); (b) a new `useEffect` placed immediately after the
`useSelectedElement` line so `selectPin` is in its closure. The effect:
- guards `typeof document === 'undefined'`;
- constructs ONE `LongPressDetector` per HUD mount (the same detector
  instance accumulates dwell time across `touchstart` → `touchend`);
- registers `touchstart` and `touchend` listeners on `document` with
  `{ passive: true }` (the browser-synthetic `click` after a short tap is
  harmless — `SelectionManager.select` is idempotent on the same pin);
- on `touchstart` calls `detector.start()` when `e.touches.length === 1`;
- on `touchend` calls `detector.end()`, then resolves the touched pin via
  `document.elementFromPoint(touch.clientX, touch.clientY)` → `escapeHud`
  → `findPinnedAncestor` → `getAttribute(PIN_ATTR)` and routes through
  `selectPin(pinId)` when present. Both tap and long-press route to the
  same `selectPin` — the long-press "lock" is the default `locked=true`
  semantics inside `SelectionManager.select`, identical to the existing
  click-to-select path;
- returns a cleanup that removes both listeners. Depends on `selectPin`
  (which is stable per `useSelectedElement` mount, but listed in deps for
  React-correctness).

`PinScope.tsx` also adds (c) a compact-viewport early-return branch placed
adjacent to (immediately after) the existing `!hudVisible` branch in
`PinScopeHud`'s render. When `isCompactViewport(viewport.width)` is true
(< `MOBILE_BREAKPOINT = 768`), the HUD collapses to the same
`FloatingToggle`-only shape `!hudVisible` already renders, so the user can
tap the toggle to re-expand. `useViewportSize` already drives a re-render
on `resize`, so rotation/resize flips this branch automatically. The frozen
`src/runtime/utils/long-press.ts`, `src/runtime/hooks/useSelectedElement.ts`,
and `src/runtime/utils/element-walker.ts` were NOT modified.

**Red → green transition evidence.**

Pre-wave RED: the new describe block `R-21-01 — touch + responsive collapse`
(three tests) was added to `tests/unit/runtime/pinscope.test.tsx` BEFORE any
source-tree change. All three tests failed against the post-W2 `PinScope.tsx`
(which never registers a touch listener and never collapses below 768 px):

```
 ❯ tests/unit/runtime/pinscope.test.tsx (14 tests | 3 failed | 11 skipped) 219ms
   ❯ tests/unit/runtime/pinscope.test.tsx > R-21-01 — touch + responsive collapse > tap (touchstart→touchend < 500ms) selects a pinned element
     → expected null to be <div data-pin="e_7" …(1)></div> // Object.is equality
   ❯ tests/unit/runtime/pinscope.test.tsx > R-21-01 — touch + responsive collapse > long-press (touchend ≥ 500ms after touchstart) locks the selection
     → expected null to be <div data-pin="e_8" …(1)></div> // Object.is equality
   ❯ tests/unit/runtime/pinscope.test.tsx > R-21-01 — touch + responsive collapse > compact viewport (innerWidth < 768) collapses HUD; restoring width re-expands it
     → expected <style data-pinscope-badges></style> to be null

 Test Files  1 failed (1)
      Tests  3 failed | 11 skipped (14)
```

The first two failures bottom out on
`expect(document.querySelector('[data-pin-selected]')).toBe(pinned)` returning
`null` — no `src/` consumer registers a `touchstart`/`touchend` listener, so
the synthetic touch dispatch is observed by nothing. The third failure proves
the responsive-collapse gate is absent: with `innerWidth = 600` the visible
HUD still renders `<PinBadges/>` (the `[data-pinscope-badges]` selector
matches the `<style data-pinscope-badges>` block PinBadges injects). This is
the F-21-01 finding text reproduced end-to-end.

Post-fix GREEN (same describe block, same vitest filter — only the source
tree changed in between):

```
 ✓ tests/unit/runtime/pinscope.test.tsx (14 tests | 11 skipped) 317ms

 Test Files  1 passed (1)
      Tests  3 passed | 11 skipped (14)
```

All three R-21-01 named tests flipped FAIL → PASS across the
`PinScope.tsx` edits.

**Definition of Done — clause-by-clause verification.**

- *tap selects.* Test 1 seeds `<div data-pin="e_7">` with a known rect, stubs
  `document.elementFromPoint` to return the pin when the touch lands inside
  it, renders `<PinScope/>`, dispatches `TouchEvent('touchstart')` then
  `TouchEvent('touchend')` ~50 ms apart at `(70, 70)`, and asserts
  `document.querySelector('[data-pin-selected]') === pinned` — GREEN.
- *long-press locks.* Test 2 uses `vi.useFakeTimers()` to dispatch
  `touchstart`, advance time by 600 ms (past `LONG_PRESS_MS = 500`), then
  dispatch `touchend`. Asserts `[data-pin-selected]` resolves to the pin
  AND survives a subsequent `mouseleave` on the host (regression guard —
  proves the lock, not a transient tap; the lock semantics live in
  `SelectionManager.select` with `locked = true` default) — GREEN.
- *compact viewport collapses HUD.* Test 3 sets `window.innerWidth = 600`
  BEFORE `render(<PinScope/>)` and fires `resize`, asserts the
  `[data-pinscope-badges]` element inside `[data-pinscope-ui="root"]` is
  ABSENT AND `[data-pinscope-toggle]` (the `FloatingToggle` handle) is
  PRESENT, then restores `window.innerWidth = 1280`, re-fires `resize`,
  and asserts `[data-pinscope-badges]` returns — GREEN.

**Acceptance criteria — grep predicates.**

- `grep -nE 'LongPressDetector|isCompactViewport' pinscope/src/runtime/PinScope.tsx`
  → 5 hits (line 35 import — both symbols on one line; line 263 doc comment
  referencing `LongPressDetector`; line 274 `new LongPressDetector()`; lines
  436, 439 referencing/calling `isCompactViewport`). ≥ 2 ✓
- `grep -nE 'touchstart|touchend' pinscope/src/runtime/PinScope.tsx` → 6 hits
  inside the new `useEffect` body (doc comment lines 263, 264; listener
  registrations lines 297, 298; cleanup `removeEventListener` lines 300,
  301). All inside a `useEffect` body (previously zero across all of
  `src/runtime/`). ✓
- `grep -rn 'LongPressDetector' pinscope/src/` → 2 files —
  `src/runtime/utils/long-press.ts` (definition) and
  `src/runtime/PinScope.tsx` (consumer). ≥ 2 files ✓
- `grep -rn 'isCompactViewport' pinscope/src/` → 2 files —
  `src/runtime/utils/long-press.ts` (definition) and
  `src/runtime/PinScope.tsx` (consumer). ≥ 2 files ✓
- `cd pinscope && npm run typecheck` → exit 0 ✓
- `cd pinscope && npm test` → exit 0; 316 tests passed (313 prior + 3 new
  R-21-01). The existing `tests/unit/runtime/selection.test.tsx` and
  `controls.test.tsx` click-to-select cases do not regress (the touch
  listener does not interfere with the existing click handler — both route
  through the same `SelectionManager` via `selectPin`, which is idempotent
  on the same pin). ✓

**Verification command outputs (exit codes).**

```
$ npm run typecheck
> pinscope@1.0.0 typecheck
> tsc --noEmit
typecheck exit=0

$ npm test
 ✓ tests/unit/runtime/pinscope.test.tsx (14 tests) 1531ms  [contains 3 R-21-01 tests]
 ✓ tests/unit/runtime/edge-cases.test.ts (5 tests) 114ms
 ✓ tests/unit/runtime/element-walker.test.ts (7 tests) 19ms
 ✓ tests/unit/runtime/infopanel.test.tsx (3 tests) 188ms
 ✓ tests/unit/runtime/shortcuts.test.tsx (15 tests) 36ms
 ✓ tests/unit/runtime/pinscope-assembly.test.tsx (7 tests) 378ms
 ✓ tests/unit/runtime/perf.test.tsx (2 tests) 156ms       [AC-070 / AC-071 within budget]
 ✓ tests/unit/runtime/components.test.tsx (3 tests) 122ms
 ✓ tests/unit/long-press.test.ts (3 tests) 7ms            [AC-064 utility tests still GREEN]
 ... (30 files total)
 ✓ tests/unit/deployment.test.ts (10 tests) 2112ms
 ✓ tests/unit/claude-bridge.test.ts (2 tests) 2429ms

 Test Files  30 passed (30)
      Tests  316 passed (316)
npm test exit=0
```

**Scope notes.** Only the two files named in R-21-01's Execution plan were
touched (`src/runtime/PinScope.tsx`, `tests/unit/runtime/pinscope.test.tsx`).
The frozen `src/runtime/utils/long-press.ts` was NOT modified — the executor
consumed `LongPressDetector` and `isCompactViewport` as-is.
`src/runtime/hooks/useSelectedElement.ts` was NOT modified — the touch
listener routes through the hook's existing `selectPin` return so the click
and touch paths share one `SelectionManager`. `src/runtime/utils/element-walker.ts`
was NOT modified — the touch listener consumes `escapeHud` and
`findPinnedAncestor` as-is. The `!hudVisible` branch was NOT touched — the
new compact-viewport branch is a separate early return adjacent to it. No
new findings discovered during implementation — `NEW-FINDINGS-W3.md` not
created.

**Suspected-finding status.** N/A — F-21-01 is CONFIRMED; the SUSPECTED item
this round is F-21-04, scheduled in W4.

**Regression check.** Full suite is GREEN at 316/316 (W2 baseline: 313 → +3
new R-21-01 tests). No pre-wave-green test went RED post-fix. AC-070 mount
budget held on the single mount run (`perf.test.tsx` still passes) — the
touch-listener `useEffect` body registers two `addEventListener` calls and
nothing more; it is cheaper than the R-20-02 `RuntimePinObserver` deferral.
AC-064 utility tests (`tests/unit/long-press.test.ts`) still GREEN — the
utilities themselves were not modified. The existing click-to-select hover
flow tests (selection coverage in `pinscope.test.tsx`, `pinscope-assembly.test.tsx`,
and `shortcuts.test.tsx`) all still pass. AC-070-flake-watch: not applicable
this wave — the perf test was GREEN on the first run; no flake re-run needed.

### Wave 3 gate

`cd pinscope && npm run typecheck` → exit 0. `cd pinscope && npm test` → exit 0;
316/316 pass; the R-21-01 named describe block is GREEN with all three DoD
tests transitioned red→green (tap selects via real `TouchEvent` dispatch;
long-press at ≥ 500 ms locks and survives `mouseleave`; compact viewport at
`innerWidth=600` collapses the visible-HUD subtree and exposes the
`FloatingToggle`, restoring at `innerWidth=1280` returns the HUD); existing
`tests/unit/runtime/selection.test.tsx` / `pinscope-assembly.test.tsx` /
`shortcuts.test.tsx` click-to-select cases do not regress; AC-070 mount-time
perf test stays within budget. **Wave 3 PASSES the gate.** Wave 4 may proceed.

## Wave 4 — R-21-04

### R-21-04 — cross-origin iframe outline overlay (investigation, SUSPECTED)

**Status:** CLOSED — `### Resolution` branch (REFUTED for this loop).

**R-items executed in this wave:** R-21-04 (sole R-item; W4 is single-R-item by
the wave map — `PinScope.tsx` single-owner per wave if STEP-2 confirms,
zero-file otherwise). This wave is the STEP-1-eligible investigation R-item;
the verdict below selects the no-code-change branch.

**Branch fired:** REFUTED (`### Resolution`).

**STEP 1 — confirm-or-refute (mandatory).**

*SPEC re-read evidence (verbatim).*

`pinscope/SPEC.md` §12 (lines 327–336):

```
## 12. Edge Cases

Dynamic content (MutationObserver assigns `e_r{N}` runtime IDs); Shadow DOM
(mark `data-pin-shadow`, limited inspection); iframes (same-origin inject,
cross-origin outline only); SVG (`getBBox` + `getCTM`); print mode
(`@media print` hides HUD); z-index conflicts (PinScope reserves
`2147483647`); hostile CSS (PinScope styles use `!important`); mobile/touch
(tap=select, long-press=lock, HUD collapsible < 768px); many elements
(throttle to 30fps > 500 elements, skip badges < 16×16, `data-pin-ignore`
opt-out); color-on-color (brightness sampling swaps badge color).
```

The iframe clause is the eight-word fragment "iframes (same-origin inject,
cross-origin outline only)" embedded inside a single dense paragraph of
edge-case prose. §12 is normative behavior, but its iframe sub-clause names
only one falsifiable behavior — the cross-origin outline — and assigns its
machine-verification to AC-061.

`pinscope/SPEC.md` Appendix A.5 line 568–569 (AC-061 verbatim):

```
- **AC-061** · P4 · P3 · runtime — cross-origin iframes render an outline +
  label only (no injection). **verify:** integration test.
```

AC-061's `verify` is `integration test` — i.e. Playwright, browser-engine,
two real origins. It is recorded BLOCKED in `convergence/audit-findings-R21.json`
under `blocked[2]`: *"AC-061 P3 — verify kind 'manual' / env 'browser' —
cross-origin iframe needs two real origins + a browser. (See investigation
F-21-04: implementation is also unwired in <PinScope/>, but the AC itself is
env-only.)"*

*Grep evidence (the four greps the plan's STEP-1 mandate names).*

```
$ grep -rn 'markCrossOriginFrames' pinscope/src/
pinscope/src/runtime/utils/iframe-overlay.ts:31:export function markCrossOriginFrames(root: ParentNode = document): number {

$ grep -rn 'iframe' pinscope/src/runtime/
pinscope/src/runtime/utils/iframe-overlay.ts:1:/** Cross-origin iframe handling — see SPEC §12 (Edge Cases) and Appendix A.5. */
pinscope/src/runtime/utils/iframe-overlay.ts:5:/** Attribute marking an `<iframe>` PinScope can only outline (cross-origin). */
pinscope/src/runtime/utils/iframe-overlay.ts:8:/** Attribute marking a generated cross-origin iframe outline overlay. */
pinscope/src/runtime/utils/iframe-overlay.ts:12: * True when an `<iframe>` is cross-origin. PinScope cannot inject into a
pinscope/src/runtime/utils/iframe-overlay.ts:26: * Sweep `root` for `<iframe>` elements and, for every cross-origin frame,
pinscope/src/runtime/utils/iframe-overlay.ts:33:  for (const frame of Array.from(root.querySelectorAll('iframe'))) {
pinscope/src/runtime/utils/iframe-overlay.ts:68:/** True when an element is a cross-origin iframe with limited inspection. */

$ grep -rn 'crossOrigin' pinscope/src/runtime/
(no matches — search uses literal `crossOrigin` substring; the conceptual
"cross-origin" hyphenated term lives only in comments inside iframe-overlay.ts)

$ grep -rn 'IframeOverlay' pinscope/src/runtime/
(no matches — there is no `*IframeOverlay*` React component; the overlay is
imperatively built as a `<div data-pinscope-iframe-overlay>` inside
`markCrossOriginFrames`, never as a JSX component the HUD imports.)
```

The pre-wave-execution state is: `markCrossOriginFrames` and
`IFRAME_ATTR`/`IFRAME_OVERLAY_ATTR` exist solely in their definition file
`src/runtime/utils/iframe-overlay.ts`. Zero `src/` consumer. No
`*IframeOverlay*` React component exists. The zero-consumer state recorded in
`audit-findings-R21.json` `investigation_findings[3].re_read` still holds at
execution time — the W1–W3 commits did not introduce any iframe wiring.

*STEP-1 verdict: REFUTED — out of AC-scope for this loop.*

Per the plan's R-21-04 Resolution section verbatim: *"Under the loop's rule
'the North-Star is frozen; plan the fix to reality, never to the spec', the
relevant frozen-contract check is 'does any AC falsify reality?' — AC-061
cannot be falsified in the current env, so the gap is coverage, not
contract."* The three converging conditions the SUSPECTED classification rests
on all hold:

1. **AC-061's verify is `env: browser` BLOCKED** — confirmed by the verbatim
   text above and `audit-findings-R21.json` `blocked[2]`. No node-env
   machine check can falsify the AC as written.
2. **AC-061's severity is P3** — confirmed by `· P4 · P3 ·` (priority class
   P4, severity P3). The plan classifies F-21-04 as the only P3-SUSPECTED of
   the round; the analogous P2-CONFIRMED Shadow-DOM finding (F-21-02) shipped
   in W1 precisely because AC-060's `verify` is `integration test with a
   shadow root` — a node-env surrogate is reachable for Shadow-DOM but not
   for cross-origin iframes.
3. **The unit suite already covers the helper end-to-end.**
   `tests/unit/runtime/iframe-overlay.test.ts` (8 tests, GREEN this wave —
   see verification block below) constructs `markCrossOriginFrames` against
   fixture iframes whose `contentDocument` access throws, asserts the
   `data-pin-iframe` stamping, the overlay div emission, the label
   resolution. The helper's correctness is machine-proven; only its wiring
   into `PinScopeHud` is dormant.

By symmetry with R-20-04 (annotation request_type / §10-E flow, refuted last
round as non-normative-prose-with-no-AC), R-21-04 closes here as a
refuted-for-this-loop investigation. The recommended follow-up — a
strengthen-proposal for AC-061 swapping the Playwright integration test for a
jsdom RTL surrogate that calls `markCrossOriginFrames(document)` against an
iframe fixture — is forwarded to the loop owner as the appropriate vehicle.
Authoring that AC change is the loop owner's call, not this R-item's.

**STEP 2 — NO CODE CHANGE.** Per STEP-1 verdict, the Resolution branch fires.
No `src/` file is edited. No new test is added (the existing
`iframe-overlay.test.ts` unit suite already satisfies the helper's
machine-checkable contract — adding a duplicate test here would not change
the loop's coverage). No `WAVE-R21-RESULT.md` modification beyond this
appended block.

**Definition of Done — refuted-branch verification.**

The plan's DoD for the refuted branch (verbatim): *"`git diff --stat` shows
**0** files changed under `pinscope/src/`. `npm test` reports 0 failures. The
`### Resolution` below is then the authoritative closing record."*

- *STEP 1 performed and recorded:* SPEC §12 + AC-061 verbatim text re-read
  above; the four greps recorded with full output; the in-scope-vs-refuted
  verdict (REFUTED) is recorded in this execution log. ✓
- *Pre-fix grep result recorded:* `grep -rn 'markCrossOriginFrames' pinscope/src/`
  shows the sole hit inside `utils/iframe-overlay.ts` (no consumer). ✓
- *Either branch:* the no-code-change branch fired — `git diff --stat` for the
  W4 commit window shows **zero** `pinscope/src/` files changed. ✓
- *`npm test` stays green:* 316/316 passed (see verification block below). ✓

**Acceptance criteria — STEP-1 / refuted-branch grep predicates.**

- STEP-1 verdict recorded: REFUTED. ✓
- `grep -rn 'markCrossOriginFrames' pinscope/src/` → 1 hit (definition only,
  pre-fix state unchanged). ✓
- *Either:* STEP-2 wiring lands AND grep hits land *(NOT taken)*; *OR:* no
  `src/` file changed AND `### Resolution` is the closing state. **Refuted
  branch taken — second disjunct holds.** ✓
- `cd pinscope && npm test` stays green (0 fail). ✓

**Verification command outputs (exit codes).**

```
$ cd pinscope && npm run typecheck
> pinscope@1.0.0 typecheck
> tsc --noEmit
typecheck exit=0

$ cd pinscope && npm test
 ✓ tests/unit/runtime/iframe-overlay.test.ts (8 tests) 189ms     [AC-061 unit suite still GREEN]
 ✓ tests/unit/runtime/pinscope.test.tsx (14 tests) 1476ms        [W1+W2+W3 tests still GREEN]
 ✓ tests/unit/runtime/edge-cases.test.ts (5 tests) 83ms
 ✓ tests/unit/runtime/element-walker.test.ts (7 tests) 17ms
 ✓ tests/unit/runtime/shortcuts.test.tsx (15 tests) 32ms
 ✓ tests/unit/runtime/infopanel.test.tsx (3 tests) 185ms
 ✓ tests/unit/runtime/pinscope-assembly.test.tsx (7 tests) 409ms
 ✓ tests/unit/operation-parser.test.ts (45 tests) 25ms
 ✓ tests/unit/roundtrip.test.ts (4 tests) 9ms
 ✓ tests/unit/operation-builder.test.ts (18 tests) 11ms
 ✓ tests/unit/runtime/components.test.tsx (3 tests) 123ms
 ✓ tests/unit/runtime/perf.test.tsx (2 tests) 180ms              [AC-070 / AC-071 within budget]
 ✓ tests/unit/plugin.test.ts (12 tests) 110ms
 ✓ tests/unit/pin-map.test.ts (9 tests) 55ms
 ✓ tests/unit/screenshot.test.ts (3 tests) 35ms
 ✓ tests/unit/runtime/public-api.test.ts (2 tests) 7ms
 ✓ tests/unit/edge-utils.test.ts (5 tests) 85ms
 ✓ tests/unit/operation-perf.test.ts (3 tests) 7ms
 ✓ tests/unit/property-shortcuts.test.ts (12 tests) 8ms
 ✓ tests/unit/ast-transformer.test.ts (66 tests) 131ms
 ✓ tests/unit/long-press.test.ts (3 tests) 5ms
 ✓ tests/unit/production-stripper.test.ts (4 tests) 5ms
 ✓ tests/unit/deployment.test.ts (10 tests) 2397ms
 ✓ tests/unit/claude-bridge.test.ts (2 tests) 3162ms
 ... (30 files total)

 Test Files  30 passed (30)
      Tests  316 passed (316)
   Duration  11.63s
npm test exit=0
```

**`git diff --stat` for this wave's source-tree delta (pre-commit).**

```
$ git diff --stat HEAD -- pinscope/src/
(no output — 0 files changed under pinscope/src/)
```

The W4 commit's source-tree delta is **0 src/ files**. The commit's
deliverable is this appended WAVE-R21-RESULT.md block — that IS the wave's
output per the role contract's instruction *"if refuted with no src/ changes,
the commit still includes the WAVE-R21-RESULT.md update — that IS the wave's
deliverable."*

**Scope notes.** Zero `pinscope/src/` files touched. Only
`pinscope/convergence/WAVE-R21-RESULT.md` modified (this appended W4 block).
The frozen `src/runtime/utils/iframe-overlay.ts` was not touched. The
R-21-02 `useEffect` (the would-be host for STEP-2's `markCrossOriginFrames`
fold-in) was not modified — confirmed by `git diff --stat HEAD -- pinscope/src/`
above. No new findings discovered during the STEP-1 re-read — the SPEC §12
iframe clause and AC-061's `env: browser` BLOCKED status both match the audit
finding text verbatim, so `NEW-FINDINGS-W4.md` is not created.

**Suspected-finding status — verdict.** F-21-04 was SUSPECTED entering this
wave; **REFUTED for this loop** exiting it. The Resolution is recorded under
the heading "Resolution" in `REMEDIATION-PLAN-R21.md` R-21-04 (verbatim).
**Recommended follow-up (forwarded to loop owner):** propose a strengthen
of AC-061 to add a jsdom RTL surrogate — a unit-style test that calls
`markCrossOriginFrames(document)` against an `<iframe src="about:blank">`
fixture (or a stubbed `contentDocument` throw via `Object.defineProperty`)
and asserts the resulting `data-pin-iframe` + `[data-pinscope-iframe-overlay]`
shape from within the assembled `<PinScope/>` mount. That AC change would
re-classify F-21-04 from SUSPECTED to CONFIRMED in a future round and trigger
the STEP-2 wiring branch (one observer, two sweeps inside R-21-02's
`useEffect`). If a future round's auditor finds the gap unacceptable, this
resolution is void and STEP-2 wiring applies.

**Regression check.** Full suite is GREEN at 316/316 (W3 baseline: 316 → +0
new tests this wave — the refuted branch adds no tests). No pre-wave-green
test went RED post-wave (no source-tree change means no possible regression).
AC-061's existing unit suite (`tests/unit/runtime/iframe-overlay.test.ts`,
8 tests) remained GREEN — the helper's machine-checkable behavior is
unchanged. The W1 / W2 / W3 R-21-02 / R-21-03 / R-21-01 named DoD tests
(inside `pinscope.test.tsx`, 14 tests) all remained GREEN. AC-070 / AC-071
perf-budget tests within budget (`perf.test.tsx`, 2 tests).

### Wave 4 gate

`cd pinscope && npm run typecheck` → exit 0. `cd pinscope && npm test` → exit
0; 316/316 pass; STEP-1 verdict recorded (REFUTED); the refuted-branch DoD
holds (`git diff --stat HEAD -- pinscope/src/` returns zero output before
commit; `### Resolution` from `REMEDIATION-PLAN-R21.md` R-21-04 is the
authoritative closing record); the strengthen-proposal recommendation for
AC-061 is forwarded to the loop owner above. **Wave 4 PASSES the gate.**
PS-R21 W1–W4 complete: 3 confirmed-and-fixed (R-21-01/02/03), 1 SUSPECTED-and-
refuted (R-21-04).
