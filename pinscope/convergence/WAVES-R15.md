# Wave Map — PS-R15

## Plan validation

**ACCEPTED.**

Re-gated fresh after the prior plan was rejected for a silent scope reduction
(finding `F-15-05`, Rulers §8.2, had no R-item). The re-authored plan has 11
R-items (`R-15-01..R-15-11`). This is a full fresh gate — the prior verdict was
not assumed correct and nothing else was assumed unchanged.

STEP 1 gate, all five rejection conditions checked:

- **Silent scope reduction — PASS.** All 22 raw findings route to an R-item:
  - 11 spec-auditor findings: `F-15-01/02/03`→R-15-01, `F-15-04`→R-15-05,
    `F-15-05`→R-15-03, `F-15-06`→R-15-02, `F-15-07`→R-15-07, `F-15-08`→R-15-04,
    `F-15-09`→R-15-06, `F-15-10`→R-15-08, `F-15-11`→R-15-09. 11/11 routed.
  - 9 narrative `blocking_findings`: `NF-15-01/02/03`→R-15-01,
    `NF-15-04/05`→R-15-07, `NF-15-06`→R-15-04, `NF-15-07`→R-15-06,
    `NF-15-08`→R-15-05, `NF-15-09`→R-15-08. 9/9 routed.
  - 2 test-audit findings: `AC-076`→R-15-10, `AC-107`→R-15-11. 2/2 routed.
  - **The prior-round defect is verified fixed.** `F-15-05` (Rulers §8.2,
    multi-scale `10/50/100/200` ticks + live-coords corner) is now covered by
    **R-15-03** — a full six-section R-item with spec anchor §8.2, files
    `src/runtime/components/Rulers.tsx`, and a red→green DoD that fails the
    current single-uniform-interval implementation. Corroborated by the
    `claims` entry `NC-08-03` (`code_satisfied: false`); the plan correctly
    notes `NC-08-03` is a `claims` entry, not a `blocking_findings` entry, so
    `F-15-05` is the sole routed finding for R-15-03. The plan's round-summary
    arithmetic (`11 spec-auditor + 9 narrative + 2 test-audit = 22 → 11
    R-items`) is now internally consistent.
  - No regression elsewhere: `candidate_acs` / `strengthen_proposals` are
    proposals and correctly out of scope; the 7 BLOCKED ACs are environment
    limits, not findings, and are correctly not planned.
- **Missing section — PASS.** All 11 R-items carry the five
  REMEDIATION-STYLE sections (Ecosystem analysis, Execution plan, Acceptance
  criteria, Dependencies, Risk assessment) plus Definition of Done. R-15-08 and
  R-15-09 add a mandatory `Step 1 — CONFIRM/REFUTE` inside Execution plan; that
  is an extra step within a present section, not a missing section.
- **No root cause — PASS.** Every R-item names a root cause, not a symptom:
  R-15-01 the `PinScope.tsx` root frozen at "PS-R2 scope" and never
  reassembled; R-15-03 a component built to an under-specified AC rather than
  §8.2; R-15-05 the missing `!important` qualifier; R-15-10 / R-15-11 the
  hollow test-design shortcut (source-grep / self-fulfilling demo).
- **Hollow Definition of Done — PASS.** Every DoD is mechanically checkable by
  someone who never saw the change: named test files transitioning red→green,
  grep predicates with explicit counts (`grep -cE ... ≥ 5`, `grep -c
  '!important' ... ≥ 12`), `npm test` exit 0. R-15-08 / R-15-09 give a
  verifiable REFUTED branch (`git diff --stat` empty + a cited §-line). None
  merely restates the finding or says "looks right".
- **Line-number anchors — PASS.** The plan body uses content anchors
  throughout (`PinScopeProps` interface, `PinScopeHud` function body,
  `applyStateOverride`, the `configureServer` hook, the `ticks(...)`
  generator, the `parsed.kind === 'operation'` branch). Line numbers appear
  only in the frozen `audit-findings-R15.json` `re_read` fields (`lines 9-14`,
  `lines 59-67`) — explicitly permitted by REMEDIATION-STYLE for audit
  snapshots, never in the plan body.

