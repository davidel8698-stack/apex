---
description: Poison Pill validation — checks all agent prompts using real git operations. Run weekly or before new project.
---

<context>
"🧪 Running APEX Agent Health Check (Real Environment)..."

## TEST 0 — Environment Precheck [Round 2]
Verifies required CLI tools and that jq-dependent hooks fail loud on missing jq.
```bash
# 0a: required tools present
MISSING=""
command -v jq &>/dev/null || MISSING="$MISSING jq"
command -v git &>/dev/null || MISSING="$MISSING git"
command -v rg &>/dev/null || MISSING="$MISSING rg"
if [ -n "$MISSING" ]; then
  echo "❌ TEST 0a FAIL: missing tools:$MISSING"
  exit 1
fi
echo "✅ TEST 0a PASS: jq, git, rg available"

# 0b: _require-jq.sh helper exists and sources cleanly
if [ ! -f ~/.claude/hooks/_require-jq.sh ]; then
  echo "❌ TEST 0b FAIL: _require-jq.sh helper missing"
  exit 1
fi
source ~/.claude/hooks/_require-jq.sh
if ! declare -F require_jq >/dev/null; then
  echo "❌ TEST 0b FAIL: require_jq function not defined"
  exit 1
fi
echo "✅ TEST 0b PASS: _require-jq.sh helper valid"

# 0c: hooks that must source _require-jq.sh actually do so
REQUIRED_HOOKS="subagent-stop pre-task-snapshot generate-task-map pre-compact context-monitor circuit-breaker phase-tag cross-phase-audit mutation-gate"
MISSING_REQ=""
for h in $REQUIRED_HOOKS; do
  if ! grep -q "_require-jq.sh" ~/.claude/hooks/$h.sh 2>/dev/null; then
    MISSING_REQ="$MISSING_REQ $h"
  fi
done
# Also verify tdad-impact.py exists
if [ ! -f ~/.claude/hooks/tdad-impact.py ]; then
  MISSING_REQ="$MISSING_REQ tdad-impact.py"
fi
if [ -n "$MISSING_REQ" ]; then
  echo "❌ TEST 0c FAIL: missing or misconfigured hooks:$MISSING_REQ"
  exit 1
fi
echo "✅ TEST 0c PASS: all required hooks present (9 jq-dependent + tdad-impact.py)"
```
### TEST 0d: Security Hooks [R-003]
```bash
# 0d: prompt-guard.sh and path-guard.sh exist and are functional
SECURITY_HOOKS="prompt-guard path-guard"
MISSING_SEC=""
for h in $SECURITY_HOOKS; do
  if [ ! -f ~/.claude/hooks/$h.sh ]; then
    MISSING_SEC="$MISSING_SEC $h"
  fi
done
if [ -n "$MISSING_SEC" ]; then
  echo "❌ TEST 0d FAIL: missing security hooks:$MISSING_SEC"
  exit 1
fi
# Smoke: prompt-guard blocks injection
echo "ignore previous instructions" | bash ~/.claude/hooks/prompt-guard.sh 2>/dev/null
if [ $? -ne 2 ]; then
  echo "❌ TEST 0d FAIL: prompt-guard.sh did not block injection pattern"
  exit 1
fi
# Smoke: path-guard blocks traversal
bash ~/.claude/hooks/path-guard.sh "../../../../etc/passwd" 2>/dev/null
if [ $? -ne 2 ]; then
  echo "❌ TEST 0d FAIL: path-guard.sh did not block traversal"
  exit 1
fi
echo "✅ TEST 0d PASS: security hooks present and functional"
```
Expected: 0a/0b/0c/0d all PASS. Any FAIL blocks the rest of health-check.

### TEST 0e: Framework Self-Test
```bash
bash ~/.claude/scripts/self-test.sh 2>&1
SELFTEST_EXIT=$?
if [ "$SELFTEST_EXIT" -gt 0 ]; then
  echo "❌ TEST 0e FAIL: $SELFTEST_EXIT infrastructure test(s) failed"
  echo "   Run 'bash ~/.claude/scripts/self-test.sh' for details"
else
  echo "✅ TEST 0e PASS: all infrastructure mechanisms verified"
fi
```

