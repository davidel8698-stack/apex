# APEX Framework — Deep Forensic Audit — 2026-04-10

## Executive Summary

The APEX v7 framework is a substantial multi-agent pipeline system spanning 72 files across hooks, commands, agents, schemas, and scripts. After Rounds 3.0–3.7, 4, 4.1, and 5, the framework is in materially better shape than its prior audit (AUDIT-2026-04-09.md) — all 12 previously-closed items remain fixed, with zero regressions detected.

This deep forensic audit identified **21 new findings** across the framework:
- **P0 (Critical): 0**
- **P1 (High): 8** — schema-state mismatches, silent backup failures, hardcoded capacity, type mismatch
- **P2 (Medium): 9** — shell safety gaps, implicit write chains, asymmetric tracking
- **P3 (Low): 4** — vestigial references, ineffective stderr suppression

**Top 5 most important findings:**
1. **DEEP-SO-001** (P1): resume.md writes `session_started` to rotation_history but schema requires `session_ended` — every context rotation creates an invalid record
2. **DEEP-SO-002** (P1): next.md writes `pending_notifications` and `tokens.productive` to STATE.json — neither field exists in schema, and schema enforces `additionalProperties: false`
3. **DEEP-SO-006** (P1): cross-phase-audit.sh writes `regression_rate` as 0-100 integer but schema defines it as 0-1 float — any non-zero regression rate exceeds schema maximum
4. **DEEP-SF-001** (P1): pre-compact.sh always exits 0 even when backup fails — callers cannot detect data loss
5. **DEEP-DD-001** (P1): next.md unconditionally sets `tdad.index_built=true` after hook call, even when python3 is missing and index was not built

The framework's core safety mechanisms (destructive-guard, subagent-stop, phantom-check, pre-task-snapshot) are well-implemented with filesystem-level verification and 3-way exit codes. The primary risk area is **schema-state consistency**: multiple code paths write fields that violate the schema, and the validator runs in soft mode with `|| true`, meaning these violations are never caught.

## Audit Methodology

This audit followed the 10-pass methodology specified in the engagement brief. All 10 passes were executed. The audit was conducted as static analysis only — no hooks were executed at runtime, no STATE.json files were modified, and no framework files were changed. Every finding was verified against current file content with line numbers and verbatim quotes. The auditor explicitly filtered out false positives from sub-agent exploration (e.g., Task() and resolve_model() are prompt pseudocode, not missing implementations; /compact is a built-in Claude Code command; specialist agents are intentionally compact, not stubs).

Round history confirmed from commit log: Rounds 3.0–3.7, 4, 4.1, and 5 are all applied.

## Inventory Results

### Hooks (19 files, ~1,248 lines)

| File | Lines | Description |
|------|-------|-------------|
| _require-git.sh | 17 | Guard: checks git availability and repo context |
| _require-jq.sh | 23 | Guard: checks jq availability with named error |
| _state-update.sh | 47 | Atomic STATE.json updater using jq + temp file |
| circuit-breaker.sh | 79 | Detects no-change loops and tool-call spirals |
| context-monitor.sh | 57 | Token usage estimator with threshold checks |
| cross-phase-audit.sh | 103 | Re-runs prior phase verify commands for regressions |
| destructive-guard.sh | 179 | Blocks dangerous bash commands (rm -rf, force push, etc.) |
| generate-task-map.sh | 96 | Creates TASK_MAP.md from PLAN_META + git |
| mutation-gate.sh | 80 | Runs Stryker/mutmut mutation testing on C/D tasks |
| phantom-check.sh | 28 | Greps SUMMARY.md for uncertainty language |
| phase-tag.sh | 43 | Creates git tags for completed phases with filesystem verification |
| post-write.sh | 35 | Post-write checks: TypeScript errors, secrets, silent catches |
| pre-compact.sh | 46 | Backs up STATE.json, PLAN.md before context compaction |
| pre-task-snapshot.sh | 81 | Creates git stash snapshot with filesystem verification |
| session-log.sh | 49 | Appends timestamped events to SESSION-LOG.md |
| subagent-stop.sh | 40 | Validates subagent produced real changes (3-way exit) |
| tdad-impact.py | 47 | Python: maps changed files to impacted tests |
| tdad-index.sh | 89 | Builds TEST_MAP.txt from test file analysis |
| verify-learnings.sh | 110 | Validates apex-learnings.md tiered structure and staleness |

### Commands (12 files, ~1,388 lines)

| File | Lines | Description |
|------|-------|-------------|
| _debate.md | 45 | Architecture debate protocol for irreversible decisions |
| health-check.md | 191 | Environment and agent validation suite (10 tests) |
| micro.md | 45 | Minimal task executor: no critic, no phantom check |
| next.md | 653 | Main orchestration pipeline (the heart of APEX) |
| pause.md | 28 | State save + pre-compact before manual pause |
| precheck.md | 15 | Marks pre-build checklist items complete |
| quick.md | 64 | Single-task executor with critic and phantom check |
| recover.md | 15 | Recovery menu for stuck/locked state |
| resume.md | 143 | Fresh session initialization after context rotation |
| spec.md | 12 | Spec review/update entry point |
| start.md | 97 | New project initialization |
| status.md | 80 | Glass cockpit dashboard renderer |

### Agents — Core (5 files, ~501 lines)

| File | Lines | Description |
|------|-------|-------------|
| architect.md | 94 | Creates phase plans, PLAN_META.json, WAVE_MAP.json |
| critic.md | 82 | Clean-room adversarial reviewer with filesystem verification |
| executor.md | 217 | Task implementer with trajectory monitoring and typed output |
| planner.md | 46 | Complexity classifier + requirements capturer |
| verifier.md | 62 | Phase-level verification with cross-phase regression check |

### Agents — Specialist (4 files, ~67 lines)

| File | Lines | Description |
|------|-------|-------------|
| data.md | 17 | Database/migration specialist with RLS and idempotency rules |
| frontend.md | 16 | UI/UX specialist with accessibility and loading state rules |
| integration.md | 17 | OAuth/webhook specialist with token management rules |
| security.md | 17 | Auth/multi-tenancy specialist with XSS/injection checks |

Note: Specialist agents are intentionally compact. They define domain-specific non-negotiables and mandatory verify commands, and inherit base behavior from executor.md. This is by design, not a deficiency.

### Schemas (4 files, ~611 lines)

| File | Lines | Description |
|------|-------|-------------|
| CONTEXT_BUDGET.schema.json | 94 | Per-zone token budgets and rotation triggers |
| PLAN_META.schema.json | 54 | Phase plan metadata structure |
| RESULT.schema.json | 113 | Executor output contract |
| STATE.schema.json | 350 | Primary state machine schema (largest file) |

### Scripts (3 files, ~410 lines)

| File | Lines | Description |
|------|-------|-------------|
| self-test.sh | 43 | Infrastructure test suite runner |
| sync-to-claude.sh | 160 | Deploys framework/ to ~/.claude/ |
| validate-state.sh | 207 | JSON Schema subset validator (jq-based) |

### Framework Root (5 files, ~1,564 lines)

| File | Lines | Description |
|------|-------|-------------|
| apex-branding.md | 1,176 | Complete cinematic CLI visual identity |
| apex-design-notes.md | 91 | Design rationale reference |
| apex-learnings.md | 159 | Tiered citation-based knowledge base (out of scope) |
| apex-model-routing.json | 50 | Per-agent model selection routing |
| DEV-FLOW.md | 88 | Developer workflow documentation |

### Framework vs. Deployed (~/.claude/) Comparison

All APEX framework files are deployed and in sync with ~/.claude/. The deployed ~/.claude/ contains additional GSD framework files (11 agents, 2 hooks, 1 statusline script) that are outside APEX scope. No APEX files are missing from deployment.

## Call Graph Results

### Dead Code Analysis
**No dead hooks, orphaned agents, or phantom schemas detected.** All 19 hooks have callers (either from commands/agents or via settings.json wiring). All 9 agents (5 core + 4 specialist) are referenced in apex-model-routing.json and dispatched by commands. All 4 schemas are referenced by multiple consumers.

### Settings.json Hook Wiring
Six hooks are wired in ~/.claude/settings.json. All exist at their declared paths:

| Hook | Event | Matcher | Exists |
|------|-------|---------|--------|
| destructive-guard.sh | PreToolUse | Bash | YES |
| post-write.sh | PostToolUse | Write\|Edit | YES |
| circuit-breaker.sh | PostToolUse | Bash | YES |
| subagent-stop.sh | SubagentStop | (all) | YES |
| pre-compact.sh | PreCompact | (all) | YES |
| verify-learnings.sh | SessionStart | (all) | YES |

No stderr suppression (`2>/dev/null`) or exit-code masking (`|| true`) found in settings.json wiring.

## Environment Dependencies (Pass 4 Results)

### External Tool Usage and Guards

| Tool | Used by | Guard Present | Guard Type |
|------|---------|---------------|------------|
| jq | circuit-breaker.sh, context-monitor.sh, cross-phase-audit.sh, generate-task-map.sh, mutation-gate.sh, phase-tag.sh, pre-compact.sh, pre-task-snapshot.sh, subagent-stop.sh | YES (all 9) | `source _require-jq.sh` + `require_jq` |
| git | circuit-breaker.sh, cross-phase-audit.sh, generate-task-map.sh, mutation-gate.sh, phase-tag.sh, pre-task-snapshot.sh, subagent-stop.sh, tdad-index.sh | YES (6 via _require-git.sh, 2 via `|| exit 2`) | `source _require-git.sh` or inline guard |
| rg | generate-task-map.sh | YES | `command -v rg &>/dev/null` (line 51) |
| python3 | tdad-index.sh | YES | `command -v python3 &>/dev/null` (line 12) |
| npx/tsc | post-write.sh | YES | `command -v npx &>/dev/null` (line 6) |
| npx/stryker | mutation-gate.sh | YES | `command -v npx` + `npx stryker --version` (lines 32-33) |
| mutmut | mutation-gate.sh | YES | `command -v mutmut` (line 42) |
| md5sum | circuit-breaker.sh | NO | Used for file hash (line 25) — standard coreutils |
| grep | destructive-guard.sh, multiple | NO | Standard POSIX — assumed always available |
| awk | cross-phase-audit.sh | NO | Standard POSIX — assumed always available |

**Assessment:** All non-standard tools are properly guarded. The framework follows a consistent pattern: `_require-jq.sh` and `_require-git.sh` are sourced for frequently-used tools, while `command -v` is used for less-common tools (rg, python3, npx). No unguarded external tool usage detected.

### 2>/dev/null Usage Census

| Hook | Count | Context | Risk |
|------|-------|---------|------|
| circuit-breaker.sh | 5 | jq field reads with `// ""` fallbacks | Low — guards + fallbacks |
| context-monitor.sh | 7 | jq reads + arithmetic test | Low — one ineffective (DEEP-SF-004) |
| cross-phase-audit.sh | 4 | jq reads + phase num comparison | Low |
| destructive-guard.sh | 15 | grep pattern matching | Low — grep doesn't produce meaningful stderr |
| generate-task-map.sh | 5 | jq reads + rg search | Low |
| mutation-gate.sh | 2 | git diff + npx version check | Medium — git error suppressed (DEEP-ED note) |
| phantom-check.sh | 2 | grep for uncertainty phrases | Low |
| phase-tag.sh | 0 | (uses explicit capture: `2>&1`) | N/A — good pattern |
| post-write.sh | 6 | tsc output + secret/catch detection | Low |
| pre-compact.sh | 4 | cp + jq operations | Medium (DEEP-SF-001) |
| pre-task-snapshot.sh | 2 | schema validation + git stash store | Low |
| session-log.sh | 1 | grep for last date | Low |
| subagent-stop.sh | 0 | (uses explicit capture: `2>&1`) | N/A — good pattern |
| tdad-index.sh | 2 | command -v + find | Low |
| **Total** | **55** | | |

**Assessment:** 55 instances of `2>/dev/null` across 14 hooks. Most are defensive patterns on jq field reads that already have `_require-jq.sh` guards — the `2>/dev/null` suppresses jq's stderr on empty/null fields, which is a common and acceptable pattern. The notable exceptions are pre-compact.sh (where suppression hides backup failures — DEEP-SF-001) and context-monitor.sh:28 (ineffective on test command — DEEP-SF-004). phase-tag.sh and subagent-stop.sh demonstrate the preferred pattern: capturing stderr with `2>&1` instead of suppressing it.

## Error Handling Audit (Pass 5 Results)

### Shell Safety Settings

| Script | set -e | set -u | set -o pipefail | Notes |
|--------|--------|--------|-----------------|-------|
| circuit-breaker.sh | NO | NO | NO | Relies on explicit `|| exit 2` |
| context-monitor.sh | NO | NO | NO | Relies on explicit exit codes |
| cross-phase-audit.sh | NO | NO | NO | Relies on explicit exit codes |
| destructive-guard.sh | NO | NO | NO | Pure conditionals |
| generate-task-map.sh | NO | NO | NO | Relies on explicit exit codes |
| mutation-gate.sh | NO | NO | NO | Relies on explicit exit codes |
| phantom-check.sh | NO | NO | NO | Simple grep-based |
| phase-tag.sh | NO | NO | NO | Relies on explicit exit codes |
| post-write.sh | NO | NO | NO | Relies on explicit exit codes |
| pre-compact.sh | NO | NO | NO | (DEEP-SF-001) |
| pre-task-snapshot.sh | NO | NO | NO | 3-way exit codes |
| session-log.sh | NO | NO | NO | Always succeeds |
| subagent-stop.sh | NO | NO | NO | 3-way exit codes |
| tdad-index.sh | NO | NO | NO | Relies on explicit exit codes |
| verify-learnings.sh | NO | NO | NO | Pure string processing |
| _require-git.sh | NO | NO | NO | Guard utility |
| _require-jq.sh | NO | NO | NO | Guard utility |
| _state-update.sh | NO | NO | NO | jq wrapper |
| validate-state.sh | NO | YES | YES | **Only script with safety flags** |
| sync-to-claude.sh | YES | YES | YES | **Well-hardened deployment script** |
| self-test.sh | NO | NO | NO | Test runner |

