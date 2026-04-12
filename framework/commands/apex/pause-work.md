---
description: Redirect to /apex:pause. Alias for pause command.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

Redirecting to /apex:pause...

This command is an alias. Invoking /apex:pause behavior now.

Read and execute the full /apex:pause procedure:
1. Read .apex/STATE.json
2. Save current state (status: "paused")
3. Log pause event
4. Backup state
5. Run dream-cycle memory consolidation if memory primitives exist
6. Show pause summary

All logic is defined in /apex:pause. Follow that command's specification exactly.
</context>