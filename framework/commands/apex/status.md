---
description: Current project status with token tracking and context health.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## STATUS VIEW SELECTION [M11 / Phase 12.07]
Resolve which view to render in this order:

1. **Argument scan.** If the invocation includes `--verbose` →
   STATUS_VIEW="verbose". If it includes `--detailed` →
   STATUS_VIEW="detailed". Otherwise STATUS_VIEW="default".
2. **User-preference override.** If `.apex/STATUS_PREFS.json` exists
   and its `default_view` field is one of `default | detailed |
   verbose`, and the invocation did NOT pass a `--verbose` /
   `--detailed` flag, set STATUS_VIEW to the preference.
   **CLI flag always wins over saved preference** (this rule resolves
   the precedence ambiguity — `--verbose` overrides a saved
   `default_view: "default"`, never the reverse).
3. **Auto-surface on anomaly.** When STATUS_VIEW=="default" AND
   ANY of the following hold, promote STATUS_VIEW to "detailed"
   and append an `🔔 anomaly auto-surfaced` line at the top of the
   output. The promotion is persistent for THIS invocation only.
   - `STATE.session.drift_indicators.spec_drift_count > 0`
   - `STATE.session.drift_indicators.circuit_breaker_triggers > 0`
   - `STATE.session.drift_indicators.low_confidence_results > 0`
   - `STATE.session.consecutive_failures > 0`
   - `STATE.quality.current_drift_pct > 5` when M16 wires this field
   - Most-recent event-log.jsonl entry has `severity == "CRITICAL"`
     (M10 / Phase 12.06 wires the severity tier).
4. **Render branch.**
   - STATUS_VIEW=="default" → render the **5-SIGNAL DEFAULT VIEW**
     block below ONLY. Skip the full cockpit + context health
     blocks entirely.
   - STATUS_VIEW=="detailed" → render the 5-signal header AS A
     SUMMARY, then the Context Health block, then the cockpit (full
     autonomy ladder + DORA + autopilot panels). Skip the LEARNINGS
     LIVING-EVIDENCE deep block.
   - STATUS_VIEW=="verbose" → render everything, as today (no
     change from pre-M11 behavior).

## 5-SIGNAL DEFAULT VIEW (M11)
When STATUS_VIEW=="default", emit ONLY these 5 lines (no frame,
plain ASCII, ≤80 cols). Each maps to a STATE.json field; missing
fields render `N/A`.

```
Phase {STATE.current_phase}/{STATE.phases_total} — {phase_goal_from_PLAN.md_first_line_or_dash}
Autonomy: {autonomy_label}   ({autonomy_reason})
Task: {STATE.current_unit} — {task_status_label}
Last verify: {last_verdict_label}   ({verify_link_or_dash})
Context: {gauge_pct}% {gauge_glyph}   ({gauge.status_label})
```

Field resolution:
- `phase_goal_from_PLAN.md_first_line_or_dash` — grep the first
  `## Phase goal` line from `.apex/phases/{current_phase}/PLAN.md`
  if present; otherwise `—`.
- `autonomy_label` — derive from `STATE.autonomy.by_task_class` if
  present, else `by_verify_level`. Format: `Trusted for {class}
  ({consecutive_successes} clean)` when level>=1; `Supervised
  ({class})` when level==0.
- `autonomy_reason` — one-line plain-language summary
  ("8 clean B-runs", "permanent Supervised — Track C", etc.).
- `task_status_label` — derive from `STATE.status` mapped to
  plain language: `active` → `Building`, `critic_needed` →
  `Reviewing`, `pending_approval` → `Waiting for review`,
  `blocked` → `Blocked`, etc.
- `last_verdict_label` — read the most recent
  `.apex/phases/*/[unit]-CRITIC.md` `Verdict:` line, fallback to
  `—`.
- `gauge_pct`, `gauge_glyph`, `gauge.status_label` — read from the
  same `context-monitor.sh --health-json` call documented in the
  CONTEXT HEALTH BLOCK section below.

If the auto-surface trigger fired in step 3, prepend a single
`🔔 anomaly auto-surfaced: {reason_string}` line before the 5
signals AND fall through to STATUS_VIEW=="detailed" rendering
(skip back to the cockpit block).

