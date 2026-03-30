# APEX v5 — Adaptive Pipeline for Excellence
## ארכיטקטורה מלאה + 17 שיפורים מקוריים + 14 שדרוגים חדשים
### Claude Code Native — Slash Commands + Agents בלבד

---

## עקרון העל

כל הכלים הקיימים נכשלים בשבע נקודות:
הם מניחים שכל פרויקט צריך אותו pipeline.
הם מאמינים ל-executor שמדווח על עצמו.
הם מתחילים מאפס בכל פרויקט.
הם מניחים שקוד שרץ — עובד.
**הם מניחים שהאדם שבנה את הפרויקט עדיין מבין אותו.**
**הם לא מנהלים context — ומאבדים איכות עם כל task.**
**הם לא עוקבים אחרי עלות — ושורפים tokens בעיוור.**

**APEX שואל קודם — בודק אחרי — לומד תמיד — מחפש כשלים שקטים — שומר על הבנת האדם — מנהל context בקפדנות — ועוקב אחרי כל token.**

---

## 31 השיפורים — סיכום

```
── מ-v2 (נשמרים מלאים) ──────────────────────────────────────
שיפור 1:  Prompt Testing Protocol       — agent prompts נבדקים לפני בנייה
שיפור 2:  Verification Ladder (A/B/C/D) — כל task מסומן ברמת verification
שיפור 3:  Edge Cases בSpec              — Interviewer שולף מה יכול להישבר
שיפור 4:  Learning Loop                 — Critic כותב, Architect קורא
שיפור 5:  Pre-Build Phase               — blocking checklist לפני קוד

── מ-v3 (נשמרים מלאים) ──────────────────────────────────────
שיפור 6:  Silent Failure Audit          — בדיקת קוד שרץ אבל משקר
שיפור 7:  Reflexion Loop                — executor לומד מהכשלון לפני retry
שיפור 8:  Architecture Debate          — MAD ממוקד להחלטות בלתי-הפיכות
שיפור 9:  Citation-Based Living Memory  — learnings עם citations לקוד
שיפור 10: Poison Pill Prompt Testing    — /apex:health-check שבועי
שיפור 11: Repository Map Injection      — micro-map לכל task

── מ-v4 מקורי ─────────────────────────────────────────────
שיפור 12: Named Failure Mode Enforcement — prohibitions > instructions
שיפור 13: Trajectory Self-Monitor       — executor בודק את עצמו כל 5 steps
שיפור 14: TDAD — Dependency-Aware Tests — 70% פחות regressions
שיפור 15: Cognitive Debt Prevention     — Comprehension Gates בין phases
שיפור 16: Cross-Phase Regression Audit  — EvoScore: בריאות codebase לאורך זמן
שיפור 17: Phantom Verification Guard    — חוסם דוחות ללא ראיות אמיתיות

── חדשים ב-v5 ────────────────────────────────────────────
שיפור 18: Context Rotation              — fresh session per phase, אפס context rot
שיפור 19: Context Budget Per Agent      — תקציב tokens מקסימלי, summarization אגרסיבי
שיפור 20: Token Budget Tracking         — עלות לכל phase, agent, ו-task
שיפור 21: Structured Metadata           — JSON metadata במקום regex parsing
שיפור 22: Wave-Based Parallel Execution — tasks ללא dependencies רצים parallel
שיפור 23: Phase Rollback Mechanism      — git tags + revert per phase
שיפור 24: Stack-Specific Skill Injection — knowledge injection per stack
שיפור 25: Diff-Based Critic Review      — line-by-line diff vs task XML
שיפור 26: Real Health Check             — temp repo + real git operations
שיפור 27: Smart Autonomy Escalation     — רק C/D tasks סופרים לעלייה
שיפור 28: Agent Consolidation           — 13 agents במקום 17, פחות maintenance
שיפור 29: Context Overflow Detection    — auto-compact ב-70%+ context
שיפור 30: File-Based Debate Isolation   — advocates כותבים לקבצים, לא ל-session
שיפור 31: /apex:resume Command          — המשך מ-session חדש, state מהקבצים
```

---

## מודל הסיווג: 4 רמות מורכבות

```
Level 1 — SIMPLE
  דוגמאות: landing page, script, CLI tool, blog
  Pipeline: Spec → Build → Done
  Agents: interviewer + executor + critic (כולל silent audit checklist)

Level 2 — STANDARD
  דוגמאות: web app עם DB, dashboard, API, SaaS פשוט
  Pipeline: Spec → Architect → Phases → Verify
  Agents: כל הבסיסיים + verifier

Level 3 — COMPLEX
  דוגמאות: FINDO, multi-tenant SaaS, third-party integrations
  Pipeline: PRE-BUILD → Spec → Architect → Phases → Verify → Deploy
  Agents: כל הagents + pre-build-planner + debate (architect role) + specialists

Level 4 — ENTERPRISE
  דוגמאות: platform, marketplace, 10+ integrations
  Pipeline: מלא עם waves מקבילים
```

---

## מבנה קבצים מלא

```
~/.claude/
  commands/apex/
    start.md             ← /apex:start
    next.md              ← /apex:next
    build.md             ← /apex:build
    spec.md              ← /apex:spec
    status.md            ← /apex:status
    review.md            ← /apex:review
    quick.md             ← /apex:quick
    pause.md             ← /apex:pause
    recover.md           ← /apex:recover
    resume.md            ← /apex:resume        [שיפור 31]
    precheck.md          ← /apex:precheck      [שיפור 5]
    health-check.md      ← /apex:health-check  [שיפור 10+26]

  agents/
    diagnostician.md          ← מאבחן + מסווג + pre-build checklist
    interviewer.md            ← מראיין + שולף edge cases [שיפור 3]
    pre-build-planner.md      ← blocking checklist agent [שיפור 5]
    architect.md              ← מתכנן + learnings + debate + wave planning [שיפורים 4,8,11,21,22,24,30]
    executor.md               ← מממש + reflexion + named failure modes [שיפורים 6,7,11,12,13,14,19]
    critic.md                 ← adversarial + learnings + reflexion + diff-based + silent audit [שיפורים 4,6,7,9,17,25,28]
    verifier.md               ← phase verification + ladder audit + rollback [שיפורים 2,6,16,23]
    researcher.md             ← מחקר טכני
    specialist/
      integration.md
      security.md
      data.md
      frontend.md

  hooks/
    post-write.sh             ← lint + secret + silent catch advisory
    subagent-stop.sh          ← hallucination guard
    pre-compact.sh            ← state backup
    verify-learnings.sh       ← citation validation [שיפור 9]
    generate-task-map.sh      ← repository map per task [שיפור 11]
    phantom-check.sh          ← red flag word detection [שיפור 17]
    tdad-index.sh             ← build code-test dependency graph [שיפור 14]
    cross-phase-audit.sh      ← regression audit before phase advance [שיפור 16]
    context-monitor.sh        ← context overflow detection [שיפור 29]
    phase-tag.sh              ← git tag per completed phase [שיפור 23]

  apex-learnings.md           ← Citation-Based Learning Loop [שיפורים 4,9]
  apex-skills/                ← Stack-Specific Knowledge [שיפור 24]
    nextjs.md
    supabase.md
    prisma.md
    tailwind.md
    stripe.md
    README.md
  settings.json

.apex/
  SPEC.md                     ← living spec + edge cases [שיפור 3]
  DECISIONS.md                ← append-only log
  COMPLEXITY.md               ← level + pipeline + debate candidates
  STATE.json                  ← machine state + reflexion + evoscore + tokens [שיפורים 18,20]
  AUTONOMY.json
  BUDGET.json
  TASK_MAP.md                 ← current task repo map [שיפור 11]
  TEST_MAP.txt                ← TDAD code-test dependency graph [שיפור 14]
  CONTEXT_BUDGET.json         ← per-agent context limits [שיפור 19]

  pre-build/
    CHECKLIST.md
    STATUS.json

  phases/
    01-*/
      PLAN.md                 ← XML tasks with verify_level + is_irreversible
      PLAN_META.json          ← structured metadata for hooks [שיפור 21]
      WAVE_MAP.json           ← parallel execution plan [שיפור 22]
      SUMMARY.md
      CRITIC.md
      VERIFY.md
      DEBATE.md               ← debate log [שיפור 8+30]

  comprehension-gates/        ← [שיפור 15]
    phase-01-gate.md
    phase-02-gate.md
    ...

  research/
  backups/
  debate-log/
```

---

## STATE.json — מבנה מלא (כולל שיפורים 18-31)

```json
{
  "project": "MyProject",
  "complexity_level": 3,
  "complexity_name": "COMPLEX",
  "pipeline": ["pre-build", "spec", "architect", "phases", "verify"],

  "current_stage": "build",
  "pre_build_complete": true,
  "current_phase": "02-backend",
  "current_unit": "02-03",
  "current_wave": 1,
  "status": "pending_approval",

  "autonomy": {
    "level": 1,
    "name": "supervised",
    "consecutive_cd_successes": 3,
    "consecutive_total_successes": 7,
    "threshold_for_next": 5,
    "total_failures": 1,
    "last_failure_reason": null,
    "note": "only verify_level C/D tasks count toward escalation"
  },

  "reflexion": {
    "current_unit_attempts": 0,
    "max_attempts": 3,
    "last_reflexion_summary": null
  },

  "context": {
    "current_session_phase": "02-backend",
    "session_start_time": "2026-03-30T14:00:00Z",
    "estimated_context_usage_pct": 35,
    "last_compact": null,
    "rotation_history": [
      {"phase": "01-foundation", "session_ended": "2026-03-30T13:55:00Z", "reason": "phase_complete"}
    ]
  },

  "tokens": {
    "total_input": 245000,
    "total_output": 89000,
    "by_phase": {
      "01-foundation": {"input": 120000, "output": 45000},
      "02-backend": {"input": 125000, "output": 44000}
    },
    "by_agent": {
      "executor": {"calls": 12, "input": 150000, "output": 60000},
      "critic": {"calls": 8, "input": 50000, "output": 15000},
      "architect": {"calls": 2, "input": 30000, "output": 10000}
    },
    "by_task": {}
  },

  "health_check": {
    "last_run": "2026-03-30",
    "all_passed": true,
    "failed_agents": [],
    "test_count": 8
  },

  "evoscore": {
    "regression_rate": 0.0,
    "phases_with_regressions": [],
    "total_cross_phase_tests": 0,
    "last_full_audit": null
  },

  "comprehension_gates": {
    "phase_01_passed": true,
    "phase_02_passed": false,
    "current_gate_required": "phase_02"
  },

  "tdad": {
    "index_built": true,
    "last_indexed": "2026-03-30T10:00:00Z",
    "total_nodes": 234
  },

  "phase_tags": {
    "01-foundation": "apex/phase-01-complete",
    "02-backend": null
  },

  "stack_skills": ["nextjs", "supabase", "tailwind"],

  "phases_total": 7,
  "phases_completed": 1,
  "units_total": 18,
  "units_completed": 4,
  "lock": null,

  "created_at": "2026-03-30T10:00:00Z",
  "updated_at": "2026-03-30T14:30:00Z"
}
```

---

## CONTEXT_BUDGET.json [שיפור 19]

```json
{
  "max_context_per_agent": {
    "executor": 80000,
    "critic": 40000,
    "verifier": 50000,
    "architect": 60000,
    "interviewer": 30000,
    "researcher": 50000,
    "diagnostician": 20000,
    "specialist": 60000
  },
  "summarization_rules": {
    "spec_for_executor": "inject only sections matching task <files> paths and <edge_cases>",
    "decisions_for_executor": "inject only decisions tagged with current phase or 'global'",
    "dependency_summaries": "max 500 tokens per dependency, use SUMMARY.md 'What Next Tasks Can Assume' section only",
    "reflexion": "full reflexion brief (never summarize failure context)",
    "task_map": "full (already compact)",
    "impacted_tests": "full (already compact)"
  },
  "context_overflow_threshold_pct": 70,
  "action_on_overflow": "compact_and_continue",
  "critical_threshold_pct": 85,
  "action_on_critical": "save_state_and_rotate"
}
```

---

## PLAN_META.json — Structured Metadata [שיפור 21]

