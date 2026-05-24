# Narrative Coverage Scan — PS-R22

- **Round:** 22 (post-convergence terminal-check)
- **Spec version:** 2.0.0 (`sha256:1779526021db1f5bc7ffe36647e6deb08ba3f8234e82cee31dc0bca5357c7a45`) — unchanged from R21
- **Generated at:** 2026-05-25T00:00:00Z
- **Predecessor:** `narrative-scan-R21.json` (54 claims · 33 covered · 0 blocking)
- **Coverage summary:** 57 claims · 36/57 covered · uncovered_unsatisfied **0** · candidate_acs 21 · strengthen_proposals 8 · blocking_findings **0**

## Round-over-round delta

| Metric | R21 | R22 | Δ |
|---|---|---|---|
| Total claims | 54 | 57 | +3 |
| Covered (AC) | 33 | 36 | +3 |
| Uncovered | 21 | 21 | 0 |
| Candidate ACs | 21 | 21 | 0 |
| Strengthen proposals | 8 | 8 | 0 |
| `uncovered_unsatisfied` (blocking gate) | **0** | **0** | 0 |
| `blocking_findings.length` | **0** | **0** | 0 |

**Three new normative atoms minted this round (NC-12-03 / NC-12-04 / NC-12-05)** to make R-21's §12 integrations traceable; all three are `code_satisfied: true` and AC-covered (AC-060 / AC-064 / AC-064 respectively), so they land in the **covered** bucket and do not add to the uncovered count.

**Regression check (per task brief):** no claim that was `code_satisfied: true` in R21 has flipped to `false`; no claim that was `uncovered_satisfied: true` has flipped to `uncovered_unsatisfied: true`. One claim was *promoted* (NC-12-02 `unknown -> true`) because R-21-03 supplied the component-level wiring that was previously absent.

## Claims by section

### §1 Vision
- **NC-01-01** — Success metric 95% within ≤2 rounds — *covered by AC-107* — `unknown` (aggregate statistic, not a per-build falsifiable behaviour).

### §3 Architecture
- **NC-03-01** — 6-layer runtime grouping — `normative:false`.

### §4 Tech / Bundle
- **NC-04-01** — Dev bundle < 80 KB / < 25 KB gz — *covered by AC-073* — true.
- **NC-04-02** — Prod bundle 0 bytes of PinScope — *covered by AC-010, AC-074* — true.
- **NC-04-03** — No Redux/Zustand — uncovered — true (candidate AC-NEW-01).

### §6 Build-time
- **NC-06-01** — Plugin name + enforce:'pre' — *covered by AC-001* — true.
- **NC-06-02** — PinScopeOptions §6.1 defaults — uncovered — true (AC-NEW-02).
- **NC-06-03** — buildStart load / buildEnd save — uncovered — true (AC-NEW-03).
- **NC-06-04** — @babel/parser jsx/typescript/decorators-legacy — uncovered — true (AC-NEW-04).
- **NC-06-05** — JSXOpeningElement without loc is skipped — uncovered — true (AC-NEW-05).
- **NC-06-06** — transformJSX emits code + source map — *covered by AC-011* — true.
- **NC-06-07** — PinMap.save() dirty-gated — uncovered — true (AC-NEW-06).
- **NC-06-08** — getOrAssign un-deletes + refreshes last_seen — uncovered — true (AC-NEW-07).
- **NC-06-09** — Removed entry marked deleted:true, id never reused — *covered by AC-008* — true.
- **NC-06-10** — Moved element yields a new id — uncovered — true (AC-NEW-08).

### §7 Runtime HUD
- **NC-07-01** — `<PinScope/>` portal-renders 7-component tree — uncovered — true (AC-NEW-09).
- **NC-07-02** — props hudPosition / defaultGridMode / shortcutsEnabled — uncovered — true (AC-NEW-10).
- **NC-07-03** — HUD-hidden branch renders only FloatingToggle — uncovered — true (AC-NEW-11).
- **NC-07-04** — Badge z-index 2147483645–2147483647 + blue/red/green — *covered by AC-023* — true (strengthen).
- **NC-07-05** — VoidBadges + RuntimePinObserver — *covered by AC-024, AC-025* — true (strengthen ×2; R-20-01/02 integration intact).
- **NC-07-06** — useHoveredElement rAF throttle — uncovered — true (AC-NEW-12).

### §8 Components
- **NC-08-01** — InfoPanel fixed/right:16/top:56/width:320 — uncovered — true (AC-NEW-13).
- **NC-08-02** — Empty values render '—' — *covered by AC-033* — true.
- **NC-08-03** — Rulers 24px + ticks 10/50/100/200 + corner coords — *covered by AC-034* — true (strengthen).
- **NC-08-04** — Crosshair disabled over HUD / measuring / hidden — *covered by AC-035* — true (strengthen).
- **NC-08-05** — GridOverlay 4 modes via SVG <pattern> — *covered by AC-036* — true.
- **NC-08-06** — TopBar fixed/top:0/height:32 + 4 fields — *covered by AC-037* — true.
- **NC-08-07** — CommandBar 40→120 px on focus — uncovered — true (AC-NEW-14).
- **NC-08-08** — CommandBar history → .pinscope/history.json (cap 1000) — *covered by AC-053* — true (strengthen).
- **NC-08-09** — Tab autocomplete in CommandBar — uncovered — true (AC-NEW-15).
- **NC-08-10** — MeasurementTool Δx/Δy/diagonal/gap + Alt-sibling — *covered by AC-039* — **partial** (two-click satisfied; Alt-hover absent; strengthen flag — not a blocking finding).
- **NC-08-11** — StatePanel auto-generated override rules — uncovered — true (AC-NEW-16).
- **NC-08-12** — SnapshotManager extracts exactly 32 computed-style properties — *covered by AC-042* — true (strengthen).
- **NC-08-13** — Shift+P toggles PinBadges + VoidBadges together — uncovered — true (AC-NEW-20).
- **NC-08-14** — Shift+C toggles crosshair — uncovered — true (AC-NEW-21).

