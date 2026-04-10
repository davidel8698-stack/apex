# APEX DEV-FLOW

The authoritative source of truth for all APEX framework files is the
`framework/` tree in this repository. The live installation at
`~/.claude/` is treated as a deploy target — never edit it directly.

## The loop

```
edit framework/<file>
       |
       v
bash framework/scripts/sync-to-claude.sh --dry-run   (preview)
       |
       v
bash framework/scripts/sync-to-claude.sh             (deploy)
       |
       v
test in a Claude Code session
       |
       v
git add framework/<file> && git commit               (if tests pass)
```

## Why not edit `~/.claude/` directly?

1. **OneDrive + symlinks are unreliable.** This repo lives on OneDrive,
   and symlinking from `~/.claude/` into it causes sync conflicts and
   occasional file corruption. The sync script is the safe alternative.
2. **Version control belongs to `framework/`.** Edits in `~/.claude/`
   have no history and can be lost on the next deploy. Always edit the
   source of truth.
3. **The dev loop is atomic.** Edit -> sync -> test -> commit gives you
   a clean rollback point every time. Editing in place muddies the
   history.

## Safety guarantees of `sync-to-claude.sh`

- **Additive only.** The script never deletes files from `~/.claude/`.
- **Scoped to APEX.** Only files that exist under `framework/` are
  touched. Non-APEX files (GSD agents, user hooks, `settings.json`) are
  left alone.
- **Dry-run first.** The `--dry-run` flag shows every file that would be
  copied without making any changes. Run it before every live sync.

## What the script copies

| Source                                 | Destination                       |
|----------------------------------------|-----------------------------------|
| `framework/agents/`                    | `~/.claude/agents/`               |
| `framework/commands/apex/`             | `~/.claude/commands/apex/`        |
| `framework/hooks/`                     | `~/.claude/hooks/`                |
| `framework/apex-skills/`               | `~/.claude/apex-skills/`          |
| `framework/schemas/`                   | `~/.claude/schemas/`              |
| `framework/apex-branding.md`           | `~/.claude/apex-branding.md`      |
| `framework/apex-design-notes.md`       | `~/.claude/apex-design-notes.md`  |
| `framework/apex-learnings.md`          | `~/.claude/apex-learnings.md`     |
| `framework/apex-model-routing.json`    | `~/.claude/apex-model-routing.json` |

## What the script does NOT touch

- `~/.claude/settings.json` and `~/.claude/settings.local.json` — user-owned
- `~/.claude/agents/` files that don't exist in `framework/agents/` — e.g. GSD agents, custom subagents
- `~/.claude/commands/` at the top level (only `commands/apex/` is synced)
- Anything outside the paths listed above
- `framework/scripts/` itself (the script does not deploy itself)

## Verifying a deploy

After a live sync, spot-check with:

```bash
diff -r framework/agents/ ~/.claude/agents/ | head
diff -r framework/commands/apex/ ~/.claude/commands/apex/ | head
```

APEX files should show zero differences. Differences in non-APEX files
(e.g. GSD subagents) are expected and fine — the script never touches
them.

## Hook shell conventions

All hooks use explicit error handling instead of `set -e`:

- **`set -u`** — mandatory in all hooks. Catches undefined variable bugs.
- **`set -e`** — deliberately NOT used. `set -e` has known footguns
  (breaks `if cmd; then` constructs, interacts badly with `$?` capture).
  All hooks use explicit `|| exit 2` or `$?` checks instead.
- **`set -o pipefail`** — used in hooks with pipelines
  (`cross-phase-audit.sh`, `generate-task-map.sh`). Add it to any new
  hook that uses pipes.

Exit code convention (3-tier, all hooks):
- `0` = success
- `1` = advisory (non-blocking warning)
- `2` = blocking (halt execution)

## If a sync looks wrong

Stop. Do not re-run. Open a Claude Code session with the framework/
branch checked out and investigate. `~/.claude/` is not version
controlled, so there is no built-in rollback — but because the script is
additive-only, the worst case is that some `~/.claude/` files are newer
than the repo. To recover, fix the source in `framework/`, commit, and
re-run the sync.
