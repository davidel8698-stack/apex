# Report 02 — IDE-Embedded AI Coding Agents

**Agent #2 of 10 — APEX Competitive Intelligence Swarm**
**Scope:** AI agents that live inside an IDE/editor (not pure CLIs — those are Report 05). This is APEX's biggest substitution risk for the dev audience: if an IDE ships agentic mode "natively," it can obviate the need for a framework like APEX.
**Date:** 2026-05-24

---

## 1. Scope & Methodology

This report covers the AI coding tools embedded *inside* an IDE or editor — the experience a user gets without ever opening a terminal. Eleven competitors are profiled in depth: **Cursor**, **Windsurf (Cognition)**, **Cline**, **Roo Code** (which announced shutdown mid-research), **Kilo Code** (Roo's principal heir), **Continue.dev**, **Zed**, **JetBrains AI Assistant + Junie**, **VS Code Copilot Agent Mode / Visual Studio 2026 Cloud Agent**, **Trae (ByteDance)**, and **Void**. I add a short note on **Google Antigravity 2.0** because it shipped at I/O 2026 and reshapes the standalone-agent-IDE niche.

**Method.**
- **18 distinct web searches** in 2026 frames covering: Cursor Composer/Bugbot/Background-Agent/pricing/Composer-2-2.5/Anysphere-funding/best-practices; Windsurf Cascade/memories-rules-workflows/Cognition-acquisition/Windsurf 2; Cline plan-act/focus-chain/checkpoints/v3.25/pricing/SDK; Roo Code modes/shutdown; Kilo Code platform; Continue agent/CI pivot; Zed agent panel/ACP/external-agents/parallel; Junie hierarchical planning/pricing; VS Code Copilot Agent Mode/VS 2026 Cloud; Trae Builder/SOLO; Void status; Antigravity 2.0; AGENTS.md universal spec.
- **4 deep WebFetches** of primary docs: Cursor agent best practices [1], Cline GitHub repo [13], Windsurf Cascade docs [9], Zed agent panel docs [29].
- All findings tagged with `[N]` numeric footnotes. Items I could not personally verify are tagged **`*unverified*`** in-line.

**Data-quality caveats.**
1. The IDE-agent category is in violent motion. **Roo Code is shutting down on May 15, 2026** [16][17] — six days before this report's date. Treat any 2024–early-2025 commentary on Roo Code as obsolete.
2. **Windsurf was acquired by Cognition in July 2025 for ~$250M after OpenAI's ~$3B bid collapsed over Microsoft IP concerns** [3][7]. The product still ships under the Windsurf brand but is now Devin-adjacent.
3. **Continue.dev pivoted away from being an IDE-extension competitor** to being a CI/CD AI-checks platform in mid-2025 [11][12]. Their old "Continue agent in your IDE" pitch is no longer the lead story.
4. **Void's repo is paused** as of 2026 — no end-of-life announcement, but no commits either [25].
5. Star counts, ARR, and pricing all change weekly; I cite the date attached to each figure and mark anything I could not anchor to primary sources.

**What I could NOT verify.**
- Whether Cursor's Composer 2.5 actually beats Claude Opus 4.7 on broader benchmarks (only SWE-Bench Multilingual is cited by Cursor's own post [6]).
- Exact installed-base count for VS Code Copilot Agent Mode (Microsoft does not publish breakdowns).
- Whether Kiro is "IDE-embedded" in the same sense as Cursor — it's a *standalone* IDE (VS Code fork), so it qualifies, but it's also covered more deeply in Report 06 (spec-driven). I include a brief entry here for orientation only.

---

## 2. Per-Competitor Deep Dives

Each block hits ~17 dimensions emphasizing what APEX must match or beat: planner/critic loop, checkpoint/rollback, hooks/extensibility, memory, multi-agent, model agnosticism, non-programmer accessibility, cost, and the brutal "what they do better" comparison.

---

### 2.1 Cursor (Anysphere) — **The category-defining substitution risk; now a model lab**