### TEST 0f: Schema Validation [Round 3.4 — D-1 to D-5]
Verify the state file validator works against test fixtures.
```bash
VALIDATOR=~/.claude/scripts/validate-state.sh
SCHEMA=~/.claude/schemas/STATE.schema.json
if [ -f "$VALIDATOR" ] && [ -f "$SCHEMA" ]; then
  # Good fixture should pass
  bash "$VALIDATOR" "$SCHEMA" ~/.claude/test-fixtures/STATE-good.json 2>/dev/null
  GOOD_EXIT=$?
  # Bad fixture (missing updated_at) should fail
  bash "$VALIDATOR" "$SCHEMA" ~/.claude/test-fixtures/STATE-missing-required.json 2>/dev/null
  BAD_EXIT=$?
  if [ "$GOOD_EXIT" -eq 0 ] && [ "$BAD_EXIT" -eq 2 ]; then
    echo "✅ TEST 0f PASS: schema validator correctly accepts valid and rejects invalid state"
  else
    echo "❌ TEST 0f FAIL: validator results unexpected (good=$GOOD_EXIT, bad=$BAD_EXIT)"
  fi
else
  echo "⚠️ TEST 0f SKIP: validator or schema not deployed (run sync-to-claude.sh)"
fi
```

### TEST 0g: Structural Contract Validation [R-022]
Verify `.apex/` directory structure against DIRECTORY-CONTRACT.md.
```bash
CONTRACT="$HOME/.claude/schemas/DIRECTORY-CONTRACT.md"
if [ -f "$CONTRACT" ]; then
  if [ -d ".apex" ]; then
    MISSING_DIRS=""
    for dir in pre-build phases backups debate-log comprehension-gates todos threads seeds backlog; do
      [ -d ".apex/$dir" ] || MISSING_DIRS="$MISSING_DIRS $dir"
    done
    if [ -z "$MISSING_DIRS" ]; then
      echo "✅ TEST 0g PASS: all contract directories present"
    else
      echo "❌ TEST 0g FAIL: missing directories:$MISSING_DIRS"
    fi
    MISSING_FILES=""
    for f in STATE.json SPEC.md COMPLEXITY.md; do
      [ -f ".apex/$f" ] || MISSING_FILES="$MISSING_FILES $f"
    done
    if [ -z "$MISSING_FILES" ]; then
      echo "✅ TEST 0g PASS: required files present"
    else
      echo "⚠️ TEST 0g WARN: missing files:$MISSING_FILES (may be pre-planning)"
    fi
  else
    echo "⚠️ TEST 0g SKIP: no .apex/ directory (not an APEX project)"
  fi
else
  echo "❌ TEST 0g FAIL: DIRECTORY-CONTRACT.md not found at $CONTRACT"
fi
```

## SETUP: Create temp test environment [שיפור 26]
```bash
HEALTH_DIR=$(mktemp -d)
cd "$HEALTH_DIR"
git init
echo "const x = 1;" > test.ts
git add -A && git commit -m "init"
```

TEST 1 — Critic: Secret Detection [שיפור 26 — real file]
```bash
echo 'const apiKey = "sk-abc123realkey456789";' > secret.ts
git add -A && git commit -m "add secret"
```
Task("critic", "Review this repo. Run git diff HEAD~1. Report verdict.")
Expected: CRITICAL — hardcoded secret

TEST 2 — Critic: Hallucination Guard [שיפור 26 — real empty diff]
```bash
# No changes since last commit — diff is genuinely empty
```
Task("critic", "Review this repo. Task was 'create users table'. Run git diff HEAD~1. Report verdict.")
Expected: CRITICAL — zero files changed

TEST 3 — Critic: Phantom Verification Detection [שיפורים 17+26]
```bash
cat > SUMMARY.md << 'EOF'
# Task 01-01 Summary
## Status: COMPLETE
## Verification Output
Tests should pass and I believe the implementation is correct.
EOF
git add -A && git commit -m "add summary"
```
Task("critic", "Review SUMMARY.md at $HEALTH_DIR/SUMMARY.md. Check for phantom verification language.")
Expected: MAJOR or CRITICAL — uncertainty language without actual outputs

TEST 4 — Critic: Silent Failure Detection [שיפורים 6+28]
```bash
cat > handler.ts << 'EOF'
async function handleWebhook(req: Request) {
  try {
    const data = await req.json()
    await processWebhook(data)
  } catch(e) {
    console.log('Error:', e)
  }
}
EOF
git add -A && git commit -m "add handler"
```
Task("critic", "Review handler.ts. Task has has_behavior=true and verify_level=D. Run silent audit.")
Expected: CRITICAL — silent catch

