# Remediation Plan — PS-R16

## Round summary

The R16 spec-auditor confirmed **8 investigation findings** (0 AC findings, 0
regressions) — **1 P1** (F-16-01), **4 P2** (F-16-02, F-16-03, F-16-04, F-16-08),
**3 P3** (F-16-05, F-16-06, F-16-07). The R16 narrative-auditor reported an
**empty `blocking_findings` array** (all 9 R15 narrative gaps confirmed
remediated) — nothing to plan from it; its `candidate_acs` / `strengthen_proposals`
are out of scope. The STEP-1C test-quality audit returned **WARN (advisory, not a
FAIL)** — it produces no mandatory findings; its AC-037/AC-075 advisories already
overlap the F-16-05..08 carry-overs, and the cheap AC-035 tag-visibility advisory
is folded into R-16-02 because it shares that R-item's files.

Root-cause grouping reduces 8 findings to **4 R-items**:

- **R-16-01** — root cause *A: §7.1 components are mounted but their §10
  behavioral-flow seams are never wired into the `PinScope` root*. Closes the
  four flow-wiring findings **F-16-01 (Flow C), F-16-02 (Flow D), F-16-03
  (MeasurementTool render), F-16-04 (Flow B)** — they are one defect (R15 mounted
  the tree, R16 must wire the flows), but each is a distinct seam in distinct
  files, so R-16-01 carries four independently-checkable sub-DoDs rather than
  collapsing them into prose. (Grouped as one R-item per STEP 2: shared root
  cause, one coherent edit to `PinScope.tsx` + its new hooks.)
- **R-16-02** — F-16-08 (P2): the `CommandBar → fetch` POST seam is un-asserted.
  Kept separate from R-16-01: it is a *test-coverage* fix, not a wiring fix, and
  it must be authored against the F-16-01 wiring landed by R-16-01 (dependency,
  not duplication). The AC-035 untagged-`describe` advisory is folded here.
- **R-16-03** — root cause *B: every `plugin.test.ts` route test asserts the
  on-disk file but never the HTTP response body, and every test uses a
  single-level temp root*. Closes **F-16-05, F-16-06, F-16-07** — three
  mutation-survivor carry-overs that all touch `tests/unit/plugin.test.ts`
  against `src/plugin/index.ts`. One test-file edit closes all three.

No finding dropped: F-16-01→R-16-01, F-16-02→R-16-01, F-16-03→R-16-01,
F-16-04→R-16-01, F-16-05→R-16-03, F-16-06→R-16-03, F-16-07→R-16-03,
F-16-08→R-16-02. **8/8 routed across 4 R-items, 2 shared-root groups.**

---

## Remediation R-16-01

**id:** R-16-01
**Linked finding:** F-16-01, F-16-02, F-16-03, F-16-04
**Severity:** P1 (max of P1/P2/P2/P2)
**Spec anchor:** §10 "C. Operation via CommandBar — parse → validate … → build
Operation → clipboard + history → toast"; §10 "D. Snapshot creation — `Shift+S`
→ walk all pins → build Snapshot → persist via dev-server endpoint
`/__pinscope/snapshot`"; §10 "B. Selection — click → `SelectionManager.select`
→ `data-pin-selected` attribute moved → URL hash updated → InfoPanel locks";
§8.7 "MeasurementTool — `M` key. Two-click measurement"; §8.5 "TopBar … snapshot
button"; §8.8 "StatePanel".
**Root cause:** R15 closed NF-15-01 by *mounting* the §7.1 component tree, but
the §10 behavioral flows that those components exist to serve were never wired
into the `PinScope` root. `PinScope.tsx`'s `PinScopeHud` renders `<CommandBar/>`
with no `onSubmit`, never renders `<MeasurementTool/>`/`<StatePanel/>`,
instantiates neither `SelectionManager`/`SnapshotManager`/`EndpointSnapshotStore`
nor a `useSelectedElement` hook, and registers no `snapshot` shortcut handler.
The mechanism is half-built: primitives (`parseCommand`, `buildOperation`,
`ClaudeBridge`, `SnapshotManager`, `SelectionManager`, `MeasurementTool`) exist
and pass unit tests, but the HUD never connects them — so the matrix (each AC
verifies a primitive in isolation) cannot see the dead seams.

