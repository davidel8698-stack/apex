---
description: Start new APEX project.
---

<context>
## VISUAL IDENTITY
All user-facing output in this command MUST render using ~/.claude/apex-branding.md.
Read ~/.claude/apex-branding.md before producing any output.
Opening banner: render Section 5 (Project Init Banner) verbatim — substitute placeholders.
Signature line appears at the bottom. Never skip a frame.

## ENVIRONMENT PRECHECK — runs FIRST, before any other step
MISSING_TOOLS=""
command -v jq &>/dev/null || MISSING_TOOLS="$MISSING_TOOLS jq"
command -v git &>/dev/null || MISSING_TOOLS="$MISSING_TOOLS git"
command -v rg &>/dev/null || MISSING_TOOLS="$MISSING_TOOLS ripgrep(rg)"
if [ -n "$MISSING_TOOLS" ]; then
  echo "🚫 APEX PRECHECK FAILED — missing required tool(s):$MISSING_TOOLS"
  echo "   APEX hooks depend on these. Install them and restart your shell, then retry /apex:start."
  echo "   Run /apex:health-check for environment diagnostics."
  STOP.
fi

Check .apex/STATE.json. If exists: "Project in progress. /apex:next or /apex:resume." Stop.

If no:
  0. Render Section 5 banner with [●] for completed steps, [◐] for active, [○] for pending.
  1. mkdir -p .apex/{pre-build,phases,research,backups,debate-log,comprehension-gates}

  ## USER PROFILE CAPTURE
  2. Ask user (in detected language or default English):
     - "What is your technical level?" → non-programmer / junior / senior / architect
     - "What language should I communicate in?" → e.g. Hebrew + English tech terms
     Write answers into CLAUDE.md ## User Profile section (from CLAUDE-TEMPLATE.md).
     USER_LANG = captured language preference.

  3. Create STATE.json with:
     apex_version: "v7"
     reflexion: {current_unit_attempts: 0, max_attempts: 3}
     evoscore: {regression_rate: 0.0, phases_with_regressions: [], total_cross_phase_tests: 0}
     comprehension_gates: {}
     tdad: {index_built: false}
     context: {current_session_phase: null, estimated_context_usage_pct: 0, rotation_history: [], observation_masking_active: true}
     tokens: {total_input: 0, total_output: 0, framework_overhead: 0, overhead_pct: 0, by_phase: {}, by_agent: {}, by_task: {}}
     phase_tags: {}
     stack_skills: []
     circuit_breaker: {consecutive_no_change_actions: 0, max_allowed: 3, total_tool_calls_this_task: 0, max_tool_calls_per_task: 80, last_file_hash: null, triggered: false}
     snapshots: {pre_task_stash: null, last_snapshot_task: null}
     autopilot: {
       enabled: false,
       mode: null,
       enabled_at: null,
       stop_at_task: null,
       start_at_task: null,
       range_start: null,
       range_end: null,
       auto_pause_on: ["D", "C_security", "C_data"],
       max_tasks_before_human_check: 15,
       max_phases_before_human_check: 3,
       paused_reason: null,
       was_autopilot: false,
       consecutive_sessions: 0,
       tasks_completed_in_autopilot: 0,
       phases_completed_in_autopilot: 0,
       last_completed_task: null,
       last_healthy_tag: null,
       advisor_last_run: null,
       advisor_risk_score: null
     }
     session: {
       id: "sess_" + timestamp,
       started_at: now,
       tasks_completed: 0, tasks_failed: 0, tasks_partial: 0,
       consecutive_failures: 0, consecutive_partials: 0,
       last_checkpoint_tag: null, last_checkpoint_at: null,
       last_wave_tag: null, tasks_since_last_rotation: 0,
       total_context_rotations: 0,
       health_status: "green",
       auto_paused: false, auto_pause_reason: null,
       drift_indicators: {
         spec_drift_count: 0, circuit_breaker_triggers: 0,
         reflexion_total_attempts: 0, low_confidence_results: 0
       }
     }
  4. Create .apex/CONTEXT_BUDGET.json with default budgets (copy from ~/.claude reference or use v6 defaults)
  5. bash ~/.claude/hooks/session-log.sh "resume" "סשן התחיל — [project name]"
  6. Task("planner", "Classify this project, capture requirements, and generate pre-build checklist if Level 3+.")
  7. After planner:
     Level 3+: Update STATE: {current_stage: "pre-build", status: "blocking"}
     Else:     Update STATE: {current_stage: "spec", status: "pending_approval"}
</context>