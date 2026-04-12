---
description: Build pipeline for creating new features. Distinct from /apex:refine.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

Task from $ARGUMENTS.

## PURPOSE
Dedicated pipeline for building new features and capabilities. This is the "create new"
pipeline — for improving existing code, use /apex:refine instead.

**Build vs. Refine:** Build creates new capabilities. Refine improves existing ones.
Different risk profiles, different verification strategies, different defaults.

## GUARD
If no .apex/STATE.json: "❌ No APEX project. Run /apex:start first." STOP.
If $ARGUMENTS is empty: "❌ /apex:build requires a task description." STOP.

## PIPELINE MODE
Set in STATE.json: `"pipeline_mode": "build"`

This flag tells downstream agents (architect, executor, verifier) to use build defaults:
- Architect: decompose around feature boundaries and user requirements
- Executor: feature tests AND regression tests required
- Verifier: feature-based verification (does the new capability work?)

## EXECUTION
Route to /apex:next with pipeline_mode = build.
All pipeline stages apply with build defaults:
  - Full planning (architect + PLAN_META)
  - Full execution (executor with specialist support)
  - Full review (critic, clean-room, cross-model)
  - Full verification (verifier for C/D, phantom check, mutation gate)
  - Full session tracking (checkpoints, DORA, autopilot)

### Build Defaults
- Default verify_level: **C** (high rigor — new code needs thorough verification)
- Spec creation: yes — new features need a spec
- Test strategy: feature tests (does the new thing work?) + regression tests (did we break anything?)
- Verification: feature-based (does the capability match the spec?)

## KEY DIFFERENCES FROM REFINE
| Aspect | Build | Refine |
|--------|-------|--------|
| Input | New feature description | Existing code to improve |
| Spec | Creates new SPEC.md | Uses existing spec |
| Default verify_level | C (high rigor) | B (standard rigor) |
| Test strategy | Feature tests + regression | Regression only (mandatory) |
| Verification | Feature-based (does it work?) | Diff-based (what changed?) |
| Phase structure | Feature boundaries | Code boundaries |
| Risk profile | Higher (new code) | Lower (existing code) |

NOTE: For trivial tasks (rename, typo fix) → use /apex:fast.
For small tasks (single feature, one file) → use /apex:quick.
For maximum ceremony → use /apex:full.
For improving existing code → use /apex:refine.
</context>