| Dimension | Detail |
|---|---|
| **Lineage / scale** | Founded 2022 (Anysphere). Series D in Nov 2025 raised $2.3B at **$29.3B valuation** [3]; April 2026 round reportedly closing at **$50B pre-money** ($60B post) with a16z + Thrive + Nvidia [4]. **$2B ARR as of Feb 2026; management forecasts $6B by year-end** [4]. Acquired Graphite (code review) Dec 2025 [4]. Cursor 3 shipped April 2026 [5]. |
| **Core philosophy** | "Build software with AI agents" — Cursor is no longer an "AI-augmented editor," it is an **agent workspace**. The IDE is the chassis for the agent fleet [1][5]. |
| **Composer (in-IDE agent)** | Three modes: **Ask** (read-only chat), **Manual** (you drive), **Agent** (autonomous, picks files, runs terminal, iterates) [1]. **Composer 2** (Mar 2026): in-house frontier model, RL-trained on long-horizon tasks, $0.50/M in, $2.50/M out, scores 73.7 on SWE-Bench Multilingual, 61.7 on Terminal-Bench 2.0 [6]. **Composer 2.5** (May 18, 2026): 79.8% SWE-Bench Multilingual — within 0.7pp of Claude Opus 4.7 at **1/10 the cost** [6]. **This is the single most aggressive move in the category — Cursor is now a model lab, not an IDE wrapper.** |
| **Plan Mode** | `Shift+Tab` toggle. Agent researches the codebase, asks clarifying questions, writes a plan to `.cursor/plans/*.md` *before* it touches code [1]. **Functionally identical to APEX's `/apex:plan-phase` output — but native, one-keystroke, integrated with the model that will execute it.** |
| **Background Agent** | Cloud Ubuntu VMs clone your repo, work on a branch, open a PR. You start tasks from your phone, mobile web, or Slack [2]. Billed per-request (~$0.04 cheap models, more for Opus/GPT-5) [27]. **Direct collision with APEX's wave-parallelization narrative — Cursor sells this as the killer feature for engineering managers.** |
| **Parallel Agents (worktrees)** | Up to **8 agents simultaneously, each in its own git worktree** [2][7]. The Agents Window shows every agent (local/worktree/cloud/SSH) in one pane [7]. Cursor will run multiple models on the same prompt and *recommend which it thinks is best* [1] — a built-in cross-model arbiter. |
| **Bugbot (autonomous code review)** | Spawns Cloud Agents in their own VMs on PR-open events [8]. **2M+ PRs/month, 70%+ resolution rate (up from 52% at launch), 35%+ of proposed fixes merged directly** [8][2]. **Bugbot Autofix** (Feb 2026) — not just flags issues, opens PRs with the fix already applied [8]. Pricing: $40/user/month Pro, separate from editor license [2]. |
| **Rules & Skills** | `.cursor/rules/*.md` (always-on instructions), `SKILL.md` files for dynamic skills + custom `/`-commands + pre/post hooks (Nightly only as of writing) [1]. Steady move toward Claude Code parity. |
| **Verification / critic loop** | Bugbot is the critic *for PRs*; in-IDE, there's no explicit critic agent — the model self-checks via tools and diagnostics. Multi-model "best-of" suggestion [1] is a primitive critic layer. |
| **Checkpoint / rollback** | Every dev environment has its own version history that admins can roll back; re-indexing checkpoints recommended for >2hr sessions [7]. Less granular than Cline's per-tool-call shadow git. |
| **Memory** | Rules + `@Branch` orientation + project-wide indexing. Auto-summarization in long conversations is acknowledged to cause focus loss [1]. **No three-tier memory architecture, no dream-cycle synthesis.** |
| **Extensibility** | Rules, Skills, hooks (Nightly), MCP servers — converging on the Claude Code surface area. Skills marketplace is nascent vs. Claude Code's 425+ plugins. |
| **Cost posture** | Pro $20/mo, Pro+ $60, **Ultra $200**, Teams $40/user [27]. Cloud agents metered on top. Heavy users hit $1k+/mo easily. Composer 2.5 dramatically cuts inference cost when used as the model. |
| **Non-programmer accessibility** | High for inline chat; medium for Agent mode (still surfaces terminal). No structured spec or workflow library for non-devs. Best-in-class onboarding UX in the category. |
| **Enterprise readiness** | SOC2, SSO, private-deployment options; Background Agent VMs run in Cursor's cloud (data-residency questions). Quoted by NVIDIA, Stripe-tier customers. |
| **What it does BETTER than APEX** | (1) Native, frictionless **parallel-agent UX** — APEX requires `/apex:new-workspace`, Cursor requires zero ceremony. (2) **In-house frontier model at 1/10 the cost** — APEX has no answer here. (3) **Bugbot as a productized critic on PRs** with measurable 70% resolution. (4) Mobile/phone control of Background Agents. (5) Plan Mode integrated with the executor model that will actually run it (APEX's planner/executor split is more disciplined but also more friction). (6) Top-tier funded distribution and dev mindshare. |
| **What APEX does better** | (1) Falsifiable RESULT.json with verified vs. unverified criteria — Cursor has no schema-level honesty primitive. (2) Auditor filesystem-quarantined from impl code — Cursor's Bugbot sees everything. (3) 9-failure-mode taxonomy and named hooks — Cursor handles failures generically. (4) Free forever; open-source. (5) Multi-platform via thin adapters (Cursor is, well, Cursor). (6) Non-programmer dual-mode philosophy (collaborator vs. replacement) — Cursor's UX still assumes a developer. (7) Spec/decisions/complexity control plane vs. Cursor's `.cursor/rules/` flat-file approach. |
| **What APEX should steal / learn** | (a) The **Agents Window as glass cockpit** — APEX has STATE.json + `/apex:status`; build a TUI dashboard. (b) **Background Agent (cloud-runnable) as a paid tier**. (c) **Plan files as version-controlled artifacts** in a flat directory (Cursor writes to `.cursor/plans/`; APEX writes to `.apex/phases/*/PLAN.md`, but the *idea of plan-as-shareable-asset* deserves emphasis). (d) **Multi-model best-of pick** — run two models on the same critic prompt and surface disagreement. (e) Mobile control surface. |
| **Threat level** | **CRITICAL.** Cursor owns the IDE-agent mindshare; non-programmers who hear about "AI coding" hear "Cursor" first. If Cursor ships an APEX-equivalent spec/critic layer (which is plausible — Composer 2.5 + Bugbot are 70% of the way), APEX's value-add to a Cursor user shrinks dramatically. |

---

### 2.2 Windsurf (Cognition) — **The IDE Cognition bought to flank Devin**

| Dimension | Detail |
|---|---|
| **Lineage / scale** | Codeium pivoted to Windsurf editor Nov 2024. **Acquired by Cognition (Devin) July 14, 2025 for ~$250M** after a $3B OpenAI bid collapsed over Microsoft IP concerns [3]. $82M ARR at acquisition, 350+ enterprise customers, 210 employees [3]. **Windsurf 2.0 launched April 15-16, 2026** [10]. Ranked #1 in LogRocket AI Dev Tool Power Rankings, Feb 2026 *unverified* [3]. |
| **Core philosophy** | "Flow state" coding — agent maintains context across long sessions; the editor stays out of the way [9]. Post-Cognition: "Windsurf is the IDE side; Devin is the cloud-agent side; the two converge." |
| **Cascade (in-IDE agent)** | Code mode (writes code) + Chat mode (read-only Q&A) [9]. Up to **20 tool calls per prompt**, auto-continue across limit hits [9]. Specialized **planning agent runs continuously** alongside the executor — refines long-term plan while executor takes short-term actions [9]. Linter integration in the loop — model sees lint errors after each change and self-corrects [9]. |
| **Memories** | Auto-generated, machine-local. To make memory durable and shareable, user must promote to `.windsurf/rules/` or `AGENTS.md` [21]. Workspace-scoped persistent context bundle survives session restarts [21]. |
| **Rules** | Global / workspace / system scopes; can be inferred from `AGENTS.md` [21]. Version-controlled, team-shareable. |
| **Workflows** | Named, repeatable, version-controlled. "A Workflow earns its place when the prompt would otherwise be rewritten by hand at least once a week" [21]. **Functionally equivalent to APEX's `apex-workflows/` library of 30+ recipes — but ad-hoc per-team rather than curated.** |
| **Checkpoints** | Named project snapshots — easy navigation and reversion. **Reverts are irreversible** (their warning, not mine) [9]. |
| **Agent Command Center (W2.0)** | Kanban board of every agent session — local Cascade + cloud Devin VMs side by side [10]. **Devin is bundled in all Windsurf plans now** [10]. |
| **Devin integration** | Devin's autonomous PR-generating agent runs as a cloud sibling to in-IDE Cascade. This is the closest commercial product to "kick off a long task on your phone, get a PR" — Cursor Background Agent's chief rival [10]. |
| **Model agnosticism** | Menu-based model selection; availability varies by plan [9]. |
| **Critic / verification** | Implicit (lint-loop, tests-loop); no explicit critic agent. |
| **Non-programmer accessibility** | High in chat; SOLO-style autonomous mode via Devin handoff. Onboarding has been criticized as more confusing than Cursor's. |
| **Cost posture** | Pricing has shifted post-acquisition; current Pro tier is competitive with Cursor Pro *unverified*. Devin Cloud access still rolling out gradually [10]. |
| **Enterprise readiness** | Inherits Cognition's enterprise muscle. SOC2, SSO, private deployment. |
| **What it does BETTER than APEX** | (1) Continuous **planning-agent-in-parallel-with-executor** — APEX runs planner *then* executor; Cascade does both *concurrently*, which is closer to how a human PM actually works. (2) **AGENTS.md as universal rules format** — Cascade adopted it before APEX; APEX still uses `.apex/` internal files. (3) Devin sibling for true delegate-and-walk-away workflow. (4) Workspace-scoped memory bundle that survives restarts without explicit save. |
| **What APEX does better** | (1) Falsifiable RESULT.json. (2) Critic/auditor as a separate agent. (3) Scale-adaptive ceremony. (4) Self-healing loop. (5) Open source. (6) Spec-driven control plane. |
| **What APEX should steal / learn** | (a) **Concurrent planner-and-executor**, not sequential. (b) Make **AGENTS.md the primary rules file**, with `.apex/SPEC.md` etc. as the *deeper* layer. (c) Bundle a "cloud agent" tier (even if it's just shelling to GitHub Actions). (d) Named, irreversible checkpoints surfaced as first-class UI. |
| **Threat level** | **HIGH.** Cognition's enterprise distribution + Devin sibling + Windsurf IDE = a credible "do everything" stack. The W2.0 Agent Command Center directly competes with APEX's glass cockpit narrative. |

---

### 2.3 Cline (cline/cline) — **The architectural twin APEX is built next to, not on top of**

| Dimension | Detail |
|---|---|
| **Lineage / scale** | Started as "Claude Dev" mid-2024, rebranded Cline. **62.2k GitHub stars** as of May 2026 [13], **5M+ installs across VS Code + JetBrains + Cursor + Windsurf + Zed + Neovim + preview CLI for macOS/Linux** [14]. Apache 2.0, 97.7% TypeScript, 267 releases, current CLI v3.0.13 (May 23, 2026) [13]. **Cline SDK released May 14, 2026** — open-source agent runtime now powering CLI and Kanban; IDE extensions being migrated to it [30]. |
| **Core philosophy** | "Autonomous coding agent as an SDK, IDE extension, or CLI assistant" [13]. Plan first, act second; show every diff before applying it; never silently mutate. |
| **Plan / Act modes** | **Marquee 2026 feature.** Plan mode: read-only — model can search, read, write you a step-by-step proposal; *cannot* modify code or run commands [14][22]. Act mode: executes the plan, asking permission before each irreversible tool use [14]. Common pattern: frontier reasoning model (Opus, Gemini 2.5 Pro, DeepSeek R1) in Plan, cheap executor (Llama 3.3 70B on Groq, Gemini Flash) in Act [14]. **This is structurally identical to APEX's architect → executor split — Cline did it in the IDE, APEX did it in the framework.** |
| **Focus Chain** | Auto-generates a todo list from the user's task, **re-injects the list every 6 messages by default** to fight "lost in the middle" [22][24]. **Directly addresses APEX failure-mode #3 (context loss), and arguably better than APEX's STATE.json which requires the agent to actively read it.** Released v3.25 (Aug 2025) [24]. |
| **Deep Planning** | `/deep-planning` command: 4-step process — investigate the entire codebase, grep, read files, analyze patterns and dependencies — *before* writing a plan [24]. Comparable to APEX's `/apex:discuss-phase` + planner. |
| **Checkpoints (shadow git)** | **Per-tool-call checkpoints** — every file write, terminal command, web request gets its own checkpoint in a shadow Git repo [22]. Three restore modes: Restore Files, Restore Task Only, Restore Files & Task [22]. **More granular than Cursor or Windsurf.** Mirrors APEX's pre-task snapshot but at finer granularity. |
| **Auto-approve** | Pre-authorize specific categories: read-only ops, file writes, terminal commands, browser actions, MCP tool calls [14]. Per-category yes/no, no fancy heuristics. |
| **Rules system** | `.clinerules/` directory; conditional rules for file-scoped governance ("apply these rules when editing `*.tsx`") [14][13]. |
| **MCP integration** | Native, deep. **MCP Marketplace** for one-click install [14]. Largest non-Anthropic MCP surface in the category. |
| **Computer Use** | Agent can verify its own UI work in a real browser (Claude Computer Use under the hood) [14]. APEX has no equivalent. |
| **Model agnosticism** | Anthropic, OpenAI, Google, OpenRouter, AWS Bedrock, Azure/GCP Vertex, Ollama local [13]. BYOK by default. |
| **Cost posture** | Open source free; **Teams free through Q1 2026, $20/user/mo after (first 10 seats permanently free)** [26]. Enterprise custom; deployed at Samsung, SAP, Oracle, Salesforce [26]. **BYOK means inference cost goes straight to the model provider — APEX-comparable economics.** |
| **Non-programmer accessibility** | Better than Cursor's Agent mode for "see every step" auditability; worse than Cursor's chat for pure speed. Plan/Act split is intuitive even for non-devs. |
| **Critic / verification** | None as a separate agent. Diagnostics + auto-approve gates substitute. |
| **Memory** | `.clinerules/`, AGENTS.md, project-level task history. No three-tier memory or dream-cycle synthesis. |
| **What it does BETTER than APEX** | (1) **Per-tool-call shadow-git checkpoints** — finer than APEX's pre-task snapshot. (2) **Focus Chain auto-injection every 6 messages** — APEX's STATE.json requires explicit reads; Cline forces the context-loss fix into the model. (3) **Multi-IDE distribution** (VS Code + JetBrains + Cursor + Windsurf + Zed + Neovim) — APEX is Claude-Code-first with thin adapters; Cline is IDE-agnostic by construction. (4) **Cline SDK as an open-source agent runtime** — anyone can build their own Cline-on-top-of-X; APEX doesn't offer an SDK. (5) **Computer Use** for self-verifying UI work. (6) MCP Marketplace UX is best in the category. |
| **What APEX does better** | (1) Spec/decisions/complexity control plane vs. Cline's flat `.clinerules/`. (2) Falsifiable RESULT.json. (3) Critic agent + auditor filesystem-quarantine. (4) Wave parallelization with one-file-one-owner. (5) Workflow library as organizational memory. (6) Self-healing loop. (7) Non-programmer dual-mode philosophy. (8) DORA tracking. |
| **What APEX should steal / learn** | (a) **Re-inject the active task list into every Nth message** — this is the single highest-leverage anti-drift mechanism in the category, and APEX should add it to `/apex:next`. (b) **Per-tool-call checkpoints** in the pre-task-snapshot hook (currently only per-task). (c) **Publish an APEX SDK** so Cursor/Zed/etc. can run APEX as an embedded runtime. (d) **Computer Use** for UI verification via the verifier agent. (e) Bring `AGENTS.md` adoption to the front (`.apex/SPEC.md` continues to be the deeper layer). |
| **Threat level** | **CRITICAL.** Cline is the most architecturally similar tool to what APEX builds on top of Claude Code — Plan/Act, checkpoints, hooks, MCP, rules. **If a non-programmer asks "what's the most rigorous AI coding tool that's free?", Cline is the answer if they don't know about APEX.** |

---

### 2.4 Roo Code (RooCodeInc/Roo-Code) — **3M+ installs, dead on May 15, 2026**

| Dimension | Detail |
|---|---|
| **Lineage / scale** | Forked from Cline. **3M+ installs at peak** [17]. v3.50.4 released Feb 21, 2026 [15]. **Co-founder Matt Rubens announced shutdown on April 21, 2026; all products end May 15, 2026 — VS Code extension, Roo Code Cloud, Roo Code Router** [16][17]. |
| **Core philosophy (was)** | Roo Code gives you "a whole dev team of AI agents in your code editor" — multiple personas (Code, Architect, Ask, Debug, custom) [15]. |
| **Why it died** | Team concluded "**IDEs are not the future of coding**" and pivoted to **Roomote** — a cloud-based autonomous agent that runs end-to-end across Slack, GitHub, and Linear with no IDE [16][17]. Bet: developers want delegation, not better autocomplete. **This is the same thesis Devin/Background Agent/VS Code Cloud Agent are betting on.** |
| **Modes (was)** | Code, Architect, Ask, Debug, plus custom modes and a community Mode Gallery [15]. **Diff-based editing saved ~30% tokens vs. Cline's full-file rewrites** [15]. |
| **Heir** | **Kilo Code** (see §2.5) — forked from Roo, also pulls Cline features. Most Roo users migrating there [17][18]. |
| **What APEX should learn** | The shutdown is the single most important data point in this entire report. **A 3M-install product whose team unanimously decided the IDE plugin layer was a dead end.** If they are right, APEX's IDE-adapter strategy needs to assume the surface area shrinks while cloud-agent and CLI surface area grows. The Roomote thesis (Slack-as-IDE, GitHub-as-runtime) is plausible enough that APEX should sketch a "headless mode" for the same use-case. |
| **What this means for APEX** | (1) Don't over-invest in IDE-specific adapters — invest in **cross-IDE protocols (ACP, AGENTS.md, MCP)**. (2) The "delegate to cloud, get a PR" workflow is becoming the dominant one — APEX needs a story here that's not just `/apex:new-workspace`. (3) Brand collapse is real — a beloved 3M-install tool can die in 30 days because the founders changed their mind about the category. **APEX needs founder-independence (community, contributors, governance) to survive a similar pivot.** |
| **Threat level** | **N/A — dead.** But the *reason* it died (founders' loss of faith in the IDE-plugin category) is a Critical strategic signal. |

---

### 2.5 Kilo Code (Kilo-Org/kilocode) — **Roo's heir with platform ambitions**

| Dimension | Detail |
|---|---|
| **Lineage / scale** | Direct fork of Roo Code, **also pulls features from Cline** — "superset of Cline and Roo" [18][19]. **Raised $8M Dec 2025** with mission to become the "agentic engineering platform" [19]. Now positioning as IDE extension *plus* deployment platform. |
| **Modes** | Multi-mode: Plan (Architect), Code (Coder), Debug (Debugger), plus custom [19]. Same shape as Roo's. |
| **MCP Marketplace** | Yes, with one-click install. |
| **Model support** | **500+ models** including Claude 4 Sonnet/Opus, Gemini 2.5 Pro [19]. |
| **Platform features** | **Kilo Deploy** (one-click deploy), voice prompting, **sessions sync across devices** [19]. Distinctly more than just an IDE plugin. |
| **AGENTS.md** | First-class support [20]. |
| **IDE coverage** | VS Code primary; JetBrains plugin; CLI [19]. |
| **What it does BETTER than APEX** | (1) **Voice prompting in the IDE** — APEX has no voice surface. (2) **Sessions sync across devices** — APEX state is per-machine unless user manually syncs `.apex/`. (3) Platform extension (deploy, cloud) — APEX has no deploy story. (4) Plug-and-play Roo + Cline feature parity for users wanting both. |
| **What APEX does better** | Same list as Cline (Cline ⊆ Kilo featurewise, so APEX's Spec/Decisions/Complexity/critic/falsifiability/self-healing all still apply). |
| **What APEX should steal / learn** | (a) **Voice prompting** — for non-programmers especially, this is huge. (b) **Sessions sync across devices** (could be as simple as recommending `.apex/` in a synced folder + a `/apex:sync` helper). (c) Position APEX as a *platform*, not just a framework. |
| **Threat level** | **HIGH and rising.** Best-positioned heir to Roo's installed base + active platform ambitions + $8M runway. By Q4 2026, Kilo may be the *third* serious choice (behind Cursor and Cline) for users picking an IDE agent. |

---

### 2.6 Continue.dev (continuedev/continue) — **Pivoted out of the IDE-extension race**

| Dimension | Detail |
|---|---|
| **Lineage / scale** | Open-source VS Code + JetBrains extension since 2023. **Pivoted to "Continuous AI"** in mid-2025 [11][12] — an open-source CLI that **runs async agents on every PR**, enforcing team rules and suggesting fixes. The IDE extension still exists but the *narrative* has shifted to CI-driven AI checks. |
| **Core philosophy (now)** | "**Source-controlled AI checks, enforceable in CI**" [12]. Each check is a markdown file in your repo → shows up as a GitHub status check, green if good, red with a suggested fix if not [12]. |
| **Agent Mode (still in IDE)** | Autonomous multi-step: analyze → plan → modify files → execute terminal → verify [11]. Tool calls embedded in chat requests with user permission. |
| **Headless mode** | Run agents in the cloud with no UI — perfect for CI/CD [12]. |
| **Model support** | Claude Opus 4.6 / Sonnet 4.6, GPT-4o / o3, Gemini 2.0 Pro, Llama 3.3, DeepSeek V3 [11]. |
| **Pricing** | **Free, open source, no paid tiers** [11]. |
| **Why this matters for APEX** | Continue's pivot is **Exhibit B** (after Roo) of the thesis: *the IDE-extension surface is being eaten by CI-side checks and cloud agents*. APEX's CI story is currently weak — it's a *human workflow* framework. **`/apex:ship` could grow a CI-checks pipeline mirroring Continue's approach.** |
| **Threat level** | **MEDIUM.** Not a direct IDE-extension competitor anymore. But the CI-checks angle is a *flank attack* on APEX's "trust the agent" story — Continue is selling provable, machine-enforced rules at the PR boundary, which is conceptually similar to APEX's critic but lives in CI rather than in the dev loop. |

---

### 2.7 Zed (zed-industries/zed) — **The performance-and-protocol play**

| Dimension | Detail |
|---|---|
| **Lineage / scale** | Rust-native editor, GPU-accelerated, no Electron. Open source under GPL v3 [28]. **Zed 1.0 released April 29, 2026** [28]. Loads 100k-line monorepo in <1s vs. Cursor's ~4.5s [28]. |
| **Agent Panel** | Primary AI surface — first-party agent + external agents (Claude Agent, Gemini CLI, Codex, Copilot) [29][32]. **`cmd-alt-j`** opens threads sidebar — each thread isolated context window [29]. |
| **Parallel Agents (Zed 1.0)** | Multiple agents in same window, working on different parts of the codebase [28]. Worktree isolation. |
| **External Agents via ACP** | Zed defined the **Agent Client Protocol (ACP)** — open standard for any agent to integrate with any editor. **20+ tools + JetBrains adopted by May 2026** [28][32]. ACP is to agents what LSP is to language servers. |
| **Multibuffer review** | "Review Changes" multi-buffer tab — accept/reject individual hunks or whole changesets [29]. **The best change-review UX in the category** for cross-file refactors. |
| **Tool permission profiles** | Write / Ask / Minimal built-ins + pattern-based rules for per-tool confirm/allow/deny [29]. |
| **Checkpoints** | Yes, first-party. External agents may not all support [29]. |
| **MCP** | Native; warning icons when models don't support all MCP tools [29]. |
| **Collaborative editing** | Multiple humans + multiple agents share one buffer + cursor stream + channels [29]. **Unique in the category.** |
| **Model agnosticism** | Via ACP, anything goes. BYOK at the provider level [29]. |
| **What it does BETTER than APEX** | (1) **ACP as an open protocol** — APEX has no protocol story; it's a wrapper. (2) **Native multi-human + multi-agent collaboration** — APEX is single-user. (3) **Multibuffer-review for cross-file refactors** — APEX's diff UX runs through the underlying IDE; Zed's is purpose-built. (4) **Native performance** — non-programmers feel speed; this matters. (5) Free, open source, GPL. |
| **What APEX does better** | (1) Pipeline orchestration. (2) Spec/decisions/complexity control plane. (3) Critic agent / falsifiability. (4) Self-healing loop. (5) Workflow library. (6) Non-programmer-first design (Zed is a developer's editor through and through). |
| **What APEX should steal / learn** | (a) **Adopt ACP** as one of APEX's adapter targets — sit on top of Zed natively without re-implementing the agent shell. (b) **Multibuffer change review** — APEX's `/apex:ui-review` could output a Zed multibuffer, or APEX could ship its own. (c) **Collaborative mode** — multi-user APEX state in `.apex/` is unblocked by file sync, but the UX deserves explicit support. (d) Tool permission profiles (Write/Ask/Minimal) as APEX scope presets. |
| **Threat level** | **MEDIUM.** Zed is a *protocol* threat more than a *product* threat — if ACP becomes the LSP-of-agents, APEX needs to speak ACP fluently or be locked out of Zed's growing user base. The actual Agent Panel UX is good but not category-leading. |

---

### 2.8 JetBrains AI Assistant + Junie — **The enterprise-IDE incumbent's autonomous answer**

| Dimension | Detail |
|---|---|
| **Lineage / scale** | AI Assistant since 2023. **Junie launched January 2026** [33]. Plugin available for IntelliJ, PyCharm, WebStorm, GoLand, RubyMine, RustRover etc. **Junie CLI** runs outside JetBrains IDEs too [33]. |
| **Core philosophy** | "Deep IDE integration" — Junie uses JetBrains' static analysis, refactoring engine, AST awareness, and project model directly, not via vector retrieval [33][34]. Plans → reviews with user → executes stage by stage. |
| **Hierarchical planning + backtracking** | Junie creates a structured plan with requirements, technical design, delivery stages, and testing; user confirms; Junie executes stage-by-stage with backtracking on failure [34]. **The closest commercial competitor to APEX's phase-and-wave structure.** |
| **Execution loop** | After each generation: run the built-in compiler + inspections, execute tests, catch type mismatches / compile errors, self-correct [34]. **Uses the IDE's deterministic toolchain as the verification substrate — far stronger than running shell tests.** |
| **Workflow modes** | Code mode (multi-step plan + execute with reporting), Ask mode (read-only exploration) [34]. Mirrors Cline's Plan/Act. |
| **Mellum** | JetBrains' proprietary autocomplete LLM, used for inline completions; Claude/Gemini routed for reasoning tasks [35]. |
| **Pricing** | **AI Pro $100/year (10 credits / 30 days), AI Ultimate $300/year (35 credits), AI Enterprise $720/year (max credits)** [36]. Credits consumed per agentic task. *Heavy users complain Ultimate runs out fast* [36]. |
| **Capabilities** | Migrate a module from Java 17 → 21 or CommonJS → ESM with 90% accuracy [33]. Refactor modules from natural-language prompts. |
| **AGENTS.md support** | Yes (via JetBrains' AI plugin layer) [20]. |
| **Critic / verification** | Implicit via IDE inspections + tests. No separate critic agent. |
| **What it does BETTER than APEX** | (1) **IDE static analysis as the verification substrate** — APEX runs `pytest`/`vitest` and parses output; Junie reads JetBrains' AST directly. Lower false-positive rate, semantic understanding of types and call graphs. (2) **Hierarchical plan + backtracking** is the most APEX-like execution structure in the category — and it's native to a $720/year enterprise product. (3) **Existing enterprise distribution** — JetBrains has 12M+ developers; Junie reaches them by default. (4) **CLI for non-JetBrains users** so even VS Code/Neovim users can drive it. |
| **What APEX does better** | (1) Open source / free. (2) Cross-IDE/cross-CLI by construction. (3) Critic as a separate, code-blind agent. (4) Falsifiable RESULT.json. (5) Workflow library. (6) Scale-adaptive. (7) Non-programmer dual-mode. |
| **What APEX should steal / learn** | (a) **Use AST tools where available** — APEX's verifier could call language servers via LSP for type-checking rather than shell-test-only. (b) **Hierarchical plan + backtracking** is exactly the structure APEX already has — package it more visibly (`/apex:plan-phase` → wave map → backtrack-on-failure is the same shape but APEX users don't see it as one unit). (c) Pricing model: per-credit transparency, not per-seat, may appeal to APEX's non-programmer audience. |
| **Threat level** | **HIGH (in enterprise).** For any team already on JetBrains IDEs, Junie is the obvious "we don't need APEX or Cursor" answer. For non-JetBrains users, the CLI is a less interesting option than Cline. |

---

### 2.9 VS Code Copilot Agent Mode + Visual Studio 2026 Cloud Agent — **The Microsoft full-court press**

| Dimension | Detail |
|---|---|
| **Lineage / scale** | Copilot Agent Mode **GA on both VS Code and JetBrains as of March 2026** [37]. April 2026 VS Code releases (1.115, 1.116) added Companion App, MCP server bridging, Copilot CLI remote steering [37]. **Visual Studio 2026 integrated cloud agent in Copilot Chat picker, April 2026** [38]. |
| **Core philosophy** | Multi-pronged: local agent (VS Code/VS), CLI agent (background, optional worktrees), cloud agent (GitHub Actions infra). "Assign a task, close the IDE, get a PR" [38]. |
| **Coding Agent** | Assign a GitHub *issue* to Copilot → it writes code, runs tests, opens a PR — fully async, runs on GitHub Actions [37]. |
| **Third-party agent harness** | SDK from Anthropic and OpenAI — third-party agents run locally or in cloud through the Copilot harness [37]. **Microsoft is becoming an aggregator, not just a product.** |
| **Agentic code review** | Shipped March 2026 — gathers full project context, can pass suggestions directly to the coding agent for auto-fix PRs [37]. Bugbot-clone, scaled by Microsoft. |
| **Companion App** | Standalone app for parallel agent sessions, MCP server bridging, terminal control, remote CLI steering from any device [37]. |
| **Custom agents** | VS 2026 Insiders adds **guided skill building in Agent Mode** — build your own specialized agent inside the IDE [37]. |
| **Pricing** | Individual $19/mo, Business $39/user/mo, Enterprise $39/user/mo [37]. |
| **C++ tools** | C++ Code Editing Tools GA in agent mode — language-aware navigation, class hierarchy mapping, call-chain following [38]. **Areas where APEX has weak coverage.** |
| **What it does BETTER than APEX** | (1) **Distribution** — VS Code is ~70% market share among devs; Copilot ships there for free-trial. (2) **Cloud Agent on GitHub Actions infrastructure** — no separate compute provider, integrates with org's existing CI. (3) **Third-party harness for Anthropic + OpenAI agents** — Microsoft is happy to be the chassis for everyone, including Claude. (4) C++ language-aware tools at GA quality — APEX is language-agnostic, which is also a weakness. |
| **What APEX does better** | (1) Open source. (2) Spec/decisions control plane. (3) Critic agent. (4) Wave parallelization at the framework level. (5) Self-healing loop. (6) Non-programmer dual-mode. (7) Falsifiability. (8) Free. |
| **What APEX should steal / learn** | (a) **Build APEX on top of the Copilot third-party harness** — APEX could be one of the "skills" available in Copilot Agent Mode. (b) **GitHub-Actions-as-cloud-runner** for `/apex:execute-phase` — eliminate the need for users to set up their own background compute. (c) **Assign-an-issue-to-APEX** workflow — issue → spec → plan → wave → critic → PR, fully async. (d) Companion App pattern — separate UI for monitoring parallel APEX runs. |
| **Threat level** | **CRITICAL (in enterprise) / HIGH (overall).** Microsoft is bundling all of this with GitHub Enterprise — APEX has to justify itself against "we already have Copilot." The third-party harness is also a *gift* — APEX can target it as a runtime. |

---

### 2.10 Trae (ByteDance) — **The free VS Code fork with SOLO mode**

| Dimension | Detail |
|---|---|
| **Lineage / scale** | ByteDance VS Code fork, free tier extremely generous (10 fast + 50 slow + 1k advanced + 5k autocompletes/month) [23]. macOS + Windows + browser-based Cloud IDE [23]. **Trae Agent open-sourced on GitHub** as a general-purpose SWE agent [23]. |
| **Builder Mode** | Take a natural-language description → scaffold a complete project end-to-end (file structure, code, deployment) [23]. |
| **SOLO Mode (Trae 2.0)** | **Fully autonomous coding agent** — takes an idea, plans, picks tools, executes, ships production-ready code [40]. Multi-agent orchestration: multiple agents on different tasks at once, each with its own model and context [40]. **Granular IDE-mode-to-SOLO-mode handoff** — user picks autonomy level per task [40]. |
| **Model support** | GPT-4o, Claude Sonnet, Gemini 2.5 Pro, ByteDance proprietary [23]. |
| **Multimodal** | Upload Figma → get React components [23]. |
| **Pricing** | Free tier usable for hobby work. Pro $10/mo (or $90/year) — cheapest serious AI IDE on the market [23]. |
| **Privacy concerns** | **Telemetry shared with ByteDance affiliates, no opt-out, 5-year retention after account closure** [23]. **Linux unsupported** [23]. |
| **Context limits** | Loses track on 50k+ line codebases [23]. |
| **What it does BETTER than APEX** | (1) **Truly autonomous "ship me a deployed app" SOLO mode** with model handoff — APEX has nothing like Builder/SOLO. (2) **Figma → React** multimodal pipeline. (3) **Cheapest serious AI IDE** ($10/mo). (4) Granular autonomy slider per task. |
| **What APEX does better** | (1) **Trust posture** (open source, no ByteDance telemetry, no 5-year retention). (2) Spec/critic/falsifiability. (3) Scale (Trae loses 50k+ line codebases; APEX scales-adaptively). (4) Linux support. (5) Pipeline rigor. |
| **What APEX should steal / learn** | (a) **Autonomy slider per task** — APEX has `/apex:fast` vs `/apex:full` but they're separate commands; Trae lets you set a slider mid-task. (b) **Figma → component** workflow as a UI-phase recipe. (c) Builder/SOLO-style end-to-end scaffolding workflow recipe. |
| **Threat level** | **MEDIUM.** Privacy concerns + Linux gap + China-vendor risk limit enterprise adoption, but for hobbyist non-programmers (APEX's core audience), Trae is *very* compelling. The free tier is genuinely lethal. |

---

### 2.11 Void (voideditor/void) — **The open-source ideal that stalled**

| Dimension | Detail |
|---|---|
| **Lineage / scale** | Open-source VS Code fork — Cursor-style features (tab autocomplete, inline edits, agent), connects directly to model providers (no middleman backend) [25]. Top-trending HN/GitHub launch. |
| **Current status** | **Active development paused as of 2026** [25]. Repo still public, last build still runs, no end-of-life notice, but no new features and PRs/issues not reviewed [25]. |
| **Agent Mode + Gather Mode + Chat** | Three modes; agent can read and modify codebase, gather mode for read-only context-building [25]. |
| **Diagnostics in the loop** | Editor's own lint/type errors fed back to the model after each change [25]. |
| **Structured patches, not full-file rewrites** | Like Roo Code [25]. |
| **FIM-style completion model support** | Tab autocomplete uses fill-in-the-middle models, not just chat completion [25]. |
| **Privacy stance** | **Directly connects to model providers — no Void backend touches your code** [25]. Strongest privacy posture in the category. |
| **Model agnosticism** | DeepSeek, Llama, Gemini, Qwen, anything self-hosted [25]. |
| **Why it stalled** | *Unverified* — likely founder bandwidth + Cursor's massive funding overwhelming any open-source alternative's velocity. |
| **What it does BETTER than APEX** | (1) **No-backend, direct-to-provider privacy posture** — APEX could match this (it does, by sitting on top of Claude Code) but doesn't market it. (2) **FIM models for autocomplete** — niche but technically correct. |
| **What APEX does better** | (1) Active development. (2) Pipeline. (3) Critic. (4) Spec layer. (5) Self-healing. (6) Everything else. |
| **What APEX should steal / learn** | (a) **Lead the marketing with privacy posture** — "your code never touches an APEX server" is a strong line. (b) Watch the Void repo: if a successor (or hard fork) emerges with momentum, it's a free-software ally to align with. |
| **Threat level** | **LOW (stalled).** A monument to how hard it is to compete with Cursor on raw IDE-agent UX without funding. |

---

### 2.12 (bonus) Google Antigravity 2.0 — **The Gemini-native IDE that became a platform at I/O 2026**

| Dimension | Detail |
|---|---|
| **Lineage / scale** | Launched late 2025 as Google's Gemini-native agentic IDE. **Antigravity 2.0 at I/O May 19, 2026** — standalone desktop app + CLI + SDK + Managed Agents in Gemini API + Gemini Enterprise Agent Platform [42]. Free for individuals during public preview [42]. macOS / Windows / Linux [42]. |
| **Core philosophy** | "Agent-first" — deploy agents that autonomously plan, execute, and verify complex tasks across editor + terminal + browser [42]. Default model: Gemini 3.5 Flash with optionality for Gemini 3 Pro, Claude Sonnet 4.5, GPT-OSS [42]. |
| **What it means** | Google is the **third hyperscaler** (after Anthropic-via-Claude-Code and Microsoft-via-Copilot) shipping a first-party agent stack. **APEX already has thin Antigravity adapter listed in its multi-platform story** — this is correct strategy. |
| **Threat level** | **HIGH and rising.** Antigravity 2.0's CLI + SDK opens a wide surface for APEX to layer on top of — same playbook as Claude Code. The threat is that Google ships a *good enough* native pipeline (planner + critic + verifier) bundled with free Gemini access, and APEX's value-add on Antigravity shrinks before APEX users discover the platform. |

---

## 3. Cross-cutting patterns in this domain

**(A) The IDE-extension layer is being eaten — from below by CLIs, from above by cloud agents.** Roo Code's shutdown [16][17], Continue's pivot to CI [12], Cline's SDK + CLI investments [30], and Roomote's "delegate-to-Slack" pitch [17] all point the same direction: the *editor sidebar* is no longer where the future of AI coding lives. **Cursor and Windsurf are the exceptions because they own the editor itself**, not just an extension.

**(B) "Plan / Act" or "Architect / Code" is now table stakes.** Every serious tool in this report ships a planner mode: Cursor Plan Mode [1], Windsurf planning-agent [9], Cline Plan/Act [22], Roo Code Architect [15], Kilo Plan-Architect [19], Junie hierarchical plans [34], Continue agent multi-step [11], Trae Builder [23]. **APEX's `/apex:plan-phase` + executor split is no longer differentiated as a *feature* — only as a *discipline*.** APEX must lead with rigor (clean-room critic, falsifiable RESULT.json, scope-discipline hooks), not the architecture alone.

**(C) Parallel agents in git worktrees are converging on the same UX.** Cursor (up to 8 [2]), Zed 1.0 [28], Windsurf Agent Command Center [10], VS Code Companion App [37], Trae multi-agent [40], Cline (via SDK [30]). **APEX's `/apex:new-workspace` is correct architecture but the UX is a CLI command, not a Kanban board.** This is the single most visible gap.

**(D) AGENTS.md is winning as the universal rules format.** Joint Google/OpenAI/Factory/Sourcegraph/Cursor launch [20]; **60,000+ repos** carry it; tools with detailed AGENTS.md average 35-55% fewer agent-generated bugs [20]. **APEX uses `.apex/SPEC.md` + `.apex/DECISIONS.md` + `.clinerules/`-style files.** APEX should *also* read/write AGENTS.md as the public surface and treat its internal files as the deeper layer.

**(E) Checkpoints are getting finer-grained.** Cline at per-tool-call [22], Cursor per-session [7], Windsurf named-and-irreversible [9], Zed first-party + ACP-mediated [29]. **APEX's pre-task snapshot is coarser than Cline's** — the next iteration should match per-tool granularity, ideally via a `PostToolUse` hook.

**(F) Agent runtimes are becoming SDKs.** Cline SDK released May 14, 2026 [30]; VS Code third-party harness from Anthropic + OpenAI [37]; Zed ACP [32]; Antigravity SDK [42]. **APEX has no SDK** — anyone wanting to extend APEX must edit markdown files in `~/.claude/`. This is a major gap if APEX wants to be embedded *inside* other tools rather than alongside them.

---

## 4. Where this domain collectively beats APEX

1. **Native parallel-agent UX.** Cursor's Agents Window [7], Windsurf's Agent Command Center [10], Zed's threads sidebar [29], VS Code's Companion App [37]. APEX has STATE.json and `/apex:status` — text, not a board.
2. **Cloud / Background agents bundled with IDE plan.** Cursor Background Agent [2], Windsurf Devin Cloud [10], VS Code Coding Agent on GitHub Actions [37]. APEX has no "delegate to a cloud and come back to a PR" story.
3. **Per-tool-call shadow-git checkpointing.** Cline [22] is finer than APEX's pre-task snapshot.
4. **Re-injection of task list every Nth message** to fight context drift (Cline Focus Chain [22][24]). APEX has it as JSON state; Cline forces it back into the prompt.
5. **In-house frontier models at 1/10 cost.** Cursor Composer 2.5 [6]. APEX has no model lab.
6. **IDE static analysis as verification substrate** (Junie [34]). APEX runs shell tests; Junie reads the AST.
7. **Voice prompting** (Kilo [19], Cursor *unverified*).
8. **Multimodal Figma → component** (Trae [23], Cursor *unverified*).
9. **Cross-IDE distribution** (Cline ships in 7+ IDEs and a CLI [14]). APEX is Claude-Code-first.
10. **AGENTS.md universal standard adoption** — APEX uses its own layout [20].
11. **PR-level critic with measurable resolution rate** (Bugbot 70% [8]). APEX's critic operates pre-merge, not as a separate productized lane.
12. **Mobile control surface** (Cursor [2], VS Code remote CLI steering [37]).
13. **Sub-second editor performance** (Zed [28]) and the resulting non-programmer perception of "this just works."
14. **Massive funded distribution** (Cursor $50B [4], Microsoft Copilot, JetBrains).

---

## 5. Where APEX collectively beats this domain

1. **Falsifiable RESULT.json schema** with `verified` vs `unverified` and `tool_verified` vs `self_verified`. **No IDE agent in this report has this** — Bugbot reports "resolution rate," but that's an aggregate, not a per-task contract.
2. **Auditor agent filesystem-quarantined from implementation code.** Cursor's Bugbot sees everything; Junie's inspections run inside the IDE process with full file access. APEX's auditor reads tests only.
3. **9 named failure modes with named hooks per failure.** No competitor enumerates failure modes; they ship generic "safety" + "checkpoint."
4. **Self-healing loop with two-consecutive-clean-rounds stop criterion** (`/apex:self-heal`). No competitor has a structured spec-anchored convergence loop.
5. **Scale-Adaptive Classifier** — auto-tunes ceremony to project scale. Every competitor either is ceremony-free (Cursor) or ceremony-heavy (Junie) by construction.
6. **Workflow library as organizational memory** — 30+ pre-built recipes. Closest competitor is Windsurf's Workflows [21] but they are ad-hoc per team.
7. **Non-programmer dual-mode philosophy** (collaborator vs. replacement based on domain expertise). Every competitor is built for developers.
8. **Spec/Decisions/Complexity control plane** as git-diff-able files. Competitors offer `.cursor/rules/`, `.clinerules/`, AGENTS.md — but no first-class decisions log or complexity scoring.
9. **Free forever core + paid enterprise** — Cursor Pro is $20/mo, Junie Pro is $100/year, even Cline charges for teams. APEX's commitment to free-core is rare.
10. **Multi-platform via thin adapters.** APEX runs on Claude Code, Cursor, Codex, Copilot, Gemini, Windsurf, Antigravity. Every competitor here is locked to its host editor.
11. **`/apex:peer-review` and `/apex:_debate` / `/apex:_roundtable`** as multi-agent quality structures. Closest analog is Cursor multi-model best-of-pick [1] — much shallower.
12. **Reflexion executor with anti-rationalization injection + phantom-check hook for self-incrimination patterns.** Unique anti-hallucination posture.

---

## 6. Strategic recommendations for APEX

In priority order, with rough effort estimates:

1. **(P0, 2-3 weeks) Adopt AGENTS.md as APEX's public surface.** Read it. Write it on `/apex:onboard`. Keep `.apex/SPEC.md` as the deeper layer. Without this, APEX users on Cursor/Windsurf/Kilo are getting a worse experience than they would with native tools. This is the single highest-leverage move. [20]

2. **(P0, 3-4 weeks) Add re-injection of the active task/wave list every N messages, copying Cline's Focus Chain mechanically [22][24].** This is the lowest-effort, highest-impact anti-drift mechanism available, and it is a *direct fix* to APEX failure-mode #3 (context loss).

3. **(P1, 4-6 weeks) Per-tool-call shadow-git checkpoints via a `PostToolUse` hook.** Match Cline's granularity. Restore-files / restore-task / both — same three modes [22].

4. **(P1, 4-6 weeks) Publish an APEX SDK** that lets other tools embed APEX as an agent runtime — mirroring Cline SDK [30]. Lets APEX run *inside* Cursor's third-party harness, VS Code's third-party harness [37], Zed's ACP [32], Antigravity [42]. Without this, APEX is a Claude-Code-first framework forever.

5. **(P1, 2-3 weeks) Glass-cockpit TUI for parallel waves.** Match Cursor Agents Window [7] / Windsurf Agent Command Center [10] / Zed threads sidebar [29] / VS Code Companion App [37]. STATE.json + jq is technically equivalent but UX-deficient.

6. **(P1, 4-8 weeks) "Delegate to cloud, get a PR" workflow via GitHub Actions.** `/apex:cloud-execute` — APEX phase runs on Actions, opens a PR. Eliminates the need for users to set up their own background compute. Directly answers the Roo Code "IDEs aren't the future" thesis [17].

7. **(P2, 2 weeks) Concurrent planner-and-executor option.** Windsurf's specialized planning agent that refines the plan *while the executor takes short-term actions* [9] — APEX's current sequential pattern is more disciplined but slower for trivial work.

8. **(P2, 1 week per UI) Lead marketing with privacy posture.** "Your code never touches an APEX server." Void [25] could have owned this; nobody currently does. APEX's open-source + BYOK story is genuinely best-in-category.

9. **(P2, 2-4 weeks) AST-aware verification via LSP.** Junie's IDE-inspection substrate [34] is more reliable than shell-tests for type errors. APEX verifier could call out to LSPs.

10. **(P2, 4 weeks) Autonomy slider per task** (Trae model [40]). APEX has `/apex:fast` vs `/apex:full` as separate commands; one slider is more discoverable.

11. **(P3, ongoing) Plan for the IDE-extension category collapse.** Roo Code died because the team lost faith [17]. Continue pivoted to CI [12]. APEX must avoid the same fate by: (a) staying CLI-resident (Claude Code + Codex CLI + Gemini CLI), not IDE-resident; (b) speaking the *protocols* (ACP, AGENTS.md, MCP, third-party harnesses) so platform shifts don't eject APEX; (c) cloud-execution story so "Slack-as-IDE / GitHub-as-runtime" works.

12. **(P3, ongoing) Pricing transparency.** Junie's per-credit model is transparent but limiting; Cursor's per-request is opaque. APEX's free-core + future enterprise tier should pre-publish per-task cost estimates (planner cost + executor cost + critic cost) so users can compare against Cursor's $20/$60/$200 stack honestly.

---

## 7. Sources & citations

1. Cursor — "Best practices for coding with agents" — https://cursor.com/blog/agent-best-practices
2. AdwaitX — "Cursor Deploys BugBot Agent: 70% Resolution Rate at 2M PRs/Month" (2026) — https://www.adwaitx.com/cursor-bugbot-ai-code-review-agent-2026/
3. Cognition — "Cognition's acquisition of Windsurf" — https://cognition.ai/blog/windsurf
4. TechFundingNews — "Anysphere's Cursor soars to $29B valuation" (Nov 2025); CNBC — "AI startup Cursor raises $2.3 billion at $29.3 billion valuation" — https://techfundingnews.com/anysphere-soars-to-29-3b-valuation-with-2-3b-funding-redefining-the-future-of-coding/ and https://www.cnbc.com/2025/11/13/cursor-ai-startup-funding-round-valuation.html
5. DataCamp — "What Is Cursor 3? Agents, Worktrees, and What's New" — https://www.datacamp.com/blog/cursor-3
6. Cursor — "Introducing Composer 2" (Mar 19, 2026) and "Composer 2.5" review (May 2026) — https://cursor.com/blog/composer-2 and https://www.buildfastwithai.com/blogs/cursor-composer-2-5-review-2026
7. AgentPatterns — "Cursor 3 Agents Window: Parallel Agents and Worktree Isolation" — https://www.agentpatterns.ai/tools/cursor/agents-window/
8. Cursor — "Closing the code review loop with Bugbot Autofix" — https://cursor.com/blog/bugbot-autofix and "Bugbot Autofix" changelog (Feb 26, 2026) — https://cursor.com/changelog/02-26-26
9. Windsurf — "Cascade" docs — https://docs.windsurf.com/windsurf/cascade/cascade
10. AlternativeTo — "Windsurf 2.0 has launched with a new Agent Command Center, Spaces, and Devin integration" (April 16, 2026) — https://alternativeto.net/news/2026/4/windsurf-2-0-has-launched-with-a-new-agent-command-center-spaces-and-devin-integration/
11. WeavAI — "Continue.dev Review 2026: Free Open Source AI Coding" — https://weavai.app/blog/en/2026/04/25/continue-dev-review-2026-free-open-source-ai-coding/
12. Continue — GitHub repo and product page — https://github.com/continuedev/continue and https://www.continue.dev/
13. Cline — GitHub repo (May 2026 snapshot) — https://github.com/cline/cline
14. Cline — Product / docs / DeployHQ Guide 2026 — https://cline.bot/ and https://www.deployhq.com/guides/cline
15. Qodo — "Roo Code vs Cline: Best AI Coding Agents for VS Code (2026)" — https://www.qodo.ai/blog/roo-code-vs-cline/
16. The New Stack — "Roo Code pivots to cloud-based agent, says IDEs aren't the future of coding" — https://thenewstack.io/roo-code-cloud-ides-ai-coding/
17. RoboRhythms — "Roo Code vs Roomote and Why You Need to Switch Before May 15" (2026) — https://www.roborhythms.com/roo-code-vs-roomote/
18. Cursor-Alternatives.com — "Roo Code Shutting Down: Migrate Your Rules to Cline or Kilo Code" — https://cursor-alternatives.com/blog/roo-code-rules/
19. Ai505 — "Kilo Code vs Roo Code vs Cline: The 2026 AI Coding Battle Nobody Saw Coming" — https://ai505.com/kilo-code-vs-roo-code-vs-cline-the-2026-ai-coding-battle-nobody-saw-coming/
20. ASDLC — "AGENTS.md Specification: A Research-Backed Guide" and OpenAI Developers — "Custom instructions with AGENTS.md" — https://asdlc.io/practices/agents-md-spec/ and https://developers.openai.com/codex/guides/agents-md
21. Windsurf — Cascade Memories docs and "Intro to Rules, Memories, & Workflows" — https://docs.windsurf.com/windsurf/cascade/memories and https://windsurf.com/university/general-education/intro-rules-memories
22. Cline — "Focus Chain" docs and Cline blog "How I learned to stop course-correcting and start using message checkpoints" — https://docs.cline.bot/features/focus-chain and https://cline.bot/blog/how-i-learned-to-stop-course-correcting-and-start-using-message-checkpoints
23. AI Adoption Agency — "Trae AI Review: ByteDance Free AI Coding IDE" (2026) and ByteDance trae-agent repo — https://aiadoptionagency.com/trae-ai-bytedances-ai-driven-vibe-coding-ide/ and https://github.com/bytedance/trae-agent
24. Cline — "Cline v3.25: The Coding Agent Built for Hard Problems" (Aug 2025) — https://cline.bot/blog/cline-v3-25
25. Void — voideditor.com and Codersera "Void IDE in 2026: What It Is, How It Works" — https://voideditor.com/ and https://codersera.com/blog/void-ide-complete-guide-2026/
26. CheckThat.ai — "Cline Pricing 2026" and Cline pricing page — https://checkthat.ai/brands/cline/pricing and https://cline.bot/pricing
27. AI:Productivity — "Cursor Pricing 2026: $0 Hobby, $20 Pro, $60 Pro+, $200 Ultra" — https://aiproductivity.ai/blog/cursor-pricing/
28. Builder.io — "Is Zed ready for AI power users in 2026?" and Zed release notes (May 2026) — https://www.builder.io/blog/zed-ai-2026 and https://releasebot.io/updates/zed
29. Zed — "Agent Panel" docs — https://zed.dev/docs/ai/agent-panel
30. MarkTechPost — "Cline Releases Cline SDK: An Open-Source Agent Runtime" (May 14, 2026) — https://www.marktechpost.com/2026/05/14/cline-releases-cline-sdk-an-open-source-agent-runtime-now-powering-its-cli-and-kanban-with-ide-extensions-being-migrated/
31. Cursor — "Composer: Building a fast frontier model with RL" — https://cursor.com/blog/composer
32. Zed — "Agent Client Protocol" and "External Agents" docs — https://zed.dev/acp and https://zed.dev/docs/ai/external-agents
33. JetBrains — "Junie" product page and Geeky Gadgets coverage — https://www.jetbrains.com/junie/ and https://www.geeky-gadgets.com/junie-jetbrains-autonomous-coding-agent/
34. Umayanga Gunawardhana on Medium — "Taming the AI Beast: How Hierarchical Planning with Backtracking Unlocks Junie's Full Potential" — https://umayangag.medium.com/taming-the-ai-beast-how-hierarchical-planning-with-backtracking-unlocks-junies-full-potential-for-b718320367ef
35. AI:Productivity — "JetBrains AI Assistant 2026: Free, $8 Pro, $30 Ultimate" — https://aiproductivity.ai/blog/jetbrains-ai-assistant/
36. JetBrains AI Plans & Pricing — https://www.jetbrains.com/ai-ides/buy/ and JetBrains AI Assistant Licensing — https://www.jetbrains.com/help/ai-assistant/licensing-and-subscriptions.html
37. Visual Studio Magazine / DEV.to — "VS Code Agent Mode in 2026: Companion App and MCP" and Code.visualstudio.com docs — https://dev.to/jangwook_kim_e31e7291ad98/vs-code-agent-mode-in-2026-companion-app-and-mcp-4m4n and https://code.visualstudio.com/docs/copilot/agents/overview
38. Visual Studio Magazine — "VS 2026 Joins VS Code with Integrated Cloud Agent" (Apr 29, 2026) — https://visualstudiomagazine.com/articles/2026/04/29/vs-2026-joins-vs-code-with-integrated-cloud-agent-assign-a-task-close-the-ide-get-a-pr.aspx
39. Microsoft Learn — "Use Agent Mode - Visual Studio" — https://learn.microsoft.com/en-us/visualstudio/ide/copilot-agent-mode?view=visualstudio
40. TRAE — "SOLO mode overview" docs and iWeaver "Trae 2.0: SOLO is All You Need" — https://docs.trae.ai/ide/solo-mode and https://www.iweaver.ai/guide/from-single-prompt-to-full-deployment-trae-2-0-solo-is-all-you-need/
41. Kiro — kiro.dev product page and Digital Applied complete guide — https://kiro.dev/ and https://www.digitalapplied.com/blog/amazon-kiro-aws-agentic-ide-complete-guide
42. MarkTechPost — "Google Launches Antigravity 2.0 at I/O 2026" (May 19, 2026) and Google Developers Blog — https://www.marktechpost.com/2026/05/19/google-launches-antigravity-2-0-at-i-o-2026-a-standalone-agent-first-platform-with-cli-sdk-managed-execution-and-enterprise-support/ and https://developers.googleblog.com/build-with-google-antigravity-our-new-agentic-development-platform/
