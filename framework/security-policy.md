# APEX Security Policy — Defense-in-Depth Layer Map

**Purpose:** This document is the authoritative map between the six security
mechanisms named in `apex-spec.md` (Failure 9 — Defense-in-Depth Security Layer)
and their concrete `.sh` implementations in the APEX framework.

If you are adding, modifying, or auditing a security mechanism, start here.

**Spec anchor:** `apex-spec.md`, Failure 9:
> Defense-in-Depth Security Layer: `apex-prompt-guard.js`, Path Traversal
> Prevention, `apex-workflow-guard.js`, CI scanner, `security.cjs` module.

---

## Mechanism → Implementation Map

| # | Spec mechanism | Concrete file | Trigger | Status |
|---|---|---|---|---|
| 1 | `apex-prompt-guard.js` | `framework/hooks/prompt-guard.sh` | PreToolUse (Write\|Edit\|Agent) | Active — auto-wired in settings.json |
| 2 | Path Traversal Prevention | `framework/hooks/path-guard.sh` | PreToolUse (Write\|Edit) | Active — auto-wired in settings.json |
| 3 | `apex-workflow-guard.js` | `framework/hooks/workflow-guard.sh` | PreToolUse (Read) + explicit invocation from `/apex:workflow` | Active — auto-wired post-R-006 |
| 4 | CI scanner | `framework/hooks/ci-scan.sh` | Manual (CI pipeline invocation) | Exists — not auto-wired by design |
| 5 | `security.cjs` module | `framework/hooks/_security-common.sh` (+ the 5 guard hooks above, distributed) | Library — sourced, never invoked directly | Active |
| 6 | Destructive command blocking | `framework/hooks/destructive-guard.sh` | PreToolUse (Bash) | Active — auto-wired in settings.json (v7 hardened with chained-command splitting) |

---

## Why distributed, not monolithic

The APEX spec names JavaScript artifacts (`.js`, `.cjs`) but APEX ships with
**zero JavaScript runtime dependencies** — all hooks are shell scripts. The
functional equivalent of the `security.cjs` module is split across two layers:

1. **Shared utility library** — `_security-common.sh` provides three primitives
   (`_sec_normalize`, `_sec_pattern_match`, `_sec_block`) that every guard hook
   sources. This is the single source of truth for input normalization,
   zero-width-character stripping, and block-response formatting.
2. **Individual guards** — each guard enforces one concern (prompts, paths,
   workflow recipes, bash destructives, auditor quarantine). They source the
   shared library, declare their patterns locally, and exit 2 on block.

**Advantages of this architecture:**
- Each guard is independently testable in isolation.
- Pattern-set changes are localized — a prompt-injection regex update touches
  only `prompt-guard.sh`, not a shared monolith.
- Shell-only runtime means zero dependency surface beyond `bash`, `grep`, `sed`.
- `_security-common.sh` prevents policy drift between guards (normalization is
  identical everywhere).

A monolithic `security.sh` would violate the single-responsibility principle
and make PreToolUse matchers harder to scope (every Read/Write/Bash would hit
one fat handler).

---

## How to add a new security mechanism

1. Create `framework/hooks/<name>-guard.sh` — source `_security-common.sh` at
   the top and declare patterns locally.
2. Choose the trigger:
   - Auto-wired: add a `PreToolUse` or `PostToolUse` entry in
     `framework/settings.json` scoped to the narrowest matcher possible.
     Include a self-filter early in the script (see `workflow-guard.sh` for the
     pattern) so hot paths bypass file I/O.
   - Manual/CI: leave out of `settings.json`; invoke from the relevant command
     `.md` file or from CI.
3. Add a row to the **Mechanism → Implementation Map** table above.
4. Add a row to `framework/HOOK-CLASSIFICATION.md` with the correct category.
5. Add a test case in `framework/tests/test-hooks-security.sh`.

---

## Policy notes

- Individual guard internals (pattern lists, block messages) are the source of
  truth for enforcement. This document does not duplicate patterns — it maps
  spec mechanisms to files.
- When the spec says `security.cjs`, read it as "the consolidated policy
  module" — implemented here as `_security-common.sh` plus the distributed
  guards sourcing it.
- `ci-scan.sh` is intentionally not auto-wired: it is a supply-chain scanner
  meant for CI pipelines, not per-tool-invocation enforcement.

---

## References

- `apex-spec.md` — Failure 9 (Defense-in-Depth Security Layer)
- `framework/HOOK-CLASSIFICATION.md` — all 28 hooks classified by trigger type
- `framework/settings.json` — auto-wired hook entries
- `framework/hooks/_security-common.sh` — shared utility library
