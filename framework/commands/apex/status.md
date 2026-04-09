---
description: Current project status with token tracking and context health.
---

<context>
## VISUAL IDENTITY
Read ~/.claude/apex-branding.md before producing output.
Render Section 6 (The Cockpit Dashboard) verbatim — substitute placeholders with live values from STATE.json.
Preserve all frame alignment. Do NOT add emojis inside the MEGA frame.
Append signature line (Section 3.E) at the bottom.

## GLASS COCKPIT — AMBIENT HEADER (prepend BEFORE the Cockpit Dashboard)
1. Section 10-D (Ambient Timeline) — last 8 events from SESSION-LOG.md
2. Section 10-E (Live Ticker)      — literal tail -5 from SESSION-LOG.md
This lets the user scan recent activity before diving into the full telemetry.

## DATA GATHERING
Read .apex/STATE.json

Extract and substitute into Section 6 template:
  [PROJECT_NAME]         → STATE.project_name
  [project_name]         → STATE.project_name
  [N] · [level_name]     → STATE.complexity_level · STATE.level_name
  [stage] → [status]     → STATE.current_stage → STATE.status
  [N] / [total] WAVE [W] → STATE.current_phase / STATE.total_phases · STATE.current_wave

  TASK PROGRESS:
    nodal bar: build with ●/◐/○ based on completed/active/pending
    percentage: (tasks_done / total_tasks) * 100
    20-char progress bar: solid █ for done, ░ for remaining

  AUTONOMY LADDER:
    A/B/C/D rows with L0-L2 bars (4-char wide)
    consecutive wins from STATE.autonomy.by_verify_level

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
    Mutation kill rate (if available)

  SESSION HEALTH:
    Completed/Failed/Partial from STATE.session
    Consecutive failures, rotations
    Last checkpoint tag + time ago

  AUTOPILOT:
    State: ENABLED/DISABLED/PAUSED from STATE.autopilot.enabled and paused_reason
    Mode from STATE.autopilot.mode
    Tasks/phases in autopilot
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
