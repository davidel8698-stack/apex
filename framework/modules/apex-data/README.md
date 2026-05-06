# apex-data

**Status:** active
**Capabilities:** data, database-design, migrations, query-optimization

Domain specialist for database design, migrations, data modeling, and query optimization. Migrated from `framework/agents/specialist/data.md` into the module ecosystem in R5-001.

## Files

- `manifest.json` — module manifest (validates against `framework/modules/_schema/manifest.schema.json`).
- `agent.md` — agent prompt body, preserved byte-for-byte from the pre-migration location.

## Dispatch

Resolves to `Task("data-specialist", ...)` calls. The agent's frontmatter `name: data-specialist` is the dispatch contract; `sync-to-claude.sh` delivers `agent.md` to `~/.claude/agents/specialist/data-specialist.md` so Claude Code's runtime continues to find it.
