# APEX Round 3 — Synthesized Research Brief
## Agent-to-Agent Communication Patterns in LLM Coding Systems
### Cross-Model Synthesis (4 Deep Research Sources, March 2026)

---

## 1. Executive Summary

This document distills findings from four independent deep-research passes on how LLM-based agents communicate in multi-agent coding systems. Where multiple models converge on the same finding, confidence is high. Where they diverge, tensions are noted explicitly. All benchmark numbers are cross-referenced; fabricated or unverifiable claims are flagged.

### The Seven Core Findings (Unanimous or Near-Unanimous)

**Finding 1: More communication between agents usually makes things worse.**
CooperBench (Stanford/SAP, 2026; 652 task pairs, 12 repos) found two-agent cooperation produces ~30% lower success rates than solo performance. Leading models (GPT-5, Claude Sonnet 4.5) achieved only ~25% success in two-agent cooperation — roughly 50% worse than a single agent doing both tasks. Failure breakdown: expectation failures 42%, commitment deviations 32%, communication jams 26%. Adding communication channels did not meaningfully improve merge success (GPT-5: 27.91% without comm vs 27.90% with; Claude: 27.30% vs 25.92%).
*[All 4 models cite CooperBench with consistent numbers; M2 adds the per-model communication delta data]*

**Finding 2: Three focused agents beat seven chatty ones.**
AgentCoder's 3-agent pipeline (programmer → test designer → test executor) achieves 96.3% on HumanEval and 91.8% on MBPP (GPT-4) with only 56.9K tokens. ChatDev's 7-agent waterfall achieves 33.33% on ProgramDev (MAST evaluation) with far higher token costs. MetaGPT's SOP-constrained pipeline achieves 85.9%/87.7% on HumanEval/MBPP at 126.5 tokens/line vs ChatDev's 248.9.
*[M1, M2, M3, M4 all cite AgentCoder; M1 reports lower numbers (79.9%/89.9%) which appear to be an ablation variant, not the full system — the 96.3%/91.8% figures from M2/M3/M4 are the correct full-system results]*

**Finding 3: Verifier contamination is catastrophic and measurable.**
A March 2026 study found Claude Code's autonomous review accepts adversarially framed vulnerable code in 88.2% of cases when PR metadata provides implementer reasoning. Metadata redaction restores detection in 94% of autonomous cases and 100% of interactive cases. No tested mitigation strategy (CoT, reflection, explicit debiasing instructions) effectively reduces anchoring — only removing the anchor works.
*[M3 provides the primary source; M1 and M4 cite the same 88.2% figure via R2 findings; M2 cites LLM-judge bias research independently]*

**Finding 4: Simple verification prompts outperform complex ones.**
Asking an LLM to judge conformance, explain reasoning, AND propose a fix causes a 20–40 percentage point accuracy drop compared to simple direct judgment. The LLM assumes flaws exist and suggests unnecessary modifications (overcorrection bias). This directly contradicts chain-of-thought intuition for verification tasks.
*[M3 provides primary evidence from ASE 2025; M2 independently cites Anthropic finding that a single judge with rubric was more consistent than multi-judge setup]*

**Finding 5: The coordination plateau is real — beyond ~4 agents, returns go negative.**
Google DeepMind's 180-configuration scaling study found: centralized coordination improves performance by 80.9% on parallelizable tasks; beyond 4 agents coordination latency grows superlinearly (power-law exponent ~1.724); for sequential reasoning tasks ALL multi-agent variants degraded performance by 39–70%; when single-agent baseline exceeds ~45% accuracy, coordination overhead exceeds benefits. Centralized orchestration contains error amplification to 4.4x; unstructured networks amplify 17.2x.
*[M3 and M4 provide the deepest DeepMind analysis; M1 and M2 cite compatible but less specific scaling data]*

**Finding 6: Structured artifacts crush free-text dialogue.**
MetaGPT explicitly invokes the telephone game as motivation for replacing natural language with typed schemas. OpenAI's structured outputs achieve 100% schema compliance vs <40% without strict mode. Dual-agent architecture research found codified communication (fixed-format pseudocode, YAML, JSON) achieves up to 87% token reduction compared to free-text while improving logical consistency.
*[All 4 models converge; M3 provides the OpenAI compliance data; M4 provides the 87% token reduction figure]*

**Finding 7: The orchestrator must stay lean.**
MAST found 41.8% of multi-agent failures stem from specification and system design issues — the orchestrator level. In MetaGPT, 72% of all tokens go to verification and coordination, not productive work. Production systems (LangGraph, OpenHands, Claude subagents) all externalize state rather than accumulating it in the orchestrator's context.
*[M3 provides the 41.8%/72% figures; all 4 models agree on stateless-by-discipline orchestration]*

### Bottom Line for APEX
APEX's current architecture (coordinator + fresh workers, typed RESULT.json, clean-room critic, file/git state, reflexion loop, architecture debate) is validated by strong evidence. The topology is correct. What needs tightening: stricter contracts, simpler critic prompts, near-stateless orchestrator discipline, and no lateral worker communication for write tasks.

---

## 2. Communication Topology Analysis

### 2.1 Hub-and-Spoke / Coordinator-Worker ⭐ (APEX's Pattern)

**How it works.** A single orchestrator decomposes tasks, dispatches to specialized workers with fresh context, and aggregates results. Workers report strictly back to the hub.

