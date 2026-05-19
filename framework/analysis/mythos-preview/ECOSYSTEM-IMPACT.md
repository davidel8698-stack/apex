# Ecosystem Impact Matrix — Mythos IMPs

> Cross-cutting matrix derived from per-IMP analysis files (`imps/IMP-NNN.md`).
> Each row aggregates the answers to questions 7 (downstream), 8 (prerequisites),
> 9 (do-not-touch), plus the conflicts list, into a horizontal view.
>
> **Purpose:** Detect ecosystem clashes between IMPs before scheduling. Two IMPs
> that both modify the same file with incompatible patterns must be serialized
> or merged — this matrix surfaces those cases.
>
> Rows are added ONLY when a per-IMP file is created. Empty matrix until then.

## Matrix

| IMP-ID | Affects Agents | Affects Hooks | Affects Commands | Affects Schemas | Prerequisites (must change first) | Forbidden zones (do not touch) | Conflicts with |
|---|---|---|---|---|---|---|---|
| [IMP-001](imps/IMP-001.md) | critic.md, executor.md, architect.md, verifier.md (downstream-aware only) | pre-task-snapshot.sh, phase-tag.sh (downstream-aware only), phantom-check.sh (do-not-touch), destructive-guard.sh (do-not-touch) | next.md, execute-phase.md (downstream-aware only) | RESULT.schema.json (add `task_start_sha`), apex-spec.md (amendment for critic responsibilities) | 1. Schema field added as optional → 2. pre-task-snapshot captures SHA → 3. executor emits → 4. existing tests pass → 5. mark required → 6. critic STEP 1.5 added → 7. new test created → 8. spec updated | critic.md clean-room protocol (`WHAT YOU NEVER RECEIVE` section); critic.md existing STEP 2/3/4 ordering; destructive-guard.sh (IMP-008 territory); phantom-check.sh (different layer); verifier.md verdict-handling | IMP-012, IMP-019, IMP-020 (other critic.md edits — serialize via merge ordering, confirmed when those IMPs are analyzed) |

## Cluster-level rollups

> Populated after a full cluster is analyzed. Aggregates per-cluster
> bottlenecks and shared do-not-touch zones.

### critic-cluster
_TBD — populated after critic-cluster analysis completes._

### destructive-guard-cluster
_TBD._

### executor-cluster
_TBD._

### hooks-state-cluster
_TBD._

## Cycle detection

> A cycle exists if IMP-A blocks IMP-B and IMP-B blocks IMP-A (directly or
> transitively). Cycles must be broken by human decision before any IMP in the
> cycle is scheduled.
>
> _No cycles detected yet (matrix empty)._
