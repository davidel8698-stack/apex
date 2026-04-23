# APEX Directory Contract

Centralized structural contract for `.apex/` project directories.
Spec anchor: "Structural contract over flexibility." (F-022)

## Required Directories

Created by `/apex:start` (mkdir -p):

| Directory | Purpose |
|-----------|---------|
| `.apex/` | Project root |
| `.apex/pre-build/` | Pre-build checklist artifacts |
| `.apex/phases/` | Phase execution data (subdirs per phase) |
| `.apex/backups/` | State backups (pre-compact, manual) |
| `.apex/debate-log/` | Architecture debate records |
| `.apex/comprehension-gates/` | Comprehension gate results |
| `.apex/todos/` | Todo tracking |
| `.apex/threads/` | Thread state |
| `.apex/seeds/` | Seed data |
| `.apex/backlog/` | Backlog items |

## Required Files

Created by `/apex:start` during initialization:

| File | Schema | Purpose |
|------|--------|---------|
| `.apex/STATE.json` | `STATE.schema.json` | Project state |
| `.apex/SPEC.md` | — | Specification document |
| `.apex/COMPLEXITY.md` | — | Complexity analysis |
| `.apex/CONTEXT_BUDGET.json` | `CONTEXT_BUDGET.schema.json` | Per-agent context limits |

## Phase-Created Files

Created during planning and execution (per phase directory):

| File | Schema | Created By |
|------|--------|------------|
| `.apex/phases/NN/PLAN.md` | — | architect |
| `.apex/phases/NN/PLAN_META.json` | `PLAN_META.schema.json` | architect |
| `.apex/phases/NN/WAVE_MAP.json` | — | architect |
| `.apex/phases/NN/TASK-RESULT.json` | `RESULT.schema.json` | executor |
| `.apex/phases/NN/TASK-SUMMARY.md` | — | executor |
| `.apex/phases/NN/TASK-CRITIC.md` | — | critic |
| `.apex/phases/NN/VERIFY.md` | — | verifier |

## Session-Level Files

| File | Purpose |
|------|---------|
| `.apex/DECISIONS.md` | Architecture decisions log |
| `.apex/SESSION-LOG.md` | Session event log |
| `.apex/TASK_MAP.md` | Task dependency map |
| `.apex/TEST_MAP.txt` | Test coverage map |

## Agent Prompt Structure — U-Shaped Attention Guidelines

Spec anchor: "U-shaped attention awareness." (F-008)

LLMs attend more strongly to the beginning and end of context (primacy-recency effect).
All agent `.md` files MUST follow this structure:

| Position | Content | Why |
|----------|---------|-----|
| Top 20% (lines 1-N) | Role identity, non-negotiables, domain invariants, critical constraints | Primacy — highest attention |
| Middle 60% | Task-specific logic, steps, context injection points | Lower attention — procedural content |
| Bottom 20% | Verdict rules, mandatory verify commands, output format, failure mode prohibitions | Recency — second-highest attention |

**Enforcement:** health-check TEST 0h validates this structure for all agent files.

## Validation Rules

1. All 9 subdirectories MUST exist after `/apex:start` completes.
2. `STATE.json` MUST validate against `STATE.schema.json`.
3. `PLAN_META.json` (when present) MUST validate against `PLAN_META.schema.json`.
4. `RESULT.json` files MUST validate against `RESULT.schema.json`.
5. Phase directories use zero-padded numbering: `01/`, `02/`, etc.