Plan is scheduled below.

## Dependency analysis

Layering rule (build-module → runtime → APEX-integration) and the
final-form file-read rule produce the following graph.

- **R-15-01** (assemble the `<PinScope/>` HUD root, `src/runtime/PinScope.tsx`
  + new `src/runtime/components/FloatingToggle.tsx`) is the round's hub. It
  *mounts* Rulers, Crosshair, GridOverlay, TopBar, CommandBar, StatePanel,
  etc., but does **not edit** them — its preservation list explicitly disclaims
  editing the individual component files. It therefore depends on no other
  R-item for correctness. Its plan states the Crosshair-guard props (R-15-02)
  are passed regardless: if R-15-02 lands later the props are simply ignored —
  no regression. **R-15-01 has no hard dependency.** It is the sole owner of
  `PinScope.tsx`.
- **R-15-02** (Crosshair guards, `Crosshair.tsx`) — additive optional props,
  no upstream dependency. It is *consumed by* R-15-01's wiring but does not
  block it. Placed in the same wave as R-15-01 (different files, no conflict);
  the executor serializes R-15-02's component edit before R-15-01's Crosshair
  wiring step.
- **R-15-03** (Rulers multi-scale ticks + corner coords, `Rulers.tsx`) —
  internal upgrade of a component R-15-01 only mounts; the
  `data-pinscope-rulers` / `data-pinscope-ui` handles are preserved so
  R-15-01's assembly DoD still resolves. No dependency. Independent file.
- **R-15-04** (StatePanel host-stylesheet scan, `StatePanel.tsx`) —
  independent hardening of a mounted component. No dependency. Independent
  file.
- **R-15-05** (badge `!important` hardening, `src/runtime/styles/badges.css.ts`)
  — independent. No dependency. Independent file.
- **R-15-06** (snapshot persistence: `src/plugin/index.ts` `configureServer`
  route + new `src/runtime/managers/EndpointSnapshotStore.ts`) — a
  **build-module / dev-server-middleware** fix. It edits `src/plugin/index.ts`,
  shared with R-15-07. Per the build→runtime layering and the soft dependency
  the plan declares, R-15-06's `configureServer` snapshot-route edit is
  sequenced **before** R-15-07's history-route edit on the same file.
- **R-15-07** (CommandBar §8.6: `CommandBar.tsx` + `src/plugin/index.ts`
  history route) — also edits `src/plugin/index.ts`. **Write-serial conflict
  with R-15-06 on that file → the two must not share a wave.** R-15-07 is
  scheduled in a wave strictly after R-15-06.
- **R-15-08** (`withPinScope` package-root re-export, `src/index.ts`) —
  independent, CONFIRM/REFUTE-first. Independent file.
- **R-15-09** (`delta` field routing, `src/runtime/parsers/operation-builder.ts`)
  — independent, CONFIRM/REFUTE-first. Independent file.
- **R-15-10** (rewrite `tests/unit/screenshot.test.ts` to a behavioral test) —
  test-only, independent file.
- **R-15-11** (rewrite `tests/unit/roundtrip.test.ts` onto production
  primitives) — test-only. Soft relation to R-15-09 (if both land together the
  completeness check must accept `delta` *or* `value`); **no file conflict**
  (`roundtrip.test.ts` vs `operation-builder.ts`), so this is an authoring
  note, not a wave constraint.

**Net constraint set:** exactly one ordering edge — `R-15-06 → R-15-07` — and
one shared file — `src/plugin/index.ts` (R-15-06, R-15-07). Every other R-item
is dependency-free and touches a distinct file (`PinScope.tsx` owned solely by
R-15-01). Two waves suffice.

## Waves

### Wave 1 — gate: no R-item depends on another R-item this round; no two R-items touch the same file

