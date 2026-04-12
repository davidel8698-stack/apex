---
description: List all /apex: commands grouped by category.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
Display all available /apex: commands with one-line descriptions, organized by category.

## OUTPUT
Display the following command catalog:

"## APEX Commands

### Pipeline (core build flow)
- `/apex:start` — Start new APEX project
- `/apex:next` — Advance to next logical step (orchestration heart)
- `/apex:spec` — Generate or update SPEC.md
- `/apex:precheck` — Pre-flight checks before starting
- `/apex:discuss-phase` — Gather context before phase planning
- `/apex:plan-phase` — Create PLAN.md for a phase
- `/apex:execute-phase` — Execute all tasks in a phase
- `/apex:validate-phase` — Run audit + verification on completed phase
- `/apex:test` — Run verify commands for current phase
- `/apex:ship` — Final verification + tag release

### Speed Presets (ceremony level)
- `/apex:fast` — Zero ceremony, single trivial change
- `/apex:quick` — Light ceremony, small task
- `/apex:micro` — Micro-task with minimal overhead
- `/apex:full` — Full ceremony pipeline

### Recovery
- `/apex:pause` — Save state and pause work
- `/apex:resume` — Resume in fresh session
- `/apex:recover` — Recover from crash or stuck state
- `/apex:rollback` — Roll back to previous checkpoint
- `/apex:forensics` — Diagnose what went wrong (timeline + analysis)
- `/apex:walkthrough` — Guided forensics with explanations

### Memory
- `/apex:plant-seed` — Plant a seed idea for later
- `/apex:add-backlog` — Add item to backlog
- `/apex:review-backlog` — Review and triage backlog items
- `/apex:thread` — Create or continue a discussion thread

### Quality
- `/apex:health-check` — Environment and project health diagnostics
- `/apex:peer-review` — Peer review (not yet implemented)
- `/apex:ui-review` — UI review (not yet implemented)

### Collaboration
- `/apex:_debate` — Internal debate agent (system use)
- `/apex:_roundtable` — Internal roundtable agent (system use)

### Operations
- `/apex:status` — Project status dashboard
- `/apex:session-report` — Session metrics report
- `/apex:onboard` — Onboard existing project to APEX
- `/apex:list` — This command
- `/apex:milestone-summary` — Milestone summary (not yet implemented)

### Stubs (future)
- `/apex:new-agent` — Custom agent creation (deferred)
- `/apex:new-workspace` — New workspace setup (not yet implemented)
- `/apex:build` — Alias for /apex:full
- `/apex:refine` — Refinement pass (not yet implemented)
- `/apex:ui-phase` — UI-specific phase (not yet implemented)
- `/apex:pause-work` — Redirect to /apex:pause
- `/apex:resume-work` — Redirect to /apex:resume"
</context>