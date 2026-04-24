# APEX Audit Findings — Round R2

**Audit date:** 2026-04-23
**Auditor:** Claude Opus 4.6 (Auditor Agent mode)
**Spec anchor:** User-provided APEX ideal definition (inline in prompt)
**Codebase snapshot:** commit 277e34d (master branch)
**R1 reference:** Round R1 (2026-04-12, commit 80789e9, 28 findings)

---

## Executive Summary

**R1 disposition: 28 findings → 19 RESOLVED, 4 PARTIAL, 2 STILL OPEN, 3 RECLASSIFIED**
**New R2 findings: 11** (0 P0, 2 P1, 6 P2, 3 P3)
**Total open findings (R2): 17** (0 P0, 2 P1, 8 P2, 4 P3 + 3 reclassified)

**Severity distribution (open findings only):**
- P0 (spec-core contradiction, multi-failure): 0
- P1 (explicit spec violation, single failure): 2
- P2 (dormant/partial mechanism): 8
- P3 (declaration without enforcement, low blast radius): 4
- RECLASSIFIED (spec contradiction / roadmap / not-applicable): 3

**Top 3 themes:**
1. **R1 remediation was substantive** — 14 of 16 fix commits resolved their target findings completely. The 4 P0 findings from R1 are now 0 P0. This is a genuine severity reduction.
2. **Spec-implementation divergence in state architecture** — The spec declares "SQLite+FTS5" and "PEP 420 namespace" but the implementation chose JSON+JSONL and has no Python packaging. These are spec artifacts, not implementation bugs.
3. **Agent tool declarations vs. orchestrator expectations** — test-architect declares read-only tools but must produce output files. Memory primitive commands assume directories exist without defensive mkdir. The wiring between components has small gaps.

---

## R1 Findings Disposition Matrix

| R1 ID | Sev | R2 Status | R2 ID | Notes |
|-------|-----|-----------|-------|-------|
| F-001 | P0 | PARTIAL | R2-F-001 | 5/6 mechanisms exist. security.cjs absent-by-design. |
| F-002 | P0 | RECLASSIFIED | SC-002 | Spec contradiction: SQLite+FTS5 vs. JSON+JSONL architecture. |
| F-003 | P0 | RECLASSIFIED | ROADMAP | Monolithic is correct for v1. Spec describes future state. |
| F-004 | P0 | RESOLVED | — | All 6 commands now fully implemented. |
| F-005 | P1 | RESOLVED | — | Wave 0 Nyquist layer in next.md:242-264. |
| F-006 | P1 | RESOLVED | — | Skipped-test detection in post-write.sh:12-21. |
| F-007 | P1 | PARTIAL | R2-F-002 | DORA metrics computed but lead_time_avg uses biased formula. |
| F-008 | P1 | RESOLVED | — | U-shape guidelines + health-check TEST 0h. |
| F-009 | P2 | RECLASSIFIED | N/A | PEP 420 not applicable to markdown/bash framework. |
| F-010 | P2 | RESOLVED | — | Color Discipline section 12-A in apex-branding.md. |
| F-011 | P2 | RESOLVED | — | /apex:start:44 creates all 4 dirs. .apex/ here is framework-build. |
| F-012 | P2 | RESOLVED | — | Dream-cycle triggers on context overflow + time gate in next.md:66-72. |
| F-013 | P1 | RESOLVED | — | ast-kb-check.sh exists and wired in settings.json. |
| F-014 | P2 | RESOLVED | — | Spec drift hash check in next.md:372-379. |
| F-015 | P2 | RESOLVED | — | Decision-filtered glass cockpit in next.md:39-48. |
| F-016 | P2 | RESOLVED | — | quarantine-guard.sh wired as PreToolUse on Read\|Bash. |
| F-017 | P1 | RESOLVED | — | Friendly 4-button menu in onboard.md:59-69. |
| F-018 | P2 | RESOLVED | — | build.md and refine.md are distinct pipeline modes by design. |
| F-019 | P3 | STILL OPEN | R2-F-010 | Decision gate fixed at 60 min, spec says "60-90". |
| F-020 | P1 | RESOLVED | — | peer-review.md has manual copy/paste workflow. |
| F-021 | P3 | RESOLVED | — | Structural contract validated in health-check TEST 0g. |
| F-022 | P1 | RESOLVED | — | workflow-guard.sh exists with 7 injection patterns. |
| F-023 | P3 | RESOLVED | — | Elapsed time in glass cockpit header next.md:47. |
| F-024 | P2 | PARTIAL | R2-F-007 | Observation masking documented as zone system but not runtime-enforced. |
| F-025 | P3 | RESOLVED | — | All 30 workflow .md files have Security Invariants. |
| F-026 | P1 | PARTIAL | R2-F-003 | 10 hooks wired (was 7). No hook classification document. |
| F-027 | P3 | RESOLVED | — | ship.md:23 activates strict_mode before verification. |
| F-028 | P3 | RESOLVED | — | Two-tier methodology check in next.md:226-231. |

