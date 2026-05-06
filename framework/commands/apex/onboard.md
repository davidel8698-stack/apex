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

3. Analyze project complexity (Scale-Adaptive Classifier):
   Run these bash commands silently:
   ```bash
   COMMITS=$(git log --oneline 2>/dev/null | wc -l)
   TEST_FILES=$(find . -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" 2>/dev/null | grep -v node_modules | wc -l)
   HAS_CI=$( [ -d .github/workflows ] || [ -f .gitlab-ci.yml ] || [ -f Jenkinsfile ] || [ -f .circleci/config.yml ] && echo 1 || echo 0 )
   HAS_DOCKER=$( [ -f Dockerfile ] || [ -f docker-compose.yml ] || [ -f docker-compose.yaml ] && echo 1 || echo 0 )
   CONTRIBUTORS=$(git shortlog -sn 2>/dev/null | wc -l)
   LOC=$(find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.rb" -o -name "*.sh" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -5000 | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
   ```

   Display:
   "Project analysis:
   - LOC: [N]
   - Test files: [N]
   - CI/CD: [yes/no]
   - Docker: [yes/no]
   - Contributors: [N]
   - Git commits: [N]"

4. Suggest complexity level (Scale-Adaptive Classifier):
   Internal mapping (NOT shown to user):
   - 1: LOC < 500, no tests, no CI, no Docker, ≤ 1 contributor
   - 2: LOC 500–5000, some tests OR CI present, ≤ 3 contributors
   - 3: LOC 5000–50000, test suite + CI present, Docker likely, 2+ contributors
   - 4: LOC > 50000, full test suite, CI+CD, Docker, 4+ contributors

   Auto-detect which level matches. Let DETECTED = the matched level number (1-4).

   Display (friendly 4-button menu — no L1/L2/L3/L4 labels visible):
   "Based on your project, I recommend:

   1. Trying it out — small experiments, scripts
   2. Building something real — medium projects with some tests
   3. Going to production — production-bound with CI/CD
   4. My business depends on this — critical enterprise systems

   Select (1-4) or press Enter for [recommended]:"

   The auto-detected level shows [recommended] next to its line.
   Wait for user response. If user presses Enter or no response → use detected level. If user picks a number → use their choice.
   Store the selected number (1-4) in STATE.json as complexity_level.

5. Pre-fill and invoke /apex:start:
   "Starting APEX with:
   - Project type: [type]
   - Complexity level: [N]
   - Detected conventions: [any found in existing config]

   Invoking /apex:start..."

   Execute the /apex:start procedure with the gathered context.
   This includes the THREAT-MODEL BOOTSTRAP [R5-020] step which
   invokes the security specialist in threat-model-bootstrap mode to
   produce `.apex/THREAT_MODEL.md` from `~/.claude/THREAT_MODEL-TEMPLATE.md`,
   with `Indirect Prompt Injection` preserved as the default threat.
   Re-runnability: if `.apex/THREAT_MODEL.md` already exists from a
   prior onboarding attempt, the bootstrap writes a merge proposal to
   `.apex/THREAT_MODEL.proposed.md` rather than overwriting.

6. Log event:
   bash ~/.claude/hooks/session-log.sh "onboard" "Existing project onboarded — type: [type], complexity: [level]"
</context>