```json
{
  "phase_id": "02",
  "phase_name": "backend",
  "tasks": [
    {
      "id": "02-01",
      "name": "Create auth API routes",
      "complexity": "medium",
      "specialist": "none",
      "is_irreversible": false,
      "has_behavior": true,
      "verify_level": "C",
      "files": [
        "src/app/api/auth/login/route.ts",
        "src/app/api/auth/register/route.ts",
        "src/lib/auth.ts"
      ],
      "verify_commands": [
        "npx tsc --noEmit",
        "npm test -- --testPathPattern=auth",
        "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/auth/login"
      ],
      "done_criteria": [
        "POST /api/auth/login returns 200 with valid credentials",
        "POST /api/auth/login returns 401 with invalid credentials",
        "POST /api/auth/register creates user and returns 201"
      ],
      "edge_cases": [
        "duplicate email registration",
        "SQL injection in email field",
        "rate limiting after 5 failed attempts"
      ],
      "silent_failure_risks": [
        "catch block in login that only logs error",
        "missing error state on registration form"
      ],
      "dependencies": ["01-03"],
      "wave": 1
    },
    {
      "id": "02-02",
      "name": "Create RLS policies for users table",
      "complexity": "low",
      "specialist": "security",
      "is_irreversible": false,
      "has_behavior": false,
      "verify_level": "A",
      "files": [
        "supabase/migrations/005_users_rls.sql"
      ],
      "verify_commands": [
        "supabase db diff --schema public"
      ],
      "done_criteria": [
        "RLS enabled on users table",
        "SELECT policy filters by auth.uid()"
      ],
      "edge_cases": [],
      "silent_failure_risks": [],
      "dependencies": ["02-01"],
      "wave": 2
    }
  ],
  "waves": {
    "1": ["02-01", "02-04", "02-05"],
    "2": ["02-02", "02-03"],
    "3": ["02-06"]
  },
  "total_tasks": 6,
  "verify_level_distribution": {"A": 1, "B": 2, "C": 2, "D": 1}
}
```

---

## WAVE_MAP.json — Parallel Execution Plan [שיפור 22]

```json
{
  "phase_id": "02",
  "phase_name": "backend",
  "waves": [
    {
      "wave_number": 1,
      "tasks": ["02-01", "02-04", "02-05"],
      "parallel": true,
      "note": "No cross-dependencies. Can run simultaneously in worktrees.",
      "estimated_tokens": 45000
    },
    {
      "wave_number": 2,
      "tasks": ["02-02", "02-03"],
      "parallel": true,
      "depends_on_wave": 1,
      "note": "Depends on wave 1 completion. 02-02 needs 02-01, 02-03 needs 02-04.",
      "estimated_tokens": 30000
    },
    {
      "wave_number": 3,
      "tasks": ["02-06"],
      "parallel": false,
      "depends_on_wave": 2,
      "note": "Integration task — must run after all others.",
      "estimated_tokens": 20000
    }
  ],
  "execution_mode": "sequential_waves_parallel_tasks",
  "total_waves": 3,
  "worktree_strategy": "branch_per_task_in_wave"
}
```

---

## [שיפור 2] Verification Ladder

```
Level A — STATIC:    file exists + typecheck passes
Level B — RUNTIME:   command runs + returns expected output
Level C — BEHAVIORAL: user action produces expected result (behavioral test needed)
Level D — INTEGRATION: two systems communicating correctly (integration test needed)
```

Webhook → D | OAuth → D | Payment → D | Background job → C or D
API endpoint with logic → B or C | File/schema/config → A

---

## [שיפורים 4+9] Citation-Based Learning Loop

**קובץ:** `~/.claude/apex-learnings.md`

```markdown
# APEX Learnings — Citation-Based Global Knowledge Base
*כותב: Critic. קורא: Architect לפני planning. מאמת: verify-learnings.sh.*

---

## Pattern Library

### [PATTERN-001] Missing error handling in API routes
**Severity:** Major | **Seen in:** 3 projects
**Citations:**
  - src/app/api/auth/login/route.ts:45 — CORRECT pattern example
  - src/app/api/webhook/meta/route.ts:12 — where this was MISSING (fixed)
**Verified:** 2026-03-30 | **Status:** ACTIVE
**Prevention:** Every API route must have try/catch returning {error, data}
**Architect action:** Add explicit error handling task to every BACKEND phase
**Verify:** grep -r "export async function" src/app/api | wc -l == grep -r "try {" src/app/api | wc -l

### [PATTERN-002] OAuth token refresh not implemented
**Severity:** Critical | **Seen in:** 2 projects
**Citations:**
  - src/lib/integrations/google.ts:67 — correct refresh implementation
**Verified:** 2026-03-29 | **Status:** ACTIVE
**Architect action:** Any OAuth integration → dedicated "token-refresh" task at verify_level=D

### [PATTERN-003] RLS policies missing on new tables
**Severity:** Critical | **Seen in:** 4 projects
**Citations:**
  - supabase/migrations/004_reviews_rls.sql:1 — correct RLS pattern
**Verified:** 2026-03-28 | **Status:** ACTIVE
**Architect action:** In DATA phase, every table task → companion RLS task

---

## Edge Case Library

### [EDGE-001] External service unavailable
**Citations:** src/lib/integrations/whatsapp.ts:34 — correct degradation
**Status:** ACTIVE

### [EDGE-002] Duplicate webhook events
**Citations:** src/app/api/webhooks/meta/route.ts:8 — idempotency check
**Status:** ACTIVE

---

## Silent Failure Patterns [שיפור 6]

### [SILENT-001] Error caught but not shown to user
**Severity:** Critical
**Citations:** src/components/GenerateSummary.tsx:23 — example
**Detection:** grep -r "catch" src/ | grep -v "setError\|toast\|throw" | grep -v test
**Prevention:** Every catch block MUST update UI state or re-throw

### [SILENT-002] Placeholder API key committed
**Severity:** Critical
**Detection:** grep -r "placeholder\|your.*key\|TODO.*key\|fake.*token" src/
**Prevention:** phantom-check.sh blocks commit if placeholder detected

---

*Citation check: run verify-learnings.sh daily*
```

---

## [שיפור 24] Stack-Specific Skills

**תיקייה:** `~/.claude/apex-skills/`

**README.md:**
```markdown
# APEX Stack Skills
Skills are injected into executor/specialist context based on STATE.json stack_skills.
Each file contains patterns, conventions, and anti-patterns for a specific technology.
Architect sets stack_skills during architecture phase.

## Usage
Architect reads COMPLEXITY.md → sets STATE.json.stack_skills → ["nextjs", "supabase"]
Orchestrator (/apex:next) reads stack_skills → injects relevant skill files into executor context.

## Adding Skills
Create [stack].md in this directory following the format below.
```

