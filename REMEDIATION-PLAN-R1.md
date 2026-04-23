# REMEDIATION-PLAN-R1

**Source audit:** apex-audit-findings-R1.md (2026-04-12, commit 80789e9)
**Spec anchor:** apex-spec.md (user-provided ideal definition)
**Plan date:** 2026-04-23
**Planner:** Claude Opus 4.6 (Remediation Planner mode)

---

## Remediation R-001

**Linked finding:** F-001
**Spec anchor:** "Defense-in-Depth Security Layer: `apex-prompt-guard.js`, Path Traversal Prevention, `apex-workflow-guard.js`, CI scanner, `security.cjs` module."

### Ecosystem analysis

1. **Purpose of this component:** The Defense-in-Depth layer is a multi-mechanism security perimeter that prevents injection, traversal, workflow poisoning, and CI-level supply-chain attacks on APEX's own files.
2. **Why here:** Security must be structural (hooks that auto-fire), not advisory (prompts that can be ignored). hooks/ is the enforcement layer.
3. **Current malfunction:** 3 of 6 named mechanisms are absent: workflow-guard, CI scanner, security.cjs module. The 3 that exist (prompt-guard.sh, path-guard.sh, destructive-guard.sh) are shell scripts, not .js — but functionally correct.
4. **Root cause:** Spec contradiction SC-001 names .js files; CLAUDE.md mandates .sh hooks. The team implemented the .sh equivalents for 3 mechanisms and deferred the other 3. apex-design-notes.md explicitly documents the zero-JS-dependency decision.
5. **Ideal state per spec:** 6 named security mechanisms all present and active: prompt injection guard, path traversal prevention, workflow content validation, CI scanner, and consolidated security module.
6. **Correct fix approach:** (a) Build `workflow-guard.sh` that validates workflow .md files for injection patterns before execution. (b) Build `ci-scan.sh` that scans for known CI supply-chain vectors (unpinned actions, secret exposure). (c) Consolidate security utilities into a sourced `_security-common.sh` module (the .sh equivalent of security.cjs). Spec SC-001 resolution: .sh implementations satisfy the functional requirement.
7. **Downstream components affected:** `framework/commands/apex/workflow.md` (must invoke workflow-guard before executing), `framework/settings.json` (must wire workflow-guard as PreToolUse), all CI-related workflow recipes.
8. **Pre-fix changes required elsewhere:** None — these are new files that extend existing patterns.
9. **Do-not-touch zones:** `prompt-guard.sh` (working correctly), `path-guard.sh` (working correctly), `destructive-guard.sh` (working correctly) — do not refactor existing guards.
10. **Non-obvious insights:** Workflow files are READ during execution (not written), so the Read tool matcher in settings.json would need to trigger workflow-guard. This is architecturally different from prompt-guard which triggers on Write|Edit. Alternatively, workflow-guard can be invoked explicitly by /apex:workflow before reading the recipe — avoiding the need for a Read matcher (which would be noisy for all file reads).

### Execution plan

**Files to modify:**
- `framework/commands/apex/workflow.md` — add validation step before recipe execution
- `framework/settings.json` — optionally wire workflow-guard

**Files to create:**
- `framework/hooks/workflow-guard.sh` — injection pattern scanner for workflow .md files
- `framework/hooks/ci-scan.sh` — CI supply-chain vector scanner
- `framework/hooks/_security-common.sh` — shared security utilities (normalize, pattern match)

**Files that MUST remain untouched:**
- `framework/hooks/prompt-guard.sh` — working, tested
- `framework/hooks/path-guard.sh` — working, tested
- `framework/hooks/destructive-guard.sh` — working, tested

**Order of operations:**
1. Create `_security-common.sh` with shared normalization/pattern-match functions (extracted from existing guards)
2. Create `workflow-guard.sh` that sources `_security-common.sh` and scans .md files for: instruction overrides, role hijacking, hidden directives in markdown (HTML comments, zero-width chars), executable code blocks with injection markers
3. Create `ci-scan.sh` that scans `.github/workflows/` for: unpinned actions (no SHA), secret echo/log, overly-permissive permissions, pull_request_target misuse
4. Modify `workflow.md` to call `workflow-guard.sh` on the selected recipe file before displaying/adopting
5. Add `workflow-guard.sh` to `settings.json` if Read-triggered enforcement is desired (decision point — see below)
6. Add tests to `test-hooks-security.sh`

**Rollback trigger:** Any existing security hook test fails after changes.

### Acceptance criteria

- Criterion 1: `workflow-guard.sh` detects and blocks a test workflow file containing "ignore all previous instructions" → exit 2
- Criterion 2: `ci-scan.sh` detects an unpinned GitHub Action (`uses: actions/checkout@v4` without SHA) → exit 2
- Criterion 3: `/apex:workflow` invokes workflow-guard before adopting a recipe
- Regression check: All tests in `test-hooks-blocking.sh`, `test-hooks-security.sh`, `test-guards.sh` still pass
- Spec re-check: All 6 Defense-in-Depth mechanisms have functional equivalents (3 existing .sh + workflow-guard.sh + ci-scan.sh + _security-common.sh)

### Dependencies

- **Blocks:** R-022 (F-022 is a subset of F-001 — workflow injection protection)
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** medium (new files + modification to workflow.md)
- **Reversibility:** trivial (new files can be deleted; workflow.md change is one line)
- **Confidence in fix approach:** high
- **Requires human decision:** YES — Should workflow-guard be auto-fired via settings.json Read matcher (noisy for all reads) or explicitly invoked by /apex:workflow only (less coverage but zero false positives)? Recommendation: explicit invocation in workflow.md.

---

## Remediation R-002

**Linked finding:** F-002
**Spec anchor:** "State management hybrid. Markdown + SQLite+FTS5."

### Ecosystem analysis

