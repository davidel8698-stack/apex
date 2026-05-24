# APEX Deep-Research Synthesis — 2026-05-24

**Inputs:** 5 parallel deep-research reports, ~94 unique URLs across 4 hop-depths
- `01-anthropic-tool-use-memory.md` — Anthropic Cookbook + canonical compaction/memory primitives (17 URLs)
- `02-anthropic-context-engineering.md` — Anthropic Eng blog + Chroma + Claude Code reference architecture (16 URLs)
- `03-karpathy-skills.md` — Karpathy 4-rule CLAUDE.md + Forrest Chang's extended 12-rule template (21 URLs, 3 hops)
- `04-manus-context-engineering.md` — Manus 6 lessons + the post-publication "5th rewrite" revisions (22 URLs + 4 searches)
- `05-microsoft-agentic-security.md` — MDASH + CyberGym + Team Atlanta lineage (18 URLs)

**Mission:** consolidate every finding relevant to improving APEX, ranked by evidence weight and APEX impact, with the smallest viable change per item.

---

## 0. Top-line: where the five sources converge

Eleven things every source agreed on, in one form or another. These are the **highest-confidence claims** anywhere in the research — if APEX violates any of them, fix it first.

| # | Consensus claim | Sources |
|---|---|---|
| 1 | **The harness is most of the engineering; the model is a swappable input.** | Microsoft (Kim verbatim), Manus ("model is commodity, harness is moat" — Gupta), Anthropic (context engineering > prompt engineering), Karpathy (behavioral rules outlive models) |
| 2 | **Context engineering is now a named discipline** distinct from prompt engineering. | Anthropic (coined the term), Manus (adopted), LangChain (adopted), Karpathy (implicit), Microsoft (implicit) |
| 3 | **Long context degrades non-uniformly — "context rot" is empirical.** Effective window << stated window. | Anthropic (named it), Chroma 18-model study (measured it), Manus L3 ("128K is a liability"), Lance Martin ("effective window much lower than stated") |
| 4 | **File system is the right substrate for agent memory** — restorable, persistent, agent-operable. | Anthropic (Pokémon agent, Claude Code), Manus L3 ("ultimate context"), Anthropic memory tool, LangChain Write |
| 5 | **Compression must be restorable** — drop the expanded form, keep the identifier (path/URL/query). | Anthropic (just-in-time), Manus L3 (URLs not page content), LangChain (Compress lever) |
| 6 | **Multi-agent costs ~15× tokens vs. chat AND is a bad fit for most coding tasks.** | Anthropic (explicit, twice), Cognition ("Don't Build Multi-Agents"), Manus (only for decoupled work like Wide Research), Microsoft (uses it but for security stages, not coding) |
| 7 | **Sub-agents work for narrow well-defined sub-tasks with structured returns; fail for coupled creative work.** | Anthropic 90.2% lift on research eval, Manus Wide Research 100 sub-agents (only for parallel items), Cognition Flappy Bird failure, Microsoft auditor/debater/prover all decoupled |
| 8 | **Verification is the single highest-leverage practice.** | Anthropic ("the single highest-leverage thing you can do"), Karpathy ("Goal-Driven Execution"), Microsoft (oracles + provers), Manus L5 (failure preservation = adaptation) |
| 9 | **Anti-overengineering / "biggest gains came from removing things."** | Karpathy (4 rules dedicated to it), Anthropic (verbatim anti-overengineering prompt block), Manus (5 rewrites, every one simpler), Schmid ("Bitter Lesson"), Vercel (80% tool cut) |
| 10 | **Errors must be preserved in context, not cleaned up.** Erasing failure removes the evidence the model needs to adapt. | Manus L5 verbatim, Anthropic (durable execution, "letting agent know when a tool is failing… works surprisingly well"), Team Atlanta (oracles + ASAN traces retained) |
| 11 | **Stable prefix + diverse user content** is the cache-hygiene rule. Single-token differences invalidate KV-cache. | Manus L1 (10× cost ratio), Anthropic (cache_control breakpoint at end of system prompt), Microsoft (configurable model-agnostic harness implies stable prefix) |

The **one major debate** the sources do NOT resolve: **how much sub-agent ceremony is right for coding.** Anthropic and Cognition lean against; Manus uses it tactically; Microsoft uses it heavily but for security pipelines (not coding). APEX is in the *coding* category, so this is a load-bearing question.

---

## 1. Validation — what the research CONFIRMS APEX is already doing right

Before recommending changes, the synthesis confirms a substantial fraction of APEX's existing design is externally validated. Don't break these.

| APEX design choice | Validated by |
|---|---|
| **The harness-is-the-engineering thesis** | Microsoft Kim verbatim; Manus; entire Schmid/Martin/Gupta line |
| **File-based agent state** (`.apex/STATE.json`, `DECISIONS.md`, `TASK_MAP.md`, `PLAN.md`, `RESULT.json`) | Anthropic just-in-time + memory tool; Manus L3; LangChain Write |
| **Multi-agent with clean-room critic** | Anthropic orchestrator-worker; Microsoft auditor → debater (separate cognition, separate prompts) |
| **DECISIONS.md as cross-agent ground truth** | Cognition Principle 1 ("share full agent traces"); Anthropic memory-tool pattern |
| **Phase-based execution with verify gates** | Anthropic Explore→Plan→Implement→Commit; Microsoft 5-stage pipeline; Karpathy goal-driven |
| **`/apex:fast` / `/apex:quick` / `/apex:full` tiering** | Anthropic explicit ("multi-agent uses 15× tokens — value-of-task gate"); Karpathy "bias toward caution… for trivial tasks, use judgment" |
| **Resume-from-checkpoint, not restart** | Anthropic ("resume from where errors occurred, not restart"); Manus L5 (preserve failure context) |
| **Self-heal rounds = Stochastic Graduate Descent applied to APEX itself** | Manus 5 rewrites in 6 months; Schmid "Bitter Lesson" applied to harness |
| **Anti-rationalization armor on executor** | Manus L5 ("keep the wrong stuff in"); Anthropic durable execution |
| **destructive-guard + plan-mode + ecosystem-10Q gate** | **APEX is STRONGER than any disclosed competitor on AI-system safety** — MDASH, Big Sleep, Anthropic, Team Atlanta publish ZERO guardrails for the agent's own reasoning loop |
| **Specialist agent catalog (architect / executor / critic / verifier / framework-auditor / wave-executor / round-checker / remediation-planner / batch-scheduler)** | Microsoft auditor/debater/prover; Team Atlanta N-version programming |
| **Per-stack skill generation (`apex-skills/`)** | Microsoft "domain plugins" pattern; Anthropic agent-skills convention |

