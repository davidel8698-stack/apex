# APEX Framework — Deep Forensic Audit — 2026-04-10

## Executive Summary

**Overall state:** The APEX framework is architecturally sound and has benefited significantly from Rounds 2–5 of remediation. All 12 previously-closed findings remain fixed. The core pipeline (/apex:next → executor → critic → verdict) is correctly wired and the clean-room protocol is properly enforced. The hook system is comprehensive, with proper 3-tier exit codes (0/1/2), filesystem-level verification, and tool guards.

**However**, this audit surfaces **19 new findings** that the prior audit missed or that were introduced during remediation:

| Severity | Count |
|----------|-------|
| P0 (Critical) | 0 |
| P1 (High) | 5 |
| P2 (Medium) | 6 |
| P3 (Low) | 8 |

**Top 5 most important findings:**

1. **DEEP-SO-001 (P1):** STATE.json is schema-invalid at creation — start.md omits ~10 required fields that are progressively populated, but the schema demands them all with `additionalProperties: false`.
2. **DEEP-DD-001 (P1):** verifier.md reads `*-SUMMARY.md` for test results, but test results live in RESULT.json. SUMMARY.md is human narrative only.
3. **DEEP-DD-002 (P1):** status.md references `STATE.project_name` and `STATE.level_name` — fields that don't exist in the schema (correct names: `project`, `complexity_name`).
4. **DEEP-SF-001 (P1):** drift_indicators accumulate across sessions but are never reset on /apex:resume, causing potential re-pause loops.
5. **DEEP-SF-002 (P1):** pre-compact.sh exits 1 (advisory) on backup failure, meaning compaction can proceed after a failed backup — data loss risk for STATE.json.

**Pattern-Echo Hallucination note:** During this audit, 6 sub-agents generated false findings claiming schema fields were undeclared when they were present. Every finding below was verified against current file content by the primary auditor. See "Auditor's Self-Critique" section.

---

## Audit Methodology

This audit followed the prescribed 10-pass methodology:

1. **Pass 1 (Inventory):** Complete enumeration of all 72 framework files with line counts.
2. **Pass 2 (Call Graph):** Systematic grep of every hook, agent, and schema to map callers and identify dead code.
3. **Pass 3 (Documentation Drift):** Line-by-line comparison of command docs against actual hook/agent behavior.
4. **Pass 4 (Environment Dependencies):** Tool usage audit for jq, git, rg, python3, npx, stryker, mutmut.
5. **Pass 5 (Error Handling):** Exit code audit, set -u/set -e analysis, silent failure detection.
6. **Pass 6 (State File Analysis):** Field lifecycle mapping for STATE.json, CONTEXT_BUDGET.json, PLAN_META.json, RESULT.json.
7. **Pass 7 (Pipeline Tracing):** Full execution walk-through of /apex:next (670 lines) and all other commands.
8. **Pass 8 (Settings & Wiring):** Deployed settings.json vs framework hooks comparison.
9. **Pass 9 (Anti-Pattern Hunt):** Targeted search for AP-1 through AP-6 and new candidates.
10. **Pass 10 (Cross-Check):** Consistency check against observed Shield project behavior.

**Deviation:** No runtime execution of hooks was performed. All findings are based on static code analysis. Findings that require runtime verification are flagged as such.

---

## Inventory Results

### Hooks (19 files, 1257 lines)

| File | Lines | Description |
|------|-------|-------------|
| `_require-git.sh` | 17 | Guard: fails loud if git unavailable or not in repo |
| `_require-jq.sh` | 23 | Guard: ensures jq is in PATH before dependent hooks |
| `_state-update.sh` | 47 | Atomic JSON state updater using jq + temp file + mv |
| `circuit-breaker.sh` | 79 | Detects no-change loops and tool-call spirals; exits 2 on breach |
| `context-monitor.sh` | 58 | Real token counting; proactive compact at 55%, hard rotate at 70% |
| `cross-phase-audit.sh` | 104 | Runs regression tests from prior phases before phase advancement |
| `destructive-guard.sh` | 180 | Blocks rm/DROP TABLE/destructive patterns with chained command detection |
| `generate-task-map.sh` | 97 | Builds repository map of task-relevant files |
| `mutation-gate.sh` | 81 | Post-critic mutation testing for C/D tasks (Stryker or mutmut) |
| `phantom-check.sh` | 29 | Blocks advancement on uncertainty language in SUMMARY.md |
| `phase-tag.sh` | 44 | Creates git tags for completed phases with filesystem verification |
| `post-write.sh` | 36 | Post-write validation: TypeScript checking + secret detection |
| `pre-compact.sh` | 40 | Backs up STATE.json before compaction; tracks observation masking |
| `pre-task-snapshot.sh` | 82 | Creates git stash snapshot per-task for rollback |
| `session-log.sh` | 51 | Appends timestamped events to SESSION-LOG.md |
| `subagent-stop.sh` | 41 | Validates executor completed with tool calls (hallucination guard) |
| `tdad-index.sh` | 90 | Builds code-test dependency graph using embedded Python |
| `tdad-impact.py` | 47 | Python utility: identifies impacted tests from changed files |
| `verify-learnings.sh` | 111 | Validates apex-learnings.md citations, enforces HOT/WARM ceilings |

### Commands (12 files, 1416 lines)

| File | Lines | Description |
|------|-------|-------------|
| `_debate.md` | 45 | Architecture debate protocol for irreversible decisions |
| `health-check.md` | 191 | Poison pill validation with 10 agent + environment tests |
| `micro.md` | 45 | Trivial single-file tasks — no critic, no phantom check |
| `next.md` | 670 | Main orchestrator: stages, routing, executor, critic, verdict |
| `pause.md` | 28 | Saves state and pauses work |
| `precheck.md` | 15 | Marks pre-build checklist items complete |
| `quick.md` | 64 | Small tasks with executor + critic but no full planning |
| `recover.md` | 15 | Recovery from crash or stuck state |
| `resume.md` | 143 | Resume project with auto-pause recovery and breaker checks |
| `spec.md` | 12 | Review or update specification |
| `start.md` | 108 | Project initialization with precheck, STATE init, planner dispatch |
| `status.md` | 80 | Glass cockpit dashboard with token economy, autonomy, session health |

### Agents (9 files, 568 lines)

**Core (5):**

| File | Lines | Description |
|------|-------|-------------|
| `architect.md` | 94 | Creates phase plans with structured PLAN_META.json |
| `critic.md` | 82 | Adversarial clean-room reviewer; never sees executor reasoning |
| `executor.md` | 217 | Task implementor with reflexion, TDAD awareness, RESULT.json output |
| `planner.md` | 46 | Complexity classifier, requirements capturer |
| `verifier.md` | 62 | Phase-level verification with cross-phase regression checking |

**Specialists (4):**

| File | Lines | Description |
|------|-------|-------------|
| `specialist/data.md` | 17 | RLS, migrations, N+1 prevention |
| `specialist/frontend.md` | 16 | Loading states, error boundaries, accessibility |
| `specialist/integration.md` | 17 | OAuth, webhooks, API tokens |
| `specialist/security.md` | 17 | Tenant isolation, RLS, injection prevention |

### Schemas (4 files, 623 lines)

| File | Lines | Description |
|------|-------|-------------|
| `CONTEXT_BUDGET.schema.json` | 100 | Token zones, thresholds (55/70/75%), per-agent limits |
| `PLAN_META.schema.json` | 54 | Structured task metadata: spec_ref, verify_level, done_criteria |
| `RESULT.schema.json` | 113 | Typed executor output consumed by critic |
| `STATE.schema.json` | 356 | Full machine state: 41 required fields |

### Scripts (3 files, 431 lines)

| File | Lines | Description |
|------|-------|-------------|
| `self-test.sh` | 43 | Test runner executing framework/tests/ |
| `sync-to-claude.sh` | 160 | Deploys framework/ → ~/.claude/ with orphan detection |
| `validate-state.sh` | 228 | JSON Schema validator with soft/strict modes |

### Other Framework Files

| File | Lines | Description |
|------|-------|-------------|
| `DEV-FLOW.md` | 88 | Authoritative dev workflow |
| `apex-branding.md` | 1176 | Peak Protocol visual identity system |
| `apex-design-notes.md` | 91 | Design rationale for R1-R8 |
| `apex-learnings.md` | 159 | Tiered learning accumulator (HOT/WARM/COLD) |
| `apex-model-routing.json` | 50 | Model routing: 9 agents, Sonnet default, Opus for security |
| `apex-skills/` | 10 files, 329 lines | Stack-specific patterns (React, Next.js, Prisma, etc.) |
| `tests/` | 8 files, 643 lines | Test harness + 7 test suites |
| `test-fixtures/` | 2 files, 264 lines | Valid/invalid STATE.json samples |

### Framework vs Deployed (~/.claude/) Comparison

**Result:** All APEX hooks, commands, agents, and schemas are synchronized between `framework/` and `~/.claude/`. Only non-APEX files differ:

| Difference | Status |
|------------|--------|
| `~/.claude/hooks/gsd-check-update.js` | GSD-only, not part of APEX. Expected. |
| `~/.claude/hooks/gsd-statusline.js` | GSD-only, not part of APEX. Expected. |

**No missing APEX files. No orphaned deployed files.**

---

## Call Graph Results

### Hook Wiring Summary

**Wired in settings.json (automatic, event-driven):**

| Event | Hook | Status |
|-------|------|--------|
| PreToolUse[Bash] | `destructive-guard.sh` | WIRED |
| PostToolUse[Write\|Edit] | `post-write.sh` | WIRED |
| PostToolUse[Bash] | `circuit-breaker.sh` | WIRED |
| SubagentStop | `subagent-stop.sh` | WIRED |
| PreCompact | `pre-compact.sh` | WIRED |
| SessionStart | `verify-learnings.sh` | WIRED |

**Called explicitly from commands (not wired — intentional):**

| Hook | Called From |
|------|-----------|
| `context-monitor.sh` | next.md:35 |
| `cross-phase-audit.sh` | next.md:187,414,495; verifier.md:41 |
| `generate-task-map.sh` | next.md:201; quick.md:38; micro.md:38 |
| `mutation-gate.sh` | next.md:399 |
| `phantom-check.sh` | next.md:291; quick.md:62 |
| `phase-tag.sh` | next.md:522; verifier.md:46 |
| `pre-task-snapshot.sh` | next.md:246; quick.md:31; micro.md:24 |
| `session-log.sh` | next.md (7 call sites); start.md:104; resume.md:43 |
| `tdad-impact.py` | next.md:204 |
| `tdad-index.sh` | next.md:145 |

**Helper libraries (sourced, not called directly):**

| Hook | Sourced By |
|------|-----------|
| `_require-git.sh` | circuit-breaker, cross-phase-audit, generate-task-map, phase-tag, pre-task-snapshot, subagent-stop, tdad-index (7 hooks) |
| `_require-jq.sh` | circuit-breaker, context-monitor, cross-phase-audit, generate-task-map, mutation-gate, pre-compact, pre-task-snapshot, subagent-stop, tdad-index, verify-learnings (10 hooks) |
| `_state-update.sh` | circuit-breaker, context-monitor, cross-phase-audit, mutation-gate, phase-tag, pre-compact (6 hooks) |

### Dead Code: NONE

All 19 hooks have at least one caller. Zero orphaned hooks.

### Phantom Agents: NONE

All 9 agents referenced in commands have corresponding files. All 9 agent files are referenced in at least one command.

### Orphaned Schemas: NONE

All 4 schemas are referenced by hooks, commands, or agents.

### Agent Dispatch Map

| Command | Agents Dispatched |
|---------|------------------|
| next.md | planner, architect, executor, critic, verifier + 4 specialists |
| quick.md | executor, critic |
| micro.md | executor |
| start.md | planner |
| health-check.md | executor, critic, architect, security-specialist (tests) |
| _debate.md | architect (3x: advocate A, advocate B, judge) |

---

## Pipeline Trace Summary

### /apex:next — Full Execution Path (670 lines)

