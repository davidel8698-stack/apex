# Report 08 — Open-Source Autonomous SWE Agents
**Agent #8 of 10 — APEX Competitive Intelligence Swarm**
**Scope:** Open-source agents that attempt full SWE-bench-style autonomous bug-fixing / feature-building, plus the academic ideas these scaffolds operationalize.
**Date:** 2026-05-24

---

## 1. Scope & Methodology

This report maps the open-source autonomous SWE-agent flank that competes with APEX on the "engineering autonomous" pitch — the free-software end of the spectrum where the agent is supposed to take a GitHub issue (or a natural-language brief) and produce a passing patch with minimal human supervision. The center of gravity in 2026 is **OpenHands** (formerly OpenDevin) as the production platform, **SWE-agent / mini-SWE-agent** as the canonical research scaffold, and a constellation of academic systems (**AutoCodeRover**, **SpecRover**, **Agentless**, **Kimi-Dev**, **MAGIS**, **SWE-Search**, **Live-SWE-agent**, **Moatless Tools**) that contributed the foundational ideas every modern coding agent now uses. I also cover **GPT-Engineer** and **Smol Developer** as archeology (both effectively closed), **MentatBot** (now a hosted GitHub bot, OSS roots), **Sweep AI** (pivoted to JetBrains), and the **Devstral** open-weight model that powers many of these scaffolds.

**Research footprint:** 16 web searches and 4 deep WebFetches of primary repos / leaderboards (OpenHands GitHub, swebench.com, SWE-agent GitHub, AutoCodeRover GitHub). Cross-checks performed against arXiv papers (2407.16741 OpenHands, 2405.15793 SWE-agent, 2404.05427 AutoCodeRover, 2408.02232 SpecRover, 2407.01489 Agentless, 2509.23045 Kimi-Dev, 2403.17927 MAGIS, 2410.20285 SWE-Search, 2511.13646 Live-SWE-agent, 2412.21139 SWE-Gym), GitHub release notes, and 2026 vendor blog posts.

**What I could NOT fully verify:**
- Live SWE-bench Verified top-20 leaderboard rows — swebench.com truncates its JS-rendered table in the WebFetch view; numerical scores are sourced from third-party leaderboard aggregators and arXiv/blog citations from the vendors themselves, which I cross-referenced where possible. Treat exact ordering as *approximate*.
- OpenAI's "abandonment" of SWE-bench Verified (Feb 23 2026) is reported by `byteiota.com` summarizing an OpenAI blog post; the OpenAI post itself was not directly fetched [12].
- MentatBot's current SOTA claims are vendor-stated; no independent third-party benchmark verification surfaced.

**Data-quality caveats:**
- **Benchmark contamination is now real and admitted.** OpenAI publicly confirmed in early 2026 that frontier models can reproduce verbatim ground-truth patches for parts of SWE-bench Verified [12][14]. Many "best score" claims older than late-2025 are inflated. SWE-bench Pro (Scale AI, GPL-licensed) is the new harder benchmark; numbers there are roughly *half* of Verified.
- **Scaffold-vs-model contribution is contested.** Recent work argues the model dominates and complex agent scaffolding is overengineered [13]; Live-SWE-agent's near-SOTA result with a self-evolving minimal scaffold supports this.

---

## 2. Per-Competitor Deep Dives

### 2.1 OpenHands (formerly OpenDevin) — the de-facto open-source flagship

| Dimension | Detail |
|---|---|
| Lineage / scale | Founded March 2024 as "OpenDevin" to replicate Cognition's Devin; rebranded "OpenHands" late 2024 under All-Hands-AI org. **70K+ GitHub stars, 490+ contributors** [10]. Raised $18.8M Series A [10]. Latest v1.7.0 released **May 1, 2026** [1]; v1.6.0 (March 30, 2026) added Kubernetes support and Planning Mode beta [1]. |
| Core philosophy | "An autonomous agent is a function from event history to next event, run in a loop." Open platform for AI software developers as generalist agents — write code, interact with command line, browse web [11]. |
| Architecture | Tiny event-sourced core: stateless `Agent` emits `Actions` → `Conversation` runs the loop and stores an append-only `EventLog` → `Workspace` (local process or Docker container) executes Actions and returns `Observations` → `LLM` wrapped by LiteLLM for provider portability [3][16]. Everything else (memory compression, microagent knowledge, sub-agent delegation, security review, stuck detection) is a small auxiliary service hanging off the event stream [16]. |
| Multi-agent? | Yes. Multi-agent support with controller-spawned subagents for parallel subtasks; cloud sandboxes run many agents in parallel; MicroAgent system for specialized skills [16]. SDK allows defining agents in code and scaling to thousands [2]. |
| Spec / planning layer | **Planning Mode beta** (v1.6 / March 2026): Plan Mode generates a structured `PLAN.md` file outlining steps; agent asks clarifying questions for vague prompts; user switches to Code Mode to execute [16]. This is the closest OSS analog to APEX's `discuss-phase` + `plan-phase` split. |
| Verification / critic loop | **StuckDetector** identifies repetitive/unproductive patterns (action_observation, action_error, monologue, alternating_pattern thresholds) [3]. **LLMSecurityAnalyzer** appends a security risk field to tool calls; **ConfirmRisky** policy blocks actions exceeding configurable threshold (default: high) [3]. No first-class adversarial critic agent. |
| Memory / persistent state | Event-sourced state model with deterministic replay; immutable agent configuration; typed tool system with MCP integration [16]. Memory compression service. |
| Rollback / safety | Sandboxed Docker/Kubernetes runtime isolates execution; GitHub App integration for PR-based workflows (humans approve diffs). No native pre-task git snapshot equivalent to APEX's hidden-tree approach; rollback is "discard the PR." |
| Cost posture | Pay-per-token via user's chosen LLM provider; LiteLLM gives full provider freedom (Claude, GPT, Gemini, OpenRouter, local). No built-in budget caps documented. |
| Non-programmer accessibility | CLI + local GUI (React + REST API) + cloud deploy. Requires Docker. The cloud-hosted product is friendlier; the SDK is engineering-only. Plan Mode helps non-coders express intent. |
| Extensibility surface | **Public extensions registry**, MCP tools, MicroAgents, hook event processor (`_hook_processor` field in `LocalConversation`) [3]. Issue #9482 ("Implement Claude Code Hooks") shows ecosystem demand for APEX-like hook semantics. |
| Enterprise readiness | Enterprise edition (separate license), self-hosted GPU cloud deploys [10], Kubernetes, GitHub App. Active SOC posture not verified. |
| **What it does BETTER than APEX** | (1) **Sandboxing is first-class** — Docker/K8s isolation is the default, not an add-on; APEX runs on the host. (2) **Multi-agent at scale** — proven 1000s-of-agents cloud orchestration; APEX's wave-executor tops out at ~5–8 items. (3) **Provider portability via LiteLLM** is broader and battle-tested. (4) **Headless REST API** for programmatic submission. (5) **77.6% SWE-Bench Verified** is a real, public benchmark number; APEX has no published benchmark score. (6) **Massive community** (70K stars, 490 contributors) — APEX is one person. (7) **Vulnerability Fixer service** (March 2026) auto-remediates CVEs at scale. |
| **What APEX does better** | (1) **9-failure-mode taxonomy with named hooks per failure** — OpenHands has stuck-detector + security-analyzer but no equivalent of `phantom-check`, `destructive-guard`, `mutation-gate`, `quarantine-guard`. (2) **Auditor filesystem-quarantined from implementation code** — OpenHands has no analog; its sub-agents see everything. (3) **`SPEC_VERSION` hash + spec-to-verification ledger** with `originating_requirement_id` traceability — OpenHands' Planning Mode is descriptive, not falsifiable. (4) **Non-programmer-first design** — OpenHands assumes you can run Docker. (5) **Scale-adaptive ceremony** — OpenHands has one ceremony level. (6) **Workflow library as organizational memory** — OpenHands has MicroAgents (knowledge snippets), not pipeline recipes. |
| **What APEX should steal / learn** | (a) **Event-sourced append-only EventLog with deterministic replay** — APEX's `event-log.jsonl` is similar but not yet a replay primitive; making it replayable would unlock cheap regression testing and forensics. (b) **Stateless Agent abstraction with typed Actions/Observations** — turn APEX agents into pure functions over state; easier multi-platform porting. (c) **MicroAgents as composable knowledge units** — generalize `apex-skills/` so users can publish/subscribe to micro-agent libraries. (d) **LiteLLM wrapper** instead of per-adapter shims — would shrink APEX's multi-platform surface. (e) **Stuck-detector thresholds taxonomy** (`action_observation`, `action_error`, `monologue`, `alternating_pattern`) — APEX's circuit-breaker uses error-hash recurrence; OpenHands' multi-axis taxonomy is richer. (f) **Public extensions registry** — apex-workflows lives in-repo; a registry would amplify network effects. |
| **Threat level** | **CRITICAL.** OpenHands is APEX's nearest open-source neighbor, has 70× the community, ships weekly, and now has the spec/plan primitives APEX called out. If they add a real critic + auditor quarantine + per-failure hooks, APEX's USP narrows to "non-programmer accessibility." |

