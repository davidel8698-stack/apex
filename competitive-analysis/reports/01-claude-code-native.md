# Report 01 — Claude-Code-Native Frameworks
**Agent #1 of 10 — APEX Competitive Intelligence Swarm**
**Scope:** Frameworks, methodologies and skill-packs that run *on top of* Claude Code (Anthropic's CLI) and use its hooks / agents / slash-commands / skills / plugins / MCP as their substrate.
**Date:** 2026-05-24

---

## 1. Scope & Methodology

### What I covered
This report covers the **direct architectural competition** to APEX — frameworks that, like APEX itself, sit on top of Claude Code and try to turn it into a disciplined engineering system. I cover the 10 frameworks on the seed list plus **5 I discovered during research that turned out to be more dominant than the seeds** (Superpowers, gstack, GSD, Everything Claude Code, the Anthropic-official plugin marketplace itself). I also cover the **community critique layer** — the Hacker News "Framework Wars" thread, "The Framework Trap" essay, and the brutal Ruflo independent audit — because the APEX author needs to know not just who is winning but *which way the wind is blowing on whether any of this is even a good idea*.

### Effort
- **19 distinct web searches** (above the 15-search bar)
- **6 deep WebFetches** of primary repos and high-signal third-party reviews (above the 4-fetch bar)
- Cross-checks against GitHub repos, npm releases, the official Anthropic plugin marketplace, the official Anthropic Agent Skills docs, the Ruflo independent audit gist, the "Framework Trap" essay, and the "Framework Wars" Substack/HN discussions.

### What I could not verify
- **Star counts drift weekly** in this space. I report figures from the source nearest in date to today (2026-05-24), but figures may be 2–10% stale by the time this is read. Where two sources gave different numbers I note both.
- **The "150,000 → 174,000 → 204,000" Superpowers star trajectory** is reported by three different secondary sources at different dates. The GitHub repo fetch returned **204k stars** as the freshest data point [3]; other sources gave 124k [16] and 174k [13]. *unverified* — the 204k figure is sourced from a single fetch that may have over-counted; treat as "150–200k range".
- **Internal usage of CCPM cutting shipping time in half** is a vendor claim from Ran Aroussi (creator) [4] and has no third-party verification.
- **Claude-Flow / Ruflo's "84.8% solve rate on SWE-bench"** [22] is a vendor-published benchmark and is contradicted by the Roman Roman independent audit [6][7] — treat as *unverified*.

### Notable data-quality caveats
- Several "framework wars" articles published in March–May 2026 already contradict each other on star counts because growth in this category is explosive — Superpowers grew from 0 to 150k+ in seven months [13].
- The Ruflo/Claude-Flow audit [6][7] is the single most important data point in this whole domain and *every other claim about Claude-Flow's capabilities must be discounted by it*.
- BMAD-METHOD has multiple community ports to Claude Code (PabloLION, aj-geddes, 24601, darthpelo, terryso) [11]; the "main" BMAD-METHOD repo is IDE-agnostic and not Claude-Code-native by itself, but the community has aggressively forked it onto Claude Code skills/plugins. I treat the canonical bmad-code-org/BMAD-METHOD as the competitor since the forks are downstream.

---

## 2. Per-Competitor Deep Dives

### 2.1 Superpowers (obra/superpowers) — the gorilla in the room

| Dimension | Detail |
|---|---|
| Lineage / scale | Created October 2025 by Jesse Vincent (Prime Radiant, ex-Perl-pumpking, Request Tracker creator). **~200k stars in 7 months** (124k cited by [16] in April, 174k by [13] in May, 204k per fresh GitHub fetch [3]). Current version **v5.1.0** (2026-05-04) [3]. Accepted into the official Anthropic Claude Code marketplace 2026-01-15 [13]. |
| Core philosophy | "Discipline over model upgrades." Imposes rigorous methodology on the existing model rather than hoping for a smarter one [13]. Quote: *"Rather than seeking a smarter model, Jesse Vincent has demonstrated that imposing rigorous methodology on an existing model produces better results than letting a superior model work without constraints"* [13]. |
| Architecture | Ships as **14 markdown skills** that install to `~/.claude/skills/` [3][13]. No code, no daemon. Six "major" skills enforce the workflow; 8 supporting skills round out testing, git, code review, parallel dispatch. |
| Multi-agent | Yes — via `dispatching-parallel-agents` and `subagent-driven-development` skills. Pattern: a coordinator agent owns the plan; fresh subagents are spawned per task with clean 200k context windows [3][14]. |
| Spec / planning | `brainstorming` skill **refuses to write code until clarifying questions are asked**. `writing-plans` breaks features into 2–5 minute atomic tasks [3][13]. |
| Verification | `test-driven-development` skill enforces RED-GREEN-REFACTOR and **deletes code written before tests exist** [3][14]. `requesting-code-review` + `receiving-code-review` form a two-stage review (spec compliance, then code quality). `verification-before-completion` blocks premature "done" claims. `systematic-debugging` is a 4-phase root cause process [3]. |
| Memory / state | Per-subagent context isolation via `using-git-worktrees`. No formal cross-session memory layer — relies on git history and plan files [3]. |
| Rollback / safety | Git-worktree isolation is the safety net. No hook-level rollback / pre-task snapshots [3]. |
| Cost posture | Subagent-driven development is **inherently cheaper** than monolithic conversations because each subagent burns a fresh budget that is discarded on completion. No explicit cost tracking. |
| Non-programmer accessibility | **Designed for developers.** Vocabulary is "TDD," "git worktrees," "PR review." A non-programmer would bounce off in 30 seconds. |
| Extensibility surface | Skills are pure markdown — anyone can add one. Includes a meta `writing-skills` skill. Cross-runtime: Claude Code, Cursor, Codex CLI, Codex App, Factory Droid, Gemini CLI, OpenCode, GitHub Copilot CLI [3][13]. |
| Enterprise readiness | MIT licensed, used by Simon Willison and named in his coding workflow [13]. Anthropic blessing via marketplace acceptance. No SLA. |
| **What it does BETTER than APEX** | (1) **Brand and mindshare** — 200k stars dwarfs anything APEX could realistically hit. (2) **Multi-CLI day-one support** — 8 harnesses out of the box vs APEX's "thin adapters" aspiration. (3) **Brutal TDD enforcement that actually deletes code** — APEX has test-architect with veto but does not auto-delete. (4) **Radical simplicity** — 14 markdown files is the whole framework. APEX's 11 commands + 8 agents + 16 hooks + skills is materially heavier. (5) **Anthropic-marketplace presence** [3][13] — distribution channel APEX does not have. |
| **What APEX does better** | (1) **Named failure-mode taxonomy** — Superpowers has no equivalent to APEX's 9-failure model with one hook per failure. (2) **Filesystem-quarantined auditor** — Superpowers' code review runs in the same context that sees the code; APEX's auditor sees only test files. (3) **Pipeline orchestration** — APEX has `/apex:next`, a stateful pipeline brain; Superpowers is skill-triggered and forgets between sessions. (4) **STATE.json / event-log control plane** — Superpowers has no equivalent; relies entirely on git. (5) **Self-healing loop with two-consecutive-clean stop criterion** — no Superpowers analog. (6) **Hooks for destructive-guard / phantom-check / mutation-gate** — Superpowers has none. (7) **Non-programmer positioning** — Superpowers is explicitly for developers. |
| **What APEX should steal / learn** | (a) **The "TDD enforcement deletes code" mechanism** — turn `test-deletion-guard` into `pre-implementation-test-guard` that deletes implementation code if no failing test exists in the diff. (b) **Skill-as-markdown radical simplicity** — APEX should consider whether some of its agents could be skills instead, with a much shorter ramp. (c) **Multi-runtime marketing-first design** — Superpowers led with 8-harness support; APEX's adapters should be promoted as a headline feature, not a footnote. (d) **Apply for Anthropic marketplace inclusion** — distribution moat. |
| **Threat level** | **CRITICAL.** Superpowers is the default "what should I install" answer in 2026. Every new Claude Code user discovers it before APEX. It is also a *cleaner* answer to APEX's pitch for the developer segment — APEX must double down on what Superpowers structurally cannot do (non-programmer accessibility, named failure modes, falsifiable RESULT.json contracts, filesystem-quarantined auditor). |

**Deep-dive narrative.** Superpowers is the existential threat in this domain. Its growth curve is unprecedented for a Claude-Code-native project — 0 to 200k stars in 7 months, official Anthropic marketplace blessing in three months, and Simon Willison endorsement before that [13][3]. The framework's design philosophy is the inverse of APEX's: where APEX adds layers (hooks + agents + commands + state files + a control plane), Superpowers strips down to 14 markdown skills and trusts Claude Code's native skill-discovery to do the orchestration. The TDD-enforcement-deletes-code mechanic is so brutal it feels like a parody of strict engineering, but reviewers cite it as exactly the reason it works [14] — it creates a *tripwire that the model cannot rationalize past*, much like APEX's phantom-check hook. The Achilles heel: it bounces off non-existing-tests projects ("the TDD enforcement fights you constantly" [14]), and OpenCode users report skill-explosion problems where everything triggers and the framework "loads unnecessary skills and causes it to over-engineer" [14]. This is the opening APEX has: scale-adaptive classifier could solve both, but APEX has to ship visibility first.

---

### 2.2 gstack (garrytan/gstack) — the YC president's Claude Code stack

| Dimension | Detail |
|---|---|
| Lineage / scale | Open-sourced by Garry Tan (CEO of Y Combinator) in early 2026. **~97k stars, 14.5k forks** as of 2026-05-15 [15]. Growing ~900 stars/day [15]. |
| Core philosophy | Model Claude Code as a **23-person engineering team** — CEO, Designer, Eng Manager, Release Manager, Doc Engineer, QA, Security Officer (OWASP+STRIDE), etc. [15] |
| Architecture | 23 opinionated skills as slash commands [15]. Workflow: think → plan → build → review → test → ship → reflect [15]. |
| Multi-agent | Yes — but **role-based**, not parallel-execution. The agents are persona prompts that each own a phase; output of one feeds the next [15]. |
| Spec / planning | The CEO and Eng Manager personas own this. Plan-mode-first. |
| Verification | Reviewer persona + QA persona that "opens a real browser" + Security Officer that runs OWASP/STRIDE audits [15]. |
| Memory / state | Slash-command-level; no formal state machine. |
| Rollback / safety | None hook-level. Standard git workflow. |
| Cost posture | Not addressed. |
| Non-programmer accessibility | **For founders, not non-programmers.** Tan claims ~810× his 2013 LOC pace [15], which presumes he can read the code. |
| Extensibility surface | Markdown skills; trivially fork-able. Works across 7 AI coding agents [15]. |
| Enterprise readiness | MIT, but it's "Garry's personal stack" — not built for teams. |
| **What it does BETTER than APEX** | (1) **Founder-celebrity distribution** — Garry Tan is a megaphone APEX cannot match. (2) **Role-based personas at scale** — 23 named roles vs APEX's 8 core + 4 specialist agents. (3) **Single-author opinionation** — coherent voice, no spec to defer to. (4) **Real-browser QA** — APEX does not run Playwright by default. |
| **What APEX does better** | (1) **Stateful pipeline orchestration** — gstack is "23 skills you can call"; APEX has `/apex:next` that actually moves the project forward. (2) **Falsifiable RESULT.json** — gstack roles report in prose. (3) **Self-healing loop, scale-adaptive classifier, named failure modes** — none in gstack. (4) **Multi-platform (not just Anthropic + 6 others)** — APEX adapters include Google Antigravity which gstack does not. |
| **What APEX should steal / learn** | (a) **Founder-celebrity-as-distribution** — if the APEX author can get any non-programmer-author celebrity to publicly use APEX, that's the gstack playbook. (b) **23 roles is a lot but it's marketing-legible** — "30 specialists" reads better than "8 + 4." (c) **"Real browser QA" as a named pillar** — APEX's UI phase has 6-pillar Design Contract but doesn't headline browser execution. |
| **Threat level** | **HIGH.** Less threatening than Superpowers because it's explicitly Garry Tan's personal setup, not a community project. But the distribution moat (YC founder mailing list, YC Twitter) makes it the default for the entire YC ecosystem, and YC ships ~250 startups/year. |

**Deep-dive narrative.** gstack is what happens when a celebrity dogfoods. The repo's growth (97k stars [15]) is almost entirely network-effect from Garry Tan's audience, not from inherent superiority over BMAD or Superpowers. The framework itself is fairly thin — 23 markdown skills with role personas — and its productivity claims ("3 production services, 40+ features in 60 days, while running YC full-time" [15]) are unfalsifiable but plausible because logical LOC understates AI inflation. The most APEX-relevant feature is the **role specialization with downstream output handoff** — the CEO persona's output becomes the Eng Manager's input. APEX's roundtable / debate features already do this for irreversible decisions, but APEX could borrow the *named-role-per-phase* clarity that gstack achieves. The biggest threat is that gstack normalizes "Claude Code + a markdown skill pack" as the canonical stack, leaving frameworks with state machines and hooks (APEX) looking baroque by comparison. APEX must counter with the "named failure modes" pitch — gstack has no answer for what happens when the QA persona hallucinates a passing test.

---

### 2.3 GSD / Get-Shit-Done (gsd-build/get-shit-done) — context engineering at scale

| Dimension | Detail |
|---|---|
| Lineage / scale | Created December 2025 by Lex Christopherson ("glittercowboy") under TÂCHES brand. **~59–64k stars** depending on source date [10][12]; current v1.42.3 (2026-05-16) [12]. 2,100+ commits, 138 contributors, 57 releases in ~4 months [10]. Note: repo recently relocated to "GSD Redux" [12]. |
| Core philosophy | "Light-weight meta-prompting, context engineering and spec-driven development" [10]. Treats context window as a managed resource [10]. |
| Architecture | Atomic-plan execution in fresh subagent contexts. Coordinator stays at 30–40% context usage while subagents do heavy lifting in clean 200k windows [10]. |
| Multi-agent | Yes — subagent dispatch model very similar to Superpowers. |
| Spec / planning | Spec-driven, breaks work into atomic plans before execution [10]. |
| Verification | Atomic plans with automatic git commits create work trail; no formal critic loop [10]. |
| Memory / state | Specs + git history. |
| Rollback / safety | Git commits per atomic plan = de-facto rollback. |
| Cost posture | The core pitch is *cost-via-context-discipline* — keeping main context at 30–40% avoids the long-session degradation curve [10]. |
| Non-programmer accessibility | Devs only — vocabulary is "atomic plans," "subagent dispatch," "context rot." |
| Extensibility surface | 14 CLI runtimes supported [10]: Claude Code, OpenCode, Gemini CLI, Codex, Copilot CLI, Cursor, Windsurf, Augment, Trae, Qwen Code, Hermes, CodeBuddy, Cline, Antigravity, Kilo. |
| Enterprise readiness | Used at Amazon, Google, Shopify, Webflow [10]. |
| **What it does BETTER than APEX** | (1) **Multi-CLI breadth (14 runtimes)** beats APEX's adapters list. (2) **Single-purpose clarity** — "stop context rot" is a memorable one-liner. (3) **Adoption velocity** — 0 to 60k stars in 5 months, FAANG dogfooding. (4) **Context-as-resource framing** — APEX has a context-budget hook but does not market context engineering as its core. |
| **What APEX does better** | (1) **State persistence beyond context** — STATE.json + event-log.jsonl outlive any context window; GSD has none. (2) **Falsifiable verification** — APEX's auditor + RESULT.json; GSD just trusts the subagent output. (3) **Named failure modes + hooks** — destructive-guard, phantom-check, mutation-gate; GSD has none. (4) **Non-programmer mode** — GSD does not even attempt this. |
| **What APEX should steal / learn** | (a) **"Context rot" is a brilliant phrase** — APEX should adopt and re-use it. (b) **Atomic plans with automatic commits** is what APEX's `/apex:fast` should do by default — currently APEX commits per task; per-atomic-plan is finer-grained. (c) **14 runtimes** is the multi-platform bar to clear. |
| **Threat level** | **HIGH.** Most direct philosophical competitor for the "discipline + context management" niche APEX wants. Already adopted at FAANG. |

**Deep-dive narrative.** GSD is the most APEX-like framework in this report — it shares APEX's "spec-driven + context-managed + subagent dispatch" worldview almost exactly. The differences are revealing: GSD chose **minimalism and one mechanism** (atomic-plan-in-fresh-subagent), where APEX layered **9 mechanisms for 9 failure modes**. GSD's growth curve [10] suggests minimalism is winning the discovery battle. APEX's depth wins on day-7 when something goes wrong — GSD has no rollback, no hook layer, no critic — but day-1 conversion goes to GSD. The relocation to "GSD Redux" [12] suggests the project is mid-refactor, which is a small window APEX can exploit if it moves on multi-runtime support immediately. The phrase "context rot" [10] should be lifted directly into APEX's positioning copy: it is the most evocative single phrase in the entire 2026 Claude-Code ecosystem.

---

### 2.4 BMAD-METHOD (bmad-code-org/BMAD-METHOD) — the ancestor APEX borrowed from

| Dimension | Detail |
|---|---|
| Lineage / scale | "Breakthrough Method for Agile AI Driven Development." Active since 2025. **~47.9k stars, 5.6k forks** [8][1]. Current **v6.7.1** (2026-05-18) on stable; v6.2.2 (2026-03-26) on releases pages [1][2]. |
| Core philosophy | Agile-team-simulation with formal phases. Multi-agent IDE-agnostic. |
| Architecture | **34+ workflows, 12–19 specialized agents** [2][8][9]. Modular: BMM (Method Module for software dev), BMB (Builder Module for custom agents), CIS (Creative Intelligence System), BMVCS (Version Control System), TEA (Test Architecture) [2]. Step-file architecture, document sharding, web bundles [2]. |
| Multi-agent | Yes. Includes **Party Mode** — `bmad-party-mode` command pulls multiple agents into a single conversation; BMad Master orchestrator picks relevant agents per message; agents respond in character, agree/disagree, build on each other's ideas [17]. |
| Spec / planning | Phase 1 Analysis → Phase 2 Plan → Phase 3 Solutioning → Phase 4 Implementation [2]. Replaces "adversarial reviewer" with quality-rubric synthesis pass emitting both HTML and markdown reports [2]. PRD and Product Brief rebuilt as `bmad-prd` and `bmad-brief` with 3 first-class intents (Create / Update / Validate) [1]. |
| Verification | **TEA (Test Engineering Architect)** — standalone BMAD module; expert agent "Murat" with 9 workflows; gate decisions PASS/CONCERNS/FAIL/WAIVED; P0–P3 prioritization (probability × impact); risk-based test plans, evidence-backed go/no-go decisions [18]. New `bmad-investigate` skill — forensic, evidence-graded case files for bug triage, incident RCA, code exploration [1]. |
| Memory / state | New `.decision-log` pattern tracks all decisions from start through workflows, allowing easier continuation or later modification [1]. Auto Memory saves learned patterns across sessions [9]. |
| Rollback / safety | Not documented as a primary feature; relies on git. |
| Cost posture | Medium article claims "90% token savings" via v6 [2]; not independently verified. |
| Non-programmer accessibility | Implicit yes — "empowering everyone, not just those who can pay" [8] — but vocabulary ("PRD," "epic," "scrum master") assumes business-stakeholder literacy at minimum. |
| Extensibility surface | BMad Builder Module lets users create custom agents [2]. Distributed via `npx bmad-method install` [1][9]. Multiple community Claude Code skill-pack ports (PabloLION, aj-geddes, 24601, darthpelo, terryso) [11]. |
| Enterprise readiness | "Used by solo developers and Fortune 500 engineering teams worldwide" [1]. |
| **What it does BETTER than APEX** | (1) **TEA's gate decisions (PASS/CONCERNS/FAIL/WAIVED)** are more nuanced than APEX's binary PASS/FAIL/NEEDS_REVIEW. (2) **34+ workflows** is more than APEX's 30+ workflow library — and BMAD's workflows are more polished/longer-tenured. (3) **Decision-log pattern** is more durable than APEX's DECISIONS.md. (4) **Party Mode** is the original of `/apex:roundtable` and is more flexible (open-ended conversation). (5) **Modular architecture (BMM/BMB/CIS/BMVCS/TEA)** lets users adopt pieces; APEX is more monolithic. (6) **Scale-adaptive intelligence** [8] predates APEX's classifier. (7) **9 specialized skills + 15 workflow commands** via BMAD-for-Claude-Code skill pack [9]. |
| **What APEX does better** | (1) **9-failure-mode taxonomy with named hooks** — BMAD has no equivalent. (2) **STATE.json + event-log control plane** — BMAD relies on document sharding. (3) **Filesystem-quarantined auditor** — BMAD's reviewer sees implementation. (4) **Destructive-guard, phantom-check, mutation-gate hooks** — BMAD relies on agent behavior. (5) **Self-healing loop** with two-consecutive-clean stop criterion. (6) **Non-programmer-first design** — BMAD is built around SDLC ceremony that assumes PM/architect/dev fluency. (7) **Pipeline orchestration** via `/apex:next` is more directive than BMAD's workflow library which is more user-driven. |
| **What APEX should steal / learn** | (a) **PASS/CONCERNS/FAIL/WAIVED** gate granularity — adopt directly. (b) **Decision-log as primitive** — APEX should add this alongside DECISIONS.md. (c) **`bmad-investigate` forensic case file** — pattern is exactly what APEX's `/apex:forensics` should output. (d) **Modular architecture** — APEX should explore whether commands could be installed à la carte the way BMAD's BMM/BMB/CIS modules can. (e) **Quality-rubric synthesis (replacing adversarial reviewer)** [2] — interesting alternative to pure critic; investigate. |
| **Threat level** | **HIGH.** Largest installed base of any spec-driven framework. The closest philosophical match to APEX — same "agile + multi-agent" worldview. APEX literally borrowed from it (acknowledged in the briefing). The fact that BMAD is *still* growing (v6.7.1 active) means APEX is competing with a moving target, not capturing leftover share. |

**Deep-dive narrative.** BMAD-METHOD is APEX's intellectual parent, and the briefing explicitly acknowledges this. The honest assessment: BMAD is **further along the polish curve** but APEX is **further along the failure-mode-hardening curve**. BMAD's TEA module with the PASS/CONCERNS/FAIL/WAIVED gate granularity [18] is a strictly better verification primitive than APEX's binary system. Party Mode [17] is the live model for APEX's `/apex:roundtable` and is more open-ended (free conversation vs structured turns). The v6 modular split (BMM/BMB/CIS/BMVCS/TEA) suggests an evolutionary path APEX should consider — APEX could ship an "APEX Core" with optional "APEX Build," "APEX Refine," "APEX UI" modules rather than a single monolith. The risks for APEX: BMAD's hookless, document-based approach (it relies on Claude Code's native discovery) means it sidesteps the cross-platform hook compatibility problems APEX hits when running on Windows, in parallel sessions, or via marketplace delivery (a known sharp edge in the Claude Code hook system per [21]). Where APEX wins decisively: the 9-failure-mode taxonomy and the named-hook-per-failure mapping has no BMAD equivalent. APEX should defend this aggressively and steal the PASS/CONCERNS/FAIL/WAIVED granularity within a single release.

