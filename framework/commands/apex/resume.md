---
description: Resume project in fresh session after context rotation or crash.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## VISUAL IDENTITY
Read ~/.claude/apex-branding.md before producing output.
Render Section 8.C (Context Rotation) as the opening transition.
Render Section 13 status bar below the transition.
If autopilot is enabled, render Section 9 active badge after the status bar.

### APEXSkin Resolution
Before rendering, resolve APEXSkin variables (Section 17 of apex-branding.md).
Resolution order: PROJECT-APEX.md `## APEXSkin Overrides` → APEX.md defaults → built-in defaults.
Apply resolved values to all template placeholders ({{project_name}}, {{theme_color}},
{{sigil_variant}}, {{frame_style}}, {{version_tag}}, {{signature_line}}).
Variable substitution MUST complete before rendering — never substitute mid-frame.

## GLASS COCKPIT — AMBIENT HEADER
After the status bar/badge, render:
  1. Section 10-D (Ambient Timeline) — decision-filtered query (see apex-branding.md Section 10-D parse rule: DECISION_TYPES filter on event-log.jsonl, cap at 5, pad to 3)
  2. Section 10-E (Live Ticker)      — literal tail -5 from SESSION-LOG.md
This gives the user instant continuity — "here's what happened before the rotation".

Every output ends with the signature line.

1. Read .apex/STATE.json
2. Read .apex/COMPLEXITY.md (level + pipeline)
3. Read .apex/SPEC.md summary (first 3 sections only)
4. Read latest DECISIONS.md entries (last 10)

## MEMORY RELOAD
If .apex/todos/ OR .apex/threads/ OR .apex/seeds/ OR .apex/backlog/ exist:
  5. Read .apex/todos/ — list pending action items (filename + first line)
  6. Read .apex/threads/ — list active threads (exclude .archived files)
  7. Read .apex/seeds/ — list seeds (filename + first line)
  8. Read .apex/backlog/ — count deferred items
  9. Display memory summary in resume output (inside soft frame):
     "📋 Memory: [N] todos · [M] threads · [K] seeds · [J] backlog"
  10. If .apex/memory-synthesis-log.md exists, show last dream-cycle timestamp.

## AUTO-PAUSE RECOVERY
If STATE.session exists AND STATE.session.auto_paused == true:
  Display in user's configured language (from CLAUDE.md User Profile):
  "⚠️ הסשן הקודם הושהה אוטומטית.
  סיבה: [STATE.session.auto_pause_reason]
  נקודת שחזור אחרונה: [STATE.session.last_checkpoint_tag or 'אין']
  משימות שהושלמו לפני ההשהיה: [STATE.session.tasks_completed]"

  Update STATE.session:
    auto_paused = false
    auto_pause_reason = null
    consecutive_failures = 0
    consecutive_partials = 0
    health_status = "green"
    drift_indicators = {
      spec_drift_count: 0,
      circuit_breaker_triggers: 0,
      reflexion_total_attempts: 0,
      low_confidence_results: 0
    }

## SESSION UPDATE
If STATE.session exists:
  Update STATE.session: total_context_rotations++, tasks_since_last_rotation = STATE.session.tasks_completed
  bash ~/.claude/hooks/session-log.sh "resume" "סשן חודש — הקשר נקי"

Update STATE.context:
  current_session_phase = STATE.current_phase
  session_start_time = now
  estimated_context_usage_pct = 5
  append to rotation_history: {phase, session_ended: now, reason: "manual_resume"}

## DISPLAY (render from ~/.claude/apex-branding.md)
1. Render Section 8.C — Context Rotation transition
2. Render Section 13 status bar with current values:
   `▲ APEX v7  │  [PROJECT]  │  Phase [N]/[M]  │  Wave [W]  │  [STATUS]`
3. If STATE.autopilot.enabled: render Section 9 active badge below status bar
4. Append a soft frame (Section 3.C, 68 chars wide) with:
   - Level [N] · [NAME]
   - Stage [stage] → Phase [current_phase] → Wave [current_wave]
   - Units [done] / [total]
   - Autonomy Level [N]
   - EvoScore [regression_rate]%
   - Tokens [total]
   - Session [completed] done · [failed] failed
5. Append signature line from Section 3.E

## SELF-HEAL RESUME CHECK
If STATE.self_heal exists AND STATE.self_heal.status == "running":
  Display in user's configured language:
  "🔁 Resuming /apex:self-heal at R[STATE.self_heal.current_round], step [STATE.self_heal.current_step]"
  If STATE.self_heal.current_step == "execute" AND STATE.self_heal.current_wave != null:
    Display: "  Wave [STATE.self_heal.current_wave]"
  Source and follow ~/.claude/commands/apex/self-heal.md with the
  internal flag --resume.
  STOP. (Do not fall through to autopilot or /apex:next.)

