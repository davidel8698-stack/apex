# Remediation Plan — PS-R15

## Round summary

R15 carries **22 raw findings** across three sources — 11 spec-auditor investigation findings `F-15-01..F-15-11` (9 CONFIRMED, 2 SUSPECTED = `F-15-10`/`F-15-11`), 9 narrative `blocking_findings` `NF-15-01..NF-15-09`, and 2 hollow-test findings from `TEST-AUDIT-R15.md` (`AC-076`, `AC-107`) — collapsed into **11 R-items** after shared-root-cause grouping. Every one of the 11 spec-auditor findings is routed: each of `F-15-01..F-15-11` maps to exactly one R-item, including `F-15-05` (Rulers §8.2), which is closed by **R-15-03**. Severity tally of the 11 R-items: **P1 ×2** (`R-15-01` root assembly, `R-15-05` hostile-CSS hardening), **P2 ×7** (`R-15-02`, `R-15-03`, `R-15-04`, `R-15-06`, `R-15-07`, `R-15-10`, `R-15-11`), **P3 ×2** (`R-15-08`, `R-15-09`). The dominant root cause is one fault behind three findings: `src/runtime/PinScope.tsx` was frozen at "PS-R2 scope" (inspection layer only) and never re-assembled — that single un-wired root is the cause of `F-15-01`/`NF-15-01`, `F-15-02`/`NF-15-02` and `F-15-03`/`NF-15-03`, and is also why every measurement/control/state component is dead code despite passing isolated tests. **Shared-root-cause groups: 4** — Group A: `R-15-01` closes `F-15-01`+`NF-15-01`+`F-15-02`+`NF-15-02`+`F-15-03`+`NF-15-03` (one un-assembled root); Group B: `R-15-05` closes `F-15-04`+`NF-15-08` (badge CSS never hardened with `!important`); Group C: `R-15-07` closes `F-15-07`+`NF-15-04`+`NF-15-05` (CommandBar built to a partial §8.6 contract); Group D: each remaining R-item closes one finding plus its narrative twin where one exists (`R-15-04`=`F-15-08`+`NF-15-06`, `R-15-06`=`F-15-09`+`NF-15-07`, `R-15-08`=`F-15-10`+`NF-15-09`). `F-15-05` (Rulers §8.2) has no entry in the narrative `blocking_findings` list — its narrative twin `NC-08-03` (`code_satisfied: false`) is a `claims` entry, not a blocking finding — so `R-15-03` closes `F-15-05` alone, corroborated by `NC-08-03`. `F-15-06` (`R-15-02`) and `F-15-11` (`R-15-09`) likewise have one spec-auditor finding each. The `candidate_acs` and `strengthen_proposals` in the narrative scan are PROPOSALS and out of scope. The 7 BLOCKED ACs (browser / apex-install env limits) are not findings and are not planned. `pinscope/SPEC.md` is frozen — every R-item fixes reality to the spec, never the reverse. Finding-routing arithmetic: 11 spec-auditor + 9 narrative + 2 test-audit = 22 raw findings → 11 R-items; 11 of 11 spec-auditor findings routed, 9 of 9 narrative findings routed, 2 of 2 test-audit findings routed.

---

## Remediation R-15-01

**id:** R-15-01
**Linked finding:** F-15-01, NF-15-01, F-15-02, NF-15-02, F-15-03, NF-15-03
**Severity:** P1
**Spec anchor:** §7.1 — "portal-renders the HUD tree (`PinBadges`, `Rulers`, `Crosshair`, `GridOverlay`, `InfoPanel`, `TopBar`, `CommandBar`) into `document.body` under a `data-pinscope-ui=\"root\"` wrapper. When HUD hidden, renders only a `FloatingToggle`."
**Root cause:** `src/runtime/PinScope.tsx` was deliberately frozen at "PS-R2 scope" — its own doc-comment says *"mounts the inspection layer (PinBadges + InfoPanel). The measurement, control and state layers are added by later rounds."* Those later rounds built every component and manager but never returned to re-assemble the root. The result is a hollow product: the root mounts 2 of 7 §7.1 components, declares 2 of 4 §7.1 props, and has no HUD-hidden branch. This is one root cause behind six findings — they are not separate gaps, they are three faces of one un-assembled root.

### Ecosystem analysis
1. Which §7.1 components are already built and test-passing in isolation? All seven plus `MeasurementTool`, `StatePanel`, `VoidBadges` — confirmed present under `src/runtime/components/`.
2. Which managers/hooks must the root own to drive those components? `SelectionManager`, `SnapshotManager`, `RuntimePinObserver`, `HistoryManager`, `ClaudeBridge`, `useKeyboardShortcuts` — all built, none mounted.
3. What state must the root hold? HUD-visible boolean, current `GridMode`, measurement-mode boolean, state-override value — required to drive `TopBar`, `Crosshair`, `GridOverlay`.
4. Does `TopBar` need a `viewport`? Yes — `useViewportSize` already exists and is consumed by `Rulers`; the root can share it.
5. Does `GridOverlay` need a cycle source? `nextGridMode` exists in `GridOverlay.tsx`; the root cycles it via `useKeyboardShortcuts` `grid-cycle`/`grid-0..4`.
6. What new component does §7.1 require that does not exist? `FloatingToggle` — `grep -rln 'FloatingToggle' src` returns nothing; it must be created.
7. Will adding `defaultGridMode`/`shortcutsEnabled` props break callers? No — both are optional; existing `enabled`/`hudPosition` callers are unaffected.
8. Does the production-zero guarantee survive? Yes — the `process.env.NODE_ENV === 'production'` early-return is preserved verbatim; no new top-level import is eager beyond what already ships.
9. Is there a perf budget risk? §13 mount budget < 50 ms (AC-070) — the assembled tree must still satisfy `tests/unit/runtime/perf.test.tsx`; that test is the rollback signal.
10. Does any AC currently assert the assembled tree? No — that is precisely the false-convergence STEP 5 caught; this R-item makes the assembly real and a new RTL test (see DoD) makes it checkable.

