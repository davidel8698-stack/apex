# APEX Audit Findings — Round R1

**Audit date:** 2026-04-12
**Auditor:** Claude Opus 4.6 (Auditor Agent mode)
**Spec anchor:** User-provided APEX ideal definition (inline in prompt)
**Codebase snapshot:** commit 80789e9 (master branch)

---

## Executive Summary

**Total findings: 28** (4 P0, 8 P1, 10 P2, 6 P3)

**Severity distribution:**
- P0 (spec-core contradiction, multi-failure): 4
- P1 (explicit spec violation, single failure): 8
- P2 (dormant/partial mechanism): 10
- P3 (declaration without enforcement, low blast radius): 6

**Top 3 themes:**
1. **Defense-in-Depth is hollow** — 3 of 6 named security mechanisms (workflow-guard.js, security.cjs, CI scanner) don't exist. The spec promises a security *layer*; what's built is a security *collection of shell scripts*.
2. **Spec declares capabilities that have no executable implementation** — SQLite+FTS5, Nyquist Validation Layer, Wave 0 enforcement, PEP 420 namespace, skipped-test regression detection, color discipline are all spec promises with zero code behind them.
3. **Module ecosystem is monolithic** — Spec declares separate repos with independent lifecycles (apex-core, apex-frontend, apex-data, etc.); reality is a single `framework/` directory. `/apex:new-agent` is stubbed "NOT YET IMPLEMENTED".

---

## Coverage Map

| # | Axis | Findings | Confidence |
|---|------|----------|------------|
| 1 | Nine Failures (1-9) | 8 | HIGH — all 9 failures traced through hooks, agents, commands |
| 2 | Dual-mode (collaborator vs replacement) | 1 | HIGH — classifier exists in architect.md, enforced in next.md |
| 3 | Scale-Adaptive Classifier | 1 | HIGH — onboard.md has bash detection but no standalone module |
| 4 | First-hour usability for non-programmers | 2 | MEDIUM — would need real user testing to fully assess |
| 5 | /apex:help natural language navigator | 0 | HIGH — fully implemented with intent routing table |
| 6 | Test architecture as discipline with veto | 0 | HIGH — test-architect.md exists with veto, orchestrated in next.md F.5 |
| 7 | Auditor quarantine | 1 | HIGH — quarantine protocol in auditor.md reviewed |
| 8 | Module ecosystem as platform | 2 | HIGH — directory structure directly observable |
| 9 | Memory 3-tier + dream-cycle + 4 primitives + workflows | 2 | HIGH — agent and directories verified |
| 10 | Defense-in-Depth on APEX's own files | 3 | HIGH — file existence checks definitive |
| 11 | State derives from disk / proof-of-process | 2 | MEDIUM — would need runtime trace to fully confirm |
| 12 | 30+ core principles | 7 | MEDIUM — some principles are architectural and hard to verify statically |

---

## Blind Spots

1. **Runtime behavior** — All findings are from static analysis. Cannot confirm hooks actually fire in production pipelines without end-to-end execution.
2. **Cross-model critic enforcement** — Logic exists in next.md:443-449 and routing JSON, but whether Claude Code actually dispatches to a different model depends on runtime model availability. Static analysis confirms the code path exists.
3. **Branding/APEXSkin rendering** — apex-branding.md is 1000+ lines. Verified references exist in commands but didn't audit every frame for completeness.

---

## Contradictions Within Spec Itself

**SC-001: Shell hooks vs. JS security files**
The spec names `apex-prompt-guard.js`, `apex-workflow-guard.js`, `security.cjs` (JavaScript files) in the Defense-in-Depth section, but the build rules in CLAUDE.md say "Hooks are shell scripts (.sh)". The actual implementation uses `.sh` files (prompt-guard.sh, path-guard.sh, destructive-guard.sh). The spec's JS filenames contradict the framework's hook architecture.

**SC-002: SQLite+FTS5 vs. JSON state**
The spec says "State management hybrid: Markdown + SQLite+FTS5". But it also says "State derives from disk" and all schemas are JSON (STATE.json, PLAN_META.json, RESULT.json). The two state strategies contradict — no spec section describes how SQLite integrates with the JSON state files.

---

## Findings

---

## Finding F-001: Defense-in-Depth missing 3 of 6 named mechanisms

**Axis:** 10 — Defense-in-Depth on APEX's own files
**Severity:** P0
**Status:** CONFIRMED
**Spec anchor:** "Defense-in-Depth Security Layer: `apex-prompt-guard.js`, Path Traversal Prevention, `apex-workflow-guard.js`, CI scanner, `security.cjs` module."
**Evidence:** `framework/hooks/` contains prompt-guard.sh, path-guard.sh, destructive-guard.sh. No files named `apex-workflow-guard.js`, `security.cjs`, or any CI scanner script exist anywhere in the repo. Glob for `*.js` and `*.cjs` under framework/ returns zero results.
**Current behavior:** 3 shell-based guards exist (prompt-guard.sh, path-guard.sh, destructive-guard.sh). No workflow-guard, no security.cjs module, no CI scanner.
**Expected behavior (per spec):** 6 named security mechanisms all present and active.
**Gap:** 50% of Defense-in-Depth mechanisms are absent. Workflow injection, CI-level scanning, and the consolidated security module don't exist.
**Blast radius:** Failure 9 (Security gaps) — specifically Indirect Prompt Injection via workflow files is unguarded. Workflows in `apex-workflows/` are not validated by any guard before execution.
**Reproduction:** `find framework/ -name "*.js" -o -name "*.cjs"` returns empty. `find framework/ -name "*workflow-guard*"` returns empty. `find framework/ -name "*security.cjs*"` returns empty.
**Dependencies:** None.
**Out-of-scope note:** See SC-001 — the spec names .js files but CLAUDE.md says hooks are .sh. This may be a spec-internal contradiction rather than a build gap. However, regardless of extension, the *functionality* (workflow content validation, CI scanning, consolidated security module) is absent.
**Fix hints:** Either build .sh equivalents that validate workflow file content before execution, or acknowledge as spec contradiction and remove JS references.

