# apex-test-architect

**Status:** active
**Capabilities:** test-architecture, test-pyramid, mutation-testing, veto-power, wave-0-mapping

Pre-execution test strategy planning with veto power. Runs in per-task mode (BEFORE executor on C/D tasks) and per-phase mode (Wave 0 infrastructure mapping). Migrated from `framework/agents/test-architect.md` into the module ecosystem in R5-001 — the spec lists `apex-test-architect` as a module, so it moves out of the core-engine agents root.

## Files

- `manifest.json` — module manifest (validates against `framework/modules/_schema/manifest.schema.json`).
- `agent.md` — agent prompt body, preserved byte-for-byte from the pre-migration location, including veto-power language.

## Dispatch

Resolves to `Task("test-architect", ...)` calls (e.g., from `framework/commands/apex/next.md`). The agent's frontmatter `name: test-architect` is the dispatch contract; `sync-to-claude.sh` delivers `agent.md` to `~/.claude/agents/specialist/test-architect.md` so Claude Code's runtime continues to find it.

## Veto-branch wiring

Living Evidence Counter veto-branch directive (apex-learnings.md emit on veto) is added by R5-019 in Wave 6.
