# Narrative Coverage Scan — PS-R20

- **Round:** 20 · **Spec version:** 2.0.0
- **Spec hash:** `sha256:1779526021db1f5bc7ffe36647e6deb08ba3f8234e82cee31dc0bca5357c7a45` (re-verified via `sha256sum pinscope/SPEC.md` — unchanged from R19; North-Star still FROZEN)
- **Normative claims:** 52 · **AC-covered:** 33 · **Uncovered:** 19 (all satisfied)
- **Candidate ACs:** 19 · **Strengthen proposals:** 6 · **Blocking findings:** 0

## Summary

R20 is a re-verification round. The North-Star spec and `ac-matrix.json` are
byte-identical to R19 (spec hash matches). Every R19 `re_read` check was re-run
against the live `pinscope/` and `framework/` trees this round and every result
held. All 52 prior claim IDs are carried over unchanged for stability.

**STEP 6 — convergence gate:** No normative claim is both `covered_by: []` AND
`code_satisfied: false`. `blocking_findings` is empty; `uncovered_unsatisfied`
is 0. The R19 CONVERGED state stands — narrative coverage does not break it.

The single `code_satisfied: false` claim (NC-08-10, Alt-hover sibling
distances) is **covered_by AC-039**, whose own `verify:` check still passes —
so it is NOT an un-AC'd gap and NOT a blocking finding. The unmet sub-behaviour
is carried as the AC-039 strengthen proposal, exactly as in R19.

## Claims by section

### §1 Mission
- **NC-01-01** `[AC-107]` *satisfied: unknown* — 95% of UI requests in <=2 rounds. Aggregate population statistic; no harness measures the rate. AC-107 checks one scripted scenario only.

### §3 Architecture
- **NC-03-01** *normative: false* — 6-layer runtime grouping; descriptive context.

### §4 Technical Stack
- **NC-04-01** `[AC-073]` — dev bundle < 80 KB min / < 25 KB gz.
- **NC-04-02** `[AC-010, AC-074]` — prod bundle 0 bytes of PinScope.
- **NC-04-03** *uncovered, satisfied* — no Redux/Zustand; React hooks only. `grep -rniE 'redux|zustand'` → 0. → candidate **AC-NEW-01**.

### §6 Build-Time Module
- **NC-06-01** `[AC-001]` — plugin name `vite-plugin-pinscope`, enforce `pre`.
- **NC-06-02** *uncovered, satisfied* — PinScopeOptions §6.1 defaults. → **AC-NEW-02**.
- **NC-06-03** *uncovered, satisfied* — buildStart loads / buildEnd saves PinMap. → **AC-NEW-03**.
- **NC-06-04** *uncovered, satisfied* — @babel/parser plugins jsx/typescript/decorators-legacy (`ast-transformer.ts:50`). → **AC-NEW-04**.
- **NC-06-05** *uncovered, satisfied* — loc-absent JSXOpeningElement skipped. → **AC-NEW-05**.
- **NC-06-06** `[AC-011]` — transformJSX emits code + source map.
- **NC-06-07** *uncovered, satisfied* — `PinMap.save()` dirty-gated (`pin-map.ts:33`). → **AC-NEW-06**.
- **NC-06-08** *uncovered, satisfied* — getOrAssign un-deletes + refreshes last_seen (`pin-map.ts:51-52`). → **AC-NEW-07**.
- **NC-06-09** `[AC-008]` — removed entry marked deleted:true, ID never reused.
- **NC-06-10** *uncovered, satisfied* — moved element → new key → new ID. → **AC-NEW-08**.

### §7 Runtime Module
- **NC-07-01** *uncovered, satisfied* — full §7.1 HUD tree portal-rendered (all 7 components imported `PinScope.tsx:6-13`). → **AC-NEW-09**.
- **NC-07-02** *uncovered, satisfied* — props hudPosition/defaultGridMode/shortcutsEnabled. → **AC-NEW-10**.
- **NC-07-03** *uncovered, satisfied* — HUD-hidden renders only FloatingToggle. → **AC-NEW-11**.
- **NC-07-04** `[AC-023]` — badge z-index 2147483645-2147483647, blue/red/green. *Strengthen.*
- **NC-07-05** `[AC-024, AC-025]` — void-element overlay badge + MutationObserver.
- **NC-07-06** *uncovered, satisfied* — useHoveredElement rAF per-frame throttle. → **AC-NEW-12**.