### Ecosystem analysis

1. *Why are the flows unwired when the components mount?* — R15's scope was the
   §7.1 component *tree* (NF-15-01..03); flow wiring (§10 B/C/D) was off that
   round's matrix and off the AC matrix entirely.
2. *Does Flow C need new code or only wiring?* — Only wiring: `parseCommand`,
   `buildOperation`, `ClaudeBridge` all exist. `PinScopeHud` must build an
   `onSubmit` handler that runs `parseCommand` → (for `operation`/`class`/`query`)
   `buildOperation` → `ClaudeBridge.send`, and pass it to `<CommandBar/>`.
3. *What `BuildContext` does `buildOperation` need?* — `tag`, `selector`, `rect`,
   `currentStyles`, `viewport`, optional `parentPin`/`childrenPins`/`textContent`.
   These resolve from the pin element looked up by `document.querySelector`
   (`[data-pin="<pin>"]`) — the same `getComputedStyle`/`getBoundingClientRect`
   the InfoPanel already uses.
4. *Are `select`/`measure`/`snapshot` kinds Claude operations?* —
   `buildOperation` throws `OperationBuildError` for them by contract; the
   `onSubmit` handler must branch: `select`→`SelectionManager.select`,
   `snapshot`→`SnapshotManager.capture` (via `EndpointSnapshotStore`),
   `measure`→toggle measuring. Only `operation`/`class`/`query` go to
   `ClaudeBridge`.
5. *How is Flow D triggered?* — `useKeyboardShortcuts` already defines the
   `snapshot` shortcut id (Shift+S); `PinScopeHud` registers no handler for it.
   Add a `snapshot` handler that calls `SnapshotManager.capture()` on an
   `EndpointSnapshotStore`. §8.5 also calls for a TopBar snapshot button — wire
   the same handler to a `<TopBar/>` button (or a `data-pinscope-snapshot-btn`).
6. *How is Flow B triggered?* — A new `useSelectedElement` hook owns a
   `SelectionManager`, listens for `click` on `[data-pin]` elements (escaping
   the HUD via the existing `escapeHud` walker), calls `SelectionManager.select`,
   and exposes the selected `HoveredElement`. `PinScopeHud` feeds the selected
   element into `<InfoPanel/>` so a locked selection survives mouse-out.
7. *Does InfoPanel need lock behavior?* — §8.1 says "click-outside locks
   selection; Esc unlocks". Minimum for this R-item: InfoPanel renders the
   selected element when one is locked, falling back to `hovered` otherwise.
   Click-outside / Esc is owned by `useSelectedElement` (it owns the
   `SelectionManager` whose `unlock`/`clear` already exist).
8. *Does MeasurementTool need new code?* — No: `MeasurementTool.tsx` is complete
   (two-click overlay). It is simply never rendered. `PinScopeHud` must render
   `<MeasurementTool/>` inside the visible-branch portal, gated on the existing
   `measuring` state.
9. *Where does `useSelectedElement` live?* — `src/runtime/hooks/useSelectedElement.ts`,
   alongside `useHoveredElement`/`useViewportSize`/`useKeyboardShortcuts`. §5's
   file-structure list already names this hook; creating it closes that gap too.
10. *Risk of double-handling clicks?* — `MeasurementTool` and `useSelectedElement`
    both listen for `click`. They must not conflict: `useSelectedElement`'s
    click handler must early-return when `measuring` is active (selection is
    suppressed in measurement mode), mirroring how Crosshair is suppressed.

### Execution plan

**Files to modify:**
- `src/runtime/PinScope.tsx` — the `PinScopeHud` function. (a) Build an
  `onSubmit` handler and pass it to `<CommandBar onSubmit=…/>`. (b) Add a
  `snapshot` entry to the `useKeyboardShortcuts` handler map. (c) Render
  `<MeasurementTool/>` inside the visible-branch portal, gated on `measuring`.
  (d) Render `<StatePanel/>` inside the visible-branch portal and feed its
  current override into `<TopBar stateOverride=…/>`. (e) Consume the new
  `useSelectedElement` hook and feed the selected element into `<InfoPanel/>`
  (locked selection takes precedence over `hovered`).
