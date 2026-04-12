---
description: Guided forensics with step-by-step explanations and fix suggestions.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
A guided, interactive version of /apex:forensics. Walks the user through
what happened, explains each step in plain language, and offers fix suggestions.

## PROCEDURE
1. Read .apex/STATE.json — extract project state.
2. Read .apex/SESSION-LOG.md — last 30 lines.
3. Run: git log --oneline -15

4. Walk through events one by one:
   For each event (most recent first):
     "### Event: [timestamp] — [event_type]
     **What happened**: [plain language explanation]
     **Impact**: [what this affected]
     **Status**: [normal / warning / problem]"

     If event is a failure or warning:
       "**Suggested fix**: [specific action]
       Run: /apex:[relevant command]"

5. After walkthrough, provide overall assessment:
   "## Summary
   - Total events reviewed: [N]
   - Problems found: [N]
   - Warnings: [N]

   ## Recommended Actions (in order)
   1. [most critical action first]
   2. [next action]
   3. [optional cleanup]"

6. Log event:
   bash ~/.claude/hooks/session-log.sh "walkthrough" "Guided forensics completed — {problems} problems found"
</context>