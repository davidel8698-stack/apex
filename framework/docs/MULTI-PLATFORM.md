# APEX Multi-Platform Support

**Spec anchors:**
- "multi-agent framework ופלטפורמה לסוכני קוד (Claude Code, Cursor, OpenClaw, Codex, Copilot, Gemini, Windsurf, Antigravity דרך thin adapters)"
- "Multi-platform from day one."
- Brand position #7 — "Multi-Platform."

**Purpose:** Document how APEX targets multiple host platforms through a thin adapter layer, what is delivered today, and what is on the roadmap.

---

## What "multi-platform" means in APEX

The framework files (agents, commands, hooks, schemas, skills, settings) live in `framework/` as the canonical source of truth. Each host platform — Claude Code, Cursor, Codex, Windsurf, Gemini, Antigravity — has its own conventions for where these files live and how they are wired. APEX bridges this with **thin adapters**: per-platform manifests describing the host's path conventions and a per-platform sync script that copies the framework files into the host-shaped tree.

Adapters do not rewrite framework logic. The framework is single-sourced; adapters are translation layers at sync time.

---

## Today (R5)

### Canonical: Claude Code
- **Manifest:** `framework/adapters/claude-code/adapter.json`
- **Sync script:** `framework/scripts/sync-to-claude.sh`
- **Status:** canonical — feature-complete. Every APEX surface (agents, commands, hooks, settings, skills) is delivered.

### Active stub: Cursor
- **Manifest:** `framework/adapters/cursor/adapter.json`
- **Sync script:** `framework/scripts/sync-to-cursor.sh`
- **Status:** active. The adapter delivers agents and commands into the Cursor-shaped tree (`~/.cursor/agents/`, `~/.cursor/rules/`). Hooks are deferred until Cursor exposes a hook plane. `apex-skills` deferred.
- **Why Cursor first?** Cursor's `.cursor/rules/` model is the closest cousin to Claude Code's `.claude/commands/`, so the second adapter doubles as a sanity check on the contract: if one alternative platform can be supported by manifest changes alone, the abstraction is real.

### Adapter contract
- **Document:** `framework/adapters/adapter-contract.md`
- **Test:** `framework/tests/test-adapter-contracts.sh` validates every `adapters/<platform>/adapter.json` against the contract.

---

## Roadmap (post-R5)

The remaining platforms named in the spec are roadmap entries. Each will get a thin adapter manifest plus, where useful, a `sync-to-<platform>.sh` companion. The contract in `adapters/adapter-contract.md` is meant to absorb them without revision (`schema_version` bumps are reserved for incompatible changes).

| Platform     | Status | Notes |
|--------------|--------|-------|
| Claude Code  | canonical | Reference implementation. |
| Cursor       | active | Agents + commands deliver. Hooks deferred. |
| Codex        | planned | Manifest skeleton only. |
| Windsurf     | planned | Manifest skeleton only. |
| Gemini       | planned | Investigate hook-plane equivalent. |
| Antigravity  | planned | Investigate agent-dispatch convention. |
| Copilot      | planned | Likely commands-only adapter. |

Promotion criteria for `planned` → `active`:
1. The adapter manifest passes `test-adapter-contracts.sh`.
2. A `sync-to-<platform>.sh` script exists and runs in `--dry-run` without error.
3. At least one APEX surface (agents *or* commands) is verifiably delivered into the host-shaped tree.

---

## Why thin and why now

- **Thin** — heavy adapters become a parallel logic tree, which doubles the maintenance burden and silently drifts. The adapter contract caps the surface intentionally: paths, settings format, hook protocol availability, agent dispatch convention, deferred features.
- **Now** — the spec mandates "multi-platform from day one." Without at least one alternative adapter, the framework is just a Claude Code product with multi-platform aspiration. Shipping the Cursor stub turns the brand position into a verifiable artifact.

What is intentionally **not** delivered in R5:
- Per-platform feature parity for hooks. Hooks are the most platform-specific surface and the slowest to port.
- Auto-detect-and-sync. Each platform sync is invoked explicitly.
- Cross-platform settings.json merging. Currently every adapter writes a fresh settings file (where applicable); merge strategy is deferred.

---

## Verifying the contract

```bash
# Sanity: adapter manifests parse and conform.
bash framework/tests/test-adapter-contracts.sh

# Cursor stub dry-run (no files written).
bash framework/scripts/sync-to-cursor.sh --dry-run

# Canonical sync (writes to ~/.claude/).
bash framework/scripts/sync-to-claude.sh --dry-run
```

The first two are the R5 contract surface. The third is unchanged behavior — `sync-to-claude.sh` only gained a comment annotation in this round.
