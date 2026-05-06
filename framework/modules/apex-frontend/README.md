# apex-frontend

**Status:** active
**Capabilities:** frontend, ui-ux, component-architecture, accessibility, responsive-design

Domain specialist for UI/UX implementation, component architecture, responsive design, accessibility. Migrated from `framework/agents/specialist/frontend.md` into the module ecosystem in R5-001.

## Files

- `manifest.json` — module manifest (validates against `framework/modules/_schema/manifest.schema.json`).
- `agent.md` — agent prompt body, preserved byte-for-byte from the pre-migration location.

## Dispatch

Resolves to `Task("frontend-specialist", ...)` calls. The agent's frontmatter `name: frontend-specialist` is the dispatch contract; `sync-to-claude.sh` delivers `agent.md` to `~/.claude/agents/specialist/frontend-specialist.md` so Claude Code's runtime continues to find it.
