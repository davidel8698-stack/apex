# WAVE-R17-RESULT

Per-wave execution results for the PS-R17 self-healing convergence loop.

---

## Wave 1

### R-17-01

**id:** R-17-01
**linked finding:** F-17-01 (CONFIRMED, P2)
**status:** closed

**summary:** Removed the orphan/duplicate `SelectionManager` instance from the
`command` `useMemo` in `PinScope.tsx` and routed the §10-B / §11 `select e_N`
CommandBar command through the one canonical `SelectionManager` owned by the
`useSelectedElement` hook, so the command now locks the InfoPanel (not just the
`data-pin-selected` attribute + URL hash).

#### Red -> Green transition

Named test: **"the `select e_N` command locks the InfoPanel"** in
`tests/unit/runtime/selection.test.tsx`.

**RED** (before the `PinScope.tsx` fix — `onSubmit` still called the orphan
`command.selection.select`):

```
 ❯ tests/unit/runtime/selection.test.tsx  (7 tests | 1 failed) 118ms
   ❯ ... > the `select e_N` command locks the InfoPanel
     → expected null not to be null

 FAIL  tests/unit/runtime/selection.test.tsx > select e_N command — InfoPanel lock (R-17-01, §10-B/§11) > the `select e_N` command locks the InfoPanel
AssertionError: expected null not to be null
 ❯ tests/unit/runtime/selection.test.tsx:127:28
    125|     // even though the mouse never hovered or clicked a `[data-pin]` e…
    126|     const pinIdLabel = hud().querySelector('[data-testid="pin-id"]');
    127|     expect(pinIdLabel).not.toBeNull();
       |                            ^

 Test Files  1 failed (1)
      Tests  1 failed | 6 passed (7)
```

Red for the right reason: the `data-pin-selected` attribute + `#select=e_2` hash
assertions passed (the orphan manager moved those), but the InfoPanel's
`[data-testid="pin-id"]` was never rendered — the React `selected` state never
updated, so the panel never locked. That is exactly the F-17-01 defect.

**GREEN** (after the `PinScope.tsx` fix):

```
 RUN  v1.6.1 /home/user/apex/pinscope

 ✓ tests/unit/runtime/selection.test.tsx  (7 tests) 130ms

 Test Files  1 passed (1)
      Tests  7 passed (7)
```

#### Files modified

- `pinscope/src/runtime/PinScope.tsx`
  - Dropped `selection: new SelectionManager()` from the `command` `useMemo`
    return object (the orphan instance).
  - Updated the `useSelectedElement` call-site destructure to
    `const { selected, select: selectPin } = useSelectedElement(measuring)`.
  - Routed the `onSubmit` `select` branch (`parsed.kind === 'select'`) through
    `selectPin(parsed.pin)` instead of `command.selection.select(parsed.pin)`.
  - Added `selectPin` to the `onSubmit` `useCallback` dependency array.
  - Removed the now-dead `import { SelectionManager } ...` (direct consequence
    of dropping the only `new SelectionManager()` in this file; leaving it
    would fail lint/build). Same file the R-item names — no scope mutation.
- `pinscope/src/runtime/hooks/useSelectedElement.ts`
  - The programmatic `select(pinId)` member on the `SelectedElement` interface
    and the hook return was already present in the R17 STEP-5 setup commit; no
    further change was required here this wave (verified in place — it calls
    `manager.select(pinId)` then `setSelected(resolveSelected(pinId))`,
    mirroring the click handler).
- `pinscope/tests/unit/runtime/selection.test.tsx`
  - The named DoD test (`describe('select e_N command — InfoPanel lock ...')`)
    was present from the STEP-5 setup commit; runs red on the pre-fix code and
    green after. Includes the flow-B regression guard test.

#### DoD clause verification

DoD closure conditions (from REMEDIATION-PLAN-R17.md §R-17-01):

