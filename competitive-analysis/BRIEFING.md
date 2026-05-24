# APEX Competitive Intelligence Swarm — Shared Briefing

**Mission:** 10 parallel research agents map the entire competitive landscape APEX faces in 2026. Each agent owns one domain and produces ONE deep, citation-rich report. A master document synthesizes all 10.

**Quality bar (non-negotiable — no skimming, no rounding, no hand-waving):**
- Minimum **15 distinct web searches** + **4 deep WebFetches** of primary docs/repos.
- Every load-bearing claim must carry a numbered citation `[N]` resolving to a URL in §7.
- Unverified claims must be tagged `*unverified*` in-line — never silently presented as fact.
- Cross-check vendor blogspam against primary repos / official docs / changelogs / GitHub commits.
- **Active-project research rule:** for any actively-developed project, check the changelog / recent commits / latest release notes before concluding on its current state. Tools evolve weekly in 2026 — do not rely on 2024–2025 articles for "current" claims.
- If a competitor is **dead, abandoned, or pivoted away from APEX's space**, say so and explain when/why.
- The user is a **non-programmer**; explanations must be precise but readable. No jargon-dump.
- Language: English (matches existing Report 05).

---

## 1. What APEX is (you MUST internalize this before writing)

APEX is an **open-source multi-agent framework for AI code agents** — primarily Claude Code, with thin adapters for Cursor, OpenAI Codex, GitHub Copilot, Gemini, Windsurf, and Google's Antigravity. It turns session-by-session AI coding into **autonomous, stateful, falsifiable, cost-aware, multi-platform, scope-honest, injection-hardened, scale-adaptive engineering**.

**Unique market positioning:** designed **first for non-programmers** (not developers). Free forever in the core; paid enterprise services. Tech stack required: TypeScript / Python / Go + git + a test framework.

APEX is built around **9 named failure modes** that kill AI dev projects today:

