# Wave Map — PS-R18

## Plan validation

**ACCEPTED.**

`REMEDIATION-PLAN-R18.md` carries one R-item, **R-18-01**, for the single
binding finding **F-18-01** (CONFIRMED P2 — lossy/duplicated
`.pinscope/history.json` persistence on the §10-C operation flow). The plan
passes all five STEP 1 gate checks:

- **All six mandatory sections present.** R-18-01 has Ecosystem analysis,
  Execution plan, Acceptance criteria, Dependencies, Risk assessment (the five
  REMEDIATION-STYLE.md sections) plus a Definition of Done.
- **Root cause, not symptom.** F-18-01's root cause is the *split
  append-and-persist ownership* of the §10-C history flow — `CommandBar.tsx`
  appends a `parsed: null` placeholder and persists, while `ClaudeBridge.send`
  appends the real `parsed: <Operation>` row and never persists. R-18-01 fixes
  the **ownership**: it makes `HistoryManager.append()` the single commit point
  with one optional persist hook, wires that hook exactly once in
  `PinScope.tsx`, and removes the duplicate `CommandBar` placeholder append plus
  the local `persistHistory`/`HISTORY_ENDPOINT`. It does not patch either the
  duplication symptom or the loss symptom in isolation — it consolidates the
  writer so both symptoms are eliminated at their common source.
- **Definition of Done is mechanically checkable.** Four conditions: a named
  red→green test (`history-persist-ownership (R-18-01)`) with exact
  length-2 / submission-order / both-`parsed`-non-null / no-duplicate-rows /
  last-operation-persisted assertions; a single-persist-owner grep predicate; a
  no-placeholder-duplication grep predicate; and a full-suite no-regression
  check. The DoD explicitly rejects the "no longer duplicated/lossy"
  restatement as insufficient.
- **No silent scope reduction.** Binding scope is the single finding F-18-01,
  the only entry in `audit-findings-R18.json` (`findings: []`,
  `investigation_findings: [F-18-01]`); it is routed to R-18-01.
  `narrative-scan-R18.json` `blocking_findings` is empty — its 19 uncovered
  claims are all `uncovered_satisfied` / `code_satisfied` proposals, out of
  remediation scope. `TEST-AUDIT-R18.md` verdict is WARN (advisory): the AC-075
  flat-tree perf-bound note is standalone, shares no file with R-18-01, and is
  correctly not planned as an R-item. Every binding finding is covered.
- **No line-number anchors in the plan body.** R-18-01 uses content anchors
  throughout — function/identifier names (`append()`, `ClaudeBridge.send`,
  `persistHistory`, `HISTORY_ENDPOINT`, `MAX_ENTRIES`), block descriptions
  ("the `command` `useMemo`", "the Enter branch of `onInputKey`"). Raw
  `file:line` references appear only inside the frozen `audit-findings-R18.json`
  snapshot, which REMEDIATION-STYLE.md explicitly permits.

## Dependency analysis

R-18-01 is the only R-item this round, so there is **no inter-R-item
dependency graph** — no R-item blocks or is blocked by another.

Intra-R-item ordering is fixed inside R-18-01's *Order of operations* and is
not a scheduler concern (it does not split the item across waves): the three
files land together as one execution unit —
`HistoryManager.ts` (add the optional persist hook) →
`PinScope.tsx` (construct the manager with the hook in the `command`
`useMemo`) → `CommandBar.tsx` (drop the duplicate placeholder append, delete
the local `persistHistory`/`HISTORY_ENDPOINT`). The build-module → runtime →
APEX-integration layering rule is satisfied trivially: all three modified
files are in the runtime layer (`pinscope/src/runtime/...`), and the one
external dependency — the `/__pinscope/history` dev-server route in
`src/plugin/index.ts` — is confirmed correct and explicitly untouched.

External (non-R-item) dependency: the unchanged `/__pinscope/history` route
and its `{ version, entries }` POST wire format, which the relocated persist
hook must keep emitting. This is a pre-existing, stable contract — not a
scheduling constraint.

## Waves

### Wave 1

| R-item   | Finding   | Files touched (one owner per file) |
|----------|-----------|-------------------------------------|
| R-18-01  | F-18-01   | `pinscope/src/runtime/managers/HistoryManager.ts`, `pinscope/src/runtime/PinScope.tsx`, `pinscope/src/runtime/components/CommandBar.tsx` |

- **Members:** R-18-01 (the only R-item this round; no dependency on any other
  R-item, so it lands in Wave 1).
- **Files MUST remain untouched:** `pinscope/src/plugin/index.ts`,
  `pinscope/src/runtime/managers/ClaudeBridge.ts`, and the `HistoryManager`
  `MAX_ENTRIES` cap value / `list()` semantics — per R-18-01's preservation
  contract.
- **Gate check:** the round advances only when R-18-01's Definition of Done
  holds — (1) the new `history-persist-ownership (R-18-01)` test exists and is
  green with its exact length-2 / order / both-`parsed`-non-null /
  no-duplicate / last-operation-persisted assertions; (2)
  `grep -rn "/__pinscope/history" pinscope/src/runtime` resolves to exactly one
  POST call site (the `HistoryManager` persist hook), with `persistHistory` and
  `HISTORY_ENDPOINT` no longer present in `CommandBar.tsx`; (3) no code path
  appends a `parsed: null` `HistoryEntry` for an operation/class/query submit;
  (4) full `npm test` is green, including the AC-053 `ClaudeBridge`-isolation
  `entries.length toBe(1)` assertion and the AC-054 autocomplete-latency test.

There is no Wave 2: a single R-item with no dependency occupies Wave 1 alone.
The 5–8-items-per-wave target does not apply to a one-R-item round.

## Conflict matrix

Files touched per R-item, confirming no intra-wave collision (the
write-serial-safety / one-owner-per-wave rule).

| File                                                  | R-18-01 | Other R-items in Wave 1 |
|-------------------------------------------------------|---------|--------------------------|
| `pinscope/src/runtime/managers/HistoryManager.ts`     | write   | none                     |
| `pinscope/src/runtime/PinScope.tsx`                   | write   | none                     |
| `pinscope/src/runtime/components/CommandBar.tsx`      | write   | none                     |

Wave 1 contains exactly one R-item, so every file in the matrix has a single
owner and **no two R-items in the same wave modify the same file**. The
write-serial-safety constraint holds trivially. Files in R-18-01's
"MUST remain untouched" list (`pinscope/src/plugin/index.ts`,
`pinscope/src/runtime/managers/ClaudeBridge.ts`) appear in no R-item's write
set and are intentionally absent from this matrix.
