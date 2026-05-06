# apex-core

**Status:** core

The `apex-core` module is a *meta-entry* in the registry. It does NOT contain agent files of its own. Core lives at `framework/agents/` and `framework/hooks/`; this manifest exists so the eight-module spec listing has a registry-discoverable entry for "core".

## What counts as core

**Core-engine agents (NOT migrated into modules):**
- `framework/agents/architect.md`
- `framework/agents/auditor.md`
- `framework/agents/critic.md`
- `framework/agents/executor.md`
- `framework/agents/planner.md`
- `framework/agents/verifier.md`

**Self-heal pipeline workers (NOT migrated into modules — preservation contract):**
- `framework/agents/specialist/framework-auditor.md`
- `framework/agents/specialist/remediation-planner.md`
- `framework/agents/specialist/batch-scheduler.md`
- `framework/agents/specialist/wave-executor.md`
- `framework/agents/specialist/round-checker.md`

**Core hooks and scripts:** every file under `framework/hooks/` and `framework/scripts/` (the live tree stays flat — modules contribute hooks, they do not host them).

## What is NOT core

The seven domain modules (`apex-data`, `apex-frontend`, `apex-integration`, `apex-memory-synthesis`, `apex-security`, `apex-test-architect`, `apex-fintech`, `apex-healthcare`, `apex-builder`) live under `framework/modules/<name>/` and have independent manifests. Each can have an independent owner and version even while the core repo is still a monorepo (manifest-only commitment for R5; per-module submodules deferred).
