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

## Prefix restoration via R6-014 rename

`R6-014` (round 6, finding F-014/F-018) renamed
`prompt-guard.cjs` → `apex-prompt-guard.cjs` and
`workflow-guard.cjs` → `apex-workflow-guard.cjs` to match the spec
literal `apex-` prefix. The .cjs extension is documented as equivalent
to the spec's .js per the R5-003 paragraph below. Both divergences
(extension and prefix) are now covered:

- **Extension** — spec `.js` ↔ impl `.cjs`. Documented and justified
  below ("Why `.cjs` for the two named-as-`.js`"). Functionally
  equivalent; preserved for the zero-`package.json` requirement.
- **Prefix** — spec `apex-prompt-guard` / `apex-workflow-guard` ↔ impl
  literal match (post-R6-014). Brand-position-named files are now
  literally named per the spec; no aliasing layer is required.

The R6-014 rename touched `framework/settings.json` (matcher entries),
`framework/scripts/sync-to-claude.sh` (delivery list), this doc
(file-list section above), `framework/HOOK-CLASSIFICATION.md`, the bash
shims (`prompt-guard.sh`, `workflow-guard.sh` — names preserved by
design so existing command-invoked call sites continue to resolve),
and the `framework/tests/test-security-*.sh` suite. The rename is
content-preserving for the .cjs files (byte-identical).

If R6-014 is ever reverted, this paragraph and the file-list section
above must be reverted in lockstep — the doc text must match the
implementation.

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

## IMP-003 arg-content enforcement coverage (R17-642)

The IMP-003 spec anchor names two hooks — `apex-prompt-guard.cjs` and
`path-guard.sh` — as the enforcement points for arg-content validation.
In practice, only one of the two can structurally perform arg-name
dispatch under the current Claude Code invocation contract; this
section records the runtime division of labor so a literal reader of
the spec does not expect parity that is not present.

**Canonical arg-name dispatch lives in `apex-prompt-guard.cjs`.**
This .cjs guard is Auto-PreToolUse on `Write|Edit|Agent` and receives
the full `tool_input` envelope on stdin. The function
`security.cjs:matchArgContent` walks each `tool_input` entry and
applies three tiers of validation: (1) **path-typed** args
(`path` / `filename` / `file` / `file_path`) reject shell metachars
(`; & | $ ` `( ) < >`) and embedded CR/LF; (2) **name-typed** args
(`name` / `title` / `description`) reject role markers
(`<|im_start|>`, `[INST]`, `### System`, `Assistant:` — the canonical
list lives in `framework/test-fixtures/security-patterns.json`
`role_marker_patterns.patterns[]`); (3) **length-threshold advisory**
warns (no block) when a name-typed arg exceeds 1000 characters. All
three tiers fire from the .cjs path only.

**`path-guard.sh` covers only the path-prefix half of IMP-003.** Its
invocation shape (`bash path-guard.sh $FILEPATH` with FILEPATH as a
positional argument) does not carry the full `tool_input` envelope, so
the hook cannot dispatch by arg name. It enforces the orthogonal
path-prefix concerns: parent traversal (`../`), Unix/Windows system
directories, `.git/*`, sensitive-file patterns (`.env`, `id_rsa`,
`credentials`). The two responsibilities — arg-name dispatch
(`apex-prompt-guard.cjs`) and path-prefix rejection (`path-guard.sh`)
— are complementary, not duplicative. Both are required for full
IMP-003 coverage.

**Future port option (deferred).** A future remediation may move
`matchArgContent` into `framework/hooks/_security-common.sh` (coupled
with the F-644 Bash-fallback parity work). If that lands,
`path-guard.sh` could source the shared library and gain arg-name
dispatch at near-zero cost — a single canonical engine would back both
hooks. Until then, `apex-prompt-guard.cjs` is the single enforcement
point for the arg-name half; consumers reading the IMP-003 spec
anchor should follow this section to learn where the substance lives.

## Node.js prerequisite for IMP-003 (R17-644)

Full IMP-003 arg-content validation requires Node.js on the host. The
canonical engine lives in `apex-prompt-guard.cjs` (delegated to by
`prompt-guard.sh` when `node` is on PATH, and invoked directly by the
runtime-aware dispatcher in `framework/settings.json`). When Node is
absent, the Bash fallback in `prompt-guard.sh` runs instead.

**What still works on Bash-only hosts.** The five free-text
prompt-injection patterns continue to enforce: instruction override,
role hijacking, prompt framing (system-label at start of line), markdown
code-block injection (the system-tagged triple-backtick form), and
priority injection (`IMPORTANT:` / `CRITICAL:` at start of line). All
five exit 2 on match per the original R-006 logic; preservation
contract intact.

**What requires Node.js.** The IMP-003 arg-name dispatch tiers — (1)
path-typed shell-metachar rejection, (2) name-typed role-marker
rejection, (3) >1000-char advisory — depend on
`security.cjs:matchArgContent` walking the full `tool_input` envelope.
The Bash fallback receives only the positional input string, not the
arg-typed envelope, so it cannot dispatch.

**Runtime advisory.** When the Bash fallback runs, `prompt-guard.sh`
emits a single-line stderr advisory naming the missing capability
and pointing to this section. The advisory is informational, not
blocking — the five free-text patterns still fire. Operators on
Bash-only hosts (minimal containers, forensic shells) should install
Node.js to gain IMP-003 arg-content coverage.

