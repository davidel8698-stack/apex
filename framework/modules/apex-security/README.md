# apex-security

**Status:** active
**Capabilities:** security, auth, multi-tenancy, encryption, tenant-isolation

Domain specialist for auth, multi-tenancy, encryption. Migrated from `framework/agents/specialist/security.md` into the module ecosystem in R5-001.

## Files

- `manifest.json` — module manifest (validates against `framework/modules/_schema/manifest.schema.json`).
- `agent.md` — agent prompt body, preserved byte-for-byte from the pre-migration location.

## Dispatch

Resolves to `Task("security-specialist", ...)` calls. The agent's frontmatter `name: security-specialist` is the dispatch contract; `sync-to-claude.sh` delivers `agent.md` to `~/.claude/agents/specialist/security-specialist.md` so Claude Code's runtime continues to find it.

## Future wiring

Per-project `THREAT_MODEL.md` bootstrap (Indirect Prompt Injection as default threat) is wired by R5-020 in Wave 4. The security stack language port (`apex-prompt-guard.cjs`, `apex-workflow-guard.cjs`, `security.cjs`; R6-014 added the `apex-` prefix to the two ported guards to match the spec literal naming) is R5-003 (Wave 5) and lives under `framework/hooks/` (the live tree remains flat); this module advertises the capability, the hooks are delivered separately by `sync-to-claude.sh`.
