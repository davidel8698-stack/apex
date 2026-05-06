# apex-builder

**Status:** stub

Meta-framework module for creating new APEX modules (BMAD's Builder analog per spec). Scaffolded in R5-001 as a manifest + README placeholder.

## Scope

The Builder module owns the contract for `/apex:new-agent` and any future scaffolding tooling. R5-021 (Wave 6) extends `framework/commands/apex/new-agent.md` with full manifest-validating scaffolding and an `agent-lint.sh` hook; R5-001 only adjusts `new-agent.md` to write a manifest under `framework/modules/<name>/` (the path correction).

## Future work

- Promote to `active` once the new-agent flow is fully wired (R5-021).
- Optionally house an `agent.md` for a "module-builder" specialist that audits manifests and reviews new-module proposals.