### §9 Schemas
- **NC-09-01** — .pinmap.json schema — *covered by AC-006* — true.
- **NC-09-02** — Operation §9.3 schema — *covered by AC-052* — true.

### §10 Data flows
- **NC-10-01** — Snapshot persists via /__pinscope/snapshot — uncovered — true (AC-NEW-17).
- **NC-10-02** — Hover inspection < 8 ms — *covered by AC-071* — true.

### §11 Operation grammar
- **NC-11-01** — 6 grammar forms — *covered by AC-050* — true.
- **NC-11-02** — 10 shortcut properties — *covered by AC-051* — true.

### §12 Edge cases (R21 + R22 minting)
- **NC-12-01** — z-index 2147483647 reserved + !important — uncovered — true (AC-NEW-18).
- **NC-12-02** — > 500 pins ⇒ 30fps + skip < 16×16 — *covered by AC-065* — **true** (promoted from R21 `unknown`; R-21-03 supplied the wiring).
- **NC-12-03** *(NEW R22)* — Shadow-DOM hosts marked `data-pin-shadow` + InfoPanel reports 'limited inspection' — *covered by AC-060* — true (R-21-02 integration in `pinscope/src/runtime/utils/shadow-dom.ts` + `PinScope.tsx` L197-220 + `InfoPanel.tsx` L145-158).
- **NC-12-04** *(NEW R22)* — Touch: tap=select, long-press (≥ 500ms) = lock — *covered by AC-064* — true (R-21-01 integration in `pinscope/src/runtime/utils/long-press.ts` + `PinScope.tsx` L262-303; `LONG_PRESS_MS=500`).
- **NC-12-05** *(NEW R22)* — HUD collapses below 768px viewport — *covered by AC-064* — true (R-21-01 compact-viewport branch in `PinScope.tsx` L439-446; `MOBILE_BREAKPOINT=768`).

### §13 Performance budgets
- **NC-13-01** — `<PinScope/>` mount < 50 ms — *covered by AC-070* — true (R-21 useEffects all post-paint; no mount-path impact).
- **NC-13-02** — Operation parse < 4 ms — *covered by AC-072* — true.

### §14 Testing strategy
- **NC-14-01** — AST transformer ≥ 50 input/output pairs — *covered by AC-080* — true.
- **NC-14-02** — operation-parser ≥ 30 grammar variants — *covered by AC-081* — true.

### §15 Deployment / exports
- **NC-15-01** — pinscope/vite/runtime/next/webpack subpaths — *covered by AC-090* — true.
- **NC-15-02** — index.ts re-exports withPinScope — uncovered — true (AC-NEW-19).

### §16 Phase plan
- **NC-16-01** — P5 phase definition — `normative:false`.

### §17 APEX integration
- **NC-17-01** — apex-skills/pinscope.md teaches model — *covered by AC-100* — true.
- **NC-17-02** — /apex:ui-phase scaffolds PinScope — *covered by AC-102* — true.
- **NC-17-03** — /apex:ui-review ingests evidence — *covered by AC-103* — true.
- **NC-17-04** — architect + frontend agent list pinscope — *covered by AC-104* — true.
- **NC-17-05** — apex-spec.md registers PinScope — *covered by AC-105* — true.
- **NC-17-06** — round-trip avg < 2 — *covered by AC-107* — `unknown` (aggregate statistic).

## Candidate ACs (proposals — informational, NOT blocking)

21 candidates carry forward unchanged from R21 (AC-NEW-01 … AC-NEW-21). All are `code_satisfied: true`. See JSON `candidate_acs[]` for the full Appendix-A-format rows and their verify methods.

## Strengthen proposals (proposals — informational, NOT blocking)

8 carry forward unchanged from R21. See JSON `strengthen_proposals[]`. Of particular note:

- **AC-024 / AC-025** — R-20-01/02 integration into PinScope.tsx is intact post-R21; strengthening these would lock in the integrated-tree assertion as a contract rather than relying on standalone-component coverage.
- **AC-039** — the Alt-hover sibling-distance sub-behaviour of §8.7 remains UNIMPLEMENTED. Adopting the strengthen proposal would re-open AC-039 until built. This is the **only** strengthen proposal whose adoption would create work.
- **AC-053** — the §8.6 history.json cap-1000 persistence path remains under-verified relative to the claim.

## Blocking findings

**None.** The convergence gate condition `coverage.uncovered_unsatisfied == blocking_findings.length == 0` holds for R22 just as for R21. There is no normative claim that is BOTH un-AC'd AND not satisfied by the code.

## Verdict

PS-R22 narrative axis is **clean — terminal**. R21's three integrations (Shadow-DOM marking, heavy-page throttle + skip-small-badge, touch tap/long-press + responsive collapse) are intact in `pinscope/src/runtime/PinScope.tsx`, are exercised by the `R-21-01/02/03` describe blocks in `tests/unit/runtime/pinscope.test.tsx`, and have been promoted to first-class narrative claims (NC-12-03/04/05) so future scans inherit explicit traceability instead of an implicit §12 sentence. No regression in any prior `code_satisfied: true` claim. The loop may declare convergence on the narrative axis.

---

**Summary line:** `claims: 57 · covered: 36/57 · uncovered_unsatisfied: 0 · candidate_acs: 21 · strengthen_proposals: 8`
