# Narrative scan — PS-R21

- **Round:** 21
- **Generated:** 2026-05-24T19:34:28Z
- **Spec version:** 2.0.0 (FROZEN)
- **Spec hash:** `sha256:1779526021db1f5bc7ffe36647e6deb08ba3f8234e82cee31dc0bca5357c7a45` *(unchanged from R20 — no SPEC bump occurred)*
- **Compared against:** `narrative-scan-R20.json`

## Coverage summary

> `claims: 54 · covered: 33/54 · uncovered_satisfied: 21 · uncovered_unsatisfied: 0 · candidate ACs: 21 · strengthen proposals: 8 · blocking findings: 0`

54 normative claims walked across §1–§17; 33 already AC-covered, 21 normative
claims remain un-AC'd but the code satisfies all 21 — every uncovered claim is
a *paperwork gap*, not a *real gap*, so **convergence is not blocked**. The
prose-versus-Appendix-A delta is purely a documentation-completeness backlog
the user can adopt at the next SPEC bump. Two new normative claims joined the
ledger in R21 (NC-08-13 and NC-08-14) because the R-20-01/02/03 HUD
integration landed in commit `98841a4` and made the §8.11 Shift+P / Shift+C
shortcut atoms newly observable as wired behaviour — both are immediately
covered_by:[] satisfied:true, so they enter as candidate ACs, not blockers.

Two of the §7 claims also gained additional strengthen proposals in R21:
`AC-024` and `AC-025` now hold the §7.2 contract through the integrated tree
(VoidBadges-mounted-via-PinScope-portal; RuntimePinObserver-bound-via-useEffect),
but their `verify` still targets the component in isolation. R-20-01/02 made
the integrated coverage observable, so AC-024/AC-025 should be strengthened to
exercise the integrated path (the loose component-in-isolation tests are now
weaker than reality).

## Delta vs R20

| Aspect | R20 | R21 | Δ |
|---|---|---|---|
| Total normative claims | 52 | **54** | +2 |
| Covered (covered_by non-empty) | 33 | 33 | 0 |
| Uncovered, code_satisfied:true | 19 | **21** | +2 |
| Uncovered, code_satisfied:false | 0 | 0 | 0 |
| Candidate ACs | 19 | **21** | +2 |
| Strengthen proposals | 6 | **8** | +2 (AC-024 / AC-025 integration paths) |
| Blocking findings | 0 | 0 | 0 |

**New normative claims minted in R21:**
- `NC-08-13` — §8.11 Shift+P toggles both pin badge layers together.
- `NC-08-14` — §8.11 Shift+C toggles the crosshair.

Both atoms were latent in §8.11 spec text but became observable wired behaviour
only in commit `98841a4` (PS-R20 W1-3). They are not regressions — R20 didn't
miss them through error; the integration that makes them testable simply only
just landed. Both ship as `code_satisfied: true`.

**Carried-forward IDs (R20 → R21):** all 52 R20 claim_ids are preserved
unchanged; only 2 new ids appended (`NC-08-13`, `NC-08-14`).

## Claims by section

Lists per spec section; full structured fields in `narrative-scan-R21.json`.

### §1 Mission
- **NC-01-01** *(covered AC-107, satisfied:unknown)* — Success metric 95% UI requests <=2 rounds. Aggregate statistic; AC-107 covers one scripted scenario.

### §3 System Architecture
- **NC-03-01** *(non-normative)* — 6-layer module split is descriptive context.

### §4 Technical Stack
- **NC-04-01** *(covered AC-073, satisfied)* — Dev build <80 KB / <25 KB.
- **NC-04-02** *(covered AC-010/AC-074, satisfied)* — Prod build 0 bytes.
- **NC-04-03** *(uncovered, satisfied)* — No Redux/Zustand. **→ candidate AC-NEW-01.**

