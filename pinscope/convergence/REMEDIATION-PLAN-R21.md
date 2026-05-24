# Remediation Plan — PS-R21

**Round summary.** The R21 audit recorded **0 AC findings**, **0 narrative
blocking findings**, **0 regressions**, and **0 false-PASSes from the test
audit**; all four items are free-investigation findings from
`audit-findings-R21.json`: **3 CONFIRMED** (F-21-01 P2, F-21-02 P2, F-21-03 P3)
and **1 SUSPECTED** (F-21-04 P3). Each maps to exactly one R-item — R-21-01 ↔
F-21-01, R-21-02 ↔ F-21-02, R-21-03 ↔ F-21-03, R-21-04 ↔ F-21-04. Nothing
dropped.

**Shared-root-cause group (1) — "PinScopeHud never wires imperative HUD
mechanisms".** F-21-01, F-21-02, F-21-03 (and provisionally F-21-04) share the
exact same root cause that R-20-01/02/03 began closing last round: every
imperative `src/runtime/utils/*.ts` module that the HUD needs to *invoke* (not
just *render*) — `long-press.ts`, `shadow-dom.ts`, `throttle.ts`,
`iframe-overlay.ts` — exists, is correct, is unit-tested in isolation, and has
a PASSING AC, but `PinScopeHud` in `src/runtime/PinScope.tsx` never imports it,
never builds a `useEffect` that calls it, and never threads its outputs into
the components that need to read them. R-20-02 installed the **first**
`useEffect` in `PinScopeHud` (the `RuntimePinObserver` lifecycle); R-21 closes
the rest of the same false-PASS class. The four R-items below are planned
independently (each has its own DoD that is mechanically checkable in
isolation) but their executions all converge on the same `PinScopeHud` body —
the executor should serialize them within one wave on the shared file (same
contract R20 used for R-20-01/02/03).

This plan is READ-ONLY analysis; it edits no code. The North-Star
`pinscope/SPEC.md` is frozen — every fix below targets reality.

---

## Remediation R-21-01

**Linked finding:** F-21-01
**Severity:** P2
**Spec anchor:** "mobile/touch (tap=select, long-press=lock, HUD collapsible
< 768px)" (§12); AC-064 "touch: tap selects, long-press (500ms) locks; HUD
collapses below 768px"
**Root cause:** `PinScopeHud`'s `createPortal` tree wires only mouse + keyboard
input — there is no `touchstart`/`touchend` listener anywhere in
`src/runtime/`, no consumer ever constructs a `LongPressDetector`, and the
`useViewportSize` hook is read but no branch ever calls `isCompactViewport`
to suppress/collapse the HUD subtree below the 768px breakpoint. The
`long-press.ts` utility (`LongPressDetector`, `LONG_PRESS_MS=500`,
`isCompactViewport`, `MOBILE_BREAKPOINT=768`) is correct and unit-tested but
has zero importer in `src/runtime/`. This is the same dormant-mechanism shape
the R20 plan called the "shared root cause" — `PinScopeHud` never grew the
imperative side of its input layer past mouse/keyboard.

### Ecosystem analysis
1. What handles a touch tap in the shipped HUD today? Nothing — `grep` for
   `touchstart|touchend|onTouch` across `src/runtime/` returns zero hits.
2. What detects a long-press? Nothing in the runtime tree — only the
   isolated unit test in `tests/unit/long-press.test.ts` constructs
   `LongPressDetector` directly.
3. Where does §10-B "select" already live? In `useSelectedElement` — its
   `onClick` listener runs `SelectionManager.select(pinId)` on a click on a
   pinned ancestor. A tap should reach that same path; a long-press should
   additionally lock the selection (the existing manager state).
4. Where does the responsive-collapse branch belong? Inside `PinScopeHud`
   visible-HUD branch, gated on `isCompactViewport(viewport.width)` — the
   collapsed shape should render only the `FloatingToggle` (mirroring the
   existing `!hudVisible` branch the SPEC already authorizes), so the user
   can re-expand on rotation. `viewport` is already produced by
   `useViewportSize()` and is in scope.
5. Does this need a new state cell? No — `isCompactViewport` is a pure
   function of `viewport.width`; the branch is `viewport.width <
   MOBILE_BREAKPOINT` and renders the same `FloatingToggle` portal as the
   `!hudVisible` branch.