---

### 2.5 SuperClaude (SuperClaude-Org/SuperClaude_Framework) — the polished veteran

| Dimension | Detail |
|---|---|
| Lineage / scale | Author: NomenAK (now SuperClaude-Org). **20.4k–22.9k stars** (sources vary; recent fetch shows 22.9k [4]). Current **v4.3.0** (2026-03-22) [4]. Python pipx install. |
| Core philosophy | "Meta-programming configuration framework that transforms Claude Code into a structured development platform through behavioral instruction injection and component orchestration" [4]. |
| Architecture | **30 slash commands, 20 specialized agents, 7 behavioral modes** [4]. 8 MCP servers (Tavily, Context7, Sequential-Thinking, Serena, Playwright, Magic, Morphllm-Fast-Apply, Chrome DevTools) [4]. |
| Multi-agent | Yes — via tool orchestration. Personas: Architect, Security Engineer, Frontend Architect, PM Agent, Deep Research Agent, etc. [4][5]. |
| Spec / planning | `/brainstorm`, `/implement`, `/test`, `/research` slash commands [4]. |
| Verification | **Confidence-based validation** in Deep Research: source credibility 0.0–1.0, coverage completeness, synthesis coherence; minimum threshold 0.6, target 0.8 [4]. ReflexionMemory for error learning [4]. |
| Memory / state | `/load` and `/save` commands for session persistence. ReflexionMemory built-in. Optional Serena MCP for session persistence [4]. Case-based learning in Deep Research [4]. |
| Rollback / safety | **The hooks system was removed in v3 because it was getting complex and buggy; planned redesign for v4** [20]. v4.3.0 adds general security hardening but no rollback feature documented [4][20]. |
| Cost posture | Not addressed primarily. |
| Non-programmer accessibility | Explicitly **for developers and contributors** [4]. Requires reading PLANNING.md, TASK.md, KNOWLEDGE.md before sessions [4]. |
| Extensibility surface | pipx install model. **Currently Claude Code only**; v4 may add other AI coding assistants [20]. TypeScript plugin system planned for v5.0 [20]. v4.2+ ships as native Claude Code plugin via marketplace [23]. |
| Enterprise readiness | MIT licensed; not enterprise-targeted. |
| **What it does BETTER than APEX** | (1) **30 slash commands** vs APEX's 11. (2) **Confidence-scored verification (0.0–1.0)** is more granular than PASS/FAIL/NEEDS_REVIEW. (3) **MCP server ecosystem integration (8 servers built in)** — APEX does not pre-wire MCP. (4) **ReflexionMemory built-in** is the closest existing implementation to APEX's Memory Synthesis dream-cycle. (5) **Polish + documentation** — extensive docs site, 12+ contributors. |
| **What APEX does better** | (1) **APEX has hooks; SuperClaude removed theirs because they were buggy** [20] — major regression. (2) **APEX has destructive-guard, phantom-check, mutation-gate** — SuperClaude has none. (3) **APEX has state files, control plane, event log** — SuperClaude has slash-command session save/load only. (4) **APEX has multi-CLI adapters today** — SuperClaude is Claude-Code-only with "may" for v4. (5) **APEX's named failure-mode taxonomy** — SuperClaude has none. (6) **APEX's `/apex:roundtable` and `/apex:_debate`** for irreversible decisions — SuperClaude has none. |
| **What APEX should steal / learn** | (a) **Confidence-scored verification (0.0–1.0)** — adopt as a third dimension alongside PASS/CONCERNS/FAIL/WAIVED. (b) **Pre-wired MCP servers** — APEX should ship a curated MCP set (Context7 docs, Tavily search, Playwright, etc.) as `apex-mcp-defaults`. (c) **ReflexionMemory pattern** — explicit study target for the Memory Synthesis agent. (d) **Persona library size (20)** — APEX could expand specialists to roughly match. (e) **TypeScript plugin system** (planned v5) — track and plan APEX's response if SuperClaude ships first. |
| **Threat level** | **MEDIUM.** SuperClaude lost momentum to Superpowers and gstack in 2026. Removing hooks in v3 was a serious self-inflicted wound [20]. APEX's hook layer is the moat against SuperClaude. |