---

## Finding F-002: SQLite+FTS5 control plane declared but not built

**Axis:** 11 — State derives from disk / proof-of-process
**Severity:** P0
**Status:** CONFIRMED
**Spec anchor:** "State management hybrid. Markdown + SQLite+FTS5."
**Evidence:** Zero `.db`, `.sqlite`, or SQLite-related files in the entire repo. No Python/JS code imports sqlite3 or better-sqlite3. All state is JSON (STATE.json, PLAN_META.json, RESULT.json) and Markdown (SESSION-LOG.md, DECISIONS.md).
**Current behavior:** Pure JSON+Markdown state management. No SQLite database.
**Expected behavior (per spec):** Hybrid state with SQLite+FTS5 for full-text search across project artifacts.
**Gap:** Entire SQLite layer is missing. FTS5 search capability doesn't exist.
**Blast radius:** Failure 2 (Forgetting) and Failure 3 (Context loss) — the FTS5 search was supposed to enable fast retrieval across sessions. Without it, memory queries rely on grep/glob over markdown files.
**Reproduction:** Static analysis only — `grep -r "sqlite" framework/` returns zero results.
**Dependencies:** None.
**Fix hints:** This is a major architectural component. May require phased implementation or explicit spec amendment to drop SQLite in favor of pure JSON+grep.

---

## Finding F-003: Module ecosystem is monolithic, not platform

**Axis:** 8 — Module ecosystem as platform
**Severity:** P0
**Status:** CONFIRMED
**Spec anchor:** "Module Ecosystem as Extension Model... APEX modular to separate repositories with independent lifecycles: apex-core, apex-frontend, apex-data, apex-security, apex-test-architect, apex-fintech, apex-healthcare, apex-builder. Each module separate repo, separate issues, separate versioning."
**Evidence:** All framework code lives under `framework/` in a single git repo. No evidence of separate repositories, separate package.json files, separate versioning, or module boundary enforcement. `framework/agents/specialist/` contains frontend, data, security, integration specialists as .md files in the same directory.
**Current behavior:** Single monolithic repo with all agents, hooks, commands in one directory tree.
**Expected behavior (per spec):** 8+ separate repositories with independent lifecycles, issues, versioning.
**Gap:** Zero modularization. No package boundaries, no independent versioning, no module lifecycle separation.
**Blast radius:** Branding position 12 ("Platform, Not Tool") and `/apex:new-agent` (NOT YET IMPLEMENTED). The ecosystem extension model that allows community contribution doesn't exist.
**Reproduction:** `ls framework/` shows flat structure. No `package.json`, `setup.py`, or module manifest files exist per-module.
**Dependencies:** F-004 (/apex:new-agent not implemented).
**Fix hints:** This may be acceptable for v1 launch as monorepo with logical boundaries, deferring physical separation. But the spec is explicit about separate repos.

---

## Finding F-004: 6 commands stubbed as "NOT YET IMPLEMENTED"

**Axis:** 8 — Module ecosystem as platform / 4 — First-hour usability
**Severity:** P0
**Status:** CONFIRMED
**Spec anchor:** "Pipeline commands complete: /apex:new-agent, /apex:new-workspace, /apex:peer-review, /apex:ui-review, /apex:ui-phase, /apex:milestone-summary" (all listed as required capabilities)
**Evidence:** Reading command files confirms stub status:
- `framework/commands/apex/new-agent.md` — "NOT YET IMPLEMENTED — deferred per apex-design-notes.md"
- `framework/commands/apex/new-workspace.md` — "NOT YET IMPLEMENTED"
- `framework/commands/apex/peer-review.md` — "NOT YET IMPLEMENTED"
- `framework/commands/apex/ui-review.md` — "NOT YET IMPLEMENTED"
- `framework/commands/apex/ui-phase.md` — "NOT YET IMPLEMENTED"
- `framework/commands/apex/milestone-summary.md` — "NOT YET IMPLEMENTED"
**Current behavior:** Commands exist as files with descriptions but contain no executable logic.
**Expected behavior (per spec):** All pipeline commands functional.
**Gap:** 6 commands are empty shells. /apex:new-agent is the foundation of the "Platform, Not Tool" branding. /apex:ui-phase is the foundation of the "6-pillar Design Contract". /apex:peer-review enables the cross-AI peer review. /apex:milestone-summary enables proof-of-process at milestone level.
**Blast radius:** Multiple spec promises depend on these: platform extensibility (new-agent), UI quality (ui-phase, ui-review), quality assurance (peer-review), and delivery visibility (milestone-summary).
**Reproduction:** Read each file — all contain "NOT YET IMPLEMENTED" text.
**Dependencies:** F-003 (module ecosystem requires new-agent).