If STATE.self_heal exists AND STATE.self_heal.status in ["closed", "halted"]:
  Display brief: "Last self-heal loop ended with status [STATE.self_heal.status]
  at R[STATE.self_heal.current_round]. Type /apex:self-heal to start a new round."
  (Do not auto-resume; fall through to autopilot/next checks.)

## AUTOPILOT CHECK
If STATE.autopilot.enabled == true:
  STATE.autopilot.consecutive_sessions++

  ## CIRCUIT BREAKERS (check BEFORE auto-continuing)
  PAUSE_AUTOPILOT = false

  # Breaker 1: Session loop — same task across multiple resumes
  If STATE.autopilot.last_completed_task != null
     AND STATE.autopilot.last_completed_task == STATE.autopilot.previous_last_completed_task
     AND STATE.autopilot.consecutive_sessions >= 2:
    PAUSE_AUTOPILOT = true
    REASON = "Stuck: same task across 2+ sessions — possible infinite loop"

  # Breaker 2: Phase stall — no progress across 3 sessions
  If STATE.autopilot.consecutive_sessions >= 3
     AND STATE.autopilot.tasks_completed_in_autopilot == STATE.autopilot.previous_tasks_completed_in_autopilot:
    PAUSE_AUTOPILOT = true
    REASON = "No progress across 3 consecutive sessions"

  # Breaker 3: Human checkpoint — every 3 phases in autopilot
  If STATE.autopilot.phases_completed_in_autopilot > 0
     AND STATE.autopilot.phases_completed_in_autopilot % 3 == 0:
    PAUSE_AUTOPILOT = true
    REASON = "Mandatory human checkpoint after 3 autopilot phases"

  # Null guard: skip mode-specific breakers if autopilot not configured through advisor
  If STATE.autopilot.mode == null: skip mode-specific breakers (autopilot not configured through advisor)

  # Breaker 4: Mode-specific conditions (4 sub-conditions: until, range, after, smart)
  # Total pause conditions: Breakers 1-3 (fixed) + null guard + Breaker 4a-4d (mode-specific) = 7 checks
  If STATE.autopilot.mode == "until" AND next_task == STATE.autopilot.stop_at_task:
    PAUSE_AUTOPILOT = true
    REASON = STATE.autopilot.stop_at_task + " — " + (STATE.autopilot.paused_reason or "reached stop point")

  If STATE.autopilot.mode == "range" AND next_task > STATE.autopilot.range_end:
    PAUSE_AUTOPILOT = true
    REASON = "Reached end of autopilot range (" + STATE.autopilot.range_end + ")"

  If STATE.autopilot.mode == "after" AND current_task < STATE.autopilot.start_at_task:
    PAUSE_AUTOPILOT = true
    REASON = "Autopilot starts at " + STATE.autopilot.start_at_task + " — manual mode for now"

  If STATE.autopilot.mode == "smart":
    Read next task from PLAN_META.json
    If next_task.verify_level in STATE.autopilot.auto_pause_on
       OR (next_task.verify_level == "C" AND next_task.specialist in ["security", "data"]):
      PAUSE_AUTOPILOT = true
      REASON = "Smart pause: next task " + next_task.id + " is " + next_task.verify_level + " (" + next_task.specialist + ")"

  If PAUSE_AUTOPILOT:
    STATE.autopilot.enabled = false
    STATE.autopilot.was_autopilot = true
    STATE.autopilot.paused_reason = REASON
    Display: "⏸️ Autopilot paused: " + REASON
    Display: "/apex:next to continue manually."
    STOP.

  # After breakers: refresh "previous_" snapshot fields for next session's comparison.
  # CRITICAL ORDERING: This MUST run only in the success path (no breaker tripped).
  # If a breaker tripped above, control already hit STOP inside the PAUSE block and
  # never reaches here — leaving previous_ fields unchanged.
  #
  # WHY this matters: If session X's breaker fires and the user force-resumes to
  # session X+1, the breaker MUST fire again because the underlying problem isn't
  # solved. Updating previous_ fields on the pause path would silently reset the
  # comparison baseline, hiding the stuck state from the next session's check.
  # The STOP above + this guard together enforce "pause path = no refresh".
  If PAUSE_AUTOPILOT == false:
    STATE.autopilot.previous_last_completed_task = STATE.autopilot.last_completed_task
    STATE.autopilot.previous_tasks_completed_in_autopilot = STATE.autopilot.tasks_completed_in_autopilot

  # All clear — auto-continue
  Display: "🤖 Autopilot: Phase [current_phase], Task [next_task] → continuing. (Stop: set autopilot.enabled=false in STATE.json)"
  Source and follow ~/.claude/commands/apex/next.md

Else:
  "/apex:next to continue."
</context>