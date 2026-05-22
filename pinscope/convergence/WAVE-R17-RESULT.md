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