**Deep-dive narrative.** SuperClaude was the "framework you installed" in 2025 — large, polished, well-documented. In 2026 it has been outflanked by Superpowers (which trades depth for radical simplicity), GSD (which trades depth for context discipline), and gstack (which trades depth for celebrity distribution). The most damning data point is buried in the docs: **the hooks system was removed in v3 because it was getting too complex and buggy** [20]. This is exactly the failure mode APEX's destructive-guard / phantom-check / mutation-gate / circuit-breaker layer is engineered against — and SuperClaude could not solve it. APEX should treat this as direct validation of its hook-centric approach and study what SuperClaude got wrong (the cross-platform sharp edges around configuration loading, state management, Windows compatibility per [21]). Conversely, SuperClaude's **confidence-scored verification** (0.0–1.0 with explicit thresholds) [4] is a more sophisticated rubric than APEX's three-state outcome, and APEX should adopt it. The pre-wired MCP server set (8 useful ones) [4] is also a competitive blind spot for APEX — Claude Code users in 2026 expect MCP to be part of the stack.

---

### 2.6 Everything Claude Code / ECC (Affaan Mustafa) — the harness-comparison comprehensive

| Dimension | Detail |
|---|---|
| Lineage / scale | Built by Affaan Mustafa (San Francisco). **~100K+ stars, 13k forks** [19]. Won the Anthropic × Forum Ventures hackathon at Cerebral Valley in September 2025 [19]. Current v1.9.0 (March 2026) [19]. |
| Core philosophy | "The most complete open-source framework for making AI coding agents behave consistently across tools" [19]. Harness standardization. |
| Architecture | **28 specialized agents, 119 skills, 60 commands** [19]. AGENTS.md-at-root convention + cross-platform hook adapter [19]. |
| Multi-agent | Yes — 28 agents across language ecosystems. |
| Spec / planning | Skill-driven, not phase-driven. |
| Verification | AgentShield security scanning included [19]. |
| Memory / state | Memory persistence layer described [19]. |
| Rollback / safety | AgentShield + security scanning. Not deeply documented. |
| Cost posture | "Cuts costs 60%" per vendor claim [19] — *unverified*. |
| Non-programmer accessibility | Dev-targeted. |
| Extensibility surface | Selective-install architecture (v1.9.0 [19]). Supports Claude Code, Cursor, Codex, OpenCode from a single repo [19]. |
| Enterprise readiness | MIT, free. Hackathon-winner pedigree [19]. |
| **What it does BETTER than APEX** | (1) **119 skills, 60 commands** — APEX has far fewer. (2) **AGENTS.md-at-root** is a cleaner cross-platform standard than CLAUDE.md per-platform. (3) **Cross-platform hook adapter** solves the Windows / parallel-session / marketplace-delivery hook problem APEX has not solved at scale. (4) **Selective install** — users pick what to install. (5) **AgentShield security scanning** built in. |
| **What APEX does better** | (1) **APEX's named failure-mode hooks** are more rigorous than ECC's generic AgentShield. (2) **Filesystem-quarantined auditor** — ECC has none. (3) **APEX's STATE.json + event-log** — ECC has memory persistence but not an event log. (4) **Pipeline orchestration via `/apex:next`** — ECC is a skill library, not an orchestrator. |
| **What APEX should steal / learn** | (a) **AGENTS.md-at-root convention** — adopt as APEX's universal config marker. (b) **Cross-platform hook adapter** — if ECC has solved the Windows hook compatibility problem, study their implementation. (c) **Selective install** — APEX should offer minimal/standard/full installation profiles. (d) **AgentShield-style continuous security scanning** as a hook. |
| **Threat level** | **HIGH.** ECC's "harness standardization" pitch directly threatens APEX's "multi-platform via thin adapters" positioning — ECC already has it working at 100k-star scale. |

