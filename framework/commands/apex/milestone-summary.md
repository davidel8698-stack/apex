---
description: Aggregate milestone report with DORA metrics and proof-of-process.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
Generates a comprehensive milestone report aggregating all phase results, DORA metrics,
and proof-of-process data. Provides delivery visibility and stakeholder-ready output.

## GUARD
If no .apex/STATE.json: "❌ No APEX project. Run /apex:start first." STOP.
Read STATE.json → phases, dora metrics.
If no completed phases exist: "❌ No completed phases. Nothing to summarize." STOP.

## DATA COLLECTION

1. **Phase Results:** For each directory in `.apex/phases/*/`:
   - Read `SUMMARY.md` (if exists) → extract verdict, key changes, issues found
   - Read `PLAN_META.json` → extract task count, verify_levels, created_at
   - Read all `*-RESULT.json` → extract status (pass/fail/partial), tests_run counts
   - Count: total tasks, passed, failed, partial

2. **DORA Metrics:** Read STATE.json:
   - `dora.lead_time_avg` — average hours from plan to completion
   - `dora.deployment_freq` — phases completed per day
   - `dora.change_failure_rate` — percentage of phases that failed
   - `dora.recovery_time_avg` — average hours from failure to recovery

   **M18.1 DORA quartet from git log (additive to STATE-derived DORA above):**
   Before rendering, refresh `.apex/DORA.json` from the git-log engine:

   ```
   bash framework/hooks/dora-collect.sh 2>/dev/null || true
   ```

   (Best-effort; if the hook is unavailable or the repo has no commits the
   command falls through to the existing STATE-derived DORA section without
   blocking the summary.)

   Then, if `.apex/DORA.json` exists and is valid JSON, read:
   - `.deployment_frequency.deploys_per_week` — DF (per-week rate)
   - `.deployment_frequency.deploys_in_window` — DF (raw count)
   - `.lead_time.median_seconds` — LT (median, with sample_size)
   - `.change_failure_rate.ratio` — CFR (per-commit proxy; numerator/denominator surfaced inline)
   - `.mean_time_to_restore.median_seconds` — MTTR (median, with sample_size)

   These are rendered as a second DORA block ("DORA quartet — measured")
   under the existing STATE-derived block. Methodology, committed definitions,
   and heuristic limitations live in `framework/docs/CLAIMS-MEASUREMENT.md`
   §"DORA measurement engine".

3. **Timeline:** 
   - `STATE.created_at` → project start
   - Current timestamp → elapsed time
   - Phase start/end times from PLAN_META.json created_at fields

4. **Quality Signals:**
   - Count critic verdicts (pass/fail/partial) across all CRITIC.md files
   - Count auditor findings across all AUDIT.md files
   - Count DECISIONS.md entries by type

## REPORT FORMAT

```
═══════════════════════════════════════════════
  APEX MILESTONE SUMMARY
  Project: {project_name}
  Generated: {timestamp}
═══════════════════════════════════════════════

📊 DELIVERY METRICS
  Phases completed:     {N}
  Tasks executed:       {N} ({passed} pass, {failed} fail, {partial} partial)
  Elapsed time:         {N}d {N}h
  
📈 DORA METRICS
  Lead time (avg):      {N}h per phase
  Deployment frequency: {N} phases/day
  Change failure rate:  {N}%
  Recovery time (avg):  {N}h

📐 DORA QUARTET — MEASURED (M18.1, git-log engine)
  Window:               {window_days}d
  Deployment frequency: {deploys_per_week}/wk ({deploys_in_window} in window)
  Lead time (median):   {lt_median_seconds}s (n={lt_sample_size})
  Change failure rate:  {cfr_ratio} ({cfr_numerator}/{cfr_denominator}, per-commit proxy)
  MTTR (median):        {mttr_median_seconds}s (n={mttr_sample_size})
  Method:               framework/docs/CLAIMS-MEASUREMENT.md §"DORA measurement engine"

🔍 QUALITY SIGNALS
  Critic pass rate:     {N}%
  Auditor findings:     {N} total ({N} resolved)
  Decisions recorded:   {N}

📋 PHASE BREAKDOWN
  Phase {id}: {verdict} — {summary} ({N} tasks, {elapsed})
  ...

═══════════════════════════════════════════════
```

## OUTPUT

Write report to `.apex/MILESTONE-SUMMARY.md`.
Display report to user.

"📊 Milestone summary generated → .apex/MILESTONE-SUMMARY.md"

## ERROR HANDLING
- If a phase directory has no SUMMARY.md: show as "Phase {id}: No summary available"
- If DORA metrics are null: show as "N/A (insufficient data)"
- If PLAN_META.json is missing in a phase: skip that phase with warning
- If `.apex/DORA.json` is missing OR `dora-collect.sh` exits non-zero:
  render the "DORA QUARTET — MEASURED" block as `N/A (insufficient git
  history)` for every field and surface a one-line footnote citing
  `framework/docs/CLAIMS-MEASUREMENT.md` for definitions. The existing
  STATE-derived DORA block above stays unchanged.
</context>
