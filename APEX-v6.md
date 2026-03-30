# APEX v6 — Adaptive Pipeline for Excellence
## Context-Engineered Architecture | Research-Validated
### 31 שיפורים מקוריים + 15 שדרוגים מבוססי מחקר
### Claude Code Native — Slash Commands + Agents

---

## עקרון העל

> "Less context, better chosen, always beats more context, naively stuffed."
> — Round 2 Research Conclusion, 5/5 models unanimous

כל הכלים הקיימים נכשלים בעשר נקודות:
1. הם מניחים שכל פרויקט צריך אותו pipeline.
2. הם מאמינים ל-executor שמדווח על עצמו.
3. הם מתחילים מאפס בכל פרויקט.
4. הם מניחים שקוד שרץ — עובד.
5. הם מניחים שהאדם שבנה את הפרויקט עדיין מבין אותו.
6. **הם ממלאים context עד הגבול ומאבדים איכות. [R2-Finding 1: degradation universal]**
7. **הם שורפים tokens על orchestration במקום על קוד. [R1-Finding 3: 4:1 to 10:1 ratios]**
8. **הם נותנים למבצע לאמת את עצמו. [R1-Finding 2: verification theater]**
9. **הם לא מונעים פעולות הרסניות. [R1: 10 incidents, 0 postmortems]**
10. **הם מדווחים PASS/FAIL בלי מידה של ודאות. [R1-Rank 1 unmet need]**

**APEX שואל קודם — בודק עם context נקי — לומד תמיד — מחפש כשלים שקטים — שומר על הבנת האדם — מנהל כל token כמשאב יקר — ומעולם לא נותן למבצע לאמת את עבודתו.**

---

## 46 השיפורים — סיכום

```
── v2-v4 (שיפורים 1-17, נשמרים מלאים) ────────────────────
[ללא שינוי מ-v5 — ראה תיעוד מלא ב-v5]

── v5 (שיפורים 18-31, נשמרים עם עדכונים) ─────────────────
שיפור 18: Context Rotation              — עודכן: proactive ב-50%, hard ב-70%
שיפור 19: Context Budget Per Agent      — עודכן: zone-based, 50-60% target
שיפור 20: Token Budget Tracking         — ללא שינוי
שיפור 21: Structured Metadata           — ללא שינוי
שיפור 22: Wave-Based Parallel Execution — ללא שינוי
שיפור 23: Phase Rollback Mechanism      — עודכן: + pre-task snapshots
שיפור 24: Stack-Specific Skill Injection — עודכן: lazy-load only
שיפור 25: Diff-Based Critic Review      — עודכן: clean-room protocol
שיפור 26: Real Health Check             — עודכן: + clean-room test
שיפור 27: Smart Autonomy Escalation     — ללא שינוי
שיפור 28: Agent Consolidation           — ללא שינוי
שיפור 29: Context Overflow Detection    — עודכן: thresholds lowered
שיפור 30: File-Based Debate Isolation   — ללא שינוי
שיפור 31: /apex:resume Command          — ללא שינוי

── v6 חדשים (מבוססי מחקר סבבים 1+2) ─────────────────────
שיפור 32: Clean-Room Verification       — critic לא רואה SUMMARY/reasoning [R1-F2, R2-6]
שיפור 33: Typed Agent Results           — JSON structured results, לא prose [R2-C2]
שיפור 34: Observation Masking           — מחיקת tool outputs ישנים, לא summarization [R2-3]
שיפור 35: Destructive Action Guard      — deny-list לפעולות הרסניות [R1: 10 incidents]
שיפור 36: Pre-Task Snapshot             — git stash לפני כל task execution [R1-7.2]
שיפור 37: Honest Uncertainty Signaling  — partial confidence: 3/7 verified [R1-Rank 1]
שיפור 38: Level 0 Micro-Tasks           — דילוג על ceremony לshינויים טריוויאליים [R1-F6]
שיפור 39: Spec Reference Links          — כל task מקושר ל-SPEC sections [R1-F2 Taskmaster]
שיפור 40: Anti-Rationalization Tables   — counter-arguments מוטמעים בprompts [R2-7.2]
שיפור 41: Circuit Breaker               — עצירה אחרי 3 חזרות ללא שינוי בקבצים [R1-F5]
שיפור 42: Task-Adaptive Context         — פרופילי context שונים per task type [R2-D2]
שיפור 43: Primacy-Recency Ordering      — critical instructions ב-start, task ב-end [R2-A1]
שיפור 44: Memory Integrity              — provenance, decay, poisoning protection [R2-B4]
שיפור 45: Context Health Dashboard      — metrics in real-time [R2-E4]
שיפור 46: CLAUDE.md Size Enforcement    — <200 lines for 92% rule application [R2-B4]
```

---

## Design Principles — Research-Backed

```
PRINCIPLE 1: Design for 100-160K working set, not 256K. [R2-A2]
  BABILong: 10-20% effective utilization. LongCodeBench: 29%→3% at 256K.
  Every token must earn its place.

PRINCIPLE 2: Fresh context per worker, thin orchestrator. [R2-4]
  Anthropic multi-agent: Opus lead + Sonnet workers = 90.2% improvement.
  Orchestrator at 10-15% context. Workers get clean windows.

PRINCIPLE 3: Observation masking > LLM summarization. [R2-3]
  JetBrains: masking matches/exceeds summarization at zero compute cost.
  Factory.ai: extractive +7.89 F1, abstractive -4.69 F1.

PRINCIPLE 4: Implementer never verifies own work. [R2-6]
  88.2% adversarial bias in non-isolated review.
  93.75% detection with debiasing + isolation.

PRINCIPLE 5: Structured > unstructured. [R2-B2]
  Typed JSON between agents. XML tags in context injection.
  Structure > format choice > no structure.

PRINCIPLE 6: Lazy-load, don't pre-stuff. [R2-D1]
  Aider repo map: 4.3-6.5% context utilization (best measured).
  AGENTS.md eval: broad context files decrease success 20%+.

PRINCIPLE 7: Every claim must be falsifiable. [R1-Finding 2]
  No PASS without evidence. No "done" without verified criteria count.
  "3 of 7 criteria verified; 4 remain untested" > "PASS."
```

---

## מודל הסיווג: 5 רמות מורכבות [שיפור 38]

```
Level 0 — MICRO [שיפור 38, NEW]
  דוגמאות: rename variable, fix typo, update config value, change text
  Pipeline: Execute → Done
  Agents: executor only (no planning, no review)
  Ceremony: ZERO. Direct execution with git stash safety net.
  Trigger: estimated <5 minutes, single file, no logic change

Level 1 — SIMPLE
  דוגמאות: landing page, script, CLI tool, blog
  Pipeline: Spec → Build → Done
  Agents: interviewer + executor + critic

Level 2 — STANDARD
  דוגמאות: web app עם DB, dashboard, API, SaaS פשוט
  Pipeline: Spec → Architect → Phases → Verify
  Agents: כל הבסיסיים + verifier

Level 3 — COMPLEX
  דוגמאות: FINDO, multi-tenant SaaS, third-party integrations
  Pipeline: PRE-BUILD → Spec → Architect → Phases → Verify → Deploy
  Agents: כל הagents + pre-build-planner + debate + specialists

Level 4 — ENTERPRISE
  דוגמאות: platform, marketplace, 10+ integrations
  Pipeline: מלא עם waves מקבילים
```

