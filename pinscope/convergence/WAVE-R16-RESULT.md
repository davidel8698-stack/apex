# WAVE-R16-RESULT

## Wave 1 — R-16-01, R-16-03

**Executor:** ps-wave-executor · **Round:** PS-R16 · **Wave:** 1
**Baseline at wave start:** 293 passed / 0 failed (per the round brief). The
working tree at wave start carried a transient pre-staged mutation of
`src/plugin/index.ts` (M3/M4/M5: `ok: true → false`, `recursive: true → false`)
and the already-authored R-16-03 test strengthening in `tests/unit/plugin.test.ts`.
**Suite at wave end:** 297 passed / 0 failed (29 test files), `npm run build`
and `tsc --noEmit` exit 0. (+4 vs 293 = 3 new `flow-wiring.test.tsx` cases +
1 new nested-root case in `plugin.test.ts`.)

---

### R-16-01 — §10 flow-seam wiring into the `<PinScope/>` root — status: `closed`

**Linked findings:** F-16-01 (Flow C), F-16-02 (Flow D), F-16-03
(MeasurementTool render), F-16-04 (Flow B).

**Files modified:**
- `src/runtime/PinScope.tsx` — wired all four §10 seams into `PinScopeHud`.
- `src/runtime/components/TopBar.tsx` — added the §8.5 `data-pinscope-snapshot-btn`
  button + `onSnapshot` prop.

**Files created:**
- `src/runtime/hooks/useSelectedElement.ts` — the §10-B selection hook.
- `tests/unit/runtime/flow-wiring.test.tsx` — the DoD §5 RTL test.

**Red → green transition** (`tests/unit/runtime/flow-wiring.test.tsx`):

RED — the flow-wiring test authored and run against the pre-R16 `PinScope.tsx`
(no `onSubmit`, no `<MeasurementTool/>` render, no `useSelectedElement`):
```
 FAIL  tests/unit/runtime/flow-wiring.test.tsx > ... > Flow D — the measuring state renders the MeasurementTool
AssertionError: expected null not to be null
 ❯ tests/unit/runtime/flow-wiring.test.tsx:110:25

 FAIL  tests/unit/runtime/flow-wiring.test.tsx > ... > Flow B — clicking a pinned element moves the data-pin-selected attribute
AssertionError: expected null to be <div data-pin="e_9"></div> // Object.is equality

 Test Files  1 failed (1)
      Tests  3 failed (3)
```
(Flow C also failed — no clipboard write — Flow D and Flow B shown above.)

GREEN — after creating `useSelectedElement.ts`, wiring `PinScope.tsx`, and
adding the `TopBar` snapshot button:
```
 RUN  v1.6.1 /home/user/apex/pinscope
 ✓ tests/unit/runtime/flow-wiring.test.tsx  (3 tests) 142ms
 Test Files  1 passed (1)
      Tests  3 passed (3)
```

DoD §5 transient-stash verification — R-16-01 source files
(`PinScope.tsx`, `TopBar.tsx`, `useSelectedElement.ts`) stashed via
`git stash push --include-untracked`, the test re-run against the reverted
(pre-R16) source:
```
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 3 ⎯⎯⎯⎯⎯⎯⎯
 FAIL  ... > Flow C — a CommandBar operation submit reaches the Operation pipeline
 FAIL  ... > Flow D — the measuring state renders the MeasurementTool
 FAIL  ... > Flow B — clicking a pinned element moves the data-pin-selected attribute
      Tests  3 failed (3)
```
Stash popped, all R-16-01 changes restored.

**Definition of Done — clause-by-clause:**

1. **Flow C wired (F-16-01)** — `verified: true`.
   ```
   $ grep -rln 'parseCommand' src
   src/runtime/PinScope.tsx
   src/runtime/parsers/operation-parser.ts
   $ grep -rln 'ClaudeBridge' src
   src/runtime/PinScope.tsx
   src/runtime/managers/ClaudeBridge.ts
   $ grep -c 'onSubmit' src/runtime/PinScope.tsx
   2
   ```
   Exactly two `parseCommand` files incl. `PinScope.tsx`; `ClaudeBridge` lists
   `PinScope.tsx`; `onSubmit` count is 2 (handler `const onSubmit = useCallback`
   + JSX prop `<CommandBar onSubmit={onSubmit}/>`). The Flow C test asserts a
   §9.3 `Operation` (`version 1.0`, `pin e_7`, `request_type operation`,
   `background-color`/`red`) reaches the spied clipboard.