### Execution plan
**Files to modify:** `src/runtime/PinScope.tsx` — the `PinScopeProps` interface and the `PinScopeHud` function body.
**Files to create:** `src/runtime/components/FloatingToggle.tsx` — a single fixed-position button that, when clicked, sets HUD-visible true; carries a `data-pinscope-toggle` attribute.
**Files that MUST remain untouched:** the production guard (`if (process.env.NODE_ENV === 'production') return null;`) and the `enabled === false` guard must keep their exact early-return semantics — only code *after* those guards may change. The individual component files (`Rulers.tsx`, `Crosshair.tsx`, etc.) and their isolated tests are not edited by this R-item.
**Order of operations:**
1. Extend `PinScopeProps` with `defaultGridMode?: GridMode` and `shortcutsEnabled?: boolean` (import `GridMode` from `./components/GridOverlay.js`).
2. Create `FloatingToggle.tsx`.
3. In `PinScopeHud`, add root state: `hudVisible` (default true), `gridMode` (default `props.defaultGridMode ?? 'off'`), `measuring`, `stateOverride`.
4. Wire `useKeyboardShortcuts` (gated on `props.shortcutsEnabled !== false`) to toggle `hudVisible`, cycle `gridMode`, toggle `measuring`.
5. Replace the portal body: when `!hudVisible` render only `<FloatingToggle/>`; otherwise render the full tree — `PinBadges`, `Rulers`, `Crosshair`, `GridOverlay`, `InfoPanel`, `TopBar`, `CommandBar` — inside the existing `data-pinscope-ui="root"` wrapper.
6. Pass `measuring`/`hudVisible` down to `Crosshair` and `gridMode` to `GridOverlay`/`TopBar` (the Crosshair guard props are delivered by R-15-02 — see Dependencies).
**Rollback trigger:** `npm test` reports any previously-green test now failing, or `tests/unit/runtime/perf.test.tsx` mount budget exceeds 50 ms.

### Acceptance criteria
- [ ] `grep -E 'Rulers|Crosshair|GridOverlay|TopBar|CommandBar' src/runtime/PinScope.tsx` returns a match for each of the five names.
- [ ] `grep -E 'defaultGridMode|shortcutsEnabled' src/runtime/PinScope.tsx` returns matches for both props inside `PinScopeProps`.
- [ ] `src/runtime/components/FloatingToggle.tsx` exists and is referenced by `PinScope.tsx`.
- [ ] `PinScope.tsx` contains a HUD-hidden branch that renders `FloatingToggle` and nothing else.
- [ ] The full vitest suite stays green (no regression among the 257 existing tests).

### Definition of Done
A new RTL test file `tests/unit/runtime/pinscope-assembly.test.tsx` (authored as a behavioral test, not a count) is added by the executor and transitions red → green: it renders `<PinScope/>`, then asserts a present query handle for **all seven** §7.1 components via their data attributes — `[data-pinscope-rulers]`, `[data-pinscope-crosshair]`, `[data-pinscope-grid]` (with a non-`off` `defaultGridMode`), `[data-pinscope-topbar]`, `[data-pinscope-command]`, plus the PinBadges `<style>` and InfoPanel root. A second case sets HUD-hidden and asserts `[data-pinscope-toggle]` is the only PinScope element rendered. A third case passes `shortcutsEnabled={false}` and asserts a `Shift+G` keydown does NOT change the rendered grid mode. R-15-01 is closed when this file passes AND `grep -cE 'Rulers|Crosshair|GridOverlay|TopBar|CommandBar' src/runtime/PinScope.tsx` ≥ 5 AND `npm test` exits 0.

### Dependencies
- R-15-02 (Crosshair guards) supplies the `measuring`/`hudVisible` props this R-item passes to `Crosshair`; if R-15-02 lands in the same wave, serialize R-15-02 before the Crosshair wiring step here. If R-15-02 lands later, this R-item may pass the props to a Crosshair that ignores them — acceptable, no regression.
- No dependency on R-15-03..R-15-09 (those harden components this R-item merely mounts).

### Risk assessment
**High** — this is the largest R-item and touches the shipping root. Risk is mounting a component that throws on mount (e.g. a manager expecting a store). Mitigation: each component is already test-passing in isolation, so failures will surface as integration faults caught by the DoD RTL test and the existing perf test. The production-zero guard is explicitly in the preservation list, so AC-010/AC-074 cannot regress.

---

## Remediation R-15-02

**id:** R-15-02
**Linked finding:** F-15-06
**Severity:** P2
**Spec anchor:** §8.3 — "Crosshair … disabled over HUD, in measurement mode, or when HUD hidden."
**Root cause:** `Crosshair.tsx` was built against only the first of the three §8.3 disable conditions. Its `onMove` handler checks `target.closest('[data-pinscope-ui]')` (the over-HUD case) but the component takes no props, so it has no channel to learn about measurement mode or HUD visibility — both pieces of state that live in the root. The gap is a missing prop surface, not a missing algorithm.

### Ecosystem analysis
1. Where do "measurement mode" and "HUD hidden" states live? In `PinScopeHud` after R-15-01 introduces them.
2. Does `Crosshair` currently accept props? No — `export function Crosshair(): ReactElement | null` takes none.
3. What is the cleanest disable mechanism? Two boolean props `measuring?` and `hudHidden?`; when either is true, return `null` before rendering lines.
4. Does the over-HUD check stay? Yes — it is correct for §8.3's first case and is preserved.
5. Will adding optional props break the isolated `controls.test.tsx`? No — props are optional and default to `false`, preserving current behavior when unset.
6. Is there a render-loop risk? No — the props are derived state passed top-down from the root; no new effect.

### Execution plan
**Files to modify:** `src/runtime/components/Crosshair.tsx` — the `Crosshair` function signature and its early-return block.
**Files that MUST remain untouched:** the `onMove` over-HUD branch (`target.closest([HUD_ROOT_ATTR])`) — its hide-over-HUD behavior is correct and must not be removed; only an *additional* guard is added.
**Order of operations:**
1. Add `interface CrosshairProps { measuring?: boolean; hudHidden?: boolean }`.
2. After the existing `if (!pos) return null;`, add `if (measuring || hudHidden) return null;` (or fold both into one guard before line rendering).
**Rollback trigger:** `tests/unit/runtime/controls.test.tsx` Crosshair cases regress.

### Acceptance criteria
- [ ] `grep -E 'measuring|hudHidden' src/runtime/components/Crosshair.tsx` returns matches.
- [ ] The over-HUD `closest` check is still present.
- [ ] The crosshair renders `null` when `measuring` is true.

### Definition of Done
A test case is added to `tests/unit/runtime/controls.test.tsx` and transitions red → green: it mounts `<Crosshair measuring />`, fires a `mousemove` away from any HUD element, and asserts `queryByTestId`/`[data-pinscope-crosshair]` is absent; a second case mounts `<Crosshair hudHidden />` and asserts the same. A control case mounts `<Crosshair/>` with no props, fires the same mousemove, and asserts the crosshair IS present (proving the guard is conditional, not unconditional). Closed when all three cases pass and `npm test` exits 0.

### Dependencies
- Consumed by R-15-01 (the root passes `measuring`/`hudHidden` here). No upstream dependency — can land independently.

### Risk assessment
**Low** — additive optional props, two-line guard, isolated component.

---

## Remediation R-15-03

