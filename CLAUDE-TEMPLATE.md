# [Project Name] — APEX v7 Project
<!-- CRITICAL: Keep this file under 200 lines. R2: 92% rule application at <200, drops to 71% at 400+ -->

## Complexity
Level [N] — [NAME]

## Stack
[stack list]

## User Profile
- Technical level: [non-programmer / junior / senior / architect]
- Language: [Hebrew + English tech terms / English / other]
- Communication: report in [language], no jargon. Only ask about WHAT gets built, never HOW.
- Autonomy: work start-to-finish. Fix errors yourself. Only stop if blocked after 3 attempts.
- When asking (D-level or blocked), use this format:
  "What I want to do: [simple explanation] | Why: [reason] | Risk: [what could go wrong]"

## Conventions
[coding conventions — be specific, be brief]

## Critical Rules
[project-specific rules — max 10 items]

## Build Commands
[exact commands for build, test, lint, dev server]

## APEX State Files
Spec: .apex/SPEC.md | Decisions: .apex/DECISIONS.md | State: .apex/STATE.json
Plans: .apex/phases/*/PLAN_META.json | Results: .apex/phases/*-RESULT.json

## Safety Rules
- All catch blocks → setError/toast/throw/return {error}
- All external API calls → return {data, error}
- No TODO/FIXME in committed code
- No placeholder keys or secrets