2. **Flow D wired (F-16-02)** — `verified: true`.
   ```
   $ grep -nE 'snapshot|EndpointSnapshotStore' src/runtime/PinScope.tsx
   27:import { EndpointSnapshotStore } from './managers/EndpointSnapshotStore.js';
   138:      snapshots: new SnapshotManager(new EndpointSnapshotStore()),
   216:          snapshot: () => onSnapshot(),
   $ grep -n 'data-pinscope-snapshot-btn' src/runtime/components/TopBar.tsx
   51:        data-pinscope-snapshot-btn=""
   ```
   `useKeyboardShortcuts` carries a `snapshot:` handler entry; an
   `EndpointSnapshotStore` is instantiated; `TopBar` has the snapshot button.

3. **MeasurementTool rendered (F-16-03)** — `verified: true`.
   ```
   $ grep -c 'MeasurementTool' src/runtime/PinScope.tsx
   2
   ```
   Import + `{measuring && <MeasurementTool />}` render in the visible-branch
   portal. Flow D test confirms `[data-pinscope-measure]` appears only while
   `measuring` is on and disappears when toggled off.

4. **Flow B wired (F-16-04)** — `verified: true`.
   ```
   $ ls src/runtime/hooks/useSelectedElement.ts
   src/runtime/hooks/useSelectedElement.ts
   $ grep -rln 'SelectionManager' src
   src/runtime/PinScope.tsx
   src/runtime/hooks/useSelectedElement.ts
   src/runtime/managers/SelectionManager.ts
   $ grep -n 'useSelectedElement' src/runtime/PinScope.tsx
   20:import { useSelectedElement } from './hooks/useSelectedElement.js';
   129:  const { selected } = useSelectedElement(measuring);
   ```
   The hook file exists; `SelectionManager` listed for `useSelectedElement.ts`;
   `PinScope.tsx` consumes the hook and feeds `selected ?? hovered` into
   `<InfoPanel/>`.

5. **RTL red→green test** — `verified: true`. `tests/unit/runtime/flow-wiring.test.tsx`
   transitions red→green (output above); transient-stash confirms it fails
   against the pre-R16 `PinScope.tsx`. Asserts (a) `e_7.bg → red` submit → §9.3
   `Operation` to clipboard, (b) `measuring` renders `[data-pinscope-measure]`,
   (c) a click on `[data-pin]` moves `[data-pin-selected]`.

6. **build / tsc / npm test exit 0** — `verified: true`.
   ```
   $ npm run build   → BUILD_EXIT=0
   $ npx tsc --noEmit → TSC_EXIT=0
   $ npx vitest run  → Test Files 29 passed (29) · Tests 297 passed (297)
   ```

**Notes:** `StatePanel.tsx` is render-only per the plan's untouched list; it
owns its own internal `state` with no callback prop, so `<TopBar
stateOverride>` keeps `null` (feeding StatePanel state into TopBar would
require adding a prop to `StatePanel.tsx` — forbidden scope mutation). The
mechanically-checkable DoD requires only that `<StatePanel/>` is rendered,
which it is (line 247). The `query` command path uses an `EMPTY_BUILD_CONTEXT`
since a `? topic` query carries no DOM target. Every `catch` in the new
`onSubmit` / `useSelectedElement` code logs via `console.warn` and returns —
no swallowed failure.

---

### R-16-03 — `plugin.test.ts` route-test strengthening — status: `closed`

**Linked findings:** F-16-05 (M3 `ok` snapshot), F-16-06 (M5 `ok` history),
F-16-07 (M4 `recursive` mkdir).

**Files modified:** `tests/unit/plugin.test.ts` (test-only — `src/plugin/index.ts`
NOT edited, per the R-16-03 untouched list).

**Wave-start state:** the R-16-03 test strengthening (`postThrough` returning
`{ status, body }`, the `ok`-flag assertions, the nested-root test) was already
present in the working tree; `src/plugin/index.ts` carried the transient
M3/M4/M5 mutation. The wave's job: prove the strengthened tests catch the
mutants (RED), then restore the correct source (GREEN).