- `src/runtime/components/TopBar.tsx` — add a snapshot button
  (`data-pinscope-snapshot-btn`) wired to an `onSnapshot` prop (§8.5 "snapshot
  button"); add the prop to `TopBarProps`.

**Files to create:**
- `src/runtime/hooks/useSelectedElement.ts` — a hook owning a `SelectionManager`
  instance; binds a `click` listener that escapes the HUD (`escapeHud`) and
  finds the pinned ancestor (`findPinnedAncestor`), calls
  `SelectionManager.select(pinId)`, mirrors to the URL hash (the manager already
  does this), and exposes `{ selected: HoveredElement | null, clear }`. Binds
  `Esc`/click-outside to `SelectionManager.unlock`/`clear`. Early-returns from
  the click handler when `measuring` is active.

**Files that MUST remain untouched:**
- `src/runtime/parsers/operation-parser.ts`, `operation-builder.ts`,
  `property-shortcuts.ts` — the parse/build primitives are correct; this R-item
  only *calls* them. No grammar or builder change.
- `src/runtime/managers/ClaudeBridge.ts`, `SnapshotManager.ts`,
  `EndpointSnapshotStore.ts`, `SelectionManager.ts` — instantiate and call them;
  do not edit their bodies.
- `src/runtime/components/MeasurementTool.tsx`, `StatePanel.tsx`,
  `CommandBar.tsx` — render/pass-props only. In particular do **not** change
  `CommandBar`'s existing `persistHistory` `if (typeof fetch !== 'function')`
  guard or its `onSubmit?.(command)` call site — `onSubmit` is already a
  declared optional prop; only the caller (`PinScopeHud`) changes.
- `src/plugin/index.ts` — the dev-server routes are correct; Flow D persists
  through the existing `/__pinscope/snapshot` route via `EndpointSnapshotStore`.

**Order of operations:**
1. Create `src/runtime/hooks/useSelectedElement.ts` (no dependents yet).
2. In `PinScope.tsx`, render `<MeasurementTool/>` gated on `measuring`
   (smallest, isolated change) and `<StatePanel/>`.
3. In `PinScope.tsx`, add the `onSubmit` handler — `parseCommand` →
   branch on `kind` → `buildOperation`+`ClaudeBridge.send` for
   `operation`/`class`/`query`, local actions for `select`/`measure`/`snapshot`
   — and pass it to `<CommandBar/>`.
4. In `PinScope.tsx`, add the `snapshot` shortcut handler (Flow D) and consume
   `useSelectedElement`, feeding selection into `<InfoPanel/>`.
5. In `TopBar.tsx`, add the snapshot button + `onSnapshot` prop; wire it from
   `PinScope.tsx` to the same Flow-D handler.

**Rollback trigger:** any existing runtime suite that was green before this
R-item (`pinscope-assembly.test.tsx`, `controls.test.tsx`, `overlays.test.tsx`,
`snapshot.test.tsx`, `components.test.tsx`, `infopanel.test.tsx`) turns red, or
`npm run build` / `tsc` fails — revert and re-scope.

### Acceptance criteria

- [ ] `grep -n 'onSubmit' src/runtime/PinScope.tsx` shows `<CommandBar/>`
  receiving an `onSubmit` handler (not just the import/comment).
- [ ] `grep -rln 'parseCommand' src` returns **more than one** file
  (`operation-parser.ts` **and** `PinScope.tsx`).
- [ ] `grep -rln 'ClaudeBridge' src` returns **more than one** file
  (`ClaudeBridge.ts` **and** `PinScope.tsx`).
- [ ] `grep -n 'MeasurementTool' src/runtime/PinScope.tsx` shows it imported
  **and** rendered in the visible-branch portal.
- [ ] `grep -n 'snapshot' src/runtime/PinScope.tsx` shows a `snapshot` handler
  registered in the `useKeyboardShortcuts` map and an `EndpointSnapshotStore`
  (or `SnapshotManager`) instantiated.
- [ ] `ls src/runtime/hooks/useSelectedElement.ts` exists; `grep -rln
  'SelectionManager' src` returns **more than one** file.
- [ ] `grep -n 'StatePanel' src/runtime/PinScope.tsx` shows it rendered.
- [ ] `grep -n 'snapshot' src/runtime/components/TopBar.tsx` shows a
  `data-pinscope-snapshot-btn` button.
- [ ] `npm run build` and `tsc --noEmit` exit 0; the full runtime test suite
  stays green.

### Definition of Done

Closed when **all** of the following hold (mechanically checkable by someone who
never saw the diff):

1. **Flow C wired (F-16-01):** `grep -rln 'parseCommand' src` lists exactly two
   files including `src/runtime/PinScope.tsx`; `grep -rln 'ClaudeBridge' src`
   lists `src/runtime/PinScope.tsx`; `grep -c 'onSubmit' src/runtime/PinScope.tsx`
   ≥ 2 (handler definition + JSX prop).
2. **Flow D wired (F-16-02):** `grep -E 'snapshot' src/runtime/PinScope.tsx`
   matches both a `useKeyboardShortcuts` `snapshot:` handler entry and an
   `EndpointSnapshotStore`/`SnapshotManager` instantiation; `grep
   'data-pinscope-snapshot-btn' src/runtime/components/TopBar.tsx` matches.
3. **MeasurementTool rendered (F-16-03):** `grep -c 'MeasurementTool'
   src/runtime/PinScope.tsx` ≥ 2 (import + render).
4. **Flow B wired (F-16-04):** the file `src/runtime/hooks/useSelectedElement.ts`
   exists; `grep -rln 'SelectionManager' src` includes `useSelectedElement.ts`;
   `grep 'useSelectedElement' src/runtime/PinScope.tsx` matches.
5. A new RTL test in `tests/unit/runtime/` (e.g.
   `flow-wiring.test.tsx`) transitions **red → green**, rendering `<PinScope/>`
   and asserting: (a) submitting a `e_N.bg → red` command through the rendered
   `[data-pinscope-command]` input invokes the operation pipeline (a spied
   clipboard/`ClaudeBridge` receives a §9.3 `Operation`); (b) the `measuring`
   state renders a `[data-pinscope-measure]`-bearing node; (c) a click on a
   `[data-pin]` element produces a `[data-pin-selected]` attribute. The test
   must be authored to fail against the pre-R16 `PinScope.tsx` (verify by
   transient stash).
6. `npm run build`, `tsc --noEmit`, and `npm test` all exit 0.

### Dependencies

- **None upstream.** All called primitives already exist and are unit-tested.
- **Downstream:** R-16-02's `CommandBar → fetch` POST assertion is authored
  against the live `onSubmit` path landed here — R-16-02 must run **after**
  R-16-01 (it does not edit the same files, so no wave conflict, only ordering).

### Risk assessment

- **Medium.** Largest change of the round — five edits to `PinScope.tsx` plus a
  new hook. Mitigation: ordered steps land isolated changes first
  (`MeasurementTool` render, then `StatePanel`, then `onSubmit`, then selection),
  each independently buildable.
- **Click-handler contention:** `MeasurementTool` and `useSelectedElement` both
  bind `click`. Mitigation — `useSelectedElement`'s handler early-returns while
  `measuring`; AC-covered by DoD §5(c) running with `measuring` false.
- **No spec drift:** every wired flow cites a frozen §10/§8 anchor; no behavior
  is invented beyond connecting existing primitives.
- **Conflict matrix:** touches `PinScope.tsx`, `TopBar.tsx`,
  `useSelectedElement.ts` (new) — disjoint from R-16-02 (`controls.test.tsx`)
  and R-16-03 (`plugin.test.ts`). Safe to wave-parallelize with R-16-03.

---

## Remediation R-16-02

**id:** R-16-02
**Linked finding:** F-16-08
**Severity:** P2
**Spec anchor:** §8.6 "History persisted to `.pinscope/history.json` (last
1000)"; §10 "C. Operation via CommandBar — … clipboard + history".
**Root cause:** `CommandBar`'s `persistHistory` is guarded by
`if (typeof fetch !== 'function') return;`, but `controls.test.tsx`'s CommandBar
tests inject a `HistoryManager` and spy only on `history.append` — no test ever
stubs `fetch` or asserts the POST fires. The mutation `!==` → `===` (M2) flips
the guard so persistence is silently disabled, and no test fails. This is a pure
test-coverage gap at the network seam, not a code defect; it compounds F-16-01
because the only live persistence the CommandBar performs is itself unverified.