1. **Purpose of this component:** SQLite+FTS5 provides full-text search across all project artifacts (SPEC.md, DECISIONS.md, SESSION-LOG.md, PLAN.md files) enabling fast cross-session retrieval without grep-over-markdown.
2. **Why here:** The spec positions it as a control plane — a queryable index over the markdown/JSON files that remain the source of truth.
3. **Current malfunction:** Zero SQLite implementation exists. No .db files, no sqlite3 imports, no FTS5 indexing.
4. **Root cause:** Architectural scope. The JSON+Markdown state management was built first and works. SQLite+FTS5 is an optimization layer that was deferred. Additionally, start.md (line 89-91) explicitly documents: "JSONL is directly importable to SQLite+FTS5 when framework-level query needs exceed jq capabilities."
5. **Ideal state per spec:** Hybrid state — Markdown+JSON as source of truth, SQLite+FTS5 as queryable index for cross-session search.
6. **Correct fix approach:** This is a WONTFIX for v1 with spec amendment recommendation. The current JSON+JSONL+jq architecture is functional. The `event-log.jsonl` was designed as the migration path (start.md:89-91). Building SQLite+FTS5 would: (a) add a Python/Node.js runtime dependency that contradicts the zero-dependency design, (b) duplicate state that already exists in JSON/Markdown, (c) introduce sync risk (SQLite index vs. JSON source of truth). Recommendation: amend spec to say "Markdown + JSON + JSONL (SQLite+FTS5 ready via JSONL migration path)" instead of "Markdown + SQLite+FTS5".
7. **Downstream components affected:** None — no component currently depends on SQLite.
8. **Pre-fix changes required elsewhere:** None.
9. **Do-not-touch zones:** `event-log.jsonl` format (it IS the migration path — don't change its schema).
10. **Non-obvious insights:** The JSONL format was deliberately chosen to be SQLite-importable. This is documented. The design is "ready for SQLite" not "requires SQLite now." Building SQLite now would violate the zero-dependency principle (apex-design-notes.md) and CLAUDE.md rule "Hooks are shell scripts (.sh)."

### Execution plan

**WONTFIX** — with spec amendment.

**Files to modify:**
- None (code)
- Spec amendment recommendation: Change "State management hybrid: Markdown + SQLite+FTS5" to "State management hybrid: Markdown + JSON + JSONL (SQLite+FTS5 ready via structured JSONL migration path)"

**Rollback trigger:** N/A

### Acceptance criteria

- Criterion 1: Spec text is amended to reflect the actual architecture
- Criterion 2: event-log.jsonl continues to use structured JSONL format importable to SQLite
- Spec re-check: The amended spec anchor matches the implementation

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low (spec text change only)
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** YES — Does the spec owner accept amending the SQLite+FTS5 requirement to "SQLite-ready via JSONL"? If not, this becomes a major implementation effort requiring phased build.

---

## Remediation R-003

**Linked finding:** F-003
**Spec anchor:** "Module Ecosystem as Extension Model... APEX modular to separate repositories with independent lifecycles: apex-core, apex-frontend, apex-data, apex-security, apex-test-architect, apex-fintech, apex-healthcare, apex-builder."

### Ecosystem analysis

1. **Purpose of this component:** Platform extensibility via separate repos/modules with independent lifecycles, enabling community contribution and enterprise module isolation.
2. **Why here:** The spec differentiates APEX from "tool" to "platform" via modular extensibility.
3. **Current malfunction:** All code is in a single `framework/` directory with no package boundaries, no independent versioning, no module lifecycle separation.
4. **Root cause:** The framework is being built as a monolith-first design. Physical separation into repos is a distribution concern, not a build concern.
5. **Ideal state per spec:** 8+ separate repositories with independent lifecycles.
6. **Correct fix approach:** This is a **WONTFIX for v1** — physical repo separation is a post-launch concern. However, LOGICAL boundaries should be established now: (a) Document module boundaries in DIRECTORY-CONTRACT.md, (b) Ensure specialist agents are self-contained (no cross-specialist imports), (c) Ensure `/apex:new-agent` works as the platform entry point when built (R-004).
7. **Downstream components affected:** `/apex:new-agent` (F-004), all specialist agents, all hooks.
8. **Pre-fix changes required elsewhere:** None for logical boundaries.
9. **Do-not-touch zones:** Entire `framework/` directory structure — do not reorganize now.
10. **Non-obvious insights:** Physical repo separation during active build would cause merge hell. The spec describes the target architecture, not the build-phase architecture. Logical boundaries now, physical separation at v1 launch.

### Execution plan

**WONTFIX for v1** — with logical boundary documentation.

**Files to modify:**
- `framework/DIRECTORY-CONTRACT.md` — add module boundary documentation mapping framework/ subdirectories to future repos

**Files to create:** None

**Files that MUST remain untouched:**
- All framework/ files — no reorganization

**Order of operations:**
1. Document logical module boundaries in DIRECTORY-CONTRACT.md
2. Verify each specialist agent is self-contained (no cross-specialist dependencies)

**Rollback trigger:** N/A

### Acceptance criteria

- Criterion 1: DIRECTORY-CONTRACT.md maps current directories to future module repos
- Criterion 2: No specialist agent references another specialist agent's internal files
- Spec re-check: Module ecosystem documented as logical boundary with physical separation roadmap

### Dependencies

- **Blocks:** R-004 (new-agent requires module boundary understanding)
- **Blocked by:** None
- **Conflicts with:** R-009 (PEP 420 namespace — same deferred scope)

### Risk assessment

- **Blast radius:** low (documentation only)
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** YES — Confirm that physical repo separation is deferred to post-v1 launch.

---

## Remediation R-004

**Linked finding:** F-004
**Spec anchor:** "Pipeline commands complete: /apex:new-agent, /apex:new-workspace, /apex:peer-review, /apex:ui-review, /apex:ui-phase, /apex:milestone-summary"

### Ecosystem analysis

1. **Purpose of this component:** 6 commands that enable platform extensibility (new-agent), workspace isolation (new-workspace), cross-AI review (peer-review), UI quality (ui-review, ui-phase), and delivery visibility (milestone-summary).
2. **Why here:** These are core pipeline commands listed in the spec as required capabilities.
3. **Current malfunction:** All 6 files contain "NOT YET IMPLEMENTED" with redirects to existing alternatives.
4. **Root cause:** Prioritization — core pipeline (start, next, status, help, etc.) was built first. These 6 are second-tier commands.
5. **Ideal state per spec:** All 6 commands functional with executable logic.
6. **Correct fix approach:** Build each command using the established pattern (PROPOSALS MODE guard, read STATE.json, structured procedure, branding frames). Priority order by spec impact: (1) ui-phase (6-pillar Design Contract), (2) milestone-summary (proof-of-process), (3) new-agent (platform extensibility), (4) peer-review (cross-AI quality), (5) ui-review (UI quality gate), (6) new-workspace (isolation).
7. **Downstream components affected:** Each command may reference agents, hooks, or state fields that don't yet exist.
8. **Pre-fix changes required elsewhere:** For `new-agent`: module boundary documentation (R-003). For `peer-review`: external AI integration design.
9. **Do-not-touch zones:** Existing stub files contain useful redirect logic — preserve as fallback.
10. **Non-obvious insights:** `peer-review` requires calling external AI APIs (GPT-4, Gemini) which introduces a runtime dependency and API key requirement. This is architecturally different from all other commands. May need a plugin/adapter pattern. `new-workspace` requires git worktree management. `ui-phase` requires the 6-pillar Design Contract specification which is referenced but not fully documented in the current codebase.

### Execution plan

**Files to modify:**
- `framework/commands/apex/ui-phase.md`
- `framework/commands/apex/milestone-summary.md`
- `framework/commands/apex/new-agent.md`
- `framework/commands/apex/peer-review.md`
- `framework/commands/apex/ui-review.md`
- `framework/commands/apex/new-workspace.md`

**Files to create:** None (modify existing stubs)

**Files that MUST remain untouched:**
- All non-stub commands — do not modify working pipeline commands

**Order of operations:**
1. Build `ui-phase.md` — 6-pillar design contract workflow
2. Build `milestone-summary.md` — aggregate phase results + DORA + proof-of-process
3. Build `new-agent.md` — agent template generator with validation
4. Build `peer-review.md` — external AI adapter (may be partially functional with MCP tools)
5. Build `ui-review.md` — UI-specific verification using frontend-specialist
6. Build `new-workspace.md` — git worktree management wrapper

**Rollback trigger:** Any existing command test fails after changes.

### Acceptance criteria

- Criterion 1: Each of the 6 commands has executable logic (no "NOT YET IMPLEMENTED" text)
- Criterion 2: Each command follows the established pattern: PROPOSALS MODE guard, STATE.json read, branding frames
- Criterion 3: Each command can be invoked without error on a test project
- Regression check: All existing command tests pass
- Spec re-check: "Pipeline commands complete" — all 6 listed commands are functional

### Dependencies

- **Blocks:** None
- **Blocked by:** R-003 (new-agent needs module boundary docs), R-020 (peer-review is the implementation of cross-AI review)
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** high (6 new command implementations)
- **Reversibility:** moderate (stubs can be restored from git)
- **Confidence in fix approach:** medium (peer-review has external API dependency uncertainty; ui-phase needs 6-pillar spec clarification)
- **Requires human decision:** YES — (1) Should peer-review support specific AI vendors, or use a generic MCP adapter? (2) What are the exact 6 pillars for the Design Contract in ui-phase?

---

## Remediation R-005

**Linked finding:** F-005
**Spec anchor:** "Nyquist Validation Layer with Wave 0 enforcement." and "Test infrastructure mapping before code."

### Ecosystem analysis

1. **Purpose of this component:** Wave 0 is a mandatory pre-execution step at the PHASE level that maps test infrastructure before any code is written. It ensures test scaffolding exists before executors run.
2. **Why here:** Test-architect currently runs per-TASK (before each C/D task in next.md F.5). Wave 0 should run per-PHASE — a different granularity that catches phase-level test gaps.
3. **Current malfunction:** No Wave 0 concept exists. Test-architect runs per-task, not per-phase.
4. **Root cause:** Design granularity gap — the per-task test-architect was built; the per-phase validation layer was not.
5. **Ideal state per spec:** Before any code execution in a phase, Wave 0 runs test-architect at phase level to map test infrastructure, identify coverage gaps, and validate test framework readiness.
6. **Correct fix approach:** Add a Wave 0 step to next.md's build stage, BEFORE dispatching Wave 1. Wave 0 spawns test-architect with the full phase plan (all tasks), not individual task specs. Output: `.apex/phases/$PHASE/WAVE_0_TEST_MAP.json`. If veto: block phase execution.
7. **Downstream components affected:** `framework/commands/apex/next.md` (build stage), `framework/agents/test-architect.md` (needs phase-level input mode)
8. **Pre-fix changes required elsewhere:** test-architect.md may need a "phase mode" vs "task mode" input distinction.
9. **Do-not-touch zones:** Per-task test-architect invocation in next.md F.5 — keep both granularities.
10. **Non-obvious insights:** Wave 0 should be lightweight — it MAPS infrastructure, it doesn't BUILD tests. Building happens in Wave 1+. The mapping catches: missing test framework, missing test directories, missing test configurations, insufficient test coverage targets.

### Execution plan

**Files to modify:**
- `framework/commands/apex/next.md` — add Wave 0 step in build stage before Wave 1 dispatch
- `framework/agents/test-architect.md` — add phase-level input mode

**Files to create:** None

**Files that MUST remain untouched:**
- Per-task test-architect invocation in next.md (F.5 section)

**Order of operations:**
1. Add phase-level input mode to test-architect.md (accepts full PLAN_META.json, outputs WAVE_0_TEST_MAP.json)
2. Add Wave 0 block in next.md build stage: after architect outputs PLAN_META.json, before first Wave dispatch
3. Wire veto logic: if WAVE_0_TEST_MAP.veto == true, block phase execution
4. Add Wave 0 skip for L1 complexity (minimal ceremony)

**Rollback trigger:** Wave 0 blocks legitimate phase execution on a test project.

### Acceptance criteria

- Criterion 1: Wave 0 runs automatically before Wave 1 on L2+ projects
- Criterion 2: Wave 0 output file exists at `.apex/phases/$PHASE/WAVE_0_TEST_MAP.json`
- Criterion 3: Wave 0 veto blocks phase execution with actionable message
- Regression check: Existing per-task test-architect still runs for C/D tasks
- Spec re-check: "Nyquist Validation Layer with Wave 0 enforcement" — Wave 0 exists and enforces test infrastructure mapping

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** medium (modifies next.md orchestration + test-architect agent)
- **Reversibility:** moderate (next.md is the orchestration heart — changes need careful rollback)
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-006

**Linked finding:** F-006
**Spec anchor:** "Skipped-test regression detection."

### Ecosystem analysis

1. **Purpose of this component:** Detect when an executor silently adds `.skip()`, `.only()`, `xit()`, `xdescribe()`, or `@pytest.mark.skip` to test files to make them pass — a core mutation vector.
2. **Why here:** This belongs in the post-write hook chain — after any test file is modified, check for skip patterns.
3. **Current malfunction:** No mechanism detects silently skipped tests within test files. Verifier detects task-level scope reduction (RESULT.json status="skip"), but not test-file-level skips.
4. **Root cause:** The mutation-gate checks test QUALITY (mutation testing), and verifier checks task SCOPE, but neither checks for test SUPPRESSION (individual tests disabled).
5. **Ideal state per spec:** A hook that catches skip patterns in modified test files.
6. **Correct fix approach:** Add skip-pattern detection to `post-write.sh` (existing hook, already fires on Write|Edit). When the written file matches test patterns (`*.test.*`, `*.spec.*`, `test_*.py`), scan for skip markers. Exit 2 if found.
7. **Downstream components affected:** `framework/hooks/post-write.sh` (add new check section)
8. **Pre-fix changes required elsewhere:** None.
9. **Do-not-touch zones:** Existing post-write.sh checks (secret detection, TSC, conventional commits) — add new section, don't modify existing.
10. **Non-obvious insights:** `.only()` is as dangerous as `.skip()` — it runs ONLY that test, silently suppressing all others. Both must be detected. Also: `pending()` in RSpec, `@unittest.skip` in Python, `#[ignore]` in Rust. The detection should be polyglot. False positive risk: legitimate skip with reason (e.g., `it.skip('known flaky', ...)`) — should the hook be BLOCKING or ADVISORY? Recommendation: BLOCKING, because legitimate skips should be documented in PLAN_META.json as accepted risks.

### Execution plan

**Files to modify:**
- `framework/hooks/post-write.sh` — add skipped-test detection section

**Files to create:** None

**Files that MUST remain untouched:**
- Existing post-write.sh sections (secret detection, TSC, conventional commits)

**Order of operations:**
1. Add file-pattern check: if filename matches `*.test.*|*.spec.*|test_*` patterns
2. Add skip-pattern regex: `.skip(`, `.only(`, `xit(`, `xdescribe(`, `@pytest.mark.skip`, `@unittest.skip`, `#[ignore]`, `pending(`
3. If patterns found: extract matches, display, exit 2 (blocking)
4. Add test cases to test-hooks-blocking.sh

**Rollback trigger:** False positives on legitimate test files in any test project.

### Acceptance criteria

- Criterion 1: Writing a test file with `.skip(` triggers exit 2 from post-write.sh
- Criterion 2: Writing a test file with `.only(` triggers exit 2
- Criterion 3: Writing a non-test file with `.skip(` does NOT trigger (e.g., documentation)
- Regression check: All existing post-write.sh tests pass
- Spec re-check: "Skipped-test regression detection" — detected at write time

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low (adding section to existing hook)
- **Reversibility:** trivial (remove the added section)
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-007

**Linked finding:** F-007
**Spec anchor:** "DORA self-monitoring." and "The First Framework That Improves DORA."

### Ecosystem analysis

1. **Purpose of this component:** DORA metrics (lead time, deployment frequency, change failure rate, recovery time) are self-monitored by the framework to substantiate the branding position "The First Framework That Improves DORA."
2. **Why here:** Metrics must be collected at the execution/completion points — hooks and commands.
3. **Current malfunction:** **PARTIALLY FIXED since audit.** Current state:
   - `lead_time_avg`: WRITTEN by `phase-tag.sh` (hook, lines 50-52) — rolling average from PLAN_META created_at to completion
   - `deployment_freq`: WRITTEN by `phase-tag.sh` (hook, line 65) — phases_completed / days
   - `change_failure_rate`: WRITTEN by `next.md` (command logic, line 593) — phases_failed / phases_completed
   - `recovery_time_avg`: WRITTEN by `next.md` (line 491-494) AND `recover.md` (lines 33-36) — hours from failure to recovery
   The audit found "no hook writes to these fields" — this was accurate at audit time (commit 80789e9). Since then, phase-tag.sh has been updated to write lead_time and deployment_freq. The remaining two metrics (change_failure_rate, recovery_time) are written by command pseudocode, not hooks.
4. **Root cause:** Incremental build — DORA schema was designed first, write paths were added later.
5. **Ideal state per spec:** All 4 DORA metrics actively collected and updated.
6. **Correct fix approach:** Verify all 4 write paths are complete. The remaining gap: change_failure_rate and recovery_time are written by command logic (next.md/recover.md), which depends on Claude following the pseudocode. For structural enforcement, consider moving change_failure_rate computation to phase-tag.sh (which already has DORA update logic). Recovery_time is correctly in next.md/recover.md (it needs to run at specific failure/recovery events).
7. **Downstream components affected:** `framework/hooks/phase-tag.sh`, `framework/commands/apex/status.md` (display)
8. **Pre-fix changes required elsewhere:** None.
9. **Do-not-touch zones:** `status.md` DORA display section (already correctly renders all 4 metrics).
10. **Non-obvious insights:** Moving change_failure_rate to phase-tag.sh would centralize all DORA writes in one hook + next.md's recovery tracking. This is cleaner than the current split across 3 files.

### Execution plan

**Files to modify:**
- `framework/hooks/phase-tag.sh` — add change_failure_rate computation (phases_failed / phases_completed)

**Files to create:** None

**Files that MUST remain untouched:**
- `framework/commands/apex/status.md` — already correct
- `framework/commands/apex/next.md` DORA sections — keep recovery_time logic

**Order of operations:**
1. Add change_failure_rate computation to phase-tag.sh alongside existing lead_time and deployment_freq updates
2. Verify recovery_time_avg write path in next.md is complete (it is — lines 491-494)
3. Test: complete a phase, verify all 4 DORA fields are non-null in STATE.json
4. Test: fail a task then recover, verify recovery_time_avg is populated

**Rollback trigger:** phase-tag.sh fails to create git tags after modification.

### Acceptance criteria

- Criterion 1: After phase completion, `jq '.dora | keys' .apex/STATE.json` shows all 4 metrics non-null
- Criterion 2: `lead_time_avg` is computed as hours (reasonable value, not 0 or null)
- Criterion 3: `deployment_freq` is phases/day (reasonable value)
- Criterion 4: `change_failure_rate` is 0 for zero-failure runs
- Regression check: phase-tag.sh still creates annotated git tags correctly
- Spec re-check: "DORA self-monitoring" — all 4 metrics have write paths

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low (adding computation to existing hook)
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-008

**Linked finding:** F-008
**Spec anchor:** "U-shaped attention awareness." and "Context ordering by U-shape."

### Ecosystem analysis

1. **Purpose of this component:** U-shaped attention curve (primacy-recency effect) means LLMs attend more to the beginning and end of context, less to the middle. Critical instructions should be placed at the top and bottom.
2. **Why here:** This is an architectural pattern in how agent .md files and command outputs are structured, not a runtime hook.
3. **Current malfunction:** U-shaped ordering is documented as a design principle in apex-design-notes.md:9 but not enforced or verified.
4. **Root cause:** U-shaped ordering is inherently a DESIGN constraint, not a runtime check. There's no easy way to "enforce" it via a hook — it's about how prompts are composed.
5. **Ideal state per spec:** Context engineering at state-of-the-art level with U-shaped ordering in all agent prompts.
6. **Correct fix approach:** (a) Audit all agent .md files for U-shaped compliance: critical instructions at top (before <context> block) and bottom (after closing context), task-specific/volatile content in the middle. (b) Document the pattern in a "PROMPT ENGINEERING GUIDELINES" section of DIRECTORY-CONTRACT.md. (c) Add a linter/checklist item to health-check that verifies agent .md files follow the pattern. This is NOT a runtime enforcement — it's a structural audit.
7. **Downstream components affected:** All agent .md files (8 core + 4 specialist), all command .md files.
8. **Pre-fix changes required elsewhere:** None.
9. **Do-not-touch zones:** Agent content/logic — only reorder sections if U-shape is violated.
10. **Non-obvious insights:** next.md already implements observation masking with zone-based context: Zone 1 (Stable Prefix — cached) at top, Zone 2 (JIT per task) in middle, Zone 3 (Working Memory — volatile) varies. This IS U-shaped engineering — the most critical context (executor prompt, CLAUDE.md, TASK_MAP) is in Zone 1 (top/first-read). The gap is that this pattern is only in next.md, not documented as a framework-wide requirement.

### Execution plan

**Files to modify:**
- `framework/DIRECTORY-CONTRACT.md` — add U-shaped prompt engineering guidelines
- `framework/commands/apex/health-check.md` — add agent prompt structure audit (U-shape check)

**Files to create:** None

**Files that MUST remain untouched:**
- Agent .md files — verify compliance, reorder only if needed (separate task per agent)

**Order of operations:**
1. Audit all 12 agent .md files: is the critical constraint section at the top? Is the task injection point not buried in the middle?
2. Document U-shaped guidelines in DIRECTORY-CONTRACT.md
3. Add health-check test: verify each agent .md has role/constraints in first 20% and critical output format in last 20%
4. Fix any agent files that violate the pattern (if found)

**Rollback trigger:** Agent prompt reordering changes behavior (unlikely but test).

### Acceptance criteria

- Criterion 1: DIRECTORY-CONTRACT.md documents U-shaped prompt engineering guidelines
- Criterion 2: health-check.md includes an agent prompt structure audit
- Criterion 3: All 12 agent .md files place critical constraints in the first 20% of content
- Regression check: All health-check tests still pass
- Spec re-check: "U-shaped attention awareness" — documented, audited, enforced via health-check

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low (documentation + health-check addition)
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-009

**Linked finding:** F-009
**Spec anchor:** "PEP 420 namespace."

### Ecosystem analysis

1. **Purpose of this component:** Python namespace packaging (PEP 420) for APEX module distribution — allows `import apex.core`, `import apex.frontend`, etc. from separate packages.
2. **Why here:** Required for physical module separation where Python-based components (tdad-impact.py, apex-debug.py) are distributed as packages.
3. **Current malfunction:** No namespace mechanism exists. Zero PEP 420 implementation.
4. **Root cause:** Module ecosystem (F-003) is monolithic. Namespace packaging requires module separation first.
5. **Ideal state per spec:** Python namespace packages for APEX modules.
6. **Correct fix approach:** **WONTFIX for v1** — depends on physical module separation (R-003), which is deferred. When modules are separated into repos, each Python module gets a `pyproject.toml` with `apex.*` namespace. This is a distribution concern, not a framework concern.
7. **Downstream components affected:** Python scripts (tdad-impact.py, apex-debug.py).
8. **Pre-fix changes required elsewhere:** R-003 (module ecosystem separation).
9. **Do-not-touch zones:** Existing Python scripts — they work as standalone files.
10. **Non-obvious insights:** PEP 420 (implicit namespace packages) actually requires NO `__init__.py` files. When module repos are created, the namespace comes naturally from directory structure. The "fix" is essentially free once physical separation happens.

### Execution plan

**WONTFIX for v1** — blocked by R-003 (module ecosystem).

**Rollback trigger:** N/A

### Acceptance criteria

- Criterion 1: Deferred to post-v1 with R-003
- Spec re-check: PEP 420 is a post-physical-separation concern

### Dependencies

- **Blocks:** None
- **Blocked by:** R-003
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low
- **Reversibility:** N/A
- **Confidence in fix approach:** high (natural outcome of module separation)
- **Requires human decision:** NO (follows R-003 decision)

---

## Remediation R-010

**Linked finding:** F-010
**Spec anchor:** "Color discipline." listed under Failure 5 handling and UX principles.

### Ecosystem analysis

1. **Purpose of this component:** Consistent color semantics across all APEX output — colors have fixed meanings (green=verified, yellow=partial/warning, red=failed/blocked), not decorative.
2. **Why here:** Part of the anti-fake-reporting strategy (Failure 5) and UX for non-technical users. Colors should be defined in apex-branding.md and enforced in rendering templates.
3. **Current malfunction:** Output uses emojis (checkmarks, warning signs) but no systematic color discipline. No mapping between semantic state and color.
4. **Root cause:** The branding system (apex-branding.md) focuses on frame layout and typography, not color semantics. Color was left as implicit.
5. **Ideal state per spec:** Defined color semantics enforced across all output.
6. **Correct fix approach:** (a) Define color semantic map in apex-branding.md. (b) Since Claude Code terminal output doesn't support arbitrary colors (it's markdown-rendered), "color" translates to: emoji semantics + bold/formatting. The color discipline is really about CONSISTENT SEMANTIC INDICATORS: ✅/🟢 = verified, ⚠️/🟡 = partial, ❌/🔴 = failed, 🔵 = informational, ⬜ = pending. (c) Audit all commands/agents for consistent emoji usage.
7. **Downstream components affected:** All command .md files that render output, apex-branding.md.
8. **Pre-fix changes required elsewhere:** None.
9. **Do-not-touch zones:** session-log.sh already has a consistent emoji mapping (checkpoint=✅, fail=❌, etc.) — use this as the baseline.
10. **Non-obvious insights:** Terminal color codes (ANSI) may not render in all Claude Code environments. The emoji-based approach is more portable. session-log.sh:23-35 already defines a semantic emoji map — this should be promoted to the framework-wide standard.

