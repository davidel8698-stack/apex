---
description: Poison Pill validation — checks all agent prompts using real git operations. Run weekly or before new project.
---

<context>
"🧪 Running APEX Agent Health Check (Real Environment)..."

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
Expected: MAJOR — uncertainty language without actual outputs

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

Expected: Critic with CONTEXT_B produces different (usually more thorough) review.
Pass: Critic with clean-room context finds issues that contaminated context missed.

## CLEANUP
```bash
rm -rf "$HEALTH_DIR"
```

WRITE RESULTS to .apex/health-check-[date].md and update STATE.json health_check.

If any failures:
"⚠️ [N] agent(s) failed. Prompts may have decayed.
Failed: [list with test IDs]
Fix: update failing agent's system prompt, re-run /apex:health-check"

If all pass: "✅ All agents healthy (9/9 tests passed)"
</context>