**Red → green transition** (`tests/unit/plugin.test.ts`):

RED — strengthened tests run against the mutated `src/plugin/index.ts`
(`ok: false`, `recursive: false`):
```
 FAIL  tests/unit/plugin.test.ts > ... snapshot dev-server route ... > writes the snapshot body to .pinscope/snapshots/s_<id>.json
 FAIL  tests/unit/plugin.test.ts > ... snapshot dev-server route ... > creates the snapshot directory chain when the project root is nested
 FAIL  tests/unit/plugin.test.ts > ... history dev-server route ... > writes the posted command history to .pinscope/history.json
 FAIL  tests/unit/plugin.test.ts > ... history dev-server route ... > caps the persisted history at the last 1000 entries
AssertionError: expected false to be true // Object.is equality
 Test Files  1 failed (1)
      Tests  4 failed | 8 passed (12)
```
The 4 failures confirm the strengthened tests kill M3 (snapshot `ok`), M5
(history `ok`, both route tests) and M4 (nested-root: 400 + no file under
`recursive: false`).

GREEN — `src/plugin/index.ts` restored to its correct committed state via
`git checkout HEAD -- src/plugin/index.ts` (the spec mandates the source is
already correct and untouched; the mutation was transient):
```
 RUN  v1.6.1 /home/user/apex/pinscope
 ✓ tests/unit/plugin.test.ts  (12 tests) 32ms
 Test Files  1 passed (1)
      Tests  12 passed (12)
```

**Definition of Done — clause-by-clause:**

1. **F-16-05 closed (kills M3)** — `verified: true`. The snapshot-route test
   `JSON.parse`s `result.body` and asserts `response.ok === true` (and
   `response.id`). Against the M3 mutant (`ok: false`) the test failed
   ("writes the snapshot body…" in the RED list); against restored source it
   passes.

2. **F-16-06 closed (kills M5)** — `verified: true`. Both history-route tests
   (`writes the posted command history…`, `caps … at the last 1000 entries`)
   `JSON.parse` the body and assert `response.ok === true` and `response.count`
   (1 and 1000). Against the M5 mutant both failed (RED list); against restored
   source both pass.

3. **F-16-07 closed (kills M4)** — `verified: true`. The
   `creates the snapshot directory chain when the project root is nested` test
   uses `root = path.join(base, 'workspace', 'apps', 'web')` — a multi-level
   path NOT created on disk (`expect(fs.existsSync(root)).toBe(false)`) — and
   asserts status 200 + the file present at the deep path. Against the M4
   mutant (`recursive: false`) the handler `mkdirSync` throws `ENOENT`, the
   route answers 400, no file → test failed (RED list); against the real
   `recursive: true` it passes.

4. **npm test exit 0, previously-green plugin tests stay green** —
   `verified: true`. `plugin.test.ts` 12/12; full suite 297/297.

**Notes:** `src/plugin/index.ts` final state is byte-identical to its committed
HEAD (`grep` confirms `recursive: true`, `ok: true` at all four sites) — no
source change, as R-16-03 requires.

---

### Wave-1 regression check

```
$ npm run build      → exit 0
$ npx tsc --noEmit   → exit 0
$ npx vitest run
 Test Files  29 passed (29)
      Tests  297 passed (297)
```
No previously-green test turned red. 293 → 297 (+3 `flow-wiring.test.tsx`,
+1 nested-root `plugin.test.ts`). The `iframe-overlay.test.ts` `NetworkError`
console lines are pre-existing benign happy-dom noise (the suite still reports
all files passed) — unrelated to this wave.

### Scope notes

`src/plugin/index.ts` was touched: it was restored (`git checkout HEAD --`)
from a transient pre-staged M3/M4/M5 mutation back to its correct committed
state. This is the R-16-03 "implement the real fix" step — the strengthened
tests were already authored and proven RED against the mutated source; the fix
is the correct source. The file's final content equals committed HEAD, so no
net source change ships from this wave. No other file outside the R-items'
named set was modified.

---

## Wave 2 — R-16-02