---

## Finding F-005: Nyquist Validation Layer and Wave 0 enforcement absent

**Axis:** 1 — Nine Failures (Failure 5: Hallucination)
**Severity:** P1
**Status:** CONFIRMED
**Spec anchor:** "Nyquist Validation Layer with Wave 0 enforcement." and "Test infrastructure mapping before code."
**Evidence:** `grep -ri "nyquist\|wave.0\|wave_0" framework/` returns zero relevant results. No hook, agent, or command implements a "Wave 0" concept where test infrastructure is mapped before any code is written.
**Current behavior:** Test-architect runs before executor on C/D tasks (next.md F.5), but this is per-task, not per-phase. No Wave 0 concept exists.
**Expected behavior (per spec):** A validation layer that ensures test infrastructure is mapped at the phase level before any code execution begins (Wave 0).
**Gap:** The concept of a dedicated Wave 0 (test infrastructure before code) doesn't exist. Test-architect runs per-task, which is a different granularity.
**Blast radius:** Failure 5 (Hallucination) — test infrastructure gaps may not be caught until mid-execution.
**Reproduction:** Static analysis only — grep returns no matches.
**Dependencies:** None.
**Fix hints:** Could be implemented as a mandatory first step in /apex:execute-phase that runs test-architect at phase level before dispatching Wave 1.

---

## Finding F-006: Skipped-test regression detection missing

**Axis:** 1 — Nine Failures (Failure 6: Mutation)
**Severity:** P1
**Status:** CONFIRMED
**Spec anchor:** "Skipped-test regression detection."
**Evidence:** `grep -ri "skipped.test\|\.skip\(\)\|skip()\|\.only(" framework/hooks/` returns zero results. No hook scans test files for `.skip()`, `.only()`, `.pending()`, `xit(`, `xdescribe(` patterns.
**Current behavior:** Verifier detects *task-level* scope reduction (RESULT.json with status="skip"). No mechanism detects silently skipped individual tests within test files.
**Expected behavior (per spec):** Detection of skipped tests at the test-file level — when a developer or agent adds `.skip()` to bypass failing tests.
**Gap:** An executor could add `.skip()` to make tests pass, and no hook would catch it.
**Blast radius:** Failure 6 (Mutation) — silent test skipping is a core mutation vector.
**Reproduction:** Static analysis — no hook contains test-skip detection regex.
**Dependencies:** None.
**Fix hints:** Add a post-write hook that greps modified test files for `.skip(`, `.only(`, `xit(`, `xdescribe(`, `@pytest.mark.skip` patterns.

---

## Finding F-007: DORA metrics structure exists but no collection mechanism

**Axis:** 1 — Nine Failures (Failure 3: Context loss) / 12 — Core principles
**Severity:** P1
**Status:** CONFIRMED
**Spec anchor:** "DORA self-monitoring." and "The First Framework That Improves DORA."
**Evidence:** STATE.schema.json defines `dora` object with `lead_time_avg`, `deployment_freq`, `change_failure_rate`, `recovery_time_avg`. STATUS command (status.md:80-85) renders these fields. But no hook, command, or agent *writes* to these fields. grep for "dora.lead_time\|dora.deployment\|dora.change_failure\|dora.recovery_time" in hooks/ returns zero write operations.
**Current behavior:** DORA fields exist in schema and are displayed in dashboard, but always show "N/A" because nothing populates them.
**Expected behavior (per spec):** DORA metrics are self-monitored — lead time computed from phase start->complete, deployment frequency from phase completions per day, change failure rate from critic FAIL rate, recovery time from failure->recovery timestamps.
**Gap:** Read path exists. Write path doesn't. Branding position 6 ("The First Framework That Improves DORA") is unsubstantiated.
**Blast radius:** Proof-of-process for DORA improvement is hollow.
**Reproduction:** `grep -r "dora\." framework/hooks/ framework/agents/` — no write operations found. `grep -r "lead_time_avg" framework/hooks/` — zero results.
**Dependencies:** None.
**Fix hints:** Add DORA update logic to: phase-tag.sh (lead_time, deployment_freq), verifier verdict handler (change_failure_rate), recovery command (recovery_time).

---

## Finding F-008: U-shaped attention ordering is design note, not enforcement

**Axis:** 12 — Core principles ("U-shaped attention awareness")
**Severity:** P1
**Status:** CONFIRMED
**Spec anchor:** "U-shaped attention awareness." and "Context ordering by U-shape."
**Evidence:** `grep -ri "u-shaped\|u_shaped" framework/` returns exactly one result: `apex-design-notes.md:9: "Primacy-recency ordering: critical instructions first, task last (R2: U-shaped attention curve)"`. This is a design note, not an enforcement mechanism. context-monitor.sh monitors token *usage* but does not enforce context *ordering*.
**Current behavior:** U-shaped ordering is documented as a design principle in design notes. No hook or mechanism validates that context is actually ordered with critical instructions at start and end.
**Expected behavior (per spec):** Context engineering at state-of-the-art level with U-shaped ordering enforced.
**Gap:** The principle exists as documentation; there is no automated enforcement.
**Blast radius:** Failure 3 (Context loss) — middle-of-context instructions may be lost due to attention curve.
**Reproduction:** Static analysis — only one reference to U-shaped in entire codebase, and it's a design note.
**Dependencies:** None.
**Fix hints:** U-shaped ordering is inherently an architectural pattern in how prompts are composed, not a runtime hook. It may be enforced by how agent .md files structure their content (critical info at top and bottom). Verify agent prompt structure follows this pattern.