### Execution plan

**Files to modify:**
- `framework/apex-branding.md` — add Color Discipline section with semantic map
- `framework/commands/apex/status.md` — verify emoji consistency
- `framework/commands/apex/next.md` — verify emoji consistency

**Files to create:** None

**Files that MUST remain untouched:**
- `framework/hooks/session-log.sh` emoji mapping — it's already correct, use as reference

**Order of operations:**
1. Extract emoji-to-semantic mapping from session-log.sh
2. Add "Color Discipline" section to apex-branding.md with the canonical map
3. Audit all command .md files for emoji consistency against the map
4. Fix any inconsistencies found
5. Add to health-check: verify no command uses ✅ for non-verified states

**Rollback trigger:** N/A (documentation + consistency fix)

### Acceptance criteria

- Criterion 1: apex-branding.md has a "Color Discipline" section with semantic map
- Criterion 2: All command outputs use consistent emoji-to-semantic mapping
- Criterion 3: ✅ is NEVER used for unverified states across all .md files
- Regression check: health-check tests pass
- Spec re-check: "Color discipline" — defined and enforced

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low (branding documentation + emoji audit)
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-011

**Linked finding:** F-011
**Spec anchor:** "Four primitives: apex/todos/, apex/threads/, apex/seeds/, apex/backlog/."

