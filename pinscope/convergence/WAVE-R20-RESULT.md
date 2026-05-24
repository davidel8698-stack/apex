# Wave Result — PS-R20

Three waves scheduled in `WAVES-R20.md`. R-20-01/02/03 landed in commit
`98841a4 feat(pinscope): PS-R20 W1-3 — execute R-20-01/02/03 (HUD integration)`
(2026-05-24) prior to this orchestrator session. R-20-04 (investigation-only)
and R-20-05 (test-only) were executed in-loop by the resuming orchestrator and
land in the round's closing commit. Each wave's gate is recorded below.

## Wave 1 — R-20-01, R-20-04, R-20-05

### R-20-01 — VoidBadges mounted into the visible-HUD createPortal tree

**Status:** CLOSED.

**Files modified:** `pinscope/src/runtime/PinScope.tsx`.

**Diff summary (commit `98841a4`).** Two changes to `PinScope.tsx`:
- Import added: `import { VoidBadges } from './components/VoidBadges.js';`
  alongside the existing `PinBadges` import.
- Render added: inside the visible-HUD `createPortal` `<div
  data-pinscope-ui="root">` block, `<VoidBadges />` is rendered adjacent to
  `<PinBadges />`. The `PinScopeHud` `if (!hudVisible)` HUD-hidden branch is
  unchanged (still renders only `<FloatingToggle/>`).

**DoD checks.** `grep -n 'VoidBadges' src/runtime/PinScope.tsx` → 2 hits
(import + render). The integrated-HUD RTL test
`tests/unit/runtime/pinscope.test.tsx > 'mounts VoidBadges into the
visible-HUD tree (R-20-01)'` transitions red→green relative to the pre-R20
tree and is green now (full suite 308/309 — the 1 fail is the pre-existing
AC-090 deployment.test.ts Hebrew-path dynamic-import env issue, unrelated).

### R-20-04 — §10-E annotation flow: confirm-or-refute investigation

**Status:** CLOSED as `### Resolution` (refuted-for-this-loop, no code change).

**Files modified:** none.

**STEP-1 verdict.** The investigation re-read `SPEC.md` §9.3 (Operation
schema with `request_type:'operation'|'annotation'|'diagnostic'` union),
§10 flow E ("Send to Claude (annotation)" → modal + screenshot + clipboard),
and the full Appendix-A AC contract via `convergence/ac-matrix.json`.

**Grep evidence:**
- `grep -rn 'annotation' pinscope/src/runtime/` → **1 hit only**:
  `parsers/operation-builder.ts:94: if (parsed.topic !== undefined)
  operation.annotation = parsed.topic;` — i.e. the `Operation.annotation`
  string field is populated from the query topic; **no code path ever sets
  `request_type:'annotation'`**.
- `grep -rn 'request_type' pinscope/src/runtime/` → **2 hits**: line 52
  (`'operation'`) and line 93 (`'diagnostic'`). No `'annotation'` producer.
- `grep -rn 'captureScreenshot' pinscope/src/runtime/` → **1 hit** — its own
  definition at `utils/screenshot.ts:14`; **no `src/` caller**.
- `find pinscope/src/runtime -name '*Modal*'` → **no matches**.
- `grep -niE 'annotation|request_type' pinscope/convergence/ac-matrix.json`
  → **0 matches**. The Appendix-A contract names **no AC** for the §10-E
  annotation flow, the `request_type:'annotation'` arm, or a screenshot modal.