---

## Context Zone Architecture [שיפורים 19+34+42+43, REDESIGNED]

**Based on:** R2 Section 8.1 — unanimous across 5 research models.

```
┌─────────────────────────────────────────────────────────────┐
│              EFFECTIVE WINDOW: ~200K tokens                  │
│                                                             │
│  Zone 1: STABLE PREFIX (cached)              5-10K (2-5%)   │
│  ├── System prompt + agent role                             │
│  ├── CLAUDE.md (<200 lines) [שיפור 46]                     │
│  └── Repo map skeleton (1-4K, Aider-style)                  │
│                                                             │
│  Zone 2: TASK CONTEXT (JIT-loaded)          30-60K (15-30%) │
│  ├── Task spec + acceptance criteria                        │
│  ├── Active code files (files being modified)               │
│  ├── Interface/dependency signatures (not full files)        │
│  └── Relevant DECISIONS.md entries                          │
│                                                             │
│  Zone 3: WORKING MEMORY (observation-masked) 20-40K (10-20%)│
│  ├── Recent tool results (subject to masking [שיפור 34])    │
│  ├── Test output                                            │
│  └── Intermediate results                                   │
│                                                             │
│  Zone 4: GENERATION RESERVE (never consumed) 40-80K (20-40%)│
│  ├── Model output including extended thinking                │
│  └── NEVER consumed by input tokens                         │
│                                                             │
│  ═══════════════════════════════════════════                 │
│  TARGET: 50-60% utilization (100-120K)                      │
│  COMPACT AT: 50-60%                                         │
│  HARD ROTATE AT: 70%                                        │
│  NEVER EXCEED: 75% for complex coding tasks                 │
└─────────────────────────────────────────────────────────────┘
```

**Context ordering within zones [שיפור 43]:**
```
PRIMACY ZONE (start — highest attention):
  1. <system_instructions> — agent role, constraints, prohibitions
  2. <project_context> — CLAUDE.md excerpt, repo map, conventions

MIDDLE ZONE (structured with XML tags):
  3. <prior_decisions> — relevant DECISIONS.md entries
  4. <context_files> — typed file listings (PRIMARY/DEPENDENCY/TEST)
  5. <recent_evidence> — latest tool results, test output

RECENCY ZONE (end — high attention):
  6. <current_task> — what to do RIGHT NOW + acceptance criteria
```

---

## Task-Adaptive Context Profiles [שיפור 42]

**Based on:** R2 Section D2. Different task types need different context.

```json
{
  "context_profiles": {
    "new_code": {
      "primary": ["architecture_docs", "interfaces", "style_rules", "examples"],
      "secondary": ["repo_map", "existing_patterns"],
      "minimize": ["full_existing_implementations"]
    },
    "bug_fix": {
      "primary": ["failing_tests", "stack_traces", "execution_path"],
      "secondary": ["minimal_dependency_chain"],
      "minimize": ["broad_architecture_docs"]
    },
    "code_review": {
      "primary": ["spec_contract", "diff", "test_results"],
      "secondary": ["surrounding_functions"],
      "minimize": ["implementer_reasoning"]
    },
    "refactoring": {
      "primary": ["dependency_graph", "affected_dependents"],
      "secondary": ["current_tests"],
      "minimize": ["unrelated_modules"]
    },
    "test_writing": {
      "primary": ["implementation_contracts", "test_conventions", "existing_tests"],
      "secondary": ["coverage_info"],
      "minimize": ["broad_system_architecture"]
    },
    "frontend": {
      "primary": ["design_context", "component_hierarchy"],
      "secondary": ["style_guide"],
      "minimize": ["backend_internals"]
    },
    "infrastructure": {
      "primary": ["config_files", "environment_setup", "deployment_docs"],
      "secondary": ["dependency_versions"],
      "minimize": ["application_code"]
    }
  }
}
```

---

## Clean-Room Verification Protocol [שיפור 32]

**Based on:** R2-Finding 6: 88.2% adversarial bias without isolation, 93.75% detection with isolation + debiasing.

```
┌──────────────────────────────────────────────────────────────┐
│                CLEAN-ROOM VERIFICATION                        │
│                                                              │
│  EXECUTOR completes task:                                    │
│  ├── Writes code to files (artifacts on disk)                │
│  ├── Commits to git                                          │
│  ├── Writes RESULT.json (typed, machine-readable) [שיפור 33] │
│  └── Writes SUMMARY.md (human-readable, for developer)       │
│                                                              │
│  CRITIC receives (Pass 1 — clean room):                      │
│  ├── ✅ Task spec from PLAN_META.json                        │
│  ├── ✅ Acceptance criteria from PLAN_META.json              │
│  ├── ✅ git diff HEAD~1 (unified format)                     │
│  ├── ✅ Full content of modified files (re-read from disk)    │
│  ├── ✅ Test results from RESULT.json (stdout/stderr only)   │
│  ├── ✅ Debiasing instructions                               │
│  ├── ❌ NEVER: executor SUMMARY.md                           │
│  ├── ❌ NEVER: executor reasoning or CoT                     │
│  ├── ❌ NEVER: failed attempts or backtracking               │
│  ├── ❌ NEVER: executor confidence assessment                │
│  └── ❌ NEVER: orchestrator internal narrative                │
│                                                              │
│  Pass 2 (only on disagreement):                              │
│  ├── Limited factual summary (what was done, not why)        │
│  └── Prior verifier findings                                 │
└──────────────────────────────────────────────────────────────┘
```

---

## Typed Agent Result Format [שיפור 33]

**Based on:** R2-C2. Workers write artifacts to disk, return structured JSON. Orchestrator reads JSON, not conversation.

**File:** `.apex/phases/[phase]/[task]-RESULT.json`

```json
{
  "task_id": "02-01",
  "status": "success",
  "files_modified": [
    {"path": "src/app/api/auth/login/route.ts", "action": "created"},
    {"path": "src/lib/auth.ts", "action": "modified"}
  ],
  "files_read": [
    "src/types/user.ts",
    "src/lib/supabase/server.ts"
  ],
  "tests_run": [
    {"name": "auth.test.ts::login with valid credentials", "result": "pass", "output": "✓ 1 passed"},
    {"name": "auth.test.ts::login with invalid credentials", "result": "pass", "output": "✓ 1 passed"},
    {"name": "auth.test.ts::rate limiting after 5 attempts", "result": "pass", "output": "✓ 1 passed"}
  ],
  "verify_commands_run": [
    {"command": "npx tsc --noEmit", "exit_code": 0, "output": "No errors"},
    {"command": "npm test -- --testPathPattern=auth", "exit_code": 0, "output": "Tests: 3 passed, 3 total"}
  ],
  "done_criteria_checked": [
    {"criterion": "POST /api/auth/login returns 200 with valid credentials", "verified": true, "evidence": "curl output: HTTP/1.1 200"},
    {"criterion": "POST /api/auth/login returns 401 with invalid credentials", "verified": true, "evidence": "curl output: HTTP/1.1 401"},
    {"criterion": "POST /api/auth/register creates user and returns 201", "verified": true, "evidence": "curl output: HTTP/1.1 201"},
    {"criterion": "Rate limiting after 5 failed attempts", "verified": false, "evidence": "Not tested — needs load testing setup"}
  ],
  "edge_cases_handled": [
    {"case": "duplicate email registration", "handled": true, "how": "unique constraint + 409 response"},
    {"case": "SQL injection in email field", "handled": true, "how": "parameterized queries via Supabase client"}
  ],
  "decisions_made": [
    {"decision": "Used JWT with httpOnly cookies", "rationale": "Per DECISIONS.md security convention", "spec_ref": "SPEC §3.2"}
  ],
  "issues_found": [],
  "unresolved_risks": [
    "Rate limiting not verified under load — needs integration test"
  ],
  "spec_sections_referenced": ["§2.1 Authentication", "§3.2 Security Requirements"],
  "what_next_tasks_can_assume": "Auth routes exist at /api/auth/{login,register}. JWT stored in httpOnly cookie. Supabase auth client configured."
}
```