**Executor:** ps-wave-executor · **Round:** PS-R16 · **Wave:** 2 (final)
**Baseline at wave start:** 297 passed / 0 failed (29 test files) — the
committed state after Wave 1 (`f9b2186` flow-seam wiring, incl. the live
`CommandBar` `onSubmit` Flow-C path). The working tree at wave start carried
the already-authored R-16-02 test strengthening in
`tests/unit/runtime/controls.test.tsx` (the §8.6 `fetch`-POST persistence test
+ the `AC-035` Crosshair `describe` rename), staged by the Wave-2 start commit
`31ecdae`. The wave's job: prove the strengthened test catches a broken
`CommandBar → fetch` seam (RED via transient M2 mutation), restore the source
(GREEN), verify the AC-035 tag-filter visibility, and confirm no regression.
**Suite at wave end:** 298 passed / 0 failed (29 test files). (+1 vs 297 = the
new `controls.test.tsx` CommandBar persistence case.)

---

### R-16-02 — `CommandBar → fetch` POST persistence seam coverage + AC-035 tag visibility — status: `closed`

**Linked finding:** F-16-08 (P2) — the `CommandBar → fetch` POST persistence
seam is un-asserted (R15 mutation survivor M2: `typeof fetch !== 'function'`
survives `!==` → `===` because no test confirms the CommandBar fires the
persistence `fetch` POST). Folds the advisory AC-035 tag-visibility fix.

**Files modified:** `tests/unit/runtime/controls.test.tsx` (test-only —
`src/runtime/components/CommandBar.tsx` NOT edited, per the R-16-02 untouched
list).

**Red → green transition** (`tests/unit/runtime/controls.test.tsx` ›
`fires the §8.6 fetch POST to the /__pinscope/history endpoint on submit`):

RED — the new test run against a transiently mutated `CommandBar.tsx`
`persistHistory` guard (`typeof fetch !== 'function'` → `=== 'function'`, the
M2 mutant — flipped so the guard returns early whenever `fetch` IS available,
disabling all persistence):
```
 FAIL  tests/unit/runtime/controls.test.tsx > CommandBar §8.6 — focus-expand / Tab autocomplete / history (R-15-07) > fires the §8.6 fetch POST to the /__pinscope/history endpoint on submit
AssertionError: expected "spy" to be called 1 times, but got 0 times
 ❯ tests/unit/runtime/controls.test.tsx:248:22
    246|
    247|     // The persistence POST fired exactly once at the history endpoint.
    248|     expect(fetchSpy).toHaveBeenCalledTimes(1);
       |                      ^
 Test Files  1 failed (1)
      Tests  1 failed | 14 skipped (15)
```
The failure is for the right reason: with the seam broken the CommandBar never
fires the `fetch` POST, so the spy is called 0 times — the test catches it.

GREEN — `src/runtime/components/CommandBar.tsx` restored to its correct
committed state via `git checkout HEAD -- src/runtime/components/CommandBar.tsx`
(R-16-02 forbids editing this source; the mutation was transient):
```
 ✓ tests/unit/runtime/controls.test.tsx  (15 tests | 14 skipped) 36ms
 Test Files  1 passed (1)
      Tests  1 passed | 14 skipped (15)
```

**Definition of Done — clause-by-clause:**

1. **CommandBar `fetch`-POST test exists** — `verified: true`. `controls.test.tsx`
   contains the test `fires the §8.6 fetch POST to the /__pinscope/history
   endpoint on submit` (line 226) inside the CommandBar §8.6 `describe`. It
   stubs `globalThis.fetch` with a `vi.fn()` spy (`vi.stubGlobal('fetch', …)`),
   renders `<CommandBar/>`, types `e_5.bg → red`, presses Enter, and asserts:
   the spy's first argument is `'/__pinscope/history'`, `init.method` is
   `'POST'`, and the request body `JSON.parse`s to `{ version: '1.0',
   entries: [...] }` with the submitted command present in `entries`.
   ```
   $ grep -n 'fetch' tests/unit/runtime/controls.test.tsx
   226:  it('fires the §8.6 fetch POST to the /__pinscope/history endpoint on submit', async () => {
   235:    const fetchSpy = vi
   238:    vi.stubGlobal('fetch', fetchSpy);
   248:    expect(fetchSpy).toHaveBeenCalledTimes(1);
   $ grep -n '__pinscope/history' tests/unit/runtime/controls.test.tsx
   226:  ...fetch POST to the /__pinscope/history endpoint on submit...
   250:    expect(url).toBe('/__pinscope/history');
   ```