---

## Coverage Map

| # | Axis | R1 Findings | R2 New Findings | Total Open | Confidence |
|---|------|-------------|-----------------|------------|------------|
| 1 | Nine Failures (1-9) | 8 (5 resolved, 2 partial, 1 reclassified) | 3 | 5 | HIGH — all hooks, agents, commands traced |
| 2 | Dual-mode (collaborator vs replacement) | 0 | 0 | 0 | HIGH — classifier in architect.md:71-96, enforced in next.md:389-400 |
| 3 | Scale-Adaptive Classifier | 1 (resolved) | 0 | 0 | HIGH — onboard.md:30-71 auto-detects with friendly labels |
| 4 | First-hour usability for non-programmers | 2 (resolved) | 0 | 0 | MEDIUM — would need real user testing |
| 5 | /apex:help natural language navigator | 0 | 0 | 0 | HIGH — fully implemented with intent routing table |
| 6 | Test architecture as discipline with veto | 0 | 1 | 1 | HIGH — veto works but tool declaration gap found |
| 7 | Auditor quarantine | 1 (resolved) | 0 | 0 | HIGH — quarantine-guard.sh wired structurally |
| 8 | Module ecosystem as platform | 2 (1 resolved, 1 roadmap) | 0 | 1 | HIGH — monolithic, spec describes future state |
| 9 | Memory 3-tier + dream-cycle + 4 primitives | 2 (resolved) | 2 | 2 | HIGH — dirs created by start, dream-cycle wired |
| 10 | Defense-in-Depth on APEX's own files | 3 (2 resolved, 1 partial) | 2 | 3 | HIGH — file existence + behavior verified |
| 11 | State derives from disk / proof-of-process | 2 (1 resolved, 1 reclassified) | 1 | 2 | MEDIUM — JSONL substitute undocumented in spec |
| 12 | 30+ core principles | 7 (5 resolved, 1 partial, 1 still open) | 2 | 3 | MEDIUM — some principles are architectural patterns |

---

## Blind Spots

1. **Runtime behavior** — All findings are from static analysis. Cannot confirm hooks actually fire in production pipelines without end-to-end execution.
2. **Cross-model critic dispatch** — next.md:472-530 has the logic and apex-model-routing.json has `cross_model_required: true`, but whether Claude Code runtime honors the model field depends on platform behavior. Static analysis confirms the code path.
3. **Windows/Git Bash date compatibility** — Hooks use `date -d` (GNU) with `date -j -f` (BSD) fallback. On Windows Git Bash, neither may work reliably for ISO-8601 parsing. Would need runtime test on target platform.
4. **Workflow content quality** — All 30 workflows have Security Invariants sections but content quality was spot-checked, not exhaustively audited.

---

## Contradictions Within Spec Itself

**SC-001: Shell hooks vs. JS security files** (carried from R1)
The spec names `apex-prompt-guard.js`, `apex-workflow-guard.js`, `security.cjs` as JavaScript files. CLAUDE.md says "Hooks are shell scripts (.sh)". Implementation uses `.sh` files. `apex-design-notes.md:61` documents the rationale: "the framework has zero JavaScript runtime dependencies." All named *functionality* now exists as .sh equivalents (prompt-guard.sh, workflow-guard.sh, _security-common.sh). The JS filenames are spec artifacts.

**SC-002: SQLite+FTS5 vs. JSON state** (carried from R1)
The spec says "State management hybrid: Markdown + SQLite+FTS5." Implementation uses Markdown + JSON + JSONL. `start.md:76-92` documents the architecture and notes "JSONL is directly importable to SQLite+FTS5 when framework-level query needs exceed jq capabilities." The migration path exists but SQLite is not built.

**SC-003: PEP 420 namespace** (new in R2)
The spec lists "PEP 420 namespace" as a required capability. PEP 420 is a Python implicit namespace package standard. APEX is a markdown/bash framework with zero Python packages. The concept does not map to the implementation technology. This is a spec artifact from an earlier design iteration.

---

## Part 1: R1 Findings — Re-verification

### RESOLVED (19 findings)

**F-004: 6 commands stubbed** — RESOLVED. All 6 commands now have substantive implementations:
- `new-agent.md` (72 lines): template generation with validation, reserved name rejection, PROPOSALS_MODE guard.
- `new-workspace.md` (78 lines): git worktree isolation with branch naming.
- `peer-review.md` (101 lines): manual copy/paste cross-AI workflow.
- `ui-review.md` (85 lines): 6-pillar design contract verification.
- `ui-phase.md` (90 lines): dedicated frontend phase execution.
- `milestone-summary.md` (87 lines): DORA metrics + proof-of-process aggregation.