### §6 Build-Time Module
- **NC-06-01** *(covered AC-001)* — plugin name + enforce:pre.
- **NC-06-02** *(uncovered, satisfied)* — PinScopeOptions defaults. **→ AC-NEW-02.**
- **NC-06-03** *(uncovered, satisfied)* — Vite lifecycle hooks. **→ AC-NEW-03.**
- **NC-06-04** *(uncovered, satisfied)* — Babel parser plugin set. **→ AC-NEW-04.**
- **NC-06-05** *(uncovered, satisfied)* — JSX no-loc skip path. **→ AC-NEW-05.**
- **NC-06-06** *(covered AC-011)* — transformJSX emits source map.
- **NC-06-07** *(uncovered, satisfied)* — PinMap.save() dirty-gated. **→ AC-NEW-06.**
- **NC-06-08** *(uncovered, satisfied)* — getOrAssign un-delete refresh. **→ AC-NEW-07.**
- **NC-06-09** *(covered AC-008)* — removed entry deleted:true, no id reuse.
- **NC-06-10** *(uncovered, satisfied)* — moved element gets new id. **→ AC-NEW-08.**

### §7 Runtime Module
- **NC-07-01** *(uncovered, satisfied)* — Full §7.1 HUD tree mounted. **→ AC-NEW-09.**
- **NC-07-02** *(uncovered, satisfied)* — Prop surface hudPosition/defaultGridMode/shortcutsEnabled. **→ AC-NEW-10.**
- **NC-07-03** *(uncovered, satisfied)* — HUD-hidden renders only FloatingToggle. **→ AC-NEW-11.**
- **NC-07-04** *(covered AC-023, satisfied)* — Badge z-index range + colour states. *(strengthen)*
- **NC-07-05** *(covered AC-024+AC-025, satisfied)* — Void JS-overlay + MutationObserver. *(R21 strengthen — see below.)*
- **NC-07-06** *(uncovered, satisfied)* — useHoveredElement rAF throttle. **→ AC-NEW-12.**

### §8 Component Specifications
- **NC-08-01** *(uncovered, satisfied)* — InfoPanel fixed at right:16/top:56/w:320. **→ AC-NEW-13.**
- **NC-08-02** *(covered AC-033)* — Empty values render '—'.
- **NC-08-03** *(covered AC-034, satisfied)* — Rulers ticks 10/50/100/200. *(strengthen)*
- **NC-08-04** *(covered AC-035, satisfied)* — Crosshair disable conditions. *(strengthen)*
- **NC-08-05** *(covered AC-036)* — GridOverlay 4 modes + cycle.
- **NC-08-06** *(covered AC-037)* — TopBar geometry + fields.
- **NC-08-07** *(uncovered, satisfied)* — CommandBar 40→120px focus expand. **→ AC-NEW-14.**
- **NC-08-08** *(covered AC-053, satisfied)* — History persisted, 1000 cap. *(strengthen)*
- **NC-08-09** *(uncovered, satisfied)* — Tab autocomplete. **→ AC-NEW-15.**
- **NC-08-10** *(covered AC-039, satisfied:false sub-behaviour)* — MeasurementTool labels + Alt-hover. Alt-hover unimplemented; carried as AC-039 strengthen, not a blocker.
- **NC-08-11** *(uncovered, satisfied)* — StatePanel auto-generates override rules. **→ AC-NEW-16.**
- **NC-08-12** *(covered AC-042, satisfied)* — Exactly 32 computed-style properties. *(strengthen)*
- **NC-08-13** *(uncovered, satisfied — NEW)* — §8.11 Shift+P toggles both badge layers. **→ AC-NEW-20.**
- **NC-08-14** *(uncovered, satisfied — NEW)* — §8.11 Shift+C toggles crosshair. **→ AC-NEW-21.**

### §9 Data Schemas
- **NC-09-01** *(covered AC-006)* — PinMap schema.
- **NC-09-02** *(covered AC-052)* — Operation schema.

### §10 Behavioral Flows
- **NC-10-01** *(uncovered, satisfied)* — Snapshot persists via `/__pinscope/snapshot`. **→ AC-NEW-17.**
- **NC-10-02** *(covered AC-071)* — Hover < 8 ms/frame.

### §11 Operation Protocol
- **NC-11-01** *(covered AC-050)* — Six grammar forms.
- **NC-11-02** *(covered AC-051)* — 10 shortcut properties.

