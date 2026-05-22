# Wave Map — PS-R17

## Plan validation

**ACCEPTED.**

`REMEDIATION-PLAN-R17.md` carries 3 R-items (R-17-01, R-17-02, R-17-03).
STEP 1 plan-gate result, checked against `framework/docs/REMEDIATION-STYLE.md`:

- **Mandatory sections.** Every R-item has all six mandatory sections —
  Linked finding / Severity / Root cause / Spec anchor header, Ecosystem
  analysis, Execution plan, Acceptance criteria, Dependencies, Risk
  assessment, plus a Definition of Done. R-17-02 and R-17-03 additionally
  carry a "STEP 1 — Confirm or refute" block (their findings are SUSPECTED);
  that is extra rigor, not a missing section.
- **Root cause, not symptom.** Each fix targets the root cause its own
  analysis names: R-17-01 removes the duplicated, unshared `SelectionManager`
  ownership (not "wire up `select`"); R-17-02 adds the missing
  error-observation step flow D lacks vs flow C (not "catch somewhere");
  R-17-03 lifts `StatePanel`'s component-local override state to the common
  `PinScopeHud` parent (not "edit the TopBar readout").
- **Definition of Done.** Each DoD names a specific test, in a specific file,
  with a red→green transition and a mechanically-checkable assertion, backed
  by `grep` predicates a reviewer who never saw the diff can run. None merely
  restates the finding; none hollow.
- **Silent scope reduction.** Binding scope = the 3 spec-auditor findings.
  `audit-findings-R17.json` reports `findings: []` and three
  `investigation_findings` — F-17-01, F-17-02, F-17-03 — all three routed
  one-to-one (F-17-01 -> R-17-01, F-17-02 -> R-17-02, F-17-03 -> R-17-03).
  `narrative-scan-R17.json` `blocking_findings` is empty and
  `uncovered_unsatisfied` is 0 — nothing required from the narrative axis.
  `TEST-AUDIT-R17.md` verdict is WARN (advisory, non-blocking) — no mandatory
  finding; its two advisories are AC-075 (left unaddressed, advisory-only,
  shares no files with any finding) and AC-037 (folded into R-17-03's DoD as a
  side-effect resolution). No finding is dropped. No scope reduction.
- **Line-number anchors.** No raw `file:line` references in the plan bodies.
  R-items point with content anchors — the `command` `useMemo`, the `onSubmit`
  `select` branch, the `onSnapshot` callback, the `<TopBar>` / `<StatePanel>`
  JSX. (Line numbers appear only inside `audit-findings-R17.json`, a frozen
  audit snapshot — permitted by REMEDIATION-STYLE.md.)

No rejection trigger fires. The plan is scheduled.

## Dependency analysis

Three R-items, **no functional dependency edge among them** — verified
against each R-item's own "Dependencies" section and confirmed by re-reading
the code:

- **R-17-01** (P2, F-17-01 CONFIRMED) edits `useSelectedElement.ts` (the hook)
  and `PinScope.tsx` at the `command` `useMemo` (removes the orphan
  `selection: new SelectionManager()`), the `onSubmit` `select` branch
  (`parsed.kind === 'select'`), and the `useSelectedElement` call site.
- **R-17-02** (P2, F-17-02 SUSPECTED) edits `PinScope.tsx` at the `onSnapshot`
  `useCallback` (`command.snapshots.capture`), and optionally the `command`
  `useMemo` (option (a): a store reference) **or** `SnapshotManager.ts`
  (option (b): a `flush()` passthrough).
- **R-17-03** (P3, F-17-03 SUSPECTED) edits `StatePanel.tsx` (adds an
  `onStateChange` callback) and `PinScope.tsx` at the `PinScopeHud` `useState`
  block and the `<StatePanel>` / `<TopBar>` JSX (replaces the hardcoded
  `stateOverride={null}`).

No R-item edits a file another R-item must read in its post-fix form: the
managers (`SelectionManager.ts`, `EndpointSnapshotStore.ts`) and `TopBar.tsx`
are all on every R-item's "MUST remain untouched" list, so no producer ->
consumer edge exists. The §1–§17 layering test is satisfied — all three are
runtime-layer fixes at the same tier; none is a build-module fix that another
runtime fix would depend on. **Dependency graph: three isolated nodes, zero
edges.**

The decisive constraint is therefore **not** dependency ordering but
**write-serial safety**. All three R-items modify the single file
`src/runtime/PinScope.tsx`. The contract is absolute — *no two R-items in the
same wave may modify the same file; one file = one owner per wave*. The
disjoint-anchor note in R-17-03's "Dependencies" section ("R-17-01 the
`command` `useMemo` + the `onSubmit` `select` branch, R-17-02 the `onSnapshot`
callback, R-17-03 the `PinScopeHud` `useState` block + the `<StatePanel>` /
`<TopBar>` JSX") describes intra-file *anchors*, not separate files: anchors
do not lift the one-owner-per-wave rule. The three `PinScope.tsx` edits MUST
be serialized across **three separate waves**.