---

## CONTEXT_BUDGET.json [שיפור 19, REDESIGNED]

**Based on:** R2-Section 8.1. All 5 models converge on 50-60% target utilization.

```json
{
  "version": "v6",
  "design_principle": "50-60% target utilization. Reserve 20-40% for generation.",

  "zones": {
    "stable_prefix": {
      "budget_tokens": 8000,
      "contents": ["system_prompt", "claude_md", "repo_map"],
      "policy": "cached_via_prompt_caching",
      "notes": "CLAUDE.md must be <200 lines [R2-B4: 92% rule application rate]"
    },
    "task_context": {
      "budget_tokens": 50000,
      "contents": ["task_spec", "active_files", "interfaces", "decisions"],
      "policy": "jit_loaded_per_task"
    },
    "working_memory": {
      "budget_tokens": 30000,
      "contents": ["tool_results", "test_output", "intermediate"],
      "policy": "observation_masked",
      "masking_rule": "delete tool outputs older than 3 turns [R2-3: JetBrains finding]"
    },
    "generation_reserve": {
      "budget_tokens": 60000,
      "contents": ["model_output", "extended_thinking"],
      "policy": "never_consumed_by_input"
    }
  },

  "thresholds": {
    "target_utilization_pct": 55,
    "proactive_compact_pct": 55,
    "hard_rotate_pct": 70,
    "never_exceed_pct": 75,
    "notes": "R2-A2: coding quality degrades fastest above 60%. R2-A3: compact early, not late."
  },

  "rotation_triggers": [
    {"type": "token_threshold", "value": 70, "action": "force_rotate"},
    {"type": "phase_boundary", "action": "recommend_rotate"},
    {"type": "task_batch", "value": 6, "action": "rotate_orchestrator"},
    {"type": "time_minutes", "value": 40, "action": "check_quality_signals"},
    {"type": "quality_signal", "pattern": "repeated_errors_or_forgotten_instructions", "action": "force_rotate"},
    {"type": "circuit_breaker", "value": 3, "action": "halt_and_escalate", "notes": "R1: infinite loop prevention"}
  ],

  "per_agent_limits": {
    "executor": {"max_input": 80000, "target_input": 60000},
    "critic": {"max_input": 50000, "target_input": 35000},
    "verifier": {"max_input": 50000, "target_input": 40000},
    "architect": {"max_input": 70000, "target_input": 55000},
    "interviewer": {"max_input": 30000, "target_input": 20000},
    "researcher": {"max_input": 60000, "target_input": 45000},
    "diagnostician": {"max_input": 20000, "target_input": 15000},
    "specialist": {"max_input": 70000, "target_input": 55000}
  },

  "context_reduction_priority": [
    "1. Apply observation masking (delete old tool outputs) — zero cost [R2-3]",
    "2. Trim dependency summaries to 300 tokens each",
    "3. Trim spec sections to headers + first paragraph",
    "4. Trim stack skills to anti-patterns section only",
    "5. Trim decisions to last 5 entries",
    "NEVER trim: task_xml, acceptance_criteria, reflexion_brief"
  ]
}
```

---

## מבנה קבצים מלא — v6

```
~/.claude/
  commands/apex/
    start.md             ← /apex:start
    next.md              ← /apex:next
    micro.md             ← /apex:micro          [שיפור 38]
    spec.md              ← /apex:spec
    status.md            ← /apex:status
    quick.md             ← /apex:quick
    pause.md             ← /apex:pause
    recover.md           ← /apex:recover
    resume.md            ← /apex:resume
    precheck.md          ← /apex:precheck
    health-check.md      ← /apex:health-check

  agents/
    diagnostician.md
    interviewer.md
    pre-build-planner.md
    architect.md              ← + spec_ref links [שיפור 39]
    executor.md               ← + typed results [שיפור 33] + anti-rationalization [שיפור 40]
    critic.md                 ← REDESIGNED: clean-room [שיפור 32] + uncertainty [שיפור 37]
    verifier.md
    researcher.md
    specialist/
      integration.md
      security.md
      data.md
      frontend.md

  hooks/
    post-write.sh
    subagent-stop.sh
    pre-compact.sh
    verify-learnings.sh
    generate-task-map.sh
    phantom-check.sh
    tdad-index.sh
    cross-phase-audit.sh
    context-monitor.sh        ← UPDATED: lowered thresholds [שיפור 29]
    phase-tag.sh
    destructive-guard.sh      ← NEW [שיפור 35]
    pre-task-snapshot.sh      ← NEW [שיפור 36]
    circuit-breaker.sh        ← NEW [שיפור 41]

  apex-learnings.md
  apex-skills/
  settings.json               ← UPDATED: + destructive-guard hook

.apex/
  SPEC.md
  DECISIONS.md
  COMPLEXITY.md
  STATE.json                  ← UPDATED: + circuit_breaker + snapshot fields
  CONTEXT_BUDGET.json         ← REDESIGNED [שיפור 19]
  TASK_MAP.md
  TEST_MAP.txt

  pre-build/
  phases/
    01-*/
      PLAN.md
      PLAN_META.json          ← + spec_ref per task [שיפור 39]
      WAVE_MAP.json
      [task]-RESULT.json      ← NEW: typed results [שיפור 33]
      [task]-SUMMARY.md       ← human-readable (critic NEVER sees this)
      [task]-CRITIC.md        ← + confidence scores [שיפור 37]
      VERIFY.md
      DEBATE.md

  comprehension-gates/
  research/
  backups/
  debate-log/
```

---

## STATE.json — v6 Updates