1. **The named test passes.** verified: true.
   `npx vitest run tests/unit/runtime/selection.test.tsx` → `7 passed (7)` —
   includes "the `select e_N` command locks the InfoPanel" (see GREEN above).

2. **`npm test` green, no other suite regressed; the existing flow-B click lock
   test in `selection.test.ts(x)` still passes.** verified: true.
   Full suite below: `Test Files 29 passed (29) / Tests 300 passed (300)`
   (298 prior + 2 new R-17-01 tests). The flow-B test
   "a [data-pin] click still locks the InfoPanel (flow-B not regressed)" is in
   the 7-passing `selection.test.tsx` run.

3. **`new SelectionManager` count == 1 AND `command.selection` count == 0.**
   verified: true.

   ```
   $ grep -rn 'new SelectionManager' src
   src/runtime/hooks/useSelectedElement.ts:43:  if (managerRef.current === null) managerRef.current = new SelectionManager();
   ```

   Exactly one match — the lazy `managerRef` init in `useSelectedElement.ts`.
   The `PinScope.tsx` `command.selection` instantiation is gone.

   ```
   $ grep -cn 'command\.selection' src/runtime/PinScope.tsx
   0
   ```

   Zero matches (grep exit 1).

Acceptance criteria (all five):

- [x] `grep -rn 'new SelectionManager' src` → exactly one match
      (`useSelectedElement.ts:43`). verified: true.
- [x] `grep -n 'command\.selection' src/runtime/PinScope.tsx` → 0 matches.
      verified: true.
- [x] `grep -n 'selection:' src/runtime/PinScope.tsx` → no match inside the
      `command` `useMemo`. verified: true (grep returned no output at all).
- [x] `useSelectedElement`'s returned object exposes `select` — present on the
      `SelectedElement` interface (line 17) and the return statement (line 100,
      `return { selected, select, clear }`). verified: true.
- [x] The `select` branch of `onSubmit` invokes the hook-exposed selector
      (`selectPin(parsed.pin)`) and no longer names `command.selection`.
      verified: true.

#### Wave regression check

`cd pinscope && npx vitest run` (full suite):

```
 ✓ tests/unit/runtime/pinscope-assembly.test.tsx  (7 tests) 248ms
 ✓ tests/unit/runtime/infopanel.test.tsx  (3 tests) 120ms
 ✓ tests/unit/runtime/edge-cases.test.ts  (5 tests) 93ms
 ✓ tests/unit/runtime/element-walker.test.ts  (7 tests) 14ms
 ✓ tests/unit/runtime/shortcuts.test.tsx  (15 tests) 19ms
 ✓ tests/unit/runtime/perf.test.tsx  (2 tests) 135ms
 ✓ tests/unit/runtime/components.test.tsx  (3 tests) 62ms
 ✓ tests/unit/runtime/pinscope.test.tsx  (3 tests) 79ms
 ✓ tests/unit/runtime/public-api.test.ts  (2 tests) 3ms

 Test Files  29 passed (29)
      Tests  300 passed (300)
```

`npx tsc --noEmit` → exit 0 (no type errors).

The `DOMException [NetworkError]` console output during the run is pre-existing,
unrelated noise from a test that deliberately exercises a failed `fetch` — all
29 test files passed.

#### scope notes

Files modified: `src/runtime/PinScope.tsx`,
`src/runtime/hooks/useSelectedElement.ts` (no-op this wave — change pre-landed
in STEP 5 setup), and the DoD test file
`tests/unit/runtime/selection.test.tsx`. All named by R-17-01.

The dead `import { SelectionManager }` removal in `PinScope.tsx` is within the
R-item's named file and is the direct, required consequence of dropping the
only `new SelectionManager()` in that file — not a widening of scope.

Preservation-list files confirmed untouched:
`git diff --stat src/runtime/managers/SelectionManager.ts
src/runtime/managers/EndpointSnapshotStore.ts src/runtime/components/TopBar.tsx`
produced empty output. No edit to `pinscope/SPEC.md`. R-17-02 and R-17-03 were
not read or touched.

