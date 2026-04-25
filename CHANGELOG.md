# Changelog

All notable changes to APEX will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