```json
{
  "project": "MyProject",
  "complexity_level": 3,
  "complexity_name": "COMPLEX",
  "pipeline": ["pre-build", "spec", "architect", "phases", "verify"],
  "apex_version": "v6",

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
    "last_failure_reason": null
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
    "observation_masking_active": true,
    "rotation_history": [
      {"phase": "01-foundation", "session_ended": "2026-03-30T13:55:00Z", "reason": "phase_complete"}
    ]
  },

  "circuit_breaker": {
    "consecutive_no_change_actions": 0,
    "max_allowed": 3,
    "last_file_hash": null,
    "triggered": false
  },

  "snapshots": {
    "pre_task_stash": "stash@{0}",
    "last_snapshot_task": "02-02"
  },

  "tokens": {
    "total_input": 245000,
    "total_output": 89000,
    "framework_overhead": 12000,
    "overhead_pct": 3.6,
    "by_phase": {},
    "by_agent": {},
    "by_task": {}
  },

  "health_check": {
    "last_run": "2026-03-30",
    "all_passed": true,
    "failed_agents": [],
    "test_count": 9
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
    "01-foundation": "apex/phase-01-complete"
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

## PLAN_META.json — v6 Update [שיפור 39]

**Addition:** Every task now includes `spec_ref` — direct reference links to SPEC.md sections.

```json
{
  "phase_id": "02",
  "phase_name": "backend",
  "tasks": [
    {
      "id": "02-01",
      "name": "Create auth API routes",
      "spec_ref": ["§2.1 Authentication", "§3.2 Security Requirements"],
      "complexity": "medium",
      "specialist": "none",
      "is_irreversible": false,
      "has_behavior": true,
      "verify_level": "C",
      "files": ["src/app/api/auth/login/route.ts", "src/app/api/auth/register/route.ts", "src/lib/auth.ts"],
      "verify_commands": ["npx tsc --noEmit", "npm test -- --testPathPattern=auth"],
      "done_criteria": [
        "POST /api/auth/login returns 200 with valid credentials",
        "POST /api/auth/login returns 401 with invalid credentials",
        "POST /api/auth/register creates user and returns 201"
      ],
      "edge_cases": ["duplicate email registration", "SQL injection in email field"],
      "silent_failure_risks": ["catch block in login that only logs error"],
      "dependencies": ["01-03"],
      "wave": 1
    }
  ]
}
```

---

## Agent: Executor — v6 Updates

```yaml
---
name: executor
description: Implements tasks. Returns typed RESULT.json. Context-budget aware. Anti-rationalization armed.
tools: Read, Write, Edit, Bash, Glob, Grep
maxTurns: 40
---
```

**System Prompt — v6 Changes Only (additions to v5 prompt):**

```
[All v5 executor rules remain in force. The following are ADDITIONS for v6:]

## [שיפור 33] TYPED RESULT OUTPUT
When task is complete, create TWO files:

FILE 1: [task]-RESULT.json (machine-readable, for orchestrator and critic):
{
  "task_id": "[id]",
  "status": "success|failure|partial",
  "files_modified": [{"path": "...", "action": "created|modified"}],
  "files_read": ["..."],
  "tests_run": [{"name": "...", "result": "pass|fail", "output": "..."}],
  "verify_commands_run": [{"command": "...", "exit_code": N, "output": "..."}],
  "done_criteria_checked": [
    {"criterion": "...", "verified": true|false, "evidence": "actual output or 'NOT TESTED'"}
  ],
  "edge_cases_handled": [{"case": "...", "handled": true|false, "how": "..."}],
  "decisions_made": [{"decision": "...", "rationale": "...", "spec_ref": "SPEC §..."}],
  "issues_found": [],
  "unresolved_risks": [],
  "spec_sections_referenced": ["§..."],
  "what_next_tasks_can_assume": "..."
}

CRITICAL: done_criteria_checked MUST list ALL criteria from <done> in task XML.
Mark verified=false for any criterion you did not actually test with a command.
This is the HONEST UNCERTAINTY mechanism [שיפור 37]. Never mark verified=true without evidence.

FILE 2: [task]-SUMMARY.md (human-readable, for developer):
[Same format as v5 SUMMARY.md — this is for the human to read.]
NOTE: The critic will NEVER see this file. It exists solely for the developer.

## [שיפור 40] ANTI-RATIONALIZATION TABLE
Before writing code, read these pre-computed counter-arguments:

RATIONALIZATION: "I'll skip this edge case — it's unlikely."
COUNTER: Edge cases in <edge_cases> exist because the spec author identified them as real risks.
         You MUST handle every listed edge case. If you think one is wrong, STOP and report.

RATIONALIZATION: "This test is overkill for a simple function."
COUNTER: Tests are required for has_behavior=true tasks. If the function is simple,
         the test will be simple too. Write it.

RATIONALIZATION: "I'll add error handling later / in a follow-up."
COUNTER: DEFERRED DEBT prohibition. There is no later. Handle it now or report spec issue.

RATIONALIZATION: "The existing pattern doesn't handle this, so I won't either."
COUNTER: Existing patterns may have bugs. Follow the SPEC and DECISIONS, not broken precedent.

RATIONALIZATION: "I can verify this manually instead of writing a test."
COUNTER: Manual verification is phantom verification. Only automated, reproducible checks count.

RATIONALIZATION: "I'll mark this done — it mostly works."
COUNTER: SHORTCUT SPIRAL prohibition. Every <done> criterion must be verified=true in RESULT.json.
         "Mostly" = not done.

## [שיפור 39] SPEC REFERENCE TRACEABILITY
Every decision you make must reference the relevant SPEC section.
In RESULT.json, populate spec_sections_referenced with actual section numbers.
If you can't find a SPEC section supporting your approach, STOP and report.

## [שיפור 41] CIRCUIT BREAKER AWARENESS
If you notice yourself running the same command 3+ times without progress:
1. STOP immediately
2. Write to DECISIONS.md: "CIRCUIT BREAKER: [what was repeating] at step [N]"
3. Take a COMPLETELY different approach
If you cannot find a different approach, report: "⚠️ Blocked — need guidance"
```

---

## Agent: Critic — v6 REDESIGNED [שיפור 32]

```yaml
---
name: critic
description: Clean-room adversarial reviewer. NEVER sees executor reasoning. Reports partial confidence. Diff-based + silent audit + phantom check.
tools: Read, Write, Bash, Glob, Grep
---
```

**System Prompt — v6 (FULL REPLACEMENT):**

```
You are an adversarial code reviewer operating under CLEAN-ROOM PROTOCOL [שיפור 32].

## CRITICAL: WHAT YOU RECEIVE AND WHAT YOU DON'T

YOU RECEIVE:
- task_spec: Full task XML from PLAN_META.json including done_criteria, edge_cases
- diff: git diff HEAD~1 (unified format — the actual code changes)
- modified_files: Full content of modified files (re-read from disk, not cached)
- test_results: From RESULT.json — tests_run and verify_commands_run fields ONLY
- debiasing: This prompt section (anti-bias instructions below)

YOU DO NOT RECEIVE (and must NEVER request):
- Executor's SUMMARY.md (contains reasoning that biases your review)
- Executor's CoT or thought process
- Failed attempts or backtracking history
- Executor's confidence assessment
- Any narrative about WHY the code was written this way

This isolation is intentional. Research shows 88.2% of LLM reviewers are fooled by
implementer framing. With isolation + debiasing, detection rises to 93.75% [R2-6].

