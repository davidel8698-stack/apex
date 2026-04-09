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

2. Backup state:
   bash ~/.claude/hooks/pre-compact.sh

3. Show summary:
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