With no dependency edges, wave ordering is free; it is fixed only by the
write-serial split. Sequence chosen by severity and by the planner's
observation that R-17-01 removes a dead `SelectionManager` instance the other
R-items reason about: **R-17-01 (P2, CONFIRMED) -> R-17-02 (P2, SUSPECTED) ->
R-17-03 (P3, SUSPECTED)**. This lands the highest-severity confirmed defect
and the orphan-instance removal first, so Waves 2 and 3 plan against a
PinScope.tsx with one canonical `SelectionManager`.

## Waves

Three waves, one R-item each. This is the correct shape, not a defect: when
every R-item legitimately touches one shared file, single-R-item waves are
mandatory under the write-serial rule.

### Wave 1 — R-17-01

- **R-items:** R-17-01 (P2, F-17-01 CONFIRMED).
- **Files touched:**
  - `src/runtime/hooks/useSelectedElement.ts` — the `useSelectedElement` hook
    (adds a `select` member to `SelectedElement` and its return).
  - `src/runtime/PinScope.tsx` — the `command` `useMemo` (drops the orphan
    `selection` key), the `onSubmit` `select` branch, the `useSelectedElement`
    call-site destructure.
- **Gate check:** Wave 1 = R-items with no dependency on another R-item this
  round — R-17-01 has none. Write-serial: R-17-01 is the sole owner of both
  `useSelectedElement.ts` and `PinScope.tsx` in this wave. PASS.

### Wave 2 — R-17-02

- **R-items:** R-17-02 (P2, F-17-02 SUSPECTED — STEP 1 confirm/refute runs
  first; if refuted the R-item closes as a `### Resolution` with no code
  change and this wave is a no-op).
- **Files touched:**
  - `src/runtime/PinScope.tsx` — the `onSnapshot` `useCallback`; optionally
    the `command` `useMemo` (option (a) store reference).
  - *Conditionally* `src/runtime/managers/SnapshotManager.ts` — only if the
    planner's option (b) `flush()` passthrough is chosen instead of option
    (a). Either option keeps Wave 2 the sole owner of every file it touches.
- **Gate check:** R-17-02's only dependency-eligible blocker would be another
  R-item editing a file it must read post-fix — none exists. It is split out
  of Wave 1 **purely** to satisfy write-serial safety on `PinScope.tsx`
  (R-17-01 owns `PinScope.tsx` in Wave 1). In Wave 2, R-17-02 is the sole
  owner of `PinScope.tsx` (and of `SnapshotManager.ts` if option (b)). PASS.

### Wave 3 — R-17-03

- **R-items:** R-17-03 (P3, F-17-03 SUSPECTED — STEP 1 confirm/refute runs
  first; if refuted the R-item closes as a `### Resolution` with no code
  change and this wave is a no-op).
- **Files touched:**
  - `src/runtime/components/StatePanel.tsx` — the `StatePanel` component
    (adds the optional `onStateChange` callback prop, invoked in `choose`).
  - `src/runtime/PinScope.tsx` — the `PinScopeHud` `useState` block (new
    `stateOverride` state) and the `<StatePanel>` / `<TopBar>` JSX (wires
    `onStateChange`, replaces `stateOverride={null}` with the live value).
- **Gate check:** R-17-03 has no dependency on R-17-01 or R-17-02. It is
  assigned to Wave 3 **purely** to satisfy write-serial safety on
  `PinScope.tsx` (owned by R-17-01 in Wave 1, R-17-02 in Wave 2). In Wave 3,
  R-17-03 is the sole owner of both `StatePanel.tsx` and `PinScope.tsx`. PASS.

## Conflict matrix

Files touched, by R-item (files, not line ranges, per REMEDIATION-STYLE.md):

| File | R-17-01 | R-17-02 | R-17-03 |
|------|---------|---------|---------|
| `src/runtime/PinScope.tsx` | W1 | W2 | W3 |
| `src/runtime/hooks/useSelectedElement.ts` | W1 | — | — |
| `src/runtime/managers/SnapshotManager.ts` | — | W2 (option b only) | — |
| `src/runtime/components/StatePanel.tsx` | — | — | W3 |

`src/runtime/PinScope.tsx` is touched by all three R-items — the round's only
shared-file collision. It is resolved by assigning each of R-17-01, R-17-02,
R-17-03 to a distinct wave (W1, W2, W3 respectively): in every wave exactly
one R-item owns `PinScope.tsx`. No other file is touched by more than one
R-item. **No intra-wave file collision in any of the three waves.**

Files on every R-item's preservation ("MUST remain untouched") list and
verified not edited by any wave: `src/runtime/managers/SelectionManager.ts`,
`src/runtime/managers/EndpointSnapshotStore.ts`,
`src/runtime/components/TopBar.tsx`.
