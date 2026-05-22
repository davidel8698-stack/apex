# Narrative Coverage Scan — PS-R17

- **Round:** 17 (convergence-confirmation round)
- **Spec:** `pinscope/SPEC.md` v2.0.0 — `sha256:1779526021db1f5bc7ffe36647e6deb08ba3f8234e82cee31dc0bca5357c7a45`
- **Spec hash:** unchanged from R16 — the North-Star is frozen and stable.
- **Prior scan:** `narrative-scan-R16.json` (52 claims, 33 covered, 19 uncovered — all 19 satisfied, 0 blocking findings).

## Coverage summary

R17 is a convergence-confirmation pass. STEP 3 independently re-read the current
`pinscope/src` and `framework/` code for every normative claim — no satisfaction
was assumed from R16. Result: the tree is converged. All 52 narrative claims
carry over from R16 with stable `claim_id`s (the spec hash is unchanged, so no
claim was added, dropped, or re-worded).

- **Claim objects:** 54 — 52 `normative: true` (counted in the coverage block)
  plus 2 non-normative context entries (`NC-03-01` layer grouping, `NC-16-01`
  phase plan) carried for ID stability.
- **Total normative claims:** 52 = 33 covered + 19 uncovered.
- **Covered by Appendix A:** 33
- **Uncovered:** 19 → 19 candidate ACs; **all 19 satisfied by code** —
  `uncovered_unsatisfied = 0`.
- **Strengthen proposals:** 6 (covered ACs whose `verify:` under-checks the claim).
- **Blocking findings:** 0.

`uncovered_unsatisfied == blocking_findings.length == 0` — the convergence gate
is clear. The nine R15 blocking findings remediated in R16 (`NF-15-01`..`09`)
were each independently re-confirmed this round and remain satisfied.

## Claims by section

### §1, §4 — Mission & Stack
- `NC-01-01` *(AC-107)* success metric 95%/<=2 rounds — population statistic,
  `code_satisfied: unknown` (one scenario tested, not the aggregate rate).
- `NC-04-01` *(AC-073)* dev bundle < 80 KB — satisfied.
- `NC-04-02` *(AC-010/074)* prod 0 bytes — satisfied.
- `NC-04-03` **uncovered** — no Redux/Zustand; React hooks only. Satisfied
  (`grep -rni 'redux|zustand' src package.json` → 0). → AC-NEW-01.

### §6 — Build module
All build claims re-read and satisfied. Uncovered: `NC-06-02` (resolveOptions
defaults), `NC-06-03` (buildStart/buildEnd lifecycle), `NC-06-04` (parser
plugins), `NC-06-05` (loc-absent skip), `NC-06-07` (dirty-gated save),
`NC-06-08` (un-delete on re-sight), `NC-06-10` (moved element → new id) →
AC-NEW-02..08. Covered: `NC-06-01` (AC-001), `NC-06-06` (AC-011), `NC-06-09`
(AC-008).

### §7 — Runtime core
- `NC-07-01` **uncovered** — full §7.1 HUD tree portal-rendered. R17 re-read
  PinScope.tsx lines 233-252: all 7 components present. → AC-NEW-09.
- `NC-07-02` **uncovered** — props hudPosition/defaultGridMode/shortcutsEnabled
  declared and honoured. → AC-NEW-10.
- `NC-07-03` **uncovered** — HUD-hidden branch renders only FloatingToggle. →
  AC-NEW-11.
- `NC-07-04` *(AC-023)* badge z-index 2147483645-2147483647 + colour states —
  satisfied; AC-023 under-checks → strengthen.
- `NC-07-05` *(AC-024/025)* void overlay badges + MutationObserver — satisfied.
- `NC-07-06` **uncovered** — rAF-throttled hover. → AC-NEW-12.

### §8 — Components
- `NC-08-01` **uncovered** — InfoPanel geometry (fixed/right:16/top:56/w:320). →
  AC-NEW-13.
- `NC-08-02` *(AC-033)* em-dash for empty values — satisfied.
- `NC-08-03` *(AC-034)* rulers 24px + 10/50/100/200 ticks + corner coords —
  satisfied; AC-034 checks only 100px → strengthen.
- `NC-08-04` *(AC-035)* crosshair disabled over-HUD / measuring / hidden —
  satisfied; AC-035 checks only over-HUD → strengthen.