**id:** R-15-03
**Linked finding:** F-15-05
**Severity:** P2
**Spec anchor:** §8.2 — "Rulers — horizontal (top) + vertical (left), 24px, ticks at `10/50/100/200` px, monospace labels, corner shows live mouse coords."
**Root cause:** `Rulers.tsx` was built against the AC, not the spec. `AC-034` verifies only that ticks render "at 100px intervals", so the component author wrote a single-scale `ticks(extent, interval)` loop with `interval` defaulting to 100 and stopped — the §8.2 multi-scale tick set (`10/50/100/200` px) and the corner live-coordinate readout were never written. The component passes the matrix because the matrix under-checks §8.2; the gap is a component built to satisfy an under-specified AC rather than the frozen spec. Independently corroborated by narrative claim `NC-08-03` (`code_satisfied: false`), which is a `claims`-list entry (not a `blocking_findings` entry), so `F-15-05` is the sole routed finding here.

### Ecosystem analysis
1. What does §8.2 require beyond the current code? A multi-scale tick set — ticks at the four scales `10`, `50`, `100`, `200` px (a major/minor hierarchy, not one uniform spacing) — and a corner element that shows the live mouse coordinates.
2. What does the code currently produce? `ticks(extent, interval)` loops `v += interval` for a single `interval` (default 100); the returned tree has only the two `bar` divs (horizontal + vertical) and no corner element.
3. What is the natural multi-scale model? Render minor ticks at the 10px scale, progressively longer/labelled ticks at 50/100/200 px — e.g. a tick's length/label class is chosen by the largest scale of `{10,50,100,200}` that divides its position. Labels stay monospace per §8.2.
4. Where does the live-coords readout get its data? A `mousemove` listener (or the existing hovered-position source) feeds the corner element with `x`/`y`; the corner sits where the horizontal and vertical bars meet (top-left, 24×24px).
5. Does the corner element need isolation from host CSS? Yes — it renders inside the `data-pinscope-ui` portal subtree; it inherits the HUD's isolation, no new !important needed beyond what R-15-05 hardens.
6. Will this change `AC-034`? No — `AC-034` counts 100px-interval tick labels; a multi-scale set still contains the 100px ticks, so `AC-034` continues to pass. The new behavior (10/50/200 scales + corner coords) is additive and is the gap STEP 5 caught.
7. Is this testable without a browser? Yes — jsdom renders the tick DOM; a unit test can count ticks at each scale and assert the corner element updates on a synthetic `mousemove`.
8. Does the root assembly depend on this? No — R-15-01 mounts `Rulers` regardless; this R-item upgrades the mounted component's internals. The `data-pinscope-rulers` handle R-15-01's DoD queries is preserved.

### Execution plan
**Files to modify:** `src/runtime/components/Rulers.tsx` — the `ticks(...)` generator and the `Rulers` returned tree.
**Files that MUST remain untouched:** the `24px` bar dimensions and the monospace label styling (both already correct per §8.2); the `data-pinscope-rulers`/`data-pinscope-ui` attributes that R-15-01's assembly DoD queries — only the tick-generation logic and the new corner element are added.
**Order of operations:**
1. Replace the single-`interval` `ticks` generator with a multi-scale generator: produce ticks at the 10px base step and tag each tick with the largest of `{10,50,100,200}` that divides its position (driving tick length and whether it carries a label).
2. Render the multi-scale ticks in both the horizontal and vertical `bar` divs, keeping monospace labels.
3. Add a corner element (24×24px, at the top-left where the bars meet) that subscribes to `mousemove` and renders the live `x`/`y` mouse coordinates; tag it with a `data-pinscope-ruler-corner` attribute for the DoD test.
**Rollback trigger:** `AC-034`'s tagged test (100px-interval tick count) regresses, or `tests/unit/runtime/components.test.tsx` Rulers cases regress.

### Acceptance criteria
- [ ] `Rulers.tsx` generates ticks at the four scales 10/50/100/200 px, not one uniform `interval`.
- [ ] `Rulers.tsx` renders a corner element carrying `data-pinscope-ruler-corner`.
- [ ] The corner element displays live mouse coordinates that update on `mousemove`.
- [ ] The 24px bar dimensions and monospace labels are unchanged; `AC-034` stays green.

### Definition of Done
A test in `tests/unit/runtime/components.test.tsx` (Rulers block) transitions red → green: it renders `<Rulers/>` for a known viewport extent and asserts the horizontal bar contains ticks at the 10px scale AND distinctly-marked (longer/labelled) ticks at the 50, 100, and 200 px scales — i.e. more than one tick class is present, proving the multi-scale set. A second case asserts a `[data-pinscope-ruler-corner]` element exists, then fires a synthetic `mousemove` to `(x=137, y=84)` and asserts the corner's text content reports those coordinates. The current single-uniform-interval implementation must FAIL the first case. Closed when both cases pass AND `grep -E '10|50|200' src/runtime/components/Rulers.tsx` shows the multi-scale tick scales are present in code AND `grep 'data-pinscope-ruler-corner' src/runtime/components/Rulers.tsx` matches AND `npm test` exits 0 (including the unchanged `AC-034` test).

### Dependencies
None — `Rulers` is mounted by R-15-01 but this internal upgrade is independent of the mount; it touches only `Rulers.tsx`.

### Risk assessment
**Low–Medium** — isolated to one component file. Risk is the multi-scale tick generator producing a different count at the 100px scale and regressing `AC-034`; mitigation: the 100px ticks remain a subset of the multi-scale set, and the rollback trigger names the `AC-034` test explicitly as the regression signal. The corner `mousemove` listener must be cleaned up on unmount to avoid a listener leak.

---

## Remediation R-15-04

**id:** R-15-04
**Linked finding:** F-15-08, NF-15-06
**Severity:** P2
**Spec anchor:** §8.8 — "auto-generates override rules by scanning host stylesheets for `:hover`/`:focus`/`:active`."
**Root cause:** `StatePanel.tsx` implements only the attribute half of §8.8 — `applyStateOverride` toggles `<html data-state-override>` and stops. The spec requires the panel to additionally *scan* `document.styleSheets` and synthesize override rules so the forced state actually takes effect on a host whose CSS does not itself key off `[data-state-override]`. The stylesheet-scan generator was simply never written; `grep 'styleSheets|cssRules' src/runtime` returns nothing.

### Ecosystem analysis
1. What must the generator do? Walk `document.styleSheets` → `cssRules`, find rules whose `selectorText` contains `:hover`/`:focus`/`:active`, and emit a parallel rule scoped under `[data-state-override="<state>"]` with the pseudo-class stripped.
2. Where are generated rules injected? Into a dedicated `<style data-pinscope-state-rules>` element appended to `<head>`, so they are removable and never collide with host CSS.
3. Cross-origin stylesheets throw on `cssRules` access — must the scan guard? Yes — wrap each sheet read in try/catch and skip on `SecurityError`.
4. When does the scan run? On `applyStateOverride('hover'|'focus'|'active')`; cleared (style element emptied/removed) on `'none'`.
5. Does this touch the existing attribute path? No — the attribute toggle stays; the generator is additive.
6. Is this testable without a browser? Yes — jsdom supports `document.styleSheets` and `insertRule`; a test can seed a sheet with a `:hover` rule.

