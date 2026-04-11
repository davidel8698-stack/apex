---
description: Save current state and pause work.
---

<context>
Read .apex/STATE.json

1. Save current state:
   Update STATE.json:
   - status: "paused"
   - context.last_pause: now
   - context.estimated_context_usage_pct: current estimate

2. Log pause event:
   bash ~/.claude/hooks/session-log.sh "auto_pause" "עבודה מושהית — [stage]/[phase]/[unit]"

3. Backup state:
   bash ~/.claude/hooks/pre-compact.sh

3b. Dream-cycle — memory consolidation:
   If .apex/todos/ OR .apex/threads/ OR .apex/seeds/ OR .apex/backlog/ exist:
     Spawn memory-synthesis agent (dream-cycle mode):
     - Consolidate stale todos → backlog
     - Summarize long threads
     - Promote mature seeds → todos
     - Write consolidation report to .apex/memory-synthesis-log.md
   Else: skip (memory primitives not initialized).

4. Show summary:
   "⏸️ APEX Paused
   📍 Stage: [stage] → Phase [phase] → Unit [unit]
   ✅ Units: [done] / [total]
   💰 Tokens this session: [total]

   State saved to .apex/STATE.json
   Backup: .apex/backups/

   To continue:
   - Same session: /apex:next
   - New session: /apex:resume"
</context>