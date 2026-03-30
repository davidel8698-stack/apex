# [Project Name] — APEX v6 Project
<!-- CRITICAL: Keep this file under 200 lines. R2: 92% rule application at <200, drops to 71% at 400+ -->

## Complexity
Level [N] — [NAME]

## Stack
[stack list]

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