1. **Pipeline failure** → circuit-breaker hook (recurring-error hash detector with sliding-window detection; health-checkpoint that extends caps when work is healthy, hard-stops when sick), pre-task snapshots in hidden git tree, one-click rollback, recovery menu, `/apex:forensics`, `/apex:help` (free-text conversational navigator — non-programmer never needs to remember command names).
2. **Forgetting** → three-tier memory architecture + **Memory Synthesis dream-cycle agent** that consolidates across sessions; `PROJECT-APEX.md` Two-Tier Methodology; primitives `apex/todos/`, `apex/threads/`, `apex/seeds/`, `apex/backlog/`; **`apex-workflows/` library of 30+ pre-built workflow recipes** (e.g., add-authentication, migrate-to-postgres, prepare-for-production, accessibility-audit). Workflows are organizational memory — successful ones become templates for other projects.
3. **Context loss** → `STATE.json` + `event-log.jsonl` control plane (git-diff-able, jq-queryable). Glass cockpit shows 3–5 top decision-required items. Context ordering follows U-shape attention research. Aider-style repo map. `/apex:list`, `/apex:onboard`, `/apex:resume-work`, `/apex:pause-work` with structured handoff. **Scale-Adaptive Classifier** auto-infers project scale (code size, presence of tests, CI/CD, prod deployment, team size) and pre-tunes ceremony — user can override but defaults are correct. Drops decision burden from non-programmer.
4. **Drift** → `SPEC_VERSION` hash + `SPEC_DELTA.json`; spec-to-verification ledger in Layer 0; iterative decomposition with `originating_requirement_id` (every task traces back to a spec line); `/apex:build` vs `/apex:refine` as separate pipelines; Phase-Gating doctrine; `/apex:discuss-phase` with gray-area classifier; scope-creep detector (short task XML + large diff → flag); `/apex:ui-phase` with 6-pillar Design Contract.
5. **Hallucination / fake reporting** → `phantom-check` hook detects self-incrimination patterns (`desperate hack`, `getting desperate`, `last resort`, `to fool`, `to trick`, `cover-up`, `evade detection`, `# hack`, `XXX hack`); AST-KB Hallucination Gate; `RESULT.json` distinguishes `verified_criteria[]` vs `unverified_criteria[]` AND `tool_verified_criteria[]` vs `self_verified_criteria[]`; **auditor agent NEVER sees implementation code** — only test files (filesystem-quarantined); citation cross-checking against event-log; `/apex:peer-review` (cross-AI manual workflow); APEX_STRICT_MODE=1; Nyquist Validation Layer with Wave 0 enforcement; **`test-architect` module with VETO power on phase completion** (test architecture is a discipline, not a sub-task; runs BEFORE executor on C/D tasks); Reflexion executor with anti-rationalization injection.
6. **Mutation / silent destruction** → `destructive-guard` hook blocks force-push, mass-effect patterns (`pkill -f`, `kubectl delete --all`, `rm -rf *`, `git config core.hooksPath`), `.git/` writes, alias-with-shell-escape; pre-task snapshot; mutation-gate; one-file-one-owner with git worktree isolation; read-parallel/write-serial with Vertical Slices Enforcement; **test-deletion-guard** + skipped-test regression detection (test count cannot silently drop); `/apex:new-workspace` for git-worktree-isolated workstreams.
7. **Quality errors** → **cross-model critic (53% → 80%+ accuracy boost documented in critic literature)**, adversarial persona locked-in (<1% → 93.7%), mutation testing, selective property-based testing, critic restricted to PASS/FAIL/NEEDS_REVIEW (no rationalization room), anti-rationalization injection in executor prompts, typed artifact contracts between roles, `/apex:peer-review`, **`/apex:roundtable`** (multi-specialist collaborative session — security, performance, cost, UX, data specialists present angles on same decision; architect decides), **`/apex:_debate`** for irreversible decisions.
8. **Cost overruns** → token budgets per task, prompt caching, model routing (cheap models for edits, expensive for planning), context-budget hook with 50/75/90% advisory warnings.
9. **Scope chaos / unclear intent** → `/apex:build` (new features) vs `/apex:refine` (improve existing) as distinct pipelines; `/apex:fast` (M15 batch micro-tasks, <5 min single-file no-logic-change); `/apex:quick` (skip optional agents); `/apex:ui-phase` (6-pillar Design Contract with domain-specific contract templates); `/apex:workflow` library; `/apex:walkthrough` step-by-step explanation; `/apex:discuss-phase`; `/apex:plant-seed` for future ideas; `/apex:thread` for ongoing technical discussion.

**Dual-mode philosophy (critical USP):** APEX distinguishes "domains where the user is the expert" (product decisions, UX flows, business rules) → APEX is a **collaborator** (presents options, encourages thought, never decides for user) vs. "domains where the user is not" (code architecture, security patterns, performance optimization) → APEX is a **replacement** (decides and executes, surfaces only trade-offs needing user approval).

**Self-healing loop:** `/apex:self-heal` runs audit → plan → schedule → execute → check rounds until **two consecutive clean rounds (0 P0 + 0 P1 findings)** or max-rounds cap. Anchored on `apex-spec.md`. Uses framework-auditor (P0–P3 classification), remediation-planner (ecosystem 10-question gate per fix), batch-scheduler (independent waves of 5–8 items), wave-executor (strict scope discipline — new findings go to `NEW-FINDINGS-W<X>.md`, never to new fixes), round-checker (two-consecutive-clean stop criterion).

**Architecture footprint:**
- `~/.claude/commands/apex/` — 11 slash command `.md` files
- `~/.claude/agents/` — 8 core + 4 specialist agent `.md` files
- `~/.claude/hooks/` — 16 shell scripts (circuit-breaker, phantom-check, destructive-guard, mutation-gate, quarantine-guard, memory-watchdog, turn-checkpoint, session-auto-resume, etc.)
- `~/.claude/apex-skills/` — stack-specific skill files
- `~/.claude/apex-learnings.md` — learning accumulator
- `~/.claude/settings.json` — hook configuration

