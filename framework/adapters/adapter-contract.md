# APEX Adapter Contract — Multi-Platform Support

**Spec anchors:**
- "multi-agent framework ופלטפורמה לסוכני קוד (Claude Code, Cursor, OpenClaw, Codex, Copilot, Gemini, Windsurf, Antigravity דרך thin adapters)"
- "Multi-platform from day one."

**Purpose:** Capture the *minimum* contract every adapter must satisfy so that the same APEX framework files can be delivered to different host platforms (Claude Code, Cursor, Codex, Windsurf, Gemini, Antigravity, ...). Adapters are intentionally **thin** — translation layers at sync time, not per-platform code rewrites.

---

## Why thin adapters

The APEX framework is a tree of files (agents, commands, hooks, schemas, skills, settings). Each host platform has its own conventions for where these files live, how they are referenced, and what wiring formats they expect. A thin adapter:

- **Translates paths and filenames** — `~/.claude/agents/specialist/security-specialist.md` becomes `~/.cursor/agents/security-specialist.md` (or whatever the host expects).
- **Translates settings/wiring** — Claude Code's `.hooks.PreToolUse[]` schema becomes a different settings shape, or is ported to the host's hook protocol where one exists.
- **Documents what does not transfer** — e.g. Cursor's hook model differs; some hooks are deferred until the host gains the corresponding primitive.

What the adapter does **not** do:
- It does **not** rewrite the framework files. The framework is canonical; the adapter is a delivery shape.
- It does **not** invent platform-specific features.
- It does **not** maintain a parallel logic tree.

---

## The contract — fields every `adapter.json` must declare

Every `framework/adapters/<platform>/adapter.json` is a JSON document with the following top-level fields:

```json
{
  "schema_version": "1",
  "platform": "<short identifier, e.g. claude-code, cursor>",
  "display_name": "<human-friendly name>",
  "status": "canonical | active | stub",
  "paths": {
    "agents":   "<path under HOME or platform-config-root>",
    "commands": "<path>",
    "hooks":    "<path or null when host has no hook plane>",
    "settings": "<path>",
    "skills":   "<path or null>"
  },
  "settings_format": "claude-code-hooks-v1 | cursor-rules-v1 | none",
  "hook_protocol": {
    "supported": "full | partial | none",
    "notes": "<free text — what carries, what is dropped>"
  },
  "agent_dispatch": {
    "convention": "frontmatter-name | filename-only | other",
    "notes": "<free text>"
  },
  "deferred": ["<feature ids the adapter does not yet implement>"],
  "delivers": ["agents", "commands", "hooks", "skills", "settings"]
}
```

### Field semantics

- **`schema_version`** — bumped on incompatible contract change.
- **`platform`** — short kebab-case identifier; matches the directory name under `framework/adapters/`.
- **`status`** —
  - `canonical` — the reference platform (Claude Code).
  - `active` — feature-complete enough to deliver agents + commands. Hooks may be partial.
  - `stub` — manifest only; the corresponding sync script may be a dry-run scaffold.
- **`paths`** — where the adapter expects files to live on the host. Use `null` for surfaces the host does not expose.
- **`settings_format`** — discriminator for the platform's settings file shape.
- **`hook_protocol.supported`** — `full` if every Claude Code hook trigger maps to a host primitive; `partial` if some triggers do not exist on the host; `none` if the host has no hook plane.
- **`agent_dispatch.convention`** — how the host resolves an agent reference. Claude Code uses the `name:` frontmatter field; other hosts may use the filename or a registry.
- **`deferred`** — free-form list of feature ids that the adapter intentionally does not implement in this round. Documented for the future-work backlog.
- **`delivers`** — the surfaces this adapter actually copies during sync. A stub may deliver only `["agents"]` initially.

---

## The two adapters in this round

### `claude-code/adapter.json` (canonical)
- **status:** `canonical`
- **paths:** `~/.claude/{agents,commands/apex,hooks,settings.json,apex-skills}`
- **settings_format:** `claude-code-hooks-v1`
- **hook_protocol.supported:** `full`
- **agent_dispatch.convention:** `frontmatter-name`
- **delivers:** all five surfaces

### `cursor/adapter.json` (active stub)
- **status:** `active`
- **paths:** `~/.cursor/{agents,rules,settings.json}`; hooks `null`
- **settings_format:** `cursor-rules-v1`
- **hook_protocol.supported:** `none` — Cursor does not expose Claude Code's PreToolUse/PostToolUse plane, so the entire hook layer is `deferred`.
- **agent_dispatch.convention:** `frontmatter-name` (Cursor's `.cursor/rules/*.md` accepts a similar frontmatter shape).
- **delivers:** `["agents", "commands"]` for now; `hooks` and `skills` deferred.

The accompanying script is `framework/scripts/sync-to-cursor.sh`, modeled after `sync-to-claude.sh` but driven by the cursor adapter manifest.

---

## How `sync-to-claude.sh` and `sync-to-cursor.sh` use the contract

- `sync-to-claude.sh` is the canonical reference implementation. It does not strictly *read* the adapter manifest at runtime today (it hardcodes the canonical paths) — but the manifest is the documented contract for any reader asking "where do APEX files actually go on Claude Code?"
- `sync-to-cursor.sh` *does* read `framework/adapters/cursor/adapter.json` so that path changes flow through one source of truth.

Future work: collapse `sync-to-claude.sh` to also be manifest-driven. Out of scope for R5-025.

---

## Validation

`framework/tests/test-adapter-contracts.sh` validates that every `framework/adapters/<platform>/adapter.json` parses as JSON, declares the required fields, and uses an enum value the contract recognises. The two adapters in this round both pass.