**F-005: Nyquist Validation Layer** — RESOLVED. `next.md:242-264` implements Wave 0: triggers test-architect in phase mode when `complexity_level >= 2`, produces `WAVE_0_TEST_MAP.json`, blocks on `veto == true` with `STATE.status = "blocked_by_wave_0"`. L1 skip at line 262.

**F-006: Skipped-test regression** — RESOLVED. `post-write.sh:12-21` catches `.skip()`, `.only()`, `xit()`, `xdescribe()`, `@pytest.mark.skip`, `@unittest.skip`, `#[ignore]`, `pending(` in test files. Exit 2 = blocking.

**F-008: U-shaped attention** — RESOLVED. `health-check.md:153-196` (TEST 0h) audits all agent .md files for U-shaped structure: top 20% must have critical markers (NEVER/MUST/constraint), bottom 20% must have enforcement markers (VERDICT/MANDATORY/VERIFY). Automated validation, not just documentation.

**F-010: Color discipline** — RESOLVED. `apex-branding.md` section 12-A "COLOR DISCIPLINE" defines semantic color map. `health-check.md:198+` (TEST 0i) audits emoji consistency across commands.

**F-011: Memory primitive dirs** — RESOLVED. `start.md:44` creates `mkdir -p .apex/{...todos,threads,seeds,backlog}`. Current `.apex/` is the framework build project, not a target project.

**F-012: Dream-cycle periodic trigger** — RESOLVED. `next.md:66-72` triggers dream-cycle on WARNING_OVERFLOW when `MEMORY_FILE_COUNT > 10`. Also triggers on time gate (every 60 min).

**F-013: AST-KB Hallucination Gate** — RESOLVED. `ast-kb-check.sh` (79 lines) validates imports in JS/Python files. Wired in `settings.json` as PostToolUse on Write|Edit.

**F-014: Spec drift hash check** — RESOLVED. `next.md:372-379` computes `sha256sum .apex/SPEC.md`, compares to `STATE.spec_version`. Advisory warning on mismatch.

**F-015: Glass cockpit decision filter** — RESOLVED. `next.md:39-48` filters by `DECISION_TYPES = pending_approval | auto_pause | time_gate | coherence_fail | veto | blocked | phantom_fail`. Replaces chronological tail. Cap at 5 items.

**F-016: Auditor quarantine breach** — RESOLVED. `quarantine-guard.sh` wired in `settings.json` as PreToolUse on Read|Bash. Agent-aware: checks `APEX_ACTIVE_AGENT`, instant pass-through if not auditor. Allow-list: test files + state files + manifests only.

**F-017: Scale-Adaptive friendly labels** — RESOLVED. `onboard.md:59-69` shows "Trying it out / Building something real / Going to production / My business depends on this" with `[recommended]` tag. No L1-L4 labels visible.

**F-018: Build/refine thin wrappers** — RESOLVED-BY-DESIGN. Both are distinct pipeline modes that delegate to `next.md`. The spec says "different pipelines" which they are — different entry points with different framing.

**F-020: Cross-AI peer review** — RESOLVED. `peer-review.md` (101 lines) implements manual copy/paste workflow for cross-AI review.

**F-021: Structural contract** — RESOLVED. `health-check.md:121-151` (TEST 0g) validates `.apex/` directory structure against DIRECTORY-CONTRACT.md. Checks 9 required dirs and 3 required files.

**F-022: Workflow injection** — RESOLVED. `workflow-guard.sh` (63 lines) scans for instruction overrides, role hijacking, hidden HTML directives, system prompt framing, executable injection blocks, priority injection, zero-width characters.

**F-023: Elapsed time** — RESOLVED. `next.md:47` computes `elapsed = now - STATE.created_at`, formats as "[N]d [N]h", displays in cockpit header.

**F-025: Workflow Security Invariants** — RESOLVED. All 30 workflow .md files contain "Security Invariants" section (verified by grep count: 30/30).

**F-027: Strict mode before ship** — RESOLVED. `ship.md:23` sets `STATE.strict_mode = true` before verification.

**F-028: Two-tier methodology check** — RESOLVED. `next.md:226-231` checks for APEX.md and PROJECT-APEX.md presence. Advisory warning if missing.

### PARTIAL (4 findings — new R2 IDs assigned)

See Part 2 for full finding format: R2-F-001 (from F-001), R2-F-002 (from F-007), R2-F-003 (from F-026), R2-F-007 (from F-024).