**One blanket message from the research:** APEX's overall pipeline architecture is correct and externally validated. The improvements below are *deltas inside* this architecture, not replacements of it.

---

## 2. P0 — Highest-priority changes (validated by 3+ sources, high impact, low risk)

These are the changes I'd ship first. Each one is named in multiple research sources, addresses a documented APEX gap, and has small implementation surface.

### P0-1 — Anti-bloat / anti-overengineering armor

**Gap:** APEX has anti-rationalization armor (executor won't silently change scope) but no anti-bloat armor (executor will happily add abstractions, type-hints, error handlers, "improvements" not asked for). Karpathy's 4-rule CLAUDE.md is essentially *60 lines that close this gap*. Anthropic publishes a verbatim 180-word prompt block addressing the exact same problem.

**Evidence:**
- Karpathy Rules 2 + 3 ("Simplicity First", "Surgical Changes") and Section 1 ("Think Before Coding")
- Anthropic verbatim "Avoid over-engineering" block in claude-4 best practices
- Manus L3 ("biggest gains came from removing things") + 5 rewrites of strictly-decreasing complexity
- Forrest Chang's claimed (un-verified but trend-plausible) 41% → 11% error reduction from these 4 rules alone

**Smallest viable change:**
1. Add to `executor.md`, `wave-executor.md`, `remediation-planner.md` the verbatim Anthropic block (Anthropic Cookbook §2.9 — quoted in Report 01 lines 557–567):
   > "Avoid over-engineering. Only make changes that are directly requested or clearly necessary…"
2. Add the four Karpathy "No X" bans (no abstractions for single-use code; no flexibility that wasn't requested; no error handling for impossible scenarios; if 200 lines could be 50, rewrite).
3. Add to `critic.md`: a new verdict bucket `approved-with-noise` for solutions that pass correctness but add abstractions/parameters/error handlers not justified by PLAN.md acceptance criteria.

**Risk:** Negligible. This is literally adopting battle-tested verbatim prompts from the model vendor and the dominant community CLAUDE.md.

### P0-2 — Tradeoff-disclosure preamble + rigor-tier philosophy in `apex-spec.md`

**Gap:** APEX is currently all-or-nothing rigor. Karpathy's tagline is the single line that resolves the user's documented complaint about APEX feeling too heavy for trivial tasks: *"These guidelines bias toward caution over speed. For trivial tasks, use judgment."*

**Evidence:**
- Karpathy CLAUDE.md opening line (verbatim above)
- User memory: `feedback_plan_design.md` ("no over-engineering"), `feedback_rigor_standard.md` ("for substantial work, wants maximally rigorous… for trivial, doesn't")
- Anthropic explicit: "For tasks where the scope is clear and the fix is small… ask Claude to do it directly" (skip plan mode)
- Anthropic multi-agent post: "multi-agent systems require tasks where the value of the task is high enough to pay for the increased performance"

**Smallest viable change:** Top of `apex-spec.md`:
```
APEX biases toward rigor over speed for substantial work where silent wrong
assumptions compound. The framework's value scales with task complexity:
  /apex:fast    — trivial (typo, single-line fix, comment): zero ceremony
  /apex:quick   — small (one file, one logical change)
  /apex:build   — standard (multi-file feature; full plan, critic, verify)
  /apex:full    — substantial (multi-phase; ecosystem-10Q, debate, roundtable)
Pick the lowest tier that fits. Multi-agent ceremony costs ~15× tokens of a
direct call — invoke it deliberately, not by default.
```
Then in every agent prompt declare: *"This agent is part of APEX's rigor stack. If the calling command is /apex:fast or /apex:quick, skip optional checks (assumptions block, anti-bloat self-check, style-conservation note) but keep mandatory checks (correctness, safety, task-boundary respect)."*

**Risk:** Low. Documents existing behavior; gives the framework permission to be light when appropriate.

### P0-3 — Assumption-block as the floor (companion to ecosystem-10Q ceiling)

**Gap:** The user's ecosystem-10Q gate (in memory) is the **ceiling** — heavy, plan-bound, exhaustive. Karpathy's "state 1-3 assumptions before implementing" is the **floor** — light, per-turn, prevents silent-assumption failures that ecosystem-10Q only catches at plan-time.

**Evidence:**
- Karpathy Section 1 ("Think Before Coding"): *"State your assumptions explicitly. If uncertain, ask. If multiple interpretations exist, present them — don't pick silently."*
- Anthropic hallucination-suppression prompt: *"Never speculate about code you have not opened. Make sure to investigate and read relevant files BEFORE answering."*
- Manus L4 (recitation) — externalizing the plan is what keeps it in the recent attention span
- Karpathy original tweet (verbatim, Jan 26 2026): *"The models make wrong assumptions on your behalf and just run along with them without checking. They don't seek clarifications, don't surface inconsistencies, don't present tradeoffs, don't push back when they should."*

**Smallest viable change:** Add to `executor` agent prompt:
```
Before any code change, output an "Assumptions" block listing 1-3 assumptions
you are making about (a) what the user wants, (b) what already exists in the
codebase, (c) what counts as done. If any assumption has ≥2 plausible
alternatives, stop and ask. If zero assumptions are uncertain, write
"Assumptions: none uncertain" and proceed.
```
Skip the block for `/apex:fast`. Make it mandatory for `/apex:build` and `/apex:full`.

**Risk:** Adds a few tokens per task. Bounded by the cap (≤3 bullets).

### P0-4 — Diff-bloat alarm in critic ("every changed line should trace to user's request")

**Gap:** APEX's critic checks correctness, safety, and task-boundary respect. It does NOT check whether each changed line maps to a PLAN.md acceptance criterion. This is Karpathy's "Surgical Changes" final test — operationally checkable.

**Evidence:**
- Karpathy Section 3 closing test (verbatim): *"Every changed line should trace directly to the user's request."*
- Karpathy original tweet: *"They still sometimes change/remove comments and code they don't sufficiently understand as side effects, even if orthogonal to the task."*
- Anthropic Building Effective Agents: "Keep it concise" applied to diffs as well as prompts
- Manus L1 (append-only context) — same principle applied to code state

**Smallest viable change:** Add to `critic.md`:
```
Diff-bloat check: for each non-test file touched, every changed line should
map to a specific PLAN.md acceptance criterion. If a changed line cannot be
mapped (e.g., reformatted import, added type hint, restructured comment),
mark it. If >10% of changed lines are unmappable, return verdict =
"approved-with-noise" and list the noise items in CRITIC.md under
"Diff-bloat notes". Does not block merge; informs auditor.
```

**Risk:** Critic gets noisier. Mitigated by the 10% threshold and non-blocking verdict.

### P0-5 — Adopt Anthropic's canonical 5-section state-handoff template

**Gap:** APEX's `STATE.json` + `RESUME-PROMPT.md` carry the right information but not in the canonical Claude-readable format. Anthropic's server-side compaction default prompt and SDK client-side compaction prompt agree on a 5-section template. Adopting it makes APEX state forward-compatible with Anthropic-native compaction tooling.

**Evidence:**
- Anthropic Cookbook (Report 01 §2.3) — the 5-section template verbatim:
  1. Task Overview
  2. Current State
  3. Important Discoveries
  4. Next Steps
  5. Context to Preserve
- The same template appears in both the server-side `compact_20260112` default and the client-side SDK compaction default
- Manus L3 (file system as ultimate context) — agent-readable summaries are the substrate
- Anthropic harnesses post (`claude-progress.txt`) — the same 5-section spirit

**Smallest viable change:** Either
(a) restructure `STATE.json` with five fixed sections matching the template, or
(b) keep `STATE.json` structural + add a sibling `STATE_NARRATIVE.md` that mirrors the template.

Option (b) is less invasive; option (a) is cleaner long-term. Update `turn-checkpoint.sh` and `session-auto-resume.sh` to write/read the new shape.

**Risk:** Medium. Schema migration. Mitigation: additive, with `RESUME-PROMPT.md` continuing to read both shapes during transition.

### P0-6 — KV-cache hygiene audit + invariant

**Gap:** Manus's #1 lesson is that the KV-cache hit rate is the *single most important* production metric — 10× cost ratio on Claude Sonnet ($0.30 vs $3.00 per MTok). A second-precision timestamp in a system prompt is a smoking gun. APEX has hooks (`turn-checkpoint.sh`, `context-monitor.sh`, `memory-watchdog.sh`) that emit content into context — they need to be audited for prefix stability.

**Evidence:**
- Manus L1 verbatim — the post leads with this
- Anthropic compaction docs — cache_control breakpoint pattern at end of system prompt
- Anthropic context-editing docs — `clear_at_least` parameter exists *specifically* to prevent cache busting
- Microsoft MDASH — "configuration flip" model swaps imply stable prefixes elsewhere
- The 10× cost ratio is Anthropic-published pricing; not vendor marketing

**Smallest viable change:**
1. Audit every hook output for **timestamps with sub-minute precision**. Replace with `YYYY-MM-DD` granularity or remove from system-prompt-adjacent output.
2. Audit `STATE.json` / `CONTEXT_BUDGET.json` / `PLAN_META.json` writers — enforce **sorted JSON keys** (deterministic serialization). Add a pre-write canonicalizer.
3. Document the **prefix-stability invariant** in `apex-spec.md`: "Any content that lands inside a model's prompt prefix must be deterministic. Hook outputs that vary turn-to-turn must land in a user-message position, not a system-prompt position."

**Risk:** Low. Determinism is almost always net positive.

### P0-7 — Adopt Anthropic's verbatim prompt blocks

**Gap:** APEX wrote bespoke prompt language for several domains that Anthropic has now published battle-tested verbatim text for. Adopting these verbatim is essentially "free" alignment.

**Six verbatim blocks to adopt** (all quoted in Report 01 §2.9):

| Block | APEX target | Anthropic-claimed effect |
|---|---|---|
| `<use_parallel_tool_calls>` block | `wave-executor.md` top | ~100% parallel-call success rate |
| Balancing-autonomy-and-safety / destructive-action examples | `executor.md`, `wave-executor.md`, `remediation-planner.md` | Same intent as APEX's destructive-guard |
| Overengineering control block | (covered by P0-1 above) | (per Karpathy claims: 41→11% error reduction) |
| Hallucination-suppression `<investigate_before_answering>` block | `executor.md`, `critic.md` | "Never speculate about code you have not opened" |
| Test-anti-hardcoding block | `executor.md`, `critic.md` | Prevents the "tests pass but solution only handles known inputs" failure |
| Context-window-awareness prompt | All agents (universal) | Prevents agents from stopping early due to budget paranoia |

**Smallest viable change:** Insert each block into the relevant agent prompt as a labeled section. Total addition: ~600 words across the framework.

**Risk:** Negligible. These are Anthropic's own recommended texts.

### P0-8 — Explicit compaction primitive at phase boundaries

**Gap:** APEX has `turn-checkpoint.sh` and `context-monitor.sh` but no actual compaction step — i.e., a step that takes a long phase trace, summarizes it with the canonical 5-section template, and replaces it. Anthropic measured:
- **+39% combined** (memory tool + context editing) over baseline on agentic search
- **+29% context-editing alone**
- **84% token reduction** on 100-turn web-search workflows

**Evidence:**
- Anthropic primary article: "Compaction typically serves as the first lever in context engineering"
- Anthropic Cookbook: full `compact_20260112` API surface (default 150k trigger, min 50k, `pause_after_compaction`, `instructions`)
- Anthropic harnesses post: "compaction isn't sufficient" alone — you need filesystem + git + tests in addition. But it's still the first lever.
- Manus L4 (recitation evolved into a sub-agent planner injecting structured object only when needed — same idea)

**Smallest viable change:**
1. Add a new hook `phase-compaction.sh` that runs at phase boundaries. Invokes a `memory-synthesis`-style agent to produce a `phase-N-SUMMARY.md` matching the 5-section template, focused on: decisions, open issues, most-recently-touched files.
2. Document in `executor.md` the recommended Claude API `context_management` config when APEX runs programmatically (cookbook thresholds: low=5k test / mid=30-40k typical / high=50k+ compute-intensive).
3. Recommend `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50` in `.claude/settings.json` for APEX projects — gives Claude Code earlier compaction headroom.

**Risk:** Medium. Bad compaction loses decisions. Mitigation: pilot on a non-critical phase, A/B compare pre/post `STATE.json`.

### P0-9 — Failure-preservation invariant ("keep the wrong stuff in")

**Gap:** Manus L5 + Anthropic durable-execution agree: never clean up failure traces. APEX has `*-CRITIC.md` (retained) and `RESULT.json` (retained), but it's not explicit whether `turn-checkpoint.sh` or wave-executor sanitize failed-turn state when moving on.

**Evidence:**
- Manus L5 verbatim: *"Erasing failure removes evidence. And without evidence, the model can't adapt."*
- Anthropic multi-agent post: *"Letting the agent know when a tool is failing and letting it adapt works surprisingly well."*
- Team Atlanta retrospective: oracles + segfaults + ASAN traces retained as the model's reality-check
- Microsoft MDASH: prover stage explicitly produces ASan-style proofs — failure-evidence is the deliverable, not noise

**Smallest viable change:** Add explicit invariant to `apex-spec.md`:
```
Failure-preservation invariant: when a task fails, the failure trace is
appended to .apex/phases/{phase}/FAILURES.md and remains accessible to all
subsequent agents in that phase. No agent may delete, summarize-away, or
hide a failure trace. Critic, verifier, and remediation-planner MUST read
the relevant FAILURES.md before issuing verdicts.
```
Add a `failures_seen: [paths]` field to `RESULT.json` so audits can verify the agent actually read them.

**Risk:** Low. APEX's rigor philosophy already aligns.

### P0-10 — Lightweight `step → verify: check` plan format for `/apex:fast` / `/apex:quick`

**Gap:** APEX's PLAN.md schema is great for `/apex:build` and `/apex:full` but overkill for trivial work. Karpathy's three-column template (`[Step] → verify: [check]`) is the lightest possible plan format and maps directly to what a human would scribble.

**Evidence:**
- Karpathy Section 4 (Goal-Driven Execution) template verbatim
- Anthropic best practices: "For tasks where the scope is clear and the fix is small, ask Claude to do it directly"
- Microsoft MDASH per-stage stop criteria implies stage-light plans
- Anthropic Building Effective Agents: workflow patterns scale with task complexity

**Smallest viable change:** Update `/apex:fast` and `/apex:quick` skill definitions to output:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
```
No JSON, no schema, no `PLAN_META.json` overhead. Plan ends when verify checks pass. `/apex:build` and `/apex:full` continue using full PLAN.md.

**Risk:** Plan format proliferation. Mitigated by clear command boundaries.

---

## 3. P1 — High-value changes (require more design)

These need more thought, design, or experimentation. Each one has strong evidence from at least one source but the implementation surface is non-trivial.

### P1-1 — Per-stage stop criteria (MDASH pattern)

**Source:** Microsoft MDASH 5-stage pipeline — *"each pipeline stage has its own role, prompt regime, tools, and stop criteria."*

**APEX gap:** `circuit-breaker.sh` is task-scoped. Sub-stages within a task share one global budget — a runaway "edit then test then critic then verify" loop can blow the budget without sub-stage gating.

**Smallest viable change:** Extend `PLAN_META.json` and `circuit-breaker.sh` to carry **stage-typed budgets**:
```json
{
  "stages": {
    "scan": {"budget_tokens": 5000, "budget_calls": 5, "stop_on": "evidence_complete"},
    "edit": {"budget_tokens": 20000, "budget_calls": 30, "stop_on": "all_acceptance_met"},
    "test": {"budget_tokens": 10000, "budget_calls": 20, "stop_on": "all_tests_pass"},
    "critic": {"budget_tokens": 8000, "budget_calls": 10, "stop_on": "verdict_returned"}
  }
}
```

**Risk:** Schema breaking change. Mitigation: opt-in field with fallback to current task-scoped budget.

### P1-2 — Restorable-compression audit (Manus L3 + Anthropic JIT)

**Source:** Manus L3 + Anthropic just-in-time — *every summary must be paired with an identifier (path/URL/query) so the agent can re-load detail on demand*.

**APEX gap:** Many of APEX's summaries (`*-RESULT.json`, `*-SUMMARY.md`, `MEMORY.md`, `apex-learnings.md`) may not always carry a pointer back to the source trace. Without that pointer, the summary is *destructive compression*, not restorable.

**Smallest viable change:**
1. Audit each summary-producing artifact. Require every summary block to include `source_files: [paths]`.
2. Add a convention: a summary that loses information without recording a path to the source is a defect.
3. Document in `apex-spec.md` the restorable-compression invariant.

**Risk:** Low. Mostly a documentation + audit change.

### P1-3 — Recitation cost measurement (Manus's 30% warning)

**Source:** Manus's 5th rewrite *repealed* continuous todo.md recitation because it cost ~30% of all tokens. The post itself describes recitation as a virtue (L4); the post-publication update describes it as a tax.

**APEX gap:** APEX re-reads `STATE.json`, `apex-spec.md`, `PLAN.md` on `/apex:next`. The recent v8 circuit-breaker work added "spec entry" — this is a recitation mechanism. Worth measuring the cost.

**Smallest viable change:**
1. Instrument `context-monitor.sh` to log a **"recitation token category"** — how many tokens per turn come from re-reading APEX-internal artifacts vs. user code.
2. If recitation > 20% of total tokens, switch to the Manus 5th-rewrite pattern: pin recitation to phase/task boundaries, not every turn. (APEX already has phase boundaries — this is the natural pivot.)
3. Replace continuous re-reading with a **structured-object inject pattern**: a sub-agent reads `STATE.json` once, produces a 1-2k-token structured digest, injected only when context drifts.

**Risk:** Medium. Cutting recitation can cause "lost-in-the-middle" failures. Test on real runs before committing.

### P1-4 — Critic posterior-credibility (Microsoft Bayesian framing)

**Source:** Microsoft Kim verbatim — *"When an auditor flags something as suspect and the debater can't refute it, that finding's posterior credibility goes up."*

**APEX gap:** APEX's partial-confidence critic returns categorical verdicts (pass / partial / fail). The MDASH framing adds a *delta*: when an executor's claim survives critic challenge, confidence rises; when critic disputes and executor counter-evidence can't be refuted, confidence rises further.

**Smallest viable change:** Extend `*-CRITIC.md` and `RESULT.json` with two new fields:
```json
"critic": {
  "pre_challenge_confidence": 0.6,
  "post_challenge_confidence": 0.9,
  "challenge_history": [
    {"challenge": "...", "executor_response": "...", "resolved": true}
  ]
}
```
Add to `framework-auditor.md`: large positive deltas (>0.3) are flagged as "high-confidence findings"; large negative deltas (<−0.3) escalate to user.

**Risk:** Adds critic complexity. Only useful if a downstream consumer (auditor, framework-auditor, milestone-summary) actually reads the field.

### P1-5 — Cross-provider second opinion for irreversibles (MDASH)

**Source:** Microsoft MDASH — *"a second separate SOTA model as an independent counterpoint."* Not a different prompt on the same model — a structurally separate model. Same-provider critic has correlated failure modes.

**APEX gap:** APEX's critic is clean-room but typically same-model. For irreversible actions (database migrations, force-pushes, destructive refactors), correlated failure is the worst case.

**Smallest viable change:** Add an opt-in `critic.provider` field to `PLAN_META.json`:
```json
"critic": {
  "provider": "anthropic",            // default
  "cross_provider_on_severity": "critical",  // opt-in
  "cross_provider_model": "gpt-5"     // routed when severity matches
}
```
When `severity=critical`, route to a non-matching provider. Document the trade-off (cost, API-key management) in `apex-spec.md`.

**Risk:** High setup cost (multiple API keys, multiple SDK paths). Defer to a dedicated phase.

### P1-6 — Sub-agent for capability amplification mid-task (depthfirst's biggest win)

**Source:** depthfirst lifted CyberGym 41 → 48% by spawning a dedicated **instrumentation sub-agent**. Generalization: if a capability is shared across the main agent's tools and the main agent is under-using it, give it a dedicated sub-agent.

**APEX gap:** APEX has specialist agents but they're invoked at *phase boundaries*, not as embedded mid-task sub-routines.

**Smallest viable change:** Identify APEX's **most-under-used capability** in current runs. Likely candidates:
- Snapshot/rollback verification (currently a hook; might benefit from being a sub-agent)
- Test-architect's regression-test scaffolding (used pre-phase; might benefit from mid-phase invocation)
- Memory-synthesis (currently dream-cycle only; might benefit from mid-phase compaction)

Pick one. Wrap as a dedicated sub-agent invokable from inside `executor.md`. Measure the lift.

**Risk:** Medium. Adds latency and token cost; pick the right candidate.

### P1-7 — Multi-oracle verification stacking

**Source:** Team Atlanta retrospective: *"Ensembling only works when oracles exist to judge correctness."* They stack hardware (segfaults), sanitizers (ASAN/UBSAN), and PoV re-execution. Microsoft MDASH stacks debater + prover. Anthropic stacks LLM-judge + human.

**APEX gap:** APEX's `verify_levels` typically pick ONE oracle (lint OR unit OR integration OR critic). For high-severity work, stacking is the right move.

**Smallest viable change:** Allow `VERIFY.md` to list multiple oracles for one task, with ALL required to pass:
```
verify:
  - lint:     `npm run lint`
  - unit:     `npm test -- --coverage`
  - integration: `npm run test:integration`
  - critic:   spawn critic agent with policy=strict
  - human:    require explicit user OK before merge (high-severity only)
```
For low-severity, retain single-oracle behavior (default). For `severity=critical`, require multi-oracle.

**Risk:** Slows high-severity work. Intentional trade-off.

### P1-8 — Effort levels replace `budget_tokens` in `PLAN_META.json`

**Source:** Anthropic Opus 4.7 deprecates manual `budget_tokens`; uses adaptive thinking + effort levels (`low` / `medium` / `high` / `xhigh` / `max`).

**APEX gap:** APEX's `CONTEXT_BUDGET.json` probably hard-codes tokens. With current models, effort levels are the future.

**Smallest viable change:** Add per-agent `effort` to `PLAN_META.json`:
```json
{
  "phase": "phase-7",
  "effort": {
    "architect":      "xhigh",   // long horizon, irreversible
    "executor":       "xhigh",   // coding default per Anthropic
    "critic":         "high",
    "verifier":       "medium",
    "framework-auditor": "xhigh",
    "fast_micro":     "low"
  }
}
```
The orchestrator passes the effort level through to model invocation. Backward-compatible default if absent.

**Risk:** Low. Pure additive.

### P1-9 — Tool/agent description optimization pass (Anthropic 40% gain claim)

**Source:** Anthropic multi-agent post — their "tool-testing agent" rewrote tool descriptions and cut future task time by **40%**. Anthropic generalizes: *"spent more time optimizing tools than the overall prompt."*

**APEX gap:** APEX has ~30 agent prompts that function as tool descriptions from the orchestrator's perspective. None have been audited as tools.

**Smallest viable change:** Add a `/apex:health-check` mode that:
1. Takes each agent prompt + the `description` field
2. Reads recent transcripts from `~/.claude/projects/.../`
3. Proposes refinements (description tightening, examples, anti-pattern callouts)
4. Reports via `framework-auditor.md`-style findings

The Anthropic-claimed 40% lift is on a different benchmark (multi-agent research eval), but the pattern is generic: descriptions matter for delegation accuracy.

**Risk:** Low. Self-improvement is already an APEX value.

### P1-10 — Per-stage domain plugins (Microsoft MDASH extension)

**Source:** Microsoft MDASH injects per-domain knowledge plugins (kernel calling conventions, IRP rules, lock invariants, IPC trust boundaries, codec state machines). APEX's `apex-skills/` is the analog at the *stack* level. The MDASH extension is per-*stage*.

**APEX gap:** `apex-skills/<stack>.md` exists. `apex-skills/<stack>-<stage>.md` does not.

**Smallest viable change:** Naming convention extension. Example:
- `apex-skills/nextjs.md` — stack-wide (existing)
- `apex-skills/nextjs-critic.md` — what a Next.js *critic* should look for (anti-patterns, common bugs)
- `apex-skills/nextjs-executor.md` — coding conventions, framework idioms
- `apex-skills/nextjs-test-architect.md` — test patterns specific to Next.js

Default-fallback rule: if `<stack>-<stage>.md` not found, use `<stack>.md`.

**Risk:** File proliferation. Mitigate with naming convention and lazy generation (only generate when a real gap is identified).

---

## 4. P2 — Longer-term / strategic moves

### P2-1 — Marketplace plugin packaging

**Source:** Karpathy repo proves a single CLAUDE.md is enough to be a Claude Code marketplace plugin (`.claude-plugin/{plugin,marketplace}.json`).

**APEX move:** Once stable, ship APEX as a marketplace plugin (`/plugin install apex@apex-framework`). The repo currently has commands + agents + hooks; the plugin format wraps all of these.

**Risk:** Some APEX files (hooks as shell scripts) may not all fit the plugin model cleanly. Validate first.

### P2-2 — SECURITY.md threat model (where APEX leads the industry)

**Source:** Microsoft MDASH, Big Sleep, Anthropic Research, Team Atlanta all publish ZERO guardrails for the agent's own reasoning loop. APEX already has destructive-guard + plan-mode + 10Q gate — **APEX is ahead**. Document this.

**Smallest viable change:** Create `SECURITY.md` (or section in apex-spec.md) listing APEX's threat model:
- Malicious file contents being read into agent context (memory poisoning)
- Untrusted git remotes
- Untrusted MCP servers
- Untrusted hooks
- Prompt-injection via tool outputs

For each, name the defense (destructive-guard / plan-mode / 10Q gate / context-monitor / etc.).

**Risk:** None — pure documentation, high credibility value.

### P2-3 — Quarterly "Stochastic Graduate Descent" REMOVAL pass

**Source:** Manus rewrote 5× in 6 months. Vercel cut 80% of agent tools. Schmid: *"biggest gains came from removing things."*

**APEX move:** Schedule a quarterly `/apex:self-heal` round explicitly targeted at REMOVAL — find what can be cut. Track "is each rewrite simpler than the last?" If complexity is growing, that's a red flag.

**Smallest viable change:** Add a `self-heal --mode=removal` flag that biases the framework-auditor toward consolidation findings instead of gap findings.

**Risk:** None — meta-process.

### P2-4 — Glossary in `apex-spec.md` mapping APEX → Anthropic canonical vocabulary

**Source:** Anthropic Building Effective Agents names the canonical patterns (prompt-chaining, routing, parallelization, orchestrator-workers, evaluator-optimizer). APEX uses bespoke vocabulary (wave, phase, round, campaign).

**APEX move:** Glossary section cross-referencing:
- Wave → parallelization (sectioning)
- Round (self-heal) → evaluator-optimizer
- Architect→Executor→Critic → orchestrator-workers + evaluator-optimizer
- Phase → orchestrated workflow

**Risk:** None. Helps onboarding and future-proofs the framework's discoverability.

### P2-5 — Per-agent persistent memory directories (Claude Code reference architecture)

**Source:** Claude Code's `~/.claude/agent-memory/<name>/` (user scope), `.claude/agent-memory/<name>/` (project), `.claude/agent-memory-local/<name>/` (private). MEMORY.md auto-loaded up to 200 lines / 25KB.

**APEX move:** Each APEX agent gains a persistent memory directory. Especially valuable for:
- `architect` — accumulate cross-project architectural patterns (`memory: user`)
- `critic`, `auditor`, `framework-auditor` — accumulate project-specific findings (`memory: project`)
- `executor` — no persistent memory (clean room per task)

**Risk:** Memory poisoning. Document mitigation: every agent prompt explicitly treats memory content as data, not instructions.

### P2-6 — Cross-provider verification eval / APEX-on-APEX benchmark

**Source:** Anthropic measured 90.2% lift, 40% description-rewrite gain, 90% parallel-tool speedup. APEX has no comparable numbers. Microsoft published 88.45% on CyberGym (unreproducible per depthfirst). Per CyberGym critique: any vendor benchmark claim must publish harness + model + cost + exclusions.

**APEX move:** Build a small "APEX eval" — 20 representative tasks across `/apex:fast`, `/apex:build`, `/apex:full`. Run before/after each P0/P1 change. Track: success rate, total tokens, total time, critic agreement, regression rate.

**Risk:** Eval design is the hard part. Mitigation: borrow Anthropic's recommended methodology (LLM-as-judge with 0.0-1.0 score; ~20 representative queries to start).

### P2-7 — Methodology disclosure in `/apex:milestone-summary`

**Source:** CyberGym critique — Microsoft's 88.45% is unreproducible because they didn't publish the harness. Same goes for Anthropic's Mythos 83.1%. Lesson: vendor claims without harness disclosure are not evidence.

**APEX move:** When APEX publishes performance claims (DORA metrics, milestone reports), match the depthfirst rigor:
- What was measured
- With what model + provider
- On what scaffolding
- What was excluded
- Token cost
- Single-run vs multi-run

**Smallest viable change:** `/apex:milestone-summary` template gains a mandatory "Methodology" section.

**Risk:** None.

---

## 5. Cross-source tension to resolve before next major APEX release

The research surfaced one architectural debate APEX cannot ignore. **You must take a position on it before the next major release.**

### The multi-agent ceremony question

**Pro-sub-agent (use ceremony):**
- Anthropic: 90.2% lift on research eval (single Opus 4 vs Opus 4 + 3-5 Sonnet 4 sub-agents)
- Manus Wide Research: 100 parallel sub-agents for embarrassingly-parallel work
- Microsoft MDASH: 100+ specialized agents in 5-stage pipeline (auditor/debater/prover)
- depthfirst: dedicated instrumentation sub-agent lifted CyberGym 41 → 48% (no other change)

**Anti-sub-agent (avoid ceremony):**
- Anthropic explicit warning, twice: *"Most coding tasks involve fewer truly parallelizable tasks than research."* + 15× token cost.
- Cognition "Don't Build Multi-Agents": shared context + full agent traces > isolation
- Manus 5th rewrite: tools reduced from "dozens" to <20, MCP moved out of context, recitation killed
- Schmid: "The harness you build today will be obsolete when the next frontier model drops"

**Reconciliation that emerged from cross-reference:**

| Task shape | Use multi-agent? |
|---|---|
| Independent items (100 sneakers, 1507 vulnerabilities) | **Yes** — Wide Research pattern |
| Independent verification angles (auditor + debater + prover) | **Yes** — MDASH pattern |
| Independent decomposition (architect plans, executor codes, critic verifies — all on a SHARED artifact) | **Conditional** — depends on whether sub-agents have access to DECISIONS.md as ground truth |
| Coupled creative work (one program, multiple authors) | **No** — Cognition's Flappy Bird failure |
| Quick fixes / typos / single-line changes | **No** — Anthropic's "ask Claude directly" + Karpathy's "use judgment" |

**APEX is currently a mix:**
- ✅ Architect / executor / critic / verifier on a SHARED artifact (`STATE.json`, `PLAN.md`, `DECISIONS.md`) — sub-agents work because they share ground truth
- ✅ Wave-executor for parallel tasks within a phase — works because tasks are independent
- ❌ Risk: invoking the full ceremony on tasks that don't earn it (the user has complained about this — see `feedback_plan_design.md`)

**Recommended position:**
1. Default to **multi-agent ceremony only for `/apex:build` and `/apex:full`** — explicitly value-of-task gate.
2. **DECISIONS.md is the single source of truth that every agent reads first** — this is the Cognition fix for shared-context-via-files.
3. **`/apex:fast` and `/apex:quick` skip multi-agent ceremony by design** — Anthropic explicitly endorses this.
4. **Document the position in `apex-spec.md`** with the table above, so future maintainers don't drift.

---

## 6. Quick-win shortlist (if you do only 5 things)

If you can only ship 5 of these, ship these:

1. **P0-1** — Anti-overengineering prompt block (Karpathy 4 rules + Anthropic verbatim block) in executor + critic. ~30 lines per agent. **Highest ROI single change.**
2. **P0-2** — Tradeoff-disclosure preamble in `apex-spec.md`. One paragraph. Resolves the user's documented "feels heavy" complaint.
3. **P0-3** — Assumption-block floor before code in executor. Complements the user's existing 10Q ceiling. Three-bullet cap.
4. **P0-6** — KV-cache hygiene audit. Strip sub-minute timestamps from hook output. Enforce sorted JSON keys. 10× cost ratio is unignorable.
5. **P0-9** — Failure-preservation invariant. `FAILURES.md` per phase. No agent may delete failure traces. Critic + verifier MUST read them.

Combined implementation surface: ~200 lines of prompt edits + one hook canonicalizer + one schema field. No new agents, no new commands, no breaking changes.

---

## 7. Surprises worth knowing

Things from the research that contradicted prior assumptions or were genuinely new:

- **Anthropic's Mythos 83.1% on CyberGym is "a vendor claim" — they didn't publish the harness.** Same for Microsoft's 88.45%. Vendor benchmarks without harness disclosure are not evidence.
- **Smaller models often beat larger ones on bounded sub-tasks** (Team Atlanta with GPT-4o-mini). The budget profile isn't an apology — it's sometimes the *correct* choice.
- **Manus's recitation pattern (Lesson 4) was REPEALED in their 5th rewrite** because it cost 30% of tokens. The original blog post is partially out-of-date; the canonical update is in the Peak Ji + Lance Martin webinar.
- **Anthropic concedes their own compaction "isn't sufficient"** for production-grade web apps. The harness layer (filesystem + git + structured tests) is essential, not optional. This validates APEX's existence as a category.
- **Models perform BETTER on shuffled haystacks than logically structured ones** (Chroma 18-model study). Counter-intuitive — implies APEX should not always sort files alphabetically when loading multiple.
- **Claude Sonnet 4.6+ tracks its own remaining context natively.** Anthropic's recommended prompt: *"do not stop tasks early due to token budget concerns"* — the model now reasons about budgets. APEX's `context-monitor.sh` is partially redundant for newer models (but still a useful safety net).
- **The memory tool has a documented prompt-injection vector** ("memory poisoning"). APEX's `STATE.json` + `MEMORY.md` pattern needs the same mitigation: instruct agents to treat memory content as data, not instructions.
- **Manus was acquired by Meta for $2-3B in Dec 2025** (blocked by China April 2026). Their post is no longer an independent voice — track whether post-acquisition Manus continues publishing.
- **WebFetch's summarizer refused to reproduce MIT-licensed CLAUDE.md verbatim** citing "appropriate boundaries for content reuse." Bypassed via `gh api`. Worth knowing for future verbatim-capture research.
- **Anthropic explicitly warns against frameworks** in their own Building Effective Agents post. APEX's defense: every behavior must be traceable to a plain markdown agent prompt or a shell hook. The spec should explicitly say: *"If you cannot trace any APEX behavior to a markdown agent prompt or a shell hook, it is a bug."*

---

## 8. Recommendation → source matrix (citation density check)

| Recommendation | Anthropic Cookbook | Anthropic Eng | Karpathy | Manus | Microsoft |
|---|---|---|---|---|---|
| P0-1 anti-overengineering | ✅ verbatim block | ✅ overeng prompt | ✅ 2 of 4 rules | ✅ "remove things" | — |
| P0-2 tradeoff disclosure | ✅ skip plan-mode | ✅ multi-agent value gate | ✅ tagline | ✅ (5 rewrites simpler) | — |
| P0-3 assumption block | ✅ investigate-before | ✅ hallucination prompt | ✅ Section 1 | — | — |
| P0-4 diff-bloat alarm | — | — | ✅ Section 3 closing | ✅ append-only | — |
| P0-5 5-section template | ✅ canonical | ✅ compaction default | — | — | — |
| P0-6 KV-cache hygiene | ✅ cache_control | ✅ cache + compaction | — | ✅ L1 (10× ratio) | ✅ stable prefix |
| P0-7 verbatim prompts | ✅ 6 blocks | ✅ effort, autonomy | — | — | — |
| P0-8 compaction primitive | ✅ compact_20260112 | ✅ "first lever" | — | ✅ (sub-agent planner) | — |
| P0-9 failure preservation | ✅ durable execution | ✅ "let agent know" | — | ✅ L5 verbatim | ✅ oracles + ASAN |
| P0-10 lightweight plan | — | ✅ "small fix directly" | ✅ step→verify | — | ✅ per-stage stops |
| P1-1 per-stage stops | — | — | — | ✅ implicit | ✅ verbatim |
| P1-2 restorable compression | ✅ JIT | ✅ identifiers | — | ✅ L3 | — |
| P1-3 recitation cost | — | — | — | ✅ 30% warning | — |
| P1-4 posterior credibility | — | — | — | — | ✅ verbatim |
| P1-5 cross-provider critic | — | — | — | — | ✅ verbatim |
| P1-6 sub-agent amplifier | — | ✅ subagent pattern | — | — | ✅ depthfirst +7% |
| P1-7 multi-oracle | — | ✅ LLM-judge + human | — | — | ✅ debater + prover + Atlanta oracles |
| P1-8 effort levels | ✅ deprecates budget_tokens | ✅ low/med/high/xhigh/max | — | — | — |
| P1-9 description optimization | ✅ tool-eval cookbook | ✅ 40% gain claim | — | — | — |
| P1-10 per-stage skills | — | — | — | — | ✅ domain plugins |

Every P0 has at least 2 supporting sources. Every P1 has at least 1 strong source. No recommendation rests on a single un-cross-checked claim.

---

## 9. What we did NOT cover (research limits, transparency)

- **Token-economics of APEX itself** — no measurement of current per-task token cost across `/apex:fast` / `/apex:build` / `/apex:full`. The 15× multi-agent figure (Anthropic) is a *direction*, not a measurement of APEX specifically.
- **Adversarial robustness of APEX agents** — AgentDojo, ASB, ShieldAgent, LlamaFirewall exist as 2026 benchmarks; APEX hasn't been measured against any.
- **MCP integration details** — Anthropic and Manus both reference MCP heavily; APEX's stance on MCP servers vs in-process tools wasn't surveyed.
- **Computer use / Playwright MCP** — Anthropic's harnesses post calls this "the single highest-leverage gap" for text-only verifiers. APEX has no equivalent today. Out of scope for this synthesis; worth a dedicated phase.
- **Memory-poisoning attack scenarios** — security warnings exist (Anthropic, Manus) but no quantified attack/defense data in the sources.
- **Cross-provider cost comparison** — recommendation P1-5 assumes the cost is justified for irreversibles but the actual ratio (Anthropic vs OpenAI vs Google on identical tasks) wasn't surveyed.

---

## Final note for the user (the framework's author)

APEX's core thesis — *the harness is the engineering, the model is a swappable input* — is now externally validated by a hyperscaler (Microsoft MDASH), the most-cited context-engineering blog post (Manus), and Anthropic's own engineering writings. **You're building the right thing.**

The three areas where APEX has under-developed seams are:
1. **Anti-bloat behavioral floor** — every other source bakes this into the executor; APEX has it only at plan-level via ecosystem-10Q.
2. **Restorable compression discipline** — APEX produces summaries but doesn't always pair them with source paths.
3. **Per-stage stop criteria** — APEX's circuit-breaker is task-scoped; the field has moved to sub-task-scoped.

The one area where APEX is **ahead of the disclosed competition** is **AI-system safety** — destructive-guard, plan-mode, and the 10Q ecosystem gate are stronger than anything Microsoft, Google Big Sleep, Anthropic Research, or Team Atlanta have published. Document this in `SECURITY.md` and lean into it.

The single highest-ROI shipping target is **P0-1 + P0-2 + P0-3 combined** — ~200 lines of prompt edits that close the gap with the dominant community CLAUDE.md and resolve the user's documented "feels heavy" complaint at the same time.