### Execution plan
**Files to modify:** `src/runtime/components/StatePanel.tsx` — the `applyStateOverride` function.
**Files that MUST remain untouched:** the `html.setAttribute('data-state-override', state)` / `removeAttribute` behavior — it is the correct §8.8 attribute mechanism and stays; the generator is layered on top.
**Order of operations:**
1. Add a `generateOverrideRules(state)` helper that scans `document.styleSheets` (try/catch per sheet), collects rules matching `:hover|:focus|:active`, and rewrites each selector under `[data-state-override="<state>"]` with the pseudo removed.
2. In `applyStateOverride`, after the attribute toggle: for a non-`none` state, ensure a `<style data-pinscope-state-rules>` exists and fill it with the generated rules; for `none`, empty it.
**Rollback trigger:** the existing `[data-state-override]` attribute test (AC-040 path) regresses.

### Acceptance criteria
- [ ] `grep -E 'styleSheets|cssRules' src/runtime/components/StatePanel.tsx` returns matches.
- [ ] `applyStateOverride` produces a `[data-pinscope-state-rules]` style element for non-`none` states.
- [ ] Cross-origin sheet access is wrapped in try/catch.

### Definition of Done
A test in `tests/unit/runtime/controls.test.tsx` (or a new `state-panel.test.tsx`) transitions red → green: it inserts a stylesheet containing `.btn:hover { color: red }` into the jsdom document, calls `applyStateOverride('hover')`, then asserts a `[data-pinscope-state-rules]` `<style>` element exists whose text contains a rule selector with `[data-state-override="hover"]` and `.btn` but NOT `:hover`. A second case calls `applyStateOverride('none')` and asserts the generated rules are cleared. Closed when both pass and `npm test` exits 0.

### Dependencies
None — `StatePanel` is mounted by R-15-01 but this hardening is independent of the mount.

### Risk assessment
**Medium** — `cssRules` access semantics differ between jsdom and real browsers; the try/catch guard contains the cross-origin risk. The generator must not infinite-loop on `@import`/nested rules — restrict the scan to top-level `CSSStyleRule` entries.

---

## Remediation R-15-05

**id:** R-15-05
**Linked finding:** F-15-04, NF-15-08
**Severity:** P1
**Spec anchor:** §12 — "hostile CSS (PinScope styles use `!important`)" and "z-index conflicts (PinScope reserves `2147483647`)."
**Root cause:** `badges.css.ts` was written without §12's hardening requirement in mind: the only `!important` declaration is on the `[data-pinscope-ui]` outline rule. Every badge `::before` declaration — `content`, `background`, `position`, `z-index` (2147483645/6/7), `padding`, `border-radius` — is unqualified, so a host page with an equal-or-higher-specificity rule on `[data-pin]::before` or `[data-pin]` can override the badge background, hide it, or push it below host UI. The §12 isolation guarantee was specified but the CSS author never applied it to the badge rules.

### Ecosystem analysis
1. Which declarations must become `!important`? The visually load-bearing ones on `[data-pin]::before`, `:hover::before`, `[data-pin-selected]::before` — `content`, `background`, `position`, `top`, `left`, `z-index`, `padding`, `pointer-events`, and the `[data-pin]:hover`/`[data-pin-selected]` `outline` rules.
2. Does hardening risk breaking the HUD-exempt rule `[data-pinscope-ui] [data-pin]::before { display: none }`? Yes — if badge `display`/`content` becomes `!important` the exempt rule must also be `!important` to still win. The exempt rule and the `@media print` hide rules must therefore also carry `!important`.
3. Does the `@media print { [data-pinscope-ui] { display: none } }` rule need `!important`? Yes — to survive a hostile print stylesheet.
4. Is z-index already correct numerically? Yes — `2147483645/6/7` match §7.2; only the `!important` qualifier is missing.
5. Does this change any AC behavior? AC-023 reads `::before` content text — unaffected by adding `!important`. No regression expected.

### Execution plan
**Files to modify:** `src/runtime/styles/badges.css.ts` — the `badgeCss` template string.
**Files that MUST remain untouched:** the numeric z-index values (`2147483645`, `2147483646`, `2147483647`) and the color rgba values must not change — only the `!important` qualifier is appended. `src/runtime/constants.ts` `Z_SELECTED=2147483647` is already correct and is not edited.
**Order of operations:**
1. Append `!important` to each declaration in the three `::before` blocks (`content`, `background`, `position`, `top`, `left`, `z-index`, `padding`, `border-radius`, `pointer-events`).
2. Append `!important` to the `outline` declarations in `[data-pin]:hover` and `[data-pin][data-pin-selected]`.
3. Append `!important` to `display: none` in the HUD-exempt rule and both `@media print` rules so they still win over the now-hardened badge rules.
**Rollback trigger:** `tests/unit/runtime/overlays.test.tsx` or the AC-023-tagged path regresses.

### Acceptance criteria
- [ ] `grep -c '!important' src/runtime/styles/badges.css.ts` returns a count ≥ 12 (was 1).
- [ ] Every `z-index:` declaration in the file carries `!important`.
- [ ] The `[data-pinscope-ui] [data-pin]::before { display: none }` exempt rule carries `!important`.