**Measured results (cross-validated).**
- Anthropic's multi-agent research system: lead + subagents outperformed single-agent Opus 4 by 90.2% on internal research evals. However, Anthropic notes this is valid especially for breadth-first tasks, not necessarily tight coding. [M2]
- DeepMind: centralized coordination improves performance by 80.9% on parallelizable tasks, containing error amplification to 4.4x (vs 17.2x unstructured). [M3, M4]
- Factory.ai hub-spoke Droids: #1 on Terminal-Bench at 58.75%. [M3]
- MetaGPT: better tokens/LOC (126.5) than ChatDev (248.9) despite more total tokens per project. [M1, M2]

**Token overhead.** Moderate — scales linearly with worker count. Anthropic reports agents use ~4x more tokens than chat, multi-agent systems ~15x. Claude teams note token use grows linearly with teammate count. CrewAI's hierarchical mode adds ~6–9 additional manager LLM calls per 3-worker crew. [M2, M3]

**Best for.** Parallelizable coding tasks; phase-separated workflows; tasks with truly independent subtasks.

**Worst for.** Simultaneous editing of shared files; tasks with dense dynamic dependencies between workers.

**Failure modes.**
- Orchestrator state bloat over many rounds [All 4]
- Imprecise task decomposition causing duplicate work — Anthropic found subagents "performed the exact same searches" with vague instructions [M2, M3]
- Single point of failure at orchestrator [M4]
- Workers unable to request missing context [M3]

### 2.2 Sequential Pipeline (A → B → C)

**How it works.** Linear, unidirectional handoffs. Each agent processes the upstream artifact and forwards.

**Measured results.**
- AgentCoder (programmer → test designer → executor): 96.3% HumanEval, 91.8% MBPP; 56.9K tokens — the most efficient multi-agent pattern measured. Ablation: programmer alone = 61.0%, full 3-agent = 96.3% (+35.3pp from architecture alone). [M2, M3, M4]
- MapCoder (4-stage: recall → plan → generate → debug): 93.9% HumanEval, 83.1% MBPP. [M1]
- AgileCoder: 57.79% executability on ProjectDev vs ChatDev's 32.79%. [M4]

**Token overhead.** AgentCoder: 56.9K/66.3K (HumanEval/MBPP) — lowest of any multi-agent system. MetaGPT: 138.2K/206.5K. ChatDev: ~22.9K but far lower quality. [M2, M3]

**Best for.** Function-level code generation; test-driven development; workflows with clear pass/fail gates.

**Worst for.** Deeply entangled repo-wide bugs; tasks requiring backtracking; tight real-time interaction between multiple implementers.

**Failure modes.** Progressive information loss ("telephone game"); stage-local optimization (a stage "succeeds" locally but harms the next); MAST classifies significant MAS failures as loss of conversation history, incorrect verification, and ignored input. [M1, M2]

### 2.3 Debate / Adversarial

**How it works.** Two+ agents argue opposing positions; a judge selects the winner.

**Measured results.** Evidence for coding is weaker than other topologies:
- "Review Beats Planning" (2025): reasoning model reviewing code model's free output reaches 90.2%, exceeding GPT-4o's 87.2%. But reasoning model planning + code model implementing degrades by 2.4pp. Direction matters: adversarial review > adversarial planning. [M3]
- ColMAD: collaborative MAD improved error detection vs competitive debate; competitive debate suffered from "debate hacking." [M2]
- DebateLoc variants: SWE-bench pass@1 into 40%+ range vs ~12.5% for original SWE-agent, but via more complex trajectories. [M1]

**Token overhead.** High — minimum 2–3x base generation cost plus judge. [All 4]

**Best for.** Architecture decisions with genuine trade-offs; security review; design decisions where multiple approaches have real merit.

**Worst for.** Routine bug fixes; simple diffs; tasks where adding agents decreases success via coordination failures.

**Failure modes.**
- If both debaters share the same flawed context, debate amplifies shared bias [M1]
- Judge contamination from seeing implementer reasoning [M1, M2]
- Competitive debate can degenerate into "debate hacking" / rhetorical overfitting [M2]
- Consensus inertia — agents converge on first plausible answer [M3]
- Simple majority voting often performs as well as elaborate debate protocols [M3]

### 2.4 Hierarchical (Manager → Sub-managers → Workers)

**Measured results.** MetaGPT's SOP-driven hierarchy: 85.9%/87.7% on HumanEval/MBPP. AgileCoder's Agile hierarchy outperforms ChatDev and MetaGPT on project-style benchmarks. MAST found that a simple workflow fix ensuring final authority for the CEO in ChatDev raised success by 9.4%. [M1, M2]

**Token overhead.** Medium-high; MetaGPT: 138.2K/206.5K tokens. Managers incur extra planning/review turns but can prevent workers from pursuing dead ends. [M1, M2]

**Failure modes.** Manager bottleneck; task-spec drift down the hierarchy; "organizational theater" — roles without artifact production; manager drift from poor decomposition. [M1, M2, M4]

### 2.5 Peer-to-Peer / Round-Robin — ⚠️ Anti-Pattern for Coding

**Measured results.** CooperBench: direct communication did not meaningfully improve merge success. CAMEL shows role-playing pairs outperform single-shot baselines on cooperative tasks, but not on rigorous coding benchmarks. [M1, M2]

**Token overhead.** High and disproportionate — up to 20% of total token budget spent on communication that doesn't help. [M3]

**Failure modes.** Agent gossip; jammed channels; silence loops; repetition; uncheckable promises; incorrect partner model; hallucinated state claims. [All 4]

**Consensus verdict:** This is the "bag of agents" anti-pattern. All 4 models agree it should be avoided for coding tasks.

### 2.6 Blackboard / Shared State