---

## Finding F-009: PEP 420 namespace not implemented

**Axis:** 12 — Core principles
**Severity:** P2
**Status:** CONFIRMED
**Spec anchor:** "PEP 420 namespace."
**Evidence:** `grep -ri "pep.420\|pep420\|namespace" framework/` returns only one hit for "namespace" in destructive-guard.sh (`kubectl delete namespace`), unrelated to PEP 420.
**Current behavior:** No namespace mechanism exists.
**Expected behavior (per spec):** PEP 420 namespace packaging for APEX modules.
**Gap:** Entire feature absent. Python namespace packages not implemented.
**Blast radius:** Low — primarily affects Python-based module distribution.
**Reproduction:** Static analysis only.
**Dependencies:** F-003 (module ecosystem).
**Fix hints:** May be deferred until module ecosystem is physically separated.

---

## Finding F-010: Color discipline absent

**Axis:** 12 — Core principles / 4 — First-hour usability
**Severity:** P2
**Status:** CONFIRMED
**Spec anchor:** "Color discipline." and "Color discipline" listed under both Failure 5 handling and UX principles.
**Evidence:** `grep -ri "color.discipline\|color_discipline" framework/` returns zero results. No hook, template, or configuration defines color semantics (e.g., green=verified, yellow=partial, red=failed).
**Current behavior:** Output uses emojis (checkmarks, warning signs) but no systematic color discipline.
**Expected behavior (per spec):** Consistent color semantics across all APEX output — colors have fixed meanings, not decorative.
**Gap:** No color system defined or enforced.
**Blast radius:** Failure 5 (Hallucination) — color discipline was part of the anti-fake-reporting strategy. Also UX for non-technical users.
**Reproduction:** Static analysis only.
**Dependencies:** None.
**Fix hints:** Define color semantics in apex-branding.md and enforce in rendering templates.

---

## Finding F-011: Memory primitive directories not created by framework

**Axis:** 9 — Memory 3-tier + dream-cycle + 4 primitives
**Severity:** P2
**Status:** CONFIRMED
**Spec anchor:** "Four primitives: apex/todos/, apex/threads/, apex/seeds/, apex/backlog/."
**Evidence:** memory-synthesis.md references `.apex/todos/`, `.apex/threads/`, `.apex/seeds/`, `.apex/backlog/` as working directories. But no command (start.md, onboard.md, next.md) creates these directories during project initialization. `glob .apex/todos/ .apex/threads/ .apex/seeds/ .apex/backlog/` returns empty.
**Current behavior:** Directories are referenced by the dream-cycle agent but never created by any init flow.
**Expected behavior (per spec):** Four memory primitive directories exist and are actively used.
**Gap:** The dream-cycle agent has nowhere to read from or write to. Memory primitives are structurally dead.
**Blast radius:** Failure 2 (Forgetting) — the entire retrospective/prospective/parking-lot memory layer is non-functional because the directories don't exist.
**Reproduction:** Check `.apex/` directory — only `STATE.json`, `CONTEXT_BUDGET.json`, `phases/` exist. No `todos/`, `threads/`, `seeds/`, `backlog/`.
**Dependencies:** None.
**Fix hints:** Add `mkdir -p .apex/{todos,threads,seeds,backlog}` to /apex:start initialization.

---

## Finding F-012: Dream-cycle only triggers on pause/resume, no standalone schedule

**Axis:** 9 — Memory 3-tier + dream-cycle
**Severity:** P2
**Status:** SUSPECTED
**Spec anchor:** "Memory Synthesis dream-cycle agent."
**Evidence:** memory-synthesis.md states "Runs during pause/resume transitions." The /apex:pause and /apex:resume commands reference it. But there is no scheduled/periodic trigger — if a user never pauses, the dream cycle never runs.
**Current behavior:** Dream cycle only runs when explicitly triggered by pause/resume flow.
**Expected behavior (per spec):** A "dream-cycle" implies periodic consolidation, not just on-demand.
**Gap:** Long sessions without pause/resume will accumulate stale todos, unarchived threads, and unprocessed seeds.
**Blast radius:** Failure 2 (Forgetting) — memory degrades in long sessions.
**Reproduction:** Static analysis — grep for memory-synthesis invocation only appears in pause/resume commands.
**Dependencies:** F-011 (directories must exist first).
**Fix hints:** Add dream-cycle trigger to /apex:next time-gate (every 60 minutes) or context rotation.

---

## Finding F-013: AST-KB Hallucination Gate not implemented

