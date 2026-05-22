# Remediation Plan — PS-R17

## Round summary

Round 17 audit input: the `spec-auditor` reported **3 open investigation
findings** (1 CONFIRMED, 2 SUSPECTED), **0 confirmed AC findings**, and **0
regressions**; 7 ACs are environment-BLOCKED (browser / apex-install
unavailable) and are not findings. The `narrative-auditor` `blocking_findings`
array is empty (0) — nothing planned from it; its 19 candidate ACs and 6
strengthen proposals are out-of-scope proposals. The STEP 1C test-quality audit
(`TEST-AUDIT-R17.md`) returned **WARN — advisory, non-blocking**, carrying 2
advisory items (AC-037 untested non-null `stateOverride` branch; AC-075 shallow
flat-tree perf bound); WARN raises no mandatory finding.

This plan routes **all 3 findings** — **F-17-01 → R-17-01**, **F-17-02 →
R-17-02**, **F-17-03 → R-17-03** — one R-item each. STEP 2 root-cause analysis
found **no shared root cause**: the three findings touch three different
mechanisms (duplicate `SelectionManager` ownership; a missing `flush()` await in
flow D; a never-lifted `StatePanel` override). F-17-01 and F-17-03 are
superficially similar ("two working pieces not connected") but the connecting
mechanism and the files differ, so they are *not* collapsed. **3 R-items · 0
shared-root groups.** The AC-037 advisory is folded into R-17-03's Definition of
Done as a side-effect resolution (the non-null `stateOverride` branch becomes
live and gets a test). The AC-075 advisory is standalone, shares no files with
any finding, and is left unaddressed (advisory-only, does not block
convergence). R-17-01 carries P2, R-17-02 P2, R-17-03 P3.

---

## Remediation R-17-01