### Ecosystem analysis

1. **Purpose of this component:** Four memory primitive directories for the dream-cycle agent: todos (actionable items), threads (ongoing conversations), seeds (future ideas), backlog (deferred work).
2. **Why here:** These directories must exist for memory-synthesis agent to read/write.
3. **Current malfunction:** **ALREADY FIXED since audit.** `start.md` line 44 creates all four directories: `mkdir -p .apex/{pre-build,phases,backups,debate-log,roundtable-log,comprehension-gates,todos,threads,seeds,backlog}`. The audit was at commit 80789e9; the fix was applied in a subsequent commit.
4. **Root cause:** Was missing at audit time, now present.
5. **Ideal state per spec:** Four directories created during `/apex:start`.
6. **Correct fix approach:** Verify fix is complete. No further action needed.
7. **Downstream components affected:** memory-synthesis.md (reads/writes these directories)
8. **Pre-fix changes required elsewhere:** None.
9. **Do-not-touch zones:** start.md line 44 — already correct.
10. **Non-obvious insights:** The directories are created but may be empty. memory-synthesis agent needs at least one seed file or todo to process. Consider adding a `.gitkeep` or initial seed file.

### Execution plan

**Already fixed.** Verify only.

**Order of operations:**
1. Verify `start.md` line 44 creates all 4 directories
2. Verify memory-synthesis.md references these directories correctly
3. Consider: add initial `.gitkeep` to each directory for git tracking (optional)

**Rollback trigger:** N/A

### Acceptance criteria

- Criterion 1: `/apex:start` creates `.apex/todos/`, `.apex/threads/`, `.apex/seeds/`, `.apex/backlog/`
- Criterion 2: memory-synthesis.md references these paths correctly
- Spec re-check: "Four primitives" — directories created at project init

### Dependencies

- **Blocks:** R-012 (dream-cycle needs directories to exist)
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low (already fixed)
- **Reversibility:** N/A
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-012

**Linked finding:** F-012
**Spec anchor:** "Memory Synthesis dream-cycle agent."

### Ecosystem analysis

1. **Purpose of this component:** Periodic memory consolidation — stale todos → backlog, long threads → summarized, mature seeds → todos. The "dream" metaphor implies it runs periodically, not just on explicit triggers.
2. **Why here:** Currently only runs during /apex:pause and /apex:resume. Long sessions without pause never trigger consolidation.
3. **Current malfunction:** Dream-cycle only fires on pause/resume. A user who never pauses accumulates stale memory artifacts.
4. **Root cause:** The dream-cycle was wired to pause/resume transitions as the natural consolidation point. No periodic trigger was added.
5. **Ideal state per spec:** Dream-cycle runs periodically — not just on explicit pause/resume.
6. **Correct fix approach:** Add a time-gated dream-cycle trigger to next.md. When context-monitor detects WARNING_OVERFLOW (55%+ usage), or when 60-minute decision gate fires, offer dream-cycle as an option. Alternatively, trigger automatically every N tasks (e.g., every 10 tasks completed).
7. **Downstream components affected:** `framework/commands/apex/next.md` (add trigger point)
8. **Pre-fix changes required elsewhere:** R-011 (directories must exist — already fixed).
9. **Do-not-touch zones:** Existing pause/resume dream-cycle triggers — keep them.
10. **Non-obvious insights:** Running dream-cycle too frequently wastes context tokens. The right trigger is context-aware: run when memory primitives have accumulated enough content to warrant consolidation. A simple heuristic: `find .apex/{todos,threads,seeds} -type f | wc -l` > 10. If fewer than 10 files across primitives, skip.

### Execution plan

**Files to modify:**
- `framework/commands/apex/next.md` — add dream-cycle trigger at time gate or context overflow point

**Files to create:** None

**Files that MUST remain untouched:**
- `framework/commands/apex/pause.md` — keep existing trigger
- `framework/commands/apex/resume.md` — keep existing trigger

**Order of operations:**
1. Add dream-cycle trigger to next.md at the 60-minute time gate: after user selects "continue", check if memory primitives have >10 files → if yes, run dream-cycle in background
2. Add dream-cycle trigger to context-monitor WARNING_OVERFLOW path: before compact, consolidate memory
3. Add file-count heuristic to skip dream-cycle when unnecessary

**Rollback trigger:** Dream-cycle trigger causes excessive token usage during normal execution.

### Acceptance criteria

- Criterion 1: Dream-cycle triggers automatically after 60+ minutes if memory primitives have >10 files
- Criterion 2: Dream-cycle does NOT trigger if <10 files in memory primitives
- Criterion 3: Pause/resume triggers still work unchanged
- Regression check: next.md orchestration still advances tasks correctly
- Spec re-check: "Memory Synthesis dream-cycle agent" — runs periodically, not just on pause/resume

### Dependencies

- **Blocks:** None
- **Blocked by:** R-011 (directories exist — already fixed)
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** medium (modifies next.md orchestration)
- **Reversibility:** moderate (next.md changes need careful rollback)
- **Confidence in fix approach:** medium (token cost of dream-cycle during execution is uncertain)
- **Requires human decision:** NO

---

## Remediation R-013

**Linked finding:** F-013
**Spec anchor:** "Phantom-check, AST-KB Hallucination Gate."

### Ecosystem analysis

1. **Purpose of this component:** AST-KB (Abstract Syntax Tree - Knowledge Base) validation catches hallucinated imports — modules/functions that don't exist. USENIX research shows 19.7% of AI-generated imports don't exist.
2. **Why here:** This should be a post-write hook that validates newly added imports against installed packages.
3. **Current malfunction:** phantom-check.sh exists for LANGUAGE-level hallucination (uncertainty phrases). AST-KB (import validation) has no implementation.
4. **Root cause:** phantom-check addresses one hallucination vector (self-reported uncertainty). AST-KB addresses a different vector (non-existent code references). The second was never built.
5. **Ideal state per spec:** Post-write validation that checks if imported modules/functions actually exist in the project or installed packages.
6. **Correct fix approach:** Add an AST-KB check to post-write.sh (or a new hook `ast-kb-check.sh`). For JS/TS: parse import statements, check if the module resolves via `node -e "require.resolve('module')"`. For Python: check if the module resolves via `python -c "import module"`. Scope to newly added/modified lines only (via git diff).
7. **Downstream components affected:** `framework/hooks/post-write.sh` (if integrated) or `framework/settings.json` (if new hook)
8. **Pre-fix changes required elsewhere:** None.
9. **Do-not-touch zones:** `phantom-check.sh` — language-level check, separate concern.
10. **Non-obvious insights:** Full AST parsing (e.g., with `tree-sitter`) would be ideal but adds a dependency. A lighter approach: regex-extract imports from modified files, then validate each against the package manager. False positives: local modules (relative imports) that haven't been created yet — the check should only validate npm/pip packages, not relative imports. Also: this hook would be SLOW (spawning node/python per import). Consider: advisory only, not blocking. Or batch-check at phase end, not per-write.

### Execution plan

**Files to create:**
- `framework/hooks/ast-kb-check.sh` — import validation hook

**Files to modify:**
- `framework/settings.json` — wire ast-kb-check.sh as PostToolUse on Write|Edit (or keep as manual invocation)

**Files that MUST remain untouched:**
- `framework/hooks/phantom-check.sh` — separate concern

**Order of operations:**
1. Create `ast-kb-check.sh`:
   - Extract file type from input path
   - For .ts/.tsx/.js/.jsx: regex extract `import ... from '...'` and `require('...')`
   - Filter to non-relative imports (skip `./` and `../`)
   - Validate each: `node -e "require.resolve('$module')"` (check exit code)
   - For .py: regex extract `import` and `from ... import`
   - Validate each: `python3 -c "import $module"` (check exit code)
2. Set as ADVISORY (exit 1, not exit 2) — false positives expected for local modules
3. Add to settings.json as PostToolUse on Write|Edit (optional — see decision point)
4. Add tests

**Rollback trigger:** False positive rate > 20% on a real project.

### Acceptance criteria

- Criterion 1: Writing a file with `import nonexistent_module_xyz` triggers advisory warning
- Criterion 2: Writing a file with `import os` (valid module) does NOT trigger
- Criterion 3: Relative imports (`./utils`) are skipped (not validated)
- Regression check: All existing post-write.sh and hook tests pass
- Spec re-check: "AST-KB Hallucination Gate" — import validation exists

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** medium (new hook + settings.json wiring)
- **Reversibility:** trivial (new file, can delete)
- **Confidence in fix approach:** medium (false positive rate uncertain — advisory mode mitigates)
- **Requires human decision:** YES — Should this be auto-fired (PostToolUse) or manually invoked at phase verification? Auto-fire is comprehensive but slow. Recommendation: advisory PostToolUse.

---

## Remediation R-014

**Linked finding:** F-014
**Spec anchor:** "SPEC_VERSION hash + SPEC_DELTA.json."

### Ecosystem analysis

1. **Purpose of this component:** Spec version hash enables drift detection — if SPEC.md changes after planning, execution should know the plan was built against a different spec version.
2. **Why here:** The drift check should happen in next.md BEFORE dispatching executor, comparing STATE.json spec_version against current SPEC.md hash.
3. **Current malfunction:** spec.md (command) correctly writes spec_version hash when spec is updated. STATE.json stores the hash. But next.md does NOT check this hash before execution.
4. **Root cause:** Write path built (spec.md lines 15-43), read path missing (no check in next.md).
5. **Ideal state per spec:** Before executing a task, next.md compares STATE.json spec_version with current SPEC.md hash. If mismatch: warn user that spec has drifted.
6. **Correct fix approach:** Add spec drift check to next.md build stage, before executor dispatch. Compute `sha256sum .apex/SPEC.md`, compare with `STATE.json.spec_version`. If mismatch: advisory warning "Spec has changed since planning. Consider re-running /apex:spec to update." Not blocking — the user may have intentionally updated spec.
7. **Downstream components affected:** `framework/commands/apex/next.md`
8. **Pre-fix changes required elsewhere:** None — spec.md already writes the hash.
9. **Do-not-touch zones:** `framework/commands/apex/spec.md` — write path already correct.
10. **Non-obvious insights:** The check must handle the case where spec_version is "" (initial state, no spec yet). In that case, skip the check. Also: if SPEC.md doesn't exist, skip. The check is meaningful only when BOTH spec_version is non-empty AND SPEC.md exists.