**Axis:** 1 — Nine Failures (Failure 5: Hallucination)
**Severity:** P1
**Status:** CONFIRMED
**Spec anchor:** "Phantom-check, AST-KB Hallucination Gate."
**Evidence:** phantom-check.sh exists and detects uncertainty language. But "AST-KB" (Abstract Syntax Tree - Knowledge Base validation that checks if imported modules/functions actually exist) has no implementation. No script parses AST or validates imports against installed packages.
**Current behavior:** Only language-level phantom detection (uncertainty phrases in SUMMARY.md).
**Expected behavior (per spec):** AST-level validation that catches hallucinated imports (spec cites "USENIX: 19.7% imports don't exist").
**Gap:** The most measurable hallucination vector (non-existent imports/APIs) is unguarded.
**Blast radius:** Failure 5 (Hallucination) — fake imports survive to production.
**Reproduction:** Static analysis — no AST parsing code exists in any hook or agent.
**Dependencies:** None.
**Fix hints:** Build a post-write hook that runs `node -e "require('module')"` or `python -c "import module"` on newly added imports.

---

## Finding F-014: SPEC_DELTA.json generated on-demand but not validated by drift detection

**Axis:** 1 — Nine Failures (Failure 4: Drift)
**Severity:** P2
**Status:** SUSPECTED
**Spec anchor:** "SPEC_VERSION hash + SPEC_DELTA.json."
**Evidence:** spec.md (lines 17-28) generates SPEC_DELTA.json when the spec is updated. STATE.schema.json has `spec_version` field. But no hook validates that `spec_version` in STATE.json matches the current SPEC.md hash during execution. schema-drift.sh validates JSON structure but not spec version consistency.
**Current behavior:** SPEC_DELTA.json is written when spec changes. But mid-execution, no mechanism detects that SPEC.md has drifted from what the plan was built against.
**Expected behavior (per spec):** SPEC_VERSION hash enables drift detection — if spec changes after planning, execution should be aware.
**Gap:** Drift detection is architectural (the mechanism exists) but not actively enforced during execution.
**Blast radius:** Failure 4 (Drift) — plan could be based on stale spec version.
**Reproduction:** Static analysis — no hook checks `spec_version` hash during /apex:next execution.
**Dependencies:** None.
**Fix hints:** Add spec_version hash check to /apex:next before dispatching executor.

---

## Finding F-015: Glass cockpit is partially implemented

**Axis:** 1 — Nine Failures (Failure 3: Context loss) / 4 — First-hour usability
**Severity:** P2
**Status:** CONFIRMED
**Spec anchor:** "Glass cockpit with 3-5 decision-required items at top."
**Evidence:** next.md (lines 39-42) implements "GLASS COCKPIT — AMBIENT HEADER" with Ambient Timeline (last 8 events) and Live Ticker (last 5 events). status.md (lines 24-27) also renders glass cockpit. But the spec describes "3-5 decision-required items" — the current implementation shows *events*, not *decision-required items*. There's no filtering for actionable decisions.
**Current behavior:** Glass cockpit shows recent events chronologically from SESSION-LOG.md.
**Expected behavior (per spec):** Glass cockpit filters to show only items requiring user decision, capped at 3-5.
**Gap:** Event stream vs. decision filter — the cockpit floods rather than filters.
**Blast radius:** Core principle violation: "Filter, don't flood."
**Reproduction:** Read next.md lines 39-42 — `tail -12 .apex/SESSION-LOG.md -> filter to last 8 event lines`. No decision-required filtering.
**Dependencies:** None.
**Fix hints:** Add grep for decision-required events (pending_approval, collaborator mode tasks, time gates) in the cockpit header.

---

## Finding F-016: Auditor quarantine has a potential breach path

**Axis:** 7 — Auditor quarantine
**Severity:** P2
**Status:** SUSPECTED
**Spec anchor:** "Auditor agent that never touches implementation code — only test files."
**Evidence:** auditor.md enforces QUARANTINE PROTOCOL with glob patterns (`**/test/**`, `**/tests/**`, `**/__tests__/**`, `**/*.test.*`, `**/*.spec.*`). However, it has `Tools: Read, Bash`. The Bash tool is constrained to "test directories" but the enforcement is in the agent prompt, not in a hook. If the agent hallucinates or ignores the constraint, no external mechanism prevents it from running `cat src/main.ts`.
**Current behavior:** Quarantine is prompt-enforced, not hook-enforced.
**Expected behavior (per spec):** Auditor *never* touches implementation — this should be structurally guaranteed.
**Gap:** Prompt-based constraint vs. structural guarantee. A hallucinating auditor could breach quarantine.
**Blast radius:** Failure 5 (Hallucination) — auditor reading implementation code would contaminate its test-only judgment.
**Reproduction:** Read auditor.md — "QUARANTINE PROTOCOL" is in the agent prompt. No hook validates auditor's file access patterns.
**Dependencies:** None.
**Fix hints:** Add a hook that blocks Read/Bash operations on non-test files when the active agent is "auditor".

---

## Finding F-017: Scale-Adaptive Classifier is embedded, not standalone

