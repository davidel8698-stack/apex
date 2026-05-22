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
