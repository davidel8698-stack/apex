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