**Deep-dive narrative.** ECC is the framework APEX should fear if APEX wants to own the "multi-platform" story. Where APEX positions multi-platform as a thin-adapter aspiration, ECC has shipped it at 100k-star scale with an AGENTS.md-at-root convention and an actual cross-platform hook adapter [19]. The hackathon-winner pedigree (Anthropic × Forum Ventures, September 2025 [19]) gave it legitimacy APEX cannot match. The single biggest steal-worthy item: **AGENTS.md-at-root**. The single biggest defensive concern: APEX's adapter story needs to be one-shot-installable, not a documentation page.

---

### 2.7 BMAD-Method as Claude Code Plugin (community ports)

Multiple Claude Code-native ports of BMAD exist [11]: **PabloLION/bmad-plugin** (10+ specialized agents and 30+ skills), **aj-geddes/claude-code-bmad-skills** (~221 stars — auto-detection, memory integration, slash commands, <5-second install), **24601/BMAD-AT-CLAUDE** (early port), **darthpelo/claude-plugin-bmad** (holacracy roles variant), **terryso/claude-bmad-skills** (plugin-marketplace-installable) [11]. Together these are the "BMAD-on-Claude-Code" segment.

**Threat level**: **MEDIUM.** Individually small, but collectively they expand BMAD's reach into the Claude Code skill marketplace and reduce friction. APEX should consider: a Claude Code marketplace plugin for APEX (one-command install) is now table stakes — Superpowers, BMAD (via ports), gstack, GSD, SuperClaude (v4.2+) all have one [13][3][15][10][23][11].

---

### 2.8 claude-flow / Ruflo (ruvnet/ruflo) — the cautionary tale

