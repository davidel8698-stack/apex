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

## STATE.json BOOTSTRAP [R5-004]
If `.apex/STATE.json` is missing AND `.apex/event-log.jsonl` exists:
  Run `bash ~/.claude/hooks/state-rebuild.sh` first. The hook reconstructs STATE.json from the disk-resident event log + phase summaries (spec: "State derives from disk."). If reconstruction succeeds, proceed below. If STATE.json is still missing after the rebuild attempt, fall through to `/apex:start` rather than reading a non-existent file.

## SESSION BOOT BANNER [v7.1 Auto-Continuity]
If `.apex/SESSION_BOOT.md` exists:
  Read it. The boot banner was written by `session-auto-resume.sh` on
  SessionStart and identifies *why* the previous session ended (memory_pressure,
  external_watchdog, health_red, etc.). Render its Hebrew banner to the user
  inside a soft frame. After resume completes successfully (auto_paused → false),
  delete the file: `rm .apex/SESSION_BOOT.md` so the next session does not
  re-display a stale banner.

## TURN-CHECKPOINT SURFACING [v7.1 Auto-Continuity]
If `.apex/TURN_CHECKPOINT.json` exists:
  Read its `ts` and compute age in minutes.
  If age < `auto_continuity.turn_checkpoint_freshness_minutes` (default 30) AND
     STATE.session.auto_paused was true (previous session ended mid-task):
    Display in user's configured language with proposals_mode formatting:
    "📍 נמצאה נקודת checkpoint תוך-task מה-[ts]:
       משימה: [task_id], אחרי [tool_call_index] קריאות-כלי

     אפשרויות:
     1. [recommended] /apex:next — להמשיך עם רענון של reflexion counter
     2. /apex:recover — לבחור באופציה (6) ולהמשיך *מ*ה-checkpoint עם
                        prior progress מוזרק לexecutor brief
     3. (התעלם) /apex:next ולהתחיל את המשימה מחדש מאפס"
  If checkpoint is older than threshold, just reset:
    Delete TURN_CHECKPOINT.json (stale — no longer trustworthy).

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

## ROTATION-NOTE INGESTION [M14 / Phase 12.08]
# When the previous session ended via /apex:next's rotation dispatch,
# pre-rotation-snapshot.sh wrote 4 atomic artifacts including a
# ROTATION-NOTE-<timestamp>.md under .apex/phases/<phase>/. Load that
# note PREFERENTIALLY over DECISIONS.md for the immediate "what was I
# doing" context. DECISIONS.md remains the historical record.
ROTATION_NOTE=""
if command -v git >/dev/null 2>&1; then
  # Find the most recent apex/rotation/* tag and the matching note.
  LATEST_ROTATION_TAG=$(git tag --list 'apex/rotation/*' 2>/dev/null | sort -r | head -1)
  if [ -n "$LATEST_ROTATION_TAG" ]; then
    # Tag format: apex/rotation/<TS_FILE>-<phase> → derive the note path.
    TS_PART=$(echo "$LATEST_ROTATION_TAG" | sed -E 's|^apex/rotation/(.*)-[^-]+$|\1|')
    PHASE_PART=$(echo "$LATEST_ROTATION_TAG" | sed -E 's|^apex/rotation/.*-([^-]+)$|\1|')
    CANDIDATE=".apex/phases/${PHASE_PART}/ROTATION-NOTE-${TS_PART}.md"
    if [ -f "$CANDIDATE" ]; then
      ROTATION_NOTE="$CANDIDATE"
    fi
  fi
fi

If ROTATION_NOTE is non-empty:
  Display: "🔄 Resuming from rotation snapshot ${LATEST_ROTATION_TAG}"
  Read $ROTATION_NOTE and inject the body into the resume context
  AS THE PRIMARY "what was I doing" source. DECISIONS.md still loaded
  for historical context but secondary to the note.
  bash ~/.claude/hooks/session-log.sh "resume_from_rotation" "Loaded ROTATION-NOTE: ${ROTATION_NOTE}"
Else:
  # No rotation snapshot → fall through to legacy resume path (loads
  # DECISIONS.md + most-recent SUMMARY.md as before).
  bash ~/.claude/hooks/session-log.sh "resume_no_rotation_note" "No apex/rotation/* tag found — legacy resume path"

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