**Cross-reference to F-642.** A future remediation may port
`matchArgContent` into `framework/hooks/_security-common.sh` so the
Bash fallback achieves parity (and `path-guard.sh` gains arg-name
dispatch as a free side-effect — see §IMP-003 arg-content enforcement
coverage above). Until then, Node.js is the prerequisite for full
IMP-003 coverage. The canonical pattern set lives in
`framework/test-fixtures/security-patterns.json` — single source of
truth shared between the .cjs and .sh runtimes when both are present.

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

## Quarterly adversarial pattern refresh (R16-633 / IMP-033)

The detection patterns in `framework/test-fixtures/security-patterns.json`
must not stagnate. Spec anchor (IMP-033): "`framework/hooks/
apex-prompt-guard.cjs` חייב לעבור Quarterly adversarial attack-generation
refresh." The refresh cycle below is the process; the script
`framework/scripts/adversarial-pattern-refresh.sh` is the entry point.

### Cycle (run once per calendar quarter)

1. **Generate.** Run `framework/scripts/adversarial-pattern-refresh.sh`
   in `generate` mode. The script enumerates the current pattern
   families (prompt injection, role hijacking, hidden directives,
   encoded-bypass, role markers, etc.) and produces a candidate set of
   new attack signatures. Initially a stub; the script's body grows
   round-over-round as new attack classes surface.
2. **Add signatures.** Review candidate signatures, drop false-positive
   risks, and append survivors to the appropriate array in
   `framework/test-fixtures/security-patterns.json`.
3. **Remove obsolete.** Mark signatures whose attack vector no longer
   applies (platform-side fix landed, attack class subsumed by a
   broader pattern). Delete after one quarter of quarantine to allow
   rollback.
4. **Release notes.** Add a CHANGELOG entry summarising the refresh —
   number of signatures added, removed, retained.
5. **Visibility.** The refresh date and signature count delta surface
   in the next round's audit findings under the "Adversarial pattern
   refresh" cadence check.

### Cadence

- **Quarterly.** Calendar quarters (Q1/Q2/Q3/Q4). A missed quarter is
  itself an audit finding.
- The script logs its execution to `.apex/pattern-refresh.log` (epoch
  + signature count + delta).

### Output visibility

- CHANGELOG.md — one entry per refresh.
- `framework/test-fixtures/security-patterns.json` — direct diff.
- Audit round R{N+quarterly} — "pattern refresh cadence" check.

## Subagent cache invalidation — fresh-session requirement (R-DH-P7-03)

> Topic-shift note: this section addresses runtime caching of subagent
> definitions (a host-side concern), separate from the .js/.cjs spec
> naming reconciliation above. Both topics belong here because both
> govern the runtime-vs-source contract for security-critical artifacts.

**The Claude Code harness caches subagent definitions at session
start.** When a subagent's `~/.claude/agents/<name>.md` file changes
mid-session (e.g., after a `/apex:self-heal` round that strengthens
`framework-auditor.md` and syncs the install copy), the running
session continues to use the OLD definition until session restart.

This was the confound documented in `detector-review/FINAL-CERTIFICATION.md`
§3 L-DH-03: Phase 6 trials had to use `general-purpose` with the
strengthened definition embedded as prompt body (rather than
`framework-auditor` directly) because the session's cached
definition was stale.

**Operating requirement.** Production self-heal invocations
(`/apex:self-heal`) should run in a FRESH Claude Code session
after any framework-auditor / round-checker / specialist-agent
file change. This includes:

- Any commit that touches `framework/agents/**/*.md`
- Any commit that touches `framework/modules/apex-*/agent.md`
  (synthesized into `~/.claude/agents/specialist/<name>.md` by
  `sync-to-claude.sh`)

**Verification.** `framework/tests/test-subagent-cache.sh` enforces
the source-vs-install contract on every CI run via two axes:
(1) `diff -q` byte-equality on every emitted destination per
`sync-to-claude.sh`'s delivery declarations (`copy_tree
framework/agents/` + `copy_modules_specialists` flatten);
(2) mtime sanity (`[ src -nt dst ]` MUST be FALSE; catches the
post-sync edit pattern where source was updated after the last
sync). Pre-flight SKIP when `~/.claude/agents/` is absent.

The test does NOT verify session-cache invalidation (host-side
behavior); it verifies that the on-disk install state matches the
source. A drift FAIL signals "fresh-session required after the
next sync" — the operator must restart Claude Code or use the
mitigation pattern below.

**Mitigation pattern for in-flight detection rounds.** If a session
must continue with a strengthened agent definition mid-round, use
the `general-purpose` subagent with the strengthened definition
embedded as the prompt body (matches the Campaign A Phase-6
mitigation; documented in `detector-review/EXPERIMENT-PROTOCOL.md`
§12 amendment 2026-05-24).

## See also

- `framework/security-policy.md` — mechanism→implementation map (one row per
  spec mechanism).
- `framework/HOOK-CLASSIFICATION.md` — "CommonJS — Node-runtime guards
  (R5-003)" section.
- `apex-spec.md` Failure 9 — original spec roster.
- `framework/scripts/adversarial-pattern-refresh.sh` — quarterly cycle entry point (R16-633).
- `framework/tests/test-subagent-cache.sh` — subagent cache staleness probe (R-DH-P7-03).
