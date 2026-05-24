---
description: Start new APEX project.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## ADAPTER HONESTY BANNER [R6-017]
## Spec anchors: "Multi-platform from day one." + "Honest scope over marketing scope." + "Honestly Scoped, Not Universally Promised."
## Runtime propagation of manifest-level honesty: when running on a
## non-canonical adapter (hook_protocol.supported != "full"), the user
## must be told which APEX behavioral guarantees are deferred on this
## host. One-time per project — suppressed by STATE.adapter_honesty_shown.
```bash
# Resolve framework root for adapter manifest reads.
APEX_FW_ROOT="${APEX_FW_ROOT:-$HOME/.claude}"
ADAPTER_DETECT="$APEX_FW_ROOT/hooks/_adapter-detect.sh"
if [ -f "$ADAPTER_DETECT" ]; then
  ACTIVE_ADAPTER=$(bash "$ADAPTER_DETECT" active 2>/dev/null || echo "claude-code")
else
  ACTIVE_ADAPTER="claude-code"
fi
ADAPTER_MANIFEST="$APEX_FW_ROOT/adapters/$ACTIVE_ADAPTER/adapter.json"
ALREADY_SHOWN=$(jq -r '.adapter_honesty_shown // false' .apex/STATE.json 2>/dev/null || echo "false")
if [ -f "$ADAPTER_MANIFEST" ] && [ "$ALREADY_SHOWN" != "true" ]; then
  HOOK_SUPPORT=$(jq -r '.hook_protocol.supported // "full"' "$ADAPTER_MANIFEST" 2>/dev/null)
  if [ "$HOOK_SUPPORT" != "full" ]; then
    DEFERRED_LIST=$(jq -r '.deferred // [] | join(", ")' "$ADAPTER_MANIFEST" 2>/dev/null)
    DISPLAY_NAME=$(jq -r '.display_name // .platform // "this adapter"' "$ADAPTER_MANIFEST" 2>/dev/null)
    echo ""
    echo "⚠️  APEX SCOPE-HONESTY BANNER"
    echo "   Active adapter: $DISPLAY_NAME (hook_protocol.supported = $HOOK_SUPPORT)"
    echo "   Out-of-scope on this platform: $DEFERRED_LIST"
    echo "   Behavioral guarantees that depend on hooks (destructive-guard,"
    echo "   prompt-guard, schema-drift, phantom-check, ...) are NOT enforced"
    echo "   on $DISPLAY_NAME until the host exposes a comparable primitive."
    echo "   See framework/adapters/$ACTIVE_ADAPTER/adapter.json + framework/docs/MULTI-PLATFORM.md."
    echo ""
    # One-time suppression: set the flag in STATE.json.
    if [ -f .apex/STATE.json ]; then
      tmp=".apex/STATE.json.banner.tmp"
      jq '.adapter_honesty_shown = true' .apex/STATE.json > "$tmp" && mv "$tmp" .apex/STATE.json
    fi
  fi
fi
```

