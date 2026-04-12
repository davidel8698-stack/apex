---
description: Extract and display session metrics from STATE.json.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
Generate a formatted report of the current session's metrics from STATE.json.

## PROCEDURE
1. Read .apex/STATE.json — extract session object.
   If STATE does not exist: "No APEX project found." STOP.
   If STATE.session does not exist: "No session data available." STOP.

2. Extract metrics:
   - Session start time: STATE.session.started_at
   - Tasks completed this session: count from session log
   - Token usage: STATE.tokens (input, output, total)
   - Context usage: STATE.context.estimated_context_usage_pct
   - Rotations: STATE.context.rotation_history.length
   - Auto-pauses: count from session log
   - Errors encountered: count from session log

3. Read .apex/SESSION-LOG.md — count events by type for this session.

4. Display report:
   "## Session Report

   **Started**: [timestamp]
   **Duration**: [calculated from start to now]

   ### Progress
   - Tasks completed: [N]
   - Current position: Phase [P] / Wave [W] / Task [T]

   ### Token Economy
   - Input tokens: [N]
   - Output tokens: [N]
   - Total: [N]

   ### Context Health
   - Usage: [N]%
   - Rotations this session: [N]
   - Current phase: [session_phase]

   ### Events
   - Checkpoints: [N]
   - Warnings: [N]
   - Errors: [N]
   - Auto-pauses: [N]"
</context>