**Axis:** 3 — Scale-Adaptive Classifier
**Severity:** P1
**Status:** CONFIRMED
**Spec anchor:** "Scale-Adaptive Classifier in onboarding. APEX infers scale automatically... Instead of choosing preset, system guesses correctly and presents."
**Evidence:** onboard.md (lines 30-57) has a "Scale-Adaptive Classifier" that runs bash commands (LOC count, test files, CI detection, Docker, contributors) and maps to L1-L4. planner.md has "PHASE 0: Auto-Detection". But the user is asked "Override? (y/N or specify level 1-4)" — requiring them to evaluate a technical classification.
**Current behavior:** Classification runs automatically, presents result, asks for override with technical labels (L1-L4).
**Expected behavior (per spec):** "User-facing complexity is a 4-button menu" with friendly names ("Trying it out" / "Building something real" / "Going to production" / "My business depends on this"). Auto-selected by classifier, no technical labels exposed.
**Gap:** User sees "Suggested complexity level: L3" instead of "Going to production [recommended]". The technical leak contradicts "first-hour usability for non-programmers".
**Blast radius:** Failure 3 (Context loss) — wrong scale selection cascades through all ceremony levels.
**Reproduction:** Read onboard.md line 56: `"Suggested complexity level: L[N] — [name]. Override? (y/N or specify level 1-4)"`
**Dependencies:** None.
**Fix hints:** Replace L1-L4 with friendly preset names. Present as numbered options with [recommended] tag.

---

## Finding F-018: /apex:build and /apex:refine listed as separate pipelines but are thin wrappers

**Axis:** 1 — Nine Failures (Failure 4: Drift)
**Severity:** P2
**Status:** SUSPECTED
**Spec anchor:** "/apex:build and /apex:refine as separate pipelines."
**Evidence:** build.md and refine.md exist as commands. However, both ultimately route through the same /apex:next orchestration with different framing. The spec implies fundamentally different pipelines (build creates new, refine improves existing), but both share the same executor, critic, verifier flow.
**Current behavior:** Separate entry points with shared pipeline.
**Expected behavior (per spec):** "Build, refine, and onboard are different pipelines" — implying distinct execution paths, not just different labels.
**Gap:** The "different pipeline" claim may be satisfied by different ceremony levels and constraints, or may require truly separate orchestration. Marking as SUSPECTED because the semantic difference may be in the planning/spec phase rather than execution.
**Blast radius:** Low — functionally the pipeline works, but the separation claim is weak.
**Reproduction:** Read build.md and refine.md — both reference full review cycle (critic, clean-room, cross-model).
**Dependencies:** None.

---

## Finding F-019: Decision gates per 60-90 minutes partially implemented

**Axis:** 4 — First-hour usability
**Severity:** P3
**Status:** CONFIRMED
**Spec anchor:** "Decision gates per 60-90 minutes."
**Evidence:** next.md (lines 118-138) implements TIME-BASED DECISION GATE at 60-minute intervals. This matches the lower bound of "60-90 minutes". Implementation is correct.
**Current behavior:** Decision gate fires at 60-minute intervals, presents 3 options in Hebrew.
**Expected behavior (per spec):** Decision gates per 60-90 minutes.
**Gap:** Minor — gate is fixed at 60 minutes, not adaptive between 60-90. The spec says "per 60-90 minutes" which could mean the range, not a fixed interval. Marking as P3 because the mechanism exists and is functional.
**Blast radius:** None — mechanism works.
**Reproduction:** Read next.md lines 118-138.
**Dependencies:** None.

---

## Finding F-020: Cross-AI peer review has no implementation path

**Axis:** 1 — Nine Failures (Failure 7: Quality errors)
**Severity:** P1
**Status:** CONFIRMED
**Spec anchor:** "Cross-AI peer review optional." and "/apex:peer-review"
**Evidence:** peer-review.md is stubbed "NOT YET IMPLEMENTED". No mechanism exists to invoke an external AI (GPT-4, Gemini) for independent review. The cross-model critic within Claude Code (sonnet->opus) exists but is not cross-AI (different vendor).
**Current behavior:** Cross-model critic exists (same vendor, different model). Cross-AI (different vendor) review doesn't exist.
**Expected behavior (per spec):** Optional cross-AI peer review as additional quality layer.
**Gap:** /apex:peer-review is a dead command. The only quality gate is the internal cross-model critic.
**Blast radius:** Failure 7 (Quality errors) — single-vendor bias in quality assessment.
**Reproduction:** Read peer-review.md — "NOT YET IMPLEMENTED".
**Dependencies:** F-004 (command not implemented).

---

## Finding F-021: Structural contract for phase directory partially enforced

**Axis:** 12 — Core principles ("Structural contract over flexibility")
**Severity:** P3
**Status:** CONFIRMED
**Spec anchor:** "Structural contract for phase structure." and "Structural contract over flexibility."
**Evidence:** DIRECTORY-CONTRACT.md defines the expected directory structure. next.md (line 198) enforces `mkdir -p .apex/phases/${current_phase}/` with a comment about the pattern. schema-drift.sh validates JSON structure. But there is no hook that validates the *directory* structure (e.g., that every phase has PLAN_META.json, that no unexpected files exist).
**Current behavior:** JSON schema validated, directory pattern documented, but directory structure not validated at runtime.
**Expected behavior (per spec):** Structural contract enforced — not just documented.
**Gap:** DIRECTORY-CONTRACT.md is documentation, not enforcement.
**Blast radius:** Low — directory structure is created by the pipeline, so deviations are unlikely unless manual intervention.
**Reproduction:** Static analysis — no hook validates directory structure against DIRECTORY-CONTRACT.md.
**Dependencies:** None.

