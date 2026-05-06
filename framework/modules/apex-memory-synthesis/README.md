# apex-memory-synthesis

**Status:** active
**Capabilities:** memory-synthesis, dream-cycle, session-consolidation

Dream-cycle agent that consolidates the four memory primitives (`todos/`, `threads/`, `seeds/`, `backlog/`) across sessions. Migrated from `framework/agents/specialist/memory-synthesis.md` into the module ecosystem in R5-001.

## Files

- `manifest.json` — module manifest (validates against `framework/modules/_schema/manifest.schema.json`).
- `agent.md` — agent prompt body, preserved byte-for-byte from the pre-migration location.

## Dispatch

Resolves to `Task("memory-synthesis", ...)` calls. The agent's frontmatter `name: memory-synthesis` is the dispatch contract; `sync-to-claude.sh` delivers `agent.md` to `~/.claude/agents/specialist/memory-synthesis.md` so Claude Code's runtime continues to find it.

Dream-cycle wiring (START/COMPLETE event-log emission) lands in R5-023 (Wave 3).
