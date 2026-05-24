# Narrative Coverage Scan — PS-R18

- **Spec:** `pinscope/SPEC.md` v2.0.0 (`sha256:1779526021db1f5bc7ffe36647e6deb08ba3f8234e82cee31dc0bca5357c7a45`) — FROZEN, unchanged from R17.
- **Round role:** STEP 1B of `/ps-heal` — convergence-confirmation round.
- **Result:** 52 normative-tracked claims (50 normative + 2 non-normative context), 33 AC-covered, 19 uncovered. All 19 uncovered claims are code-satisfied. **0 blocking findings — the tree remains converged.**

## Coverage summary

R18 is a convergence-confirmation round. STEP 3 independently re-read the current
`pinscope/src/` and `framework/` source for every normative claim — no R17
satisfaction verdict was assumed. The spec hash is byte-identical to R17 and the
implementation tree exhibits the same converged shape: every normative narrative
claim is either AC-covered or demonstrably satisfied by code. The 19 uncovered
claims are paperwork gaps (real behaviour the code implements that no Appendix-A
AC asserts) — each yields a candidate AC, none blocks. Three claims
(`NC-01-01`, `NC-12-02`, `NC-17-06`) carry `code_satisfied: unknown`: NC-01-01
and NC-17-06 are aggregate statistical metrics no harness measures, and NC-12-02's
>500-element degrade path is exercised by the AC-065 util/fixture test but not
wired into a live badge component — all three are AC-covered, so none is a
blocking finding. `coverage.uncovered_unsatisfied = 0 = blocking_findings.length`.
Counts unchanged from R17 (52 / 33 / 19 / 19-satisfied / 0-unsatisfied), as
expected for a converged tree two rounds after the last seam closure.

## Claims by section

### §1 Mission
- **NC-01-01** (covered AC-107, code unknown) — 95% of UI requests in <=2 rounds. Aggregate statistic; AC-107 checks one scripted scenario only.

### §3–§4 Architecture / Stack
- **NC-03-01** (non-normative) — 6-layer runtime grouping is descriptive context.
- **NC-04-01** (covered AC-073) — dev bundle < 80 KB / < 25 KB gz. `package.json size-limit` entry confirmed.
- **NC-04-02** (covered AC-010, AC-074) — prod build 0 bytes of PinScope. `transformIndexHtml` strips data-pin when disabled.
- **NC-04-03** (uncovered, satisfied) — no Redux/Zustand. `grep -rniE 'redux|zustand' src package.json` → 0.

### §6 Build-Time Module
- **NC-06-01** (covered AC-001) — `pinscope()` plugin name/enforce.
- **NC-06-02** (uncovered, satisfied) — `resolveOptions()` defaults match §6.1 exactly.
- **NC-06-03** (uncovered, satisfied) — buildStart→load, buildEnd→reconcile+save.
- **NC-06-04** (uncovered, satisfied) — `@babel/parser` plugins `jsx`/`typescript`/`decorators-legacy`.
- **NC-06-05** (uncovered, satisfied) — `if (!loc) return;` skips loc-absent JSX nodes.
- **NC-06-06** (covered AC-011) — transformJSX emits code + source map.
- **NC-06-07** (uncovered, satisfied) — `save()` dirty-gated (`if (!this.dirty) return;`).
- **NC-06-08** (uncovered, satisfied) — getOrAssign refreshes last_seen + clears `deleted`.
- **NC-06-09** (covered AC-008) — reconcile marks `deleted:true`, IDs never reused.
- **NC-06-10** (uncovered, satisfied) — `stableKey` = `file:line:column`; moved element → new key → new id.

### §7 Runtime Module
- **NC-07-01** (uncovered, satisfied) — full 7-component HUD tree portal-rendered into `document.body`.
- **NC-07-02** (uncovered, satisfied) — props hudPosition/defaultGridMode/shortcutsEnabled honoured.
- **NC-07-03** (uncovered, satisfied) — HUD-hidden branch renders only `FloatingToggle`.
- **NC-07-04** (covered AC-023, under-checked) — badge z-index 2147483645-647, blue/red/green. **Strengthen → AC-023.**
- **NC-07-05** (covered AC-024, AC-025) — void-element overlay + `e_r{N}` MutationObserver.
- **NC-07-06** (uncovered, satisfied) — `useHoveredElement` rAF-throttled (one resolve per frame).