**Measured results.** A 2025 Google paper found blackboard-based LLM systems competitive with SOTA while spending fewer tokens than message-passing, outperforming baselines on 5/6 tasks. However, testing was limited to data science workflows, not coding benchmarks. LangGraph's stateful graphs are widely adopted for enterprise multi-agent workflows. MemGPT/Letta supports two-tier memory enabling cross-agent shared memory. [M1, M3]

**Failure modes.** Stale reads; race conditions; last-writer-wins; unbounded state accumulation. Cursor found that locking on shared files failed operationally. [M1, M2]

### 2.7 Event-Sourced

**Measured results.** OpenHands achieves 77.6% on SWE-bench Verified (M3) / 53–72% range (M1, depending on model). Context condensation maintains equivalent solve rate while cutting per-turn costs by >50%. The ESAA framework validated event sourcing for file-based agent systems with only 200–500 tokens overhead per event (~15KB for 86 events) — negligible. [M3, M4]

**Failure modes.** Log growth; replay cost; poor event schema if Action/Observation not well-typed; condensers can over-aggressively summarize. [M1, M4]

### 2.8 Nested Conversations (Subagents)

Claude subagents and AutoGen nested chats: subagents start with short, specialized prompts and receive only task-relevant context. Trade-off is per-subagent spin-up cost. Claude docs note subagents cannot spawn other subagents. [M1, M2]

### 2.9 Voting / Ensemble

Limited evidence of benefit for coding. MAST notes MAS performance sometimes barely exceeds single-agent or best-of-N baselines. Voting is statistically futile for code synthesis because independent agents rarely generate identical ASTs. Some SWE-agent ecosystems use multi-attempt strategies (5 attempts) to push pass@1 from ~53% to ~66%. [M1, M3, M4]

### 2.10 Role-Playing / Simulation

ChatDev achieves only 33.33% on ProgramDev despite rich company simulation. Removing roles entirely dropped quality from 0.3953 to 0.2212 — roles help, but only when anchored to SOPs and structured artifact handoffs (MetaGPT). Heavy role-play without artifact production is wasteful. [M1, M2]

---

## 3. Information Boundary Design

### 3.1 Downstream (Orchestrator → Worker)

**Consensus: what should flow.**
All 4 models converge on a minimal, typed context packet:

1. **Task specification** with clear acceptance criteria (not vague "implement the thing")
2. **Relevant code slices/file paths** — not the entire codebase. Use structural representations (AST signatures, dependency graphs) over full dumps
3. **I/O examples and constraints** — "strongly correlate with higher-quality code generation" (Fagădău et al. 2024) [M3]
4. **Explicit anti-patterns** — what NOT to do, known wrong paths
5. **Output schema** — exact format expected for RESULT.json
6. **Escalation path** — what to do if information is missing

**Consensus: what should NOT flow.**
- Full conversation history or prior workers' reasoning traces
- Unfiltered environment dumps ("everything in the repo")
- Free-text digests of what happened before
- "Background context" that isn't actionable

**Measured impact of getting it wrong.**
- Incomplete/ambiguous/contradictory task descriptions cause 20–40% drop in Pass@1 [M3]
- CooperBench: more context did not help cooperation — agents couldn't integrate it correctly [M1]
- Agent scaling theory: mutual information I(A;C) across chains A→B→C is upper-bounded, independent of prompt length [M1]
- Vague delegation creates duplication/gaps; overstuffed context distracts, slows, and costs more [M2]

### 3.2 Upstream (Worker → Orchestrator)

**Consensus: what should flow.**
- **Typed result object** (RESULT.json): status, changed files, tests run, error messages, artifact pointers
- **Pointers to artifacts on disk**: the actual code changes, diffs, test logs
- **Bounded summary** (<200–500 tokens) for orchestrator routing decisions only

**Consensus: what should NOT flow.**
- Long chains-of-thought or intermediate reasoning
- Unverifiable claims ("implemented and done")
- Full tool call histories or exploration dead-ends
- Claude Code enforces this by design: "intermediate tool calls and results stay inside the subagent"

**Measured information loss.**
- Telephone-game studies show strong factual/semantic degradation over 10–30 iterations of summarize chains [M1]
- OpenHands' condenser maintains 54% solve rate vs 53% baseline while cutting costs >50% — proving that careful condensation preserves quality [M3]
- CooperBench: commitment failures arise from unverifiable promises [M1, M2]

### 3.3 Lateral (Worker → Worker)

**Strong consensus: lateral communication should be minimal to zero for write tasks.**

All 4 models agree that free-form lateral communication hurts coding performance. The disagreement is on degree:

- **M3, M4 (strictest):** Lateral communication should be structurally prevented. If Worker B depends on Worker A, use sequential dispatch through orchestrator. Zero lateral messaging permitted.
- **M1, M2 (slightly more permissive):** Allow limited, artifact-based lateral reads. Executors in later phases can read prior RESULT.json and code artifacts on the same task chain when explicitly instructed, but not arbitrary cross-task histories or narrative summaries.

**Synthesis recommendation for APEX:** Default to zero lateral communication. When there is an explicit sequential dependency, the orchestrator provides Worker A's artifacts to Worker B as part of the downstream context packet — this is orchestrator-mediated, not peer-to-peer.

**Production patterns for conflict avoidance:**
- Git worktrees: each worker gets its own filesystem (Claude Code supports up to 10 concurrent tasks; Cursor runs up to 8 parallel agents) [M3]
- File-level ownership: one file, one owner — never let two agents edit the same file simultaneously [All 4]
- Merge via orchestrator, not peer-to-peer, using git as the conflict-resolution substrate [M1]

