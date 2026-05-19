# IMP Analysis Index — Mythos Preview

> Single status table for all 76 IMPs from [`APEX-IMPROVEMENTS.md`](APEX-IMPROVEMENTS.md).
> Updated as IMPs progress through the lifecycle defined in [`METHODOLOGY.md`](METHODOLOGY.md).
>
> **Status legend:** `pending` → `analyzing` → `analyzed` → (`needs-human-decision` | `blocked` | `scheduled`) → `in-progress` → `done` | `wontfix`

## Summary counters

| Status | Count |
|---|---|
| pending | 75 |
| analyzing | 0 |
| analyzed | 1 |
| needs-human-decision | 0 |
| blocked | 0 |
| scheduled | 0 |
| in-progress | 0 |
| done | 0 |
| wontfix | 0 |
| **Total** | **76** |

## Status table

> Only IMPs that have moved off `pending` appear in detail below. Default state
> for all 76 IMPs is `pending`; the bulk row at the bottom captures the rest.

| IMP-ID | Priority | Cluster | Status | Analyst | Date | Notes / File |
|---|---|---|---|---|---|---|
| IMP-001 | P0 | critic | analyzed | Claude (pilot) | 2026-05-17 | [imps/IMP-001.md](imps/IMP-001.md) — awaiting user review; gate not yet evaluated |
| IMP-002 through IMP-076 | mixed | mixed | pending | — | — | not yet analyzed |

## Cluster assignments (preliminary, refined as IMPs are analyzed)

Based on `Files affected` in [`APEX-IMPROVEMENTS.md`](APEX-IMPROVEMENTS.md) — preliminary, will be confirmed per IMP during analysis.

- **critic-cluster** — IMPs touching `framework/agents/critic.md` as the primary site.
- **destructive-guard-cluster** — IMPs touching `framework/hooks/destructive-guard.sh`.
- **executor-cluster** — IMPs touching `framework/agents/executor.md` and/or `framework/schemas/RESULT.schema.json`.
- **hooks-state-cluster** — IMPs touching state-management hooks (state-rebuild, _tokens-update, context-monitor) or `STATE.schema.json`.
- **agents-cluster** — IMPs touching agents other than executor/critic.
- **commands-cluster** — IMPs touching slash commands (`framework/commands/apex/`).
- **other** — IMPs that don't fit cleanly above; will be re-clustered during analysis.

## Processing order

1. critic-cluster (in progress: IMP-001 pilot)
2. destructive-guard-cluster
3. executor-cluster
4. hooks-state-cluster
5. agents-cluster, commands-cluster, other (by descending density)

Inside each cluster: P0 first, then P1, then P2/P3 as merited.