- `NC-08-05` *(AC-036)* GridOverlay 4 modes + cycle + SVG pattern — satisfied.
- `NC-08-06` *(AC-037)* TopBar fixed/top:0/32px + 4 fields — satisfied.
- `NC-08-07` **uncovered** — CommandBar 40px→120px focus expand. → AC-NEW-14.
- `NC-08-08` *(AC-053)* history → .pinscope/history.json last 1000 — satisfied
  (handleHistoryRequest caps at HISTORY_MAX_ENTRIES=1000); AC-053 under-checks →
  strengthen.
- `NC-08-09` **uncovered** — CommandBar Tab autocomplete wired (lines 96-110). →
  AC-NEW-15.
- `NC-08-10` *(AC-039)* MeasurementTool — Δx/Δy/diagonal/gap satisfied;
  **Alt-hover sibling-distances sub-behaviour is UNIMPLEMENTED** (`grep -ni
  'alt|sibling'` MeasurementTool.tsx → 0). This is **NOT a blocking finding**:
  the claim is `covered_by AC-039`, so the unmet sub-behaviour is a
  covered-but-under-checked gap handled by the AC-039 strengthen proposal — a
  proposal, never a convergence blocker.
- `NC-08-11` **uncovered** — StatePanel generateOverrideRules scans
  document.styleSheets. → AC-NEW-16.
- `NC-08-12` *(AC-042)* SnapshotManager 32 computed styles — satisfied
  (TRACKED_STYLES literal counted = exactly 32); AC-042 doesn't pin the count →
  strengthen.

### §9–§13 — Schemas, flows, protocol, perf
- `NC-09-01` *(AC-006)*, `NC-09-02` *(AC-052)* — satisfied.
- `NC-10-01` **uncovered** — snapshot persists via `/__pinscope/snapshot`
  (EndpointSnapshotStore + plugin configureServer). → AC-NEW-17.
- `NC-10-02` *(AC-071)*, `NC-13-01` *(AC-070)*, `NC-13-02` *(AC-072)* — perf
  budgets, satisfied via tagged perf tests.
- `NC-11-01` *(AC-050)*, `NC-11-02` *(AC-051)* — operation grammar & shortcuts,
  satisfied.
- `NC-12-01` **uncovered** — z-index 2147483647 reserved + badge !important
  hardening. → AC-NEW-18.
- `NC-12-02` *(AC-065)* >500-element degrade — AC-tagged fixture test exists;
  badge-component wiring unconfirmed (`grep '500|16'` PinBadges/VoidBadges → 0).
  `code_satisfied: unknown`. Covered by AC-065, so not a blocking finding.

### §14–§15 — Testing & deployment
- `NC-14-01` *(AC-080)* transformer suite >= 50 pairs — satisfied (44 HTML + 8
  component + 4 explicit = 56 cases).
- `NC-14-02` *(AC-081)* parser suite >= 30 — satisfied.
- `NC-15-01` *(AC-090)* export subpaths — satisfied.
- `NC-15-02` **uncovered** — src/index.ts re-exports withPinScope (line 6); AC-091
  doesn't list it, so removing it wouldn't fail AC-091. → AC-NEW-19.

### §17 — APEX integration
`NC-17-01`..`06` all covered (AC-100/102/103/104/105/107). `grep` re-checks
confirmed each framework file/heading present this round. `NC-17-06` aggregate
"average < 2 rounds" remains `code_satisfied: unknown` (one scripted scenario,
not the average).

## Candidate ACs (proposals — never block convergence)

19 candidate ACs, all carried over from R16 (`AC-NEW-01`..`19`), every one
`code_satisfied: true`. They are proposals for the user to adopt into Appendix A
via a SPEC version bump; they do not block the loop. Each `re_read` is recorded
in the JSON.

## Strengthen proposals (proposals — never block convergence)

6 strengthen proposals: `AC-023` (badge z-index/colour), `AC-034` (multi-scale
ticks + corner coords), `AC-035` (crosshair full disable set), `AC-039`
(Alt-hover sibling distances — note: adopting this re-opens AC-039 until the
behaviour is built), `AC-042` (exact 32-key count), `AC-053` (CommandBar history
file + 1000 cap). Each quotes its `claim_quote`, `current_verify`, and
`proposed_verify` in the JSON.

## Blocking findings

**None.** No normative claim is both `covered_by: []` and `code_satisfied:
false`. `NC-08-10`'s unimplemented Alt-hover sub-behaviour is covered by AC-039
and therefore handled as a strengthen proposal, not a blocking finding.
`uncovered_unsatisfied = 0 = blocking_findings.length` — the convergence gate is
clear. The tree is converged at PS-R17.
