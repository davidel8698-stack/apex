# Wave Map — PS-R15

## Plan validation

## PLAN REJECTED

The plan `REMEDIATION-PLAN-R15.md` does not pass the STEP 1 plan gate. No waves
are emitted. The orchestrator must halt round 15 and re-author the plan.

### Defect 1 — Silent scope reduction: F-15-05 has no R-item

`audit-findings-R15.json` carries **11 spec-auditor investigation findings**
(F-15-01..F-15-11). Mapping every finding to an R-item:

| Finding | Confidence | Severity | R-item | Status |
|---|---|---|---|---|
| F-15-01 | CONFIRMED | P1 | R-15-01 | covered |
| F-15-02 | CONFIRMED | P2 | R-15-01 | covered |
| F-15-03 | CONFIRMED | P2 | R-15-01 | covered |
| F-15-04 | CONFIRMED | P2 | R-15-04 | covered |
| **F-15-05** | **CONFIRMED** | **P2** | **— none —** | **UNCOVERED** |
| F-15-06 | CONFIRMED | P2 | R-15-02 | covered |
| F-15-07 | CONFIRMED | P2 | R-15-06 | covered |
| F-15-08 | CONFIRMED | P2 | R-15-03 | covered |
| F-15-09 | CONFIRMED | P2 | R-15-05 | covered |
| F-15-10 | SUSPECTED | P3 | R-15-07 | covered |
| F-15-11 | SUSPECTED | P3 | R-15-08 | covered |

**F-15-05 is covered by no R-item.** It is the Rulers §8.2 gap: `Rulers.tsx`
generates ticks at a single uniform `interval` (default 100) and renders no
corner element, while §8.2 requires a multi-scale tick set (10/50/100/200 px)
and a corner showing live mouse coordinates. The finding is **CONFIRMED** (not
SUSPECTED, not BLOCKED) and is independently corroborated by the narrative scan
claim **NC-08-03** (`code_satisfied: false`, "no multi-scale 10/50/100/200 tick
set; no corner live-coords element").

The plan's round summary asserts "**13 distinct findings**" assembled from "11
spec-auditor investigation findings" via "4 shared-root-cause groups", and
enumerates Group A (F-15-01/02/03), Group B (F-15-04), Group C (F-15-07), Group
D (F-15-08/09/10). None of the four declared groups, and no R-item, references
F-15-05 or `Rulers.tsx`. There is no documented shared-root-cause rationale
folding F-15-05 into another R-item — R-15-01 explicitly mounts `Rulers` as an
already-built component and disclaims editing it ("The individual component
files (`Rulers.tsx`, `Crosshair.tsx`, etc.) ... are not edited by this
R-item"). F-15-05 is therefore silently dropped.

A CONFIRMED finding with no R-item is a **silent scope reduction**
(`framework/agents/ps-scheduler.md` STEP 1; REMEDIATION-STYLE.md): scope
reduction is a bug, not a planner's prerogative. The plan must be re-authored
to add an R-item that fixes `Rulers.tsx` to the §8.2 multi-scale-tick +
corner-coordinates contract, or — if the planner believes F-15-05 belongs in an
existing R-item — to state that shared-root-cause grouping explicitly and route
the finding through it.

### Defect 2 — Round summary finding count is inconsistent with coverage

The round summary claims 13 distinct findings (11 investigation + 9 narrative
blocking + 2 hollow-test, collapsed via shared root causes). After grouping,
the plan routes exactly 10 investigation findings (F-15-01,02,03,04,06,07,08,
09,10,11) plus AC-076 and AC-107. F-15-05 — the eleventh investigation finding
— is absent from every R-item, every linked-finding list, and every declared
group. The "13 distinct findings ... collapsed into 10 R-items" arithmetic
silently omits one source finding. This is the same defect as Defect 1 viewed
from the plan's own bookkeeping; it is recorded separately so the re-author
also corrects the round summary.

### Scheduling not performed

Per the WRITE-FIRST CONTRACT and STEP 1, because the plan is rejected the
scheduler emits **no `## Dependency analysis`, no `## Waves`, and no
`## Conflict matrix`**. The remaining R-items (R-15-01 root assembly through
R-15-10) were NOT validated for write-serial safety or sequenced — a rejected
plan is not scheduled. Once the plan is re-authored to cover F-15-05, the full
plan re-enters STEP 1 from the top.

---

_No waves emitted. Round 15 halts pending plan re-authoring._