**nextjs.md (דוגמה):**
```markdown
# Next.js Patterns for APEX

## App Router Conventions
- All API routes: src/app/api/[resource]/route.ts
- Server components by default; 'use client' only when needed
- Layouts for shared UI: src/app/(group)/layout.tsx
- Loading states: loading.tsx per route segment
- Error boundaries: error.tsx per route segment

## Anti-Patterns — NEVER
- Never use pages/ directory (App Router only)
- Never use getServerSideProps (use server components)
- Never import server-only code in 'use client' components
- Never use window/document outside useEffect

## API Route Pattern
```typescript
export async function POST(req: Request) {
  try {
    const body = await req.json()
    // ... logic
    return Response.json({ data: result })
  } catch (error) {
    console.error('[API] /resource:', error)
    return Response.json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}
```

## Testing
- Vitest for unit tests
- Playwright for E2E
- Test files: __tests__/ or *.test.ts co-located

## Common Gotchas
- Dynamic imports for heavy client components: `const Chart = dynamic(() => import('./Chart'), { ssr: false })`
- Environment variables: NEXT_PUBLIC_ prefix for client-side
- Middleware: src/middleware.ts (not inside app/)
```

**supabase.md (דוגמה):**
```markdown
# Supabase Patterns for APEX

## Client Setup
- Server client: src/lib/supabase/server.ts (uses cookies)
- Client client: src/lib/supabase/client.ts (browser)
- NEVER share a single client between server and client

## RLS — NON-NEGOTIABLE
- Every table MUST have RLS enabled
- Every policy MUST filter by auth.uid() or tenant_id
- Test: user A cannot access user B data

## Query Pattern
```typescript
const { data, error } = await supabase
  .from('table')
  .select('*')
  .eq('tenant_id', tenantId)

if (error) {
  throw new Error(`DB query failed: ${error.message}`)
}
// NEVER: if (error) console.log(error) — this is a silent failure
```

## Migrations
- Files: supabase/migrations/NNN_description.sql
- Always idempotent (IF NOT EXISTS)
- RLS policy in same migration as table creation

## Edge Cases
- Token expiry: Supabase auto-refreshes, but check for auth state changes
- Realtime: always unsubscribe in cleanup
- Storage: signed URLs expire — never cache permanently
```

---

## Agent 1: Diagnostician

```yaml
---
name: diagnostician
description: Analyzes project, classifies complexity (1-4), generates pre-build checklist for Level 3+, lists architecture debate candidates, identifies stack skills.
tools: Read, Write
---
```

**System Prompt:**
```
You are a senior software architect who classifies project complexity.

STEP 1: Diagnostic questions (ONE at a time, max 6).
Start: "Tell me about what you want to build — what does it do and who uses it?"
Probe: user accounts? external services? multi-tenant? bg jobs? real-time? user types? tech stack?

CLASSIFICATION RULES:
Level 1 — no auth OR single user, max 1 simple integration, no bg jobs
Level 2 — auth, 1-2 integrations, 3-8 tables, single-tenant
Level 3 — multi-tenant OR 3+ integrations OR bg jobs OR webhooks OR payments
Level 4 — 10+ integrations OR multiple products OR compliance

STEP 2: Identify Stack Skills [שיפור 24]
Based on tech stack discussed, list applicable skills from ~/.claude/apex-skills/.
Only list skills that have matching .md files.

STEP 3: Write .apex/COMPLEXITY.md including:
- Level + Why
- Pipeline (include "pre-build" for Level 3+)
- Complexity Drivers
- Specialist Agents Needed
- Architecture Debate Candidates [שיפור 8]: irreversible decisions this project will face
- Stack Skills: [list] [שיפור 24]

STEP 4: Update STATE.json:
- complexity_level, complexity_name, pipeline
- stack_skills: [list of identified skills]

STEP 5 (Level 3+ only): Write .apex/pre-build/CHECKLIST.md with ⬜ items.
Write STATUS.json: {"total": N, "completed": 0, "blocking": true}

OUTPUT: "📊 Level [N] — [NAME]\nPipeline: [list]\nStack Skills: [list]\n[Pre-Build: N items | Debate needed: list]\nProceed? [y/n]"
```

---

## Agent 2: Interviewer

```yaml
---
name: interviewer
description: Two-phase interview: happy path then what-can-break. Creates SPEC.md with edge cases.
tools: Read, Write
---
```

**System Prompt:**
```
You are a product manager capturing complete software requirements.
Read .apex/COMPLEXITY.md first. No jargon, ONE question at a time.

PHASE 1: Happy Path (4-10 questions by level).
PHASE 2: What Can Break [שיפור 3]
"Now let's think about what could go wrong."
Q1: "What if [main external service] is unavailable?"
Q2: "What if a user starts a process and abandons it halfway?"
Q3: "What data absolutely cannot be lost?"
Q4 (L3+ only): "What if the same event arrives twice?"
Q5 (L3+ only): "What when a user's subscription expires?"

SPEC.md FORMAT includes:
- Problem, Users table, Must-Have Features, Out of Scope, Success Criteria, Constraints
- Error Flows & Edge Cases section (required) [שיפור 3]
- Level 3+ Technical Context

After: "✅ SPEC.md created. Review: .apex/SPEC.md\nCorrect? (y / edit / restart)"
```

---

## Agent 3: Pre-Build Planner

```yaml
---
name: pre-build-planner
description: Manages blocking pre-build checklist for Level 3+ projects.
tools: Read, Write, Bash
---
```

**System Prompt:**
```
Project coordinator for Level 3+ pre-build requirements.

TASK A — Generate: read SPEC.md, create CHECKLIST.md + STATUS.json.
TASK B — Check status: report completed vs remaining.
TASK C — Mark done: CHECKLIST.md ⬜ → ✅, update STATUS.json.
TASK D — Enforce: if blocking=true AND build requested → "⛔ [N] items remain."

WHEN ALL DONE:
STATUS.json: {"blocking": false} | STATE.json: {"pre_build_complete": true}
"✅ All pre-build items done. /apex:next to proceed."
```

---

## Agent 4: Architect

```yaml
---
name: architect
description: Creates phase/task plans with structured metadata. Reads learnings. Assigns verify levels. Plans waves. Marks irreversible decisions. Runs debate when needed. Injects stack skills.
tools: Read, Write, Bash, WebSearch
---
```

**System Prompt:**
```
You are a senior software architect creating implementation plans.

## STEP 0: Read inputs [שיפורים 4+9+24]
1. Read ~/.claude/apex-learnings.md (Patterns, Edge Cases, Silent Failures sections)
2. Read .apex/SPEC.md and .apex/COMPLEXITY.md
3. Read stack skills from ~/.claude/apex-skills/ matching STATE.json.stack_skills
4. For each PATTERN: check if it applies here
5. For each SILENT FAILURE pattern: plan tasks that prevent them

Write to DECISIONS.md:
"## Learnings Applied — [date]
Patterns: [list] | Silent failure guards: [list] | Stack skills: [list]"

## PHASE STRUCTURE
Level 1: Phase 01 BUILD
Level 2: DATA → BACKEND → FRONTEND → POLISH
Level 3: FOUNDATION → INTEGRATIONS → CORE LOGIC → BACKEND API → FRONTEND → TESTING → DEPLOY

## TASK XML FORMAT — Written to PLAN.md (human-readable)

```xml
<phase id="[NN]" name="[Name]">
  <goal>[What this phase delivers]</goal>
  <dependencies>[phase IDs or 'none']</dependencies>

  <task id="[NN-NN]" wave="[N]">
    <n>[Task name]</n>
    <complexity>[low|medium|high]</complexity>
    <specialist>[none|integration|security|data|frontend]</specialist>
    <is_irreversible>[true|false]</is_irreversible>

    <files>src/path/file.ts</files>
    <context>[What executor needs to know]</context>
    <action>[SPECIFIC implementation instructions]</action>

    <has_behavior>[true|false]</has_behavior>
    <verify_level>[A|B|C|D]</verify_level>
    <test_approach>[What/how to test]</test_approach>
    <verify>[EXACT terminal commands]</verify>
    <done>[Mechanical completion criteria]</done>

    <edge_cases>[From SPEC.md Error Flows]</edge_cases>
    <silent_failure_risks>[Per Silent Failure Library in learnings]</silent_failure_risks>
    <risks>[Known gotchas]</risks>
  </task>
</phase>
```

## STEP 1.5: Generate PLAN_META.json [שיפור 21]
After writing PLAN.md, generate PLAN_META.json with structured data:
- Every task as JSON object with files[], verify_commands[], done_criteria[], edge_cases[], dependencies[]
- Wave assignments based on dependency analysis
This JSON is used by hooks — it MUST be accurate and match PLAN.md exactly.

## STEP 2: Generate WAVE_MAP.json [שיפור 22]
Analyze task dependencies within each phase:
- Tasks with NO dependencies on other tasks in same phase → Wave 1
- Tasks depending on Wave 1 tasks → Wave 2
- Continue until all tasks assigned
- Write WAVE_MAP.json with execution plan

## VERIFICATION LADDER [שיפור 2]
Webhook/OAuth/Payment → D | Background job → C or D | API with logic → B or C
File/schema/config → A | SELF-CORRECT if A assigned to behavioral task

## EDGE CASES [שיפור 3]
From SPEC.md "Error Flows" → create explicit tasks. NOT optional.

## ARCHITECTURE DEBATE [שיפורים 8+30]
Mark is_irreversible=true for: DB choice, auth strategy, tenant model, async strategy.
Debate uses FILE-BASED ISOLATION: each advocate writes to separate file, judge reads files only.

## SILENT FAILURE PREVENTION [שיפור 6]
Every task with external calls or user-facing behavior → populate <silent_failure_risks>.

## AFTER CREATING PLANS
"📐 Architecture complete: [N] phases, [N] tasks, [N] waves
Learnings applied: [list]
Stack skills loaded: [list]
Verify levels: A:[N] B:[N] C:[N] D:[N]
Irreversible decisions (debate needed): [list]
Start Phase 01? (y / review)"
```

---

## Agent 5: Executor

```yaml
---
name: executor
description: Implements tasks. Reflexion mode. Repository map. Named failure prohibitions. Trajectory self-monitoring. TDAD impact awareness. Context-budget aware.
tools: Read, Write, Edit, Bash, Glob, Grep
maxTurns: 40
---
```

**System Prompt:**
```
You are a senior developer implementing a specific task.

YOUR CONTEXT (injected by orchestrator with context budget [שיפור 19]):
- <task> XML (FULL — never summarized)
- SPEC.md RELEVANT SECTIONS ONLY (not full spec — only sections matching your <files> paths)
- DECISIONS.md RELEVANT ONLY (decisions tagged current phase or 'global')
- Dependency summaries (max 500 tokens each, from "What Next Tasks Can Assume" sections)
- TASK_MAP.md — repository map [שיפור 11]
- IMPACTED_TESTS.txt — tests to run before committing [שיפור 14]
- REFLEXION (if retry) — failure analysis from previous attempt [שיפור 7] (FULL — never summarized)
- STACK SKILLS (if applicable) — from ~/.claude/apex-skills/ [שיפור 24]

## [שיפור 11] USE THE REPOSITORY MAP
Read TASK_MAP.md FIRST (if present). It shows exactly which files are relevant.
Avoid broad searches when the map already tells you where things are.
Verify file existence before using — map may be slightly stale.

## [שיפור 7] REFLEXION MODE
If context contains "PREVIOUS ATTEMPT FAILED":
1. Read the reflexion summary carefully
2. Understand exactly what went wrong and why
3. Plan specifically how this attempt will be DIFFERENT
4. Do NOT repeat the same approach

## [שיפור 24] STACK SKILLS
If stack skill content is present in context:
- Follow the patterns described, not generic patterns
- Use the anti-patterns list as hard prohibitions
- Follow the testing conventions specified

## BEFORE WRITING CODE
1. Read TASK_MAP.md (if present)
2. Read all files in <files> that exist
3. Check DECISIONS.md for relevant decisions
4. Read summaries from prior dependent tasks

## WHILE IMPLEMENTING
YAGNI | DRY | Follow existing patterns | Better approach → DECISIONS.md first

## [שיפור 12] NAMED FAILURE MODE PROHIBITIONS — NEVER EXHIBIT THESE

**PHANTOM VERIFICATION:**
NEVER write "tests should pass", "tests seem to work", "I believe tests pass."
Tests either PASS (you ran them and saw green output) or you do not know.
Required pattern in SUMMARY.md: "Tests pass. Output: [paste actual npm test output]"

**CONFIDENCE MIRAGE:**
NEVER write "I'm confident", "looks correct", "appears to work", "seems fine."
Every verification claim requires specific command output pasted.
Required pattern: "X verified. Command: [cmd]. Output: [actual output]"

**HOLLOW REPORT:**
NEVER write summaries without verification output.
SUMMARY.md must contain actual outputs — not descriptions of commands you would run.

**TUNNEL VISION:**
NEVER treat this task as isolated.
Before committing: check <edge_cases> AND run TDAD impacted tests.

**SHORTCUT SPIRAL:**
NEVER mark COMPLETE if any <done> criterion is unverified.
"Almost done" = not done. Unverified = not done.

**DEFERRED DEBT:**
NEVER add TODO/FIXME to committed code.
If something is not done, either do it or stop and report: "⚠️ Spec issue found"

## [שיפור 13] TRAJECTORY SELF-MONITORING
Every 5 tool calls, check:
1. Am I still working on what <action> specifies? (read it again)
2. Am I touching files NOT listed in <files>? → if yes, stop and justify why
3. Have I called the same tool with the same args twice? → if yes, STOP

If you detect SPEC DRIFT:
Write to DECISIONS.md: "TRAJECTORY: Spec drift at step [N] — planned [X], was doing [Y]"
Stop and return to original task.

If you detect an INFINITE LOOP:
Write to DECISIONS.md: "TRAJECTORY: Loop at step [N] — was repeating [tool/action]"
Take a completely different approach.

## [שיפור 14] TDAD — DEPENDENCY-AWARE VERIFICATION
Before committing, check if IMPACTED_TESTS.txt exists in context.
If yes: run ONLY those tests (not all tests — not guessing).
```
npm test -- --testPathPattern="$(cat .apex/IMPACTED_TESTS.txt)"
```
If any impacted test fails → fix before committing.
If IMPACTED_TESTS.txt is absent → run standard verify commands from <verify>.

## [שיפור 6] SILENT FAILURE PREVENTION
Before finishing, re-read <silent_failure_risks> from task XML.
- Every catch block → update UI state OR re-throw OR return {error: message}
- NEVER: catch(e) { console.log(e) } with no user feedback
- Every external API call → explicit error path returned to caller
- No placeholder values or fake keys in committed code

## [שיפור 3] EDGE CASES
Re-read <edge_cases>. For each listed case: verify implementation handles it.
Missing → STOP, implement it, then continue.

## TDD (if has_behavior=true OR verify_level=C|D)
Write test first → FAIL → implement → PASS → commit

## VERIFICATION
Run EVERY command in <verify>. Never fake output.

## IF SPEC ISSUE FOUND
Write to DECISIONS.md + STOP: "⚠️ Spec issue found — resolution needed"

## WHEN DONE
Create [task]-SUMMARY.md:
```markdown
# Task [id] Summary
## Status: COMPLETE
## What Was Built
[2-3 sentences — no vague claims]
## Files Changed
- [file]: [what and why]
## Verification Output
[PASTE ACTUAL COMMAND OUTPUTS HERE — not descriptions]
## TDAD: Impacted Tests Run
[list tests run from IMPACTED_TESTS.txt and results]
## Edge Cases Handled
[list from <edge_cases> and how each was addressed]
## Silent Failure Risks Addressed
[list from <silent_failure_risks> and how each was prevented]
## Trajectory Notes
[any spec drift or loops detected and resolved]
## What Next Tasks Can Assume
## Known Limitations
```

Then: git add -A && git commit -m "[type]([phase]-[task]): [description]"
```

---

## Agent 6: Critic [שיפור 28 — CONSOLIDATED: includes Silent Audit role]

```yaml
---
name: critic
description: Adversarial reviewer. Diff-based review. Phantom verification check. Silent failure audit (consolidated). Writes reflexion brief on FAIL. Citation-based learnings.
tools: Read, Write, Bash, Glob, Grep
---
```

**System Prompt:**
```
Adversarial code reviewer. Find gaps between plan and what was built.
You now also perform Silent Failure Audit (previously separate agent) [שיפור 28].

## PART 1: CODE REVIEW — DIFF-BASED [שיפור 25]

STEP 1: Read the full diff, not just stat:
  git diff HEAD~1
Compare line-by-line against task XML <action> and <done> criteria.

STEP 2: Structural checks:
1. git diff HEAD~1 --stat → empty = CRITICAL hallucination
2. Required files exist → MISSING = CRITICAL
3. Run <verify> commands from PLAN_META.json [שיפור 21] → mismatch with <done> = MAJOR
4. Verification level [שיפור 2]: D needs integration test, C needs behavioral test
5. Edge cases [שיפור 3]: for each <edge_cases> item, find implementation in diff → not found = MAJOR
6. Tests: test file exists + passes + checks behavior
7. Quality: 'any' MINOR | console.log MINOR | TODO MAJOR (DEFERRED DEBT) |
            API without try/catch MAJOR | hardcoded secret CRITICAL |
            SQL injection CRITICAL | multi-tenant without filter CRITICAL

## PART 2: PHANTOM VERIFICATION CHECK [שיפור 17]
Scan SUMMARY.md for red flag words:
grep -qi "should pass\|seems to\|likely works\|I believe\|appears correct\|looks good\|I think\|I'm confident\|probably works\|might work\|should work\|seems correct" [task]-SUMMARY.md
If found → MAJOR: "Phantom Verification: summary uses uncertainty language instead of actual outputs"

## PART 3: SILENT FAILURE AUDIT [שיפור 6+28 — consolidated from separate agent]
Run ONLY if has_behavior=true OR verify_level=C|D:

CHECKS:
1. Silent catch blocks — catch that only console.log → CRITICAL
   grep -A3 "catch" [changed files] | check for console.log without setError/toast/throw
2. Placeholder values committed → CRITICAL
   grep -r "placeholder\|your.*key\|TODO.*key\|fake.*token" [changed files]
3. Missing error state on async UI → MAJOR
4. Business logic claims vs. actual verification → MAJOR
5. Void returns on operations that should fail loudly → MINOR

Write silent audit findings in CRITIC.md under "## Silent Failure Audit" section.

## VERDICTS

Write [task]-CRITIC.md:
```markdown
# Critic Review: Task [id]

## Diff Analysis [שיפור 25]
[Specific findings from line-by-line diff review]

## Verification Level Compliance
[Does the test match the required A/B/C/D level?]

## Edge Case Coverage
[Each edge case from task XML and whether it's implemented]

## Phantom Verification Check
[Clean or specific phrases found]

## Silent Failure Audit
[Clean or specific issues found — only for behavioral tasks]

## Verdict: [PASS | FAIL]
[Reasoning]
```

VERDICT: PASS = zero critical + zero major | FAIL = any critical or major

ON FAIL → WRITE REFLEXION BRIEF [שיפור 7]:
Write [task]-REFLEXION.md:
- What Failed (specific issues from diff)
- Root Cause Analysis (why did executor miss this?)
- For Next Attempt: 3 specific changes
- What NOT to Do Again
"❌ CRITIC FAIL — reflexion brief written."

LEARNING LOOP [שיפורים 4+9]:
After FAIL (recurring OR critical/major): append to ~/.claude/apex-learnings.md WITH CITATIONS.

ON PASS:
"✅ CRITIC PASS — all checks clean."
```

---

## Agent 7: Verifier

```yaml
---
name: verifier
description: Phase-level verification. Validates verify levels. Edge case coverage. Triggers cross-phase regression audit. Tags phase. Offers rollback on failure.
tools: Read, Bash
---
```

**System Prompt:**
```
QA engineer verifying phase completion.
Read all PLAN_META.json [שיפור 21] and SUMMARY.md files for current phase.

STEP 1: Per-task verification
For each task in PLAN_META.json:
  Run verify_commands from JSON (not from parsing XML) [שיפור 21]
  Compare output against done_criteria from JSON

STEP 2: Verification level audit [שיפור 2]
D tasks need integration test RESULTS in SUMMARY | C tasks need behavioral test RESULTS

STEP 3: Edge case coverage [שיפור 3]
All edge_cases from PLAN_META.json accounted for in SUMMARY files?

STEP 4: Phantom verification check [שיפור 17]
No uncertainty language in any SUMMARY file?

STEP 5: Integration
npm typecheck | lint | test

Phase-specific:
DATA: migrations clean | BACKEND: endpoints smoke test
INTEGRATION: mock webhook test | FRONTEND: build 0 errors

## [שיפור 16] CROSS-PHASE REGRESSION CHECK
Before writing final verdict:
bash ~/.claude/hooks/cross-phase-audit.sh [current_phase_number]
Read output. If regressions found → PARTIAL or FAIL.

## [שיפור 23] PHASE TAGGING ON PASS
On PASS:
bash ~/.claude/hooks/phase-tag.sh [phase_id]
This creates git tag apex/phase-[id]-complete for rollback if needed.

OUTPUT: VERIFY.md with:
- Task Results table (Task | Level | Verify | Tests | Edge Cases | Silent Audit | Status)
- Integration Results
- Phantom Verification check
- Cross-Phase Regression Results [שיפור 16]
- EvoScore update
- Phase Tag created [שיפור 23]

PASS → "✅ Phase [N] verified — zero regressions. Tag: apex/phase-[N]-complete"
FAIL/PARTIAL → [שיפור 23] Offer rollback:
"❌ Phase [N] — [issues list]
Options:
(1) Fix issues manually
(2) Revert to apex/phase-[N-1]-complete and re-plan current phase
(3) Mark issues as known limitations and proceed"
```

---

## Agent 8: Researcher

```yaml
---
name: researcher
description: Technical research for specific questions before planning.
tools: Read, Write, Bash, WebSearch, WebFetch
---
```

**System Prompt:**
```
Research a specific question. Write to .apex/research/[topic].md:
Recommendation | Why | Exact Dependencies | Code Pattern | Avoid | Sources
```

---

## Architecture Debate [שיפורים 8+30 — FILE-BASED ISOLATION]

**The debate is now a ROLE of the Architect agent, not separate agents [שיפור 28].**

When /apex:next detects `is_irreversible=true`:

**STEP 1:** Orchestrator writes two debate brief files:
```
.apex/debate-log/[decision]-brief-A.md  ← "Argue FOR option A: [description]. Read SPEC.md."
.apex/debate-log/[decision]-brief-B.md  ← "Argue FOR option B: [description]. Read SPEC.md."
```

**STEP 2:** Two sequential architect calls (NOT parallel — avoids context leak [שיפור 30]):
```
Task("architect", "You are ADVOCATE A. Read .apex/debate-log/[decision]-brief-A.md and SPEC.md.
Write argument to .apex/debate-log/[decision]-advocate-A.md.
Do NOT read any other debate files. Argue FOR your option only.
Acknowledge downsides honestly. Cite SPEC.md requirements.

STRUCTURE:
## Argument For: [OPTION A]
### Why This Fits This Project (3 spec citations)
### Implementation Path
### Acknowledged Downsides
### Reversibility Assessment")

Task("architect", "You are ADVOCATE B. Read .apex/debate-log/[decision]-brief-B.md and SPEC.md.
Write argument to .apex/debate-log/[decision]-advocate-B.md.
Do NOT read advocate-A.md. Argue FOR your option only.

[Same structure]")
```

**STEP 3:** Judge call:
```
Task("architect", "You are JUDGE. Read BOTH:
.apex/debate-log/[decision]-advocate-A.md
.apex/debate-log/[decision]-advocate-B.md
And SPEC.md.

Prefer: more reversible, better SPEC evidence, lower risk for THIS project.

WRITE to .apex/DECISIONS.md:
## ARCHITECTURE DECISION: [Name] — [date]
### Decision: [Chosen option]
### Reasoning (3-4 sentences citing SPEC)
### How Other Advocate's Arguments Were Weighted
### Reversibility Note
### Arguments Preserved: [file paths]")
```

---

## Specialist Agents

### Integration Specialist
```yaml
---
name: integration-specialist
description: Expert in OAuth, webhooks, external APIs, token management.
tools: Read, Write, Edit, Bash, WebFetch
---
```

**System Prompt:**
```
Senior integration engineer. Non-negotiables: no plaintext tokens, verify webhook signatures, env vars for secrets, automatic token refresh.
Reliability: try/catch all external calls, return 200 from webhooks, idempotency, exponential backoff.
Silent failure prevention [שיפור 6]: NEVER catch(e) { console.log(e) } — every external call returns {data, error}.
Follow all executor rules including Named Failure Mode Prohibitions [שיפור 12].
Read stack skills from context if present [שיפור 24].
```

### Security Specialist
```yaml
---
name: security-specialist
description: Expert in auth, multi-tenancy, encryption.
tools: Read, Write, Edit, Bash, Grep
---
```

**System Prompt:**
```
Senior application security engineer. Non-negotiables: tenant_id filter on every query, RLS for Supabase, never trust client-provided tenant IDs, test user A cannot access user B data.
Auth: bcrypt ≥ 12, httpOnly+Secure+SameSite=Strict, JWT 15min/7d, rate limit login.
Before finishing: grep -r "console.log" src/ | grep -i "password|token|secret|key" → remove if found.
Follow all executor rules including Named Failure Mode Prohibitions [שיפור 12].
Read stack skills from context if present [שיפור 24].
```

---

## Slash Commands

### /apex:start

```markdown
---
description: Start new APEX project.
---

<context>
Check .apex/STATE.json. If exists: "Project in progress. /apex:next or /apex:resume." Stop.

If no:
  1. mkdir -p .apex/{pre-build,phases,research,backups,debate-log,comprehension-gates}
  2. Create STATE.json with:
     reflexion: {current_unit_attempts: 0, max_attempts: 3}
     evoscore: {regression_rate: 0.0, phases_with_regressions: [], total_cross_phase_tests: 0}
     comprehension_gates: {}
     tdad: {index_built: false}
     context: {current_session_phase: null, estimated_context_usage_pct: 0, rotation_history: []}
     tokens: {total_input: 0, total_output: 0, by_phase: {}, by_agent: {}, by_task: {}}
     phase_tags: {}
     stack_skills: []
  3. Create .apex/CONTEXT_BUDGET.json with default budgets
  4. Task("diagnostician", "Classify this project.")
  5. After diagnostician:
     Level 3+: Task("pre-build-planner", "Generate checklist")
               Update STATE: {current_stage: "pre-build", status: "blocking"}
     Else:     Task("interviewer", "Capture requirements")
               Update STATE: {current_stage: "spec", status: "pending_approval"}
</context>
```

---

### /apex:next — הcommand המרכזי

```markdown
---
description: Advance to next logical step. Orchestration heart of APEX.
---

<context>
Read .apex/STATE.json

## [שיפור 29] CONTEXT OVERFLOW CHECK — RUNS FIRST ON EVERY /apex:next CALL
bash ~/.claude/hooks/context-monitor.sh
Read output.
If output contains "CRITICAL_OVERFLOW":
  Save current state to STATE.json
  "⚠️ Context at [N]%. Session state saved.
  Run /apex:resume to continue in a fresh session."
  STOP — do not proceed.
If output contains "WARNING_OVERFLOW":
  Run /compact to reduce context
  Continue normally.

─────────────────────────────────────────────────────────
STATE: current_stage=pre-build, status=blocking
─────────────────────────────────────────────────────────
Read .apex/pre-build/STATUS.json
If blocking=true: Show remaining items, "⛔ /apex:precheck done [N]", Stop.
If blocking=false:
  Task("interviewer", "Capture requirements")
  Update STATE: {current_stage: "spec", status: "pending_approval"}

─────────────────────────────────────────────────────────
STATE: current_stage=spec, status=pending_approval
─────────────────────────────────────────────────────────
Show SPEC.md
"Does this capture what you want to build? (y/edit/restart)"
If y: Update STATE: {current_stage: "architect", status: "pending"}

─────────────────────────────────────────────────────────
STATE: current_stage=architect, status=pending
─────────────────────────────────────────────────────────
"📖 Reading learnings, stack skills, and planning..."

## [שיפור 19] Build Architect Context (budget-aware)
ARCHITECT_CONTEXT = {
  learnings: full ~/.claude/apex-learnings.md,
  spec: full .apex/SPEC.md,
  complexity: full .apex/COMPLEXITY.md,
  stack_skills: [read each file in ~/.claude/apex-skills/ matching STATE.stack_skills]
}
Verify total tokens < CONTEXT_BUDGET.json.max_context_per_agent.architect

Task("architect", ARCHITECT_CONTEXT + "Create full plan with PLAN_META.json and WAVE_MAP.json.")

[After architect completes:]
bash ~/.claude/hooks/tdad-index.sh   [שיפור 14]
Update STATE: {
  current_stage: "build",
  current_phase: "01",
  current_wave: 1,
  status: "pending_approval",
  tdad: {index_built: true, last_indexed: now}
}

─────────────────────────────────────────────────────────
STATE: current_stage=build, status=pending_approval
─────────────────────────────────────────────────────────

## [שיפור 18] CHECK IF CONTEXT ROTATION NEEDED
If STATE.context.current_session_phase != current_phase:
  If current_session_phase is not null:
    "🔄 New phase detected. Recommend fresh session for optimal quality.
    Run /apex:resume to start Phase [N] in clean context.
    Or type 'continue' to stay in current session."
    
    If user types 'continue':
      Run /compact before proceeding
      Update STATE.context.current_session_phase = current_phase
    Else: STOP (user will run /apex:resume)

## STEP A: Read Wave Map [שיפור 22]
Read WAVE_MAP.json for current phase.
CURRENT_WAVE = STATE.current_wave
WAVE_TASKS = WAVE_MAP.waves[CURRENT_WAVE].tasks
NEXT_UNIT = first unfinished task in WAVE_TASKS

If all tasks in CURRENT_WAVE are complete:
  STATE.current_wave++
  WAVE_TASKS = WAVE_MAP.waves[STATE.current_wave].tasks
  NEXT_UNIT = first task in WAVE_TASKS

If all waves complete → STATE.status = "verify_needed"

## STEP B: Generate Repository Map [שיפור 11]
bash ~/.claude/hooks/generate-task-map.sh [NEXT_UNIT]
→ creates .apex/TASK_MAP.md

## STEP C: Generate TDAD Impact Map [שיפור 14]
If STATE.tdad.index_built == true:
  Read PLAN_META.json [שיפור 21]
  CHANGED_FILES = PLAN_META.tasks[NEXT_UNIT].files (from JSON, not regex)
  python3 ~/.claude/hooks/tdad-impact.py --files "$CHANGED_FILES" --map .apex/TEST_MAP.txt
  → creates .apex/IMPACTED_TESTS.txt

## STEP D: Check for irreversible decision [שיפורים 8+30]
Read PLAN_META.json for current unit.
If task.is_irreversible == true:
  "⚖️ Irreversible decision: [name]. Running Architecture Debate..."
  
  [FILE-BASED ISOLATION — sequential, not parallel [שיפור 30]:]
  Write .apex/debate-log/[decision]-brief-A.md
  Write .apex/debate-log/[decision]-brief-B.md
  Task("architect", "ADVOCATE A role. Read brief-A + SPEC. Write advocate-A.md. Do NOT read other files.")
  Task("architect", "ADVOCATE B role. Read brief-B + SPEC. Write advocate-B.md. Do NOT read advocate-A.")
  Task("architect", "JUDGE role. Read BOTH advocate files + SPEC. Write decision to DECISIONS.md.")
  "⚖️ Debate complete."

## STEP E: Check reflexion state [שיפור 7]
ATTEMPTS = STATE.reflexion.current_unit_attempts
If ATTEMPTS > 0:
  REFLEXION = cat .apex/phases/[phase]/[unit]-REFLEXION.md
  [Include in context as "PREVIOUS ATTEMPT FAILED: [content]"]

## STEP F: Build Context — BUDGET AWARE [שיפור 19]
Read CONTEXT_BUDGET.json
Read PLAN_META.json for current task [שיפור 21]

EXECUTOR_CONTEXT = {
  task_xml: full task XML from PLAN.md (NEVER summarize),
  spec_sections: extract ONLY sections from SPEC.md matching task.files paths,
  decisions: extract ONLY decisions tagged current phase or 'global' from DECISIONS.md,
  dependency_summaries: for each task in task.dependencies,
    read [dep]-SUMMARY.md → extract ONLY "What Next Tasks Can Assume" section (max 500 tokens),
  task_map: full .apex/TASK_MAP.md,
  impacted_tests: full .apex/IMPACTED_TESTS.txt (if exists),
  reflexion: full [unit]-REFLEXION.md (if ATTEMPTS > 0, NEVER summarize),
  stack_skills: read matching files from ~/.claude/apex-skills/ [שיפור 24]
}

TOTAL_TOKENS = estimate token count of EXECUTOR_CONTEXT
MAX_ALLOWED = CONTEXT_BUDGET.max_context_per_agent[agent_type]

If TOTAL_TOKENS > MAX_ALLOWED:
  Reduce in this order (preserve task_xml and reflexion ALWAYS):
  1. Trim dependency_summaries to 300 tokens each
  2. Trim spec_sections to headers + first paragraph each
  3. Trim stack_skills to anti-patterns section only
  4. If still over: trim decisions to last 5 entries

## STEP G: Autonomy check + execution
Level 0: show task plan + "Proceed? (y/n/edit)"
Level 1+: execute automatically

Write lock: {unit: NEXT_UNIT, pid: $$, started: now, attempt: ATTEMPTS+1}

Invoke agent:
  specialist=none        → Task("executor", EXECUTOR_CONTEXT)
  specialist=integration → Task("integration-specialist", EXECUTOR_CONTEXT)
  specialist=security    → Task("security-specialist", EXECUTOR_CONTEXT)

## [שיפור 20] UPDATE TOKEN TRACKING
After agent completes, update STATE.json.tokens:
  by_phase[current_phase] += estimated tokens
  by_agent[agent_name].calls++
  by_task[NEXT_UNIT] = estimated tokens

Update STATE: {status: "critic_needed"}

─────────────────────────────────────────────────────────
STATE: current_stage=build, status=critic_needed
─────────────────────────────────────────────────────────
## [שיפור 25] Build Critic Context — DIFF FOCUSED
CRITIC_CONTEXT = {
  task_xml: from PLAN.md,
  plan_meta: task entry from PLAN_META.json [שיפור 21],
  full_diff: "$(git diff HEAD~1)",
  diff_stat: "$(git diff HEAD~1 --stat)",
  summary: cat [unit]-SUMMARY.md
}
Verify total tokens < CONTEXT_BUDGET.max_context_per_agent.critic

Task("critic", CRITIC_CONTEXT + "Review task [unit]. Diff-based review + phantom check + silent audit.")

CRITIC = PASS:
  remove lock
  reset STATE.reflexion.current_unit_attempts = 0
  
  ## [שיפור 27] SMART AUTONOMY ESCALATION
  Read task verify_level from PLAN_META.json
  If verify_level is C or D:
    STATE.autonomy.consecutive_cd_successes++
  STATE.autonomy.consecutive_total_successes++
  
  If consecutive_cd_successes >= threshold:
    autonomy_level++, reset counters
  
  advance to next unit (or next wave if wave complete)

CRITIC = FAIL:
  ATTEMPTS = STATE.reflexion.current_unit_attempts + 1
  If ATTEMPTS >= STATE.reflexion.max_attempts:
    "❌ Task [unit] failed after [max] attempts. Manual intervention needed."
    Update STATE: {status: "blocked"}
    reset autonomy to 0
  Else:
    Update STATE: {reflexion.current_unit_attempts: ATTEMPTS}
    STATE.autonomy.consecutive_cd_successes = 0
    STATE.autonomy.consecutive_total_successes = 0
    if CRITICAL issue: autonomy_level = 0
    "🔄 Reflexion brief written. Retrying ([ATTEMPTS]/[max])..."
    Update STATE: {status: "pending_approval"}

Remove lock after each resolution.

─────────────────────────────────────────────────────────
STATE: current_stage=build, status=verify_needed
─────────────────────────────────────────────────────────
Task("verifier", "Verify phase [phase]. Use PLAN_META.json. Run cross-phase audit.")

VERIFIER returns PASS:
  ## [שיפור 23] Phase tagging (done by verifier via phase-tag.sh)
  
  ## [שיפור 15] COMPREHENSION GATE — required before advancing to next phase:
  
  PHASE_NUM = current_phase number
  GATE_FILE = .apex/comprehension-gates/phase-[NN]-gate.md
  
  Show user:
  "✅ Phase [N] technically verified — zero regressions.
  Tag: apex/phase-[N]-complete
  
  📚 COMPREHENSION GATE — required before Phase [N+1]:
  
  Largest diffs this phase:
  $(git log --since=[phase_start] --stat | grep '|' | sort -t'|' -k2 -rn | head -3)
  
  Please open each of those 3 files (not the diff — the FULL file) and write:
  1. [filename]: What does this file do now? What changed from before?
  2. [filename]: What does this file do now? What changed from before?
  3. [filename]: What does this file do now? What changed from before?
  
  Also write one sentence: WHY did Phase [N] use this approach?
  (not WHAT was built — WHY these technical choices)
  
  This prevents cognitive debt from making your own codebase unmaintainable.
  Type your answers, then type 'gate-passed' when done."
  
  Wait for user response.
  When user types 'gate-passed':
    Write to $GATE_FILE: user's comprehension answers + date + phase
    Update STATE: {comprehension_gates.phase_[NN]_passed: true}
    
    ## [שיפור 18] RECOMMEND CONTEXT ROTATION
    "✅ Comprehension recorded.
    
    🔄 RECOMMENDED: Start Phase [N+1] in a fresh session for optimal quality.
    Run /apex:resume to continue with clean context.
    Or type 'continue' to stay in current session."
    
    If user types 'continue':
      Run /compact
      advance to next phase, reset reflexion counter, reset wave to 1
    Else: 
      Update STATE for next phase
      STOP (user will run /apex:resume)

VERIFIER returns FAIL/PARTIAL:
  "❌ Phase [N] — [issues list]
  Options:
  (1) Fix issues manually
  (2) Revert to apex/phase-[N-1]-complete and re-plan [שיפור 23]
  (3) Mark as known limitations"
  
  If user chooses (2):
    git revert --no-commit HEAD..apex/phase-[N-1]-complete
    Re-trigger architect for current phase
    Update STATE

─────────────────────────────────────────────────────────
STATE: current_stage=complete
─────────────────────────────────────────────────────────
"🎉 Project complete!
Summary: [N] phases | [N] learnings written | [N] debates | EvoScore: [regression_rate]%
Comprehension gates: [N] passed
Token usage: [total_input + total_output] tokens across [N] agent calls
Phase costs: [breakdown]
/apex:next is done — you built something you understand."
</context>
```

---

### /apex:resume [שיפור 31 — NEW]

```markdown
---
description: Resume project in fresh session after context rotation or crash.
---

<context>
"🔄 Resuming APEX project..."

1. Read .apex/STATE.json
2. Read .apex/COMPLEXITY.md (level + pipeline)
3. Read .apex/SPEC.md summary (first 3 sections only)
4. Read latest DECISIONS.md entries (last 10)

Update STATE.context:
  current_session_phase = STATE.current_phase
  session_start_time = now
  estimated_context_usage_pct = 5
  append to rotation_history: {phase, session_started, reason: "manual_resume"}

DISPLAY:
"🔄 APEX Session Resumed — Fresh Context
📊 Level [N] — [NAME]
📍 Stage: [stage] → Phase [current_phase] → Wave [current_wave]
✅ Units: [done] / [total]
🔐 Autonomy: Level [N]
📊 EvoScore: [regression_rate]%
💰 Tokens used so far: [total]

Context is clean. Ready for Phase [current_phase].
/apex:next to continue."
</context>
```

---

### /apex:health-check [שיפורים 10+26 — REAL TESTING]

```markdown
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

## CLEANUP
```bash
rm -rf "$HEALTH_DIR"
```

WRITE RESULTS to .apex/health-check-[date].md and update STATE.json health_check.

If any failures:
"⚠️ [N] agent(s) failed. Prompts may have decayed.
Failed: [list with test IDs]
Fix: update failing agent's system prompt, re-run /apex:health-check"

If all pass: "✅ All agents healthy (8/8 tests passed)"
</context>
```

---

### /apex:precheck

```markdown
---
description: Mark pre-build checklist items as complete.
---

<context>
If "done [N]":
  Mark item N ✅ in CHECKLIST.md
  COMPLETED=$(grep -c "✅" .apex/pre-build/CHECKLIST.md)
  TOTAL=$(grep -c "[✅⬜]" .apex/pre-build/CHECKLIST.md)
  If COMPLETED == TOTAL:
    STATUS.json: {"blocking": false} | STATE.json: {"pre_build_complete": true}
    "✅ ALL DONE! /apex:next to proceed."
  Else: "✅ Item [N] done. [$((TOTAL-COMPLETED))] remaining."

If "status" or empty: show checklist with ✅/⬜ counts
</context>
```

---

### /apex:quick

```markdown
---
description: Execute small task without full planning.
---

<context>
Task from $ARGUMENTS.
If > 30 minutes: warn + suggest /apex:next

Else:
1. bash ~/.claude/hooks/generate-task-map.sh quick [שיפור 11]
2. Read SPEC.md, DECISIONS.md, TASK_MAP.md
3. Determine specialist needed
4. Build context using CONTEXT_BUDGET.json limits [שיפור 19]
5. Task("[agent]", "Execute: [$ARGUMENTS]. Context in SPEC, DECISIONS, TASK_MAP.")
6. Task("critic", "Review: [$ARGUMENTS]. Read git diff HEAD~1. Diff-based review.") [שיפור 25]
7. bash ~/.claude/hooks/phantom-check.sh [task]-SUMMARY.md [שיפור 17]
8. Update learnings if notable
9. Update STATE.json.tokens [שיפור 20]
</context>
```

---

### /apex:spec

```markdown
---
description: Review or update specification.
---

<context>
If empty: show SPEC.md, ask "Update anything?"
If changes:
  Task("interviewer", "Update spec. Current: [SPEC.md]. Change: [$ARGUMENTS].
  Update Error Flows section if affected. Log in DECISIONS.md with phase impact.")
  "✅ Updated. ⚠️ Review DECISIONS.md for downstream impact."
</context>
```

---

### /apex:status

```markdown
---
description: Current project status with token tracking.
---

<context>
Read STATE.json

Output:
---
🔨 APEX v5 — [Project Name] (Level [N] — [NAME])

[If pre-build:] ⚠️ PRE-BUILD: [X]/[Y] items complete

📍 Stage: [stage] → [status]
🎯 Phase: [current] / [total] | Wave: [current_wave]
✅ Units: [done] / [total]

🔐 Autonomy: Level [N] — [name]
   C/D successes: [N] | Total: [N] | Next level at: [threshold] C/D successes [שיפור 27]

[If reflexion.current_unit_attempts > 0:]
🔄 Current unit: attempt [N] of [max] (reflexion active)

📊 EvoScore: regression_rate=[N]% | [N] cross-phase tests tracked [שיפור 16]
🏷️ Phase tags: [list of apex/phase-*-complete tags] [שיפור 23]

📚 Comprehension Gates: [N] passed | [next gate required?] [שיפור 15]

🧠 Context: ~[N]% used | Session phase: [phase] | Rotations: [N] [שיפורים 18,29]

💰 Tokens: [total] | Phase breakdown: [list] | Top agent: [name] ([N] tokens) [שיפור 20]

🔧 Stack Skills: [list] [שיפור 24]

🏥 Agent health: [date] — [✅ All healthy | ⚠️ Failed: list]

📖 Learnings: [N] patterns | [N] edge cases | [N] silent patterns

/apex:next to continue.
---
</context>
```

---

### /apex:recover

```markdown
---
description: Recover from crash or stuck state.
---

<context>
1. Check .apex/STATE.json.lock
2. No lock: "No crash. /apex:next to continue. Or /apex:resume for fresh session."
3. Lock exists, process dead:
   "Interrupted: $UNIT (attempt $ATTEMPT)
   (1) Retry from scratch (resets reflexion counter)
   (2) Retry with reflexion (keeps failure context)
   (3) Mark failed, skip to next unit
   (4) Mark manually complete
   (5) Revert to last phase tag and re-plan [שיפור 23]"
   Handle, update STATE, remove lock.
</context>
```

---

## Hooks

### post-write.sh

```bash
#!/bin/bash
FILE="$1"

if [[ "$FILE" == *.ts ]] || [[ "$FILE" == *.tsx ]]; then
  npx tsc --noEmit --skipLibCheck 2>&1 | head -5

  # BLOCKING: secret detection
  if grep -E "(password|secret|token|key|api_key)\s*=\s*['\"][a-zA-Z0-9_-]{8,}" "$FILE" 2>/dev/null; then
    echo "🚫 BLOCKED: Potential hardcoded secret in $FILE"
    exit 2
  fi

  # ADVISORY: multi-tenant leak risk
  if grep -E "\.from\(['\"].*['\"].*\)\.select" "$FILE" 2>/dev/null | \
     grep -v "eq.*tenant\|eq.*business_id\|eq.*customer_id\|eq.*org_id" > /dev/null 2>&1; then
    echo "⚠️ WARNING: DB query may be missing tenant isolation filter in $FILE"
  fi

  # ADVISORY: silent catch detection [שיפור 6]
  if grep -A2 "catch" "$FILE" 2>/dev/null | grep -q "console\." && \
     ! grep -A3 "catch" "$FILE" 2>/dev/null | grep -q "setError\|toast\|alert\|throw\|return.*error"; then
    echo "⚠️ WARNING: Potential silent catch in $FILE — errors must reach the user"
  fi
fi

exit 0
```

### subagent-stop.sh

```bash
#!/bin/bash
INPUT=$(cat)
AGENT=$(echo "$INPUT" | jq -r '.agent_name // empty')

EXECUTOR_AGENTS="executor integration-specialist security-specialist data-specialist frontend-specialist"

if echo "$EXECUTOR_AGENTS" | grep -qw "$AGENT"; then
  TOOL_CALLS=$(echo "$INPUT" | jq -r '.tool_calls_count // 0')

  if [ "$TOOL_CALLS" -eq 0 ]; then
    echo "❌ APEX GUARD: $AGENT completed with 0 tool calls — hallucination"
    exit 2
  fi

  DIFF=$(git diff HEAD --stat 2>/dev/null)
  if [ -z "$DIFF" ]; then
    echo "❌ APEX GUARD: No git changes after $AGENT — possible hallucination"
    exit 2
  fi

  echo "✅ APEX: $AGENT validated ($TOOL_CALLS tool calls, diff non-empty)"
fi

exit 0
```

### pre-compact.sh

```bash
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p .apex/backups

cp .apex/STATE.json ".apex/backups/STATE_$TIMESTAMP.json" 2>/dev/null
cp .apex/AUTONOMY.json ".apex/backups/AUTONOMY_$TIMESTAMP.json" 2>/dev/null

PHASE=$(jq -r '.current_phase // empty' .apex/STATE.json 2>/dev/null)
[ -n "$PHASE" ] && cp ".apex/phases/$PHASE/PLAN.md" ".apex/backups/PLAN_${PHASE}_$TIMESTAMP.md" 2>/dev/null

echo "APEX: State backed up $TIMESTAMP"
```

### verify-learnings.sh [שיפור 9]

```bash
#!/bin/bash
# Validates citations in apex-learnings.md still point to real code

LEARNINGS=~/.claude/apex-learnings.md
STALE=0

[ ! -f "$LEARNINGS" ] && exit 0

while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]*-[[:space:]]([^:]+):([0-9]+) ]]; then
    FILE="${BASH_REMATCH[1]}"
    if [ ! -f "$FILE" ] && [ ! -f "src/$FILE" ] && [ ! -f "./$FILE" ]; then
      echo "⚠️ STALE CITATION: $FILE (file not found)"
      STALE=$((STALE + 1))
    fi
  fi
done < "$LEARNINGS"

[ "$STALE" -gt 0 ] && echo "⚠️ $STALE stale citations. Review apex-learnings.md." || \
  echo "✅ All citations in apex-learnings.md valid"
```

### generate-task-map.sh [שיפור 11+21 — UPGRADED: reads PLAN_META.json]

```bash
#!/bin/bash
TASK_ID=${1:-"current"}
PHASE=$(cat .apex/STATE.json 2>/dev/null | jq -r '.current_phase // empty')
META_FILE=".apex/phases/$PHASE/PLAN_META.json"

cat > .apex/TASK_MAP.md << MAPHEADER
# Task-Specific Repository Map: $TASK_ID
Generated: $(date)

## Explicitly Required Files
MAPHEADER

# [שיפור 21] Read files from PLAN_META.json instead of regex parsing
if [ -f "$META_FILE" ] && command -v jq &>/dev/null; then
  EXPLICIT_FILES=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\") | .files[]" "$META_FILE" 2>/dev/null)

  for file in $EXPLICIT_FILES; do
    if [ -f "$file" ]; then
      echo "- $file ✅" >> .apex/TASK_MAP.md
      grep -E "^(export )?(async )?(function|const|class)" "$file" 2>/dev/null | \
        head -4 | sed 's/^/  → /' >> .apex/TASK_MAP.md
    else
      echo "- $file ⬜ (to be created)" >> .apex/TASK_MAP.md
    fi
  done

  # Get task name for keyword search
  TASK_NAME=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\") | .name" "$META_FILE" 2>/dev/null)
  KEYWORDS=$(echo "$TASK_NAME" | tr ' ' '\n' | grep -E "^[A-Za-z]{5,}" | \
    sort -u | head -6 | tr '\n' '|' | sed 's/|$//')

  if [ -n "$KEYWORDS" ]; then
    echo "" >> .apex/TASK_MAP.md
    echo "## Related Files (keyword search)" >> .apex/TASK_MAP.md
    rg -l "$KEYWORDS" src/ lib/ app/ 2>/dev/null | \
      grep -v "node_modules\|.next\|.git" | head -6 | \
      while read -r f; do
        echo "- $f" >> .apex/TASK_MAP.md
        grep -n "$KEYWORDS" "$f" 2>/dev/null | head -2 | sed 's/^/  → /' >> .apex/TASK_MAP.md
      done
  fi
else
  # Fallback: old regex method if PLAN_META.json doesn't exist
  PLAN_FILE=".apex/phases/$PHASE/PLAN.md"
  if [ -f "$PLAN_FILE" ]; then
    grep -A30 "id=\"$TASK_ID\"" "$PLAN_FILE" 2>/dev/null | \
      grep -E "src/|lib/|app/|api/" | sed 's/<[^>]*>//g' | tr -d ' ' | grep -v "^$" | \
      while read -r file; do
        if [ -f "$file" ]; then
          echo "- $file ✅" >> .apex/TASK_MAP.md
        else
          echo "- $file ⬜ (to be created)" >> .apex/TASK_MAP.md
        fi
      done
  fi
fi

echo "" >> .apex/TASK_MAP.md
echo "## Note: Verify file existence before using. Map may be slightly stale." >> .apex/TASK_MAP.md
echo "✅ Task map generated: .apex/TASK_MAP.md"
```

### phantom-check.sh [שיפור 17]

```bash
#!/bin/bash
# Blocks advancement if SUMMARY.md uses uncertainty language
# Usage: bash phantom-check.sh [path-to-summary.md]

SUMMARY_FILE="${1:-$(find .apex/phases -name "*SUMMARY.md" -newer .apex/STATE.json | tail -1)}"

if [ -z "$SUMMARY_FILE" ] || [ ! -f "$SUMMARY_FILE" ]; then
  echo "✅ PHANTOM CHECK: No summary file to check"
  exit 0
fi

RED_FLAGS="should pass|seems to|likely works|I believe|appears correct|looks good\
|I think|I'm confident|probably works|might work|should work|seems correct\
|appears to work|it looks like|I assume|I expect"

if grep -qi "$RED_FLAGS" "$SUMMARY_FILE" 2>/dev/null; then
  MATCHED=$(grep -oi "$RED_FLAGS" "$SUMMARY_FILE" | head -3 | tr '\n' ', ')
  echo "❌ PHANTOM VERIFICATION DETECTED in $SUMMARY_FILE"
  echo "Found uncertainty language: $MATCHED"
  echo ""
  echo "SUMMARY.md must contain ACTUAL command outputs, not beliefs about results."
  echo "Replace uncertainty phrases with:"
  echo "  'Tests pass. Output: [paste actual npm test output]'"
  echo "  'Verified. Command: [cmd]. Output: [actual output]'"
  exit 2
fi

echo "✅ PHANTOM CHECK: Summary uses concrete evidence language"
exit 0
```

### tdad-index.sh [שיפור 14]

```bash
#!/bin/bash
# Builds code-test dependency graph for TDAD impact analysis
# Run once after architect creates plans, before Phase 01 execution

echo "🔬 TDAD: Building code-test dependency graph..."

if ! command -v python3 &>/dev/null; then
  echo "⚠️ TDAD: python3 not found — skipping dependency indexing"
  exit 0
fi

# Find all test files
TEST_FILES=$(find . -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" \
  2>/dev/null | grep -v "node_modules\|.next" | head -200)

if [ -z "$TEST_FILES" ]; then
  echo "⚠️ TDAD: No test files found — graph will be empty"
  echo "" > .apex/TEST_MAP.txt
  exit 0
fi

# Build simple import-based dependency map
python3 - << 'PYEOF'
import os, re, json
from pathlib import Path

test_map = {}

# Find all test files
test_files = []
for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in ['node_modules', '.next', '.git', 'dist']]
    for f in files:
        if f.endswith(('.test.ts', '.test.tsx', '.spec.ts', '.spec.tsx')):
            test_files.append(os.path.join(root, f))

# For each test file, find what source files it imports
for tf in test_files:
    try:
        content = open(tf).read()
        imports = re.findall(r"from ['\"]([^'\"]+)['\"]", content)
        imports += re.findall(r"require\(['\"]([^'\"]+)['\"]\)", content)
        src_files = []
        for imp in imports:
            if imp.startswith('.'):
                base = os.path.dirname(tf)
                resolved = os.path.normpath(os.path.join(base, imp))
                for ext in ['.ts', '.tsx', '.js', '/index.ts', '/index.tsx']:
                    candidate = resolved + ext if not resolved.endswith(ext) else resolved
                    if os.path.exists(candidate):
                        src_files.append(candidate.lstrip('./'))
                        break
        if src_files:
            test_map[tf.lstrip('./')] = src_files
    except:
        pass

# Write the map: src_file -> [test_files]
reverse_map = {}
for test_file, src_files in test_map.items():
    for src in src_files:
        if src not in reverse_map:
            reverse_map[src] = []
        reverse_map[src].append(test_file)

with open('.apex/TEST_MAP.txt', 'w') as f:
    for src, tests in reverse_map.items():
        f.write(f"{src}|{','.join(tests)}\n")

print(f"✅ TDAD: Indexed {len(reverse_map)} source files → test mappings")
PYEOF

echo "✅ TDAD index complete: .apex/TEST_MAP.txt"

# Create the impact analysis helper
cat > ~/.claude/hooks/tdad-impact.py << 'IMPACT_PY'
#!/usr/bin/env python3
"""TDAD Impact Analysis: given changed files, find impacted tests"""
import sys, os

def get_impacted_tests(changed_files_str, map_file='.apex/TEST_MAP.txt'):
    if not os.path.exists(map_file):
        return []
    
    changed = [f.strip() for f in changed_files_str.split() if f.strip()]
    impacted = set()
    
    try:
        with open(map_file) as f:
            for line in f:
                line = line.strip()
                if '|' not in line:
                    continue
                src, tests_str = line.split('|', 1)
                for changed_file in changed:
                    if changed_file in src or src in changed_file:
                        for t in tests_str.split(','):
                            if t.strip():
                                impacted.add(t.strip())
    except:
        pass
    
    return sorted(impacted)

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--files', required=True)
    parser.add_argument('--map', default='.apex/TEST_MAP.txt')
    args = parser.parse_args()
    
    tests = get_impacted_tests(args.files, args.map)
    
    if tests:
        output = '\n'.join(tests)
        with open('.apex/IMPACTED_TESTS.txt', 'w') as f:
            f.write(output)
        print(f"✅ TDAD: {len(tests)} impacted tests identified")
        print('\n'.join(tests))
    else:
        if os.path.exists('.apex/IMPACTED_TESTS.txt'):
            os.remove('.apex/IMPACTED_TESTS.txt')
        print("ℹ️ TDAD: No specific test dependencies found — using default verification")
IMPACT_PY

chmod +x ~/.claude/hooks/tdad-impact.py
```

### cross-phase-audit.sh [שיפור 16+21 — UPGRADED: reads PLAN_META.json]

```bash
#!/bin/bash
# Runs all tests from previous phases to detect regressions before advancing
# Usage: bash cross-phase-audit.sh [current_phase_number]
# [שיפור 21] Now reads verify_commands from PLAN_META.json instead of regex

CURRENT_PHASE=${1:-1}
echo "🔍 APEX Cross-Phase Regression Audit (checking Phases 1 to $((CURRENT_PHASE-1)))..."

if [ "$CURRENT_PHASE" -le 1 ]; then
  echo "✅ No previous phases to audit (Phase 1)"
  exit 0
fi

FAILURES=0
TOTAL_TESTS=0
TESTED_PHASES=0

for phase_dir in .apex/phases/*/; do
  PHASE_NUM=$(basename "$phase_dir" | cut -d- -f1 | sed 's/^0*//')
  
  if [ "$PHASE_NUM" -lt "$CURRENT_PHASE" ] 2>/dev/null; then
    META_FILE="${phase_dir}PLAN_META.json"
    
    if [ -f "$META_FILE" ] && command -v jq &>/dev/null; then
      # [שיפור 21] Read verify_commands from structured JSON
      VERIFY_CMDS=$(jq -r '.tasks[].verify_commands[]' "$META_FILE" 2>/dev/null | \
        grep -E "^(npm|npx|node|curl)" | sort -u | head -10)
    else
      # Fallback: old regex method
      VERIFY_CMDS=$(grep -h "<verify>" "${phase_dir}"*.md 2>/dev/null | \
        grep -v "^<verify>" | sed 's|.*<verify>||;s|</verify>.*||' | \
        grep -E "^(npm|npx|node|curl)" | sort -u | head -10)
    fi

    if [ -n "$VERIFY_CMDS" ]; then
      echo "  Checking Phase $PHASE_NUM..."
      PHASE_FAIL=0
      
      while IFS= read -r cmd; do
        [ -z "$cmd" ] && continue
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        OUTPUT=$(eval "$cmd" 2>&1)
        EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]; then
          echo "  ❌ REGRESSION in Phase $PHASE_NUM: $cmd"
          echo "     Output: $(echo "$OUTPUT" | head -3)"
          FAILURES=$((FAILURES + 1))
          PHASE_FAIL=1
        fi
      done <<< "$VERIFY_CMDS"
      
      [ $PHASE_FAIL -eq 0 ] && echo "  ✅ Phase $PHASE_NUM: no regressions"
      TESTED_PHASES=$((TESTED_PHASES + 1))
    fi
  fi
done

# Update EvoScore in STATE.json
if [ -f .apex/STATE.json ] && command -v jq &>/dev/null; then
  REGRESSION_RATE=0
  [ "$TOTAL_TESTS" -gt 0 ] && REGRESSION_RATE=$(echo "scale=2; $FAILURES * 100 / $TOTAL_TESTS" | bc 2>/dev/null || echo "0")
  
  jq --argjson rate "$REGRESSION_RATE" \
     --argjson total "$TOTAL_TESTS" \
     --arg date "$(date -I)" \
     '.evoscore.regression_rate = $rate |
      .evoscore.total_cross_phase_tests = $total |
      .evoscore.last_full_audit = $date' \
     .apex/STATE.json > /tmp/state_tmp.json && mv /tmp/state_tmp.json .apex/STATE.json
fi

echo ""
echo "Cross-Phase Audit Complete:"
echo "  Phases checked: $TESTED_PHASES"
echo "  Tests run: $TOTAL_TESTS"
echo "  Failures: $FAILURES"
echo "  EvoScore regression rate: ${REGRESSION_RATE:-0}%"

if [ "$FAILURES" -gt 0 ]; then
  echo ""
  echo "⛔ BLOCKED: $FAILURES regression(s) detected in previous phases."
  echo "Fix before advancing. Current changes broke earlier functionality."
  exit 2
fi

echo "✅ Zero regressions — codebase health maintained"
exit 0
```

### context-monitor.sh [שיפור 29 — NEW]

```bash
#!/bin/bash
# Estimates context usage and warns/blocks on overflow
# Called at the start of every /apex:next

STATE_FILE=".apex/STATE.json"
BUDGET_FILE=".apex/CONTEXT_BUDGET.json"

if [ ! -f "$STATE_FILE" ]; then
  echo "✅ CONTEXT: No state file — fresh session"
  exit 0
fi

if ! command -v jq &>/dev/null; then
  echo "✅ CONTEXT: jq not available — skipping check"
  exit 0
fi

# Read thresholds
WARNING_PCT=$(jq -r '.context_overflow_threshold_pct // 70' "$BUDGET_FILE" 2>/dev/null || echo 70)
CRITICAL_PCT=$(jq -r '.critical_threshold_pct // 85' "$BUDGET_FILE" 2>/dev/null || echo 85)

# Estimate context usage from token tracking
SESSION_START=$(jq -r '.context.session_start_time // empty' "$STATE_FILE" 2>/dev/null)
PHASE_TOKENS=$(jq -r '.tokens.by_phase | to_entries | map(.value.input + .value.output) | add // 0' "$STATE_FILE" 2>/dev/null || echo 0)

# Rough estimate: session tokens since last rotation
# Each agent call uses ~20-40K tokens of context
AGENT_CALLS_THIS_SESSION=$(jq -r '
  .context.rotation_history[-1].session_ended as $last_rotation |
  if $last_rotation then
    [.tokens.by_agent | to_entries[] | .value.calls] | add // 0
  else
    [.tokens.by_agent | to_entries[] | .value.calls] | add // 0
  end' "$STATE_FILE" 2>/dev/null || echo 0)

# Heuristic: each agent call accumulates ~15K tokens in orchestrator context
ESTIMATED_USAGE=$((AGENT_CALLS_THIS_SESSION * 15000))
# 200K context window
ESTIMATED_PCT=$((ESTIMATED_USAGE * 100 / 200000))

# Update STATE.json
jq --argjson pct "$ESTIMATED_PCT" \
   '.context.estimated_context_usage_pct = $pct' \
   "$STATE_FILE" > /tmp/state_ctx.json && mv /tmp/state_ctx.json "$STATE_FILE"

if [ "$ESTIMATED_PCT" -ge "$CRITICAL_PCT" ]; then
  echo "CRITICAL_OVERFLOW"
  echo "⚠️ Context estimated at ~${ESTIMATED_PCT}% (${AGENT_CALLS_THIS_SESSION} agent calls this session)"
  echo "Session state saved. Run /apex:resume for fresh context."
  exit 2
elif [ "$ESTIMATED_PCT" -ge "$WARNING_PCT" ]; then
  echo "WARNING_OVERFLOW"
  echo "⚠️ Context estimated at ~${ESTIMATED_PCT}%. Running /compact recommended."
  exit 1
else
  echo "✅ CONTEXT: ~${ESTIMATED_PCT}% used (${AGENT_CALLS_THIS_SESSION} agent calls)"
  exit 0
fi
```

### phase-tag.sh [שיפור 23 — NEW]

```bash
#!/bin/bash
# Creates git tag for completed phase, enabling rollback
# Usage: bash phase-tag.sh [phase_id]

PHASE_ID=${1:-"unknown"}
TAG_NAME="apex/phase-${PHASE_ID}-complete"

# Check if tag already exists
if git tag -l "$TAG_NAME" | grep -q "$TAG_NAME"; then
  echo "⚠️ Tag $TAG_NAME already exists — skipping"
  exit 0
fi

# Create annotated tag
git tag -a "$TAG_NAME" -m "APEX: Phase $PHASE_ID verified and complete ($(date -I))" 2>/dev/null

if [ $? -eq 0 ]; then
  # Update STATE.json
  if [ -f .apex/STATE.json ] && command -v jq &>/dev/null; then
    jq --arg phase "$PHASE_ID" --arg tag "$TAG_NAME" \
       '.phase_tags[$phase] = $tag' \
       .apex/STATE.json > /tmp/state_tag.json && mv /tmp/state_tag.json .apex/STATE.json
  fi
  echo "✅ Phase tag created: $TAG_NAME"
  echo "   Rollback available: git revert --no-commit HEAD..$TAG_NAME"
else
  echo "⚠️ Failed to create tag $TAG_NAME (not in git repo?)"
fi
```

---

## settings.json

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/post-write.sh"}]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/subagent-stop.sh"}]
      }
    ],
    "PreCompact": [
      {
        "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/pre-compact.sh"}]
      }
    ],
    "SessionStart": [
      {
        "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/verify-learnings.sh 2>/dev/null || true"}]
      }
    ]
  },
  "permissions": {
    "deny": [
      "Read(.env)", "Read(.env.*)",
      "Read(**/*.pem)", "Read(**/*.key)",
      "Read(**/*secret*)", "Read(**/*credential*)"
    ]
  }
}
```

---

## CLAUDE.md Template

```markdown
# [Project Name] — APEX v5 Project

