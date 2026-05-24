# APEX — Strategic Snapshot

> **Snapshot date:** 2026-05-25.
> **Status:** Re-runnable. NOT part of the `apex-spec.md` SSoT — this is a
> point-in-time strategic intelligence document derived from two parallel
> research swarms run on 2026-05-24. The spec defines what APEX IS; this
> document describes the competitive landscape APEX faces and the
> playbook for navigating it.
>
> **Source evidence base:** `competitive-analysis/` directory (raw
> reports, deep-research outputs, master synthesis). This document
> condenses; it does not duplicate. For depth, open the source reports
> via the pointers in each section.
>
> **Re-run protocol:** Quarterly re-run of both swarms (competitive +
> deep-research) → re-derive this document → if findings still hold,
> bump snapshot date; if findings shift materially, write a delta block
> and re-baseline.

---

## §1. The 2026 AI Dev-Tool Landscape — One Page

The AI-dev-tool landscape in 2026 is no longer one market. It is **three
overlapping markets converging on one another, each devouring the tier
above and being eaten from below**. The squeeze on APEX is structural,
not coincidental, and it is happening on all three flanks simultaneously.

**Tier 1 — The Hosts (the substrate under everyone).**
Anthropic, OpenAI, and Google form the runtime layer almost every other
tool builds on. In the past twelve months:
- **Anthropic Claude Code** shipped *Rubber Duck* critic, *Goals/Outcomes*
  auto-verification, *Managed Agents*, *Routines* (cron + GitHub-webhook
  agents), a plugin marketplace with context-cost estimates, background
  sessions, an agent dashboard, and the **Claude Agent SDK** (Python +
  TypeScript with built-in tool execution, automatic context compaction,
  parallel subagents, MCP, verification primitives). SWE-bench Verified
  jumped from 62% to 87% during 2025–2026.
- **OpenAI** committed to merging ChatGPT + Codex + Atlas into a single
  desktop "super-app" (March 2026). OpenAI Agents SDK shipped sandbox
  snapshot/rehydrate.
- **Google Antigravity 2.0** at I/O 2026 — standalone desktop + CLI + SDK +
  Managed Agents + Gemini Enterprise Agent Platform, free for individuals
  during preview. Gemini CLI being end-of-life'd into Antigravity by
  18 June 2026.

**The hosts are systematically absorbing the value of every "framework on
top of Claude Code" — including APEX. Five of APEX's nine failure modes
are now solvable with native primitives.** APEX's substrate is being
eaten from under it.

**Tier 2 — The IDEs (where developers actually live).**
- **Cursor / Anysphere** crossed $2B ARR in February 2026, raised at
  $50–60B valuation, ships in-house Composer 2.5 model (79.8% SWE-Bench
  Multilingual at 1/10 the cost of Claude Opus), Bugbot autofix (70% PR
  resolution at 2M PRs/month), 8-way parallel git-worktree agents,
  Background Agent on mobile.
- **Cognition (Devin + Windsurf)** raised at $25B (April 2026, more than
  doubling Sep 2025's $10.2B), welds Devin (autonomous, Goldman Sachs
  "Employee #1") to Windsurf (350+ enterprise customers, FedRAMP High).
  SWE-1.5 proprietary model claims 13× faster than Sonnet 4.5.
- **GitHub Copilot Agent Mode** is GA on VS Code + JetBrains. **Agent HQ**
  bundles Claude, Codex, Cognition, xAI agents into one Copilot
  subscription with mission-control governance.
- **JetBrains Junie + Junie CLI**, **Cline SDK** (5M+ installs across 7
  IDEs), **Zed 1.0 + ACP** open agent protocol, **Roo Code shut down**
  May 15 ("IDEs are not the future of coding"), **Continue.dev pivoted
  to CI checks**.

**Tier 3 — The Vibe-Coders (the non-programmer market APEX claims).**
- **Lovable** hit $200M ARR, $6.6B valuation, 25M+ projects, 100K/day,
  NVIDIA / Salesforce / Databricks / Atlassian backing.
- **AI app-builder revenue hit $4.7B in 2026, projected $12.3B by 2027.**
- **63% of vibe-coding users have zero programming background** — *the
  exact market APEX claims as its USP, except they are not adopting
  Claude-Code-plus-framework*. They are adopting Lovable, Bolt, v0,
  Replit Agent 3, Base44, Mocha because the friction of installing
  16 shell hooks and editing markdown command files is itself a wall
  non-programmers won't climb.

**The agent-buyer pool is smaller than presumed.** 2025 Stack Overflow
Developer Survey: 84% of devs use AI but only 29% trust it. 52% of devs
don't use agents at all. 38% have no plans to. The trust gap is real —
and APEX's falsifiability/auditor-quarantine story is uniquely good at
addressing it — but only if users adopt agents in the first place.

**Funding signals threat magnitude.** Cursor $50–60B. Cognition $25B.
Lovable $6.6B. Factory $1.5B. Augment Code $227M. Money is consolidating
around 3–4 mega-platforms (GitHub/Microsoft, AWS, Cognition, JetBrains,
possibly Augment) plus a tail of specialists. APEX is exactly the
anti-consolidation play — but anti-consolidation requires distribution
which APEX lacks.

> 📄 **Source depth:** `competitive-analysis/reports/00-threat-matrix.md`
> + `competitive-analysis/MASTER-COMPETITIVE-ANALYSIS.md`

---

## §2. The 15 Most Threatening Individual Competitors (Ranked)