| R-item | Files touched | Layer |
|---|---|---|
| R-15-06 | `src/plugin/index.ts` (`configureServer` `POST /__pinscope/snapshot` route); **create** `src/runtime/managers/EndpointSnapshotStore.ts` | build-module + runtime |
| R-15-01 | `src/runtime/PinScope.tsx`; **create** `src/runtime/components/FloatingToggle.tsx` | runtime (root assembly) |
| R-15-02 | `src/runtime/components/Crosshair.tsx` | runtime |
| R-15-03 | `src/runtime/components/Rulers.tsx` | runtime |
| R-15-04 | `src/runtime/components/StatePanel.tsx` | runtime |
| R-15-05 | `src/runtime/styles/badges.css.ts` | runtime |
| R-15-08 | `src/index.ts` | integration |
| R-15-09 | `src/runtime/parsers/operation-builder.ts` | runtime |

Wave-gate check: 8 R-items, 10 distinct files (incl. 3 created), **zero file
collision** — each file has exactly one owner this wave. R-15-06 is placed in
Wave 1 (build-module fix precedes runtime) so the build-module half of the
only ordering edge lands first, freeing R-15-07's runtime half for Wave 2.
R-15-01 owns `PinScope.tsx` alone; R-15-02 mounts in the same wave on a
different file (`Crosshair.tsx`) — its guard props are consumed by R-15-01's
wiring, and the executor serializes the R-15-02 component edit before
R-15-01's `PinScopeHud` portal-body wiring step (intra-file order is moot —
they are separate files). One-owner-per-wave holds. 8 R-items is within the
5–8 band.

### Wave 2 — gate: all dependencies (R-15-06) are in Wave 1; no two R-items touch the same file

| R-item | Files touched | Layer |
|---|---|---|
| R-15-07 | `src/runtime/components/CommandBar.tsx`; `src/plugin/index.ts` (add `POST /__pinscope/history` route) | runtime + build-module |
| R-15-10 | `tests/unit/screenshot.test.ts` | test |
| R-15-11 | `tests/unit/roundtrip.test.ts` | test |

Wave-gate check: 3 R-items, 4 distinct files, **zero file collision**.
R-15-07 is here, not in Wave 1, solely because it shares `src/plugin/index.ts`
with R-15-06 — write-serial safety forbids them in one wave. R-15-06's
`configureServer` snapshot route lands and is committed in Wave 1; R-15-07
then adds the `/__pinscope/history` route to that file in its final form.
R-15-11's soft relation to R-15-09 (Wave 1) is satisfied trivially: R-15-09 is
already landed, so R-15-11's completeness predicate authors `value !==
undefined || delta !== undefined` against the final builder. A smaller final
wave (3 R-items) is permitted by the 5–8 guideline.

## Conflict matrix

Files touched, by R-item, across both waves. A file with two R-items in the
**same wave** would be a collision; none exists.

| File | R-items | Wave(s) | Collision? |
|---|---|---|---|
| `src/runtime/PinScope.tsx` | R-15-01 | W1 | no — sole owner |
| `src/runtime/components/FloatingToggle.tsx` *(created)* | R-15-01 | W1 | no |
| `src/runtime/components/Crosshair.tsx` | R-15-02 | W1 | no |
| `src/runtime/components/Rulers.tsx` | R-15-03 | W1 | no |
| `src/runtime/components/StatePanel.tsx` | R-15-04 | W1 | no |
| `src/runtime/styles/badges.css.ts` | R-15-05 | W1 | no |
| `src/index.ts` | R-15-08 | W1 | no |
| `src/runtime/parsers/operation-builder.ts` | R-15-09 | W1 | no |
| `src/runtime/managers/EndpointSnapshotStore.ts` *(created)* | R-15-06 | W1 | no |
| `src/plugin/index.ts` | **R-15-06, R-15-07** | **W1, W2** | **no — split across waves** (R-15-06 in W1, R-15-07 in W2; serialized by the `R-15-06 → R-15-07` edge) |
| `src/runtime/components/CommandBar.tsx` | R-15-07 | W2 | no |
| `tests/unit/screenshot.test.ts` | R-15-10 | W2 | no |
| `tests/unit/roundtrip.test.ts` | R-15-11 | W2 | no |

The only multi-R-item file, `src/plugin/index.ts`, has its two owners in
different waves — the one-owner-per-wave rule holds for every wave. No
intra-wave collision exists.
