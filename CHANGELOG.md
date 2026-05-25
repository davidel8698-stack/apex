# Changelog

All notable changes to APEX will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added (2026-05-25 — spec-restructure)

- **`apex-strategy.md`** (new sibling to `apex-spec.md`) — strategic intelligence snapshot from two parallel research swarms run 2026-05-24: 10-agent competitive landscape (60+ competitors) + 5-agent deep-research synthesis (~94 unique URLs across Anthropic / Manus / Karpathy / Microsoft MDASH). Contains: top-15 threat ranking, 5 existential risks, 6 honest moats, 30-item steal-worthy master table, 30/90/365-day playbook, surprises + caveats + methodology. Re-runnable quarterly. Points to raw evidence in `competitive-analysis/`.

- **`apex-spec.md` extended** with 27 new doctrinal requirements **IMP-DR-001..IMP-DR-027** (Strategy C — Hybrid Documented-Inline, chosen after blast-radius analysis):
  - **F1 Pipeline:** IMP-DR-006 (KV-cache hygiene + prefix-stability invariant), IMP-DR-011 (per-stage stop criteria), IMP-DR-013 (recitation cost measurement), IMP-DR-018 (effort levels replace budget_tokens)
  - **F2 Forgetting:** IMP-DR-008 (compaction primitive at phase boundaries), IMP-DR-012 (restorable-compression audit), IMP-DR-020 (per-stage domain plugins), IMP-DR-024 (per-agent persistent memory directories)
  - **F3 Context loss:** IMP-DR-005 (Anthropic canonical 5-section state-handoff template)
  - **F4 Drift:** IMP-DR-002 (tradeoff-disclosure preamble + rigor-tier philosophy), IMP-DR-004 (diff-bloat alarm in critic), IMP-DR-010 (lightweight step→verify plan for fast/quick), IMP-DR-022 (quarterly REMOVAL pass)
  - **F5 Hallucination:** IMP-DR-003 (assumption-block floor), IMP-DR-009 (failure-preservation invariant + FAILURES.md), IMP-DR-017 (multi-oracle verification stacking)
  - **F7 Quality:** IMP-DR-001 (anti-overengineering armor — highest ROI single change), IMP-DR-014 (posterior-credibility Bayesian framing), IMP-DR-015 (cross-provider second opinion), IMP-DR-016 (sub-agent capability amplification), IMP-DR-019 (tool description optimization), IMP-DR-025 (APEX-on-APEX eval benchmark), IMP-DR-027 (Multi-Agent Ceremony Position table)
  - **F9 Security:** IMP-DR-021 (SECURITY.md threat model — where APEX leads MDASH/Big Sleep/Anthropic Research/Team Atlanta on agent-loop guardrails)
  - **Working Principles:** "Research-Validated Consensus (11 claims)" sub-section with attribution; IMP-DR-007 (6 verbatim Anthropic prompt blocks); IMP-DR-023 (APEX → Anthropic vocabulary glossary)
  - **Claim Measurement section:** IMP-DR-026 (methodology disclosure rule)
  - **Strategic Addenda pointer:** cross-link to `apex-strategy.md`

- **TOC + AGENT-NAV markers** at top of `apex-spec.md` for easier section discovery without breaking SSoT (Strategy C: organized monolithic, not modular).

### Notes

- **Backward compatibility:** all 84 original IMP-NNN IDs (001..082 + V8-CB2 + DOC-03) preserved at logical locations. 12 brand positions, ~50 Working Principles, "Self-Healing Loop" section heading, 4 memory primitives, NC-17-05 PinScope normative claim, 3 CLAIMS-MEASUREMENT cross-ref phrases — all preserved inline (verified by 13-grep validation gate).
- **No ecosystem changes:** PinScope FROZEN SPEC untouched, 4 specialist agents untouched, sync-to-claude.sh untouched, markdown links continue to work.
- **Sync tests pass post-restructure:** `test-sync-doc-coverage.sh` 7/7, `test-sync-coverage.sh` 50/50.
- **Backup:** `.apex/checkpoints/spec-restructure-2026-05-25/pre-restructure.bak` (the original 682-line spec).
- **Strategy rationale:** documented in `.claude/plans/wobbly-jumping-harbor.md`. Strategy A (append-only) chosen over Strategy B (full modular) because B would have required editing PinScope FROZEN SPEC (NC-17-05) — out of scope for an APEX-only restructure. Strategy C adds navigation aids on top of Strategy A.
- **Landing commit:** apex-spec.md changes landed in `240c340` (which bundled them with PinScope ps-heal R22 terminal closure via auto-staging by background `/ps-heal` automation running in parallel with this session). apex-strategy.md landed cleanly in `f1ec232`.

## [0.1.0] - 2026-04-25

### Added

- **Initial public release** of the APEX v6 framework.
- **44 slash commands** covering project lifecycle (`/apex:start`, `/apex:build`, `/apex:refine`, `/apex:next`, `/apex:forensics`, `/apex:rollback`, `/apex:help`, and more).
- **12 agents**: 8 core (architect, planner, executor, critic, verifier, auditor, test-architect, memory-synthesis) + 4 specialists (data, frontend, integration, security).
- **29 hooks** for circuit breakers, state management, security gates, destructive-action prevention, schema validation, and workflow control.
- **10 stack-specific skill templates** (Next.js, Postgres, Prisma, React, Stripe, etc.).
- **30+ pre-built workflow recipes** for common engineering tasks (add-authentication, migrate-to-postgres, prepare-for-production, accessibility-audit).
- **Three-tier memory architecture** with Memory Synthesis dream-cycle agent.
- **Scale-adaptive classifier** that adapts framework behavior to project scale.
- **Dual-mode operation**: collaborator in product decisions, replacement in technical decisions.
- **Defense-in-depth security layer** with prompt-guard, path-traversal prevention, workflow-guard, and a CI scanner.
- **Full specification** in `apex-spec.md`.

### Security

- All planning artifacts are treated as adversarial input (Indirect Prompt Injection threat model).
- Negative authorization tests are blocking.
- ML entropy secret scanning is enabled.

[Unreleased]: https://github.com/davidel8698-stack/apex/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/davidel8698-stack/apex/releases/tag/v0.1.0
