# Report 06 — Spec-Driven & Planning-First Frameworks
**Agent #6 of 10 — APEX Competitive Intelligence Swarm**
**Scope:** Frameworks/tools that put a written specification (spec.md / requirements.md / .sdd / PRD) at the center of the AI-coding loop, then derive code, tests, and tasks from it — i.e., APEX's intellectual home turf.
**Date:** 2026-05-24

---

## 1. Scope & Methodology

### What I covered
I researched the eleven most-discussed spec-driven and planning-first frameworks active in May 2026: **GitHub Spec Kit, AWS Kiro, OpenSpec, Tessl, SpecDD, BMAD-METHOD, Backlog.md, SpecStory, claude-task-master, Cosine Genie, GSD ("Get Shit Done")**, plus secondary references to **Spec Kitty** (a Spec Kit fork) and **Google Antigravity 2.0** (briefly — it has spec-like artifacts via `.gemini/antigravity/brain/` but lives more naturally in Report 02). I also fetched the seminal "spec-driven critique" literature to understand where the methodology itself is weakest.

### Searches & fetches performed
- **17 web searches** across Google Search results (current as of May 2026)
- **5 deep WebFetch passes** of primary sources: `github.com/github/spec-kit`, `kiro.dev`, `github.com/MrLesk/Backlog.md`, `openspec.pro`, `marktechpost.com` 2026-05-08 comparative survey, `tessl.io` blog (Sept 2025 launch piece)
- Cross-checked vendor claims against MarkTechPost and Augment Code analyst surveys (both May 2026), DEV.to and Medium third-party reviews, and the explicitly critical Augment Code piece "What spec-driven development gets wrong" plus Kent Beck's published critique referenced therein.

### What I could NOT fully verify
- **Tessl's pricing, funding round details, and Framework GA status.** As of the source I fetched (Sept 2025 launch blog), Framework was in *closed beta* and Registry in *open beta*; I have **no May-2026 GA confirmation** and tag this *unverified*.
- **GSD's exact star count.** Sources cite ~59,600–61,000 depending on whether they count the original `gsd-build/get-shit-done` repo or the "GSD Redux" successor. I use ~60k as a midpoint with the caveat that the project repo split is itself a yellow flag *unverified-precision*.
- **SpecStory's enterprise pricing.** Not published; sales-team-only. *unverified*.
- **Cosine Genie's spec workflow as a distinct surface.** Genie does multi-agent task decomposition from a ticket/PRD, but I could not find a separate "spec layer" product the way Tessl or Kiro frames one. I treat Genie as adjacent rather than core to this domain.
- **OpenSpec star count.** Vendor page does not display it; one secondary review claims "highest overall scoring in a Feb 2026 independent eval across 13 categories" but I did not find that eval directly.

### Data-quality caveats
- Almost every comparative article I found is published by a competitor in the space (Augment Code, BCMS, MarkTechPost paid placements). I have weighted independent DEV.to / Medium hands-on reviews and primary repos more heavily.
- "Spec-driven" has become a marketing term in 2026; some tools tagged SDD only carry a folder of markdown templates with no enforcement. I have flagged these.
- I avoided the temptation to write up Cursor "Plan Mode" and Claude Code's `CLAUDE.md` as SDD — those are covered in Reports 02 and 01 respectively. This report focuses on tools whose **primary** product surface is specifications.

---

## 2. Per-Competitor Deep Dives

### 2.1 GitHub Spec Kit — the de-facto open standard for SDD

| Dimension | Detail |
|---|---|
| Lineage / scale | Open-sourced by GitHub in Sept 2025; **v0.8.13** released **May 21, 2026**; **~105,000 GitHub stars, ~8,000 forks** as of mid-May 2026 [1][2][14]. Most-starred SDD-specific repo in existence. |
| Core philosophy | "Code is now the last-mile output." Specifications are the persistent artifact; code is regenerable scaffolding [1][2]. |
| Architecture | Python CLI (`uvx specify init`) that scaffolds a `.specify/` directory + per-feature `specs/<feature>/` folders. Slash-commands installed into the host agent (Claude Code, Copilot, Cursor, Gemini CLI, Codex CLI, Qwen, Tabnine, etc. — **30+ agents** supported) [1][14]. |
| Multi-agent? | No internal multi-agent system. **Hosts** the user's existing agent; provides structured prompts that any agent can execute. |
| Spec / planning layer | Seven-command sequence: `/speckit.constitution → /speckit.specify → /speckit.clarify → /speckit.plan → /speckit.analyze → /speckit.tasks → /speckit.implement` [1][14]. Optional `/speckit.checklist` for custom quality validation. |
| Verification / critic loop | **Yes** — `/speckit.analyze` is a cross-artifact consistency pass that validates `spec.md`, `clarifications`, `plan.md`, `tasks.md`, and `constitution.md` alignment. Constitution violations are auto-flagged as **CRITICAL** and block implementation [14]. This is genuine SDD enforcement, not a marketing claim. |
| Memory / persistent state | `.specify/memory/constitution.md` (principles), `specs/<feature>/` per-feature artifacts including `data-model.md`, `api-spec.json`, `research.md`, `quickstart.md`. No session checkpointing — relies on git. |
| Rollback / safety | Git-only. Spec Kit creates a feature branch per spec (`001-create-feature`) so rollback = branch delete. No pre-task snapshot equivalent. |
| Cost posture | Free, open-source (MIT). Spec Kit itself is zero-cost; the agent it drives bills you. |
| Non-programmer accessibility | **Medium.** Requires `uvx` / Python install. Constitution & spec authoring are markdown-based, so a non-coder can write them, but the slash-command muscle memory and feature-branch git flow are not non-programmer-friendly. |
| Extensibility surface | Mature **extensions + presets** model with a resolution stack: project-overrides > presets > extensions > core. Multiple presets can stack with priority ordering [1]. This is the most developed customization surface in the SDD space. |
| Enterprise readiness | GitHub-backed; Microsoft Learn module exists ("Implement Spec-Driven Development using the GitHub Spec Kit") [6]. Azure Samples ship an `azure-speckit-constitution`. Production-ready for greenfield work; less suited to brownfield by user reports [10]. |
| **What it does BETTER than APEX** | (a) **Constitution-as-critical-blocker is a clean primitive** — APEX's `SPEC.md` + `SPEC_DELTA.json` is more sophisticated but Spec Kit's constitution + `/analyze` is brutally simple and works on day one. (b) **30+ agent reach via slash-command injection** — APEX's adapter story is thinner. (c) **105k stars = unbeatable mindshare**; spec-driven discourse in 2026 *is* Spec Kit discourse. (d) **Extension/preset resolution stack** is more polished than APEX's apex-skills loader. (e) **Microsoft training course** — institutional legitimacy APEX cannot buy. |
| **What APEX does better** | (a) **`originating_requirement_id` true traceability** — Spec Kit's tasks reference file paths but lack a formal bi-directional link from line of code back to spec line [11][14]. (b) **9-failure-mode taxonomy + named hooks** — Spec Kit has zero injection-hardening; no `phantom-check`, no `destructive-guard`, no `circuit-breaker`. (c) **Filesystem-quarantined auditor** — Spec Kit's `/analyze` reads everything; APEX's auditor cannot see implementation code. (d) **`/apex:refine` vs `/apex:build` separation** — Spec Kit explicitly fails brownfield work [10]. (e) **Conversational navigator `/apex:help`** — Spec Kit requires memorizing seven slash commands. (f) **Pre-task snapshot + one-click rollback** — Spec Kit has nothing beyond git. |
| **What APEX should steal / learn** | (a) Adopt a **constitution-style file** as a layer above `SPEC.md` for project-wide non-negotiable principles distinct from feature specs. (b) Build an `/apex:analyze` equivalent that *only* runs cross-artifact alignment between SPEC, PLAN, and TASK_MAP (apart from `/apex:validate-phase`). (c) Mirror Spec Kit's **extension + preset resolution stack** in `apex-skills/`. (d) Steal the **per-feature branch convention** as a default for `/apex:build`. (e) Match the **30+ agent adapter** count for credibility; today APEX claims six. |
| **Threat level** | **Critical.** Spec Kit owns the spec-driven brand. If APEX cannot answer "why not just use Spec Kit?" in a single sentence to a non-programmer, the user walks. |

