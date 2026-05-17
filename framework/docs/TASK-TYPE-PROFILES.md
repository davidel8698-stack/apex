# Task-Type Context Profiles (M12, Phase 12.03)

**Purpose.** Different task types have different optimal context
profiles. A bug fix needs the failing test and the stack trace — not the
full architecture docs. A new-code task needs the architecture and
interface contracts — not the test fixtures. Loading the wrong profile
wastes 5-15K tokens per task and degrades executor quality (R2-C130:
SWE-Pruner showed 23-38% context reduction *improved* absolute task
success, not just per-token efficiency).

**Spec anchors.**
- `apex-spec.md` §"היכולות הנדרשות" — context-aware execution.
- `.apex/phases/12-apex-evolution-v8/PLAN.md` task 12.03 §§1-10.
- R2-C127..C137 (task-type-specific context research).
- R2 §9 missing piece #5 (task-adaptive context). M12 closes it.

## The six profiles

The full bundle lives in `framework/CONTEXT_BUDGET.default.json` under
the top-level `profiles` key. Each profile names content slices to
include / exclude and modules to preload. The schema for one profile is
defined at `framework/schemas/CONTEXT_BUDGET.schema.json` →
`#/definitions/profile`.

### `default`
Baseline shared by every task. Architect / executor always loads
`task_xml`, `acceptance_criteria`, `spec_excerpts`, `files_modified`.
A task whose `task_type` is missing from PLAN_META falls back to this
profile (no extra include / exclude).

### `new_code` — greenfield implementation
Loads: `architecture_docs`, `interface_contracts`, `style_guide`,
`code_examples`.
Excludes: `full_implementation_history` (the *evolution* of a file is
rarely load-bearing for a fresh write; the *current* contract is).

Why: starting from scratch needs the system's shape and conventions,
not the diff archive.

### `bug_fix` — localized correction
Loads: `failing_tests`, `stack_traces`, `execution_path`,
`minimal_dependencies`.
Excludes: `broad_architecture_docs`, `unrelated_modules`.

Why: the bug is the signal. Anything not on the execution path is
distraction. Loading the architecture doc bloats prompt and dilutes
attention.

### `code_review` — adversarial second pass
Loads: `spec_excerpts`, `diff`, `test_results`, `surrounding_functions`.
Excludes: `implementer_reasoning`, `executor_summary_md`.

Why: the clean-room contract for critic is enforced architecturally —
critic never sees executor reasoning — so this profile *reinforces*
that boundary rather than relaxing it. Useful when a non-critic agent
needs to review (e.g., a roundtable consultation).

### `refactor` — shape-preserving change
Loads: `dependency_graph`, `impact_set`, `current_tests`.
Excludes: `unrelated_files`, `broad_architecture_docs`.

Why: the refactor's correctness rests on the dependency graph being
intact post-change. Tests are the regression net. Everything else is
out of scope.

### `test_writing` — test authoring
Loads: `impl_contracts`, `test_conventions`, `existing_tests`,
`coverage_report`.
Excludes: `broad_architecture_docs`.
Preloads: `test-architect` module agent.

Why: a test-writing task is shape-driven (existing test conventions,
contract surface). The test-architect module emits the TEST_PLAN that
seeds the work; pre-loading it avoids a round-trip.

### `frontend` — UI work
Loads: `design_context`, `component_hierarchy`, `style_guide`,
`design_tokens`.
Excludes: `backend_modules`, `database_schema`, `infra_config`.
Preloads: `apex-frontend` module agent.

Why: frontend tasks are visual / interaction / accessibility shaped.
Backend schemas are pure noise. The apex-frontend module owns the
`shadcn-gate` and design-system enforcement; preload puts it in
scope from the first executor turn.

## How architect assigns `task_type`

`framework/agents/architect.md` Step 1.11 runs the classifier on
each task's `name + spec_ref joined + files joined` against the
task-type vocabulary section of
`framework/docs/RISK-KEYWORDS.md`. The decision rule:

1. `bug_fix` keyword match wins over everything (R2 task-distribution
   evidence: bug fixes are the high-volume task type).
2. `code_review` wins next.
3. `refactor` wins next.
4. `test_writing` wins next.
5. `frontend` wins next.
6. `new_code` is the conservative default.

The architect writes the chosen `task_type` into each task object in
PLAN_META.json. The `PLAN_META.schema.json` declares the enum.

## Hybrid bug-in-new-feature

The most common ambiguity. Architect rule: **bug_fix wins**. Smaller
context, less waste. Document the choice in the task description so
downstream tools (critic, auditor) know the intent was "fix the
broken behavior inside the partially-implemented feature."

## Per-profile cache invalidation

Anthropic prompt caching is keyed on the exact stable_prefix bytes
the agent receives. Different profiles produce different prefixes →
different cache keys. A session that switches between three profiles
within the 5-minute TTL pays the prefix-write cost three times
(once per profile).

The trade-off is acceptable. R2-C130 (SWE-Pruner) measured 23-38%
context reduction with *improved* absolute success rate — better
context fit overcomes the cache-write penalty. M04's model diversity
(critic / verifier / auditor on opus) already creates per-model
cache stratification; profile stratification stacks on top.

See `framework/docs/PROMPT-CACHING.md` for the full cache-key
contract.

## When a profile is the wrong choice

The architect's classifier is conservative — when in doubt it picks
`new_code` (the broadest include set). If you find a task running
with the wrong profile:

1. **Edit `PLAN_META.task_type`** for that task directly. The schema
   accepts any of the six enum values.
2. **Add a comment to the task description** explaining the override
   so the auditor's second-opinion pass doesn't flip it back.
3. **If the misclassification is systematic** (same keyword tripping
   across many tasks), file a change to
   `framework/docs/RISK-KEYWORDS.md` — keyword list edits are
   themselves a Track C change per RISK-KEYWORDS.md's own update
   policy.

## What this file is NOT

- Not a runtime profile loader — that lives in `next.md` Step G
  (consumes `profiles[task_type]` when present).
- Not a substitute for the `CONTEXT_BUDGET` zone allocation. Profiles
  override zone *contents*, not zone *budgets*. The 4 zones
  (stable_prefix / task_context / working_memory / generation_reserve)
  are untouched by M12.
- Not enforced when PLAN_META lacks `task_type` (optional during the
  v8 transition). Migration script defaults the field to `new_code`.

## Forward work (out of M12 scope)

- Per-profile telemetry: emit which profile was chosen + token cost
  to `.apex/telemetry.jsonl` (M16, task 12.09 reads this surface).
- Workflow-recipe alignment: `apex-workflows/add-authentication.md`
  and similar high-risk recipes may want explicit `task_type`
  overrides in their PLAN templates. Audit when M19 (task 12.13)
  lands.
- Dynamic profile selection: today architect picks once at PLAN.md
  time. A long-running task may shift profile mid-execution (e.g.,
  refactor reveals a bug → bug_fix profile). Out-of-scope for v0.