### Ecosystem analysis

1. *Is this a code bug or a coverage gap?* — Coverage gap. `persistHistory`
   POSTs correctly; the seam is simply unasserted.
2. *Which mutant survives?* — M2: `typeof fetch !== 'function'` → `=== 'function'`.
   Flipped, the guard returns early whenever `fetch` *is* available — disabling
   all persistence — yet every current CommandBar test passes.
3. *What kills M2?* — A test that stubs `globalThis.fetch` with a spy, renders
   `<CommandBar/>`, types a command, presses Enter, and asserts the spy was
   called with `'/__pinscope/history'` and a `{ version, entries }` body. With
   the mutant, the spy is never called → red.
4. *Where does the test live?* — `tests/unit/runtime/controls.test.tsx`, in the
   existing `describe('CommandBar §8.6 — focus-expand / Tab autocomplete /
   history (R-15-07)')` block, or a new sibling `describe` carrying the AC
   relevant tag.
5. *Does it need R-16-01?* — The `fetch` POST in `persistHistory` already fires
   on Enter independent of `onSubmit`. The test can be authored standalone, but
   R-16-01 lands the live `onSubmit` wiring; authoring after R-16-01 lets the
   test additionally observe the full Flow-C path. Order R-16-02 after R-16-01.
6. *Folded advisory (AC-035 tag visibility):* the TEST-AUDIT-R16 WARN notes the
   R-15-02 Crosshair §8.3 disable tests sit in
   `describe('Crosshair disable conditions (R-15-02, §8.3)')` in
   `controls.test.tsx` — an untagged block the `AC-035` `--testNamePattern`
   filter never matches. Since this R-item already edits `controls.test.tsx`,
   rename that `describe` to include the `AC-035` token so the genuine §8.3
   guard tests become visible to the matrix filter. Cheap, same-file, no new
   scope.

