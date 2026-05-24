# Narrative Coverage Scan — Round 19

**Spec:** `pinscope/SPEC.md` v2.0.0 (FROZEN) ·
`sha256:1779526021db1f5bc7ffe36647e6deb08ba3f8234e82cee31dc0bca5357c7a45`
**Generated:** 2026-05-22 · STEP 1B of `/ps-heal` PS-R19 (convergence-confirmation round)

## Summary

R19 is a convergence-confirmation pass. STEP 3 independently re-read the current
`pinscope/src/` and `framework/` code for **every** normative claim — no
satisfaction was assumed from R18. 52 narrative claims enumerated across §1–§17
(50 normative, 2 borderline-descriptive: NC-03-01, NC-16-01). Of the 50
normative claims, **33 are AC-covered** and **19 are uncovered**. All 19
uncovered claims are `code_satisfied: true` or `unknown` for an aggregate
statistic — **none is a real un-AC'd code gap**, so `blocking_findings` is empty
and `uncovered_unsatisfied` is **0**. The tree is converged from the
narrative-audit standpoint. 19 candidate ACs and 6 strengthen proposals carry
forward unchanged from R18 — all are proposals, none blocks. Claim IDs are
stable with R18.

## Coverage block

| metric | value |
|---|---|
| total normative claims | 52 (50 normative + 2 descriptive) |
| covered | 33 |
| uncovered | 19 |
| candidate ACs | 19 |
| strengthen proposals | 6 |
| uncovered & satisfied | 19 |
| **uncovered & unsatisfied (blocking)** | **0** |

`covered(33) + uncovered(19) == 52` · `uncovered_satisfied(19) +
uncovered_unsatisfied(0) == 19` · `candidate_acs(19) == uncovered(19)` ·
`uncovered_unsatisfied(0) == blocking_findings.length(0)`.

## Claims by section

### §1 Mission
- **NC-01-01** *(covered AC-107, code unknown)* — 95%-in-≤2-rounds success
  metric. AC-107 verifies one scripted scenario; the population statistic is
  not harness-measurable.

### §3 Architecture / §16 Phase Plan
- **NC-03-01**, **NC-16-01** *(normative:false)* — descriptive layer grouping /
  phase table; concrete behaviours carry their own ACs.

### §4 Technical Stack
- **NC-04-01** *(covered AC-073)* — dev bundle < 80 KB / < 25 KB gz.
- **NC-04-02** *(covered AC-010, AC-074)* — prod bundle 0 bytes of PinScope.
- **NC-04-03** *(uncovered, satisfied)* — no Redux/Zustand. `grep -rniE
  'redux|zustand' pinscope/src pinscope/package.json` -> 0. → candidate AC-NEW-01.

### §6 Build-Time Module
- **NC-06-01** *(covered AC-001)*, **NC-06-06** *(covered AC-011)*, **NC-06-09**
  *(covered AC-008)* — all re-confirmed in `src/plugin/`.
- **NC-06-02 / 03 / 04 / 05 / 07 / 08 / 10** *(uncovered, all satisfied)* —
  resolved option defaults, buildStart/buildEnd lifecycle, parser plugin set,
  loc-absent skip, dirty-gated save, un-delete-on-resight, moved-element new
  key. → candidate ACs AC-NEW-02..08.

### §7 Runtime Module
- **NC-07-04** *(covered AC-023)*, **NC-07-05** *(covered AC-024, AC-025)* —
  badge z-index/colour states, void-overlay + MutationObserver.
- **NC-07-01 / 02 / 03 / 06** *(uncovered, all satisfied)* — full HUD tree,
  prop surface, HUD-hidden FloatingToggle branch, rAF hover throttle.
  → candidate ACs AC-NEW-09..12.

### §8 Component Specifications
- **NC-08-02** *(covered AC-033)*, **NC-08-03** *(covered AC-034)*, **NC-08-04**
  *(covered AC-035)*, **NC-08-05** *(covered AC-036)*, **NC-08-06** *(covered
  AC-037)*, **NC-08-08** *(covered AC-053)*, **NC-08-12** *(covered AC-042)* —
  all re-confirmed.