| Dimension | Detail |
|---|---|
| Lineage / scale | Renamed from Claude-Flow to Ruflo in January 2026 to avoid Anthropic trademark issues; npm package and CLI still claude-flow [22]. **54.6k stars** [3]. v3.6.18 (May 3, 2026) [7]. 6,000+ commits per vendor [22]. |
| Core philosophy | Multi-agent swarm orchestration with consensus, neural learning, federated comms. |
| Architecture | Orchestration Layer (MCP Server, Router, 27 Hooks) → Swarm Coordination (Queen/Topology/Consensus) → 100+ specialized agents → Memory & Learning (AgentDB, HNSW, SONA, ReasoningBank) → LLM providers [3][22]. Claimed **210–314 MCP tools, 27 hooks, 33 plugins, 12 background workers, 16 agent roles + custom types, 19 AgentDB controllers, 21 native plugins** [3][22]. |
| Multi-agent | Yes — claims hierarchical (Raft), mesh, adaptive topologies; Raft/Byzantine/Gossip/CRDT consensus [3][22]. |
| Spec / planning | SPARC mode, hive-mind intelligence, codex loop [22]. |
| Verification | Codex loop runs until completion marker or iteration cap [22]. Vendor claims 84.8% SWE-bench solve rate [22]. **All vendor verification claims independently disputed** [6][7]. |
| Memory / state | AgentDB + HNSW vector indexing (vendor claims 150–12,500× faster than brute force) [3]. SONA neural patterns [3]. |
| Rollback / safety | AIDefence plugin (prompt injection blocking, PII detection, CVE-hardened execution, path traversal prevention) [3]. |
| Cost posture | Vendor claims 30–50% token reduction; 75–80% per-session [22]. **Independent audit found framework adds 15,000–25,000 tokens of noise per session** [6][7]. |
| Non-programmer accessibility | Dev/SRE-targeted. |
| Extensibility surface | npm package, Claude Code plugin, federation, web UI (flo.ruv.io) [3][22]. |
| Enterprise readiness | Claimed; *unverified*. Repository wiki has known security audit issues [7]. |
| **What it does BETTER than APEX** | On paper: more breadth (314 MCP tools, 100+ agents). **In practice — almost nothing, per the independent audit.** |
| **What APEX does better** | (1) **APEX's tools actually execute.** The Ruflo independent audit [6][7] found ~290 of 300+ MCP tools are non-functional stubs: `agent_spawn` creates idle Map entries forever; `neural_train` ignores training data and returns hardcoded labels; `wasm_agent_prompt` echoes input unchanged; `workflow_execute` returns "Workflow not found" despite stored workflows. (2) **APEX's verification is falsifiable** (RESULT.json schema); Ruflo's metrics are hardcoded (e.g., "sleeping 352ms to simulate traditional editing, then claiming 352× faster" [6]). (3) **APEX's hooks are real shell scripts**; Ruflo's "consensus protocols" turned out to be single-process EventEmitter events with consensus-type just a string label [6][7]. |
| **What APEX should steal / learn** | (a) **Brutal honesty as a brand differentiator.** APEX should publish its own audit of itself (`/apex:health-check` already does this internally — make the output a public artifact). (b) **The Ruflo audit format itself** is a steal-worthy artifact — APEX's auditor agent should generate output in this format for any framework being compared. |
| **Threat level** | **LOW — pre-audit reputation, MEDIUM ongoing.** The maintainer has acknowledged the findings and shipped fixes in subsequent versions [7], but the audit narrative is now baked in. Ruflo's threat to APEX is mainly *brand contamination* — the audit's existence ([6] gets cited by [7][24][25]) raises the trust bar for *every* Claude-Code framework with multi-agent claims, including APEX. |

**Deep-dive narrative.** Ruflo/Claude-Flow is the most-cited example in this domain — *and* the most-disputed. The Roman Roman independent audit [6][7] is the single most important document in the Claude-Code framework ecosystem because it establishes the methodology by which all multi-agent claims should be scrutinized. The specific findings are devastating:

- ~290 of 300+ MCP tools are JSON state stubs with no execution backend [6][7]
- The 30–50% token reduction claim is achieved by *adding 15,000–25,000 tokens of noise per session* via 300+ tool definitions and duplicate `[INTELLIGENCE]` pattern injection [6]
- `agent_spawn` creates `{status: "idle"}` in a Map with no subprocess [6]
- `neural_train` returns `Math.random()` accuracy with predictions always returning "coder" [6]
- Consensus-type selection ("byzantine," "raft," "queen") stores only a string label; actual handler is identical [6]
- The auto-memory graph file is 100 MB with 719,632 duplicate edges to surface 20 unique entries [6]
- Performance "benchmarks" include sleeping 352ms to simulate traditional editing, then claiming 352× faster [6]

**The maintainer acknowledged most findings** and shipped fixes in v3.6.18 with ADR-093 covering bulk of issues, including 13 high/critical CVE packages pinned [7]. This is the right response. But the audit is the *defining narrative* for Ruflo now, and APEX must position against it: claim falsifiability (RESULT.json schema), claim phantom-check hook (detects self-incrimination patterns), claim filesystem-quarantined auditor (no implementation code visibility), claim destructive-guard (real shell hook). The Ruflo audit is a gift to APEX — it teaches the market exactly what to ask for. APEX should publish its own equivalent self-audit and make the auditor agent's output template match the audit format.

---

### 2.9 ccpm (automazeio/ccpm) — GitHub Issues as control plane

| Dimension | Detail |
|---|---|
| Lineage / scale | By Ran Aroussi / Automaze. **8.1k stars, 829 forks** [25]. |
| Core philosophy | "Issue state is project state. Comments are the audit trail" [25]. GitHub Issues as the canonical project state. |
| Architecture | 5-phase discipline: brainstorm → PRD (`.claude/prds/`) → epic (`.claude/epics/`) → task decomposition (acceptance criteria, effort, dependencies, parallelism flags) → GitHub sync (creates issues + worktrees) [25]. Up to 12 agents working concurrently per epic [25]. |
| Multi-agent | Yes — parallel via git worktrees and GitHub Issues coordination [25]. |
| Spec / planning | PRD → epic → task pipeline; "every line of code must trace back to a specification" [25]. |
| Verification | Not detailed — emphasis on traceability over automated validation [25]. |
| Memory / state | GitHub Issues + filesystem. No separate database [25]. |
| Rollback / safety | Git worktrees provide isolation. No explicit rollback mechanism [25]. |
| Cost posture | Not addressed; vendor claims cutting shipping time roughly in half [4]. |
| Non-programmer accessibility | **Developers only** — requires git, GitHub CLI, technical epic decomposition [25]. |
| Extensibility surface | Follows agentskills.io open standard. Works with Claude Code, Codex, OpenCode, Factory, Amp, Cursor [25]. |
| Enterprise readiness | MIT. Cleanly maps to team-collaboration workflows. |
| **What it does BETTER than APEX** | (1) **GitHub Issues as single source of truth** — APEX's STATE.json is a file; ccpm's state is on a SaaS the team already uses. (2) **No new tool to learn** — devs already know GitHub Issues. (3) **Multi-human + multi-agent collaboration natively** — 12 agents on one epic via worktrees. (4) **Cleaner trace** — every task is a GitHub Issue with audit trail in comments. (5) **5-phase discipline is more memorable** than APEX's 9-failure model. |
| **What APEX does better** | (1) **Verification + critic loop** — ccpm doesn't have one. (2) **Falsifiable RESULT.json** — ccpm has GitHub Issue comments. (3) **Self-healing loop** — ccpm has no equivalent. (4) **Non-programmer accessible** — ccpm requires CLI git fluency. (5) **State outside GitHub** — APEX projects can be private/offline; ccpm requires GitHub. |
| **What APEX should steal / learn** | (a) **5-phase discipline as marketing structure** — APEX should restate its pipeline in similar memorable phase terms. (b) **`.claude/prds/` and `.claude/epics/` conventions** — APEX could adopt `.apex/prds/` for parallel PRD storage. (c) **Optional GitHub Issues sync** — let APEX state mirror to GitHub Issues for teams that want it. (d) **"Issue state is project state"** — copywriting gold. |
| **Threat level** | **MEDIUM.** Strong in the "shipping team that already uses GitHub" niche; weaker for non-programmers or non-GitHub projects. |

**Deep-dive narrative.** ccpm is the most pragmatic framework in this report. It does not invent a control plane — it uses GitHub Issues, which already work, are already free, are already audited, and are already where every dev team's project state lives. The trade-off is **vendor lock-in to GitHub** and **no support for non-programmers** who would not know what a PRD or epic is. APEX's STATE.json approach is more portable and more accessible but lacks the social/auditing benefits of an issue tracker. The lesson for APEX: a **`/apex:sync-github`** command that mirrors STATE.json tasks to GitHub Issues (one-way or two-way) would close the gap for teams that want both.

---

### 2.10 claude-task-master (eyaltoledano/claude-task-master) — multi-IDE task graph