### Definition of Done
A grep predicate authored now: `grep -c '!important' src/runtime/styles/badges.css.ts` ≥ 12, AND `grep -E 'z-index: *2147483645 *!important' src/runtime/styles/badges.css.ts` matches, AND `grep -E 'background:.*!important' src/runtime/styles/badges.css.ts` matches for the badge `::before` rule. Additionally a behavioral test in `tests/unit/runtime/overlays.test.tsx` transitions red → green: it injects the `badgeCss` plus a hostile host rule `[data-pin]::before { background: black; z-index: 0 }` into jsdom, renders a `[data-pin]` element, and asserts (via `getComputedStyle` on `::before` where jsdom supports it, else by asserting the `badgeCss` rule's declarations all report `!important` priority through `CSSStyleDeclaration.getPropertyPriority`) that the PinScope background and z-index win. Closed when the grep predicates hold AND `npm test` exits 0.

### Dependencies
None.

### Risk assessment
**Low–Medium** — `!important` is a blunt instrument; the named preservation contract (HUD-exempt + print rules must also become `!important`) prevents the badge from leaking into the HUD or print output. jsdom's partial `::before` computed-style support means the DoD leans on `getPropertyPriority` as the reliable predicate.

---

## Remediation R-15-06

**id:** R-15-06
**Linked finding:** F-15-09, NF-15-07
**Severity:** P2
**Spec anchor:** §8.10 — "writes `.pinscope/snapshots/s_*.json`"; §10 flow D — "persist via dev-server endpoint `/__pinscope/snapshot`."
**Root cause:** `SnapshotManager` was built with a clean injectable `SnapshotStore` boundary, but the only concrete store ever written is `MemorySnapshotStore`. The two named persistence mechanisms — the dev-server endpoint `/__pinscope/snapshot` and the on-disk `.pinscope/snapshots/s_*.json` write — were never implemented. The boundary was designed; the implementation behind it was deferred and never delivered. `grep '__pinscope' src` and `grep 'snapshots/' src` both return nothing.

### Ecosystem analysis
1. What is the §10-D persistence path? `Shift+S` → build Snapshot → POST to dev-server endpoint `/__pinscope/snapshot` → the dev server writes `.pinscope/snapshots/s_*.json`.
2. Where does the endpoint live? In the Vite plugin's dev-server middleware — `src/plugin/` already owns Vite integration; `HistoryManager`'s doc-comment confirms the `runtime/` layer must stay free of `node:fs`, so the file write belongs server-side.
3. What store does the browser runtime use? A new `EndpointSnapshotStore implements SnapshotStore` that `fetch`-POSTs the snapshot JSON to `/__pinscope/snapshot`; `MemorySnapshotStore` stays as the test/fallback store.
4. Does the dev-server middleware exist? `grep '__pinscope' src` → no; a `configureServer` hook (or middleware) must be added to the Vite plugin to register the route and write `s_${id}.json` under `.pinscope/snapshots/`.
5. Is this testable without a browser? The `EndpointSnapshotStore` POST can be unit-tested with a mocked `fetch`; the middleware file write can be unit-tested by invoking the handler with a fake req/res and asserting the file.
6. Does this regress AC-042? No — AC-042 uses an injected test store; the new `EndpointSnapshotStore` is an *additional* implementation, default store unchanged.

### Execution plan
**Files to modify:** `src/plugin/index.ts` — add a dev-server middleware registering `POST /__pinscope/snapshot` that writes the body to `.pinscope/snapshots/s_<id>.json`.
**Files to create:** `src/runtime/managers/EndpointSnapshotStore.ts` — a `SnapshotStore` whose `write` POSTs the snapshot to `/__pinscope/snapshot`.
**Files that MUST remain untouched:** `MemorySnapshotStore` and the `SnapshotStore` interface in `SnapshotManager.ts` — the injectable boundary and the default in-memory store are correct and must not change; `createSnapshot`'s §9.2 shape is correct and stays. The `runtime/` layer must not import `node:fs` — the file write lives only in `src/plugin/`.
**Order of operations:**
1. Create `EndpointSnapshotStore` (browser store, `fetch` POST to `/__pinscope/snapshot`).
2. Add the dev-server route in `src/plugin/index.ts`'s `configureServer` that writes `s_<snapshot.id>.json` into `.pinscope/snapshots/` (mkdir-recursive).
3. Confirm `s_*` filename matches §9.2 (`s_{timestamp}`) — `createSnapshot` already sets `id: s_${Date.now()}`, so write `${snapshot.id}.json`.
**Rollback trigger:** the AC-042 snapshot-schema test regresses, or the Vite plugin shape test (AC-001) regresses.

### Acceptance criteria
- [ ] `grep -rln '__pinscope' src` returns at least `src/plugin/index.ts` and `EndpointSnapshotStore.ts`.
- [ ] `grep -rln 'snapshots/' src/plugin` returns `index.ts`.
- [ ] `EndpointSnapshotStore` implements `SnapshotStore` and POSTs to `/__pinscope/snapshot`.
- [ ] `MemorySnapshotStore` and the `SnapshotStore` interface are unchanged.

### Definition of Done
Two tests transition red → green. (a) A new `tests/unit/runtime/snapshot.test.tsx` case constructs an `EndpointSnapshotStore`, stubs global `fetch`, calls `new SnapshotManager(store).capture('x')`, and asserts `fetch` was called with `/__pinscope/snapshot` and a POST body that JSON-parses to a §9.2-shaped Snapshot. (b) A `tests/unit/plugin.test.ts` (or `deployment.test.ts`) case invokes the dev-server middleware handler with a fake request carrying a snapshot body and asserts a file `s_*.json` was written under a temp `.pinscope/snapshots/` directory with matching content. Closed when both pass AND `grep -rl '__pinscope/snapshot' src` returns ≥ 2 files AND `npm test` exits 0.

### Dependencies
- Soft dependency on R-15-07's dev-server-middleware pattern: both R-15-06 and R-15-07 add a route to `src/plugin/index.ts`'s `configureServer`. If both land in the same wave, serialize this R-item's `configureServer` edit before R-15-07's history-route edit (conflict matrix: both touch `src/plugin/index.ts`). Independent of the root assembly otherwise.

### Risk assessment
**Medium** — introduces a dev-server middleware and a `node:fs` write; the preservation contract keeps the write strictly in `src/plugin/` so the `runtime/` no-`fs` invariant (stated in `HistoryManager.ts`) holds. Path-traversal risk on the snapshot filename is mitigated by deriving the filename from `snapshot.id` (`s_<digits>`), never from untrusted input.

---

## Remediation R-15-07

**id:** R-15-07
**Linked finding:** F-15-07, NF-15-04, NF-15-05
**Severity:** P2
**Spec anchor:** §8.6 — "`fixed; bottom:0; height:40px` (expands to 120px on focus). … Autocomplete for pins/properties/values. … Tab autocomplete … History persisted to `.pinscope/history.json` (last 1000)."
**Root cause:** `CommandBar.tsx` was built to a partial §8.6 contract. Three sub-behaviors share one cause — the component was implemented as a minimal input with a constant 40px height, a per-mount `useRef<string[]>` history, and a key handler covering only Escape/Enter/Arrow keys. The focus-expand, the Tab-autocomplete wiring to the existing `parsers/autocomplete.ts`, and the persistence wiring to the existing `HistoryManager` were all left undone. `autocomplete.ts` (`getSuggestions`) and `HistoryManager` (MAX 1000) already exist — the CommandBar simply never connected to either. One under-built component, three faces.

### Ecosystem analysis
1. How is the 120px expand expressed? A focus boolean in component state drives `style.height` (40 → 120) on `onFocus`/`onBlur`.
2. What does Tab autocomplete call? `getSuggestions(input, pins, properties)` from `src/runtime/parsers/autocomplete.ts` — already built and tested; a `Tab` branch in `onInputKey` applies the first suggestion.
3. Where do `pins` come from? `document.querySelectorAll('[data-pin]')` → the `data-pin` values; `properties` from the `SHORTCUTS` keys or a static property list.
4. How is history persisted? Via `HistoryManager.append` against a store; §8.6 names `.pinscope/history.json`. The browser runtime store is in-memory/dev-server (mirrors R-15-06's snapshot pattern) — the CommandBar must call `HistoryManager` instead of its private `useRef`.
5. Does persisting to `.pinscope/history.json` need a dev-server endpoint? Yes — analogous to R-15-06; a `POST /__pinscope/history` (or reuse a history endpoint) writes the file. The runtime stays `fs`-free.
6. Does the `Cmd+K`/`/` focus path stay? Yes — it is correct §8.6 behavior and is preserved.

### Execution plan
**Files to modify:** `src/runtime/components/CommandBar.tsx` — the `style.height`, the `onInputKey` handler, and the history mechanism. `src/plugin/index.ts` — add the dev-server route that writes `.pinscope/history.json`.
**Files that MUST remain untouched:** the `Cmd+K`/`/` global-focus effect and the Escape/Enter/ArrowUp/ArrowDown branches — their behavior is correct §8.6 and must be preserved; only a focus-expand, a `Tab` branch, and the history backing store are changed. `HistoryManager` and `getSuggestions` are consumed as-is, not edited.
**Order of operations:**
1. Add a `focused` state; `onFocus` sets it true, `onBlur` false; `style.height` becomes `focused ? 120 : 40`.
2. Add a `Tab` branch to `onInputKey`: `e.preventDefault()`, call `getSuggestions(value, pins, properties)`, apply the first suggestion to `value`.
3. Replace the private `useRef<string[]>` history with a `HistoryManager` instance backed by a store that persists to `.pinscope/history.json`; on Enter, `append` an entry; keep ArrowUp/Down navigating that store's `list()`.
4. Add the `POST /__pinscope/history` dev-server route in `src/plugin/index.ts` (mkdir `.pinscope/`, write `history.json`, last 1000 enforced by `HistoryManager`).
**Rollback trigger:** the AC-038 CommandBar focus/history/blur test regresses.

### Acceptance criteria
- [ ] `grep '120' src/runtime/components/CommandBar.tsx` returns a match driving `style.height`.
- [ ] `onInputKey` has a `Tab` branch that calls `getSuggestions`.
- [ ] `grep -E 'HistoryManager|history.json' src/runtime/components/CommandBar.tsx src/plugin/index.ts` returns matches.
- [ ] The `Cmd+K`/`/` focus effect and Escape/Enter/Arrow branches are unchanged.

### Definition of Done
Three test cases (extend `tests/unit/runtime/controls.test.tsx`, CommandBar block) transition red → green. (a) Render `<CommandBar/>`, focus the input, assert the computed/style height is 120; blur, assert 40. (b) Type a partial pin `e_4` (with `data-pin="e_47"` elements present in the DOM), press `Tab`, assert the input value completes to `e_47`. (c) Submit a command with Enter, then assert it was appended through a `HistoryManager` whose store received it (spy on `HistoryManager.append`), and a `tests/unit/plugin.test.ts` case asserts the `/__pinscope/history` middleware writes `.pinscope/history.json` capped at 1000 entries. Closed when all cases pass AND `grep -E 'getSuggestions|HistoryManager' src/runtime/components/CommandBar.tsx` matches AND `npm test` exits 0.

### Dependencies
- Soft dependency on R-15-06's dev-server-middleware pattern: if both land in the same wave, serialize R-15-06's `configureServer` edit to `src/plugin/index.ts` before this R-item's history-route edit to avoid a same-file conflict (conflict matrix: both touch `src/plugin/index.ts`).
- Consumed by R-15-01 (the root mounts `CommandBar`), but the contract here is self-contained.

### Risk assessment
**Medium** — touches `src/plugin/index.ts` (shared with R-15-06) and changes the CommandBar's history backing store. The conflict matrix flags `src/plugin/index.ts` as shared between R-15-06 and R-15-07 — the scheduler must serialize those two intra-wave by the named `configureServer` anchor. Preservation list pins the focus/nav key behavior so AC-038 cannot regress.

---

## Remediation R-15-08

**id:** R-15-08
**Linked finding:** F-15-10, NF-15-09
**Severity:** P3
**Spec anchor:** §15 — "`src/index.ts` re-exports `pinscope`, `withPinScope`, `PinScope`, `useDevState` and the four public types."
**Root cause (SUSPECTED — investigation R-item):** the finding is flagged SUSPECTED because `withPinScope` is reachable via the `pinscope/next` subpath (AC-090) and AC-091's text omits it, raising the possibility that subpath-only scoping is intentional. The candidate root cause, if confirmed, is a simple omission: `withPinScope` exists in `src/plugin/next.ts` and was added to the `./next` export map but never added to the `src/index.ts` package-root barrel. **STEP 1 of this R-item is to confirm or refute, not to assume.**

### Ecosystem analysis
1. What does §15 literally say? Re-read `pinscope/SPEC.md` §15 — the spec text explicitly lists `withPinScope` among the `src/index.ts` re-exports (per the narrative scan's NC-15-02 re-read).
2. Is the spec frozen? Yes — if §15 lists `withPinScope` at the package root, reality (its absence from `index.ts`) is the gap, and the fix is to add the re-export.
3. Does `pinscope/next` already export it? Yes — `package.json` `./next` → `dist/plugin/next.js`; adding it to `index.ts` does not remove the subpath, it adds a second access path.
4. Could re-exporting it from the root pull `next.ts` into the main bundle? `next.ts` imports only a type from `./index.js` (`PinScopeOptions`) and defines a pure function — re-exporting it is tree-shakeable and does not eagerly load webpack/Next internals.
5. Does AC-091 break if `index.ts` gains an export? No — AC-091 checks the three named exports exist; an additional export does not fail it.

### Execution plan
**Step 1 — CONFIRM/REFUTE (mandatory first step):** Re-read `pinscope/SPEC.md` §15. If §15's prose lists `withPinScope` among the *package-root* `src/index.ts` re-exports → finding CONFIRMED, proceed to the fix. If §15 scopes `withPinScope` to the `pinscope/next` subpath only → finding REFUTED; in that case do NOT edit `index.ts`, and instead record a `### Resolution` note in the execution log stating §15 intends subpath-only scoping and the re-read line that proves it.
**Files to modify (only if CONFIRMED):** `src/index.ts` — the export block.
**Files that MUST remain untouched:** `package.json` `exports` map (the `./next` subpath stays); `src/plugin/next.ts` (the `withPinScope` definition is correct and unchanged).
**Order of operations:** add `export { withPinScope } from './plugin/next.js';` alongside the existing `pinscope`/`PinScope`/`useDevState` re-exports.
**Rollback trigger:** the `tests/unit/runtime/public-api.test.ts` suite or any deployment test regresses.

### Acceptance criteria
- [ ] If CONFIRMED: `grep 'withPinScope' src/index.ts` returns a match.
- [ ] If REFUTED: the execution log carries a `### Resolution` note citing the §15 re-read; `src/index.ts` is unchanged.
- [ ] In either branch, `package.json` `./next` subpath still resolves.

### Definition of Done
If CONFIRMED: a test in `tests/unit/runtime/public-api.test.ts` transitions red → green: `import { withPinScope } from '<package root entry>'` (the `.` export, not `./next`) and assert `typeof withPinScope === 'function'`. Closed when that import resolves, the test passes, and `npm test` exits 0. If REFUTED: the R-item is closed by the `### Resolution` note plus a re-read predicate — `grep -n 'withPinScope' pinscope/SPEC.md` shows §15 associates it only with the `pinscope/next` subpath — and `src/index.ts` is verified unchanged (`git diff --stat src/index.ts` empty). Either branch is a valid, verifiable close; the verifier accepts whichever the §15 re-read supports.

### Dependencies
None.

### Risk assessment
**Low** — at most a one-line barrel export. The only real risk is mis-judging intent in Step 1; the mandatory §15 re-read with a cited line resolves it deterministically.

---

## Remediation R-15-09

**id:** R-15-09
**Linked finding:** F-15-11
**Severity:** P3
**Spec anchor:** §9.3 — "`operations[]` items: `{ property, operation: 'set'|'increment'|'decrement'|'remove'|'add-class'|'remove-class', value?, delta? }`."
**Root cause (SUSPECTED — investigation R-item):** flagged SUSPECTED because storing an increment magnitude in `value` may be an intentional simplification. The candidate root cause: `operation-builder.ts`'s `kind === 'operation'` branch unconditionally sets `value: parsed.value` for every operator, including `increment`/`decrement`, so the `delta?` field declared in `src/types/operation.ts` is never populated — an APEX consumer parsing an increment cannot tell a delta from an absolute value. **STEP 1 is to confirm whether §9.3's `delta?` field is meant to carry increment/decrement magnitudes.**

### Ecosystem analysis
1. What does §9.3 intend `delta?` for? Re-read §9.3 — `value?` and `delta?` are listed as distinct optional fields on every `OperationItem`; the natural reading is `value` for `set` and `delta` for `increment`/`decrement`.
2. Does the parser distinguish the operators? Yes — `operation-parser.ts` produces `op: 'increment'|'decrement'|'set'` distinctly; the builder collapses them.
3. Is `delta` typed as a number? Yes — `OperationItem.delta?: number`; `parsed.value` is a string, so a numeric coercion is needed when routing to `delta`.
4. What about non-numeric increment values? If `parsed.value` does not parse to a finite number, fall back to `value` (string) — never produce a `NaN` delta.
5. Does AC-052 break? No — AC-052 validates the §9.3 schema; populating `delta` instead of `value` for increments is still schema-valid (both optional).
6. Does the round-trip example (R-15-11's replacement) depend on `value`? The `examples/roundtrip/scenario.ts` uses `padding-y → 12px` (a `set`) — unaffected; only increment/decrement routing changes.

### Execution plan
**Step 1 — CONFIRM/REFUTE (mandatory first step):** Re-read `pinscope/SPEC.md` §9.3. If §9.3 intends `delta?` to carry the numeric magnitude of `increment`/`decrement` operations → CONFIRMED, proceed. If §9.3's text supports `value?` being correct for all kinds and `delta?` serving another purpose → REFUTED; record a `### Resolution` note citing the §9.3 line and leave `operation-builder.ts` unchanged.
**Files to modify (only if CONFIRMED):** `src/runtime/parsers/operation-builder.ts` — the `parsed.kind === 'operation'` branch building the `OperationItem`.
**Files that MUST remain untouched:** `src/types/operation.ts` (`delta?` is already declared correctly); the `class` and `query` branches of `buildOperation`; the `set` operator's behavior (it must still populate `value`).
**Order of operations:** in the `operation` branch, when `parsed.op` is `increment` or `decrement`, parse `parsed.value` to a number; if finite, set `delta: <number>` and omit `value`; otherwise keep `value`. When `parsed.op` is `set`, keep `value` exactly as today.
**Rollback trigger:** the AC-052 operation-schema test or `tests/unit/operation-builder.test.ts` regresses.

### Acceptance criteria
- [ ] If CONFIRMED: `grep 'delta' src/runtime/parsers/operation-builder.ts` returns a match.
- [ ] An `increment`/`decrement` `OperationItem` carries `delta` (number), not `value`, when the magnitude is numeric.
- [ ] A `set` `OperationItem` still carries `value`.
- [ ] If REFUTED: a `### Resolution` note cites the §9.3 re-read; `operation-builder.ts` unchanged.

### Definition of Done
If CONFIRMED: a test in `tests/unit/operation-builder.test.ts` transitions red → green: `buildOperation(parseCommand('e_47.padding +-> 4'), ctx)` yields `operations[0].delta === 4` and `operations[0].value === undefined`; a control case `buildOperation(parseCommand('e_47.padding -> 12px'), ctx)` yields `operations[0].value === '12px'` and `operations[0].delta === undefined`. Closed when both pass and `npm test` exits 0. If REFUTED: closed by the `### Resolution` note and the predicate `git diff --stat src/runtime/parsers/operation-builder.ts` empty plus a cited §9.3 line.

### Dependencies
None.

### Risk assessment
**Low** — a single localized branch change; the `set` path and the schema-level optionality of both fields mean AC-052 cannot regress. Numeric-coercion guard prevents a `NaN` delta.

---

## Remediation R-15-10

**id:** R-15-10
**Linked finding:** TEST-AUDIT-R15 — AC-076 hollow test
**Severity:** P2
**Spec anchor:** §4 / resolution I-4 — "`html2canvas` … loads only when a screenshot is actually requested" (lazy dynamic import).
**Root cause:** `tests/unit/screenshot.test.ts` was authored as a source-text grep — it `fs.readFileSync`s `src/runtime/utils/screenshot.ts` and regex-matches the string `import('html2canvas')`. It never imports, instantiates, or executes `captureScreenshot`. The root cause is a test-design shortcut: lazy-loading is an *observable runtime behavior* (the module is not fetched until `captureScreenshot` runs), but the test asserts on source shape instead. A refactor that keeps the token but breaks laziness still passes; a correct lazy import written differently fails. This is the green-but-hollow state the loop must not treat as converged.

### Ecosystem analysis
1. What is the real behavior to assert? `captureScreenshot` must not cause `html2canvas` to load until it is called, and when called it must produce a PNG data URL via a dynamically-imported `html2canvas`.
2. How is "loaded lazily" observable in a test? Mock the `html2canvas` module; assert the mock factory is NOT invoked at import time of `screenshot.ts`, and IS invoked exactly once when `captureScreenshot` is called.
3. Does vitest support this? Yes — `vi.mock('html2canvas', factory)` with a spy on the factory, or a dynamic-import counter; assert call timing relative to `captureScreenshot`.
4. What must the replacement NOT do? It must not read the source file as text and must not assert on token presence.
5. Does the production-zero guarantee interact? `html2canvas` staying out of the initial chunk is what AC-076 protects — the behavioral test exercising deferred import is the genuine proof.

### Execution plan
**Files to modify:** `tests/unit/screenshot.test.ts` — replace its entire body.
**Files that MUST remain untouched:** `src/runtime/utils/screenshot.ts` — the implementation already does a correct `await import('html2canvas')`; this R-item fixes only the test, not the code. (If the new behavioral test fails against the current correct implementation, that is a test-authoring bug to fix in the test, not the source.)
**Order of operations:**
1. Delete the two source-grep `it` blocks and the `fs.readFileSync` of `screenshot.ts`.
2. Add a behavioral suite: `vi.mock('html2canvas', ...)` with a spy; import `captureScreenshot`; assert the `html2canvas` factory/spy has zero calls immediately after import; call `captureScreenshot` on a stub element; assert the spy was then called exactly once and the result is a `data:image/png` string.
**Rollback trigger:** the new test fails against the unmodified, known-correct `screenshot.ts` (indicates the test, not the code, is wrong).

### Acceptance criteria
- [ ] `tests/unit/screenshot.test.ts` no longer contains `readFileSync` or a regex over source text.
- [ ] The test imports and executes `captureScreenshot`.
- [ ] The test asserts `html2canvas` is not invoked before `captureScreenshot` is called.

### Definition of Done
`grep -E 'readFileSync|toMatch' tests/unit/screenshot.test.ts` returns NO match (the source-grep pattern is gone), AND `grep 'captureScreenshot' tests/unit/screenshot.test.ts` returns a match (the module is exercised). The replaced test must be a genuine red/green dual: it passes against the current correct `screenshot.ts` and would FAIL if `captureScreenshot` were rewritten to a static top-level `import html2canvas from 'html2canvas'`. Closed when the AC-076-tagged test in `screenshot.test.ts` passes as a behavioral test and `npm test` exits 0.

### Dependencies
None.

### Risk assessment
**Low** — test-only change. The rollback trigger explicitly guards against the test being authored stricter than the (correct) implementation.

---

## Remediation R-15-11

**id:** R-15-11
**Linked finding:** TEST-AUDIT-R15 — AC-107 hollow test
**Severity:** P2
**Spec anchor:** §1 / §17.6 — "95% of UI requests resolved in ≤ 2 communication rounds"; round-trip end-state "average communication rounds per UI change < 2."
**Root cause:** `tests/unit/roundtrip.test.ts` imports `runScenario` from `examples/roundtrip/scenario.ts` — a bundled demo script — and asserts `result.rounds === 1`, a value the demo script itself computes and emits. The test is self-fulfilling: it verifies the example produces the number the example was written to produce, not that the framework's `parseCommand` → `buildOperation` round-trip path guarantees a ≤ 2-round resolution. The root cause is that the AC was wired to a demo rather than to the production code path; a green AC-107 here demonstrates the example, not the §1 guarantee.

### Ecosystem analysis
1. What is the real round-trip path? `parseCommand` (`operation-parser.ts`) → `buildOperation` (`operation-builder.ts`) → an `Operation` complete enough that an executor needs no clarifying round.
2. What makes an Operation "1-round complete"? A non-empty `pin`, `request_type === 'operation'`, and at least one `operations[]` item carrying a concrete `value`/`delta` — exactly the `complete` predicate currently buried inside the demo `scenario.ts`.
3. Why is asserting the demo hollow? `scenario.ts` itself computes `rounds = complete ? 1 : 2` — the test re-reads the demo's own output; it never re-derives completeness from the framework primitives.
4. What is the genuine test? Call `parseCommand` + `buildOperation` directly (the production primitives), then assert on the resulting `Operation` shape — the test must own the completeness logic, not import it from the demo.
5. Must the test cover the negative? Yes — a genuine red/green dual needs an under-specified input (e.g. a vague/non-operation command) that yields a ≥ 2-round (incomplete) result, proving the assertion can fail.
6. Does this replace `examples/roundtrip/scenario.ts`? No — the example stays as a demo; the *test* stops depending on it.

### Execution plan
**Files to modify:** `tests/unit/roundtrip.test.ts` — replace its body to exercise the production primitives directly.
**Files that MUST remain untouched:** `examples/roundtrip/scenario.ts` — it is a sanctioned demo and may keep its own logic; this R-item only severs the *test*'s dependency on it. `src/runtime/parsers/operation-parser.ts` and `operation-builder.ts` are exercised, not edited.
**Order of operations:**
1. Remove the `import { runScenario } from '../../examples/roundtrip/scenario.js'`.
2. Import `parseCommand` and `buildOperation` directly from `src/runtime/parsers/`.
3. Positive case: parse `e_47.padding-y → 12px`, build the Operation with a test `BuildContext`, and assert — with completeness logic owned by the test — that the Operation has a non-empty `pin`, `request_type === 'operation'`, and an `operations[0]` carrying a concrete `value`/`delta`; conclude ≤ 2 rounds.
4. Negative case: feed a non-operation/under-specified command (e.g. a bare `? layout` query or a `select` form) and assert the result is NOT a 1-round complete operation — proving the test can fail.
**Rollback trigger:** the new test fails against the current, known-correct parser/builder (indicates a test-authoring bug).

### Acceptance criteria
- [ ] `tests/unit/roundtrip.test.ts` no longer imports from `examples/roundtrip/`.
- [ ] The test imports `parseCommand` and `buildOperation` from `src/runtime/parsers/`.
- [ ] The test contains both a 1-round-complete positive case and a ≥ 2-round negative case.

### Definition of Done
`grep 'examples/roundtrip' tests/unit/roundtrip.test.ts` returns NO match, AND `grep -E 'operation-parser|operation-builder' tests/unit/roundtrip.test.ts` returns matches (production primitives exercised). The AC-107-tagged test is a genuine red/green dual: the positive case passes against the current parser/builder, and the negative case demonstrates the ≤ 2-round assertion can fail for an incomplete Operation. Closed when the rewritten AC-107 test passes AND `npm test` exits 0.

### Dependencies
- Soft relation to R-15-09: if R-15-09 changes increment/decrement routing to `delta`, the round-trip completeness predicate in this test must accept `delta` as well as `value` as evidence of a concrete operation. If both land in the same wave, author this test's completeness check to treat `value !== undefined || delta !== undefined` as complete. No file conflict (different files).

### Risk assessment
**Low** — test-only change. The negative case is the safeguard against re-authoring another self-fulfilling test; the rollback trigger guards against the test being stricter than the correct primitives.
</content>
</invoke>