```
1.  Read STATE.json
2.  CONTEXT OVERFLOW CHECK → context-monitor.sh (exit 2=rotate, 1=compact, 0=ok)
3.  SESSION GUARDIAN → auto-init session if missing
4.  SESSION HEALTH CHECK → compute ERROR_RATE, PARTIAL_RATE → health status
5.  If red → auto-pause, STOP
6.  MODEL ROUTING HELPER → resolve_model() from apex-model-routing.json
7.  Route by current_stage:
    ├─ pre-build → show checklist, block if incomplete
    ├─ spec → show SPEC.md, await approval
    ├─ architect → build ARCHITECT_CONTEXT, dispatch architect agent
    │  └─ tdad-index.sh → init autonomy → set stage=build
    └─ build → STEPS A-K below
8.  STEP A: Read WAVE_MAP → find NEXT_UNIT
    └─ Wave boundary → cross-phase-audit.sh, wave tag
9.  STEP B: generate-task-map.sh → tdad-impact.py (if index built)
10. STEP C: Irreversible check → _debate.md protocol if is_irreversible
11. STEP D: Load REFLEXION.md if retry (ATTEMPTS > 0)
12. STEP E: Build EXECUTOR_CONTEXT (3 zones: stable/task/working)
13. STEP F: pre-task-snapshot.sh → exit 2=prompt, 0=proceed
14. STEP G: Autonomy check → dispatch executor/specialist by verify_level
15. STEP H: Executor produces RESULT.json + SUMMARY.md
16. STEP I: phantom-check.sh on SUMMARY.md → exit 2=synthetic FAIL, 0=continue
17. STEP J: CLEAN-ROOM CRITIC (skipped if phantom failed)
    └─ CRITIC_CONTEXT = {task_spec, diff, modified_files, test_results from RESULT.json}
18. STEP K: PROCESS VERDICT
    ├─ PASS → reset reflexion, autonomy++, session checkpoint, mutation-gate (C/D)
    ├─ PARTIAL → advisory, log
    └─ FAIL → reflexion attempt++, if ≥3 → blocked, else retry
19. LEARNING EXTRACTION (on FAIL/PARTIAL)
20. PHASE VERIFICATION (when all waves complete)
    ├─ Complexity ≤ 2 → phase-level critic
    └─ Complexity > 2 → verifier agent
21. Phase PASS → phase-tag.sh, autopilot tracking, comprehension gate
22. AUTOPILOT ADVISOR (on user request)
```

**Pipeline integrity observations:**
- All hooks referenced exist and are reachable
- Exit code handling is explicit for critical hooks (pre-task-snapshot, phantom-check)
- The phantom→critic skip path (PHANTOM_SKIP_CRITIC) is correctly guarded
- Session log is called at every state transition

### /apex:quick — Abbreviated Path

```
1.  INPUT GUARD → validate target + action verb
2.  mkdir .apex/phases/quick/
3.  pre-task-snapshot.sh
4.  generate-task-map.sh
5.  Read SPEC, DECISIONS, TASK_MAP
6.  Dispatch executor/specialist
7.  Dispatch critic (diff-based review)
8.  If FAIL → reflexion retry (max 2 attempts, NOT 3 — see DEEP-DD-007)
9.  phantom-check.sh
10. Update learnings + tokens
```

### /apex:micro — Minimal Path

```
1.  INPUT GUARD → validate file path + verb
2.  pre-task-snapshot.sh
3.  Read SPEC, DECISIONS, CLAUDE
4.  Dispatch executor (NO critic, NO phantom check)
5.  Verify via git diff
```

### /apex:resume — Recovery Path

```
1.  Read STATE, COMPLEXITY, SPEC summary, DECISIONS
2.  AUTO-PAUSE RECOVERY → reset pause flags (NOT drift_indicators — see DEEP-SF-001)
3.  SESSION UPDATE → increment rotations, update context
4.  DISPLAY → branding, status bar, ambient header
5.  AUTOPILOT CHECK → 7 circuit breakers
    └─ After breakers pass → refresh previous_* fields → auto-continue via /apex:next
```

### /apex:start — Initialization Path

```
1.  ENVIRONMENT PRECHECK → verify jq, git, rg
2.  INFRASTRUCTURE SELF-TEST → self-test.sh
3.  Check existing project → redirect if exists
4.  mkdir .apex/ directories
5.  USER PROFILE CAPTURE
6.  STATE INITIALIZATION → creates STATE.json (schema-invalid — see DEEP-SO-001)
7.  Create CONTEXT_BUDGET.json (no defaults — see DEEP-SO-005)
8.  session-log.sh "resume" (should be "start" — see DEEP-DD-006)
9.  Dispatch planner
10. Update stage based on complexity
```

---

## Environment Dependency Summary

### Tool Guard Coverage

| Tool | Used By | Guard Type | Status |
|------|---------|-----------|--------|
| jq | 10 hooks | `_require-jq.sh` (exit 2) | Fully guarded |
| git | 7 hooks | `_require-git.sh` (exit 2) | Fully guarded |
| rg | generate-task-map.sh | `command -v` → fallback to grep | Graceful degradation |
| python3 | tdad-index.sh | `command -v` → exit 1 (advisory) | Graceful degradation |
| npx/tsc | post-write.sh | `command -v` + tsconfig check | Conditional |
| stryker | mutation-gate.sh | `command -v npx && npx stryker --version` | Graceful degradation |
| mutmut | mutation-gate.sh | `command -v mutmut` | Graceful degradation |
| grep/sed/awk | All hooks | None (POSIX standard) | Assumed available |
| md5sum | circuit-breaker.sh | None | Assumed available |
| date/mkdir | Various | None (POSIX standard) | Assumed available |

### Silent Stderr Suppression Patterns

The most common pattern is `jq ... 2>/dev/null || fallback`, used consistently to provide defaults when STATE or BUDGET files don't exist. This is intentional and safe.

Potentially concerning uses:
- `circuit-breaker.sh:22` — `git diff HEAD --stat 2>/dev/null` (if git fails, hash becomes timestamp-based, avoiding false positives)
- `cross-phase-audit.sh:34` — `jq ... "$META_FILE" 2>/dev/null` (if META is malformed, commands are empty and phase is skipped silently)
- `pre-task-snapshot.sh:66` — `git stash store ... 2>/dev/null` (stderr suppressed but compensated by filesystem verification at line 70)

---

## State File Lifecycle Analysis

### STATE.json Field Lifecycle Summary

Fields are categorized by their lifecycle completeness: whether they are (1) defined in schema, (2) initialized by start.md, (3) written by hooks/commands, and (4) read by hooks/commands.

**Fully Lifecycle-Complete (defined + initialized + written + read):**

| Field | Init | Writers | Readers |
|-------|------|---------|---------|
| `apex_version` | start.md:44 | — (constant) | resume.md, status.md |
| `reflexion.*` | start.md:55 | next.md:446-472 | next.md:214 |
| `context.*` | start.md:59 | context-monitor.sh:42, resume.md:46-49 | context-monitor.sh:23-24, next.md:168 |
| `tokens.*` | start.md:60 | next.md:280, circuit-breaker.sh:63 | context-monitor.sh:23-24, status.md:43-45 |
| `circuit_breaker.*` | start.md:63 | circuit-breaker.sh:35-76 | circuit-breaker.sh:28-32,59-60 |
| `snapshots.*` | start.md:64 | pre-task-snapshot.sh:30-38 | — (rollback utility) |
| `autopilot.*` | start.md:65-86 | next.md:407-461, resume.md:68-136 | next.md:406-429, resume.md:67-121, status.md:57-64 |
| `session.*` | start.md:88-102 | next.md:44-78,390-455, resume.md:33-49 | next.md:38-72, resume.md:26-42, status.md:52-55 |
| `evoscore.*` | start.md:56 | cross-phase-audit.sh:82-87 | status.md:48 |
| `phase_tags` | start.md:61 | phase-tag.sh:31-32 | — (rollback lookup) |
| `health_check.*` | start.md:54 | health-check.md | status.md |

**Partially Lifecycle-Complete (gap in one stage):**

| Field | Gap | Finding |
|-------|-----|---------|
| `autonomy.*` | NOT initialized by start.md (init'd by next.md:155-158) | DEEP-SO-001 |
| `project` | NOT initialized by start.md (set by planner) | DEEP-SO-001 |
| `complexity_level` | NOT initialized by start.md (set by planner) | DEEP-SO-001 |
| `complexity_name` | NOT initialized by start.md (set by planner) | DEEP-SO-001 |
| `pipeline` | NOT initialized by start.md (set by planner) | DEEP-SO-001 |
| `current_stage` | NOT initialized by start.md (set after planner) | DEEP-SO-001 |
| `current_phase` | NOT initialized by start.md (set by architect stage) | DEEP-SO-001 |
| `current_unit` | NOT initialized by start.md (set by architect stage) | DEEP-SO-001 |
| `current_wave` | NOT initialized by start.md (set by architect stage) | DEEP-SO-001 |
| `status` | NOT initialized by start.md (set after planner) | DEEP-SO-001 |
| `mutation_scores` | NOT initialized by start.md (lazily created by mutation-gate.sh) | DEEP-SO-002 |
| `comprehension_gates` | Initialized but NEVER updated by any code | DEEP-SO-003 |

**CONTEXT_BUDGET.json:**

| Field | Schema | Init | Usage |
|-------|--------|------|-------|
| `thresholds.proactive_compact_pct` | Yes | No default file | context-monitor.sh:19 (fallback: 55) |
| `thresholds.hard_rotate_pct` | Yes | No default file | context-monitor.sh:20 (fallback: 70) |
| `capacity_tokens` | NOT in schema | No default file | context-monitor.sh:27 (fallback: 200000) |
| `per_agent_limits.*` | Yes | No default file | next.md:135,348 |
| `context_reduction_priority` | Yes | No default file | next.md:241 |

**RESULT.json (per-task, written by executor):**

| Field | Schema | Writer | Reader |
|-------|--------|--------|--------|
| `task_id` | Yes | executor.md | next.md, critic.md |
| `status` | Yes (enum: success/failure/partial) | executor.md | next.md:277 |
| `tests_run` | Yes | executor.md | critic.md:13, next.md:345 |
| `verify_commands_run` | Yes | executor.md | critic.md:13, next.md:345 |
| `done_criteria_checked` | Yes | executor.md | next.md:530 |
| `confidence` | Yes (enum: high/medium/low) | executor.md | next.md:453 |
| `what_next_tasks_can_assume` | Yes | executor.md | next.md:232 (dependency summaries) |

**Note on RESULT.json `status` enum vs next.md verdict naming:**
- RESULT.json uses: `success`, `failure`, `partial`
- next.md verdicts use: `PASS`, `PARTIAL`, `FAIL`
- These are different naming conventions for the same concept. The mapping is implicit, not explicitly documented.

---

## Settings & Wiring Audit

### ~/.claude/settings.json Hook Wiring Analysis

**Complete wiring block (verified):**

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/destructive-guard.sh" }]
    }],
    "PostToolUse": [
      { "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/post-write.sh" }] },
      { "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/circuit-breaker.sh" }] }
    ],
    "SubagentStop": [{
      "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/subagent-stop.sh" }]
    }],
    "PreCompact": [{
      "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/pre-compact.sh" }]
    }],
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "node \"...gsd-check-update.js\"" }] },
      { "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/verify-learnings.sh" }] }
    ]
  }
}
```

**Wiring correctness checklist:**

| Check | Result |
|-------|--------|
| All wired hooks exist on disk | PASS — all 6 APEX hooks present at ~/.claude/hooks/ |
| No stderr suppression in wiring | PASS — no `2>/dev/null` or `\|\| true` in command strings |
| Events match hook purpose | PASS — destructive-guard on PreToolUse[Bash], post-write on PostToolUse[Write\|Edit], etc. |
| Hook paths use `~/.claude/hooks/` consistently | PASS |
| Non-APEX hooks present | gsd-check-update.js (SessionStart) and gsd-statusline.js (statusLine) — not part of APEX, expected |

**Hooks NOT wired (by design — called explicitly from commands):**

| Hook | Why Not Wired |
|------|--------------|
| context-monitor.sh | Only needed at /apex:next start, not every tool call |
| session-log.sh | Invoked with specific event type parameters |
| pre-task-snapshot.sh | Only needed before task execution, not every tool call |
| phantom-check.sh | Only needed after executor completes |
| cross-phase-audit.sh | Only needed at phase/wave boundaries |
| phase-tag.sh | Only on phase completion |
| generate-task-map.sh | Only before task dispatch |
| mutation-gate.sh | Only after critic PASS on C/D tasks |
| tdad-index.sh | Only after architect completes |
| tdad-impact.py | Only with TDAD index built |

**This design is correct:** Automatic hooks (settings.json) fire on EVERY event. Only hooks that need to run on every bash call / every write should be wired. Command-specific hooks are explicitly called to avoid overhead.

---

## Error Handling Summary

### Shell Safety Settings Coverage

| Setting | Hooks Using It | Notes |
|---------|---------------|-------|
| `set -u` | 16/16 non-helper hooks | Undefined variable protection — universal |
| `set -e` | 0/16 hooks | Not used — explicit error handling instead |
| `set -o pipefail` | 2/16 hooks | cross-phase-audit.sh, generate-task-map.sh only |

### Exit Code Discipline

All hooks follow the 3-tier convention consistently:

| Exit Code | Meaning | Usage |
|-----------|---------|-------|
| 0 | Success | All hooks |
| 1 | Advisory (non-blocking) | pre-compact (backup fail), tdad-index (python3 missing), context-monitor (warning), subagent-stop (git error), pre-task-snapshot (git error) |
| 2 | Blocking (halt execution) | destructive-guard (deny), circuit-breaker (loop/cap), cross-phase-audit (regression), phantom-check (uncertainty), phase-tag (unverified), post-write (errors), pre-task-snapshot (unverified stash), subagent-stop (hallucination), mutation-gate (below threshold) |

**Exception:** verify-learnings.sh always exits 0 even when issues found (see DEEP-SF-004).

### $? Usage Patterns

All hooks that capture `$?` do so immediately after the relevant command:
- `post-write.sh:9` — `TSC_EXIT=$?` after npx tsc
- `cross-phase-audit.sh:62` — `EXIT_CODE=$?` after bash -c
- `pre-task-snapshot.sh:47` — `STASH_EXIT=$?` after git stash create
- `phase-tag.sh:24` — `TAG_EXIT=$?` after git tag -a
- `subagent-stop.sh:24` — `GIT_EXIT=$?` after git diff

No instances of stale `$?` (reading exit code from wrong command).

### Filesystem-Level Verification Pattern

Three hooks implement the "trust but verify" pattern — they don't trust `$?` alone, but confirm the side effect at filesystem level:

**phase-tag.sh (lines 26-43):**
```bash
# After git tag -a:
if git tag -l "$TAG_NAME" | grep -qF "$TAG_NAME"; then
  # Tag creation confirmed at filesystem level
  exit 0