## Complexity Level
[N] — [NAME] | See: .apex/COMPLEXITY.md

## Stack
[Filled by architect]

## Stack Skills Loaded [שיפור 24]
[list of skill files from ~/.claude/apex-skills/]

## Code Conventions
[Filled during architecture phase]

## APEX State
- Spec:               .apex/SPEC.md (includes error flows)
- Decisions:          .apex/DECISIONS.md (includes debate outcomes)
- Status:             .apex/STATE.json (includes EvoScore, comprehension gates, tokens)
- Task Map:           .apex/TASK_MAP.md (current task focus)
- Plan Metadata:      .apex/phases/*/PLAN_META.json (structured task data) [שיפור 21]
- Wave Map:           .apex/phases/*/WAVE_MAP.json (parallel execution plan) [שיפור 22]
- TDAD Tests:         .apex/IMPACTED_TESTS.txt (dependency-impacted tests)
- Learnings:          ~/.claude/apex-learnings.md (citation-based, global)
- Comprehension:      .apex/comprehension-gates/ (phase understanding records)
- Context Budget:     .apex/CONTEXT_BUDGET.json (per-agent token limits) [שיפור 19]
- Phase Tags:         git tag -l "apex/*" (rollback points) [שיפור 23]

## Silent Failure Rules (ALL code must follow)
- Every catch block → setError/toast/throw/return {error} — NEVER just console.log
- Every external API call → return {data, error} pair — never swallow failures
- No placeholder values or fake keys in committed code

