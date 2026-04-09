# APEX Stack Skills
Skills are injected into executor/specialist context based on STATE.json stack_skills.
Each file contains patterns, conventions, and anti-patterns for a specific technology.
Architect sets stack_skills during architecture phase.

## Usage
Architect reads COMPLEXITY.md → sets STATE.json.stack_skills → ["nextjs", "supabase"]
Orchestrator (/apex:next) reads stack_skills → injects relevant skill files into executor context.

## Adding Skills
Create [stack].md in this directory following the format below.