### Execution plan

**Files to modify:**
- `framework/commands/apex/next.md` — add spec drift check before executor dispatch

**Files to create:** None

**Files that MUST remain untouched:**
- `framework/commands/apex/spec.md` — already correct

**Order of operations:**
1. Add spec drift check in next.md build stage, after reading STATE.json, before task dispatch:
   - If STATE.spec_version is non-empty AND .apex/SPEC.md exists:
   - Compute CURRENT_HASH = sha256sum .apex/SPEC.md
   - If CURRENT_HASH != STATE.spec_version: advisory warning + offer to update via /apex:spec
2. Add to session drift indicators: increment spec_drift_count

**Rollback trigger:** False spec drift warnings on unchanged specs.

### Acceptance criteria

- Criterion 1: Modifying SPEC.md without running /apex:spec triggers drift warning in next /apex:next
- Criterion 2: Normal execution (no spec change) produces no warning
- Criterion 3: Empty spec_version (new project) produces no warning
- Regression check: next.md orchestration still works correctly
- Spec re-check: "SPEC_VERSION hash" — drift detection active during execution

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low (advisory check in next.md)
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-015

**Linked finding:** F-015
**Spec anchor:** "Glass cockpit with 3-5 decision-required items at top."

### Ecosystem analysis

1. **Purpose of this component:** The glass cockpit filters to show only items requiring user decision (pending approvals, collaborator-mode tasks, time gates), capped at 3-5. It should NOT be a chronological event stream.
2. **Why here:** next.md lines 39-42 render the cockpit. status.md also renders it.
3. **Current malfunction:** Glass cockpit shows last 8 events from SESSION-LOG.md chronologically. No filtering for decision-required items.
4. **Root cause:** The cockpit was implemented as an event tail (simple) rather than a decision filter (requires event classification).
5. **Ideal state per spec:** Glass cockpit shows 3-5 items that require user action: pending approvals, unresolved decisions, time gates, collaborator-mode tasks.
6. **Correct fix approach:** Replace `tail -12 SESSION-LOG.md` with a filtered query: grep SESSION-LOG.md and/or event-log.jsonl for decision-required events. Decision-required events: `pending_approval`, `collaborator`, `time_gate`, `blocked`, `veto`, `human_decision`. Cap at 5. If fewer than 3 decision items, pad with recent events.
7. **Downstream components affected:** `framework/commands/apex/next.md` (cockpit section), `framework/commands/apex/status.md` (cockpit section)
8. **Pre-fix changes required elsewhere:** session-log.sh event types must include decision-required markers (they already do: `auto_pause`, `coherence_fail`, etc.).
9. **Do-not-touch zones:** session-log.sh event type mapping — already correct.
10. **Non-obvious insights:** event-log.jsonl is better for filtering than SESSION-LOG.md (structured JSON vs. markdown). Use `jq` on event-log.jsonl to filter for decision-required types. Fallback to SESSION-LOG.md grep if jsonl doesn't exist.

### Execution plan

**Files to modify:**
- `framework/commands/apex/next.md` — replace cockpit tail with decision-filtered query
- `framework/commands/apex/status.md` — same change for cockpit section

**Files to create:** None

**Files that MUST remain untouched:**
- `framework/hooks/session-log.sh` — event types are correct

**Order of operations:**
1. Define decision-required event types: `pending_approval`, `auto_pause`, `time_gate`, `coherence_fail`, `veto`, `blocked`, `phantom_fail`
2. Replace next.md cockpit (lines 39-42): query event-log.jsonl for decision-required types, cap at 5, pad with recent events if <3
3. Apply same change to status.md cockpit section
4. Keep Live Ticker (tail -5) as-is — it's a different purpose (recent activity, not decisions)

**Rollback trigger:** Cockpit shows no items when decisions are pending.

### Acceptance criteria

- Criterion 1: Cockpit shows pending_approval events when they exist
- Criterion 2: Cockpit does NOT show routine events (checkpoint, resume) when decisions are pending
- Criterion 3: Cockpit caps at 5 items
- Criterion 4: Empty cockpit falls back to recent events (not blank)
- Regression check: next.md orchestration still works
- Spec re-check: "Glass cockpit with 3-5 decision-required items" — filtered, not flooded

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** R-023 (elapsed time display — both modify cockpit area)

### Risk assessment

- **Blast radius:** medium (modifies cockpit in two commands)
- **Reversibility:** moderate (cockpit rendering change)
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-016

**Linked finding:** F-016
**Spec anchor:** "Auditor agent that never touches implementation code — only test files."

### Ecosystem analysis

1. **Purpose of this component:** The auditor agent must be structurally quarantined from implementation code. It should ONLY read test files to maintain independent judgment.
2. **Why here:** Current quarantine is prompt-enforced (in auditor.md), not hook-enforced. A hallucinating auditor could breach quarantine.
3. **Current malfunction:** auditor.md has QUARANTINE PROTOCOL in the prompt with glob patterns. But the Bash tool is unconstrained by any external hook. No hook validates auditor's file access patterns.
4. **Root cause:** Prompt-based constraint vs. structural guarantee. The hook system wasn't designed for per-agent access control.
5. **Ideal state per spec:** Structural guarantee that auditor cannot touch implementation code.
6. **Correct fix approach:** Add a `quarantine-guard.sh` hook that, when the active agent is "auditor" (detectable via APEX_HOOK_SOURCE or STATE.json context), blocks Read/Bash operations on files NOT matching test patterns (`**/test/**`, `**/tests/**`, `**/__tests__/**`, `**/*.test.*`, `**/*.spec.*`). Wire as PreToolUse for Read|Bash when auditor is active.
7. **Downstream components affected:** `framework/settings.json` (new hook wiring), `framework/agents/auditor.md` (set APEX_HOOK_SOURCE)
8. **Pre-fix changes required elsewhere:** Need a mechanism to identify the active agent in hook context. Options: (a) environment variable set by next.md before spawning auditor, (b) STATE.json field indicating active agent.
9. **Do-not-touch zones:** auditor.md prompt quarantine — keep it as defense-in-depth alongside the hook.
10. **Non-obvious insights:** The hook system (settings.json matchers) triggers on ALL tool calls, not per-agent. A quarantine hook that fires on every Read/Bash would need to know the active agent context. This is architecturally novel for APEX — no existing hook is agent-aware. The simplest approach: set an env var `APEX_ACTIVE_AGENT=auditor` before spawning, check it in the hook. If the var isn't set (non-auditor context), pass through. This adds minimal overhead.

### Execution plan

**Files to create:**
- `framework/hooks/quarantine-guard.sh` — agent-aware file access control

**Files to modify:**
- `framework/commands/apex/next.md` — set APEX_ACTIVE_AGENT env var before spawning auditor
- `framework/settings.json` — wire quarantine-guard as PreToolUse on Read|Bash

**Files that MUST remain untouched:**
- `framework/agents/auditor.md` — keep prompt-level quarantine as defense-in-depth

**Order of operations:**
1. Create `quarantine-guard.sh`: if APEX_ACTIVE_AGENT == "auditor", validate file path against test patterns. Exit 2 if non-test file.
2. Modify next.md: before spawning auditor agent, export APEX_ACTIVE_AGENT=auditor. After auditor completes, unset.
3. Wire in settings.json as PreToolUse on Read|Bash
4. Test: auditor attempting to read src/main.ts → blocked. Auditor reading tests/main.test.ts → allowed.

**Rollback trigger:** Hook blocks legitimate tool calls for non-auditor agents.

### Acceptance criteria

- Criterion 1: Auditor agent cannot read files outside test directories (structurally enforced)
- Criterion 2: Non-auditor agents are NOT affected by quarantine-guard
- Criterion 3: Auditor can still read test files normally
- Regression check: All existing hook tests pass. Non-auditor workflows unaffected.
- Spec re-check: "Auditor never touches implementation code" — structurally guaranteed

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** R-026 (hook wiring changes to settings.json)

### Risk assessment

- **Blast radius:** high (new PreToolUse hook on Read|Bash — fires on ALL reads)
- **Reversibility:** moderate (remove hook from settings.json to disable)
- **Confidence in fix approach:** medium (agent-aware hooks are architecturally novel — needs careful testing)
- **Requires human decision:** YES — Is the overhead of checking APEX_ACTIVE_AGENT on every Read|Bash acceptable? The check is a single env var comparison (microseconds), so likely yes. But confirm.

---

## Remediation R-017

**Linked finding:** F-017
**Spec anchor:** "Scale-Adaptive Classifier in onboarding. APEX infers scale automatically... User-facing complexity is a 4-button menu."

### Ecosystem analysis

1. **Purpose of this component:** Present complexity levels as user-friendly names with auto-recommendation, not technical L1-L4 labels.
2. **Why here:** onboard.md line 56 displays "Suggested complexity level: L[N] — [name]. Override? (y/N or specify level 1-4)" — exposing technical labels.
3. **Current malfunction:** User sees "L3" instead of "Going to production [recommended]". The technical leak contradicts "first-hour usability for non-programmers."
4. **Root cause:** The auto-detection was built correctly, but the UX presentation layer wasn't adapted for non-technical users.
5. **Ideal state per spec:** "User-facing complexity is a 4-button menu" with friendly names, auto-selected, no technical labels.
6. **Correct fix approach:** Replace the L1-L4 prompt in onboard.md with a numbered menu showing friendly names, with [recommended] tag on the auto-detected level. Remove "Override? (y/N or specify level 1-4)".
7. **Downstream components affected:** `framework/commands/apex/onboard.md`
8. **Pre-fix changes required elsewhere:** None.
9. **Do-not-touch zones:** Auto-detection logic (LOC, tests, CI, Docker, contributors) — keep it.
10. **Non-obvious insights:** The internal representation should remain L1-L4 in STATE.json. Only the USER-FACING prompt changes. The mapping: L1 = "Trying it out", L2 = "Building something real", L3 = "Going to production", L4 = "My business depends on this" — these exact names are in the spec.

### Execution plan

**Files to modify:**
- `framework/commands/apex/onboard.md` — replace L1-L4 prompt with friendly 4-button menu

**Files to create:** None

**Files that MUST remain untouched:**
- Auto-detection logic in onboard.md (LOC, tests, CI analysis)
- STATE.json complexity_level (remains L1-L4 internally)

