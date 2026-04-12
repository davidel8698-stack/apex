---
description: Mark pre-build checklist items as complete.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

If "done [N]":
  Mark item N ✅ in CHECKLIST.md
  COMPLETED=$(grep -c "✅" .apex/pre-build/CHECKLIST.md)
  TOTAL=$(grep -c "[✅⬜]" .apex/pre-build/CHECKLIST.md)
  If COMPLETED == TOTAL:
    STATUS.json: {"blocking": false} | STATE.json: {"pre_build_complete": true}
    "✅ ALL DONE! /apex:next to proceed."
  Else: "✅ Item [N] done. [$((TOTAL-COMPLETED))] remaining."

If "status" or empty: show checklist with ✅/⬜ counts
</context>