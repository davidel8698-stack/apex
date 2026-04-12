---
description: UI-specific review pass. Not yet implemented.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

Not yet implemented.

For general verification, use:
- /apex:validate-phase — run audit + verification on a completed phase
- /apex:test — run verify commands for current phase
</context>