**id:** R-17-01
**Linked finding:** F-17-01 (CONFIRMED)
**Severity:** P2
**Root cause:** `PinScopeHud` instantiates **two independent `SelectionManager`
objects** — one private inside `useSelectedElement`, one as `command.selection`
in the `command` `useMemo`. The §11 `select e_N` command writes the orphan
`command.selection` manager, whose state feeds nothing; the InfoPanel `selected`
React state is sourced only from the hook's manager. The defect is duplicated,
unshared ownership of selection state, not a missing feature.
**Spec anchor:** "click → `SelectionManager.select` → `data-pin-selected`
attribute moved → URL hash updated → InfoPanel locks" (§10-B) and `"select"
Target` as a first-class grammar form (§11).

### Ecosystem analysis
1. Where does the InfoPanel's lock come from? `PinScope.tsx` — `const { selected
   } = useSelectedElement(measuring)`, rendered as `<InfoPanel hovered={selected
   ?? hovered} ...>`. Only the hook's manager drives it.
2. What writes `command.selection`? Exactly one site: the `if (parsed.kind ===
   'select')` branch in `onSubmit` calls `command.selection.select(parsed.pin)`.
3. What reads `command.selection`? Nothing — confirmed by the finding's
   `re_read` grep.
4. Does `useSelectedElement` accept an injected manager today? No — it
   unconditionally does `new SelectionManager()` in its `managerRef` lazy init.
5. Does a `[data-pin]` click still need to lock? Yes — §10-B click path must
   keep working; this R-item must not regress it.
6. Does `select` need to update the React `selected` state? Yes — that is the
   InfoPanel-lock trigger; moving the attribute + hash is insufficient.
7. Is the URL-hash / `data-pin-selected` side effect already correct on the
   command path? Yes — `SelectionManager.select` does both; only the React
   state bridge is missing.
8. Can the hook expose a programmatic `select`? It already returns `{ selected,
   clear }`; adding a `select(pinId)` to that surface is the natural seam.
9. Does measurement mode interaction change? No — `select` command is a HUD
   action; `measuring` only suppresses the *click* listener, not a command.
10. Any SSR concern? `resolveSelected` already guards `typeof document` — reuse
    it; no new SSR branch needed.

### Execution plan
**Files to modify:**
- `src/runtime/hooks/useSelectedElement.ts` — the `useSelectedElement` hook.
  Make the single owned `SelectionManager` the *sole* manager, and expose a
  programmatic `select(pinId: string)` on the returned `SelectedElement` object
  that calls `manager.select(pinId)` then `setSelected(resolveSelected(pinId))`
  — mirroring exactly what the existing `onClick` handler does for a pinned
  target. Extend the `SelectedElement` interface with the new `select` member.
- `src/runtime/PinScope.tsx` — the `command` `useMemo` and the `onSubmit`
  `select` branch. Remove `selection: new SelectionManager()` from the `command`
  object (it is the orphan instance). In `onSubmit`, the `if (parsed.kind ===
  'select')` branch must call the hook-exposed `select` instead of
  `command.selection.select`. Destructure the new member at the
  `useSelectedElement` call site (`const { selected, select: selectPin } =
  useSelectedElement(measuring)`).

**Files to create:** none.

**Files that MUST remain untouched:**
- `src/runtime/managers/SelectionManager.ts` — the manager class is correct as
  written (`select` already moves the attribute and syncs the hash). Do not
  alter its public surface.
- The `[data-pin]` `click` handler inside `useSelectedElement`'s `useEffect` —
  its pinned-target / click-outside / Escape behavior must be preserved
  verbatim; only the *new* exported `select` is added alongside it.
- The `measuring` early-return in the click handler.

**Order of operations:**
1. In `useSelectedElement.ts`, add the `select` member to the `SelectedElement`
   interface and implement it next to the existing `clear` closure, reusing
   `resolveSelected`.
2. In `PinScope.tsx`, drop the `selection` key from the `command` `useMemo`
   return object.
3. In `PinScope.tsx`, change the `select` branch of `onSubmit` to call the
   hook-provided `selectPin(parsed.pin)`; add `selectPin` to the `onSubmit`
   `useCallback` dependency array.
4. Update the `useSelectedElement` destructure at its call site.

**Rollback trigger:** if, after the change, a `[data-pin]` click no longer locks
the InfoPanel (the pre-existing flow-B click path regresses) — revert and
re-plan.

### Acceptance criteria
- [ ] `grep -rn 'new SelectionManager' src` returns **exactly one** match
      (the lazy `managerRef` init in `useSelectedElement.ts`); the
      `PinScope.tsx` `command.selection` instantiation is gone.
- [ ] `grep -n 'command\.selection' src/runtime/PinScope.tsx` returns **0**
      matches.
- [ ] `grep -n 'selection:' src/runtime/PinScope.tsx` does not match inside the
      `command` `useMemo`.
- [ ] `useSelectedElement`'s returned object exposes a `select` function
      (`grep -n 'select' src/runtime/hooks/useSelectedElement.ts` shows it on
      both the `SelectedElement` interface and the return statement).
- [ ] The `select` branch of `onSubmit` invokes the hook-exposed selector
      (`grep -n` over `PinScope.tsx` shows the `select` branch no longer names
      `command.selection`).

### Definition of Done
Add (or extend) a test in `tests/unit/runtime/selection.test.ts` —
named test case **"the `select e_N` command locks the InfoPanel"** — that:
mounts the real `<PinScope/>`, types `select e_2` into the CommandBar and
submits it, then asserts the InfoPanel reflects pin `e_2` (the
`[data-state-override]`-independent InfoPanel content shows `e_2`, equivalently
the element carrying `data-pin-selected` is `e_2`) **without any prior click on
a `[data-pin]` element**. This test must transition **red → green**: red against
current `main` (the command does not lock), green after R-17-01.
R-17-01 is closed when:
1. that named test passes, AND
2. `npm test` is green with no other suite regressed (the existing flow-B click
   lock test in `selection.test.ts` still passes), AND
3. the two `grep` predicates above (`new SelectionManager` count == 1,
   `command.selection` count == 0) both hold.

### Dependencies
None. R-17-01 touches `useSelectedElement.ts` and `PinScope.tsx`; R-17-02 and
R-17-03 also touch `PinScope.tsx` but different anchors (the `onSnapshot`
callback and the `<TopBar>` JSX respectively) — see the conflict note in
R-17-03. No ordering constraint.

### Risk assessment
**Low–medium.** The fix removes a dead instance and routes one command through
an existing, tested code path (the hook's `select`/`setSelected` pair already
backs the click flow). Main risk: the `onSubmit` `useCallback` dependency array
must gain `selectPin` or the closure goes stale — covered by an explicit step.
No public API or `SelectionManager` surface change, so no cross-file drift. The
URL-hash and `data-pin-selected` side effects are unchanged because they live in
`SelectionManager.select`, which both paths now share.

---

## Remediation R-17-02

**id:** R-17-02
**Linked finding:** F-17-02 (SUSPECTED — investigation R-item)
**Severity:** P2
**Root cause:** Flow D's wiring (`onSnapshot` in `PinScope.tsx`) calls
`SnapshotManager.capture()` but never `flush()`es the `EndpointSnapshotStore`.
`EndpointSnapshotStore.write` is synchronous and stashes the persist promise in
`pending`; `flush()` is the *only* way to observe a `SnapshotPersistError`. Flow
C deliberately `.catch()`es its `ClaudeBridge.send` promise ("never swallow");
flow D omits the equivalent observation step, so a failed persist becomes an
unhandled rejection. Root cause: flow D is missing the error-observation step
flow C has.
**Spec anchor:** "Snapshot creation — `Shift+S` → walk all pins → build Snapshot
→ persist via dev-server endpoint `/__pinscope/snapshot` → **toast**" (§10-D).

### STEP 1 — Confirm or refute (mandatory first step, SUSPECTED finding)
Confirm against the **frozen** SPEC and current code before fixing:
- `grep -n 'flush' src/runtime/PinScope.tsx` → expect **0 matches** (confirms
  `onSnapshot` never flushes).
- Re-read `EndpointSnapshotStore` — its docstring states `flush()` exists "so
  callers (and tests) can observe a failed persist instead of a silently
  swallowed one"; `post()` throws a typed `SnapshotPersistError` on network
  error or non-OK response. Confirms the failure signal is real and lost.
- Re-read the `onSubmit` flow-C branch — `void command.bridge.send(...).catch(...)`
  with the "never swallow" comment. Confirms flow C observes; flow D does not.
- §10-D's "→ toast" terminus confirms a *user-visible* failure signal is
  spec-mandated, so swallowing is a genuine gap, not a benign omission.
If STEP 1 instead shows `onSnapshot` already awaits/`.catch()`es a `flush()`,
this R-item closes as a **`### Resolution` — false finding** with the grep as
proof. Expectation per the audit `re_read`: the finding **CONFIRMS**.

