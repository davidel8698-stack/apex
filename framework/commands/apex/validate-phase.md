---
description: Run cross-phase audit and verification on a completed phase.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
Validate a completed phase by running the cross-phase audit hook and invoking the verifier agent.

## ARGUMENTS
$ARGUMENTS must contain a phase number. If empty, use STATE.current_phase.

## PROCEDURE
1. Read .apex/STATE.json — determine phase to validate.

2. Verify phase has been executed:
   Check .apex/phases/{phase}/ for RESULT.json files.
   If no results found:
     "Phase {phase} has no execution results. Run /apex:execute-phase {phase} first."
     STOP.

3. Run cross-phase audit:
   bash ~/.claude/hooks/cross-phase-audit.sh {phase}
   Capture output and exit code.

   If exit code != 0:
     "## Cross-Phase Audit: ISSUES FOUND
     [audit output]"
   Else:
     "## Cross-Phase Audit: PASSED"

4. Invoke verifier agent:
   Task("verifier", "Verify phase {phase} completion.
   Read all RESULT.json and CRITIC.md files in .apex/phases/{phase}/.
   Check:
   - All tasks have RESULT.json with status: success
   - All CRITIC.md verdicts are PASS
   - verify_commands from PLAN_META.json all pass
   - No unresolved issues in DECISIONS.md for this phase
   Write findings to .apex/phases/{phase}/VERIFY.md")

5. Read .apex/phases/{phase}/VERIFY.md and display results.

6. Summary:
   "## Phase {phase} Validation
   Cross-phase audit: [PASSED/ISSUES]
   Verifier: [PASSED/ISSUES]

   [If all passed:]
   Phase {phase} validated. Ready for next phase: /apex:next
   [If issues found:]
   Issues must be resolved before proceeding. Review VERIFY.md for details."

7. Log event:
   bash ~/.claude/hooks/session-log.sh "phase_validate" "Phase {phase} validation: [result]"
</context>