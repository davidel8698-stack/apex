---
description: Onboard an existing project to APEX. Guided setup for projects without .apex/.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
Guide through APEX setup for an existing project that does not have .apex/ initialized.

## PROCEDURE
1. Check if .apex/STATE.json exists:
   If yes: "Project already has APEX initialized. Use /apex:resume or /apex:next." STOP.

2. Detect project type:
   - Check for package.json → Node.js project
   - Check for requirements.txt / pyproject.toml → Python project
   - Check for Cargo.toml → Rust project
   - Check for go.mod → Go project
   - Check for pom.xml / build.gradle → Java project
   - Check for *.sln / *.csproj → .NET project
   - Check for Gemfile → Ruby project
   - Otherwise → "Unknown project type"

   Display: "Detected project type: [type]"

3. Analyze project size:
   - Count source files: find . -name "*.{ext}" | wc -l
   - Check git history: git log --oneline | wc -l
   - Check for existing tests: look for test directories

   Display:
   "Project analysis:
   - Source files: [N]
   - Git commits: [N]
   - Test directory: [found/not found]"

4. Suggest complexity level:
   - < 20 files, no tests → suggest level 2 (Trying it out)
   - 20-100 files → suggest level 3 (Serious side project)
   - 100+ files or existing tests → suggest level 4 (Production-grade)
   
   Display: "Suggested complexity level: [N] — [name]. Agree? (y/n or specify level 1-5)"
   Wait for user response.

5. Pre-fill and invoke /apex:start:
   "Starting APEX with:
   - Project type: [type]
   - Complexity level: [N]
   - Detected conventions: [any found in existing config]

   Invoking /apex:start..."

   Execute the /apex:start procedure with the gathered context.

6. Log event:
   bash ~/.claude/hooks/session-log.sh "onboard" "Existing project onboarded — type: [type], complexity: [level]"
</context>