**Order of operations:**
1. Replace onboard.md line 56 prompt with:
   ```
   "Based on your project, I recommend:
   
   1. Trying it out — small experiments, scripts
   2. Building something real — medium projects with some tests
   3. Going to production — production-bound with CI/CD [recommended]
   4. My business depends on this — critical enterprise systems
   
   Select (1-4) or press Enter for [recommended]:"
   ```
   (with [recommended] on the auto-detected level)
2. Map user selection back to L1-L4 for STATE.json

**Rollback trigger:** N/A (UX change only)

### Acceptance criteria

- Criterion 1: User never sees "L1", "L2", "L3", "L4" labels
- Criterion 2: Auto-detected level shows [recommended] tag
- Criterion 3: User can select by number (1-4) or press Enter for recommended
- Criterion 4: STATE.json still stores complexity_level as numeric (1-4)
- Regression check: onboard→start flow still works
- Spec re-check: "User-facing complexity is a 4-button menu" — friendly names, auto-selected

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low (single file UX change)
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-018

**Linked finding:** F-018
**Spec anchor:** "/apex:build and /apex:refine as separate pipelines."

### Ecosystem analysis

1. **Purpose of this component:** Build creates new features; refine improves existing code. The spec says these are "different pipelines."
2. **Why here:** Both route through next.md orchestration with different framing.
3. **Current malfunction:** Both share the same executor→critic→verifier pipeline. The "different pipeline" claim is weak.
4. **Root cause:** The semantic difference between build and refine is in the PLANNING phase (different architect constraints), not the execution phase.
5. **Ideal state per spec:** "Build, refine, and onboard are different pipelines."
6. **Correct fix approach:** **PARTIALLY ADDRESSED** — git commit 80789e9 ("R-021 — refine pipeline as distinct from build") suggests this was already worked on. The difference should be: (a) Build: architect plans from spec requirements. (b) Refine: architect plans from existing code analysis + improvement goals. The execution pipeline (executor→critic→verifier) is intentionally shared — it's the planning that differs. Verify current state of build.md and refine.md. If already differentiated in planning: close as fixed.
7. **Downstream components affected:** `framework/commands/apex/build.md`, `framework/commands/apex/refine.md`
8. **Pre-fix changes required elsewhere:** None.
9. **Do-not-touch zones:** Shared execution pipeline (executor→critic→verifier) — intentionally shared.
10. **Non-obvious insights:** The spec principle "Build, refine, and onboard are different pipelines" may mean different ENTRY POINTS and PLANNING CONSTRAINTS, not different execution engines. The executor doesn't need to know if it's "building" or "refining" — it follows the plan. The differentiation is at architect level.

### Execution plan

**Files to modify:**
- `framework/commands/apex/build.md` — verify planning phase is distinct from refine
- `framework/commands/apex/refine.md` — verify planning phase is distinct from build

**Order of operations:**
1. Read current build.md and refine.md (post commit 80789e9)
2. Verify they have distinct architect instructions (build: from spec, refine: from code analysis)
3. If already differentiated: close as fixed
4. If not: add distinct planning constraints

**Rollback trigger:** N/A

### Acceptance criteria

- Criterion 1: build.md and refine.md have distinct architect planning instructions
- Criterion 2: Build plans from spec requirements
- Criterion 3: Refine plans from existing code analysis
- Regression check: Both commands still route to next.md for execution
- Spec re-check: "Build, refine, and onboard are different pipelines" — different planning, shared execution

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-019

**Linked finding:** F-019
**Spec anchor:** "Decision gates per 60-90 minutes."

### Ecosystem analysis

1. **Purpose of this component:** Periodic decision gates that pause execution to check in with the user.
2. **Why here:** next.md lines 118-138 implement time-based decision gate at fixed 60-minute intervals.
3. **Current malfunction:** Minor — gate fires at exactly 60 minutes, not adaptive between 60-90.
4. **Root cause:** Simple implementation with fixed threshold.
5. **Ideal state per spec:** "Decision gates per 60-90 minutes" — could mean adaptive interval.
6. **Correct fix approach:** The current 60-minute fixed gate is ACCEPTABLE. The spec says "per 60-90 minutes" which is reasonably interpreted as "within the 60-90 minute range." The implementation fires at 60 minutes (lower bound). This is P3 — the mechanism works.
7. **Downstream components affected:** None.
8. **Pre-fix changes required elsewhere:** None.
9. **Do-not-touch zones:** next.md time gate logic — it works.
10. **Non-obvious insights:** Making it adaptive (60 min for L1-L2, 90 min for L3-L4) would add unnecessary complexity for minimal UX gain. The 60-minute interval is safe because it's the lower bound — no user waits too long.

### Execution plan

**WONTFIX** — current implementation is within spec range (60 minutes is within "60-90 minutes").

### Acceptance criteria

- Criterion 1: Decision gate fires at 60-minute intervals (confirmed in next.md:124)
- Spec re-check: "Decision gates per 60-90 minutes" — 60 is within range

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** N/A
- **Reversibility:** N/A
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-020

**Linked finding:** F-020
**Spec anchor:** "Cross-AI peer review optional." and "/apex:peer-review"

### Ecosystem analysis

1. **Purpose of this component:** Optional cross-AI (different vendor) peer review for independent quality assessment.
2. **Why here:** peer-review.md is one of the 6 stub commands (F-004).
3. **Current malfunction:** peer-review.md is "NOT YET IMPLEMENTED". No mechanism to invoke external AI.
4. **Root cause:** External AI integration requires API keys and vendor-specific adapters — architecturally complex.
5. **Ideal state per spec:** Optional cross-AI peer review as additional quality layer.
6. **Correct fix approach:** Build peer-review.md as an MCP-adapter command. Use MCP server tools (if available) or direct API calls to send code diff to an external AI for review. The command should: (a) collect the diff for the current phase, (b) format a review prompt, (c) send to external AI via MCP or API, (d) display the review, (e) record in DECISIONS.md. Mark as OPTIONAL (the spec says "optional").
7. **Downstream components affected:** `framework/commands/apex/peer-review.md`
8. **Pre-fix changes required elsewhere:** None — this is self-contained.
9. **Do-not-touch zones:** Cross-model critic (same vendor, different model) in next.md — this is the INTERNAL quality gate and must remain.
10. **Non-obvious insights:** Without a generic MCP adapter for external AI, this command may need vendor-specific implementations (OpenAI API, Google AI API, etc.). A pragmatic v1 could simply format the review request and ask the user to paste it into another AI tool, then paste back the response. Low-tech but functional.

### Execution plan

**Files to modify:**
- `framework/commands/apex/peer-review.md` — implement cross-AI review command

**Files to create:** None

**Order of operations:**
1. Implement peer-review.md:
   - Collect current phase diff and key files
   - Format review prompt (adversarial, focused on quality issues)
   - If MCP tools available for external AI: use them
   - If not: format for manual copy/paste workflow
   - Display review results
   - Record in DECISIONS.md
2. Mark as OPTIONAL in the command (spec says "optional")

**Rollback trigger:** N/A (new implementation of stub)

### Acceptance criteria

- Criterion 1: peer-review.md has executable logic (no "NOT YET IMPLEMENTED")
- Criterion 2: Command generates a formatted review request from phase diff
- Criterion 3: Command records review results in DECISIONS.md
- Regression check: Existing cross-model critic unaffected
- Spec re-check: "Cross-AI peer review optional" — command exists and is optional

### Dependencies

- **Blocks:** None
- **Blocked by:** None (but related to R-004)
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low (new command implementation)
- **Reversibility:** trivial (revert to stub)
- **Confidence in fix approach:** medium (external AI integration uncertainty)
- **Requires human decision:** YES — Which external AI vendor(s) should be supported? Or should it use the manual copy/paste approach?

---

## Remediation R-021

**Linked finding:** F-021
**Spec anchor:** "Structural contract for phase structure." and "Structural contract over flexibility."

### Ecosystem analysis

1. **Purpose of this component:** Runtime validation that phase directories contain expected files (PLAN_META.json, etc.) and no unexpected files.
2. **Why here:** DIRECTORY-CONTRACT.md documents the expected structure. No hook validates it at runtime.
3. **Current malfunction:** Directory structure is documented but not enforced.
4. **Root cause:** The pipeline creates directories correctly (mkdir -p), but doesn't validate that the structure remains intact.
5. **Ideal state per spec:** Structural contract enforced — directory structure validated at runtime.
6. **Correct fix approach:** Add a directory structure check to the phase verification step in next.md (verify_needed stage). When a phase completes, verify its directory contains required files (PLAN_META.json at minimum). This is lightweight — not a separate hook, just a check in the existing verification flow.
7. **Downstream components affected:** `framework/commands/apex/next.md` (verify_needed stage)
8. **Pre-fix changes required elsewhere:** None.
9. **Do-not-touch zones:** `framework/DIRECTORY-CONTRACT.md` — source of truth for expected structure.
10. **Non-obvious insights:** This is P3 because the pipeline CREATES the structure correctly. Violations only happen with manual intervention. The check is more about detecting corruption than preventing it.

### Execution plan

**Files to modify:**
- `framework/commands/apex/next.md` — add directory structure check at phase verification

**Files to create:** None

