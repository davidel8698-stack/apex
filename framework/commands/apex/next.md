---
description: Advance to next logical step. Orchestration heart of APEX.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## VISUAL IDENTITY
Read ~/.claude/apex-branding.md before producing any user-facing output.
Every output must use Peak Protocol templates. Render references below.

### APEXSkin Resolution
Before rendering, resolve APEXSkin variables (Section 17 of apex-branding.md).
Resolution order: PROJECT-APEX.md `## APEXSkin Overrides` → APEX.md defaults → built-in defaults.
Apply resolved values to all template placeholders ({{project_name}}, {{theme_color}},
{{sigil_variant}}, {{frame_style}}, {{version_tag}}, {{signature_line}}).
Variable substitution MUST complete before rendering — never substitute mid-frame.

## RENDER TABLE (apex-branding.md section references)
- Top of every output:          Section 13 status bar
- Autopilot active badge:       Section 9 (only if STATE.autopilot.enabled)
- Critic PASS verdict:          Section 7.A (verdict card)
- Critic PARTIAL verdict:       Section 7.B (verdict card)
- Critic FAIL verdict:          Section 7.C (verdict card)
- BLOCKED (3 attempts):         Section 7.D (verdict card)
- Phase begin:                  Section 8.B (phase transition)
- Phase complete:               Section 8.A (phase transition)
- Context rotation:             Section 8.C (phase transition)
- Autopilot transformation:     Section 9 (enable flow)
- Autopilot Advisor briefing:   Section 10 (MEGA frame)
- Project complete:             Section 15 (grand finale)
- Bottom of every output:       Section 3.E signature line

NEVER output bare text. NEVER skip a frame. NEVER add emojis inside frames.

## GLASS COCKPIT — AMBIENT HEADER (render at top of every /apex:next output)
1. DECISION FILTER for Section 10-D (Ambient Timeline) — overrides Section 10-D parse rule:
   a. DECISION_TYPES = pending_approval | auto_pause | time_gate | coherence_fail | veto | blocked | phantom_fail
   b. Primary: jq -c 'select(.event == "pending_approval" or .event == "auto_pause" or .event == "time_gate" or .event == "coherence_fail" or .event == "veto" or .event == "blocked" or .event == "phantom_fail")' .apex/event-log.jsonl | tail -5
   c. Fallback (if event-log.jsonl missing): grep -E '(🛑|💥|👻)' .apex/SESSION-LOG.md | tail -5
   d. If result has fewer than 3 items → pad with most recent events from tail -5 .apex/SESSION-LOG.md (skip date headers)
   e. Cap at 5 items maximum. Render using Section 10-D visual template.
2. tail -5 .apex/SESSION-LOG.md → render Section 10-E (Live Ticker)
3. ELAPSED TIME: Compute elapsed = now - STATE.created_at. Format as "[N]d [N]h" (e.g., "3d 14h"). If created_at missing or null: show "N/A". Display in cockpit header after Live Ticker.
4. These appear BEFORE any other framed content in the output (right after the status bar)

Read .apex/STATE.json

## TECHNICAL LEVEL ADAPTATION
Read technical level from CLAUDE.md ## User Profile section.
TECH_LEVEL = non-programmer / junior / senior / architect

Adapt all user-facing output in this command:
- non-programmer: simple language, no jargon, explain every decision, offer guided choices, frame errors as "something went wrong" with clear next steps
- junior: moderate detail, explain technical terms on first use, highlight recommended actions
- senior: concise, use technical terms freely, focus on what changed
- architect: terse, assume full context, focus on trade-offs and risks

## CONTEXT OVERFLOW CHECK — RUNS FIRST
bash ~/.claude/hooks/context-monitor.sh
If "CRITICAL_OVERFLOW": save state, "⚠️ Context at [N]%. Run /apex:resume", STOP.
If "WARNING_OVERFLOW":
  MEMORY_FILE_COUNT = count files in .apex/todos/, .apex/threads/, .apex/seeds/
  If MEMORY_FILE_COUNT > 10:
    Run memory-synthesis agent in background (dream-cycle mode)
    bash ~/.claude/hooks/session-log.sh "dream_cycle" "Dream-cycle before context compact — ${ESTIMATED_PCT}% usage, [MEMORY_FILE_COUNT] memory files"
  If STATE.session exists AND (STATE.session.tasks_completed - STATE.session.tasks_since_last_rotation) >= 4:
    bash ~/.claude/hooks/session-log.sh "rotate" "סיבוב הקשר יזום — ${ESTIMATED_PCT}% שימוש"
    Save state, run /compact, update STATE.session.total_context_rotations++, STATE.session.tasks_since_last_rotation = STATE.session.tasks_completed
  Else: run /compact, continue.