## TELEMETRY NOTIFICATION [M16.1 / Phase 12.09 / User Decision #3]
## Spec anchors: "Honest scope over marketing scope." + "Honestly Scoped, Not Universally Promised." + User Decision #3 (opt-out from start).
## One-time, per-project notification surfaced on first /apex:start run.
## Idempotent — suppression via `.apex/telemetry-notification-shown.flag`.
```bash
TELEMETRY_FLAG=".apex/telemetry-notification-shown.flag"
if [ ! -f "$TELEMETRY_FLAG" ]; then
  echo ""
  echo "🔒 APEX collects anonymous, numeric quality counters locally to"
  echo "   validate context-preservation claims. No code, paths, names, or"
  echo "   commit messages are ever collected. Data lives in"
  echo "   .apex/telemetry.jsonl (project-local — no remote upload in v0.1.x)."
  echo "   Opt out: export APEX_TELEMETRY=off   (per-session)"
  echo "        OR: touch ~/.claude/telemetry-opt-out.flag   (persistent)"
  echo "   Full policy: framework/docs/PRIVACY-POLICY.md"
  echo ""
  echo "🔒 APEX אוסף מוני איכות מספריים אנונימיים באופן מקומי כדי לאמת"
  echo "   טענות לגבי שימור הקשר. אין איסוף של קוד, נתיבים, שמות או"
  echo "   הודעות commit. הנתונים נשמרים ב-.apex/telemetry.jsonl בלבד"
  echo "   (מקומי לפרויקט — ללא העלאה מרחוק בגרסה v0.1.x)."
  echo "   ביטול הסכמה: export APEX_TELEMETRY=off   (לסשן נוכחי)"
  echo "          או:   touch ~/.claude/telemetry-opt-out.flag   (קבוע)"
  echo "   המדיניות המלאה: framework/docs/PRIVACY-POLICY.md"
  echo ""
  mkdir -p .apex 2>/dev/null
  touch "$TELEMETRY_FLAG" 2>/dev/null || true
fi
```

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

## DATE PARSER PREFLIGHT [R3-009] — catches silent DORA / learning-staleness degradation on Windows without Python
DATE_SELFTEST=$(bash ~/.claude/hooks/_date-parse.sh 2>&1)
case "$DATE_SELFTEST" in
  "OK "*)
    # Parser functional (gnu-date, bsd-date, python3, or python2). Continue silently.
    ;;
  "FAIL "*)
    echo "🚫 APEX PRECHECK FAILED — date parser unavailable"
    echo "   $DATE_SELFTEST"
    echo "   Why this matters: DORA metrics (lead_time_avg, deployment_freq) and"
    echo "   learning-staleness checks will silently produce empty data without this."
    echo "   Fix (Linux): GNU coreutils provides 'date -d' — install with apt/yum/dnf if missing."
    echo "   Fix (macOS): BSD 'date -j -f' is built-in — a FAIL here is unusual; check shell PATH."
    echo "   Fix (Windows Git Bash): install Python 3 from https://python.org and restart shell."
    STOP.
    ;;
  *)
    echo "⚠️ Date parser selftest returned unexpected output — continuing, but run /apex:health-check."
    ;;
esac

## INFRASTRUCTURE SELF-TEST
bash ~/.claude/scripts/self-test.sh 2>&1
EXIT=$?
# R9-014: three-arm exit-code branching so consumers do not mis-frame
# exit 99 (counters inconsistent — runner-aggregate guard fired) as
# "$EXIT test(s) failed". Spec anchor: "Fail-loud, never fail-silent"
# without "fail-loud-incorrectly".
case "$EXIT" in
  0)
    : "infrastructure clean — no banner needed."
    ;;
  99)
    echo "⚠️ APEX runner counters inconsistent (exit 99) — diagnose with: bash ~/.claude/scripts/self-test.sh 2>&1 | grep 'counters inconsistent'. Run /apex:health-check."
    ;;
  *)
    echo "⚠️ APEX infrastructure degraded — $EXIT test(s) failed. Run /apex:health-check."
    ;;
esac

Check .apex/STATE.json. If exists: "Project in progress. /apex:next or /apex:resume." Stop.