**Per-project state:** `.apex/STATE.json`, `CONTEXT_BUDGET.json`, `SPEC.md`, `DECISIONS.md`, `COMPLEXITY.md`, `TASK_MAP.md`, `TEST_MAP.txt`, `.apex/phases/<n>/PLAN.md` + `PLAN_META.json` + `WAVE_MAP.json` + `<task>-RESULT.json` + `<task>-SUMMARY.md` + `<task>-CRITIC.md` + `VERIFY.md`.

**Differentiators worth comparing against everything else:**
- Non-programmer-first design (rare — most tools target devs)
- 9-failure-mode taxonomy with named hooks per failure
- Pipeline orchestration as first-class (`/apex:next` is the heart)
- Falsifiable-by-construction (RESULT.json schema with verified vs. unverified)
- Auditor filesystem-quarantined from implementation code
- Free forever core + paid enterprise (trust-first)
- Multi-platform via thin adapters (not locked to Claude Code)
- Scale-adaptive (one tool from bug-fixes to enterprise systems)
- Workflow library as organizational memory
- Self-healing loop with two-consecutive-clean-rounds stop criterion

---

## 2. The 10 domains (assignments)

| # | Report | Domain | Key competitors (you MUST cover these — find more if relevant) |
|---|---|---|---|
| 01 | `01-claude-code-native.md` | Claude-Code-native frameworks | BMAD-METHOD, SuperClaude, Agent OS (Builder Methods), ContextForge, ccpm, claude-flow, claude-task-master, ClaudeLog, awesome-claude-code agent collections, claude-rules |
| 02 | `02-ide-agents.md` | IDE-embedded AI coding agents | Cursor, Windsurf (Codeium), Cline (formerly Claude Dev), Continue, Roo Code, Zed AI, JetBrains AI Assistant + Junie, Visual Studio Copilot Agent Mode, Trae, Void editor |
| 03 | `03-autonomous-commercial.md` | Autonomous commercial agents (full-project) | Cognition Devin, Manus (Monica), Replit Agent v3, Cosine Genie, Factory (Droids), Bolt.new, Lovable, v0 (Vercel), Tempo Labs, Mocha, Base44, Trickle |
| 04 | `04-orchestration-frameworks.md` | Multi-agent orchestration frameworks for code | CrewAI, AutoGen (Microsoft), LangGraph, MetaGPT, AgentScope, OpenAI Swarm/Agents SDK, Mastra, Pydantic AI, Atomic Agents, smolagents (HuggingFace) |
| 05 | `05-cli-agents.md` | **ALREADY EXISTS** — CLI agent tools (Aider, opencode, Claude Code, Codex CLI, Gemini CLI, Goose, Plandex, Amp, Crush, RA.Aid) | _Do not regenerate; master synthesis reads this file as-is._ |
| 06 | `06-spec-driven.md` | Spec-driven & planning-first frameworks | GitHub Spec Kit, Kiro (AWS), Backlog.md, SpecStory, Plandex's plan model (spec angle), Genie spec workflow, EARS-based tooling, Specflow-like AI specs, claude-task-master spec mode |
| 07 | `07-enterprise-platforms.md` | Enterprise AI coding platforms | GitHub Copilot Workspace + Coding Agent, Amazon Q Developer Agent, Tabnine Agents, Sourcegraph Cody Agentic / amp Enterprise, Augment Code, JetBrains AI Enterprise, Qodo (Codium), Codeium Enterprise, Pieces for Developers |
| 08 | `08-autonomous-opensource.md` | Open-source autonomous SWE agents | OpenHands (formerly OpenDevin), SWE-agent (Princeton), AutoCodeRover, GPT-Engineer, MentatBot, Aider's autonomous mode, Smol Developer (archeology), Devstral integration, Sweep AI, SWE-bench top performers |
| 09 | `09-memory-context.md` | Context engineering & memory systems for code agents | Mem0, Letta (formerly MemGPT), Zep, Cognee, Mastra memory, A-MEM (academic), MemoryOS, Continuum, LangMem, Graphiti, Memori, MemTree, MIRIX |
| 10 | `10-no-code-vibe.md` | Non-programmer / "vibe coding" platforms | Bolt.new, Lovable, v0.dev, Tempo Labs, Create.xyz, Hocoos AI Builder, Base44, Mocha, Replit Agent (non-dev angle), Trickle, Durable AI, Wix Studio AI, Framer AI, Webflow AI, Softr AI |

