---
description: UI-specific phase execution. Not yet implemented.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

Not yet implemented.

For phase execution, use:
- /apex:execute-phase — execute all tasks in a phase
- /apex:plan-phase — create a plan for a phase
</context>