---

## Finding F-022: /apex:workflow exists but no injection protection for workflow files

**Axis:** 10 — Defense-in-Depth
**Severity:** P1
**Status:** CONFIRMED
**Spec anchor:** "apex-workflow-guard.js" (Defense-in-Depth) and "Indirect Prompt Injection through planning artifacts."
**Evidence:** 31 workflow files exist in `framework/apex-workflows/`. The /apex:workflow command reads and executes these recipes. But no guard validates workflow file content before execution. prompt-guard.sh checks for injection patterns in Write/Edit operations, but workflow files are *read* (not written) during execution — they're pre-existing templates that could be poisoned.
**Current behavior:** Workflow files are read and their instructions followed without content validation.
**Expected behavior (per spec):** Workflow files are validated against injection patterns before execution (the purpose of workflow-guard).
**Gap:** A poisoned workflow file (e.g., with embedded prompt injection) would be executed verbatim.
**Blast radius:** Failure 9 (Security gaps) — workflow files are high-value injection targets because they contain executable instructions for the AI agent.
**Reproduction:** Read workflow.md — no validation step before executing workflow instructions.
**Dependencies:** F-001 (workflow-guard missing).

---

## Finding F-023: Total elapsed time display exists in status but not in all outputs

**Axis:** 12 — Core principles / 4 — First-hour usability
**Severity:** P3
**Status:** CONFIRMED
**Spec anchor:** "Total elapsed time."
**Evidence:** status.md (lines 46-49) computes and displays elapsed time. But the spec lists "Total elapsed time" as part of the anti-hallucination strategy (Failure 5) — it should appear in execution output (next.md), not just the status dashboard. next.md's Glass Cockpit header does not include elapsed time.
**Current behavior:** Elapsed time shown only in /apex:status dashboard.
**Expected behavior (per spec):** Elapsed time visible in all execution outputs as a reality anchor.
**Gap:** Elapsed time is dashboard-only, not ubiquitous.
**Blast radius:** Low — minor UX gap.
**Reproduction:** Read next.md Glass Cockpit section (lines 39-42) — no elapsed time.
**Dependencies:** None.

---

## Finding F-024: Observation masking referenced but not implemented

**Axis:** 12 — Core principles ("Less context, better chosen")
**Severity:** P2
**Status:** SUSPECTED
**Spec anchor:** "Context engineering at state-of-the-art. Observation masking."
**Evidence:** pre-compact.sh mentions "v7 feature: observation masking tracking" in a comment, and CONTEXT_BUDGET.schema.json defines a `working_memory` zone described as "masked". But no mechanism actually masks (hides/summarizes) stale observations from agent context.
**Current behavior:** Comment reference to observation masking. No executable implementation.
**Expected behavior (per spec):** Stale observations are masked (summarized/removed) to free context space.
**Gap:** The concept is named but not built.
**Blast radius:** Failure 3 (Context loss) — context fills with stale observations.
**Reproduction:** `grep -r "observation.mask" framework/` — only pre-compact.sh comment and schema description.
**Dependencies:** None.

---

## Finding F-025: Two original workflows missing Security Invariants section

**Axis:** 1 — Nine Failures (Failure 9: Security gaps)
**Severity:** P3
**Status:** CONFIRMED
**Spec anchor:** Workflow recipe pattern requires "Goal, Prerequisites, Phases, Skills Required, Security Invariants" per established pattern.
**Evidence:** Per NEW-FINDINGS-W5.md (user-selected context): `framework/apex-workflows/migrate-to-postgres.md` and `framework/apex-workflows/setup-ci-cd.md` lack Security Invariants sections. All 25+ newly created workflows include this section.
**Current behavior:** 29/31 workflows have Security Invariants. 2 original workflows lack it.
**Expected behavior (per spec):** All workflows follow the established pattern including Security Invariants.
**Gap:** 2 files inconsistent with the pattern.
**Blast radius:** Low — the 2 affected workflows may generate phases without security considerations.
**Reproduction:** Read the two files — no "Security Invariants" section present.
**Dependencies:** None.
**Fix hints:** Add Security Invariants section to both files.

---

## Finding F-026: Hooks wired in settings.json cover only 7 of 22 hooks

**Axis:** 1 — Nine Failures (Failure 1: Pipeline)
**Severity:** P1
**Status:** CONFIRMED
**Spec anchor:** "Hook system — 24+ hooks" and settings.json hook matchers.
**Evidence:** settings.json wires 7 hooks as PreToolUse/PostToolUse matchers: destructive-guard.sh, prompt-guard.sh, path-guard.sh, post-write.sh, circuit-breaker.sh, pre-task-snapshot.sh, schema-drift.sh. The remaining 15 hooks (phantom-check, mutation-gate, cross-phase-audit, context-monitor, phase-tag, verify-learnings, tdad-index, generate-task-map, subagent-stop, session-log, pre-compact, etc.) are invoked *manually* via `bash ~/.claude/hooks/X.sh` in command/agent .md files.
**Current behavior:** 7 hooks auto-fire via settings.json matchers. 15 hooks depend on correct manual invocation by commands/agents.
**Expected behavior (per spec):** All hooks active and enforced.
**Gap:** The 15 manually-invoked hooks only fire if the command .md file correctly calls them. If a command skips the call (or an agent ignores it), the hook doesn't fire. This is a structural gap — the protection depends on the prompts being followed exactly.
**Blast radius:** Any hook that's only manually invoked can be silently skipped by a hallucinating agent. This affects: phantom-check (Failure 5), mutation-gate (Failure 7), cross-phase-audit (Failure 8), context-monitor (Failure 3).
**Reproduction:** Read settings.json — only 7 entries. Compare to `ls framework/hooks/` — 22 files.
**Dependencies:** None.
**Fix hints:** Some hooks are correctly invoked at specific pipeline points and shouldn't be PreToolUse/PostToolUse. But phantom-check, context-monitor, and cross-phase-audit could benefit from structural enforcement.