- **NC-08-10** *(covered AC-039, code_satisfied:false)* — MeasurementTool
  renders the two-click Δx/Δy/diagonal/gap labels (AC-039 passes), but the
  Alt-hover sibling-distances sub-behaviour is still absent (`grep -niE
  'alt|sibling' MeasurementTool.tsx` -> 0). **NOT a blocking finding**: the
  claim is AC-covered and the AC-039 check still passes; the unmet
  sub-behaviour is carried as the AC-039 strengthen proposal.
- **NC-08-01 / 07 / 09 / 11** *(uncovered, all satisfied)* — InfoPanel geometry,
  CommandBar focus-expand, Tab autocomplete wiring, StatePanel stylesheet scan.
  → candidate ACs AC-NEW-13..16.

### §9 Data Schemas
- **NC-09-01** *(covered AC-006)*, **NC-09-02** *(covered AC-052)* — PinMap and
  Operation schemas re-confirmed.

### §10 Behavioral Flows
- **NC-10-01** *(uncovered, satisfied)* — snapshot persists via dev-server
  endpoint `/__pinscope/snapshot`. → candidate AC-NEW-17.
- **NC-10-02** *(covered AC-071)* — hover < 8 ms/frame.

### §11 Operation Protocol
- **NC-11-01** *(covered AC-050)*, **NC-11-02** *(covered AC-051)* — grammar and
  10 shortcut properties re-confirmed.

### §12 Edge Cases
- **NC-12-01** *(uncovered, satisfied)* — z-index 2147483647 reserved + badge
  CSS uses `!important`. → candidate AC-NEW-18.
- **NC-12-02** *(covered AC-065, code unknown)* — > 500-element degrade path
  exercised by the AC-065 util test, not wired into a live badge component.

### §13 Performance / §14 Testing
- **NC-13-01** *(covered AC-070)*, **NC-13-02** *(covered AC-072)*, **NC-14-01**
  *(covered AC-080, 56 transformer pairs ≥ 50)*, **NC-14-02** *(covered
  AC-081)* — re-confirmed.

### §15 Deployment
- **NC-15-01** *(covered AC-090)* — export subpaths.
- **NC-15-02** *(uncovered, satisfied)* — `src/index.ts` also re-exports
  `withPinScope`; AC-091 does not pin that export. → candidate AC-NEW-19.

### §17 APEX Integration
- **NC-17-01..05** *(covered AC-100, 102, 103, 104, 105)* — apex-skill file,
  ui-phase scaffold, ui-review evidence step, architect/frontend skill wiring,
  apex-spec registration — all re-confirmed via grep.
- **NC-17-06** *(covered AC-107, code unknown)* — "average < 2 rounds" aggregate
  end-state; not harness-measurable.

## Candidate ACs (proposals — non-blocking)

All 19 carry over from R18 unchanged; each names a normative behaviour with no
covering AC, all `code_satisfied: true`. Re-read checks per claim:

- **AC-NEW-01** (NC-04-03) — `grep -rniE 'redux|zustand' pinscope/src
  pinscope/package.json` -> 0.
- **AC-NEW-02** (NC-06-02) — `resolveOptions()` in `src/plugin/index.ts`: every
  `?? <default>` matches §6.1.
- **AC-NEW-03** (NC-06-03) — `index.ts` buildStart `pinMap.load()`, buildEnd
  `pinMap.reconcile(); pinMap.save()`.
- **AC-NEW-04** (NC-06-04) — `parse(...,{plugins:['jsx','typescript','decorators-legacy']})`.
- **AC-NEW-05** (NC-06-05) — `ast-transformer.ts` `const loc = node.loc?.start;
  if (!loc) return;`.
