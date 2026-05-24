# Deep Research 04 — Manus: Context Engineering for AI Agents

**Researcher:** Agent 04 (parallel research swarm)
**Date:** 2026-05-24
**Primary URL:** https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus
**Primary author:** Yichao "Peak" Ji (Co-founder & Chief Scientist, Manus / Butterfly Effect)
**Primary publication date:** Friday, July 18, 2025

---

## 0. Source map

### Primary source
| # | URL | Hop | Purpose | What I found |
|---|-----|-----|---------|--------------|
| P1 | https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus | 0 | The post itself | Six named lessons, "Stochastic Graduate Descent" framing, 10× KV-cache cost ratio |

### Secondary fetched (hop 1)
| # | URL | Result |
|---|-----|--------|
| S1 | https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents | Anthropic's official guidance (Sep 29, 2025) — full extract |
| S2 | https://rlancemartin.github.io/2025/10/15/manus/ | Lance Martin (LangChain) webinar-derived post: reduce / offload / isolate framework |
| S3 | https://cognition.ai/blog/dont-build-multi-agents | Cognition's CONTRARIAN view (Walden Yan, June 12, 2025) |
| S4 | https://e2b.dev/blog/how-manus-uses-e2b-to-provide-agents-with-virtual-computers | e2b case study (Tereza Tizkova, May 6, 2025) — Firecracker microVMs, 27 tools, 150ms boot |
| S5 | https://www.trychroma.com/research/context-rot | Chroma "context rot" study (Hong/Troynikov/Huber, July 14, 2025) — 18 models tested |
| S6 | https://www.anthropic.com/engineering/built-multi-agent-research-system | Anthropic multi-agent research system (June 13, 2025) — 90.2% improvement, 15× token usage |
| S7 | https://www.langchain.com/blog/context-engineering-for-agents | LangChain "Write/Select/Compress/Isolate" framework (July 2, 2025) |
| S8 | https://www.philschmid.de/context-engineering-part-2 | Schmid Part 2 (Dec 4, 2025) — "biggest gains came from removing things" |
| S9 | https://www.philschmid.de/agent-harness-2026 | Schmid agent harness post (Jan 5, 2026) |
| S10 | https://manus.im/blog/manus-wide-research-solve-context-problem | Manus "Wide Research" post (Oct 29, 2025) |
| S11 | https://www.marktechpost.com/2025/07/22/context-engineering-for-ai-agents-key-lessons-from-manus/ | MarkTechPost coverage |
| S12 | https://www.joshbeckman.org/notes/920141445 | Practitioner note |
| S13 | https://medium.com/@xiweizhou/couldnt-agree-more-manus-s-agent-context-engineering-lessons-1cc234b7a169 | Xiwei Zhou validation |
| S14 | https://medium.com/@dario.fabiani/from-theory-to-practice-how-manus-ai-validates-context-engineering-principles-723ca524570d | Dario Fabiani perspective |
| S15 | https://clune.org/posts/anthropic-context-engineering/ | Arthur Clune on Claude Code |
| S16 | https://medium.com/@peakji/context-engineering-for-ai-agents-lessons-from-building-manus-71883f0a67f2 | Medium mirror of post |
| S17 | https://www.zenml.io/llmops-database/context-engineering-strategies-for-production-ai-agents | ZenML LLMOps DB entry |
| S18 | https://en.wikipedia.org/wiki/Manus_(AI_agent) | Wikipedia — Meta acquisition $2-3B Dec 2025, blocked by China Apr 2026 |
| S19 | https://www.technologyreview.com/2025/09/08/1122642/ji-peak-yichao-innovator-manus-app-ai/ | MIT Tech Review profile |
| S20 | https://hugobowne.substack.com/p/ai-agent-harness-3-principles-for | Bowne-Anderson/Gilchrist (Dec 12, 2025) — Reduce/Offload/Isolate |
| S21 | https://aakashgupta.medium.com/2025-was-agents-2026-is-agent-harnesses-... | Gupta (Jan 7, 2026) — "model is commodity, harness is moat" |
| S22 | https://snowan.gitbook.io/study-notes/ai-blogs/how-to-build-agent-harness | Harness study notes |

### Fetches that failed (HN rate-limited)
- https://news.ycombinator.com/item?id=44635141 (primary HN thread) — 429 on all 4 attempts. Search confirms the thread exists but content not retrievable.
- https://news.ycombinator.com/item?id=46210459 (HN on Lance Martin's follow-up) — 429.
- https://x.com/peakji/status/1946240739178164246 — 402.

### Hop depth
Max hop depth reached: **2** (primary → cited posts → community responses to cited posts). Total URLs fetched: **22** (plus 4 search queries).

---

## 1. Executive summary

Top takeaways ranked by APEX relevance:

1. **(HIGH) KV-cache hit rate is the single most important production metric.** With Claude Sonnet, cached input is $0.30/MTok vs uncached $3/MTok — a 10× difference. Anything that breaks prefix caching (e.g., a second-precision timestamp in system prompt) costs orders of magnitude more. APEX implication: turn-checkpoint hook, STATE.json mutations, prompts ALL need to be reviewed for prefix stability.

2. **(HIGH) "Mask, don't remove" tools.** Removing or dynamically loading tools mid-iteration invalidates the KV-cache AND confuses the model when prior observations reference now-undefined tools. Instead, keep all tools in context and use logit-masking + tool-name prefixes (`browser_*`, `shell_*`) to constrain available actions. APEX implication: agents should not be dynamically swapped in/out of context; use state-machine constraints instead.

