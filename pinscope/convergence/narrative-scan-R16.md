# Narrative Coverage Scan — PinScope PS-R16

- **Round:** 16 · STEP 1B (narrative-auditor)
- **Spec:** `pinscope/SPEC.md` v2.0.0 · `sha256:1779526021db1f5bc7ffe36647e6deb08ba3f8234e82cee31dc0bca5357c7a45`
- **Claims:** 52 normative · **Covered:** 33 · **Uncovered:** 19
- **Candidate ACs:** 19 · **Strengthen proposals:** 6
- **Blocking findings:** 0

## Round summary

R15 raised **9 blocking findings (NF-15-01..NF-15-09)** and remediated all of
them. STEP 3 of R16 independently re-read the current `pinscope/src/` tree —
not the R15 result — to judge whether each fix is real. **All 9 are confirmed
satisfied:**

| R15 finding | Claim | R16 verdict | Evidence (re-read) |
|---|---|---|---|
| NF-15-01 | NC-07-01 | FIXED | `PinScope.tsx` visible-branch portal mounts all 7 §7.1 components (`PinBadges`, `Rulers`, `Crosshair`, `GridOverlay`, `InfoPanel`, `TopBar`, `CommandBar`). |
| NF-15-02 | NC-07-02 | FIXED | `PinScopeProps` declares `hudPosition`, `defaultGridMode`, `shortcutsEnabled`; all three forwarded with defaults and honoured. |
| NF-15-03 | NC-07-03 | FIXED | `FloatingToggle.tsx` exists; `PinScopeHud` `if (!hudVisible)` branch portal-renders only `<FloatingToggle/>`. |
| NF-15-04 | NC-08-07 | FIXED | `CommandBar.tsx` style `height: focused ? 120 : 40`; `focused` toggled on focus/blur. |
| NF-15-05 | NC-08-09 | FIXED | `CommandBar` `onInputKey` has a `Tab` branch calling `getSuggestions(...)` and applying the completion. |
| NF-15-06 | NC-08-11 | FIXED | `StatePanel.generateOverrideRules()` scans `document.styleSheets` / `cssRules` for the forced pseudo-class and synthesizes scoped rules. |
| NF-15-07 | NC-10-01 | FIXED | `EndpointSnapshotStore` POSTs to `/__pinscope/snapshot`; `plugin/index.ts configureServer` writes `.pinscope/snapshots/`. |
| NF-15-08 | NC-12-01 | FIXED | `badges.css.ts` badge `::before`/`:hover`/`[data-pin-selected]` rules now carry `!important` on content/position/background/z-index. |
| NF-15-09 | NC-15-02 | FIXED | `src/index.ts` line 6 `export { withPinScope } from './plugin/next.js'`. |

`coverage.uncovered_unsatisfied` is now **0** → **0 blocking findings**. The
narrative convergence gate is clear for R16.

Two further claims that R15 marked `code_satisfied: false` for under-checking —
**NC-08-03** (Rulers multi-scale + corner coords) and **NC-08-04** (Crosshair
full disable set) — were independently re-verified this round and are **now
satisfied** in code: `Rulers.tsx` carries the 10/50/100/200 scale set (minor
stripes + major tick nodes) plus a `data-pinscope-ruler-corner` live-coords
element, and `Crosshair.tsx` guards on `measuring || hudHidden` in addition to
the over-HUD `closest('[data-pinscope-ui]')` hide. Both are `covered_by`
weak ACs, so they remain strengthen proposals — never blocking.

## Claims by section

- **§1, §16, §17.6** — NC-01-01 / NC-17-06: success-metric / round-trip
  aggregate (95% population rate, average < 2 rounds) remain `unknown`; only a
  single scripted scenario (AC-107) is measured.
- **§3, §16** — NC-03-01, NC-16-01: non-normative architecture/phase context.
- **§4** — NC-04-01/02 covered; NC-04-03 (hooks-only, no Redux/Zustand)
  uncovered but satisfied.
- **§6** — NC-06-01/06/09 covered; NC-06-02/03/04/05/07/08/10 uncovered but
  satisfied (defaults, lifecycle hooks, parser plugins, loc-skip, dirty-gate,
  un-delete, moved-element ID).
- **§7** — NC-07-04/05 covered; NC-07-01/02/03/06 uncovered, all satisfied
  (07-01/02/03 remediated this generation).
- **§8** — NC-08-02/05/06 covered; NC-08-03/04 covered-but-under-checked, now
  satisfied; NC-08-08/10/12 covered-but-under-checked; NC-08-01/07/09/11
  uncovered, all satisfied (07-style remediations). **NC-08-10 (MeasurementTool
  Alt-hover sibling distances) is the one behaviour still UNIMPLEMENTED** — but
  it is `covered_by: ["AC-039"]`, so per the auditor contract it is NOT a
  blocking finding; it is handled by the AC-039 strengthen proposal.
- **§9–§14** — all covered or uncovered-but-satisfied; NC-12-02 (>500-element
  degrade) stays `unknown` — exercised by the AC-065 fixture, component-level
  wiring into a badge component unconfirmed.
- **§15** — NC-15-01 covered; NC-15-02 uncovered, now satisfied.
- **§17** — NC-17-01..05 covered and satisfied.

## Candidate ACs (proposals — never block)

19 candidate ACs, all carried over from R15 (`AC-NEW-01`..`AC-NEW-19`). Every
one is now `code_satisfied: true` — they are paperwork gaps where Appendix A
never wrote a row for a behavior the code already implements. The 9 most urgent
in R15 (`AC-NEW-09/10/11/14/15/16/17/18/19`, all then born `OPEN`) are now
`code_satisfied: true` because their underlying R15 remediations landed.
Adoption is a separate user-approved SPEC bump.

Notable for adoption priority:
- `AC-NEW-09` (NC-07-01, P1) — full §7.1 HUD-tree mount, the keystone runtime AC.
- `AC-NEW-18` (NC-12-01, P1) — badge `!important` hostile-CSS hardening.
- `AC-NEW-19` (NC-15-02, P1) — `withPinScope` re-export from the package root.

## Strengthen proposals (proposals — never block)

6 strengthen proposals for ACs whose `verify:` under-checks the §1–§17 claim:

- **AC-023 / NC-07-04** — assert badge z-index 2147483645 + hover/selected colours.
- **AC-034 / NC-08-03** — assert the full 10/50/100/200 scale set + corner coords.
- **AC-035 / NC-08-04** — assert crosshair absence in measurement mode + HUD-hidden.
- **AC-039 / NC-08-10** — assert Alt-hover sibling distances. **Caveat:** this
  behaviour is currently unimplemented; adopting the strengthened verify would
  re-open AC-039 until MeasurementTool gains the Alt-hover path.
- **AC-042 / NC-08-12** — assert exactly 32 `computed_styles` keys.
- **AC-053 / NC-08-08** — assert CommandBar input history persists to
  `.pinscope/history.json` (via `/__pinscope/history`) capped at 1000.

## Blocking findings

**None.** All 9 R15 blocking findings are independently verified as remediated.
`coverage.uncovered_unsatisfied == blocking_findings.length == 0`.

The single still-unimplemented narrative behaviour (NC-08-10 Alt-hover sibling
distances) is AC-covered (`AC-039`) and therefore — per the auditor contract — a
covered-but-under-checked claim, surfaced only as the AC-039 strengthen
proposal, not a blocking finding.
