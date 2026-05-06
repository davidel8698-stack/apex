---
description: Execute all tasks in a specified phase in wave order.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
Execute all tasks in a phase by invoking /apex:next for each task, respecting wave ordering.

## ARGUMENTS
$ARGUMENTS must contain a phase number. If empty:
  "Usage: /apex:execute-phase {phase_number}
   Example: /apex:execute-phase 2"
  STOP.

## PROCEDURE
1. Read .apex/STATE.json — verify project exists.
   If STATE does not exist: "No APEX project. Run /apex:start first." STOP.

2. Read .apex/phases/{phase}/PLAN_META.json — extract task list and wave assignments.
   Read .apex/phases/{phase}/WAVE_MAP.json — extract wave dependency order.
   If either missing:
     "No plan found for phase {phase}. Run /apex:plan-phase {phase} first."
     STOP.

3. Update STATE.json:
   - current_phase: {phase}
   - current_stage: "execution"
   - status: "active"

4. Execute tasks in wave order:
   For each wave W in WAVE_MAP (ascending order):
     For each task T in wave W:
       Display: "### Wave {W} — Task: {T.id} ({T.title})"

       Update STATE.json:
         - current_unit: T.id
         - current_wave: W

       ## OWNER-GUARD DISPATCH [R5-013]
       Export APEX_CURRENT_TASK_ID="{T.id}" before invoking /apex:next.
       This is the structural opt-in for the owner-guard PreToolUse
       Write|Edit hook (`framework/hooks/owner-guard.sh`): when the
       env var is set, the guard reads
       .apex/phases/{phase}/WAVE_MAP.json and refuses any Write/Edit
       whose target is not in the active task's `owns_files` list.
       When unset, the guard fast-paths exit 0 — manual edits are
       never gated. Spec anchors: "One-file-one-owner עם git worktree
       isolation" + "Read-parallel, write-serial עם Vertical Slices
       Enforcement."
       export APEX_CURRENT_TASK_ID="{T.id}"

       Invoke /apex:next
       (This triggers the full executor -> critic -> verifier pipeline for the task)

       ## OWNER-GUARD CLEANUP [R5-013]
       After /apex:next returns (any verdict), unset APEX_CURRENT_TASK_ID
       so the next iteration starts clean and ad-hoc writes between
       tasks are not gated against the previous task's ownership.
       unset APEX_CURRENT_TASK_ID

       Check result:
       - If task passed: continue to next task
       - If task failed after max retries: 
         "Task {T.id} failed after maximum attempts.
          Options:
          (1) Skip and continue with remaining tasks
          (2) Stop execution — fix manually then /apex:execute-phase {phase}
          (3) /apex:recover to enter recovery mode"
         Wait for user choice.

5. After all tasks complete:
   Display:
   "## Phase {phase} Execution Complete
   Tasks: [completed]/[total]
   Failed: [count] (if any)

   Next: /apex:validate-phase {phase}"

6. Log event:
   bash ~/.claude/hooks/session-log.sh "phase_execute" "Phase {phase} execution complete — {completed}/{total} tasks"
</context>