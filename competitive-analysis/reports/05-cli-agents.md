# Report 05 — CLI Agent Tools (Terminal-First AI Coding)

**Agent #5 of 10 — APEX Competitive Intelligence Swarm**
**Scope:** Terminal-first AI coding workflows competing with APEX's CLI-driven nature.
**Date:** 2026-05-24

---

## 1. Scope & Methodology

APEX is a context-engineered pipeline framework that runs **on top of Claude Code** (Anthropic's CLI). The terminal AI coding category is the single most directly competitive surface — these are the tools a non-programmer or developer would adopt *instead of* (or *underneath*) APEX. A user evaluating APEX is almost certainly also evaluating: Aider, opencode (SST), Claude Code itself, Codex CLI, Gemini CLI, Goose, Plandex, Cline (now with CLI preview), Roo Code (Cline fork), Crush (Charm), Amp (Sourcegraph CLI), and RA.Aid. Legacy entrants (GPT-Engineer, Smol Developer) are studied for archeological lessons only.

**Method:**
- 16 distinct WebSearches in 2026 frames (Aider repo map, Aider vs Claude Code, opencode SST, Goose extensions, Plandex 2M context, Cline YOLO/checkpoints, Roo Code modes, Gemini CLI, Codex CLI, Amp CLI, Crush, RA.Aid, Open Interpreter, AutoCodeRover/Devstral, Aider polyglot benchmark, Claude Code plugins/marketplace, Goose recipes/LF, Plandex sandbox, Amp oracle/subagents).
- 4 deep WebFetches on primary docs (Aider modes [11], opencode [12], Plandex [13], Crush [14]).
- All findings tagged with `[N]` footnotes. Items I could not verify (e.g., some star counts, exact 2026 model names) are marked "*unverified*" where load-bearing.

**Note on data quality:** The 2026 AI coding CLI market is hyper-fluid (new entrants weekly, forks of forks, vendor-driven blogspam). Several "comparison" sites are SEO-farmed or vendor-shilled — I cross-checked stars/feature claims against primary repos where possible. A few claims (e.g., "147K stars in April 2026" for opencode [3], "Claw Code fastest to 100K stars" [9]) appear in single secondary sources only and are treated as suggestive, not authoritative.

---

## 2. Per-Competitor Deep Dives

Each block hits 20 dimensions emphasizing: planning, repo-map/context, diff strategy, model-agnosticism, cost, rollback/safety, multi-agent, non-programmer accessibility, extensibility.

---

### 2.1 Aider (Aider-AI/aider) — **The pioneer; still the open-source king**

| Dimension | Detail |
|---|---|
| **Lineage / scale** | Pioneer of CLI AI coding (since 2023). ~41K GitHub stars, 5.3M PyPI downloads as of May 2026 [1]. Largest deployed user base of any open-source coding CLI [9]. |
| **Core philosophy** | "Git-first, model-agnostic by design" [2]. Every change auto-committed with descriptive message — clean undo trail via `git`. |
| **Repo map (context eng.)** | Tree-sitter parse + PageRank-style relevance score → compressed, ranked map of the entire repo with classes/functions and call signatures [1][10]. Single biggest reason it stays cheap on large repos. |
| **Multi-step planning** | **Architect mode** (since 2024.09) splits reasoning from edits: strong model plans → cheap model emits diffs [11][15]. Available via `--architect` or `/architect`. |
| **Diff strategy** | Multiple formats: `diff` (SEARCH/REPLACE blocks), `udiff` (unified-diff-modified for less laziness), `whole`, `diff-fenced`. Editor formats (`editor-diff`, `editor-whole`) exist specifically for architect-mode pairing [15]. **Aider invented the SEARCH/REPLACE format that everyone else copied.** |
| **Model agnosticism** | 100+ LLM providers via unified `--model` flag (Claude, GPT, Gemini, DeepSeek, Ollama local) [2]. |
| **Cost controls** | Architect/editor split: pay frontier rates only on planning step, cheap rates on edits [1]. Prompt caching shipped. **Aider uses 4.2x fewer tokens than Claude Code on equivalent tasks** [2] — though 7-point accuracy gap (71% vs 78% one-shot). |
| **Rollback / safety** | Git auto-commits = native rollback (`git reset`, `git revert`). No shadow git; uses your real history. |
| **Multi-agent / subagents** | Limited — architect/editor pair is the only built-in multi-model orchestration. No general subagent framework. |
| **Non-programmer accessibility** | Moderate. Terminal-only; user must understand git basics. Watch mode + `/voice` improve UX. |
| **Extensibility / hooks** | `.aider.conf.yml` for team policy versioning [1]. `.aider.model.metadata.json`, conventions files. No formal hook/plugin system. Watch mode AI comments. |
| **Modes** | code (default), ask, architect, help [11]. Switching via `/code`, `/architect`, `/ask`, `/help` or `--chat-mode`. |
| **Web / search** | `/web` command pulls web content into context. |
| **Voice / multimodal** | `/voice` (Whisper), `/add-image`. |
| **Benchmark posture** | Maintains **Aider-Polyglot leaderboard** (225 Exercism exercises, 6 languages, 2 attempts) — became the de facto industry benchmark for coding models [16]. Claude Opus 4.5 reportedly leads at 89.4% [16]. |
| **Persistence** | Git history. No "session" abstraction — your repo IS the state. |
| **Test integration** | `/test` runs configured test command and feeds output back. |
| **Specialist agents** | None — single-agent loop. |
| **Critic / verify loop** | None — relies on user review + tests. |
| **What it lacks vs APEX** | No multi-agent (planner/executor/critic/verifier split), no SPEC.md/DECISIONS.md/COMPLEXITY.md control plane, no wave parallelization, no clean-room critic, no DORA tracking, no scale-adaptive ceremony toggle. |

---

### 2.2 Claude Code (anthropic, official) — **APEX's host runtime; both ally and competitor**

| Dimension | Detail |
|---|---|
| **Relationship to APEX** | APEX runs *on top of* Claude Code via `~/.claude/commands/apex/*.md`, `~/.claude/agents/`, `~/.claude/hooks/`, `~/.claude/settings.json`. Claude Code's native features set the baseline APEX must justify itself against. |
| **Native subagents** | YAML-defined reusable agents in `.claude/agents/*.md` with custom system prompt, model selection, tool permissions [17][18]. Each subagent has isolated context — only summary returns to main thread. **This is exactly the architecture APEX leverages.** |
| **Native hooks** | Event-driven scripts (deterministic, not model-interpreted). May 2026 update: `terminalSequence` field for desktop notifications/titles/bells without controlling terminal; `Stop` and `SubagentStop` hooks now include `background_tasks` and `session_crons` fields [17][18]. |
| **Skills** | Procedural snippets the model can load on demand (Claude Skills system, late 2025). The "Claude Skills Marketplace" claims 425 plugins, 2,810 skills, 200 agents [19][20]. |
| **Plugin marketplace** | Full marketplace with version pinning, auto-update, permission controls, multi-backend (GitHub/npm/GitLab/local) [19][20]. Installation scopes: User, Project, Local [19]. |
| **Agent View** | New dashboard for managing parallel coding sessions in one screen — launch, background, check status, jump back into sessions [17]. **Direct overlap with APEX's wave parallelization narrative.** |
| **MCP support** | Native, deep — used by skills, marketplace, all major integrations. |
| **Model** | Claude only (Opus 4.7 / Sonnet 4.6 / Haiku tiers). No BYOK to OpenAI/Google [2]. |
| **Diff strategy** | Anthropic-managed; uses tool calls (`str_replace_editor`, `Edit`) rather than text diff format. |
| **Rollback** | Limited native; ecosystem builds on top (e.g., shadow-git wrappers). APEX's pre-task snapshots fill this gap. |
| **Cost posture** | Premium. ~4.2x more tokens than Aider per task [2]. Heavy reliance on prompt caching. |
| **Planning** | No native planner agent — relies on the main model's internal CoT. **This is the gap APEX explicitly addresses with planner/architect/executor split.** |
| **Verification** | No native critic/verifier loop. Users adopt third-party patterns. |
| **Memory** | `CLAUDE.md` project memory; `~/.claude/memory/` user memory. No three-tier dream-cycle synthesis — APEX adds this. |
| **Extensibility** | Hooks + skills + agents + MCP + plugins = the richest extension surface in the category. **APEX is essentially a curated extension stack on this surface.** |
| **Non-programmer accessibility** | High for chat; lower for hooks/agents (markdown + YAML + shell). |
| **What APEX adds over bare Claude Code** | Pipeline orchestration (`/apex:next`, `/apex:build`, `/apex:execute-phase`), STATE.json control plane, SPEC.md/DECISIONS.md, clean-room critic, wave executor, Reflexion executor, DORA tracking, scale-adaptive ceremony, peer-review, rollback. |
| **Threat level to APEX** | **Highest** — every Claude Code marketplace plugin is a substitute APEX has to be better than. If Anthropic ships a native planner+critic loop, APEX's USP narrows. |

---

### 2.3 opencode (sst/opencode) — **Fastest-growing open-source rival**

| Dimension | Detail |
|---|---|
| **Lineage / scale** | From the SST team. Reportedly **147K GitHub stars** and 6.5M monthly developers by April 2026, growing 4.5x faster than Claude Code in star velocity [3]. (Number is from secondary source — treat as suggestive but trend is clear.) |
| **Why people pick it** | "The New Stack" headline: *"Why 157,000 developers are hedging against Anthropic with OpenCode"* [3]. The hedge story is real. |
| **Architecture** | TypeScript (65.9%), Bun/Turbo/SST infra. Persistent background server + TUI client → sessions survive SSH drops, machine sleep, terminal disconnects [12][21]. |
| **Modes (Plan vs Build)** | **Plan agent** = read-only, denies edits, asks before bash. **Build agent** = full access. Toggle with Tab [12][21]. **APEX-relevant:** this is essentially a 2-mode version of APEX's classifier→planner→executor split, but without critic/verifier. |
| **Subagents** | `@general` syntax invokes a general subagent for searches/multistep tasks [12]. Limited compared to APEX's specialist agent roster. |
| **Model providers** | 75+ via Models.dev — Anthropic, OpenAI, Google, Bedrock, Groq, Azure, OpenRouter, Vertex multi-region, local Ollama [3][12]. |
| **Diff** | Recently shipped a redesigned diff viewer with file tree, refreshed layout, enabled by default [3]. |
| **LSP integration** | Yes — code intelligence via Language Server Protocol [3]. |
| **MCP** | Yes, including OAuth flow improvements 2026 [3]. |
| **Multi-session** | "Running a planning agent and a build agent simultaneously on the same project is a workflow that Claude Code and Codex CLI do not natively support" [21]. **Direct shot at APEX's wave parallelization claim.** |
| **/init command** | Analyzes project → generates AGENTS.md (the cross-vendor standard from the Agentic AI Foundation [22]) [21]. |
| **Desktop / IDE** | TUI is flagship; desktop app + IDE extension also exist. Desktop tabs added 2026 [3]. |
| **Cost controls** | Provider-agnostic = user can route to cheap models. |
| **Rollback** | Not a flagship feature — user-managed via git. |
| **Non-programmer accessibility** | Higher than Aider — slicker TUI (Bubble Tea), session resume. |
| **Extensibility** | MCP, tool schema metadata, file watching, prompt history shipped 2026 [3]. |
| **Confusion warning** | **Two opencodes exist.** `opencode-ai/opencode` (Go, Bubble Tea TUI — what most articles called "OpenCode" pre-fork) and `sst/opencode` (TypeScript rewrite, now the main project). The Go original spawned Crush (see 2.10). |
| **What it lacks vs APEX** | No SPEC versioning, no formal critic/verifier, no DORA metrics, no clean-room review, no wave executor as a contract — just multi-session multitasking. |
| **Threat level to APEX** | **Very high** — if APEX users hear "free, model-agnostic, 75+ providers, Plan/Build modes" they may not need the heavier APEX ceremony. |

---

### 2.4 OpenAI Codex CLI (openai/codex) — **OpenAI's terminal play**

| Dimension | Detail |
|---|---|
| **Lineage** | Open-sourced 2025. Lightweight coding agent. Anthropic-style competitor for the GPT-5.x family. |
| **Default model** | `codex-1` (an o4-mini variant tuned for low-latency code Q&A/editing) [23]. Switchable via `/model` to GPT-5.4, GPT-5.3-Codex, etc. |
| **Goal mode (2026)** | "Drive toward a specific objective for hours or even days" [23]. **Direct competitor to APEX's `/apex:next` long-running orchestration.** Available across CLI, IDE, and app. |
| **Subagents** | Native — "use subagents to parallelize complex tasks" [23]. |
| **Web search** | Built-in. Citations of terminal logs and test outputs for verifiable evidence [23]. |
| **MCP** | Supported [23]. |
| **Diff** | Tool-call based (not text diff format). |
| **Rollback / safety** | Sandboxed exec by default; configurable approval levels (read-only, auto-edit, full-auto). |
| **Multi-platform** | CLI, IDE extension, web app — same agent, three surfaces. |
| **Cost** | Tied to OpenAI billing; aggressive on GPT-5.x family. |
| **Non-programmer accessibility** | Moderate. Three-tier approval is good for nervous users. |
| **What it lacks vs APEX** | OpenAI-only model lock; no clean-room critic; no SPEC/DECISIONS persistence layer; no scale-adaptive ceremony. |
| **Threat level** | **High** — OpenAI's distribution muscle + Goal Mode + subagents is roughly the same value prop as APEX, minus the ceremony scaffolding. |

---

### 2.5 Gemini CLI (google-gemini/gemini-cli) — **Google's free-tier weapon**

| Dimension | Detail |
|---|---|
| **Model** | Gemini 2.5 Pro / 3.x family; **1M token context window** [24]. |
| **Free tier** | 60 req/min, 1,000 req/day with personal Google account [24] — **the most generous free tier in the category by a wide margin.** |
| **ReAct loop** | Reason-and-act loop with built-in tools + local/remote MCP servers [24]. |
| **Built-in tools** | Google Search grounding (native), file ops, shell, web fetch [24]. |
| **MCP** | Full support — GitHub, databases, custom APIs [24]. |
| **Imminent rebrand** | Unpaid tier and Google One users: Gemini CLI + Code Assist IDE extensions will be **replaced by Antigravity CLI** on June 18, requiring migration [24]. **Volatility risk** worth noting in competitive deck. |
| **Diff** | Tool-call based. |
| **Rollback** | None native; user-managed git. |
| **Cost controls** | Free tier is the cost control. |
| **Non-programmer accessibility** | Very high — install with `npx`, login with Google account, done. **Strongest non-programmer onboarding in the category.** |
| **Extensibility** | MCP, custom tools. |
| **What it lacks vs APEX** | Single-model lock, no specialist agents, no critic loop, no SPEC layer. |
| **Threat level** | **Very high for non-programmers specifically** — APEX's target persona is exactly who Google is hunting with free + easy. |

---

### 2.6 Goose (block → AAIF/Linux Foundation) — **The vendor-neutral all-purpose agent**

| Dimension | Detail |
|---|---|
| **Lineage** | Built by Block (Square). **Contributed to Agentic AI Foundation / Linux Foundation Dec 2025** alongside MCP (Anthropic) and AGENTS.md (OpenAI) [22][25]. Moved repo from `block/goose` to `aaif-goose/goose` [4][22]. Now vendor-neutral governance. |
| **Surfaces** | Desktop app (macOS, Linux, Windows), full CLI, embeddable API [4]. ~29K GitHub stars by April 2026 [25]. |
| **Generalist scope** | Beyond code: research, writing, automation, data analysis [4]. Goose explicitly markets to non-programmers. |
| **LLM providers** | 15+ — Anthropic, OpenAI, Google, Ollama, OpenRouter, Azure, Bedrock + ACP for using Claude/ChatGPT/Gemini subscriptions instead of API keys [4]. |
| **MCP depth** | **Earliest deep adopter** of MCP. 70+ documented extensions, 3,000+ tools available [4][25]. Extensions can render interactive UIs inside desktop. |
| **Recipes (YAML workflows)** | **Most APEX-adjacent feature in the category.** Recipes are YAML files bundling instructions, required extensions (MCP servers), parameters, retry logic, subrecipes — shareable, CI-runnable [4][25]. Reportedly saved 40-60 min/week per dev on repetitive tasks [4]. **APEX's PLAN.md + WAVE_MAP.json overlaps heavily.** |
| **Custom extensions** | Python extension classes for domain-specific tools, deployment, test execution [4]. |
| **`goose serve` (2026)** | Background-service subcommand — runs as daemon [4]. Direct analog to APEX's session management. |
| **Skills platform extension (2026)** | Adds Claude-style skill loading [4]. |
| **Autonomy** | Fully autonomous — installs packages, edits files, runs shell, runs tests, reads results [4]. |
| **Diff** | Tool-call based. |
| **Rollback** | User-managed git. |
| **Non-programmer accessibility** | **Very high** — desktop app + extension UIs + recipe sharing. |
| **What it lacks vs APEX** | Recipes ≠ phased PLAN with critic/verifier loops. No clean-room adversarial review. No DORA tracking. But the gap is closing. |
| **Threat level** | **Very high (rising)** — Linux Foundation governance + recipe ecosystem + 70+ extensions + desktop UX is exactly the platform APEX aspires to be. |

---

### 2.7 Plandex (plandex-ai/plandex) — **The multi-step planning specialist**

| Dimension | Detail |
|---|---|
| **Positioning** | Built explicitly for **large projects and real-world tasks** [5][13]. Closest philosophical sibling to APEX in the OSS world. |
| **Context window** | 2M tokens effective context with default model pack; can index 20M+ token directories via tree-sitter project maps [5][26]. |
| **Tree-sitter maps** | Fast generation + syntax validation across 30+ languages [5]. Used for both auto-context loading and manual selection. Reduces likelihood that LLM generates duplicate functions [26]. |
| **Cumulative diff review sandbox** | AI changes stay separate from project files until explicitly approved [5][13][27]. **Direct equivalent to APEX's pre-task snapshot + rollback.** |
| **Configurable autonomy** | Full-auto (plans, generates, executes, debugs) OR step-by-step manual oversight [5][13]. Same dial APEX exposes via `/apex:fast` vs `/apex:full`. |
| **Branches** | Full version control on every plan update; branches for exploring multiple paths or comparing models [5][27]. **APEX has no built-in equivalent — users branch manually with git.** |
| **Automated debugging loop** | Runs builds, linters, tests; debugs browser apps via Chrome integration [5][13]. |
| **Model providers** | Anthropic, OpenAI, Google, OpenRouter, open source [5][13]. Mix-and-match within a plan. |
| **Self-hosting** | One-line zero-dependency CLI install; Dockerized local mode for self-hosting the server [5]. |
| **Diff strategy** | Cumulative diff sandbox (custom). |
| **Git integration** | Commit message generation + optional auto-commits [5]. |
| **Cost controls** | Model packs by tradeoff (capability/cost/speed). |
| **Non-programmer accessibility** | Moderate — CLI heavy. |
| **What it lacks vs APEX** | No adversarial clean-room critic, no SPEC/DECISIONS docs, no skill marketplace, no scale-adaptive ceremony toggle, no DORA tracking. |
| **Plandex Cloud** | Discontinued 10/3/2025; self-host only now [13]. |
| **Threat level** | **High** — most architecturally similar OSS competitor. The "cumulative diff sandbox + branches + auto-debug + tree-sitter map + 2M context" stack is a credible APEX-killer for users who don't need the critic/verifier rigor. |

---

### 2.8 Cline (cline/cline) — **VS Code-first, now with CLI preview**

| Dimension | Detail |
|---|---|
| **Lineage** | Formerly Claude Dev. VS Code sidebar agent; expanded 2026 to JetBrains, Cursor, Windsurf, Zed, Neovim, **plus preview CLI for macOS/Linux** [6][28]. |
| **Why included here** | Originally IDE-only, but the 2026 CLI preview + autonomous nature makes it directly competitive on terminal workflows. Also positioned as "SDK, IDE extension, or CLI assistant." |
| **Autonomous loop** | Reads code, creates/edits files, runs terminal, drives real browser via Puppeteer, asks approval at each step [6][29]. |
| **Computer Use** | Agent verifies its own UI work in a real browser [6]. **APEX has no equivalent.** |
| **Checkpoints (rollback)** | **Best-in-class.** Shadow git repo separate from project's real git; commits file state after every tool use. Three restore modes: Restore Files (revert files, keep convo), Restore Task Only (delete msgs, keep files), full restore [29]. **APEX's pre-task snapshot is similar; Cline's per-tool-use granularity is finer.** |
| **Auto-approve / YOLO** | Granular whitelist per action type (reads, writes, terminal, browser, MCP). Separate YOLO mode removes all confirmations [29]. YOLO mode disables ALL safety — security researchers warn to confine to sandboxed VMs [29]. |
| **`.clinerules`** | Project-specific rules file: coding standards, architecture conventions, deployment, testing requirements [6]. APEX has CLAUDE.md + DECISIONS.md analog. |
| **MCP Marketplace** | Plus stdio/SSE config — plug in databases, observability, internal tools [6]. |
| **Multi-agent coordination** | "Coordinator agent breaks work into subtasks and delegates to specialist agents, each with own tools and context" [6]. **This is APEX-like.** |
| **Spend limits + "Lazy Teammate Mode"** | Tunable safety/autonomy trade-off [6]. |
| **Providers** | 30+ plus Cline Provider [6]. |
| **Non-programmer accessibility** | High (IDE sidebar) → moderate (CLI). |
| **What it lacks vs APEX** | No SPEC versioning, no clean-room critic, no formal verifier, no DORA tracking. |
| **Threat level** | **High** — checkpoints + multi-agent coordination + MCP marketplace + CLI preview = a lot of APEX value at zero ceremony cost. |

---

### 2.9 Roo Code (RooCodeInc/Roo-Code) — **Cline's mode-driven fork**

| Dimension | Detail |
|---|---|
| **Lineage** | Forked from Cline. Family tree: **Cline → Roo Code → Kilo Code** [7][30]. |
| **Killer feature: Custom Modes** | Define specialized AI personas with tailored instructions + scoped tool permissions. **Each mode can restrict which tools the agent can use** [7][31]. This is exactly the security/scope-honesty story APEX tells with its specialist agents. |
| **Default modes** | Architect (plan, layout, deps), Code (precise diffs across modules), Debug (terminals + logs), Ask (quick ref), Custom (team guardrails) [7]. |
| **Mode Gallery (community marketplace)** | Pre-tested mode configs for React, docs, testing, security review etc. — click-to-install [7]. **APEX's workflow recipes have the same shape, smaller catalog.** |
| **Sticky Models** | Per-mode model memory — each mode auto-uses its last model [7]. Smart pattern APEX could steal. |
| **Roo Cloud + SOC 2** | Team features + enterprise compliance shipped 2026 [7]. |
| **Multi-provider** | Same broad set as Cline. |
| **Rollback / safety** | Inherits Cline's checkpoint shadow git. |
| **Non-programmer accessibility** | Moderate (IDE-based primarily). |
| **What it lacks vs APEX** | Critic loop, formal verifier, DORA. |
| **Threat level** | **Medium-high** — modes are simpler than APEX agents but solve much of the same problem. |

---

### 2.10 Crush (charmbracelet/crush) — **The TUI aesthetic play**

| Dimension | Detail |
|---|---|
| **Lineage** | Spun out of (ex-)OpenCode Go original after sst/opencode took over the name. Built by Charm (Bubble Tea / Glamour / Lip Gloss authors). |
| **Surface** | Glamorous TUI (Bubble Tea) **OR** non-interactive `crush run` for Unix pipes [8][14]. |
| **Platform reach** | **Widest in category** — macOS, Linux, Windows, Android, FreeBSD, OpenBSD, NetBSD [8]. |
| **Mid-session model switching** | Switch LLMs without losing conversation [8][14]. |
| **LSP integration** | Per-language LSP for semantic analysis during agent reasoning [14]. |
| **MCP** | stdio, http, sse transports; per-server timeout, disabled-tools list, shell-style credential expansion [14]. |
| **Sessions** | Per-project persistent session state; ephemeral app state separated from user config [14]. |
| **Providers** | OpenAI, Anthropic, Google, Groq, Vercel AI Gateway, OpenRouter, Hugging Face, custom [8]. |
| **Planning / subagents** | **Not present in the documented architecture** [14]. Single-agent loop. |
| **Rollback** | Permission system gates writes; no shadow-git equivalent of Cline. |
| **Diff** | Tool-call based. |
| **Non-programmer accessibility** | Moderate. TUI is gorgeous but still terminal. |
| **What it lacks vs APEX** | Planning, multi-agent, critic, verifier — basically only the "I have a pretty terminal" layer. |
| **Threat level** | **Low-medium** — beautiful UX but missing the orchestration story APEX sells. |

---

### 2.11 Amp (Sourcegraph) — **Enterprise team coding + the "Oracle"**

| Dimension | Detail |
|---|---|
| **Surface** | CLI (`@ampcode/cli`, rebuilt from ground up 2026; previously `@sourcegraph/amp`) + VS Code/forks/Cursor/Windsurf. **Killed standalone VS Code extension in March 2026; now CLI-only for VS Code path** [32][33]. |
| **The Oracle** | **Most distinctive feature.** A dedicated subagent powered by OpenAI's GPT-5 — different model, different context window, different "quality" lens. Main Agent autonomously consults Oracle, or user invokes via "ask the Oracle" [34]. **This is the clean-room critic concept APEX champions, but via different vendor.** |
| **Subagents** | Spawn "mini-me" main-agent versions with own context window + tools for parallel independent work [34]. Useful for multi-step parallel tasks, extensive-output ops, parallel cross-area work, keeping main thread clean. |
| **Models** | Claude Opus 4.7 powers "smart" mode; "Rush" runs GPT-5.5 no-reasoning (2x faster) for small tasks [33]. |
| **Team collaboration** | **Multiplayer thread sharing**, workspace collaboration, leaderboards, thread reuse [34]. **APEX has no native team collab — single-user framework.** |
| **Sourcegraph code intelligence** | Inherits Sourcegraph's enterprise code-search/symbol-graph layer. |
| **Cost controls** | Free tier; team pricing. |
| **Diff** | Tool-call based. |
| **Rollback** | User-managed git + Amp's safety prompts. |
| **Non-programmer accessibility** | Moderate. |
| **What it lacks vs APEX** | No SPEC versioning, no DECISIONS.md analog, no scale-adaptive ceremony, no Reflexion executor. |
| **Threat level** | **Medium-high for enterprise teams** — Oracle + subagents + team threads is a strong story. |

---

### 2.12 RA.Aid (ai-christianson/RA.Aid) — **Research-aware development**

| Dimension | Detail |
|---|---|
| **Distinguishing feature** | **Native web research via Tavily API** — agent autonomously decides when to search the web for context, no explicit user invocation [35]. APEX doesn't have first-class web research. |
| **Workflow** | Research → planning → implementation, all autonomous [35]. |
| **Multi-step planning** | Breaks down + executes multi-step programming tasks; analyzes codebases for architectural questions; plans + implements multi-file changes; refactors with proper planning [35]. |
| **Provider support** | Anthropic, OpenAI, OpenRouter, Gemini [35]. 2026 default provider priority: Gemini > OpenAI > Anthropic (based on which API key is set) [35]. |
| **Persistent defaults (2026)** | `--set-default-provider`, `--set-default-model` → `.ra-aid/config.json` [35]. |
| **Diff** | Tool-call based. |
| **Rollback** | User-managed git. |
| **Non-programmer accessibility** | Moderate. |
| **Threat level** | **Low-medium** — niche (research-heavy) but the autonomous-web-research idea is worth stealing. |

---

### 2.13 Open Interpreter (openinterpreter/open-interpreter) — **The natural-language computer**

| Dimension | Detail |
|---|---|
| **Positioning** | Not strictly a coding agent — a **natural-language interface for the whole computer**. LLMs run code (Python/JS/Shell) locally. |
| **Desktop App (2025)** | Polished surface for non-technical users; full document editing for Word, Excel, PDF; pivot tables/charts in Excel; tracked changes in Word; PDF form fills (even non-interactive scans) [36]. |
| **AI-native spreadsheets** | Formulas generated on the fly inside Excel [36]. |
| **Models** | 100+ via LiteLLM; works with GPT-4, Claude, local Llama [36]. |
| **API/server** | HTTP REST API, conversation history, streaming output, YAML config profiles [36]. |
| **Why it matters for APEX** | **APEX's stated audience is non-programmers.** Open Interpreter is the closest thing to a non-programmer's general-purpose CLI agent. If your user wants "edit my Excel" not "ship a feature," they go here, not APEX. |
| **Threat level** | **Niche** for coding, but **high** for the non-programmer-positioning narrative. |

---

### 2.14 Honorable mentions / legacy

- **GPT-Engineer** (~55K stars) and **Smol Developer** (~12K stars) — historical pioneers, **no longer actively maintained** as of 2026 [37]. GPT-Engineer team pivoted to Lovable (web product). Worth studying for archeology, not as live competitors.
- **AutoCodeRover** — research project; 46.2% on SWE-bench Verified; ~$0.7/task [38]. Not a daily-use CLI.
- **Devstral 2 / Mistral Vibe CLI** — Mistral × All Hands. 123B dense, 256K context. Bundled CLI ("Vibe") reads repo + git status, persistent session memory, plain-English commands [38][39]. Local-first competitor.
- **Hermes Agent (Nous Research)** — self-improving CLI with persistent memory, automated skill creation, sandboxed exec via Unix-socket RPC; multi-platform (Telegram/Slack/Discord/WhatsApp); 300+ models [9]. **Self-improvement loop is APEX-adjacent.**

---

## 3. Cross-Cutting Observations

### 3.1 Standards are converging
- **MCP (Model Context Protocol)** — Anthropic-originated, now everyone (Aider, opencode, Goose, Codex, Gemini, Cline, Roo, Crush, Amp) supports it. **Donated to the Linux Foundation's Agentic AI Foundation in Dec 2025** [22].
- **AGENTS.md** — OpenAI-originated cross-vendor project-instruction convention; **also donated to AAIF Dec 2025** [22]. opencode's `/init` generates it [21]. Crush, Goose adopting it.
- **Goose itself** is in AAIF too [22] — multi-vendor governance is the new normal.
- **APEX implication:** APEX must align with MCP + AGENTS.md or get marginalized. Reusing CLAUDE.md alongside (or as) AGENTS.md is the lowest-friction path.

### 3.2 The "Plan vs Build" mode is now table stakes
- Aider (architect/code), opencode (plan/build), Roo Code (architect/code/debug/ask/custom), Codex (goal mode), Cline (multi-agent coordinator/specialist), Goose (recipe orchestration).
- **APEX's planner/architect/executor/critic/verifier split is more granular but also more ceremonious.** Competitors achieve 80% of the value with 2-3 modes.

### 3.3 Cheap-edits-with-expensive-planning is universal
- Aider invented architect/editor pairing. Plandex, opencode, Roo Code (Sticky Models), Amp (Rush=GPT-5.5-no-reason for small tasks, Smart=Opus 4.7) all replicate the pattern.
- **APEX implication:** APEX must expose a per-step model picker. Implicit single-model usage = cost penalty.

### 3.4 Rollback / safety is a horse race
- **Cline checkpoints** = per-tool-use shadow-git restore (gold standard for granularity).
- **Aider** = git auto-commit per change (cleanest narrative for users who already understand git).
- **Plandex sandbox** = cumulative diff isolated from real files until approved (safest for risk-averse users).
- **APEX pre-task snapshots + one-click rollback** = competitive but not differentiated. Needs a clearer hook (per-tool-use? per-task? per-phase? all three?).

### 3.5 Subagents are everywhere; clean-room critics are almost nowhere
- Subagents/multi-agent: Claude Code (native), opencode (`@general`), Cline (coordinator), Codex (parallel), Amp (subagents + Oracle), Roo Code (modes), Goose (subrecipes).
- **Adversarial clean-room critic** (separate context, separate model, sees only the diff + spec, not the executor's reasoning) — only **Amp's Oracle** comes close in commercial CLIs.
- **APEX implication:** The clean-room critic is APEX's most defensible technical USP. Lead with it.

### 3.6 Three growth strategies in the market
1. **Free tier + vendor model** (Gemini CLI free, Codex tied to OpenAI billing, Claude Code tied to Anthropic) — distribution wins.
2. **Model-agnostic OSS** (Aider, opencode, Plandex, Goose, Crush) — token-cost arbitrage wins.
3. **Enterprise/team layer** (Amp, Roo Cloud + SOC 2, Cline Provider) — team collaboration + compliance wins.
- **APEX is currently option 2 in shape but option 1's persona.** This is a strategic tension.

### 3.7 Non-programmer accessibility — APEX's audience is contested
- Gemini CLI (1-line install, Google login), Goose Desktop, Open Interpreter Desktop, Cline IDE sidebar, opencode TUI/Desktop all target lower-friction surfaces.
- A pure CLI framework on top of another CLI tool (APEX on Claude Code) is **a high-friction surface for non-programmers.** The framework's pitch survives only if the natural-language UX through `/apex:*` commands hides the ceremony.

### 3.8 Volatility / risk indicators
- Gemini CLI being replaced by Antigravity CLI June 18 [24].
- Plandex Cloud shut down Oct 2025 [13].
- Amp killed VS Code extension March 2026 [33].
- Goose moved to Linux Foundation; repo path changed [22].
- "Claw Code" leak narrative from March 2026 [9] — Claude Code source allegedly leaked, spawned clean-room rewrites.
- **APEX needs explicit forward-compat strategy** since the substrate (Claude Code) is itself a moving target.

### 3.9 What no one else has that APEX has
- **SPEC.md / DECISIONS.md / COMPLEXITY.md as versioned artifacts that the agent treats as authoritative.**
- **Reflexion executor pattern** as a first-class loop (vs ad-hoc retry).
- **Scale-adaptive ceremony** (`/apex:fast` ↔ `/apex:full` continuum) — closest analog is Cline's "Lazy Teammate Mode" but that's autonomy, not ceremony.
- **DORA metrics tracking** — nobody else even tries.
- **Mutation + property-based testing as policy** — Plandex's auto-debug loop runs tests, doesn't enforce mutation testing.
- **Three-tier memory + dream-cycle synthesis** — Goose has persistent memory, Hermes has self-improvement, neither has the dream-cycle metaphor.

---

## 4. Top 5 Lessons to Steal (Ranked)

### #1 — Plan/Build mode duality with explicit, gated transitions (opencode, Roo Code, Aider)
**What:** A clean two-mode (or N-mode) surface where one mode is **read-only/planning** and another is **write/execute**, with a deliberate user gesture (Tab key, slash command) to transition. opencode's "denies file edits by default, asks permission before bash" in Plan is the killer detail.
**Why steal:** APEX's planner-architect-executor-critic-verifier pipeline is invisible to users — they just say "/apex:build" and stuff happens. Surfacing a **Plan↔Build mode toggle** (separate from the agent split) would give users the same visceral safety story Cline/opencode users love.
**How:** `/apex:plan-mode` and `/apex:build-mode` slash commands that gate the executor agent's file-write tool. Show mode in prompt prefix.

### #2 — Cline-style shadow-git checkpoints at per-tool-use granularity
**What:** Shadow git repo (separate from project git) commits state after every tool use. Three restore modes: files only, conversation only, both. APEX has pre-task snapshots — Cline's per-tool granularity is finer.
**Why steal:** "Undo any single tool call" is a more compelling safety pitch than "rollback to phase start," and it composes with APEX's existing snapshot story.
**How:** New hook `post-tool-checkpoint.sh` that commits to `.apex/shadow-git/` after every tool invocation. Add `/apex:rollback --tool-call N` and `/apex:rollback --task N`. Reuse pre-task-snapshot infra.

### #3 — Aider's repo map (tree-sitter + PageRank ranking)
**What:** Parse the whole repo with tree-sitter, rank every symbol by PageRank-style relevance to the current task, surface only the top-N into context. Aider's core insight: most files in a repo are irrelevant to most tasks; the trick is automated ranking, not bigger context windows.
**Why steal:** APEX has TASK_MAP.md and Aider repo map (per CLAUDE.md), but TASK_MAP is hand-authored. **A live tree-sitter+PageRank index would make APEX's context engineering self-tuning.** Plandex (tree-sitter), opencode (tree-sitter), Aider (tree-sitter+PageRank) all confirm tree-sitter is the standard.
**How:** Ship a hook that runs tree-sitter on `pre-task` and writes `.apex/repo-map.json`; expose to executor as a tool. Lean on the existing `tree-sitter` Node/Python packages.

### #4 — Goose Recipes as APEX's plug-and-play workflow format
**What:** Goose Recipes are shareable YAML files that bundle goal, required MCP extensions, parameters, subrecipes, retry logic. Run in CI, share with team, remix. Reportedly save 40-60 min/week/dev.
**Why steal:** APEX's ~30 workflow recipes (per the brief) need a **shareable, parameterizable, CI-runnable distribution format** that's not "a markdown file you copy into your project." Recipes + a marketplace = the Goose moat APEX needs to match.
**How:** Define `.apex/recipes/*.yml` schema. Add `/apex:recipe run <name> --param key=val`. Build a community marketplace (GitHub-backed, like Claude Code's plugin marketplace [19]).

### #5 — Amp's Oracle: clean-room critic via second model/vendor
**What:** Amp's Oracle is a *different model* (GPT-5) consulted by the main Claude agent, with its own context window. This is exactly APEX's adversarial clean-room critic concept — but the user-facing pitch is brilliant: "ask the Oracle." Single phrase, clear mental model.
**Why steal:** APEX's clean-room critic is buried in the pipeline; users don't see it as a feature, they see it as latency. **Rename and surface it.** Allow users to invoke the critic directly: "/apex:oracle <question>" or "/apex:second-opinion."
**How:** Add `/apex:oracle` slash command that invokes the existing critic agent with a different model (configurable: GPT-5, Gemini Pro, etc.) on the current diff or question. Make it the marketable face of APEX's most defensible technical USP.

---

## 5. Footnotes / Sources

[1] Awesome Agents — *Aider Review*: https://awesomeagents.ai/reviews/review-aider/
[2] Developers Digest — *Aider vs Claude Code 2026*: https://www.developersdigest.tech/blog/aider-vs-claude-code-2026-update
[3] The New Stack — *Why 157,000 developers are hedging against Anthropic with OpenCode*: https://thenewstack.io/anthropic-claudecode-opencode-split/
[4] aaif-goose/goose README + goose-docs.ai: https://github.com/aaif-goose/goose ; https://goose-docs.ai/
[5] plandex-ai/plandex README: https://github.com/plandex-ai/plandex
[6] cline/cline README: https://github.com/cline/cline ; https://cline.bot/
[7] Roo Code docs + comparison: https://docs.roocode.com/features/custom-modes ; https://www.morphllm.com/comparisons/roo-code-vs-cline
[8] charmbracelet/crush README: https://github.com/charmbracelet/crush
[9] DEV community — *Every AI Coding CLI in 2026: 30+ Tools Compared*: https://dev.to/soulentheo/every-ai-coding-cli-in-2026-the-complete-map-30-tools-compared-4gob
[10] Aider — *Repository map*: https://aider.chat/docs/repomap.html
[11] Aider — *Chat modes*: https://aider.chat/docs/usage/modes.html
[12] sst/opencode README: https://github.com/sst/opencode
[13] Plandex docs — *Plans / Context Management*: https://docs.plandex.ai/core-concepts/plans/
[14] charmbracelet/crush DeepWiki: https://deepwiki.com/charmbracelet/crush
[15] Aider — *Edit formats*: https://aider.chat/docs/more/edit-formats.html
[16] llm-stats — *Aider-Polyglot benchmark*: https://llm-stats.com/benchmarks/aider-polyglot ; SWE-Bench leaderboard May 2026: https://www.marc0.dev/en/leaderboard
[17] Releasebot — *Claude Code updates May 2026*: https://releasebot.io/updates/anthropic/claude-code
[18] ofox.ai — *Claude Code: Hooks, Subagents, Skills 2026*: https://ofox.ai/blog/claude-code-hooks-subagents-skills-complete-guide-2026/
[19] Claude Code docs — *Discover plugins*: https://code.claude.com/docs/en/discover-plugins
[20] jeremylongshore/claude-code-plugins-plus-skills: https://github.com/jeremylongshore/claude-code-plugins-plus-skills
[21] OpenAIToolsHub — *OpenCode Review*: https://www.openaitoolshub.org/en/blog/opencode-review-terminal-ai-coding ; sanj.dev — *Aider vs OpenCode vs Claude Code 2026*: https://sanj.dev/post/comparing-ai-cli-coding-assistants/
[22] paperclipped.de — *Agentic AI Foundation 2026 Guide*: https://www.paperclipped.de/en/blog/agentic-ai-foundation-linux-mcp-standard/
[23] OpenAI Codex CLI features: https://developers.openai.com/codex/cli/features ; https://openai.com/index/introducing-codex/ ; https://github.com/openai/codex
[24] Google — *Gemini CLI*: https://github.com/google-gemini/gemini-cli ; https://blog.google/innovation-and-ai/technology/developers-tools/introducing-gemini-cli-open-source-ai-agent/ ; https://developers.google.com/gemini-code-assist/docs/gemini-cli
[25] Effloow — *Goose review 2026*: https://effloow.com/articles/goose-open-source-ai-agent-review-2026 ; AIToolly — *Goose launch*: https://aitoolly.com/ai-news/article/2026-04-07-block-launches-goose-an-open-source-extensible-ai-agent-for-automated-engineering-tasks
[26] Plandex docs — *Context management*: https://docs.plandex.ai/core-concepts/context-management/ ; theunwindai — *AI Coding Agent with 2M Context*: https://www.theunwindai.com/p/ai-coding-agent-with-2-million-context
[27] vibecodinghub — *Plandex Review 2026*: https://vibecodinghub.org/tools/plandex
[28] vibecoding — *Cline Review 2026*: https://vibecoding.app/blog/cline-review-2026
[29] Cline docs — *Auto Approve & YOLO*: https://docs.cline.bot/features/auto-approve ; Yi Cheng — *YOLO Mode Hyper-V Safety Guide*: https://yicheng-yvonne.com/en/posts/2026/04/yolo-mode-hyperv-safety/
[30] Qodo — *Roo Code vs Cline 2026*: https://www.qodo.ai/blog/roo-code-vs-cline/
[31] Roo Code custom modes docs: https://docs.roocode.com/features/custom-modes
[32] sourcegraph.com/amp + amp-examples-and-guides CLI README: https://sourcegraph.com/amp ; https://github.com/sourcegraph/amp-examples-and-guides/blob/main/guides/cli/README.md
[33] amplifilabs — *Sourcegraph Amp Agent 2026*: https://amplifilabs.com/post/sourcegraph-amp-agent-accelerating-code-intelligence-for-ai-driven-development
[34] gvrooyen.substack — *Getting Started with Amp*: https://gvrooyen.substack.com/p/getting-started-with-amp ; Matt Tanner — *How to use subagents in Amp*: https://medium.com/@matthewtanner91/how-to-use-subagents-in-ai-coding-with-amp-8b8418486782 ; Amp Owner's Manual: https://ampcode.com/manual
[35] ai-christianson/RA.Aid README + docs: https://github.com/ai-christianson/RA.Aid ; https://docs.ra-aid.ai/ ; https://github.com/ai-christianson/RA.Aid/releases
[36] openinterpreter/open-interpreter README + reviews: https://github.com/openinterpreter/open-interpreter ; https://www.tooljunction.io/ai-tools/open-interpreter ; https://docs.openinterpreter.com/getting-started/introduction
[37] smol-ai/developer (legacy): https://github.com/smol-ai/developer ; Ry Walker research — *Autonomous Agentic Engineering Tools Compared*: https://rywalker.com/research/autonomous-agentic-engineering-tools
[38] AutoCodeRoverSG/auto-code-rover: https://github.com/AutoCodeRoverSG/auto-code-rover ; Shawn Kanungo — *Devstral 2 2026*: https://shawnkanungo.com/blog/what-is-devstral-2-openai-model-for-developers-2026 ; Mistral — *Devstral*: https://mistral.ai/news/devstral
[39] devstral.net: https://devstral.net/ ; 1min.ai — *Free Local AI Coding with Devstral 2*: https://1min.ai/free-local-ai-coding-with-devstral-2

---
*End of Report 05.*