### §8 Component Specifications
- **NC-08-01** *uncovered, satisfied* — InfoPanel fixed right:16/top:56/width:320. → **AC-NEW-13**.
- **NC-08-02** `[AC-033]` — empty values render `—`.
- **NC-08-03** `[AC-034]` — Rulers 24px, ticks 10/50/100/200, live corner coords. *Strengthen.*
- **NC-08-04** `[AC-035]` — Crosshair disabled over HUD / measuring / HUD-hidden. *Strengthen.*
- **NC-08-05** `[AC-036]` — GridOverlay 4 modes, off→pixel→baseline→column→spacing→off.
- **NC-08-06** `[AC-037]` — TopBar fixed top:0 height:32, four fields + pin count.
- **NC-08-07** *uncovered, satisfied* — CommandBar 40px → 120px on focus. → **AC-NEW-14**.
- **NC-08-08** `[AC-053]` — history persisted to .pinscope/history.json, last 1000 (`index.ts:17,100`). *Strengthen.*
- **NC-08-09** *uncovered, satisfied* — CommandBar Tab autocomplete. → **AC-NEW-15**.
- **NC-08-10** `[AC-039]` *satisfied: false* — two-click Δx/Δy/diagonal/gap present; **Alt-hover sibling distances UNIMPLEMENTED** (`grep -niE 'alt|sibling'` → 0). Covered by AC-039 (check passes) → NOT a blocking finding; carried as the AC-039 strengthen proposal.
- **NC-08-11** *uncovered, satisfied* — StatePanel scans host stylesheets for :hover/:focus/:active. → **AC-NEW-16**.
- **NC-08-12** `[AC-042]` — SnapshotManager extracts exactly 32 computed-style properties (TRACKED_STYLES `SnapshotManager.ts:7-14`). *Strengthen.*

### §9 Data Schemas
- **NC-09-01** `[AC-006]` — .pinmap.json §9.1 schema.
- **NC-09-02** `[AC-052]` — Operation §9.3 schema, request_type union.

### §10 Behavioral Flows
- **NC-10-01** *uncovered, satisfied* — snapshot persists via `/__pinscope/snapshot` (`EndpointSnapshotStore.ts:7`, `index.ts:11`). → **AC-NEW-17**.
- **NC-10-02** `[AC-071]` — hover inspection < 8 ms/frame.

### §11 Operation Protocol
- **NC-11-01** `[AC-050]` — six grammar forms.
- **NC-11-02** `[AC-051]` — 10 shortcut properties resolve to CSS.

### §12 Edge Cases
- **NC-12-01** *uncovered, satisfied* — z-index 2147483647 reserved + `!important` hardening (`constants.ts:13,15`). → **AC-NEW-18**.
- **NC-12-02** `[AC-065]` *satisfied: unknown* — >500-element throttle / badge skip; covered by AC-065 fixture test, live component wiring unconfirmed (consistent with R17-R19).

### §13 Performance
- **NC-13-01** `[AC-070]` — mount < 50 ms.
- **NC-13-02** `[AC-072]` — operation parse < 4 ms.

### §14 Testing
- **NC-14-01** `[AC-080]` — AST transformer suite >= 50 pairs.
- **NC-14-02** `[AC-081]` — operation-parser suite >= 30 cases.

### §15 Deployment
- **NC-15-01** `[AC-090]` — export subpaths vite/runtime/next/webpack.
- **NC-15-02** *uncovered, satisfied* — src/index.ts re-exports withPinScope (`index.ts:6`). → **AC-NEW-19**.

### §16 Phase Plan
- **NC-16-01** *normative: false* — P5 DoD deferred to §17.

### §17 APEX Integration
- **NC-17-01** `[AC-100]` — apex-skill pinscope.md (5 headings present).
- **NC-17-02** `[AC-102]` — /apex:ui-phase scaffolds PinScope.
- **NC-17-03** `[AC-103]` — /apex:ui-review ingests PinScope evidence.
- **NC-17-04** `[AC-104]` — architect/frontend add pinscope to stack_skills.
- **NC-17-05** `[AC-105]` — apex-spec.md registers PinScope.
- **NC-17-06** `[AC-107]` *satisfied: unknown* — round-trip average < 2; aggregate metric.

## Candidate ACs (19 — proposals only, never block)

All 19 carry over from R19 unchanged; every one has `code_satisfied: true`, so
each would be born `CLOSED` if adopted into Appendix A. They document satisfied
narrative behaviour the matrix never reduced to an AC — a paperwork
completeness gap, not a code gap. Adoption is a separate user-approved SPEC bump.

AC-NEW-01 (NC-04-03, grep) · AC-NEW-02..08 (§6 build, vitest) · AC-NEW-09..16
(§7-§8 runtime, vitest) · AC-NEW-17 (NC-10-01) · AC-NEW-18 (NC-12-01, grep) ·
AC-NEW-19 (NC-15-02 withPinScope root re-export). See JSON for full rows and
`re_read` checks.

## Strengthen proposals (6 — proposals only, never block)

- **AC-023** / NC-07-04 — add badge z-index 2147483645 + red-hover / green-selected colour assertions.
- **AC-034** / NC-08-03 — add the 10/50 minor tick scales + live corner coords assertions.
- **AC-035** / NC-08-04 — add crosshair-absent assertions for measurement mode and HUD-hidden.
- **AC-039** / NC-08-10 — add Alt-hover sibling-distance assertion. NOTE: behaviour is UNIMPLEMENTED; adopting this would re-open AC-039 until built.
- **AC-042** / NC-08-12 — assert exactly 32 computed_styles keys per element.
- **AC-053** / NC-08-08 — assert CommandBar input history persisted to .pinscope/history.json capped at 1000.

## Blocking findings

**None.** No normative claim is both `covered_by: []` and `code_satisfied: false`.
`coverage.uncovered_unsatisfied == 0 == blocking_findings.length`. Narrative
coverage does not block convergence this round — the R19 CONVERGED state holds.