## DEBIASING INSTRUCTIONS
- Assume the code MAY contain subtle bugs even if tests pass.
- Treat passing tests with skepticism — tests themselves may be weak or self-mocking.
- Evaluate the code AGAINST THE SPEC, not against what seems reasonable.
- If something looks correct but you can't verify it from the diff, mark it UNVERIFIED.

## REVIEW PROCESS

STEP 1: STRUCTURAL INTEGRITY
git diff HEAD~1 --stat → empty = CRITICAL (hallucination)
Required files from task spec exist → MISSING = CRITICAL

STEP 2: ACCEPTANCE CRITERIA VERIFICATION [שיפור 37]
Read done_criteria from task spec.
Read done_criteria_checked from RESULT.json.
For EACH criterion:
  - verified=true in RESULT.json AND evidence looks real → VERIFIED
  - verified=true but evidence is vague/phantom → UNVERIFIED (PHANTOM)
  - verified=false → UNVERIFIED (HONEST)
  - not listed in RESULT.json → MISSING (CRITICAL)

STEP 3: DIFF-BASED CODE REVIEW
Read full diff line-by-line.
Check against task spec <action> and <done> criteria:
- Verification level [שיפור 2]: D needs integration test, C needs behavioral test
- Edge cases: for each <edge_cases> item, find implementation in diff
- Quality: 'any' type → MINOR | console.log → MINOR | TODO → MAJOR |
           API without try/catch → MAJOR | hardcoded secret → CRITICAL |
           SQL injection → CRITICAL | multi-tenant without filter → CRITICAL

STEP 4: PHANTOM VERIFICATION CHECK [שיפור 17]
Check RESULT.json verify_commands_run:
- Commands with empty output → SUSPICIOUS
- Commands not actually run → MAJOR
Scan for phantom language in RESULT.json evidence fields:
  "should", "seems", "likely", "I believe", "appears", "I think", "probably"
  → MAJOR: phantom verification in result data

STEP 5: SILENT FAILURE AUDIT [שיפור 6+28]
(Only if has_behavior=true OR verify_level=C|D)
In modified files from diff:
1. Silent catch blocks (catch with only console.log) → CRITICAL
2. Placeholder values committed → CRITICAL
3. Missing error state on async UI → MAJOR
4. Void returns on operations that should fail loudly → MINOR

STEP 6: TEST INTEGRITY CHECK
If tests exist in diff:
- Do tests check BEHAVIOR or just STRUCTURE?
- Any hard-coded return values? → MAJOR (test fraud [R1-Finding 8])
- Any self-mocking? → MAJOR
- Vacuous assertions (expect(true).toBe(true))? → MAJOR

## OUTPUT: [task]-CRITIC.md

```markdown
# Clean-Room Review: Task [id]

## Confidence Score [שיפור 37]
**[N] of [M] acceptance criteria verified | [K] unverified | [J] missing**
Overall: [HIGH|MEDIUM|LOW|INSUFFICIENT]

## Acceptance Criteria Status
| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | [criterion text] | ✅ VERIFIED / ⚠️ UNVERIFIED / ❌ MISSING | [what was checked] |
| 2 | ... | ... | ... |

## Diff Analysis
[Specific findings from line-by-line diff review]

## Verification Level Compliance
[Does the test match the required A/B/C/D level?]

## Edge Case Coverage
| Edge Case | Found in Diff? | Implementation |
|-----------|---------------|----------------|
| [case] | ✅/❌ | [how or "not found"] |

## Silent Failure Audit
[Clean or specific issues — only for behavioral tasks]

## Test Integrity
[Any test fraud indicators? Hard-coded returns, self-mocking, vacuous assertions?]

## Verdict: [PASS | PARTIAL | FAIL]
PASS = ALL criteria verified + zero critical + zero major
PARTIAL = SOME criteria verified + zero critical [שיפור 37]
FAIL = any critical or major issue

## Unresolved
[List anything the critic could not verify — this is HONEST, not a failure]
```

VERDICT RULES:
- PASS: ALL acceptance criteria VERIFIED + zero critical + zero major
- PARTIAL: >50% criteria verified + zero critical + zero major + remaining are low-risk
  → Orchestrator may proceed with advisory, or request recheck
- FAIL: any critical or major issue
  → Write REFLEXION brief for retry

ON FAIL → REFLEXION BRIEF [שיפור 7]:
Write [task]-REFLEXION.md (same as v5).

ON PASS or PARTIAL → LEARNING LOOP [שיפורים 4+9]:
If notable patterns found, append to ~/.claude/apex-learnings.md WITH CITATIONS.
```

---

## /apex:next — v6 Orchestration Updates

**Only the CHANGED sections are shown. All other /apex:next logic from v5 remains.**

### Build stage — Context Assembly (REPLACES v5 STEP F)

```
## STEP F: Build Context — ZONE-BASED + OBSERVATION MASKING [שיפורים 19+34+42+43]
Read CONTEXT_BUDGET.json
Read PLAN_META.json for current task

Determine context_profile from task type [שיפור 42]:
  If task has verify_level=C|D and has_behavior=true → "new_code" or "bug_fix"
  If task is test-writing → "test_writing"
  If task specialist=frontend → "frontend"
  Default → "new_code"

EXECUTOR_CONTEXT = {
  ## ZONE 1: Stable Prefix (cached)
  system_prompt: executor agent prompt (includes anti-rationalization table [שיפור 40]),
  claude_md: first 200 lines of CLAUDE.md [שיפור 46],
  repo_map: .apex/TASK_MAP.md (1-4K tokens),

  ## ZONE 2: Task Context (JIT-loaded per profile)
  task_xml: full task XML from PLAN.md (NEVER summarize),
  spec_sections: extract ONLY sections matching task.spec_ref [שיפור 39],
  decisions: extract ONLY decisions tagged current phase or 'global',
  dependency_summaries: for each dep, read RESULT.json.what_next_tasks_can_assume (not SUMMARY.md),
  stack_skills: from ~/.claude/apex-skills/ matching STATE.stack_skills (lazy-load [שיפור 24]),
  active_files: load full content of files in task.files that exist,
  interface_context: for dependencies, load ONLY function signatures (not full files),

  ## ZONE 3: Working Memory
  impacted_tests: .apex/IMPACTED_TESTS.txt (if exists),
  reflexion: [unit]-REFLEXION.md (if retry, NEVER summarize),
  ## NOTE: old tool outputs will be observation-masked during execution [שיפור 34]
}

TOTAL_TOKENS = estimate token count of EXECUTOR_CONTEXT
TARGET = CONTEXT_BUDGET.per_agent_limits[agent_type].target_input
MAX = CONTEXT_BUDGET.per_agent_limits[agent_type].max_input

If TOTAL_TOKENS > MAX:
  Apply reduction priority from CONTEXT_BUDGET.json [שיפור 34]:
  1. observation masking first (zero cost)
  2. trim dependency summaries
  3. trim spec sections
  4. trim stack skills
  5. trim decisions
  NEVER trim: task_xml, acceptance_criteria, reflexion_brief
```

### Build stage — Pre-Task Snapshot (NEW STEP before execution)

```
## STEP F.5: PRE-TASK SNAPSHOT [שיפור 36]
Before invoking any executor/specialist:
  git stash push -m "apex-snapshot-[task_id]-$(date +%s)" 2>/dev/null || true
  Update STATE.snapshots.pre_task_stash = latest stash ref
  Update STATE.snapshots.last_snapshot_task = task_id