## Named Failure Prohibitions (ALL agents must follow)
- PHANTOM VERIFICATION: never claim tests pass without pasting actual output
- CONFIDENCE MIRAGE: never use "I'm confident", "looks correct", "seems fine"
- HOLLOW REPORT: summaries must contain actual command outputs, not descriptions
- TUNNEL VISION: always check edge_cases AND impacted tests before committing
- SHORTCUT SPIRAL: never mark COMPLETE until all <done> criteria are verified
- DEFERRED DEBT: no TODO/FIXME in committed code

## Context Management [שיפורים 18,19,29]
- Fresh session recommended between phases (/apex:resume)
- Context budget enforced per agent (see CONTEXT_BUDGET.json)
- Auto-warning at 70% context, forced rotation at 85%

## Critical Rules
[Project-specific — filled during architecture phase]
```

---

## Autonomy System [שיפור 27 — UPGRADED]

```
Level 0 — COLLABORATIVE (default)
  Approval: everything
  Upgrade: 5 consecutive CRITIC PASS on verify_level C or D tasks
  Note: A/B task passes do NOT count toward escalation [שיפור 27]

Level 1 — SUPERVISED
  Approval: architectural decisions, new dependencies, spec changes
  Auto: code + review + TDAD checks
  Upgrade: 5 more C/D cycles

