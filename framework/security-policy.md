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
| 1 | `apex-prompt-guard.js` | `framework/hooks/prompt-guard.cjs` (canonical, post-R5-003) + `framework/hooks/prompt-guard.sh` (shim, falls back to native Bash when node absent) | PreToolUse (Write\|Edit\|Agent) | Active — runtime-aware auto-wired in settings.json |
| 2 | Path Traversal Prevention | `framework/hooks/path-guard.sh` | PreToolUse (Write\|Edit) | Active — auto-wired in settings.json |
| 3 | `apex-workflow-guard.js` | `framework/hooks/workflow-guard.cjs` (canonical, post-R5-003) + `framework/hooks/workflow-guard.sh` (shim, falls back to native Bash when node absent) | PreToolUse (Read) + explicit invocation from `/apex:workflow` | Active — runtime-aware auto-wired post-R-006 |
| 4 | CI scanner | `framework/hooks/ci-scan.sh` | Manual (CI pipeline invocation) | Exists — not auto-wired by design |
| 5 | `security.cjs` module | `framework/hooks/security.cjs` (literal, post-R5-003) + `framework/hooks/_security-common.sh` (Bash counterpart sourced by shim guards) | Library — required/sourced, never invoked directly | Active |
| 6 | Destructive command blocking | `framework/hooks/destructive-guard.sh` | PreToolUse (Bash) | Active — auto-wired in settings.json (v7 hardened with chained-command splitting) |

---

## Why distributed, not monolithic

The APEX spec names JavaScript artifacts (`.js`, `.cjs`) and as of R5-003
the three spec-named files exist literally: `prompt-guard.cjs`,
`workflow-guard.cjs`, `security.cjs`. Detection patterns load from a shared
fixture (`framework/test-fixtures/security-patterns.json`) so the .cjs and
.sh branches cannot drift. APEX still ships with **zero npm dependencies** —
the .cjs files require only the Node standard library; on hosts without
`node`, the `.sh` shims at the same names fall back to native Bash detection
that is byte-equivalent to the canonical Node engine.

The functional equivalent of the `security.cjs` module is therefore
deliverable in two complementary layers:

1. **Canonical Node module** — `security.cjs` provides `normalize`,
   `hasZeroWidthChars`, `matchPromptInjection`, `matchWorkflowInjection`,
   `emitBlock`, `readStdinSync`, `parseHookStdin`. Required by the two
   ported guards. Loads patterns from the canonical JSON fixture.
2. **Shared Bash library** — `_security-common.sh` provides the same three
   primitives (`_sec_normalize`, `_sec_pattern_match`, `_sec_block`) that
   the .sh shims use when node is unavailable. This is the Bash counterpart
   of `security.cjs`; both layers carry the same semantics.

Each guard enforces one concern (prompts, paths, workflow recipes, bash
destructives, auditor quarantine). The two ported guards (prompt, workflow)
ship as `.cjs`+`.sh` pairs; the others remain pure `.sh` for now.

**Advantages of this architecture:**
- Each guard is independently testable in isolation.
- Pattern-set changes happen in one place (the JSON fixture); both runtimes
  pick the change up automatically.
- Hosts with `node` get the canonical Node engine for the two named guards;
  Bash-only hosts continue to work via the shim fallback. APEX ships
  zero npm-managed dependencies in either case.
- `_security-common.sh` and `security.cjs` prevent policy drift between
  guards within their respective runtimes (normalization is identical
  everywhere).

For the runtime-dispatch contract, the `.js` vs `.cjs` rationale, and the
parity test, see `framework/docs/SECURITY-RUNTIME.md`.

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