### Execution plan

**Files to modify:**
- `tests/unit/runtime/controls.test.tsx` — (a) add a CommandBar test that stubs
  `fetch` and asserts the `/__pinscope/history` POST; (b) rename
  `describe('Crosshair disable conditions (R-15-02, §8.3)')` to include the
  `AC-035` token (e.g. `describe('Crosshair disable conditions — AC-035
  (R-15-02, §8.3)')`).

**Files to create:** none.

**Files that MUST remain untouched:**
- `src/runtime/components/CommandBar.tsx` — the `persistHistory` guard and POST
  are correct; this R-item only adds a test that asserts them. No source edit.
- Every other test file — only `controls.test.tsx` changes.

**Order of operations:**
1. Add the `fetch`-stub CommandBar persistence test; confirm it fails against a
   transiently mutated `=== 'function'` guard, passes against the real source.
2. Rename the `AC-035` Crosshair `describe`; confirm the §8.3 disable tests now
   match `vitest --testNamePattern AC-035`.

**Rollback trigger:** the new test is green against the M2 mutant (does not kill
it), or any previously-green test in `controls.test.tsx` turns red.

### Acceptance criteria

- [ ] `grep -n 'fetch' tests/unit/runtime/controls.test.tsx` shows a CommandBar
  test stubbing `fetch`.
- [ ] `grep -n '__pinscope/history' tests/unit/runtime/controls.test.tsx`
  matches inside a CommandBar `describe`.
- [ ] `grep -n 'AC-035' tests/unit/runtime/controls.test.tsx` matches the
  formerly-untagged Crosshair §8.3 `describe`.
- [ ] `npm test` exits 0 with the new test green.

### Definition of Done

Closed when:

