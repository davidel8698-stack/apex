# APEX Security Runtime — `.js`/`.cjs` Spec Naming vs. Implementation

**R5-003 — Wave 5.**

## Spec naming literal

`apex-spec.md` (Failure 9 — Defense-in-Depth Security Layer) names the
following artifacts:

- `apex-prompt-guard.js`
- `apex-workflow-guard.js`
- `security.cjs` module

Two `.js` extensions and one `.cjs`.

## What ships

Three CommonJS files at `framework/hooks/`:

- `apex-prompt-guard.cjs` — port of `apex-prompt-guard.js` (R6-014 renamed from `prompt-guard.cjs` to match the spec literal `apex-` prefix).
- `apex-workflow-guard.cjs` — port of `apex-workflow-guard.js` (R6-014 renamed from `workflow-guard.cjs` to match the spec literal `apex-` prefix).
- `security.cjs` — the named `security.cjs` module, literal match.

Plus the pre-existing Bash shims at the same names (`prompt-guard.sh`,
`workflow-guard.sh`) which auto-delegate to the `.cjs` when `node` is on
PATH and fall back to the original Bash detection logic when it is not.

## Why `.cjs` for the two named-as-`.js`

The spec's `.js` naming is satisfied by `.cjs` (the CommonJS variant of
JavaScript). Functionally equivalent — both run on Node. The `.cjs`
extension is preferred for the APEX implementation because:

1. **Zero `package.json` requirement.** ESM (`.js` with `"type":"module"` in
   a `package.json`) would force every consumer of `framework/hooks/` to ship
   a `package.json` declaring module type. CommonJS (`.cjs`) does not.
   APEX commits to **zero npm dependencies** (see `apex-spec.md`,
   "Multi-platform from day one"); a stray `package.json` would imply an
   npm-managed install path which is not what the framework wants.
2. **Explicit module type.** `.cjs` is unambiguous to Node — no parsing of a
   surrounding `package.json` is needed to know how to load the file.
3. **Spec-literal compliance for `security.cjs`.** The spec already names
   the helper module `.cjs`; using `.cjs` for the two guards as well keeps
   the runtime uniform (one extension, one loader path).

## Detection-pattern parity contract

The `.cjs` and `.sh` implementations share a single source of truth for
their detection patterns: `framework/test-fixtures/security-patterns.json`.
Both runtimes load that file at startup. Any pattern change must update
the JSON; both engines pick it up automatically. This eliminates the drift
risk that would otherwise come from maintaining two independent regex sets.

`framework/tests/test-hooks-cjs.sh` validates parity end-to-end: every
fixture in the canonical pattern file is fed to both engines and their
exit codes are asserted equal.

## Runtime-aware dispatch

Two paths reach the canonical `.cjs` engine when node is available:

1. **Auto-wired via `framework/settings.json`.** The `PreToolUse` matcher
   for `Write|Edit|Agent` (prompt-guard) and for `Read` (workflow-guard)
   uses a shell conditional command:
   ```
   if command -v node >/dev/null 2>&1 && [ -f ~/.claude/hooks/<name>.cjs ];
   then node ~/.claude/hooks/<name>.cjs; else bash ~/.claude/hooks/<name>.sh; fi
   ```
2. **Command-invoked.** Commands like `/apex:workflow` continue to call
   `bash ~/.claude/hooks/workflow-guard.sh`. The shim itself
   delegates to the `.cjs` when node is present (`exec node …`),
   otherwise it executes the preserved Bash logic in-place.

Both paths converge on the same regex engine when node is installed; both
converge on the same Bash logic when it is not. Spec compliance ("the
three named files exist") is satisfied; runtime portability is
preserved for Bash-only hosts.

## File-tree summary

```
framework/hooks/
  apex-prompt-guard.cjs     <-- spec: apex-prompt-guard.js  (port; R6-014 prefixed)
  prompt-guard.sh           <-- shim: delegates to .cjs when node available (R6-014: shim name preserved)
  apex-workflow-guard.cjs   <-- spec: apex-workflow-guard.js (port; R6-014 prefixed)
  workflow-guard.sh         <-- shim: delegates to .cjs when node available (R6-014: shim name preserved)
  security.cjs              <-- spec: security.cjs           (literal)
  _security-common.sh       <-- Bash counterpart of security.cjs (sourced by shims)
framework/test-fixtures/
  security-patterns.json  <-- canonical pattern set, loaded by both runtimes
```

## See also

- `framework/security-policy.md` — mechanism→implementation map (one row per
  spec mechanism).
- `framework/HOOK-CLASSIFICATION.md` — "CommonJS — Node-runtime guards
  (R5-003)" section.
- `apex-spec.md` Failure 9 — original spec roster.