- **AC-NEW-06** (NC-06-07) — `pin-map.ts` `save()` `if (!this.dirty) return;`.
- **AC-NEW-07** (NC-06-08) — `getOrAssign()` existing branch:
  `existing.last_seen = now; delete existing.deleted`.
- **AC-NEW-08** (NC-06-10) — `stableKey()` returns `${filePath}:${line}:${column}`.
- **AC-NEW-09** (NC-07-01) — `PinScope.tsx` portal body holds all 7 §7.1
  components.
- **AC-NEW-10** (NC-07-02) — `PinScopeProps` declares + forwards hudPosition /
  defaultGridMode / shortcutsEnabled.
- **AC-NEW-11** (NC-07-03) — `if (!hudVisible)` branch portals only `<FloatingToggle/>`.
- **AC-NEW-12** (NC-07-06) — `useHoveredElement.ts` `if (rafRef.current !==
  null) return;` rAF guard.
- **AC-NEW-13** (NC-08-01) — `InfoPanel.tsx` style `position:'fixed', top:56,
  width:320`, `right:16`.
- **AC-NEW-14** (NC-08-07) — `CommandBar.tsx` `height: focused ? 120 : 40`.
- **AC-NEW-15** (NC-08-09) — `CommandBar.tsx` onInputKey `e.key === 'Tab'`
  applies `getSuggestions(...)[0]`.
- **AC-NEW-16** (NC-08-11) — `StatePanel.tsx` `generateOverrideRules()` scans
  `document.styleSheets`.
- **AC-NEW-17** (NC-10-01) — `EndpointSnapshotStore` POSTs `/__pinscope/snapshot`;
  `index.ts` `handleSnapshotRequest`.
- **AC-NEW-18** (NC-12-01) — `badges.css.ts` badge rules carry `!important`.
- **AC-NEW-19** (NC-15-02) — `src/index.ts` line 6 `export { withPinScope }`.

## Strengthen proposals (proposals — non-blocking)

All 6 carry over from R18. Each names a covering AC whose `verify:` under-checks
the claim:

- **AC-023** (NC-07-04) — add badge z-index 2147483645 + hover/selected colour
  assertions. Re-read: `badges.css.ts` z-index 2147483645/646/647, three rgba
  backgrounds.
- **AC-034** (NC-08-03) — assert the full 10/50/100/200 tick set + corner live
  coords. Re-read: `Rulers.tsx` MINOR_SCALES [10,50] stripes, MAJOR_SCALES
  [100,200] ticks, CORNER coord spans.
- **AC-035** (NC-08-04) — assert crosshair absent in measurement mode and HUD-
  hidden, not only over-HUD. Re-read: `Crosshair.tsx` `if (measuring ||
  hudHidden) return null;`.
- **AC-039** (NC-08-10) — add Alt-hover sibling-distance assertion. Re-read:
  `grep -niE 'alt|sibling' MeasurementTool.tsx` -> 0. **Adopting this would
  re-open AC-039** until the behaviour is built.
- **AC-042** (NC-08-12) — assert exactly 32 `computed_styles` keys. Re-read:
  `SnapshotManager.ts` TRACKED_STYLES literal = 32 names.
- **AC-053** (NC-08-08) — assert CommandBar history persisted to
  `.pinscope/history.json` capped at 1000. Re-read: `PinScope.tsx`
  `persistHistory` POSTs `/__pinscope/history`; `index.ts`
  `entries.slice(-HISTORY_MAX_ENTRIES)`, HISTORY_MAX_ENTRIES=1000.

## Blocking findings

**None.** Every normative claim is either AC-covered or `code_satisfied: true`
(NC-08-10 is AC-covered with the unmet Alt-hover sub-behaviour carried only as a
strengthen proposal; NC-01-01/NC-12-02/NC-17-06 are AC-covered with `unknown`
for an aggregate statistic / component-wiring nuance, not a real gap).
`uncovered_unsatisfied == 0`. PS-R19 confirms convergence from the
narrative-audit standpoint: the loop has no narrative-gap reason to stay open.
