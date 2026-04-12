---
description: Start new APEX project.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## VISUAL IDENTITY
All user-facing output in this command MUST render using ~/.claude/apex-branding.md.
Read ~/.claude/apex-branding.md before producing any output.
Opening banner: render Section 5 (Project Init Banner) verbatim — substitute placeholders.
Signature line appears at the bottom. Never skip a frame.

### APEXSkin Resolution
Before rendering, resolve APEXSkin variables (Section 17 of apex-branding.md).
Resolution order: PROJECT-APEX.md `## APEXSkin Overrides` → APEX.md defaults → built-in defaults.
Apply resolved values to all template placeholders ({{project_name}}, {{theme_color}},
{{sigil_variant}}, {{frame_style}}, {{version_tag}}, {{signature_line}}).
Variable substitution MUST complete before rendering — never substitute mid-frame.

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

## INFRASTRUCTURE SELF-TEST
bash ~/.claude/scripts/self-test.sh 2>&1
If exit code > 0: "⚠️ APEX infrastructure degraded — $EXIT test(s) failed. Run /apex:health-check."

Check .apex/STATE.json. If exists: "Project in progress. /apex:next or /apex:resume." Stop.

If no:
  0. Render Section 5 banner with [●] for completed steps, [◐] for active, [○] for pending.
  1. mkdir -p .apex/{pre-build,phases,backups,debate-log,roundtable-log,comprehension-gates,todos,threads,seeds,backlog}

  ## TWO-TIER METHODOLOGY SETUP
  1b. Copy ~/.claude/APEX-TEMPLATE.md to .apex/APEX.md
  1c. Copy ~/.claude/PROJECT-APEX-TEMPLATE.md to .apex/PROJECT-APEX.md
      Substitute [PROJECT_NAME] with project directory name.

  ## HOOK REGISTRATION DEPLOYMENT
  1d. Copy ~/.claude/settings.json to .claude/settings.json in the target project root.
      If .claude/settings.json already exists, read existing content, merge the hooks array
      (append any hooks from the template that are not already present by command match),
      and write back. Do not overwrite user-defined hooks or permissions.

  ## SNAPSHOT ORPHAN BRANCH INIT
  1e. Initialize persistent snapshot branch (idempotent — skip if exists):
      ```bash
      if ! git rev-parse --verify apex/snapshots >/dev/null 2>&1; then
        EMPTY_TREE=$(git hash-object -t tree /dev/null)
        INIT_COMMIT=$(git commit-tree "$EMPTY_TREE" -m "apex: init snapshot branch")
        git update-ref refs/heads/apex/snapshots "$INIT_COMMIT"
      fi
      ```
      This creates a hidden orphan branch for persistent pre-task snapshots.
      Unlike stash, this survives `git stash clear` and provides browseable history.

  ## USER PROFILE CAPTURE
  2. Ask user (in detected language or default English):
     - "What is your technical level?" → non-programmer / junior / senior / architect
     - "What language should I communicate in?" → e.g. Hebrew + English tech terms
     Write answers into CLAUDE.md ## User Profile section (from CLAUDE-TEMPLATE.md).
     USER_LANG = captured language preference.

  ## SCOPE WARNING [F-027]
  2b. Before proceeding, display scope warning (in USER_LANG):
      "APEX is designed for structured software projects with git and a test framework.
       It may not be the right fit if your project:
       - Has no git repository
       - Has no test framework or runner
       - Is a one-off script or experiment (<30 min of work)
       - Is non-code (documentation, design, data analysis)
       - Is prototype/throwaway code
       - Is a single-file utility

       See 'When NOT to Use APEX' in APEX-TEMPLATE.md for details.

       (1) Continue with APEX   (2) Exit and use Claude Code directly"
      If (2): display "No problem — just use Claude Code without /apex commands." and STOP.
      If (1): proceed.

  ## STATE INITIALIZATION — CANONICAL STATE / single source of truth for all orchestration decisions.
  ## Fields are progressively populated by planner/architect stages.
  ## Also update STATE.schema.json, status.md, and test fixtures on changes.
  3. Create STATE.json with:
     project: ""
     complexity_level: 0
     complexity_name: ""
     pipeline: []
     apex_version: "v7"
     current_stage: "init"
     pre_build_complete: false
     current_phase: null
     current_unit: null
     current_wave: null
     status: "initializing"
     lock: null
     spec_version: ""
     strict_mode: false
     proposals_mode: true
     created_at: now
     updated_at: now
     phases_total: 0
     phases_completed: 0
     units_total: 0
     units_completed: 0
     pending_notifications: []
     health_check: {last_run: null, all_passed: true, failed_agents: [], test_count: 0}
     reflexion: {current_unit_attempts: 0, max_attempts: 3, last_reflexion_summary: null}
     evoscore: {regression_rate: 0.0, phases_with_regressions: [], total_cross_phase_tests: 0, last_full_audit: null}
     comprehension_gates: {current_gate_required: null}
     tdad: {index_built: false, last_indexed: null, total_nodes: 0}
     context: {current_session_phase: null, session_start_time: now, estimated_context_usage_pct: 0, last_compact: null, rotation_history: [], observation_masking_active: true}
     tokens: {total_input: 0, total_output: 0, framework_overhead: 0, overhead_pct: 0, productive: 0, by_phase: {}, by_agent: {}, by_task: {}}
     phase_tags: {}
     stack_skills: []
     dora: {lead_time_avg: null, deployment_freq: null, change_failure_rate: null, recovery_time_avg: null, phases_failed: 0, _last_failure_at: null, last_updated: null}
     mutation_scores: {}
     autonomy: {
       by_verify_level: {
         A: {level: 0, consecutive_successes: 0},
         B: {level: 0, consecutive_successes: 0},
         C: {level: 0, consecutive_successes: 0},
         D: {level: 0, consecutive_successes: 0}
       }
     }
     circuit_breaker: {consecutive_no_change_actions: 0, max_allowed: 3, total_tool_calls_this_task: 0, max_tool_calls_per_task: 80, last_file_hash: null, triggered: false, trigger_reason: null}
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
       previous_tasks_completed_in_autopilot: 0,
       phases_completed_in_autopilot: 0,
       last_completed_task: null,
       previous_last_completed_task: null,
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
  4. If .apex/CONTEXT_BUDGET.json does not exist:
       Copy ~/.claude/CONTEXT_BUDGET.default.json to .apex/CONTEXT_BUDGET.json
  5. Copy ~/.claude/THREAT_MODEL-TEMPLATE.md to .apex/THREAT_MODEL.md
     Substitute [PROJECT_NAME] with project name, [DATE] with current date, [DETECTED_STACK] with "TBD — updated after Phase 0".
  6. bash ~/.claude/hooks/session-log.sh "start" "סשן התחיל — [project name]"
  7. Task("planner", "Project root: $PWD. Run Phase 0 auto-detection first. Classify this project, capture requirements, and generate pre-build checklist if Level 3+.")
  8. After planner:
     Read STATE.json complexity_level and complexity_name.
     Display: "Preset: [complexity_name] (Level [complexity_level])"
     Level 3+: Update STATE: {current_stage: "pre-build", status: "blocking"}
     Else:     Update STATE: {current_stage: "spec", status: "pending_approval"}
</context>