---

## Wave 2

### R-17-02

**id:** R-17-02
**linked finding:** F-17-02 (SUSPECTED — investigation R-item, P2)
**status:** closed

**summary:** Flow D (`onSnapshot` in `PinScope.tsx`) called
`SnapshotManager.capture()` but never `flush()`ed the `EndpointSnapshotStore`,
so a `SnapshotPersistError` from a failed dev-server persist became an unhandled
promise rejection — the exact "swallowed §10-D failure" of F-17-02. Implemented
the plan's **option (a)** (smallest diff, recommended default): the `command`
`useMemo` now holds the `EndpointSnapshotStore` instance (`snapshotStore`)
alongside `snapshots`, and `onSnapshot` ends in an observed
`command.snapshotStore.flush().catch(...)` that surfaces the failure via
`console.warn('[pinscope] snapshot persist failed', err)` — mirroring the
flow-C `bridge.send().catch('[pinscope] operation send failed')` convention in
the same file. No change to snapshot building or to the store's error
semantics.

#### STEP 1 — Confirm or refute (mandatory, SUSPECTED finding)

Finding **CONFIRMED** — the §10-D snapshot persist failure was genuinely
swallowed. Evidence, all run against the committed pre-fix baseline (`HEAD` =
`b09bb53`, the "Wave 2 execution start" checkpoint):

1. `git show HEAD:pinscope/src/runtime/PinScope.tsx | grep -n 'flush'` →
   **0 matches** (grep exit 1). The committed `onSnapshot` callback is
   `command.snapshots.capture(name);` and nothing else — no `flush()`, so the
   persist promise is never observed.

2. `EndpointSnapshotStore` (re-read, unchanged): its docstring states `flush()`
   awaits the in-flight write "so callers (and tests) can observe a failed
   persist instead of a silently swallowed one"; `post()` throws a typed
   `SnapshotPersistError` on network error or non-OK response. `write()` is
   synchronous and only stashes the promise in `pending` — `flush()` is the
   sole observation seam. The failure signal is real and, pre-fix, lost.

3. Flow C reference (`git show HEAD:.../PinScope.tsx | grep -n catch`):
   `void command.bridge.send(operation, raw).catch((err) => { ... })` with the
   "surface a failed clipboard/history write, never swallow" comment. Flow C
   observes its async failure; flow D omitted the equivalent step.

4. SPEC §10-D mandates a user-visible terminus ("→ toast") for snapshot
   creation, so a swallowed failure is a genuine spec gap, not a benign
   omission. The minimum that removes the *swallowed*-error defect is the
   in-repo flow-C `console.warn` convention.

The audit `re_read` expectation ("the finding CONFIRMS") holds — proceeded to
the fix.

#### Red -> Green transition

Named test: **"Flow D — a failed snapshot persist is surfaced, never
swallowed"** in `tests/unit/runtime/flow-wiring.test.tsx`. It mounts the real
`<PinScope/>`, stubs `globalThis.fetch` to resolve `{ ok: false, status: 500 }`,
spies on `console.warn`, registers an `unhandledrejection` listener, clicks the
`[data-pinscope-snapshot-btn]` TopBar button, awaits microtask settlement, and
asserts a `[pinscope]`-prefixed snapshot-failure `console.warn` fired AND that
no unhandled rejection escaped.

**RED** — test run with `PinScope.tsx` reverted to the committed pre-fix
baseline (via `git stash push -- src/runtime/PinScope.tsx`, keeping the new
test):

