# APEX

> **Context-engineered pipeline framework for coding agents** — multi-agent, stateful, falsifiable, scale-adaptive, and built first for non-programmers.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Status: Beta](https://img.shields.io/badge/status-beta-orange.svg)]()
[![Version](https://img.shields.io/badge/version-0.1.0-green.svg)]()
[![Spec: v6](https://img.shields.io/badge/spec-v6-purple.svg)](apex-spec.md)

---

## What is APEX?

APEX is a **multi-agent framework and platform for coding agents** (Claude Code, Cursor, Codex, Copilot, Gemini, Windsurf, and others through thin adapters) that turns them from session-by-session code assistants into an **autonomous, stateful, falsifiable, cost-aware, multi-platform, scope-honest, injection-hardened, dual-mode, scale-adaptive, and non-technical-first** engineering system.

It is the only framework in its category designed up front for **non-programmers** — not for developers — within a clearly declared scope (TypeScript / Python / Go with git and a test framework), operating as:

- a **collaborator** in product decisions (where the user is the expert), and
- a **replacement** in technical decisions (where the user is not).

The goal: hold a complete software project end-to-end without breaking itself, without burning budget, without requiring technical knowledge, without locking to a single platform, without overpromising, without letting a malicious user inject instructions through its files, without degrading delivery stability, and without being a closed tool — APEX is an **open platform that a community can extend**.

It is a **bridge over the knowledge and language barrier** for people who are not developers — **free forever in core** (enterprise services paid; core stays free — trust-first).

---

## The 9 failures APEX prevents

APEX is engineered around nine distinct failure modes that kill AI coding projects today, with **70–90% lower cost** and a UX a non-technical user can succeed with in their first session and first hour.

| # | Failure | How APEX handles it |
|---|---------|--------------------|
| 1 | **Pipeline failure** — pipeline breaks, hours lost | Circuit breakers, auto-commit to hidden git tree with one-click rollback, pre-task snapshots, recovery menu, `/apex:forensics`, `/apex:help` natural-language navigator |
| 2 | **Forgetting** — important context disappears | Three-tier memory architecture, Memory Synthesis dream-cycle agent, `apex/todos|threads|seeds|backlog/`, `apex-workflows/` library of 30+ pre-built recipes |
| 3 | **Context loss** — agent doesn't know where it is | `STATE.json` + `event-log.jsonl` control plane (jq-queryable), glass cockpit, U-shape context ordering, Aider-style repo map, scale-adaptive classifier |
| 4 | **Drift** — decided X, agent does Y | `SPEC_VERSION` hash, spec-to-verification ledger, phase-gating doctrine, scope-reduction detector, 6-pillar Design Contract |
| 5 | **Hallucination & fake reporting** | Phantom-check, AST-KB hallucination gate, `verified_criteria[]` / `unverified_criteria[]`, end-to-end smoke tests, dedicated `auditor` agent that never reads implementation code |
| 6 | **Mutation** — destructive changes | Destructive-guard hook, pre-task snapshot, mutation-gate, one-file-one-owner with worktree isolation, skipped-test regression detection |
| 7 | **Quality errors** — works but not good | Cross-model critic, fixed adversarial persona, mutation testing, property-based testing, `/apex:peer-review`, `/apex:roundtable` |
| 8 | **Systemic blindness** — fixes 1 caller, breaks 12 | TDAD + Aider-style repo map, cross-phase audit, differential semantic testing |
| 9 | **Security gaps** — Veracode: 45% fail | Security-specialist, negative authorization tests, ML entropy secret scanning, `THREAT_MODEL.md`, defense-in-depth security layer |

See [apex-spec.md](apex-spec.md) for the full specification.

---

## Quick start

APEX consists of slash commands, agents, and hooks that live under `~/.claude/`. To install:

```bash
# Clone the repo
git clone https://github.com/davidel8698-stack/apex.git
cd apex

# Copy framework files into your Claude Code config
mkdir -p ~/.claude
cp -r framework/commands ~/.claude/
cp -r framework/agents ~/.claude/
cp -r framework/hooks ~/.claude/
cp -r framework/apex-skills ~/.claude/
cp -r framework/apex-workflows ~/.claude/
cp framework/settings.json ~/.claude/

# Make hooks executable
chmod +x ~/.claude/hooks/*.sh
```

Then in Claude Code, in a new project directory, run:

```
/apex:start
```

APEX will guide you through onboarding, scale classification, and your first phase.

---

## Project structure

```
apex/
├── framework/                  Core framework — the deliverable
│   ├── commands/apex/          44 slash commands
│   ├── agents/                 8 core + 4 specialist agents
│   ├── hooks/                  32 shell scripts (security, state, workflow, Auto-Continuity v7.1)
│   ├── apex-skills/            10 stack-specific skill templates
│   ├── apex-workflows/         30+ pre-built workflow recipes
│   ├── schemas/                JSON schemas (STATE, RESULT, PLAN_META…)
│   ├── scripts/                Utility scripts incl. apex-watchdog.ps1 (Windows external watchdog)
│   ├── settings.json           Hook configuration
│   ├── tests/                  Framework self-tests
│   └── docs/                   Internal documentation
├── apex-spec.md                Full specification (the source of truth)
├── APEX Research Project/      Research briefs informing the design
└── scripts/                    Utility scripts
```

### Auto-Continuity (v7.1) — runs forever without you watching

For autonomous long-running projects (3+ days), APEX includes a four-layer
Auto-Continuity system that survives Bun OOM, idle sessions, and crashes —
without manual intervention. Three layers run inside Claude Code automatically;
a fourth (optional, Windows-only) is an external PowerShell watchdog that
respawns Claude Code if the runtime dies completely.

To install the optional external watchdog (Windows):

```powershell
cd path\to\APEX\framework\scripts
pwsh -File install-watchdog.ps1 -Mode install -ProjectPath "C:\path\to\my-project"
```

See [`framework/scripts/README-watchdog.md`](framework/scripts/README-watchdog.md)
for full details. APEX's in-process layers (memory-watchdog, turn-checkpoint,
session-auto-resume) work without it.

---

## Core commands

| Command | Purpose |
|---------|---------|
| `/apex:start` | Start a new APEX project |
| `/apex:onboard` | Onboard an existing project to APEX |
| `/apex:build` | Build pipeline for new features |
| `/apex:refine` | Refinement pipeline for existing code |
| `/apex:next` | Advance to the next logical step (orchestration heart) |
| `/apex:status` | Current status with token tracking and context health |
| `/apex:forensics` | Diagnose failures (timeline reconstruction) |
| `/apex:rollback` | One-click rollback to a previous checkpoint |
| `/apex:help` | Natural-language navigator — "I'm stuck", "How do I undo this?" |
| `/apex:health-check` | Validate all agent prompts using real git operations |
| `/apex:list` | List all `/apex:` commands grouped by category |

Run `/apex:list` inside a Claude Code session for the full catalog.

---

## How it works

APEX is **hub-and-spoke** with a manager that has final authority:

```
                         ┌─────────────┐
                         │   /apex:next │
                         └──────┬──────┘
                                │
              ┌─────────────────┼─────────────────┐
              ▼                 ▼                 ▼
       ┌────────────┐    ┌────────────┐    ┌────────────┐
       │  architect │    │  executor  │    │   critic   │
       └────────────┘    └────────────┘    └────────────┘
              │                 │                 │
              ▼                 ▼                 ▼
       ┌────────────┐    ┌────────────┐    ┌────────────┐
       │  planner   │    │  verifier  │    │  auditor   │
       └────────────┘    └────────────┘    └────────────┘
                                │
                                ▼
                         ┌────────────┐
                         │  29 hooks  │  ← circuit breakers, snapshots,
                         └────────────┘     security gates, state mgmt
```

- **Read-parallel, write-serial**: agents can read in parallel; only one writer at a time per file.
- **Vertical slice enforcement**: each phase ships an end-to-end working slice.
- **Blind-first debate**: critics never see executor reasoning before forming their own opinion.
- **Roundtable mode**: for architectural decisions with many faces, multiple specialists present perspectives — architect decides.

---

## Philosophy

- **Dual-mode**: collaborator in product decisions, replacement in technical ones.
- **Scale-adaptive**: classifies project scale automatically and adapts (bug fix → enterprise system).
- **Non-technical-first**: a non-developer can succeed in their first hour.
- **Honestly heavy**: APEX never reports work it didn't do; it reports `verified_criteria[]` separately from `unverified_criteria[]`.
- **Injection-hardened**: planning artifacts are treated as adversarial input.
- **Falsifiable**: every claim has a test; every spec has a verification ledger.
- **Free forever in core**: the engine stays free; only enterprise services are paid.

---

## Contributing

APEX is a community-extensible platform. Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, branch conventions, commit style, and PR checklist.

## Security

If you discover a security vulnerability, please follow the responsible disclosure process in [.github/SECURITY.md](.github/SECURITY.md). **Do not open a public issue.**

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

[MIT](LICENSE) © 2026 David Almoalem
