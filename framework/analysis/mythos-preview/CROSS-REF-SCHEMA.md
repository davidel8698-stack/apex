# Cross-Reference Matrix Schema — Phase 2

The cross-reference matrix maps every Lesson extracted from Phase 1 against the APEX architecture. Its purpose is to identify gaps (`MISSING`/`PARTIAL`) which become candidates for `APEX-IMPROVEMENTS.md`.

## Matrix Columns

| Column | Type | Description |
|--------|------|-------------|
| `Lesson ID` | string | `L-XXX-NN` from a section file |
| `Section` | string | Document section, e.g. `§4.1.1` |
| `Description` | string | One-line summary of the lesson (≤120 chars) |
| `APEX Components` | comma-list | Specific files: `executor.md, destructive-guard.sh, RESULT.json` |
| `Coverage` | enum | `COVERED` / `PARTIAL` / `MISSING` / `NOT_APPLICABLE` |
| `Priority` | enum | `P0` / `P1` / `P2` / `P3` |
| `Notes` | string | Why this coverage rating; what's the gap if `PARTIAL` |

## Coverage Definitions

- **`COVERED`** — APEX already has a mechanism that addresses this lesson at parity or better. No action needed; record for completeness.
- **`PARTIAL`** — APEX has a related mechanism but it's weaker, narrower, or advisory-only where the lesson suggests it should be strict. Improvement candidate.
- **`MISSING`** — APEX has no mechanism for this. Either a clear improvement candidate, or `NOT_APPLICABLE` because it doesn't fit APEX's scope.
- **`NOT_APPLICABLE`** — The lesson is real for Anthropic but doesn't translate to APEX (e.g. RSP threshold determinations are a model-developer concern, not a coding-framework concern).

## Priority Definitions

- **`P0`** — Critical gap. Affects many sessions, high blast radius, no current mitigation.
- **`P1`** — Notable gap. Affects common scenarios or has high blast radius in narrow scenarios.
- **`P2`** — Refinement. APEX already addresses the area but the lesson suggests a tightening.
- **`P3`** — Nice-to-have. Worth recording but unlikely to be prioritized soon.

## Priority Calculation Heuristic

```
impact = severity_of_gap × likelihood_in_real_use
       × not_already_covered_by_adjacent_mechanism
```

- `severity_of_gap`: 1=cosmetic, 5=destructive/irreversible action enabled
- `likelihood_in_real_use`: 1=rare adversarial, 5=most agentic sessions
- `not_already_covered_by_adjacent_mechanism`: 0.5=heavily redundant, 1.5=unique gap

`impact ≥ 15` → P0
`impact ≥ 8` → P1
`impact ≥ 4` → P2
else → P3

## Matrix Output Location

`framework/analysis/mythos-preview/CROSS-REF.md` (written in Phase 2).

## Matrix Template

```markdown
# APEX Coverage Cross-Reference Matrix

Generated from Phase 1 lesson extraction. Source: Mythos Preview System Card (April 2026).

## Summary

- Total lessons: <N>
- COVERED: <N>
- PARTIAL: <N>
- MISSING: <N>
- NOT_APPLICABLE: <N>
- P0: <N> | P1: <N> | P2: <N> | P3: <N>

## Matrix

| Lesson ID | Section | Description | APEX Components | Coverage | Priority | Notes |
|-----------|---------|-------------|------------------|----------|----------|-------|
| L-411-01 | §4.1.1 | … | … | PARTIAL | P0 | … |
```