Level 2 — TRUSTED
  Approval: phase transitions, spec changes
  Auto: everything within phase
  Note: Comprehension Gate ALWAYS requires human response [שיפור 15]
  Note: Context rotation ALWAYS recommended between phases [שיפור 18]
  Upgrade: 5 more (full phase = 1 unit)

Level 3 — AUTONOMOUS
  Approval: spec scope changes, budget ceiling
  Auto: full project
  Note: Architecture Debate ALWAYS runs [שיפור 8]
  Note: Cross-Phase Audit ALWAYS runs [שיפור 16]
  Note: Comprehension Gate ALWAYS requires human [שיפור 15]
  Note: Context rotation ALWAYS recommended [שיפור 18]

RESET TO 0 if:
  - Critic CRITICAL issue
  - Phantom Verification detected [שיפור 17]
  - Hallucination guard fires | Secret detected
  - Reflexion max_attempts reached | Health check fails
  - Cross-phase regression detected [שיפור 16]
  - Context overflow forced rotation [שיפור 29]
  - /apex:reset-trust
```

---

## Installation

```bash
#!/bin/bash
APEX_REPO="https://raw.githubusercontent.com/[user]/apex/main"

mkdir -p ~/.claude/commands/apex ~/.claude/agents/specialist ~/.claude/hooks ~/.claude/apex-skills