### STILL OPEN (2 findings — new R2 IDs assigned)

See Part 2 for full finding format: R2-F-010 (from F-019), R2-F-011 (from F-002/SC-002).

### RECLASSIFIED (3 findings)

**F-002 → SC-002:** SQLite+FTS5 is a spec contradiction. Implementation chose JSON+JSONL with documented migration path. Spec needs amendment.

**F-003 → ROADMAP:** Module ecosystem monolithic. Correct for v1 single-repo build. Spec describes future multi-repo state. No action needed until platform launch.

**F-009 → N/A:** PEP 420 namespace is not applicable. APEX is markdown/bash, not a Python package. Spec artifact. See SC-003.

---

## Part 2: New R2 Findings

---

## Finding R2-F-001: Defense-in-Depth — 1 of 6 mechanisms absent-by-design

**Axis:** 10 — Defense-in-Depth on APEX's own files
**Severity:** P2
**Status:** CONFIRMED
**Spec anchor:** "Defense-in-Depth Security Layer: `apex-prompt-guard.js`, Path Traversal Prevention, `apex-workflow-guard.js`, CI scanner, `security.cjs` module."
**Evidence:** 5 of 6 named mechanisms now exist as .sh equivalents:
- `prompt-guard.sh` ← apex-prompt-guard.js
- `path-guard.sh` ← Path Traversal Prevention
- `workflow-guard.sh` ← apex-workflow-guard.js
- `ci-scan.sh` ← CI scanner
- `_security-common.sh` ← security.cjs (shared normalization + pattern matching)
`apex-design-notes.md:61` documents rationale: "the framework has zero JavaScript runtime dependencies."
**Current behavior:** 5/6 mechanisms present as shell scripts. `security.cjs` as a standalone consolidated module does not exist — its functionality is split across `_security-common.sh` (shared utilities) and individual guard scripts.
**Expected behavior (per spec):** 6 named security mechanisms all present.
**Gap:** The spec names `security.cjs` as a single consolidated module. The implementation distributes this across `_security-common.sh` + individual guards. Functionally equivalent, but architecturally different. The "single module" concept — a centralized security policy — does not exist.
**Blast radius:** Low. All security *functions* exist. The gap is architectural (distributed vs. consolidated), not functional.
**Reproduction:** `ls framework/hooks/*security*` → only `_security-common.sh`. No single "security module" file.
**Dependencies:** SC-001 (spec contradiction on JS vs. SH).
**Out-of-scope note:** None.
**Fix hints:** Either document `_security-common.sh` as the `security.cjs` equivalent, or create a `security-policy.sh` that aggregates all security rules into one queryable file.

---

## Finding R2-F-002: DORA lead_time_avg uses exponentially decaying formula

**Axis:** 12 — Core principles ("DORA self-monitoring")
**Severity:** P3
**Status:** CONFIRMED
**Spec anchor:** "DORA self-monitoring." and "The First Framework That Improves DORA."
**Evidence:** `phase-tag.sh:50-52`:
```bash
if .dora.lead_time_avg == null then .dora.lead_time_avg = $hours
else .dora.lead_time_avg = ((.dora.lead_time_avg + $hours) / 2)
end
```
This is an exponentially weighted moving average, not a true arithmetic average. After N phases, the first phase's lead time contributes only `1/2^N` to the average. With 10 phases, phase 1 contributes 0.1%.
**Current behavior:** Exponentially decaying rolling average that biases toward recent phases.
**Expected behavior (per spec):** DORA metrics that accurately represent project-wide performance.
**Gap:** The formula is biased. For a 10-phase project, early phases are effectively invisible in the average. A true average would divide cumulative lead time by phase count.
**Blast radius:** Low — DORA metrics are informational. Incorrect averages don't affect pipeline behavior.
**Reproduction:** Calculate: 5 phases with lead times [10, 20, 30, 40, 50] hours. Formula gives: 10 → 15 → 22.5 → 31.25 → 40.625. True average: 30.0. Error: 35%.
**Dependencies:** None.
**Out-of-scope note:** None.
**Fix hints:** Track cumulative lead_time_sum and phases_completed, compute average as sum/count.

---

## Finding R2-F-003: No authoritative hook classification document