2. **Test kills mutant M2** — `verified: true`. With the `CommandBar` guard
   transiently changed to `if (typeof fetch === 'function') return;` the test
   FAILED (RED output above — `spy ... called 0 times`); with the real source
   (`!== 'function'`) it PASSED (GREEN output above). The transient mutation
   was reverted with `git checkout HEAD -- src/runtime/components/CommandBar.tsx`;
   `grep -n 'typeof fetch' src/runtime/components/CommandBar.tsx` confirms the
   restored guard is `if (typeof fetch !== 'function') return;` — byte-identical
   to committed HEAD, no source change ships.

3. **AC-035 tag visibility** — `verified: true`. The formerly-untagged
   `describe('Crosshair disable conditions (R-15-02, §8.3)')` is renamed to
   `describe('Crosshair disable conditions — AC-035 (R-15-02, §8.3)')`.
   ```
   $ grep -c 'AC-035' tests/unit/runtime/controls.test.tsx
   1
   $ grep -n 'AC-035' tests/unit/runtime/controls.test.tsx
   116:describe('Crosshair disable conditions — AC-035 (R-15-02, §8.3)', () => {
   ```
   The matched `describe` is the Crosshair §8.3 disable-conditions block (its
   three `it`s: "does not render while in measurement mode", "does not render
   while the HUD is hidden", "renders normally with no disable props").
   `vitest --testNamePattern AC-035` now runs exactly those three §8.3 guard
   tests — before the rename it matched 0:
   ```
   $ npx vitest run tests/unit/runtime/controls.test.tsx --testNamePattern AC-035
    ✓ tests/unit/runtime/controls.test.tsx  (15 tests | 12 skipped) 33ms
    Test Files  1 passed (1)
         Tests  3 passed | 12 skipped (15)
   ```
   3 passed = the §8.3 disable tests now visible to the matrix filter.

4. **`npm test` exits 0** — `verified: true`. `npx vitest run` →
   `Test Files 29 passed (29) · Tests 298 passed (298)`.

**Notes:** R-16-02 is a pure test-coverage fix — `CommandBar.tsx`'s
`persistHistory` POST is already correct (per SPEC §8.6 "History persisted to
`.pinscope/history.json` (last 1000)" and §10-C "Operation via CommandBar — …
clipboard + history"); only the network seam was unasserted. The `fetch` spy
is restored after each test by the file-level `afterEach`
(`vi.unstubAllGlobals()`, line 17) plus an explicit `vi.unstubAllGlobals()` in
the test body, so it never bleeds into sibling `controls.test.tsx` tests. The
benign `[pinscope] history persist failed` happy-dom `stderr` lines in other
CommandBar tests (which use a real relative-URL `fetch` outside a dev server)
are pre-existing console noise — `persistHistory`'s `.catch`/`try` surfaces the
failure to the console rather than swallowing it; the suite still reports all
files passed.

---

### Wave-2 regression check

```
$ npx vitest run
 Test Files  29 passed (29)
      Tests  298 passed (298)
```
No previously-green test turned red. 297 → 298 (+1 = the new CommandBar §8.6
`fetch`-POST persistence case). The full §8.3 Crosshair disable suite is
unchanged behaviorally — only its `describe` name now carries the `AC-035`
token. The `iframe-overlay.test.ts` `NetworkError` / `[pinscope] history
persist failed` console lines are pre-existing benign happy-dom noise unrelated
to this wave.

### Scope notes

`src/runtime/components/CommandBar.tsx` was touched only transiently: it was
mutated in-place (M2 `!==` → `===`) to demonstrate the RED state, then
immediately restored with `git checkout HEAD -- src/runtime/components/CommandBar.tsx`.
Its final content is byte-identical to committed HEAD — `grep` confirms the
guard is `typeof fetch !== 'function'`. No net source change ships from this
wave; the only file modified for the commit is
`tests/unit/runtime/controls.test.tsx`, exactly the file R-16-02 names. No
other file outside the R-item's named set was modified.