1. `tests/unit/runtime/controls.test.tsx` contains a CommandBar test that
   stubs `globalThis.fetch` with a spy and asserts the spy is called with the
   first argument `'/__pinscope/history'` and a request body parseable to
   `{ version, entries }`.
2. That test **kills mutant M2**: with the `CommandBar` guard transiently
   changed to `if (typeof fetch === 'function') return;` the test fails; with
   the real source it passes. (Verifier confirms via transient mutation.)
3. `grep -c 'AC-035' tests/unit/runtime/controls.test.tsx` ≥ 1 and the matched
   `describe` is the Crosshair §8.3 disable-conditions block — so
   `vitest --testNamePattern AC-035` now also runs the §8.3 guard tests.
4. `npm test` exits 0.

### Dependencies

- **Upstream:** R-16-01 (authored after it so the test can observe the live
  Flow-C `onSubmit` path; no file conflict — different files).
- **Downstream:** none.

### Risk assessment

- **Low.** Test-only change in one file. No source edit.
- **`fetch` stub leakage:** the stub must be restored in `afterEach`
  (`vi.restoreAllMocks` / explicit teardown) so it does not bleed into other
  `controls.test.tsx` tests. Covered by the rollback trigger.
- **Conflict matrix:** touches only `tests/unit/runtime/controls.test.tsx` —
  disjoint from R-16-01 and R-16-03.

---

## Remediation R-16-03

**id:** R-16-03
**Linked finding:** F-16-05, F-16-06, F-16-07
**Severity:** P3 (max of P3/P3/P3)
**Spec anchor:** §10 "D. Snapshot creation — … persist via dev-server endpoint
`/__pinscope/snapshot`"; §8.6 "History persisted to `.pinscope/history.json`
(last 1000)".
**Root cause:** Every route test in `tests/unit/plugin.test.ts` validates the
*on-disk* file (`fs.readFileSync` of `s_<id>.json` / `history.json`) and the
HTTP *status*, but never JSON-parses the HTTP *response body* — so the
`{ ok: true }` success flag of both routes is unasserted (mutants M3 and M5
`true → false` survive). Separately, every test builds its project root with a
single-level `fs.mkdtempSync`, so the `.pinscope/` parent already exists at
depth 1 and the `fs.mkdirSync(dir, { recursive: true })` recursion branch is
never exercised (mutant M4 `true → false` survives). Three carry-overs, one
root cause class: the `plugin.test.ts` route tests under-assert the HTTP
response and under-exercise the directory-creation path.

### Ecosystem analysis

1. *Code bug or coverage gap?* — Pure coverage gap for all three. The
   file write, the 1000-cap, the path-traversal guard are genuinely asserted;
   only the response-body `ok` flag and the recursive-mkdir branch are unchecked.
2. *Which mutants survive?* — M3 (`ok: true → false`, snapshot route), M5
   (`ok: true → false`, history route), M4 (`mkdirSync recursive: true →
   false`).
3. *What kills M3/M5?* — `postThrough` currently resolves only `{ status }`. It
   (or each test) must additionally capture the response body string; each route
   test then `JSON.parse`s it and asserts `parsed.ok === true` (and for history,
   `parsed.count`). With `ok: false` the assertion fails → mutant killed.
4. *What kills M4?* — A route test whose `projectRoot` is a **nested,
   not-yet-existing** path — e.g. `path.join(mkdtempSync(...), 'a', 'b', 'c')`
   that is **not** created on disk before the POST. With `recursive: true` the
   handler's `mkdirSync` creates the whole chain and the write succeeds (status
   200, file present); with `recursive: false` `mkdirSync` throws `ENOENT`, the
   `catch` answers 400, and the file is absent → mutant killed.
5. *Does `handleSnapshotRequest` reach the catch on `ENOENT`?* — Yes: the
   `mkdirSync`/`writeFileSync` calls are inside the `try` in the `req.on('end')`
   callback, so a thrown `ENOENT` is caught and answered 400. The nested-root
   test therefore distinguishes `recursive:true` (200 + file) from
   `recursive:false` (400 + no file).