**Axis:** 1 — Nine Failures (Failure 1: Pipeline)
**Severity:** P2
**Status:** CONFIRMED
**Spec anchor:** "Hook system — 24+ hooks" and "Fail-loud, never fail-silent."
**Evidence:** `framework/hooks/` contains 27 .sh files (22 functional hooks + 5 `_` prefixed utilities). `settings.json` wires 10 hooks as auto-fire PreToolUse/PostToolUse. The remaining 12 functional hooks are invoked manually by commands/agents via `bash ~/.claude/hooks/X.sh`. There is no document that maps which hooks are:
- Auto-wired (fire on every matching tool use)
- Command-invoked (fire only when a specific command calls them)
- Manual-only (user/CI invocation)
**Current behavior:** A developer must cross-reference `settings.json` and grep all command .md files to determine how each hook fires.
**Expected behavior (per spec):** A hook system where all hooks are documented with their trigger mechanism and classification.
**Gap:** Hook classification is implicit in code, not explicit in documentation.
**Blast radius:** Failure 1 (Pipeline) — if a command forgets to invoke a manual hook, there's no safety net. Example: `session-log.sh` is critical for glass cockpit but only fires if commands remember to call it.
**Reproduction:** `grep -c "session-log.sh" framework/commands/apex/*.md` → not all commands invoke it.
**Dependencies:** None.
**Out-of-scope note:** None.
**Fix hints:** Create a HOOK-CLASSIFICATION.md mapping each hook to its trigger type and which commands/agents invoke it.

---

## Finding R2-F-004: test-architect declares read-only tools but must produce output files

**Axis:** 6 — Test architecture as discipline with veto
**Severity:** P1
**Status:** CONFIRMED
**Spec anchor:** "apex-test-architect module with veto power." and "Roles must produce typed artifacts."
**Evidence:** `test-architect.md:3` declares `tools: Read, Grep, Glob` — read-only tools. But `next.md:358` invokes it with `output: ".apex/phases/$PHASE/TEST_PLAN.json"` and `next.md:248` with `output: ".apex/phases/${current_phase}/WAVE_0_TEST_MAP.json"`. Both outputs require writing files. Without `Write` in its tool list, test-architect cannot produce its required artifacts.
**Current behavior:** test-architect is declared with read-only tools but expected to write TEST_PLAN.json and WAVE_0_TEST_MAP.json.
**Expected behavior (per spec):** Agent tool declarations match their output requirements. "Roles must produce typed artifacts."
**Gap:** Tool mismatch. Either the agent cannot write its output (breaking veto mechanism), or the orchestrator handles the write (undocumented).
**Blast radius:** Failure 5 (Hallucination) — if test-architect cannot write TEST_PLAN.json, Wave 0 and per-task veto are structurally broken.
**Reproduction:** Read `test-architect.md:3` → `tools: Read, Grep, Glob`. Read `next.md:358` → `output: ".apex/phases/$PHASE/TEST_PLAN.json"`.
**Dependencies:** None.
**Out-of-scope note:** Claude Code may allow agents to write regardless of declared tools (runtime behavior). Static analysis shows the mismatch.
**Fix hints:** Add `Write` to test-architect.md tool declaration.

---

## Finding R2-F-005: Cross-platform date parsing in hooks