| Dimension | Detail |
|---|---|
| Lineage / scale | By Eyal Toledano. **27.2k stars** [4]. Current v0.43.1 [4]. |
| Core philosophy | "AI-powered task management you can drop into Cursor, Lovable, Windsurf, Roo, and others" [4]. Multi-IDE task-graph layer. |
| Architecture | MCP stdio server via `npx -y task-master-ai` exposing **36 tools (~21k tokens)** with configurable loading modes (all / standard 15 / core 7 / custom) [4]. |
| Multi-agent | Implicit via subtask assignment, not formal swarm. |
| Spec / planning | PRD at `.taskmaster/docs/prd.txt`; parses into numbered tasks for natural-language reference ("implement task 3") [4]. |
| Verification | Research commands ("Research JWT best practices") pull fresh context [4]. No formal review gates [4]. |
| Memory / state | `.taskmaster/` directory; tasks persist (format not specified) [4]. |
| Rollback / safety | `task-master move --ignore-dependencies` implies awareness; no transaction/rollback [4]. |
| Cost posture | Multi-provider fallback chain (Anthropic, OpenAI, Gemini, Perplexity, xAI, OpenRouter, Mistral, Groq, Azure, Ollama) [4]. |
| Non-programmer accessibility | "Small and medium teams" using AI-first editors [4]. Not specifically non-programmer. |
| Extensibility surface | MCP-server architecture. **IDE detection for 13 IDEs**: Cursor, Claude Code, Windsurf, VS Code, Roo, Cline, Kiro, Zed, Kilo, Trae, Gemini, OpenCode, Codex [4]. |
| Enterprise readiness | MIT. |
| **What it does BETTER than APEX** | (1) **13-IDE detection** is best-in-class multi-platform — beats APEX's adapter aspiration. (2) **Multi-provider model routing built in (10 providers)** — APEX has model routing but does not headline 10-provider support. (3) **Watch mode + compact output** — useful CLI UX. (4) **Optional metadata field for tasks (arbitrary JSON)** — flexibility APEX doesn't expose. (5) **Loop command with verbose mode** showing Claude's work in real-time. |
| **What APEX does better** | (1) **Verification/critic loop** — Task Master has none [4]. (2) **Falsifiable contracts** — Task Master is task-management only, not engineering discipline. (3) **Rollback** — Task Master acknowledges the risk but has no mechanism [4]. (4) **APEX is end-to-end** — Task Master is the planning layer; you still need everything else. |
| **What APEX should steal / learn** | (a) **13-IDE detection** — match or exceed. (b) **Configurable tool-loading modes (all / standard / core / custom)** — APEX should offer this for skills/agents to control context budget. (c) **Multi-provider fallback chain (10 providers)** — important as Claude pricing pressure increases. (d) **Optional metadata field** — useful for tasks. |
| **Threat level** | **MEDIUM.** Task-management-only, but the IDE-breadth play (13 IDEs) is APEX's stated direction; Task Master is already there. |

**Deep-dive narrative.** Task Master is APEX's "thin adapters" aspiration already shipped — except Task Master only covers planning, not the entire pipeline. The IDE-detection breadth (13 IDEs) [4] is genuinely impressive and is the bar APEX must clear. The MCP-server-as-distribution model is also worth studying — Task Master ships as `npx -y task-master-ai` and works from inside whatever IDE the user is in. APEX could consider an equivalent — `npx -y apex` exposing the entire APEX pipeline as MCP tools — which would let APEX *bypass the entire Claude Code skill-vs-plugin-vs-hook installation debate*.

---

### 2.11 Agent OS (buildermethods/agent-os) — the standards-injection minimalist

| Dimension | Detail |
|---|---|
| Lineage / scale | By Brian Casel / Builder Methods. **4.5k stars, 725 forks** [27]. Current v3 (January 2026) [27]. |
| Core philosophy | "Establishing and injecting standards, deferring to modern AI tools for the parts they now handle better" [27]. Lightweight; complements Claude Code/Cursor rather than replacing. |
| Architecture | 4 core operations: **Install / Discover / Inject / Shape** [27]. Markdown commands in `commands/agent-os/`. |
| Multi-agent | No. |
| Spec / planning | Plan-mode "Shape" operation creates specs aligned with discovered standards [27]. |
| Verification | Standards as soft enforcement. |
| Memory / state | Standards files persist in repo. |
| Rollback / safety | None — defers to Claude Code's built-ins. |
| Cost posture | Not addressed. |
| Non-programmer accessibility | **Business owners, operators, teams building with AI** [27]. |
| Extensibility surface | Slash commands for Claude Code (recommended); markdown reference for other tools [27]. |
| Enterprise readiness | MIT. |
| **What it does BETTER than APEX** | (1) **"Discover" operation auto-documents existing codebase patterns** — APEX has no equivalent for onboarding legacy codebases. (2) **Radical minimalism** — does one job (standards injection) and does not fight the model. (3) **Explicit "we complement, not replace" positioning** survives the "Framework Trap" critique. |
| **What APEX does better** | (1) **APEX is end-to-end discipline**; Agent OS is standards-only. (2) **APEX's hooks** — Agent OS has none. (3) **APEX's failure-mode hardening** — Agent OS does not address failures. |
| **What APEX should steal / learn** | (a) **Auto-discovery of existing patterns** — `/apex:onboard` could include a "discover & document" pass. (b) **Lean-into-complement positioning** — APEX should explicitly state what it *doesn't* try to replace (Claude Code's planner, model intelligence). |
| **Threat level** | **LOW.** Agent OS deliberately deferred to AI-coding-tool evolution; v3 narrowed scope. Not competing for APEX's space; could be a downstream library. |

**Deep-dive narrative.** Agent OS is the model of *graceful retreat*. Brian Casel acknowledged that AI coding tools have evolved and **explicitly narrowed v3's scope** to standards-only, deferring everything else to Claude Code, Cursor, etc. [27]. This is the opposite philosophy from BMAD or APEX (which try to own the whole pipeline). It is also a survival strategy in light of the "Framework Trap" critique [24]. APEX should learn the lesson: APEX should know what it *deliberately doesn't do* and say so loudly. Agent OS's "Discover" operation — auto-documenting existing codebase patterns into reusable standards — is genuinely a steal-worthy idea for `/apex:onboard`.

---

### 2.12 ClaudeLog (claudelog.com) — the docs/best-practices wiki

| Dimension | Detail |
|---|---|
| Lineage / scale | Community docs site with practical insights and techniques for Claude Code. Not a framework — a documentation wiki [28]. |
| Core philosophy | Reduce the gap between "works" and "ships production code reliably" via sharp CLAUDE.md, right permission mode, hooks, skills, cost model [28]. |
| Architecture | N/A — documentation site. |
| **Threat level** | **LOW (not a framework).** Worth noting because it shapes what new Claude Code users learn first. APEX should ensure ClaudeLog covers APEX (currently it covers SuperClaude [4]). |

---

### 2.13 awesome-claude-code (hesreallyhim/awesome-claude-code) — the curated directory

| Dimension | Detail |
|---|---|
| Lineage / scale | **44.7k stars, 3.8k forks, 1,157 commits, 329 open issues** [5]. Curated list. |
| Core philosophy | Quality, security, originality curation [5]. |
| **Threat level** | **LOW (directory).** APEX should ensure it is listed. The issue #1338 [7] (Ruflo accuracy disclaimer) shows this list takes accuracy seriously — APEX's submission must be airtight. |

---

### 2.14 wshobson/agents (Multi-harness marketplace) — the production-ready commercial-ish catalog

| Dimension | Detail |
|---|---|
| Lineage / scale | **35.9k stars, 3.9k forks** [3]. 82 plugins / 191 agents / 155 skills / 102 commands [3]. |
| Core philosophy | "One source-of-truth, five harnesses" — Claude Code + Codex CLI + Cursor + OpenCode + Gemini CLI [3]. PluginEval quality framework (static, LLM Judge, Monte Carlo) [3]. Three-tier model strategy (Opus for architecture/security, Sonnet/Haiku for ops) [3]. |
| Multi-agent | 16 orchestrators for multi-agent workflows [3]. |
| Memory | External plugin "Pensyve" for cross-session cognitive memory; not native [3]. |
| **What it does BETTER than APEX** | (1) **PluginEval quality framework with Monte Carlo testing** — APEX has nothing equivalent for skill-quality validation. (2) **Three-tier model routing built in** — more refined than APEX's planning/edit split. (3) **Harness-native generation** (not lowest-common-denominator translations) [3]. |
| **What APEX should steal / learn** | (a) **PluginEval-style quality testing** for APEX agents/hooks. (b) **Three-tier explicit model strategy** as a `/apex:model-routing` config. (c) **Harness-native generation pipeline** — when APEX adds an adapter, generate native artifacts not generic ones. |
| **Threat level** | **MEDIUM-HIGH.** Adjacent (catalog vs framework) but the engineering quality framework around it is exemplary. |

---

### 2.15 ContextForge / claude-context-forge (webdevtodayjason/context-forge) — the scaffolder

| Dimension | Detail |
|---|---|
| Lineage / scale | CLI scaffolder for Claude Code projects with full-screen Ink TUI [11]. |
| Core philosophy | Init wizard for a complete Claude Code project: settings.json wiring 8 hook events, `.claude/agents/*.md` (5 defaults), `.claude/skills/*/SKILL.md` (3 defaults), 21 commands across 6 subdirs, model frontmatter throughout [11]. |
| **What APEX should steal / learn** | The **TUI installer flow** itself — APEX's installer should match this quality bar. Auto-derives test framework, language, deploy target from stack [11]. |
| **Threat level** | **LOW-MEDIUM.** Scaffolder, not a framework. But sets the installer-quality expectation in the ecosystem. |

