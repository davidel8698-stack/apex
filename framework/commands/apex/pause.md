---
description: Save current state and pause work.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## VISUAL IDENTITY
Read ~/.claude/apex-branding.md before producing output.

### APEXSkin Resolution
Before rendering, resolve APEXSkin variables (Section 17 of apex-branding.md).
Resolution order: PROJECT-APEX.md `## APEXSkin Overrides` → APEX.md defaults → built-in defaults.
Apply resolved values to all template placeholders ({{project_name}}, {{theme_color}},
{{sigil_variant}}, {{frame_style}}, {{version_tag}}, {{signature_line}}).
Variable substitution MUST complete before rendering — never substitute mid-frame.

Read .apex/STATE.json

1. Save current state:
   Update STATE.json:
   - status: "paused"
   - context.last_pause: now
   - context.estimated_context_usage_pct: current estimate
   - session.auto_paused: true (so SessionStart auto-resume hook fires next session)
   - session.auto_pause_reason: keep existing if set by /apex:next Step F.4
       (memory_pressure / external_watchdog / health_red); else "manual"

   ## TURN-CHECKPOINT MERGE [v7.1 Auto-Continuity]
   If `.apex/TURN_CHECKPOINT.json` exists:
     Read it. The `task_id`, `tool_call_index`, and `last_completed_tool`
     are already mirrored in STATE.turn_checkpoint by turn-checkpoint.sh.
     If the orchestrator has a fresher view of working_summary
     (e.g. just-finished analysis text), update STATE.turn_checkpoint.working_summary
     before snapshot. Otherwise leave the existing value.
     Do NOT delete TURN_CHECKPOINT.json — /apex:resume on next session may
     consume it for option 6 (continue-from-turn-checkpoint).

2. Log pause event:
   bash ~/.claude/hooks/session-log.sh "auto_pause" "עבודה מושהית — [stage]/[phase]/[unit] (reason: [auto_pause_reason or manual])"

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