---

## Finding F-027: APEX_STRICT_MODE has no CI integration

**Axis:** 12 — Core principles ("Strict mode before commitment")
**Severity:** P3
**Status:** SUSPECTED
**Spec anchor:** "APEX_STRICT_MODE=1" and "Strict mode before commitment."
**Evidence:** APEX_STRICT_MODE is enforced in verifier.md (lines 19-28) and next.md (lines 329-332) via environment variable or STATE.json field. But the principle says "strict mode before commitment" — implying it should activate automatically before shipping. No automatic activation occurs in /apex:ship.
**Current behavior:** STRICT_MODE is opt-in (manual env var or STATE.json toggle).
**Expected behavior (per spec):** "Strict mode before commitment" implies automatic activation at ship/release time.
**Gap:** No automatic strict mode activation at critical pipeline stages.
**Blast radius:** Low — users who don't know about strict mode won't benefit from it at the most critical moment.
**Reproduction:** Read ship.md — no STRICT_MODE activation.
**Dependencies:** None.

---

## Finding F-028: APEXSkin and Two-Tier Methodology files are templates only

**Axis:** 12 — Core principles ("Methodology lives in two files")
**Severity:** P3
**Status:** CONFIRMED
**Spec anchor:** "APEX.md + PROJECT-APEX.md (Two-Tier Methodology)."
**Evidence:** `framework/APEX-TEMPLATE.md` and `framework/PROJECT-APEX-TEMPLATE.md` exist as templates. The Two-Tier Methodology is a project-level feature (APEX.md in the target project, PROJECT-APEX.md for project-specific overrides). As framework templates, they are correctly placed. However, no command validates that a target project has both files or that they are consistent.
**Current behavior:** Templates exist. No validation that target projects use them correctly.
**Expected behavior (per spec):** Two-tier methodology enforced — both files present and consistent.
**Gap:** No enforcement hook. A project could have APEX.md but not PROJECT-APEX.md, or vice versa.
**Blast radius:** Low — this is a project-level concern, not a framework-level one.
**Reproduction:** No hook checks for both files' existence.
**Dependencies:** None.

---

## Axis Coverage Summary — Findings Per Axis

| Axis | Finding IDs | Count |
|------|------------|-------|
| 1. Nine Failures | F-005, F-006, F-007, F-013, F-020, F-022, F-025, F-026 | 8 |
| 2. Dual-mode | (covered — classifier exists, no finding) | 0 |
| 3. Scale-Adaptive | F-017 | 1 |
| 4. First-hour usability | F-017, F-015, F-019, F-023 | 3* |
| 5. /apex:help | (covered — fully implemented) | 0 |
| 6. Test architecture + veto | (covered — test-architect.md with veto) | 0 |
| 7. Auditor quarantine | F-016 | 1 |
| 8. Module ecosystem | F-003, F-004 | 2 |
| 9. Memory + dream-cycle | F-011, F-012 | 2 |
| 10. Defense-in-Depth | F-001, F-022 | 2 |
| 11. State from disk | F-002, F-024 | 2 |
| 12. Core principles | F-008, F-009, F-010, F-014, F-018, F-021, F-023, F-027, F-028 | 9 |

*Some findings appear in multiple axes.

---

## What's Working Well (not findings, but context)

For completeness — these are areas where the implementation matches or exceeds the spec:

- **Dual-mode classifier** — Fully implemented in architect.md with 2-layer classification, enforced in next.md
- **Test-architect with veto** — Pre-execution agent with veto power, correctly orchestrated
- **Auditor quarantine** — Prompt-enforced (P2 gap in structural enforcement, but functionally correct)
- **Cross-model critic** — Enforcement logic in next.md:443-449 with fallback model
- **Autonomy ladder** — Per-verify-level with hard caps, session tracking
- **PROPOSALS_MODE** — Active in STATE.json, guards in all commands
- **Workflow library** — 31 recipes with index
- **/apex:help** — Natural language navigator with intent routing
- **Phantom-check** — Language-level hallucination detection
- **Schema-drift** — Required field validation on state files
- **Scope-reduction detector** — Blocking check in verifier
- **Decision gates** — Time-based gates at 60-minute intervals
- **Session health auto-pause** — Red/yellow health with auto-pause
- **Conventional commits** — Enforced by post-write hook
- **Jagged Frontier classifier** — Implemented in architect.md STEP 1.8
- **Living Evidence Counter** — In learnings system and status dashboard
- **Cost-aware model routing** — 4-profile routing with escalation rules
- **Pre-task snapshots** — Stash-based with orphan branch persistence
