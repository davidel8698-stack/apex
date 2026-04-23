---
description: Current project status with token tracking and context health.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## VISUAL IDENTITY
Read ~/.claude/apex-branding.md before producing output.
Render Section 6 (The Cockpit Dashboard) verbatim — substitute placeholders with live values from STATE.json.
Preserve all frame alignment. Do NOT add emojis inside the MEGA frame.
Append signature line (Section 3.E) at the bottom.

### APEXSkin Resolution
Before rendering, resolve APEXSkin variables (Section 17 of apex-branding.md).
Resolution order: PROJECT-APEX.md `## APEXSkin Overrides` → APEX.md defaults → built-in defaults.
Apply resolved values to all template placeholders ({{project_name}}, {{theme_color}},
{{sigil_variant}}, {{frame_style}}, {{version_tag}}, {{signature_line}}).
Variable substitution MUST complete before rendering — never substitute mid-frame.

## GLASS COCKPIT — AMBIENT HEADER (prepend BEFORE the Cockpit Dashboard)
1. Section 10-D (Ambient Timeline) — decision-filtered query (overrides Section 10-D parse rule):
   DECISION_TYPES = pending_approval | auto_pause | time_gate | coherence_fail | veto | blocked | phantom_fail
   Primary: jq on .apex/event-log.jsonl filtering for DECISION_TYPES → keep last 5
   Fallback: grep SESSION-LOG.md for decision event emojis (🛑|💥|👻) → keep last 5
   If fewer than 3 decision items → pad with recent events until 3 total. Cap at 5.
2. Section 10-E (Live Ticker)      — literal tail -5 from SESSION-LOG.md
This lets the user scan decision-required items before diving into the full telemetry.

## TECHNICAL LEVEL ADAPTATION
Read technical level from CLAUDE.md ## User Profile section.
Adapt dashboard commentary:
- non-programmer: after each metric section, add a plain-language sentence explaining what it means and whether it's good or bad
- junior: add brief tooltips for non-obvious metrics (EvoScore, DORA, mutation kill rate)
- senior/architect: display raw metrics only (current behavior)

## DATA GATHERING
Read .apex/STATE.json

Extract and substitute into Section 6 template:
  [PROJECT_NAME]         → STATE.project
  [project_name]         → STATE.project
  [N] · [preset_name]    → STATE.complexity_level · STATE.complexity_name (preset name, e.g. "Trying it out")
  [stage] → [status]     → STATE.current_stage → STATE.status
  [N] / [total] WAVE [W] → STATE.current_phase / STATE.total_phases · STATE.current_wave

  ELAPSED TIME:
    Compute elapsed = now - STATE.created_at
    Format as "[N]d [N]h" (e.g., "3d 14h")
    If created_at missing or null: show "N/A"

  TASK PROGRESS:
    nodal bar: build with ●/◐/○ based on completed/active/pending
    percentage: (tasks_done / total_tasks) * 100
    20-char progress bar: solid █ for done, ░ for remaining

  AUTONOMY LADDER:
    A/B/C/D rows with L0-L2 bars (4-char wide)
    consecutive_successes from STATE.autonomy.by_verify_level

  CONTEXT HEALTH:
    20-char bar from STATE.context.estimated_context_usage_pct
    Status: healthy (<60%) / warn (60-75%) / critical (>75%)
    Rotations from STATE.context.rotation_history.length
    Session phase from STATE.context.current_session_phase

  TOKEN ECONOMY:
    Productive/Overhead dual bar (each 20 chars)
    Total from STATE.tokens.total_input + total_output
    Cost estimated from model_routing breakdown

  QUALITY METRICS:
    EvoScore regression from STATE.evoscore.regression_rate
    Comprehension gates N/total
    Mutation kill rate from STATE.mutation_scores (show "N/A" if no scores exist)
    Living Evidence Counter: parse ~/.claude/apex-learnings.md by tier section (## HOT, ## WARM, ## COLD).
      For each tier, count entries and sum their `**Evidence count: N**` values.
      Display: "Living Evidence: [total_confirmations] confirmations across [total_learnings] learnings ([H] hot, [W] warm, [C] cold)"
      Show "Living Evidence: 0 confirmations across 0 learnings (0 hot, 0 warm, 0 cold)" if file missing or no entries.

  DORA METRICS:
    Lead Time: STATE.dora.lead_time_avg hours (avg phase completion time) or "N/A" if null
    Deploy Freq: STATE.dora.deployment_freq phases/day or "N/A" if null
    Change Fail Rate: STATE.dora.change_failure_rate as percentage or "N/A" if null
    Recovery Time: STATE.dora.recovery_time_avg hours or "N/A" if null
    Last Updated: STATE.dora.last_updated or "never"

  SESSION HEALTH:
    Completed/Failed/Partial from STATE.session
    Consecutive failures, rotations
    Last checkpoint tag + time ago

  AUTOPILOT:
    State: ENABLED/DISABLED/PAUSED from STATE.autopilot.enabled and paused_reason
    Mode from STATE.autopilot.mode
    Tasks/phases in autopilot
    Consecutive sessions from STATE.autopilot.consecutive_sessions
    Previous last completed task from STATE.autopilot.previous_last_completed_task
    Previous tasks completed in autopilot from STATE.autopilot.previous_tasks_completed_in_autopilot
    Advisor risk score from STATE.autopilot.advisor_risk_score

  LEARNINGS:
    HOT bar from hot_count/30
    WARM bar from warm_count/100
    COLD count

## RENDER
Output the Cockpit Dashboard from Section 6 of apex-branding.md with all values substituted.
Follow with the signature line.

## INLINE HINT (below signature)
If autopilot is disabled: add rounded frame (Section 3.C) with:
  "Say 'enable autopilot' to run the Advisor (Section 10)."
If autopilot is enabled: add active badge from Section 9.
If autopilot is paused: add paused badge from Section 9.
</context>