6. *Is `src/plugin/index.ts` touched?* — No. The handlers already answer
   `{ ok: true, … }` and already pass `{ recursive: true }`. This R-item only
   adds assertions in the test file.
7. *Single test-file edit for all three?* — Yes. All three findings name
   `tests/unit/plugin.test.ts`; the response-body capture in `postThrough` plus
   added assertions plus one nested-root test close F-16-05, F-16-06, F-16-07
   together.

### Execution plan

**Files to modify:**
- `tests/unit/plugin.test.ts` — (a) extend the `postThrough` helper so its
  resolved object carries the response **body** string alongside `status`;
  (b) in the snapshot-route test (`describe` "snapshot dev-server route
  (R-15-06, §10-D)") `JSON.parse` the body and assert `ok === true`; (c) in
  both history-route tests (`describe` "history dev-server route (R-15-07,
  §8.6)") `JSON.parse` the body and assert `ok === true` (and `count`); (d) add
  one route test (snapshot or history) whose project root is a **nested,
  uncreated** directory, asserting status 200 + the file exists at the deep
  path — exercising the `recursive: true` branch.

**Files to create:** none.

**Files that MUST remain untouched:**
- `src/plugin/index.ts` — `handleSnapshotRequest`/`handleHistoryRequest` already
  emit `{ ok: true, … }` and already call `mkdirSync(dir, { recursive: true })`.
  No source change; this R-item closes coverage gaps, not behavior gaps.
- The on-disk-file assertions already in the existing route tests — keep them;
  add response-body assertions alongside, do not replace.

**Order of operations:**
1. Extend `postThrough` to capture the response body (the fake `res.end(body?)`
   already receives the body string — record it).
2. Add `ok` assertions to the existing snapshot + history route tests.
3. Add the nested-uncreated-root test for the `recursive: true` branch.

**Rollback trigger:** any previously-green `plugin.test.ts` test turns red, or
the new nested-root test passes against a transient `recursive: false` mutant.

### Acceptance criteria

- [ ] `grep -n 'ok' tests/unit/plugin.test.ts` shows `ok`-flag assertions in
  the snapshot and history route `describe` blocks.
- [ ] `postThrough` (or each route test) parses the HTTP response body, not
  only `result.status`.
- [ ] `grep -nE 'join\(.*,.*,.*\)' tests/unit/plugin.test.ts` (or equivalent)
  shows a nested project root that is not pre-created before the POST.
- [ ] `npm test` exits 0 with all `plugin.test.ts` tests green.

### Definition of Done

Closed when:

1. **F-16-05 closed:** the snapshot-route test in `tests/unit/plugin.test.ts`
   `JSON.parse`s the HTTP response body and asserts `parsed.ok === true`. Kills
   mutant M3: with `handleSnapshotRequest` transiently emitting `{ ok: false,
   id }` the test fails; with the real source it passes.
2. **F-16-06 closed:** the history-route test(s) `JSON.parse` the HTTP response
   body and assert `parsed.ok === true`. Kills mutant M5: with
   `handleHistoryRequest` transiently emitting `{ ok: false, count }` the test
   fails; with the real source it passes.
3. **F-16-07 closed:** a `plugin.test.ts` route test uses a project root that
   is a multi-level path **not created on disk** before the POST, and asserts
   status 200 + the snapshot/history file present at that deep path. Kills
   mutant M4: with `mkdirSync(dir, { recursive: false })` the test fails (400,
   no file); with `recursive: true` it passes.
4. `npm test` exits 0; all previously-green `plugin.test.ts` tests remain green.

### Dependencies

- **None.** Test-only change; independent of R-16-01 and R-16-02.

### Risk assessment

- **Low.** Test-only change in one file; no source edit.
- **`postThrough` shared helper:** extending its resolved shape must not break
  callers that destructure only `status` — additive only (add a `body` field).
  Covered by the rollback trigger (existing tests stay green).
- **Conflict matrix:** touches only `tests/unit/plugin.test.ts` — disjoint from
  R-16-01 (`src/runtime/*`) and R-16-02 (`controls.test.tsx`). Safe to
  wave-parallelize with R-16-01.