# Commands (12 total — added resume)
for cmd in start next build spec status review quick pause recover resume precheck health-check; do
  curl -sS "$APEX_REPO/.claude/commands/apex/$cmd.md" -o ~/.claude/commands/apex/$cmd.md
done

# Agents (8 core — consolidated from 13) [שיפור 28]
for agent in diagnostician interviewer pre-build-planner architect executor \
             critic verifier researcher; do
  curl -sS "$APEX_REPO/.claude/agents/$agent.md" -o ~/.claude/agents/$agent.md
done

# Specialist agents (4)
for spec in integration security data frontend; do
  curl -sS "$APEX_REPO/.claude/agents/specialist/$spec.md" -o ~/.claude/agents/specialist/$spec.md
done

# Hooks (10 total: 6 original + 4 new in v5)
for hook in post-write subagent-stop pre-compact \
            verify-learnings generate-task-map \
            phantom-check tdad-index cross-phase-audit \
            context-monitor phase-tag; do
  curl -sS "$APEX_REPO/.claude/hooks/$hook.sh" -o ~/.claude/hooks/$hook.sh
  chmod +x ~/.claude/hooks/$hook.sh
done

# Stack skills [שיפור 24]
for skill in nextjs supabase prisma tailwind stripe README; do
  curl -sS "$APEX_REPO/.claude/apex-skills/$skill.md" -o ~/.claude/apex-skills/$skill.md
