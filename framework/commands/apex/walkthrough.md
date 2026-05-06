---
description: Step-by-step explanation of what happened with fix suggestions (guided forensics / walkthrough).
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
A guided, interactive version of /apex:forensics (timeline reconstruction). Walks the user through
what happened, explains each step in plain language, and offers fix suggestions.

## FIX_PLAN.md AWARENESS [R5-014]
Before stepping through the timeline: if `.apex/FIX_PLAN.md` exists, READ it
first and surface its `## Reason`, `## Context`, and `## Recommended commands`
sections at the top of the walkthrough output. FIX_PLAN.md is written by
every blocking guard (path-, destructive-, workflow-, quarantine-, schema-drift-,
phantom-check-, post-write-, circuit-breaker-) via the shared
`framework/hooks/_fix-plan-emit.sh` helper, and it is the canonical
"what to do next" plan for the most recent block. The legacy
`.apex/RECOVERY_MENU.md` (W1 R5-005) is preserved as an alias filename —
when both files are present, prefer FIX_PLAN.md (newer format). The
walkthrough's per-event explanation and overall assessment below remain
unchanged; FIX_PLAN.md merely surfaces the structured fix at the start so
the user is one step from action.

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