**Assessment:** 19 of 21 shell scripts lack any shell safety settings (DEEP-SF-002). The two exceptions are validate-state.sh (`set -uo pipefail`) and sync-to-claude.sh (`set -euo pipefail`). The framework compensates through explicit error checking patterns (`|| exit 2`, `$?` capture, conditional exit codes), but this is more fragile than shell safety settings which catch undefined variables and pipe failures automatically.

### Exit Code Patterns

The framework uses a consistent 3-way exit code convention:
- **Exit 0:** Success or advisory skip (non-blocking)
- **Exit 1:** Warning or advisory failure (non-blocking)
- **Exit 2:** Hard failure or blocked condition (blocking)

| Hook | Exit 0 | Exit 1 | Exit 2 | Pattern |
|------|--------|--------|--------|---------|
| circuit-breaker.sh | ✅ (normal) | — | ✅ (loop/cap) | 2-way |
| context-monitor.sh | ✅ (normal) | ✅ (warning) | ✅ (critical) | 3-way |
| cross-phase-audit.sh | ✅ (no regressions) | — | ✅ (regressions) | 2-way |
| destructive-guard.sh | ✅ (allowed) | — | ✅ (blocked) | 2-way |
| generate-task-map.sh | ✅ (generated) | ✅ (no files) | ✅ (git error) | 3-way |
| mutation-gate.sh | ✅ (skip/pass) | — | ✅ (below threshold) | 2-way |
| phantom-check.sh | ✅ (clean) | — | ✅ (phantom detected) | 2-way |
| phase-tag.sh | ✅ (tagged) | — | ✅ (unverified) | 2-way |
| post-write.sh | ✅ (clean) | — | ✅ (TS error/secret) | 2-way |
| pre-compact.sh | ✅ (always) | — | — | 1-way (DEEP-SF-001) |
| pre-task-snapshot.sh | ✅ (snapshot ok) | ✅ (git error) | ✅ (unverified) | 3-way |
| session-log.sh | ✅ (always) | — | — | 1-way (intentional) |
| subagent-stop.sh | ✅ (validated) | ✅ (git error) | ✅ (hallucination) | 3-way |
| tdad-index.sh | ✅ (built/skip) | — | ✅ (deploy error) | 2-way |
| verify-learnings.sh | ✅ (always) | — | — | 1-way (intentional) |

**Assessment:** Exit code patterns are generally well-designed. The 3-way pattern (used by context-monitor, generate-task-map, pre-task-snapshot, subagent-stop) is the framework's strongest error-handling mechanism, allowing callers to distinguish "success," "advisory," and "blocking." The only problematic exit pattern is pre-compact.sh (always exit 0 — DEEP-SF-001). session-log.sh and verify-learnings.sh always exit 0 by design (they're advisory/logging hooks that should never block operations).

### $? Usage Audit

Every `$?` capture in the framework is correctly placed immediately after its source command:

| File | Line | Variable | Source Command | Correct |
|------|------|----------|----------------|---------|
| cross-phase-audit.sh | 61 | EXIT_CODE | `bash -c "$cmd"` | YES |
| phase-tag.sh | 23 | TAG_EXIT | `git tag -a ...` | YES |
| post-write.sh | 8 | TSC_EXIT | `npx tsc --noEmit` | YES |
| pre-task-snapshot.sh | 46 | STASH_EXIT | `git stash create` | YES |
| subagent-stop.sh | 23 | GIT_EXIT | `git diff HEAD --stat` | YES |

No instances of stale `$?` reads (reading `$?` after an intervening command).

---

## Findings by Severity

### P0 — Critical (0 findings)

No critical findings. The framework is not actively broken for immediate users.

---

### P1 — High (7 findings)

---

### DEEP-SO-001 — rotation_history field name mismatch: session_started vs session_ended

**Severity:** P1
**Category:** State Drift
**Confidence:** HIGH
**File:** framework/commands/apex/resume.md
**Lines:** 49

**Current state (verbatim quote from file):**
```
  append to rotation_history: {phase, session_started, reason: "manual_resume"}
```

**The problem:**
resume.md:49 appends a rotation_history entry with the field name `session_started`. However, STATE.schema.json:139 defines the required fields for rotation_history items as `["phase", "session_ended", "reason"]`. The field name `session_ended` is required, not `session_started`. Every context rotation creates an entry that violates the schema.

**Which failure mode does this expose:**
**Drift** — The code and schema have diverged on the field name. Any downstream code reading `session_ended` from rotation_history will get undefined/null instead of the actual timestamp.

**Evidence of impact:**
A user running /apex:resume after a context rotation would have their rotation_history populated with `session_started` fields. If any code later reads `session_ended` (as the schema specifies), it would find nothing. If validate-state.sh is ever run in strict mode, all STATE.json files with rotation_history entries would fail validation.

**How to reproduce:**
```bash
# Show the mismatch
grep -n "session_started\|session_ended" framework/commands/apex/resume.md
grep -n "session_ended\|session_started" framework/schemas/STATE.schema.json
```

**Expected behavior:**
resume.md should write `session_ended` (matching the schema) or the schema should be updated to accept `session_started`. Given that the event represents the END of a session (a rotation is occurring), `session_ended` is the semantically correct name.

**Recommended fix direction:**
Change resume.md:49 from `session_started` to `session_ended`. Verify no other code references `session_started`.

**Related to prior findings:**
New finding.

**Verification notes:**
Verified against current state as of this audit. HIGH confidence — the mismatch is textually unambiguous between resume.md:49 and STATE.schema.json:139.

---

### DEEP-SO-002 — next.md writes fields not in STATE.schema.json (pending_notifications, tokens.productive)

**Severity:** P1
**Category:** State Drift
**Confidence:** HIGH
**File:** framework/commands/apex/next.md
**Lines:** 158-159

**Current state (verbatim quote from file):**
```
  pending_notifications: [],
  tokens: {framework_overhead: 0, productive: 0}
```

**The problem:**
next.md:158 instructs the orchestrator to write `pending_notifications` to STATE.json, and next.md:159 writes `tokens.productive`. Neither field exists in STATE.schema.json. The root schema has `additionalProperties: false` (schema line 7), and the tokens object also has `additionalProperties: false` (schema line 151). Any STATE.json containing these fields would fail strict schema validation. Additionally, next.md:502 uses `productive` in an overhead calculation: `OVERHEAD_PCT = framework_overhead * 100 / (framework_overhead + productive)`.

**Which failure mode does this expose:**
**Drift** — The orchestration instructions have drifted from the schema. The schema is supposed to be the single source of truth (per start.md:41 comment), but the pipeline writes fields the schema doesn't recognize.

**Evidence of impact:**
A user's STATE.json will contain `pending_notifications` and `tokens.productive` after the architect stage. If validate-state.sh is run in strict mode (not --soft), it will report these as additionalProperties violations. The overhead calculation at next.md:502 depends on `tokens.productive` existing.

**How to reproduce:**
```bash
# Verify fields are NOT in schema
grep "pending_notifications" framework/schemas/STATE.schema.json
grep "productive" framework/schemas/STATE.schema.json
# Verify they ARE written by next.md
grep -n "pending_notifications\|productive" framework/commands/apex/next.md
```

**Expected behavior:**
Either add `pending_notifications` and `tokens.productive` to STATE.schema.json, or remove them from next.md's state update instructions.

**Recommended fix direction:**
Add both fields to STATE.schema.json: `pending_notifications` as an array at root level, and `productive` as an integer field within the tokens object. Update validate-state.sh test fixtures accordingly.

**Related to prior findings:**
New finding. Related to DEEP-SO-003 (circuit-breaker trigger_reason) — same pattern of code writing undocumented fields.

**Verification notes:**
Verified against current state as of this audit. HIGH confidence — grep confirms absence from schema and presence in next.md.

---

### DEEP-SO-003 — circuit-breaker.sh writes trigger_reason field not in STATE.schema.json

**Severity:** P1
**Category:** State Drift
**Confidence:** HIGH
**File:** framework/hooks/circuit-breaker.sh
**Lines:** 47, 75

**Current state (verbatim quote from file):**
```
    _state_update '.circuit_breaker.triggered = true | .circuit_breaker.trigger_reason = "no_change_loop"' "$STATE_FILE"
```
(line 47)
```
  _state_update '.circuit_breaker.triggered = true | .circuit_breaker.trigger_reason = "tool_call_cap"' "$STATE_FILE"
```
(line 75)

**The problem:**
circuit-breaker.sh writes `circuit_breaker.trigger_reason` to STATE.json at two locations. However, STATE.schema.json defines the circuit_breaker object with `additionalProperties: false` and does not include `trigger_reason` in its properties. The schema only defines: `consecutive_no_change_actions`, `max_allowed`, `total_tool_calls_this_task`, `max_tool_calls_per_task`, `last_file_hash`, `triggered`.

**Which failure mode does this expose:**
**Drift** — The hook writes a field the schema explicitly forbids via `additionalProperties: false`.

**Evidence of impact:**
Every time the circuit breaker triggers, STATE.json will contain a field that fails schema validation. If validate-state.sh is run in strict mode, the STATE.json file will be flagged as invalid. The trigger_reason value is useful diagnostic information that would be lost if the field were removed rather than added to the schema.

**How to reproduce:**
```bash
grep -n "trigger_reason" framework/hooks/circuit-breaker.sh
grep "trigger_reason" framework/schemas/STATE.schema.json
# Second grep returns empty — field not in schema
```

**Expected behavior:**
`trigger_reason` should be defined in STATE.schema.json within the circuit_breaker object as `"trigger_reason": { "type": ["string", "null"] }`.

**Recommended fix direction:**
Add `trigger_reason` to the circuit_breaker properties in STATE.schema.json. Also add it to start.md init (as null).

**Related to prior findings:**
New finding. Same pattern as DEEP-SO-002.

**Verification notes:**
Verified against current state as of this audit. HIGH confidence.

---

### DEEP-SF-001 — pre-compact.sh always exits 0 even when backups fail

**Severity:** P1
**Category:** Silent Failure
**Confidence:** HIGH
**File:** framework/hooks/pre-compact.sh
**Lines:** 44-47

**Current state (verbatim quote from file):**
```
  echo "⚠️ APEX: Backup incomplete $TIMESTAMP — some files could not be copied" >&2
fi

exit 0
```

**The problem:**
pre-compact.sh always exits 0 regardless of whether backups succeeded or failed. When `BACKUP_OK=false` (lines 14, 18, 23, 33 — any backup copy fails), the hook prints a warning to stderr but still exits 0. The caller (settings.json PreCompact hook and pause.md:15) cannot distinguish successful backup from failed backup. This means context compaction can proceed even when state recovery data was not saved.

**Which failure mode does this expose:**
**Failure** — If a backup fails silently and the user later needs to recover state (e.g., after a crash during compaction), the backup they expect to exist will be missing or incomplete. This is a safety-critical failure because pre-compact is the last line of defense before context is lost.

**Evidence of impact:**
A user on OneDrive (where write conflicts are known to occur — see Shield observations) runs /apex:pause or triggers context compaction. OneDrive locks the STATE.json file during sync. The `cp` command fails. pre-compact.sh prints a warning to stderr (which may scroll past) and exits 0. The compaction proceeds. The user later runs /apex:recover and finds no valid backup to restore from.

**How to reproduce:**
```bash
# Read the exit path
grep -n "exit" framework/hooks/pre-compact.sh
# Only one exit statement: line 47, always exit 0
```

**Expected behavior:**
When BACKUP_OK is false, exit with a non-zero code (exit 1 for advisory, exit 2 for blocking) so callers can decide whether to proceed without a backup.

**Recommended fix direction:**
Change line 47 from unconditional `exit 0` to:
```bash
if [ "$BACKUP_OK" = true ]; then exit 0; else exit 1; fi
```
This allows callers to decide whether to proceed (advisory) or block (blocking).

**Related to prior findings:**
New finding.

**Verification notes:**
Verified against current state as of this audit. HIGH confidence — the single `exit 0` at line 47 is unambiguous.

---

### DEEP-DD-001 — next.md unconditionally sets tdad.index_built=true after hook call

**Severity:** P1
**Category:** Documentation Drift
**Confidence:** HIGH
**File:** framework/commands/apex/next.md
**Lines:** 145-149

**Current state (verbatim quote from file):**
```
bash ~/.claude/hooks/tdad-index.sh
Update STATE: {
  current_stage: "build", current_phase: "01", current_wave: 1,
  status: "pending_approval",
  tdad: {index_built: true, last_indexed: now},
```

**The problem:**
next.md:145 calls tdad-index.sh, then next.md:149 unconditionally sets `tdad.index_built = true`. However, tdad-index.sh exits 0 (success) when python3 is not found (tdad-index.sh:14: `exit 0`), meaning the index was NOT built but the exit code signals success. The orchestrator (Claude) following next.md would see exit 0 and proceed to set index_built=true even though no index exists. Later, next.md:193-195 uses `STATE.tdad.index_built` to decide whether to run tdad-impact.py — it would attempt to run a Python script on a system where python3 is known to be missing.

**Which failure mode does this expose:**
**Hallucination** — STATE.json claims the TDAD index is built when it isn't. Downstream code trusts this flag and acts on a false premise.

**Evidence of impact:**
A user on a system without python3 (e.g., Windows without Python installed) starts a project. tdad-index.sh exits 0 (advisory: python3 not found). STATE.json records `tdad.index_built: true`. Later, /apex:next at Step B (line 195) runs `python3 ~/.claude/hooks/tdad-impact.py` — which fails because python3 doesn't exist. The error may be swallowed depending on how the orchestrator handles it.

**How to reproduce:**
```bash
# Show tdad-index.sh exits 0 when python3 missing
grep -n "exit 0" framework/hooks/tdad-index.sh
# Line 14: exit 0 (python3 not found - advisory)
# Show next.md unconditionally sets index_built=true
grep -n "index_built" framework/commands/apex/next.md
```

**Expected behavior:**
next.md should check the exit code of tdad-index.sh and only set `tdad.index_built=true` if the hook actually built the index. Alternatively, tdad-index.sh could exit 1 (advisory) instead of 0 when python3 is missing, so the orchestrator can distinguish success from graceful skip.

**Recommended fix direction:**
Add a conditional: "If tdad-index.sh exit code == 0 AND python3 was available: set index_built=true. Else: set index_built=false." Requires design discussion — the orchestrator is an LLM following instructions, not a bash script, so the conditional must be expressed clearly in the .md pseudocode.

**Related to prior findings:**
New finding. Instance of AP-1 (Silent Install Failure).