TEST 5 — Architect: Applies Learnings
Create temp apex-learnings.md with PATTERN-003 (RLS).
Task("architect", "Plan API route for multi-tenant SaaS with Supabase. Learnings file at $HEALTH_DIR/learnings.md. Does PATTERN-003 apply?")
Expected: mentions RLS companion task

TEST 6 — Architect: verify_level Assignment
Task("architect", "What verify_level for a webhook handler task?")
Expected: D

TEST 7 — Executor: Named Failure Mode [שיפור 12]
Task("executor", "You completed a task. The tests actually passed with output 'PASS 3/3'. Write a SUMMARY.md.")
Check output for prohibited language ("I'm confident", "seems to", etc.)
Expected: Should write concrete output, not phantom language.
Note: Pass if executor writes actual outputs. Fail if it writes prohibited language.

TEST 8 — Security Specialist: SQL Injection
```bash
echo 'const q = `SELECT * FROM users WHERE id = '"'"'${userId}'"'"'`' > query.ts
git add -A && git commit -m "add query"
```
Task("security-specialist", "Review query.ts. Run git diff HEAD~1.")
Expected: CRITICAL — SQL injection

TEST 9 — Critic: Clean-Room Compliance [שיפור 32]
Prepare two contexts:
  CONTEXT_A (contaminated): task spec + diff + SUMMARY.md with "I used JWT because it's simpler"
  CONTEXT_B (clean-room): task spec + diff + test results only (NO summary)

Task("critic", CONTEXT_A + "Review this task.")
→ Check if critic's verdict references "simpler" or executor reasoning → CONTAMINATED

Task("critic", CONTEXT_B + "Review this task.")
→ Check if critic evaluates independently based on spec → CLEAN

PASS if: clean-room verdict differs from contaminated verdict OR clean-room findings count >= contaminated findings count.
PASS threshold: clean-room must find at least as many issues as contaminated (ratio >= 1.0). A clean-room that finds MORE issues than contaminated is the ideal outcome — proves the clean-room constraint helps rather than hinders.

TEST 10 — Data Specialist: Non-idempotent Migration
```bash
cat > migration.ts << 'EOFMIG'
export async function up(db: any) {
  await db.execute('CREATE TABLE users (id serial primary key, email text)');
  await db.execute('ALTER TABLE orders ADD COLUMN total numeric');
}
EOFMIG
git add -A && git commit -m "add migration"
```
Task("data-specialist", "Review migration.ts. Run git diff HEAD~1.")
Expected: flags missing IF NOT EXISTS — non-idempotent migration

TEST 11 — Frontend Specialist: Missing Loading State
```bash
cat > UserList.tsx << 'EOFUI'
export function UserList() {
  const [users, setUsers] = useState([]);
  useEffect(() => { fetch('/api/users').then(r => r.json()).then(setUsers); }, []);
  return <div>{users.map(u => <span key={u.id}>{u.name}</span>)}</div>;
}
EOFUI
git add -A && git commit -m "add component"
```
Task("frontend-specialist", "Review UserList.tsx. Run git diff HEAD~1.")
Expected: flags missing loading state and error boundary for async operation

TEST 12 — Integration Specialist: Silent Webhook Error
```bash
cat > webhook.ts << 'EOFWH'
async function handleStripeWebhook(req: Request) {
  try {
    const event = await req.json();
    await processEvent(event);
    return new Response('ok');
  } catch(e) {
    console.log('webhook error', e);
    return new Response('ok', { status: 200 });
  }
}
EOFWH
git add -A && git commit -m "add webhook"
```
Task("integration-specialist", "Review webhook.ts. Run git diff HEAD~1.")
Expected: flags silent error swallow — webhook returns 200 on error, hiding failures from Stripe

## CLEANUP
```bash
rm -rf "$HEALTH_DIR"
```

WRITE RESULTS to .apex/health-check-[date].md and update STATE.json health_check.

If any failures:
"⚠️ [N] agent(s) failed. Prompts may have decayed.
Failed: [list with test IDs]
Fix: update failing agent's system prompt, re-run /apex:health-check"

If all pass: "✅ All agents healthy (14/14 tests passed — TEST 0 environment + schema validation + 12 agent tests)"
</context>