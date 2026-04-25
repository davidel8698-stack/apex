# CLAUDE.md — Internal Build Instructions

> **Note for human readers:** This file is consumed automatically by Claude Code
> as build instructions for the APEX framework. For the public-facing project
> introduction, see [README.md](README.md). For the full specification, see
> [apex-spec.md](apex-spec.md).

---

## What This Is
This is a BUILD project for the APEX framework itself — not an application.
APEX is a context-engineered pipeline framework for Claude Code, consisting of
slash commands, agents, hooks, and JSON schemas.
The authoritative specs are APEX-v5.md (base) and APEX-v6.md (delta).
Merge rule: v6 wins on conflict. "unchanged" = use v5. "updated/redesigned" = use v6.

## Output File Structure
```
~/.claude/
  commands/apex/     11 slash command .md files
  agents/            8 core agent .md files
  agents/specialist/ 4 specialist agent .md files
  hooks/             13 shell scripts
  apex-skills/       stack-specific skill files
  apex-learnings.md  learning accumulator
  settings.json      hook configuration
```

## Project State Files (per target project, not built here)
```
.apex/STATE.json, CONTEXT_BUDGET.json, SPEC.md, DECISIONS.md,
      COMPLEXITY.md, TASK_MAP.md, TEST_MAP.txt
.apex/phases/*/PLAN.md, PLAN_META.json, WAVE_MAP.json,
              *-RESULT.json, *-SUMMARY.md, *-CRITIC.md, VERIFY.md
```

## Build Rules
1. Every file MUST match APEX-v6.md exactly. Do not invent content not in the spec.
2. If v6 says "same as v5" for a section, that section needs the v5 logic
   (which must be sourced from the user or marked as TODO).
3. Hooks are shell scripts (.sh). Agents and commands are markdown (.md).
4. settings.json hook matchers must match exact hook filenames.
5. JSON schemas (STATE, CONTEXT_BUDGET, PLAN_META, RESULT) must match v6 spec.
6. Build order: settings.json -> hooks -> agents -> commands -> skills.
7. Do not add features, comments, or "improvements" beyond what v6 specifies.

## Dependency Chain
- settings.json references hooks by path -> hooks must match
- Commands invoke hooks by path -> hooks must exist
- Commands invoke agents by name -> agents must exist
- Critic reads RESULT.json format -> executor must define it
- Verifier reads CRITIC.md format -> critic must define it

## Merge Strategy
- v5 provides full base for all components
- v6 provides deltas/redesigns for: executor, critic, settings.json, context-monitor,
  destructive-guard, pre-task-snapshot, circuit-breaker, /apex:micro, /apex:status,
  /apex:health-check (test 9), /apex:next (steps F, F.5, critic invocation),
  STATE.json, CONTEXT_BUDGET.json, PLAN_META.json, CLAUDE.md template
- Components not mentioned in v6 are built from v5 verbatim