| # | Competitor | Threat | What it threatens | Time-to-impact |
|---|---|---|---|---|
| 1 | **Claude Code (Anthropic)** | CRITICAL | Substrate. Native Rubber Duck + Goals + Managed Agents + Routines + Agent SDK collapse APEX failures 1, 3, 5, 7, 8 into native primitives. | Now and accelerating |
| 2 | **Cursor / Anysphere** | CRITICAL | Failures 3, 4, 9 + the entire IDE-vs-CLI question. Plan Mode + Background Agents + Composer 2.5 + Bugbot. $2B ARR, $50B+ valuation. | Already mature |
| 3 | **Cognition (Devin + Windsurf)** | CRITICAL | The entire "autonomous coding" premise + enterprise dollars. $25B valuation, Goldman Sachs / Citi / Nubank deployments. | 6–12 months until fully welded product |
| 4 | **Lovable** | CRITICAL | APEX's non-programmer USP. $200M ARR, 25M projects, 63% non-coder users. Owns vibe-coding mindshare. | Already lost in vibe-coding category |
| 5 | **Claude Agent SDK** | CRITICAL | APEX's identity as "the framework on Claude Code." Official, blessed, version-stable substrate. Any third party can build "APEX-lite" in a weekend. | Now |
| 6 | **GitHub Copilot Coding Agent + Agent HQ** | CRITICAL (enterprise) | Distribution + multi-vendor agent orchestration bundled with GitHub Enterprise. Microsoft is becoming an aggregator. | Already pervasive in enterprise |
| 7 | **Cline (`@cline/sdk`)** | HIGH | Open-source agent runtime position. 61K+ stars, 5M+ installs, Apache 2.0, model-agnostic by construction. APEX's architectural twin. | 3–6 months |
| 8 | **Superpowers (obra/superpowers)** | CRITICAL (Claude-Code-native) | "Default what should I install" for Claude Code. ~150–200K stars in 7 months. Anthropic-marketplace blessed. TDD enforcement deletes code. | Now |
| 9 | **OpenHands (open-source autonomous)** | CRITICAL (open-source) | Open-source autonomous coding leader. 70K stars, 490 contributors, $18.8M funded, 77.6% SWE-bench Verified, **open issue #9482 literally titled "Implement Claude Code Hooks for OpenHands"**. | Now |
| 10 | **GSD (TÂCHES)** | CRITICAL (Claude-Code-native) | Fastest growth in framework category: ~60K stars in 5 months. Same lean-ceremony positioning APEX targets. Already at FAANG. | Now |
| 11 | **GitHub Spec Kit** | HIGH | Spec-driven brand globally. 105K stars. Microsoft training course. Constitution-as-critical-blocker pattern. 30+ agent reach. | Now |
| 12 | **AWS Kiro** | HIGH | Only commercial enterprise-grade SDD IDE. Enforces EARS notation (zero-cost grammar win APEX hasn't adopted). AWS distribution. | Now |
| 13 | **Lovable + Bolt + v0 (vibe-coding category)** | CRITICAL (non-programmer flank) | The entire non-programmer category is going to browser-based zero-setup tools. APEX requires npm + git + test framework. | Lost as primary touch; opportunity as second-stage hardening tool |
| 14 | **Augment Code (Auggie + Cosmos)** | HIGH | $227M funded, #1 on SWE-bench Pro (51.80%), **first AI coding tool with ISO/IEC 42001 + SOC 2 + CMEK + on-prem GPU**. Cosmos preview is multi-agent orchestration. | Now in enterprise |
| 15 | **Strands Agent SOPs (AWS)** + **Skills.sh / Claude Marketplace** | HIGH (standards + distribution) | AWS Agent SOPs is a published cross-framework standard for markdown workflows — APEX's `apex-workflows/` library risks being out-standardized. Atomic-skill marketplaces eat monolithic frameworks. | 6 months for SOPs to consolidate; Skills.sh is now |

**Honorable mentions outside the top 15:** Replit Agent v3 (#1 non-dev autonomy with 200-min runtime + REPL self-test); BMAD-METHOD (intellectual parent APEX literally borrowed from, 47K stars, PASS/CONCERNS/FAIL/WAIVED gate granularity worth stealing); Mem0/Letta/Zep/Cognee (memory category exploding); Factory.ai Droids ($1.5B Khosla raise, Knowledge Droid pattern); Live-SWE-agent / mini-SWE-agent (79.2%/74% SWE-bench with minimal scaffolds — existentially questions whether elaborate frameworks earn their complexity).

> 📄 **Per-competitor depth:** `competitive-analysis/reports/00-threat-matrix.md` (cross-cutting), plus `reports/01-claude-code-native.md` through `reports/10-no-code-vibe.md` (one report per domain).

---

## §3. Per-Domain Headlines (10 Domains)

For full depth, open `competitive-analysis/reports/0N-name.md`. Headlines only here:

### Domain 01 — Claude-Code-Native Frameworks
**Headline:** Superpowers (~200K stars in 7 months), GSD (~60K in 5 months), gstack (~97K) emerged as the "default what should I install" answers for Claude Code. Distribution beats rigor — APEX's nine-failure-mode taxonomy is invisible against a 200K-star competitor with a one-line install. **Threat level: Critical.**

### Domain 02 — IDE-Embedded AI Agents
**Headline:** Cursor at $50B with Composer 2.5 in-house model at 1/10 Claude cost + Bugbot at 70% PR resolution + Background Agents on mobile. Cline at 5M+ installs across 7 IDEs released `@cline/sdk` (May 2026). **Roo Code (3M+ installs) shut down May 15** concluding "IDEs are not the future of coding." **Threat level: Critical.**

### Domain 03 — Autonomous Commercial Agents
**Headline:** Cognition Devin ($25B, SWE-1.5, Goldman Sachs deployment) + Replit Agent v3 (200-min autonomy, REPL-based browser self-test detecting Potemkin interfaces) + Factory.ai Droids ($1.5B Khosla raise). **Devastating ammunition for APEX:** Lovable shipped 170 production apps with CVE-2025-48757 (CVSS 9.3); Devin generated a data-deleting migration script; Replit Agent stored passwords in plain text. APEX's destructive-guard + auditor + verified/unverified contract would catch all three. **Threat level: Critical.**

### Domain 04 — Multi-Agent Orchestration Frameworks
**Headline:** LangGraph (32.8K stars, 34.5M monthly downloads, Cisco/Uber/LinkedIn/JPMorgan) shipped **Deep Agents** in March 2026 — `write_todos` + virtual filesystem + sandboxed shell + `task` subagent tool = roughly half of APEX's executor primitives in one pip install. AWS Strands (14M+ downloads) shipped **Agent SOPs** — portable across Strands / Kiro / Cursor / Claude / GPT-4. **Threat level: Critical (LangGraph); High (Strands).**

### Domain 05 — CLI Agent Tools
**Headline:** Aider remains the open-source king (~41K stars, 5.3M PyPI downloads, ~4.2× fewer tokens per task than Claude Code). opencode hit 147K stars by April 2026 with explicit "hedge against Anthropic" pitch. Amp's **"Oracle"** (separate GPT-5 model consulted by main Claude agent) is the only commercial CLI shipping a clean-room cross-model critic. **Threat level: Critical (Claude Code as substrate); Very High (opencode, Goose).**

### Domain 06 — Spec-Driven & Planning-First Frameworks
**Headline:** GitHub Spec Kit (105K stars) owns the spec-driven brand globally. AWS Kiro (commercial, $20–$200/mo) enforces **EARS notation** for acceptance criteria. **GSD's growth (60K stars in 5 months) is the existential threat:** same lean-ceremony positioning APEX targets, already at FAANG, Claude-Code-native. **Threat level: Critical.**

### Domain 07 — Enterprise AI Coding Platforms
**Headline:** GitHub **Agent HQ** (control plane bundling Claude + Codex + Cognition + xAI agents under one Copilot subscription). **Augment Code** ($227M funded, **first AI coding tool with ISO/IEC 42001** + SOC 2 + CMEK + on-prem GPU + #1 on SWE-bench Pro at 51.80%). **Windsurf Enterprise** = FedRAMP High via Palantir FedStart on AWS GovCloud. **Threat level: Critical (Agent HQ); High (Augment, Amazon Q, Windsurf-FedRAMP).**

### Domain 08 — Open-Source Autonomous SWE Agents
**Headline:** **OpenHands** (70K stars, 490 contributors, $18.8M funded, 77.6% SWE-bench Verified) — with **open GitHub issue #9482 literally titled "Implement Claude Code Hooks for OpenHands."** **Live-SWE-agent / mini-SWE-agent** (79.2% / 74% SWE-bench Verified with minimal scaffolds) existentially questions whether elaborate frameworks earn their complexity. **Threat level: Critical (OpenHands); High (minimal-scaffold challenge).**

### Domain 09 — Memory & Context Systems
**Headline:** **Anthropic's native memory tool + Auto-Dream + CLAUDE.md hierarchy** — the platform vendor now ships persistent memory + dream-cycle consolidation natively for free across all tiers. **APEX's Memory Synthesis differentiator is becoming table stakes.** **Letta** ships sleep-time compute, git-backed memory, memory defragmentation. **claude-mem** at 77.8K stars is the dominant Claude Code memory plugin. **Threat level: Critical (Anthropic native, Letta); High (claude-mem distribution).**

### Domain 10 — Non-Programmer / Vibe Coding
**Headline:** **Lovable** at $200M ARR / $6.6B valuation owns APEX's exact USP audience. **Replit Agent 3** at $9B with mature infra and real self-testing loop. **v0 (Vercel)** Feb 2026 relaunch added agentic capability. **Biggest gap APEX has:** First-touch UX. Every competitor is open-browser → describe-app → see-preview. APEX requires npm install + git + test framework. **Threat level: Critical (for APEX's stated non-programmer audience).**

---

## §4. The Five Existential Risks to APEX's Category

Five threats that aren't single tools but **trends** — each could end APEX's market category, not just challenge it:

1. **Anthropic eats the substrate.** Claude Code's native critic (Rubber Duck), auto-verifier (Goals/Outcomes), managed agents, routines, and Agent SDK collapse APEX's failure-mode taxonomy from "9 things APEX uniquely solves" to "9 things Anthropic now solves natively." When the host ships your features, your framework becomes a wrapper around obsolete primitives.

2. **Non-programmer market consolidates on hosted vibe-coding tools.** Lovable, Bolt, v0, Replit, Base44, Mocha are eating the entire non-programmer category before APEX reaches it. CLI-based pipelines become a dev-only niche regardless of APEX's "non-programmer-first" messaging, because non-programmers will never install 16 shell hooks.

3. **The agent-buyer pool stays small.** Stack Overflow 2025: 52% of devs don't use agents, 38% have no plans to. Trust dropped from 40% (2024) to 29% (2025). APEX's TAM may be smaller than presumed.

4. **The unit of value becomes the skill, not the framework.** Skills.sh + Claude Marketplace + Spec Kit ecosystem reward composable atomic units (`npx skills add`) over monolithic frameworks. Same story that killed monolithic JS frameworks vs. npm packages in 2014–2018.

5. **Vibe-coding's technical-debt backlash creates a *different* market APEX could serve — or miss.** 45% OWASP Top 10 rate; CVE counts up 5× in 3 months; technical debt up 30–41%. Either APEX positions as the hardening layer and rides this wave — or specialized "AI-debt remediation" tools take that market in 2026–2027.

---

## §5. The Five APEX Moats — Honest Assessment

Three strong, two weaker than the framework's marketing suggests, plus one sixth uncovered by deep research.

### Strong moats

1. **The 9-failure-mode taxonomy as a teaching artifact.** Naming failure modes ("phantom-check", "scope-creep detector", "mutation-gate", "test-deletion-guard") is doctrinal IP. No competitor has packaged AI-coding failures into a memorable, falsifiable taxonomy. **Vocabulary is sticky** — once devs learn "phantom check," they look for it everywhere. Even if Anthropic ships every mechanism natively, APEX still owns the *language* used to discuss them.

2. **Filesystem-quarantined auditor.** No public competitor has the architecture where the auditor agent *physically cannot read implementation code* — only test files. Anthropic's Rubber Duck runs in a fresh context window but isn't filesystem-isolated. Cursor's Bugbot sees everything. Junie's inspections run inside the IDE process. **Real, copyable-but-not-trivial moat for 12–18 months.**

3. **Two-consecutive-clean-rounds self-healing stop-criterion + Wave 0 enforcement + scale-adaptive classifier.** These are stop-criteria designs nobody else has. They reflect real engineering taste. They will hold because they encode *judgment*, and competitors keep optimizing for the wrong thing (capability) rather than for *knowing when to stop*.

### Weaker moats than the author may think

4. **"Non-programmer-first" positioning.** *Weaker than claimed.* A non-programmer will not edit 11 markdown commands and 16 shell hooks. The brand says "non-programmer-first" but the artifact says "developer-with-discipline." Either (a) build a true non-programmer surface (web UI / chat-only mode / one-line installer) or (b) honestly reposition as "for the developer who treats their craft seriously." **The current copy-vs-artifact mismatch is killing conversion.** (Note: position #11 — Dual-Mode — partly resolves this by saying APEX is collaborator for product decisions and replacement for technical decisions; the spec has chosen Dual-Mode as the answer.)

5. **Multi-platform via thin adapters.** *Weaker than claimed.* In practice the framework is deeply Claude-Code-shaped. Cline SDK is more genuinely multi-platform (5M installs across 7+ IDEs). Spec Kit works with 30+ agents out of the box. APEX's adapter story needs hardening or honest scoping.

### The sixth moat (uncovered by deep-research, not by competitive intel)

6. **AI-system safety.** Microsoft MDASH, Big Sleep, Anthropic Research, Team Atlanta — none publish guardrails for the agent's own reasoning loop. APEX has destructive-guard + plan-mode + ecosystem-10Q gate. **This is a moat the competitive landscape doesn't surface because the disclosed competition isn't even trying.** Documented and called out as a discriminator.

---

## §6. The 11 High-Confidence Consensus Claims (Research)

Eleven things every research source agreed on. If APEX violates any of them, fix first. These also feed into `apex-spec.md` as the "Research-Validated Consensus" sub-section of Working Principles.

| # | Consensus claim | Sources |
|---|---|---|
| 1 | **The harness is most of the engineering; the model is a swappable input.** | Microsoft (Kim verbatim), Manus, Anthropic, Karpathy |
| 2 | **Context engineering is now a named discipline** distinct from prompt engineering. | Anthropic (coined), Manus, LangChain, Karpathy, Microsoft |
| 3 | **Long context degrades non-uniformly — "context rot" is empirical.** Effective window << stated window. | Anthropic, Chroma 18-model study, Manus L3, Lance Martin |
| 4 | **File system is the right substrate for agent memory** — restorable, persistent, agent-operable. | Anthropic (Pokémon agent, Claude Code), Manus L3, Anthropic memory tool, LangChain Write |
| 5 | **Compression must be restorable** — drop the expanded form, keep the identifier (path/URL/query). | Anthropic (just-in-time), Manus L3, LangChain (Compress lever) |
| 6 | **Multi-agent costs ~15× tokens vs. chat AND is a bad fit for most coding tasks.** | Anthropic (explicit, twice), Cognition ("Don't Build Multi-Agents"), Manus, Microsoft |
| 7 | **Sub-agents work for narrow well-defined sub-tasks with structured returns; fail for coupled creative work.** | Anthropic 90.2% lift on research eval, Manus Wide Research, Cognition Flappy Bird failure, Microsoft |
| 8 | **Verification is the single highest-leverage practice.** | Anthropic ("the single highest-leverage thing you can do"), Karpathy ("Goal-Driven Execution"), Microsoft (oracles + provers), Manus L5 |
| 9 | **Anti-overengineering / "biggest gains came from removing things."** | Karpathy (4 rules), Anthropic (verbatim block), Manus (5 rewrites), Schmid, Vercel (80% tool cut) |
| 10 | **Errors must be preserved in context, not cleaned up.** Erasing failure removes the evidence the model needs to adapt. | Manus L5 verbatim, Anthropic durable execution, Team Atlanta (oracles + ASAN traces retained) |
| 11 | **Stable prefix + diverse user content** is the cache-hygiene rule. Single-token differences invalidate KV-cache. | Manus L1 (10× cost ratio), Anthropic (cache_control), Microsoft (configurable model-agnostic harness) |

The **one major debate** the sources do NOT resolve: how much sub-agent ceremony is right for coding. Anthropic and Cognition lean against; Manus uses it tactically; Microsoft uses it heavily but for security pipelines. APEX's position: multi-agent only for `/apex:build` and `/apex:full`, DECISIONS.md as single source of truth, `/apex:fast` and `/apex:quick` skip multi-agent ceremony by design.

> 📄 **Full doctrinal context:** `competitive-analysis/deep-research-2026-05-24/SYNTHESIS.md` + reports `01-anthropic-tool-use-memory.md` through `05-microsoft-agentic-security.md`. The 27 doctrinal upgrades derived from these are integrated into `apex-spec.md` as IMP-DR-001 through IMP-DR-027.

---

## §7. The Steal-Worthy 30-Item Master Table

Each item carries: source (competitor or research line that surfaced it), priority, effort, doctrinal cross-ref to `apex-spec.md`, and why. **Double-confirmed** items (rows 4, 5, 8, 30) appear in both research swarms and have the highest shipping ROI.

| # | Idea | Source | P | Effort | Doctrine x-ref | Why |
|---|---|---|---|---|---|---|
| 1 | **EARS notation for acceptance criteria** | Kiro (Domain 06) | P0 | 0.5 day | — | Eliminates whole classes of ambiguity; gives APEX 17 years of RE literature for free |
| 2 | **Focus Chain — re-inject active task list every N messages** | Cline (Domain 02) | P0 | 3 days | IMP-DR-013 (recitation cost — bound by frequency) | Direct fix to APEX failure-mode #3 (context loss); lowest-effort highest-impact |
| 3 | **Adopt AGENTS.md as APEX's public surface** | Multi (Domains 02/05) | P0 | 1 week | — | Without this, APEX users on Cursor/Windsurf/Kilo get worse experience than native |
| 4 | **Ship as Skills.sh + Claude Marketplace skills (atomic decomposition)** | Skills.sh (Domain 00) | P0 | 3 weeks | — *DOUBLE-CONFIRMED* | Reverses "install whole framework" friction; every skill is a funnel |
| 5 | **Apply for Anthropic plugin marketplace inclusion** | Anthropic (Domain 01) | P0 | 1 week | — *DOUBLE-CONFIRMED* | Without this, APEX is one click harder to install than Superpowers/SuperClaude |
| 6 | **PASS / CONCERNS / FAIL / WAIVED gate granularity (P0–P3)** | BMAD (Domains 01/06) | P0 | 1 week | IMP-DR-004 (`approved-with-noise` verdict) | Strictly better than APEX's binary outcome |
| 7 | **Per-tool-call shadow-git checkpoints** | Cline (Domains 02/05) | P0 | 1 week | — | Match Cline's granularity via PostToolUse hook |
| 8 | **Event-sourced EventLog with deterministic replay** | OpenHands (Domain 08) | P0 | 2 weeks | IMP-DR-009 (failure-preservation invariant) — *DOUBLE-CONFIRMED* | Forensics, regression testing, A/B hook comparison become free byproducts |
| 9 | **Adopt Strands Agent SOPs format for workflows** | Strands (Domain 04) | P0 | 3 weeks | — | Protects against being out-standardized; portability across Strands/Kiro/Cursor ecosystem |
| 10 | **Auto-snapshot per agent turn with visible undo UI** | Lovable (Domains 03/10) | P0 | 1 week | — | APEX has the mechanism; UX is buried |
| 11 | **REPL-based runtime Potemkin detection (Playwright)** | Replit (Domain 03) | P0 | 2 weeks | — | Catches runtime equivalent of phantom-check |
| 12 | **`npx create-apex` 5-minute installer for non-programmers** | Multi (Domains 00/10) | P0 | 2 weeks | — | Closes 80% of conversion-killing setup-friction gap |
| 13 | **Branch-per-chat-session (every conversation = recoverable branch)** | v0 (Domain 10) | P0 | 3 days | — | Trivial implementation, transformative non-programmer UX |
| 14 | **Aider's tree-sitter + PageRank repo map (live, self-tuning)** | Aider (Domain 05) | P1 | 2 weeks | — | Replaces hand-authored TASK_MAP.md |
| 15 | **Delta markers (ADDED/MODIFIED/REMOVED) per requirement** | OpenSpec (Domain 06) | P1 | 1 day | — | Closes APEX's brownfield gap |
| 16 | **Auto-indexed repo Wiki + Codemap visual** | Devin/Factory (Domain 03) | P1 | 3 weeks | — | Visible architectural document refreshed on a hook |
| 17 | **Knowledge-Droid pattern (persistent retrieval layer)** | Factory (Domain 03) | P1 | 4 weeks | IMP-DR-024 (per-agent persistent memory) | Dedicated indexer downstream agents query instead of re-reading source |
| 18 | **`apex-from-lovable` / `apex-from-bolt` / `apex-from-replit` import workflows** | Multi (Domains 03/10) | P1 | 2-3 weeks each | — | Rides vibe-coding-debt backlash; positions APEX as hardening layer |
| 19 | **Hash-chained tamper-evident event-log + 180-day retention** | EU-AI-Act/ISO 42001 (Domain 07) | P1 | 1 week | IMP-DR-008 (event-log integrity) | Compliance bar; matches enterprise audit specs |
| 20 | **Letta's Context Repositories (git-backed memory + sleep-time reflection)** | Letta (Domain 09) | P1 | 1 week | IMP-DR-024 — complementary | `.apex/` is already in git — days of work |
| 21 | **Cline-style Auto-approve granularity (per-category permission profiles)** | Cline (Domain 02) | P1 | 1 week | — | Better than per-task approval |
| 22 | **MCP-server mode for APEX (expose APEX as MCP tools any agent can call)** | Tessl (Domain 06) | P1 | 2 weeks | — | Bypasses entire "skill vs plugin vs hook" install debate |
| 23 | **Glass-cockpit TUI for parallel waves (Kanban board)** | Cursor/Windsurf/Zed (Domain 02) | P1 | 3 weeks | — | STATE.json + `jq` is technically equivalent but UX-deficient |
| 24 | **"Delegate to cloud, get a PR" via GitHub Actions** | VS Code Cloud Agent (Domains 02/07) | P1 | 3-4 weeks | — | Closes Roo Code "IDEs aren't the future" thesis gap |
| 25 | **Constitution-as-blocker layer (above SPEC.md, blocks on violation)** | Spec Kit (Domain 06) | P1 | 1 week | — | Adopts winning SDD vocabulary |
| 26 | **Path-based spec inheritance (directory-scoped)** | SpecDD (Domain 06) | P1 | 1 week | — | Spec at `src/billing/` auto-applies to all child files |
| 27 | **Stream-autofixer hook (catches missing imports / broken JSON in-stream)** | v0 LLM Suspense (Domain 03) | P2 | 2 weeks | — | Pure cost win — failed agent rounds get expensive |
| 28 | **Pay-by-outcome pricing for paid services (phase shipped / workflow completed)** | Cosine (Domain 03) | P2 | Business decision | — | Maps to non-programmer mental model |
| 29 | **Voice prompting (Kilo Code) + Mobile control surface** | Kilo/Cursor (Domain 02) | P2 | 4-6 weeks | — | Non-programmer accessibility wins |
| 30 | **Multi-model "ask the Oracle" critic-as-second-opinion UX** | Amp Oracle (Domain 05) | P2 | 2 weeks | IMP-DR-015 (cross-provider second opinion) — *DOUBLE-CONFIRMED* | APEX's clean-room critic is buried; surface it as a marketable feature |

---

## §8. 30-Day Strategic Roadmap

Three high-leverage external moves + five doctrinal quick wins, shipped in parallel.

### Move 1 (External, ≤30 days, P0) — Ship APEX as Skills.sh + Claude Marketplace skills

**Why first:** Addresses threats #1 (Claude Code), #5 (Agent SDK), #15 (Skills.sh/Marketplace). Closes the *distribution gap* that makes APEX invisible vs. Superpowers (~200K stars), GSD (~60K stars), Spec Kit (105K stars).

**Decomposition:**
- ~16 hooks → ~16 atomic skills (one per failure-mode hook: `apex-phantom-check`, `apex-destructive-guard`, `apex-mutation-gate`, `apex-circuit-breaker`, etc.)
- ~11 slash commands → ~11 command skills (`apex-next`, `apex-build`, `apex-refine`, etc.)
- ~30 workflow recipes → published in **Agent SOPs format** (not APEX-proprietary, for portability)
- Result: ~57 publishable skills, each individually installable, each a funnel into the integrated framework

**Acceptance criteria:** All 16 hook-skills installable via `npx skills add apex-<hookname>` and via Claude Marketplace `/plugin install`. README on each skill links to the integrated framework. Marketplace metadata: "Part of the APEX framework — install all with `npx skills add apex-all`".

### Move 2 (External, ≤30 days, P0) — Publish "APEX vs Native Claude Code 2.1 Delta"

**Why second:** Anthropic shipped Rubber Duck + Goals + Routines + Managed Agents + Agent SDK in May 2026. **Every reviewer will publish a "do you still need APEX?" article in the next 90 days.** APEX must publish first with a credibility-protective honest analysis.

**Content:** Two-column table: "Native Claude Code 2.1 provides" vs "APEX uniquely adds". Be honest: what's now redundant (acknowledge it), what's still uniquely APEX (lead with it). Uniquely APEX: filesystem-quarantined auditor, 9-failure-mode named hooks, scale-adaptive classifier, dual-mode philosophy, self-healing loop with two-consecutive-clean-rounds, falsifiable RESULT.json schema, multi-platform via thin adapters, free-forever core. Add benchmark plan: APEX-on-Claude-Code-2.1 vs Native-Claude-Code-2.1 on a real bug-fixing benchmark, scoring verified vs unverified claims per task.

### Move 3 (External, ≤30 days, P0) — Audience Decision (already addressed by Dual-Mode position)

**The competitive intel framed this as Path A (commit to non-programmers) vs Path B (reposition to disciplined developers).** APEX's spec position #11 (Dual-Mode: Collaborator AND Replacement) has already chosen the answer: APEX is non-programmer-first BUT also acknowledges that the user is the expert in product decisions (collaborator mode) while APEX is the expert in technical decisions (replacement mode). This is the third path the competitive intel didn't articulate — APEX has chosen it.

**What still needs work:** First-touch UX. Even with Dual-Mode philosophy, the install friction (npm + git + test framework + 16 shell hooks) blocks non-programmers from ever experiencing the philosophy. Consider:
- `npx create-apex` 5-minute installer (item #12 in steal table)
- Optional web UI / chat-only mode for the most-common flows
- Pre-installed bundle (Docker / VM image)

### The Five Doctrinal Quick Wins (Internal, ≤30 days, P0)

Shipped via apex-spec.md integration (Phase 2 of this snapshot's implementation):

1. **IMP-DR-001 — Anti-overengineering armor** (Karpathy 4 rules + Anthropic verbatim block) in executor + critic. ~30 lines per agent. **Highest ROI single change.**
2. **IMP-DR-002 — Tradeoff-disclosure preamble** in `apex-spec.md`. Resolves user's documented "feels heavy" complaint by formalizing `/apex:fast` → `/apex:quick` → `/apex:build` → `/apex:full` tier philosophy.
3. **IMP-DR-003 — Assumption-block floor** before code in executor. Complements user's existing ecosystem-10Q ceiling. Three-bullet cap.
4. **IMP-DR-006 — KV-cache hygiene audit.** Strip sub-minute timestamps from hook output. Enforce sorted JSON keys. 10× cost ratio (Manus L1) is unignorable.
5. **IMP-DR-009 — Failure-preservation invariant.** `FAILURES.md` per phase. No agent may delete failure traces. Critic + verifier MUST read them. Adds `failures_seen[]` field to `RESULT.json`.

**Compound effect:** The three external moves get APEX in front of new audiences. The five doctrinal upgrades make sure those new audiences encounter a framework whose behavior matches its claims — light when appropriate, rigorous when warranted, never silently bloating, never burying failures.

---

## §9. 90-Day Medium Moves

Three follow-ons that build on the 30-day foundation.

### Move 4 (≤90 days, P1) — Rebuild APEX runtime on Claude Agent SDK + Cline SDK

**Why:** Stop competing with the substrate; ride it. Replace shell hooks with SDK lifecycle plugins where possible. Maintain shell-script fallback for edge cases. This makes APEX feel native, type-safe, npm-installable — and aligns with where the ecosystem is going (threats #1, #5, #7).

**Outcome:** `pip install apex-discipline` + `npm install @apex/discipline` as official installers.

### Move 5 (≤90 days, P1) — Build First-Class Adapters for Cursor + Antigravity + Copilot

**Why:** Make APEX's STATE.json / SPEC.md / glass-cockpit visible inside the IDEs where ~80% of developers live. Multi-platform must be *real* not aspirational (closes threats #2, #6, #7; converts weak moat #5 into a strong one).

**Outcome:** Each adapter has IDE sidebar panel showing APEX phase/wave/task state, native APEX command palette, AGENTS.md ↔ SPEC.md two-way bridge, cloud-run option using IDE's existing cloud-agent infrastructure (Cursor Background Agents, VS Code Cloud Agent, Antigravity Managed Agents).

### Move 6 (≤90 days, P1) — Ship "Vibe-Coding Hardening" Workflow Suite

**Why:** Stop fighting Lovable / Bolt / Replit head-on; ride the security-debt backlash. Be the second-stage tool a non-programmer reaches for after vibe-coding gets them to MVP.

**Outcome:** Three workflow recipes:
- `apex:from-lovable` — imports a Lovable project, audits RLS / auth / secret rotation / OWASP top 10, generates fix plan, applies fixes with `/apex:execute-phase`
- `apex:from-bolt` — same for Bolt projects (no integrated backend assumption)
- `apex:from-replit` — same for Replit Agent projects (notorious for plaintext passwords + Potemkin interfaces — APEX has phantom-check and destructive-guard for both)

**Each ships with a public case study:** "We ran apex:from-lovable on the 170 apps from CVE-2025-48757 — here's how many issues we caught, here's the audit trail." This is *free distribution.*

---

## §10. The 12-Month Bet — APEX-Verified

A paid certification + audit-trail service that monetizes the **one thing APEX uniquely owns** that competitors can copy mechanisms but not earned trust.

### Why this works

**The trust gap is real.** 29% of devs trust AI tools (down from 40% in 2024). 66% report frustration with "AI almost-right-but-not-quite." This is exactly the failure mode APEX's falsifiability addresses.

**The security backlash is real.** 45% of AI-generated code has OWASP Top 10 vulnerabilities. CVE counts from AI code went from 6 in January 2026 to 35 in March 2026. Technical debt rose 30–41% post-AI-tool adoption.

**These two facts create a new market:** *third-party verification that an AI-coded app meets a published quality bar.*

**APEX has the only architecture suited to this market:**
- `RESULT.json verified_criteria[] vs unverified_criteria[]` + tool-verified vs self-verified split
- Filesystem-quarantined auditor (no other public tool has this)
- `event-log.jsonl` + `STATE.json` as an evidence chain
- Phantom-check / destructive-guard / mutation-gate / quarantine-guard hooks with named failure detection

### The product

**"APEX-Verified" badge** for apps that pass a defined audit:
- Every commit traces to a spec line (`originating_requirement_id`)
- Every claim verified (`verified_criteria[]`, no orphaned `unverified_criteria[]`)
- No skipped tests (test-deletion-guard never triggered)
- No phantom-check triggers (no "desperate hack", no `# XXX hack`, no cover-up patterns)
- Full audit trail with hash-chained event-log meeting ISO/IEC 42001 specs
- ISO/IEC 42001-mapped controls per AI Management System standard

**APEX Cloud** runs the verification suite against any repo *regardless of which AI tool generated the code* — Cursor, Devin, Claude Code, Copilot, OpenHands, Lovable, Bolt, all fair game.

**B2B sale targets:**
- **Cyber insurers** pricing AI-generated-code risk
- **Procurement teams** at regulated industries (finance, healthcare, gov)
- **App marketplaces** (Apple, Google Play, Salesforce AppExchange, AWS Marketplace)
- **Open-source consumers** (Sonatype, Snyk audience)
- **Enterprise dev teams** under EU AI Act compliance pressure

### Why this is bet-the-company

1. **It monetizes the *one thing APEX uniquely has*** (falsifiability schema + auditor quarantine) without depending on whether users adopt the framework.
2. **It scales independently of whether Anthropic eats the substrate** — even if Claude Code 3.0 ships a native critic, the certification mark belongs to APEX.
3. **It gives APEX a defensible moat against well-funded competitors** who can copy mechanisms but not earned-trust certifications.
4. **It creates a brand that survives even if the open-source framework is forked.**

**If Anthropic ships every primitive APEX has, APEX still owns the certification mark. That's the only moat funding rounds can't buy through.**

Parallel: Snyk monetized vulnerability data as a commodity *while keeping the underlying detection logic open-source*. Guy Podjarny is now doing it again with Tessl's Spec Registry. APEX should run the same play with verification artifacts.

---

## §11. Quick-Win Shortlist (If You Do Only 5 Things)

If only five total moves can ship — combining external and internal — these five give APEX the most ground per dollar:

1. **IMP-DR-001 (anti-overengineering prompt block) + External move 1 part 1** — Anti-overengineering prompt block, shipped as a standalone Skills.sh skill (`apex-anti-bloat-armor`). One change, two delivery surfaces. Demonstrates APEX's discipline in 30 lines that any user can copy-paste even without installing the rest of the framework.
2. **IMP-DR-006 — KV-cache hygiene audit.** Cost ratio 10×. No-brainer. One afternoon.
3. **External move 2 — APEX vs Native Claude Code 2.1 delta document.** Before reviewers write it for you. One week.
4. **External move 1 part 2 — Anthropic plugin marketplace submission.** Double-confirmed by both swarms. Get APEX one click away from any Claude Code user. One week.
5. **First-touch UX decision** — commit to `npx create-apex` 5-min installer (Path A operationalized through Dual-Mode) or formally reposition to disciplined-developer audience and stop talking about non-programmers. The cost of the current middle position is paid every week APEX exists.

This shortlist deliberately mixes "build" with "ship" with "decide" — because the binding constraint on APEX right now isn't engineering capacity; it's strategic clarity. The doctrinal upgrades reduce silent quality decay; the external moves make APEX discoverable; the marketplace submission compounds both.

---

## §12. Surprises Worth Knowing

Things from the research that contradicted prior assumptions or were genuinely new:

- **Anthropic's Mythos 83.1% on CyberGym is "a vendor claim" — they didn't publish the harness.** Same for Microsoft's 88.45%. Vendor benchmarks without harness disclosure are not evidence. (Operating principle behind IMP-DR-026 methodology disclosure requirement.)
- **Smaller models often beat larger ones on bounded sub-tasks** (Team Atlanta with GPT-4o-mini). The budget profile isn't an apology — it's sometimes the *correct* choice.
- **Manus's recitation pattern (Lesson 4) was REPEALED in their 5th rewrite** because it cost 30% of tokens. The original blog post is partially out-of-date. APEX's spec entry mechanism (in v8 circuit-breaker) is recitation-shaped — instrument and measure (IMP-DR-013) before doubling down.
- **Anthropic concedes their own compaction "isn't sufficient"** for production-grade web apps. The harness layer (filesystem + git + structured tests) is essential. This validates APEX's existence as a category — Anthropic is publicly telling users they need exactly what APEX provides.
- **Models perform BETTER on shuffled haystacks than logically structured ones** (Chroma 18-model study). Counter-intuitive — implies APEX should not always sort files alphabetically when loading multiple.
- **Claude Sonnet 4.6+ tracks its own remaining context natively.** Anthropic's recommended prompt: *"do not stop tasks early due to token budget concerns"* — the model now reasons about budgets. APEX's `context-monitor.sh` is partially redundant for newer models (but still a useful safety net).
- **The memory tool has a documented prompt-injection vector** ("memory poisoning"). APEX's `STATE.json` + `MEMORY.md` pattern needs the same mitigation: instruct agents to treat memory content as data, not instructions.
- **Manus was acquired by Meta for $2-3B in Dec 2025** (blocked by China April 2026). Their post is no longer an independent voice — track whether post-acquisition Manus continues publishing.
- **WebFetch's summarizer refused to reproduce MIT-licensed CLAUDE.md verbatim** citing "appropriate boundaries for content reuse." Bypassed via `gh api`. Worth knowing for future verbatim-capture research.
- **Anthropic explicitly warns against frameworks** in their own Building Effective Agents post. APEX's defense: every behavior must be traceable to a plain markdown agent prompt or a shell hook. The spec should explicitly say: *"If you cannot trace any APEX behavior to a markdown agent prompt or a shell hook, it is a bug."*
- **Roo Code (3M+ installs) shut down on May 15, 2026** concluding "IDEs are not the future of coding."
- **OpenHands has open GitHub issue #9482 literally titled "Implement Claude Code Hooks for OpenHands."** If they ship it before APEX gets a defensible distribution channel, APEX's USP collapses to non-programmer UX (which is itself a weak moat).
- **Lovable shipped 170 production apps with CVE-2025-48757 (CVSS 9.3)** because the AI generated Supabase queries without enforced row-level security. **Devin generated a data-deleting migration script. Replit Agent stored passwords in plain text.** APEX's destructive-guard + auditor + verified/unverified contract would catch all three. Write the case studies.

---

## §13. Limits & Caveats

To be honest about the limitations of both swarms:

**Competitive landscape caveats:**
- **This is a snapshot, not a treaty.** The AI-dev-tool landscape is changing weekly in 2026. The "top 15 threats" list will look different by end-2026. Re-run the swarms quarterly.
- **All competitor traction numbers carry an `*unverified*` tag** where not personally confirmed. Star counts, ARR, customer logos, funding amounts are largely vendor-reported. Where two sources conflict, the underlying domain report cites both.
- **APEX-internal moats** (the self-healing loop, the dual-mode philosophy, the scale-adaptive classifier) are evaluated against the surface APEX presents externally — not against the actual codebase. The strategic-value assessment may shift if APEX's internal implementation is materially different from `apex-spec.md`.
- **The recommendations assume APEX wants to remain a single-author open-source project with paid-services tier.** If APEX wants to take outside funding and become a hosted product (Lovable-style), the strategy changes dramatically — most of the "free forever" framing becomes a constraint to relax.
- **The 12-month bet (APEX-Verified)** requires either a corporate entity to issue certifications + ISO 42001 paperwork + sales motion — a meaningful organizational pivot. If the APEX author is not willing to take that on, this becomes a 24-month partnership play (license the verification methodology to an established compliance vendor).

**Doctrinal research caveats:**
- **Token-economics of APEX itself** — no measurement of current per-task token cost across `/apex:fast` / `/apex:build` / `/apex:full`. The 15× multi-agent figure (Anthropic) is a *direction*, not a measurement of APEX specifically.
- **Adversarial robustness of APEX agents** — AgentDojo, ASB, ShieldAgent, LlamaFirewall exist as 2026 benchmarks; APEX hasn't been measured against any.
- **MCP integration details** — Anthropic and Manus both reference MCP heavily; APEX's stance on MCP servers vs in-process tools wasn't surveyed.
- **Computer use / Playwright MCP** — Anthropic's harnesses post calls this "the single highest-leverage gap" for text-only verifiers. APEX has no equivalent today. Out of scope for this snapshot; worth a dedicated phase.
- **Memory-poisoning attack scenarios** — security warnings exist but no quantified attack/defense data in the sources.
- **Cross-provider cost comparison** — IMP-DR-015 assumes the cost is justified for irreversibles but the actual ratio (Anthropic vs OpenAI vs Google on identical tasks) wasn't surveyed.

---

## §14. Methodology

### Swarm A — Competitive Intelligence (10 agents, Report 00 + Reports 01–10)

**Method.** Ten research agents launched in parallel, each owning one domain. Each agent followed the same protocol from `competitive-analysis/BRIEFING.md`:
- Read the APEX spec / failure-mode taxonomy
- Conduct ≥15 distinct web searches + ≥4 deep WebFetches on primary repos/docs
- Profile ≥10 competitors per domain (some agents profiled 17)
- Write per-competitor analysis at ≥350 words each across structured dimensions
- Mark all unverified claims with `*unverified*` tags
- Return a 200-word executive summary + write full report (~6,000–10,000 words) to disk

**Output:** ~88,000 words across 11 reports, ~400 unique citations to primary sources (GitHub repos, official docs, TechCrunch / The Information / VentureBeat funding coverage, vendor blog posts, ICSE/FSE 2025–2026 papers, security incident reports, third-party hands-on reviews).

### Swarm B — Deep-Research Synthesis (5 agents)

**Method.** Five parallel deep-research agents, each owning one source line, with a hop-depth-4 search instruction (read primary doc → read what it cites → read what those cite → read the citing critique):
- `01-anthropic-tool-use-memory.md` — Anthropic Cookbook + canonical compaction/memory primitives (17 URLs)
- `02-anthropic-context-engineering.md` — Anthropic Eng blog + Chroma + Claude Code reference architecture (16 URLs)
- `03-karpathy-skills.md` — Karpathy 4-rule CLAUDE.md + Forrest Chang's extended 12-rule template (21 URLs, 3 hops)
- `04-manus-context-engineering.md` — Manus 6 lessons + post-publication "5th rewrite" revisions (22 URLs + 4 searches)
- `05-microsoft-agentic-security.md` — MDASH + CyberGym + Team Atlanta lineage (18 URLs)

**Output:** ~3,500 lines of synthesized research, ~94 unique URLs.

### To re-run

Quarterly re-run by reading `competitive-analysis/BRIEFING.md` and launching parallel agents with the same template. Update the briefing with the new APEX feature set and any newly-emerged competitors / research sources before re-running.

**Confidence:** High on landscape shape and top-15 threat ranking. Medium on specific funding / star / ARR numbers (vendor-reported). High on steal-worthy ideas (verified against primary docs). High on doctrinal recommendations (every P0 has ≥2 supporting sources). Medium on the APEX-Verified 12-month bet (the market exists; execution requires organizational changes the report cannot predict).

---

## §15. Cross-Links to Raw Evidence

This document condenses. For depth, open the source reports.

**Competitive Intelligence swarm artifacts:**
- `competitive-analysis/BRIEFING.md` — protocol fed to all agents
- `competitive-analysis/reports/00-threat-matrix.md` — cross-cutting meta-analysis
- `competitive-analysis/reports/01-claude-code-native.md` (15 competitors, ~12,000 words)
- `competitive-analysis/reports/02-ide-agents.md` (12 competitors)
- `competitive-analysis/reports/03-autonomous-commercial.md` (13 competitors)
- `competitive-analysis/reports/04-orchestration-frameworks.md` (17 frameworks)
- `competitive-analysis/reports/05-cli-agents.md` (12 competitors)
- `competitive-analysis/reports/06-spec-driven.md` (11 competitors)
- `competitive-analysis/reports/07-enterprise-platforms.md` (12 vendors)
- `competitive-analysis/reports/08-autonomous-opensource.md` (10+ competitors)
- `competitive-analysis/reports/09-memory-context.md` (17 systems)
- `competitive-analysis/reports/10-no-code-vibe.md` (15 platforms)
- `competitive-analysis/MASTER-COMPETITIVE-ANALYSIS.md` — Swarm A synthesis

**Deep-Research swarm artifacts:**
- `competitive-analysis/deep-research-2026-05-24/SYNTHESIS.md` — Swarm B synthesis
- `competitive-analysis/deep-research-2026-05-24/01-anthropic-tool-use-memory.md`
- `competitive-analysis/deep-research-2026-05-24/02-anthropic-context-engineering.md`
- `competitive-analysis/deep-research-2026-05-24/03-karpathy-skills.md`
- `competitive-analysis/deep-research-2026-05-24/04-manus-context-engineering.md`
- `competitive-analysis/deep-research-2026-05-24/05-microsoft-agentic-security.md`

**Unified master document:**
- `competitive-analysis/APEX-UNIFIED-STRATEGIC-MASTER.md` — the original 1,243-line fusion this snapshot derives from

**Doctrinal upgrades integrated into spec:**
- `apex-spec.md` IMP-DR-001 through IMP-DR-027 — the 27 doctrinal upgrades from Master Doc Part II, integrated as new requirements under existing failure modes

---

*End of strategic snapshot. Next re-run target: 2026-08-25.*
