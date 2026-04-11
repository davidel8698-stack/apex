---
description: Full ceremony pipeline execution — all planning, review, and verification steps.
---

<context>
Task from $ARGUMENTS.

## PURPOSE
Explicit entry point for the full APEX pipeline with maximum ceremony.
This is the top tier of the three-tier ceremony pyramid: fast / quick / full.

## GUARD
If no .apex/STATE.json: "❌ No APEX project. Run /apex:start first." STOP.
If $ARGUMENTS is empty: "❌ /apex:full requires a task description." STOP.

## EXECUTION
This command is a direct invocation of the full /apex:next pipeline.
All steps execute without shortcuts:
  - Full planning (architect + PLAN_META)
  - Full execution (executor with specialist support)
  - Full review (critic, clean-room, cross-model)
  - Full verification (verifier for C/D, phantom check, mutation gate)
  - Full session tracking (checkpoints, DORA, autopilot)

Run /apex:next with the task from $ARGUMENTS.
All pipeline stages apply. No ceremony is skipped.

NOTE: For trivial tasks (rename, typo fix) → use /apex:fast.
For small tasks (single feature, one file) → use /apex:quick.
Use /apex:full for multi-file features, architectural changes, or anything requiring full verification.
</context>
