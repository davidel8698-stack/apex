---
description: Onboard an existing project to APEX. Guided setup for projects without .apex/.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## ADAPTER HONESTY BANNER [R6-017]
## Spec anchors: "Multi-platform from day one." + "Honest scope over marketing scope." + "Honestly Scoped, Not Universally Promised."
## Runtime propagation of manifest-level honesty: when running on a
## non-canonical adapter (hook_protocol.supported != "full"), the user
## must be told which APEX behavioral guarantees are deferred on this
## host. One-time per project — suppressed by STATE.adapter_honesty_shown.
```bash
# Resolve framework root for adapter manifest reads.
APEX_FW_ROOT="${APEX_FW_ROOT:-$HOME/.claude}"
ADAPTER_DETECT="$APEX_FW_ROOT/hooks/_adapter-detect.sh"
if [ -f "$ADAPTER_DETECT" ]; then
  ACTIVE_ADAPTER=$(bash "$ADAPTER_DETECT" active 2>/dev/null || echo "claude-code")
else
  ACTIVE_ADAPTER="claude-code"
fi
ADAPTER_MANIFEST="$APEX_FW_ROOT/adapters/$ACTIVE_ADAPTER/adapter.json"
ALREADY_SHOWN=$(jq -r '.adapter_honesty_shown // false' .apex/STATE.json 2>/dev/null || echo "false")
if [ -f "$ADAPTER_MANIFEST" ] && [ "$ALREADY_SHOWN" != "true" ]; then
  HOOK_SUPPORT=$(jq -r '.hook_protocol.supported // "full"' "$ADAPTER_MANIFEST" 2>/dev/null)
  if [ "$HOOK_SUPPORT" != "full" ]; then
    DEFERRED_LIST=$(jq -r '.deferred // [] | join(", ")' "$ADAPTER_MANIFEST" 2>/dev/null)
    DISPLAY_NAME=$(jq -r '.display_name // .platform // "this adapter"' "$ADAPTER_MANIFEST" 2>/dev/null)
    echo ""
    echo "⚠️  APEX SCOPE-HONESTY BANNER"
    echo "   Active adapter: $DISPLAY_NAME (hook_protocol.supported = $HOOK_SUPPORT)"
    echo "   Out-of-scope on this platform: $DEFERRED_LIST"
    echo "   Behavioral guarantees that depend on hooks (destructive-guard,"
    echo "   prompt-guard, schema-drift, phantom-check, ...) are NOT enforced"
    echo "   on $DISPLAY_NAME until the host exposes a comparable primitive."
    echo "   See framework/adapters/$ACTIVE_ADAPTER/adapter.json + framework/docs/MULTI-PLATFORM.md."
    echo ""
    # One-time suppression: set the flag in STATE.json.
    if [ -f .apex/STATE.json ]; then
      tmp=".apex/STATE.json.banner.tmp"
      jq '.adapter_honesty_shown = true' .apex/STATE.json > "$tmp" && mv "$tmp" .apex/STATE.json
    fi
  fi
fi
```

## TELEMETRY NOTIFICATION [M16.1 / Phase 12.09 / User Decision #3]
## Spec anchors: "Honest scope over marketing scope." + "Honestly Scoped, Not Universally Promised." + User Decision #3 (opt-out from start).
## One-time, per-project notification surfaced on first /apex:onboard run.
## Mirror of the block in start.md — onboard is the entry point for existing-project adoption.
## Idempotent — suppression via `.apex/telemetry-notification-shown.flag`.
```bash
TELEMETRY_FLAG=".apex/telemetry-notification-shown.flag"
if [ ! -f "$TELEMETRY_FLAG" ]; then
  echo ""
  echo "🔒 APEX collects anonymous, numeric quality counters locally to"
  echo "   validate context-preservation claims. No code, paths, names, or"
  echo "   commit messages are ever collected. Data lives in"
  echo "   .apex/telemetry.jsonl (project-local — no remote upload in v0.1.x)."
  echo "   Opt out: export APEX_TELEMETRY=off   (per-session)"
  echo "        OR: touch ~/.claude/telemetry-opt-out.flag   (persistent)"
  echo "   Full policy: framework/docs/PRIVACY-POLICY.md"
  echo ""
  echo "🔒 APEX אוסף מוני איכות מספריים אנונימיים באופן מקומי כדי לאמת"
  echo "   טענות לגבי שימור הקשר. אין איסוף של קוד, נתיבים, שמות או"
  echo "   הודעות commit. הנתונים נשמרים ב-.apex/telemetry.jsonl בלבד"
  echo "   (מקומי לפרויקט — ללא העלאה מרחוק בגרסה v0.1.x)."
  echo "   ביטול הסכמה: export APEX_TELEMETRY=off   (לסשן נוכחי)"
  echo "          או:   touch ~/.claude/telemetry-opt-out.flag   (קבוע)"
  echo "   המדיניות המלאה: framework/docs/PRIVACY-POLICY.md"
  echo ""
  mkdir -p .apex 2>/dev/null
  touch "$TELEMETRY_FLAG" 2>/dev/null || true
fi
```

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

7. PinScope check (UI projects only):
   If the detected project_type is React+Vite, React+Next, or any
   React-based UI project, /apex:start will add `pinscope` to
   STATE.json.stack_skills (per architect STEP 0). The downstream
   /apex:ui-phase command instruments the project with PinScope
   automatically (vite/next plugin + `<PinScope/>` root mount). No
   action required here — onboarding inherits this from /apex:start.
   See framework/apex-skills/pinscope.md for the conventions.
</context>