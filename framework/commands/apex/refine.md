---
description: Refinement pass on completed work. Not yet implemented.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

Not yet implemented. Use /apex:next to continue the build pipeline.

For iterative improvement, consider:
- /apex:next — advance to next logical step
- /apex:validate-phase — verify completed work
- /apex:test — run verification commands
</context>