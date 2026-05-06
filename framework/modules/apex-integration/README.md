# apex-integration

**Status:** active
**Capabilities:** integration, oauth, webhooks, external-apis, token-management

Domain specialist for OAuth, webhooks, external APIs, token management. Migrated from `framework/agents/specialist/integration.md` into the module ecosystem in R5-001.

## Files

- `manifest.json` — module manifest (validates against `framework/modules/_schema/manifest.schema.json`).
- `agent.md` — agent prompt body, preserved byte-for-byte from the pre-migration location.

## Dispatch

Resolves to `Task("integration-specialist", ...)` calls. The agent's frontmatter `name: integration-specialist` is the dispatch contract; `sync-to-claude.sh` delivers `agent.md` to `~/.claude/agents/specialist/integration-specialist.md` so Claude Code's runtime continues to find it.
