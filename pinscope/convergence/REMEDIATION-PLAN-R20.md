# Remediation Plan — PS-R20

**Round summary.** The R20 audit recorded **0 AC findings** and **0 narrative
blocking findings**; all 5 items are free-investigation findings from
`audit-findings-R20.json`: **3 CONFIRMED P2** (F-20-01, F-20-02, F-20-03) and
**2 SUSPECTED P3** (F-20-04, F-20-05). Each maps to exactly one R-item
(`R-20-01` … `R-20-05`); nothing is dropped.

**Shared-root-cause group (1).** F-20-01, F-20-02 and F-20-03 share a single
root cause: `PinScopeHud` in `src/runtime/PinScope.tsx` was authored as a
*pure-render* component — it has **zero `useEffect`** and wires only the 9
state-mutating shortcut handlers it needs for its own `useState` cells. Every
HUD mechanism that is *imperative* rather than *declarative-render* — the
JS-overlay `VoidBadges` layer, the `RuntimePinObserver` MutationObserver, and
the `toggle-pins`/`crosshair` shortcut handlers (which need a visibility cell +
prop to act on) — was therefore never connected. The components are correct;
their **integration into the live `<PinScope/>` tree** is the missing piece.
Their ACs (AC-024, AC-025, AC-043) pass only because each verify method
exercises the unit in isolation (direct render / direct construction /
synthetic-handler dispatch), masking the dead end-to-end wiring. **They are
planned as three R-items but executed as one coherent change to `PinScope.tsx`
(plus the two prop additions F-20-03 needs); R-20-01/02/03 share Wave 1 and
serialize on the `PinScopeHud` body.** F-20-04 and F-20-05 are independent
SUSPECTED items with their own root causes — investigation R-items.

This plan is READ-ONLY analysis; it edits no code. The North-Star
`pinscope/SPEC.md` is frozen — every fix below targets reality.

---

## Remediation R-20-01