3. **(HIGH) Use the file system as the ultimate context.** Unlimited, persistent, agent-operable. Critically: **compression must be restorable** (drop file content, keep paths; drop page HTML, keep URLs). APEX already does this with .apex/ artifacts — but with weak restorability guarantees. The "just-in-time retrieval" pattern is now Anthropic's official recommendation too.

4. **(HIGH) Manipulate attention through RECITATION.** Manus's todo.md trick pushes the objective into the recent attention span. BUT: in their evolved harness, this consumed **~30% of all tokens** and they REPLACED it with a sub-agent planner. APEX's `apex-spec.md` re-reading + STATE.json re-reading on resume is exactly this pattern — but watch the token cost.

5. **(HIGH) Keep the wrong stuff IN.** Error traces, stack traces, failed actions stay in context. Erasing failure removes evidence; without evidence the model cannot adapt. APEX critic and verifier MUST preserve failure context — and this validates APEX's "anti-rationalization armor" philosophy.

6. **(HIGH) Don't get few-shotted.** Repetitive context patterns create brittle pattern-matching. Inject "small amounts of structured variation in actions and observations — different serialization templates, alternate phrasing, minor noise." APEX implication: hooks/templates that produce identical output every turn create this risk.

7. **(HIGH) "Stochastic Graduate Descent" is the actual development method.** Manus has **rewritten the agent harness 5 times in 6 months**. Each rewrite was REMOVAL, not addition. Peak Ji: "As models get stronger, we shouldn't be building more scaffolding, we should be getting out of the model's way." APEX needs to internalize: every version should be SIMPLER than the last.

8. **(MED) Bitter Lesson applied to harness design.** Schmid: "The harness you build today will likely be obsolete when the next frontier model drops." Avoid baking opinionated logic into agents/hooks that future models won't need.