### §8 Component Specifications
- **NC-08-01** (uncovered, satisfied) — InfoPanel fixed, right:16, top:56, width:320.
- **NC-08-02** (covered AC-033) — empty values render `—`.
- **NC-08-03** (covered AC-034, under-checked) — Rulers 24px, ticks 10/50/100/200, live corner coords. **Strengthen → AC-034.**
- **NC-08-04** (covered AC-035, under-checked) — Crosshair off over HUD / measuring / HUD-hidden. **Strengthen → AC-035.**
- **NC-08-05** (covered AC-036) — GridOverlay 4 modes, off→pixel→baseline→column→spacing cycle, SVG `<pattern>`.
- **NC-08-06** (covered AC-037) — TopBar fixed, top:0, 32px, four fields + live pin count.
- **NC-08-07** (uncovered, satisfied) — CommandBar 40px, expands to 120px on focus.
- **NC-08-08** (covered AC-053, under-checked) — history persisted to `.pinscope/history.json`, capped 1000. **Strengthen → AC-053.**
- **NC-08-09** (uncovered, satisfied) — CommandBar `Tab` autocomplete wired via `getSuggestions`.
- **NC-08-10** (covered AC-039, sub-behaviour absent) — Δx/Δy/diagonal/gap rendered; **Alt-hover sibling distances UNIMPLEMENTED** (`grep -niE 'alt|sibling' MeasurementTool.tsx` → 0). NOT a blocking finding: the claim is covered by AC-039 (its check still passes); the unmet sub-behaviour is carried as the AC-039 strengthen proposal. **Strengthen → AC-039.**
- **NC-08-11** (uncovered, satisfied) — StatePanel scans `document.styleSheets` for `:hover/:focus/:active`, synthesizes override rules.
- **NC-08-12** (covered AC-042, under-checked) — `TRACKED_STYLES` literal has exactly 32 properties. **Strengthen → AC-042.**

### §9 Data Schemas
- **NC-09-01** (covered AC-006) — `.pinmap.json` schema.
- **NC-09-02** (covered AC-052) — Operation `request_type` union.

### §10 Behavioral Flows
- **NC-10-01** (uncovered, satisfied) — snapshot persists via `/__pinscope/snapshot` dev-server route.
- **NC-10-02** (covered AC-071) — hover < 8 ms/frame.

### §11 Operation Protocol
- **NC-11-01** (covered AC-050) — all six grammar forms parsed.
- **NC-11-02** (covered AC-051) — all 10 shortcut properties resolve.

### §12 Edge Cases
- **NC-12-01** (uncovered, satisfied) — z-index 2147483647 reserved; badge CSS uses `!important`.
- **NC-12-02** (covered AC-065, code unknown) — >500-element 30fps throttle + <16px badge skip exercised by the AC-065 util/fixture test, not wired into a live badge component.

### §13 Performance
- **NC-13-01** (covered AC-070) — mount < 50 ms.
- **NC-13-02** (covered AC-072) — operation parse < 4 ms.

### §14 Testing
- **NC-14-01** (covered AC-080) — AST transformer suite 56 pairs (>= 50).
- **NC-14-02** (covered AC-081) — operation-parser suite >= 30 cases.

### §15 Deployment
- **NC-15-01** (covered AC-090) — package.json export subpaths.
- **NC-15-02** (uncovered, satisfied) — `src/index.ts` re-exports `withPinScope` alongside the rest (AC-091's description omits `withPinScope`).

### §16–§17 Phase Plan / APEX Integration
- **NC-16-01** (non-normative) — P5 phase plan is descriptive; concrete behaviours carry §17 ACs.
- **NC-17-01** (covered AC-100) — `framework/apex-skills/pinscope.md` five apex-skill headings present.
- **NC-17-02** (covered AC-102) — `/apex:ui-phase` PINSCOPE INSTRUMENTATION step.
- **NC-17-03** (covered AC-103) — `/apex:ui-review` PINSCOPE EVIDENCE step.
- **NC-17-04** (covered AC-104) — architect / frontend specialist reference `pinscope`.
- **NC-17-05** (covered AC-105) — `apex-spec.md` registers PinScope.
- **NC-17-06** (covered AC-107, code unknown) — average rounds per UI change < 2. Aggregate metric.

## Candidate ACs (19 — all proposals, none block)

All 19 candidates carry over from R17 unchanged; each describes a satisfied
behaviour that Appendix A does not assert. They inform a possible user-approved
SPEC bump; they do not block convergence. See `candidate_acs` in the JSON for the
`AC-NEW-01..19` rows (build defaults, lifecycle hooks, parser plugins, loc-skip,
dirty-gate, un-delete, moved-element id, full HUD tree, props, FloatingToggle,
rAF throttle, InfoPanel geometry, CommandBar expand, Tab autocomplete, StatePanel
rule synthesis, snapshot endpoint, `!important` hardening, `withPinScope`
re-export).

## Strengthen proposals (6 — all proposals, none block)

`AC-023` (badge z-index/colour states), `AC-034` (multi-scale ticks + corner
coords), `AC-035` (crosshair measuring/HUD-hidden disable), `AC-039` (Alt-hover
sibling distances — **note: that sub-behaviour is unimplemented; adopting the
strengthened verify would re-open AC-039**), `AC-042` (exact 32-key count),
`AC-053` (`.pinscope/history.json` cap at 1000). Each quotes its `re_read` in
the JSON.

## Blocking findings

**None.** Every normative claim is AC-covered or independently confirmed
satisfied by a re-read of the current code. `coverage.uncovered_unsatisfied = 0`,
which equals `blocking_findings.length = 0`. The PinScope tree is converged from
the narrative-coverage perspective; the loop may close PS-R18 on this scan.
