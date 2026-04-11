---
description: Generate a stack-specific skill file by analyzing the current project's dependencies and patterns.
---

<context>
Read `$ARGUMENTS` as the target stack name (e.g., "express", "drizzle", "tailwind").

If `$ARGUMENTS` is empty:
  Scan the project for detectable stacks:
  - Read `package.json` (dependencies + devDependencies) if it exists
  - Read `requirements.txt`, `pyproject.toml`, `Cargo.toml`, `go.mod` if they exist
  - Scan `import` statements in the first 5 source files
  Present detected stacks and ask user to select one for skill generation.

If stack name is provided:
  1. **Detect patterns** from the project:
     - Search for import/require statements using the stack
     - Identify common usage patterns (file structure, naming, configuration)
     - Note any existing conventions the project follows

  2. **Generate skill file** following this format:
     ```markdown
     # {Stack} Patterns for APEX

     ## Conventions
     - [Project-specific conventions detected from codebase]
     - [Common best practices for this stack]

     ## Anti-Patterns — NEVER
     - [Stack-specific mistakes to avoid]
     - [Patterns that lead to bugs in this stack]

     ## Common Patterns
     [Code examples showing correct usage]

     ## Testing
     - [Stack-specific testing guidance]

     ## Common Gotchas
     - [Non-obvious behaviors that cause bugs]
     ```

  3. **Write** the file to `~/.claude/apex-skills/{stack}.md`

  4. **Verify**:
     - File follows the standard skill format (Conventions, Anti-Patterns, Common Patterns, Testing, Gotchas)
     - File is 25-50 lines (concise, actionable — not documentation)
     - No duplication with existing skills in `~/.claude/apex-skills/`

  5. **Confirm**: "Skill file generated: apex-skills/{stack}.md. Add '{stack}' to STATE.json.stack_skills to activate."

## Error handling
- If stack not found in project: "No {stack} usage detected in project. Generate anyway? (The skill will use generic best practices.)"
- If skill file already exists: "Skill file apex-skills/{stack}.md already exists. Overwrite? (Current file will be backed up.)"
</context>