else
  echo "🚫 PHASE TAG: creation unverified at filesystem level" >&2
  exit 2
fi
```

**pre-task-snapshot.sh (lines 68-81):**
```bash
# After git stash store:
if git stash list | grep -qF "$STASH_MSG"; then
  # Stash confirmed in git stash list
  exit 0
else
  echo "🚫 PRE-TASK SNAPSHOT: stash creation unverified" >&2
  exit 2
fi
```

**subagent-stop.sh (lines 23-36):**
```bash
# After agent completes:
DIFF=$(git diff HEAD --stat 2>&1)
GIT_EXIT=$?
if [ $GIT_EXIT -ne 0 ]; then
  exit 1  # git error — advisory, can't verify
fi
if [ -z "$DIFF" ]; then
  echo "❌ No git changes after $AGENT — possible hallucination"
  exit 2
fi
```

This pattern is a framework strength — it prevents the "claimed but didn't happen" failure mode.

### Destructive Guard Coverage Analysis

`destructive-guard.sh` (180 lines) is the largest hook. It blocks:

| Pattern | Detection | Bypass Risk |
|---------|-----------|-------------|
| `rm -rf /` (recursive+force+dangerous) | Flag combination check | LOW — 3 flags must combine |
| `git reset --hard` | Direct pattern | LOW |
| `git push --force` (all variants) | Including --force-with-lease | LOW |
| `DROP TABLE/DATABASE/SCHEMA/INDEX` | Case-insensitive SQL | LOW — but only in execution context |
| `ALTER TABLE ... DROP` | Column/constraint drops | LOW |
| `DELETE FROM` without WHERE | Mass deletion guard | LOW |
| `terraform destroy` | Infrastructure destruction | LOW |
| `docker system prune -af` | Container cleanup | LOW |
| Fork bomb | Pattern match | MEDIUM — regex-based, variants possible |

**Quote-aware splitting (v7.1 B-7):**
The guard uses a pure-bash state machine (lines 124-164) for command splitting, handling quoted strings correctly. This prevents both false positives (`echo "rm -rf /"` is safe) and bypasses (`safe_cmd && rm -rf /` is caught).

**Known limitation:** Pipe chains (`|`) are intentionally not split (line 116-117) because pipes are data flow. This means `echo password | mysql -u root -p` would not be caught even if the mysql command is destructive. This is a design choice documented in the code.

### Cross-Phase Audit Security Model

`cross-phase-audit.sh` executes verify commands from PLAN_META.json (line 61: `bash -c "$cmd"`). This is security-relevant because PLAN_META.json is written by the architect agent, not by the user.

Security mitigations:
1. **Allowlist** (lines 50-53): Only `npm|npx|node|python|python3|pytest|vitest|jest|curl|grep|bash` prefixes allowed
2. **Metacharacter rejection** (line 56): Commands containing `;`, backticks, `$(`, `&&`, or `||` are rejected
3. **Limit** (line 35): Max 10 commands per phase (`head -10`)

These mitigations are adequate for the threat model (architect agent is trusted to produce safe verify commands). The metacharacter filter prevents injection even if PLAN_META.json is corrupted.

---

## Cross-Check Against Shield Runtime Behavior

### Shield Observations vs Audit Predictions

| Shield Observation | Audit Finding | Consistent? |
|-------------------|---------------|-------------|
| Shield Phase 7, 10/11 tasks complete | Framework pipeline supports this workflow | YES |
| Health check 10/10 PASS (2026-04-10) | All hooks and agents verified present and wired | YES |
| Orchestrator bypassed reflexion-retry on 07-10 | next.md:474-478 logs bypasses (AP-5 mitigated) | YES |
| STATE.json reconstructed from memory | DEEP-SO-001: STATE missing required fields at init. If crash mid-population, reconstruction needed | YES — PREDICTED |
| OneDrive write conflicts on .apex/ | DEEP-SF-002: pre-compact.sh backup uses advisory exit on failure | YES — PREDICTED |
| drift_indicators not observed as problem | DEEP-SF-001: re-pause loop requires ≥2 circuit breaker triggers in one session. Shield may not have hit this threshold | CONSISTENT (not contradicted) |

### Predictions That Shield Cannot Verify

These findings require specific conditions not observed on Shield:
- DEEP-DD-001 (verifier reads SUMMARY): Shield hasn't reached a phase boundary with Complexity > 2 where the verifier would be dispatched instead of the phase-level critic
- DEEP-DD-002 (status.md field names): Depends on how the orchestrator interprets "STATE.project_name" — it may auto-correct to "STATE.project" via inference
- DEEP-SF-005 (post-write JS bypass): Shield uses TypeScript, so the JS gap wouldn't surface

---

## Findings by Severity

### P0 — Critical (0 findings)

No P0 findings. The framework is not actively broken for any user running it normally.

---

### P1 — High (5 findings)

---

### DEEP-SO-001 — STATE.json is schema-invalid at creation time

**Severity:** P1 (High)
**Category:** State Drift / Schema Orphan
**Confidence:** HIGH
**File:** `framework/commands/apex/start.md`
**Lines:** 41-102

**Current state (verbatim quote from file):**
```
  ## STATE INITIALIZATION — fields are progressively populated by planner/architect stages.
  ## Also update STATE.schema.json, status.md, and test fixtures on changes.
  3. Create STATE.json with:
     apex_version: "v7"
     pre_build_complete: false
     lock: null
     created_at: now
     updated_at: now
     phases_total: 0
     ...
```
(Lines 41-102 — full init block. Notable absences: `project`, `complexity_level`, `complexity_name`, `pipeline`, `current_stage`, `current_phase`, `current_unit`, `current_wave`, `status`, `autonomy`)

**The problem:**
`STATE.schema.json` (lines 7-41) declares `additionalProperties: false` and lists 30+ fields as `required`, including `project`, `complexity_level`, `complexity_name`, `pipeline`, `current_stage`, `current_phase`, `current_unit`, `current_wave`, `status`, and `autonomy`. However, `start.md` creates STATE.json without any of these fields — they are "progressively populated" by the planner and architect stages in `/apex:next`. This means STATE.json is schema-invalid from the moment it's created until the architect completes its work, which could be multiple /apex:next invocations later.

The comment on line 41 acknowledges this: "fields are progressively populated by planner/architect stages." But the schema doesn't accommodate progressive population — it demands all fields immediately.

**Which failure mode does this expose:**
**Context Loss** — Any hook or command that reads STATE.json between /apex:start and architect completion will encounter missing fields. `validate-state.sh --strict` would reject the file. If a crash occurs mid-population, the STATE file is in an unrecoverable invalid state.

**Evidence of impact:**
A user running /apex:start then /apex:next then experiencing a crash before architect completes would find STATE.json missing `autonomy`, `current_phase`, `status`, etc. Resume would fail to read these fields. The Session Guardian (next.md:44) can initialize `session` if missing, but no guardian exists for `autonomy` or `current_stage`.

**How to reproduce:**
```bash
# Check what start.md creates vs what schema requires:
grep '"required"' framework/schemas/STATE.schema.json
# Count: 30+ required fields

# Check what start.md initializes:
grep -c ': ' framework/commands/apex/start.md | head -1
# Compare field names — ~10 required fields are missing from init
```

**Expected behavior:**
STATE.json should be schema-valid at creation. Either:
(a) start.md initializes all required fields with null/default values, or
(b) the schema uses `required` only for post-architect fields and has a separate "init-required" subset

**Recommended fix direction:**
Add default values for missing required fields in start.md: `project: null`, `complexity_level: 0`, `complexity_name: null`, `pipeline: []`, `current_stage: "init"`, `current_phase: null`, `current_unit: null`, `current_wave: null`, `status: "initializing"`, `autonomy: {by_verify_level: {A: {level:0, consecutive_successes:0}, B: {...}, C: {...}, D: {...}}}`. Requires design discussion on whether to split the schema or initialize defaults.

**Related to prior findings:** New finding.

**Verification notes:** Verified against current `start.md` lines 43-102 and `STATE.schema.json` lines 7-41. The test fixture `STATE-good.json` includes all fields, confirming the schema expects them all.

---

### DEEP-DD-001 — Verifier reads SUMMARY.md for test results instead of RESULT.json

**Severity:** P1 (High)
**Category:** Documentation Drift
**Confidence:** HIGH
**File:** `framework/agents/verifier.md`
**Lines:** 8, 24

**Current state (verbatim quote from file):**
```
Read .apex/phases/$PHASE/PLAN_META.json [שיפור 21] and all .apex/phases/$PHASE/*-SUMMARY.md files.
```
(Line 8)

```
D tasks need integration test RESULTS in *-SUMMARY.md | C tasks need behavioral test RESULTS
```
(Line 24)

**The problem:**
The verifier is instructed to read `*-SUMMARY.md` files for test results. But SUMMARY.md is explicitly designated as human-readable narrative only — it is NOT the source of truth for test data. The executor produces structured test results in `RESULT.json` (via `tests_run`, `verify_commands_run`, `done_criteria_checked`). The critic correctly reads from RESULT.json (critic.md:13). The verifier should too, but instead reads SUMMARY.md, which:
1. May contain phantom verification language (the very thing phantom-check guards against)
2. Is NOT consumed by the critic (clean-room protocol) — so the verifier is the only agent reading it
3. Has no structured format for test extraction

**Which failure mode does this expose:**
**Hallucination** — The verifier validates phase completion by reading human narrative files that may contain unverified claims, rather than structured machine-readable data. This is exactly the class of error the framework was designed to prevent.

**Evidence of impact:**
A user's executor writes SUMMARY.md with "Tests pass" (narrative) but RESULT.json has `"tests_run": []` (no tests actually ran). The critic catches this (reads RESULT.json). But the verifier, reading SUMMARY.md, sees "Tests pass" and may not cross-reference RESULT.json. Phase could be marked PASS at phase level despite per-task critic catches.

**How to reproduce:**
```bash
grep -n "SUMMARY" framework/agents/verifier.md
# Lines 8, 24, 27, 30 — all reference SUMMARY.md
grep -n "RESULT.json" framework/agents/verifier.md
# Zero results — RESULT.json not mentioned in verifier.md
```

**Expected behavior:**
Verifier should read `RESULT.json` files for structured test data and `PLAN_META.json` for criteria, consistent with how critic operates. SUMMARY.md should be secondary at most.

**Recommended fix direction:**
Replace `*-SUMMARY.md` references with `*-RESULT.json` in verifier.md lines 8 and 24. Add: "Read RESULT.json for structured test results. SUMMARY.md is supplementary narrative only."

**Related to prior findings:** New finding. Not covered in AUDIT-2026-04-09.md.

**Verification notes:** Verified against current verifier.md (62 lines). Cross-referenced with executor.md:127-159 (RESULT.json output spec) and critic.md:13 (reads RESULT.json).

---

### DEEP-DD-002 — status.md references nonexistent STATE.json field names

**Severity:** P1 (High)
**Category:** Documentation Drift
**Confidence:** HIGH
**File:** `framework/commands/apex/status.md`
**Lines:** 21, 23

**Current state (verbatim quote from file):**
```
  [PROJECT_NAME]         → STATE.project_name
  [project_name]         → STATE.project_name
  [N] · [level_name]     → STATE.complexity_level · STATE.level_name
```
(Lines 21-23)

**The problem:**
`status.md` references `STATE.project_name` and `STATE.level_name`. These fields do not exist in the STATE.json schema. The correct field names are:
- `STATE.project` (schema line 44: `"project": { "type": "string" }`)
- `STATE.complexity_name` (schema line 46: `"complexity_name": { "type": "string" }`)

Any orchestrator following status.md literally would attempt to read nonexistent fields, resulting in null/undefined values in the dashboard display.

**Which failure mode does this expose:**
**Drift** — The documentation has drifted from the actual schema, causing the orchestrator to reference wrong field paths.

**Evidence of impact:**
A user running /apex:status would see the project name and complexity name as blank/null in the cockpit dashboard, even though the data exists in STATE.json under the correct field names.

**How to reproduce:**
```bash
grep "project_name\|level_name" framework/commands/apex/status.md
# Lines 21-23: references STATE.project_name and STATE.level_name

grep "project_name\|level_name" framework/schemas/STATE.schema.json
# Zero results — these field names don't exist in the schema

grep '"project"\|"complexity_name"' framework/schemas/STATE.schema.json
# Lines 44, 46 — correct field names are "project" and "complexity_name"
```

**Expected behavior:**
`status.md` should reference `STATE.project` and `STATE.complexity_name`.

**Recommended fix direction:**
Line 21: Change `STATE.project_name` to `STATE.project`
Line 23: Change `STATE.level_name` to `STATE.complexity_name`

**Related to prior findings:** New finding.

**Verification notes:** Verified against current status.md lines 21-23 and STATE.schema.json lines 44, 46. The test fixture STATE-good.json uses `"project"` and `"complexity_name"` (lines 2-4), confirming the schema field names.

---

### DEEP-SF-001 — drift_indicators accumulate across sessions without reset, causing re-pause loops

**Severity:** P1 (High)
**Category:** Silent Failure
**Confidence:** HIGH
**File:** `framework/commands/apex/resume.md`
**Lines:** 33-38

**Current state (verbatim quote from file):**
```
  Update STATE.session:
    auto_paused = false
    auto_pause_reason = null
    consecutive_failures = 0
    consecutive_partials = 0
    health_status = "green"
```
(Lines 33-38)

**The problem:**
When /apex:resume runs auto-pause recovery (lines 33-38), it resets `consecutive_failures`, `consecutive_partials`, `health_status`, `auto_paused`, and `auto_pause_reason`. But it does NOT reset `drift_indicators` (`spec_drift_count`, `circuit_breaker_triggers`, `reflexion_total_attempts`, `low_confidence_results`).

The Session Health Check in next.md (lines 70-72) uses drift_indicators to determine health:
```
If session.drift_indicators.circuit_breaker_triggers >= 2: HEALTH = "red"
If session.drift_indicators.low_confidence_results >= 3: HEALTH = "yellow"
```

Since drift_indicators persist across resumes, a session that had 2 circuit breaker triggers will IMMEDIATELY trigger a "red" health status on the very next /apex:next after resume, causing another auto-pause. The user would experience an infinite pause-resume-pause loop.

**Which failure mode does this expose:**
**Failure** — The pipeline enters an irrecoverable loop where /apex:resume resets the pause flag but not the indicators that caused the pause, so the next /apex:next re-pauses immediately.

**Evidence of impact:**
A user whose session hit 2 circuit breaker triggers: auto-pause then /apex:resume then /apex:next, which reads drift_indicators.circuit_breaker_triggers = 2 then HEALTH = "red" then auto-pause again. The only escape is manually editing STATE.json.

**How to reproduce:**
```bash
# Check what resume.md resets:
grep -A 10 "Update STATE.session" framework/commands/apex/resume.md | head -10
# Lines 33-38: resets 5 fields. drift_indicators NOT among them.

# Check what next.md checks:
grep "drift_indicators" framework/commands/apex/next.md
# Lines 70, 71, 72: reads drift_indicators for health determination
```

**Expected behavior:**
/apex:resume should reset drift_indicators to zero (or at least the specific indicators that triggered the pause), alongside the other session counters.

**Recommended fix direction:**
Add to resume.md lines 33-38:
```
drift_indicators: {
  spec_drift_count: 0, circuit_breaker_triggers: 0,
  reflexion_total_attempts: 0, low_confidence_results: 0
}
```
Or alternatively, next.md's health check should compare drift_indicators against a baseline from the session start, not against absolute values.

**Related to prior findings:** New finding.

**Verification notes:** Verified against current resume.md lines 33-38 and next.md lines 70-72. The Shield project observed STATE reconstruction from memory (AP-4), which may have masked this issue by implicitly resetting indicators.

---

### DEEP-SF-002 — pre-compact.sh backup failure is advisory, allowing compaction after failed backup

**Severity:** P1 (High)
**Category:** Silent Failure
**Confidence:** HIGH
**File:** `framework/hooks/pre-compact.sh`
**Lines:** 38-41

**Current state (verbatim quote from file):**
```bash
  echo "⚠️ APEX: Backup incomplete $TIMESTAMP — some files could not be copied" >&2
fi

if [ "$BACKUP_OK" = true ]; then exit 0; else exit 1; fi
```
(Lines 38-41)

**The problem:**
`pre-compact.sh` is wired as a `PreCompact` hook in settings.json. When backup fails, it exits with code 1 (advisory). In the APEX hook convention:
- exit 0 = success
- exit 1 = advisory (non-blocking)
- exit 2 = blocking (halt execution)

Exit 1 means "continue with warning." This means compaction proceeds even when STATE.json backup failed. If compaction then corrupts or loses context, the backup that should enable recovery doesn't exist.

The hook correctly detects failure (line 14: `if ! cp ... 2>/dev/null`) and reports it (line 15: `echo "Failed to back up STATE.json" >&2`), but doesn't block compaction.

**Which failure mode does this expose:**
**Forgetting** — Context compaction destroys old context. If the pre-compaction backup failed, there's no recovery point. STATE.json from before compaction is lost.

**Evidence of impact:**
A user on a OneDrive-synced directory (known to cause write conflicts per Shield observations) where `cp` fails due to file locking: backup fails, compaction proceeds, context is lost, /apex:resume finds degraded state with no backup to restore from.

**How to reproduce:**
```bash
grep "exit" framework/hooks/pre-compact.sh
# Line 41: exit 1 on backup failure (advisory, non-blocking)

cat ~/.claude/settings.json | grep -A 5 "PreCompact"
# Confirms wiring: pre-compact.sh runs before compaction
```

**Expected behavior:**
Backup failure for STATE.json should exit 2 (blocking), preventing compaction without a safety net. PLAN.md backup failure could remain advisory (less critical).

**Recommended fix direction:**
Change the exit logic at line 41: if STATE.json backup specifically failed, exit 2. If only PLAN.md backup failed, exit 1. This requires tracking which backup failed independently. Alternatively, always exit 2 on any backup failure.

**Related to prior findings:** New finding.

**Verification notes:** Verified against current pre-compact.sh lines 10-41. The BACKUP_OK flag is set to false for BOTH STATE.json failure (line 16) and PLAN.md failure (line 26), but exit behavior doesn't distinguish between them.

---

### P2 — Medium (6 findings)

---

### DEEP-SO-002 — mutation_scores field defined in schema but never initialized

**Severity:** P2 (Medium)
**Category:** Schema Orphan
**Confidence:** HIGH
**File:** `framework/schemas/STATE.schema.json`
**Lines:** 333-336

**Current state (verbatim quote from file):**
```json
    "mutation_scores": {
      "type": "object",
      "additionalProperties": { "type": "number" }
    },
```
(Lines 333-336)

**The problem:**
`mutation_scores` is defined in the STATE.json schema properties (optional — not in `required` array) and is written by `mutation-gate.sh` (line 69: `'.mutation_scores[$task] = $score'`). However, `start.md` never initializes it, and mutation-gate.sh only runs for C/D verify-level tasks. Many projects will never populate this field. `status.md` (line 50) gracefully handles this with "N/A if no scores exist."

While not breaking, this represents an incomplete feature lifecycle: the schema declares it, the hook writes it, but the init doesn't seed it, and there's no mechanism to aggregate or display historical scores across phases.

**Which failure mode does this expose:**
**Quality Errors** — Mutation testing data is collected sporadically but never aggregated, so the framework can't track test quality trends over time as intended.

**Evidence of impact:**
A user running a Level 4 project with multiple D-level tasks would have per-task mutation scores scattered in STATE.json but no aggregation. The cockpit dashboard shows "N/A" until mutation-gate first runs, then shows only the most recent score.

**How to reproduce:**
```bash
grep "mutation_scores" framework/schemas/STATE.schema.json
# Line 333: defined in properties

grep "mutation_scores" framework/commands/apex/start.md
# Zero results — not initialized

grep "mutation_scores" framework/hooks/mutation-gate.sh
# Line 69: written per-task
```

**Expected behavior:**
Either initialize `mutation_scores: {}` in start.md, or document that this field is lazily populated by mutation-gate.sh. Status.md already handles the missing case gracefully.

**Recommended fix direction:**
Add `mutation_scores: {}` to start.md STATE initialization (after line 63, alongside snapshots).

**Related to prior findings:** New finding.

**Verification notes:** Verified against current files. The field is optional (not required), so this doesn't cause schema validation failure. Impact is limited to feature completeness.

---

### DEEP-SF-003 — No set -e in any hook; error propagation relies on explicit checks only

**Severity:** P2 (Medium)
**Category:** Silent Failure
**Confidence:** HIGH
**File:** All hooks in `framework/hooks/`
**Lines:** Line 1-2 of each hook

**Current state (verbatim quote from file):**
```bash
#!/bin/bash
set -u
```
(Standard opening of all hooks except _require-git.sh and _require-jq.sh)

**The problem:**
All 16 non-helper hooks use `set -u` (undefined variable protection) but none use `set -e` (exit on error) or `set -o pipefail` (pipeline error propagation). Only 2 hooks use `set -o pipefail`: `cross-phase-audit.sh` and `generate-task-map.sh` (which use `set -uo pipefail`).

Without `set -e`, a command that fails mid-hook doesn't stop execution — the hook continues with potentially stale or wrong data. The framework compensates with explicit `|| exit 2` patterns and `$?` checking, which is mostly adequate but fragile: any new code added to a hook without explicit error checking will silently fail.

**Which failure mode does this expose:**
**Silent Failure** — A failed command mid-hook doesn't stop execution; subsequent commands may operate on incorrect assumptions.

**Evidence of impact:**
In `circuit-breaker.sh`, if `md5sum` fails at line 26, `CURRENT_HASH` becomes empty, and the comparison at line 31 treats it as a no-change (empty != last_hash, so no issue). But a more subtle failure in a complex hook could propagate silently.

**How to reproduce:**
```bash
grep -l "set -e" framework/hooks/*.sh
# Zero results — no hook uses set -e

grep -l "set -u" framework/hooks/*.sh
# All main hooks have set -u

grep -l "set -uo pipefail" framework/hooks/*.sh
# Only cross-phase-audit.sh and generate-task-map.sh
```

**Expected behavior:**
Either `set -euo pipefail` should be the standard (with explicit `set +e` where needed), or the design decision to use explicit error handling should be documented. Currently it's neither enforced nor documented.

**Recommended fix direction:**
This is a design choice — `set -e` has known footguns (e.g., breaking `if` constructs). The recommendation is to document the explicit error handling convention in `DEV-FLOW.md`, and add `set -o pipefail` to all hooks that use pipelines.

**Related to prior findings:** New finding.

**Verification notes:** Verified by grepping all hooks. The explicit error handling pattern is consistently applied in critical hooks (phase-tag.sh, pre-task-snapshot.sh, subagent-stop.sh), but less consistently in advisory hooks.

---

### DEEP-SO-003 — comprehension_gates.current_gate_required initialized but never updated

**Severity:** P2 (Medium)
**Category:** Schema Orphan / Dead State
**Confidence:** HIGH
**File:** `framework/commands/apex/start.md` and `framework/commands/apex/next.md`
**Lines:** start.md:57, next.md:552-563

**Current state (verbatim quote from file):**
```
     comprehension_gates: {current_gate_required: null}
```
(start.md line 57)

```
  ## COMPREHENSION GATE
  LARGEST_DIFFS = top 3 changed files by diff size since phase start
  Render soft frame (Section 3.C) with:
    "▽  COMPREHENSION GATE — Phase [N]
     Largest changes: ...
     Does this match your understanding?   (y / explain / skip)"

  'y' → record, mark passed. 'explain' → user writes understanding, record (deep mode).
  'skip' → record, mark skipped. P2: "Cognitive debt risk." NOT available for verify_level D.
```
(next.md lines 552-563)

**The problem:**
`comprehension_gates.current_gate_required` is initialized to `null` in start.md and is defined in the schema (lines 100-106) with `additionalProperties: { "type": "boolean" }`. The comprehension gate UX exists in next.md (lines 552-563) — it shows the user top changed files and asks for understanding.

However, no code ever:
1. Updates `current_gate_required` from null to a value
2. Records the user's response ("y", "explain", "skip") into the STATE.json comprehension_gates object
3. Reads the recorded response for historical tracking

The UX exists but the state persistence doesn't.

**Which failure mode does this expose:**
**Forgetting** — The user's comprehension responses are not persisted to state, so they can't be tracked across sessions or used for cognitive debt analysis.

**Evidence of impact:**
A user who skips multiple comprehension gates accumulates "cognitive debt" per the framework's own terminology, but since skip responses aren't persisted, the framework can't track or warn about this accumulation.

**How to reproduce:**
```bash
grep "comprehension_gates" framework/commands/apex/start.md
# Line 57: initialized to null

grep -n "comprehension_gates" framework/commands/apex/next.md
# Only referenced in UX display, no STATE update

grep "comprehension_gates" framework/hooks/*.sh
# Zero results — no hook reads or writes this field
```

**Expected behavior:**
next.md's comprehension gate (lines 552-563) should persist the user's response to STATE.json, e.g.: `STATE.comprehension_gates["phase_01"] = true/false`.

**Recommended fix direction:**
After the comprehension gate prompt in next.md, add STATE update: `STATE.comprehension_gates[current_phase] = (response == "y" || response == "explain")`. Update `current_gate_required` based on next phase's verify_level.

**Related to prior findings:** New finding.

**Verification notes:** Verified against current start.md, next.md, and STATE.schema.json. The schema supports per-phase boolean tracking via `additionalProperties: boolean`, but no code uses this capability.

---

### DEEP-DD-003 — health-check.md doesn't test 3 of 4 specialist agents

**Severity:** P2 (Medium)
**Category:** Documentation Drift / Quality Errors
**Confidence:** MEDIUM
**File:** `framework/commands/apex/health-check.md`
**Lines:** 97-176

**Current state (verbatim quote from file):**
The test suite defines tests 0-9. Test 8 specifically tests `security-specialist` for SQL injection detection.

**The problem:**
Health-check.md includes 10 tests (0-9). Test 8 specifically tests `security-specialist` for SQL injection detection. However, the other 3 specialist agents are not individually tested:
- `integration-specialist` — no dedicated test
- `data-specialist` — no dedicated test
- `frontend-specialist` — no dedicated test

The model routing table (`apex-model-routing.json`) includes all 4 specialists, and all are dispatched from next.md. But health-check only validates that security-specialist works correctly under adversarial input.

**Which failure mode does this expose:**
**Quality Errors** — Specialist agents could silently produce incorrect output (e.g., data-specialist ignoring RLS, frontend-specialist missing accessibility) without being caught by the health check.

**Evidence of impact:**
A user whose environment has a corrupt or misconfigured specialist agent file would pass health-check (all 10 tests pass) but encounter failures when /apex:next dispatches to that specialist.

**How to reproduce:**
```bash
grep -i "specialist" framework/commands/apex/health-check.md
# Only security-specialist appears in test definitions
```

**Expected behavior:**
Each specialist should have at least one poison-pill test (e.g., data-specialist should detect missing RLS, frontend-specialist should detect missing alt text).

**Recommended fix direction:**
Add tests 10-12 for integration/data/frontend specialists. Requires design discussion on what each specialist's "poison pill" scenario should be.

**Related to prior findings:** New finding.

**Verification notes:** Verified against current health-check.md. Only security-specialist is tested. Confidence is MEDIUM because the existing tests do validate the agent dispatch mechanism generally — the gap is in specialist-specific behavior validation.

---

### DEEP-SF-004 — verify-learnings.sh always exits 0 regardless of findings

**Severity:** P2 (Medium)
**Category:** Silent Failure
**Confidence:** HIGH
**File:** `framework/hooks/verify-learnings.sh`
**Lines:** 112

**Current state (verbatim quote from file):**
```bash
exit 0
```
(Line 112 — final line of the script)

**The problem:**
`verify-learnings.sh` checks for stale citations and decayed entries in `apex-learnings.md`. When it finds issues (lines 95-101: HOT tier over capacity, WARM tier over capacity; lines 105-107: stale citations, decayed entries), it prints warnings to stdout — but ALWAYS exits 0.

As a SessionStart hook, exit 0 means "all clear." The hook reports problems but never blocks or even provides an advisory exit code. This means:
1. Stale citations (pointing to deleted files) persist indefinitely
2. HOT tier overflow (>30 entries) is warned but never enforced
3. Decayed entries past their max_days threshold are warned but never demoted

**Which failure mode does this expose:**
**Forgetting** — The learning accumulator is the framework's long-term memory. Stale citations and decayed entries degrade its value over time, but the hook designed to catch this never escalates.

**Evidence of impact:**
A user whose apex-learnings.md has 45 HOT entries (15 over the 30 max) would see "HOT tier over capacity: 45 entries (max: 30)" on every session start, but nothing would enforce the ceiling. The HOT tier would grow unbounded.

**How to reproduce:**
```bash
grep "exit" framework/hooks/verify-learnings.sh
# Line 16: exit 0 (no learnings file)
# Line 112: exit 0 (always, regardless of findings)
# No exit 1 or exit 2 anywhere in the file
```

**Expected behavior:**
At minimum, exit 1 (advisory) when issues are found, so the orchestrator can log the degraded state. HOT tier overflow could warrant exit 2 (blocking) to force curation.

**Recommended fix direction:**
Change line 112: if `$ISSUES -gt 0`, exit 1. If HOT_COUNT > 30 (hard ceiling per spec), consider exit 2. This would align with the 3-tier exit code convention used by all other hooks.

**Related to prior findings:** New finding.

**Verification notes:** Verified against current verify-learnings.sh. The hook correctly detects all issue types but unconditionally exits 0. The SessionStart event context may justify advisory-only behavior (blocking session start is aggressive), but the current exit 0 makes the hook's checks purely cosmetic.

---

### DEEP-DD-004 — status.md uses "consecutive wins" but STATE field is "consecutive_successes"

**Severity:** P2 (Medium)
**Category:** Documentation Drift
**Confidence:** HIGH
**File:** `framework/commands/apex/status.md`
**Lines:** 34

**Current state (verbatim quote from file):**
```
    consecutive wins from STATE.autonomy.by_verify_level
```
(Line 34)

**The problem:**
`status.md` line 34 references "consecutive wins" when the actual STATE.json field name is `consecutive_successes` (STATE.schema.json line 352: `"consecutive_successes": { "type": "integer", "minimum": 0 }`). An orchestrator following status.md literally would try to read a field called "wins" that doesn't exist.

**Which failure mode does this expose:**
**Drift** — Naming mismatch between documentation and schema.

**Evidence of impact:**
A literal interpretation would result in the autonomy ladder display in the cockpit dashboard showing null/undefined for the consecutive count column.

**How to reproduce:**
```bash
grep "consecutive" framework/commands/apex/status.md
# Line 34: "consecutive wins"

grep "consecutive" framework/schemas/STATE.schema.json
# Line 352: "consecutive_successes"
```

**Expected behavior:**
status.md should say "consecutive_successes from STATE.autonomy.by_verify_level".

**Recommended fix direction:**
Change "consecutive wins" to "consecutive_successes" on line 34.

**Related to prior findings:** New finding.

**Verification notes:** Verified against current status.md line 34 and STATE.schema.json line 352.

---

### P3 — Low (5 findings)

---

### DEEP-SO-004 — D-level autonomy cap makes consecutive_successes tracking pointless

**Severity:** P3 (Low)
**Category:** State Drift / Dead State
**Confidence:** HIGH
**File:** `framework/commands/apex/next.md`
**Lines:** 259, 378-380

**Current state (verbatim quote from file):**
```
EFFECTIVE_LEVEL = min(TASK_AUTONOMY.level, cap) where caps: A→2, B→2, C→1, D→0
```
(Line 259)

```
  STATE.autonomy.by_verify_level[verify_level].consecutive_successes++
  If consecutive_successes >= 5: level++ (up to cap), reset counter.
```
(Lines 378-380)

**The problem:**
D-level tasks have an autonomy cap of 0 (line 259). This means the effective autonomy level for D tasks is always 0, regardless of how many consecutive successes accumulate. Yet the framework still:
1. Increments `consecutive_successes` on D-task PASS (line 378)
2. Checks if `consecutive_successes >= 5` to level up (line 379)
3. Levels up to `level: 1` but caps at `EFFECTIVE_LEVEL = min(1, 0) = 0`

The consecutive_successes counter for D-level is tracked but has no effect. This is dead state — it consumes storage and processing but never changes behavior.

**Which failure mode does this expose:**
Minor **Context Loss** — Dead state fields occupy space in STATE.json and could mislead a developer reading the state.

**Evidence of impact:**
Cosmetic only. No user impact. A developer reading STATE.json might think D-level autonomy can escalate when it can't.

**How to reproduce:**
```bash
grep "caps:" framework/commands/apex/next.md
# Line 259: D→0 (cap)

grep "consecutive_successes" framework/commands/apex/next.md
# Lines 378-380: incremented for ALL verify levels including D
```

**Expected behavior:**
Either skip consecutive_successes tracking for D-level, or document that D-level never escalates by design.

**Recommended fix direction:**
Add a comment: "D-level autonomy is permanently capped at 0 — consecutive_successes is tracked for telemetry only."

**Related to prior findings:** New finding.

**Verification notes:** Verified against next.md lines 259, 378-380. This is by design (security principle: D-level tasks always require human approval), but the dead tracking is cosmetic waste.

---

### DEEP-SO-005 — CONTEXT_BUDGET.json defaults not specified in framework

**Severity:** P3 (Low)
**Category:** Schema Orphan
**Confidence:** MEDIUM
**File:** `framework/commands/apex/start.md`
**Lines:** 103

**Current state (verbatim quote from file):**
```
  4. Create .apex/CONTEXT_BUDGET.json with default budgets (copy from ~/.claude reference or use v7 defaults)
```
(Line 103)

**The problem:**
start.md instructs the orchestrator to "copy from ~/.claude reference or use v7 defaults" but no default CONTEXT_BUDGET.json file exists in `framework/` or `~/.claude/`. The schema (`CONTEXT_BUDGET.schema.json`) defines the structure but doesn't provide defaults. Hooks that read CONTEXT_BUDGET.json use fallback values (e.g., context-monitor.sh lines 19-20: `// 55` and `// 70`), so the system degrades gracefully.

**Which failure mode does this expose:**
Minor **Context Loss** — Without a CONTEXT_BUDGET.json, per-agent limits aren't enforced, and the orchestrator can't implement the reduction priority chain (next.md line 241).

**Evidence of impact:**
A user starting a new project would have no CONTEXT_BUDGET.json. context-monitor.sh falls back to 55%/70% thresholds. next.md's context reduction priority (line 241) has no file to read. The framework works but without budget governance.

**How to reproduce:**
```bash
find framework/ -name "CONTEXT_BUDGET*" -not -name "*.schema*"
# Zero results — no default file exists

grep "CONTEXT_BUDGET" framework/commands/apex/start.md
# Line 103: "copy from ~/.claude reference or use v7 defaults"

ls ~/.claude/CONTEXT_BUDGET* 2>/dev/null
# No default deployed either
```

**Expected behavior:**
A `CONTEXT_BUDGET.default.json` file in `framework/` that start.md can copy, or explicit defaults inlined in start.md.

**Recommended fix direction:**
Create `framework/CONTEXT_BUDGET.default.json` with v7 defaults (capacity: 200000, zones, thresholds: 55/70/75, per-agent limits). Reference this from start.md.

**Related to prior findings:** New finding.

**Verification notes:** Verified. The fallback values in context-monitor.sh provide adequate safety net, reducing severity. Confidence is MEDIUM because we can't determine if the orchestrator generates a reasonable default from the schema alone.

---

### DEEP-DD-005 — phantom-check.sh falls through to exit 0 when no SUMMARY file exists

**Severity:** P3 (Low)
**Category:** Documentation Drift
**Confidence:** HIGH
**File:** `framework/hooks/phantom-check.sh`
**Lines:** 8-10

**Current state (verbatim quote from file):**
```bash
if [ -z "$SUMMARY_FILE" ] || [ ! -f "$SUMMARY_FILE" ]; then
  echo "✅ PHANTOM CHECK: No summary file to check"
  exit 0
fi
```
(Lines 8-10)

**The problem:**
When no SUMMARY.md file exists (or the `find` on line 6 returns nothing), phantom-check.sh exits 0 with a success message. But next.md line 325-327 expects exit 1 for this case:
```
Else if PHANTOM_EXIT == 1:
  # Advisory: phantom hook couldn't find SUMMARY.md file.
```

The hook exits 0 (success), but the orchestrator expects exit 1 (advisory). This means the "advisory warning" path in next.md is unreachable for missing SUMMARY files — it silently succeeds instead.

**Which failure mode does this expose:**
**Hallucination** — A missing SUMMARY.md (which could indicate the executor didn't produce one) is treated as "check passed" rather than "couldn't verify."

**Evidence of impact:**
If an executor crashes before writing SUMMARY.md, phantom-check says "No summary file to check" and exits 0. The pipeline proceeds to critic without any warning that the executor's narrative output is missing.

**How to reproduce:**
```bash
grep "exit" framework/hooks/phantom-check.sh
# Line 10: exit 0 when no file found
# Line 26: exit 2 when phantom language detected
# Line 30: exit 0 when clean

grep "PHANTOM_EXIT == 1" framework/commands/apex/next.md
# Line 325: expects exit 1 for missing file case
```

**Expected behavior:**
phantom-check.sh should exit 1 (advisory) when SUMMARY.md doesn't exist, matching next.md's expectation.

**Recommended fix direction:**
Change line 10 from `exit 0` to `exit 1`, and update the message from "check passed" to "warning: no summary file found".

**Related to prior findings:** New finding.

**Verification notes:** Verified against current phantom-check.sh lines 8-10 and next.md lines 325-328. The impact is mitigated because the critic independently validates test results from RESULT.json, but the missing advisory warning is a gap.

---

### DEEP-AP-001 — context-monitor.sh capacity_tokens field not in CONTEXT_BUDGET schema

**Severity:** P3 (Low)
**Category:** Anti-Pattern Instance (AP-4: Schema-by-Memory)
**Confidence:** MEDIUM
**File:** `framework/hooks/context-monitor.sh`
**Lines:** 27

**Current state (verbatim quote from file):**
```bash
EFFECTIVE_CAPACITY=$(jq -r '.capacity_tokens // 200000' "$BUDGET_FILE" 2>/dev/null || echo 200000)
```
(Line 27)

**The problem:**
context-monitor.sh reads `.capacity_tokens` from CONTEXT_BUDGET.json. But the CONTEXT_BUDGET schema doesn't define a top-level `capacity_tokens` field. The schema (CONTEXT_BUDGET.schema.json) defines `zones`, `thresholds`, `rotation_triggers`, `per_agent_limits`, and `context_reduction_priority` — but not `capacity_tokens`.

The fallback `// 200000` means this works even if the field is absent, but the code assumes a schema structure that the schema doesn't define.

**Which failure mode does this expose:**
**Drift** — The code and schema disagree about CONTEXT_BUDGET.json's structure.

**Evidence of impact:**
The 200000 default always applies since no CONTEXT_BUDGET.json default file exists (see DEEP-SO-005). Impact is minimal due to the fallback, but if someone creates CONTEXT_BUDGET.json from the schema, they won't include `capacity_tokens`.

**How to reproduce:**
```bash
grep "capacity_tokens" framework/schemas/CONTEXT_BUDGET.schema.json
# Zero results — field not in schema

grep "capacity_tokens" framework/hooks/context-monitor.sh
# Line 27: reads from CONTEXT_BUDGET.json
```

**Expected behavior:**
Either add `capacity_tokens` to the CONTEXT_BUDGET schema, or compute capacity from existing schema fields (e.g., sum of zones).

**Recommended fix direction:**
Add `capacity_tokens` to CONTEXT_BUDGET.schema.json as a required integer field, or derive it from zone allocations.

**Related to prior findings:** New finding. Instance of AP-4 (Schema-by-Memory).

**Verification notes:** Verified against current context-monitor.sh line 27 and CONTEXT_BUDGET.schema.json. Confidence is MEDIUM because the schema may have been designed to derive capacity from zones rather than store it explicitly.

---

### DEEP-SF-005 — post-write.sh only validates TypeScript files, bypassing JavaScript entirely

**Severity:** P3 (Low)
**Category:** Silent Failure
**Confidence:** HIGH
**File:** `framework/hooks/post-write.sh`
**Lines:** 5

**Current state (verbatim quote from file):**
```bash
if [[ "$FILE" == *.ts ]] || [[ "$FILE" == *.tsx ]]; then
```
(Line 5)

**The problem:**
`post-write.sh` is wired as a PostToolUse[Write|Edit] hook — it runs after every file write/edit. Its two blocking checks (TypeScript compilation errors at line 8, hardcoded secret detection at line 18) and two advisory checks (tenant isolation at line 24, silent catch at line 30) are all inside the `if [[ "$FILE" == *.ts ]] || [[ "$FILE" == *.tsx ]]` guard.

This means `.js`, `.jsx`, `.py`, `.sql`, `.env`, and all other file types completely bypass ALL checks. A hardcoded secret in a `.js` file would not be detected. A silent catch in a `.jsx` component would pass through.

**Which failure mode does this expose:**
**Quality Errors** and **Mutation** — Secrets and code quality issues in non-TypeScript files are invisible to the hook system.

**Evidence of impact:**
A user whose project uses `.js` files (or mixed JS/TS) would have zero post-write protection for JavaScript files. An executor could commit a hardcoded API key in `config.js` without the hook triggering.

**How to reproduce:**
```bash
grep "\.ts\|\.tsx\|\.js\|\.jsx" framework/hooks/post-write.sh
# Line 5: only checks *.ts and *.tsx
# Zero matches for .js or .jsx
```

**Expected behavior:**
Secret detection (line 18) should apply to ALL source files (`.ts`, `.tsx`, `.js`, `.jsx`, `.py`). TypeScript compilation check should remain TS-only. Tenant isolation and silent catch checks should extend to `.js`/`.jsx`.

**Recommended fix direction:**
Restructure post-write.sh: move secret detection outside the TS guard into a separate block matching common source extensions. Keep `npx tsc` inside the TS guard.

**Related to prior findings:** New finding.

**Verification notes:** Verified against current post-write.sh lines 1-36. The entire file's logic is gated on line 5's TS check.

---

### DEEP-SF-006 — validate-state.sh does not support $ref resolution

**Severity:** P3 (Low)
**Category:** Silent Failure
**Confidence:** HIGH
**File:** `framework/scripts/validate-state.sh`
**Lines:** 4

**Current state (verbatim quote from file):**
```bash
# Does NOT support: $ref resolution, allOf/anyOf/oneOf, complex regex, format.
```
(Line 4)

**The problem:**
The framework's own JSON Schema validator explicitly states it does not resolve `$ref` references. However, STATE.schema.json uses `$ref` for the autonomy field structure:
```json
"A": { "$ref": "#/definitions/autonomy_level" },
"B": { "$ref": "#/definitions/autonomy_level" },
```
(STATE.schema.json lines 76-79)

This means the autonomy field's internal structure (level, consecutive_successes) is never validated by validate-state.sh. An executor could write `autonomy.by_verify_level.A = "garbage"` and the validator would not catch it.

**Which failure mode does this expose:**
**Quality Errors** — Schema validation has a blind spot for `$ref`-dependent fields.

**Evidence of impact:**
Limited — the autonomy field is only written by next.md (lines 155-158, 378, 447, 468, 471) which uses correct structure. But if STATE.json is manually edited or reconstructed from memory (AP-4), malformed autonomy data would pass validation.

**How to reproduce:**
```bash
grep '\$ref' framework/schemas/STATE.schema.json
# Lines 76-79: $ref for autonomy_level

head -5 framework/scripts/validate-state.sh
# Line 4: "Does NOT support: $ref resolution"
```

**Expected behavior:**
Either inline the autonomy_level definition (removing `$ref`), or document that autonomy fields are not validated.

**Recommended fix direction:**
Inline the `autonomy_level` definition in STATE.schema.json, replacing `$ref` with the actual type definition. This makes the schema self-contained for the jq-based validator.

**Related to prior findings:** New finding.

**Verification notes:** Verified against validate-state.sh line 4 and STATE.schema.json lines 76-79, 345-354.

---

### DEEP-DD-007 — quick.md uses 2-attempt max while next.md uses 3-attempt max for reflexion

**Severity:** P3 (Low)
**Category:** Documentation Drift
**Confidence:** HIGH
**File:** `framework/commands/apex/quick.md`
**Lines:** 52-53

**Current state (verbatim quote from file):**
```
    If STATE.reflexion.current_unit_attempts < 2:
      "🔄 Quick task reflexion. Retrying (attempt ${STATE.reflexion.current_unit_attempts}/2)..."
```
(quick.md lines 52-53)

Compared to next.md:
```
     reflexion: {current_unit_attempts: 0, max_attempts: 3, last_reflexion_summary: null}
```
(start.md line 55, referenced by next.md line 464: `If ATTEMPTS >= 3`)

**The problem:**
`/apex:quick` allows only 2 reflexion attempts (line 52), while `/apex:next` allows 3 (STATE.reflexion.max_attempts = 3, next.md line 464). This asymmetry is not documented or explained. Both commands share the same STATE.reflexion.current_unit_attempts counter.

If a user starts a task with /apex:quick (2 attempts max) and it fails twice, then switches to /apex:next for the same task, next.md would see current_unit_attempts = 2, which is less than 3, and would allow a 3rd attempt. This is functional but confusing — the attempt limits differ based on which command you use.

**Which failure mode does this expose:**
Minor **Drift** — Inconsistent retry semantics between commands using shared state.

**Evidence of impact:**
Behavioral inconsistency only. A user might expect the same retry behavior across commands.

**How to reproduce:**
```bash
grep "attempts.*2\|< 2" framework/commands/apex/quick.md
# Line 52: < 2 (2 attempts max)

grep "max_attempts\|>= 3" framework/commands/apex/next.md
# Line 464: >= 3 (3 attempts max)
```

**Expected behavior:**
Either both commands use the same max_attempts from STATE.reflexion.max_attempts, or the difference is documented with rationale (e.g., "quick tasks get fewer retries because they're expected to be simpler").

**Recommended fix direction:**
Document the asymmetry or change quick.md to read STATE.reflexion.max_attempts instead of hardcoding 2.

**Related to prior findings:** New finding.

**Verification notes:** Verified against quick.md line 52 and next.md line 464. The hardcoded 2 in quick.md does not reference STATE.reflexion.max_attempts.

---

### DEEP-DD-006 — session-log.sh logs "resume" event for new project start

**Severity:** P3 (Low)
**Category:** Documentation Drift / Misleading Name
**Confidence:** HIGH
**File:** `framework/commands/apex/start.md`
**Lines:** 104

**Current state (verbatim quote from file):**
```
  5. bash ~/.claude/hooks/session-log.sh "resume" "סשן התחיל — [project name]"
```
(Line 104)

**The problem:**
When starting a brand-new project with /apex:start, the session log event is recorded as "resume" (which renders with a play icon per session-log.sh line 45). This is misleading — it's a START, not a RESUME. The Session Log's first entry for a new project says "resume" which confuses the timeline.

**Which failure mode does this expose:**
Minor **Drift** — The session log doesn't accurately reflect what happened.

**Evidence of impact:**
Cosmetic only. A user reading SESSION-LOG.md for a new project would see a "resume" event as the first entry, which looks like a resume rather than a fresh start.

**How to reproduce:**
```bash
grep 'session-log.sh.*"resume"' framework/commands/apex/start.md
# Line 104: logs "resume" event for a new project start

grep '"start"' framework/hooks/session-log.sh
# Zero results — no "start" event type defined
```

**Expected behavior:**
Use a "start" event type, and add it to session-log.sh's icon map. Or change to "init" with a distinct icon.

**Recommended fix direction:**
Add `start) ICON="🚀" ;;` to session-log.sh's case statement, and change start.md line 104 to use `"start"` instead of `"resume"`.

**Related to prior findings:** New finding.

**Verification notes:** Verified against current start.md line 104 and session-log.sh lines 34-48. The icon map has no "start" type.

---

## Findings by Category

| Category | Finding IDs |
|----------|-------------|
| Dead Code | (none found) |
| Silent Failure | DEEP-SF-001, DEEP-SF-002, DEEP-SF-003, DEEP-SF-004, DEEP-SF-005, DEEP-SF-006 |
| Documentation Drift | DEEP-DD-001, DEEP-DD-002, DEEP-DD-003, DEEP-DD-004, DEEP-DD-005, DEEP-DD-006, DEEP-DD-007 |
| Environment Gap | (none found) |
| Pipeline Bypass | (none found) |
| Schema Orphan / State Drift | DEEP-SO-001, DEEP-SO-002, DEEP-SO-003, DEEP-SO-004, DEEP-SO-005 |
| Misleading Name | DEEP-DD-006 |
| Anti-Pattern Instance | DEEP-AP-001 |
| Regression | (none — all 12 known-fixed items confirmed) |

---

## Anti-Pattern Instances

### AP-1: Silent Install Failure
**Status:** Not found in current codebase. All tool uses have guards or graceful fallbacks.

### AP-2: Pattern-Echo Hallucination
**Status:** This auditor's own sub-agents generated 6 false findings (see "Auditor's Self-Critique"). The framework code itself does not exhibit this pattern.

### AP-3: Implicit Write Chain
**Status:** One instance found. `mutation-gate.sh` writes `mutation_scores` to STATE.json (line 69), which `status.md` reads (line 50). The dependency is implicit — no documented chain ensures mutation-gate runs before status reads. However, status.md handles the missing case ("N/A if no scores exist"), so this is gracefully degraded rather than broken.

### AP-4: Schema-by-Memory
**Status:** One instance found: **DEEP-AP-001** — context-monitor.sh reads `capacity_tokens` from CONTEXT_BUDGET.json, but this field isn't in the schema. The code constructs its expectation from memory rather than from the schema definition.

### AP-5: Pipeline Bypass
**Status:** Properly mitigated. next.md lines 474-478 explicitly log pipeline bypasses:
```
If orchestrator_applied_direct_fix (you wrote code instead of dispatching executor):
  bash ~/.claude/hooks/session-log.sh "bypass" "pipeline-bypass: direct fix for ${NEXT_UNIT}..."
```
This is consistent with Shield project observations where orchestrator bypassed reflexion-retry (logged as expected).

### AP-6: Unchecked Audit
**Status:** Not found. No code references prior audits as authoritative. The critic actively distrusts cached data (critic.md line 25: "Executor may write RESULT.json in good faith with stale or fabricated data").

### NEW: AP-7 Candidate — Progressive Schema Violation

**Pattern name:** Progressive Schema Violation
**Shape:** A schema defines strict requirements (`additionalProperties: false` + all `required`), but the code creates the data file incrementally, with fields populated by different stages over time. The file is schema-invalid at creation and may remain invalid if any stage crashes mid-population.

**Instances:** DEEP-SO-001 (STATE.json created by start.md is missing 10+ required fields that are populated by planner/architect/next.md stages).

**Why it matters:** Progressive population is natural for complex state, but strict schemas assume atomic creation. If the schema enforces strict mode and the validator runs between stages, it will reject valid in-progress state.

**Recommended mitigation:** Either relax the schema (separate `init-required` from `full-required`), or ensure all fields are initialized with defaults at creation time.

---

## Regressions Detected

**ZERO regressions.** All 12 previously-closed findings verified as still fixed:

| ID | Fix Description | Verification | Status |
|----|----------------|--------------|--------|
| F-1 | v7 everywhere | `start.md:44 apex_version: "v7"`, `apex-model-routing.json:2 "v7 Model Routing"` | FIXED |
| A-1 | 9 agents in routing | `apex-model-routing.json`: 5 core + 4 specialists by exact name | FIXED |
| A-9 | Branding consistency | Branding sections referenced consistently across commands | FIXED |
| B-4 | subagent-stop 3-way exit | `subagent-stop.sh:16 exit 2`, `line 30 exit 1`, `line 41 exit 0` | FIXED |
| C-3 | phantom-check in next.md | `next.md:291 bash ~/.claude/hooks/phantom-check.sh` | FIXED |
| C-14 | critic phantom-scan scope | `critic.md:54-60`: explicit scope boundaries, SUMMARY.md excluded | FIXED |
| B-1 | phase-tag filesystem verify | `phase-tag.sh:28 git tag -l ... grep -qF` (double-check after creation) | FIXED |
| C-2 | quick.md pre-task-snapshot | `quick.md:31 bash ~/.claude/hooks/pre-task-snapshot.sh` | FIXED |
| A-5 | previous_* fields | `start.md:80,83`: initializes both previous_ fields. `resume.md:75,82,135-136`: reads and updates them. | FIXED |
| E-6 | specialists via subdirectory | `framework/agents/specialist/` contains data.md, frontend.md, integration.md, security.md | FIXED |
| - | verify-ladder-check.sh deleted | `find framework -name "verify-ladder*"` returns nothing | FIXED |
| - | researcher.md deleted | `find framework -name "researcher*"` returns nothing | FIXED |

---

## Cross-Reference to Prior Audit

The prior audit (`AUDIT-2026-04-09.md`) identified findings across categories A through E. Round 3.0-3.2 closed 12 specific items. This audit's findings are all **new** — none overlap with the 12 closed items.

**Agreements with prior audit:**
- The hook infrastructure is well-designed (3-tier exit codes, filesystem verification)
- The clean-room critic protocol is correctly implemented
- The model routing is consistent across routing.json, next.md, and health-check.md

**Disagreements with prior audit:**
- Prior audit Round 3.1 reportedly claimed critic and verifier were missing from routing. This audit confirms they are present (`apex-model-routing.json` lines 22-27: critic and verifier both defined with "default": "sonnet"). This supports the user's observation that the prior audit had false positives.

**New findings not in prior audit:**
- DEEP-SO-001 (schema-invalid STATE at creation): Not previously identified
- DEEP-DD-001 (verifier reads SUMMARY.md): Not previously identified
- DEEP-DD-002 (status.md field name drift): Not previously identified
- DEEP-SF-001 (drift_indicators never reset): Not previously identified
- DEEP-SF-002 (pre-compact advisory on backup failure): Not previously identified

---

## Confidence Summary

| Confidence | Count | Findings |
|------------|-------|----------|
| HIGH | 17 | DEEP-SO-001, DEEP-DD-001, DEEP-DD-002, DEEP-SF-001, DEEP-SF-002, DEEP-SO-003, DEEP-SF-003, DEEP-SF-004, DEEP-DD-004, DEEP-SO-004, DEEP-DD-005, DEEP-DD-006, DEEP-DD-007, DEEP-SO-002, DEEP-SF-005, DEEP-SF-006, DEEP-AP-001 |
| MEDIUM | 2 | DEEP-DD-003, DEEP-SO-005 |
| LOW | 0 | — |

Note: DEEP-AP-001 rated MEDIUM confidence in the finding itself (schema may intentionally not include capacity_tokens).

**Runtime verification needed for:**
- DEEP-SF-001: Confirm that drift_indicators actually cause re-pause in practice (verified from code; runtime test would confirm)
- DEEP-DD-003: Confirm whether specialist agents actually fail differently from executor (may be adequately covered by generic agent tests)
- DEEP-SO-005: Confirm whether orchestrator generates a reasonable CONTEXT_BUDGET.json from the schema alone

---

## Auditor's Self-Critique

### Limitation 1: Pattern-Echo Hallucination from Sub-Agents
This audit used 6 parallel exploration agents for initial research. These agents generated **6 false findings** that the primary auditor caught by reading actual files:

1. Agents claimed `trigger_reason` was undeclared in STATE.schema.json — **FALSE** (it's at line 190 in required, line 199 in properties)
2. Agents claimed `pending_notifications` was undeclared — **FALSE** (line 178)
3. Agents claimed `tokens.productive` was undeclared — **FALSE** (line 161, 171)
4. Agents claimed `verify-learnings.sh` lacked `set -u` — **FALSE** (line 2: `set -u`)
5. Agents claimed `tdad-index.sh` exits 0 on missing python3 — **FALSE** (line 15: `exit 1`)
6. Agents claimed `pre-compact.sh` always exits 0 — **FALSE** (line 41: `exit 1` on failure)

Every finding in this report was independently verified by reading the current file. However, the auditor cannot guarantee that NO agent false positive leaked through. The Pattern-Echo risk is real and was actively realized during this audit.

### Limitation 2: No Runtime Execution
No hooks were executed at runtime. All findings are based on static code analysis. Some findings (particularly DEEP-SF-001 re-pause loop, DEEP-DD-005 phantom-check exit code mismatch) would benefit from end-to-end runtime testing.

### Limitation 3: Branding File Not Audited Line-by-Line
`apex-branding.md` (1176 lines) is the largest file in the framework. This audit verified that commands reference branding sections by number and that the branding file exists, but did not audit every section template for correctness. Branding drift (e.g., a section number changing without updating command references) could exist undetected.

### Limitation 4: Stack Skills Not Deep-Audited
The 10 stack skill files (`framework/apex-skills/`) were inventoried but not audited for technical accuracy of their patterns and anti-patterns. An incorrect pattern in `postgres.md` or `react.md` could propagate to executor context and affect code quality.

### Limitation 5: Test Suite Not Executed
`framework/tests/` contains 8 test files with a harness. These were inventoried but not executed. The tests themselves could have gaps that this audit doesn't detect.

### Limitation 6: Single-Pass Methodology
The engagement rules specify "do not re-run the audit." Some early findings may have influenced later analysis (anchoring bias). The auditor attempted to mitigate this by verifying every finding against current file content, but cognitive bias cannot be fully eliminated.

---

## Recommended Next Steps

**Priority order by impact and effort:**

1. **DEEP-SO-001 (P1, Low effort):** Add default values for all required fields in start.md STATE initialization. This is the highest-impact fix because it affects every new project.

2. **DEEP-SF-001 (P1, Low effort):** Add drift_indicators reset to resume.md lines 33-38. Without this, users can get stuck in pause-resume loops.

3. **DEEP-DD-002 (P1, Trivial):** Fix field names in status.md: `project_name` to `project`, `level_name` to `complexity_name`.

4. **DEEP-DD-001 (P1, Low effort):** Change verifier.md to read RESULT.json instead of SUMMARY.md. Cross-reference with next.md's verifier invocation.

5. **DEEP-SF-002 (P1, Low effort):** Change pre-compact.sh to exit 2 when STATE.json backup specifically fails.

6. **DEEP-DD-005 (P3, Trivial):** Change phantom-check.sh exit 0 to exit 1 for missing file case.

7. **DEEP-DD-004 (P2, Trivial):** Fix "consecutive wins" to "consecutive_successes" in status.md.

8. **DEEP-SF-004 (P2, Low effort):** Change verify-learnings.sh to exit 1 when issues found.

9. **DEEP-DD-006 (P3, Trivial):** Add "start" event type to session-log.sh and use it in start.md.

10. **DEEP-SO-005 (P3, Medium effort):** Create CONTEXT_BUDGET.default.json with v7 defaults.

11. **DEEP-SO-003 (P2, Medium effort):** Implement comprehension_gates state persistence in next.md.

12. **DEEP-DD-003 (P2, Medium effort):** Add poison-pill tests for 3 remaining specialist agents.

13. **DEEP-SF-005 (P3, Medium effort):** Extend post-write.sh secret detection to .js/.jsx/.py files.

14. **DEEP-SF-006 (P3, Low effort):** Inline `$ref` definitions in STATE.schema.json so validate-state.sh can check them.

15. **DEEP-DD-007 (P3, Trivial):** Either document quick.md's 2-attempt max or change it to read STATE.reflexion.max_attempts.

Items 1-5 are high-priority fixes. Items 6-9 are trivial fixes that can be batched. Items 10-15 require varying levels of effort.

---

## Appendix A: Files Inventoried

**72 files examined across framework/**

```
framework/DEV-FLOW.md                          88 lines
framework/agents/architect.md                    94 lines
framework/agents/critic.md                       82 lines
framework/agents/executor.md                    217 lines
framework/agents/planner.md                      46 lines
framework/agents/specialist/data.md              17 lines
framework/agents/specialist/frontend.md          16 lines
framework/agents/specialist/integration.md       17 lines
framework/agents/specialist/security.md          17 lines
framework/agents/verifier.md                     62 lines
framework/apex-branding.md                     1176 lines
framework/apex-design-notes.md                   91 lines
framework/apex-learnings.md                     159 lines
framework/apex-model-routing.json                50 lines
framework/apex-skills/README.md                  10 lines
framework/apex-skills/auth-jwt.md                33 lines
framework/apex-skills/nextjs.md                  40 lines
framework/apex-skills/postgres.md                38 lines
framework/apex-skills/prisma.md                  34 lines
framework/apex-skills/react.md                   33 lines
framework/apex-skills/stripe.md                  45 lines
framework/apex-skills/supabase.md                33 lines
framework/apex-skills/tailwind.md                25 lines
framework/apex-skills/typescript.md              38 lines
framework/commands/apex/_debate.md               45 lines
framework/commands/apex/health-check.md         191 lines
framework/commands/apex/micro.md                 45 lines
framework/commands/apex/next.md                 670 lines
framework/commands/apex/pause.md                 28 lines
framework/commands/apex/precheck.md              15 lines
framework/commands/apex/quick.md                 64 lines
framework/commands/apex/recover.md               15 lines
framework/commands/apex/resume.md               143 lines
framework/commands/apex/spec.md                  12 lines
framework/commands/apex/start.md                108 lines
framework/commands/apex/status.md                80 lines
framework/hooks/_require-git.sh                  17 lines
framework/hooks/_require-jq.sh                   23 lines
framework/hooks/_state-update.sh                 47 lines
framework/hooks/circuit-breaker.sh               79 lines
framework/hooks/context-monitor.sh               58 lines
framework/hooks/cross-phase-audit.sh            104 lines
framework/hooks/destructive-guard.sh            180 lines
framework/hooks/generate-task-map.sh             97 lines
framework/hooks/mutation-gate.sh                 81 lines
framework/hooks/phantom-check.sh                 29 lines
framework/hooks/phase-tag.sh                     44 lines
framework/hooks/post-write.sh                    36 lines
framework/hooks/pre-compact.sh                   40 lines
framework/hooks/pre-task-snapshot.sh             82 lines
framework/hooks/session-log.sh                   51 lines
framework/hooks/subagent-stop.sh                 41 lines
framework/hooks/tdad-impact.py                   47 lines
framework/hooks/tdad-index.sh                    90 lines
framework/hooks/verify-learnings.sh             111 lines
framework/schemas/CONTEXT_BUDGET.schema.json    100 lines
framework/schemas/PLAN_META.schema.json          54 lines
framework/schemas/RESULT.schema.json            113 lines
framework/schemas/STATE.schema.json             356 lines
framework/scripts/self-test.sh                   43 lines
framework/scripts/sync-to-claude.sh             160 lines
framework/scripts/validate-state.sh             228 lines
framework/test-fixtures/STATE-good.json         133 lines
framework/test-fixtures/STATE-missing-required.json  131 lines
framework/tests/_harness.sh                     118 lines
framework/tests/test-docs.sh                     38 lines
framework/tests/test-guards.sh                   26 lines
framework/tests/test-hooks-advisory.sh           29 lines
framework/tests/test-hooks-blocking.sh           58 lines
framework/tests/test-hooks-security.sh           20 lines
framework/tests/test-schemas.sh                  18 lines
framework/tests/test-wiring.sh                   72 lines
```

**Also examined:**
- `~/.claude/settings.json` (hook wiring)
- Deployed `~/.claude/hooks/` (comparison with framework/)

**Total lines across framework/:** ~5,893

---

## Appendix B: Commands Executed

```bash
# Pass 1: Inventory
find framework -type f -not -path "*/\.*" | sort
wc -l framework/hooks/*.sh framework/hooks/*.py
wc -l framework/commands/apex/*.md
wc -l framework/agents/*.md framework/agents/specialist/*.md
wc -l framework/schemas/*.json
wc -l framework/scripts/*.sh

# Pass 2: Call Graph
# For each hook:
grep -rn "HOOK_NAME" framework/commands/ framework/agents/ ~/.claude/settings.json
# For each agent:
grep -rn "AGENT_NAME" framework/commands/
# For each schema:
grep -rn "SCHEMA_NAME" framework/ | grep -v "^framework/schemas/"

# Pass 3: Documentation Drift
grep -n "bash ~/.claude/hooks\|Task(" framework/commands/apex/next.md
grep -n "SUMMARY" framework/agents/verifier.md
grep -n "RESULT.json" framework/agents/verifier.md
grep -n "project_name\|level_name" framework/commands/apex/status.md
grep -n "consecutive" framework/commands/apex/status.md
grep -n "consecutive" framework/schemas/STATE.schema.json

# Pass 4: Environment Dependencies
for tool in jq git rg grep sed python3 npx stryker mutmut; do
  grep -rn "$tool" framework/hooks/ framework/scripts/
  grep -rn "_require-$tool\|command -v $tool" framework/hooks/ framework/scripts/
done

# Pass 5: Error Handling
grep -l "set -e\|set -u\|set -o pipefail" framework/hooks/*.sh framework/scripts/*.sh
for hook in framework/hooks/*.sh; do grep -n "exit " "$hook"; done
grep -n "\$?" framework/hooks/*.sh framework/scripts/*.sh
grep -rn "2>/dev/null" framework/hooks/

# Pass 6: State File Analysis
grep -rn "STATE\.json" framework/hooks/ framework/commands/ framework/agents/
grep '"required"' framework/schemas/STATE.schema.json
# Compared start.md init block with schema required array

# Pass 7: Pipeline Tracing
# Read full content: next.md (670 lines), quick.md (64), micro.md (45),
# resume.md (143), start.md (108), status.md (80), health-check.md (191)

# Pass 8: Settings & Wiring
cat ~/.claude/settings.json | jq '.hooks'
diff -qr framework/hooks/ ~/.claude/hooks/

# Pass 9: Anti-Pattern Hunt
grep "mutation_scores" framework/schemas/STATE.schema.json framework/commands/apex/start.md framework/hooks/mutation-gate.sh
grep "comprehension_gates" framework/commands/apex/start.md framework/commands/apex/next.md framework/hooks/*.sh
grep "capacity_tokens" framework/schemas/CONTEXT_BUDGET.schema.json framework/hooks/context-monitor.sh

# Pass 10: Cross-Check
# Compared findings against Shield observations (phase 7, 10/11 tasks, health-check 10/10)

# Verification of false positives from sub-agents
grep "trigger_reason" framework/schemas/STATE.schema.json        # Line 190, 199 — CONFIRMED present
grep "pending_notifications" framework/schemas/STATE.schema.json  # Line 178 — CONFIRMED present
grep "productive" framework/schemas/STATE.schema.json             # Line 161, 171 — CONFIRMED present
head -2 framework/hooks/verify-learnings.sh                       # set -u on line 2 — CONFIRMED
grep "exit" framework/hooks/tdad-index.sh | head -5               # exit 1 on line 15 — CONFIRMED
tail -1 framework/hooks/pre-compact.sh                            # exit 1 on failure — CONFIRMED

# Full file reads (direct verification, not grep)
# Read: start.md (108 lines), STATE.schema.json (356 lines), circuit-breaker.sh (79 lines),
#        verify-learnings.sh (111 lines), pre-compact.sh (40 lines), tdad-index.sh (90 lines),
#        next.md (670 lines), verifier.md (62 lines), critic.md (82 lines), status.md (80 lines),
#        resume.md (143 lines), subagent-stop.sh (41 lines), phantom-check.sh (29 lines),
#        phase-tag.sh (44 lines), apex-model-routing.json (50 lines), mutation-gate.sh (81 lines),
#        session-log.sh (51 lines), destructive-guard.sh (180 lines), cross-phase-audit.sh (104 lines),
#        pre-task-snapshot.sh (82 lines), post-write.sh (36 lines), quick.md (64 lines),
#        validate-state.sh (50 lines of 228), STATE-good.json (133 lines),
#        settings.json (hook wiring section)
#
# Total lines read directly by primary auditor: ~2,815 lines
# Total lines inventoried: ~5,893 lines
# Coverage: ~48% of framework read line-by-line
```

---

---

## Appendix C: Framework Strengths

While this audit focuses on findings, the framework has notable strengths that should be preserved:

1. **Filesystem-level verification pattern** (phase-tag.sh, pre-task-snapshot.sh, subagent-stop.sh) — never trusting `$?` alone; confirming side effects at filesystem level. This is a best practice that exceeds most CI/CD systems.

2. **Clean-room critic protocol** — the separation between executor output (RESULT.json) and critic input is correctly maintained. The critic never sees executor reasoning, SUMMARY.md, or confidence. This prevents the classic "rubber-stamping" failure mode.

3. **3-tier exit code convention** (0=success, 1=advisory, 2=blocking) — applied consistently across 16/16 non-helper hooks (with the exception of verify-learnings.sh). This allows callers to make nuanced decisions.

4. **Quote-aware destructive guard** (destructive-guard.sh) — the pure-bash state machine for command splitting (lines 124-164) is sophisticated and correctly handles edge cases like `echo "rm -rf /"` without false positives.

5. **AP-5 bypass logging** — the framework acknowledges that orchestrator convenience can bypass the pipeline and requires explicit logging (next.md:474-478). This is honest engineering.

6. **Observation masking** — the design of deleting old tool outputs rather than LLM-summarizing them (per R2 research) is a principled approach to context management.

7. **Session Guardian auto-initialization** — next.md:44-61 automatically initializes session state for existing projects that lack it, providing backward compatibility.

8. **Progressive autonomy escalation with verify-level caps** — the autonomy ladder (next.md:258-259) ensures D-level tasks always require human approval regardless of track record.

---

*Audit conducted 2026-04-10 by independent forensic auditor. All findings verified against current file content. Pattern-Echo Hallucination countermeasures applied: 6 false positives from sub-agents caught and excluded.*
