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
</context>