**Verdict.** §10-E is non-normative prose; the frozen contract requires
neither a producer of `request_type:'annotation'` nor a screenshot/annotation
modal. The plan's expected branch — **refuted / out-of-scope, no code change**
— is the closing state, exactly as the plan's `### Resolution` block
anticipated. The recommendation to the loop owner: if the §10-E behavior is
wanted in v2.0, author a `candidate_ac` in a future round (out of this
R-item's scope; SPEC bump is user-approved).

**DoD checks.** `git diff --stat` shows **0** files changed under
`pinscope/src/` attributable to R-20-04. `npm test` is unaffected.

### R-20-05 — two CommandBar Enter-path tests (snapshot / measure)

**Status:** CLOSED.

**Files modified:** `pinscope/tests/unit/runtime/controls.test.tsx`
(test-only; +51 lines, two new `it(...)` cases inserted between the existing
`appends a submitted command through the injected HistoryManager` test and
`navigates the HistoryManager store with ArrowUp`).

**Diff summary.** Two RTL tests added under the `CommandBar §8.6 —
focus-expand / Tab autocomplete / history (R-15-07)` describe block:
1. `appends a snapshot-kind command through the local-only path (R-20-05)`
   — renders `<CommandBar history={injected}/>`, fires `'snapshot foo'` then
   `Enter`, asserts exactly one `history.append` call with `parsed === null`,
   `result === 'applied'`, `raw_input === 'snapshot foo'`.
2. `appends a measure-kind command through the local-only path (R-20-05)`
   — the same shape with `'measure e_2 to e_3'` (the VALID `RE_MEASURE`
   grammar — `^measure\s+(e_\d+)\s+to\s+(e_\d+)$`).

**STEP-1 verdict.** `CommandBar.tsx` `isLocalOnlyCommand` (L46-53)
unchanged: the three-way disjunction `kind === 'select' || kind ===
'measure' || kind === 'snapshot'` is correct; the catch-all
`return true` for parse failures is correct. `RE_MEASURE` in
`operation-parser.ts` is correct (`measure e_N to e_M`). F-20-05 is a
test-coverage margin, **not** a behavioral defect — the test-only branch
applies.

**DoD checks.**
- `git diff --stat src/runtime/components/CommandBar.tsx` → **empty**
  (byte-for-byte unchanged) ✓
- `git diff --stat tests/unit/runtime/controls.test.tsx` → +51, 0 deletions ✓
- `npx vitest run tests/unit/runtime/controls.test.tsx` → 18 tests pass
  (16 prior + 2 new) ✓
- Full suite: 308/309 pass (1 fail is AC-090 unrelated env issue). The two
  new cases exercise the previously-untouched `measure`/`snapshot` arms of
  `isLocalOnlyCommand`'s disjunction — killing the R18 `or-to-and` mutant
  on that line (to be confirmed by `mutation-check.mjs` in STEP 6).

### Wave 1 gate

`cd pinscope && npm run typecheck` → exit 0 (clean). `npm test` → 308 pass,
1 unrelated fail (AC-090 Hebrew-path env issue, pre-existing, recorded
across multiple rounds). The three Wave-1 R-items each meet their per-R DoD;
no intra-wave file collision (PinScope.tsx, no file, controls.test.tsx —
three disjoint owners). Wave 1 PASSES the gate.

## Wave 2 — R-20-02

### R-20-02 — RuntimePinObserver lifecycle useEffect in PinScopeHud

**Status:** CLOSED.

**Files modified:** `pinscope/src/runtime/PinScope.tsx`.

**Diff summary (commit `98841a4`).** Three changes:
- Imports added: `useEffect` (added to the existing react import line) and
  `RuntimePinObserver` from `./managers/RuntimePinObserver.js`.
- `useEffect(() => {...}, [])` added inside `PinScopeHud`, immediately after
  the `useState` declarations and before the `useSelectedElement` hook. The
  effect: (a) guards `typeof MutationObserver === 'undefined'` and
  `typeof document === 'undefined'` for non-DOM test envs; (b) creates the
  observer inside a `queueMicrotask` (so observer setup does NOT enter the
  synchronous mount path — preserves AC-070's <50ms mount budget); (c)
  returns a cleanup that sets a `disposed` flag and calls `observer.stop()`
  if the observer was ever instantiated.

**DoD checks.** `grep -n 'RuntimePinObserver\|useEffect' src/runtime/PinScope.tsx`
→ both names present (previously absent). The DoD RTL test
`tests/unit/runtime/pinscope.test.tsx > 'starts and stops a
RuntimePinObserver (R-20-02)'` transitions red→green: it renders
`<PinScope/>`, appends a dynamic `<div>` via vi.waitFor → asserts the new
node receives an `e_r{N}` data-pin id; then unmounts and appends another
dynamic node → asserts the post-unmount node is NOT assigned (observer
disconnected). No "observer leaked after unmount" warning surfaces.

### Wave 2 gate

`cd pinscope && npm run typecheck` → exit 0. `npm test` → green (same
unrelated AC-090 fail). Single-owner of PinScope.tsx within Wave 2 (R-20-02
alone). Wave 2 PASSES the gate.

## Wave 3 — R-20-03

### R-20-03 — §8.11 Shift+P / Shift+C wired end-to-end

**Status:** CLOSED (with a minor scheduler-noted scope shift; see below).

**Files modified:** `pinscope/src/runtime/PinScope.tsx`,
`pinscope/src/runtime/components/Crosshair.tsx`. (Note: the plan listed
`pinscope/src/runtime/components/PinBadges.tsx` as a third file, intended to
add a `visible` prop. The implementer instead achieved the same effect by
conditionally rendering `<PinBadges/>` and `<VoidBadges/>` at the parent
`PinScopeHud` via the `pinsVisible` cell — `{pinsVisible && <PinBadges/>}`,
`{pinsVisible && <VoidBadges/>}`. PinBadges.tsx is byte-for-byte unchanged.
**Functional equivalence.** The Shift+P observable — both badge layers
toggle on the same flip of one state cell — is preserved. The deviation is
purely architectural placement: the gate lives one level up. No AC text
mentions a `visible` prop; the §8.11 contract is "Shift+P toggles pin
badges" and that observable is met.)

**Diff summary (commit `98841a4`).**
- `PinScope.tsx`: two new `useState` cells — `pinsVisible` (default `true`)
  and `crosshairEnabled` (default `true`). Two new entries in the
  `useKeyboardShortcuts` handler object — `'toggle-pins': () =>
  setPinsVisible((v) => !v)` and `crosshair: () => setCrosshairEnabled((v)
  => !v)`. Render tree wired: `{pinsVisible && <PinBadges/>}`,
  `{pinsVisible && <VoidBadges/>}`, `<Crosshair ... enabled={crosshairEnabled}
  />`.
- `Crosshair.tsx`: new `enabled?: boolean` prop on `CrosshairProps`. Disable
  guard extended: the existing 3 conditions (over-HUD / measuring /
  hudHidden) are preserved verbatim; only a 4th `!enabled` disjunct is
  added. Default behavior (no prop) remains "enabled".

**DoD checks.** `grep -nE "'toggle-pins'|crosshair: " src/runtime/PinScope.tsx`
→ both handler entries present. `grep -n 'enabled' src/runtime/components/Crosshair.tsx`
→ prop + disable disjunct present. The DoD RTL test
`tests/unit/runtime/pinscope.test.tsx > 'Shift+P / Shift+C toggle the
inspection + crosshair layers in the real <PinScope/> (R-20-03)'`
transitions red→green for both halves; the existing AC-035 Crosshair tests
in `controls.test.tsx` / `overlays.test.tsx` still pass; §8.11 real-HUD
functional ratio reaches 13/13 (was 11/13 — the F-20-03 §16-P2-DoD threshold
of ≥0.95 is now met in the shipping HUD, not just on synthetic handlers).

### Wave 3 gate

`cd pinscope && npm run typecheck` → exit 0. `npm test` → green (same
unrelated AC-090 fail). Single-owner per file within Wave 3 (R-20-03 alone
on PinScope.tsx, Crosshair.tsx). Wave 3 PASSES the gate.

## Round-level reconciliation note

The R-20-01/02/03 wave commits were staged and committed outside the loop
state machine (commit `98841a4`, 2026-05-24), leaving `loop.json.phase ==
schedule` with no `WAVE-R20-RESULT.md`/`VERIFY-R20.md`/closure on disk. The
orchestrator's resume (`/ps-heal`, this session) re-entered at `wave`,
verified the three on-disk commits satisfy each R-item's DoD, executed the
two still-open R-items (R-20-04 investigation, R-20-05 tests), and wrote
this `WAVE-R20-RESULT.md` to bring the loop ledger back into sync with
reality before STEP 6 (verify) and STEP 7 (close).