9. **(MED) The big architectural debate: multi-agent.** Manus uses sub-agents for context ISOLATION (validated by Anthropic's 90.2% multi-agent gain). Cognition argues "Don't Build Multi-Agents" — context fragmentation creates conflicting assumptions. The reconciliation: sub-agents are fine for clean-room narrow tasks with structured returns; bad for parallel creative work without shared state.

10. **(MED) Context rot is real and measured.** Chroma's 18-model study: degradation is non-uniform, even simple tasks fail at long context, "effective context window" is materially less than advertised. Practically, plan for ~50% of stated context window before reliability drops.

11. **(MED) Tool count discipline: <20 atomic tools.** Manus moved from "dozens of MCP schemas" to fewer than 20 atomic functions (bash, filesystem, code execution). MCP tools are no longer in context — they're invoked via CLI through bash. This is a radical simplification APEX should consider.

12. **(MED) Compaction must be restorable / hybrid retrieval.** Anthropic's pattern: keep file paths and URLs, drop content; use grep/glob for just-in-time retrieval. CLAUDE.md style auto-load + on-demand exploration.

13. **(MED) Pokémon-agent precedent.** Anthropic's example: an agent maintaining precise tallies across "the last 1,234 steps I've been training my Pokémon in Route 1, Pikachu has gained 8 levels toward the target of 10." Demonstrates note-taking as a memory architecture, not as a heuristic.

14. **(LOW) Hermes function-calling modes.** Auto / Required / Specified — useful taxonomy for thinking about agent decision boundaries.

15. **(LOW) Wide Research scaling.** Manus's product feature deploys up to 100 parallel sub-agents that NEVER communicate with each other; main controller fans out and synthesizes. This works for embarrassingly parallel research tasks but not for coupled work.

---

## 2. Lessons catalog (verbatim from primary source)

### Lesson 1: Design Around the KV-Cache

**Verbatim opening:** "If I had to choose just one metric, I'd argue that the KV-cache hit rate is the single most important metric for a production-stage AI agent. It directly affects both latency and cost."

**The principle:** Production agents iterate (select tool → execute → observe → append → repeat). This creates a heavily input-skewed workload. In Manus: "the average input-to-output token ratio is around 100:1." Caching the prefix is therefore the dominant lever.

**Mechanism:**
1. Keep prompt prefix stable. "Even a single-token difference can invalidate the cache from that token onward." Specifically: don't put precise timestamps in the system prompt.
2. Make context append-only. Don't modify previous actions or observations. Ensure deterministic JSON serialization (stable key ordering).
3. Mark cache breakpoints explicitly when needed (vLLM, etc.) — at minimum at the end of the system prompt.
4. For self-hosted: enable prefix/prompt caching in vLLM; use session IDs for consistent routing in distributed setups.

**Evidence / numbers:**
- Cached input on Claude Sonnet: **$0.30 / MTok**
- Uncached input on Claude Sonnet: **$3.00 / MTok**
- Cost ratio: **10×**
- Avg input:output token ratio at Manus: **~100:1**

**Closing sentence:** "When assigning these, account for potential cache expiration and at minimum, ensure the breakpoint includes the end of the system prompt."

**What they tried that failed (implicit):** Including timestamps; reordering JSON; modifying prior turns.

**Trade-off:** Cache discipline reduces architectural flexibility. You can't rewrite the past — you must design context as append-only from the start.

---

### Lesson 2: Mask, Don't Remove

**Verbatim opening:** "As your agent takes on more capabilities, its action space naturally grows more complex—in plain terms, the number of tools explodes."

**The principle:** Don't dynamically add/remove tools mid-iteration. Mask logits during decoding instead.

**Why removing fails:**
1. Tool definitions live near the front of context (after system prompt). Changing them invalidates KV-cache for everything after.
2. Previous observations may reference tools no longer in context — model gets confused without constrained decoding.

**Mechanism:** Context-aware state machine over tool availability. Three Hermes function-calling modes:
- **Auto:** "The model may choose to call a function or not. Implemented by prefilling only the reply prefix."
- **Required:** "The model must call a function, but the choice is unconstrained."
- **Specified:** "The model must call a function from a specific subset."

Design pattern: **tool-name prefixes** (e.g., `browser_*`, `shell_*`) so you can mask whole categories without stateful logit processors.

**Closing sentence:** "This allows us to easily enforce that the agent only chooses from a certain group of tools at a given state without using stateful logits processors."

**Trade-off:** All tools always loaded → larger prefix → more memory pressure. But cache-friendly, so net positive.

---

### Lesson 3: Use the File System as Context

**Verbatim opening:** "Modern frontier LLMs now offer context windows of 128K tokens or more. But in real-world agentic scenarios, that's often not enough, and sometimes even a liability."

**The principle:** "Treat the file system as the ultimate context in Manus: unlimited in size, persistent by nature, and directly operable by the agent itself."

**Mechanism:**
- The agent reads/writes files on demand.
- Compression strategies are **always designed to be restorable**: drop the content of a web page from context, keep the URL; drop a document's content, keep its file path.
- Model learns to use the file system as externalized memory rather than scratchpad.

**Evidence:** No hard numbers in the post, but per the e2b case study (S4), Manus operates on Firecracker microVMs with ~150ms boot, 27 tools, sessions persisting up to 14 days for paid users.

**Speculative aside (verbatim):** Author imagines State Space Models (SSMs) could excel at agentic tasks "if they could master file-based memory—externalizing long-term state instead of holding it in context, then their speed and efficiency might unlock a new class of agents."

**Closing sentence:** "But if they could master file-based memory—externalizing long-term state instead of holding it in context—then their speed and efficiency might unlock a new class of agents."

**Trade-off:** Slower than pre-computed retrieval (Anthropic notes the same in S1); requires "opinionated and thoughtful engineering" to avoid dead-ends.

---

### Lesson 4: Manipulate Attention Through Recitation

**Verbatim opening:** "If you've worked with Manus, you've probably noticed something curious: when handling complex tasks, it tends to create a todo.md file—and update it step-by-step as the task progresses, checking off completed items."

**The principle:** Combat "lost-in-the-middle" by reciting the plan back into recent context.

**Mechanism:** Constantly rewrite the todo list. This "pushes the global plan into the model's recent attention span" and "uses natural language to bias its own focus toward the task objective—without needing special architectural changes."

**Evidence:** "A typical task in Manus requires around 50 tool calls on average."

**Closing sentence:** "In effect, it's using natural language to bias its own focus toward the task objective—without needing special architectural changes."

**IMPORTANT EVOLUTION (from S20 / S22 / S8):** In the **5th rewrite**, Manus REPLACED the todo.md rewriting pattern because "roughly 30% of all tokens went to updating that file." It was replaced with a **sub-agent planner that returns a structured object and injects it only when needed.** This is in the post-publication evolution covered in the Peak Ji + Lance Martin webinar.

**Trade-off:** Recitation works but is token-expensive. Schmid: "todo.md pattern consumed ~30% in earlier Manus versions" (S8).

---

### Lesson 5: Keep the Wrong Stuff In

**Verbatim opening:** "Agents make mistakes. That's not a bug—it's reality."

**The principle:** "Leaving the wrong turns in the context" — keep error traces, failed actions, stack traces.

**Reasoning (verbatim):** "Erasing failure removes evidence. And without evidence, the model can't adapt."

**Mechanism:** When a tool fails, don't clean up — append the error, let the model see it, let it implicitly update its priors.

**Closing sentence:** "Yet it's still underrepresented in most academic work and public benchmarks, which often focus on task success under ideal conditions."

**Meta-point:** Most agent benchmarks measure ideal-path success; real-world agents must recover. Error retention is the underrepresented competency.

**Trade-off:** Failure traces consume tokens AND can create few-shot pattern problems (Lesson 6). Manus's resolution: keep them, but add diversity.

---

### Lesson 6: Don't Get Few-Shotted

**Verbatim opening:** "Few-shot prompting is a common technique for improving LLM outputs. But in agent systems, it can backfire in subtle ways."

**The principle:** Repetitive context creates rhythmic pattern-matching → "drift, overgeneralization, or sometimes hallucination."

**Example given:** Reviewing a batch of 20 resumes — agent falls into rhythmic patterns based on context examples.

**Mechanism:** "Increase diversity. Manus introduces small amounts of structured variation in actions and observations—different serialization templates, alternate phrasing, minor noise in order or formatting."

**Closing sentence:** "The more uniform your context, the more brittle your agent becomes."

**Trade-off:** Diversity → less cache-friendly. Must balance.

---

### Conclusion (verbatim selected)

- "We affectionately refer to this manual process of architecture searching, prompt fiddling, and empirical guesswork as 'Stochastic Graduate Descent'. It's not elegant, but it works."
- "Context engineering is still an emerging science—but for agent systems, it's already essential."
- "Models may be getting stronger, faster, and cheaper, but no amount of raw capability replaces the need for memory, environment, and feedback."
- "The agentic future will be built one context at a time. Engineer them well."

---

## 3. Architectural themes (cross-lesson synthesis)

### Theme A: The KV-cache is sovereign
Every lesson except #5 and #6 is ultimately a KV-cache hygiene rule. Stable prefix (L1), don't mutate tools (L2), don't bloat context (L3), append rather than rewrite (L4 as caveat). KV-cache thinking subordinates almost everything else.

### Theme B: Restorable compression
Manus and Anthropic converge on: never throw information away; throw away the EXPANDED FORM and keep the IDENTIFIER (path, URL, query). Anthropic calls this "just-in-time" retrieval (S1). The compression is reversible at runtime by the agent itself.

### Theme C: Attention as a scarce resource
Anthropic's framing: "attention budget" depleted by each token. Manus's response: recite back into recent positions. Chroma (S5) provides the empirical foundation: 18 models all show non-uniform degradation; "performance grows increasingly unreliable as input length grows." Anthropic: "performance gradient rather than a hard cliff."

### Theme D: Tool action-space management
- Don't remove (Manus L2)
- Don't bloat — "If a human engineer can't definitively say which tool should be used in a given situation, an AI agent can't be expected to do better" (Anthropic, S1)
- Hierarchical action space (Schmid, S8): atomic tools (~20) → sandbox utilities → code/packages
- Manus's evolved harness: fewer than 20 atomic functions; MCP tools NOT in context but invoked via bash CLI
- Vercel cut 80% of agent tools and saw better results (S21)

### Theme E: Sub-agents for context isolation (contested)
**Pro-sub-agent camp:**
- Manus: planner + executor split; Wide Research scales to 100 parallel sub-agents
- Anthropic multi-agent research: 90.2% improvement on internal eval, 15× token usage, sub-agents return condensed 1,000-2,000 token summaries
- LangChain "Isolate" pillar
- Schmid's "Agent-as-Tool" pattern: sub-agent called as deterministic function returning structured JSON

**Anti-sub-agent camp:**
- Cognition (S3, Walden Yan, June 12, 2025): "Share context, and share full agent traces, not just individual messages" / "Actions carry implicit decisions, and conflicting decisions carry bad results" / Flappy Bird failure example
- Cognition: Claude Code spawns subtasks but "never does work in parallel" because subtask agents lack context

**Reconciliation:** Sub-agents work for narrow, well-defined questions with structured returns (Manus Wide Research's 100 sneakers, Anthropic's research subagents). They fail for parallel creative work where decisions must be coordinated (Cognition's Flappy Bird).

### Theme F: Recitation / structured note-taking
Both Manus (todo.md) and Anthropic (Pokémon agent maintaining "the last 1,234 steps I've been training my Pokémon in Route 1, Pikachu has gained 8 levels toward the target of 10") use external note artifacts as memory plus attention manipulation. But cost is non-trivial (30% in Manus's case).

### Theme G: Error preservation
Manus: keep failure traces. Anthropic multi-agent post: "Minor failures cascade into large behavioral changes" — built durable execution and error recovery via checkpoints. Both reject the temptation to "clean up" failure.

### Theme H: Bitter Lesson applied to harness design
Schmid (S8): "We are living the Bitter Lesson. The harness you build today will likely be obsolete when the next frontier model drops." Manus rewrote 5× in 6 months — every rewrite REMOVED structure. Lance Martin (S2): "Simple, unopinionated designs often adapt better to model improvements."

### Theme I: "Stochastic Graduate Descent"
The development method itself is unprincipled, empirical, manual iteration. Manus, LangChain, Vercel, Anthropic all rebuild repeatedly. There is no "design once and ship" stage. APEX needs to internalize this: the framework will be rewritten, and that's correct.

---

## 4. Cross-reference / synthesis

### Manus vs. Anthropic official guidance (S1)

| Topic | Manus | Anthropic |
|-------|-------|-----------|
| Definition | Implicit; "filling the context window with the right information" | "Strategies for curating and maintaining the optimal set of tokens during LLM inference" |
| Top metric | KV-cache hit rate | "Smallest set of high-signal tokens" |
| File system | "Ultimate context" — primary memory | "Just-in-time retrieval" — references not pre-fetched data |
| Long context | "Even 128K is liability"; offload | "Performance gradient, not a cliff"; context rot is real |
| Sub-agents | Yes — Wide Research, planner+executor | Yes — orchestrator-worker with 90.2% gain, 15× token cost |
| Memory | File system | File system + new "memory tool" public beta |
| Tools | Mask logits, prefix names, <20 atomic | "Bloated tool sets" are common failure |
| Compaction | Restorable references | "Compaction" = summarize + reinitialize; also "structured note-taking" |
| Examples | Diversity to avoid pattern lock | "Diverse, canonical examples" |
| Failure mode | "Keep the wrong stuff in" | Durable execution, checkpoint resume |
| Webinar collaboration | Yes — co-presented with LangChain | Direct overlap in philosophy |

**Convergence:** Both treat context as a scarce, curated resource. Both endorse file-based externalization. Both warn against tool bloat. Both endorse note-taking as memory.

**Divergence:** Manus is more cache-cost-driven (10× ratio is a recurring theme). Anthropic is more model-agnostic (talks about attention budget, not vendor pricing).

### Manus vs. Cognition (S3) — DEEPEST CONFLICT

Cognition (Walden Yan, June 12, 2025) publishes "Don't Build Multi-Agents" five weeks BEFORE Manus's Context Engineering post (July 18, 2025). They are on opposite sides of one debate:

- **Cognition Principle 1:** "Share context, and share full agent traces, not just individual messages"
- **Cognition Principle 2:** "Actions carry implicit decisions, and conflicting decisions carry bad results"
- **Manus's response (implicit, via Wide Research, S10):** Sub-agents work for embarrassingly parallel tasks where decisions don't depend on each other. Main controller fans out and integrates.

**Reconciliation:** Cognition is right when sub-agents must collaborate on a single coherent artifact (Flappy Bird game). Manus is right when sub-agents handle independent items (100 sneakers research). The deciding factor is **decision coupling**, not the architecture per se.

### Manus vs. LangChain framework (S7)

LangChain's "Write / Select / Compress / Isolate" maps cleanly onto Manus's lessons:
- **Write:** Manus L3 (file system), L4 (todo.md)
- **Select:** Manus L2 (tool masking)
- **Compress:** Manus L3 (restorable compression)
- **Isolate:** Manus's planner/executor split; Wide Research sub-agents

Lance Martin's later post (S2) explicitly reorganizes Manus's lessons under a slightly different rubric: **Reduce / Offload / Isolate**.

### Manus vs. Chroma context-rot research (S5)

Chroma's quantitative study (18 models, July 14, 2025 — 4 days BEFORE Manus's post) provides the empirical bedrock for Manus's "even 128K is not enough" claim. Specific findings: GPT-3.5 refusal rate 60.29% on repeated words, Claude Opus 4 only 2.89%; degradation is non-uniform; structural coherence of haystack matters. Manus's response to context rot is the file system + recitation strategy.

### Where they all agree (the emerging consensus, mid-2025 → early 2026)
1. **Context engineering > prompt engineering** (Karpathy coined; everyone adopted)
2. **Long context is degraded, not free** (Chroma empirical, Anthropic theoretical, Manus practical)
3. **File system is the right answer for memory** (Manus L3, Anthropic just-in-time, Claude Code's CLAUDE.md)
4. **Sub-agents for narrow tasks; not for coupled work** (Manus + Anthropic Yes; Cognition Yes-but-narrow)
5. **Remove rather than add** (Manus 5 rewrites, Vercel 80% tool cut, Schmid "biggest gains came from removing")
6. **The Bitter Lesson applies to harness design** (Schmid, Lance Martin, Aakash Gupta)
7. **Error preservation > error hiding** (Manus L5, Anthropic durable execution)

---

## 5. APEX implications

For each major lesson, I map current state → opportunity → smallest viable change.

### 5.1 KV-cache discipline (Manus L1)

**Does APEX do this?** Partially. APEX has stable system prompts in agents (architect, executor, critic, etc.) but:
- `turn-checkpoint.sh` runs on every Stop event — may write to STATE.json mid-turn, causing context churn
- `context-monitor.sh` injects token-budget data — if dynamic, breaks prefix stability
- STATE.json mutations are append-only? Need to verify
- Timestamps in CONTEXT_BUDGET.json or hook outputs are a smoking gun for cache invalidation

**Smallest viable change:**
1. **Audit every hook output for timestamps with sub-minute precision.** Replace with `YYYY-MM-DD` granularity or remove.
2. **Audit STATE.json/CONTEXT_BUDGET.json/PLAN_META.json key ordering** — enforce sorted keys (deterministic JSON serialization). This is a hook addition: pre-write JSON canonicalizer.
3. **Document the prefix-stability invariant** in apex-spec.md so future changes don't break it.

**Risk:** Low. Determinism is almost always net positive.

**Concrete artifact:** A new validator hook `kv-cache-hygiene.sh` that warns when system prompts get edited or hook outputs contain non-deterministic content.

---

### 5.2 Mask, don't remove (Manus L2)

**Does APEX do this?** APEX agents are invoked by name (architect, executor, critic, etc.) — each has its own prompt and tool set. The question: when /apex:next routes to a different agent, does it switch context (remove tools) or stay in one persistent context?

**If APEX swaps agents per phase/wave:** It's already removing — violating L2.

**Smallest viable change:**
1. **Adopt tool-name prefixes** for any custom tool sets (e.g., `apex_state_*`, `apex_critic_*`).
2. **Use Hermes-style modes** at agent boundaries: when transitioning from executor → critic, prefill the response to constrain the next action.
3. **Consider a single "harness agent"** that internally orchestrates phases, rather than swapping subprocess agents. (This is closer to Cognition's view than Manus's.)

**Risk:** Medium. APEX's multi-agent design is a core pillar. Don't change without justifying.

---

### 5.3 File system as context (Manus L3)

**Does APEX do this?** YES — strongly. .apex/STATE.json, .apex/phases/*/PLAN.md, *-RESULT.json, *-CRITIC.md, VERIFY.md, TASK_MAP.md, DECISIONS.md. This is core to APEX's design.

**The gap:** Is APEX's compression **restorable**? When a phase completes and APEX moves to the next one, what context is dropped vs. retained? If RESULT.json summarizes a 100-step phase down to 200 tokens but the full trace is gone — that's not restorable. If APEX retains the trace as a file accessible to a future grep, that's restorable.

**Smallest viable change:**
1. **Audit what APEX preserves vs. summarizes.** Make sure every summary is paired with a file path to the source.
2. **Add a "restore previous phase" capability** to /apex:next that re-reads prior phase files on demand.
3. **Adopt Anthropic's pattern:** CLAUDE.md naively dropped in upfront + glob/grep for just-in-time.

**Risk:** Low. APEX is already file-heavy.

---

### 5.4 Recitation (Manus L4) — WITH WARNING

**Does APEX do this?** YES. STATE.json is re-read on /apex:next; apex-spec.md is the recitation source for /apex:self-heal. The "spec entry" referenced in the recent commits ("v8 task-boundary reset + spec entry") looks like a recitation mechanism.

**The 30% warning:** Manus moved away from continuous todo.md rewriting because it cost 30% of tokens. APEX should measure: **what fraction of tokens per turn is consumed by re-reading STATE.json / apex-spec.md / hook outputs?**

**Smallest viable change:**
1. **Measure the recitation cost.** Instrument context-monitor.sh to log "recitation tokens" as a category.
2. **If >20%, switch to the Manus 5th-rewrite pattern:** sub-agent planner that returns a structured object injected only when needed. Don't continuously re-read; only re-read at task/phase boundaries.
3. **APEX already has phase boundaries** — pin recitation there, not every turn.

**Risk:** Medium. Aggressive cutting risks "lost-in-the-middle" failures. Test on a real run.

---

### 5.5 Keep the wrong stuff in (Manus L5)

**Does APEX do this?** Partially. *-CRITIC.md retains critic findings. RESULT.json should retain failures. But does turn-checkpoint clean up "failed turn" state? Does destructive-guard sanitize?

**Smallest viable change:**
1. **Explicit failure-preservation invariant:** when a task fails, the failure trace is appended to a permanent file (e.g., .apex/phases/*/FAILURES.md) and remains accessible to all subsequent agents in that phase.
2. **Critic and verifier MUST be able to read prior failure traces** for the same task.
3. **The "anti-rationalization armor" on executors should explicitly include failure recall.**

**Risk:** Low. APEX's rigor philosophy already aligns.

---

### 5.6 Don't get few-shotted (Manus L6)

**Does APEX do this?** Probably NOT. APEX agents use highly structured templates (PLAN.md format, RESULT.json schema, CRITIC.md format). These are uniform by design — which is exactly what creates the few-shot drift risk.

**Smallest viable change:**
1. **Inject minor variation** in agent prompts (alternate phrasings of section headers, occasional reordering).
2. **Diversify RESULT.json field ordering** within deterministic bounds (this conflicts slightly with KV-cache hygiene — pick your poison).
3. **Critic agent specifically:** vary phrasing per turn to avoid templated reviews.

**Risk:** Medium. Conflicts with KV-cache stability (5.1). The right balance: stable PREFIXES (system prompts), varied USER-message content.

---

### 5.7 "Stochastic Graduate Descent" (the meta-method)

**Does APEX do this?** /apex:self-heal is the closest analog — audit→plan→schedule→execute→check rounds until convergence. This IS Stochastic Graduate Descent applied to APEX itself.

**Smallest viable change:**
1. **Schedule a quarterly /apex:self-heal pass** specifically targeted at REMOVAL — find what can be cut.
2. **Track "Manus rewrite count" analog:** how many times has each agent prompt been rewritten? Are rewrites getting SIMPLER over time? If they're getting more complex, that's a red flag.

**Risk:** None — this is meta-process.

---

### 5.8 Tool count discipline (<20 atomic, MCP via CLI)

**Does APEX do this?** APEX's tools are largely Claude Code's built-in tools (Read, Write, Edit, Grep, Glob, Bash, Task) — that's already ~7 atomic tools. Plus agent-as-tool patterns (architect, executor, etc.).

**The Manus pattern:** Don't expose MCP tools as native tools. Wrap them behind a CLI invoked via bash. This keeps tool definitions out of the prefix.

**Smallest viable change:**
1. **Inventory APEX's effective tool surface.** If <20, no change needed.
2. **If APEX has any MCP integrations, consider the CLI wrapper pattern** to keep prefixes lean.
3. **Document the <20 atomic invariant** in apex-spec.md.

**Risk:** Low.

---

### 5.9 Bitter Lesson / "get out of the model's way"

**APEX implication:** When Claude 5 / Opus 5 ships, much of APEX's scaffolding may be unnecessary. APEX should be designed to **shed structure gracefully** as models improve. Concretely:
- Don't bake in current-model failure-mode workarounds without dating them
- Tag every hook with the model it was designed around
- Periodically re-test: "is this hook still needed on the newest model?"

**Smallest viable change:** Add a `MOTIVATION` and `INTRODUCED_FOR_MODEL` field to every hook's header comment. Schedule a model-version review.

---

### 5.10 Sub-agents debate

**APEX implication:** APEX is multi-agent BY DESIGN. The Cognition critique applies: if architect and executor make conflicting assumptions because they don't share context, APEX will produce inconsistent artifacts.

**APEX's existing mitigation:** Shared SPEC.md, STATE.json, DECISIONS.md provide cross-agent ground truth. This is the Cognition-recommended "share full agent traces" pattern.

**Smallest viable change:**
1. **Audit cross-agent assumption divergence.** Run /apex:peer-review or /apex:validate-phase looking specifically for "agent A assumed X; agent B assumed Y."
2. **Make DECISIONS.md the canonical assumption log** that every agent reads first.

**Risk:** Low. APEX already has the right primitives.

---

## 6. Open questions

What Manus doesn't answer:
1. **Exact mechanics of tool-prefix masking** — they describe `browser_*` / `shell_*` but don't show the logit-mask code or which model/SDK supports it.
2. **How they detect cache invalidation** in production. Do they have telemetry? What's their target hit rate?
3. **How they balance L1 (cache stability) against L6 (diversity)** — both can't be maximized simultaneously.
4. **The full evolution history.** What did versions 1, 2, 3, 4 look like? Only version 5's deltas are publicly known.
5. **The cost of 100-agent Wide Research** vs. 1-agent sequential — they claim qualitatively faster but no comparative numbers.
6. **Failure modes of the file-system-as-context approach.** What happens when the agent writes inconsistent files? Garbage collection?
7. **Why Manus chose Claude Sonnet specifically** — vs. Opus, GPT-4, Gemini. The KV-cache numbers are Claude-specific.
8. **How "Stochastic Graduate Descent" is actually scheduled.** Do they sprint? Do they evaluate continuously? What's the rubric for "this rewrite is done"?
9. **Whether the 100:1 input:output ratio is fundamental** or specific to Manus's design. Some agents (e.g., creative writing) may be very different.
10. **Post-acquisition trajectory.** Meta's $2-3B acquisition closed Dec 2025; China blocked it April 2026 (S18). What's the current ship-ability of Manus's stack and lessons?

---

## 7. Raw citation appendix

### Direct quotes from primary source (https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus)

> "At the very beginning of the Manus project, my team and I faced a key decision: should we train an end-to-end agentic model using open-source foundations, or build an agent on top of the in-context learning abilities of frontier models?"

> "Back in my first decade in NLP, we didn't have the luxury of that choice. In the distant days of BERT (yes, it's been seven years), models had to be fine-tuned—and evaluated—before they could transfer to a new task."

> "Then came GPT-3 and Flan-T5, and my in-house models became irrelevant overnight."

> "That hard-earned lesson made the choice clear: Manus would bet on context engineering."

> "We affectionately refer to this manual process of architecture searching, prompt fiddling, and empirical guesswork as 'Stochastic Graduate Descent'. It's not elegant, but it works."

> "If I had to choose just one metric, I'd argue that the KV-cache hit rate is the single most important metric for a production-stage AI agent."

> "Cached tokens cost 0.30 USD/MTok, while uncached ones cost 3 USD/MTok—a 10x difference."

> "The average input-to-output token ratio is around 100:1."

> "As your agent takes on more capabilities, its action space naturally grows more complex—in plain terms, the number of tools explodes."

> "This allows us to easily enforce that the agent only chooses from a certain group of tools at a given state without using stateful logits processors."

> "Modern frontier LLMs now offer context windows of 128K tokens or more. But in real-world agentic scenarios, that's often not enough, and sometimes even a liability."

> "Treat the file system as the ultimate context in Manus: unlimited in size, persistent by nature, and directly operable by the agent itself."

> "If they could master file-based memory—externalizing long-term state instead of holding it in context—then their speed and efficiency might unlock a new class of agents."

> "A typical task in Manus requires around 50 tool calls on average."

> "In effect, it's using natural language to bias its own focus toward the task objective—without needing special architectural changes."

> "Agents make mistakes. That's not a bug—it's reality."

> "Erasing failure removes evidence. And without evidence, the model can't adapt."

> "Yet it's still underrepresented in most academic work and public benchmarks, which often focus on task success under ideal conditions."

> "Few-shot prompting is a common technique for improving LLM outputs. But in agent systems, it can backfire in subtle ways."

> "The more uniform your context, the more brittle your agent becomes."

> "Context engineering is still an emerging science—but for agent systems, it's already essential."

> "Models may be getting stronger, faster, and cheaper, but no amount of raw capability replaces the need for memory, environment, and feedback."

> "The agentic future will be built one context at a time. Engineer them well."

### Direct quotes from Anthropic (S1, Sep 29, 2025)

> "the set of strategies for curating and maintaining the optimal set of tokens (information) during LLM inference, including all the other information that may land there outside of the prompts."

> "As the number of tokens in the context window increases, the model's ability to accurately recall information from that context decreases."

> "models do not use their context uniformly; instead, their performance grows increasingly unreliable as input length grows."

> "this approach mirrors human cognition: we generally don't memorize entire corpuses of information, but rather introduce external organization and indexing systems like file systems, inboxes, and bookmarks to retrieve relevant information on demand."

> "If a human engineer can't definitively say which tool should be used in a given situation, an AI agent can't be expected to do better."

> "Find the smallest set of high-signal tokens that maximize the likelihood of your desired outcome."

> "treating context as a precious, finite resource will remain central to building reliable, effective agents."

### Direct quotes from Cognition (S3, Walden Yan, June 12, 2025)

> "Share context, and share full agent traces, not just individual messages"

> "Actions carry implicit decisions, and conflicting decisions carry bad results"

(Edit Apply Models example): "the edit decision-making and applying are more often done by a single model in one action"

### Direct quotes from Chroma context-rot study (S5)

> "Large Language Models (LLMs) are typically presumed to process context uniformly—that is, the model should handle the 10,000th token just as reliably as the 100th. However, in practice, this assumption does not hold."

Specific numbers: Claude Opus 4 refusal rate 2.89%, GPT-4.1 2.55%, GPT-3.5 Turbo 60.29%; 18 models tested; context lengths tested 25 → 10,000 words; 11 needle positions.

### Direct quotes from Lance Martin (S2, Oct 15, 2025)

(Karpathy framing he adopts): "Context engineering is the delicate art and science of filling the context window with just the right information"

His three-strategy framework: **Reduce / Offload / Isolate**

> "Simple, unopinionated designs often adapt better to model improvements."

### Direct quotes from Philipp Schmid Part 2 (S8, Dec 4, 2025)

> "Their biggest performance gains didn't come from adding complex RAG pipelines or fancy routing logic. The gains came from removing things."

> "We are living the Bitter Lesson. The harness you build today will likely be obsolete when the next frontier model drops."

(Peak Ji, paraphrased): "As models get stronger, we shouldn't be building more scaffolding, we should be getting out of the model's way."

### Direct quotes from Anthropic multi-agent research (S6, June 13, 2025)

> "Multi-agent system with Claude Opus 4 (lead) + Claude Sonnet 4 (subagents) outperformed single Opus 4 by 90.2% on internal research evaluation"

> "Token usage explains 80% of performance variance in BrowseComp evaluation"

> "Multi-agent systems use ~15× more tokens than standard chat"

### Direct quotes from LangChain framework (S7, July 2, 2025)

Per Cognition (cited by LangChain): "Context engineering … is effectively the #1 job of engineers building AI agents."

Framework: **Write / Select / Compress / Isolate**

Specific numbers: tool RAG improves selection accuracy 3-fold; Claude Code auto-compacts at 95% context utilization; multi-agent uses 15× more tokens.

### Direct quotes from e2b case study (S4)

(Tao Zhang, Manus co-founder): "Manus doesn't just run some pieces of code. It uses 27 different tools, and it needs E2B to have a full virtual computer to work as a real human."

(Tao Zhang): "We chose E2B because we were thinking about the future."

Specs: Firecracker microVM boot ~150ms; Docker alternative was 10-20 seconds.

### Manus production / business context (S18, S19)

- Founders: Xiao Hong (CEO), Yichao "Peak" Ji (Chief Scientist), Zhang Tao (Product Director)
- Launched March 6, 2025
- 2 million waiting list signups within a week
- Series B April 2025: ~$75M led by Benchmark; valuation ~$500M
- Revenue run rate: ~$90M (Aug 2025) → $125M (Dec 2025)
- Meta acquisition Dec 2025: $2-3B
- Blocked by China April 27, 2026
- Wide Research feature launched July 31, 2025: scales to 100 parallel sub-agents

### Hugo Bowne-Anderson / Duncan Gilchrist (S20, Dec 12, 2025)

Three principles: **Reduce / Offload / Isolate**.

(Lance Martin quote): "Over time models get better and you're having to strip away structure, remove assumptions"

(Lance Martin quote): "Often the effective context window for these LLMs is actually quite a bit lower than stated"

### Aakash Gupta (S21, Jan 7, 2026)

> "The model is commodity. The harness is moat."

References: Manus 5 rewrites in 6 months; LangChain Deep Research 4 rewrites in 1 year; Vercel removed 80% of agent tools.

### Schmid Agent Harness 2026 (S9, Jan 5, 2026)

> "Manus refactored their harness five times in six months to remove rigid assumptions."

(Vercel reference): "removed 80% of agent tools"

### Manus evolution details (from S22 / S8 / S20 — Peak Ji webinar leakage)

- 5 rewrites in 6 months
- Initial todo.md pattern consumed ~30% of all tokens; replaced with sub-agent planner returning structured object
- Tools reduced from "dozens of dynamic MCP schemas" to <20 atomic functions (bash, filesystem, code execution)
- MCP tools no longer in context window; invoked via CLI through bash
- Peak Ji: "As models get stronger, we shouldn't be building more scaffolding, we should be getting out of the model's way."

### Outbound links from the primary source

- /blog?kind=PRODUCT — Product blog category
- https://manus.im/app
- https://arxiv.org/abs/2301.00234 — In-context learning paper
- https://arxiv.org/abs/1810.04805 — BERT
- https://en.wikipedia.org/wiki/Open_information_extraction
- https://arxiv.org/abs/2005.14165 — GPT-3
- https://arxiv.org/abs/2210.11416 — Flan-T5
- https://arxiv.org/abs/2210.03629 — ReAct (likely)
- https://medium.com/@joaolages/kv-caching-explained-276520203249
- https://en.wikipedia.org/wiki/Autoregressive_model
- https://github.com/vllm-project/vllm
- https://docs.vllm.ai/en/stable/design/v1/prefix_caching.html
- https://modelcontextprotocol.io/introduction
- https://en.wikipedia.org/wiki/Retrieval-augmented_generation
- https://platform.openai.com/docs/guides/structured-outputs
- https://en.wikipedia.org/wiki/Finite-state_machine
- https://github.com/NousResearch/Hermes-Function-Calling
- https://www.promptingguide.ai/techniques/fewshot
- https://arxiv.org/abs/2405.00492 — Temperature/sampling
- https://arxiv.org/abs/1410.5401 — Neural Turing Machines

---

## Final note for orchestrator

This research surfaced a CRITICAL post-publication development: **Manus's "Lesson 4" (todo.md recitation) was effectively repealed in their 5th rewrite** because it cost 30% of tokens. This is documented only in the Peak Ji + Lance Martin webinar derivatives (S8, S20, S22), not in the original blog post that APEX would naively be working from. The post is from July 2025; by December 2025 the recommendation evolved. APEX should be especially careful before adopting the "continuous recitation" pattern wholesale — it should be confined to phase/task boundaries, not every turn.

Additionally: **Manus was acquired by Meta** for $2-3B in Dec 2025 (S18) — the source is no longer an independent voice. This doesn't invalidate the engineering, but APEX should track whether post-acquisition Manus continues publishing.
