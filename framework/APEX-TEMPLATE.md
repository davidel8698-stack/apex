# APEX v7 — Framework Defaults
<!-- This file defines framework-level configuration. Project-level overrides go in PROJECT-APEX.md. -->
<!-- CRITICAL: Keep this file under 100 lines. It is loaded into every session. -->

## Pipeline Stages
spec → pre-build → architect → execute → verify

## Verify Levels
- **A**: Smoke test only (trivial changes)
- **B**: Unit tests required
- **C**: Behavioral + integration tests required
- **D**: Full verification — integration tests, edge cases, cross-phase regression audit

## Safety Rules
- All catch blocks → setError/toast/throw/return {error}
- All external API calls → return {data, error}
- No TODO/FIXME in committed code
- No placeholder keys or secrets

## Commit Convention
Conventional commits: `type(scope): description`
Types: feat, fix, refactor, test, docs, chore

## APEX State Files
Spec: .apex/SPEC.md | Decisions: .apex/DECISIONS.md | State: .apex/STATE.json
Plans: .apex/phases/*/PLAN_META.json | Results: .apex/phases/*-RESULT.json
Context Budget: .apex/CONTEXT_BUDGET.json | Threat Model: .apex/THREAT_MODEL.md

## Core Principles
- Schema as contract. Schema sync as contract.
- Scope reduction is a bug.
- Recovery before destruction.
- First-hour, first-session usability is non-negotiable.
- Predictability over capability.
- Filter, don't flood.

## When NOT to Use APEX
APEX is designed for structured software projects. It adds overhead that is counterproductive for:
- **No git repository** — APEX relies on git for snapshots, rollback, and commit discipline.
- **No test framework** — verification levels (B/C/D) require runnable tests. Without a test runner, verification is manual only.
- **One-off scripts or experiments** — if the task takes <30 minutes, APEX's planning overhead exceeds the work itself.
- **Non-code projects** — documentation-only, design, data analysis, or content creation projects don't benefit from the pipeline.
- **Prototype/throwaway code** — if you plan to discard the code, structured verification has no value.
- **Single-file utilities** — APEX's phase-based architecture is designed for multi-file, multi-concern projects.

If your project fits any of these, use Claude Code directly without APEX.

## Agent Autonomy
- Work start-to-finish. Fix errors yourself. Only stop if blocked after 3 attempts.
- When asking (D-level or blocked), use this format:
  "What I want to do: [simple explanation] | Why: [reason] | Risk: [what could go wrong]"