Deeper analysis: Spec Kit's `/speckit.analyze` is the closest thing in the open-source world to APEX's critic loop, but it operates only at the spec-artifact level — it checks whether `tasks.md` covers all requirements in `spec.md`, whether `plan.md` violates the constitution, and so on. It does **not** verify that *generated code* matches the spec; that responsibility is punted back to the host agent's tests or the user's eyeballs. This is Spec Kit's biggest practical gap and exactly where APEX's `RESULT.json` schema (verified vs unverified criteria, tool-verified vs self-verified) is intellectually superior. The Spec Kit `/speckit.implement` command was even flagged in Issue #2459 for *not loading constitution.md* during code generation — a "governance gap" that the maintainers concede [13]. APEX must turn this into marketing copy: *"GitHub Spec Kit checks your specs. APEX checks your code."* Note also that Spec Kit's `clarify` step is essentially what APEX calls `/apex:discuss-phase` — APEX got there first conceptually but Spec Kit got the SEO. Active development is rapid (v0.8.7 → v0.8.13 in two weeks of May 2026), so any "currently missing" gap should be treated as a 90-day countdown.

---

### 2.2 AWS Kiro — the commercial spec-driven IDE

| Dimension | Detail |
|---|---|
| Lineage / scale | Built by AWS, **previewed July 2025, GA globally November 2025** [4][5][16]. Public closed-source. By May 2026 has shipped a Web variant, CLI, and is sold to Singapore higher-ed [16]. Star count N/A (closed source, but vendor traction is real). |
| Core philosophy | "Bring engineering rigor to agentic development" — make the **spec the unit of work**, not the prompt or the file [4][5]. |
| Architecture | VS Code fork running on AWS Bedrock. Three structured spec files per feature: **`requirements.md`** (in EARS notation), **`design.md`** (architecture + components + data flow), **`tasks.md`** (numbered checklist) [4][15]. |
| Multi-agent? | Effectively yes — Kiro routes between Claude Sonnet 4.5 (reasoning-heavy specs) and Amazon Nova (high-throughput code) via an "Auto" model router. Plus MCP-attached specialist agents. |
| Spec / planning layer | **The product**. Specs are first-class file types. EARS notation is enforced for acceptance criteria: `WHEN <condition> THE SYSTEM SHALL <behavior>` [15]. This is the strongest formal-grammar SDD on the market. |
| Verification / critic loop | Indirect — **hooks** can run tests/regenerate fixtures on file save, and the implementer must complete `tasks.md` checklist items. No equivalent of APEX critic or `/speckit.analyze`. Hooks are powerful but uncurated — user must wire them. |
| Memory / persistent state | **Steering files** for project-wide rules (coding standards, preferred libraries, workflows). Per-spec folders persist requirements/design/tasks. |
| Rollback / safety | Standard IDE git tooling. No pre-task snapshot. |
| Cost posture | **Paid.** Free tier with 50 credits; **Pro $20/mo, Pro+ $40/mo, Power $200/mo**, with overage at **$0.04/credit** [16]. GovCloud pricing ~20% higher. Kiro Web at half-rate through May 29, 2026. AWS Startups gives 1 year of Pro+ free [16]. |
| Non-programmer accessibility | **High-Medium.** "Kiro lowers the barrier to entry, whether that be, you don't even know how to code, you're new to coding..." [4]. EARS notation is teachable in half a day [15]. But you must adopt a VS Code-derived IDE and AWS account. |
| Extensibility surface | MCP-native (so any MCP server attaches); custom hooks; steering rules. |
| Enterprise readiness | **Very high.** AWS enterprise billing path, GovCloud, IHL deployment, SOC-grade Bedrock backing [16]. This is the de-facto enterprise SDD product. |
| **What it does BETTER than APEX** | (a) **EARS notation as enforced grammar for acceptance criteria** — APEX has nothing that constrains spec language. EARS *eliminates whole classes of ambiguity*. (b) **IDE integration** — Kiro is the tool the user lives in all day; APEX requires switching to a CLI/agent. (c) **Hooks that fire on file save / PR open / repo events** — APEX's hooks fire on Claude Code lifecycle events, not editor events. (d) **Auto model router with intent detection** — APEX has model routing per task class, but Kiro routes mid-conversation. (e) **Enterprise distribution via AWS** — APEX has zero enterprise channel today. |
| **What APEX does better** | (a) **Multi-platform via thin adapters** — Kiro requires you to abandon Cursor/Copilot/Claude Code. (b) **Free-forever core** — Kiro's $40/mo Pro+ is a real wallet hit for the non-programmer market APEX targets. (c) **9 named failure modes with named hooks** — Kiro has hooks; APEX has *defenses*. No `phantom-check` equivalent. (d) **`originating_requirement_id` traceability + `SPEC_DELTA.json`** — Kiro's three-file spec is static; APEX's spec lineage is git-diff-able and queryable. (e) **`/apex:discuss-phase` with gray-area classifier** — Kiro asks clarifying questions but doesn't classify uncertainty type. (f) **Filesystem-quarantined auditor** — Kiro has no audit agent. |
| **What APEX should steal / learn** | (a) **Adopt EARS notation as the recommended grammar for acceptance criteria in SPEC.md.** This is the single highest-ROI steal in this report. Half a day of training, zero implementation cost, eliminates entire ambiguity classes. (b) **File-save hooks** — wire APEX `circuit-breaker` and friends to fire on `PostToolUse:Write` for *all* writes, not just task boundaries. (c) **Auto model router for spec phases** — cheap model for `/apex:clarify`, expensive for `/apex:plan-phase`. (d) **Three-file spec convention** as an *option* in `/apex:build` — many users will prefer requirements/design/tasks over a single SPEC.md. (e) **Steering files** (project-wide rules separate from per-feature specs) — APEX has DECISIONS.md but it's not pitched this way. |
| **Threat level** | **Critical.** Kiro is what APEX would look like if Amazon built it. The only thing keeping it from killing APEX is the AWS lock-in tax and the $20-$200/mo bill. |

Deeper analysis: Kiro's adoption of EARS is the single most consequential move in the 2026 SDD landscape because it imposes *structure on the spec text itself*, not just on the folder layout. Where Spec Kit gives you a `spec.md` template that is still freeform prose, Kiro forces every acceptance criterion through the EARS funnel — which means a downstream agent (or a critic) can mechanically parse "trigger / precondition / system behavior" tuples. This is the bridge between "natural language requirements" and "formal verification" that the academic RE community has been chasing for 15 years, and Kiro shipped it [9][15]. APEX should not invent its own grammar — adopting EARS gives APEX 17 years of requirements-engineering literature for free. Kiro's hooks system is also worth studying carefully: events include file save, PR open, and repo events, and each hook runs a *pre-configured prompt* (delegating to the same Bedrock agents) rather than a shell script. This is a much more dynamic primitive than APEX's `.sh`-only hooks and is something APEX should explore for prompt-driven hooks (e.g., a "verify documentation matches code" hook that calls a small Claude model on every Write). Kiro's biggest non-obvious weakness: it has **no published verification or critic story**, just hooks. The marketing pitches "engineering rigor" but the rigor is procedural (you must walk through req → design → tasks), not adversarial (no second-model critique of generated code). APEX's cross-model critic is a real differentiator here.

---

### 2.3 OpenSpec — the lightweight brownfield-friendly alternative

