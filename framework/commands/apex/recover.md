---
description: Recover from crash or stuck state.
---

<context>
## TECHNICAL LEVEL ADAPTATION
Read technical level from CLAUDE.md ## User Profile section.
Adapt recovery options display:
- non-programmer: explain each option in plain language, recommend the safest choice (option 3 or 5), hide internal details like "reflexion counter"
- junior: explain options briefly, highlight recommended choice
- senior/architect: show options as-is (current behavior)

1. Check .apex/STATE.json.lock
2. No lock: "No crash. /apex:next to continue. Or /apex:resume for fresh session."
3. Lock exists, process dead:
   "Interrupted: $UNIT (attempt $ATTEMPT)
   (1) Retry from scratch (resets reflexion counter)
   (2) Retry with reflexion (keeps failure context)
   (3) Mark failed, skip to next unit
   (4) Mark manually complete
   (5) Revert to last phase tag and re-plan [שיפור 23]"
   Handle, update STATE, remove lock.
</context>