**Verification notes:**
Verified against current state as of this audit. HIGH confidence.

---

### DEEP-SO-004 — context.last_compact never initialized by any command

**Severity:** P1
**Category:** State Drift
**Confidence:** HIGH
**File:** framework/commands/apex/start.md
**Lines:** 48

**Current state (verbatim quote from file):**
```
    context: {current_session_phase: null, estimated_context_usage_pct: 0, rotation_history: [], observation_masking_active: true}
```

**The problem:**
STATE.schema.json:120-127 lists `last_compact` as a required field within the context object. start.md:48 initializes the context object but does not include `last_compact`. resume.md:45-49 updates context fields but also does not set `last_compact`. No other command or hook initializes this field. This means every STATE.json created by /apex:start is missing a schema-required field from the moment of creation.

Additionally, start.md:48 also omits `session_start_time` (required by schema:122) from the context init. This field IS set later by the Session Guardian in next.md:47 (`started_at: now`), but the context.session_start_time specifically is never set.

**Which failure mode does this expose:**
**Forgetting** — The framework claims to track when the last context compaction occurred, but never initializes or writes this field. Any code reading `context.last_compact` will get undefined.

**Evidence of impact:**
A user creates a new project with /apex:start. STATE.json is created without `context.last_compact`. If validate-state.sh runs in strict mode, it flags the missing required field. Any future code that checks "time since last compact" will get undefined and may behave unpredictably.

**How to reproduce:**
```bash
# Verify last_compact is required
grep -A5 "\"context\"" framework/schemas/STATE.schema.json | grep "required" -A6
# Verify it's NOT in start.md init
grep "last_compact" framework/commands/apex/start.md
# Returns nothing
grep "last_compact" framework/commands/apex/resume.md
# Returns nothing
```

**Expected behavior:**
start.md should initialize `context.last_compact: null` (or the current timestamp). resume.md should also set it when appropriate.

**Recommended fix direction:**
Add `last_compact: null` to start.md:48's context initialization. Consider also initializing `session_start_time: now` in the same block.

**Related to prior findings:**
New finding. Part of the broader schema-init gap (see DEEP-SO-005).

**Verification notes:**
Verified against current state as of this audit. HIGH confidence — grep confirms absence.

---

### DEEP-ED-001 — context-monitor.sh hardcodes EFFECTIVE_CAPACITY instead of reading CONTEXT_BUDGET.json

**Severity:** P1
**Category:** Environment Dependency Gap
**Confidence:** HIGH
**File:** framework/hooks/context-monitor.sh
**Lines:** 25-26

**Current state (verbatim quote from file):**
```
# Effective capacity is 200K (R2: design for 100-160K working set within 200K window)
EFFECTIVE_CAPACITY=200000
```

**The problem:**
context-monitor.sh:26 hardcodes `EFFECTIVE_CAPACITY=200000`. The CONTEXT_BUDGET.schema.json defines configurable thresholds (and context-monitor.sh already reads `proactive_compact_pct` and `hard_rotate_pct` from CONTEXT_BUDGET.json at lines 18-19), but the base capacity against which percentages are calculated is hardcoded. If the effective context window changes (e.g., model upgrade to 500K), this constant must be manually updated in the hook rather than being configurable.

**Which failure mode does this expose:**
**Drift** — The capacity assumption is embedded in code rather than configuration. If CONTEXT_BUDGET.json's thresholds are tuned for a different capacity, the percentages will be wrong. For example, if a user configures thresholds for a 100K model, the hook will still calculate against 200K and trigger compaction too late.

**Evidence of impact:**
A user running APEX on a model with a different context window (e.g., 100K Haiku) would have context-monitor.sh calculate usage percentages against the wrong base capacity. At 80K actual tokens, context-monitor.sh would report ~40% usage instead of ~80%, missing the proactive compact threshold entirely.

**How to reproduce:**
```bash
grep -n "EFFECTIVE_CAPACITY\|200000" framework/hooks/context-monitor.sh
# Line 26: EFFECTIVE_CAPACITY=200000 — hardcoded
grep -n "capacity\|effective" framework/schemas/CONTEXT_BUDGET.schema.json
# No capacity field in schema either
```

**Expected behavior:**
EFFECTIVE_CAPACITY should either be read from CONTEXT_BUDGET.json (add a `capacity` field to the schema) or at minimum documented as a deployment constant that must match the target model.

**Recommended fix direction:**
Add a `capacity_tokens` field to CONTEXT_BUDGET.schema.json and CONTEXT_BUDGET.json. Read it in context-monitor.sh with a fallback: `EFFECTIVE_CAPACITY=$(jq -r '.capacity_tokens // 200000' "$BUDGET_FILE" 2>/dev/null)`. Requires design discussion on whether CONTEXT_BUDGET.json should be per-model or per-project.

**Related to prior findings:**
New finding.

**Verification notes:**
Verified against current state as of this audit. HIGH confidence.

---

### DEEP-SO-006 — cross-phase-audit.sh writes regression_rate as 0-100 integer but schema expects 0-1 float

**Severity:** P1
**Category:** State Drift
**Confidence:** HIGH
**File:** framework/hooks/cross-phase-audit.sh
**Lines:** 79, 81-86

**Current state (verbatim quote from file):**
```bash
  [ "$TOTAL_TESTS" -gt 0 ] && REGRESSION_RATE=$((FAILURES * 100 / TOTAL_TESTS))

  _state_update --argjson rate "$REGRESSION_RATE" \
     --argjson total "$TOTAL_TESTS" \
     --arg date "$(date +%Y-%m-%d)" \
     '.evoscore.regression_rate = $rate |
      .evoscore.total_cross_phase_tests = $total |
      .evoscore.last_full_audit = $date'
```

And STATE.schema.json:93:
```json
"regression_rate": { "type": "number", "minimum": 0, "maximum": 1 },
```

**The problem:**
cross-phase-audit.sh:79 calculates `REGRESSION_RATE` using bash integer arithmetic: `$((FAILURES * 100 / TOTAL_TESTS))`. This produces integer values in the 0-100 range (e.g., 25 for 25% regression rate). However, STATE.schema.json:93 defines `regression_rate` with `"maximum": 1`, expecting a 0.0 to 1.0 float. Any non-zero regression rate (e.g., 1 failure in 10 tests = REGRESSION_RATE=10) would exceed the schema maximum of 1 and fail validation.

**Which failure mode does this expose:**
**Drift** — The hook and the schema disagree on the scale of the regression_rate field. This means either the schema is wrong (should allow 0-100) or the hook calculation is wrong (should produce 0.0-1.0).

**Evidence of impact:**
A user's project has 1 regression in 10 cross-phase tests. cross-phase-audit.sh calculates REGRESSION_RATE=10 and writes it to STATE.json. The schema says maximum is 1. validate-state.sh (if it checked numeric ranges, which currently it doesn't per DEEP-SF-003) would reject this value. status.md:48 displays `STATE.evoscore.regression_rate` — showing "10" where it should show "10%" or "0.10".

**How to reproduce:**
```bash
# Show the integer calculation
grep -n "REGRESSION_RATE" framework/hooks/cross-phase-audit.sh
# Line 79: $((FAILURES * 100 / TOTAL_TESTS)) — produces 0-100 integers
# Show the schema constraint
jq '.properties.evoscore.properties.regression_rate' framework/schemas/STATE.schema.json
# { "type": "number", "minimum": 0, "maximum": 1 }
```

**Expected behavior:**
Either the schema should be `"maximum": 100` to match the hook's 0-100 integer output, or the hook should calculate a 0.0-1.0 float (e.g., using `awk` or `bc` for floating point: `REGRESSION_RATE=$(awk "BEGIN {printf \"%.2f\", $FAILURES / $TOTAL_TESTS}")`).

**Recommended fix direction:**
Change the schema to `"maximum": 100` and `"type": "integer"` (simpler, matches bash integer arithmetic), OR change the hook to produce a 0-1 float (more standard, but requires awk/bc). Requires design discussion on which scale is canonical. Also update status.md display to match whichever scale is chosen.

**Related to prior findings:**
New finding. Part of the schema-state consistency gap (DEEP-SO series).

**Verification notes:**
Verified against current state as of this audit. HIGH confidence — the integer arithmetic and schema constraint are both textually unambiguous.

---

### P2 — Medium (9 findings)

---

### DEEP-SF-002 — No set -e / set -u / set -o pipefail in 14 of 15 shell scripts

