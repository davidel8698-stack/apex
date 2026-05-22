# Wave Map — PS-R20

## Plan validation

`ACCEPTED`

Gate result for `REMEDIATION-PLAN-R20.md` (5 R-items, R-20-01 … R-20-05):

- **Mandatory sections.** All five R-items carry the six mandatory sections —
  Ecosystem analysis, Execution plan, Acceptance criteria, Definition of Done,
  Dependencies, Risk assessment. R-20-04 additionally carries a `### Resolution`
  block; that is an extra, not a substitute, so no section is missing.
- **Root cause, not symptom.** R-20-01/02/03 trace to one shared root cause —
  `PinScopeHud` authored as a pure-render shell with zero `useEffect`, so every
  imperative HUD mechanism was never integrated into the live `<PinScope/>`
  tree. Each fix mounts/wires the mechanism, not a symptom patch. R-20-04 and
  R-20-05 are SUSPECTED investigation R-items with hypothesised root causes and
  an explicit STEP-1 confirm-or-refute branch — appropriate for SUSPECTED
  findings, not symptom fixes.
- **Definition of Done.** Every DoD is mechanically checkable by a reader who
  never saw the change: named RTL tests with a required red→green transition
  (R-20-01/02/03/05), grep predicates, `git diff --stat` file-count assertions,
  and `npm test` / `npm run typecheck` exit codes (R-20-04/05). None merely
  restates the finding; none says "looks right".
- **No silent scope reduction.** `audit-findings-R20.json` has `findings: []`
  and five `investigation_findings` F-20-01 … F-20-05;
  `narrative-scan-R20.json` has `blocking_findings: []` and
  `uncovered_unsatisfied: 0`. The plan maps exactly one R-item to each
  investigation finding (R-20-01↔F-20-01, R-20-02↔F-20-02, R-20-03↔F-20-03,
  R-20-04↔F-20-04, R-20-05↔F-20-05). All five covered; nothing owed for
  narrative blocking findings. No finding is dropped.
- **No line-number anchors.** `grep -nE '\.(tsx|ts|md|sh|json):[0-9]+'` and a
  line-range scan over the plan body both return zero hits. The plan body uses
  content anchors only (`<div data-pinscope-ui="root">` block, the
  `useKeyboardShortcuts` handler object, `CrosshairProps`, `isLocalOnlyCommand`,
  `RE_MEASURE`, identifier names). Line numbers appear only inside the cited
  audit findings, which is permitted (frozen snapshot).

The plan is scheduled below.

## Dependency analysis

Files touched, by R-item:

- **R-20-01** — `pinscope/src/runtime/PinScope.tsx` (add `VoidBadges` import;
  mount `<VoidBadges/>` in the visible-HUD `createPortal` tree).
- **R-20-02** — `pinscope/src/runtime/PinScope.tsx` (add `RuntimePinObserver`
  and `useEffect` imports; add the lifecycle `useEffect` that `start()`s on
  mount and `stop()`s on cleanup).
- **R-20-03** — `pinscope/src/runtime/PinScope.tsx` (two `useState` cells, two
  `useKeyboardShortcuts` handler entries, prop wiring),
  `pinscope/src/runtime/components/Crosshair.tsx` (`enabled` prop + disable
  guard), `pinscope/src/runtime/components/PinBadges.tsx` (`visible` prop /
  conditional render path).
- **R-20-04** — no `src/` file (investigation R-item; STEP-1 confirm-or-refute,
  expected outcome is a no-code-change `### Resolution`).
- **R-20-05** — `pinscope/tests/unit/runtime/controls.test.tsx` (two new
  CommandBar Enter-path test cases; test-only, production code untouched).

Blocking relationships:

- **No true logical dependency exists between any two R-items.** R-20-04 and
  R-20-05 are explicitly independent of all others (plan §Dependencies). Within
  the shared-root-cause group, none of R-20-01/02/03 reads another's *output*
  in its final form — each adds an independent, additive piece to
  `PinScopeHud`. The only coupling is co-location: all three edit the same file.
- **Write-serial coupling (the binding constraint).** R-20-01, R-20-02 and
  R-20-03 all modify `pinscope/src/runtime/PinScope.tsx`. STEP 3's
  one-file-one-owner-per-wave rule forbids two of them sharing a wave. The plan
  prose suggests they "share Wave 1 and serialize on the `PinScopeHud` body";
  STEP 3 governs and overrides that — they must be split across three waves.
  This is a write-serialization ordering, not a logical dependency: the
  scheduler imposes the order to keep each file single-owner per wave.