| Dimension | Detail |
|---|---|
| Lineage / scale | Open-source, created by **Fission-AI** (creator not named on landing page). License not explicitly stated on `openspec.pro` *unverified*. Star count not displayed on landing page *unverified*. Cited in MarkTechPost May 2026 as having scored "highest overall" in a Feb 2026 13-category independent eval on a medium-sized serverless Python backend [7][8]. |
| Core philosophy | Lighter and brownfield-aware. "No rigid phase gates," no Python requirement [8]. |
| Architecture | Directory-based: `openspec/changes/[feature-name]/{proposal.md, specs/, design.md, tasks.md}` + `openspec/changes/archive/` for completed work [3]. |
| Multi-agent? | No. Hosts the user's existing agent (20+ supported including Claude, Cursor, Copilot, Windsurf, RooCode, Cline, Amazon Q, Codex) [3]. |
| Spec / planning layer | Three-phase state machine: **propose → apply → archive** via `/opsx:apply` and `/opsx:archive` commands [3]. |
| Verification / critic loop | None mechanical. Workflow recommends review of "proposal and spec deltas before large diffs land" but lacks formal gates [3]. |
| Memory / persistent state | Specs colocated with code in repo. Archive preserves history of completed change proposals. |
| Rollback / safety | Git only. |
| Cost posture | Free, OSS. No API keys required [7]. |
| Non-programmer accessibility | Medium. Directory structure is simple; no install gymnastics. |
| Extensibility surface | Light — not its strength. |
| Enterprise readiness | Low formally; positioned for teams that want auditable change proposals. |
| **What it does BETTER than APEX** | (a) **Delta markers ADDED/MODIFIED/REMOVED for brownfield iteration** [8] — APEX has `SPEC_DELTA.json` but not at the per-requirement granularity. (b) **Proposal-first workflow** — every change starts as a *proposal* file that can be reviewed before any code is touched. APEX's `/apex:discuss-phase` is similar but heavier. (c) **No Python install / lighter than Spec Kit** — APEX requires more ceremony. (d) **Archive directory pattern** — preserves completed work as historical evidence, useful for audits. |
| **What APEX does better** | (a) **Real verification (critic loop, `RESULT.json` schema, auditor)** — OpenSpec has none. (b) **9-failure-mode defenses** — OpenSpec has none. (c) **Memory synthesis dream-cycle** — OpenSpec has archive but no synthesis. (d) **Roundtable + debate protocols** — OpenSpec has none. (e) **`/apex:refine` pipeline** — OpenSpec handles brownfield with delta markers but lacks the bug-fix vs feature-add distinction. |
| **What APEX should steal / learn** | (a) **Delta markers on requirements (ADDED/MODIFIED/REMOVED)** — adopt this lexicon inside `SPEC_DELTA.json` for clearer brownfield diffing. (b) **Archive directory for completed changes** — `.apex/phases/archive/` would create a clean audit trail without polluting active phases. (c) **Proposal-first slash command** — `/apex:propose` (lighter than `/apex:discuss-phase`) for users who want to draft a change without immediately discussing it. |
| **Threat level** | **Medium.** Smaller than Spec Kit but the *MarkTechPost top-overall ranking* + brownfield friendliness make it the credible alternative for teams that bounce off Spec Kit's ceremony. |

Deeper analysis: OpenSpec is the most directly comparable competitor to APEX in spirit — both reject the "static spec at the start" trap, both support iterative refinement, both colocate specs with code. The key difference is that OpenSpec is *purely a folder convention* with no enforcement layer, while APEX wraps the convention in named failure-mode defenses. This makes OpenSpec the textbook example of an SDD framework that captures the methodology but not the rigor. The killer move OpenSpec made that APEX has not: **delta markers** at the requirement level. When an OpenSpec change proposal says `MODIFIED: requirement 2.3` it gives every downstream agent an unambiguous instruction to *re-read* the prior spec for 2.3 before generating code. APEX's `SPEC_DELTA.json` operates at a coarser level — it tracks that the spec changed, not which specific lines, in markup the agent can parse. Stealing the ADDED/MODIFIED/REMOVED lexicon is a one-day diff and would close this gap immediately.

---

### 2.4 BMAD-METHOD — the multi-agent SDLC orchestrator that adopted SDD

| Dimension | Detail |
|---|---|
| Lineage / scale | MIT-licensed open-source; "Breakthrough Method for Agile AI Driven Development." **v6.6.0** shipped April 29, 2026; **46,700+ stars, 5,500+ forks** [7][8][17]. |
| Core philosophy | Role-separated multi-agent orchestration covering the full SDLC. Each phase is owned by a distinct agent persona. |
| Architecture | 12+ specialized agents: Analyst, PM, Architect, UX, Developer, QA, Scrum Master, etc. Cross Platform Agent Team allows same agent config to run on Claude Code, Cursor, Codex, and others [17]. |
| Multi-agent? | **Yes — this is its primary selling point.** |
| Spec / planning layer | Four-phase SDLC: **Analysis → Planning → Solutioning → Implementation** [17]. Each phase produces specification documents (user stories, acceptance criteria, requirements). |
| Verification / critic loop | Phase handoffs are gated; QA agent reviews; no formal `/analyze`-style cross-artifact check. |
| Memory / persistent state | File-based handoffs; "traceable chain of outputs" per phase [7]. |
| Rollback / safety | None framework-level; relies on git. |
| Cost posture | Free, OSS. |
| Non-programmer accessibility | Medium-Low. The 12-agent persona system is conceptually heavy for non-programmers; ceremony is its biggest design choice. |
| Extensibility surface | V6 introduced **Skills Architecture** — reusable specialized sub-agents shared across workflows [17]. |
| Enterprise readiness | High in spirit (SDLC role coverage matches enterprise org charts); production deployments documented. |
| **What it does BETTER than APEX** | (a) **12 named persona agents covering full SDLC** — APEX has 8 core + 4 specialist, but BMAD's PM/UX/Scrum-Master coverage is broader. (b) **Cross-platform agent team config that works across Claude Code, Cursor, Codex without reconfiguration** — APEX adapters require per-platform tweaks. (c) **46k stars and Udemy course** — institutional traction APEX lacks. (d) **Skills Architecture** is a more sophisticated reuse primitive than `apex-skills/`. |
| **What APEX does better** | (a) **Failure-mode taxonomy** — BMAD has agents but no `phantom-check`, `destructive-guard`, `circuit-breaker`. (b) **Critic loop with mutation testing + adversarial persona** — BMAD's QA agent is generic. (c) **Auditor filesystem quarantine** — BMAD has none. (d) **Non-programmer-first design** — BMAD is built for agile dev teams, not solo non-coders. (e) **`/apex:fast`/`/apex:quick`/`/apex:full` ceremony tiers** — BMAD is one-size-fits-all. |
| **What APEX should steal / learn** | (a) **Persona breadth: add a PM/UX/Scrum-Master pattern to APEX's roundtable** for full-SDLC roundtables, not just technical ones. (b) **Cross-platform agent team config** as a single YAML/JSON manifest that adapters consume. (c) **Skills Architecture** — formalize APEX's specialist agents into a publishable skill catalog. |
| **Threat level** | **High.** BMAD's mindshare (46k stars) is the closest existential threat from the multi-agent corner. The MarkTechPost survey explicitly positions GSD as "the lean alternative to BMAD," meaning BMAD is the gravity well others orbit. |