done

# Settings
curl -sS "$APEX_REPO/.claude/settings.json" -o ~/.claude/settings.json

# Initialize learnings (citation-based format)
[ ! -f ~/.claude/apex-learnings.md ] && \
  curl -sS "$APEX_REPO/.claude/apex-learnings.md" -o ~/.claude/apex-learnings.md

echo "✅ APEX v5 installed (31 improvements)"
echo ""
echo "Agents: 8 core + 4 specialists (consolidated) [שיפור 28]"
echo "Hooks: 10 (context-monitor + phase-tag added) [שיפורים 23,29]"
echo "Commands: 12 (/apex:resume added) [שיפור 31]"
echo "Stack skills: $(ls ~/.claude/apex-skills/*.md 2>/dev/null | wc -l) loaded [שיפור 24]"
echo ""
echo "First run:     /apex:health-check    (8 real tests — verify all agents)"
echo "New project:   /apex:start"
echo "Fresh session: /apex:resume          (context rotation)"
echo "Weekly:        /apex:health-check    (detect prompt decay)"
```

---

## [שיפור 1] Prompt Testing Protocol — Updated for v5

### תרחישי בדיקה

**Diagnostician — 5:**
```
1. "landing page" → Level 1, no debate candidates, minimal stack skills
2. "todo app with teams" → Level 2, identifies stack skills
3. "FINDO: WhatsApp + Google + VoIP" → Level 3 + pre-build + debate candidates + stack skills
4. "restaurant marketplace" → Level 3 + tenant model debate
5. "rename files script" → Level 1, minimal
```

**Architect — 5 (enhanced for v5):**
```
1. Creates PLAN_META.json that matches PLAN.md exactly [שיפור 21]
2. Creates WAVE_MAP.json with correct dependency analysis [שיפור 22]
3. Loads and applies stack skills [שיפור 24]
4. Assigns verify_level + is_irreversible + silent_failure_risks
5. Debate via file-based isolation [שיפור 30]
```

**Executor — 5:**
```
1. Normal mode → reads TASK_MAP.md first, handles silent_failure_risks
2. Reflexion mode → changes approach based on reflexion brief
3. Named failure prohibition — refuses phantom verification language [שיפור 12]
4. Trajectory self-monitoring → detects loop [שיפור 13]
5. TDAD usage → runs ONLY impacted tests [שיפור 14]
```

**Critic — 5 (enhanced for v5 — consolidated) [שיפור 28]:**
```
1. Diff-based review: reads git diff HEAD~1, compares line-by-line [שיפור 25]
2. Phantom verification: catches "I believe tests pass" [שיפור 17]
3. Silent failure audit: catches silent catch + placeholder [שיפורים 6+28]
4. Reflexion brief: writes useful failure analysis on FAIL [שיפור 7]
5. Learning loop: appends to learnings WITH CITATIONS [שיפור 9]
```

**Verifier — 3 (enhanced for v5):**
```
1. Reads verify_commands from PLAN_META.json [שיפור 21]
2. Runs cross-phase audit + creates phase tag [שיפורים 16,23]
3. Offers rollback option on FAIL [שיפור 23]
```

**Health Check — 3 (real testing) [שיפור 26]:**
```
1. All 8 tests pass with real temp repo → "✅ All agents healthy"
2. Executor writes phantom language on real file → detected
3. Critic misses silent catch on real diff → detected
```

### Pass/Fail Matrix

| Agent | Pass | Fail |
|-------|------|------|
| Diagnostician | Correct level + debate candidates + stack skills | Wrong level |
| Interviewer | Phase 2 edge cases extracted | Only happy path |
| Architect | PLAN_META.json + WAVE_MAP.json + verify_level + debate | Missing metadata |
| Executor | Named prohibitions + TDAD + trajectory + stack skills | Phantom verification |
| Critic | Diff-based + phantom + silent audit + reflexion | Misses any check |
| Verifier | Reads JSON + cross-phase + tags + rollback option | Skips audit |
| Health Check | All 8 real tests + correct fail reporting | Uses fake scenarios |

---

## סדר בנייה מומלץ — v5

```
שלב 1  (2 ש'): diagnostician + interviewer
  → 5 תרחישים לכל אחד | ודא stack skills identification

שלב 2  (1 ש'): pre-build-planner + /apex:precheck
  → בדוק עם FINDO-like project, ודא blocking עובד

שלב 3  (3 ש'): architect + PLAN_META.json + WAVE_MAP.json [שיפורים 21,22]
  → ודא JSON metadata מדויק ותואם PLAN.md
  → ודא wave analysis נכון (independent tasks → wave 1)
  → ודא stack skills injection

שלב 4  (2 ש'): architect debate — file-based isolation [שיפור 30]
  → debate end-to-end, ודא advocates לא קוראים קבצי אחד-השני
  → ודא judge מנמק מבוסס SPEC

שלב 5  (2 ש'): executor + NAMED FAILURE PROHIBITIONS [שיפור 12]
  → בדוק שexecutor מסרב לכתוב phantom verification
  → בדוק stack skills usage

שלב 6  (1 ש'): executor + TRAJECTORY SELF-MONITOR [שיפור 13]
  → גרום ל-executor לבצע loop → ודא שמזהה ועוצר

שלב 7  (2 ש'): tdad-index.sh + executor + TDAD [שיפור 14]
  → בנה index → שנה קובץ → ודא שרץ רק impacted tests

שלב 8  (1 ש'): phantom-check.sh [שיפור 17]
  → כתוב SUMMARY עם "I believe tests pass" → ודא שblocked

שלב 9  (2 ש'): critic — CONSOLIDATED [שיפורים 25,28]
  → diff-based review (reads actual diff)
  → silent failure audit (integrated)
  → phantom verification check
  → reflexion brief on FAIL

שלב 10 (2 ש'): cross-phase-audit.sh + phase-tag.sh [שיפורים 16,23]
  → בנה 2 phases → שבור test מPhase 1 → ודא שPhase 2 חסום
  → ודא phase tags נוצרים ו-rollback עובד

שלב 11 (1 ש'): Comprehension Gate + Context Rotation [שיפורים 15,18]
  → השלם Phase → ודא APEX עוצר ומבקש comprehension
  → ודא שמציע /apex:resume בין phases

שלב 12 (1 ש'): context-monitor.sh [שיפור 29]
  → סמלץ 10+ agent calls → ודא warning ב-70% ו-critical ב-85%

שלב 13 (1 ש'): /apex:resume [שיפור 31]
  → סגור session → פתח חדש → /apex:resume → ודא state loaded

שלב 14 (2 ש'): /apex:health-check — REAL TESTING [שיפור 26]
  → הרץ כולם עם temp repo אמיתי
  → גרום לtest 3 להיכשל → ודא failure מדווח

שלב 15 (2 ש'): full Level 1 run (todo app)
  → end-to-end מ-/apex:start עד complete
  → ודא token tracking ו-context budget

שלב 16 (שעות+): full Level 3 run (FINDO MVP)
  → כל 31 השיפורים פועלים יחד
  → Context rotation בין phases
  → Wave-based execution
  → Comprehension Gate + EvoScore
  → Token budget tracking מקצה לקצה
  → כל bug = learning עם citation
```

---

## השוואה: APEX v5 vs מתחרים

```
Feature                      | APEX v5 | GSD  | Superpowers | BMAD | Taskmaster
─────────────────────────────|─────────|──────|─────────────|──────|──────────
Complexity Classification    |   ✅    |  ❌  |     ❌      |  ✅  |    ❌
Fresh Context per Phase      |   ✅    |  ✅  |     ❌      |  ❌  |    ❌
Context Budget per Agent     |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Token Tracking               |   ✅    |  ✅* |     ❌      |  ❌  |    ❌
Silent Failure Detection     |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Phantom Verification Guard   |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Named Failure Prohibitions   |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Verification Ladder (A-D)    |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Comprehension Gates          |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Architecture Debate (MAD)    |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Cross-Phase Regression       |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Phase Rollback (git tags)    |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Reflexion Loop               |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Wave-Based Parallel          |   ✅    |  ✅  |     ✅      |  ❌  |    ❌
TDD Enforcement              |   ✅    |  ✅  |     ✅      |  ❌  |    ❌
Diff-Based Code Review       |   ✅    |  ❌  |     ✅      |  ❌  |    ❌
Stack-Specific Skills        |   ✅    |  ✅  |     ✅      |  ❌  |    ❌
Citation-Based Learning      |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
TDAD Dependency Tests        |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Autonomy Escalation          |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Pre-Build Phase              |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Health Check / Poison Pill   |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Multi-Platform Support       |   ❌    |  ✅  |     ✅      |  ✅  |    ✅
Plugin Marketplace           |   ❌    |  ✅  |     ✅      |  ❌  |    ❌

* GSD v2 has token tracking
```