After the 5 signals (and only when STATUS_VIEW=="default"), append
one tip line: `(run /apex:status --detailed for the full panel)`.
Then skip directly to the signature line. Do NOT render the Context
Health block, the Cockpit, the Glass Cockpit header, or the
inline-hint block.

## STATUS_PREFS.json (optional, M11)
Format: `{ "default_view": "default" | "detailed" | "verbose" }`.
Location: `.apex/STATUS_PREFS.json`. The file is OPTIONAL; absence
means STATUS_VIEW resolution falls through to argument scan +
anomaly detection. Schema-wise, the file is treated as a free-form
JSON object with one known key; unknown keys are ignored.

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
Adapt dashboard commentary (per `framework/docs/PLAIN-LANGUAGE-MAPPING.md` — plain language first, technical term in parens):
- non-programmer: after each metric section, add a plain-language sentence explaining what it means and whether it's good or bad. Replace bare jargon labels with plain-language form (e.g., "code-evolution score (EvoScore)", "delivery metrics (DORA)", "test-strength score (mutation kill rate)", "hands-off mode (autopilot)").
- junior: add brief tooltips for non-obvious metrics (EvoScore, DORA, mutation kill rate)
- senior/architect: display raw metrics only (current behavior)

## CONTEXT HEALTH BLOCK (R13-006 — RENDER ABOVE COCKPIT)
Render the R2-C212 eight-metric Context Health block BEFORE the Cockpit
Dashboard. This is the primary user-inspection summary per "First-hour
usability" (apex-spec.md axis 4) and R2-C213 (user-facing indicators).
The block is ADDITIVE — existing cockpit sections (autonomy ladder,
DORA, autopilot, learnings, session health) remain UNCHANGED below.

### Data source
Invoke `bash ~/.claude/hooks/context-monitor.sh --health-json` to obtain
the 8-metric JSON snapshot. The output validates against
`~/.claude/schemas/HEALTH_METRICS.schema.json`. Parse the JSON with `jq`.

For the stale-reference rate row, invoke
`bash ~/.claude/hooks/verify-learnings.sh 2>/dev/null` and `grep` for
the `APEX_HEALTH_JSON {...}` line, then `jq -r .stale_reference_rate`.

### Terminal-capability detection (color vs text fallback)
Before rendering, run `tput colors 2>/dev/null || echo 0`. If the
result is `0` or `8` or empty (or `$NO_COLOR` is set), render text
labels `[OK]`, `[WARN]`, `[CRIT]`, `[N/A]`, `[UNMEASURED]` in place of
the color glyphs 🟢 / 🟡 / 🔴 / ⚪. The 8 metric lines themselves are
plain ASCII (tree-drawing characters ├── └── are NOT colored). RTL
terminals (Hebrew session) render text labels by default to avoid
ANSI-bidi corruption.

### Render template (substitute placeholders from health-json output)
Print 8 metric lines plus a header. The exact form is:
```
Context Health: {gauge_glyph} {gauge.pct}% (target {gauge.target_pct}%, hard {gauge.hard_pct}%)
├── Budget by zone:    stable_prefix {sp.used/1000}K/{sp.budget/1000}K · task_context {tc.used/1000}K/{tc.budget/1000}K · working_memory {wm.used/1000}K/{wm.budget/1000}K · gen_reserve {gr.reserved/1000}K (reserved)
├── Cache efficiency:  {cache_label} ({cache.hit_rate_pct}% hit rate, {cache.hits} hits / {cache.calls} calls)
├── Last rotation:     {last_rotation.at} ({last_rotation.ago_minutes} min ago) — {last_rotation.reason}
├── Last mask:         {last_mask.at} ({last_mask.ago_minutes} min ago) — {last_mask.blocks_masked} stale tool-results
├── Drift indicators:  ▢ spec={drift.spec_drift_count}  ▢ cb={drift.circuit_breaker_triggers}  ▢ reflexion={drift.reflexion_attempts}/{drift.reflexion_attempts_max}  ▢ low_conf={drift.low_confidence_results}
├── Quality (rolling): {quality.status_label}
└── ALERTS:            {alerts | join(", ") | "none" if empty}
```