```
- Expected
+ Received

- true
+ false

 ❯ tests/unit/runtime/flow-wiring.test.tsx:172:24
    170|             /snapshot/i.test(call[0]),
    171|         );
    172|         expect(warned).toBe(true);
       |                        ^

⎯⎯⎯⎯⎯⎯ Unhandled Errors ⎯⎯⎯⎯⎯⎯
Vitest caught 1 unhandled error during the test run.

⎯⎯⎯⎯ Unhandled Rejection ⎯⎯⎯⎯⎯
SnapshotPersistError: snapshot persist failed: /__pinscope/snapshot returned 500
 ❯ EndpointSnapshotStore.post src/runtime/managers/EndpointSnapshotStore.ts:65:13

 Test Files  1 failed (1)
      Tests  1 failed | 3 passed (4)
     Errors  1 error
```

Red for the right reason: against the unfixed `onSnapshot`, (a) `console.warn`
was never called with a `[pinscope]` snapshot-failure message (`warned ===
false`), and (b) Vitest caught the `SnapshotPersistError` as an **Unhandled
Rejection** — the exact F-17-02 swallowed/unobserved §10-D failure.

**GREEN** — test run with the R-17-02 fix in place:

```
 RUN  v1.6.1 /home/user/apex/pinscope

 ✓ tests/unit/runtime/flow-wiring.test.tsx  (4 tests) 249ms

 Test Files  1 passed (1)
      Tests  4 passed (4)
```

No unhandled rejection — the `flush()` promise is `.catch()`-ed and the failure
reaches `console.warn`.

#### Files modified

- `pinscope/src/runtime/PinScope.tsx` — plan option (a):
  - `command` `useMemo`: extracted the `EndpointSnapshotStore` into a local
    `snapshotStore` const, passed it to `new SnapshotManager(snapshotStore)`,
    and added `snapshotStore` to the returned `command` object so `onSnapshot`
    can reach `flush()`.
  - `onSnapshot` `useCallback`: after `command.snapshots.capture(name)`, added
    `void command.snapshotStore.flush().catch((err: unknown) => { console.warn(
    '[pinscope] snapshot persist failed', err); });` — the observed
    `.catch()` that mirrors the flow-C swallow-prevention shape. The
    `useCallback` dependency array stays `[command]` (correct — `command` is the
    only captured value; `snapshotStore` is a member of it).
- `pinscope/tests/unit/runtime/flow-wiring.test.tsx` — added the named DoD test
  "Flow D — a failed snapshot persist is surfaced, never swallowed" (the test
  file the DoD names under `tests/`).

`SnapshotManager.ts` was NOT modified — option (a) was chosen over option (b),
so the `flush()` passthrough on `SnapshotManager` was not needed.

#### DoD clause verification

R-17-02 closure conditions (from REMEDIATION-PLAN-R17.md §R-17-02):

1. **The named test passes.** verified: true.
   `npx vitest run tests/unit/runtime/flow-wiring.test.tsx` → `4 passed (4)` —
   includes "Flow D — a failed snapshot persist is surfaced, never swallowed"
   (see GREEN above). Red→green transition demonstrated above.

2. **`npm test` green; the two existing `EndpointSnapshotStore` `flush()` tests
   in `snapshot.test.tsx` still pass.** verified: true.
   Full suite: `Test Files 29 passed (29) / Tests 301 passed (301)` (300 prior
   + 1 new R-17-02 test). `npx vitest run tests/unit/runtime/snapshot.test.tsx`
   → `6 passed (6)`, which includes "POSTs the snapshot to /__pinscope/snapshot"
   and "surfaces a non-ok response as a typed error, never swallows it" — the
   two `EndpointSnapshotStore` `flush()` tests.

3. **`grep -n 'flush' src/runtime/PinScope.tsx` ≥ 1 match AND the
   `EndpointSnapshotStore.ts` diff is empty.** verified: true.

   ```
   $ grep -cn 'flush' src/runtime/PinScope.tsx
   4
   $ grep -n 'flush().catch' src/runtime/PinScope.tsx
   154:      void command.snapshotStore.flush().catch((err: unknown) => {
   $ git diff --stat src/runtime/managers/EndpointSnapshotStore.ts
   (empty output — file unchanged)
   ```