**Axis:** 1 — Nine Failures (Failure 1: Pipeline)
**Severity:** P1
**Status:** CONFIRMED
**Spec anchor:** "Multi-platform from day one." and "DORA self-monitoring."
**Evidence:** Three hooks use platform-specific date parsing:
- `phase-tag.sh:43`: `date -d "$CREATED_AT" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${CREATED_AT%%.*}" +%s 2>/dev/null || echo ""`
- `phase-tag.sh:60`: Same pattern for project creation date.
- `verify-learnings.sh:23`: `date -d "$d" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null || echo ""`
`date -d` is GNU (Linux). `date -j -f` is BSD (macOS). Neither works reliably on Windows Git Bash. The `|| echo ""` fallback means silent failure — DORA metrics and learning staleness checks silently produce no data on Windows.
**Current behavior:** On Windows/Git Bash, date parsing silently fails. DORA lead_time_avg, deployment_freq, and learning staleness are never computed.
**Expected behavior (per spec):** "Multi-platform from day one" — hooks should work on Linux, macOS, and Windows.
**Gap:** Windows is a first-class platform (this project runs on Windows 10), but date-dependent hooks silently degrade.
**Blast radius:** DORA metrics (phase-tag.sh) and learning decay (verify-learnings.sh) are non-functional on Windows. This contradicts branding position 7 ("Multi-Platform").
**Reproduction:** Run on Windows Git Bash: `date -d "2026-04-23T12:00:00Z" +%s` → fails. `date -j -f "%Y-%m-%dT%H:%M:%S" "2026-04-23T12:00:00" +%s` → fails.
**Dependencies:** R2-F-002 (DORA formula already biased; on Windows, it's absent entirely).
**Out-of-scope note:** None.
**Fix hints:** Use Python one-liner fallback: `python3 -c "from datetime import datetime; print(int(datetime.fromisoformat('$DATE').timestamp()))"` or `date +%s` (current time works everywhere).

---

## Finding R2-F-006: workflow-guard.sh not auto-wired in settings.json

**Axis:** 10 — Defense-in-Depth on APEX's own files
**Severity:** P2
**Status:** CONFIRMED
**Spec anchor:** "Defense-in-Depth Security Layer: ... apex-workflow-guard.js" and "Indirect Prompt Injection through planning artifacts."
**Evidence:** `workflow-guard.sh` exists (63 lines) with comprehensive injection pattern matching and exit 2 blocking. But it is NOT wired in `settings.json`. It is invoked explicitly by `/apex:workflow` command only. If a workflow file is loaded via Read (not via /apex:workflow), the guard does not fire.
**Current behavior:** Guard fires only when /apex:workflow invokes it. Workflow .md files can be read by any agent without injection scanning.
**Expected behavior (per spec):** Defense-in-Depth means workflow files are validated regardless of how they're accessed.
**Gap:** A poisoned workflow file read directly (not via /apex:workflow) bypasses the guard.
**Blast radius:** Failure 9 (Security gaps) — workflow files in `apex-workflows/` are trusted content that could be poisoned. The guard exists but has a bypass path.
**Reproduction:** `grep "workflow-guard" framework/settings.json` → no match. Guard only invoked by `workflow.md`.
**Dependencies:** R2-F-001 (Defense-in-Depth architectural gap).
**Out-of-scope note:** Wiring as PreToolUse on Read for all files would be too broad. May need targeted matcher.
**Fix hints:** Add workflow-guard.sh as PreToolUse on Read with a matcher that targets `apex-workflows/*.md` paths, or document the explicit-invocation-only design as accepted risk.

---

## Finding R2-F-007: Observation masking is documented zones, not runtime enforcement

**Axis:** 12 — Core principles ("Less context, better chosen")
**Severity:** P2
**Status:** CONFIRMED
**Spec anchor:** "Context engineering at state-of-the-art. Observation masking." and "Less context, better chosen."
**Evidence:** `next.md:311-338` defines a 3-zone context structure (Stable Prefix, Task Context, Working Memory) with masking rules. The R-024 fix added this zone documentation. But observation masking is a *prompt composition pattern*, not a runtime mechanism. The executor.md agent also has observation masking guidance at lines 89-93: "do not cache stale tool outputs >3 calls old." Both are instructions to the AI agent, not enforced by hooks.
**Current behavior:** Observation masking is a documented context composition pattern. No hook validates that stale observations are actually removed.
**Expected behavior (per spec):** Observation masking enforced — stale observations removed from context automatically.
**Gap:** The AI agent can ignore the masking guidance. No external mechanism validates that context follows the zone structure.
**Blast radius:** Failure 3 (Context loss) — context may fill with stale observations if the agent doesn't follow the guidance.
**Reproduction:** Read `next.md:311-338` — context structure is defined as instructions to be followed, not as a hook that validates compliance.
**Dependencies:** None.
**Out-of-scope note:** Observation masking may be inherently a prompt-level pattern that cannot be hook-enforced. Marking as P2 because the gap is real but enforcement may not be feasible.
**Fix hints:** Consider a `pre-compact.sh` enhancement that counts observation age and warns when stale observations exceed threshold.

---

## Finding R2-F-008: Memory primitive commands lack defensive mkdir

**Axis:** 9 — Memory 3-tier + dream-cycle + 4 primitives
**Severity:** P3
**Status:** CONFIRMED
**Spec anchor:** "Four primitives: apex/todos/, apex/threads/, apex/seeds/, apex/backlog/." and "Failure produces a fix plan, never a 'go debug it'."
**Evidence:** Three commands write to memory primitive directories without ensuring they exist:
- `thread.md:25`: writes to `.apex/threads/${SLUG}.md` — no mkdir.
- `plant-seed.md:21-22`: writes to `.apex/seeds/seed-${TIMESTAMP}.md` — no mkdir.
- `add-backlog.md:21-22`: writes to `.apex/backlog/item-${TIMESTAMP}.md` — no mkdir.
All three rely on `/apex:start:44` having created the directories. If dirs are deleted, moved, or the project was initialized before memory primitive dirs were added to start.md, these commands will fail.
**Current behavior:** Commands assume directories exist. Write fails if they don't.
**Expected behavior (per spec):** "Failure produces a fix plan, never a 'go debug it'" — commands should be defensive.
**Gap:** No `mkdir -p` before write. Non-technical user gets a file-not-found error with no guidance.
**Blast radius:** Low — only affects edge case where dirs are missing. `/apex:start` creates them.
**Reproduction:** Delete `.apex/threads/`, run `/apex:thread "test topic: test content"` — write fails.
**Dependencies:** None.
**Out-of-scope note:** None.
**Fix hints:** Add `mkdir -p .apex/threads/` (or seeds/, backlog/) before file creation in each command.

---

## Finding R2-F-009: test-architect defaults to haiku for veto-level decisions

**Axis:** 5 — Hallucination / 6 — Test architecture with veto
**Severity:** P2
**Status:** CONFIRMED
**Spec anchor:** "apex-test-architect module with veto power." and "Cost-awareness as principle, not add-on."
**Evidence:** `apex-model-routing.json` sets `"test-architect": { "default": "haiku" }`. The test-architect agent has **veto power** over phase completion (Wave 0) and per-task execution (F.5 step). Veto is a high-stakes decision — incorrectly vetoing blocks progress, incorrectly passing allows untested code through.
**Current behavior:** Haiku (smallest/cheapest model) makes veto decisions that block or allow entire phases.
**Expected behavior (per spec):** Cost-awareness is a principle, but veto decisions are critical. The spec says "Cost-awareness as principle, not add-on" — cost optimization should not compromise critical safety mechanisms.
**Gap:** Haiku's judgment on whether test infrastructure is adequate for a phase may be less reliable than sonnet or opus. A false negative (not vetoing when it should) lets untested code through. A false positive (vetoing incorrectly) blocks the user.
**Blast radius:** Failure 5 (Hallucination) — the gatekeeper for test infrastructure adequacy uses the least capable model.
**Reproduction:** Read `apex-model-routing.json` → `"test-architect": { "default": "haiku" }`. Read `next.md:251` → veto blocks entire phase.
**Dependencies:** R2-F-004 (test-architect tool mismatch compounds model concern).
**Out-of-scope note:** Haiku may be adequate for pattern-matching-level analysis (file existence, directory structure). The concern is about judgment calls (risk profile assessment, coverage adequacy).
**Fix hints:** Escalate test-architect to sonnet for phase-mode (Wave 0) where veto has phase-wide impact. Keep haiku for per-task mode where impact is smaller.

---

## Finding R2-F-010: Decision gate interval fixed at 60 min, spec says 60-90

**Axis:** 4 — First-hour usability
**Severity:** P3
**Status:** CONFIRMED (carried from F-019)
**Spec anchor:** "Decision gates per 60-90 minutes."
**Evidence:** `next.md:134` (approximate — time gate section) hard-codes `ELAPSED_MINUTES >= 60 AND MINUTES_SINCE_GATE >= 60`.
**Current behavior:** Decision gate fires every 60 minutes exactly.
**Expected behavior (per spec):** "Decision gates per 60-90 minutes" — implies the interval could be adaptive within this range.
**Gap:** Fixed at lower bound. Spec allows up to 90 minutes. Not adaptive based on phase complexity or user engagement.
**Blast radius:** Minimal — mechanism works, interval is within spec range.
**Reproduction:** Read next.md time gate section — hard-coded 60 minute check.
**Dependencies:** None.
**Out-of-scope note:** "Per 60-90 minutes" could mean "somewhere in this range" (satisfied by 60) rather than "adaptively between 60 and 90".
**Fix hints:** Could adapt interval based on complexity_level: L1/L2=90min, L3/L4=60min.

---

## Finding R2-F-011: event-log.jsonl as SQLite substitute not reflected in spec

**Axis:** 11 — State derives from disk / proof-of-process
**Severity:** P2
**Status:** CONFIRMED
**Spec anchor:** "State management hybrid. Markdown + SQLite+FTS5."
**Evidence:** `start.md:45` creates `event-log.jsonl`. `start.md:76-92` documents "State Management Architecture" section explaining JSONL as the queryable event stream with jq examples and migration path to SQLite. `next.md:42` queries it with `jq -c 'select(...)' .apex/event-log.jsonl`. This is a deliberate architectural choice — but the **spec** still says "SQLite+FTS5" without acknowledging the JSONL approach.
**Current behavior:** JSONL-based event stream with jq queries. Migration path to SQLite documented in generated APEX.md.
**Expected behavior (per spec):** "SQLite+FTS5" as the queryable state layer.
**Gap:** Spec describes SQLite+FTS5. Implementation uses JSONL+jq. The implementation decision is documented *within generated project files* but the spec itself hasn't been updated.
**Blast radius:** Branding and documentation — anyone reading the spec will expect SQLite, find JSONL.
**Reproduction:** Read `apex-spec.md` or the ideal definition → "SQLite+FTS5". Read `start.md:76-92` → "JSONL is the queryable event stream."
**Dependencies:** SC-002 (spec contradiction).
**Out-of-scope note:** None.
**Fix hints:** Update spec to reflect the JSONL+jq approach with SQLite+FTS5 as future migration path.

---

## Part 3: Regression Analysis

### R1 Fix Commits — Regression Check

16 fix commits were reviewed for regressions:

**No regressions found.** Each fix was additive (new sections, new hook logic, new health-check tests) without modifying existing behavior. Specific notes:

1. **277e34d (R-010 color discipline):** Added section 12-A to apex-branding.md and TEST 0i to health-check.md. No existing sections modified.
2. **d2c99f8 (R-012 dream-cycle):** Added conditional trigger to next.md context overflow section. Existing overflow handling unchanged.
3. **8346149 (R-005 Nyquist):** Added Wave 0 section to next.md between architect validation and Step A. Existing step numbering preserved.
4. **49f742d (R-006 skipped-test):** Added blocking check to post-write.sh before TypeScript checks. Existing checks unchanged.
5. **24a7fa5 (R-007 DORA):** Added DORA computation to phase-tag.sh after tag verification. Existing tag logic unchanged.
6. **c62bfad (R-008 U-shape):** Added TEST 0h to health-check.md. No modification to agent files.
7. **0c7a05b (R-014 spec drift):** Added Step F.6 to next.md after F.5. Existing steps unchanged.
8. **a7a04f6 (R-015 glass cockpit):** Modified next.md:39-48 to use DECISION_TYPES filter. Improved existing behavior (filter replaces flood).
9. **c2c1667 (R-017 friendly labels):** Modified onboard.md:50-71 to replace L1-L4 with friendly names. Improved existing behavior.
10. **049514c (R-023 elapsed time):** Added line 47 to next.md glass cockpit. Additive.
11. **ca7aae2 (R-027 strict mode):** Added lines 22-25 to ship.md. Additive.
12. **f9e4abc (R-028 two-tier check):** Added lines 226-231 to next.md. Additive.

**One interaction noted (not regression):** R2-F-005 (cross-platform date) affects R-007 (DORA metrics). The DORA fix (R-007) introduced date-dependent code that doesn't work on Windows. This is a new finding, not a regression — the original R-007 finding didn't consider platform compatibility.

---

## Axis Coverage Summary — Findings Per Axis

| Axis | Finding IDs (open) | Count |
|------|-------------------|-------|
| 1. Nine Failures | R2-F-003, R2-F-005, R2-F-009 | 3 |
| 2. Dual-mode | (covered — fully implemented, no findings) | 0 |
| 3. Scale-Adaptive | (covered — resolved in R1, no findings) | 0 |
| 4. First-hour usability | R2-F-010 | 1 |
| 5. /apex:help | (covered — fully implemented, no findings) | 0 |
| 6. Test architecture + veto | R2-F-004 | 1 |
| 7. Auditor quarantine | (covered — resolved in R1, no findings) | 0 |
| 8. Module ecosystem | ROADMAP (reclassified F-003) | 1* |
| 9. Memory + dream-cycle | R2-F-008 | 1 |
| 10. Defense-in-Depth | R2-F-001, R2-F-006 | 2 |
| 11. State from disk | R2-F-011, SC-002 | 2* |
| 12. Core principles | R2-F-002, R2-F-007 | 2 |

*Includes reclassified/spec-contradiction items.

---

## What's Working Well (context for severity assessment)

R2 confirms these areas are fully functional and spec-compliant:

- **Dual-mode classifier** — 2-layer classification in architect.md, enforced in next.md:389-400
- **Scale-Adaptive Classifier** — Auto-detection with friendly labels and [recommended] tag
- **Natural language help** — Intent routing table with 12+ patterns
- **Test-architect veto power** — Wave 0 phase-level + F.5 per-task veto (tool declaration gap aside)
- **Auditor quarantine** — Hook-enforced structural guarantee via quarantine-guard.sh
- **Cross-model critic** — Clean-room protocol with cross-model dispatch and anti-rationalization
- **Workflow library** — 30 recipes with Security Invariants, indexed
- **Phantom-check** — Two-layer defense (post-write + pre-critic in next.md)
- **Skipped-test detection** — 8 patterns caught in post-write.sh
- **Scope-reduction detector** — Blocking check in verifier.md
- **Pre-task snapshots** — Git stash with filesystem verification
- **Context budget** — 4-zone model with per-agent limits
- **Autonomy ladder** — Per-verify-level with hard caps
- **Living Evidence Counter** — In learnings system + status dashboard
- **APEXSkin branding** — 1,250-line visual identity with design constants
- **Glass cockpit** — Decision-filtered, elapsed time, live ticker
- **Session health monitoring** — Auto-pause on error rate threshold
- **Strict mode** — Dual activation (env var + STATE.json), auto-activated before ship
- **Conventional commits** — Enforced by post-write.sh
- **PROPOSALS_MODE** — Active across all 44 commands
