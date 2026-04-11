---
description: Run verify commands for the current or specified phase.
---

<context>
## PURPOSE
Execute verification commands defined in PLAN_META.json for the current or specified phase.

## ARGUMENTS
$ARGUMENTS may contain a phase number. If empty, use STATE.current_phase.

## PROCEDURE
1. Read .apex/STATE.json — get current_phase (or use $ARGUMENTS if provided).

2. Read .apex/phases/{phase}/PLAN_META.json — extract verify_commands array.
   If PLAN_META.json does not exist:
     "No PLAN_META.json found for phase {phase}. Run /apex:plan-phase {phase} first."
     STOP.

   If verify_commands is empty or missing:
     "No verify_commands defined in PLAN_META.json for phase {phase}."
     STOP.

3. Execute each verify command sequentially:
   For each cmd in verify_commands:
     Run: bash -c "$cmd" 2>&1
     Capture exit code and output.
     Record: { command: cmd, exit_code: N, output: "..." }

4. Display results:
   "## Test Results — Phase {phase}

   | # | Command | Result |
   |---|---------|--------|
   | 1 | [cmd] | PASS / FAIL (exit [N]) |
   | 2 | [cmd] | PASS / FAIL (exit [N]) |

   **Summary**: [passed]/[total] commands passed."

   If any failed, show the first 20 lines of output for each failure.

5. Log event:
   bash ~/.claude/hooks/session-log.sh "verify" "test: phase {phase} — {passed}/{total} passed"
</context>