Acceptance criteria (all four):

- [x] `grep -n 'flush' src/runtime/PinScope.tsx` returns ≥ 1 match inside the
      `onSnapshot` callback (4 matches; the operative one is line 154).
      verified: true.
- [x] The `flush()` promise in `onSnapshot` is observed — `flush().catch(` on
      line 154, not a bare `flush()` call. verified: true.
- [x] A `console.warn` with a `'[pinscope]'`-prefixed snapshot-failure message
      is in the `onSnapshot` failure path: line 155,
      `console.warn('[pinscope] snapshot persist failed', err)` — mirrors the
      flow-C `'[pinscope] operation send failed'` convention. verified: true.
- [x] `EndpointSnapshotStore.ts` is unchanged — `git diff --stat` on it
      produced empty output. verified: true.

#### Wave regression check

`cd pinscope && npx vitest run` (full suite):

```
 ✓ tests/unit/runtime/edge-cases.test.ts  (5 tests) 64ms
 ✓ tests/unit/runtime/pinscope-assembly.test.tsx  (7 tests) 240ms
 ✓ tests/unit/runtime/infopanel.test.tsx  (3 tests) 119ms
 ✓ tests/unit/runtime/element-walker.test.ts  (7 tests) 11ms
 ✓ tests/unit/runtime/shortcuts.test.tsx  (15 tests) 19ms
 ✓ tests/unit/runtime/perf.test.tsx  (2 tests) 135ms
 ✓ tests/unit/runtime/components.test.tsx  (3 tests) 67ms
 ✓ tests/unit/runtime/pinscope.test.tsx  (3 tests) 71ms
 ✓ tests/unit/runtime/public-api.test.ts  (2 tests) 3ms

 Test Files  29 passed (29)
      Tests  301 passed (301)
```

`npx tsc --noEmit` → exit 0 (no type errors).

The `DOMException [NetworkError]` console output during the run is pre-existing,
unrelated noise (an `iframe-overlay` test deliberately exercises a failed
`fetch`) — documented in the Wave 1 block; all 29 test files passed.

#### scope notes

Files modified: `src/runtime/PinScope.tsx` (the `command` `useMemo` + the
`onSnapshot` `useCallback` — both anchors the R-17-02 Execution plan names) and
the DoD test file `tests/unit/runtime/flow-wiring.test.tsx`. Plan **option (a)**
was chosen, so `SnapshotManager.ts` was deliberately NOT touched (option (b)
was not taken). No other source file modified.

Preservation-list files confirmed untouched:
`git diff --stat src/runtime/managers/EndpointSnapshotStore.ts
src/runtime/managers/SelectionManager.ts src/runtime/components/TopBar.tsx`
produced empty output. No edit to `pinscope/SPEC.md`. R-17-01 (done) and
R-17-03 (later wave) were not read or touched. No scope mutation.

---

## Wave 3

### R-17-03

**id:** R-17-03
**linked finding:** F-17-03 (SUSPECTED — investigation R-item, P3)
**status:** closed

**summary:** `PinScope.tsx` rendered `<TopBar ... stateOverride={null} />` — a
hardcoded constant — so the §8.5 TopBar `[data-field="state"]` span always read
`state: none` regardless of the live §8.8 `StatePanel` override. Root cause:
`StatePanel`'s override lived in a component-local `useState`, never lifted to
the common `PinScopeHud` parent that also renders `TopBar`. Implemented the
plan's recommended **callback** approach: `StatePanel` gained an optional
`onStateChange?: (state: StateOverride) => void` prop invoked inside `choose`
after `setState`/`applyStateOverride`; `PinScopeHud` gained a `stateOverride`
`useState` (initial `'none'`), wires `onStateChange={setStateOverride}` onto
`<StatePanel>`, and feeds the live `stateOverride` state value into the existing
`<TopBar stateOverride={...}>` prop in place of the literal `null`. The §8.8
`applyStateOverride` `<html data-state-override>` mechanism is untouched;
`TopBar.tsx` is not edited (its `string | null` prop already renders the value
correctly — `StateOverride` is assignable).

