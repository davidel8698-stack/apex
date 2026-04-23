---
description: Add a deferred task or known limitation to the project backlog.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## GUARD
If no .apex/STATE.json: "❌ No APEX project. Run /apex:start first." STOP.
If $ARGUMENTS is empty:
  "❌ /apex:add-backlog requires a task description.
   Usage: /apex:add-backlog 'Optimize database queries for user search — not blocking launch'
   Backlog items are deferred work, not current-phase tasks."
  STOP.

## WRITE
TIMESTAMP = $(date +%Y%m%d-%H%M%S)
BACKLOG_FILE = .apex/backlog/item-${TIMESTAMP}.md

Ensure directory exists: `mkdir -p .apex/backlog/`

Create file:
```
# Backlog Item: [timestamp]

${$ARGUMENTS}

---
Status: pending
Priority: unranked
Source: manual (/apex:add-backlog)
```

"📋 Backlog item added: ${BACKLOG_FILE}
   Review backlog with /apex:review-backlog."
</context>