### Stub-rendering rules (R13-006 acceptance criteria)
- `gauge.status == "unmeasured"` (pre-R12-001 STATE, total_input=0):
  render `Context Health: 🟡 unmeasured (run /apex:next to wire counter)`
  and OMIT the percentage / threshold tail.
- `gauge.status == "ok"`: glyph 🟢 (or `[OK]` in text mode).
- `gauge.status == "warn"`: glyph 🟡 (or `[WARN]`).
- `gauge.status == "crit"`: glyph 🔴 (or `[CRIT]`).
- `cache_efficiency.status == "n/a"`: render "Cache efficiency:  n/a"
  (cache adapter does not report cache_hits/cache_writes).
- `last_rotation.at == null`: render "Last rotation:     never".
- `last_mask.at == null`: render "Last mask:         never".
- `quality_rolling.status == "n/a"`: render
  "Quality (rolling): n/a (Phase 12 M16 pending)".
- `alerts == []`: render "ALERTS:            none".

### Existing-sections regression invariant
The Cockpit Dashboard rendering below (autonomy ladder, DORA, autopilot,
learnings, session health, token economy) MUST still render verbatim.
The Context Health block is PREPENDED; nothing is removed.

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

  AUTO-CONTINUITY [v7.1] (only render if STATE.session.memory exists AND samples_taken > 0):
    Memory bar: 20-char bar from STATE.session.memory.working_set_pct (commit relative to threshold)
    Bun memory: STATE.session.memory.commit_mb MB / threshold MB
    High-water mark: STATE.session.memory.high_water_mark_mb MB
    Samples taken this session: STATE.session.memory.samples_taken
    If consecutive_over_threshold > 0: render warning hint "⚠ N consecutive samples over threshold — auto-pause approaching"
    Turn checkpoint (only render if STATE.turn_checkpoint.ts not null):
      Last checkpoint: STATE.turn_checkpoint.ts (humanized as "N min ago")
      Task: STATE.turn_checkpoint.task_id @ tool call STATE.turn_checkpoint.tool_call_index
      Last completed tool: STATE.turn_checkpoint.last_completed_tool
    If STATE.session.auto_paused == true: render auto-pause banner above cockpit:
      "🛑 Auto-paused: STATE.session.auto_pause_reason — run /apex:resume to continue."

  AUTOPILOT:
    State: ENABLED/DISABLED/PAUSED from STATE.autopilot.enabled and paused_reason
    Mode from STATE.autopilot.mode
    Tasks/phases in autopilot
    Consecutive sessions from STATE.autopilot.consecutive_sessions
    Previous last completed task from STATE.autopilot.previous_last_completed_task
    Previous tasks completed in autopilot from STATE.autopilot.previous_tasks_completed_in_autopilot
    Advisor risk score from STATE.autopilot.advisor_risk_score

  SELF-HEAL LOOP (only render if STATE.self_heal exists AND status != "idle"):
    Status from STATE.self_heal.status (running/paused/closed/halted)
    Round R[STATE.self_heal.current_round]
    Step from STATE.self_heal.current_step
    If current_step == "execute" AND current_wave != null: "Wave [current_wave]"
    Consecutive clean rounds: STATE.self_heal.consecutive_clean_rounds / 2 (target)
    Last P0+P1 count: STATE.self_heal.last_p01_count or "—"
    Max rounds: STATE.self_heal.max_rounds
    Started: STATE.self_heal.started_at (humanized)
    If last_round_artifacts present: list paths under "Last round artifacts"
    Render in a soft frame (Section 3.C) below the cockpit, before the signature line.

  LEARNINGS:
    HOT bar from hot_count/30
    WARM bar from warm_count/100
    COLD count

## RENDER
Output the Cockpit Dashboard from Section 6 of apex-branding.md with all values substituted.
Follow with the signature line.

## INLINE HINT (below signature)
If autopilot is disabled: add rounded frame (Section 3.C) with:
  "Say 'enable hands-off mode (autopilot)' to run the Advisor (Section 10)."
If autopilot is enabled: add active badge from Section 9.
If autopilot is paused: add paused badge from Section 9.
</context>