### §12 Edge Cases
- **NC-12-01** *(uncovered, satisfied)* — Reserved z-index + !important hardening. **→ AC-NEW-18.**
- **NC-12-02** *(covered AC-065, satisfied:unknown)* — 30fps throttle + 16×16 skip at >500 pins. Unit-fixture path exists; component-level wiring stays unknown (consistent with R17–R20).

### §13 Performance
- **NC-13-01** *(covered AC-070)* — Mount < 50 ms. R-20-02 queueMicrotask defer was specifically inserted to keep this budget.
- **NC-13-02** *(covered AC-072)* — Parse < 4 ms.

### §14 Testing Strategy
- **NC-14-01** *(covered AC-080)* — AST transformer >=50 pairs.
- **NC-14-02** *(covered AC-081)* — Operation parser >=30 variants.

### §15 Deployment & Integration
- **NC-15-01** *(covered AC-090)* — Four export subpaths.
- **NC-15-02** *(uncovered, satisfied)* — `withPinScope` re-exported from index. **→ AC-NEW-19.**

### §16 Phase Plan
- **NC-16-01** *(non-normative)* — P5 phase definition.

### §17 APEX Integration
- **NC-17-01** *(covered AC-100)* — apex-skill content.
- **NC-17-02** *(covered AC-102)* — `/apex:ui-phase` scaffolds.
- **NC-17-03** *(covered AC-103)* — `/apex:ui-review` ingests.
- **NC-17-04** *(covered AC-104)* — architect / apex-frontend agent stack_skills.
- **NC-17-05** *(covered AC-105)* — apex-spec.md registration.
- **NC-17-06** *(covered AC-107, satisfied:unknown)* — Round-trip avg < 2 rounds (aggregate).

## Candidate ACs (21)

Proposals for a future SPEC bump. None block convergence (all satisfied:true).

| Proposal | Claim | Phase / Severity / Kind |
|---|---|---|
| `AC-NEW-01` | NC-04-03 — no Redux/Zustand | P1 · P2 · grep |
| `AC-NEW-02` | NC-06-02 — PinScopeOptions defaults | P1 · P1 · vitest |
| `AC-NEW-03` | NC-06-03 — Vite buildStart/buildEnd | P1 · P1 · vitest |
| `AC-NEW-04` | NC-06-04 — Babel parser plugin set | P1 · P2 · vitest |
| `AC-NEW-05` | NC-06-05 — JSX no-loc skip | P1 · P2 · vitest |
| `AC-NEW-06` | NC-06-07 — PinMap.save() dirty-gate | P1 · P2 · vitest |
| `AC-NEW-07` | NC-06-08 — getOrAssign un-delete refresh | P1 · P1 · vitest |
| `AC-NEW-08` | NC-06-10 — moved element new id | P1 · P1 · vitest |
| `AC-NEW-09` | NC-07-01 — full §7.1 HUD tree | P2 · P1 · vitest |
| `AC-NEW-10` | NC-07-02 — prop surface | P2 · P2 · vitest |
| `AC-NEW-11` | NC-07-03 — HUD-hidden FloatingToggle | P2 · P2 · vitest |
| `AC-NEW-12` | NC-07-06 — rAF throttle | P2 · P2 · vitest |
| `AC-NEW-13` | NC-08-01 — InfoPanel geometry | P1 · P2 · vitest |
| `AC-NEW-14` | NC-08-07 — CommandBar 40→120 focus expand | P2 · P2 · vitest |
| `AC-NEW-15` | NC-08-09 — Tab autocomplete wired in CommandBar | P3 · P2 · vitest |
| `AC-NEW-16` | NC-08-11 — StatePanel override-rule auto-gen | P2 · P2 · vitest |
| `AC-NEW-17` | NC-10-01 — snapshot via `/__pinscope/snapshot` | P4 · P2 · vitest |
| `AC-NEW-18` | NC-12-01 — badges !important hardening | P2 · P1 · grep |
| `AC-NEW-19` | NC-15-02 — withPinScope re-export | P1 · P1 · vitest |
| **`AC-NEW-20`** *(NEW in R21)* | NC-08-13 — Shift+P toggles both badge layers | P2 · P1 · vitest |
| **`AC-NEW-21`** *(NEW in R21)* | NC-08-14 — Shift+C toggles crosshair | P2 · P1 · vitest |

