# Roundtable Trigger Rules

**Owner:** architect.md (primary), planner.md (secondary)
**Schema field:** `roundtable_needed` on a task or phase object.
**Spec anchor:** "`/apex:roundtable` … לא מתאים ל-tasks רגילים — זה overhead."

`/apex:roundtable` is the multi-specialist deliberation protocol where every
participant presents a position and the architect decides. It is **overhead**
for routine work — running it on every task wastes context and time. It is
also **load-bearing** for irreversible, cross-cutting, or multi-stakeholder
work, where the cost of a wrong unilateral call exceeds the cost of the
deliberation.

The classifier below is deterministic. If any rule fires, set
`roundtable_needed = true` for the task. If no rule fires, leave the field
absent (defaults to `false` at runtime). The architect (or planner) records
the trigger reason in `DECISIONS.md` so the user can audit when and why
roundtable was auto-recruited.

---

## Trigger rules

A task qualifies for auto-recruited roundtable if **any** of the following
holds. Multiple may fire — record all of them.

### R1 — Multi-specialist surface
The task touches **>2 specialist domains** simultaneously.
Signals (from PLAN_META.json or task description):
- The task has more than two of: `frontend`, `data`, `security`,
  `integration`, `test-architect`, `memory-synthesis` listed as required
  specialists.
- The task description mentions ≥3 of: UI, API, schema, auth, deploy, infra,
  data migration, observability.
**Why:** Roundtable is the cross-talk surface; >2 specialists means at least
one will be surprised by another's choice unless surfaced upfront.

### R2 — Irreversible decision
The task is **irreversible** in the operational sense — wrong choice cannot
be cheaply rolled back.
Signals:
- `is_irreversible == true` in the task XML.
- Task description contains: data deletion, prod deploy, schema migration
  with destructive change, contract break, payment integration, third-party
  webhook commitment, public API release, package publish, SaaS billing
  setup.
**Why:** Reversibility is the cost-of-mistake floor. Below it, fast unilateral
calls are fine. Above it, the cost of a wrong call dominates the deliberation
cost.

### R3 — Schema / migration / contract
The task changes a **shared contract** that other parts of the system depend
on.
Signals:
- File path matches `**/migrations/**`, `**/schema/**`, `**/openapi/**`,
  `**/proto/**`, `**/contracts/**`.
- Task description contains: schema change, contract version bump,
  breaking API change, database migration, event-schema update,
  message-format change.
**Why:** Contract changes ripple. Roundtable surfaces the ripples before they
become incidents.

### R4 — Multi-stakeholder
The task affects **multiple human roles** with potentially conflicting
priorities.
Signals:
- Task description mentions ≥2 of: end-user, admin, support agent, data
  team, finance team, legal, compliance, ops, customer success.
- Task description contains: cross-team dependency, requires sign-off,
  coordinated rollout, feature flag handoff, dual-write window.
**Why:** Conflicts of priority surface as conflicts in design. Roundtable
makes them explicit before code is written.

### R5 — Architecture-level decision
The task encodes a **directional architectural commitment** (not a leaf
implementation).
Signals:
- Task description contains: choose, decide between, evaluate options,
  trade-off, ADR, architecture decision, foundational, default for the
  rest of the project.
- The task is the first task in a new phase tagged `FOUNDATION`.
**Why:** Architecture decisions cascade. The cost of revisiting them later
exceeds the cost of getting them right the first time, which is what
roundtable buys.

---

## Anti-rules (do NOT auto-recruit)

The following indicate a routine task; roundtable would be overhead.

- The task is a leaf implementation with `verify_level == "A"` or `"B"` and
  `is_irreversible == false`.
- The task is a typo / copy / cosmetic UI fix.
- The task is a single-file refactor with no contract change.
- The task is a test addition or test refactor.
- The task is a documentation update.

If a rule from §"Trigger rules" fires AND an anti-rule fires, the trigger
rule wins. Anti-rules are tie-breakers for genuinely ambiguous cases.

---

## Output contract

When `roundtable_needed = true`, the architect (or planner):
1. Sets the field in PLAN_META.json on the task object.
2. Records `## Roundtable trigger — <task-id>` in `DECISIONS.md` with the
   firing rule(s) and a one-sentence rationale.
3. The downstream `/apex:next` pipeline reads the field and routes to
   `/apex:_roundtable` before executing the task.

---

## Test
`framework/tests/test-roundtable-classifier.sh` runs a corpus of ≥10 task
descriptions through a deterministic implementation of the rules above and
asserts the classifier matches the expected verdict for every entry.