**Order of operations:**
1. At verify_needed stage in next.md, add: verify `.apex/phases/$PHASE/PLAN_META.json` exists
2. Advisory warning if required files missing (don't block — could be from manual cleanup)
3. Log to session-log if structure violation found

**Rollback trigger:** False warnings on valid phase directories.

### Acceptance criteria

- Criterion 1: Phase verification checks for PLAN_META.json existence
- Criterion 2: Missing required file produces advisory warning
- Regression check: Phase completion flow unaffected
- Spec re-check: "Structural contract enforced" — validated at phase verification

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-022

**Linked finding:** F-022
**Spec anchor:** "apex-workflow-guard.js" and "Indirect Prompt Injection through planning artifacts."

### Ecosystem analysis

1. **Purpose of this component:** Validate workflow recipe files for injection patterns before execution.
2. **Why here:** Workflow .md files contain executable instructions that Claude follows. A poisoned workflow is a high-value injection target.
3. **Current malfunction:** No validation step before executing workflow instructions.
4. **Root cause:** workflow-guard was never built (part of F-001).
5. **Ideal state per spec:** Workflow files validated against injection patterns before execution.
6. **Correct fix approach:** **Subsumed by R-001.** R-001 creates workflow-guard.sh and wires it into workflow.md. This finding is the specific application of the missing mechanism identified in F-001.

### Execution plan

**Subsumed by R-001.** No separate action needed.

### Dependencies

- **Blocks:** None
- **Blocked by:** R-001 (which creates workflow-guard.sh)
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** Covered by R-001
- **Reversibility:** Covered by R-001
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-023

**Linked finding:** F-023
**Spec anchor:** "Total elapsed time."

### Ecosystem analysis

1. **Purpose of this component:** Elapsed time as a reality anchor — part of anti-hallucination strategy. Should appear in all execution outputs, not just status dashboard.
2. **Why here:** status.md displays elapsed time. next.md Glass Cockpit does not.
3. **Current malfunction:** Elapsed time visible only in /apex:status, not in /apex:next outputs.
4. **Root cause:** Elapsed time computation was added to status.md but not propagated to next.md cockpit.
5. **Ideal state per spec:** Elapsed time visible in all execution outputs.
6. **Correct fix approach:** Add elapsed time to next.md Glass Cockpit ambient header. Compute from STATE.created_at.
7. **Downstream components affected:** `framework/commands/apex/next.md` (cockpit header)
8. **Pre-fix changes required elsewhere:** None.
9. **Do-not-touch zones:** `framework/commands/apex/status.md` — already correct.
10. **Non-obvious insights:** The computation is simple: `now - STATE.created_at`. Already implemented in status.md. Just replicate in next.md cockpit.

### Execution plan

**Files to modify:**
- `framework/commands/apex/next.md` — add elapsed time to Glass Cockpit header

**Order of operations:**
1. Add elapsed time computation to cockpit header section (after line 42)
2. Format as "[N]d [N]h" matching status.md format

**Rollback trigger:** N/A

### Acceptance criteria

- Criterion 1: /apex:next output includes elapsed time in cockpit header
- Criterion 2: Format matches status.md ("[N]d [N]h")
- Regression check: next.md orchestration unaffected
- Spec re-check: "Total elapsed time" — visible in execution outputs

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** R-015 (both modify cockpit area — serialize)

### Risk assessment

- **Blast radius:** low
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-024

**Linked finding:** F-024
**Spec anchor:** "Context engineering at state-of-the-art. Observation masking."

### Ecosystem analysis

1. **Purpose of this component:** Stale observations (old tool outputs) are masked (summarized/removed) to free context space for fresh information.
2. **Why here:** Context engineering ensures the LLM's limited context window is used optimally.
3. **Current malfunction:** pre-compact.sh mentions "observation masking tracking" in a comment. CONTEXT_BUDGET.schema.json defines `working_memory` zone. STATE.json has `observation_masking_active: true`. But no mechanism actually masks stale observations.
4. **Root cause:** The infrastructure (flags, schema fields, comments) was laid; the mechanism was not built.
5. **Ideal state per spec:** Stale observations summarized/removed from agent context.
6. **Correct fix approach:** Observation masking in Claude Code is primarily about how context is composed in next.md's executor dispatch. The zone-based system (Zone 1: Stable Prefix, Zone 2: JIT per task, Zone 3: Working Memory) IS observation masking — Zone 1 is cached (not re-read), Zone 3 is volatile (replaced per task). The gap is that this mechanism isn't documented as "observation masking" and doesn't actively SUMMARIZE old observations — it replaces them. Add: (a) Document the zone system as the observation masking implementation in DIRECTORY-CONTRACT.md. (b) In next.md, when dispatching executor, explicitly note that previous task's tool outputs are NOT included (they're in Zone 3 of the PREVIOUS task, not carried forward). (c) Consider: pre-compact.sh could summarize the last N tool outputs before compaction.
7. **Downstream components affected:** `framework/commands/apex/next.md`, `framework/hooks/pre-compact.sh`
8. **Pre-fix changes required elsewhere:** None.
9. **Do-not-touch zones:** Zone-based context system in next.md — it works, just needs documentation.
10. **Non-obvious insights:** Claude Code itself manages context compaction. APEX's role is to structure context so that WHEN compaction happens, critical information (task spec, acceptance criteria, reflexion) survives. The "NEVER trim" rules in next.md (task_xml, acceptance_criteria, reflexion_brief) ARE observation masking — they define what's protected and what's expendable. The gap is labeling, not mechanism.

### Execution plan

**Files to modify:**
- `framework/DIRECTORY-CONTRACT.md` — document observation masking via zone system
- `framework/commands/apex/next.md` — add explicit "observation masking" label to the zone-based context dispatch section

**Files to create:** None

**Order of operations:**
1. Document zone system as observation masking in DIRECTORY-CONTRACT.md
2. Label the zone system in next.md as "Observation Masking Protocol"
3. Verify NEVER-trim rules protect critical context

**Rollback trigger:** N/A (documentation only)

### Acceptance criteria

- Criterion 1: Observation masking documented as zone-based context management
- Criterion 2: next.md zone system labeled as observation masking
- Criterion 3: NEVER-trim rules explicitly listed
- Regression check: Context dispatch in next.md unaffected
- Spec re-check: "Observation masking" — implemented via zone system, documented

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low (documentation + labeling)
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-025

**Linked finding:** F-025
**Spec anchor:** Workflow recipe pattern requires "Security Invariants" per established pattern.

### Ecosystem analysis

1. **Purpose of this component:** All workflow recipes must include Security Invariants section.
2. **Why here:** Two original workflows (migrate-to-postgres.md, setup-ci-cd.md) lacked Security Invariants.
3. **Current malfunction:** **ALREADY FIXED.** Both files now have Security Invariants sections:
   - `migrate-to-postgres.md` lines 57-63: Security Invariants with 5 items (env vars, SSL, least-privilege, file cleanup, role separation)
   - `setup-ci-cd.md` lines 49-55: Security Invariants with 5 items (secrets vault, no echo, least-privilege tokens, SHA pinning, fork secret protection)
4. **Root cause:** Was missing at audit time, now fixed.
5. **Ideal state per spec:** All workflows have Security Invariants.
6. **Correct fix approach:** Already fixed. Verify only.

### Execution plan

**Already fixed.** Verify only.

### Acceptance criteria

- Criterion 1: migrate-to-postgres.md has Security Invariants section (confirmed)
- Criterion 2: setup-ci-cd.md has Security Invariants section (confirmed)
- Spec re-check: 31/31 workflows have Security Invariants

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** N/A (already fixed)
- **Reversibility:** N/A
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-026

**Linked finding:** F-026
**Spec anchor:** "Hook system — 24+ hooks" and settings.json hook matchers.

### Ecosystem analysis

1. **Purpose of this component:** Hooks should be structurally enforced (auto-fired via settings.json), not depend on prompt compliance.
2. **Why here:** 7 of 22 hooks are auto-fired via settings.json. 15 are manually invoked by command .md files.
3. **Current malfunction:** Manually-invoked hooks can be silently skipped by a hallucinating agent.
4. **Root cause:** Design choice — some hooks are correctly manual (they fire at specific pipeline points, not on every tool call). But some should be structural.
5. **Ideal state per spec:** All hooks active and enforced.
6. **Correct fix approach:** NOT all 15 manual hooks should become auto-fired. Many are correctly invoked at specific pipeline points (e.g., phase-tag at phase completion, cross-phase-audit at phase boundary). The gap is for hooks that SHOULD be structural but aren't:
   - `phantom-check.sh` — could be PostToolUse on Write when file is SUMMARY.md
   - `context-monitor.sh` — could be PreToolUse on Agent (check budget before spawning)
   - Other hooks (session-log, phase-tag, generate-task-map, etc.) are correctly manual — they fire at pipeline orchestration points, not on individual tool calls.
7. **Downstream components affected:** `framework/settings.json`
8. **Pre-fix changes required elsewhere:** None.
9. **Do-not-touch zones:** Pipeline-point hooks (phase-tag, cross-phase-audit, mutation-gate, etc.) — keep as manual invocation from next.md.
10. **Non-obvious insights:** Making all hooks auto-fire would cause: (a) massive overhead (every tool call triggers 22 hooks), (b) false positives (phantom-check running on non-SUMMARY files), (c) incorrect timing (phase-tag running before phase completes). The right approach is SELECTIVE structural enforcement for the 2-3 hooks that benefit from it.

### Execution plan

**Files to modify:**
- `framework/settings.json` — add 1-2 strategic hooks

**Files to create:** None

**Files that MUST remain untouched:**
- All hook scripts — no modification needed
- Pipeline-point invocations in next.md — keep them

**Order of operations:**
1. Evaluate each manual hook for structural enforcement suitability:
   - phantom-check.sh: YES — could fire PostToolUse on Write when file matches *SUMMARY.md
   - context-monitor.sh: MAYBE — could fire PreToolUse on Agent (budget check before spawning)
   - session-log.sh: NO — event-specific, fires at pipeline points
   - phase-tag.sh: NO — phase completion only
   - cross-phase-audit.sh: NO — phase boundary only
   - mutation-gate.sh: NO — after critic PASS only
   - generate-task-map.sh: NO — before executor only
   - pre-compact.sh: NO — before compaction only
   - tdad-index.sh: NO — once after architect
   - verify-learnings.sh: NO — on-demand
   - subagent-stop.sh: MAYBE — could fire PostToolUse on Agent
2. Add phantom-check.sh as PostToolUse on Write with file pattern filter for *SUMMARY.md
3. Consider adding context-monitor.sh as PreToolUse on Agent
4. Document the manual-vs-structural decision rationale

**Rollback trigger:** New structural hooks cause false positives or performance degradation.

### Acceptance criteria

- Criterion 1: phantom-check.sh fires automatically when SUMMARY.md is written
- Criterion 2: Pipeline-point hooks remain manual (no false fires)
- Criterion 3: Performance: <100ms overhead per tool call from new structural hooks
- Regression check: All existing hook tests pass. Pipeline orchestration unaffected.
- Spec re-check: "All hooks active and enforced" — structural where appropriate, pipeline-point where needed

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** R-016 (both modify settings.json — serialize changes)

### Risk assessment

- **Blast radius:** medium (settings.json affects all tool calls)
- **Reversibility:** moderate (remove entries from settings.json)
- **Confidence in fix approach:** medium (need to verify file pattern filtering in settings.json matchers)
- **Requires human decision:** YES — Which manual hooks should become structural? Recommendation: only phantom-check.sh. context-monitor and subagent-stop have timing sensitivity that makes auto-fire risky.

---

## Remediation R-027

**Linked finding:** F-027
**Spec anchor:** "APEX_STRICT_MODE=1" and "Strict mode before commitment."

### Ecosystem analysis

1. **Purpose of this component:** Strict mode auto-activates before shipping/commitment — all tasks treated as verify_level D.
2. **Why here:** ship.md runs full verification but does NOT activate STRICT_MODE.
3. **Current malfunction:** STRICT_MODE is opt-in only (manual env var or STATE.json toggle). No automatic activation at ship time.
4. **Root cause:** ship.md was built as a verification-and-tag command. STRICT_MODE activation wasn't wired in.
5. **Ideal state per spec:** "Strict mode before commitment" — automatic activation at ship/release time.
6. **Correct fix approach:** Add `STATE.strict_mode = true` at the beginning of ship.md's procedure (before running full test suite). This ensures all verification during ship runs at the highest strictness level.
7. **Downstream components affected:** `framework/commands/apex/ship.md`
8. **Pre-fix changes required elsewhere:** None — verifier.md already reads STRICT_MODE.
9. **Do-not-touch zones:** verifier.md STRICT_MODE logic — already correct.
10. **Non-obvious insights:** STRICT_MODE during ship is temporary — after ship completes, it should revert. But since ship is a terminal command (project is "shipped"), reversion doesn't matter. If the user continues working after ship, they'd run /apex:start for a new cycle.

### Execution plan

**Files to modify:**
- `framework/commands/apex/ship.md` — add STRICT_MODE activation at procedure start

**Files to create:** None

**Order of operations:**
1. Add to ship.md step 1 (after reading STATE.json): `STATE.strict_mode = true`, write updated STATE.json
2. This ensures steps 2-4 (test suite, cross-phase audit, unresolved items) all run under strict mode

**Rollback trigger:** STRICT_MODE breaks ship verification flow.

### Acceptance criteria

- Criterion 1: ship.md sets strict_mode = true before running verification
- Criterion 2: Verification commands run at D-level strictness
- Regression check: ship.md still creates release tags correctly
- Spec re-check: "Strict mode before commitment" — automatically activated at ship time

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low (single line addition to ship.md)
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-028

**Linked finding:** F-028
**Spec anchor:** "APEX.md + PROJECT-APEX.md (Two-Tier Methodology)."

### Ecosystem analysis

1. **Purpose of this component:** Two-tier methodology — APEX.md (framework defaults) + PROJECT-APEX.md (project overrides) must both be present and consistent.
2. **Why here:** Templates exist (APEX-TEMPLATE.md, PROJECT-APEX-TEMPLATE.md). /apex:start copies them. But no hook validates target projects have both files.
3. **Current malfunction:** No enforcement that both files exist in target project.
4. **Root cause:** start.md creates the files but no ongoing validation ensures they persist.
5. **Ideal state per spec:** Two-tier methodology enforced — both files present.
6. **Correct fix approach:** Add a check to /apex:next (build stage start): verify .apex/APEX.md and .apex/PROJECT-APEX.md exist. Advisory warning if missing. This is P3 — the files are created by start.md, so they'll only be missing if manually deleted.
7. **Downstream components affected:** `framework/commands/apex/next.md`
8. **Pre-fix changes required elsewhere:** None.
9. **Do-not-touch zones:** Template files — correct.
10. **Non-obvious insights:** This is a very low-priority check. The files are created at init and rarely touched. A missing file indicates manual deletion or corruption, which is unlikely in normal operation.

### Execution plan

**Files to modify:**
- `framework/commands/apex/next.md` — add two-tier file existence check

**Order of operations:**
1. Add advisory check at build stage start: if .apex/APEX.md OR .apex/PROJECT-APEX.md missing → warn

**Rollback trigger:** False warnings.

### Acceptance criteria

- Criterion 1: Missing APEX.md produces advisory warning in /apex:next
- Criterion 2: Both files present → no warning
- Regression check: next.md orchestration unaffected
- Spec re-check: "Two-tier methodology" — presence validated

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Dependency DAG

```
R-001 ──blocks──→ R-022 (workflow-guard is subset of R-001)
R-003 ──blocks──→ R-004 (new-agent needs module boundary docs)
R-003 ──blocks──→ R-009 (PEP 420 needs module separation)
R-011 ──blocks──→ R-012 (dream-cycle needs directories — already fixed)
R-004 ←──related──→ R-020 (peer-review is one of the 6 stubs)

Execution order by DAG layers:

Layer 0 (no dependencies — can parallelize):
  R-002 (WONTFIX), R-005, R-006, R-007, R-008, R-010, R-011 (verify only),
  R-013, R-014, R-015, R-017, R-018, R-019 (WONTFIX), R-023, R-024,
  R-025 (verify only), R-026, R-027, R-028

Layer 1 (depends on Layer 0):
  R-001 (no deps but high effort — strategic placement)
  R-003 (WONTFIX for v1)
  R-012 (depends on R-011 which is already fixed)

Layer 2 (depends on Layer 1):
  R-022 (blocked by R-001)
  R-004 (blocked by R-003 for new-agent)
  R-009 (WONTFIX, blocked by R-003)

Layer 3 (depends on Layer 2):
  R-020 (related to R-004)

No cycles detected.
```

---

## Conflict Matrix

Files touched by multiple R-IDs:

| File | R-IDs | Resolution |
|------|-------|------------|
| `framework/commands/apex/next.md` | R-005, R-012, R-014, R-015, R-016, R-021, R-023, R-028 | **SERIALIZE ALL.** next.md is the orchestration heart. Apply changes sequentially: R-014 (spec drift check) → R-015 (cockpit filter) → R-023 (elapsed time) → R-005 (Wave 0) → R-012 (dream-cycle trigger) → R-016 (agent env var) → R-021 (dir check) → R-028 (two-tier check). |
| `framework/settings.json` | R-001, R-013, R-016, R-026 | **SERIALIZE.** All add hook entries. Apply: R-026 (phantom-check structural) → R-001 (workflow-guard) → R-013 (ast-kb-check) → R-016 (quarantine-guard). |
| `framework/hooks/post-write.sh` | R-006 | No conflict — single R-ID. |
| `framework/hooks/phase-tag.sh` | R-007 | No conflict — single R-ID. |
| `framework/commands/apex/workflow.md` | R-001 | No conflict — single R-ID. |
| `framework/commands/apex/onboard.md` | R-017 | No conflict — single R-ID. |
| `framework/commands/apex/ship.md` | R-027 | No conflict — single R-ID. |
| `framework/DIRECTORY-CONTRACT.md` | R-003, R-008, R-024 | **SERIALIZE.** Different sections — low risk but serialize for safety. |
| `framework/apex-branding.md` | R-010 | No conflict — single R-ID. |
| `framework/commands/apex/status.md` | R-015 | No conflict — single R-ID. |
| `framework/agents/test-architect.md` | R-005 | No conflict — single R-ID. |

**Critical conflict zone:** `next.md` is modified by 8 remediations. Each must be applied and tested independently before the next. Recommended serialization order above minimizes merge conflicts (independent sections first, then interconnected sections).

---

## Spec Contradictions

**SC-001 (from audit):** Shell hooks vs. JS security files.
- F-001 and R-001 resolve this: .sh implementations satisfy functional requirements. Spec should be amended to remove .js filenames.
- **No R-ID conflict.** R-001 handles this.

**SC-002 (from audit):** SQLite+FTS5 vs. JSON state.
- R-002 resolves this: WONTFIX with spec amendment. JSONL migration path documented.
- **No R-ID conflict.** R-002 handles this.

**No new contradictions discovered during planning.**

---

## New findings discovered during planning

1. **NF-001: DORA change_failure_rate computed in command pseudocode, not hook.**
   - next.md line 593 computes `change_failure_rate = phases_failed / phases_completed`. This is command-level logic, not hook enforcement. phase-tag.sh (which already writes lead_time and deployment_freq) would be the natural location. R-007 addresses moving this.

2. **NF-002: quarantine-guard.sh introduces agent-aware hook architecture.**
   - R-016 proposes APEX_ACTIVE_AGENT env var. This is a NEW architectural pattern — no existing hook is agent-aware. If adopted, other per-agent restrictions could follow. Should be documented as an architectural decision.

3. **NF-003: subagent-stop.sh is not wired in settings.json.**
   - subagent-stop.sh detects hallucinated agents (zero tool calls, zero changes). It could benefit from PostToolUse auto-firing on Agent completion. Currently manually invoked. Not in the audit findings — discovered during R-026 analysis.

4. **NF-004: event-log.jsonl event types may need expansion for cockpit filtering.**
   - R-015 proposes filtering cockpit by decision-required events. If event-log.jsonl doesn't tag events with a `requires_decision: true` field, the filtering would need regex on event types. Consider adding a structured field.

---

## Summary

| R-ID | F-ID | Status | Priority | Action |
|------|------|--------|----------|--------|
| R-001 | F-001 | PLAN READY | P0 | Build workflow-guard.sh, ci-scan.sh, _security-common.sh |
| R-002 | F-002 | WONTFIX | P0 | Spec amendment (SQLite → JSONL-ready) |
| R-003 | F-003 | WONTFIX v1 | P0 | Logical boundaries documentation |
| R-004 | F-004 | PLAN READY | P0 | Build 6 stub commands |
| R-005 | F-005 | PLAN READY | P1 | Wave 0 in next.md + test-architect phase mode |
| R-006 | F-006 | PLAN READY | P1 | Skipped-test detection in post-write.sh |
| R-007 | F-007 | PLAN READY | P1 | Move change_failure_rate to phase-tag.sh |
| R-008 | F-008 | PLAN READY | P1 | U-shaped guidelines + health-check audit |
| R-009 | F-009 | WONTFIX v1 | P2 | Blocked by R-003 |
| R-010 | F-010 | PLAN READY | P2 | Color discipline in branding + audit |
| R-011 | F-011 | ALREADY FIXED | P2 | Verify only |
| R-012 | F-012 | PLAN READY | P2 | Dream-cycle time trigger in next.md |
| R-013 | F-013 | PLAN READY | P1 | AST-KB import validation hook |
| R-014 | F-014 | PLAN READY | P2 | Spec drift check in next.md |
| R-015 | F-015 | PLAN READY | P2 | Cockpit decision filter |
| R-016 | F-016 | PLAN READY | P2 | Quarantine-guard.sh with agent awareness |
| R-017 | F-017 | PLAN READY | P1 | Friendly preset names in onboard.md |
| R-018 | F-018 | VERIFY | P2 | Check if already differentiated post-80789e9 |
| R-019 | F-019 | WONTFIX | P3 | 60 min is within 60-90 range |
| R-020 | F-020 | PLAN READY | P1 | Cross-AI peer review command |
| R-021 | F-021 | PLAN READY | P3 | Directory structure check in next.md verify |
| R-022 | F-022 | SUBSUMED by R-001 | P1 | No separate action |
| R-023 | F-023 | PLAN READY | P3 | Elapsed time in next.md cockpit |
| R-024 | F-024 | PLAN READY | P2 | Document zone system as observation masking |
| R-025 | F-025 | ALREADY FIXED | P3 | Verify only |
| R-026 | F-026 | PLAN READY | P1 | Selective structural hook enforcement |
| R-027 | F-027 | PLAN READY | P3 | STRICT_MODE auto-activation in ship.md |
| R-028 | F-028 | PLAN READY | P3 | Two-tier file check in next.md |

**Human decisions required:** R-001, R-002, R-003, R-004, R-013, R-016, R-020, R-026 (8 of 28)
