---
description: Gather context and clarifications before planning a phase.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
Interactive discussion to gather context before phase planning.
Ensures the architect agent has sufficient information to create a good plan.

## ARGUMENTS
$ARGUMENTS may contain a phase number. If empty, use STATE.current_phase + 1 (next phase).

## PROCEDURE
1. Read .apex/STATE.json — determine target phase number.
   If all phases complete: "All phases complete. Nothing to discuss." STOP.

2. Read .apex/SPEC.md — identify the sections relevant to the target phase.
   Read .apex/COMPLEXITY.md — get complexity level and pipeline stages.
   Read .apex/DECISIONS.md — last 10 entries for accumulated context.

3. If .apex/phases/{phase}/ does not exist: mkdir -p .apex/phases/{phase}/

4. Present phase overview:
   "## Phase {phase} Discussion

   **Relevant SPEC sections**: [list sections]
   **Complexity level**: [level]
   **Prior decisions that affect this phase**: [list relevant ones]"

5. Ask clarifying questions based on SPEC analysis:
   - Identify ambiguities in the SPEC for this phase
   - Identify external dependencies or integration points
   - Identify potential edge cases
   - Ask about priorities and constraints

   Present as numbered questions. Wait for user response.

6. After user responds, capture answers:
   Write to .apex/phases/{phase}/CONTEXT.md:
   "# Phase {phase} Context
   Date: [now]

   ## SPEC Sections
   [relevant sections]

   ## Clarifications
   [Q&A from discussion]

   ## Constraints
   [any constraints identified]

   ## Dependencies
   [any dependencies identified]"

7. Confirm:
   "Context captured in .apex/phases/{phase}/CONTEXT.md
   Ready for: /apex:plan-phase {phase}"

8. Log event:
   bash ~/.claude/hooks/session-log.sh "phase_discuss" "Phase {phase} context gathered"
</context>