### Ecosystem analysis
1. What does `onSnapshot` do today? `command.snapshots.capture(name)` — and
   nothing else; the returned `Snapshot` and any persist failure are dropped.
2. How is a persist failure surfaced? Only via `EndpointSnapshotStore.flush()`,
   which returns the `pending` promise that rejects with `SnapshotPersistError`.
3. Does `SnapshotManager` expose the store? Not directly — `capture()` calls
   `store.write()` internally; `flush()` lives on `EndpointSnapshotStore`. The
   wiring needs a handle to the store, or `SnapshotManager` must forward `flush`.
4. How does flow C surface its failure? `console.warn('[pinscope] operation
   send failed', err)` inside a `.catch`. Flow D should mirror this shape — a
   console signal at minimum (the §10-D "toast" is the richer form; a
   console.warn is the established in-repo convention for flow C and is the
   minimum that removes the *swallowed*-error defect).
5. Is the snapshot itself still built/written on failure? Yes — only the
   *failure signal* is lost; the fix adds the signal, it does not change the
   capture.
6. Does a test seam exist? `tests/unit/runtime/snapshot.test.tsx` already
   stubs `fetch` and asserts `store.flush()` rejects on a non-OK response — the
   store-level behavior is covered; the *root-wiring* observation is not.
7. Both `onSnapshot` call sites (TopBar button, `Shift+S` shortcut) route
   through the same `onSnapshot` callback — fixing it once covers both.
8. SSR concern? `onSnapshot` runs only from a user action inside a mounted HUD;
   no SSR path.

### Execution plan
**Files to modify:**
- `src/runtime/PinScope.tsx` — the `onSnapshot` `useCallback` (the `§10-D — walk
  all pins …` block). After `command.snapshots.capture(name)`, observe the
  persist: obtain the `EndpointSnapshotStore` `flush()` promise and `.catch()`
  it with a `console.warn('[pinscope] snapshot persist failed', err)` — the
  same swallow-prevention shape as the flow-C `bridge.send().catch(...)`.