#### STEP 1 — Confirm or refute (mandatory, SUSPECTED finding)

Finding **CONFIRMED** — the §8.5 TopBar state readout was genuinely stale
(cosmetic staleness, P3). Evidence, all run against the committed pre-fix
baseline (`HEAD` = `f6ba54b`, the "Wave 3 execution start" checkpoint — verified
via `git stash` of the two source files, keeping the new test):

1. `git show HEAD:pinscope/src/runtime/PinScope.tsx | grep -n 'stateOverride'`
   showed exactly **1 match** — `stateOverride={null}` — the hardcoded `<TopBar>`
   prop. No `useState` for an override existed in `PinScopeHud`.

2. `TopBar.tsx` (re-read, unchanged): line 47 renders
   `<span data-field="state">state: {stateOverride ?? 'none'}</span>`. With a
   constant `null` fed in, the `?? 'none'` collapses it permanently to
   `state: none`.

3. `StatePanel` (pre-fix, re-read): its override was `const [state, setState] =
   useState<StateOverride>('none')`, **local** to `StatePanel`. `choose` called
   `setState` + `applyStateOverride` — `applyStateOverride` writes
   `<html data-state-override>` (§8.8) but nothing reported the chosen value
   upward. `StatePanel` exported no `onStateChange`/callback prop.

4. SPEC §8.5 lists a "state-override selector" readout *in the TopBar*; §8.8
   owns the actual `[data-state-override]` override mechanism. The TopBar
   readout is spec-meant to reflect the live override and pre-fix could not.

5. **Direct red-test proof** — the named DoD test run against the stashed
   pre-fix source (test present, fix absent):

   ```
    ❯ tests/unit/runtime/controls.test.tsx  (16 tests | 1 failed | 15 skipped)
      ❯ ... > TopBar reflects the live StatePanel override
        → expected 'state: none' to contain 'hover'

    FAIL  tests/unit/runtime/controls.test.tsx > TopBar ↔ StatePanel wiring (R-17-03, F-17-03) > TopBar reflects the live StatePanel override
   AssertionError: expected 'state: none' to contain 'hover'

   - Expected
   + Received

   - hover
   + state: none

    ❯ tests/unit/runtime/controls.test.tsx:87:26
   ```

The audit `re_read` expectation ("the finding CONFIRMS — cosmetic staleness")
holds — proceeded to the fix.

#### Red -> Green transition