Deeper analysis: BMAD is technically out-of-scope for this report (it's primarily a multi-agent framework, covered more centrally in Report 04), but **v6 explicitly rebranded around spec-driven development** as the methodology positioning, so it is unavoidably in APEX's spec-driven competitive set. BMAD's four-phase model (Analysis → Planning → Solutioning → Implementation) is structurally very close to APEX's discuss → plan → execute → validate, with one important distinction: BMAD assigns each phase to a *named persona agent* with backstory and tone, where APEX uses functional roles (architect, executor, critic, auditor). The persona approach is more relatable for non-programmers ("the PM agent will ask about your users") and APEX should consider whether its functional roles need optional persona masks. BMAD's biggest weakness vs APEX is the absence of any falsifiability machinery — there is no `RESULT.json` equivalent, no critic that can return PASS/FAIL/NEEDS_REVIEW from a locked-down adversarial position. BMAD looks rigorous because of the role separation but the rigor is conventional, not enforced.

---

### 2.5 Tessl — the venture-backed spec-driven platform

| Dimension | Detail |
|---|---|
| Lineage / scale | Founded by **Guy Podjarny** (founder of Snyk) [12]. Series A announced 2025; specific amount *unverified*. **Tessl Framework launched in closed beta** Sept 2025; **Tessl Spec Registry in open beta** with **10,000+ pre-built specs** for OSS libraries [12][18]. As of May 2026 GA status not confirmed *unverified*. |
| Core philosophy | "Specs are long-term memory in the codebase." Pair specs with tests as guardrails. Embrace both rigorous spec-first and AI-generated "vibe-specs" [12][18]. |
| Architecture | Specs as `.spec.md` files containing: (1) component description, (2) capabilities with linked tests, (3) API surface [18]. Tessl can be used as CLI (humans) or **MCP server (agents)** [18]. |
| Multi-agent? | No internal multi-agent. Designed to delegate code generation to whatever agent is hosting Tessl tools. |
| Spec / planning layer | The product. Two modes: **spec-first (TDD-like)** and **"vibe-specing"** (build first, backfill specs after) [18]. |
| Verification / critic loop | **Yes** — each capability in a spec has a linked test; tests are the enforcement layer. This is APEX-comparable rigor. |
| Memory / persistent state | Specs in-repo serve as long-term memory; Spec Registry provides external library specs to prevent API hallucinations. |
| Rollback / safety | Tests catch breakage; git for rollback. No bespoke snapshot. |
| Cost posture | Closed beta; pricing not public *unverified*. |
| Non-programmer accessibility | Medium. Vibe-spec mode is friendly; spec-first is more rigorous. The MCP-server-for-agents design lets any agent host be the user surface. |
| Extensibility surface | `.tessl/` "tiles" teach agents spec-driven workflow [7]; Spec Registry is community-extensible. |
| Enterprise readiness | Targeted at production teams; backed by a serial-founder CEO; AI Native DevCon'26 community events. |
| **What it does BETTER than APEX** | (a) **Spec Registry with 10,000+ specs for OSS libraries** — directly attacks library hallucination, which APEX has no native answer to. (b) **Linked tests as part of the spec grammar** — APEX has `TEST_MAP.txt` but Tessl makes the spec ↔ test link first-class. (c) **MCP-server-for-agents design** — Tessl is *the tool the agent uses*, not the tool the user uses; APEX is closer to the user surface. (d) **"Vibe-spec" backfill mode** — Tessl explicitly accepts that some users prototype first and document after; APEX is more spec-first dogmatic. (e) **Founder credibility (Snyk)**. |
| **What APEX does better** | (a) **Open source + free** — Tessl is closed-beta-and-priced. (b) **9-failure-mode defenses** — Tessl has tests but no `phantom-check`/`destructive-guard`/`circuit-breaker`. (c) **Auditor quarantine** — Tessl's tests aren't filesystem-isolated from impl. (d) **`originating_requirement_id`** — Tessl links capability to test, but not back to a top-level requirement ID. (e) **Self-healing loop** — Tessl has no two-consecutive-clean-rounds equivalent. |
| **What APEX should steal / learn** | (a) **Build an APEX Spec Registry** — a community catalog of `apex-workflows/` and stack-specific contracts that pre-tested patterns can be reused. The `apex-workflows/` library is already heading here; formalize it. (b) **Make spec ↔ test linkage first-class** — every requirement in `SPEC.md` should have a `tests: [...]` field that the executor and critic both reference. (c) **MCP-server mode for APEX** — expose APEX functions (e.g., `discuss-phase`, `plan-phase`) as MCP tools that any agent can call from any host. This is a real strategic move for multi-platform reach. (d) **Officially support a vibe-first onboarding** — `/apex:onboard` could include a "let me describe what I built, then we'll generate the spec retroactively" mode. |
| **Threat level** | **High.** Tessl is the most strategically dangerous *commercial* SDD play because Podjarny will likely repeat the Snyk playbook: open standard, paid enterprise tooling. If Tessl ships the Spec Registry GA before APEX has any equivalent, APEX loses the library-hallucination story permanently. |

Deeper analysis: Tessl's bet is that **specs become a tradable commodity**, much like Snyk made vulnerability data a commodity. The Spec Registry is the cleanest articulation of this — 10,000+ pre-existing specs that describe how libraries *should* be used, served to agents at code-generation time. APEX has nothing comparable. The `apex-workflows/` library of 30+ recipes is in the same conceptual neighborhood (organizational memory) but is APEX-local, not a network good. The single strategic question for the APEX author is: **does APEX want to be a methodology (Spec Kit's model), a tool (Kiro's model), or a network (Tessl's model)?** Tessl's existence forces APEX to pick. Note that Podjarny's quoted prediction — "by end of 2027, developers working with agents won't look at code most of the time" — is exactly APEX's non-programmer-first thesis. He has the venture funding to execute on it.

---

### 2.6 SpecDD — the lightweight community-driven SDD framework

| Dimension | Detail |
|---|---|
| Lineage / scale | Open-source, Apache 2.0; created by **Matīss Treinis and SpecDD contributors** [19]. Launch date not specified *unverified*. Star count and adoption not on landing page *unverified*. |
| Core philosophy | Give humans + AI agents "a shared source of truth for intent, requirements, boundaries, and completion criteria" via local human-readable `.sdd` files [19]. |
| Architecture | `.specdd/bootstrap.md` at project root + `.sdd` files colocated with source: `app.sdd`, `src/module.sdd`, `src/billing/invoice.service.sdd` next to `invoice.ts` [19]. |
| Multi-agent? | No — hosts the user's existing agent. |
| Spec / planning layer | `.sdd` files with structured sections: `Spec: Name`, `Purpose`, `Owns`, `Must`, `Must not`, `Scenario`, `Tasks` [19]. |
| Verification / critic loop | **None automated.** Explicitly recommends human review: "Always inspect generated code before relying on it." Recommends tests be run after [19]. |
| Memory / persistent state | Files in repo; path-based resolution for "applicable specs come from ancestor specs, explicit References, and same-directory basename matches" [19]. |
| Rollback / safety | Git only. |
| Cost posture | Free, OSS, Apache 2.0. |
| Non-programmer accessibility | **High.** Landing page explicitly addresses "I am not technical, can I use SpecDD too?" with affirmative answer [19]. |
| Extensibility surface | File-format-based; `.sdd` schema is the extension surface. |
| Enterprise readiness | Targets QA, support, operations alongside engineering — wider audience than most. |
| **What it does BETTER than APEX** | (a) **Path-based spec inheritance** — child specs automatically inherit from ancestor specs and same-directory basename matches. APEX has nothing like this directory-aware spec scoping. (b) **"Owns" + "Must" + "Must not" structured fields** — clearer separation of concerns than APEX's prose-heavy `SPEC.md`. (c) **Explicit non-technical-user welcome** — same audience as APEX, with a friendlier explicit pitch. (d) **Spec for non-code artifacts** — infrastructure, automation, documentation, workflows are all in scope. APEX is more code-centric. |
| **What APEX does better** | (a) **Everything verification-related** — SpecDD explicitly delegates verification to humans. APEX has critic, auditor, RESULT.json. (b) **Memory synthesis** — SpecDD specs are static files; APEX synthesizes across sessions. (c) **`/apex:roundtable` and `/apex:_debate`** — SpecDD has no decision-protocol layer. (d) **Failure-mode defenses** — SpecDD has none. |
| **What APEX should steal / learn** | (a) **Adopt directory-scoped spec inheritance.** A spec at `src/billing/` should automatically apply to all child files. This is a huge non-programmer ergonomic win. (b) **Structured `Must` / `Must not` / `Owns` / `Scenario` fields in `SPEC.md`** — currently APEX SPEC.md is prose; structured fields make critic enforcement mechanical. (c) **Specs for non-code artifacts** — `apex-skills/` already does this for stack patterns; extend to infrastructure and documentation. |
| **Threat level** | **Medium-Low.** SpecDD is conceptually clean but lacks the verification layer that APEX's USP rests on. Adoption metrics are too thin to verify. Watch but do not panic. |

Deeper analysis: SpecDD's path-based inheritance is the most interesting structural idea in the entire SDD landscape. The concept that a spec at `src/billing/invoice.service.sdd` *automatically inherits* from `src/billing/billing.sdd` which inherits from `app.sdd` matches how programmers think about scope (and how non-programmers think about organizational hierarchy). This is a one-time structural win — once adopted you never re-explain "this rule applies to all billing files" because the directory location says so. APEX should adopt this in `SPEC.md` and the executor's context-loading order. The framework is otherwise undermarketed and underverified; it would benefit enormously from a critic loop and a public adoption number.

---

### 2.7 Backlog.md — markdown-native AI-collaborative backlog