## Strengthen proposals (8)

Where an existing AC covers a claim but its `verify:` under-checks the
behaviour. **No strengthen proposal blocks convergence** (the existing AC's
own check still passes).

| AC | Claim | Current verify (short) | Proposed verify (short) |
|---|---|---|---|
| `AC-023` | NC-07-04 z-index/colour states | reads ::before text for 5 pins | also assert z-index 2147483645 default + red rgba on :hover + green rgba on [data-pin-selected] |
| **`AC-024`** *(NEW in R21)* | NC-07-05 VoidBadges integrated | renders `<VoidBadges/>` in isolation | also render `<PinScope/>` and assert `[data-void-badge]` overlay inside `[data-pinscope-ui=root]` portal (R-20-01 landed integration in 98841a4) |
| **`AC-025`** *(NEW in R21)* | NC-07-05 RuntimePinObserver lifecycle | direct instantiation start/stop | also mount `<PinScope/>`, add element post-mount → e_r id; unmount, add element → NO e_r id (R-20-02 landed lifecycle binding in 98841a4) |
| `AC-034` | NC-08-03 ruler ticks | counts 100px tick labels only | also assert 10/50/200 tick scales + corner live-coords cell |
| `AC-035` | NC-08-04 crosshair disable | asserts absence over HUD only | also assert absence while measuring and while HUD hidden |
| `AC-039` | NC-08-10 measurement Alt-hover | two-click measurement only | also assert Alt-hover renders sibling distances — **note: Alt-hover currently UNIMPLEMENTED; adopting this would re-open AC-039 until built** |
| `AC-042` | NC-08-12 32 properties | schema validation only | also assert each element's `computed_styles` has exactly 32 keys |
| `AC-053` | NC-08-08 history.json 1000 cap | clipboard + history append | also assert input history persisted to `.pinscope/history.json` via `/__pinscope/history` route, capped at 1000 |

## Blocking findings (0)

**None.** No normative claim has `covered_by: []` AND `code_satisfied: false`.
Each of the 21 uncovered normative claims is satisfied by the code; each of
the 8 strengthen-proposal claims is covered by an AC whose check still passes
on the current source.

The R-20-01/02/03 HUD integration landed `code_satisfied: true` on every
behaviour it introduced — VoidBadges integrated mount, RuntimePinObserver
lifecycle, Shift+P / Shift+C toggles — so it produced new candidate ACs and
strengthen proposals but **no blocking finding**. The convergence gate is
clear at PS-R21.

## What changed since R20 in code (per commit 98841a4)

- `pinscope/src/runtime/PinScope.tsx` (+49/-3): added VoidBadges mount,
  RuntimePinObserver useEffect (queueMicrotask-deferred to keep AC-070
  budget), pinsVisible/crosshairEnabled state cells, `toggle-pins`/`crosshair`
  shortcut handlers, prop wiring on `<Crosshair enabled={…}/>` and on the
  two conditional `<PinBadges/>` / `<VoidBadges/>` mounts.
- `pinscope/src/runtime/components/Crosshair.tsx` (+10/-2): added
  `enabled?: boolean` prop defaulting `true`; appended `|| !enabled` to the
  existing `measuring || hudHidden` disable guard.
- `pinscope/tests/unit/runtime/pinscope.test.tsx`: 4 new DoD tests under
  three describe blocks (`R-20-01 — VoidBadges mount`, `R-20-02 —
  RuntimePinObserver lifecycle`, `R-20-03 — §8.11 Shift+P / Shift+C
  toggles`) — all passing, none AC-tagged.

The new behaviours produced two new normative §8.11 atoms (NC-08-13,
NC-08-14) and let two existing claim/AC pairs (NC-07-05 / AC-024 + AC-025)
be carried through the integrated tree, giving them strengthen-proposal
upgrades. Nothing in the integration violates a §1–§17 claim.

## Convergence verdict from this scan

`uncovered_unsatisfied = 0` → **the narrative gate is clear**. The 21
candidate ACs + 8 strengthen proposals are documentation-completeness
backlog for the user to consider at the next user-approved SPEC bump; they
are NOT remediation work for the current loop round.