Named test: **"TopBar reflects the live StatePanel override"** in
`tests/unit/runtime/controls.test.tsx`. It mounts the real `<PinScope/>`,
asserts the TopBar `[data-field="state"]` span first reads `none`, clicks the
StatePanel's `[data-state-btn="hover"]` button, and asserts the TopBar state
field text now contains `hover` and not `none`. This single test exercises the
now-live non-null `stateOverride` branch — simultaneously resolving the AC-037
TEST-AUDIT-R17 advisory ("the non-null `stateOverride` branch is never
exercised").

**RED** — test run with `PinScope.tsx` and `StatePanel.tsx` reverted to the
committed pre-fix baseline (via `git stash push -- src/runtime/PinScope.tsx
src/runtime/components/StatePanel.tsx`, keeping the new test):

```
 ❯ tests/unit/runtime/controls.test.tsx  (16 tests | 1 failed | 15 skipped) 78ms
   ❯ ... > TopBar reflects the live StatePanel override
     → expected 'state: none' to contain 'hover'

 FAIL  tests/unit/runtime/controls.test.tsx > TopBar ↔ StatePanel wiring (R-17-03, F-17-03) > TopBar reflects the live StatePanel override
AssertionError: expected 'state: none' to contain 'hover'

- Expected
+ Received

- hover
+ state: none

 ❯ tests/unit/runtime/controls.test.tsx:87:26

 Test Files  1 failed (1)
      Tests  1 failed | 15 skipped (16)
```

Red for the right reason: against the unfixed source the TopBar
`[data-field="state"]` span still read `state: none` after the StatePanel
`hover` button was clicked — the override never reached `TopBar` because
`stateOverride={null}` is hardcoded and `StatePanel`'s state was never lifted.
That is exactly the F-17-03 defect.

**GREEN** — test run with the R-17-03 fix in place (`git stash pop` restored
the two source files):

```
 RUN  v1.6.1 /home/user/apex/pinscope

 ✓ tests/unit/runtime/controls.test.tsx  (16 tests | 15 skipped) 72ms

 Test Files  1 passed (1)
      Tests  1 passed | 15 skipped (16)
```

The lifted `stateOverride` state flows StatePanel → `PinScopeHud` → TopBar; the
state field reflects the live `hover` override.

#### Files modified

- `pinscope/src/runtime/components/StatePanel.tsx` — added the optional
  `StatePanelProps` interface with `onStateChange?: (state: StateOverride) =>
  void`; `StatePanel` now destructures `{ onStateChange }` (default `= {}`, so
  it stays usable standalone); `choose` invokes `onStateChange?.(next)` after
  `setState(next)` + `applyStateOverride(next)`. `applyStateOverride` /
  `generateOverrideRules` / the `<html data-state-override>` write are
  byte-for-byte unchanged.
- `pinscope/src/runtime/PinScope.tsx` — `PinScopeHud`: added
  `const [stateOverride, setStateOverride] = useState<StateOverride>('none')`;
  added `import type { StateOverride }` from `StatePanel.js` (the type now used
  in this file); replaced the hardcoded `stateOverride={null}` on `<TopBar>`
  with the live `stateOverride` state value; wired
  `onStateChange={setStateOverride}` onto `<StatePanel>`.
- `pinscope/tests/unit/runtime/controls.test.tsx` — added the named DoD test
  "TopBar reflects the live StatePanel override" in a new `describe('TopBar ↔
  StatePanel wiring (R-17-03, F-17-03)')` block (the test file the DoD names
  under `tests/`).

`TopBar.tsx` was NOT modified — the fix is purely in the data feeding its
existing `stateOverride` prop, per the preservation-list directive.

#### DoD clause verification

R-17-03 closure conditions (from REMEDIATION-PLAN-R17.md §R-17-03):

1. **The named test passes.** verified: true.
   `npx vitest run tests/unit/runtime/controls.test.tsx -t "TopBar reflects the
   live StatePanel override"` → `1 passed | 15 skipped (16)` (see GREEN above).
   Red→green transition demonstrated above.

2. **`npm test` green — the existing AC-037 TopBar test and the AC-040
   StatePanel `data-state-override` test in `controls.test.tsx` still pass.**
   verified: true.
   `npx vitest run tests/unit/runtime/controls.test.tsx` → `16 passed (16)` —
   the full file, including the AC-037 and AC-040 tests. Full suite below:
   `Test Files 29 passed (29) / Tests 302 passed (302)` (301 prior + 1 new
   R-17-03 test).

3. **`grep -n 'stateOverride={null}' src/runtime/PinScope.tsx` returns 0 AND the
   `TopBar.tsx` diff is empty.** verified: true.

   ```
   $ grep -n 'stateOverride={null}' src/runtime/PinScope.tsx
   (no match — grep exit 1)
   $ grep -n 'stateOverride' src/runtime/PinScope.tsx
   130:  const [stateOverride, setStateOverride] = useState<StateOverride>('none');
   261:        stateOverride={stateOverride}
   $ git diff --stat src/runtime/components/TopBar.tsx
   (empty output — file unchanged)
   ```

Acceptance criteria (all five):

- [x] `grep -n 'stateOverride={null}' src/runtime/PinScope.tsx` → 0 matches —
      the hardcoded constant is gone. verified: true.
- [x] `<TopBar>` in `PinScope.tsx` is passed the `stateOverride` *state value* —
      a `useState` declaration (line 130) and the prop bound to it (line 261,
      `stateOverride={stateOverride}`), not a literal `null`. verified: true.
- [x] `StatePanel` accepts an `onStateChange` callback prop and invokes it —
      `grep -n 'onStateChange' src/runtime/components/StatePanel.tsx` →
      `98:  onStateChange?: (state: StateOverride) => void;` (prop type),
      `101:export function StatePanel({ onStateChange }...` (destructure),
      `107:    onStateChange?.(next);` (the call inside `choose`). verified: true.
- [x] `src/runtime/components/TopBar.tsx` is unchanged — `git diff --stat` on it
      produced empty output. verified: true.
- [x] `applyStateOverride`'s `<html data-state-override>` write is unchanged —
      `git diff src/runtime/components/StatePanel.tsx` shows no `-`/`+` line on
      any `data-state-override` / `setAttribute` / `removeAttribute` statement;
      the only changes are the new `StatePanelProps` interface, the destructure,
      and the `onStateChange?.(next)` call in `choose`. verified: true.

AC-037 advisory side effect: the new test exercises the now-live non-null
`stateOverride` branch of `TopBar`, resolving the carried-over AC-037
TEST-AUDIT-R17 advisory ("the non-null `stateOverride` branch is never
exercised") as a documented side effect. verified: true.

#### Wave regression check

`cd pinscope && npx vitest run` (full suite):

```
 ✓ tests/unit/runtime/controls.test.tsx  (16 tests) 140ms
 ✓ tests/unit/ast-transformer.test.ts  (66 tests) 71ms
 ✓ tests/unit/edge-utils.test.ts  (5 tests) 65ms
 ✓ tests/unit/deployment.test.ts  (10 tests) 499ms
 ✓ tests/unit/claude-bridge.test.ts  (2 tests) 855ms
 ✓ tests/unit/operation-perf.test.ts  (3 tests) 5ms
 ✓ tests/unit/long-press.test.ts  (3 tests) 3ms
 ✓ tests/unit/property-shortcuts.test.ts  (12 tests) 8ms
 ✓ tests/unit/production-stripper.test.ts  (4 tests) 3ms

 Test Files  29 passed (29)
      Tests  302 passed (302)
```

`npx tsc --noEmit` → exit 0 (no type errors).

Suite count went 301 → 302 (the one new R-17-03 DoD test); no prior test
regressed. The console error noise during the run (happy-dom `ERR_INVALID_URL`
on `/__pinscope/history`, pre-existing) is unrelated to this wave — documented
in the Wave 1 and Wave 2 blocks; all 29 test files passed.

#### scope notes

Files modified: `src/runtime/components/StatePanel.tsx` (the `StatePanel`
component render + the new `onStateChange` callback), `src/runtime/PinScope.tsx`
(the `PinScopeHud` `useState` block + the `<StatePanel>`/`<TopBar>` JSX), and
the DoD test file `tests/unit/runtime/controls.test.tsx` — exactly the three
files R-17-03 names. No other source file modified.

The `import type { StateOverride }` added to `PinScope.tsx` is within the
R-item's named file and is the direct, required consequence of typing the new
`stateOverride` `useState` — not a widening of scope.

Preservation-list files confirmed untouched:
`git diff --stat src/runtime/components/TopBar.tsx` produced empty output
(`TopBar.tsx` unchanged, per the explicit preservation directive). The §8.8
`applyStateOverride` `<html data-state-override>` write is byte-for-byte
preserved (no `-`/`+` lines on it in the `StatePanel.tsx` diff). No edit to
`pinscope/SPEC.md`. R-17-01 and R-17-02 (done in Waves 1-2) were not read or
touched. No scope mutation.