| Dimension | Detail |
|---|---|
| Lineage / scale | Open-source by **MrLesk**; **5.6k GitHub stars; v1.45.1** released May 7, 2026 [20]. |
| Core philosophy | "Tasks as plain markdown files; AI agents are first-class citizens in a git-native workflow" [20]. |
| Architecture | CLI-first + React web UI with Kanban boards. Tasks stored as `backlog/task-10 - Add core search functionality.md` etc. Optional `--no-git` for filesystem-only projects [20]. |
| Multi-agent? | Hosts user's agent(s). Supports Claude Code, Codex, Gemini CLI, Kiro via MCP or CLI. |
| Spec / planning layer | Tasks include `--ac "Clear acceptance criteria"`, descriptions, implementation plans. Generates `AGENTS.md` + `CLAUDE.md` instruction files at init [20]. |
| Verification / critic loop | None automated. Definition-of-done checklists + status transitions are human-driven. |
| Memory / persistent state | Markdown files + git commits. `backlog search --modified-file src/path.ts` enables file-to-task lookup. |
| Rollback / safety | Git-native; atomic descriptive commits per operation. |
| Cost posture | Free, OSS. |
| Non-programmer accessibility | High — Kanban UI + markdown editing + minimal CLI surface. |
| Extensibility surface | MCP server (`backlog mcp start`); fallback CLI mode. |
| Enterprise readiness | Light; better for small teams or solo devs. |
| **What it does BETTER than APEX** | (a) **Visible Kanban board** — APEX has no UI; non-programmers respond strongly to drag-and-drop. (b) **Atomic descriptive commits per backlog op** — APEX commits per task but doesn't auto-commit on backlog moves. (c) **Cross-branch task sync with conflict resolution** [21] — APEX has no equivalent. (d) **Generated `AGENTS.md` + `CLAUDE.md` at init** — APEX requires users to onboard the agent themselves. (e) **`backlog search --modified-file`** — file-to-task reverse lookup that APEX lacks. |
| **What APEX does better** | (a) **Full SDD lifecycle** — Backlog.md is a task tracker first, spec tracker second. (b) **Verification, critic, auditor** — Backlog.md has none. (c) **`apex-workflows/` library** — Backlog.md has no workflow templates. (d) **Phase-gating, complexity classification, scale-adaptive ceremony** — Backlog.md is one-tier. (e) **Failure-mode defenses** — none in Backlog.md. |
| **What APEX should steal / learn** | (a) **Add a Kanban UI surface** — even a terminal-only one, or generate an HTML view on demand from `TASK_MAP.md`. This is the single biggest non-programmer adoption lever in this report. (b) **Auto-generate `AGENTS.md` / `CLAUDE.md` at `/apex:onboard`** — already partially done; make it universal. (c) **File-to-task reverse search** — every commit should record `apex_task_id` and APEX should expose `apex search --modified-file`. (d) **Cross-branch task sync with conflict resolution** — for users working in worktrees. |
| **Threat level** | **Medium.** Not a direct SDD competitor; competes for the *non-programmer-friendly project layer* slot which APEX needs to own. |

Deeper analysis: Backlog.md is the only tool in this domain with a real GUI (Kanban board), and that is not a coincidence — its author understood that markdown-in-folders is *necessary but not sufficient* for non-programmer adoption. APEX's primary UX risk is that every state file is JSON or markdown in a hidden directory, and non-programmers cannot see, touch, or rearrange their work. A Backlog.md-style Kanban view rendered from `STATE.json` + `TASK_MAP.md` would be a major non-programmer win at low engineering cost. The other big idea Backlog.md got right is the auto-generated `AGENTS.md` + `CLAUDE.md` at project init — this is how it ensures *any* agent that lands in the repo (Claude Code, Codex, Gemini CLI, Kiro) understands the project conventions immediately. APEX should generate equivalents and consider an `AGENTS.md` of its own as an emerging cross-agent standard.

---

### 2.8 SpecStory — capture sessions as institutional memory

| Dimension | Detail |
|---|---|
| Lineage / scale | Closed-source vendor (`specstoryai`). **200,000+ installs** by mid-2026 [22]. VS Code Marketplace + CLI. Local-first with optional cloud sync. |
| Core philosophy | "Turn ephemeral AI conversations into durable project knowledge" — capture every AI chat session as searchable markdown [22]. |
| Architecture | IDE extension + CLI that captures Cursor, Copilot, Claude Code, Codex sessions into `.specstory/history/` as markdown. Optional SpecStory Cloud syncs to centralized searchable KB. **Agent Skills** library for processing history (session summarizers, secret scanners, etc.). |
| Multi-agent? | No. Captures whatever agent the user is running. |
| Spec / planning layer | Indirect — captured sessions become specs through SpecFlow guide. Live rules can be derived from history. |
| Verification / critic loop | None — passive capture. |
| Memory / persistent state | **This is its entire product.** `.specstory/history/` is the persistent state. |
| Rollback / safety | N/A (read-only capture). |
| Cost posture | Local-first free; cloud tier pricing not publicly published *unverified*. |
| Non-programmer accessibility | High — install extension, sessions auto-capture. |
| Extensibility surface | Open-source Agent Skills repo (`specstoryai/agent-skills`) — community can write skills that operate on history. |
| Enterprise readiness | Cloud product is positioned for teams; secret-scanning skill suggests enterprise hardening. |
| **What it does BETTER than APEX** | (a) **Passive capture of every AI session across every tool** — APEX captures structured artifacts but not raw conversation logs. (b) **Cross-tool memory** — SpecStory captures Cursor + Copilot + Claude + Codex in one folder, while APEX is Claude-Code-centric. (c) **Agent Skills marketplace pattern** — open-source skills that operate on captured data. (d) **200k installs is massive distribution.** |
| **What APEX does better** | (a) **Active intervention** — APEX prevents bad outcomes; SpecStory just records them. (b) **Memory synthesis** — APEX's dream-cycle agent consolidates learning; SpecStory leaves you with raw transcripts. (c) **Critic + auditor** — none in SpecStory. (d) **Failure-mode defenses** — none. (e) **Workflows + STATE machine** — none. |
| **What APEX should steal / learn** | (a) **Capture every Claude Code session into `apex/sessions/` as markdown** — even if APEX is not invoked, the session is captured. This is the precondition for retrospective memory synthesis. (b) **Adopt an "Agent Skills marketplace" model** — let community contribute skills that operate on `apex/` state. (c) **Cross-tool aspiration** — APEX should claim memory across Cursor/Copilot/Claude when used together, not just Claude. |
| **Threat level** | **Medium.** SpecStory is *complementary* to APEX (capture + synthesis), not directly competitive on SDD. The threat is if SpecStory layers prevention/verification on top — they have the captured data, the distribution, and the team. |

Deeper analysis: SpecStory is the clearest example of an adjacent player that could pivot into APEX's space with one feature release. Today they passively capture; tomorrow they could ship a "Session Critic" that re-runs old sessions through a second model to flag what the user missed. With 200k installs and existing agent-skill primitives, they are 90 days from an APEX-lite competitor if they choose. APEX should treat SpecStory as a partner *or* preempt: build APEX's own session capture into `apex/sessions/` and use it as the input to memory synthesis. The intellectual property at risk is the *raw conversation data* — whoever has it can build everything else on top.

---

### 2.9 claude-task-master — PRD-driven task management

