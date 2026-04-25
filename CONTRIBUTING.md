# Contributing to APEX

Thank you for considering a contribution! APEX is an open platform designed to be community-extensible. This document explains how to get set up, our conventions, and what we look for in pull requests.

---

## Getting started

1. **Fork** the repo on GitHub.
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/apex.git
   cd apex
   ```
3. **Install** the framework into a Claude Code config (see [README.md § Quick start](README.md#quick-start)).
4. **Run the health check** to confirm a clean baseline:
   ```
   /apex:health-check
   ```

---

## Branch naming

Use one of these prefixes:

- `feature/<short-description>` — new commands, agents, hooks, or workflows
- `fix/<short-description>` — bug fixes
- `docs/<short-description>` — documentation only
- `refactor/<short-description>` — internal restructuring without behavior change
- `test/<short-description>` — adding or improving tests

Example: `feature/add-supabase-skill`, `fix/destructive-guard-edge-case`.

---

## Commit style — Conventional Commits

We use [Conventional Commits](https://www.conventionalcommits.org/). Format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `perf`, `style`, `build`, `ci`.

**Scope** (optional): `apex`, `executor`, `critic`, `hooks`, `skills`, `workflows`, etc.

**Examples**:
```
feat(apex): add /apex:roundtable command for architecture debates
fix(hooks): destructive-guard now catches `rm -rf` with --no-preserve-root
docs(spec): clarify scale-adaptive classifier defaults
```

The body should explain **why**, not what (the diff shows what).

---

## Pull request checklist

Before opening a PR, please confirm:

- [ ] The change matches the spec in [apex-spec.md](apex-spec.md), or you updated the spec in the same PR.
- [ ] You ran `/apex:health-check` and it passed.
- [ ] If you added/changed a hook: `shellcheck` passes on the file.
- [ ] If you added/changed a JSON schema: it is valid JSON and matches existing patterns.
- [ ] If you added a new command: it is registered in `/apex:list` output, and has a matching entry in `framework/commands/apex/`.
- [ ] If you added a new agent: it follows the agent contract (typed RESULT.json, no implementation-code reads if it's an auditor variant, etc.).
- [ ] Commit messages follow Conventional Commits.
- [ ] No personal paths, secrets, or local state added to tracked files (see `.gitignore`).
- [ ] No `.apex/` runtime state committed.

---

## Adding a new command, agent, hook, or skill

| Component | Location | Format | Notes |
|-----------|----------|--------|-------|
| **Command** | `framework/commands/apex/<name>.md` | Markdown | Must declare its inputs, outputs, and verify level |
| **Agent** | `framework/agents/<name>.md` | Markdown | Must declare allowed tools and output schema |
| **Specialist agent** | `framework/agents/specialist/<name>.md` | Markdown | Same as agent + domain note |
| **Hook** | `framework/hooks/<name>.sh` | Bash | Must be idempotent; check `framework/settings.json` for matcher |
| **Skill** | `framework/apex-skills/<stack>.md` | Markdown | Stack-specific patterns (e.g. nextjs, postgres) |
| **Workflow** | `framework/apex-workflows/<name>.md` | Markdown | Pre-conditions, steps, post-conditions |

The build order (declared in [CLAUDE.md](CLAUDE.md)) is: **settings.json → hooks → agents → commands → skills**. Respect this order when proposing changes.

---

## Reporting bugs

Please use the bug report template under `.github/ISSUE_TEMPLATE/bug_report.md`. Include:

- Your platform (Claude Code version, OS, shell).
- The command / sequence that produced the bug.
- The expected vs. actual behavior.
- Relevant snippets from `.apex/event-log.jsonl` (redact anything sensitive).

## Proposing features

Please open a discussion **before** opening a PR for a new feature, so the design can be aligned with the spec. Use the feature request template under `.github/ISSUE_TEMPLATE/feature_request.md`.

## Code of conduct

Be kind. Assume good faith. Disagreements are settled by the spec; if the spec is wrong, propose a spec change.

---

Thank you for helping APEX grow.