---

### 2.16 VoltAgent/awesome-claude-code-subagents — the subagent catalog (18.1k stars [29])

100+ specialized subagents across core dev, languages, infrastructure, quality/security, data/AI, DX, specialized domains, business [29]. Pure catalog; not a framework. **Threat: LOW** but it's the de-facto subagent gallery — APEX subagents should be listed.

---

### 2.17 Anthropic's claude-plugins-official (anthropics/claude-plugins-official) — the substrate, not the competitor

| Dimension | Detail |
|---|---|
| Lineage / scale | Official Anthropic-managed marketplace. **27k stars, 2.9k forks, 405 commits** [30]. 55+ curated official plugins + external_plugins section for community [30]. |
| Threat | **CRITICAL infrastructure shift.** This is the new distribution channel for *every* Claude Code framework, including APEX's competitors (Superpowers and SuperClaude v4.2+ are already in [13][23]). |
| **What APEX should learn** | **Get APEX accepted into the official marketplace.** Submit via the [plugin directory submission form](https://clau.de/plugin-directory-submission) [30]. Without this, APEX is one click harder to install than Superpowers / SuperClaude. |

---

### 2.18 Anthropic Agent Skills (anthropics/skills) — the spec, not the competitor

Agent Skills as an open standard (Anthropic-published), with progressive disclosure as core design principle [31]. Pre-built skills for PowerPoint/Excel/Word/PDF. Universal `SKILL.md` format. Supported across Claude.ai, Claude Code, Claude Agent SDK, Claude Developer Platform [31].

**Threat: substrate-level.** APEX must ensure its skills follow `SKILL.md` format so they're discoverable across the entire Anthropic ecosystem, not just Claude Code.

---

## 3. Cross-cutting patterns in this domain

1. **Markdown-skill-pack > installer-framework.** Superpowers, gstack, GSD all won by shipping as small markdown skill packs that work via Claude Code's native skill discovery. Heavier installer frameworks (BMAD v6 npm install, SuperClaude pipx) are losing the discovery battle even when their feature set is broader. **Implication for APEX**: the installer is friction the market resents.

2. **Multi-runtime support is now table stakes.** Task Master (13 IDEs), GSD (14 runtimes), Superpowers (8 harnesses), wshobson (5 harnesses), ECC (4 harnesses) all support multiple AI coding agents. Pure-Claude-Code-only frameworks (early SuperClaude, original BMAD) are being penalized. **Implication for APEX**: ship adapters as first-class, not footnotes.

3. **Anthropic marketplace acceptance is the new moat.** Superpowers (accepted Jan 2026), SuperClaude v4.2+, multiple BMAD ports — getting into the official `claude-plugins-official` registry is a one-click distribution advantage that competitors can no longer ignore.

4. **The "Framework Trap" critique is real and gaining mindshare.** "The Framework Trap" essay [24] and Hacker News commentary [20] argue that elaborate multi-phase frameworks "fight the model's training distribution." The author quotes Scott Logic: *"sea of markdown documents, long agent run-times and unexpected friction"* [24]. APEX must answer this directly: why is APEX's ceremony justified where others' isn't?

5. **Trust will be the next competitive axis.** The Ruflo independent audit [6][7] established that vendor claims are now subject to source-code scrutiny. Any framework claiming "consensus protocols" or "neural training" or "X% token reduction" will be audited. APEX's falsifiable RESULT.json schema and filesystem-quarantined auditor are the right posture for this world — but APEX needs to advertise them.

6. **Skill explosion is a real failure mode.** OpenCode users report that Superpowers "loads unnecessary skills and causes it to over-engineer" [14]. As skill counts grow (Superpowers 14, gstack 23, GSD 30+, BMAD-CC 9, ECC 119, wshobson 155), skill-routing becomes the next problem to solve.

---

## 4. Where this domain collectively beats APEX

1. **Discovery and distribution.** Superpowers, gstack, GSD, SuperClaude, BMAD all have orders-of-magnitude more stars and far better organic discovery than APEX. APEX is not on the official Anthropic marketplace; the others are or are about to be.

2. **Multi-runtime support already shipped.** Task Master / GSD / Superpowers / wshobson / ECC all support 4–14 IDEs/CLIs *today*. APEX's adapters are an aspiration.

3. **Celebrity authorship.** Garry Tan (YC CEO), Jesse Vincent (Perl pumpking, RT creator, Simon Willison-endorsed), Brian Casel (Builder Methods), Eyal Toledano. The APEX author has no comparable public profile in dev tools.

4. **Onboarding speed for new users.** Superpowers/gstack/GSD are 1-command installs of small markdown packs. APEX requires CLAUDE.md instructions, hook configuration, agent files, state setup.

5. **Anthropic blessing.** Superpowers + SuperClaude v4.2+ in official marketplace. APEX is not.

6. **Lower technical surface area.** Superpowers is 14 markdown files. APEX is 11 commands + 12 agents + 16 hooks + skills + state schemas. The blast radius for bugs is larger.

7. **More polished single-purpose pitches.** "TDD enforcement that deletes code" (Superpowers), "Stop context rot" (GSD), "23 roles in your Claude" (gstack) — APEX's "9 failure modes" pitch is more academic and less viral.

8. **BMAD's TEA module has more granular gates** (PASS/CONCERNS/FAIL/WAIVED with risk-based P0–P3) than APEX's binary outcome.

---

## 5. Where APEX collectively beats this domain

1. **Named failure-mode taxonomy with one hook per failure.** Nothing in this domain matches APEX's 9-failure model. Superpowers/gstack/GSD have no explicit failure taxonomy at all. BMAD has it implicitly (PM/Dev/QA roles) but not mapped to hooks. This is APEX's strongest moat.

2. **Filesystem-quarantined auditor.** Auditor sees only test files, never implementation. No other framework in this domain has this — BMAD's reviewer, Superpowers' code-review skill, SuperClaude's confidence-scored Deep Research all see implementation. APEX's design uniquely defends against the auditor-rationalization failure mode.

3. **Falsifiable RESULT.json with verified vs unverified criteria.** Closest analog is SuperClaude's confidence scores. Most others are prose reports.

4. **Hook layer is real, real shell scripts, and survives.** SuperClaude *removed* its hook system in v3 because it was too complex. Ruflo's "hooks" turned out to be EventEmitter events [6]. APEX's destructive-guard, phantom-check, mutation-gate, circuit-breaker, quarantine-guard, memory-watchdog, turn-checkpoint, session-auto-resume are real and orthogonal to model behavior.

5. **Self-healing loop with two-consecutive-clean-rounds stop criterion.** No other framework has anything comparable. ECC, BMAD, Superpowers all stop on completion claim; only APEX has a stop criterion based on *zero P0 + P1 findings two rounds in a row*.

6. **Non-programmer-first design.** Genuinely unique. BMAD's "everyone" framing is closer to "small business owner who has a PM"; gstack is "Garry Tan dogfooded"; Superpowers/GSD/SuperClaude are explicitly for developers. *Nothing else in this domain targets the non-programmer like APEX does.* This is APEX's most defensible market.

7. **Scale-Adaptive Classifier.** BMAD has "scale-adaptive intelligence" [8] but it adjusts planning depth — APEX's classifier also picks ceremony level based on tests/CI/prod/team. More dimensional.

8. **`/apex:roundtable` and `/apex:_debate`** for irreversible decisions are more structured than BMAD's free-form Party Mode.

9. **Multi-platform adapter philosophy** — Cursor, Codex, Copilot, Gemini, Windsurf, Antigravity — is broader than even GSD's 14 if APEX ships them. Currently APEX is *behind* on this; the philosophy is right but execution is incomplete.

10. **Pipeline orchestration via `/apex:next`** — single command that knows what to do next is uniquely directive. Most others are skill libraries that wait for the user to invoke them.

---

## 6. Strategic recommendations for APEX

In priority order:

### P0 — Existential (do in the next 4 weeks)

1. **Submit APEX to the official Anthropic `claude-plugins-official` marketplace** via [the submission form](https://clau.de/plugin-directory-submission) [30]. Without this, APEX is structurally disadvantaged vs Superpowers, SuperClaude, BMAD ports, gstack-on-marketplace. The submission must be airtight on quality and security — Anthropic curates.

2. **Ship a 1-command APEX install as a Claude Code plugin** (`/plugin install apex@apex-marketplace`). Currently APEX requires multi-file setup; the rest of this market is one command.

3. **Publish the APEX self-audit publicly.** Run `/apex:health-check` against APEX itself, format the output like the Ruflo audit [6], and put it on the README. The trust narrative is becoming the next competitive axis and APEX is structurally well-positioned to win it — *but only if it advertises the falsifiability*.

### P1 — Critical (next 8 weeks)

4. **Steal BMAD's PASS/CONCERNS/FAIL/WAIVED gate granularity.** APEX's binary PASS/FAIL/NEEDS_REVIEW is now the lagging implementation. Add WAIVED with explicit reason capture.

5. **Steal Superpowers' "TDD enforcement deletes code" mechanism.** Add `pre-implementation-test-guard` hook that deletes implementation code if no matching failing test exists in the diff. This is a *tripwire*, not a rule — exactly the kind of mechanism APEX's hook layer is engineered for.

6. **Steal SuperClaude's confidence-scored verification (0.0–1.0)** as a third dimension alongside the BMAD gate grades. Result: PASS/CONCERNS/FAIL/WAIVED + 0.0–1.0 confidence + verified/tool-verified/unverified — strongest verification rubric in the entire domain.

7. **Ship pre-wired MCP servers** as `apex-mcp-defaults`: Context7 (docs), Tavily (search), Playwright (browser/UI verification), Serena (session persistence). Match SuperClaude's MCP curation.

8. **Adopt the AGENTS.md-at-root convention** from ECC [19] alongside CLAUDE.md. This is the cross-platform standard the multi-runtime ecosystem is converging on.

### P2 — Differentiation (next quarter)

9. **Lead with multi-runtime in marketing.** APEX's adapter list (Cursor, Codex, Copilot, Gemini, Windsurf, Antigravity) is a feature; today it reads as an aspiration. Ship adapters one at a time, working, and add IDE-detection like Task Master's 13-IDE matrix.

10. **Adopt the phrase "context rot"** (GSD's coinage [10]) in APEX positioning. Most evocative single phrase in the 2026 Claude-Code lexicon.

11. **Add `/apex:sync-github`** that mirrors STATE.json tasks to GitHub Issues for ccpm-style team collaboration without abandoning portability.

12. **Modular install** like BMAD's BMM/BMB/CIS/BMVCS/TEA split — `apex-core` + `apex-build` + `apex-refine` + `apex-ui` + `apex-test-architect` as separately installable. Reduces objection from non-programmer users who don't need the full stack.

13. **Publish APEX as `SKILL.md`-format skills** for the Anthropic open standard [31] so they're discoverable across Claude.ai, Claude Code, and Claude Agent SDK.

### P3 — Defensive narrative

14. **Engage publicly with "The Framework Trap" critique** [24]. APEX's answer must be: "We don't add ceremony for ceremony's sake; we add **one named hook per named failure mode**, every mechanism is falsifiable, and our scale-adaptive classifier downsizes for trivial work." Without this answer, APEX is grouped with BMAD/Spec Kit/SuperClaude in the critique's target.

15. **Lean into non-programmer positioning as the unfair advantage.** *Nothing else in this market targets non-programmers.* APEX's `/apex:help` (free-text navigator), Scale-Adaptive Classifier, dual-mode philosophy, and recovery menus are the only competitive product for this segment.

16. **Publish a head-to-head Superpowers/gstack/GSD vs APEX comparison table** on the APEX site. Be brutally honest about where each wins. The Framework Wars discourse is happening; APEX must participate or be defined by others.

---

## 7. Sources & citations

1. BMAD-METHOD CHANGELOG v6.2.2 + v6.7.1 — https://github.com/bmad-code-org/BMAD-METHOD/blob/main/CHANGELOG.md
2. BMAD v6 architecture analysis (Medium) — https://medium.com/@hieutrantrung.it/from-token-hell-to-90-savings-how-bmad-v6-revolutionized-ai-assisted-development-09c175013085
3. SuperClaude / Superpowers / ruflo / wshobson primary GitHub repos (composite from WebFetches) — https://github.com/SuperClaude-Org/SuperClaude_Framework , https://github.com/obra/superpowers , https://github.com/ruvnet/ruflo , https://github.com/wshobson/agents
4. ccpm + Task Master primary repos and Ran Aroussi statement — https://github.com/automazeio/ccpm , https://github.com/eyaltoledano/claude-task-master , https://x.com/aroussi/status/1958181744601166059
5. awesome-claude-code primary repo — https://github.com/hesreallyhim/awesome-claude-code
6. Ruflo / Claude-Flow independent audit (Roman Roman gist) — https://gist.github.com/roman-rr/ed603b676af019b8740423d2bb8e4bf6
7. Ruflo issue #1514 (audit warning) + issue #1338 (awesome-claude-code listing accuracy disclaimer) + issue #1482 (security/reliability review) + issue #1375 (security audit) — https://github.com/ruvnet/ruflo/issues/1514 , https://github.com/hesreallyhim/awesome-claude-code/issues/1338
8. BMad Method overview (BMad Code site) — https://www.bmadcode.com/bmad-method/
9. BMAD for Claude Code (community port) — https://aj-geddes.github.io/claude-code-bmad-skills/getting-started.html
10. GSD framework articles and primary repo — https://github.com/gsd-build/get-shit-done , https://www.augmentcode.com/learn/gsd-58k-stars-claude-code
11. ContextForge + BMAD ports + claude-forge — https://github.com/webdevtodayjason/context-forge , https://github.com/PabloLION/bmad-plugin , https://github.com/24601/BMAD-AT-CLAUDE , https://github.com/darthpelo/claude-plugin-bmad , https://github.com/terryso/claude-bmad-skills
12. GSD repo state (relocation notice) — https://github.com/gsd-build/get-shit-done/
13. Superpowers deep dive (Anil Mathew, Medium, April 2026) — https://medium.com/@anilmathewm/i-gave-claude-code-a-brain-its-called-superpowers-and-it-has-150-000-github-stars-for-a-reason-16c4074a9209
14. Superpowers Review (andrew.ooo, April 2026) — https://andrew.ooo/posts/superpowers-agentic-skills-framework-claude-code/
15. gstack primary repo + augmentcode coverage — https://github.com/garrytan/gstack , https://www.augmentcode.com/learn/garry-tan-gstack-hits-89.7K-stars
16. Superpowers, GSD, gstack comparison (Ewan Mak, Medium) — https://medium.com/@tentenco/superpowers-gsd-and-gstack-what-each-claude-code-framework-actually-constrains-12a1560960ad
17. BMAD Party Mode docs — https://docs.bmad-method.org/explanation/party-mode/
18. BMAD TEA (Test Architect) module — https://github.com/bmad-code-org/bmad-method-test-architecture-enterprise , https://bmad-code-org.github.io/bmad-method-test-architecture-enterprise/
19. Everything Claude Code (ECC) — https://www.augmentcode.com/learn/everything-claude-code-github , https://ecc.tools/
20. SuperClaude v3 hook removal + Hacker News "The Claude Code Framework Wars" — https://news.ycombinator.com/item?id=45155302 , https://www.boolinvest.com/2025/07/superclaude-framework-developer.html
21. Claude Code hooks limits (190 things hooks cannot enforce + cross-platform sharp edges) — https://dev.to/boucle2026/what-claude-code-hooks-can-and-cannot-enforce-148o
22. Ruflo vendor benchmarks + v3 features — https://github.com/ruvnet/ruflo/wiki/Benchmark-System , https://pasqualepillitteri.it/en/news/774/claude-flow-ruflo-multi-agent-orchestration-guide
23. SuperClaude v4 plugin migration — https://github.com/SuperClaude-Org/SuperClaude_Plugin/blob/main/MIGRATION_GUIDE.md , https://github.com/SuperClaude-Org/SuperClaude_Framework/issues/419
24. "The Framework Trap" (paddo.dev) — https://paddo.dev/blog/the-framework-trap/
25. ccpm deep extraction + Ran Aroussi post — https://aroussi.com/post/ccpm-claude-code-project-management
26. Claude Code Framework Wars (Shawn McKean Substack) — https://shmck.substack.com/p/claude-code-framework-wars
27. Agent OS site + v3 — https://buildermethods.com/agent-os , https://github.com/buildermethods/agent-os
28. ClaudeLog — https://claudelog.com/
29. VoltAgent awesome-claude-code-subagents — https://github.com/VoltAgent/awesome-claude-code-subagents
30. Anthropic claude-plugins-official + submission form — https://github.com/anthropics/claude-plugins-official , https://clau.de/plugin-directory-submission
31. Anthropic Agent Skills spec — https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills , https://github.com/anthropics/skills
