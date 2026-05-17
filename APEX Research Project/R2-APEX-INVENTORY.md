# R2-APEX-INVENTORY — Current State of APEX vs R2 Primitives

> **Phase-2 artifact** of R2↔APEX gap analysis.
> **Method:** Direct file reads (schemas, hooks, agents) + targeted audits by 3 specialist sub-agents (verification, compaction/rotation, memory/retrieval).
> **Audit status code:** ✅ Implemented and used | ⚠️ Partial / declarative-only / used in some paths | ❌ Missing entirely | 🚨 Theatre (declared but no implementation backs it)
> **Confidence on findings:** Each claim cites `file:line` evidence. Where `grep` returned zero matches, this is recorded as proof of absence.

---

## P1 — Token Budgeting

### What APEX has

- **`framework/CONTEXT_BUDGET.default.json:1-65`** — formal 4-zone budget JSON with `version: "v7"`, `design_principle: "Target 50-60% utilization. R2: coding quality degrades above 70%."`
  - Zones: `stable_prefix` 30K | `task_context` 50K | `working_memory` 60K | `generation_reserve` 60K → total budget 200K (matches `capacity_tokens: 200000`).
  - **Thresholds:** `target_utilization_pct: 55`, `proactive_compact_pct: 55`, `hard_rotate_pct: 70`, `never_exceed_pct: 75` ([CONTEXT_BUDGET.default.json:26-31](framework/CONTEXT_BUDGET.default.json#L26-L31)).
  - **Per-agent limits:** planner 40K/25K, architect 40K/25K, executor 30K/20K, critic 25K/15K, verifier 20K/12K ([CONTEXT_BUDGET.default.json:37-43](framework/CONTEXT_BUDGET.default.json#L37-L43)).
  - **Reduction priority list:** `["observation_masking", "compact_working_memory", "evict_completed_task_context", "hard_rotate"]` ([CONTEXT_BUDGET.default.json:44-49](framework/CONTEXT_BUDGET.default.json#L44-L49)).
  - **Rotation triggers:** `[utilization_pct=70 hard_rotate, utilization_pct=55 proactive_compact, pattern=repeated_tool_errors warn_and_compact]` ([CONTEXT_BUDGET.default.json:32-36](framework/CONTEXT_BUDGET.default.json#L32-L36)).
- **`framework/schemas/CONTEXT_BUDGET.schema.json`** — JSON Schema enforcing the structure (closed `additionalProperties: false`).
- **`framework/schemas/STATE.schema.json:186-235`** — `tokens.total_input`, `total_output`, `framework_overhead`, `overhead_pct`, `by_phase{}`, `by_agent{}`, `by_task{}`, `productive` — full token-accounting schema.
- **`framework/schemas/STATE.schema.json:154-184`** — `context.estimated_context_usage_pct`, `context.last_compact`, `context.observation_masking_active`, `context.rotation_history[]`.
- **`framework/hooks/context-monitor.sh`** — script that reads `tokens.total_input + total_output` and divides by `capacity_tokens` to compute `estimated_context_usage_pct`.

### Status vs R2

| R2 capability | APEX status | Evidence |
|---|---|---|
| Per-zone budget (R2-C055) | ✅ | 4 zones, sums to 200K. Matches R2 §8 zones structure. |
| Per-agent limits (R2-C051/C058) | ✅ | All 5 core agents capped; orchestrator (architect) at 40K = 20% which is **higher than R2's 10-15%**. |
| Reduction-priority order (R2-C003 implies) | ⚠️ | List exists but **no code consumes the array** — pure documentation (Agent B confirmed). |
| Real token counter (R2-C167) | 🚨 | `tokens.total_input` is **never written** by any hook; `next.md` only writes `framework_overhead +=` and `critic call tokens` — the script always falls through to `AGENT_CALLS * 20000 / capacity` heuristic. Live STATE.json: `estimated_context_usage_pct: 5` after 136 tool calls — value is meaningless. |
| Rotation triggers (R2-C091/C202) | ⚠️ | Utilization% via task-count proxy (`>= 4` tasks at `next.md:137`); phase-boundary manual; time-based via decision-gate; but `pattern=repeated_tool_errors` config is dead — no code reads `rotation_triggers[]`. |
| Generation-reserve never consumed (R2-C192) | ✅ | Schema closed; reserve declared. |
| Orchestrator at 10-15% (R2-C194) | ⚠️ | Architect cap = 40K (~20% of 200K). Above R2's recommended ceiling. |

### Critical findings

🚨 **Token counter is non-functional.** The whole budget enforcement chain depends on `total_input` being updated, but no hook writes it. This means every `estimated_context_usage_pct < 70` decision is based on the fallback heuristic, which is itself imprecise (`AGENT_CALLS * 20000`). All R2-leveraged metrics that depend on real token accounting (Context Health Dashboard R2-C212, ultimate metric R2-C214) are unreachable until the counter is wired.

⚠️ **Architect budget exceeds R2's orchestrator cap.** R2-C194 says "10-15% MAX" for the orchestrator. APEX architect is at 20% (40K/200K). For a 200K window, that's 5K above the R2 ceiling. (Empirically not catastrophic, but trending toward R2-C175 "orchestrator bottleneck".)

---

## P2 — Retrieval (RAG / Repo Map / File Selection)

### What APEX has

- **`framework/hooks/generate-task-map.sh:21-88`** — produces `.apex/TASK_MAP.md`. Reads explicit `files[]` from `PLAN_META.json` for the current task, plus `rg -l` keyword search over `src/ lib/ app/`. Each file: first 4 grep'd headers (`grep -E "^(export )?(async )?(function|const|class)" "$file" | head -4`).
- **`framework/hooks/tdad-index.sh:61-109`** — Python regex over `from '...'` and `require('...')` imports → builds test↔source dependency map → writes `.apex/TEST_MAP.txt` (`src|test1,test2` lines).
- **`framework/commands/apex/next.md:410`** — annotates `repo_map: .apex/TASK_MAP.md (1-4K tokens)` (matches R2's 1-4K target).
- **`framework/commands/apex/next.md:418-419`** — `active_files: full content of files in task.files`; `interface_context: function signatures only for dependencies`.
- **`framework/hooks/ast-kb-check.sh`** — hallucinated-import guard (Node `require.resolve()` / Python `import x` validity). Advisory exit 1, never blocking. Cited motivation: "19.7% of AI-generated imports reference non-existent modules (USENIX research)."
- **Hybrid retrieval**: always-present TASK_MAP injected to architect prompt; on-demand Grep/Glob/Read tools available to all agents.

### Status vs R2

| R2 capability | APEX status | Evidence |
|---|---|---|
| Always-present compressed repo map 1-4K (R2-C065/C072) | ✅ | TASK_MAP.md generated and injected at architect Step 0. |
| tree-sitter AST parsing (R2-C066) | ❌ | `grep -r tree-sitter framework/` = 0 matches. |
| PageRank biased 50× to active files (R2-C066) | ❌ | No centrality scoring anywhere. |
| Plan-driven vs graph-driven retrieval | ⚠️ | Plan-driven: `PLAN_META.files[]` + grep. Not graph-derived. R2 says graph approach achieves 4.3-6.5% context utilization (Aider) vs Cursor 14.7%. |
| Signatures-only for dependencies (R2-C066) | ⚠️ | Yes for deps (`interface_context`), but **full content for active files**. Mixed. |
| Tier-3 vector/semantic retrieval (R2-C072) | ❌ | None. SQLite mirror exists but for STATE replay, not vector index. FTS5 only over event-log. |
| GrepRAG / lexical intent-aware (R2-C070) | ⚠️ | Grep is available as tool, but no orchestrated hybrid (lexical+semantic). |
| On-demand file reads (R2-C072) | ✅ | Read/Glob/Grep tools standard. |

### Critical findings

❌ **No Aider-style structural retrieval.** APEX's repo map is plan-driven (PLAN_META.files[] + keyword grep), not graph-driven. R2 §B3 puts Aider as the gold standard with 4.3-6.5% context utilization (highest measured). This is a known gap — also flagged by R6 synthesis as a Phase-2/3 consideration.

✅ **Token budget for repo map matches R2.** 1-4K target.

---

## P3 — Compaction & Observation Masking

### What APEX has (declarative)

- **`framework/CONTEXT_BUDGET.default.json:14-19`** — `working_memory.policy: "Observation masking after task. Compact on threshold."`
- **`framework/CONTEXT_BUDGET.default.json:44-49`** — `context_reduction_priority: ["observation_masking", "compact_working_memory", "evict_completed_task_context", "hard_rotate"]` — observation masking listed FIRST.
- **`framework/schemas/STATE.schema.json:170`** — `context.observation_masking_active: boolean`.
- **`framework/templates/STATE-init.template.json:59`** — initialized to `true`.
- **`framework/apex-design-notes.md:8`** — explicitly cites R2 finding: "Observation masking > LLM summarization (R2: JetBrains study, 50% cost, equal quality)."

### What APEX has (operational)

- **`framework/hooks/pre-compact.sh:11-42`** — backs up STATE.json + active PLAN.md to `.apex/backups/` before Claude's built-in /compact runs. Validates backup with `STATE_BACKUP_OK` gate.
- **`framework/hooks/pre-compact.sh:35`** — emits a single banner: `echo "R2: Observation masking active — old tool outputs should be re-read, not cached."` (printed message only).
- **`framework/commands/apex/next.md:139,140,326,873`** — invokes Claude Code's built-in `/compact` (LLM summarization).

### Status vs R2

| R2 capability | APEX status | Evidence |
|---|---|---|
| Observation masking actually deletes old tool outputs (R2-C003/C032/C231) | 🚨 **THEATRE** | `observation_masking_active` is initialized once and **never flipped or read** by any code path. Agent B confirmed: zero writes outside init template; the reduction-priority array is unconsumed; pre-compact.sh only emits a banner. **The R2-C003 50% cost win is unrealized.** |
| Default to observation masking, fallback to LLM summarization at phase boundary (R2-C003/C226) | ❌ | The reverse — LLM `/compact` is the only actual mechanism. R2 anti-pattern R2-C169 in active use. |
| Pre-compact backup to `.apex/backups/` | ✅ | Working — STATE.json and PLAN.md captured. |
| Compact at 50-60% (R2-C037) | ⚠️ | `proactive_compact_pct: 55` configured. But triggered via task-count proxy (`>= 4 tasks`), not real % (because token counter is dead — see P1). |
| Re-read files from disk after compaction (R2-C040) | ✅ | Agent prompts explicitly tell agents not to trust cached file reads ([critic.md:12, executor.md:91-93](framework)). |
| Anthropic context editing (R2-C099/C156) | ❌ | `grep -r "context.editing" framework/` = 0 matches. Available since Sep 2025. |

### Critical findings

🚨 **Highest-leverage R2 gap.** Observation masking is the most-cited single technique (4/5 models, JetBrains DL4C 2025, R2-C003/C032/C231). APEX has the design intent in `apex-design-notes.md:8`, the policy in CONTEXT_BUDGET, the priority list, the schema field — but **no code that does the deletion**. This is the #1 fix-target for the recommendations phase.

⚠️ **APEX defaults to LLM summarization** (R2 anti-pattern R2-C169) by routing to Claude Code's built-in `/compact`, while documenting the opposite intent in design notes. R2 explicitly says LLM summarization causes ~15% LONGER agent runs because smoothed summaries hide failure patterns.

---

## P4 — Multi-Agent Isolation

### What APEX has

- **`framework/agents/critic.md:2-3`** — explicit declaration: "Clean-room adversarial reviewer. NEVER sees executor reasoning."
- **`framework/agents/critic.md:15-16`** — exclusion list: "WHAT YOU NEVER RECEIVE (and must NEVER request) — Executor's SUMMARY.md, CoT, confidence, failed attempts, or any narrative about WHY code was written this way."
- **`framework/agents/critic.md:18-22`** — explicit debiasing instructions:
  - "Assume code MAY contain subtle bugs even if tests pass"
  - "Treat passing tests with skepticism — tests may be weak or self-mocking"
  - "Evaluate AGAINST THE SPEC, not against what seems reasonable"
  - "If you can't verify from the diff, mark UNVERIFIED"
- **`framework/agents/critic.md:24-30`** — anti-fraud rule: "If RESULT.json asserts X and filesystem denies X → CRITICAL (fraud, not mistake)."
- **`framework/schemas/RESULT.schema.json:5`** — schema-level contract: "Critic reads ONLY this file — never SUMMARY.md."
- **`framework/agents/executor.md:125-185`** — executor writes RESULT.json (machine, for critic) AND SUMMARY.md ([executor.md:185](framework/agents/executor.md): "The critic will NEVER see this file").
- **`framework/agents/critic.md:9-13`** — critic input contract: `task_spec` (PLAN_META), `git diff HEAD~1`, modified files re-read from disk, and from RESULT.json **only** `tests_run` + `verify_commands_run`.
- **Three-agent verification stack:**
  - **critic** (per-task adversarial, clean-room, single-pass) → writes `[task]-CRITIC.md`
  - **verifier** (phase-level, NOT clean-room — explicitly reads SUMMARY.md for phantom-language at `verifier.md:9`) → writes `VERIFY.md`
  - **auditor** (test-quality, stricter quarantine — reads ONLY test files, never implementation) → writes `[task]-AUDIT.md`
- **`framework/agents/architect.md:183-186`** — architecture-debate uses file-based isolation: each advocate writes to a separate file, judge reads files only.
- **`framework/agents/architect.md:121-155`** — `roundtable_needed` flag triggers `/apex:_roundtable` multi-specialist deliberation for cross-cutting/irreversible tasks.
- **`framework/hooks/cross-phase-audit.sh:54-129`** — re-runs all prior-phase verify commands; nonzero exit = REGRESSION; updates `STATE.json.evoscore.regression_rate`; exits 2 (BLOCKED) on failure.

### Status vs R2

| R2 capability | APEX status | Evidence |
|---|---|---|
| Critic clean-room (R2-C006/C123/C232) | ✅ | Explicit in critic.md:2-3 + RESULT.schema.json:5 + executor.md:185 (SUMMARY.md never reaches critic). |
| Explicit debiasing instructions (R2-C120) | ✅ | critic.md:18-22, four explicit anti-bias clauses. R2 says +25% detection improvement. |
| Worker→Orchestrator typed JSON (R2-C112/C199) | ✅ | RESULT.schema.json closed schema with required fields: status, files_modified, files_read, tests_run, decisions_made (with rationale+spec_ref), issues_found, unresolved_risks, verified_criteria, unverified_criteria, confidence, attempt_number. **Stronger than R2 baseline.** |
| Artifacts-to-disk pattern (R2-C113) | ✅ | Workers write code/configs to disk; orchestrator verifies artifacts directly via cross-phase-audit. |
| Two-pass clean-then-conditional (R2-C124/C207) | ❌ | Single-pass only. On FAIL, critic writes REFLEXION.md feeding next executor attempt — not a second critic pass. |
| Model/temperature diversity for verification (R2-C125) | ❌ | All agents run on same Claude Code model. No frontmatter declares model/temperature. |
| Adversarial parallel personas for code review (R2-C208) | ⚠️ | Single critic per task. **However:** parallel-personas exist for *planning* via `/apex:_debate` (architect.md:183-186) and `/apex:_roundtable` (architect.md:121-155) — both pre-execution, file-isolated. Not used for code review. |
| Different verifier vs critic role (R2-C006) | ✅ | Three distinct agents: critic (per-task, clean-room), verifier (phase-level, sees SUMMARY for phantom check), auditor (test-quality, file-quarantined to test files). |
| Free-text inter-agent comms anti-pattern (R2-C180) | ✅ avoided | Typed JSON via RESULT.json; SUMMARY.md is human-only. |
| Cross-phase regression audit (R2-C108 implication) | ✅ | cross-phase-audit.sh re-runs verify commands; exit 2 on regression. |
| TiCoder-style test-first generation loop (R2-C146) | ❌ | TDD is conditional per-task ([executor.md:115-116](framework/agents/executor.md): only when `has_behavior=true OR verify_level=C|D`), not a generation-feedback loop. |
| Coordination plateau >4 agents (R2-C181) | ✅ avoided | Core stack = 4 agents (architect/executor/critic/verifier) + auditor as conditional 5th. |

### Critical findings

✅ **APEX nailed clean-room verification.** Schema-enforced, prompt-reinforced, policy-explicit. R2-C232 ("Clean-room verification — architecturally isolating verifiers") is the one R2 §9 missing-piece that APEX has actually solved well. Debiasing prompt exists; verifier separation is real.

⚠️ **Two-pass conditional reveal not implemented.** R2-C124/C207 calls for Pass 2 to reveal limited factual implementer summary on disagreement. APEX uses single-pass + REFLEXION feedback to next attempt. Likely OK for most cases but a documented R2 deviation.

❌ **No model/temperature diversity.** R2-C125. Likely M-effort change (executor on Sonnet, critic on Opus, or temperature delta).

❌ **No code-review parallel personas.** Pre-execution debate exists but no security/architecture/performance critic split per code review. R2-C208 mentions this as a verification enhancement but it's a P2/P3 add-on, not a critical gap.

---

## P5 — Session Rotation & Checkpointing

### What APEX has

- **Triggers in `framework/commands/apex/next.md`:**
  - Utilization-proxy: `tasks_completed - tasks_since_last_rotation >= 4` ([next.md:137](framework/commands/apex/next.md#L137))
  - Phase-boundary: when `current_session_phase != current_phase` → prompts user to rotate ([next.md:323-326](framework/commands/apex/next.md#L323-L326)) — **manual**.
  - Time-based: `GATE_INTERVAL` 60-90 min by complexity ([next.md:195-219](framework/commands/apex/next.md#L195-L219)) — decision-gate, not auto-rotate.
- **`framework/hooks/turn-checkpoint.sh:78-117`** — writes `.apex/TURN_CHECKPOINT.json` every 5 tool calls inside a long-running task.
- **`framework/hooks/memory-watchdog.sh:81-93`** — samples Bun runtime RSS + commit MB; threshold 2048MB. Triggers `.apex/AUTO_PAUSE_REQUEST.flag` after 3 consecutive over-threshold samples.
- **`framework/hooks/circuit-breaker.sh:35-101`** — checks consecutive no-change actions; triggers HALT, not rotation.
- **`framework/commands/apex/resume.md:62-65`** — post-rotation load: STATE.json, COMPLEXITY.md, SPEC.md (first 3 sections), DECISIONS.md (last 10).
- **`framework/commands/apex/resume.md:68-75`** — loads memory primitives (todos, threads, seeds, backlog).
- **`framework/schemas/STATE.schema.json:170-184`** — `context.rotation_history[]` with phase, session_ended, reason.
- **`framework/schemas/STATE.schema.json:341-345`** — `session.tasks_since_last_rotation`, `total_context_rotations`, `health_status` (green/yellow/red).
- **`framework/schemas/STATE.schema.json:399-414`** — `drift_indicators.spec_drift_count`, `circuit_breaker_triggers`, `reflexion_total_attempts`, `low_confidence_results`.

### What turn-checkpoint actually captures

`.apex/TURN_CHECKPOINT.json` schema fields ([STATE.schema.json:457-491](framework/schemas/STATE.schema.json#L457-L491)):
- ✅ `task_id`, `tool_call_index`, `last_completed_tool`
- ❌ `working_summary` is always `null` (lines 83-86, 113 of turn-checkpoint.sh) — hook explicitly disclaims: "It does not write a working_summary — that requires conversational context the hook cannot see."
- ❌ Empty `in_flight_edits[]` in practice
- ❌ Does NOT capture: DECISIONS.md state, git tag, phase summary

Live STATE.json verification: `task_id: "(unknown)"`, `working_summary: null` — confirms turn-checkpoint runs blind to context.

### Status vs R2

| R2 capability | APEX status | Evidence |
|---|---|---|
| Hard-rotate at 70% (R2-C091) | ⚠️ | Threshold configured (70%) but token counter is dead → never reaches the comparison. |
| Soft/proactive 50-60% (R2-C037/C230) | ⚠️ | Configured but unreachable for same reason. |
| Phase-boundary rotation (R2-C091/C202) | ✅ | Working but manual prompt — not auto. |
| Task-batch (every 5-8 tasks) (R2-C091) | ⚠️ | Hardcoded `>= 4` — outside R2's 5-8 range. |
| Time-based 30-45min (R2-C091) | ⚠️ | 60-90min — exceeds R2's window. Decision-gate, not rotation. |
| Quality-signal triggers (R2-C091/C202) | ❌ | `pattern=repeated_tool_errors` configured but **no code reads `rotation_triggers[]`**. Drift indicators exist but feed `health_status` (which causes pause, not rotation). |
| Recovery-density spike 3+ same actions (R2-C091/C202) | ⚠️ | Circuit-breaker tracks consecutive no-change but triggers HALT (not rotation). |
| State-preservation pre-rotation: STATE+DECISIONS+git-tag+phase-summary (R2-C203) | ⚠️ | turn-checkpoint captures STATE-lite only; git tagging is a separate hook (`pre-task-snapshot`); phase summaries are SUMMARY.md flow; **no atomic capture mechanism**. |
| State-restoration post-rotation (R2-C204) | ⚠️ | ~60% compliant: loads STATE+SPEC slice+DECISIONS slice. Does NOT regenerate repo-map at resume. Does NOT explicitly load PLAN_META.json. Re-reading source files happens per-task downstream, not at resume. |
| **Do NOT load conversation history** (R2-C204) | ✅ | Compliant by virtue of fresh session. |
| Prompt caching utilization (R2-C092/C155) | 🚨 | `grep -r "cache_control\|prompt_cach" framework/` = **0 matches**. The R2-C092 90% cost / 85% latency win is **completely unrealized**. apex-design-notes.md:11 declares the intent ("stable prefix first → 90% input cost reduction") but no API call uses it. |

### Critical findings

🚨 **Prompt caching is 0% utilized.** Anthropic prompt caching has been production-ready since 2024 (R2-C092: 10% input price, 85% latency reduction, break-even at 2 cache hits). APEX declares the design pattern (stable_prefix zone, "stable prefix FIRST" comment in next.md:404) but **never actually annotates any prompt with `cache_control` markers**. This is the second-highest-leverage P0 fix after observation masking.

🚨 **Token-utilization-based rotation is unreachable** (because P1's token counter is dead). All thresholds in CONTEXT_BUDGET.default.json:26-31 are theoretical.

⚠️ **State-preservation is fragmented across hooks.** R2-C203 wants atomic capture (STATE + DECISIONS + git tag + phase summary). APEX has all four mechanisms but in different hooks fired at different times. A `pre-rotation-snapshot` hook that bundles them would close the gap.

⚠️ **Resume is ~60% R2-compliant.** Missing repo-map regeneration and explicit PLAN_META reload.

---

## P6 — Memory Integrity

### What APEX has

- **`framework/apex-learnings.md:1-170`** — tiered memory accumulator:
  - **HOT** (max 30, always loaded into architect): requires `Seen in: 2+ projects` AND `Status: ACTIVE` AND `Confidence: VALIDATED+`.
  - **WARM** (max 100, loaded when stack/domain matches): single-project OK, CANDIDATE+.
  - **COLD** (archive, never auto-loaded): >90 days without re-confirmation.
- **Write gates** ([apex-learnings.md:8](framework/apex-learnings.md#L8)): "Failure-derived → WARM immediately. Success-derived → require 2-project threshold."
- **Confidence lifecycle**: CANDIDATE (1) → VALIDATED (2+) → ESTABLISHED (5+).
- **Per-entry fields** ([apex-learnings.md:22-37](framework/apex-learnings.md#L22-L37)): Severity, Decay class, Evidence count, Seen in (project list), Detection, Prevention, Citation (file:line+date), Status, Confidence.
- **Decay classes** (declared in apex-learnings.md, enforced in `verify-learnings.sh:27-36`): safety=999999d, architectural=365d, bug=180d, framework=90d, project=30d.
- **`framework/hooks/verify-learnings.sh:38-146`** — validation hook (SessionStart trigger):
  - Lines 68-75: validates `Evidence count ≥ 1`.
  - Lines 77-95: emits `⏰ DECAYED:` advisory when age exceeds decay-class max.
  - Lines 97-116: citation file-existence check (no hash check).
  - Lines 128-134: tier ceiling advisories (HOT>30, WARM>100).
- **`framework/modules/apex-memory-synthesis/agent.md:9-15`** — memory-synthesis agent (DREAM CYCLE protocol, lines 54-80) — but **operates only on `.apex/todos|threads|seeds|backlog/`**, not on `apex-learnings.md`.
- **`framework/hooks/pre-compact.sh:11-42`** — backs up STATE.json + PLAN.md to `.apex/backups/`. **No equivalent backup for `apex-learnings.md`.**
- **`framework/docs/STATE-PLANE.md:22-38`** — opt-in SQLite mirror (`APEX_SQLITE_MIRROR=1`, fail-loud when sqlite3 absent). FTS5 over event-log only — not over learnings.

### Status vs R2

| R2 capability | APEX status | Evidence |
|---|---|---|
| T1 always-loaded CLAUDE.md <200 lines (R2-C076/C209) | ⚠️ | Slice via `next.md:409` (first 200 lines), not write-time enforced. Documented in apex-design-notes.md:10. |
| T2 per-phase STATE/DECISIONS/PLAN_META (R2-C209) | ✅ | `CONTEXT_BUDGET.default.json:7` lists these as stable_prefix zone contents. |
| T3 on-demand filesystem (R2-C209) | ✅ | Read/Grep/Glob tools standard. apex-learnings.md is HOT/WARM/COLD-banded markdown. |
| T4 cold SQLite/vector (R2-C209/C210) | ⚠️ | SQLite mirror exists but **opt-in**, off by default. No vector store. COLD band of apex-learnings is markdown archive, not SQLite-backed. |
| Provenance: source-agent (R2-C211) | ❌ | Per-entry fields lack `source-agent`. Only critic writes by convention; no machine-readable author. |
| Provenance: machine-readable timestamp (R2-C211) | ⚠️ | "Verified" / "Citation" date strings exist but are text, not RFC 3339. |
| Provenance: confidence (R2-C211) | ✅ | CANDIDATE/VALIDATED/ESTABLISHED ordinal. |
| Provenance: scope (R2-C211) | ❌ | No scope field (per-entry). R6 §8 Q6 calls for PROJECT/ORG/GLOBAL tiers. |
| Provenance: invalidation-path (R2-C211) | ❌ | Not present. |
| Decay enforcement: detect-only (R2-C081) | ⚠️ | verify-learnings.sh emits `⏰ DECAYED` advisory but **no auto-demote/archive sweep**. Operator-driven. |
| Hash-invalidation on file change (R2-C081/C211) | ❌ | Citations are text-only (file:line). circuit-breaker.sh hashes git diff but for action-loop detection, not memory invalidation. |
| Validated snapshot backups (R2-C211) | ⚠️ | STATE/PLAN backed up; **`apex-learnings.md` is NOT** — vulnerable to MINJA-style overwrite without rollback. |
| Periodic memory audit by independent agent (R2-C211) | ⚠️ | memory-synthesis agent exists but **excludes apex-learnings.md scope**. Audit is by `verify-learnings.sh` script — not an agent. |
| Quarantine speculative observations (R2-C211) | ⚠️ | Documented gate ("Failure-derived → WARM, Success-derived → 2-project threshold") but **no code-enforced gate** — depends on critic write discipline. |
| Cap memory pointer-vs-content ratio | ❌ | Not present. |
| Tier ceiling enforcement (advisory-only) (R2-C209) | ⚠️ | HOT≤30, WARM≤100 advisory; no auto-eviction. |
| MINJA defense (R2-C082-086) | ⚠️ | Smaller threat surface (single-developer, file-based) per R6 §11 #6. But no provenance, no validated backups for learnings, no agent audit. |

### Critical findings

⚠️ **Memory architecture is partially complete; the gaps are in integrity not structure.** APEX has tiers, decay classes, write gates, evidence counters, lifecycle states. The R2 §9 missing-piece R2-C234 ("Memory integrity — provenance, decay, poisoning protection") is partially addressed (decay) but missing key elements (provenance fields, hash-invalidation, learnings backup, dedicated audit agent).

⚠️ **memory-synthesis agent exists but doesn't audit learnings.** R6 §8 Q10 strongly recommends a dream-cycle agent that includes apex-learnings.md in its scope. APEX has the agent (`apex-memory-synthesis/`) but its scope is limited to todos/threads/seeds/backlog. Extending its scope is M-effort.

❌ **No backup for apex-learnings.md.** R2-C211 mandates "validated backup snapshots" for memory. APEX backs up STATE and PLAN but not learnings. Trivial S-effort fix.

❌ **No hash-invalidation on cited code changes.** R2-C081 mitigation. Citations are file:line text strings — when the code at that line changes, no detection. circuit-breaker.sh has hashing infra that could be reused.

---

## P7 — Verification (Clean-Room)

(Covered in P4 above. Summary here for completeness.)

| R2 capability | APEX status |
|---|---|
| Clean-room critic (R2-C123/C232) | ✅ |
| Debiasing instructions (R2-C120) | ✅ |
| Pass 1 / Pass 2 protocol (R2-C124/C207) | ❌ |
| Model/temperature diversity (R2-C125) | ❌ |
| Parallel personas for review (R2-C208) | ⚠️ planning-only |
| TiCoder test-first loop (R2-C146) | ❌ |
| Verifier independent of critic (R2-C006) | ✅ |
| Anti-fraud (RESULT vs filesystem) (R2-C123 strengthening) | ✅ |
| Cross-phase regression audit (R2-C108) | ✅ |

---

## R2 §9 — The 6 Missing Pieces — Direct Verdict

R2's conclusion (line 977-986) explicitly identifies 6 gaps. Direct status:

| # | R2 missing piece | APEX status | Evidence |
|---|---|---|---|
| 1 | **Observability** — measuring context health real-time | 🚨 **MISSING** | Schema fields exist (STATE.json `context.estimated_context_usage_pct`, `tokens.total_input`, `session.health_status`, `drift_indicators`), but `total_input` is never written → all dependent metrics are based on a fallback heuristic. No Context Health Dashboard rendering. |
| 2 | **Proactive rotation** — compact at 50-60% not 85% | ⚠️ **CONFIGURED, UNREACHABLE** | Thresholds set correctly (`proactive_compact_pct: 55`, `hard_rotate_pct: 70`) but rotation actually triggers via task-count proxy because the % itself is unreliable. R2-C037 *thresholds* match but the *trigger mechanism* is broken. |
| 3 | **Observation masking** — delete tool outputs | 🚨 **THEATRE** | Boolean flag never flipped, reduction-priority array never consumed, pre-compact emits a banner. Design intent in apex-design-notes.md:8 + R2-C003 explicit, but **zero implementation**. |
| 4 | **Clean-room verification** — architecturally isolating verifiers | ✅ **SOLVED** | The one R2 §9 piece APEX did right. critic.md:2-3 + RESULT.schema.json:5 + executor.md:185 enforce isolation; debiasing instructions in critic.md:18-22; three-agent stack with role separation. |
| 5 | **Task-adaptive loading** — different profiles per task type | ❌ **MISSING** | One CONTEXT_BUDGET for all task types. R2-C132-137 calls for 6 different profiles (new-code/bug-fix/code-review/refactor/test-writing/frontend). `grep -E "task_type\|task_adaptive\|profile" framework/CONTEXT_BUDGET.default.json` = 0 matches. |
| 6 | **Memory integrity** — provenance, decay, poisoning protection | ⚠️ **PARTIAL** | Decay classes ✅, evidence counters ✅, tier ceilings ✅. **But:** no provenance fields (source-agent/scope/invalidation-path), no hash-invalidation, no learnings backup, no dedicated audit agent for learnings. |

**Score:** 1 ✅ | 2 ⚠️ | 3 🚨/❌

---

## Cross-Check vs Prior APEX Synthesis Rounds (R3, R5, R6, Verification)

| R2 finding cluster | Prior round addressed? | Evidence |
|---|---|---|
| Clean-room critic + debiasing | ✅ R3, R4 | apex-design-notes.md:16-17 cites R3 88.2% adversarial, R3-R4 93.75% with debiasing. **Already addressed.** |
| Token budget per-agent limits | ✅ R5/R7 (improvement #19) | apex-design-notes.md:82, CONTEXT_BUDGET.schema.json. **Architecture in place; counter is dead.** |
| Phase tagging on pass + rollback (improvement #23) | ✅ R5 | verifier.md, recover.md. |
| TDAD impact-aware testing (improvement #14) | ✅ R4 (70% regression reduction) | apex-design-notes.md:20. |
| Prompt caching | ❌ Declared (R7), not implemented | apex-design-notes.md:11 declares; **no cache_control anywhere**. |
| Tiered memory HOT/WARM/COLD with decay classes | ✅ R6 | apex-r6-synthesis.md §3.5 + apex-learnings.md. **Architecture done, integrity partial.** |
| Memory poisoning / MINJA defense | ⚠️ R6 acknowledged, partial implementation | r6 §5 says smaller threat surface for APEX (single-dev file-based); explicit defenses not all in place. |
| Memory synthesis agent (dream cycle) | ✅ R6 — agent exists | But scope excludes apex-learnings.md. |
| 3 vs 7 agents | ✅ R3 / apex-design-notes.md:25 | "3 focused agents >> 7 chatty ones: AgentCoder 96.3% HumanEval (R3)". |
| Structured artifacts crush free-text | ✅ R3 | apex-design-notes.md:27 — "87% token reduction". RESULT.schema.json:5 enforces. |
| Mutation testing | ⚠️ Verification synthesis flagged as gap | apex-verification-research-synthesis.md §1 finding 4 + recommendations. mutation-gate.sh exists for C/D tasks. **Already addressed for verify-level C/D.** |
| Property-based testing | ❌ Verification synthesis flagged; not in apex-design-notes | Gap. |
| Differential semantic testing | ❌ Verification synthesis flagged; not in apex-design-notes | Gap. |
| Auth/tenant security verification | ⚠️ R4 — security persona for D-level critic (apex-design-notes.md:55) | Partial — covers vulnerability detection but not multi-tenant. |
| Observation masking | ❌ Declared (R2 + apex-design-notes.md:8); not implemented | **The unaddressed R2 finding.** |
| Aider-style AST + PageRank repo map | ⚠️ R6 acknowledged, not implemented | "Phase 2-3 consideration" per r6 §3.3. |
| Per-task-type context profiles | ❌ Not in any prior round | Novel R2 finding (R2-C138). |
| Task#N quality vs Task#1 metric | ❌ Not in any prior round | Novel R2 finding (R2-C214) — "the ultimate APEX metric". |
| Two-pass critic with conditional reveal | ❌ Not in any prior round | Novel R2 finding (R2-C124/C207). |
| Model/temperature diversity | ❌ Not in any prior round | Novel R2 finding (R2-C125). |
| Anthropic context editing API | ❌ Not in any prior round | Novel — published Sep 2025 after R3-R6. |

**Filter result for Phase 4 recommendations:** Items already addressed in prior rounds will receive `prior_round_addressed: yes` in the gap matrix and will NOT generate new recommendations unless the implementation is incomplete (e.g., token counter dead despite R7 design).

---

## Summary Table — APEX Coverage of R2 Capabilities

| Primitive | R2 expectation | APEX status | P0 leverage? |
|---|---|---|---|
| **P1 Token Budgeting** | Per-zone per-agent + real metering | ⚠️ Schema OK, counter dead | 🚨 P0 — unlocks all metrics |
| **P2 Retrieval** | Aider-style AST+PageRank, 1-4K | ⚠️ Plan-driven, 1-4K, no AST | P2 — gap noted in R6 |
| **P3 Compaction & Masking** | Default observation masking | 🚨 Theatre — banner only | 🚨 P0 — highest single R2 leverage (50% cost) |
| **P4 Multi-Agent Isolation** | Coordinator + fresh workers | ✅ Done | — |
| **P5 Rotation & Caching** | Proactive 50-60%, prompt caching | 🚨 Caching unused, rotation unreachable | 🚨 P0 — 90% cost / 85% latency unrealized |
| **P6 Memory Integrity** | Provenance + decay + audit + backup | ⚠️ Decay ✅, others partial | P1 — incremental hardening |
| **P7 Verification** | Clean-room + debiasing | ✅ Done (single-pass) | — |

### The 3 Theatre-Level Gaps (Phase 4 P0 candidates)

1. 🚨 **Observation masking** — declared in policy, schema, design notes; zero implementation. Unlocks R2-C003 (50% cost reduction, +2.6% quality).
2. 🚨 **Token counter** — `total_input` never written; all utilization metrics dead. Unlocks the entire Context Health Dashboard (R2-C212), and makes R2-C037/C091 thresholds actually trigger.
3. 🚨 **Prompt caching** — design intent declared (apex-design-notes.md:11); no `cache_control` markers anywhere. Unlocks R2-C092 (90% cost / 85% latency).

These three together are the dominant lever set: implementing them likely yields > 60% of the R2-promised cost-quality improvement APEX could realize.

**Phase 2 status:** ✅ Complete.
**Next:** Phase 3 — Build R2-APEX-GAP-MATRIX.md mapping all 235 R2 claims to APEX status with severity/effort/leverage scoring.
