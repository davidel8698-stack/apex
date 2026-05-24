# Wave Map — PS-R16

## Plan validation

`ACCEPTED`

STEP-1 gate, all criteria checked against `REMEDIATION-PLAN-R16.md`:

- **Mandatory sections.** All three R-items (R-16-01, R-16-02, R-16-03)
  carry the five REMEDIATION-STYLE.md sections (Linked finding / Spec anchor,
  Ecosystem analysis, Execution plan, Acceptance criteria, Dependencies, Risk
  assessment) plus a Definition of Done. None missing.
- **Root cause, not symptom.** R-16-01 wires the §10 B/C/D + §8.7 flow seams
  (root cause A: components mounted, flows unwired) rather than patching one
  seam; R-16-02 closes the `CommandBar → fetch` network-seam coverage gap that
  lets mutant M2 survive; R-16-03 closes the `plugin.test.ts` response-body /
  recursive-mkdir under-assertion (root cause class for M3/M4/M5). Each fix
  targets the root cause its own analysis names.
- **Definition of Done.** Every DoD is mechanically checkable by a reader who
  never saw the diff: grep predicates with explicit match counts, named
  red→green test transitions, and transient-mutation kill checks (M2/M3/M4/M5).
  None merely restates the finding.
- **Silent scope reduction.** Binding scope this round = the 8 spec-auditor
  investigation findings F-16-01..F-16-08 (`narrative-scan-R16.json`
  `blocking_findings` is empty; `TEST-AUDIT-R16.md` verdict WARN is advisory
  and produces no mandatory findings). Every finding maps to an R-item:
  F-16-01→R-16-01, F-16-02→R-16-01, F-16-03→R-16-01, F-16-04→R-16-01,
  F-16-05→R-16-03, F-16-06→R-16-03, F-16-07→R-16-03, F-16-08→R-16-02.
  8/8 routed. No finding dropped.
- **Line-number anchors.** The plan body uses content anchors only
  (`PinScopeHud`, `persistHistory`, named `describe(...)` blocks, function /
  identifier names). Raw `file:line` refs appear only inside
  `audit-findings-R16.json`, which REMEDIATION-STYLE.md explicitly permits as a
  frozen audit snapshot. No line-number anchors in the plan body.

**Noted, non-gating:** the Round-summary prose says "reduces 8 findings to
**4 R-items**" and "8/8 routed across **4 R-items**", but the document defines
exactly three R-item sections (R-16-01, R-16-02, R-16-03) and the explicit
routing line lists only those three ids. This is a prose miscount, not a
defect: no finding is unrouted and no R-item is missing. It is not a STEP-1
rejection trigger (missing section / symptom fix / hollow DoD / silent scope
reduction / line-number anchor) — every finding maps to a real, fully-specified
R-item. Recorded here for the orchestrator; the plan proceeds to scheduling.

## Dependency analysis

Three R-items, scheduled across two waves.

- **R-16-01** (P1, runtime layer) — modifies `src/runtime/PinScope.tsx` and
  `src/runtime/components/TopBar.tsx`; creates
  `src/runtime/hooks/useSelectedElement.ts`. Plan states **no upstream
  dependency**: every primitive it wires (`parseCommand`, `buildOperation`,
  `ClaudeBridge`, `SnapshotManager`, `EndpointSnapshotStore`, `SelectionManager`,
  `MeasurementTool`) already exists and is unit-tested. → eligible for Wave 1.

- **R-16-03** (P3, test layer) — modifies only `tests/unit/plugin.test.ts`;
  asserts against `src/plugin/index.ts`, which it does **not** edit. Plan states
  **no dependency** on R-16-01 or R-16-02 (`src/plugin/*` is disjoint from the
  `src/runtime/*` surface R-16-01 touches). → eligible for Wave 1.

- **R-16-02** (P2, test layer) — modifies only
  `tests/unit/runtime/controls.test.tsx`. Plan declares an **upstream
  dependency on R-16-01**: the new CommandBar persistence test is authored
  against the live `onSubmit` Flow-C path that R-16-01 lands, so it must be
  written *after* R-16-01. R-16-02 does not edit any file R-16-01 edits, so the
  dependency is an **ordering constraint, not a write conflict** — it
  nonetheless forces R-16-02 into a later wave than R-16-01. → Wave 2.

Layering: R-16-01 is the runtime-layer fix; R-16-02 / R-16-03 are test-layer
fixes. R-16-02's runtime test depends on the runtime wiring landing first;
R-16-03's plugin test is independent of the runtime layer. No
APEX-integration-layer R-items this round.

Dependency graph:

```
R-16-01  ──(ordering: live onSubmit path)──▶  R-16-02
R-16-03  (independent — no edge in or out)
```

## Waves

### Wave 1 — R-16-01, R-16-03

| R-item   | Files touched                                                                                                                  |
|----------|--------------------------------------------------------------------------------------------------------------------------------|
| R-16-01  | modify `src/runtime/PinScope.tsx`; modify `src/runtime/components/TopBar.tsx`; create `src/runtime/hooks/useSelectedElement.ts` |
| R-16-03  | modify `tests/unit/plugin.test.ts`                                                                                             |

**Wave gate check:** R-16-01 and R-16-03 have no dependency on any other
R-item this round (R-16-01 upstream = none; R-16-03 upstream = none) — both are
Wave-1 eligible. Write-serial safety: R-16-01's file set
{`src/runtime/PinScope.tsx`, `src/runtime/components/TopBar.tsx`,
`src/runtime/hooks/useSelectedElement.ts`} and R-16-03's file set
{`tests/unit/plugin.test.ts`} are **disjoint** — no file has two owners in this
wave. Safe to execute in parallel.

### Wave 2 — R-16-02

| R-item   | Files touched                                          |
|----------|--------------------------------------------------------|
| R-16-02  | modify `tests/unit/runtime/controls.test.tsx`          |

**Wave gate check:** R-16-02's only dependency, R-16-01, lands in Wave 1
(< Wave 2) — dependency satisfied. R-16-02 is the sole R-item in this wave, so
the one-owner-per-wave rule holds trivially. The wave is below the 5–8
target band; per STEP 3 a smaller final wave is acceptable, and the R-16-01
ordering constraint makes it mandatory here.

## Conflict matrix

Files touched, by R-item — confirming no intra-wave collision.

| File                                          | R-16-01 | R-16-02 | R-16-03 | Wave  |
|------------------------------------------------|---------|---------|---------|-------|
| `src/runtime/PinScope.tsx`                     | modify  | —       | —       | 1     |
| `src/runtime/components/TopBar.tsx`            | modify  | —       | —       | 1     |
| `src/runtime/hooks/useSelectedElement.ts`      | create  | —       | —       | 1     |
| `tests/unit/plugin.test.ts`                    | —       | —       | modify  | 1     |
| `tests/unit/runtime/controls.test.tsx`         | —       | modify  | —       | 2     |

- **Wave 1** (R-16-01, R-16-03): every row with a Wave-1 mark has exactly one
  owner. The two R-items' file sets are disjoint — no collision.
- **Wave 2** (R-16-02): single R-item — no collision possible.
- **No file is touched by two R-items in any wave.** Every column pair
  (R-16-01/R-16-02, R-16-01/R-16-03, R-16-02/R-16-03) shares no file, so the
  write-serial rule holds and the R-16-02-after-R-16-01 split is driven purely
  by the declared ordering dependency, not by a file conflict.