- To get a `flush` handle, either (a) keep a reference to the
  `EndpointSnapshotStore` instance in the `command` `useMemo` alongside
  `snapshots`, or (b) add a `flush()` passthrough to `SnapshotManager` that
  delegates to its store when the store exposes one. Choose (a) if it is the
  smaller diff; (b) if `SnapshotManager` is the cleaner seam — either satisfies
  the DoD. Whichever is chosen, `onSnapshot` must end in an observed
  (`.catch`-ed or `await`-ed-in-try/catch) `flush()`.

**Files to create:** none.

**Files that MUST remain untouched:**
- `src/runtime/managers/EndpointSnapshotStore.ts` — `write`/`flush`/`post` are
  correct as written; `flush()` already returns the rejectable `pending`
  promise. Do not change its error semantics.
- The flow-C `onSubmit` branch — its `.catch` is the reference pattern, not a
  thing to edit.
- `createSnapshot` / `snapshotElement` in `SnapshotManager.ts` — the snapshot
  *building* is not in scope; only the persist-failure observation is.

**Order of operations:**
1. Run the STEP 1 grep/re-read; record CONFIRM (or write a `### Resolution` and
   stop).
2. Ensure `onSnapshot` can reach a `flush()` — via the `command` `useMemo`
   store reference (option a) or a `SnapshotManager.flush()` passthrough
   (option b).
3. In `onSnapshot`, after `capture()`, attach an observed `.catch()` on the
   `flush()` promise that `console.warn`s the failure — never swallow.
4. Keep `onSnapshot`'s `useCallback` dependency array correct for any new
   captured value.

**Rollback trigger:** if a successful snapshot now logs a spurious failure
warning (false-positive signal), or `onSnapshot` throws synchronously — revert
and re-plan.

### Acceptance criteria
- [ ] `grep -n 'flush' src/runtime/PinScope.tsx` returns **≥ 1** match inside
      the `onSnapshot` callback (currently 0).
- [ ] The `flush()` promise in `onSnapshot` is observed — a `.catch(` or an
      `await` in a `try`/`catch` — not a bare `flush()` call. `grep` over the
      `onSnapshot` block shows `catch` adjacent to the `flush`.
- [ ] A `console.warn` with a `'[pinscope]'`-prefixed snapshot-failure message
      is present in the `onSnapshot` failure path (mirrors the flow-C
      `'[pinscope] operation send failed'` convention).
- [ ] `EndpointSnapshotStore.ts` is unchanged (`git diff --stat` shows no edit
      to that file).

### Definition of Done
Add a test in `tests/unit/runtime/flow-wiring.test.tsx` —
named **"Flow D — a failed snapshot persist is surfaced, never swallowed"** —
that: mounts the real `<PinScope/>`, stubs `globalThis.fetch` to resolve a
non-OK response (`{ ok: false, status: 500 }`), spies on `console.warn`,
triggers a snapshot (clicks the `data-pinscope-snapshot-btn` **or** dispatches
the `Shift+S` shortcut), awaits microtask settlement, and asserts
`console.warn` was called with a `'[pinscope]'`-prefixed snapshot-failure
message **and** that no unhandled rejection occurred. This test must transition
**red → green**: red on current `main` (the rejection is unhandled, no warn),
green after R-17-02.
R-17-02 is closed when:
1. that named test passes, AND
2. `npm test` is green, the two existing `EndpointSnapshotStore` `flush()`
   tests in `snapshot.test.tsx` still pass, AND
3. `grep -n 'flush' src/runtime/PinScope.tsx` returns ≥ 1 match and the
   `EndpointSnapshotStore.ts` diff is empty.

### Dependencies
None. Touches `PinScope.tsx` (`onSnapshot` block, and optionally the `command`
`useMemo`) — disjoint anchors from R-17-01 and R-17-03. No ordering constraint.

