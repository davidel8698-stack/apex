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

## Auto-Continuity Layer Files (v7.1)

Transient flag and checkpoint files used by the Auto-Continuity Layer
(memory-watchdog, turn-checkpoint, session-auto-resume, external watchdog).
All are **lazily created** — absent on projects that have never tripped the
relevant trigger. Consumers MUST tolerate absence.

| File | Created By | Lifetime | Purpose |
|------|------------|----------|---------|
| `.apex/AUTO_PAUSE_REQUEST.flag` | `memory-watchdog.sh` | One-shot — deleted by `/apex:next` Step F.4 after consuming | Signal that an auto-pause is requested. Plain-text body holds the reason (memory_pressure, etc.) |
| `.apex/SHUTDOWN_REQUEST.flag` | `apex-watchdog.ps1` (external) | One-shot — deleted by `/apex:next` Step F.4 after consuming | Signal from the external Windows watchdog asking the in-process orchestrator to do a graceful pause before forced kill |
| `.apex/SESSION_BOOT.md` | `session-auto-resume.sh` (SessionStart) | Read by `/apex:resume` on next invocation; cleared after | Banner+payload describing the previous session's auto-pause reason and recommended next action. Always replaces previous content (not append) |
| `.apex/TURN_CHECKPOINT.json` | `turn-checkpoint.sh` | Replaced every N tool calls during a long-running task; persists across sessions until next checkpoint | Fine-grained turn-level checkpoint enabling `/apex:recover` option 6 (continue-from-turn-checkpoint) |

**Schema:** `.apex/TURN_CHECKPOINT.json` mirrors the `turn_checkpoint` block in
`STATE.schema.json` (single-source). The other three files are plain-text /
markdown — no formal schema; only a minimum required line ("REASON: ...") for
the `.flag` files.

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

## Observation Masking Protocol

Spec anchor: "Context engineering at state-of-the-art. Observation masking." (F-024)

APEX implements observation masking through the zone-based context dispatch system
in `/apex:next` Step E (Build Executor Context):

| Zone | Content | Masking Behavior |
|------|---------|-----------------|
| Zone 1: Stable Prefix | System prompt, CLAUDE.md, repo map, stack skills | Cached — not re-read per task |
| Zone 2: Task Context | Task XML, spec sections, decisions, active files | JIT — replaced entirely per task |
| Zone 3: Working Memory | Impacted tests, reflexion brief | Volatile — previous task's outputs discarded |

**Key masking rules:**
- Previous task's tool outputs are NOT carried forward (Zone 3 replacement)
- When context exceeds budget, trim order: dep summaries → spec → skills → decisions
- **NEVER trim:** task_xml, acceptance_criteria, reflexion_brief

This ensures stale observations are automatically masked by zone replacement,
not by explicit summarization.