**Cross-cutting threat matrix (Report 00):** A meta-analyst agent produces `00-threat-matrix.md` — a cross-domain ranking of the 15 most dangerous individual competitors to APEX with: (a) why they threaten APEX's USP, (b) what defense APEX needs, (c) timeline to threat materialization, (d) a "what would APEX have to lose" scenario.

---

## 3. Required output template (every report MUST follow this)

```markdown
# Report NN — [Domain Name]
**Agent #N of 10 — APEX Competitive Intelligence Swarm**
**Scope:** [one-sentence scope]
**Date:** 2026-05-24

---

## 1. Scope & Methodology
- What I covered
- How many searches / fetches I performed
- What I could NOT verify (be honest)
- Notable data-quality caveats

## 2. Per-Competitor Deep Dives

### 2.1 [Competitor Name] — [tagline]

| Dimension | Detail |
|---|---|
| Lineage / scale | (founding year, stars/users/funding/last-release-date) |
| Core philosophy | |
| Architecture (agents/hooks/state/etc.) | |
| Multi-agent? | |
| Spec / planning layer | |
| Verification / critic loop | |
| Memory / persistent state | |
| Rollback / safety | |
| Cost posture | |
| Non-programmer accessibility | |
| Extensibility surface | |
| Enterprise readiness | |
| **What it does BETTER than APEX** | (be specific, brutal honesty) |
| **What APEX does better** | |
| **What APEX should steal / learn** | (actionable items) |
| **Threat level (Low / Med / High / Critical)** | + 1-line justification |

(repeat 2.2, 2.3 … for each competitor)

## 3. Cross-cutting patterns in this domain
3–5 emerging themes.

## 4. Where this domain collectively beats APEX
Honest list — no flinching.

## 5. Where APEX collectively beats this domain
Honest list — no boosterism.

## 6. Strategic recommendations for APEX
Concrete moves the APEX author should consider, in priority order.

## 7. Sources & citations
Numbered URL list (used by `[N]` callouts in body).
```

**Per-competitor depth target:** ≥ 350 words of substantive analysis per competitor (the table is structure; flesh it out underneath if needed). A 10-competitor report should land between **4,000 and 8,000 words**.

---

## 4. Failure modes the user explicitly wants caught

- **Skimming.** Don't list features; explain mechanisms. If you can't explain HOW a tool does X, you haven't researched it deeply enough.
- **Vendor parroting.** A tool's own marketing site is not a source. Cross-check with: GitHub repo, latest release notes, third-party review, HN/Reddit user threads, benchmark results.
- **2024 freezes.** Many tools shipped major rewrites in 2025–2026. A 2024 review is archaeology, not current intel.
- **Missing the obvious.** If a "killer competitor" exists in your domain that's not in the list above, ADD it. Don't constrain yourself to the seed list.
- **Pulling punches.** This report is for the APEX author. He needs to know where he's losing. Soften nothing.

---

## 5. Deliverable summary (return this to the orchestrator)

When done, return a **200-word summary** containing:
1. Top 3 most threatening competitors in your domain (named)
2. The single biggest gap APEX has vs. this domain
3. The single biggest steal-worthy idea from this domain
4. Your confidence level (High / Med / Low) and what would raise it