This enables per-task rollback (not just per-phase).
If executor breaks something, user can: git stash pop to restore pre-task state.
```

### Build stage — Critic Invocation (REPLACES v5 critic_needed)

```
─────────────────────────────────────────────────────────
STATE: current_stage=build, status=critic_needed
─────────────────────────────────────────────────────────

## [שיפור 32] CLEAN-ROOM CRITIC CONTEXT
CRITIC_CONTEXT = {
  ## What critic RECEIVES:
  task_spec: task entry from PLAN_META.json (includes done_criteria, edge_cases, spec_ref),
  diff: "$(git diff HEAD~1)",
  modified_files: [re-read each modified file from disk — NOT from executor output],
  test_results: from [task]-RESULT.json — ONLY tests_run and verify_commands_run fields,
  debiasing: built into critic system prompt,

  ## What critic NEVER RECEIVES:
  ## ❌ [task]-SUMMARY.md
  ## ❌ executor reasoning/CoT
  ## ❌ executor confidence assessment
  ## ❌ failed attempts
  ## ❌ orchestrator narrative
}
Verify total tokens < CONTEXT_BUDGET.per_agent_limits.critic.max_input

Task("critic", CRITIC_CONTEXT)

## Process verdict with PARTIAL support [שיפור 37]:
CRITIC = PASS:
  [Same as v5: remove lock, reset reflexion, update autonomy, advance]

CRITIC = PARTIAL:
  Show user:
  "⚠️ Task [unit] — PARTIAL verification.
  Verified: [N] of [M] criteria. Unverified: [list]
  Zero critical/major issues found in verified portions.
  (1) Accept and continue (unverified items become known risks)
  (2) Retry to verify remaining criteria
  (3) Mark as manual verification needed"

  If (1): advance with advisory logged to DECISIONS.md
  If (2): STATUS = pending_approval (retry)
  If (3): advance with TODO in DECISIONS.md

CRITIC = FAIL:
  [Same as v5: reflexion loop]
```

---

## /apex:micro [שיפור 38, NEW]

```markdown
---
description: Execute trivial task with zero ceremony. <5 min, single file, no logic change.
---

<context>
Task from $ARGUMENTS.

## SAFETY NET ONLY — NO PLANNING, NO REVIEW
1. bash ~/.claude/hooks/pre-task-snapshot.sh micro
   → git stash for rollback

2. Read SPEC.md (if exists), DECISIONS.md (last 3 entries), CLAUDE.md (if exists)

3. Execute directly:
   Task("executor", "Execute this micro-task: [$ARGUMENTS].
   No formal planning. No RESULT.json needed. Just do it and commit.
   Follow CLAUDE.md conventions. Follow Named Failure Prohibitions.")

4. Verify: git diff HEAD~1 --stat
   If zero changes → "⚠️ Nothing changed. Was this the right command?"
   If changes exist → "✅ Done. Changes: [diff stat]"

5. Update STATE.json.tokens

NOTE: No critic review. No phantom check. No TDAD.
The git stash provides rollback safety.
Use ONLY for: rename, fix typo, update config, change display text, add comment.
If task involves logic, new files, or tests → use /apex:quick instead.
</context>
```

---

## New Hooks — v6

### destructive-guard.sh [שיפור 35]

```bash
#!/bin/bash
# Blocks destructive commands non-bypassably
# Based on: R1 research — 10 documented incidents, 0 vendor postmortems
# Hook type: PreToolUse (Bash)

COMMAND="$1"

# Deny-list of destructive patterns
DENY_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "rm -rf \."
  "rm -rf \*"
  "git reset --hard"
  "git clean -fdx"
  "DROP TABLE"
  "DROP DATABASE"
  "DROP SCHEMA"
  "TRUNCATE TABLE"
  "terraform destroy"
  "kubectl delete namespace"
  "docker system prune -af"
  "chmod -R 777"
  "mkfs\."
  "> /dev/sd"
  "dd if=/dev/zero"
  ":(){ :|:& };:"
)

for pattern in "${DENY_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qi "$pattern" 2>/dev/null; then
    echo "🛑 APEX DESTRUCTIVE GUARD: BLOCKED"
    echo "Command: $COMMAND"
    echo "Matched: $pattern"
    echo ""
    echo "This command is on APEX's deny-list. It cannot be executed."
    echo "If you believe this is a false positive, use the manual terminal."
    exit 2
  fi
done

# Additional check: rm -rf with path that goes up
if echo "$COMMAND" | grep -qE "rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--recursive)\s+\.\." 2>/dev/null; then
  echo "🛑 APEX DESTRUCTIVE GUARD: BLOCKED — rm -rf with parent directory traversal"
  exit 2
fi

exit 0
```

### pre-task-snapshot.sh [שיפור 36]

```bash
#!/bin/bash
# Creates git stash snapshot before task execution for per-task rollback
# Usage: bash pre-task-snapshot.sh [task_id]

TASK_ID=${1:-"unknown"}
TIMESTAMP=$(date +%s)
STASH_MSG="apex-snapshot-${TASK_ID}-${TIMESTAMP}"

# Check if there's anything to stash
if git diff --quiet HEAD 2>/dev/null && git diff --cached --quiet HEAD 2>/dev/null; then
  # Clean working tree — create empty stash marker
  echo "✅ PRE-TASK SNAPSHOT: Working tree clean (no stash needed)"

  # Update STATE.json
  if [ -f .apex/STATE.json ] && command -v jq &>/dev/null; then
    jq --arg task "$TASK_ID" --arg stash "clean-${TIMESTAMP}" \
       '.snapshots.pre_task_stash = $stash | .snapshots.last_snapshot_task = $task' \
       .apex/STATE.json > /tmp/state_snap.json && mv /tmp/state_snap.json .apex/STATE.json
  fi
  exit 0
fi

# Stash current changes
git stash push -m "$STASH_MSG" --include-untracked 2>/dev/null

if [ $? -eq 0 ]; then
  # Immediately pop to restore working state — the stash remains in reflog
  git stash pop 2>/dev/null

  # Update STATE.json
  if [ -f .apex/STATE.json ] && command -v jq &>/dev/null; then
    jq --arg task "$TASK_ID" --arg stash "$STASH_MSG" \
       '.snapshots.pre_task_stash = $stash | .snapshots.last_snapshot_task = $task' \
       .apex/STATE.json > /tmp/state_snap.json && mv /tmp/state_snap.json .apex/STATE.json
  fi

  echo "✅ PRE-TASK SNAPSHOT: Saved for task $TASK_ID"
  echo "   Rollback: git stash list | grep '$STASH_MSG'"
else
  echo "⚠️ PRE-TASK SNAPSHOT: git stash failed — continuing without snapshot"
fi

exit 0
```

### circuit-breaker.sh [שיפור 41]

```bash
#!/bin/bash
# Detects repeated actions without file changes — prevents infinite loops
# Based on: R1 findings — GSD Issue #456 (infinite loops), Superpowers recursive subagent
# Called after each tool use by executor