6. Does the touch path conflict with the existing `useSelectedElement`
   click handler? No — a synthetic `click` is dispatched by the browser
   after a `touchend` short tap by default, but to be deterministic in
   tests the touch handler should call `selectPin(pinId)` directly (via a
   `selectPin` value lifted into the touch listener's closure). The
   `useSelectedElement` hook already exposes `select` (line: `const
   { selected, select: selectPin } = useSelectedElement(measuring);`); the
   touch listener routes through the same `select` method.
7. Where does the long-press "lock" live? `SelectionManager` already
   exposes a lock — the lock semantics of the existing `select(pinId)`
   call match a long-press lock (it sets `data-pin-selected` and survives
   mouse-out). A long-press calls `select(pinId)`; a tap also calls
   `select(pinId)`. To distinguish, the long-press additionally invokes
   `manager.lock` if the manager exposes one — otherwise the tap-vs-long-
   press distinction is observable only via the `Gesture` value the
   detector returns (the DoD asserts on the Gesture-derived branch, not on
   manager internals).
8. Sync-strategy / hook-trigger? N/A — pinscope is not part of the
   `framework/` → `~/.claude/` build; no `framework/settings.json` or
   `HOOK-CLASSIFICATION.md` involvement.
9. Does mounting this affect AC-070 (<50 ms mount)? The touch listener
   registration runs once on mount in a `useEffect`; the responsive-
   collapse branch is a synchronous JSX gate on already-computed
   `viewport.width`. Both are cheap. R-20-02's queueMicrotask deferral
   model is the precedent — if AC-070 regresses, defer the
   `LongPressDetector` construction inside the listener body (lazy) rather
   than at mount.
10. Does this re-open AC-064 verify? AC-064 is env=browser BLOCKED
    (Playwright touch emulation); after the wiring lands, AC-064 remains
    env-blocked but the new DoD test (RTL `touchstart`/`touchend`
    dispatch) gives the loop a node-env mutation-killing assertion. No AC
    file edit required.

### Execution plan
**Files to modify:** `src/runtime/PinScope.tsx` — (a) add imports
`LongPressDetector`, `isCompactViewport` from `./utils/long-press.js`; (b)
inside `PinScopeHud`, add a new `useEffect` (empty deps) that registers
`touchstart`/`touchend` listeners on `document` (passive), uses
`LongPressDetector.start()` on `touchstart`, on `touchend` walks
`document.elementFromPoint(touch.clientX, touch.clientY)` → `escapeHud` →
`findPinnedAncestor` → `getAttribute(PIN_ATTR)` → call `selectPin(pinId)`
when present; the long-press branch additionally calls a manager-lock path
(the existing `selectPin` already locks via `SelectionManager.select`).
Cleanup removes the listeners; (c) in the visible-HUD `createPortal` block
(the `<div data-pinscope-ui="root">` that contains `<PinBadges/>`,
`<Rulers/>`, …, `<CommandBar/>`), add an early return — *before* returning
the full HUD JSX — that renders only the `FloatingToggle` portal when
`isCompactViewport(viewport.width)` is true, mirroring the existing
`!hudVisible` branch (so the host can re-expand by tapping it).
**Files to create:** none.
**Files that MUST remain untouched:** `src/runtime/utils/long-press.ts` —
the detector, threshold, and breakpoint constants are correct as-is.
`src/runtime/hooks/useSelectedElement.ts` — the click → `SelectionManager`
path must keep its existing semantics; the touch listener calls into
`selectPin` (the hook's existing return), it does not duplicate the
manager. The HUD-hidden branch (`if (!hudVisible)`) must keep rendering
only `<FloatingToggle/>`; the new compact-viewport branch sits adjacent to
it, not inside it.
**Order of operations:** 1. add imports. 2. add the `useEffect` registering
touch listeners (tap → `selectPin`; long-press → same `selectPin` since
`SelectionManager.select` already locks). 3. add the compact-viewport early
return adjacent to the HUD-hidden branch. (Serialize within the shared-root
wave with R-21-02/03 on the `PinScopeHud` body.)
**Rollback trigger:** `npm run typecheck` red, `npm test` red, the existing
`tests/unit/runtime/selection.test.tsx` / `controls.test.tsx` click-to-
select cases regress, or AC-070 mount-time perf test exceeds budget.

### Acceptance criteria
- [ ] `grep -nE 'LongPressDetector|isCompactViewport' pinscope/src/runtime/PinScope.tsx`
      returns at least two hits (import + use).
- [ ] `grep -nE 'touchstart|touchend' pinscope/src/runtime/PinScope.tsx`
      returns hits inside a `useEffect` body (today both return zero
      across all of `src/runtime/`).
- [ ] `grep -rn 'LongPressDetector' pinscope/src/` shows at least two
      files — `long-press.ts` (definition) and `PinScope.tsx` (consumer).
- [ ] `grep -rn 'isCompactViewport' pinscope/src/` shows at least two
      files — `long-press.ts` (definition) and `PinScope.tsx` (consumer).
- [ ] `cd pinscope && npm run typecheck` exits 0.
- [ ] `cd pinscope && npm test` stays green (309+ tests pass, 0 fail).

### Definition of Done
A new RTL describe block in `tests/unit/runtime/pinscope.test.tsx` named
`R-21-01 — touch + responsive collapse` carries three named tests that
must all transition **red → green** across the fix:
1. *tap selects.* Seeds a pinned host element (`<div data-pin="e_7">`),
   renders `<PinScope/>`, dispatches a real `TouchEvent('touchstart')`
   then `TouchEvent('touchend')` < 500 ms apart whose `clientX`/`clientY`
   land inside the host's rect (use a stubbed `document.elementFromPoint`
   if jsdom returns null), asserts `document.querySelector('[data-pin-
   selected]')` resolves to that element.
2. *long-press locks.* Same fixture, but `touchend` fires ≥ 500 ms after
   `touchstart` (use `vi.useFakeTimers()` + `vi.advanceTimersByTime(600)`);
   asserts the element is locked (`[data-pin-selected]` present) AND the
   selection survives a subsequent `mouseleave` on the host (regression
   guard — proves the lock, not just a tap).
3. *compact viewport collapses HUD.* Sets `window.innerWidth = 600`,
   dispatches `window.dispatchEvent(new Event('resize'))` after rendering
   `<PinScope/>`, asserts the visible-HUD subtree
   (`document.querySelector('[data-pinscope-ui="root"] [data-pinscope-
   badges]')`) is **absent** AND a `FloatingToggle` handle is present
   (e.g. `document.querySelector('[data-pinscope-floating-toggle]')` or
   the toggle's existing test handle); then restores
   `window.innerWidth = 1280`, re-fires resize, asserts the visible HUD
   subtree returns.

R-21-01 is closed when those three named tests are green, `npm test`
reports 0 failures, the four greps above all match, and `cd pinscope &&
npm run typecheck` exits 0.

### Dependencies
Shares `src/runtime/PinScope.tsx` with R-21-02 and R-21-03 (shared-root-cause
group) — same wave, serialize edits on the `PinScopeHud` body. No dependency
on R-21-04 (SUSPECTED — `Resolution`-eligible).

### Risk assessment
**Medium.** Touches the same `PinScopeHud` body as R-21-02/03 and adds the
second post-R-20-02 `useEffect`. Risks: (a) the touch listener could
double-fire selection alongside the browser-synthetic `click` after a tap;
mitigated by passing `passive: true` and letting `useSelectedElement`'s
existing click handler be idempotent (`SelectionManager.select(samePin)`
is a no-op). (b) the compact-viewport branch could collapse the HUD on
devtools-narrow desktop and frustrate developers; mitigated by mirroring
the existing `!hudVisible` branch shape (the user can re-expand by tapping
the `FloatingToggle`). (c) AC-070 mount-time regression; mitigated by
keeping the `useEffect` body cheap (listener registration only — no DOM
sweep). No schema, build, or production-output surface touched.

---

## Remediation R-21-02

**Linked finding:** F-21-02
**Severity:** P2
**Spec anchor:** "Shadow DOM (mark `data-pin-shadow`, limited inspection)"
(§12); AC-060 "Shadow DOM hosts are marked `data-pin-shadow` and InfoPanel
reports limited inspection"
**Root cause:** Same shared root cause as R-21-01 — `PinScopeHud` never
invokes the imperative `markShadowHosts` sweep on mount and never re-sweeps
on dynamic content. `shadow-dom.ts` exports `markShadowHosts(root)` and
`isShadowLimited(el)` (both correct, both unit-tested) but no `src/`
consumer ever imports them. `InfoPanel.tsx` also does not read the
`data-pin-shadow` attribute — so even after the sweep stamps a host, the
inspector cannot report "limited inspection" until the panel is given the
read path. The full AC-060 contract has two halves: marking (a
`PinScopeHud` `useEffect`) AND reporting (an `InfoPanel` read of
`isShadowLimited` against the currently-shown host).

### Ecosystem analysis
1. What marks Shadow-DOM hosts in the shipped HUD today? Nothing — `grep`
   for `markShadowHosts|SHADOW_ATTR|shadow-dom` across `src/runtime/`
   returns only the definition in `utils/shadow-dom.ts`.
2. Does the marker utility exist? Yes — `markShadowHosts(root)` sweeps
   `root.querySelectorAll('*')`, sets `data-pin-shadow` on every
   `HTMLElement` whose `shadowRoot` is non-null, returns the count.
3. Where should the sweep run? Inside `PinScopeHud`, in a new `useEffect`
   (empty deps): one synchronous sweep on mount, then a `MutationObserver`
   on `document.body` (subtree: true) that re-runs the sweep when new
   nodes are added (mirroring the lifecycle pattern R-20-02 installed for
   `RuntimePinObserver`). Both observers may share one `useEffect` block
   for R-21-04 — see "Combined-effect note" below.
4. Where does "limited inspection" report? `InfoPanel.tsx` — the
   component already reads `hovered.element` to render details; it must
   additionally test `isShadowLimited(hovered.element)` and, when true,
   render a visible marker the test can assert on (a dedicated
   `<div data-pinscope-shadow-limited>limited inspection</div>` row at the
   top of the panel body is the minimal shape).
5. Does this conflict with AC-033 (`—` empty rendering) or AC-032
   (collapsible sections)? No — the new row is additive, sits outside any
   `CollapsibleSection`, and does not change the empty-value branch.
6. SSR safety? `PinScopeHud` already early-returns when `typeof document
   === 'undefined'`; the `useEffect` body is client-only; the
   `MutationObserver` guard mirrors R-20-02.
7. AC-070 budget? `markShadowHosts` runs `querySelectorAll('*')` once on
   mount — on a typical page that is sub-millisecond. If a future page
   has > 5000 elements, defer via `queueMicrotask` the way R-20-02 does;
   the executor decides based on AC-070 telemetry.
8. Combined-effect note: R-21-02 and R-21-04 both want a
   `MutationObserver` on `document.body`. The execution should land them
   in **one** `useEffect` that:
   - runs an initial sweep (`markShadowHosts(document); markCrossOriginFrames(document);`)
   - installs a single `MutationObserver` whose callback re-runs both
     sweeps;
   - returns a cleanup that disconnects.
   The two R-items remain independently DoD-checkable (their tests assert
   different attributes and different observable DOM outputs), but the
   wave-executor should land them as a single edit to avoid two
   redundant observers on the same root. R-21-04's `Resolution` branch
   (see below) does not change this — if R-21-04 chooses the `Resolution`
   path, R-21-02 still lands its sweep alone, just without the
   `markCrossOriginFrames` call inside the same effect.
9. Sync-strategy / hook-trigger? N/A — no `framework/` file.

### Execution plan
**Files to modify:**
- `src/runtime/PinScope.tsx` — (a) add an import `markShadowHosts` from
  `./utils/shadow-dom.js`; (b) inside `PinScopeHud`, add a new `useEffect`
  (empty deps) that on mount calls `markShadowHosts(document)`, then
  installs a `MutationObserver` on `document.body` with `{ subtree: true,
  childList: true }` whose callback re-runs `markShadowHosts(document)`;
  the cleanup disconnects the observer. (Same effect should host the
  R-21-04 `markCrossOriginFrames` call when R-21-04's STEP 2 lands.)
- `src/runtime/components/InfoPanel.tsx` — (a) add an import
  `isShadowLimited` from `../utils/shadow-dom.js`; (b) when
  `hovered?.element` is non-null and `isShadowLimited(hovered.element)`
  returns true, render an additional row inside the panel body keyed
  `<div data-pinscope-shadow-limited>limited inspection</div>` (or
  equivalent observable handle).
**Files to create:** none.
**Files that MUST remain untouched:** `src/runtime/utils/shadow-dom.ts` —
the `markShadowHosts` sweep, the `SHADOW_ATTR` constant, and
`isShadowLimited` are correct as-is. `InfoPanel.tsx`'s
`CollapsibleSection` / `StyleRow` blocks (the AC-032 / AC-033 paths) must
keep their current behavior; the new "limited inspection" row is
additive, not a replacement for any existing block.
**Order of operations:** 1. add the imports (PinScope.tsx + InfoPanel.tsx).
2. add the `useEffect` in `PinScopeHud` performing the initial sweep +
installing the observer + cleanup. 3. add the `InfoPanel` row gated on
`isShadowLimited(hovered.element)`. (Serialize within the shared-root
wave with R-21-01/R-21-03/R-21-04.)
**Rollback trigger:** `npm run typecheck` red; `npm test` red; existing
AC-060 unit test (`tests/unit/runtime/edge-cases.test.ts`) regresses; or
the new observer leaks (visible in a React unmount warning during the test
run).

### Acceptance criteria
- [ ] `grep -nE 'markShadowHosts' pinscope/src/runtime/PinScope.tsx`
      returns at least one hit (import + call inside a `useEffect`).
- [ ] `grep -nE 'isShadowLimited' pinscope/src/runtime/components/InfoPanel.tsx`
      returns at least one hit (import + use).
- [ ] `grep -rn 'markShadowHosts' pinscope/src/` shows at least two
      files — `shadow-dom.ts` (definition) and `PinScope.tsx` (consumer).
- [ ] `grep -rn 'isShadowLimited' pinscope/src/` shows at least two
      files — `shadow-dom.ts` (definition) and `InfoPanel.tsx` (consumer).
- [ ] The PinScope.tsx `useEffect` body that calls `markShadowHosts`
      returns a cleanup that calls `.disconnect()` on the
      `MutationObserver` (grep the effect body for `disconnect(`).
- [ ] `cd pinscope && npm run typecheck` exits 0; `cd pinscope && npm test`
      stays green (309+ tests).

### Definition of Done
A new RTL describe block in `tests/unit/runtime/pinscope.test.tsx` named
`R-21-02 — Shadow-DOM marking + InfoPanel limited-inspection report`
carries two named tests that must both transition **red → green** across
the fix:
1. *PinScopeHud marks Shadow-DOM hosts on mount.* Before render, attaches
   a Shadow root to a host element appended to `document.body`
   (`const host = document.createElement('div'); host.attachShadow({mode:
   'open'}); document.body.appendChild(host);`). Renders `<PinScope/>`.
   Asserts `host.getAttribute('data-pin-shadow') === ''` after the
   initial microtask flush. Then appends a **second** shadow-host
   element after mount, flushes microtasks (the MutationObserver re-
   sweep), and asserts the second host is also marked. Finally
   `unmount()`s, appends a third shadow host, flushes, and asserts it is
   **not** marked (observer disconnected).
2. *InfoPanel reports limited inspection over a marked host.* Seeds a
   shadow host pre-mount (so it is marked by the initial sweep), renders
   `<PinScope/>`, fires `mousemove` over the host, asserts a node matching
   `document.querySelector('[data-pinscope-shadow-limited]')` is present
   inside the `[data-pinscope-ui="root"]` portal. Then fires `mousemove`
   over a non-shadow pinned element and asserts the
   `[data-pinscope-shadow-limited]` row is **absent**.

R-21-02 is closed when those two named tests are green, `npm test`
reports 0 failures, every grep predicate above matches, and `cd pinscope
&& npm run typecheck` exits 0.

### Dependencies
Shares `src/runtime/PinScope.tsx` with R-21-01, R-21-03, R-21-04 (shared-
root group) — same wave, serialize edits. May share its `useEffect` body
with R-21-04 (combined sweep + observer) — the executor coalesces them
into one effect; R-21-02's DoD passes regardless of whether R-21-04
co-mounts inside the same `useEffect` or in its own.

### Risk assessment
**Low-medium.** Adds the second `MutationObserver` to `PinScopeHud` (after
R-20-02's `RuntimePinObserver`); two observers on `document.body` is fine
but warrants the combined-effect note above so they share one observer
when R-21-04 lands. Risks: (a) observer leak across test renders —
mitigated by the mandatory `.disconnect()` cleanup, asserted by the DoD's
unmount check. (b) `InfoPanel` integration could shift the `CollapsibleSection`
layout — mitigated by placing the new row *outside* any collapsible
section. (c) AC-070 regression on extreme pages — defer-via-microtask is
the R-20-02 mitigation pattern available if needed. No schema, build, or
production-output surface touched.

---

## Remediation R-21-03

**Linked finding:** F-21-03
**Severity:** P3
**Spec anchor:** "many elements (throttle to 30fps > 500 elements, skip
badges < 16×16, `data-pin-ignore` opt-out)" (§12); AC-065 "with > 500
pinned elements, `mousemove` handling throttles to 30fps and badges
< 16×16px are skipped"
**Root cause:** Same shared root cause — the imperative degrade utilities
(`isHeavyPage`, `shouldSkipBadge`, `throttle`, `HEAVY_PAGE_INTERVAL_MS=33`)
exist and are unit-tested but `src/runtime/hooks/useHoveredElement.ts`
hard-codes `requestAnimationFrame` (~60fps) with no `isHeavyPage` gate,
and `PinBadges.tsx` is a pure CSS-`::before` `<style>` block that has no
per-element size check. The hot path was never asked to call into the
degrade helpers. P3 (not P2) because AC-065 is itself P2, the real-world
impact is graceful-degradation rather than a broken capability, and
`data-pin-ignore` IS honored by the AST transform — only the *frame-rate*
and *small-badge* legs of AC-065 are dormant.

### Ecosystem analysis
1. What throttles hover today? `useHoveredElement` uses
   `requestAnimationFrame` only — `if (rafRef.current !== null) return;`
   coalesces to one resolve per frame (~60 Hz), with no heavy-page
   branch.
2. What constitutes a "heavy page" per the spec? > 500 pinned elements;
   the existing helper is `isHeavyPage(documentPinCount)` where
   `documentPinCount = document.querySelectorAll('[data-pin]').length`.
3. Where does the 30 Hz path live? `HEAVY_PAGE_INTERVAL_MS = 33` ms with
   the existing `throttle(fn, ms)` leading + trailing wrapper. When
   `isHeavyPage(count)` is true, the `mousemove` listener body should be
   wrapped by `throttle(handle, 33)` instead of (or in addition to) the
   rAF coalesce.
4. How should the gate be polled? Counting `[data-pin]` once at mount is
   wrong (the count grows post-mount as `RuntimePinObserver` assigns
   `e_r{N}` ids). Recompute the gate periodically — either on every
   mousemove (cheap: a single `querySelectorAll` call gated behind the
   already-throttled handler) or on each MutationObserver tick. The
   minimal correct shape: read `document.querySelectorAll('[data-pin]').length`
   inside the listener body and branch on `isHeavyPage(count)` to pick
   the 30fps path (a `setTimeout`-based debounce) vs the rAF path.
5. Where does the skip-small-badge belong? `PinBadges.tsx` is CSS-only —
   it cannot per-element size-check. The skip-small-badge gate has two
   viable shapes: (a) extend `PinBadges` to render a per-pin CSS rule
   only for pins whose `getBoundingClientRect()` meets `shouldSkipBadge`
   (transitions PinBadges from a static `<style>` block to a hook-driven
   list — bigger surface); (b) inject a complementary `<style>` block
   that adds a `[data-pin-skipbadge]` attribute selector hiding badges,
   and have a small `useEffect` (lifecycle-bound) sweep the document on
   the heavy-page branch only and stamp the attribute on pins whose rect
   `shouldSkipBadge`. Shape (b) is additive and contained; the executor
   picks the shape — the DoD checks observable outcome (small badges
   not painted on a heavy page), not the mechanism.
6. Performance budget? The 30fps switch should *improve* hover budget on
   heavy pages (AC-071 < 8 ms/frame); the skip-small-badge sweep should
   itself run via the `throttle(33)` budget on the heavy branch only —
   on the < 500-pin path nothing changes (no new work, AC-070/AC-071
   unaffected).
7. Does this touch `PinScope.tsx`? Yes — the heavy-page sweep needs a
   `useEffect` lifecycle in `PinScopeHud` (mount/unmount of the
   sweep). The `useHoveredElement` change is internal to the hook.
8. Risk to AC-027 (HUD-skip) / AC-026 (nearest-ancestor)? No — the
   30fps branch wraps the same `handleMove` body; `escapeHud` +
   `findPinnedAncestor` semantics are unchanged.
9. Sync-strategy / hook-trigger? N/A.

### Execution plan
**Files to modify:**
- `src/runtime/hooks/useHoveredElement.ts` — (a) add imports
  `isHeavyPage`, `HEAVY_PAGE_INTERVAL_MS`, `throttle` from
  `../utils/throttle.js`; (b) inside the existing `useEffect`, on each
  `handleMove` invocation compute `const count =
  document.querySelectorAll('[data-pin]').length;`. When
  `isHeavyPage(count)` is true, route the resolution body through a
  `throttle(resolve, HEAVY_PAGE_INTERVAL_MS)`-wrapped callback (one
  throttle instance per hook mount, created lazily on first heavy-branch
  entry and reused for subsequent moves). When `isHeavyPage(count)` is
  false, use the existing rAF coalesce. The cleanup remains the
  `removeEventListener` + `cancelAnimationFrame` already present.
- `src/runtime/PinScope.tsx` — add a `useEffect` (empty deps) that, when
  `isHeavyPage(document.querySelectorAll('[data-pin]').length)` is true,
  sweeps `document.querySelectorAll('[data-pin]')` and for each pin
  whose `getBoundingClientRect()` satisfies `shouldSkipBadge(w, h)`
  stamps a `data-pin-skipbadge` attribute. Inject a complementary
  `<style data-pinscope-skip-badge>` block (rendered once inside the
  visible-HUD `createPortal` tree) whose rule is
  `[data-pin-skipbadge]::before { display: none !important; }`. The
  sweep re-runs on `MutationObserver` ticks; cleanup disconnects the
  observer. (When R-21-02's `useEffect` is the host
  `MutationObserver`, fold this sweep call into the same observer
  callback — the wave-executor coalesces them.)
**Files to create:** none.
**Files that MUST remain untouched:** `src/runtime/utils/throttle.ts` —
the helpers are correct as-is. `src/runtime/components/PinBadges.tsx`'s
CSS-`::before` style block (the static `badgeCss` rule) must keep its
current behavior; the skip-small-badge `<style>` block is **additive**,
injected from `PinScope.tsx` alongside `<PinBadges/>` so it is removed
when the HUD unmounts. The `useHoveredElement.ts` rAF path is preserved
on the non-heavy branch — only the heavy branch routes through `throttle`.
**Order of operations:** 1. update `useHoveredElement.ts` with the
heavy-page gate. 2. add the skip-small-badge `useEffect` +
complementary `<style>` block in `PinScope.tsx`. (Serialize within the
shared-root wave with R-21-01/02/04 on the shared `PinScope.tsx` body;
`useHoveredElement.ts` is a sibling file with no R-21 conflict.)
**Rollback trigger:** `npm run typecheck` red, `npm test` red, AC-070
or AC-071 perf-budget regression, or existing AC-026/027 hover tests
regress.

### Acceptance criteria
- [ ] `grep -nE 'isHeavyPage|HEAVY_PAGE_INTERVAL_MS|throttle' pinscope/src/runtime/hooks/useHoveredElement.ts`
      returns at least two hits (import + use).
- [ ] `grep -nE 'shouldSkipBadge|data-pin-skipbadge' pinscope/src/runtime/PinScope.tsx`
      returns at least one hit each (import + sweep + style anchor).
- [ ] `grep -rn 'isHeavyPage' pinscope/src/` shows at least two files —
      `throttle.ts` (definition) AND a consumer (`useHoveredElement.ts`).
- [ ] `grep -rn 'shouldSkipBadge' pinscope/src/` shows at least two
      files — `throttle.ts` (definition) AND a consumer (`PinScope.tsx`).
- [ ] `cd pinscope && npm run typecheck` exits 0.
- [ ] `cd pinscope && npm test` stays green (309+ tests, AC-026 / AC-027 /
      AC-070 / AC-071 all still pass).

### Definition of Done
A new RTL describe block in `tests/unit/runtime/pinscope.test.tsx` (or
`perf.test.tsx`) named `R-21-03 — heavy-page degrade` carries two named
tests that must both transition **red → green** across the fix:
1. *> 500 pins switches hover to ≥ 30 Hz throttle.* Pre-populates
   `document.body` with 600 `<div data-pin="e_{i}">` elements, renders
   `<PinScope/>` (mounting the hover hook), then dispatches 30
   `mousemove` events at 5 ms intervals via `vi.useFakeTimers()` +
   `vi.advanceTimersByTime`. Spies the resolution side-effect
   (`document.elementFromPoint` calls, or `setHovered` state transitions
   captured via a render counter on `InfoPanel`). Asserts the resolution
   count over 150 ms (5 × 30) is ≤ 6 (≤ 1 per `HEAVY_PAGE_INTERVAL_MS =
   33 ms`), proving the 30fps branch is active. A second assertion with
   only 100 pins pre-populated dispatches the same event stream and
   asserts a higher resolution count (rAF path, > 6) — the test passes
   only when the gate correctly switches.
2. *< 16×16 badges are hidden on a heavy page.* Pre-populates 600
   pins of which a known subset (e.g. 5 named `e_small_{i}`) carries
   inline `style="width:8px;height:8px"`; renders `<PinScope/>`; flushes
   microtasks. Asserts each `e_small_{i}` element has
   `getAttribute('data-pin-skipbadge') === ''`; asserts a normal-sized
   sibling does NOT carry the attribute; asserts the injected style
   block `document.querySelector('style[data-pinscope-skip-badge]')` is
   present.

R-21-03 is closed when those two named tests are green, `npm test`
reports 0 failures, every grep predicate above matches, and AC-070 /
AC-071 perf tests still pass within budget.

### Dependencies
Shares `src/runtime/PinScope.tsx` with R-21-01, R-21-02, R-21-04 (shared-
root wave). `useHoveredElement.ts` is a sibling file with no R-21
conflict — the executor may parallelize that edit with the
`PinScope.tsx` work. May share its `MutationObserver` host with R-21-02's
combined effect.

### Risk assessment
**Medium.** Two concerns: (a) AC-070 mount-time regression if the
heavy-page initial sweep is unconditional — mitigated by gating the
sweep on `isHeavyPage(count)` at mount and only running it when the
threshold is exceeded. (b) AC-071 hover budget regression on the
non-heavy branch — mitigated by ensuring the gate check is a single
`querySelectorAll` per mousemove (or cached + invalidated on
`MutationObserver` ticks); the non-heavy path stays on the existing rAF
coalesce. (c) Test flake on heavy-page synthetic event ordering —
mitigated by `vi.useFakeTimers()` controlling both the throttle window
and the rAF schedule. No schema, build, or production-output surface
touched.

---

## Remediation R-21-04

**Linked finding:** F-21-04 (SUSPECTED — investigation R-item)
**Severity:** P3
**Spec anchor:** "iframes (same-origin inject, cross-origin outline only)"
(§12); AC-061 "cross-origin iframes render an outline + label only (no
injection)"
**Root cause (hypothesised, to be confirmed in STEP 1 below):** Same
shared root cause as R-21-01/02/03 — `markCrossOriginFrames` exists, is
correct, is unit-tested in `tests/unit/runtime/iframe-overlay.test.ts`,
but no `src/` consumer ever imports it. The audit recorded this
**P3/SUSPECTED** because (i) AC-061 is itself env=browser BLOCKED
(cannot be machine-verified without two real origins), (ii) AC-061's own
severity is P3, and (iii) the unit suite's isolated calls satisfy the
node-env evidence the loop currently demands. The open question for
STEP 1 is whether the AC-061 unit-test coverage already satisfies the
frozen contract (Resolution: no-code-change) or whether wiring the sweep
into `PinScopeHud` is owed regardless.

### Ecosystem analysis
1. Is the `markCrossOriginFrames` sweep correct? Per `re_read` and the
   source: yes — sweeps `<iframe>` elements under `root`, tests
   `isCrossOriginFrame`, stamps `IFRAME_ATTR = 'data-pin-iframe'`,
   appends an overlay div with a dashed outline and a label.
2. What invokes it today? Only `tests/unit/runtime/iframe-overlay.test.ts`
   — no `src/` consumer.
3. What does AC-061 require? "cross-origin iframes render an outline +
   label only (no injection)" — verified by manual / browser
   integration. The AC's verify is env-blocked; the unit test asserts
   the helper's behavior in isolation against a fixture.
4. Is the shipped HUD violating the contract? The contract is a
   behavioral one (when the HUD is live on a page with a cross-origin
   iframe, the iframe is outlined + labeled). With no `src/` consumer
   the HUD does **not** outline cross-origin iframes — so reality
   diverges from the spec text, even though the AC's verify is too
   weak to catch it. The R20 plan's pattern (R-20-04 Resolution) was:
   when the gap lives entirely in non-normative prose with no AC
   coverage, accept reality. Here the gap lives in §12 normative prose
   AND has an AC (AC-061), just one the loop cannot execute — closer to
   R-20-01/02/03 than to R-20-04.
5. Decision the planner defers to STEP 1: re-confirm against the
   frozen `pinscope/SPEC.md` §12 and Appendix-A AC-061 verbatim text
   that the wiring gap is in scope; if confirmed, STEP 2 wires the
   sweep alongside R-21-02's `MutationObserver` (combined effect — see
   R-21-02 ecosystem note 8); if refuted (AC-061's env-blocked verify
   is held to suffice), close as `### Resolution` with no code change.
6. Combined-effect note: if STEP 2 lands the wiring, it shares the
   `useEffect` body with R-21-02 — one observer, two sweeps
   (`markShadowHosts` + `markCrossOriginFrames`) on the same callback.
7. Sync-strategy / hook-trigger? N/A.

### Execution plan
**Files to modify:** none under `src/` *until STEP 1 concludes*. This is
an investigation R-item.
**Files to create:** none.
**Files that MUST remain untouched:** `src/runtime/utils/iframe-overlay.ts`
— the sweep, the `IFRAME_ATTR`/`IFRAME_OVERLAY_ATTR` constants, and
`isCrossOriginFrame`/`isIframeLimited` are correct as-is and must not
change.
**Order of operations:**
- **STEP 1 — confirm or refute.** Re-read `pinscope/SPEC.md` §12
  ("iframes (same-origin inject, cross-origin outline only)") and
  Appendix A AC-061 verbatim. Confirm that (a) §12 is normative prose
  (the SPEC §0 reading rules treat §12 as normative behavior, not §10-E-
  class advisory prose), and (b) AC-061 names an end-to-end browser
  observation, not a unit-construction surrogate. Also grep
  `src/runtime/` for `markCrossOriginFrames|IFRAME_ATTR` to verify the
  zero-consumer state still holds at execution time.
- **STEP 2 — branch on the STEP-1 verdict:**
  - *If confirmed in scope* (the expected outcome, by symmetry with
    R-21-02 which has the same env-blocked AC pattern): wire
    `markCrossOriginFrames(document)` into the same `useEffect` block
    R-21-02 installs in `PinScopeHud` — one observer, two sweeps. Add
    the import alongside R-21-02's `markShadowHosts` import. The sweep
    runs once on mount and again on each `MutationObserver` tick. The
    DoD below holds.
  - *If refuted* (STEP 1 concludes the unit-test isolation satisfies
    the frozen contract for this AC): make **no code change**. Record
    `### Resolution` as the closing state; recommend to the loop owner
    that a strengthen-proposal for AC-061 (replacing the env-blocked
    Playwright integration test with a jsdom RTL test that calls
    `markCrossOriginFrames(document)` against an iframe fixture) be
    considered next round — that's the loop owner's call, not this
    R-item's.
**Rollback trigger:** STEP 2 wiring lands and AC-070 mount-time
regresses, OR the new sweep causes the existing
`tests/unit/runtime/iframe-overlay.test.ts` cases to regress. If either
fires, revert the wiring and re-evaluate.

### Acceptance criteria
- [ ] STEP 1 is performed: SPEC §12 + AC-061 verbatim text is re-read
      and the in-scope-vs-refuted verdict is recorded in the execution
      log.
- [ ] `grep -rn 'markCrossOriginFrames' pinscope/src/` is run and the
      pre-fix result (sole hit inside `utils/iframe-overlay.ts`) is
      recorded.
- [ ] Either: STEP 2 wiring lands AND `grep -nE 'markCrossOriginFrames'
      pinscope/src/runtime/PinScope.tsx` returns at least one hit
      (import + call inside the R-21-02 `useEffect`) AND the DoD test
      is green; OR: no `src/` file changed AND the `### Resolution` is
      the closing state.
- [ ] `cd pinscope && npm test` stays green (0 fail) regardless of
      branch.

### Definition of Done
R-21-04 is closed when STEP 1 has been executed and recorded, and **one**
of the following holds, mechanically checkable by someone who never saw
the investigation:
- **(confirmed → wiring lands)** A new RTL test in
  `tests/unit/runtime/pinscope.test.tsx` named `R-21-04 — cross-origin
  iframe outline overlay` pre-mounts a fixture `<iframe>` whose
  `isCrossOriginFrame` returns `true` (e.g. by stubbing
  `iframe.contentDocument` to throw a `SecurityError` via
  `Object.defineProperty`, or by appending a `src="about:blank"` iframe
  and asserting the cross-origin branch via the helper's existing
  fallback). Renders `<PinScope/>`. Asserts the iframe carries
  `data-pin-iframe` after the initial microtask flush AND an overlay
  matching `[data-pinscope-iframe-overlay]` is present in
  `document.body`. The test transitions **red → green** across the
  STEP-2 wiring. `npm test` exits 0; `git diff --stat` shows
  `PinScope.tsx` and `tests/unit/runtime/pinscope.test.tsx` modified;
  no other source-tree file changed.
- **(refuted)** The execution log states "AC-061's env-blocked verify
  satisfies the frozen contract for this AC; no §12 normative behavior
  is left uncovered after `markCrossOriginFrames` is held to be
  reachable via the unit suite", with the grep evidence. `git diff
  --stat` shows **0** files changed under `pinscope/src/`. `npm test`
  reports 0 failures. The `### Resolution` below is then the
  authoritative closing record.

### Resolution (only if STEP 1 refutes)
This R-item closes as a **refuted-for-this-loop** investigation. The
finding is recorded P3/SUSPECTED precisely because AC-061 is env=browser
blocked AND its node-env surrogate (the isolated `markCrossOriginFrames`
unit suite) already proves the helper behaves correctly. Under the
loop's rule "the North-Star is frozen; plan the fix to reality, never
to the spec", the relevant frozen-contract check is "does any AC
falsify reality?" — AC-061 cannot be falsified in the current env, so
the gap is *coverage*, not *contract*. The recommended follow-up is a
strengthen-proposal for AC-061 to add a jsdom RTL surrogate that calls
`markCrossOriginFrames(document)` against an iframe fixture, but
authoring that AC is the loop owner's call, not this R-item's. The
re-read check that proves the resolution: `grep -rn
'markCrossOriginFrames' pinscope/src/` shows only the definition file
(consistent with the pre-fix state), and the SPEC §12 + AC-061 verbatim
quote is recorded in the execution log. If a future round's auditor
finds the gap unacceptable (e.g. R22 escalates this to CONFIRMED),
this resolution is void and STEP 2 wiring applies.

### Dependencies
None for the STEP 1 phase. If STEP 2 lands, R-21-04 shares the
`PinScopeHud` `useEffect` with R-21-02 — same wave, same effect body.
Independent of R-21-01 and R-21-03.

### Risk assessment
**Very low.** If the `Resolution` branch is taken, no code changes — risk
is bounded to STEP 1 misjudgment, mitigated by the verbatim SPEC re-read
contract above. If STEP 2 lands, the risk profile matches R-21-02
(observer leak, AC-070 budget); both are mitigated by the same
`.disconnect()` cleanup and the combined-effect coalescing into one
observer.

---

**R-items: 4 (3 P2 + 1 P3 confirmed + 1 P3 suspected; the P3 count is
'F-21-03 + F-21-04') · shared-root-cause groups: 1 (R-21-01/02/03/04 all
target the `PinScopeHud` imperative-wiring class) · refuted-branch
R-items: 1 (R-21-04 STEP-1-eligible `### Resolution`)**