- **Chosen serialization order: R-20-01 → R-20-02 → R-20-03.** This follows the
  plan's own "Order of operations" hints. R-20-03's `pinsVisible` gate is
  designed to also cover the `<VoidBadges/>` layer that R-20-01 mounts (plan
  R-20-03 §Dependencies: "if R-20-01 lands first, extend the `pinsVisible` gate
  to cover `<VoidBadges/>` too"). Sequencing R-20-01 before R-20-03 lets that
  extension land cleanly; R-20-02 (the observer `useEffect`) is order-neutral
  and slots in the middle.
- **Layering (`pinscope/SPEC.md` §1–§17).** All of R-20-01/02/03 are §7 runtime
  fixes; R-20-04 is a §9/§10 investigation; R-20-05 is a §8.6/§9.4 test-only
  item. No build-module → runtime → APEX-integration cross-layer ordering is
  triggered this round — every code-touching item is runtime or test.

## Waves

Three waves. Wave 1 carries the two non-`PinScope.tsx` items plus the first of
the serialized trio; Waves 2 and 3 each carry one further `PinScope.tsx` owner.
Wave sizes are below the 5–8 target only because the dominant constraint this
round is write-serialization on a single file — three R-items contend for
`PinScope.tsx` and cannot be parallelized.

### Wave 1 — R-20-01, R-20-04, R-20-05

- **R-20-01** — files: `pinscope/src/runtime/PinScope.tsx`.
- **R-20-04** — files: none (investigation R-item; STEP-1 confirm-or-refute).
- **R-20-05** — files: `pinscope/tests/unit/runtime/controls.test.tsx`.
- One-owner check: the three R-items touch three disjoint paths
  (`PinScope.tsx`, no file, `controls.test.tsx`). No collision.
- Dependency check: none of the three depends on an R-item in a later wave.
- **Gate check:** `cd pinscope && npm run typecheck` exits 0 and
  `npm test` is green; R-20-01's named `VoidBadges`-in-`<PinScope/>` RTL test is
  green; R-20-05's two new CommandBar Enter-path cases are green against
  unmodified `CommandBar.tsx`; R-20-04's STEP-1 verdict is recorded and
  `git diff --stat` shows 0 `pinscope/src/` files changed by R-20-04. Wave 2
  does not start until this gate passes.

### Wave 2 — R-20-02

- **R-20-02** — files: `pinscope/src/runtime/PinScope.tsx`.
- One-owner check: sole R-item in the wave — `PinScope.tsx` has exactly one
  owner. Held out of Wave 1 only because R-20-01 already owns `PinScope.tsx`
  there.
- Dependency check: R-20-02 is order-neutral; it is placed after R-20-01 purely
  to keep `PinScope.tsx` single-owner per wave.
- **Gate check:** `cd pinscope && npm run typecheck` exits 0 and `npm test` is
  green; R-20-02's named MutationObserver RTL test (runtime `e_r{N}` assignment
  + observer-disconnected-after-unmount) is green; no "observer leaked after
  unmount" warning surfaces. Wave 3 does not start until this gate passes.

### Wave 3 — R-20-03

- **R-20-03** — files: `pinscope/src/runtime/PinScope.tsx`,
  `pinscope/src/runtime/components/Crosshair.tsx`,
  `pinscope/src/runtime/components/PinBadges.tsx`.
- One-owner check: sole R-item in the wave — each of the three files has
  exactly one owner. Placed last so its `pinsVisible` gate can extend over the
  `<VoidBadges/>` layer mounted by R-20-01 (Wave 1) without a same-wave
  `PinScope.tsx` collision.
- Dependency check: all upstream R-items (R-20-01, R-20-02) are in waves < 3.
- **Gate check:** `cd pinscope && npm run typecheck` exits 0 and `npm test` is
  green; R-20-03's named `Shift+P` / `Shift+C` real-`<PinScope/>` toggle test
  (both halves red→green); the existing AC-035 Crosshair tests in
  `controls.test.tsx` / `overlays.test.tsx` still pass; the §8.11 real-HUD
  functional ratio reaches 13/13.

## Conflict matrix

File → R-items that touch it, and the wave each is in. No file is touched by
two R-items inside the same wave.

| File | R-20-01 | R-20-02 | R-20-03 | R-20-04 | R-20-05 |
|---|---|---|---|---|---|
| `pinscope/src/runtime/PinScope.tsx` | W1 | W2 | W3 | — | — |
| `pinscope/src/runtime/components/Crosshair.tsx` | — | — | W3 | — | — |
| `pinscope/src/runtime/components/PinBadges.tsx` | — | — | W3 | — | — |
| `pinscope/tests/unit/runtime/controls.test.tsx` | — | — | — | — | W1 |
| (no file — investigation) | — | — | — | W1 | — |

Intra-wave collision check:

- **Wave 1:** R-20-01 owns `PinScope.tsx`; R-20-05 owns `controls.test.tsx`;
  R-20-04 owns no file. Three disjoint owners — no collision.
- **Wave 2:** R-20-02 alone — single owner of `PinScope.tsx`.
- **Wave 3:** R-20-03 alone — single owner of `PinScope.tsx`,
  `Crosshair.tsx`, and `PinBadges.tsx`.

`PinScope.tsx` is contended by R-20-01/02/03; the three appear in three
different waves (W1/W2/W3), so the one-file-one-owner-per-wave rule holds. No
other file is multiply owned.