If no:
  0. Render Section 5 banner with [●] for completed steps, [◐] for active, [○] for pending.
  1. mkdir -p .apex/{pre-build,phases,backups,debate-log,roundtable-log,comprehension-gates,todos,threads,seeds,backlog}
     touch .apex/event-log.jsonl

  ## MEMORY PRIMITIVE SCAFFOLDING [R5-022]
  1a. Create the four memory primitive directories explicitly and pin them in
      git with `.gitkeep` markers, so absence of any of these dirs later
      signals a broken state (not "unused"). Per spec: "ארבעה primitives:
      `apex/todos/`, `apex/threads/`, `apex/seeds/`, `apex/backlog/`."
      ```bash
      mkdir -p .apex/todos .apex/threads .apex/seeds .apex/backlog
      touch .apex/todos/.gitkeep .apex/threads/.gitkeep .apex/seeds/.gitkeep .apex/backlog/.gitkeep
      ```
      Note: `thread.md`, `plant-seed.md`, and `add-backlog.md` retain their
      defensive `mkdir -p` calls as belt-and-braces — preservation contract.

  ## TWO-TIER METHODOLOGY SETUP
  1b. Copy ~/.claude/APEX-TEMPLATE.md to .apex/APEX.md
  1c. Copy ~/.claude/PROJECT-APEX-TEMPLATE.md to .apex/PROJECT-APEX.md
      Substitute [PROJECT_NAME] with project directory name.

  ## HOOK REGISTRATION DEPLOYMENT
  1d. Copy ~/.claude/settings.json to .claude/settings.json in the target project root.
      If .claude/settings.json already exists, read existing content, merge each
      event bucket (.hooks.PreToolUse[] and .hooks.PostToolUse[]) — append any
      entries from the template that are not already present (match by the
      nested `.hooks[].command` field), and write back. Do not overwrite
      user-defined hooks or permissions.

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

  ## STATE MANAGEMENT ARCHITECTURE (C-001 resolution)
  When generating .apex/APEX.md, include the following section:

  ```
  ## State Management Architecture

  APEX uses structured JSON + Markdown as source of truth, with
  `.apex/event-log.jsonl` as the queryable event stream for temporal
  queries, provenance tracking, and timeline reconstruction.

  Every state mutation (_state-update.sh) and session event (session-log.sh)
  appends a structured JSONL line with timestamp, source, and details.

  Query examples:
  - Last 10 events: `tail -10 .apex/event-log.jsonl | jq .`
  - All failures: `jq -s '[.[] | select(.event=="fail")]' .apex/event-log.jsonl`
  - State changes by hook: `jq -s '[.[] | select(.source=="circuit-breaker")]' .apex/event-log.jsonl`
  - Events since date: `jq -s '[.[] | select(.ts > "2026-04-01")]' .apex/event-log.jsonl`

  Migration path: JSONL is directly importable to SQLite+FTS5 when
  framework-level query needs exceed jq capabilities. The structured
  format ensures zero data loss during migration.
  ```

  ## USER PROFILE CAPTURE [R6-006]
  ## PROPOSALS_MODE-compliant: numbered proposals, NOT open-ended questions.
  2. Present numbered proposals to the user (in detected language or default English).

     2.a Technical level — present this 4-option proposal verbatim
         (one line, mirroring the SCOPE WARNING format):

         "Your technical level?  (1) Non-programmer [recommended]   (2) Junior   (3) Senior   (4) Architect
          Select (1-4) or press Enter for [recommended]:"

         Map response to STATE field tech_level:
         (1) → "non-programmer"   (2) → "junior"   (3) → "senior"   (4) → "architect"
         Enter / no response → "non-programmer" (the [recommended] default).

     2.b Communication language — present this 3-option proposal verbatim
         (one line, mirroring the SCOPE WARNING format):

         "Your preferred language?  (1) Hebrew + English tech terms [recommended]   (2) English only   (3) Other (specify)
          Select (1-3) or press Enter for [recommended]:"

         Map response to STATE field language:
         (1) → "he+en"   (2) → "en"
         (3) → prompt user once for free-text language code, store as-is.
         Enter / no response → "he+en" (the [recommended] default).

     Write tech_level and language into CLAUDE.md ## User Profile section
     (from CLAUDE-TEMPLATE.md). USER_LANG = captured language preference.

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
     tokens: {total_input: 0, total_output: 0, framework_overhead: 0, overhead_pct: 0, productive: 0, cache_hits: 0, cache_writes: 0, session_start_at: null, session_baseline_total: 0, by_phase: {}, by_agent: {}, by_task: {}}  # R12-001 — cache_hits/cache_writes/session_start_at/session_baseline_total mirror STATE-init.template.json + STATE.schema.json (three-place contract)
     phase_tags: {}
     stack_skills: []                     # For React+Vite/Next UI projects, the architect will add "pinscope" here (per its STEP 0). The pinscope skill teaches downstream agents about Pin IDs / Operations / PinMap; the frontend specialist + /apex:ui-phase consume it to install + use PinScope (default visual-debug HUD per CLAUDE.md PinScope sub-project section).
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
     circuit_breaker: {consecutive_no_change_actions: 0, max_allowed: 3, total_tool_calls_this_task: 0, max_tool_calls_per_task: 80, last_file_hash: null, triggered: false, trigger_reason: null, cap_original: 80, cap_extensions_used: 0, tool_calls_at_last_change: 0, last_warning_threshold: 0}
     snapshots: {pre_task_stash: null, last_snapshot_task: null}
     quality: {rolling_window_tasks: [], baseline_window_tasks: [], current_drift_pct: 0, alert_threshold_pct: 5, baselined_at_phase: null, tasks_since_rebaseline: 0}  # M16 (Phase 12.09) — quality drift instrumentation; three-place contract with STATE.schema.json + STATE-init.template.json
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
  ## THREAT-MODEL BOOTSTRAP [R5-020] — project-specific, re-runnable
  ## Spec anchor: "`THREAT_MODEL.md` per-project עם Indirect Prompt Injection כאיום ברירת מחדל."
  5. Invoke the security specialist in threat-model-bootstrap mode to
     produce `.apex/THREAT_MODEL.md` from
     `~/.claude/THREAT_MODEL-TEMPLATE.md`. This is re-runnable: if
     `.apex/THREAT_MODEL.md` already exists, the agent writes a merge
     proposal to `.apex/THREAT_MODEL.proposed.md` instead of
     overwriting (preservation contract). Otherwise it scaffolds
     `.apex/THREAT_MODEL.md` directly.

     Default-on threat: the produced file MUST contain
     "Indirect Prompt Injection" verbatim — strip-resistant by spec.

     Bootstrap flow:
     - If `.apex/THREAT_MODEL.md` exists → propose merge, do NOT
       overwrite.
     - Else → copy template to `.apex/THREAT_MODEL.md`, substitute
       `[PROJECT_NAME]` (project directory name), `[DATE]` (current
       date), `[DETECTED_STACK]` ("TBD — updated after Phase 0" until
       planner Phase 0 completes).
     - Tailor the Stack-Specific Threats section to the detected stack
       (drop irrelevant T-1xx/T-2xx/T-3xx subsections).
     - Populate at least one Project-Specific Threat (T-4xx) from
       captured project context.

     Invocation (prose form to preserve R5-001 Task(...) invocation
     count invariant): run the security specialist agent in
     threat-model-bootstrap mode. Pass it the project root ($PWD), the
     source template path (~/.claude/THREAT_MODEL-TEMPLATE.md), and
     the target path (.apex/THREAT_MODEL.md). The default threat
     "Indirect Prompt Injection" must be preserved verbatim. Re-run
     guard: if target already exists, the agent writes a proposal to
     .apex/THREAT_MODEL.proposed.md and stops.

     Fallback (security agent unavailable): copy
     `~/.claude/THREAT_MODEL-TEMPLATE.md` to `.apex/THREAT_MODEL.md`
     with the same substitutions and continue. The template already
     contains "Indirect Prompt Injection" as T-001, so the default
     threat is preserved even via the fallback path.
  6. bash ~/.claude/hooks/session-log.sh "start" "סשן התחיל — [project name]"
  7. Task("planner", "Project root: $PWD. Run Phase 0 auto-detection first. Classify this project, capture requirements, and generate pre-build checklist if Level 3+.")
  8. After planner:
     Read STATE.json complexity_level and complexity_name.
     Display: "Preset: [complexity_name] (Level [complexity_level])"
     Level 3+: Update STATE: {current_stage: "pre-build", status: "blocking"}
     Else:     Update STATE: {current_stage: "spec", status: "pending_approval"}
</context>