### Risk assessment
**Low.** The fix adds an observation step to an existing promise; it does not
change snapshot building or the store's error semantics. The reference pattern
(flow C's `.catch`) is already in the same file. Main risk: choosing the
`flush` handle — option (a) reuses the existing `command` `useMemo`, the
smallest diff and the recommended default; option (b) widens `SnapshotManager`'s
surface and would need its own narrow test. The finding is SUSPECTED, so STEP 1
must run first — if it refutes, this becomes a `### Resolution` with zero code
change.

---

## Remediation R-17-03

**id:** R-17-03
**Linked finding:** F-17-03 (SUSPECTED — investigation R-item)
**Severity:** P3
**Root cause:** `PinScope.tsx` renders `<TopBar ... stateOverride={null} />` — a
hardcoded constant — while the real §8.8 selector, `StatePanel`, owns its
override in a *component-local* `useState` that is never lifted into
`PinScopeHud`. The TopBar's `data-field="state"` span therefore always reads
`state: none`. Root cause: `StatePanel`'s override state is local, not lifted to
the common `PinScopeHud` parent that also renders `TopBar`.
**Spec anchor:** "**8.5 TopBar** — `fixed; top:0; height:32px`. … **state-
override selector** …" (§8.5) and "**8.8 StatePanel** — forces global state via
`[data-state-override]` on `<html>`" (§8.8).

### STEP 1 — Confirm or refute (mandatory first step, SUSPECTED finding)
Confirm against the **frozen** SPEC and current code before fixing:
- `grep -n 'stateOverride={null}' src/runtime/PinScope.tsx` → expect **1 match**
  (the hardcoded prop).
- `grep -n 'data-field="state"' src/runtime/components/TopBar.tsx` → the span
  renders `state: {stateOverride ?? 'none'}`; with a constant `null` it is
  permanently `none`.
- Re-read `StatePanel` — its override lives in `const [state, setState] =
  useState<StateOverride>('none')`, local to `StatePanel`; `applyStateOverride`
  writes `<html data-state-override>` but nothing reports the value upward.
- §8.5 lists a "state-override selector" *in the TopBar*; §8.8 owns the actual
  override mechanism. Confirms the TopBar readout is meant to reflect the live
  override and currently cannot.
If STEP 1 instead shows the TopBar already receives a live override value, this
R-item closes as a **`### Resolution` — false finding**. Expectation per the
audit `re_read`: the finding **CONFIRMS** (cosmetic staleness).

### Ecosystem analysis
1. Who renders both `TopBar` and `StatePanel`? `PinScopeHud` — they are sibling
   children of the same portal `<div data-pinscope-ui="root">`. The common
   parent is the natural place to own the override state.
2. What state shape does the readout need? `StateOverride` (`'none' | 'hover' |
   'focus' | 'active'`) exported by `StatePanel.tsx`. `TopBar`'s
   `stateOverride` prop is typed `string | null`; `StateOverride` is assignable.
3. Does `StatePanel` expose its current state? Not today — it holds a private
   `useState`. It needs an `onChange`/`onStateChange` callback prop so the
   parent can mirror the value, OR `PinScopeHud` lifts the state and passes
   `state` + `onChange` down (controlled `StatePanel`).
4. Does the §8.8 mechanism change? No — `applyStateOverride` keeps writing
   `<html data-state-override>`; only the *reporting* of the chosen state is
   added. The `[data-state-override]` behavior must not regress.
5. What does the TopBar do with `'none'`? `stateOverride ?? 'none'` already
   renders `none` for a `'none'` value too — passing the live `'none'` state is
   equivalent to today's display when nothing is overridden; only `hover`/
   `focus`/`active` change the readout.
6. Is `TopBar`'s prop type wide enough? `string | null` accepts every
   `StateOverride` member; no `TopBar` type change is required (passing the
   `StateOverride` string satisfies it).
7. AC-037 overlap (TEST-AUDIT-R17): the AC-037 test renders `TopBar` only with
   `stateOverride={null}`; the non-null branch is never exercised. R-17-03's DoD
   below requires a test of the now-live non-null path — this resolves the
   AC-037 advisory as a side effect.
8. SSR concern? State lifting is pure React; no new SSR branch.

### Execution plan
**Files to modify:**
- `src/runtime/components/StatePanel.tsx` — the `StatePanel` component. Add an
  optional callback prop (e.g. `onStateChange?: (state: StateOverride) => void`)
  invoked inside `choose` after `setState`/`applyStateOverride`, so the parent
  learns the chosen override. (Equivalently make `StatePanel` controlled — but
  the callback is the smaller, lower-risk diff and keeps `StatePanel` usable
  standalone.)
- `src/runtime/PinScope.tsx` — `PinScopeHud`. Add a `stateOverride` `useState`
  (initial `'none'`). Pass `onStateChange={setStateOverride}` to `<StatePanel>`.
  Replace the hardcoded `stateOverride={null}` on `<TopBar>` with the live
  `stateOverride` state value.

**Files to create:** none.

**Files that MUST remain untouched:**
- `applyStateOverride` and `generateOverrideRules` in `StatePanel.tsx` — the
  §8.8 attribute/stylesheet mechanism is correct; only `StatePanel`'s render and
  the new callback are added. The `<html data-state-override>` write must be
  byte-for-byte preserved.
- `TopBar.tsx` — `TopBar` already renders `state: {stateOverride ?? 'none'}`
  correctly; its `string | null` prop accepts a `StateOverride`. **Do not edit
  `TopBar.tsx`** — the fix is purely in the data feeding the existing prop.

**Order of operations:**
1. Run the STEP 1 grep/re-read; record CONFIRM (or write a `### Resolution` and
   stop).
2. In `StatePanel.tsx`, add the optional `onStateChange` prop and invoke it in
   `choose`.
3. In `PinScope.tsx`, add the `stateOverride` `useState` to `PinScopeHud`.
4. In `PinScope.tsx`, wire `onStateChange={setStateOverride}` onto `<StatePanel>`
   and replace `stateOverride={null}` on `<TopBar>` with the state value.

**Rollback trigger:** if forcing a state via the StatePanel no longer sets
`<html data-state-override>` (the §8.8 mechanism regresses), or the TopBar state
field stops rendering — revert and re-plan.

### Acceptance criteria
- [ ] `grep -n 'stateOverride={null}' src/runtime/PinScope.tsx` returns **0**
      matches (the hardcoded constant is gone).
- [ ] `<TopBar>` in `PinScope.tsx` is passed the `stateOverride` *state value*
      (`grep -n 'stateOverride'` over `PinScope.tsx` shows a `useState`
      declaration and the prop bound to it, not a literal `null`).
- [ ] `StatePanel` accepts an `onStateChange` (or equivalent) callback prop
      and invokes it (`grep -n 'onStateChange' src/runtime/components/StatePanel.tsx`
      matches the prop type and the call in `choose`).
- [ ] `src/runtime/components/TopBar.tsx` is unchanged (`git diff --stat` shows
      no edit to `TopBar.tsx`).
- [ ] `applyStateOverride`'s `<html data-state-override>` write is unchanged.

### Definition of Done
Add a test in `tests/unit/runtime/controls.test.tsx` —
named **"TopBar reflects the live StatePanel override"** — that: mounts the
real `<PinScope/>` (or `PinScopeHud`), clicks the `data-state-btn="hover"`
button in the StatePanel, and asserts the TopBar `[data-field="state"]` span
text contains `hover` (not `none`). This single test exercises the **now-live
non-null `stateOverride` branch**, which simultaneously resolves the AC-037
TEST-AUDIT-R17 advisory ("the non-null `stateOverride` branch is never
exercised"). This test must transition **red → green**: red on current `main`
(TopBar always shows `none`), green after R-17-03.
R-17-03 is closed when:
1. that named test passes, AND
2. `npm test` is green — the existing AC-037 TopBar test and the AC-040
   StatePanel `data-state-override` test in `controls.test.tsx` still pass, AND
3. `grep -n 'stateOverride={null}' src/runtime/PinScope.tsx` returns 0 and the
   `TopBar.tsx` diff is empty.

### Dependencies
None functionally. **File-conflict note:** R-17-01, R-17-02, and R-17-03 all
edit `src/runtime/PinScope.tsx`, but at disjoint anchors — R-17-01 the `command`
`useMemo` + the `onSubmit` `select` branch, R-17-02 the `onSnapshot` callback,
R-17-03 the `PinScopeHud` `useState` block + the `<StatePanel>`/`<TopBar>` JSX.
If executed in the same wave, `ps-scheduler` must serialize the three
`PinScope.tsx` edits (intra-file serialization by anchor); they do not conflict
semantically.

### Risk assessment
**Low.** Standard React state lifting; the §8.8 mechanism (`applyStateOverride`)
is untouched, so no behavioral regression to the override itself. `TopBar.tsx`
is not edited at all — its prop already renders correctly. The finding is
SUSPECTED and P3 (cosmetic staleness), so STEP 1 runs first; if refuted this is
a `### Resolution` with no code change. The only cross-cutting risk is the
shared `PinScope.tsx` file, addressed by the serialization note above.