### 3.4 The Verification Boundary — **THE Critical Boundary**

This is the most evidence-rich and highest-stakes boundary. Three independent research streams converge (M3 framework, validated by all others):

**Stream 1 — Confirmation bias is catastrophic.**
88.2% adversarial success rate when PR metadata provides implementer reasoning. Metadata redaction restores detection in 94% autonomous / 100% interactive cases. No tested mitigation (CoT, reflection, debiasing instructions) works — only removing the anchor. [M3]

**Stream 2 — Overcorrection bias punishes complex verification.**
Asking an LLM to judge + explain + propose fix causes 20–40pp accuracy drop vs simple direct judgment. The LLM assumes flaws exist and suggests unnecessary modifications. [M3, validated by M2's finding that single judge with rubric > multi-judge]

**Stream 3 — Human code review parallels.**
Prior knowledge of code improves review usefulness, but implementer self-justification hurts objectivity. Clean room = "no implementer persuasion," not "no context." [M2]

**Synthesis: What the critic should receive.**
✅ Original task specification with acceptance criteria
✅ Raw git diff / changed files
✅ Deterministic test/compile output (stdout/stderr)
✅ Relevant repo context (interfaces, types the code must conform to)

❌ Executor's SUMMARY.md
❌ Executor's chain-of-thought, reasoning, or self-assessment
❌ Prior failed attempts' rationale
❌ Any "explain your design choices" framing

**Critic prompt design (M3, validated by M2):**
- Radically simple: "Does this diff satisfy the specification? Here are test results."
- Three-valued verdict: PASS / FAIL / NEEDS_REVIEW
- Brief justification only on failure (<200 tokens)
- NO "explain your reasoning in detail" — triggers overcorrection
- NO redesign suggestions or alternative implementations

---

## 4. Message Format Comparison

### Evidence Table (Cross-Validated)

| Format | System | Quality | Token Efficiency |
|--------|--------|---------|-----------------|
| Structured SOPs + artifacts | MetaGPT | 85.9% HumanEval | 126.5 tokens/line |
| Structured feedback loop | AgentCoder | 96.3% HumanEval | 56.9K total |
| Free-text role-play | ChatDev | 33.3% ProgramDev | 248.9 tokens/line |
| Free-form cooperation | CooperBench agents | 30% below solo | 20% wasted on comm |
| Strict JSON schemas | OpenAI Structured | 100% compliance | N/A |
| Without strict schemas | OpenAI baseline | <40% compliance | N/A |
| Codified communication | Dual-agent research | — | 87% token reduction |

### Recommended APEX Message Format: Hybrid Typed Envelope

All 4 models converge on the same recommendation: **JSON envelope + artifact pointers + bounded natural-language notes.**

**RESULT.json schema (synthesized from all 4 models):**

```json
{
  "task_id": "string",
  "spec_version": "string",
  "status": "pass | fail | partial | blocked",
  "changed_files": ["path/to/file.ts"],
  "created_files": ["path/to/new_file.ts"],
  "diff_path": ".apex/diffs/task-001.patch",
  "tests": {
    "passed": 12,
    "failed": 0,
    "skipped": 1,
    "log_path": ".apex/logs/test-001.log"
  },
  "lint": { "status": "pass", "warnings": 2 },
  "assumptions": ["Database schema unchanged", "API v2 contract holds"],
  "dependency_contracts": [
    { "provides": "UserService.getById()", "signature": "..." }
  ],
  "risks": ["No integration test for edge case X"],
  "questions": [],
  "missing_context": [],
  "confidence": "high | medium | low",
  "attempt_fingerprint": "hash-of-approach",
  "summary": "Brief human-readable note, <200 tokens"
}
```

**CRITIC verdict (structured):**

```json
{
  "verdict": "PASS | FAIL | NEEDS_REVIEW",
  "failed_requirements": ["specific spec violations"],
  "severity": "critical | major | minor",
  "justification": "<200 tokens, only on FAIL"
}
```

**Key principles:**
- Orchestrator logic driven by JSON and artifacts only, never by summary prose [All 4]
- SUMMARY.md is human-facing only — never enters agent routing [M1, M2]
- Schema-validated before orchestrator invocation (Tier 0 validation) — if malformed, trigger local retry without spending orchestrator tokens [M4]

---

## 5. State Management Patterns

### 5.1 File-Based State with Git (APEX's Current Approach) — ✅ Validated

Git naturally implements multiple distributed systems patterns simultaneously:
- **Event sourcing**: commits = immutable events; `git log` = replay
- **Actor isolation**: worktrees = per-agent filesystem
- **Saga compensation**: `git revert` / `git reset --hard` = compensating transactions
- **Conflict resolution**: `git merge` with human review

Production coding agents (Copilot Workspace, Jules, Amazon Q, Claude Code, Cursor) all operate on git repos. This is the dominant production pattern. [All 4]

### 5.2 Event-Sourcing Lite for APEX

All 4 models recommend adding lightweight event logging alongside the .apex/ directory. The recommendation (synthesized):

Append small JSON event records to `.apex/events.jsonl`:
```json
{"ts": "2026-03-30T12:00:00Z", "type": "task_dispatched", "role": "executor", "task_id": "T-001", "spec_version": "v3", "input_hash": "abc123", "files_scope": ["src/auth.ts"]}
{"ts": "2026-03-30T12:01:30Z", "type": "task_completed", "task_id": "T-001", "status": "pass", "files_touched": ["src/auth.ts", "tests/auth.test.ts"]}
```

Overhead: 200–500 tokens per event, ~15KB for 86 events — negligible vs LLM inference costs. [M3, M4]

Benefits: audit trail, debugging, postmortem analysis, replay for understanding failure chains.

### 5.3 Orchestrator State: Near-Stateless by Discipline

**Unanimous recommendation.** On each `/apex:next`:
1. Read `.apex/state.json` (small pointer file: current phase, active tasks, spec version)
2. Read relevant RESULT.json / CRITIC.json files
3. Read current git state
4. Construct context from these files + user's latest input
5. Discard prior orchestrator reasoning

This mirrors LangGraph (re-derive from checkpoints), OpenHands (ConversationState derived from event log), and Claude subagents (fresh context per invocation). [All 4]

### 5.4 Conflict Resolution

**Consensus:** Prevent conflicts structurally rather than resolving them after the fact.

- Single-writer principle: one file, one owner at any given time [All 4]
- Git worktree isolation for parallel workers [M3, M4]
- Sequential merge with rebasing when genuine merge conflicts arise [M3]
- Token Coherence paper (2025) validates: lazy invalidation reduces synchronization cost from O(n × S × |D|) to O((n + W) × |D|) [M3]

### 5.5 Recovery and Rollback: The Saga Pattern

**M4 provides the clearest formulation, validated by M1 and M3:**

Every forward action is paired with a compensating transaction:
- Executor writes code → compensating: `git reset --hard` to pre-task snapshot
- If Critic issues FAIL → orchestrator triggers compensating transaction → repository returns to clean state → REFLEXION.md generated → retry on pristine codebase

This prevents residual syntax errors from accumulating across retry attempts and eliminates the "last writer wins" problem in reflexion loops. APEX already takes pre-task git snapshots — the recommendation is to formalize this as an explicit Saga with deterministic rollback before retry. [M4, supported by M1, M3]

---

## 6. Scaling Analysis

### 6.1 The Coordination Plateau (Cross-Validated)

| Source | Finding |
|--------|---------|
| DeepMind 180-config study | Beyond 4 agents: coordination latency grows superlinearly (power-law ~1.724) |
| DeepMind | Sequential reasoning: ALL multi-agent variants degraded 39–70% |
| DeepMind | Threshold: when single-agent > ~45%, multi-agent overhead exceeds benefits |
| DeepMind | Centralized: 4.4x error amplification. Decentralized: 17.2x |
| CooperBench | 2 cooperating agents: ~30% worse than solo |
| Claude teams docs | Start with 3–5 teammates |
| Anthropic | 1 agent for simple tasks, 2–4 for comparisons, 10+ only for wide research with clear separation |

### 6.2 Token Economics

| System | Agents | Total Tokens | Efficiency |
|--------|--------|-------------|------------|
| AgentCoder | 3 | 56.9K (HumanEval) | Best measured |
| MetaGPT | 5 | 138.2K (HumanEval) | 126.5 tok/LOC |
| ChatDev | 7 | ~183.7K | 248.9 tok/LOC |
| CAMEL | 2 | ~2K | 86% duplication |
| Multi-agent vs chat | varies | ~15x more tokens | Per Anthropic |
| Factory.ai model mixing | varies | 1.2M vs 3.4M | Cheap models for impl, expensive for spec |

In MetaGPT's development experiments, 72% of all tokens go to verification and coordination, not productive code generation. [M3]

### 6.3 When NOT to Use Multi-Agent

**Unanimous across all 4 models:**
- Write-heavy tasks on shared files
- Sequential dependencies where agents must wait for each other
- Tasks a single agent can complete in <5 minutes wall-clock [M3]
- Routine/small bug fixes [All 4]
- When single-agent baseline already exceeds ~45% accuracy [M3, M4]

**Multi-agent pays off when:**
- Tasks are genuinely parallelizable across independent subtasks
- Required context exceeds single-agent effective window
- Tasks require >15 minutes of single-agent work [M3]
- Read-heavy parallel tasks (codebase analysis, research, test generation) [M3]

### 6.4 Minimum Viable Multi-Agent

**Consensus:** 2–3 roles capture most of the benefit.

The evidence-supported minimum: **implementer + clean verifier**, optionally with a planner/architect.

Evidence: AgentCoder (3 agents, 96.3%), Copilot Workspace (plan → implement → validate), Jules Planning Critic (reduced failures by 9.5%), Cursor (planners/workers/judge). Larger "companies" (ChatDev-style) do not translate to better correctness. [M1, M2, M3]

---

## 7. Production System Analysis

### 7.1 Systems That Work (Organized by Pattern)

**Coordinator + Artifact-Centric (Dominant Production Pattern):**
- **Anthropic Research System:** Lead researcher + subagents with task boundaries. 90.2% improvement over single Opus 4. [M2]
- **Cursor:** Evolved from flat coordination to planners/workers/judge. Dynamic context discovery (agents pull context as needed rather than receiving dumps). [M2]
- **MetaGPT:** Manager + SOPs + structured artifacts. 85.9%/87.7% HumanEval/MBPP. [M1, M2]
- **OpenHands:** Event-sourced, typed events, condenser system. Up to 77.6% on SWE-bench Verified. [M1, M3]
- **Copilot Workspace:** spec → plan → implement → validate. Structured plan + diffs, not free-form chat. [M1, M2, M3]
- **Jules:** plan → diff → PR. Planning Critic reduced failures by 9.5%. [M2]
- **Amazon Q Developer:** plan spanning multiple files, code/tests/review, @workspace context. [M2]
- **Factory.ai:** Droids for coding/testing/deployment; #1 on Terminal-Bench at 58.75%. Model mixing (cheap for impl, expensive for spec) cut tokens from 3.4M to 1.2M. [M1, M3]

**Pipeline With Iterative Feedback (Highest Benchmark Performance):**
- **AgentCoder:** programmer → test designer (independent, doesn't see code) → test executor → feedback loop. 96.3% HumanEval. Closest analog to APEX's executor → critic → reflexion. [All 4]
- **MapCoder:** recall → plan → generate → debug. 93.9% HumanEval. [M1]
- **AgileCoder:** Agile sprints + Dynamic Code Graph. 57.79% executability on ProjectDev. [M1, M4]

**Single-Agent-With-Tools (Important Baselines):**
- **Aider:** AST-based repo map provides structural awareness without full file tokens. Demonstrates many "multi-agent" tasks can be solved by better context engineering within a single agent. [M3]
- **SWE-Agent:** Single LM + strong Agent-Computer Interface. 12.5% SWE-bench, 87.7% HumanEvalFix. [M1]

### 7.2 The Plan-First Universal Pattern

Every successful production coding agent generates an explicit plan before implementation: Copilot Workspace, Jules, Cursor Plan Mode, Amazon Q /dev, Devin, Replit Plan Mode. The plan serves as both a coordination artifact and an information boundary. [M3]

### 7.3 Context Management Gold Standard: OpenHands Condenser

Rolling Condenser: keep head (first 4 events — system prompts), keep tail (recent context), summarize middle. Transforms quadratic cost scaling to linear while preserving 98%+ capability. Key insight: initial instructions and recent events carry disproportionate value; middle events can be lossy-compressed. [M3]

---

## 8. APEX-Specific Recommendations

### 8.1 Overall Architecture Verdict

**KEEP. The topology is correct.** APEX's flow (orchestrator → executor with typed context → RESULT.json → clean-room critic → CRITIC.md → reflexion loop) closely mirrors AgentCoder — the highest-performing measured pattern. All 4 models validate the architecture at the topology level. [Unanimous]

What needs changing is not the shape but the **tightness of contracts and boundaries.**

### 8.2 Orchestrator: Near-Stateless by Discipline

**Recommendation:** On each `/apex:next`, re-read `.apex/state.json`, relevant RESULT/CRITIC files, and current git state. Discard prior orchestrator reasoning.

**Store in `.apex/`:**
- `state.json` — current phase, active tasks, spec version, pointer to latest results
- `events.jsonl` — lightweight append-only event log
- Task artifacts (RESULT.json, CRITIC.json, REFLEXION.json per task)

**Evidence:** MAST 41.8% of failures at orchestrator level; MetaGPT 72% tokens on coordination; LangGraph/OpenHands/Claude all externalize state. [All 4]

### 8.3 RESULT.json: Strengthen as Contract

**Recommendation:** Enforce strict schema validation (Tier 0). Add fields per synthesized schema in Section 4. If JSON malformed, trigger automatic local retry without orchestrator involvement.

**Key additions vs current APEX:** `spec_version`, `dependency_contracts`, `assumptions`, `missing_context`, `attempt_fingerprint`, `confidence`. [Synthesized from all 4]

### 8.4 Clean-Room Critic: Simplify Radically

**Recommendation:** Keep the current protocol (critic never sees SUMMARY.md) and go further:

The critic receives ONLY:
1. Task specification + acceptance criteria
2. Raw git diff
3. Test/compile output

The critic prompt: "Does this diff satisfy the specification? Here are the test results."

Output: Three-valued verdict (PASS / FAIL / NEEDS_REVIEW) + brief justification on failure (<200 tokens). No redesign suggestions, no "explain your reasoning."

**Evidence:** 88.2% contamination rate; 20–40pp overcorrection from complex prompts; single judge with rubric > multi-judge. [M2, M3]

### 8.5 Lateral Communication: Default to Zero

**Recommendation:** No direct worker-to-worker communication. When Worker B depends on Worker A's output, the orchestrator mediates — providing A's artifacts as part of B's downstream context packet.

**Evidence:** CooperBench 30% degradation; communication channels don't improve merge success; 17.2x error amplification in unstructured networks. [All 4]

**Exception:** Read-only dependency artifacts (e.g., RESULT.json `dependency_contracts` field) can be included by orchestrator when dispatching dependent tasks.

### 8.6 Missing Context: Fail-Fast Re-Dispatch

**Recommendation:** If executor discovers it needs information not in the context packet, it returns immediately:
```json
{ "status": "blocked", "missing_context": ["DatabaseSchema", "AuthService interface"], "questions": ["What ORM is used?"] }
```
The orchestrator gathers the missing context and re-dispatches. This is cheaper than having the executor search independently (which pollutes its context). [M3, M4]

### 8.7 Reflexion Loop: Distill, Don't Replay

**Recommendation:** On FAIL:
1. Orchestrator executes deterministic `git reset --hard` to pre-task snapshot (Saga pattern) [M4]
2. Generates `REFLEXION.json`:
```json
{
  "failure_class": "test_failure | compile_error | spec_mismatch",
  "failing_evidence": "test output / error messages",
  "approach_to_avoid": "Description of what didn't work",
  "suspect_assumptions": ["X was assumed but proved false"],
  "candidate_strategies": ["Try approach Y instead"],
  "do_not_repeat": ["approach fingerprint"]
}
```
3. Next executor gets: spec, clean codebase, REFLEXION.json, failing test output
4. Does NOT get: previous attempt's full code, reasoning, SUMMARY.md

**Evidence:** Anchoring on failed approach prevents fresh thinking; reflexive architectures have 14.2% coordination failure rate from oscillation; chain-of-verification works best when failures become targeted constraints. [M3, M1]

**Bound iteration:** Maximum 3–5 retry attempts (AgentCoder uses 5). Vary approach each iteration. [M3]

### 8.8 Architecture Debate: Blind-First, Evidence-Second

**Recommendation (synthesized from M2 and M3):**

1. **Blind Proposal:** Advocate A and Advocate B each receive identical spec + evidence packet separately. They do not see each other's reasoning.
2. **Structured Output:** Each returns `architecture.json` with: choices, trade-offs, risk tags, failure modes, evidence pointers. Not free-text essays.
3. **Constrained Rebuttal (optional):** Each sees the other's claims and artifacts only (not reasoning). Responds to claims with evidence.
4. **Simultaneous Judge:** Judge receives both proposals simultaneously (not sequentially — prevents primacy/recency bias) + spec + rubric. Randomize ordering.
5. **Structured Verdict:** Judge outputs selection with explicit trade-off acknowledgment against objective rubric.

Limit to 1–2 rounds. Store all artifacts for human inspection. [M1, M2, M3]

**Evidence:** Competitive debate can degenerate (ColMAD); judge bias exists; evidence-rubric > rhetoric; simultaneous presentation prevents ordering bias. [M2, M3]

### 8.9 Spec Drift: First-Class Versioned Events

**Recommendation:** Every spec has a `SPEC_VERSION` hash. Mid-build spec changes:
1. Orchestrator creates `SPEC_DELTA.json` (what changed, why)
2. Marks which task results are invalidated by the change
3. Future executors and critics receive both latest spec AND spec diff
4. Invalidated tasks are re-dispatched or re-validated

This applies Copilot Workspace's "regenerate-downstream" pattern and event-sourcing's immutable change tracking. [M1, M2]

---

## 9. Anti-Pattern Catalog

### 🔴 Critical Severity

| # | Anti-Pattern | Evidence | Mitigation |
|---|-------------|----------|------------|
| 1 | **Bag of agents / unstructured peer communication** | 17.2x error amplification (DeepMind); 30% success drop (CooperBench) | Strict hub-and-spoke; zero lateral messaging |
| 2 | **Verifier contamination** | 88.2% adversarial success when reviewer sees implementer reasoning; no mitigation works except removal | Clean-room: spec + diff + tests only; no SUMMARY.md |
| 3 | **Complex verification prompts** | 20–40pp accuracy drop from overcorrection bias | Simple direct judgment; PASS/FAIL/NEEDS_REVIEW; <200 token justification |
| 4 | **Vague delegation** | Duplication/gaps (Anthropic); expectation failures (CooperBench) | Typed task packets with scope, boundaries, schema, success criteria |
| 5 | **Summary-only upstream** | Commitment failures; telephone-game drift; MAST FM-2.4 (8.2% of failures) | RESULT.json + artifact pointers; ban free-text from routing |

### 🟠 High Severity

| # | Anti-Pattern | Evidence | Mitigation |
|---|-------------|----------|------------|
| 6 | **Unbounded context accumulation** | Token explosions; performance collapse; 72% tokens to coordination in MetaGPT | Stateless orchestrator; observation masking; condenser patterns |
| 7 | **Same-file concurrent editing** | Race conditions scale quadratically with agent count; Cursor locking failed | One file, one owner; git worktree isolation |
| 8 | **Telephone-game summarization** | 99% per-step → 90.4% over 10 steps; 95% per-step → 35.8% over 20 | Minimize chain depth; structured artifacts; hub-spoke over long chains |
| 9 | **Role-play without artifacts** | ChatDev 33.33% despite rich simulation; quality drops without SOP anchoring | Roles must produce typed artifacts, not conversation |
| 10 | **Infinite refinement loops** | 14.2% coordination failure from oscillation | Bound at 3–5 iterations; vary approach; concrete termination criteria |

### 🟡 Medium Severity

| # | Anti-Pattern | Evidence | Mitigation |
|---|-------------|----------|------------|
| 11 | **Role drift** | MAST FM-1.2: planners start coding, reviewers start implementing | Constrained output schemas; role-specific tool access |
| 12 | **Duplicate work** | 53–86% duplicate token rates (AgentTaxo); Anthropic: agents doing "exact same searches" | Extremely specific, non-overlapping task descriptions; specify what NOT to do |
| 13 | **Competitive debate as default** | Debate hacking; rhetorical overfitting (ColMAD) | Collaborative critique with evidence rubric; blind proposals |
| 14 | **Free-text dependency handoffs** | Uncheckable commitments (CooperBench) | Contract files, interface schemas, or tests — not chat messages |
| 15 | **Too many agents too early** | Superlinear coordination overhead beyond 4 | Start with 2–3; add only for genuinely parallel independent work |

---

## 10. Three Architectural Principles (Meta-Synthesis)

Across all research and all 4 models, three principles transcend specific implementation choices:

**Principle 1: Information boundaries ARE the architecture.**
The topology matters less than what crosses each boundary. APEX's hub-spoke with typed results and clean-room verification is validated. The specific evidence — 88.2% contamination, 20–40pp overcorrection, 30% cooperation degradation — all converge: agents should exchange structured artifacts through constrained interfaces, not share reasoning or context. [M3, supported by all]

**Principle 2: Isolation is almost always better than communication.**
Fresh context per worker, structural file isolation, clean-room verification, near-stateless orchestration — all derive from the same insight: the cost of contamination, anchoring, and progressive information loss exceeds the cost of redundant context gathering. [All 4]

**Principle 3: The read/write distinction determines when multi-agent wins.**
Multi-agent excels for read-heavy parallel tasks (analysis, research, test generation) and degrades for write-heavy coordinated tasks (multi-file refactoring with dependencies). APEX should parallelize reads aggressively, serialize writes through single agents. Sweet spot: 2–4 specialized workers on parallelizable subtasks with centralized orchestration. [M3, M4]

---

## 11. Cross-Model Validation Notes

### Where all 4 models agree (highest confidence):
- Hub-and-spoke is optimal for coding
- Clean-room verification is mandatory
- Structured JSON > free text
- Orchestrator should be near-stateless
- 2–4 agent sweet spot
- File/git-based state is correct
- APEX's current architecture is fundamentally sound
- Peer-to-peer is an anti-pattern for coding

### Where models provided unique contributions:
- **M1:** Deepest coverage of academic systems (MapCoder, RepoAgent, AgileCoder); spec drift as event; event-sourcing-lite concept
- **M2:** Anthropic engineering blog data; Cursor's architectural evolution; Jules Planning Critic -9.5%; ColMAD debate research; blind-first debate protocol; Hebrew context
- **M3:** DeepMind 180-config study; overcorrection bias 20–40pp; 88.2% contamination details; ESAA framework; Token Coherence paper; Aider AST approach; break-even heuristics (5 min/15 min)
- **M4:** Saga pattern formalization; A2A protocol; DiffMem/Lore; MAST failure percentages (FM-2.4 = 8.2%, FM-3.2+3.3 = 21.3%); Tier 0 validation; power-law exponent 1.724; AgileCoder ProjectDev benchmark

### Where models diverged:
- **Lateral communication strictness:** M3/M4 say zero; M1/M2 allow limited artifact reads. Synthesis: zero by default, orchestrator-mediated artifact sharing for explicit dependencies.
- **AgentCoder numbers:** M1 cites 79.9%/89.9% (appears to be an ablation or different model); M2/M3/M4 cite 96.3%/91.8% (full system, GPT-4). The higher numbers are the correct full-system results.
- **Debate protocol:** M2 recommends collaborative + blind; M3 says adversarial review > adversarial planning; M4 says strict adversarial + judge, no synthesis. Synthesis: blind proposals, structured claims, evidence-based rubric, no rhetoric.

### Claims that could not be fully cross-validated:
- M4's specific MAST FM percentage breakdowns (8.2%, 11.8%, 21.3%) — cited but not independently confirmed by other models at the same granularity
- M3's "Review Beats Planning" 90.2% claim — single source
- M4's characterization of voting as "statistically futile" for code — logical but lacks specific benchmark proof
- M3's 5-minute / 15-minute break-even heuristic — practical intuition, not formally measured

---

## 12. Sources (Consolidated, Deduplicated)

### Academic Papers
- **MAST** — "Why Do Multi-Agent LLM Systems Fail?" (UC Berkeley) — failure taxonomy, 1,642 traces, 14 failure modes
- **CooperBench** — "Why Coding Agents Cannot be Your Teammates Yet" (Stanford/SAP, 2026) — 652 task pairs
- **DeepMind Scaling Study** — "Towards a Science of Scaling Agent Systems" (2025) — 180 configurations
- **AgentCoder** — programmer/test designer/executor pipeline — arXiv 2312.13010
- **MetaGPT** — SOP-constrained multi-agent software engineering — arXiv 2308.00352
- **MapCoder** — multi-agent with retrieval — arXiv 2405.11403
- **AgileCoder** — Agile methodology-based agents — FORGE 2025
- **ChatDev** — role-playing software company simulation — ACL 2024
- **OpenHands/OpenDevin** — event-sourced agent SDK — arXiv 2511.03690
- **SWE-Agent** — agent-computer interface — arXiv 2405.15793
- **RepoAgent** — repository-level documentation — arXiv 2402.16667
- **CAMEL** — role-playing agent communication
- **AgentVerse** — dynamic agent team formation — ICLR 2024
- **ColMAD** — collaborative vs competitive multi-agent debate
- **Token Coherence** — MESI cache protocols for multi-agent — arXiv 2603.15183
- **ESAA** — Event Sourcing for Agent Architecture
- **Lore / DiffMem** — Git as differential memory for agents — arXiv 2603.15566
- **Cross-context verification** — information restriction in LLM verification
- **Overcorrection bias** — ASE 2025 (complex verification prompts degrade accuracy)
- **Security code review bias** — 88.2% contamination rate study (March 2026)
- **LLM-as-judge surveys** — systematic biases and structural protocols

### Production Systems & Documentation
- Anthropic engineering blog: multi-agent research system
- Claude Code subagents & Agent Teams documentation
- Cursor engineering blog: dynamic context discovery, scaling agents
- GitHub Copilot Workspace
- Jules (Google) — plan/diff/PR flow + Planning Critic
- Amazon Q Developer
- Replit Agent
- Devin (Cognition) — limited protocol detail publicly available
- Factory.ai
- LangGraph documentation (state management, checkpoints, memory)
- AutoGen/AG2 conversation patterns
- CrewAI hierarchical process
- OpenHands SDK documentation

### Protocols & Standards
- MCP (Model Context Protocol) — agent-to-tool connections
- A2A (Agent-to-Agent Protocol) — peer discovery and task delegation