STATE_FILE=".apex/STATE.json"

if [ ! -f "$STATE_FILE" ] || ! command -v jq &>/dev/null; then
  exit 0
fi

# Get current file state hash
CURRENT_HASH=$(git diff HEAD --stat 2>/dev/null | md5sum | cut -d' ' -f1)
LAST_HASH=$(jq -r '.circuit_breaker.last_file_hash // ""' "$STATE_FILE" 2>/dev/null)
MAX_ALLOWED=$(jq -r '.circuit_breaker.max_allowed // 3' "$STATE_FILE" 2>/dev/null)

if [ "$CURRENT_HASH" = "$LAST_HASH" ] && [ -n "$LAST_HASH" ]; then
  # No file changes since last check
  COUNT=$(jq -r '.circuit_breaker.consecutive_no_change_actions // 0' "$STATE_FILE" 2>/dev/null)
  COUNT=$((COUNT + 1))

  jq --argjson count "$COUNT" \
     '.circuit_breaker.consecutive_no_change_actions = $count' \
     "$STATE_FILE" > /tmp/state_cb.json && mv /tmp/state_cb.json "$STATE_FILE"

  if [ "$COUNT" -ge "$MAX_ALLOWED" ]; then
    echo "🛑 CIRCUIT BREAKER TRIGGERED"
    echo "   $COUNT consecutive actions without file changes."
    echo "   Likely stuck in a loop."
    echo ""
    echo "   Options:"
    echo "   1. Take a completely different approach"
    echo "   2. Report: '⚠️ Blocked — need guidance'"
    echo "   3. /apex:recover to reset"

    jq '.circuit_breaker.triggered = true' "$STATE_FILE" > /tmp/state_cb.json && mv /tmp/state_cb.json "$STATE_FILE"
    exit 2
  fi
else
  # Files changed — reset counter
  jq --arg hash "$CURRENT_HASH" \
     '.circuit_breaker.consecutive_no_change_actions = 0 | .circuit_breaker.last_file_hash = $hash | .circuit_breaker.triggered = false' \
     "$STATE_FILE" > /tmp/state_cb.json && mv /tmp/state_cb.json "$STATE_FILE"
fi

exit 0
```

---

## context-monitor.sh — v6 Updated Thresholds [שיפור 29]

```bash
#!/bin/bash
# v6: Lowered thresholds based on R2 research
# R2: compact at 50-60%, hard rotate at 70%, never exceed 75%

STATE_FILE=".apex/STATE.json"
BUDGET_FILE=".apex/CONTEXT_BUDGET.json"

if [ ! -f "$STATE_FILE" ]; then
  echo "✅ CONTEXT: No state file — fresh session"
  exit 0
fi

if ! command -v jq &>/dev/null; then
  exit 0
fi

# v6 thresholds (lowered from v5)
WARNING_PCT=$(jq -r '.thresholds.proactive_compact_pct // 55' "$BUDGET_FILE" 2>/dev/null || echo 55)
CRITICAL_PCT=$(jq -r '.thresholds.hard_rotate_pct // 70' "$BUDGET_FILE" 2>/dev/null || echo 70)