| Dimension | Detail |
|---|---|
| Lineage / scale | Open-source by **Eyal Toledano**. **~25,400 GitHub stars; v0.43.0** released Feb 4, 2026 [23][24]. |
| Core philosophy | "Task management middleware that sits between your spec and your AI editor" [23]. Parse a PRD → generate tasks.json → drive Cursor/Lovable/Windsurf/Roo/Claude Code. |
| Architecture | Three operating modes (Core 7 tools / Standard 15 / All 36). Solo mode = local files; Team mode = Hamster cloud sync [23]. Recent: MCP Bundle (MCPB) spec for single-click Claude Desktop install. |
| Multi-agent? | No — feeds tasks to a single host agent. |
| Spec / planning layer | `parse_prd` ingests a PRD markdown file and emits `tasks.json` with dependencies, complexity scores, expansion of subtasks [23]. |
| Verification / critic loop | None — it's task-management middleware, not a critic. |
| Memory / persistent state | `tasks.json` + optional metadata field (arbitrary JSON per task for external IDs/workflow data) [23]. |
| Rollback / safety | None framework-level. |
| Cost posture | Free, OSS; team mode has Hamster cloud add-on. |
| Non-programmer accessibility | Medium. CLI + MCP install; PRD authoring is markdown. |
| Extensibility surface | MCPB bundles; deferred-loading saves ~16% of Claude Code's 200k context window. |
| Enterprise readiness | Hamster cloud for teams; team-mode commands. |
| **What it does BETTER than APEX** | (a) **`parse_prd` is the cleanest single primitive in the space** — point at a PRD file, get a ready-to-execute `tasks.json` with dependencies and complexity scores. APEX's plan-phase is heavier. (b) **MCPB single-click install** — APEX install is multi-step. (c) **Deferred-loading context optimization** — saves 16% of the host's 200k window. APEX `CONTEXT_BUDGET.json` is more sophisticated but less optimized. (d) **Three operating modes with tool counts (Core 7 / Standard 15 / All 36)** — clean opt-in surface; APEX has 11 commands without graduated exposure. |
| **What APEX does better** | (a) **Critic loop, auditor, RESULT.json** — task-master has none. (b) **`/apex:roundtable`, `/apex:_debate`** — none. (c) **Failure-mode defenses** — none. (d) **Memory synthesis** — none. (e) **`/apex:refine` vs `/apex:build`** — task-master is feature-add only. |
| **What APEX should steal / learn** | (a) **A first-class `parse_prd`/`parse_spec` command** — pour a PRD in, get TASK_MAP.md + complexity scores out, no questions asked. Today APEX requires `/apex:discuss-phase` → `/apex:plan-phase` for this. (b) **MCPB single-click install** for Claude Desktop. (c) **Deferred command loading** — only expose core 6 commands by default, advanced commands behind a flag. (d) **Per-task metadata field** for external IDs (Jira, Linear) — closes a real gap for team workflows. |
| **Threat level** | **High.** With 25.4k stars and an established niche, task-master is the path-of-least-resistance choice for the "I have a PRD, what next?" use case. If APEX cannot answer that question in three commands or fewer, it loses this user permanently. |

Deeper analysis: task-master is the clearest example in this report of *competing through reduced ceremony*. Its `parse_prd` is a single command that ingests a PRD and emits a dependency-ordered task graph. The user did not have to discuss, did not have to plan, did not have to clarify — they just paid the cost of writing the PRD once and got the rest free. APEX's equivalent flow requires `/apex:discuss-phase` → `/apex:plan-phase` → execution, with potential `/apex:precheck`. For a user with a clear PRD, this is over-ceremonious. APEX should explicitly add a "fast path" — `/apex:parse-spec` or `/apex:from-prd` — that compresses discuss+plan into a single PRD-ingest step. Note that task-master itself targets the "AI editor" market (Cursor, Lovable, Windsurf, Roo, Claude Code) which makes it a natural front-end for any of those, including agents running APEX downstream.

---

### 2.10 GSD ("Get Shit Done") — the fastest-growing SDD framework

| Dimension | Detail |
|---|---|
| Lineage / scale | Open-source, by **TÂCHES**. **~59,600–61,000 GitHub stars** (depending on source/repo) accumulated in ~5 months Dec 2025 → May 2026 [7][25]. 138 contributors, 2,100+ commits, 57 public releases. Note: development reportedly migrating to "GSD Redux"/"Open GSD" repo [25] *unverified*. |
| Core philosophy | "Spec-driven development without the ceremony." Complexity should live in the system, not the workflow. Lean alternative to BMAD [7][25]. |
| Architecture | Meta-prompting + context-engineering + SDD system for Claude Code. Hierarchy: Project > Milestone > Phase > Plan > Task. Each phase = `discuss → plan → execute → verify` [25]. |
| Multi-agent? | Yes — parallel researchers, planners, executors, verifiers [7]. |
| Spec / planning layer | Hierarchical: Milestones group phases; phases gate work; each phase has its own spec/plan. |
| Verification / critic loop | "Verify" step at end of each phase [25]. Less rigorous than APEX's critic + auditor but present. |
| Memory / persistent state | Phase artifacts in repo; v1.39 added `--minimal` flag to ship only 6 core skills + reduce system prompt from ~12k to ~700 tokens (94% reduction) [25]. |
| Rollback / safety | None framework-level; git-based. |
| Cost posture | Free, OSS. |
| Non-programmer accessibility | Medium-High. The Project > Milestone > Phase > Plan > Task hierarchy is intuitive. |
| Extensibility surface | Skills are first-class; v1.39 ships them as opt-in modules. |
| Enterprise readiness | Growing fast; recent updates include knowledge-graph integration (`/gsd-graphify`) and pattern-mapper agent for codebase analysis [25]. |
| **What it does BETTER than APEX** | (a) **60k stars in 5 months is the fastest growth curve in this entire report** — TÂCHES has solved distribution. APEX must learn this. (b) **Project > Milestone > Phase > Plan > Task hierarchy** is more legible than APEX's phase-only model. (c) **`--minimal` install with 94% prompt reduction** — APEX's prompt cost is unmanaged. (d) **`/gsd-graphify` knowledge graph integration** — APEX has nothing comparable for codebase graph queries. (e) **Pattern-mapper agent for codebase pattern analysis** — APEX has no codebase-mapping specialist. |
| **What APEX does better** | (a) **Critic loop rigor** — GSD's verify step is generic; APEX's critic is locked to PASS/FAIL/NEEDS_REVIEW with anti-rationalization injection. (b) **Auditor filesystem quarantine** — GSD has no equivalent. (c) **Failure-mode defenses** — GSD has none of APEX's 9-failure-mode hooks. (d) **Memory synthesis dream-cycle** — none in GSD. (e) **`/apex:roundtable` + `/apex:_debate`** — none. (f) **Scale-adaptive classifier** — GSD's hierarchy is fixed; APEX adjusts ceremony per project scale. |
| **What APEX should steal / learn** | (a) **Add a Milestone tier above Phase** — gives projects a quarterly or release-aligned grouping that non-programmers understand. (b) **Ship `--minimal` install** — a starter mode with only the 5-6 most-used commands and a slim system prompt; aggressively reduce APEX's prompt footprint. (c) **Knowledge-graph specialist** — add a `/apex:codebase-graph` command that queries an Aider-style repo map. (d) **Pattern-mapper agent** that scans the codebase and identifies recurring patterns to enforce or refactor. (e) **Study TÂCHES's growth playbook**: what did they do that took them from 0 to 60k stars in 5 months? Likely answer: ruthless ceremony reduction, Claude Code-native install, and aggressive content marketing. |
| **Threat level** | **Critical.** GSD's growth trajectory is the most alarming signal in this report. If they continue at this rate they will be at 150k+ stars by end of 2026 and *the* default lean SDD framework. APEX must define its differentiation against GSD in one sentence by end of Q3 2026. |

Deeper analysis: GSD is the existential competitor to APEX in 2026. Both are Claude-Code-native, both wrap discuss-plan-execute-verify, both target lean ceremony, both are open source. The differentiators APEX has — failure-mode defenses, critic rigor, auditor quarantine, memory synthesis — are real but invisible to a casual GitHub browser comparing star counts. GSD has 7x APEX's mindshare (assumed *unverified-comparison*) with arguably less rigor. This is the classic "open-source rigor vs. open-source velocity" tension. APEX's response must be (a) ruthless onboarding simplification (`--minimal`), (b) explicit head-to-head positioning ("GSD verifies; APEX falsifies"), and (c) one killer feature GSD cannot easily replicate — the filesystem-quarantined auditor is the strongest candidate. The migration to "GSD Redux" is a yellow flag worth watching; framework refactors at this scale often shed users.

---

### 2.11 Cosine Genie — autonomous SWE with embedded spec workflow