**Severity:** P2
**Category:** Silent Failure
**Confidence:** HIGH
**File:** framework/hooks/*.sh (all except validate-state.sh)
**Lines:** (top of each file)

**Current state (verbatim quote from file):**
All 14 hook scripts in framework/hooks/ begin with `#!/bin/bash` (or `#!/usr/bin/env bash`) followed by a comment, with no shell safety settings. The sole exception is framework/scripts/validate-state.sh:15 which has `set -uo pipefail`.

Example from circuit-breaker.sh:1-2:
```
#!/bin/bash
# v7: Added total tool-call cap per task + enhanced loop detection [R1, R7]
```

**The problem:**
Without `set -u`, undefined variables silently expand to empty strings, which can cause conditional branches to take the wrong path. Without `set -o pipefail`, pipe failures are masked by the last command's exit code. The framework partially mitigates this via explicit `|| exit 2` guards on critical commands, but intermediate failures (e.g., a `jq` expression that produces unexpected output) can propagate silently.

**Which failure mode does this expose:**
**Failure** — An undefined variable or silent pipe failure could cause a hook to take the wrong branch, potentially allowing an operation that should have been blocked.

**Evidence of impact:**
If `STATE_FILE` were undefined in circuit-breaker.sh (e.g., due to a sourcing error), `[ ! -f "$STATE_FILE" ]` would test `[ ! -f "" ]`, which is true, causing the hook to exit 0 and skip all checks. With `set -u`, this would error immediately.

**How to reproduce:**
```bash
# Count scripts with shell safety
grep -l "set -e\|set -u\|set -o pipefail" framework/hooks/*.sh framework/scripts/*.sh
# Only framework/scripts/validate-state.sh
# Count scripts without
ls framework/hooks/*.sh | wc -l
# 17 files (including 2 _require-*.sh and _state-update.sh), none with safety flags
```

**Expected behavior:**
All shell scripts should include at minimum `set -u` to catch undefined variables. `set -o pipefail` is recommended for scripts with pipe chains. `set -e` requires more careful adoption due to interaction with conditional commands.

**Recommended fix direction:**
Add `set -u` to all hooks. Add `set -o pipefail` to hooks with pipe chains (cross-phase-audit.sh, generate-task-map.sh, tdad-index.sh). Test thoroughly — `set -u` may expose currently-hidden undefined variables. Requires design discussion on whether `set -e` is appropriate given the 3-way exit code pattern.

**Related to prior findings:**
New finding.

**Verification notes:**
Verified against current state as of this audit. HIGH confidence.

---

### DEEP-AP-001 — tdad-impact.py bare except: catches KeyboardInterrupt and SystemExit

**Severity:** P2
**Category:** Anti-Pattern Instance (AP-1: Silent Install Failure)
**Confidence:** HIGH
**File:** framework/hooks/tdad-impact.py
**Lines:** 24-25

**Current state (verbatim quote from file):**
```python
    except:
        pass
```

**The problem:**
tdad-impact.py:24 uses a bare `except:` clause which catches ALL exceptions including `KeyboardInterrupt` and `SystemExit`. If the user presses Ctrl+C during test mapping, or if a system-level error occurs, the exception is silently swallowed. The function returns an empty list, and the caller (tdad-index.sh) proceeds as if no tests were impacted — which could mean important tests are skipped.

**Which failure mode does this expose:**
**Quality Errors** — If the TDAD mapping fails silently, the executor may skip impacted tests, leading to undetected regressions.

**Evidence of impact:**
A user's project has a corrupted TEST_MAP.txt (e.g., binary characters from OneDrive sync conflict). tdad-impact.py attempts to read it, encounters a UnicodeDecodeError or similar, catches it via bare `except:`, returns empty list. The orchestrator proceeds without running impacted tests, missing a regression.

**How to reproduce:**
```bash
grep -n "except:" framework/hooks/tdad-impact.py
# Line 24: bare except clause
```

**Expected behavior:**
Use `except Exception:` instead of bare `except:` to allow KeyboardInterrupt and SystemExit to propagate. Optionally log the exception to stderr before returning empty.

**Recommended fix direction:**
Change line 24 from `except:` to `except Exception:` and add `import traceback; traceback.print_exc(file=sys.stderr)` before `pass`.

**Related to prior findings:**
New finding. Instance of AP-1 (Silent Install Failure).

**Verification notes:**
Verified against current state as of this audit. HIGH confidence.

---

### DEEP-DD-002 — Phantom-check synthetic CRITIC.md not logged to SESSION-LOG.md

**Severity:** P2
**Category:** Documentation Drift
**Confidence:** HIGH
**File:** framework/commands/apex/next.md
**Lines:** 285-310

**Current state (verbatim quote from file):**
```
If PHANTOM_EXIT == 2: phantom language detected in SUMMARY.md.
  # Synthesize REFLEXION.md (normally written by critic on FAIL)
  Write .apex/phases/${current_phase}/${NEXT_UNIT}-REFLEXION.md:
    [...]
  # Synthesize CRITIC.md with FAIL verdict — verdict handler reads this
  Write .apex/phases/${current_phase}/${NEXT_UNIT}-CRITIC.md:
    [...]
  # Skip the CLEAN-ROOM CRITIC dispatch below. Verdict handler will see FAIL.
  PHANTOM_SKIP_CRITIC = true
```

**The problem:**
When phantom-check detects uncertainty language (exit 2), next.md:285-310 synthesizes a CRITIC.md with FAIL verdict and sets PHANTOM_SKIP_CRITIC=true. However, there is no `session-log.sh` call in this path. Compare to the normal PASS checkpoint at next.md:379 which calls `session-log.sh "checkpoint"`. The phantom-skip path creates a "hidden" failure that doesn't appear in SESSION-LOG.md, making it invisible in the Ambient Timeline (Glass Cockpit) and making post-mortem analysis harder.

**Which failure mode does this expose:**
**Context Loss** — A phantom verification failure is not recorded in the session log. The next /apex:resume or /apex:status will not show this event in the timeline, losing context about what happened.

**Evidence of impact:**
A user's executor writes phantom language in SUMMARY.md. Phantom-check fires, CRITIC.md is synthesized as FAIL. The FAIL verdict handler at next.md:440 does log to session-log.sh, BUT the specific reason (phantom detection rather than actual code failure) is not distinguished. The session log will show "task failed" without indicating it was a phantom verification failure.

**How to reproduce:**
```bash
# Show phantom path has no session-log call
sed -n '285,320p' framework/commands/apex/next.md | grep "session-log"
# Returns nothing
# Compare to normal checkpoint
grep -n "session-log" framework/commands/apex/next.md | head -10
```

**Expected behavior:**
Add a session-log.sh call in the phantom-skip path, e.g.: `bash ~/.claude/hooks/session-log.sh "phantom_fail" "phantom-check: ${NEXT_UNIT} — uncertainty language detected"`

**Recommended fix direction:**
Add session-log call between lines 310 and the PHANTOM_SKIP_CRITIC assignment. Tag the event type as "phantom_fail" for distinct filtering.

**Related to prior findings:**
New finding.

**Verification notes:**
Verified against current state as of this audit. HIGH confidence — the path between lines 285-310 contains no session-log call.

---

### DEEP-DD-003 — Phase-boundary drift check doesn't update drift_indicators

**Severity:** P2
**Category:** Documentation Drift
**Confidence:** HIGH
**File:** framework/commands/apex/next.md
**Lines:** 512-520

**Current state (verbatim quote from file):**
```
    ## DRIFT CHECK — mandatory at phase boundaries in autopilot
    Read .apex/phases/${current_phase}/PLAN_META.json
    Count total done_criteria across all tasks. Count verified=false in RESULT.json files.
    UNVERIFIED_RATIO = unverified / total
    If UNVERIFIED_RATIO > 0.20:
      STATE.autopilot.enabled = false
      STATE.autopilot.was_autopilot = true
      STATE.autopilot.paused_reason = "Phase drift: " + (UNVERIFIED_RATIO * 100) + "% criteria unverified (threshold: 20%)"
      "⏸️ Autopilot paused: too many unverified criteria at phase boundary. Manual review needed."
```

**The problem:**
The phase-boundary drift check (lines 512-520) detects drift when >20% of criteria are unverified but does NOT update `STATE.session.drift_indicators.spec_drift_count`. Compare to the wave-boundary coherence check at next.md:181 which does increment `spec_drift_count`. This creates asymmetric drift tracking — wave-level drift is counted, but phase-level drift is not.

**Which failure mode does this expose:**
**Forgetting** — Phase-boundary drift events are not recorded in drift_indicators. The session health check (next.md:68-72) uses `drift_indicators` to determine health status. A phase with significant drift would not contribute to the health calculation.

**Evidence of impact:**
A user's autopilot completes a phase where 25% of criteria are unverified. The autopilot is paused (correct), but `spec_drift_count` remains at 0. The user manually inspects drift_indicators and sees zero drift, which contradicts the autopilot pause reason. Health status calculations undercount actual drift.

**How to reproduce:**
```bash
# Show wave-level drift increments counter
grep -n "spec_drift_count" framework/commands/apex/next.md
# Line 181: STATE.session.drift_indicators.spec_drift_count++
# Show phase-level drift does NOT
sed -n '512,520p' framework/commands/apex/next.md | grep "drift_indicators"
# Returns nothing
```

**Expected behavior:**
Add `STATE.session.drift_indicators.spec_drift_count++` to the phase-boundary drift check path, alongside the autopilot pause.

**Recommended fix direction:**
Add drift indicator increment at line 517, before or after the autopilot state update.

**Related to prior findings:**
New finding.

**Verification notes:**
Verified against current state as of this audit. HIGH confidence.

---

### DEEP-AP-002 — WAVE_MAP.json and PLAN_META.json read without existence validation (AP-3)

**Severity:** P2
**Category:** Anti-Pattern Instance (AP-3: Implicit Write Chain)
**Confidence:** MEDIUM
**File:** framework/commands/apex/next.md
**Lines:** 173, 194, 198, 209, 329

**Current state (verbatim quote from file):**
Line 173:
```
WAVE_TASKS = WAVE_MAP.waves[CURRENT_WAVE].tasks
```
Line 194:
```
  CHANGED_FILES = PLAN_META.tasks[NEXT_UNIT].files
```

**The problem:**
WAVE_MAP.json and PLAN_META.json are created by the architect agent at next.md:140 (via `Task("architect", ...)`). Multiple subsequent steps read these files (lines 173, 194, 198, 209, 329) without validating they exist. If the architect agent fails or produces malformed output, these reads would fail. Because the commands are .md prompt instructions for an LLM orchestrator (not bash scripts), there's no automatic file-existence check — the orchestrator must be explicitly told to verify.

**Which failure mode does this expose:**
**Failure** — If PLAN_META.json or WAVE_MAP.json doesn't exist when needed, the orchestrator will fail at an indeterminate point, producing confusing error behavior rather than a clear "architect output missing" message.

**Evidence of impact:**
An architect agent call times out or produces only PLAN.md but not the JSON files. The orchestrator proceeds to Step A (line 173), attempts to read WAVE_MAP.json, and encounters a file-not-found situation. Without explicit guidance, the LLM may hallucinate wave data or produce an unclear error.

**How to reproduce:**
```bash
# Show WAVE_MAP.json is created at line 140 and read at line 173
grep -n "WAVE_MAP" framework/commands/apex/next.md
# Show no existence check between creation and first read
sed -n '140,173p' framework/commands/apex/next.md | grep -i "exist\|verify\|check.*file"
# Returns nothing
```

**Expected behavior:**
After the architect invocation (line 140), add an explicit check: "Verify PLAN_META.json and WAVE_MAP.json exist in .apex/phases/${current_phase}/. If missing, STOP with error: 'Architect did not produce required files.'"

**Recommended fix direction:**
Add a file existence check between lines 143 and 145. This is a prompt instruction, not code, so it should be phrased as: "Before proceeding: verify .apex/phases/${current_phase}/PLAN_META.json and WAVE_MAP.json exist. If either is missing: STOP with 'Architect output incomplete — PLAN_META.json or WAVE_MAP.json missing.'"

**Related to prior findings:**
New finding. Instance of AP-3 (Implicit Write Chain).

**Verification notes:**
Verified against current state as of this audit. MEDIUM confidence — the LLM orchestrator may naturally check file existence before reading, but the instruction doesn't require it. The risk depends on the orchestrator's behavior under failure.

---

### DEEP-DD-004 — Token overhead tracking asymmetric when phantom-check skips critic

**Severity:** P2
**Category:** Documentation Drift
**Confidence:** HIGH
**File:** framework/commands/apex/next.md
**Lines:** 322-355

**Current state (verbatim quote from file):**
Line 322-323:
```
## GUARD: If PHANTOM_SKIP_CRITIC == true, skip this ENTIRE section (CRITIC_CONTEXT,
## security persona, Mission Briefing, Task("critic"), Flight Recorder, framework_overhead
```
Line 355:
```
STATE.tokens.framework_overhead += critic call tokens
```

**The problem:**
When PHANTOM_SKIP_CRITIC is true (lines 322-326), the entire critic section including the `framework_overhead` update at line 355 is skipped. A task that fails phantom-check will show lower framework overhead than an identical task that passes phantom-check but fails critic. This creates inconsistent token accounting — the same logical outcome (task FAIL) produces different overhead measurements depending on which detection mechanism caught it.

**Which failure mode does this expose:**
**Quality Errors** — Token overhead statistics become unreliable because the same type of failure produces different measurements. The overhead check at next.md:501-503 (`If OVERHEAD_PCT > 15`) may undercount overhead when phantom failures are common.

**Evidence of impact:**
A project with frequent phantom verification failures would show artificially low framework overhead, because phantom-check failures skip the critic token cost. The overhead monitoring at line 501-503 would not trigger warnings when it should.

**How to reproduce:**
```bash
# Show phantom skip bypasses overhead update
sed -n '322,326p' framework/commands/apex/next.md
sed -n '355,355p' framework/commands/apex/next.md
```

**Expected behavior:**
When phantom-check fires, estimate and record the tokens that WOULD have been spent on the critic call, or at minimum record a fixed "phantom-check cost" to maintain consistent accounting.

**Recommended fix direction:**
After the phantom-skip path (around line 310), add: "STATE.tokens.framework_overhead += estimated phantom-check cost (fixed estimate: 2000 tokens)". Requires design discussion on the right estimate.

**Related to prior findings:**
New finding.

**Verification notes:**
Verified against current state as of this audit. HIGH confidence — the skip instruction at line 322-326 explicitly lists "framework_overhead update" as skipped.

---

### DEEP-SO-005 — start.md claims "CANONICAL STATE SHAPE" but misses multiple required schema fields

**Severity:** P2
**Category:** Schema Orphan / State Drift
**Confidence:** HIGH
**File:** framework/commands/apex/start.md
**Lines:** 41-91

**Current state (verbatim quote from file):**
Line 41:
```
  ## ⚠️ CANONICAL STATE SHAPE — single source of truth. Also update STATE.schema.json and status.md on changes.
```
Lines 42-91 initialize STATE.json with specific fields.

**The problem:**
start.md:41 declares itself the "CANONICAL STATE SHAPE — single source of truth" for STATE.json. However, it initializes only ~15 of the ~31 root-level required fields defined in STATE.schema.json:8-41. The following required root-level fields are missing from start.md's init:

Missing from init (filled later by planner/architect stages):
- `project`, `complexity_level`, `complexity_name`, `pipeline` (filled by planner at step 6)
- `current_stage`, `status` (filled at step 7)
- `current_phase`, `current_unit`, `current_wave` (filled at architect stage in next.md)
- `autonomy` (filled at next.md:154-157)
- `phases_total`, `phases_completed`, `units_total`, `units_completed` (filled at architect stage)

Never explicitly initialized by any command:
- `health_check` (required object with 4 fields — schema:316-325)
- `pre_build_complete` (boolean — schema:49)
- `lock` (string|null — schema:335)
- `created_at` (datetime — schema:336)
- `updated_at` (datetime — schema:337)
- `mutation_scores` (object — schema:327, though not in required array)

Additionally, within initialized objects, some required sub-fields are missing:
- `context.last_compact` (required per schema:124) — see DEEP-SO-004
- `context.session_start_time` (required per schema:122)
- `tdad.last_indexed`, `tdad.total_nodes` (required per schema:110)
- `reflexion.last_reflexion_summary` (required per schema:57)
- `comprehension_gates.current_gate_required` (required per schema:101)

**Which failure mode does this expose:**
**Drift** — The "single source of truth" is incomplete. Between /apex:start step 3 and the planner completing step 6, STATE.json is invalid per its own schema. This is by design (progressive initialization), but the gap between the claim and reality is a documentation and testing issue.

**Evidence of impact:**
If validate-state.sh is run in strict mode immediately after /apex:start step 3, it will report multiple validation failures. Any tool or script that expects a schema-valid STATE.json in this window will fail. The claim "single source of truth" in the start.md comment is misleading to future maintainers.

**How to reproduce:**
```bash
# Count required root fields in schema
grep -c '"' framework/schemas/STATE.schema.json | head -1
# More precisely:
jq '.required | length' framework/schemas/STATE.schema.json
# Should return 31
# Count fields initialized by start.md
grep -c ":" framework/commands/apex/start.md | head -1
# Much fewer than 31
```

**Expected behavior:**
Either (a) start.md should initialize ALL required fields (even as null/0/false/empty), making STATE.json schema-valid from creation, or (b) the "CANONICAL STATE SHAPE" comment should be revised to say "initial partial state — completed by planner and architect stages" and validate-state.sh should have a "phase-aware" mode that knows which fields to expect at each stage.

**Recommended fix direction:**
Option (a) is simpler: add the missing fields with default values (null, false, 0, empty) to start.md's init block. This makes STATE.json always valid and removes the progressive-initialization window. Requires design discussion.

**Related to prior findings:**
New finding. Encompasses DEEP-SO-004 (context.last_compact).

**Verification notes:**
Verified against current state as of this audit. HIGH confidence — the gap between schema required fields and start.md init is quantifiable.

---

### DEEP-SF-003 — validate-state.sh does not support $ref resolution, cannot validate autonomy structure

**Severity:** P2
**Category:** Silent Failure
**Confidence:** HIGH
**File:** framework/scripts/validate-state.sh
**Lines:** 4, and framework/schemas/STATE.schema.json:75-78

**Current state (verbatim quote from file):**
validate-state.sh:4:
```
# Does NOT support: $ref resolution, allOf/anyOf/oneOf, complex regex, format.
```
STATE.schema.json:75-78:
```json
            "A": { "$ref": "#/definitions/autonomy_level" },
            "B": { "$ref": "#/definitions/autonomy_level" },
            "C": { "$ref": "#/definitions/autonomy_level" },
            "D": { "$ref": "#/definitions/autonomy_level" }
```

**The problem:**
STATE.schema.json uses `$ref` to define the autonomy.by_verify_level.A/B/C/D structure (lines 75-78, referencing `#/definitions/autonomy_level` at lines 340-348). validate-state.sh explicitly states it does not support `$ref` resolution (line 4). This means the autonomy nested structure — which has required fields (`level`, `consecutive_successes`) and type constraints — is NEVER validated, even when validate-state.sh runs.

**Which failure mode does this expose:**
**Quality Errors** — The autonomy ladder data can become malformed without detection. If `consecutive_successes` were accidentally set to a string, or `level` exceeded the maximum of 3, the validator would not catch it.

**Evidence of impact:**
A bug in the orchestrator sets `autonomy.by_verify_level.A.level = 5` (exceeding the max of 3). validate-state.sh runs but does not validate the $ref-based structure, so the invalid value persists. Downstream autonomy calculations (next.md:249-250) produce unexpected behavior.

**How to reproduce:**
```bash
grep -n "\$ref" framework/schemas/STATE.schema.json
# Lines 75-78: $ref for autonomy levels
grep -n "ref" framework/scripts/validate-state.sh
# Line 4 explicitly says $ref not supported
```

**Expected behavior:**
validate-state.sh should inline the `autonomy_level` definition and validate it directly, or implement basic $ref resolution for local definitions.

**Recommended fix direction:**
Add hardcoded validation for the autonomy structure in validate-state.sh: check that A, B, C, D exist, each has `level` (integer 0-3) and `consecutive_successes` (integer >= 0). This avoids implementing general $ref resolution.

**Related to prior findings:**
New finding.

**Verification notes:**
Verified against current state as of this audit. HIGH confidence.

---

### DEEP-AP-003 — Pipeline bypass logging is conditional on manual fix, not automatic (AP-5)

**Severity:** P2
**Category:** Anti-Pattern Instance (AP-5: Pipeline Bypass)
**Confidence:** MEDIUM
**File:** framework/commands/apex/next.md
**Lines:** 459-462

**Current state (verbatim quote from file):**
```
  ## PIPELINE BYPASS LOGGING [AP-005]
  ## If you fix the issue directly (without re-dispatching executor), log the bypass:
  bash ~/.claude/hooks/session-log.sh "bypass" "pipeline-bypass: direct fix for ${NEXT_UNIT} instead of reflexion→retry"
  ## This creates measurement data for AP-005 (Pipeline Bypass via Orchestrator Convenience).
```

**The problem:**
The pipeline bypass logging at next.md:459-462 is documented as a comment instruction ("If you fix the issue directly..."). This means the session-log call only fires if the orchestrator CHOOSES to follow the comment's instruction. The orchestrator (Claude) might fix the issue directly and proceed without noticing or following this logging instruction, because it's a comment rather than a mandatory step. This is the exact anti-pattern AP-5 warns about: a bypass that depends on voluntary compliance rather than automatic detection.

**Which failure mode does this expose:**
**Context Loss** — Pipeline bypasses may go unlogged, making it impossible to measure how often the orchestrator skips the executor→critic→reflexion cycle. Without measurement data, AP-5 cannot be quantified or addressed.

**Evidence of impact:**
The orchestrator encounters a task FAIL, reads the reflexion, and directly fixes the code without re-dispatching the executor. It skips the session-log call because the instruction is a comment, not a mandatory step. The session log has no record of the bypass. Post-mortem analysis cannot determine whether the task was retried properly or bypassed.

**How to reproduce:**
```bash
# Show the logging is in a comment block
sed -n '459,462p' framework/commands/apex/next.md
```

**Expected behavior:**
The bypass should be detected automatically (e.g., by checking if the executor was re-invoked after a FAIL verdict) rather than relying on the orchestrator to self-report.

**Recommended fix direction:**
This is a design challenge — the orchestrator IS the LLM, and there's no programmatic wrapper to enforce the logging. One approach: add a circuit-breaker-style check in the next /apex:next invocation that detects "last verdict was FAIL but no retry was recorded" and logs it retroactively. Requires design discussion.

**Related to prior findings:**
New finding. Instance of AP-5 (Pipeline Bypass via Orchestrator Convenience).

**Verification notes:**
Verified against current state as of this audit. MEDIUM confidence — the comment is clearly present, but the actual bypass behavior depends on the orchestrator's compliance with instructions.

---

### P3 — Low (4 findings)

---

### DEEP-SF-004 — context-monitor.sh 2>/dev/null on arithmetic test is ineffective

**Severity:** P3
**Category:** Silent Failure
**Confidence:** HIGH
**File:** framework/hooks/context-monitor.sh
**Lines:** 28

**Current state (verbatim quote from file):**
```
if [ "$TOTAL_INPUT" -gt 0 ] 2>/dev/null; then
```

**The problem:**
The `2>/dev/null` on line 28 attempts to suppress errors from the arithmetic comparison. However, `[ ... ]` (test) commands in bash do not write errors to stderr for non-numeric values — they simply fail with exit code 2. The `2>/dev/null` is ineffective and misleading, suggesting the author expected stderr output that doesn't occur. If `TOTAL_INPUT` is an empty string or non-numeric, the test silently fails and falls through to the else branch (heuristic fallback), which is correct behavior but for the wrong reason.

**Which failure mode does this expose:**
**Quality Errors** — Minor: the code works correctly by accident. The 2>/dev/null doesn't cause harm but indicates a misunderstanding of bash error behavior.

**Evidence of impact:**
Minimal. The code behaves correctly in all cases. This is a cosmetic issue.

**How to reproduce:**
```bash
grep -n "2>/dev/null" framework/hooks/context-monitor.sh
# Line 28: 2>/dev/null on test command
```

**Expected behavior:**
Remove the `2>/dev/null` or replace with explicit numeric validation: `if [[ "$TOTAL_INPUT" =~ ^[0-9]+$ ]] && [ "$TOTAL_INPUT" -gt 0 ]; then`

**Recommended fix direction:**
Remove `2>/dev/null` from line 28.

**Related to prior findings:**
New finding.

**Verification notes:**
Verified against current state as of this audit. HIGH confidence — bash test(1) behavior is well-documented.

---

### DEEP-DD-005 — pre-compact.sh backs up AUTONOMY.json which doesn't exist in framework

**Severity:** P3
**Category:** Documentation Drift
**Confidence:** HIGH
**File:** framework/hooks/pre-compact.sh
**Lines:** 21-25

**Current state (verbatim quote from file):**
```
if [ -f .apex/AUTONOMY.json ]; then
  if ! cp .apex/AUTONOMY.json ".apex/backups/AUTONOMY_$TIMESTAMP.json" 2>/dev/null; then
    echo "⚠️ Failed to back up AUTONOMY.json" >&2
    BACKUP_OK=false
  fi
fi
```

**The problem:**
pre-compact.sh:21 checks for and backs up `.apex/AUTONOMY.json`. However, this file is never created by any APEX command, hook, or agent. The autonomy data lives inside STATE.json (at `STATE.autonomy.by_verify_level`), not in a separate AUTONOMY.json file. This code block is vestigial — it references a file from an earlier design that was absorbed into STATE.json.

**Which failure mode does this expose:**
**Context Loss** — Minor: the dead code path never executes (the file doesn't exist), so there's no functional impact. However, it suggests incomplete cleanup from a design change and could confuse future maintainers.

**Evidence of impact:**
None — the `if [ -f .apex/AUTONOMY.json ]` check always fails because the file doesn't exist. The code is inert.

**How to reproduce:**
```bash
# Search for AUTONOMY.json creation
grep -rn "AUTONOMY.json" framework/
# Only found in pre-compact.sh — never created anywhere
```

**Expected behavior:**
Remove the AUTONOMY.json backup block from pre-compact.sh since the file is never created.

**Recommended fix direction:**
Delete lines 21-25 of pre-compact.sh.

**Related to prior findings:**
New finding.

**Verification notes:**
Verified against current state as of this audit. HIGH confidence.

---

### DEEP-SF-005 — next.md:186 suppresses git tag stderr with 2>/dev/null

**Severity:** P3
**Category:** Silent Failure
**Confidence:** HIGH
**File:** framework/commands/apex/next.md
**Lines:** 186

**Current state (verbatim quote from file):**
```
    git tag "apex/wave-${current_phase}-${CURRENT_WAVE}-complete" -m "Wave ${CURRENT_WAVE} coherence checked" 2>/dev/null
```

**The problem:**
next.md:186 creates a wave checkpoint git tag with `2>/dev/null`. If the tag creation fails (e.g., tag already exists from a retry, git in detached HEAD state), the error is silently suppressed. Compare to phase-tag.sh which explicitly captures and verifies tag creation with filesystem-level verification.

**Which failure mode does this expose:**
**Forgetting** — A failed wave tag creation goes unnoticed. The next wave-boundary coherence check (next.md:179) uses `last_wave_tag` for the diff range, which may reference a tag that doesn't exist.

**Evidence of impact:**
Low — wave tags are convenience checkpoints, not safety-critical. If a tag fails to create, the coherence check at the next wave boundary would still work via fallback mechanisms (HEAD comparison). But the tag reference in STATE.session.last_wave_tag (line 187) would point to a non-existent tag.

**How to reproduce:**
```bash
grep -n "2>/dev/null" framework/commands/apex/next.md | grep "tag"
# Line 186: git tag with stderr suppressed
# Compare to phase-tag.sh which verifies
grep -n "2>/dev/null" framework/hooks/phase-tag.sh
# Phase-tag uses full verification, not suppression
```

**Expected behavior:**
Either use phase-tag.sh for wave tags too, or at minimum check the exit code of the git tag command before recording the tag name in STATE.

**Recommended fix direction:**
Replace `2>/dev/null` with exit code checking: "If git tag fails, log warning to session-log.sh and do not update last_wave_tag."

**Related to prior findings:**
New finding.

**Verification notes:**
Verified against current state as of this audit. HIGH confidence.

---

### DEEP-DD-006 — next.md:372 git tag for task checkpoint suppresses errors with 2>/dev/null

**Severity:** P3
**Category:** Silent Failure
**Confidence:** HIGH
**File:** framework/commands/apex/next.md
**Lines:** 372

**Current state (verbatim quote from file):**
```
    git tag -a "$TASK_TAG" -m "APEX checkpoint: task ${NEXT_UNIT} passed critic" 2>/dev/null
```

**The problem:**
Similar to DEEP-SF-005, the task checkpoint tag at next.md:372 uses `2>/dev/null`. If this tag creation fails, the error is suppressed, but STATE.session.last_checkpoint_tag (line 377) is still updated with the tag name. This means the session state references a checkpoint tag that may not exist.

**Which failure mode does this expose:**
**Forgetting** — The checkpoint tag is used for recovery (/apex:recover). If the tag doesn't exist but STATE claims it does, recovery would fail.

**Evidence of impact:**
Moderate but unlikely — git tag creation rarely fails in normal operation. The most likely failure case is duplicate tag names from retry cycles.

**How to reproduce:**
```bash
sed -n '371,378p' framework/commands/apex/next.md
```

**Expected behavior:**
Check git tag exit code before updating last_checkpoint_tag, or use phase-tag.sh's filesystem verification pattern.

**Recommended fix direction:**
Add exit code check: "If git tag fails, log warning; do NOT update last_checkpoint_tag."

**Related to prior findings:**
Related to DEEP-SF-005 (same pattern at wave level).

**Verification notes:**
Verified against current state as of this audit. HIGH confidence.

---

## State File Analysis (Pass 6 Results)

### STATE.json: Schema Required Fields vs. Initialization

The STATE.schema.json defines 31 required root-level fields. start.md initializes approximately 14 of these directly, with the remainder filled by subsequent pipeline stages.

| Required Field | Schema Type | Initialized by start.md | Filled by | Notes |
|----------------|-------------|-------------------------|-----------|-------|
| project | string | NO | planner (step 6) | |
| complexity_level | integer 0-4 | NO | planner (step 6) | |
| complexity_name | string | NO | planner (step 6) | |
| pipeline | array[string] | NO | planner (step 6) | |
| apex_version | string "v7" | YES (line 43) | — | |
| current_stage | string | NO | start.md (step 7) | Filled AFTER planner |
| pre_build_complete | boolean | NO | NEVER | ⚠️ Never initialized |
| current_phase | string\|null | NO | next.md:147 | Filled at architect stage |
| current_unit | string\|null | NO | next.md | Filled during build |
| current_wave | integer\|null | NO | next.md:147 | Filled at architect stage |
| status | string | NO | start.md (step 7) | Filled AFTER planner |
| reflexion | object | YES (line 44) | — | Missing: last_reflexion_summary |
| context | object | YES (line 48) | — | Missing: last_compact, session_start_time |
| circuit_breaker | object | YES (line 52) | — | ⚠️ trigger_reason NOT in schema |
| snapshots | object | YES (line 53) | — | |
| tokens | object | YES (line 49) | — | ⚠️ productive NOT in schema |
| health_check | object | NO | NEVER (only by /health-check) | ⚠️ Required but never auto-initialized |
| evoscore | object | YES (line 45) | — | |
| comprehension_gates | object | YES (line 46) | — | Missing: current_gate_required |
| tdad | object | YES (line 47) | — | Missing: last_indexed, total_nodes |
| phase_tags | object | YES (line 50) | — | |
| stack_skills | array | YES (line 51) | — | |
| autonomy | object | NO | next.md:154-157 | Filled at architect stage |
| autopilot | object | YES (lines 54-76) | — | Complete init |
| session | object | YES (lines 77-91) | — | Complete init |
| phases_total | integer | NO | next.md | Filled at architect stage |
| phases_completed | integer | NO | next.md | Filled at phase complete |
| units_total | integer | NO | next.md | Filled at architect stage |
| units_completed | integer | NO | next.md | Filled at task complete |
| lock | string\|null | NO | NEVER | ⚠️ Never explicitly initialized |
| created_at | datetime | NO | NEVER | ⚠️ Never initialized |
| updated_at | datetime | NO | NEVER | ⚠️ Never initialized |

**Key observations:**
- 5 required fields are NEVER initialized by any command: `pre_build_complete`, `health_check`, `lock`, `created_at`, `updated_at`
- 4 sub-fields within initialized objects are missing from start.md: `context.last_compact`, `context.session_start_time`, `tdad.last_indexed`, `tdad.total_nodes`, `reflexion.last_reflexion_summary`, `comprehension_gates.current_gate_required`
- 2 fields are written to STATE.json that don't exist in the schema: `circuit_breaker.trigger_reason` (by circuit-breaker.sh), `pending_notifications` and `tokens.productive` (by next.md)
- The progressive initialization is by design but creates a window where STATE.json is schema-invalid

### STATE.json: Writers and Readers

| Component | Writes to STATE.json via | Fields Written |
|-----------|------------------------|----------------|
| start.md | Direct JSON construction | Initial ~14 fields |
| planner.md | Orchestrator instruction | project, complexity_level, complexity_name, pipeline, stack_skills |
| next.md | Orchestrator instruction | current_stage, status, current_phase, current_wave, autonomy, tdad, tokens, session, pending_notifications |
| circuit-breaker.sh | `_state_update` | circuit_breaker.* + trigger_reason |
| context-monitor.sh | `_state_update` | context.estimated_context_usage_pct |
| cross-phase-audit.sh | `_state_update` | evoscore.regression_rate, total_cross_phase_tests, last_full_audit |
| mutation-gate.sh | `_state_update` | mutation_scores |
| phase-tag.sh | `_state_update` | phase_tags |
| pre-task-snapshot.sh | `_state_update` | snapshots.pre_task_stash, snapshots.last_snapshot_task |
| resume.md | Orchestrator instruction | context.*, autopilot.*, session.* |

**Key observation:** All hook writes go through `_state_update` (atomic jq-based updater). Orchestrator writes (from .md commands) are instructions for Claude — they don't go through `_state_update` and have no validation. The schema is never checked at write time.

### RESULT.json and PLAN_META.json: Schema Consistency

**RESULT.json** (written by executor, read by critic):
- Schema defines 15 required fields (RESULT.schema.json)
- Executor.md:128-147 documents all 15 fields in its output template
- Critic.md:13 reads only `tests_run` and `verify_commands_run` from RESULT.json
- No validation hook exists for RESULT.json — the executor is trusted to produce valid output
- If executor omits a required field, critic won't detect it (critic only reads 2 of 15 fields)

**PLAN_META.json** (written by architect, read by many):
- Schema defines task structure with files[], verify_commands[], done_criteria[], etc.
- Architect.md:61-66 documents PLAN_META.json creation
- Read by: cross-phase-audit.sh (verify_commands), generate-task-map.sh (files), resume.md (verify_level, specialist), next.md (multiple fields), verifier.md (all fields)
- No validation hook exists — architect is trusted to produce valid output

**CONTEXT_BUDGET.json** (created by start.md, read by context-monitor.sh):
- Schema defines zones, thresholds, rotation_triggers, per_agent_limits
- start.md:92 says "copy from ~/.claude reference or use v7 defaults" — no explicit creation code
- context-monitor.sh reads only thresholds (proactive_compact_pct, hard_rotate_pct)
- No validation — if CONTEXT_BUDGET.json is malformed, context-monitor.sh falls back to hardcoded defaults (lines 18-19: `// 55` and `// 70`)

### validate-state.sh: Coverage Gaps

The validator (207 lines) implements a JSON Schema subset:
- ✅ Root type checking (object)
- ✅ Required fields (root level)
- ✅ Type checking (with integer/number coercion)
- ✅ Enum constraints (root level)
- ✅ additionalProperties (root level)
- ✅ Nested required fields (one level deep)
- ❌ $ref resolution — autonomy levels NOT validated (DEEP-SF-003)
- ❌ format constraints — datetime strings NOT checked
- ❌ minimum/maximum ranges — numbers NOT range-checked
- ❌ Deeply nested (2+ levels) required fields
- ❌ Pattern matching

Additionally, the validator is called with `--soft` mode by pre-task-snapshot.sh:19, meaning failures produce warnings but don't block operations. This makes the validation purely informational.

---

## Pipeline Traces (Pass 7 Results)

### /apex:next — Full Pipeline (653 lines)

```
 1. Read STATE.json
 2. bash context-monitor.sh → exit 2: STOP | exit 1: /compact | exit 0: continue
 3. SESSION GUARDIAN: if no STATE.session → initialize session object + session-log.sh
 4. SESSION HEALTH CHECK: compute error rate, partial rate → green/yellow/red
    If red → auto-pause + session-log.sh + STOP
 5. Read apex-model-routing.json (optional)
 6. [pre-build gate] Read pre-build/STATUS.json → if blocking: STOP
 7. [spec gate] Show SPEC.md → user approves
 8. [architect gate] Build ARCHITECT_CONTEXT → Task("architect") → PLAN_META.json + WAVE_MAP.json
 9. bash tdad-index.sh → Update STATE (⚠️ DEEP-DD-001: unconditionally sets index_built=true)
10. [build gate] Check context rotation need
11. STEP A: Read WAVE_MAP.json (⚠️ DEEP-AP-002: no existence check) → get NEXT_UNIT
    Wave boundary: run project tests, check regressions, git tag wave
12. STEP B: bash generate-task-map.sh → TASK_MAP.md
    If tdad.index_built: python3 tdad-impact.py → IMPACTED_TESTS.txt
13. STEP C: If task.is_irreversible → source _debate.md
14. STEP D: If retry (ATTEMPTS > 0) → load REFLEXION.md
15. STEP E: Build EXECUTOR_CONTEXT (zone-based)
    Token check (⚠️ described but implementation left to orchestrator)
16. STEP F: bash pre-task-snapshot.sh → exit 2: prompt user | exit 0: continue
17. STEP G: Autonomy check → if level 0: show plan + ask | if level 1+: auto-execute
    Task("[agent]") → RESULT.json + SUMMARY.md → update tokens
18. PHANTOM CHECK: bash phantom-check.sh → exit 2: synthesize CRITIC.md FAIL (⚠️ DEEP-DD-002: no session-log)
19. CLEAN-ROOM CRITIC: if not phantom_skip → build CRITIC_CONTEXT → Task("critic")
    Security persona for D-level/security tasks
    (⚠️ DEEP-DD-004: phantom skip → no overhead tracking)
20. PROCESS VERDICT:
    PASS → reset reflexion, autonomy++, git tag checkpoint, session-log
           mutation-gate for C/D, autopilot state update, mini cross-phase every 5 tasks
    PARTIAL → advance with advisory, session update
    FAIL → reflexion, session update, autopilot pause
           (⚠️ DEEP-AP-003: bypass logging is conditional)
           If 3 attempts → BLOCKED
21. LEARNING EXTRACTION: on FAIL/PARTIAL → append to apex-learnings.md
22. [verify_needed gate] Phase verification:
    Complexity ≤2 → bash cross-phase-audit.sh + Task("critic") phase-level
    Complexity >2 → Task("verifier")
    (⚠️ DEEP-SO-006: regression_rate scale mismatch)
23. OVERHEAD CHECK: if >15% → notification
24. PHASE PASS → bash phase-tag.sh, autopilot phase tracking
    (⚠️ DEEP-DD-003: drift check doesn't update drift_indicators)
    Comprehension gate + recommend /apex:resume
25. [complete gate] → Render Project Complete Ceremony
```

### /apex:quick — Abbreviated Pipeline (64 lines)

```
 1. INPUT GUARD: require target identifier + action verb → reject if missing
 2. TASK_ID="quick-$(date +%s)", mkdir .apex/phases/quick/
 3. bash pre-task-snapshot.sh → exit 2: prompt user | exit 0: continue
 4. bash generate-task-map.sh
 5. Read SPEC.md, DECISIONS.md, TASK_MAP.md
 6. Determine specialist, build context with CONTEXT_BUDGET.json limits
 7. Task("[agent]") → execute task
 8. Task("critic") → diff-based review
 9. If FAIL and attempts < 2: retry executor + critic
10. bash phantom-check.sh on SUMMARY.md
11. Update learnings, tokens
```

No findings specific to quick.md beyond those already in next.md's pipeline. The pre-task-snapshot call at line 31 was confirmed present (known-fixed C-2).

### /apex:micro — Minimal Pipeline (45 lines)

```
 1. INPUT GUARD: require explicit file path + concrete verb + target
 2. bash pre-task-snapshot.sh micro → git stash for rollback
 3. Read SPEC.md, DECISIONS.md, CLAUDE.md
 4. Task("executor") → execute micro-task, commit
 5. Verify: git diff HEAD~1 --stat → zero changes = warning
 6. Update tokens
 7. NOTE: No critic, no phantom check, no TDAD
```

Intentionally minimal. The git stash provides the safety net. No additional findings.

### /apex:resume — Session Restart Pipeline (143 lines)

```
 1. Read STATE.json, COMPLEXITY.md, SPEC.md, DECISIONS.md
 2. AUTO-PAUSE RECOVERY: if auto_paused → reset counters, set green
 3. SESSION UPDATE: total_context_rotations++, session-log.sh "resume"
 4. Update STATE.context (⚠️ DEEP-SO-001: session_started vs session_ended)
 5. DISPLAY: Render transition, status bar, autopilot badge, cockpit frame
 6. AUTOPILOT CHECK: if enabled → consecutive_sessions++
 7. CIRCUIT BREAKERS (1-4):
    B1: session loop (same task across 2+ sessions)
    B2: phase stall (no progress across 3 sessions)
    B3: human checkpoint (every 3 phases)
    B4: mode-specific (until/range/after/smart)
    If any fires → pause autopilot + STOP
 8. After breakers: refresh previous_* snapshot fields (only on success path)
 9. Source and follow next.md (auto-continue)
```

### /apex:start — Project Initialization (97 lines)

```
 1. ENVIRONMENT PRECHECK: check jq, git, rg → STOP if missing
 2. INFRASTRUCTURE SELF-TEST: bash self-test.sh → warn if failures
 3. Check existing STATE.json → if exists: "Project in progress" → STOP
 4. Render Section 5 banner
 5. mkdir -p .apex/{pre-build,phases,backups,debate-log,comprehension-gates}
 6. USER PROFILE CAPTURE: technical level + language → write to CLAUDE.md
 7. Create STATE.json (⚠️ DEEP-SO-005: missing 17 required fields)
 8. Create CONTEXT_BUDGET.json (copy from ~/.claude reference)
 9. bash session-log.sh "resume" "סשן התחיל"
10. Task("planner") → classify, capture requirements
11. Update STATE: current_stage, status based on complexity level
```

### /apex:health-check — Validation Suite (191 lines)

```
 1. TEST 0a: Check jq, git, rg available
 2. TEST 0b: Verify _require-jq.sh sources cleanly
 3. TEST 0c: Verify 9 jq-dependent hooks source _require-jq.sh + tdad-impact.py exists
 4. TEST 0e: bash self-test.sh
 5. TEST 0f: Schema validation with good/bad test fixtures
 6. SETUP: Create temp git repo
 7. TEST 1: Critic secret detection (real file with hardcoded API key)
 8. TEST 2: Critic hallucination guard (empty diff)
 9. TEST 3: Critic phantom verification (uncertainty language in SUMMARY.md)
10. TEST 4: Critic silent failure (catch-and-log pattern)
11. TEST 5: Architect learnings application (PATTERN-003)
12. TEST 6: Architect verify_level assignment (webhook = D)
13. TEST 7: Executor named failure mode (no phantom language)
14. TEST 8: Security specialist SQL injection detection
15. TEST 9: Critic clean-room compliance (contaminated vs clean contexts)
16. CLEANUP: rm -rf temp dir
17. Write results to .apex/health-check-[date].md + update STATE.json
```

No findings in health-check.md. The 0c test correctly checks only jq-dependent hooks (not all hooks).

### /apex:status — Dashboard Renderer (80 lines)

```
 1. Read apex-branding.md
 2. Render Glass Cockpit: Section 10-D + 10-E from SESSION-LOG.md
 3. Read STATE.json → extract all dashboard values
 4. Render Section 6 (Cockpit Dashboard) with substitutions
 5. Render signature line
 6. If autopilot disabled: hint to enable | enabled: show badge | paused: show badge
```

Note: status.md uses display labels like `STATE.project_name` and `STATE.level_name` which don't exactly match schema field names (`project`, `complexity_name`). These are prompt instructions for the LLM, not literal jq paths, so the LLM would interpret them correctly. Not classified as a finding.

### /apex:pause — State Save (28 lines)

```
 1. Update STATE.json: status, pause metadata
 2. bash pre-compact.sh (⚠️ DEEP-SF-001: always exits 0)
 3. Display summary
```

### /apex:recover — Recovery Menu (15 lines)

```
 1. Check .apex/STATE.json.lock → if lock exists + process dead: show menu
 2. Options:
    (1) Clear lock and resume
    (2) Restore STATE from backup
    (3) Revert to last checkpoint tag
    (4) Reset circuit breaker
    (5) Revert to last phase tag and re-plan
```

Minimal implementation — intentionally a menu rather than automated recovery.

---

## Findings by Category

| Category | IDs | Count |
|----------|-----|-------|
| State Drift | DEEP-SO-001, DEEP-SO-002, DEEP-SO-003, DEEP-SO-004, DEEP-SO-005, DEEP-SO-006 | 6 |
| Silent Failure | DEEP-SF-001, DEEP-SF-002, DEEP-SF-003, DEEP-SF-004, DEEP-SF-005 | 5 |
| Documentation Drift | DEEP-DD-001, DEEP-DD-002, DEEP-DD-003, DEEP-DD-004, DEEP-DD-005, DEEP-DD-006 | 6 |
| Environment Dependency Gap | DEEP-ED-001 | 1 |
| Anti-Pattern Instance | DEEP-AP-001, DEEP-AP-002, DEEP-AP-003 | 3 |

**Total: 21 findings** (0 P0, 8 P1, 9 P2, 4 P3)

## Settings & Wiring Audit (Pass 8 Results)

### ~/.claude/settings.json Hook Configuration

The deployed settings.json wires 6 APEX hooks (plus 2 GSD hooks out of scope):

```json
"hooks": {
    "PreToolUse": [
        { "matcher": "Bash", "hooks": [{ "command": "bash ~/.claude/hooks/destructive-guard.sh" }] }
    ],
    "PostToolUse": [
        { "matcher": "Write|Edit", "hooks": [{ "command": "bash ~/.claude/hooks/post-write.sh" }] },
        { "matcher": "Bash", "hooks": [{ "command": "bash ~/.claude/hooks/circuit-breaker.sh" }] }
    ],
    "SubagentStop": [
        { "hooks": [{ "command": "bash ~/.claude/hooks/subagent-stop.sh" }] }
    ],
    "PreCompact": [
        { "hooks": [{ "command": "bash ~/.claude/hooks/pre-compact.sh" }] }
    ],
    "SessionStart": [
        { "hooks": [{ "command": "bash ~/.claude/hooks/verify-learnings.sh" }] }
    ]
}
```

### Wiring Audit Results

| Check | Result |
|-------|--------|
| All wired hooks exist at declared paths | ✅ All 6 exist in ~/.claude/hooks/ |
| No stderr suppression in wiring | ✅ No `2>/dev/null` in settings.json |
| No exit-code masking in wiring | ✅ No `\|\| true` in settings.json |
| Events match hook purpose | ✅ All correct (see below) |
| Hooks that should be wired ARE wired | ✅ (see analysis below) |

### Event-to-Hook Mapping Verification

| Hook | Event | Correct? | Rationale |
|------|-------|----------|-----------|
| destructive-guard.sh | PreToolUse (Bash) | ✅ | Must intercept BEFORE dangerous commands run |
| post-write.sh | PostToolUse (Write\|Edit) | ✅ | TypeScript/secret checks run AFTER file is written |
| circuit-breaker.sh | PostToolUse (Bash) | ✅ | Counts tool calls AFTER each bash execution |
| subagent-stop.sh | SubagentStop | ✅ | Validates agent output when agent session ends |
| pre-compact.sh | PreCompact | ✅ | Backs up state BEFORE context compaction |
| verify-learnings.sh | SessionStart | ✅ | Validates learnings at session beginning |

### Hooks NOT Wired in Settings (Called Explicitly by Commands)

These hooks are invoked directly by command .md files via `bash ~/.claude/hooks/...` rather than through settings.json events. This is intentional — they run at specific pipeline steps, not on every tool call:

| Hook | Called by | Why not wired |
|------|-----------|---------------|
| context-monitor.sh | next.md:35 | Runs at start of /apex:next only, not every tool call |
| cross-phase-audit.sh | next.md:399,479; verifier.md:41 | Runs at wave/phase boundaries only |
| generate-task-map.sh | next.md:192; quick.md:38 | Runs before task execution only |
| mutation-gate.sh | next.md:384 | Runs after C/D task critic pass only |
| phantom-check.sh | next.md:282; quick.md:62 | Runs after executor, before critic only |
| phase-tag.sh | next.md:506; verifier.md:46 | Runs on phase completion only |
| pre-task-snapshot.sh | next.md:237; quick.md:31; micro.md:24 | Runs before task execution only |
| session-log.sh | Multiple locations in next.md, resume.md, start.md | Logging at specific events, zero overhead |
| tdad-index.sh | next.md:145 | Runs at architect stage only |

### Framework/Settings.json — Design Note

There is no `framework/settings.json` to compare against the deployed `~/.claude/settings.json`. This is by design: settings.json is user-configurable and contains non-APEX hooks (GSD), permissions, and environment variables. The sync-to-claude.sh script (lines 17-18) explicitly states it is "Scoped to APEX — non-APEX files (GSD agents, user hooks, settings.json) are never touched." This creates an audit gap — there is no source-of-truth for the APEX hook wiring other than the deployed file itself — but it is an intentional design choice to prevent sync from overwriting user customizations.

---

## Anti-Pattern Instances

### AP-1: Silent Install Failure
- **DEEP-DD-001** (P1): tdad-index.sh exits 0 when python3 missing; orchestrator still sets index_built=true
- **DEEP-AP-001** (P2): tdad-impact.py bare `except:` silently swallows all errors

### AP-3: Implicit Write Chain
- **DEEP-AP-002** (P2): WAVE_MAP.json and PLAN_META.json read without existence validation after architect creates them

### AP-4: Schema-by-Memory Reconstruction
- **DEEP-SO-002** (P1): next.md writes pending_notifications and tokens.productive — fields not in schema
- **DEEP-SO-003** (P1): circuit-breaker.sh writes trigger_reason — field not in schema
- **DEEP-SO-005** (P2): start.md init template is incomplete vs. schema — progressive initialization without validation
- **DEEP-SO-006** (P1): cross-phase-audit.sh writes regression_rate as 0-100 integer but schema expects 0-1 float

### AP-5: Pipeline Bypass via Orchestrator Convenience
- **DEEP-AP-003** (P2): Pipeline bypass logging depends on orchestrator voluntary compliance, not automatic detection

### AP-6: The Unchecked Audit
No instances found. No code or documentation references prior audit findings as authoritative without verification.

### New Anti-Pattern Candidate: AP-7 — Asymmetric State Tracking
**Shape:** Two code paths that produce the same logical outcome (e.g., task FAIL) but update different state fields, creating inconsistent measurements.
**Instances:**
- **DEEP-DD-003** (P2): Wave-level drift increments spec_drift_count; phase-level drift does not
- **DEEP-DD-004** (P2): Normal critic updates framework_overhead; phantom-skip does not

## Regressions Detected

**Zero regressions detected.** All 12 previously-closed items from Rounds 3.0–3.7 and 4–5 are confirmed fixed:

| ID | Description | Status | Verification |
|----|-------------|--------|--------------|
| F-1 | v6/v7/v8 drift | FIXED | All framework files consistently use v7. grep confirmed. |
| A-1 | apex-model-routing missing agents | FIXED | apex-model-routing.json contains all 9 agents (5 core + 4 specialist by exact name). |
| A-9 | Branding cards contradict routing | FIXED | Branding and routing are consistent (verified via grep). |
| B-4 | subagent-stop git misattribution | FIXED | subagent-stop.sh has 3-way exit: 0=valid, 1=git error (advisory), 2=hallucination. Verified at lines 15, 29, 34, 40. |
| C-3 | phantom-check missing in /apex:next | FIXED | phantom-check.sh called at next.md:282. |
| C-14 | critic phantom-scan ambiguity | FIXED | critic.md:59-60 explicitly scopes phantom scan to RESULT.json fields only, with clear note that SUMMARY.md is handled upstream. |
| B-1 | phase-tag silent fail | FIXED | phase-tag.sh:27-35 implements filesystem-level verification pattern with `git tag -l` check. |
| C-2 | /apex:quick missing snapshot | FIXED | quick.md:31 calls pre-task-snapshot.sh. Exit code 2 handling at lines 32-36. |
| A-5 | resume.md breakers non-existent fields | FIXED | start.md:71-72 initializes previous_last_completed_task and previous_tasks_completed_in_autopilot. resume.md:74-76 reads them correctly. |
| E-6 | specialists discovery | FIXED | 4 specialist agents in framework/agents/specialist/ directory, all deployed to ~/.claude/agents/specialist/. |
| verify-ladder-check.sh | should be DELETED | FIXED | grep found no file with this name in framework/. |
| researcher.md | should be DELETED | FIXED | grep found no file with this name in framework/. |

## Cross-Reference to Prior Audit

All 12 items from AUDIT-2026-04-09.md that were marked as closed in Rounds 3.0–5 remain closed. See "Regressions Detected" section above for per-item verification.

### Detailed Verification of Each Known-Fixed Item

| ID | Original Issue | Fix Applied In | Current Evidence | Status |
|----|---------------|----------------|------------------|--------|
| F-1 | v6/v7/v8 version drift | Round 3.1 | `grep -rn "v[5-8]" framework/` shows all v7 references. Schema apex_version enum = ["v7"]. Test at test-schemas.sh:4 validates. | CONFIRMED FIXED |
| A-1 | apex-model-routing missing agents | Round 3.0 | apex-model-routing.json contains 9 entries: planner, architect, executor, critic, verifier, integration-specialist, security-specialist, data-specialist, frontend-specialist. Each maps to an existing .md file. | CONFIRMED FIXED |
| A-9 | Branding cards contradict routing | Round 3.0 | Branding.md uses same agent names as routing. No contradictions found. | CONFIRMED FIXED |
| B-4 | subagent-stop git misattribution | Round 3.0 | subagent-stop.sh lines 15 (exit 2: zero tool calls), 29 (exit 1: git error advisory), 34 (exit 2: no changes), 40 (exit 0: validated). Clean 3-way exit with comments explaining each path. | CONFIRMED FIXED |
| C-3 | phantom-check missing in /apex:next | Round 3.0 | next.md:282 calls `bash ~/.claude/hooks/phantom-check.sh`. Full handler for exit codes 0, 1, 2 at lines 285-319. | CONFIRMED FIXED |
| C-14 | critic phantom-scan ambiguity | Round 3.5 | critic.md:52-59 explicitly lists which fields to scan (RESULT.json tests_run[].output, verify_commands_run[].output, new code comments). Line 59 clarifies: "Do NOT scan: task_spec, done_criteria_checked.evidence, modified_files." Line 60 notes SUMMARY.md is handled upstream. | CONFIRMED FIXED |
| B-1 | phase-tag silent fail | Round 3.0 | phase-tag.sh:26-35 implements filesystem verification: after `git tag -a`, runs `git tag -l "$TAG_NAME" | grep -qF "$TAG_NAME"` to confirm the tag exists. Only updates STATE.json after verification (line 30). Exits 2 with diagnostic output on verification failure (lines 37-42). | CONFIRMED FIXED |
| C-2 | /apex:quick missing snapshot | Round 3.0 | quick.md:31 calls `bash ~/.claude/hooks/pre-task-snapshot.sh "$TASK_ID"`. Exit code 2 handling at lines 32-36 with user prompt for abort/proceed. | CONFIRMED FIXED |
| A-5 | resume.md breakers non-existent fields | Round 3.2 | start.md:71-72 initializes `previous_last_completed_task: null` and `previous_tasks_completed_in_autopilot: 0`. resume.md:74-76 reads both fields. resume.md:134-136 updates them on the success path (no breaker tripped), with explicit comment explaining why this ordering matters (lines 125-132). | CONFIRMED FIXED |
| E-6 | specialists discovery | Round 3.0 | framework/agents/specialist/ contains data.md, frontend.md, integration.md, security.md. All deployed to ~/.claude/agents/specialist/. next.md:264 routes by specialist field. | CONFIRMED FIXED |
| — | verify-ladder-check.sh should be DELETED | Round 3.2 | `grep -rn "verify-ladder-check" framework/` returns zero results. File does not exist. | CONFIRMED FIXED |
| — | researcher.md should be DELETED | Round 3.0 | `grep -rn "researcher" framework/agents/` returns zero results. File does not exist. | CONFIRMED FIXED |

Additionally, this audit found 21 new findings that were not identified in the prior audit. The most significant new category is **schema-state consistency** (DEEP-SO-001 through DEEP-SO-006), which represents a systemic gap rather than isolated bugs. The prior audit focused primarily on missing files, broken wiring, and pipeline gaps — all of which have been fixed. The remaining issues are in the contract layer (schema) rather than the execution layer (hooks and commands).

## Confidence Summary

| Confidence | Count | Findings |
|------------|-------|----------|
| HIGH | 19 | DEEP-SO-001, SO-002, SO-003, SO-004, SO-005, SO-006, SF-001, SF-002, SF-003, SF-004, SF-005, DD-001, DD-002, DD-003, DD-004, DD-005, DD-006, ED-001, AP-001 |
| MEDIUM | 2 | DEEP-AP-002, AP-003 |
| LOW | 0 | — |

**MEDIUM confidence findings — runtime verification needed:**
- **DEEP-AP-002**: The LLM orchestrator may naturally check file existence before reading. Runtime test: run /apex:next on a project where architect was interrupted before creating WAVE_MAP.json, and observe whether the orchestrator handles it gracefully.
- **DEEP-AP-003**: The pipeline bypass logging depends on whether the LLM follows comment instructions. Runtime test: observe an actual FAIL verdict scenario and check whether the session-log bypass entry appears.

## Auditor's Self-Critique

### Limitations of This Audit

1. **Static analysis only.** No hooks were executed at runtime. All behavioral claims are inferred from code reading. This means:
   - I cannot confirm whether the `2>/dev/null` suppressions in practice cause observable failures
   - I cannot confirm whether the LLM orchestrator follows all pseudocode instructions faithfully
   - I cannot confirm whether schema validation errors cause runtime problems or are silently absorbed
   - I cannot confirm whether the autonomy escalation logic (next.md:365-366) behaves as intended when consecutive_successes reaches the cap

2. **Agent files received thorough but not equal attention to hooks.** I read all 9 agent .md files (5 core + 4 specialist) completely. Hooks received the deepest analysis because they contain executable code with deterministic behavior. Agent files are LLM prompts with interpretive behavior — findings depend on whether the LLM follows instructions faithfully. Specific areas I examined:
   - **architect.md**: Verified PLAN_META.json and WAVE_MAP.json creation steps (lines 61-73), learnings loading rules (lines 10-14), verification ladder (lines 75-77). No issues found — the agent's instructions are clear and well-structured.
   - **verifier.md**: Verified Phase Completion Invariant (lines 10-16), cross-phase-audit.sh call (line 41), phase-tag.sh call (line 46). The Rendering Gap check at line 11 is a strong anti-hallucination guard. No issues found.
   - **planner.md**: Verified complexity classification (lines 14-18), STATE.json field updates (line 22), pre-build flow (lines 39-42). The planner writes `complexity_level`, `complexity_name`, `pipeline`, `stack_skills` to STATE.json — these are the first batch of fields missing from start.md init (DEEP-SO-005), and planner.md:22 is where they're supposed to be filled. This is consistent with the progressive initialization design.
   - **critic.md**: Verified clean-room protocol (lines 7-16), filesystem verification rules (lines 24-30), phantom scan scope (lines 52-59). C-14 fix confirmed: line 59-60 explicitly scopes phantom scanning. No issues found.
   - **executor.md**: Verified trajectory monitoring (lines 75-87), observation masking (lines 89-93), RESULT.json output format (lines 128-147), anti-rationalization table (lines 184-206). The `git add -A` at line 182 adds all files, which could include unintended files, but this is standard APEX workflow.

3. **Pass 7 (Pipeline Tracing) proportionality assessment.** next.md is 653 lines. I traced every major path:
   - **All 5 stage gates** (pre-build, spec, architect, build, complete) — verified state transitions
   - **All 4 verdict paths** (PASS, PARTIAL, FAIL, BLOCKED) — verified state updates and branching
   - **3 special paths** (phantom-check skip, wave boundary, phase boundary) — found 3 findings
   - **Autopilot advisor** (lines 558-641) — verified mode options and state updates, no findings
   - **Session Guardian** (lines 43-61) — verified session initialization, no findings
   - I found 9 findings from pipeline tracing (DD-001 through DD-006, SO-006, AP-002, AP-003). This is proportional — next.md's structure is well-organized with clear pseudocode, and most of its length is correct. The findings cluster around state updates and edge-case paths rather than core logic.

4. **Pass 9 (Anti-Pattern Hunt) depth assessment.**
   - **AP-1 (Silent Install Failure):** Found 2 instances (DD-001 tdad/python3, AP-001 tdad-impact.py bare except). I examined all tool guards across all hooks — jq, git, rg, python3, npx, stryker/mutmut are all checked. The remaining silent failures are in the ORCHESTRATOR's handling of hook exit codes, not in the hooks themselves.
   - **AP-3 (Implicit Write Chain):** Found 1 explicit instance (AP-002 WAVE_MAP/PLAN_META). I acknowledge this may be under-sampled. Additional implicit chains exist: executor→RESULT.json→critic, executor→SUMMARY.md→phantom-check, architect→PLAN.md→executor. I focused on the architect→WAVE_MAP chain because it's the only one where the writing agent (architect) is a separate invocation from the reading code (Step A). The executor→RESULT.json→critic chain is tighter (same pipeline invocation), making failures more visible. Future audits could examine: what happens if executor creates RESULT.json but not SUMMARY.md? What if SUMMARY.md exists from a prior attempt with stale content?
   - **AP-4 (Schema-by-Memory Reconstruction):** Found 4 instances (SO-002, SO-003, SO-005, SO-006). This is the strongest finding category — the schema and code have multiple points of divergence. I believe I have captured the most significant instances, but there may be additional sub-field mismatches in deeply nested objects (e.g., tokens.by_agent structure, PLAN_META task sub-fields).
   - **AP-5 (Pipeline Bypass):** Found 1 instance (AP-003 conditional logging). The phantom-check synthetic CRITIC.md at next.md:299-308 is technically also a bypass (critic never runs), but it's INTENTIONAL and documented. The only unintentional bypass risk is the voluntary logging at lines 459-461.

5. **Test files and fixtures not deeply audited.** The framework/tests/ directory and framework/test-fixtures/ directory contain test infrastructure. I referenced test-schemas.sh to verify version checks and test-fixtures/STATE-good.json for fixture completeness, but did not audit the test suite for coverage gaps, false positives, or missing edge cases.

6. **Encoding, line endings, and file permissions not verified.** I did not check CRLF vs LF, BOM presence, file encodability, or executable bits. Given the Windows+OneDrive+Git Bash environment, mixed line endings are plausible but would only affect shell scripts (which Git typically auto-converts via .gitattributes).

7. **sync-to-claude.sh and DEV-FLOW.md received light attention.** I read sync-to-claude.sh (160 lines) and confirmed it's well-hardened (set -euo pipefail, additive-only by default, scoped to APEX files). DEV-FLOW.md (88 lines) is developer documentation and was checked for consistency but not deeply traced. Neither produced findings.

8. **Honest findings count.** I identified 21 findings across a 72-file framework that has undergone 8+ rounds of fixes (3.0-3.7, 4, 4.1, 5). The count breaks down as:
   - **Schema-state consistency** (6 findings, SO series): This is a systemic pattern, not 6 independent bugs. The root cause is that code evolves faster than the schema, and the validator runs in soft mode.
   - **Silent failures** (5 findings, SF series): Most are defensive 2>/dev/null patterns that are technically correct but create maintenance risk. The only operationally impactful one is pre-compact.sh (SF-001).
   - **Documentation drift** (6 findings, DD series): These are gaps between what the pseudocode documents and what the state tracking actually records. They affect audit trails more than functionality.
   - **Environment/anti-patterns** (4 findings): Edge-case risks.

   The framework's core safety mechanisms work well. destructive-guard.sh (179 lines) is comprehensive with quote-aware command splitting. subagent-stop.sh has clean 3-way exit codes. pre-task-snapshot.sh uses filesystem-level verification. phase-tag.sh verifies tags via `git tag -l`. These are the framework's strengths and produced zero findings. The weakness is schema governance — the gap between the contract (STATE.schema.json) and the implementation (hooks and commands that write to STATE.json).

## Cross-Check Against Known Runtime Behavior (Pass 10)

The engagement brief references a real-world APEX run on a test project called "Shield" with specific observed behaviors. This section cross-checks audit findings against those observations.

### Observation: STATE.json observed empty and reconstructed from memory (AP-4)

**Consistency check:** DEEP-SO-005 documents that start.md creates an incomplete STATE.json (17 missing required fields). If a STATE.json became empty (e.g., due to OneDrive write conflict), reconstruction would need to know the full schema to rebuild it. The Session Guardian in next.md:44-60 can reconstruct the session object, but not the full state. This is CONSISTENT with the observation — reconstruction from memory would produce incomplete state because no single code path creates a fully schema-valid STATE.json.

### Observation: Orchestrator bypassed reflexion-retry pipeline during task 07-10 (AP-5)

**Consistency check:** DEEP-AP-003 documents that pipeline bypass logging is conditional on voluntary compliance. The observation that the orchestrator bypassed the retry pipeline is CONSISTENT with this finding — the .md instructions suggest logging the bypass (next.md:459-461) but don't enforce it. The bypass would have gone unlogged unless the orchestrator voluntarily followed the comment instruction.

### Observation: OneDrive-induced write conflicts on .apex/

**Consistency check:** DEEP-SF-001 documents that pre-compact.sh always exits 0 even when backups fail. OneDrive write conflicts during backup would cause `cp` to fail, but pre-compact.sh would still exit 0 — hiding the failure. This is CONSISTENT with the observation — OneDrive conflicts would be invisible to the APEX pipeline because the backup hook doesn't propagate failures.

### Observation: Health check ran 10/10 PASS on 2026-04-10

**Consistency check:** This is CONSISTENT with the audit finding that all agent prompts are well-structured and the environment checks (TEST 0a-0f) are comprehensive. The health check validates agent behavior through real git operations, which would catch most prompt-level issues. The health check does NOT validate schema-state consistency (the primary finding category in this audit), so a 10/10 PASS is expected even with the SO-series findings present.

### Observation: Tasks 07-10 and 07-11 ran on post-Round-3.2 pipeline

**Consistency check:** All 12 known-fixed items from Rounds 3.0-3.7 are confirmed still fixed in this audit. The framework improvements from these rounds (filesystem verification, 3-way exit codes, phantom-check integration) are all present. This is CONSISTENT with the observation that recent tasks completed successfully on the improved pipeline.

---

## Recommended Next Steps

### Priority 1 — Schema-State Consistency (Findings: SO-001 through SO-006)
The most impactful remediation would be a "schema sweep" that:
1. Adds `trigger_reason`, `pending_notifications`, and `tokens.productive` to STATE.schema.json
2. Fixes `session_started` → `session_ended` in resume.md
3. Resolves `regression_rate` scale mismatch (0-100 integer vs 0-1 float) between cross-phase-audit.sh and schema
4. Adds missing default values to start.md init (last_compact, session_start_time, etc.)
5. Removes or documents the progressive-initialization design pattern

This addresses 6 of 8 P1 findings and closes the gap between the schema (the contract) and the code (the implementation).

### Priority 2 — Silent Failure Hardening (Findings: SF-001 through SF-005)
1. Make pre-compact.sh exit non-zero on backup failure
2. Add `set -u` to all hooks
3. Implement basic $ref validation in validate-state.sh for autonomy

### Priority 3 — Tracking Consistency (Findings: DD-002, DD-003, DD-004)
1. Add session-log entry for phantom-check failures
2. Add drift_indicators update for phase-boundary drift
3. Add framework_overhead estimate for phantom-check path

### Priority 4 — Pipeline Robustness (Findings: AP-002, AP-003, DD-001)
1. Add WAVE_MAP.json/PLAN_META.json existence check after architect
2. Make tdad.index_built conditional on actual index creation
3. Design automatic bypass detection (hard problem — requires design discussion)

## Appendix A: Files Inventoried

**Total files examined: 48** (all files listed below were read, at minimum in part)

### Hooks (19 files)
```
framework/hooks/_require-git.sh          17 lines
framework/hooks/_require-jq.sh           23 lines
framework/hooks/_state-update.sh         47 lines
framework/hooks/circuit-breaker.sh       79 lines
framework/hooks/context-monitor.sh       57 lines
framework/hooks/cross-phase-audit.sh    103 lines
framework/hooks/destructive-guard.sh    179 lines
framework/hooks/generate-task-map.sh     96 lines
framework/hooks/mutation-gate.sh         80 lines
framework/hooks/phantom-check.sh         28 lines
framework/hooks/phase-tag.sh             43 lines
framework/hooks/post-write.sh            35 lines
framework/hooks/pre-compact.sh           46 lines
framework/hooks/pre-task-snapshot.sh     81 lines
framework/hooks/session-log.sh           49 lines
framework/hooks/subagent-stop.sh         40 lines
framework/hooks/tdad-impact.py           47 lines
framework/hooks/tdad-index.sh            89 lines
framework/hooks/verify-learnings.sh     110 lines
```

### Commands (12 files)
```
framework/commands/apex/_debate.md        45 lines
framework/commands/apex/health-check.md  191 lines
framework/commands/apex/micro.md          45 lines
framework/commands/apex/next.md          653 lines
framework/commands/apex/pause.md          28 lines
framework/commands/apex/precheck.md       15 lines
framework/commands/apex/quick.md          64 lines
framework/commands/apex/recover.md        15 lines
framework/commands/apex/resume.md        143 lines
framework/commands/apex/spec.md           12 lines
framework/commands/apex/start.md          97 lines
framework/commands/apex/status.md         80 lines
```

### Agents (9 files)
```
framework/agents/architect.md             94 lines
framework/agents/critic.md                82 lines
framework/agents/executor.md             217 lines
framework/agents/planner.md               46 lines
framework/agents/verifier.md              62 lines
framework/agents/specialist/data.md       17 lines
framework/agents/specialist/frontend.md   16 lines
framework/agents/specialist/integration.md 17 lines
framework/agents/specialist/security.md   17 lines
```

### Schemas (4 files)
```
framework/schemas/CONTEXT_BUDGET.schema.json  94 lines
framework/schemas/PLAN_META.schema.json       54 lines
framework/schemas/RESULT.schema.json         113 lines
framework/schemas/STATE.schema.json          350 lines
```

### Scripts (3 files)
```
framework/scripts/self-test.sh            43 lines
framework/scripts/sync-to-claude.sh      160 lines
framework/scripts/validate-state.sh      207 lines
```

### Framework Root (1 file read)
```
framework/apex-model-routing.json         50 lines
```

### Deployed
```
~/.claude/settings.json                  (hooks section fully read)
~/.claude/hooks/                         (directory listing verified)
~/.claude/agents/                        (directory listing verified)
~/.claude/agents/specialist/             (directory listing verified)
```

## Appendix B: Commands Executed

```bash
# Pass 1: Inventory
find framework -type f -not -path "*/\.*" | sort
ls -la framework/hooks/ framework/commands/apex/ framework/agents/ framework/agents/specialist/ framework/schemas/ framework/scripts/
wc -l framework/hooks/*.sh framework/hooks/*.py
wc -l framework/commands/apex/*.md
wc -l framework/agents/*.md framework/agents/specialist/*.md
wc -l framework/schemas/*.json framework/scripts/*.sh
ls ~/.claude/hooks/ ~/.claude/agents/ ~/.claude/agents/specialist/ ~/.claude/commands/apex/

# Pass 2: Call Graph
for hook in framework/hooks/*.sh; do grep -rn "$(basename $hook)" framework/commands/ framework/agents/ ~/.claude/settings.json; done
for agent in framework/agents/*.md framework/agents/specialist/*.md; do grep -rn "$(basename $agent .md)" framework/commands/; done
for schema in framework/schemas/*.json; do grep -rn "$(basename $schema)" framework/ | grep -v "^framework/schemas/"; done

# Pass 3: Documentation Drift
grep -n "bash ~/.claude/hooks\|Task(" framework/commands/apex/next.md
grep -n "bash ~/.claude/hooks\|Task(" framework/commands/apex/quick.md
grep -n "bash ~/.claude/hooks\|Task(" framework/commands/apex/micro.md
grep -n "bash ~/.claude/hooks\|Task(" framework/commands/apex/resume.md

# Pass 4: Environment Dependencies
grep -rn "jq\|git\|rg\|python3\|npx\|tsc\|stryker\|mutmut" framework/hooks/
grep -rn "_require-jq\|_require-git\|command -v" framework/hooks/

# Pass 5: Error Handling
grep -l "set -e\|set -u\|set -o pipefail" framework/hooks/*.sh framework/scripts/*.sh
for hook in framework/hooks/*.sh; do grep -n "exit " "$hook"; done
grep -n "\$?" framework/hooks/*.sh
grep -n "2>/dev/null" framework/hooks/*.sh
grep -n "|| true" framework/hooks/*.sh

# Pass 6: State File Analysis
grep -rn "STATE\.json" framework/hooks/ framework/commands/ framework/agents/
grep -n "session_started\|session_ended" framework/commands/apex/resume.md framework/schemas/STATE.schema.json
grep "pending_notifications\|productive\|trigger_reason" framework/schemas/STATE.schema.json

# Pass 7: Pipeline Tracing
# Full read of next.md (653 lines), resume.md (143 lines), quick.md (64 lines), micro.md (45 lines)
# Traced every hook call and Task() invocation

# Pass 8: Settings & Wiring
cat ~/.claude/settings.json | jq '.hooks'
ls ~/.claude/hooks/

# Pass 9: Anti-Pattern Hunt
grep -rn "2>/dev/null" framework/hooks/ | wc -l
grep -rn "|| true" framework/hooks/
grep -rn "except:" framework/hooks/*.py
grep -rn "AUTONOMY.json" framework/

# Pass 10: Cross-check
grep -rn "verify-ladder-check\|researcher\.md" framework/
grep -rn "v[5-8]" framework/ --include="*.md" --include="*.sh" --include="*.json"
ls /tmp/  # Verified /tmp exists in Git Bash on Windows
```

---

### Additional Files Referenced (not in framework/)

```
~/.claude/settings.json                  (full hooks section)
~/.claude/hooks/                         (directory listing — 21 files)
~/.claude/agents/                        (directory listing — 16 files)
~/.claude/agents/specialist/             (directory listing — 4 files)
~/.claude/commands/apex/                 (directory listing — 12 files)
/tmp/                                    (existence verified — MSYS provides /tmp on Windows)
```

### Files NOT Read (Out of Scope)

```
.apex/                                   (project state — out of scope)
AUDIT-2026-04-09.md                     (prior audit — reference only)
CHECKPOINT-FINDINGS-2026-04-10.md       (reference only)
APEX-GAPS-MASTER-2026-04-10.md          (reference only)
framework/apex-branding.md              (1,176 lines — checked version references only)
framework/apex-learnings.md             (159 lines — out of scope per engagement)
framework/DEV-FLOW.md                   (88 lines — checked for consistency, no findings)
framework/apex-design-notes.md          (91 lines — checked version references only)
framework/tests/*.sh                    (test scripts — referenced but not audited)
framework/test-fixtures/*.json          (test fixtures — referenced but not audited)
```

---

*Audit conducted 2026-04-10 by Claude Opus 4.6 under Deep Forensic Audit engagement. Static analysis only — no runtime execution, no file modifications, no commits.*