# Estimate context usage
AGENT_CALLS_THIS_SESSION=$(jq -r '
  [.tokens.by_agent | to_entries[] | .value.calls] | add // 0' "$STATE_FILE" 2>/dev/null || echo 0)

# Heuristic: each agent call accumulates ~15K tokens in orchestrator context
ESTIMATED_USAGE=$((AGENT_CALLS_THIS_SESSION * 15000))
ESTIMATED_PCT=$((ESTIMATED_USAGE * 100 / 200000))

# Update STATE.json
jq --argjson pct "$ESTIMATED_PCT" \
   '.context.estimated_context_usage_pct = $pct' \
   "$STATE_FILE" > /tmp/state_ctx.json && mv /tmp/state_ctx.json "$STATE_FILE"

if [ "$ESTIMATED_PCT" -ge "$CRITICAL_PCT" ]; then
  echo "CRITICAL_OVERFLOW"
  echo "⚠️ Context estimated at ~${ESTIMATED_PCT}% (threshold: ${CRITICAL_PCT}%)"
  echo "R2 research: coding quality degrades severely above 70%."
  echo "Run /apex:resume for fresh context."
  exit 2
elif [ "$ESTIMATED_PCT" -ge "$WARNING_PCT" ]; then
  echo "WARNING_OVERFLOW"
  echo "⚠️ Context at ~${ESTIMATED_PCT}%. Proactive compact recommended."
  echo "R2: observation masking (deleting old tool outputs) is preferred over LLM summarization."
  exit 1
else
  echo "✅ CONTEXT: ~${ESTIMATED_PCT}% used (${AGENT_CALLS_THIS_SESSION} agent calls)"
  exit 0
fi
```

---

## settings.json — v6 Updated

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/destructive-guard.sh"}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/post-write.sh"}]
      },
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/circuit-breaker.sh"}]
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

## /apex:health-check — v6 Updated (9 tests)

**Test 9 added [שיפור 32]:**

```
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
```

---

## /apex:status — v6 Updated

```
🔨 APEX v6 — [Project Name] (Level [N] — [NAME])

[If pre-build:] ⚠️ PRE-BUILD: [X]/[Y] items complete

📍 Stage: [stage] → [status]
🎯 Phase: [current] / [total] | Wave: [current_wave]
✅ Units: [done] / [total]

🔐 Autonomy: Level [N] — [name]
   C/D successes: [N] | Next level at: [threshold]

[If reflexion active:]
🔄 Current unit: attempt [N] of [max]

📊 EvoScore: regression_rate=[N]%

📚 Comprehension Gates: [N] passed

🧠 Context Health: [🟢/🟡/🔴] ~[N]% | Session phase: [phase] | Rotations: [N]
   Observation masking: [active/inactive]
   Circuit breaker: [N]/[max] no-change actions

💰 Tokens: [total] | Framework overhead: [N]% (target: <5%)
   Phase: [breakdown] | Top agent: [name]

🛡️ Safety: Destructive guard [active] | Pre-task snapshots [active]
🏷️ Phase tags: [list]
🔧 Stack Skills: [list]
🏥 Agent health: [date] — [✅/⚠️]
📖 Learnings: [N] patterns | [N] silent | [N] edge cases

/apex:next to continue.
```

---

## Autonomy System — v6 (unchanged from v5 except reset triggers)

```
[Same as v5. Additional reset trigger:]

RESET TO 0 if:
  [all v5 triggers plus:]
  - Circuit breaker triggered [שיפור 41]
  - Destructive action blocked [שיפור 35]
```

---

## CLAUDE.md Template — v6

```markdown
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
```

---

## Installation — v6

```bash
#!/bin/bash
APEX_REPO="https://raw.githubusercontent.com/[user]/apex/main"

mkdir -p ~/.claude/commands/apex ~/.claude/agents/specialist ~/.claude/hooks ~/.claude/apex-skills

# Commands (12: added micro)
for cmd in start next micro spec status quick pause recover resume precheck health-check; do
  curl -sS "$APEX_REPO/.claude/commands/apex/$cmd.md" -o ~/.claude/commands/apex/$cmd.md
done

# Core agents (8)
for agent in diagnostician interviewer pre-build-planner architect executor critic verifier researcher; do
  curl -sS "$APEX_REPO/.claude/agents/$agent.md" -o ~/.claude/agents/$agent.md
done

# Specialist agents (4)
for spec in integration security data frontend; do
  curl -sS "$APEX_REPO/.claude/agents/specialist/$spec.md" -o ~/.claude/agents/specialist/$spec.md
done

# Hooks (13: added destructive-guard, pre-task-snapshot, circuit-breaker)
for hook in post-write subagent-stop pre-compact verify-learnings generate-task-map \
            phantom-check tdad-index cross-phase-audit context-monitor phase-tag \
            destructive-guard pre-task-snapshot circuit-breaker; do
  curl -sS "$APEX_REPO/.claude/hooks/$hook.sh" -o ~/.claude/hooks/$hook.sh
  chmod +x ~/.claude/hooks/$hook.sh
done

# Stack skills
for skill in nextjs supabase prisma tailwind stripe README; do
  curl -sS "$APEX_REPO/.claude/apex-skills/$skill.md" -o ~/.claude/apex-skills/$skill.md
done

# Settings + learnings
curl -sS "$APEX_REPO/.claude/settings.json" -o ~/.claude/settings.json
[ ! -f ~/.claude/apex-learnings.md ] && \
  curl -sS "$APEX_REPO/.claude/apex-learnings.md" -o ~/.claude/apex-learnings.md

echo "✅ APEX v6 installed — Research-Validated Context Engineering"
echo ""
echo "New in v6 (research-backed):"
echo "  🧪 Clean-room verification (93.75% detection rate)"
echo "  📊 Typed agent results (JSON, not prose)"
echo "  🗑️ Observation masking (50%+ cost reduction)"
echo "  🛡️ Destructive action guard (non-bypassable)"
echo "  📸 Pre-task snapshots (per-task rollback)"
echo "  📏 Honest uncertainty (partial confidence: 3/7 verified)"
echo "  ⚡ Level 0 micro-tasks (zero ceremony)"
echo "  🔗 Spec reference links (zero progressive compression)"
echo "  🛑 Circuit breaker (infinite loop prevention)"
echo ""
echo "First run:     /apex:health-check    (9 tests)"
echo "Micro task:    /apex:micro 'fix typo in header'"
echo "New project:   /apex:start"
echo "Fresh session: /apex:resume"
```

---

## השוואה מעודכנת: APEX v6 vs מתחרים

```
Feature                         | APEX v6 | GSD  | Superpowers | BMAD | Taskmaster
────────────────────────────────|─────────|──────|─────────────|──────|──────────
Clean-Room Verification          |  ✅ NEW |  ❌  |     ❌      |  ❌  |    ❌
Typed Agent Results (JSON)       |  ✅ NEW |  ❌  |     ❌      |  ❌  |    ❌
Observation Masking              |  ✅ NEW |  ❌  |     ❌      |  ❌  |    ❌
Destructive Action Guard         |  ✅ NEW |  ❌  |     ❌      |  ❌  |    ❌
Pre-Task Snapshots               |  ✅ NEW |  ❌  |     ❌      |  ❌  |    ❌
Honest Uncertainty (partial)     |  ✅ NEW |  ❌  |     ❌      |  ❌  |    ❌
Level 0 Micro-Tasks              |  ✅ NEW |  ❌  |     ❌      |  ❌  |    ❌
Spec Reference Traceability      |  ✅ NEW |  ❌  |     ❌      |  ❌  |    ❌
Anti-Rationalization Tables      |  ✅ NEW |  ❌  |     ✅      |  ❌  |    ❌
Circuit Breaker                  |  ✅ NEW |  ❌  |     ❌      |  ❌  |    ❌
Task-Adaptive Context Profiles   |  ✅ NEW |  ❌  |     ❌      |  ❌  |    ❌
Context Zone Architecture        |  ✅ NEW |  ❌  |     ❌      |  ❌  |    ❌
Complexity Classification        |   ✅    |  ❌  |     ❌      |  ✅  |    ❌
Fresh Context per Phase          |   ✅    |  ✅  |     ❌      |  ❌  |    ❌
Context Budget per Agent         |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Token Tracking                   |   ✅    |  ✅* |     ❌      |  ❌  |    ❌
Silent Failure Detection         |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Phantom Verification Guard       |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Named Failure Prohibitions       |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Verification Ladder (A-D)        |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Comprehension Gates              |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Architecture Debate (MAD)        |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Cross-Phase Regression           |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Phase Rollback (git tags)        |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Reflexion Loop                   |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Wave-Based Parallel              |   ✅    |  ✅  |     ✅      |  ❌  |    ❌
TDD Enforcement                  |   ✅    |  ✅  |     ✅      |  ❌  |    ❌
Diff-Based Code Review           |   ✅    |  ❌  |     ✅      |  ❌  |    ❌
Stack-Specific Skills            |   ✅    |  ✅  |     ✅      |  ❌  |    ❌
Citation-Based Learning          |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
TDAD Dependency Tests            |   ✅    |  ❌  |     ❌      |  ❌  |    ❌
Multi-Platform Support           |   ❌    |  ✅  |     ✅      |  ✅  |    ✅
Plugin Marketplace               |   ❌    |  ✅  |     ✅      |  ❌  |    ❌

UNIQUE TO APEX v6: 12 features no competitor offers.
Framework overhead target: <5% of context (vs Superpowers 11%, Taskmaster 25%, BMAD 86%).
```

---

## Research References

Every v6 change traces to specific research findings:

| Change | Research Source | Confidence |
|--------|---------------|------------|
| Clean-room verification | R2-6: 88.2% bias, 93.75% with debiasing | HIGH (5/5) |
| Typed agent results | R2-C2: structured > free-text | HIGH (5/5) |
| Observation masking | R2-3: JetBrains study, +2.6% vs summarization | HIGH (4/5) |
| Destructive guard | R1: 10 incidents, 0 postmortems | HIGH (documented) |
| Pre-task snapshots | R1-7.2: rollback guarantee recommendation | HIGH (5/5) |
| Honest uncertainty | R1-Rank 1: #1 unmet need across all tools | HIGH (5/5) |
| Level 0 micro-tasks | R1-F6: excessive ceremony = abandonment driver | HIGH (5/5) |
| Spec references | R1-F2: Taskmaster loses 80%+ of spec | HIGH (2/5, quantified) |
| Anti-rationalization | R2-7.2: Superpowers innovation, validated | MEDIUM-HIGH |
| Circuit breaker | R1-F5: GSD Issue #456, infinite loops | HIGH (4/5) |
| Task-adaptive context | R2-D2: different task types need different context | HIGH (5/5) |
| Context zones | R2-8.1: unanimous architectural recommendation | HIGH (5/5) |
| 50-60% compact threshold | R2-A3: JetBrains + all 5 models | HIGH (5/5) |
| <200 line CLAUDE.md | R2-B4: 92% at <200, 71% at 400+ | MEDIUM-HIGH |
| Primacy-recency ordering | R2-A1: U-shaped attention, all 5 models | HIGH (5/5) |
