---
description: Create PLAN.md for a specified phase using the architect agent.
---

<context>
## PURPOSE
Generate a detailed execution plan for a specific phase by invoking the architect agent.

## ARGUMENTS
$ARGUMENTS must contain a phase number. If empty:
  "Usage: /apex:plan-phase {phase_number}
   Example: /apex:plan-phase 2"
  STOP.

## PROCEDURE
1. Read .apex/STATE.json — verify project exists and phase is valid.
   If STATE does not exist: "No APEX project. Run /apex:start first." STOP.

2. Read context files:
   - .apex/SPEC.md
   - .apex/COMPLEXITY.md
   - .apex/DECISIONS.md
   - .apex/phases/{phase}/CONTEXT.md (if exists, from /apex:discuss-phase)
   - Previous phase results: .apex/phases/{phase-1}/VERIFY.md (if exists)

3. Invoke architect agent:
   Task("architect", "Create PLAN.md for phase {phase}.

   Project: [STATE.project]
   Complexity: [COMPLEXITY.level]
   SPEC sections for this phase: [relevant sections]
   Phase context: [from CONTEXT.md if exists]
   Previous phase outcomes: [from VERIFY.md if exists]

   Output:
   - .apex/phases/{phase}/PLAN.md — task breakdown with wave assignments
   - .apex/phases/{phase}/PLAN_META.json — metadata including verify_commands
   - .apex/phases/{phase}/WAVE_MAP.json — wave dependency map

   Follow SPEC exactly. Do not invent requirements beyond SPEC.")

4. Validate outputs exist:
   - .apex/phases/{phase}/PLAN.md must exist
   - .apex/phases/{phase}/PLAN_META.json must exist
   If missing: "Architect failed to produce required outputs. Review and retry."

5. Display plan summary:
   "## Phase {phase} Plan Created
   Tasks: [count from PLAN_META]
   Waves: [count from WAVE_MAP]
   Verify commands: [count]

   Review: cat .apex/phases/{phase}/PLAN.md
   Execute: /apex:execute-phase {phase}"

6. Log event:
   bash ~/.claude/hooks/session-log.sh "phase_plan" "Phase {phase} plan created — [task_count] tasks in [wave_count] waves"
</context>