## SESSION GUARDIAN — AUTO-INIT FOR EXISTING PROJECTS
If STATE.session does NOT exist:
  Initialize STATE.session = {
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
  Write updated STATE.json
  bash ~/.claude/hooks/session-log.sh "resume" "Session Guardian הופעל על פרויקט קיים"

## SESSION HEALTH CHECK — RUNS AFTER CONTEXT CHECK
If STATE.session exists:
  ERROR_RATE = session.tasks_failed / max(session.tasks_completed + session.tasks_failed, 1)
  PARTIAL_RATE = session.tasks_partial / max(session.tasks_completed + session.tasks_partial, 1)

  HEALTH = "green"
  If ERROR_RATE > 0.3 OR session.consecutive_failures >= 2: HEALTH = "red"
  Else if session.drift_indicators.circuit_breaker_triggers >= 2: HEALTH = "red"
  Else if ERROR_RATE > 0.15 OR PARTIAL_RATE > 0.4 OR session.consecutive_partials >= 3: HEALTH = "yellow"
  Else if session.drift_indicators.low_confidence_results >= 3: HEALTH = "yellow"

  Update STATE.session.health_status = HEALTH

  If HEALTH == "red":
    Update STATE.session: auto_paused = true, auto_pause_reason = [computed reason]
    bash ~/.claude/hooks/session-log.sh "auto_pause" "[reason in user language]"
    Display in user's configured language (from CLAUDE.md User Profile):
    "🛑 סשן מושהה אוטומטית
    סיבה: [explanation in user language]

    [N] משימות הושלמו | [N] נכשלו | [N] חלקי
    נקודת שחזור אחרונה: [tag or 'אין']

    אפשרויות:
    1. /apex:resume — התחל סשן חדש עם הקשר נקי
    2. /apex:recover — שחזר מנקודת שחזור
    3. /apex:next — המשך (לא מומלץ)"
    STOP.

  If HEALTH == "yellow":
    bash ~/.claude/hooks/session-log.sh "warning" "[warning in user language]"
    Continue cautiously.

## TIME-BASED DECISION GATE — RUNS AFTER SESSION HEALTH CHECK
If STATE.session.started_at exists:
  ELAPSED_MINUTES = (now - STATE.session.started_at) in minutes
  LAST_GATE = STATE.session.last_time_gate OR STATE.session.started_at
  MINUTES_SINCE_GATE = (now - LAST_GATE) in minutes

  If ELAPSED_MINUTES >= 60 AND MINUTES_SINCE_GATE >= 60:
    STATE.session.last_time_gate = now
    Write updated STATE.json
    bash ~/.claude/hooks/session-log.sh "time_gate" "Decision gate at [ELAPSED_MINUTES] minutes"
    Display in user's configured language (from CLAUDE.md User Profile):
    "⏱️ עברו [ELAPSED_MINUTES] דקות מתחילת הסשן.

    אפשרויות:
    1. המשך — הכל בסדר, תמשיך לעבוד
    2. /apex:pause — שמור מצב והפסק
    3. /apex:resume — התחל סשן חדש עם הקשר נקי"

    Wait for user response.
    If user selects 1 ("continue"):
      MEMORY_FILE_COUNT = count files in .apex/todos/, .apex/threads/, .apex/seeds/
      If MEMORY_FILE_COUNT > 10:
        Run memory-synthesis agent in background (dream-cycle mode)
        bash ~/.claude/hooks/session-log.sh "dream_cycle" "Periodic dream-cycle triggered at [ELAPSED_MINUTES] min — [MEMORY_FILE_COUNT] memory files"
      proceed normally.
    If user selects 2 or 3: execute selected command. STOP.

## MODEL ROUTING HELPER (used by all agent invocations below)
Read ~/.claude/apex-model-routing.json (if exists)
resolve_model(agent_type, verify_level):
  model = routing[agent_type].default
  If verify_level AND routing[agent_type].downgrade_on_verify_level[verify_level] exists → use that
  If STATE.complexity_level in routing[agent_type].escalate_on_level → use that (overrides downgrade)
  If retrying AND routing[agent_type].escalate_on_retry exists → use that (overrides all)
  Return model

─────────────────────────────────────────────────────────
STATE: current_stage=pre-build, status=blocking
─────────────────────────────────────────────────────────
Read .apex/pre-build/STATUS.json
If blocking=true: show remaining items, "⛔ /apex:precheck done [N]", Stop.
If blocking=false:
  ## RENDER: Mission Briefing (Section 10-B variant for planner)
  ##   Agent card: PLANNER (Section 10-A)
  ##   Replaces "Done When" with "Will capture requirements and write SPEC.md"
  Task("planner", "Capture requirements — skip Phase 1 (complexity already classified)")
  ## RENDER: Flight Recorder (Section 10-C variant for planner)
  ##   Body: "CLASSIFICATION: Level [N]" + requirements summary from SPEC.md
  Update STATE: {current_stage: "spec", status: "pending_approval"}

─────────────────────────────────────────────────────────
STATE: current_stage=spec, status=pending_approval
─────────────────────────────────────────────────────────
Show SPEC.md → "Does this capture what you want to build? (y/edit/restart)"
If y: Update STATE: {current_stage: "architect", status: "pending"}

─────────────────────────────────────────────────────────
STATE: current_stage=architect, status=pending
─────────────────────────────────────────────────────────
ARCHITECT_CONTEXT = {
  learnings_hot: ~/.claude/apex-learnings.md HOT section only,
  learnings_warm: WARM entries matching STATE.stack_skills,
  spec: .apex/SPEC.md,
  complexity: .apex/COMPLEXITY.md,
  stack_skills: from ~/.claude/apex-skills/ matching STATE.stack_skills
}
Verify tokens < CONTEXT_BUDGET.per_agent_limits.architect.max_input

## RENDER: Mission Briefing (Section 10-B variant for architect)
##   Agent card: ARCHITECT (Section 10-A)
##   "Phase" instead of "Task", "Reads: HOT + WARM learnings ([N] entries)" instead of "Done When"
Task("architect", ARCHITECT_CONTEXT + "Create full plan with PLAN_META.json and WAVE_MAP.json.",
     model=resolve_model("architect"))
## RENDER: Flight Recorder (Section 10-C variant for architect)
##   Body: "PLAN SUMMARY" — tasks planned, waves built, debates triggered (from PLAN_META.json)

bash ~/.claude/hooks/tdad-index.sh
TDAD_EXIT=$?
Update STATE: {
  current_stage: "build", current_phase: "01", current_wave: 1,
  status: "pending_approval",
  tdad: {index_built: (TDAD_EXIT == 0), last_indexed: (if TDAD_EXIT == 0 then now else null)},
  ## PHASE DIRECTORY ENFORCEMENT: always create as .apex/phases/${PHASE_NUMBER}/
  ## Pattern: nested under phases/ with zero-padded phase number (e.g., .apex/phases/01/, .apex/phases/02/)
  ## NEVER use flat naming like .apex/phase-01/ or .apex/phases-01/
  mkdir -p .apex/phases/${current_phase}/
  autonomy: { by_verify_level: {
    A: {level:0, consecutive_successes:0}, B: {level:0, consecutive_successes:0},
    C: {level:0, consecutive_successes:0}, D: {level:0, consecutive_successes:0}
  }},
  pending_notifications: [],
  tokens: {framework_overhead: 0, productive: 0}
}

─────────────────────────────────────────────────────────
STATE: current_stage=build, status=pending_approval
─────────────────────────────────────────────────────────

## TWO-TIER METHODOLOGY CHECK
If NOT file_exists(.apex/APEX.md) OR NOT file_exists(.apex/PROJECT-APEX.md):
  MISSING = list missing files
  "⚠️ Two-tier methodology: ${MISSING} not found. Run /apex:start to regenerate."
  bash ~/.claude/hooks/session-log.sh "warning" "Two-tier methodology: ${MISSING} missing"
  Continue (advisory only).

## CHECK CONTEXT ROTATION
If STATE.context.current_session_phase != current_phase AND current_session_phase is not null:
  "🔄 New phase. Run /apex:resume for clean context, or 'continue'."
  If 'continue': /compact, update current_session_phase. Else: STOP.

## ARCHITECT OUTPUT VALIDATION
Before proceeding: verify .apex/phases/${current_phase}/PLAN_META.json and WAVE_MAP.json exist.
If either is missing: STOP. "🚫 Architect output incomplete — PLAN_META.json or WAVE_MAP.json missing. Re-run /apex:next."

## WAVE 0: Nyquist Validation Layer [F-005]
If STATE.complexity_level >= 2 AND NOT file_exists(.apex/phases/${current_phase}/WAVE_0_TEST_MAP.json):
  Resolve model: routing["test-architect"] from apex-model-routing.json.
  Task("test-architect", {
    mode: "phase",
    input: .apex/phases/${current_phase}/PLAN_META.json + .apex/SPEC.md,
    output: ".apex/phases/${current_phase}/WAVE_0_TEST_MAP.json"
  })
  Read WAVE_0_TEST_MAP.json.
  If WAVE_0_TEST_MAP.veto == true:
    bash ~/.claude/hooks/session-log.sh "veto" "Wave 0 — test-architect vetoed phase ${current_phase}: ${WAVE_0_TEST_MAP.veto_reason}"
    STATE.status = "blocked_by_wave_0"
    Display:
    "🚫 Wave 0 veto: ${WAVE_0_TEST_MAP.veto_reason}
     Test infrastructure must be established before code execution.
     Address gaps and re-run /apex:next."
    STOP.
  Else:
    bash ~/.claude/hooks/session-log.sh "wave_0" "Wave 0 passed — test infrastructure mapped for phase ${current_phase}"

If STATE.complexity_level <= 1:
  ## L1 skip — minimal ceremony, Wave 0 not required

## STEP A: Read Wave Map
CURRENT_WAVE = STATE.current_wave
WAVE_TASKS = WAVE_MAP.waves[CURRENT_WAVE].tasks
NEXT_UNIT = first unfinished task
If all tasks in CURRENT_WAVE complete:
  ## WAVE BOUNDARY — CUMULATIVE COHERENCE CHECK
  If STATE.session exists AND CURRENT_WAVE > 1:
    Run project-level tests (from PLAN_META build commands)
    COMBINED_DIFF_STAT = "$(git diff ${STATE.session.last_wave_tag}..HEAD --stat)" (if last_wave_tag exists)
    If any test fails that was NOT touched in this wave:
      STATE.session.drift_indicators.spec_drift_count++
      bash ~/.claude/hooks/session-log.sh "coherence_fail" "רגרסיה בין-משימתית זוהתה בגל ${CURRENT_WAVE}"
      Attempt to fix regression before advancing. If unfixable → treat as FAIL.
    Else:
      bash ~/.claude/hooks/session-log.sh "wave_complete" "גל ${CURRENT_WAVE} הושלם — ${N} משימות"
    WAVE_TAG="apex/wave-${current_phase}-${CURRENT_WAVE}-complete"
    git tag -a "$WAVE_TAG" -m "Wave ${CURRENT_WAVE} coherence checked"
    If git tag succeeded:
      STATE.session.last_wave_tag = WAVE_TAG
    Else:
      bash ~/.claude/hooks/session-log.sh "warning" "git tag failed for wave ${CURRENT_WAVE}"
  Advance wave.
If all waves complete → STATE.status = "verify_needed"

## STEP B: Repository + Impact Maps
bash ~/.claude/hooks/generate-task-map.sh [NEXT_UNIT]
If STATE.tdad.index_built:
  CHANGED_FILES = PLAN_META.tasks[NEXT_UNIT].files
  python3 ~/.claude/hooks/tdad-impact.py --files "$CHANGED_FILES" --map .apex/TEST_MAP.txt

## STEP C: Irreversible Decision Check
Read PLAN_META.json for current unit.
If task.is_irreversible == true:
  "⚖️ Irreversible decision: [name]. Running Architecture Debate..."
  Source and follow ~/.claude/commands/apex/_debate.md protocol.
  "⚖️ Debate complete."

If task.roundtable_needed == true:
  "🔵 Multi-faceted decision: [name]. Convening Roundtable..."
  Source and follow ~/.claude/commands/apex/_roundtable.md protocol.
  "🔵 Roundtable complete."

## STEP D: Reflexion State
ATTEMPTS = STATE.reflexion.current_unit_attempts
If ATTEMPTS > 0: load .apex/phases/${current_phase}/[unit]-REFLEXION.md as "PREVIOUS ATTEMPT FAILED: [content]"

## STEP E: Build Executor Context — Observation Masking Protocol
## Observation masking: context is structured so stale observations are replaced per-task, not summarized. See DIRECTORY-CONTRACT.md.
Read CONTEXT_BUDGET.json, PLAN_META.json for current task.
Stable prefix FIRST (for cache hits), volatile LAST:

EXECUTOR_CONTEXT = {
  ## ZONE 1: Stable Prefix (cached)
  system_prompt: executor agent prompt,
  claude_md: first 200 lines of CLAUDE.md,
  repo_map: .apex/TASK_MAP.md (1-4K tokens),
  stack_skills: matching STATE.stack_skills (lazy-load),

  ## ZONE 2: Task Context (JIT per task)
  task_xml: full task XML from PLAN.md (NEVER summarize),
  spec_sections: ONLY sections matching task.spec_ref,
  decisions: ONLY decisions tagged current phase or 'global',
  dependency_summaries: from .apex/phases/${dep_phase}/[dep_task]-RESULT.json.what_next_tasks_can_assume (not SUMMARY.md),
  active_files: full content of files in task.files,
  interface_context: function signatures only for dependencies,

  ## ZONE 3: Working Memory (volatile — LAST position)
  impacted_tests: .apex/IMPACTED_TESTS.txt,
  reflexion: .apex/phases/${current_phase}/[unit]-REFLEXION.md (if retry, NEVER summarize)
}

If TOTAL_TOKENS > MAX: reduce per CONTEXT_BUDGET.json priority:
  observation masking → trim dep summaries → trim spec → trim skills → trim decisions
  NEVER trim: task_xml, acceptance_criteria, reflexion_brief

## STEP F: Pre-Task Snapshot
bash ~/.claude/hooks/pre-task-snapshot.sh [task_id]
If hook exit code == 2: snapshot verification failed (filesystem-level).
  STATE.snapshots.pre_task_stash is null. Prompt user:
  "🚫 Pre-task snapshot could not be verified — no rollback available.
   (1) Abort task   (2) Proceed without snapshot (risk: no rollback)"
  If (1): STATE.status = "pending_approval", STOP.
  If (2): log warning to SESSION-LOG.md, continue.
Else (exit 0): proceed.
Update STATE: snapshots, circuit_breaker.total_tool_calls_this_task = 0

## STEP F.5: Test Architecture Review (C/D only) [F-006]
Read task verify_level from PLAN_META.json.
If verify_level in ["A", "B"]: skip this step entirely.
If verify_level in ["C", "D"]:
  Resolve model: routing["test-architect"] from apex-model-routing.json.
  Task("test-architect", {
    input: task_xml + .apex/SPEC.md,
    output: ".apex/phases/$PHASE/TEST_PLAN.json"
  })
  Read TEST_PLAN.json.
  If TEST_PLAN.veto == true:
    bash ~/.claude/hooks/session-log.sh "test_architect" "VETO — test-architect blocked task ${NEXT_UNIT}: ${TEST_PLAN.veto_reason}"
    STATE.status = "blocked_by_test_architect"
    Display to user:
    "🚫 Test architect vetoed task ${NEXT_UNIT}: ${TEST_PLAN.veto_reason}
     Review TEST_PLAN.json and address gaps before re-running /apex:next."
    STOP.
  Else:
    bash ~/.claude/hooks/session-log.sh "test_architect" "TEST_PLAN approved for task ${NEXT_UNIT} — risk: ${TEST_PLAN.risk_profile}"
    Inject TEST_PLAN.json into executor context (executor receives test requirements).

## STEP F.6: Spec Drift Check [F-014]
If STATE.spec_version is non-empty AND file .apex/SPEC.md exists:
  CURRENT_HASH = sha256sum .apex/SPEC.md | cut -d' ' -f1
  If CURRENT_HASH != STATE.spec_version:
    STATE.session.drift_indicators.spec_drift_count++
    bash ~/.claude/hooks/session-log.sh "spec_drift" "SPEC.md changed since planning (stored: ${STATE.spec_version:0:8}…, current: ${CURRENT_HASH:0:8}…). Consider /apex:spec."
    "⚠️ Spec drift detected — SPEC.md has changed since last /apex:spec. Review changes or re-run /apex:spec to update."
    (Advisory only — do not block execution)

## STEP G: Autonomy Check + Execute
Read task verify_level from PLAN_META.json

## STRICT MODE OVERRIDE
If STATE.strict_mode == true:
  Override verify_level to "D" for this task (runtime only — PLAN_META unchanged).
  bash ~/.claude/hooks/session-log.sh "strict_mode" "STRICT MODE — משימה ${NEXT_UNIT} מוגברת ל-verify_level D"

## DECISION MODE ENFORCEMENT [F-005]
Read task decision_mode from PLAN_META.json (default: "replacement" if field absent)
If decision_mode == "collaborator":
  EFFECTIVE_LEVEL = 0
  bash ~/.claude/hooks/session-log.sh "decision_mode" "COLLABORATOR MODE — task ${NEXT_UNIT} forces approval (decision_mode=collaborator)"
  Skip to approval prompt below.
Else (decision_mode == "replacement" or absent):
  TASK_AUTONOMY = STATE.autonomy.by_verify_level[verify_level]
  EFFECTIVE_LEVEL = min(TASK_AUTONOMY.level, cap) where caps: A→2, B→2, C→1, D→0

If EFFECTIVE_LEVEL == 0: show plan + "Proceed? (y/n/edit)"
If EFFECTIVE_LEVEL >= 1: execute automatically

## RENDER: Mission Briefing (Section 10-B) BEFORE invocation
##   Agent card chosen by specialist field:
##     none          → EXECUTOR card
##     integration   → INTEGRATION card
##     security      → SECURITY card
##     data          → DATA card
##     frontend      → FRONTEND card
##   Populate: task_id, verify_level, goal, context_loaded tokens, done_when, budget
Invoke agent by specialist field:
  none→executor, integration→integration-specialist, security→security-specialist,
  data→data-specialist, frontend→frontend-specialist
  model=resolve_model(agent_type)
## RENDER: Flight Recorder (Section 10-C) AFTER invocation returns
##   Parse .apex/phases/${current_phase}/${task_id}-RESULT.json
##   Show files touched, tools called, verify commands, done criteria, confidence

Update STATE.tokens: by_phase, by_agent, by_task, productive += this call
Update STATE: {status: "critic_needed"}

─────────────────────────────────────────────────────────
STATE: current_stage=build, status=critic_needed
─────────────────────────────────────────────────────────

## PHANTOM CHECK — second defense layer before clean-room critic
## Rationale: critic never sees SUMMARY.md (clean-room), so SUMMARY phantom language
## is invisible to critic. The phantom-check hook greps SUMMARY.md for uncertainty
## phrases ("should", "seems", "I believe", etc.) and fails fast before critic runs.
bash ~/.claude/hooks/phantom-check.sh .apex/phases/${current_phase}/${NEXT_UNIT}-SUMMARY.md
PHANTOM_EXIT=$?

If PHANTOM_EXIT == 2: phantom language detected in SUMMARY.md.
  # Synthesize REFLEXION.md (normally written by critic on FAIL)
  Write .apex/phases/${current_phase}/${NEXT_UNIT}-REFLEXION.md:
    "# Phantom Verification Failure
    ## What Failed
    SUMMARY.md contained uncertainty language (should/seems/I believe/probably/...)
    The phantom-check hook blocked advancement before clean-room critic ran.
    ## For Next Attempt
    1. Rewrite SUMMARY.md with concrete command outputs only.
    2. Replace every 'should pass' / 'seems to work' with actual pasted test output.
    3. If you cannot produce concrete evidence for a claim, mark the criterion
       verified=false in RESULT.json and explain why in 'issues_found'.
    ## What NOT to Do Again
    Never write 'I believe' or 'appears to' in SUMMARY.md — those are phantom verification."
  # Synthesize CRITIC.md with FAIL verdict — verdict handler reads this
  Write .apex/phases/${current_phase}/${NEXT_UNIT}-CRITIC.md:
    "# Clean-Room Review: ${NEXT_UNIT}
    ## Confidence: 0/0 criteria verified | N/A unverified | N/A missing
    ## Phantom Verification Failure
    SUMMARY.md contained uncertainty language. Detected by phantom-check hook
    before clean-room critic dispatch. Critic did not run.
    ## Verdict: FAIL
    Phantom verification is treated as a critical failure. Rewrite SUMMARY.md
    with concrete command outputs and retry."
  # Log phantom failure to session log (DD-002 fix)
  bash ~/.claude/hooks/session-log.sh "phantom_fail" "זיהוי שפת פנטום ב-SUMMARY.md של ${NEXT_UNIT}"
  # Track phantom-check overhead in framework tokens (DD-004 fix)
  STATE.tokens.framework_overhead += 500
  # Skip the CLEAN-ROOM CRITIC dispatch below. Verdict handler will see FAIL.
  PHANTOM_SKIP_CRITIC = true

Else if PHANTOM_EXIT == 1:
  # Advisory: phantom hook couldn't find SUMMARY.md file. Log warning, continue to critic.
  bash ~/.claude/hooks/session-log.sh "warning" "phantom-check could not locate SUMMARY.md for ${NEXT_UNIT}"
  PHANTOM_SKIP_CRITIC = false

Else (PHANTOM_EXIT == 0):
  # SUMMARY uses concrete language — proceed to clean-room critic normally.
  PHANTOM_SKIP_CRITIC = false

## CLEAN-ROOM CRITIC
## GUARD: If PHANTOM_SKIP_CRITIC == true, skip this ENTIRE section (CRITIC_CONTEXT,
## security persona, Mission Briefing, Task("critic"), Flight Recorder, framework_overhead
## update) and proceed directly to PROCESS VERDICT + AUTONOMY UPDATE below. The verdict
## handler will read the synthetic CRITIC.md written by phantom-check and run its FAIL path.
If PHANTOM_SKIP_CRITIC: skip to PROCESS VERDICT section below.

CRITIC_CONTEXT = {
  task_spec: from PLAN_META.json (done_criteria, edge_cases, spec_ref),
  diff: "$(git diff HEAD~1)",
  modified_files: re-read from disk,
  test_results: from .apex/phases/${current_phase}/[task]-RESULT.json — tests_run and verify_commands_run ONLY
  ## NEVER: SUMMARY.md, executor reasoning/CoT/confidence, failed attempts
}
Verify tokens < CONTEXT_BUDGET.per_agent_limits.critic.max_input

## [v7, R4] SECURITY PERSONA — activates for D-level and security tasks
If task verify_level == "D" OR task.specialist == "security":
  CRITIC_CONTEXT += {
    security_persona: "You are a RED TEAM security reviewer.
    Assume this code contains at least one exploitable vulnerability.
    Check: injection, XSS, CSRF, missing auth, tenant bypass, hardcoded secrets,
    missing rate limiting, insecure defaults.
    If you find ZERO issues, state why you're confident."
  }

## CROSS-MODEL ENFORCEMENT [R-008]
## Spec: "Cross-model critic חובה" — critic must run on a different model than executor.
critic_model = resolve_model("critic")
executor_model = (the model resolved for this task's executor dispatch)
If critic_model == executor_model AND routing["critic"].cross_model_required:
  critic_model = routing["critic"].fallback_if_same
  Log to SESSION-LOG: "Cross-model enforcement: executor={executor_model}, critic escalated to {critic_model}"

## RENDER: Mission Briefing (Section 10-B variant for critic)
##   Agent card: CRITIC (Section 10-A)
##   "Will verify against [N] criteria" instead of "Done When"
##   Note: "Clean-room: no SUMMARY.md"
Task("critic", CRITIC_CONTEXT, model=critic_model)
## RENDER: Flight Recorder (Section 10-C variant for critic)
##   Parse .apex/phases/${current_phase}/${task_id}-CRITIC.md
##   Body: VERDICT with verified/unverified/missing counts (NO files touched section)
STATE.tokens.framework_overhead += critic call tokens

## PROCESS VERDICT + AUTONOMY UPDATE
Read task verify_level. On any verdict:

**RENDER**: Before any prose, emit the verdict card from apex-branding.md Section 7
  (7.A for PASS, 7.B for PARTIAL, 7.C for FAIL, 7.D for BLOCKED).

PASS:
  Reset reflexion attempts to 0. Remove lock.
  STATE.autonomy.by_verify_level[verify_level].consecutive_successes++
  # D-level: consecutive_successes tracked for telemetry only (cap=0, no promotion effect by design)
  If consecutive_successes >= 5: level++ (up to cap), reset counter.
    Append P3 notification: "Autonomy escalated for [level]"

  ## SESSION CHECKPOINT
  If STATE.session exists:
    TASK_TAG="apex/task-${current_phase}-${NEXT_UNIT}-complete"
    git tag -a "$TASK_TAG" -m "APEX checkpoint: task ${NEXT_UNIT} passed critic"
    If git tag succeeded:
      Update STATE.session: last_checkpoint_tag = TASK_TAG, last_checkpoint_at = now
    Else:
      bash ~/.claude/hooks/session-log.sh "warning" "git tag failed for checkpoint ${NEXT_UNIT}"
    Update STATE.session:
      tasks_completed++
      consecutive_failures = 0
      consecutive_partials = 0
    bash ~/.claude/hooks/session-log.sh "checkpoint" "משימה ${NEXT_UNIT} הושלמה ✅"

  ## DORA RECOVERY TRACKING [R-011]
  If STATE.dora._last_failure_at is non-null:
    RECOVERY_HOURS = (now - STATE.dora._last_failure_at) in hours
    If STATE.dora.recovery_time_avg is null:
      STATE.dora.recovery_time_avg = RECOVERY_HOURS
    Else:
      STATE.dora.recovery_time_avg = (STATE.dora.recovery_time_avg + RECOVERY_HOURS) / 2
    STATE.dora._last_failure_at = null
    STATE.dora.last_updated = now

  ## MUTATION GATE (C/D tasks only)
  Read task verify_level from PLAN_META.json for NEXT_UNIT.
  If verify_level in ["C", "D"]:
    bash ~/.claude/hooks/mutation-gate.sh ${NEXT_UNIT} ${verify_level}
    If exit 2 (below threshold):
      Treat as PARTIAL — task correctness confirmed by critic, but test quality insufficient.
      "⚠️ Mutation kill rate below threshold. Tests need strengthening."
      Log to DECISIONS.md: "Mutation gate: ${NEXT_UNIT} passed critic but below mutation threshold"

  ## TEST AUDITOR (C/D tasks only) [R-012]
  ## Quarantined agent — reads ONLY test files, never implementation code.
  ## Runs after critic PASS + mutation gate, before autopilot state update.
  If verify_level in ["C", "D"]:
    AUDITOR_CONTEXT = {
      test_plan: .apex/phases/${current_phase}/TEST_PLAN.json,
      critic_verdict: .apex/phases/${current_phase}/${NEXT_UNIT}-CRITIC.md (verdict line only),
      result_tests: .apex/phases/${current_phase}/${NEXT_UNIT}-RESULT.json (tests_run, verify_commands_run only),
      task_spec: PLAN_META.json task XML for NEXT_UNIT (done_criteria, edge_cases, verify_level)
    }
    Task("auditor", AUDITOR_CONTEXT, model=resolve_model("auditor"))
    Read .apex/phases/${current_phase}/${NEXT_UNIT}-AUDIT.md
    If verdict == "FAIL":
      Treat as PARTIAL — task correctness confirmed by critic, but test quality insufficient per auditor.
      "⚠️ Auditor detected test quality issues. Tests need strengthening."
      Log to DECISIONS.md: "Auditor: ${NEXT_UNIT} passed critic but failed test quality audit"
    If verdict == "WARN":
      Log to DECISIONS.md: "Auditor advisory: ${NEXT_UNIT} — minor test quality gaps noted"
      # Advisory only — does not change verdict. Continue.

  ## NEGATIVE AUTH GATE (security tasks only) [R-028]
  Read task from PLAN_META.json for NEXT_UNIT.
  If task.negative_auth_required == true:
    Read RESULT.json tests_run for NEXT_UNIT.
    DENY_PATTERN = grep -iE "deny|unauthorized|forbidden|403|401" in test names
    If zero matches:
      Treat as PARTIAL — task correctness confirmed by critic, but missing negative authorization tests.
      "⚠️ Security task missing negative auth (deny) tests. At least one test must verify unauthorized access is denied."
      Log to DECISIONS.md: "Negative auth gate: ${NEXT_UNIT} passed critic but has no deny tests"

  ## AUTOPILOT STATE UPDATE (on PASS)
  If STATE.autopilot.enabled:
    STATE.autopilot.tasks_completed_in_autopilot++
    STATE.autopilot.last_completed_task = NEXT_UNIT
    STATE.autopilot.last_healthy_tag = TASK_TAG
    STATE.autopilot.consecutive_sessions = 0

    # Mini cross-phase audit every 5 autopilot tasks
    If STATE.autopilot.tasks_completed_in_autopilot % 5 == 0:
      bash ~/.claude/hooks/cross-phase-audit.sh ${STATE.current_phase}
      If regressions found: 
        STATE.autopilot.enabled = false
        STATE.autopilot.was_autopilot = true
        STATE.autopilot.paused_reason = "Regressions detected in mini cross-phase audit"
        "⏸️ Autopilot paused: regressions detected after 5-task audit. Manual review needed."

  # Re-activation offer (if was in autopilot but paused for danger zone)
  If NOT STATE.autopilot.enabled AND STATE.autopilot.was_autopilot:
    If task was D-level or C-level with security/data specialist:
      Read next task from PLAN_META.json
      If next_task.verify_level in ["A", "B"]:
        RENDER: soft frame (Section 3.C) with text:
          "▲  Danger zone passed. Safe tasks ahead.
           Re-enable autopilot?   (y / n)"
        If 'y': STATE.autopilot.enabled = true, STATE.autopilot.was_autopilot = false
               RENDER: Section 9 autopilot transformation banner

  Advance to next unit/wave.

PARTIAL:
  Append P1 notification: "Task [unit] PARTIAL: [N]/[M] criteria verified"
  Advance with advisory logged to DECISIONS.md.

  ## SESSION UPDATE (PARTIAL)
  If STATE.session exists:
    Update STATE.session: tasks_partial++, consecutive_partials++
    bash ~/.claude/hooks/session-log.sh "partial" "משימה ${NEXT_UNIT} — ${N}/${M} קריטריונים עברו"

  "⚠️ PARTIAL: [N]/[M] for [unit]. 'retry' or 'manual' to override, else continuing."

FAIL:
  ATTEMPTS = STATE.reflexion.current_unit_attempts + 1
  STATE.autonomy.by_verify_level[verify_level].consecutive_successes = 0

  ## SESSION UPDATE (FAIL)
  If STATE.session exists:
    Update STATE.session: tasks_failed++, consecutive_failures++
    STATE.session.drift_indicators.reflexion_total_attempts++
    If RESULT.confidence == "low": STATE.session.drift_indicators.low_confidence_results++
    If STATE.circuit_breaker.triggered: STATE.session.drift_indicators.circuit_breaker_triggers++
    bash ~/.claude/hooks/session-log.sh "fail" "משימה ${NEXT_UNIT} נכשלה (ניסיון ${ATTEMPTS}/3)"

  ## DORA FAILURE TRACKING [R-011]
  STATE.dora.phases_failed++
  STATE.dora._last_failure_at = now (ISO 8601)
  If STATE.phases_completed > 0:
    STATE.dora.change_failure_rate = STATE.dora.phases_failed / STATE.phases_completed
  Else:
    STATE.dora.change_failure_rate = 1.0
  STATE.dora.last_updated = now

  ## AUTOPILOT PAUSE ON FAIL
  If STATE.autopilot.enabled:
    STATE.autopilot.enabled = false
    STATE.autopilot.was_autopilot = true
    STATE.autopilot.paused_reason = "Task " + NEXT_UNIT + " FAIL — requires manual intervention"
    "⏸️ Autopilot paused: task failed."

  If ATTEMPTS >= 3:
    "❌ Failed after 3 attempts. Manual intervention needed.
    (1) Fix manually + /apex:next (2) /apex:recover (3) Skip as known limitation"
    STATE.status = "blocked"
    For each level: consecutive_successes = 0. Current level → 0.
  Else:
    STATE.reflexion.current_unit_attempts = ATTEMPTS
    If CRITICAL: STATE.autonomy.by_verify_level[verify_level].level = 0
    "🔄 Reflexion brief written. Retrying ([ATTEMPTS]/3)..."
    STATE.status = "pending_approval"
    ## PIPELINE BYPASS LOGGING [AP-005]
    ## MANDATORY: If you (the orchestrator) applied code changes directly instead of
    ## re-dispatching executor through reflexion→retry, you MUST log this bypass:
    If orchestrator_applied_direct_fix (you wrote code instead of dispatching executor):
      bash ~/.claude/hooks/session-log.sh "bypass" "pipeline-bypass: direct fix for ${NEXT_UNIT} instead of reflexion→retry"

## LEARNING EXTRACTION (on FAIL/PARTIAL only)
If verdict is FAIL or PARTIAL with notable pattern (phantom, test fraud, silent failure):
  Read .apex/phases/${current_phase}/[task]-REFLEXION.md "What Failed" section
  Append verbatim to ~/.claude/apex-learnings.md ## WARM section with timestamp + project tag

Remove lock. Show batched P1/P2 notifications at wave boundaries.

─────────────────────────────────────────────────────────
STATE: current_stage=build, status=verify_needed
─────────────────────────────────────────────────────────

## STRUCTURAL CONTRACT CHECK
Verify .apex/phases/${current_phase}/PLAN_META.json exists.
If missing:
  "⚠️ Structural contract: PLAN_META.json missing from phase ${current_phase} directory."
  bash ~/.claude/hooks/session-log.sh "warning" "Structural contract violation: PLAN_META.json missing in phase ${current_phase}"
Continue — do not block (could be from manual cleanup).

## PHASE VERIFICATION — ADAPTIVE BY COMPLEXITY
COMPLEXITY = STATE.complexity_level

If COMPLEXITY <= 2:
  bash ~/.claude/hooks/cross-phase-audit.sh ${STATE.current_phase}
  PHASE_CRITIC_CONTEXT = {
    phase_spec: .apex/phases/${current_phase}/PLAN_META.json, task_results: all .apex/phases/${current_phase}/*-RESULT.json (status/files/tests only),
    cross_phase_audit: output, diff: "$(git diff apex/phase-[N-1]-complete..HEAD)"
  }
  ## RENDER: Mission Briefing (Section 10-B phase-level critic variant)
  ##   Agent card: CRITIC (Section 10-A)
  ##   "Phase-level review: [N] tasks against phase goal"
  Task("critic", PHASE_CRITIC_CONTEXT + "Phase-level: do all tasks satisfy the phase goal?",
       model=resolve_model("critic"))
  ## RENDER: Flight Recorder (Section 10-C phase-critic variant)
  ##   Body: PHASE VERDICT with task counts + cross-phase audit result
Else:
  ## RENDER: Mission Briefing (Section 10-B variant for verifier)
  ##   Agent card: VERIFIER (Section 10-A)
  ##   "Phase" instead of "Task", "Cross-phase regression check: yes"
  Task("verifier", "Verify phase [phase]. Use PLAN_META.json. Run cross-phase audit.",
       model=resolve_model("verifier"))
  ## RENDER: Flight Recorder (Section 10-C verifier variant)
  ##   Body: PHASE RESULTS — pass/fail counts + cross-phase audit summary
  STATE.tokens.framework_overhead += verifier call tokens

## OVERHEAD CHECK
OVERHEAD_PCT = framework_overhead * 100 / (framework_overhead + productive)
If OVERHEAD_PCT > 15: append P2 notification about overhead.

PASS:
  bash ~/.claude/hooks/phase-tag.sh [phase]

  ## AUTOPILOT PHASE TRACKING
  If STATE.autopilot.enabled:
    STATE.autopilot.phases_completed_in_autopilot++

    ## DRIFT CHECK — mandatory at phase boundaries in autopilot
    Read .apex/phases/${current_phase}/PLAN_META.json
    Count total done_criteria across all tasks. Count verified=false in RESULT.json files.
    UNVERIFIED_RATIO = unverified / total
    If UNVERIFIED_RATIO > 0.20:
      STATE.autopilot.enabled = false
      STATE.autopilot.was_autopilot = true
      STATE.autopilot.paused_reason = "Phase drift: " + (UNVERIFIED_RATIO * 100) + "% criteria unverified (threshold: 20%)"
      STATE.session.drift_indicators.spec_drift_count++
      "⏸️ Autopilot paused: too many unverified criteria at phase boundary. Manual review needed."

  ## RENDER: PHASE COMPLETE CINEMA
  Render Section 8.A from apex-branding.md substituting:
    [N]           → current_phase
    [M] / [M]     → tasks_completed / tasks_total
    Tag           → apex/phase-[N]-complete
    Duration      → sessions · rotations
    Tokens        → productive · overhead
    Tests         → run · passed

  ## SESSION LOG (PHASE COMPLETE)
  If STATE.session exists:
    bash ~/.claude/hooks/session-log.sh "phase_complete" "שלב ${current_phase} הושלם — ${N} משימות, ${STATE.session.tasks_failed} כישלונות"

  ## COMPREHENSION GATE
  STATE.comprehension_gates.current_gate_required = "phase_" + current_phase
  LARGEST_DIFFS = top 3 changed files by diff size since phase start
  Render soft frame (Section 3.C) with:
    "▽  COMPREHENSION GATE — Phase [N]
     Largest changes:
       ● [file1] — [one-sentence explanation]
       ● [file2] — [one-sentence explanation]
       ● [file3] — [one-sentence explanation]
     Does this match your understanding?   (y / explain / skip)"

  'y' → record, mark passed. 'explain' → user writes understanding, record (deep mode).
  'skip' → record, mark skipped. P2: "Cognitive debt risk." NOT available for verify_level D.

  ## COMPREHENSION GATE STATE PERSISTENCE
  If response == 'y' or 'explain':
    STATE.comprehension_gates["phase_" + current_phase] = true
  If response == 'skip':
    STATE.comprehension_gates["phase_" + current_phase] = false
  STATE.comprehension_gates.current_gate_required = null

  "🔄 RECOMMENDED: /apex:resume for fresh context. Or 'continue'."
  'continue' → /compact, advance phase.
  Else → update STATE, STOP.

FAIL/PARTIAL:
  "❌ Phase [N] — [issues]. (1) Fix manually (2) Revert to prior tag + re-plan (3) Mark as limitations"

Show ALL pending notifications at phase boundary. Clear queue.

─────────────────────────────────────────────────────────
## AUTOPILOT ADVISOR
─────────────────────────────────────────────────────────
Triggered when user requests "enable autopilot" (via /apex:next response or /apex:status).

**RENDER**: Output MUST use Section 10 (The Autopilot Advisor Briefing) from
apex-branding.md. Do not output bare text. Fill all placeholders from STEP 1-4 below,
then render the MEGA frame template verbatim with substitutions.

## STEP 1: Gather Data
Read PLAN_META.json for current phase — extract all remaining tasks with verify_level, specialist, dependencies.
Read STATE.json — autonomy ladder, phase history, session drift_indicators.
Read DECISIONS.md — count entries with "unresolved" tag.
Check SPEC.md modification date vs last task completion date.
Count FAIL/PARTIAL ratio in current phase from RESULT.json files.

## STEP 2: Risk Analysis
REMAINING_TASKS = tasks not yet completed in current phase
A_COUNT = count where verify_level == "A"
B_COUNT = count where verify_level == "B"
C_COUNT = count where verify_level == "C"
D_COUNT = count where verify_level == "D"
SECURITY_COUNT = count where specialist in ["security", "data"]
RISK_SCORE = (D_COUNT * 4 + C_COUNT * 2 + B_COUNT * 1) / REMAINING_TASKS.length

PREV_PHASE_FAIL_RATIO = (tasks_failed + tasks_partial) / tasks_total in previous phase
SPEC_RECENTLY_MODIFIED = SPEC.md modified within last 24 hours
UNRESOLVED_DECISIONS = count of "unresolved" in DECISIONS.md
PHASES_COMPLETED_MANUALLY = total phases - autopilot.phases_completed_in_autopilot

## STEP 3: Build Danger Map
SAFE_ZONES = consecutive sequences of A/B tasks
DANGER_ZONES = consecutive sequences containing D or C_security/C_data tasks
For each zone: list task IDs, verify_levels, specialist types

## STEP 4: Determine Recommendation
If D_COUNT == 0 AND RISK_SCORE < 1.5 AND PREV_PHASE_FAIL_RATIO < 0.20
   AND NOT SPEC_RECENTLY_MODIFIED AND UNRESOLVED_DECISIONS == 0
   AND PHASES_COMPLETED_MANUALLY >= 1:
  RECOMMENDATION = "GREEN — Full autopilot recommended"

Else if D_COUNT > 0 OR SECURITY_COUNT > 0:
  RECOMMENDATION = "YELLOW — Conditional autopilot recommended"
  SUGGESTED_MODE = "smart" (or "until" if danger is contiguous block)

Else if PREV_PHASE_FAIL_RATIO > 0.30 OR PHASES_COMPLETED_MANUALLY == 0
   OR SPEC_RECENTLY_MODIFIED:
  RECOMMENDATION = "RED — Autopilot not recommended"

## STEP 5: Present Briefing (in user's configured language)
Display:
"🤖 AUTOPILOT ADVISOR — Phase [N] Analysis

RECOMMENDATION: [GREEN/YELLOW/RED] — [summary]

[For each zone:]
[SAFE/DANGER] ZONE (tasks [start]-[end]): [verify_levels], [specialists]
  → [recommendation for this zone]

CONCERNS: [numbered list of specific risks found]

RISK SCORE: [N] (scale: 0=safe, 4=max risk)
TRACK RECORD: [FAIL/PARTIAL ratio] in previous phase
SPEC STABILITY: [stable / modified recently]
UNRESOLVED DECISIONS: [N]

OPTIONS:
(1) Full autopilot — all tasks [recommended/not recommended]
(2) Autopilot until [first danger task], then manual [if applicable]
(3) Manual for [danger zone], then autopilot after [if applicable]
(4) Smart autopilot — auto-pause before D/C-security/C-data tasks ← [RECOMMENDED if yellow]
(5) Custom range — specify start/end tasks
(6) No autopilot — continue manual mode"

User selects option → set STATE.autopilot accordingly:
  (1) → mode: "full", enabled: true
  (2) → mode: "until", stop_at_task: [first danger task], enabled: true
  (3) → mode: "after", start_at_task: [first safe task after danger], enabled: false
  (4) → mode: "smart", auto_pause_on: ["D", "C_security", "C_data"], enabled: true
  (5) → mode: "range", range_start/range_end from user input, enabled: true
  (6) → no change

STATE.autopilot.advisor_last_run = now
STATE.autopilot.advisor_risk_score = RISK_SCORE

─────────────────────────────────────────────────────────
STATE: current_stage=complete
─────────────────────────────────────────────────────────

## RENDER: PROJECT COMPLETE CEREMONY
Render Section 15 (Project Complete Ceremony) from ~/.claude/apex-branding.md.
Substitute ALL placeholders from STATE.json:
  ACHIEVEMENTS   phases · tasks · critic reviews · debates · learnings
  QUALITY        evoscore regression · comprehension gates · mutation kill rate · audits
  ECONOMICS      total tokens · productive % · overhead % · cost · savings · cache hit
  FLIGHT LOG     sessions · rotations · autopilot tasks · manual interventions
End with signature line (Section 3.E).
</context>