**Linked finding:** F-20-01
**Severity:** P2
**Spec anchor:** "JS-overlay path for void elements; a MutationObserver detects
new void elements at runtime" (§7.2); AC-024 "void elements (img,input,br)
receive a JS-overlay badge positioned over them"
**Root cause:** `PinScopeHud`'s HUD `createPortal` tree (the `<div
data-pinscope-ui="root">` block) renders 10 components but never lists
`<VoidBadges/>`. `VoidBadges.tsx` is a complete, correct component with zero
`src/` consumers — dead code from the runtime's perspective. The shared
root cause is `PinScopeHud` being a pure-render shell that never grew its
inspection layer past the CSS-`::before` path; `PinBadges.tsx`'s own docblock
("The JS-overlay path for void elements ... is deferred") records the omission.

### Ecosystem analysis
1. What renders void-element badges today? Nothing in the shipped HUD —
   `PinBadges` injects only the CSS `::before` style block, and `::before`
   does not render on void elements (`img`/`input`/`br`/`hr`/`area`/`embed`).
2. Does the JS-overlay component exist? Yes — `src/runtime/components/VoidBadges.tsx`
   exports `VoidBadges`, collecting one `position:fixed` overlay div per void
   `[data-pin]` element, keyed by pin id, at `Z_BADGE`.
3. Why does AC-024 still PASS? `tests/unit/runtime/overlays.test.tsx` renders
   `<VoidBadges/>` directly — it never asserts the component is in the
   `<PinScope/>` tree.
4. Where must the fix land? The visible-branch `createPortal` tree of
   `PinScopeHud` in `PinScope.tsx` (the block opening `<div
   data-pinscope-ui="root">` that contains `<PinBadges />`, `<Rulers />` …).
5. Is `VoidBadges` self-sufficient once mounted? Yes — it reads the DOM in its
   own `useEffect` and needs no props.
6. Does this interact with R-20-03 (pin visibility)? Yes — if Shift+P pin
   visibility is added, void badges should hide with the CSS badges. R-20-03
   covers that wiring; R-20-01 only mounts the component.
7. Sync-strategy? N/A — no new `framework/` file; pinscope is not part of the
   `framework/` → `~/.claude/` build.
8. Does mounting it twice (HUD-hidden branch) matter? No — only the
   visible-HUD branch renders the inspection layer; the HUD-hidden branch
   renders solely `FloatingToggle` and stays untouched.

### Execution plan
**Files to modify:** `src/runtime/PinScope.tsx` — (a) add a `VoidBadges` import
alongside the existing `import { PinBadges } from './components/PinBadges.js'`
line; (b) in the visible-HUD `createPortal` tree (the `<div
data-pinscope-ui="root">` block containing `<PinBadges />`), render
`<VoidBadges />` adjacent to `<PinBadges />`.
**Files to create:** none.
**Files that MUST remain untouched:** `src/runtime/components/VoidBadges.tsx` —
the component is correct as-is; do not alter its `VOID_TAGS` set, its `collect()`
logic, or its `useEffect`. The HUD-hidden branch of `PinScopeHud` (the `if
(!hudVisible)` block rendering only `<FloatingToggle/>`) must stay rendering
only `FloatingToggle`.
**Order of operations:** 1. add the import. 2. add `<VoidBadges />` to the
visible-HUD tree. (Serialize within Wave 1 after R-20-02/R-20-03 edits to the
same `PinScopeHud` body, or land all three as one edit.)
**Rollback trigger:** `npm run typecheck` or `npm test` (the
`tests/unit/runtime/pinscope.test.tsx` suite) goes red after the edit.

### Acceptance criteria
- [ ] `grep -nE '<VoidBadges' pinscope/src/runtime/PinScope.tsx` returns a hit
      inside the visible-HUD `createPortal` tree.
- [ ] `grep -rn 'VoidBadges' pinscope/src/` shows at least two files —
      `VoidBadges.tsx` (definition) and `PinScope.tsx` (consumer).
- [ ] `cd pinscope && npm run typecheck` exits 0.
- [ ] `cd pinscope && npm test` stays green (303+ tests pass, 0 fail).

### Definition of Done
A new RTL test in `tests/unit/runtime/pinscope.test.tsx` (or `overlays.test.tsx`)
seeds `document.body` with a void `[data-pin]` element
(`<img data-pin="e_9">`), renders `<PinScope/>`, and asserts
`document.querySelector('[data-pinscope-void-badges]')` is non-null AND a
`[data-void-badge="e_9"]` element exists inside the
`[data-pinscope-ui="root"]` portal. This test must transition **red → green**
across the fix: red against current `main` (VoidBadges unmounted), green after.
R-20-01 is closed when that named test is green and `npm test` reports 0
failures.

### Dependencies
Shares the `PinScope.tsx` file with R-20-02 and R-20-03 (same Wave, same
`PinScopeHud` body — serialize the edits or apply as one). No dependency on the
SUSPECTED items.

### Risk assessment
**Low.** `VoidBadges` is a self-contained, already-tested component; mounting
it adds one DOM-reading `useEffect`. Risk: the new overlay layer could overlap
the CSS-`::before` badges visually for non-void elements — mitigated because
`VoidBadges.collect()` filters to `VOID_TAGS` only, so it emits nothing for
elements `PinBadges` already labels. No schema, no build-pipeline, no
production-output surface touched (PinScope is stripped from prod builds).

---

## Remediation R-20-02

**Linked finding:** F-20-02
**Severity:** P2
**Spec anchor:** "Dynamic content (MutationObserver assigns `e_r{N}` runtime
IDs)" (§12); AC-025 "a MutationObserver assigns `e_r{N}` IDs to elements added
at runtime"
**Root cause:** Same shared root cause as R-20-01 — `PinScopeHud` is a
pure-render component with **zero `useEffect`**, so the `RuntimePinObserver`
class (a lifecycle-bound MutationObserver that must be `.start()`ed on mount
and `.stop()`ed on unmount) was never instantiated. `RuntimePinObserver.ts` has
zero `src/` consumers; it is dormant code. AC-025 passes only because
`edge-cases.test.ts` constructs `new RuntimePinObserver()` and calls `.start()`
directly.

### Ecosystem analysis
1. What assigns `e_r{N}` ids to runtime-added DOM today? Nothing in the shipped
   HUD — `PinScope.tsx` has no `useEffect` and never imports
   `RuntimePinObserver`.
2. Does the observer class exist and work? Yes —
   `src/runtime/managers/RuntimePinObserver.ts` exports `RuntimePinObserver`
   with `start()`, `stop()`, `assign()`; `start()` is idempotent (early-returns
   if `this.observer` is set) and `assign()` skips elements that already carry
   a `[data-pin]`.
3. Why must this be a `useEffect`? A MutationObserver is a side effect with a
   lifecycle — it must start after mount and disconnect on unmount to avoid a
   leaked observer. `PinScopeHud` currently has none.
4. Where does the observer start belong? Inside `PinScopeHud`, in a new
   `useEffect` with an empty dependency array, whose cleanup calls `.stop()`.
5. What does it observe? Default `document.body` — matches
   `RuntimePinObserver.start()`'s default `root` argument.
6. Does it conflict with the `useHoveredElement` rAF or other effects?
   No — it is an independent observer; the only shared concern is unmount
   cleanup, which `.stop()` handles.
7. SSR safety? `PinScopeHud` already early-returns when `typeof document ===
   'undefined'`; the `useEffect` body runs only client-side anyway, but the
   effect should still guard `typeof MutationObserver !== 'undefined'` for
   non-DOM test envs.
8. Sync-strategy? N/A — no new `framework/` file.

### Execution plan
**Files to modify:** `src/runtime/PinScope.tsx` — (a) add a `RuntimePinObserver`
import alongside the other `./managers/` imports (`ClaudeBridge`,
`SnapshotManager`, …); (b) inside `PinScopeHud`, add a new `useEffect` (empty
dependency array) that constructs a `RuntimePinObserver`, calls `.start()`, and
returns a cleanup that calls `.stop()`. Add `useEffect` to the existing
`import { useCallback, useMemo, useState } from 'react'` line.
**Files to create:** none.
**Files that MUST remain untouched:** `src/runtime/managers/RuntimePinObserver.ts`
— the class is correct; do not change its `counter`, `e_r${...}` id format, or
`observe` options. The `useMemo` command-primitives block and the
`useKeyboardShortcuts` call in `PinScopeHud` must keep their current behavior.
**Order of operations:** 1. add the `RuntimePinObserver` and `useEffect`
imports. 2. add the `useEffect` that `start()`s on mount and `stop()`s on
cleanup. (Serialize within Wave 1 with R-20-01/R-20-03 — same `PinScopeHud`
body.)
**Rollback trigger:** `npm run typecheck` red, or `npm test` red, or a
React "observer leaked after unmount" warning surfaces in the test run.

### Acceptance criteria
- [ ] `grep -nE 'RuntimePinObserver' pinscope/src/runtime/PinScope.tsx` returns
      a hit (import + construction).
- [ ] `grep -nE 'useEffect' pinscope/src/runtime/PinScope.tsx` returns at least
      one hit (today it returns none).
- [ ] `grep -rn 'RuntimePinObserver' pinscope/src/` shows at least two files —
      the definition and `PinScope.tsx`.
- [ ] The new `useEffect` returns a cleanup that calls `.stop()`
      (grep the effect body for `.stop(`).
- [ ] `cd pinscope && npm run typecheck` exits 0; `npm test` stays green.

### Definition of Done
A new RTL test in `tests/unit/runtime/pinscope.test.tsx` renders `<PinScope/>`,
then appends a fresh element to `document.body` *without* a `data-pin`
attribute, flushes the MutationObserver microtask, and asserts the new element
has gained a `data-pin` value matching `/^e_r\d+$/`. The test also `unmount()`s
`<PinScope/>` and asserts a subsequently-added element is **not** assigned an id
(observer disconnected). This test must transition **red → green**: red on
current `main` (no observer running), green after. R-20-02 is closed when that
named test is green and `npm test` reports 0 failures.

### Dependencies
Shares `PinScope.tsx` with R-20-01 and R-20-03 — same Wave, serialize edits.
No dependency on SUSPECTED items.

### Risk assessment
**Medium-low.** Introduces the first `useEffect` into `PinScopeHud`. Risk: an
un-disconnected observer leaks across test renders — mitigated by the mandatory
`.stop()` cleanup, asserted by the DoD's unmount check. Risk: in a non-DOM test
env `MutationObserver` may be undefined — mitigated by a `typeof
MutationObserver` guard. `RuntimePinObserver` mutates the host DOM (adds
`data-pin` attrs); this is exactly the §12 contract and is dev-only (stripped
from prod builds), so no production surface is affected.

---

## Remediation R-20-03

**Linked finding:** F-20-03
**Severity:** P2
**Spec anchor:** §8.11 v1.0 key table — explicitly names `Shift+P`
(`toggle-pins`) and `Shift+C` (`crosshair`); §16 P2-DoD ">=95% of the §8.11
shortcuts perform their action".
**Root cause:** Same shared root cause as R-20-01/02 — `PinScopeHud`'s
`useKeyboardShortcuts` call wires only the 9 ids that mutate its existing
`useState` cells. `toggle-pins` and `crosshair` have **no state to toggle**:
`PinBadges` exposes no visibility prop and `Crosshair` accepts only
`measuring`/`hudHidden`, no enable/disable. The handlers were never written
because the *state cells and props they would drive do not exist*. Real-HUD
functional ratio is 11/13 = 0.846, below the §16 P2 threshold; AC-043 hides
this because `shortcuts.test.tsx` dispatches synthetic handlers for all 13 ids
and never exercises `PinScope.tsx`.

### Ecosystem analysis
1. Which §8.11 ids are dead in the real HUD? `toggle-pins` (Shift+P) and
   `crosshair` (Shift+C) — the `useKeyboardShortcuts` handler object in
   `PinScopeHud` lists exactly 9 ids; `command`/`escape` are serviced by
   `CommandBar` (Cmd+K / `/` / Esc), leaving these two with no path.
2. What does `toggle-pins` need? A boolean visibility cell in `PinScopeHud` and
   a way to hide/show the pin badges. `PinBadges` currently takes no props.
3. What does `crosshair` need? A boolean enable cell in `PinScopeHud` and an
   enable/disable input on `Crosshair`. `Crosshair` currently has only
   `measuring`/`hudHidden` and no on/off toggle.
4. Minimal correct shape for `toggle-pins`? Add a `pinsVisible` `useState` cell;
   give `PinBadges` (and the void-badge layer from R-20-01) a `visible`/`hidden`
   prop, OR conditionally render the badge layer; wire the `toggle-pins`
   handler to flip the cell.
5. Minimal correct shape for `crosshair`? Add a `crosshairEnabled` `useState`
   cell; extend `CrosshairProps` with an `enabled` (default `true`) prop and
   add it to the existing `if (measuring || hudHidden) return null;` disable
   guard; wire the `crosshair` handler to flip the cell.
6. Does this re-open AC-035? AC-035 asserts the over-HUD / measuring / hidden
   disable paths — adding a *fourth* `enabled` gate that defaults `true` does
   not change those three behaviors, so AC-035 stays green. Verify the existing
   `controls.test.tsx`/`overlays.test.tsx` Crosshair cases still pass.
7. Is this a hook-trigger change? No — no hook file, `framework/settings.json`,
   or `HOOK-CLASSIFICATION.md` involvement; the three-places contract does not
   apply.
8. After the fix, what is the functional ratio? 13/13 §8.11 ids reach a real
   action — clears the §16 ">=95%" P2-DoD.

### Execution plan
**Files to modify:**
- `src/runtime/PinScope.tsx` — add two `useState` cells in `PinScopeHud`
  (`pinsVisible` default `true`, `crosshairEnabled` default `true`); add
  `'toggle-pins'` and `'crosshair'` entries to the `useKeyboardShortcuts`
  handler object (the object literal currently listing `toggle-hud`,
  `grid-cycle`, `grid-0`…`grid-4`, `measure`, `snapshot`); pass the new state
  into the badge layer and into `<Crosshair .../>` (the existing
  `<Crosshair measuring={measuring} hudHidden={!hudVisible} />` element).
- `src/runtime/components/Crosshair.tsx` — extend `CrosshairProps` with an
  `enabled?: boolean` (default `true`) and add it to the disable guard
  `if (measuring || hudHidden) return null;` → also return `null` when
  `!enabled`.
- `src/runtime/components/PinBadges.tsx` — give `PinBadges` a `visible?: boolean`
  prop (default `true`); when hidden, render no badge `<style>` (or an empty
  one) so Shift+P hides the CSS badges. (Alternatively, conditionally render
  `<PinBadges/>` from `PinScope.tsx` keyed on `pinsVisible` and leave
  `PinBadges` propless — the executor picks one; the DoD checks the behavior,
  not the mechanism.)
**Files to create:** none.
**Files that MUST remain untouched:** `src/runtime/hooks/useKeyboardShortcuts.ts`
— the `SHORTCUTS` table and `ShortcutId` union already contain `toggle-pins`
and `crosshair`; do not change the table, the `matchShortcut` resolver, or the
`useEffect` binding. The three existing `Crosshair` disable conditions
(over-HUD via `onMove`, `measuring`, `hudHidden`) must keep their current
behavior — only a new `!enabled` disjunct is added.
**Order of operations:** 1. add `enabled` to `CrosshairProps` + disable guard.
2. add the `visible` prop / conditional render path for pin badges. 3. in
`PinScope.tsx` add the two `useState` cells, the two handler entries, and the
prop wiring. (Serialize within Wave 1 with R-20-01/R-20-02 on the shared
`PinScope.tsx` body.)
**Rollback trigger:** `npm run typecheck` red, `npm test` red, or AC-035's
Crosshair tests in `controls.test.tsx`/`overlays.test.tsx` regress.

### Acceptance criteria
- [ ] `grep -nE "'toggle-pins'|'crosshair'" pinscope/src/runtime/PinScope.tsx`
      returns hits inside the `useKeyboardShortcuts` handler object.
- [ ] `grep -nE 'enabled' pinscope/src/runtime/components/Crosshair.tsx` shows
      `enabled` is a `CrosshairProps` member and is in the disable guard.
- [ ] `grep -rnE 'pinsVisible|crosshairEnabled' pinscope/src/runtime/PinScope.tsx`
      returns the two new state cells.
- [ ] `cd pinscope && npm run typecheck` exits 0; `npm test` stays green
      (existing AC-035 Crosshair tests still pass).

### Definition of Done
A new RTL test in `tests/unit/runtime/shortcuts.test.tsx` (or a new
`pinscope.test.tsx` case) renders the real `<PinScope/>` — not synthetic
handlers — and:
1. seeds a `[data-pin]` element, dispatches `Shift+P` on `document`, and
   asserts the pin-badge layer is gone (e.g. `[data-pinscope-badges]` style
   block absent / produces no badge), then dispatches `Shift+P` again and
   asserts it returns;
2. moves the mouse to render the crosshair, dispatches `Shift+C`, and asserts
   `[data-pinscope-crosshair]` (or `[data-crosshair]`) is gone, then `Shift+C`
   again and asserts it returns.
Both halves must transition **red → green** across the fix. R-20-03 is closed
when that named test is green, the §8.11 real-HUD functional ratio is 13/13,
and `npm test` reports 0 failures.

### Dependencies
Shares `PinScope.tsx` with R-20-01 and R-20-02 (same Wave). The pin-visibility
toggle should also hide the `VoidBadges` layer added by R-20-01 — if R-20-01
lands first, extend the `pinsVisible` gate to cover `<VoidBadges/>` too. No
dependency on SUSPECTED items.

### Risk assessment
**Low-medium.** Touches three files but each change is small and additive.
Risk: a new `Crosshair` `enabled` gate could be mis-ordered and disable the
crosshair unconditionally — mitigated by defaulting `enabled` to `true` and the
DoD's toggle-twice assertion. Risk: AC-035 regression — mitigated by the
acceptance criterion re-running the existing Crosshair tests. No schema, build,
or production-output surface touched.

---

## Remediation R-20-04

**Linked finding:** F-20-04 (SUSPECTED — investigation R-item)
**Severity:** P3
**Spec anchor:** §9.3 `request_type: 'operation'|'annotation'|'diagnostic'`;
§10 flow E "Send to Claude (annotation)".
**Root cause (hypothesised, to be confirmed in STEP 1 below):** The §10-E
annotation flow (select → screenshot modal → annotation `Operation` →
clipboard) was never built: `operation-builder.ts` emits only `'operation'`
(base) and `'diagnostic'` (query branch); `request_type:'annotation'` is
emitted by no code path, and `src/runtime/utils/screenshot.ts`
(`captureScreenshot`) is a working but uncalled unit with no annotation/modal
component. The audit recorded this **P3/SUSPECTED** because §10-E is
non-normative prose, no AC in the frozen Appendix A requires an `annotation`
`request_type` or a screenshot modal, and AC-076 (the only screenshot-touching
AC, verifying the html2canvas dynamic-import property) PASSES. The open
question for STEP 1: is this a genuine gap warranting a new AC, or out of v2.0
scope?

### Ecosystem analysis
1. Is the §10-E flow normative? Per the finding, §10-E is non-normative prose;
   no Appendix-A AC names it — STEP 1 must re-confirm this against the frozen
   `SPEC.md` Appendix A.
2. Does any code emit `request_type:'annotation'`? Per `re_read`: no —
   `operation-builder.ts` sets `'operation'` (base object) and `'diagnostic'`
   (query branch); `operation.annotation` is assigned the query *topic* but
   `request_type` is never `'annotation'`.
3. Is `captureScreenshot` reachable? Per `re_read`: it is defined in
   `screenshot.ts` and has no `src/runtime/` caller.
4. Does a screenshot/annotation modal component exist? Per `re_read`: no file
   matching `*Modal*` or `*Annotation*` under `src/runtime/components/`.
5. Decision the planner defers to STEP 1: confirm the gap is real, then decide
   — recommend a `candidate_ac` to the loop owner (out of *this* agent's
   scope to author), or record §10-E as out-of-v2.0-scope with a `Resolution`.
6. Is the frozen SPEC the authority? Yes — if §10-E is non-normative and no AC
   covers it, reality (no annotation flow) does not violate the frozen
   contract; the finding is then a *visibility* note, not a behavioral gap.
7. Sync-strategy / hook-trigger? N/A.

### Execution plan
**Files to modify:** none under `src/` *until STEP 1 concludes*. This is an
investigation R-item.
**Files to create:** none.
**Files that MUST remain untouched:** `src/runtime/parsers/operation-builder.ts`,
`src/runtime/utils/screenshot.ts`, and all of `src/runtime/components/` —
no edit is made until STEP 1 determines whether a fix is in scope.
**Order of operations:**
- **STEP 1 — confirm or refute.** Re-read `pinscope/SPEC.md` §9.3, §10 flow E,
  and the full Appendix-A AC list; grep `src/runtime/` for `annotation`,
  `request_type`, `captureScreenshot`, and any `*Modal*` component. Confirm:
  (a) §10-E is non-normative prose; (b) no Appendix-A AC requires
  `request_type:'annotation'` or a screenshot modal.
- **STEP 2 — branch on the STEP-1 verdict:**
  - *If confirmed out-of-AC-scope* (the expected outcome): make **no code
    change**. Record the `### Resolution` below as the closing state and
    recommend to the loop owner that a `candidate_ac` for the §10-E flow be
    considered next round if the §10-E behavior is wanted in v2.0 — authoring
    that AC is the loop owner's call, not this R-item's.
  - *If STEP 1 instead finds an AC that DOES require the annotation flow*
    (contradicting the finding): escalate — the finding's severity is wrong;
    a follow-up P-graded R-item building the modal + the `annotation`
    `request_type` branch in `buildOperation` is required, and `ps-scheduler`
    should be told the round's finding-set changed.
**Rollback trigger:** STEP 1 reveals an AC requiring the flow — abandon the
"no-change" resolution and escalate per STEP 2.

### Acceptance criteria
- [ ] STEP 1 is performed: `SPEC.md` §9.3/§10-E and Appendix A are re-read and
      the §10-E normativity verdict is recorded in the execution log.
- [ ] `grep -rn 'annotation' pinscope/src/runtime/` is run and its result
      (only `operation.annotation = topic`, no `request_type:'annotation'`) is
      recorded.
- [ ] Either: no `src/` file changed AND the `### Resolution` is the closing
      state; or: an escalation is raised because STEP 1 found a covering AC.
- [ ] `cd pinscope && npm test` stays green (0 fail) regardless of branch.

### Definition of Done
R-20-04 is closed when STEP 1 has been executed and recorded, and **one** of
the following holds, checkable by someone who never saw the investigation:
- **(refuted / out-of-scope)** the execution log states "§10-E is non-normative;
  no Appendix-A AC requires `request_type:'annotation'`" with the grep evidence,
  AND `git diff --stat` shows **0** files changed under `pinscope/src/`, AND
  `npm test` reports 0 failures — the `### Resolution` below is then the
  authoritative closing record; **or**
- **(confirmed in-AC-scope)** the log names the covering AC and an escalation
  R-item is filed for the next round.
The DoD is mechanically checkable: it is a grep result + a `git diff --stat`
count + a test exit code.

### Resolution
This R-item is expected to close as a **refuted-for-this-loop** investigation,
not a code fix. The finding itself is recorded P3/SUSPECTED precisely because
the §10-E annotation flow lives in non-normative prose and the **frozen
Appendix-A contract names no AC for it** — `request_type:'annotation'` is a
valid §9.3 union member that simply has no producing code path, and AC-076
(the sole screenshot AC) passes on the dynamic-import property alone. Under the
loop's rule "the North-Star is frozen; plan the fix to reality", reality not
implementing a non-AC'd flow is **not a contract violation**. The correct
closing action is therefore *no code change* plus a recommendation that the
loop owner decide whether to add a `candidate_ac` for the §10-E flow — that
decision is out of this agent's scope. The re-read check that proves the
resolution: `grep -rn 'annotation' pinscope/src/runtime/` shows only
`operation.annotation = topic` (no `request_type:'annotation'`), and an
Appendix-A scan shows no AC string mentioning `annotation` `request_type` or a
screenshot modal. If a future round's auditor finds such an AC, this resolution
is void and the escalation branch applies.

### Dependencies
None — independent of the R-20-01/02/03 Wave-1 group and of R-20-05. Can run in
any wave; investigation-only, touches no shared file.

### Risk assessment
**Very low.** Investigation-only; the expected outcome changes no code. The one
real risk is mis-judging §10-E normativity — mitigated by STEP 1 forcing a
full Appendix-A re-read before any "no-change" resolution is recorded, and by
the escalation branch that fires if a covering AC is found.

---

## Remediation R-20-05

**Linked finding:** F-20-05 (SUSPECTED — investigation R-item; carried from
F-19-01)
**Severity:** P3
**Spec anchor:** §8.6 CommandBar command flow; §9.4 — the `select`/`measure`/
`snapshot` local-action classification.
**Root cause (hypothesised, to be confirmed in STEP 1):** Not a code defect — a
**test-coverage margin**. `CommandBar.tsx`'s `isLocalOnlyCommand` correctly
returns `true` for `kind === 'select' || kind === 'measure' || kind ===
'snapshot'`, but `controls.test.tsx` only ever submits `select e_1` (hits the
first disjunct) and the invalid-grammar `measure e_2 e_3` (the parse throws and
the `catch` returns `true` without reaching the `measure`/`snapshot`
disjuncts). The `measure`/`snapshot` arms of the disjunction are never
exercised, so the R18 `or-to-and` mutant on that line survives. The root cause
is a missing test input, not wrong production code — the shipping path matches
§8.6/§9.4.

### Ecosystem analysis
1. Is `isLocalOnlyCommand` correct? Per the finding's `re_read` and the source:
   yes — its three-way disjunction returns `true` for valid `select`,
   `measure`, and `snapshot` kinds; the catch-all returns `true` for
   unparseable input.
2. Why does the mutant survive? `measure e_2 e_3` fails `RE_MEASURE`
   (`/^measure\s+(e_\d+)\s+to\s+(e_\d+)$/i` — no `to`), so `parseCommand`
   throws and the `catch` branch returns before the `measure`/`snapshot`
   disjuncts execute. No test feeds a *valid* `measure e_N to e_M` or
   `snapshot` through the CommandBar Enter path.
3. What input closes the margin? A valid `snapshot foo` and a valid
   `measure e_2 to e_3` submitted through the CommandBar `onKeyDown` Enter
   handler, asserting each produces exactly one local-only history entry
   (`history.append` called once with `parsed: null`).
4. Is this a behavioral gap? No — the finding explicitly states it is a benign
   coverage margin, not a dead path or swallowed failure; it does not block
   convergence.
5. Where does the test go? `tests/unit/runtime/controls.test.tsx`, alongside
   the existing `select e_1` CommandBar case.
6. Does this need a production-code change? Hypothesised no — STEP 1 confirms.
7. Sync-strategy / hook-trigger? N/A.

### Execution plan
**Files to modify:** `tests/unit/runtime/controls.test.tsx` — add CommandBar
Enter-path cases for a valid `snapshot`-kind and a valid `measure e_N to e_M`-kind
command, adjacent to the existing `select e_1` local-only test.
**Files to create:** none.
**Files that MUST remain untouched:** `src/runtime/components/CommandBar.tsx`
(specifically `isLocalOnlyCommand` — its three-way disjunction is correct and
must NOT change) and `src/runtime/parsers/operation-parser.ts` (`RE_MEASURE`
and the grammar are correct). This is a test-only remediation.
**Order of operations:**
- **STEP 1 — confirm or refute.** Re-read `CommandBar.tsx` `isLocalOnlyCommand`
  and `operation-parser.ts` `RE_MEASURE`/`RE_SNAPSHOT`; confirm the production
  path is correct and the gap is purely a missing valid-`measure`/-`snapshot`
  test input (i.e. F-20-05 is a coverage margin, not a behavioral defect).
- **STEP 2 — close the margin.** If STEP 1 confirms (expected): add the two
  CommandBar Enter-path test cases. Each renders `<CommandBar>` with an
  injected `HistoryManager`, types a valid command (`snapshot foo`,
  `measure e_2 to e_3`), fires the `Enter` key, and asserts the history
  received exactly one local-only entry whose `parsed` is `null`. If STEP 1
  instead refutes (finds `isLocalOnlyCommand` actually wrong): escalate — a
  production-code R-item is then required, not a test-only one.
**Rollback trigger:** the new tests fail to go green against unmodified
`CommandBar.tsx` — that would mean the production code is wrong (refutes the
finding) and the test-only plan must be abandoned for an escalation.

### Acceptance criteria
- [ ] STEP 1 is performed and its verdict (production path correct / a coverage
      margin only) is recorded in the execution log.
- [ ] `tests/unit/runtime/controls.test.tsx` contains a new CommandBar case
      submitting a valid `snapshot`-kind command via the Enter handler.
- [ ] `tests/unit/runtime/controls.test.tsx` contains a new CommandBar case
      submitting a valid `measure e_N to e_M`-kind command via the Enter handler.
- [ ] `src/runtime/components/CommandBar.tsx` is byte-for-byte unchanged
      (`git diff --stat` shows it untouched).
- [ ] `cd pinscope && npm test` stays green (0 fail) with the two new cases.

### Definition of Done
R-20-05 is closed when, against **unmodified** `CommandBar.tsx`, the two new
`controls.test.tsx` cases both pass: one submits a valid `snapshot foo` through
the CommandBar Enter path and asserts `history.list()` gains exactly one entry
with `parsed === null` and `result === 'applied'`; the other does the same for
a valid `measure e_2 to e_3`. Both cases exercise the `measure`/`snapshot`
disjuncts of `isLocalOnlyCommand` (the previously-unexercised arms), so the
R18 `or-to-and` mutant on that line is now killed. The DoD is mechanically
checkable: `npm test` exits 0 with the two named cases present and green, and
`git diff --stat` shows `CommandBar.tsx` unchanged. If STEP 1 instead refutes
the finding (production code wrong), the closing record is the escalation entry
naming the required production-code R-item.

### Dependencies
None — independent of all other R-items; test-only, touches no shared source
file. Can run in any wave.

### Risk assessment
**Very low.** Test-only remediation against correct production code; it adds
coverage and cannot regress behavior. The only risk is the new tests failing —
which would *refute* F-20-05 and is itself the rollback trigger that converts
this into an escalation. No schema, build, runtime, or production-output
surface touched.