**Substantive depth:** OpenHands' architectural decision to treat the agent as a pure function over an event log is the single most consequential design choice in this domain. It makes every other property derivable: replay → forensics; pure function → multi-process scaling; append-only log → audit trail; typed tools → MCP interop. APEX's design grew organically from failure modes (each hook is a patch on a wound). OpenHands started from theory (event-sourcing + actor model) and grew features outward. The result is OpenHands has a *smaller, more principled core* but *fewer named defenses*; APEX has a richer defense surface but a *less principled core*. The right strategic move for APEX is not to compete on architectural elegance but to be the **safety/falsifiability layer on top of OpenHands-class platforms** — a posture compatible with APEX's "thin adapters" multi-platform strategy. The fact that OpenHands explicitly fielded an issue (#9482) titled "Implement Claude Code Hooks for OpenHands" [3] reveals the community is asking for what APEX already has, but inside OpenHands.

---

### 2.2 SWE-agent / mini-SWE-agent (Princeton) — the canonical research scaffold

| Dimension | Detail |
|---|---|
| Lineage / scale | Princeton NLP + Stanford; published at **NeurIPS 2024** (arXiv 2405.15793) [4][5]. SWE-agent main repo: **19.3K stars**, MIT, v1.1.0 (May 22 2025) [6]. **mini-swe-agent** (newer) explicitly "supersedes" SWE-agent: "100 lines of python… >74% on SWE-bench Verified" [6][17]. |
| Core philosophy | The **Agent-Computer Interface (ACI)** thesis: most of an agent's competence comes from designing tools the LM can reliably call — not from the LM itself. Free-flowing, generalizable, "maximal agency to the LM" [6]. |
| Architecture | Single-loop agent with YAML-configured tool surface. Core ACI commands: `open`, `goto`, `scroll`, `edit` (with a *line-aware* surrogate that prevents off-by-one bugs LMs make with raw `sed`), `search_file`, `search_dir`, `submit`. mini-swe-agent is "a prompt, executes actions using bash and subprocess.run, maintains a short history" [17]. |
| Multi-agent? | No — single loop. Multi-agent attempts (SWE-Search, MAGIS) are *forks* of this paradigm. |
| Spec / planning layer | None. The LM does all planning inline. |
| Verification / critic loop | None native; the LM is its own critic via Reflexion-style turns. |
| Memory / persistent state | Short conversation history; no episodic store. |
| Rollback / safety | Containerized execution (Docker); no git-level snapshots. |
| Cost posture | Whatever the LM costs; mini-swe-agent's minimalism keeps token usage low. |
| Non-programmer accessibility | Low. CLI for researchers. |
| Extensibility surface | YAML tool definitions. |
| Enterprise readiness | None — this is a benchmark platform. |
| **What it does BETTER than APEX** | (1) **ACI design discipline** — every tool is engineered so the LM cannot mis-use it (line-aware editor, scroll bounds). APEX gives the LM raw shell. (2) **mini-swe-agent's radical simplicity** — 100 lines, 74% SWE-bench Verified [17]; powerful argument that less scaffolding is better. (3) **Cited 1000+ times** — the academic gravity is on this side. (4) Adopted by Meta, NVIDIA, IBM, Anyscale [17]. |
| **What APEX does better** | (1) Production-grade safety (destructive-guard, mutation-gate, snapshots). (2) Multi-agent orchestration. (3) Spec/plan/verify pipeline. (4) Memory across sessions. (5) Non-programmer UX. SWE-agent is a *benchmark vehicle*, not a daily-driver. |
| **What APEX should steal / learn** | (a) **The ACI principle**: every tool APEX exposes to the LM should be engineered so misuse is structurally impossible (e.g., APEX's edit tool should be line-aware, refuse multi-region edits in one call, validate against AST). (b) **mini-swe-agent's "100-line baseline"** is a falsification test — if APEX's elaborate machinery doesn't beat the 100-line baseline on a representative benchmark, the machinery is overhead. APEX should publish its own SWE-bench-like score against mini-swe-agent. (c) **YAML-configured tool surface** instead of hardcoded hooks would lower the bar for community tool contribution. |
| **Threat level** | **MEDIUM.** Not a product threat; an *idea* threat. mini-swe-agent's 74%-in-100-lines result is an existential question for every elaborate framework — APEX included. The APEX author must have an answer for "what does the ceremony buy that mini-swe-agent doesn't?" |

**Substantive depth:** SWE-agent's ACI paper is the single most-imitated idea in coding agents [5]. Its central observation — that LMs interact with computers through interfaces designed for humans, and that *redesigning those interfaces for the LM* improves performance more than scaling the model — has been operationalized by every successor including OpenHands' typed-tool system and Aider's diff format. APEX's hook architecture is downstream of this insight: a hook is a *policy interface* that intercepts LM actions before they hit the world. But APEX never sat down and asked "what does an LM-optimized editor *look like*?" — it inherited Claude Code's shell-and-Edit primitives. The mini-swe-agent result is more uncomfortable: a 100-line Python script with bash and a short history outperforms Agentless, Moatless, and AutoCodeRover, and lands within 5 points of Anthropic's internal scaffold [13][17]. If most of an agent's competence is the model + a tiny loop, then APEX's elaborate ceremony is justified only by *what the model alone cannot do* — i.e., safety, accountability, falsifiability, persistence, multi-session memory, multi-agent coordination. That's exactly APEX's pitch, but it must be tested empirically.

---

### 2.3 AutoCodeRover (NUS / AutoCodeRoverSG) — the AST-aware spec-inferring agent

| Dimension | Detail |
|---|---|
| Lineage / scale | National University of Singapore (Abhik Roychoudhury group); arXiv 2404.05427 (April 2024) [7]. **3.1K stars**, MIT [9]; latest release v1.1.0 (September 10, 2024) — *low recent activity, but the lineage continues as SpecRover and SpecRover Pro*. |
| Core philosophy | "Code search in AutoCodeRover is a vehicle for inferring specification from program structure" [7]. Intent extraction is more important than retrieval. |
| Architecture | Two-phase: **Context Retrieval** (LLM uses code-search APIs operating on AST — `search_class`, `search_method`, `search_method_in_class`, `search_code_in_file` — not string match) → **Patch Generation** (LLM writes patch from retrieved context). Optional **fault localization via test suite** when tests available [7][9]. |
| Multi-agent? | No — single agent; SpecRover adds a reviewer agent. |
| Spec / planning layer | **Implicit spec inference** from program structure. SpecRover (ICSE 2025) adds explicit code-intent extraction with a confidence measure on patches [8]. |
| Verification / critic loop | SpecRover adds a **reviewer agent that vets patches and assigns confidence** [8]. AutoCodeRover itself relies on test-suite fault localization. |
| Memory / persistent state | None across runs. |
| Rollback / safety | Patch-level — generates a diff, doesn't apply directly. |
| Cost posture | **<$0.70 per issue** on SWE-bench Verified at 46.2% pass@1 [9]; SpecRover: $0.65 per issue with >50% improvement over AutoCodeRover [8]. |
| Non-programmer accessibility | Researcher tool. |
| Extensibility surface | Add new search APIs. |
| Enterprise readiness | Spun out as commercial SpecRover Pro (per Yuntong Zhang publications page). |
| **What it does BETTER than APEX** | (1) **AST-based code search instead of grep/string-match** — APEX (and Claude Code) rely on text-level search; AutoCodeRover's structural search retrieves *semantically* coherent units. (2) **Spec inference from structure** — the entire pipeline assumes the spec is encoded in the code itself; APEX assumes the spec is a separate `SPEC.md`. (3) **Confidence-scored patches via reviewer agent** (SpecRover) — APEX's RESULT.json has verified/unverified but no confidence scalar. (4) **Cost discipline** — published per-issue dollar costs; APEX has no equivalent published number. |
| **What APEX does better** | (1) Multi-task, multi-phase, multi-session — AutoCodeRover is single-issue. (2) Safety hooks, destructive-guard. (3) Non-programmer pipeline. (4) Spec governance (versioning, delta, traceability). (5) Workflow library. |
| **What APEX should steal / learn** | (a) **AST-based retrieval as a first-class search primitive**: APEX should expose `search_class`, `search_method`, `search_callers`, `search_callees` tools alongside grep, using tree-sitter or LSP. This is the single biggest known win in coding-agent retrieval, and APEX is leaving it on the table. (b) **Spec inference from program structure** is the *converse* of APEX's "spec-first" philosophy — but combining them yields the strongest result: spec-first when building, structure-inferred when refining. APEX's `/apex:build` vs `/apex:refine` split could exploit this: `refine` should infer the implicit spec first, then propose changes. (c) **Reviewer agent with confidence score** (SpecRover) — APEX's critic returns PASS/FAIL/NEEDS_REVIEW; adding a calibrated confidence number would let downstream pipelines route by risk. (d) **Published per-issue cost** — APEX should benchmark and publish typical cost-per-task to compete on cost transparency. |
| **Threat level** | **MEDIUM-HIGH (academic).** Not a product threat, but a *technique* threat: AST search and intent extraction are now table stakes for any agent that wants to compete on SWE-bench. The SpecRover commercial spinout could become a product threat. |

**Substantive depth:** AutoCodeRover is intellectually the closest academic system to APEX's spec-driven side. Its insight — that the *retrieval problem* in coding agents is solved by exploiting program structure (AST nodes are the natural unit of meaning, not bytes) — directly addresses a known weakness in grep-based agents: they over-retrieve junk and under-retrieve callers. APEX inherits Claude Code's text-grep paradigm and would benefit measurably from an AST-search hook backed by tree-sitter or an LSP. The SpecRover paper goes further: it explicitly tries to *reconstruct the intent* behind every patch and uses a reviewer agent to vet both the patch and the inferred spec. APEX's RESULT.json schema (verified vs unverified, tool-verified vs self-verified) is downstream of the same idea — both systems are trying to make agent claims falsifiable — but SpecRover's confidence scalar is more actionable than APEX's binary verification.

---

### 2.4 Agentless (UIUC, Lingming Zhang) — the "stop using agents" baseline

| Dimension | Detail |
|---|---|
| Lineage / scale | UIUC; arXiv 2407.01489 (July 2024), FSE 2025 [15]. MIT. Repo: OpenAutoCoder/Agentless. |
| Core philosophy | "Demystifying LLM-Based Software Engineering Agents" — *agents are overkill*. A fixed 3-phase pipeline beats most agent loops. |
| Architecture | **No agent loop.** Fixed pipeline: (1) **Hierarchical localization** (file → class/function → fine-grained edit locations); (2) **Repair** (LLM generates patch); (3) **Patch validation** (test against issue's spec) [15]. |
| Multi-agent? | No. No agent. |
| Spec / planning layer | None — the GitHub issue *is* the spec. |
| Verification / critic loop | Patch validation step; ranking across multiple candidate patches. |
| Memory / persistent state | None. |
| Rollback / safety | Patch-level; never executes the code in a stateful way. |
| Cost posture | **$0.70 per issue**, 32% on SWE-bench Lite (best of all OSS at submission); >50% on Verified with Claude 3.5 Sonnet [15]. |
| Non-programmer accessibility | Low. |
| Extensibility surface | Almost none — it's a fixed pipeline. |
| Enterprise readiness | None. |
| **What it does BETTER than APEX** | (1) **Falsifies the "more agents = better" intuition.** Adopted by OpenAI for GPT-4o/o1 reporting and DeepSeek for V3/R1 [15]. (2) **Brutally low cost** with strong scores. (3) **Reproducibility** — fixed pipeline means deterministic comparison. (4) **Skill-prior insight** — Kimi-Dev's follow-up showed Agentless-style training induces transferable skill priors that *also* make agent loops better [9 (Kimi-Dev)]. |
| **What APEX does better** | Everything that requires multi-task, multi-phase, or stateful work. Agentless is single-issue bug-fix only. |
| **What APEX should steal / learn** | (a) **The "is this task agent-shaped?" classifier**: many APEX tasks (especially under `/apex:fast` and `/apex:quick`) would run faster and cheaper through an Agentless-style fixed pipeline. APEX should have a *non-agentic fast path* for localized bug fixes. (b) **Hierarchical localization** (file → function → lines) as an explicit pipeline stage before edit, rather than letting the LM wander. (c) **Multi-candidate patch ranking** — APEX generates one patch and verifies; Agentless generates many and ranks. For high-stakes tasks this is cheap insurance. |
| **Threat level** | **LOW (product), HIGH (intellectual).** Agentless says "your framework might be cargo-culting agency." APEX must answer: when *is* the agent loop earning its keep? |

**Substantive depth:** Agentless is the most uncomfortable paper in this domain for any framework author. It demonstrates that for a large class of real GitHub issues, the entire agent-loop machinery — observation parsing, tool selection, multi-turn reasoning, scratchpad memory — adds complexity without adding skill. A three-stage fixed pipeline (localize, edit, validate) with Claude 3.5 Sonnet already cracks 50% on SWE-bench Verified [15]. The follow-up Kimi-Dev paper (2509.23045) [9] generalizes this: *Agentless-style training induces "skill priors" — localization, code edit, self-reflection — that the model carries with it into any subsequent agent loop*. The implication: complex scaffolds may be compensating for skill the model never learned. APEX should run this experiment internally: for one cycle, route all bug-fix tasks through an Agentless-style pipeline and measure pass-rate vs cost vs APEX-orchestrated. If the deltas are small, APEX has a cost-optimization opportunity (Agentless for small bugs, full pipeline for spec-driven work).

---

### 2.5 GPT-Engineer (Anton Osika) — archeology / archived 2026

| Dimension | Detail |
|---|---|
| Lineage / scale | April 2023 by Anton Osika; 55K+ stars at peak — one of the fastest-growing repos in GitHub history [18]. **Archived April 22, 2026** by owner; read-only [18]. |
| Core philosophy | "Specify what you want it to build, the AI asks for clarification, and then builds it" — first popular agent to operationalize "natural-language brief → whole codebase". |
| Architecture | Single LLM call (later, multi-step) with prompt scaffolding for clarification + code generation + improvement. Generates whole project from `prompt` file. |
| Multi-agent? | No. |
| Spec / planning layer | The prompt itself; agent asks clarifying questions before generating. |
| Verification / critic loop | None native. |
| Memory / persistent state | Re-reads project files each invocation. |
| Rollback / safety | Manual — generates new files; user reviews. |
| Cost posture | One large LLM call per generation cycle. |
| Non-programmer accessibility | **High at launch** — pioneered the "describe, then watch it build" UX. |
| Extensibility surface | Modular `steps.py`; community added many step types. |
| Enterprise readiness | None. Project pivoted commercially to **Lovable** [19][20]. |
| **What it did BETTER than APEX (historically)** | (1) **Established the "sit back and watch" paradigm** that Lovable, Claude Code, Codex inherited [18]. (2) **Clarifying-question loop before generation** — a discipline APEX's `/apex:discuss-phase` re-invented. (3) **README explicitly recommends Aider** as the maintained alternative — graceful handoff, no community resentment. |
| **What APEX does better** | Everything maintained. GPT-Engineer is no longer competitive on capability; APEX competes on staying alive. |
| **What APEX should steal / learn** | (a) **The clarifying-question loop before generation** is well-trodden — APEX's `discuss-phase` is on the right track. (b) **Graceful sunset** — when a project pivots, redirect users to the successor. The Lovable team's archive note is exemplary. (c) **From a single founder to a $300M+ Series B commercial product** — proof that an open-source autonomous agent can graduate to no-code-builder economics. APEX's commercial path (free core + paid enterprise) is *less aggressive* than Lovable's pivot but more honest to OSS users. |
| **Threat level** | **DEAD (product), HISTORICAL (paradigm).** Not a competitor; an ancestor. |

**Substantive depth:** GPT-Engineer's archive notice is the perfect cautionary tale for APEX: a 55K-star open-source autonomous SWE agent, built by one person in a few weekends, became the precursor to a multi-hundred-million-dollar commercial product (Lovable, $200M ARR per Creators AI) [19][20]. The open-source CLI was archived not because it failed but because the founders' attention is elsewhere — and "community-maintained" did not translate to ongoing development. The README's parting line — "we recommend Aider for a well-maintained CLI alternative" — is what APEX would want to write if/when it sunsets. APEX's author should plan for two scenarios: (a) APEX wins, requires enterprise stewardship to survive; (b) APEX is overtaken, and a graceful handoff to OpenHands or a successor preserves user trust. Either way, the GPT-Engineer pattern (open-source moment → commercial pivot → archive) is the most common life-cycle and should be planned for, not denied.

---

### 2.6 MentatBot (AbanteAI) — open-source CLI → hosted GitHub bot

| Dimension | Detail |
|---|---|
| Lineage / scale | AbanteAI; original CLI now archived (`AbanteAI/archive-old-cli-mentat`); product pivoted to **MentatBot** hosted GitHub bot [21][22]. |
| Core philosophy | "Github-based agent designed to write and review pull requests" — collaboration on GitHub is the surface, not the CLI [21]. |
| Architecture | Optimizes "contextual gathering, planning, editing, testing, review" stages. As a GitHub bot, it sees Github Actions output and uses it to **self-correct** [21]. |
| Multi-agent? | Internal pipeline stages; not multi-agent in the OpenHands sense. |
| Spec / planning layer | Planning stage explicit; spec = issue. |
| Verification / critic loop | Review stage; uses CI feedback for self-correction. |
| Memory / persistent state | Per-repository context, codebase understanding [22]. |
| Rollback / safety | PR-based — humans approve. |
| Cost posture | Subscription pricing (vendor-hosted). |
| Non-programmer accessibility | High via GitHub UX. |
| Extensibility surface | GitHub bot config. |
| Enterprise readiness | Available as VS Code extension + GitHub bot [22]. |
| **What it did BETTER than APEX** | (1) **SOTA on SWE-bench Lite at 38%** when launched (June 2024) [21][23]. (2) **CI-feedback loop** — uses GitHub Actions output for self-correction; APEX has no first-class CI-integration pattern. (3) **Pull-request native** workflow lowers user friction to zero. |
| **What APEX does better** | (1) Open-source vs hosted. (2) Multi-platform vs GitHub-only. (3) Local-first vs cloud-only. (4) Safety hooks. (5) Spec governance. |
| **What APEX should steal / learn** | (a) **CI-output as a first-class feedback signal**: APEX's executor reads test output, but reading GitHub Actions / CI logs of *the prior commit* as a learning signal is unexplored. (b) **PR-based collaboration surface** — APEX could ship a `/apex:open-pr` mode that pushes work to GitHub PRs with structured RESULT.json comments. |
| **Threat level** | **MEDIUM.** Niche but solid; not a direct frontal competitor. |

**Substantive depth:** MentatBot's design lesson is "meet the user where they are." GitHub is the existing workflow surface for millions of developers; making the agent a bot on PRs eliminates the *install + configure + run* friction that even Claude Code imposes. APEX's footprint (commands, hooks, agents, settings.json) is heavyweight by comparison. APEX could offer a *thin GitHub-bot personality* that runs APEX pipeline on GitHub-issue triggers and posts STATE.json + RESULT.json as PR review comments — preserving the safety/falsifiability properties while gaining MentatBot's frictionless UX. The CI-feedback loop is the genuinely novel idea here: agents that read the previous CI failure and treat it as Reflexion data are an underexplored direction in OSS.

---

### 2.7 Devstral (Mistral) — the open-weight model behind many OSS agents

| Dimension | Detail |
|---|---|
| Lineage / scale | Mistral AI; first release May 2025 (Devstral-Small-2505); Devstral 2 / Medium variants 2025–2026 [24][25][26]. |
| Core philosophy | "A new state-of-the-art open model for coding agents." Built explicitly for *agent scaffolds*, not chat. |
| Architecture | Apache-2.0 weights. Optimized via RL on tool-use trajectories with All-Hands AI (OpenHands integration) [24][25]. |
| Multi-agent? | N/A (model, not agent). |
| Performance | Devstral Small 1.0: 46.8% SWE-bench Verified; Devstral Small 1.1: 53.6%; Devstral Medium: 61.6% [25][26]. New SOTA for open weights without test-time scaling. |
| Cost posture | Open weights — run locally or via any inference host. Massive cost-per-token advantage over Claude Opus. |
| Non-programmer accessibility | Indirect — via OpenHands or any scaffold. |
| **What it does BETTER than APEX** | APEX has no model. But the *combination* Devstral + OpenHands is a fully open, locally-runnable stack that hits ~60% SWE-bench Verified at near-zero marginal cost [24]. APEX is locked to API-only models (Claude/GPT/Gemini), which costs per-token. |
| **What APEX does better** | Multi-model, multi-platform — APEX runs against whatever LLM the user already pays for. |
| **What APEX should steal / learn** | (a) **First-class Devstral integration** via OpenHands adapter — gives APEX users a "fully local, fully open" mode for sensitive codebases. (b) **Document the cost curve**: a published comparison of APEX-on-Claude-Opus vs APEX-on-Devstral-Medium-via-local would be powerful marketing for cost-conscious users. |
| **Threat level** | **LOW (direct), HIGH (ecosystem).** Devstral is not a competitor but it dramatically reduces the moat of API-locked frameworks. APEX should ride this wave, not resist it. |

**Substantive depth:** Devstral is consequential because it shifts the economics. A 60%-SWE-bench-Verified open-weight model means a developer with a 24GB GPU can run an agent loop indefinitely for the cost of electricity. Every framework that *requires* API calls is now at a structural cost disadvantage against frameworks that work with local models. APEX should explicitly support and document local-LLM mode (probably via Ollama + LiteLLM through an OpenHands adapter) and benchmark APEX-Devstral against APEX-Claude. The cost number will likely surprise users (Devstral runs at $0 per task vs Claude Opus at $5–$50 per task) and is a credible reason to choose APEX *because* it's model-agnostic.

---

### 2.8 Sweep AI — pivoted to JetBrains (was: GitHub bot)

| Dimension | Detail |
|---|---|
| Lineage / scale | Founded 2023 as GitHub bot for issue-to-PR; **pivoted to JetBrains AI coding assistant** in 2025; main repo last update Sept 2025; JetBrains plugin updated April 2026 [27]. |
| Core philosophy | (Now) "World-class AI coding agent and autocomplete for JetBrains developers." |
| Architecture | Originally: issue → context retrieval (FAISS/vector) → planner → coder → PR. Now: IDE-embedded autocomplete + agent [27]. |
| Multi-agent? | Originally yes (planner/coder split). |
| **Threat level** | **LOW.** Pivoted out of APEX's space. |

**Substantive depth (brief — not a direct competitor anymore):** Sweep is a case study in why the autonomous-GitHub-bot business model is hard. Issue-to-PR sounds magical in a demo but the failure modes (wrong fix, scope-creep, repeated comment threads) made the unit economics painful. The team's pivot to a JetBrains IDE plugin is rational: IDE-side agents have tighter feedback loops, smaller blast radius, and a clearer pricing surface. APEX should note this — pure autonomous-PR-bot is a *narrow* niche, and Sweep's pivot suggests the open-source GitHub-bot patch-generator market is being absorbed by IDE-native agents (Cursor, Cline, Windsurf) and commercial PR bots (GitHub Coding Agent, Devin, Genie).

---

### 2.9 Smol Developer (smol-ai) — archeology / paradigm seed

| Dimension | Detail |
|---|---|
| Lineage / scale | swyx (Shawn Wang) / smol-ai, May 2023; "first library to let you embed a developer agent in your own app." Low recent commit activity; smol-ai org now ships unrelated projects (smolagents at HuggingFace is a different lineage). |
| Core philosophy | **Human-in-the-loop, prompt-as-source**: the markdown prompt *is* the source code; AI is used "as long as it adds value — once it gets in your way, take over the codebase with no fuss" [28]. |
| Architecture | Whole-program synthesis from markdown spec → file plan → file-by-file generation with debugger script for diagnostics. |
| **Threat level** | **DEAD.** Historical. |

**Substantive depth:** Smol Developer's lasting contribution is the **"prompt-as-source-of-truth"** doctrine — the idea that the canonical artifact is the human-readable spec, and the generated code is rebuilt from it. APEX's `SPEC.md` + `SPEC_VERSION` hash + `SPEC_DELTA.json` are direct intellectual descendants. The other contribution is the **"AI as long as it adds value"** norm — explicitly designing for the human to take over without ceremony. APEX's `discuss-phase` and `walkthrough` reflect this. Smol Developer is no longer a product but the design DNA persists across the field.

---

### 2.10 MAGIS / SWE-Search / Live-SWE-agent / Moatless / Kimi-Dev / SWE-Gym — the academic frontier (consolidated)

These are research systems, not products, but their ideas drive the next generation of open-source agents. Each gets a focused dive because the **ideas are what APEX needs to absorb**, not the products.

**MAGIS** (NeurIPS 2024, arXiv 2403.17927) [29]: Four-role multi-agent framework — Manager, Repository Custodian, Developer, QA Engineer. 13.94% SWE-bench resolution rate, an 8× improvement over plain GPT-4. Lesson for APEX: *role specialization with separated responsibility* (custodian vs developer vs QA) is empirically the right decomposition, and APEX already maps to this (architect / test-architect / executor / critic / verifier). MAGIS validates APEX's structure but achieves it with cheaper coordination overhead.

**SWE-Search** (ICLR 2025, arXiv 2410.20285) [30]: Adds **Monte Carlo Tree Search** plus iterative refinement on top of an agent loop. Value Agent + Discriminator Agent debate. The result: agents that can *backtrack* and explore alternatives instead of running a linear chain. Lesson for APEX: APEX's `wave-executor` is strictly forward-pass; introducing MCTS-style backtracking ("try wave A, evaluate, if poor try wave B") is a known win on hard problems and currently absent.

**Live-SWE-agent** (arXiv 2511.13646, Nov 2025) [31]: **Self-evolving** scaffold — starts with bash and writes its own tools on the fly as needed. 79.2% SWE-bench Verified with Claude Opus 4.5, 45.8% on SWE-Bench Pro, leading all open-source [13][31]. Lesson for APEX: APEX's hooks/skills/workflows are *pre-defined*; an agent that *grows its own skills mid-run* and writes them back to `apex-skills/` for future sessions is a research direction APEX has the substrate for (it already has a skills directory and a learnings.md accumulator). The Live-SWE result *also* validates that minimal scaffolds + self-evolution beats elaborate pre-built scaffolds.

**Moatless Tools** [32]: "Hobby project" by Albert Örwall that achieves **70.8% SWE-bench Verified at $0.63/instance with Claude 4 Sonnet** [32]. Pre-defined workflow rather than agent loop — Agentless-adjacent. Lesson: cost-per-task discipline is a competitive axis APEX is not yet on.

**Kimi-Dev** (arXiv 2509.23045) [9 (Kimi-Dev)]: **60.4% SWE-bench Verified with an open-source workflow model**, training-data approach: Agentless-style RL induces "skill priors" (localization, code edit, self-reflection, verification) that transfer into agent loops. Lesson: the skill the agent needs can be *trained in*, not just scaffolded. This is the most important model-side advance of 2025.

**SWE-Gym** (ICML 2025, arXiv 2412.21139) [33]: Training environment with 2,438 real-world Python instances + executable runtime + tests + natural-language tasks. Released to the OSS community. Lesson: APEX could publish its own *pipeline benchmark* (a set of 50–100 multi-phase, multi-week project briefs with expected outcomes) and let other frameworks compete on it. This would be APEX-as-benchmark-author, not just APEX-as-framework — a strong defensive moat.

**AgentLess + Kimi-Dev hybrid** as the future workflow: Kimi-Dev shows you can take an Agentless-style fixed pipeline, train a model on its trajectories, and *then* drop the trained model into a full agent scaffold for a final boost. APEX's `apex-learnings.md` is a primitive precursor — capturing per-session learnings — but training a model on those learnings is the obvious next step (a model fine-tuned on the APEX framework's own RESULT.json + CRITIC.md history would be a unique asset).

| **Collective threat level** | **HIGH (academic / intellectual).** Every one of these papers operationalizes an idea APEX should consider — AST search, MCTS backtracking, self-evolution, skill-prior training, cost discipline, training-environment moats. The product threat is low because none of these are products. The technique threat is severe: any commercial open-source agent (OpenHands, future Devin-clone) that incorporates 2–3 of these techniques becomes harder to compete with. |

---

## 3. Cross-cutting patterns in this domain

1. **Scaffold ceiling is being approached.** mini-swe-agent at 74% Verified in 100 lines [17], Live-SWE-agent at 79.2% with a self-evolving minimal scaffold [13][31], Anthropic's internal scaffold at ~81% — the gap between "tiny scaffold" and "elaborate scaffold" is narrowing. The field's center of gravity is shifting from scaffold engineering to **model training for agent skills** (Kimi-Dev, Devstral, R2E-Gym). APEX must answer: what is the unique value of elaborate scaffolding when the model can do it alone?

2. **Benchmark contamination is now admitted.** OpenAI publicly stopped reporting SWE-bench Verified scores in Feb 2026 after confirming contamination [12][14]. SWE-bench Pro (multi-language, GPL-licensed, contamination-resistant) is the new standard. Any APEX claim of "SOTA" must use Pro, not Verified.

3. **AST/structural retrieval has won the retrieval debate.** AutoCodeRover and successors showed AST-based code search beats grep [7]; OpenHands and SWE-agent are moving to LSP/tree-sitter tool primitives. Frameworks still relying on text-grep retrieval are leaving accuracy on the table.

4. **Event-sourced state is becoming standard.** OpenHands' append-only EventLog + deterministic replay [16], SWE-agent's trajectory logs, Live-SWE-agent's runtime-mutation traces — every serious scaffold now treats agent state as an event stream, not a mutable object. APEX's `event-log.jsonl` is on the right side of this; making it *replayable* would close the gap.

5. **Cost-per-task is now a published metric.** AutoCodeRover ($0.70), SpecRover ($0.65), Moatless ($0.63), Agentless ($0.70) [7][8][15][32]. APEX has no equivalent published number — a competitive blind spot.

6. **Skill-prior training is the model-side answer.** Kimi-Dev shows that training a model on Agentless-style trajectories induces transferable skill priors usable by any subsequent scaffold [9 (Kimi-Dev)]. APEX's `apex-learnings.md` is the right kind of artifact to seed such training.

---

## 4. Where this domain collectively beats APEX

1. **Published benchmark numbers.** Every system here has a SWE-bench Verified score; APEX has none. This is a credibility gap.
2. **Sandboxed execution is default.** OpenHands' Docker/K8s runtime, AutoCodeRover/Agentless's patch-only output. APEX runs on the host.
3. **AST-based retrieval primitives** — APEX uses grep; the field uses tree-sitter/LSP.
4. **Local-model economics.** Devstral + OpenHands runs fully local; APEX is API-locked in practice.
5. **Academic gravity.** SWE-agent's ACI, AutoCodeRover's spec inference, Agentless's pipeline minimalism, Reflexion — all peer-reviewed at top venues; APEX is *engineering* without academic publication.
6. **Massive communities.** OpenHands 70K stars / 490 contributors; APEX is one author.
7. **Event-sourced replay.** OpenHands' deterministic replay enables forensics, regression testing, A/B scaffold comparison — APEX's event log is descriptive, not replayable.
8. **Cost discipline.** Published $/task numbers create competitive transparency APEX cannot match.
9. **Self-evolving scaffolds** (Live-SWE-agent) are at the research frontier; APEX's scaffold is static.
10. **Training-data approach** (Kimi-Dev, SWE-Gym, R2E-Gym): the model can be improved for the framework, not just the framework for the model.

---

## 5. Where APEX collectively beats this domain

1. **Named-failure-mode hooks.** Phantom-check, destructive-guard, mutation-gate, quarantine-guard, circuit-breaker — none of these have equivalents in OpenHands, SWE-agent, or AutoCodeRover. OpenHands has a stuck-detector and security-analyzer; nothing else has even those.
2. **Auditor filesystem-quarantine** — the auditor never sees implementation code, only tests. No OSS competitor does this.
3. **Multi-session memory architecture** (three-tier + dream-cycle). OSS agents are single-issue or single-session; APEX is multi-month.
4. **Spec governance** — `SPEC_VERSION` hash, `SPEC_DELTA.json`, `originating_requirement_id` traceability. No OSS competitor.
5. **Dual-mode philosophy** (collaborator vs replacement based on user expertise) — unique design discipline.
6. **Non-programmer accessibility** — OSS agents assume you can run Docker, debug Python, and read tracebacks. APEX's `/apex:help` (free-text navigator), `/apex:walkthrough`, `/apex:resume-work` target users who cannot.
7. **Workflow library as organizational memory** (`apex-workflows/`) — closest analog is OpenHands MicroAgents, which are knowledge snippets, not pipeline recipes.
8. **Self-healing loop with two-consecutive-clean-rounds stop criterion** — no OSS analog.
9. **Multi-platform via thin adapters** — OpenHands is itself the platform; APEX runs on Claude Code, Cursor, Codex, Gemini, etc.
10. **Cross-AI peer review pipeline** (`/apex:peer-review`) — unique manual workflow.

---

## 6. Strategic recommendations for APEX

**Priority 1 (existential):** Publish a SWE-bench Pro score for APEX-on-Claude-Opus-4.7. Without a benchmark number, APEX cannot enter the conversation that OpenHands, Live-SWE-agent, Kimi-Dev, and AutoCodeRover are in. Run it; publish it; iterate. The author can use OpenHands' evaluation harness or mini-swe-agent's setup to bootstrap. *Note: target SWE-bench Pro, not Verified, due to confirmed contamination on Verified [12][14].*

**Priority 2 (technique gap):** Adopt **AST-based code search** as a first-class tool. APEX should expose `search_class`, `search_method`, `search_callers`, `search_callees` backed by tree-sitter or LSP — alongside grep. This is the single biggest known retrieval win [7] and is currently absent.

**Priority 3 (cost gap):** Publish APEX's typical cost-per-task on a fixed benchmark (50 SWE-bench Pro tasks). Then benchmark APEX-on-Devstral-Medium (local, free per token) vs APEX-on-Claude-Opus and publish the comparison. Cost-conscious users will switch to APEX *because* it's model-agnostic.

**Priority 4 (architecture):** Make `event-log.jsonl` **deterministically replayable** following OpenHands' EventLog pattern [16]. This unlocks: cheap regression testing, A/B comparison of hook configurations, forensics replay, and a learning corpus for future fine-tuning.

**Priority 5 (defense):** Add a **non-agentic fast path** modeled on Agentless [15] — for localized bug fixes, run Localize → Edit → Validate without the full pipeline. Use a classifier to route; measure cost/quality vs full APEX. This is APEX's answer to "is the elaborate ceremony justified?"

**Priority 6 (community):** Open a public **APEX extensions/skills registry** mirroring OpenHands' extensions repo [16]. Let third parties publish hooks, skills, and workflows. Network effects are how OpenHands hit 70K stars; APEX needs the same accumulator.

**Priority 7 (technique):** Borrow **OpenHands' stuck-detector axes** (`action_observation`, `action_error`, `monologue`, `alternating_pattern`) [3] and integrate into APEX's circuit-breaker. APEX's recurring-error-hash detector is one-dimensional; OpenHands' is multi-dimensional.

**Priority 8 (technique):** Borrow **SpecRover's confidence-scored reviewer** [8]. Replace APEX's PASS/FAIL/NEEDS_REVIEW with PASS/FAIL/NEEDS_REVIEW + calibrated confidence. Downstream phases can then route by risk.

**Priority 9 (technique):** Add **multi-candidate patch ranking** (Agentless [15]) for high-stakes tasks: generate N patches, validate each against tests, rank by `tests_passed × confidence`. Cheap insurance.

**Priority 10 (long-game):** Publish APEX's pipeline-benchmark (50–100 multi-phase project briefs with expected outcomes) as the **APEX-Bench** training/evaluation environment, mirroring SWE-Gym [33]. Become the benchmark author, not just the framework author. This creates a moat — competitors must compete on APEX's terms.

**Priority 11 (sunset planning):** Document APEX's *sunset playbook* now (per the GPT-Engineer archive pattern). Identify the "if APEX is overtaken, here's the migration path" successor: most likely OpenHands + APEX skills shimmed onto it. Trust is built by planning the failure case.

---

## 7. Sources & citations

1. OpenHands releases page — https://github.com/All-Hands-AI/OpenHands/releases (v1.6.0 March 30 2026; v1.7.0 May 1 2026)
2. OpenHands marketing site — https://www.openhands.dev/
3. OpenHands stuck-detection / security / hooks — https://github.com/OpenHands/OpenHands/issues/9482 ; https://docs.openhands.dev/sdk/api-reference/openhands.sdk.conversation ; https://github.com/OpenHands/software-agent-sdk/blob/main/openhands-sdk/openhands/sdk/conversation/impl/local_conversation.py
4. SWE-agent NeurIPS 2024 paper — https://arxiv.org/abs/2405.15793
5. ACI as "most-imitated idea" — https://dev.to/truongpx396/swe-agent-deep-dive-build-your-own-guide-ade
6. SWE-agent GitHub — https://github.com/SWE-agent/SWE-agent
7. AutoCodeRover paper — https://arxiv.org/pdf/2404.05427 ; https://arxiv.org/html/2404.05427v1
8. SpecRover ICSE 2025 — https://arxiv.org/abs/2408.02232 ; https://abhikrc.com/pdf/ICSE25.pdf
9. AutoCodeRover GitHub (37.3% Lite / 46.2% Verified / <$0.70) — https://github.com/AutoCodeRoverSG/auto-code-rover ; Kimi-Dev paper — https://arxiv.org/abs/2509.23045 ; https://arxiv.org/html/2509.23045v2
10. OpenHands community stats & funding — https://www.spheron.network/blog/deploy-openhands-gpu-cloud/ ; https://vibecoding.app/blog/openhands-review
11. OpenHands paper (arXiv 2407.16741) — https://arxiv.org/abs/2407.16741
12. OpenAI stopped reporting SWE-bench Verified Feb 23 2026 — https://byteiota.com/openai-abandons-swe-bench-verified-59-flawed-tests/ ; OpenAI primary post — https://openai.com/index/why-we-no-longer-evaluate-swe-bench-verified/
13. Live-SWE-agent / scaffold-ceiling thesis — https://agentmarketcap.ai/blog/2026/04/11/live-swe-agent-open-source-scaffold-swe-bench-2026 ; https://arxiv.org/abs/2511.13646
14. SWE-bench Pro vs Verified contamination analysis — https://www.morphllm.com/swe-bench-pro ; https://www.morphllm.com/swe-benchmark
15. Agentless paper — https://arxiv.org/abs/2407.01489 ; https://github.com/OpenAutoCoder/Agentless ; FSE 2025 PDF — https://lingming.cs.illinois.edu/publications/fse2025.pdf
16. OpenHands SDK paper (arXiv 2511.03690) — https://arxiv.org/html/2511.03690v2 ; OpenHands product update March 2026 — https://openhands.dev/blog/openhands-product-update---march-2026 ; OpenHands extensions registry — https://github.com/OpenHands/extensions
17. mini-swe-agent — https://github.com/SWE-agent/mini-swe-agent ; https://www.decisioncrafters.com/mini-swe-agent-100-line-ai/ ; https://mini-swe-agent.com/latest/
18. GPT-Engineer GitHub (archived April 22 2026) — https://github.com/AntonOsika/gpt-engineer
19. Lovable history / GPT-Engineer pivot — https://www.taskade.com/blog/lovable-history ; https://en.wikipedia.org/wiki/Lovable_(company)
20. Lovable revenue & growth — https://www.productgrowth.blog/p/how-lovable-dev-hacked-their-growth ; https://thecreatorsai.com/p/lovable-growth-secrets-and-costs ; https://menlovc.com/perspective/software-creation-for-all-leading-lovables-330m-series-b/
21. MentatBot SOTA SWE-bench Lite announcement — https://mentat.ai/blog/mentatbot-sota-coding-agent
22. MentatBot product info — https://mentat.ai/ ; https://github.com/AbanteAI ; https://marketplace.visualstudio.com/items?itemName=AbanteAI.mentat
23. Dissecting SWE-bench leaderboards (Profiles & architectures) — https://arxiv.org/abs/2506.17208 ; https://arxiv.org/html/2506.17208v2
24. Devstral × OpenHands integration — https://openhands.dev/blog/devstral-a-new-state-of-the-art-open-model-for-coding-agents ; https://github.com/SWE-bench/experiments/pull/228
25. Devstral Small 1.1 / Medium scores — https://mistral.ai/news/devstral-2507
26. Devstral primary docs — https://mistral.ai/news/devstral ; https://huggingface.co/mistralai/Devstral-Small-2505
27. Sweep AI status & JetBrains pivot — https://github.com/sweepai ; https://github.com/sweepai/sweep ; https://plugins.jetbrains.com/plugin/26275-sweep-ai
28. Smol Developer — https://github.com/smol-ai/developer ; https://justcall.io/ai-agent-directory/smol-ai-developer/
29. MAGIS NeurIPS 2024 — https://arxiv.org/abs/2403.17927 ; https://proceedings.neurips.cc/paper_files/paper/2024/file/5d1f02132ef51602adf07000ca5b6138-Paper-Conference.pdf
30. SWE-Search ICLR 2025 — https://arxiv.org/abs/2410.20285 ; https://proceedings.iclr.cc/paper_files/paper/2025/file/a1e6783e4d739196cad3336f12d402bf-Paper-Conference.pdf
31. Live-SWE-agent paper — https://arxiv.org/abs/2511.13646 ; https://arxiv.org/html/2511.13646v3 ; https://github.com/OpenAutoCoder/live-swe-agent
32. Moatless Tools — https://github.com/aorwall/moatless-tools ; analysis — https://medium.com/@te2be/coding-agents-open-source-approaches-on-swe-bench-074cc28c5bb0
33. SWE-Gym ICML 2025 — https://arxiv.org/abs/2412.21139 ; https://github.com/SWE-Gym/SWE-Gym ; Apple ML — https://machinelearning.apple.com/research/training-software ; R2E-Gym COLM 2025 — https://arxiv.org/abs/2504.07164
34. Aider modes / architect-editor — https://aider.chat/docs/usage/modes.html ; https://aider.chat/2024/09/26/architect.html ; https://aider.chat/docs/git.html
35. Reflexion paper — https://arxiv.org/abs/2303.11366 ; OpenReview — https://openreview.net/pdf?id=vAElhFcKW6
36. SWE-bench leaderboards aggregator — https://www.swebench.com/ ; https://llm-stats.com/benchmarks/swe-bench-verified ; https://epoch.ai/benchmarks/swe-bench-verified