| Dimension | Detail |
|---|---|
| Lineage / scale | YC-backed. **Genie 2** + **Genie 2.1** shipped in 2026. Proprietary, closed source. **72% on SWE-Lancer; 53% pass rate ($107,750) on SWE-Lancer Diamond Eval** [26][27]. |
| Core philosophy | "The copilot era is over." Fully autonomous software engineer — assign a Jira/Linear ticket; Genie branches, implements, opens PR [26]. |
| Architecture | Proprietary Genie 2 model + multi-agent orchestration. Asynchronous: no IDE required. |
| Multi-agent? | **Yes** — Genie Multi-agent decomposes backlog items into subtasks and orchestrates parallel writers. Stays on goal across subtasks. |
| Spec / planning layer | Indirect — ingests user stories / Jira tickets / PRDs as spec input. No standalone spec product. |
| Verification / critic loop | Iterative testing built into Genie 2's training; "iteratively test those changes before reverting to the user" [27]. Not user-visible critic. |
| Memory / persistent state | Across-session retrieval in large codebases; not exposed as user-facing artifacts. |
| Rollback / safety | Git-based via PR review. |
| Cost posture | Commercial; pricing on request. |
| Non-programmer accessibility | High in the sense that the user just assigns tickets; low in the sense that they need to understand Jira/Linear/PR review. |
| Extensibility surface | Slack integration (Genie 2.1); ticket-system integrations. |
| Enterprise readiness | High — sells to dev teams with Jira/Linear workflows. |
| **What it does BETTER than APEX** | (a) **Asynchronous execution without an IDE** — assign a ticket, walk away, review PR. APEX requires the user to be at the terminal. (b) **SWE-Lancer 72% benchmark crown** — quantifiable code-quality lead. (c) **Multi-agent subtask decomposition that survives roadblocks** — APEX waves are static; Genie adapts mid-flight. (d) **Genie 2 is a trained model, not a prompting framework** — they own the fine-tuning. |
| **What APEX does better** | (a) **Open source + free** — Genie is proprietary. (b) **Transparency** — every APEX artifact is human-readable; Genie's reasoning is black-box. (c) **Failure-mode defenses** — Genie's hallucination defenses are model-internal; APEX's are explicit and inspectable. (d) **Multi-platform via thin adapters** — Genie is its own surface. (e) **Spec-as-first-class artifact** — Genie consumes specs; APEX makes them governable. |
| **What APEX should steal / learn** | (a) **Asynchronous execution mode** — `/apex:dispatch <ticket-url>` that runs without supervision and surfaces a PR for review. (b) **Subtask decomposition that survives roadblocks** — APEX waves should support mid-wave re-planning on failure rather than circuit-breaking. (c) **Integration with Jira/Linear/GitHub Issues** — ingest tickets as `originating_requirement_id` automatically. (d) **Slack integration** — for the non-programmer who lives in Slack, not the terminal. |
| **Threat level** | **High.** Genie is borderline out-of-scope (it's closer to Report 03 autonomous commercial agents), but the multi-agent subtask decomposition and asynchronous PR workflow are exactly the missing piece between APEX and a non-programmer who wants to assign work via Slack and check back later. If Genie ships a free tier, the threat goes Critical. |

Deeper analysis: Genie is the spec-driven domain's example of "spec consumption" rather than "spec authoring." Tessl, Spec Kit, Kiro, OpenSpec, SpecDD all help you *write* a better spec. Genie takes whatever ticket you have, even a one-line Jira note, and runs the full development cycle. This is the asynchronous endgame the entire industry is moving toward. APEX's principal weakness here is that the user has to be at the terminal to use it. An `/apex:dispatch` command that runs detached on a fresh worktree, posts progress to Slack, and surfaces a PR when done would close this gap. Without it, APEX remains a "user at keyboard" tool while the market is moving to "user assigns and walks away."

---

## 3. Cross-cutting patterns in this domain

**Theme 1: The constitution / steering-rules layer has become standard.** Spec Kit (`constitution.md`), Kiro (steering files), GSD (skills), Tessl (`.tessl/` tiles), SpecDD (`.specdd/bootstrap.md`) all converged on the idea that **project-wide principles live in a separate persistent file** distinct from per-feature specs. APEX's `DECISIONS.md` is the closest equivalent but is not pitched this way. **APEX should explicitly name and elevate a constitution-equivalent.**

**Theme 2: EARS notation is winning as the formal grammar for acceptance criteria.** Kiro enforces it; Spec Kit Issue #1356 explicitly proposes adopting it. EARS is unambiguously the lingua franca by mid-2026. APEX has no formal grammar.

**Theme 3: Three-artifact decomposition (requirements / design / tasks) is the dominant spec shape.** Kiro hard-codes it; Spec Kit produces it; OpenSpec produces a variant. APEX's single `SPEC.md` + `PLAN.md` + `TASK_MAP.md` is structurally similar but uses different names. **APEX should align nomenclature** for SEO and onboarding clarity (or explicitly explain why its names are better).

**Theme 4: Spec ↔ test linkage is the verification frontier.** Tessl makes capability ↔ test first-class; Augment Code's Verifier agent checks results against original spec; Spec Kit's `/analyze` flags coverage gaps. APEX has `TEST_MAP.txt` but the link is by-convention, not by-grammar.

**Theme 5: Brownfield is the unsolved problem.** Spec Kit explicitly fails on brownfield; OpenSpec uses delta markers; SpecDD inherits up the directory tree. The brownfield-friendliest tool wins enterprise. APEX has `/apex:refine` and `SPEC_DELTA.json` but does not market brownfield aggressively.

**Theme 6: Distribution is more decisive than rigor.** GSD: 60k stars in 5 months. Spec Kit: 105k stars. BMAD: 46k stars. APEX's rigor is real but invisible to a star-counter. Whoever ships the cleanest `npm install` or `uvx tool install` wins the next 10,000 non-programmer users.

---

## 4. Where this domain collectively beats APEX

1. **EARS-grammar enforcement for acceptance criteria** — Kiro has it; APEX has nothing comparable. Whole classes of ambiguity are eliminable by adopting one notation.
2. **Constitution layer as a first-class file with auto-blocking on violation** — Spec Kit's `/speckit.analyze` blocks implementation on constitution conflict. APEX's `DECISIONS.md` does not gate.
3. **Spec Registry / library specs to prevent API hallucinations** — Tessl's 10k-spec library. APEX has nothing.
4. **Per-feature branch and three-file decomposition as the default shape** — universal in this domain; APEX uses different conventions.
5. **Visible Kanban UI for tasks** — Backlog.md has one. APEX is terminal-only.
6. **Asynchronous detached execution that produces a PR** — Genie has it. APEX requires user-at-terminal.
7. **Directory-scoped spec inheritance** — SpecDD has it. APEX's spec scoping is global.
8. **MCP-server mode where the framework IS the tool the agent uses** — Tessl's positioning. APEX is closer to the user surface.
9. **Mindshare/distribution** — Spec Kit (105k), GSD (60k), BMAD (47k), task-master (25k) all dwarf APEX in stars.
10. **Brownfield-aware change proposals with ADDED/MODIFIED/REMOVED delta markers** — OpenSpec. APEX's `SPEC_DELTA.json` is coarser.
11. **Spec ↔ test linkage as part of spec grammar** — Tessl. APEX's `TEST_MAP.txt` is auxiliary.
12. **Microsoft-Learn-grade training material** — Spec Kit has it. APEX has none.
13. **30+ agent reach via slash-command injection** — Spec Kit. APEX claims six adapters.
14. **Enterprise distribution channel** — Kiro through AWS. APEX has none.
15. **Cross-tool session capture** — SpecStory's 200k installs across Cursor + Copilot + Claude + Codex. APEX is Claude-centric.

---

## 5. Where APEX collectively beats this domain

1. **Filesystem-quarantined auditor that cannot see implementation code** — *no other tool in this report has this*. This is APEX's single most defensible primitive in the spec-driven space.
2. **`RESULT.json` schema with `verified_criteria[]` vs `unverified_criteria[]` AND `tool_verified_criteria[]` vs `self_verified_criteria[]`** — falsifiability-by-construction. Spec Kit's `/analyze` is artifact-only; APEX checks code.
3. **9-failure-mode taxonomy with named hook per failure** (`phantom-check`, `destructive-guard`, `circuit-breaker`, `mutation-gate`, `quarantine-guard`, `memory-watchdog`, `turn-checkpoint`, `session-auto-resume`, `pre-task-snapshot`). No other SDD tool has anything comparable.
4. **Cross-model critic locked to PASS/FAIL/NEEDS_REVIEW with anti-rationalization injection** — Tessl's tests run; APEX's critic *judges*.
5. **Memory synthesis dream-cycle agent that consolidates across sessions** — no equivalent in this domain.
6. **`/apex:_debate` for irreversible decisions + `/apex:roundtable` for collaborative ones** — no other SDD tool has decision-protocol layers.
7. **Scale-adaptive classifier that pre-tunes ceremony from bug-fix to enterprise** — every other tool is one-size-fits-all (BMAD heavy, OpenSpec light, no graduated middle).
8. **Dual-mode collaborator vs replacement philosophy** — no other tool explicitly distinguishes "user is expert here" from "user is not."
9. **Pre-task snapshot in hidden git tree + one-click rollback + recovery menu** — Spec Kit, OpenSpec, SpecDD all just say "use git." APEX has actual rollback UX.
10. **Self-healing loop with two-consecutive-clean-rounds stop criterion** — no equivalent in this domain.
11. **`/apex:walkthrough` and `/apex:forensics`** — no other SDD tool has post-failure timeline reconstruction.
12. **`/apex:help` conversational navigator (no command memorization)** — Spec Kit has seven `/speckit.*` slashes to memorize; BMAD has agent invocations. APEX abstracts.
13. **`apex-workflows/` library of 30+ pre-built recipes** — closest analog is Tessl's Spec Registry, but for *processes* not *libraries*.
14. **`/apex:build` vs `/apex:refine` as separate pipelines** — every SDD tool collapses these; APEX's separation is structurally cleaner.
15. **Free forever core + paid enterprise (trust-first)** — Kiro is paid; Tessl will be paid; Spec Kit/OpenSpec/GSD are free-only. APEX's hybrid is the most credible long-term posture.

---

## 6. Strategic recommendations for APEX

In priority order — these are the moves the APEX author should make in response to this competitive landscape:

**P0 — Defend the SDD home turf within 30 days**
1. **Adopt EARS notation as the recommended grammar for acceptance criteria in `SPEC.md`.** Half a day of authoring work. Eliminates whole classes of spec ambiguity. Gives APEX 17 years of RE literature for free. *Without this, Kiro owns the formal-spec narrative.*
2. **Elevate `DECISIONS.md` to a constitution-equivalent with explicit blocking behavior.** Re-pitch it as `CONSTITUTION.md` or add a constitution layer. Have `/apex:validate-phase` and a new `/apex:analyze` flag constitution conflicts as CRITICAL (Spec Kit pattern).
3. **Build `/apex:analyze` as a cross-artifact consistency check** between `SPEC.md`, `PLAN.md`, `TASK_MAP.md`, and `DECISIONS.md`. This is a Spec Kit feature APEX must match.
4. **Adopt OpenSpec's ADDED/MODIFIED/REMOVED delta markers inside `SPEC_DELTA.json`.** One-day diff. Closes brownfield gap.

**P0 — Distribution & onboarding (existential)**
5. **Ship `apex --minimal` install** that exposes only 5-6 core commands and reduces the system prompt by ≥80% (GSD pattern). Aggressively cut APEX's onboarding cost.
6. **Build `/apex:parse-spec` (or `/apex:from-prd`) as a single-command PRD-to-TASK_MAP path** — task-master's pattern. APEX is currently over-ceremonious for the "I have a clear PRD" use case.
7. **Auto-generate `AGENTS.md` + `CLAUDE.md` at `/apex:onboard`** so any agent that opens the repo knows APEX conventions immediately (Backlog.md pattern).
8. **Publish APEX as MCP server** so any agent on any host (Cursor, Copilot, Codex, etc.) can call `apex:discuss-phase`, `apex:plan-phase` as MCP tools (Tessl pattern). This is APEX's true multi-platform play.

**P1 — Steal the best ideas (60-90 days)**
9. **Add a Milestone tier above Phase** for non-programmers who think in releases (GSD pattern).
10. **Add directory-scoped spec inheritance** — a spec at `src/billing/SPEC.md` automatically applies to all children (SpecDD pattern).
11. **Build a Kanban view rendered from `STATE.json` + `TASK_MAP.md`** — even an HTML-on-demand version (Backlog.md pattern).
12. **Make spec ↔ test linkage first-class in `SPEC.md`** — every requirement carries a `tests: [...]` field that critic + executor both read (Tessl pattern).
13. **Add `/apex:dispatch <ticket-url>`** — asynchronous detached run on a worktree that posts a PR when done (Genie pattern). This is the asynchronous endgame.
14. **Add file-save hooks (not just lifecycle hooks)** for `circuit-breaker` and friends (Kiro pattern).
15. **Capture every Claude Code session into `apex/sessions/`** as the input to memory synthesis (SpecStory pattern).

**P1 — Differentiation marketing**
16. **One-sentence head-to-head positioning vs. each top-3 threat.** Draft now: "GitHub Spec Kit checks your specs. APEX checks your code." / "Kiro brings rigor inside one IDE; APEX brings it across every agent you use." / "GSD verifies; APEX falsifies." These belong on the README above the fold.
17. **Pitch the filesystem-quarantined auditor as APEX's signature primitive.** No other SDD tool has this; it is the most defensible piece of intellectual real estate APEX owns.

**P2 — Long-term moves**
18. **Build an APEX Spec/Workflow Registry** as the network-good play (Tessl pattern). The `apex-workflows/` library is the seed; make it a publishable, discoverable, community-extensible catalog.
19. **Pursue enterprise channel partnerships** — even one ("APEX on Azure Marketplace" or "APEX-certified for Google Antigravity") begins to neutralize Kiro's AWS distribution moat.
20. **Adopt PM/UX/Scrum-Master personas as optional masks** for the architect/executor/critic functional roles (BMAD pattern). Personas are more relatable for non-programmers.

---

## 7. Sources & citations

1. https://github.com/github/spec-kit — GitHub Spec Kit official repo (105k stars, v0.8.13 May 21 2026)
2. https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/ — GitHub Blog launch post
3. https://openspec.pro/ — OpenSpec landing page
4. https://kiro.dev/ — Kiro homepage (target audience, philosophy)
5. https://kiro.dev/blog/introducing-kiro/ — Introducing Kiro blog post
6. https://learn.microsoft.com/en-us/training/modules/spec-driven-development-github-spec-kit-enterprise-developers/ — Microsoft Learn training module
7. https://www.marktechpost.com/2026/05/08/9-best-ai-tools-for-spec-driven-development-in-2026-kiro-bmad-gsd-and-more-compare/ — MarkTechPost comparative survey
8. https://intent-driven.dev/knowledge/spec-kit-vs-openspec/ — Spec Kit vs OpenSpec comparison
9. https://kiro.directory/tips/ears-format — EARS Format Complete Guide
10. https://dev.to/willtorber/spec-kit-vs-bmad-vs-openspec-choosing-an-sdd-framework-in-2026-d3j — DEV community comparison
11. https://www.augmentcode.com/guides/automating-spec-driven-development-with-ai-agents — Augment Code on traceability
12. https://tessl.io/blog/tessl-launches-spec-driven-framework-and-registry/ — Tessl Framework + Registry launch
13. https://github.com/github/spec-kit/issues/2459 — `/speckit.implement` constitution governance gap issue
14. https://deepwiki.com/github/spec-kit/4.6-constitution-system — Spec Kit constitution + analyze deep dive
15. https://kiro.dev/docs/specs/feature-specs/ — Kiro Feature Specs documentation
16. https://kiro.dev/pricing/ — Kiro pricing tiers
17. https://github.com/bmad-code-org/BMAD-METHOD — BMAD-METHOD official repo (v6.6.0, 46.7k stars)
18. https://docs.tessl.io/use/spec-driven-development-with-tessl — Tessl documentation
19. https://specdd.ai/ — SpecDD landing page
20. https://github.com/MrLesk/Backlog.md — Backlog.md official repo (5.6k stars, v1.45.1)
21. https://en.thedavestack.com/backlog-md/ — Backlog.md third-party review
22. https://specstory.com/ — SpecStory homepage (200k+ installs claim)
23. https://github.com/eyaltoledano/claude-task-master — claude-task-master official repo (~25.4k stars, v0.43.0)
24. https://github.com/eyaltoledano/claude-task-master/blob/main/docs/tutorial.md — task-master tutorial
25. https://github.com/gsd-build/get-shit-done — GSD official repo (~60k stars)
26. https://cosine.sh/ — Cosine product page ("copilot era is over")
27. https://cosine.sh/blog/genie-autonomous-software-engineer — Genie 2.0 announcement (SWE-Lancer metrics)
28. https://www.augmentcode.com/blog/what-spec-driven-development-gets-wrong — Augment Code critique of SDD pitfalls
29. https://thebcms.com/blog/spec-driven-development — BCMS "Definitive 2026 Guide" to SDD
30. https://aws.amazon.com/blogs/aws/aws-weekly-roundup-kiro-cli-latest-features-aws-european-sovereign-cloud-ec2-x8i-instances-and-more-january-19-2026/ — AWS weekly roundup with Kiro CLI features
