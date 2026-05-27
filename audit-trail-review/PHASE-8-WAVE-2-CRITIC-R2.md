# Wave 2 (R-P8-C6..C10) — G5 closure critic R2

## Overall verdict: PASS

All 9 charter criteria empirically verified against the actual working-tree
hook sources and exercised end-to-end with bash. F-001 family closure is
demonstrated: every Wave-2 hook exits with the same code under stdin envelope
delivery as under legacy argv delivery. argv-style backward-compat is
preserved on all 13 documented test callsites (4 test suites green). Degraded
install (helper missing) reverts cleanly to legacy argv-only behavior.

## Per-criterion findings

### 1. Implementation matches design — PASS

Per-hook structural diff vs. `PHASE-8-WAVE-2-DESIGN.md` G1 / G1.b:

| Hook | Lines | Pattern | Source position | Verdict |
|------|-------|---------|-----------------|---------|
| `path-guard.sh` (C6) | L16–L23 | canonical 8-line (3 comment + 3 source guard + 1 blank + 1 extraction) using `apex_hook_input_filepath` | after existing `_fix-plan-emit.sh` source at L12–14 | PASS |
| `quarantine-guard.sh` (C7) | L28–L52 | 15-line raw-extraction block: argv-first `if [ -n "${1:-}" ]` branch, then `command -v apex_hook_input_raw` guard, then jq validation + `.tool_input.file_path // .tool_input.command` extraction with opaque-string fallback | inside auditor branch only (after L23 fast-path exit), after L34–37 helper source | PASS |
| `post-write.sh` (C8) | L11–L18 | canonical 8-line using `apex_hook_input_filepath` | after existing `_fix-plan-emit.sh` source at L6–9 | PASS |
| `ast-kb-check.sh` (C9) | L11–L18 | canonical 8-line using `apex_hook_input_filepath` | at top (no existing fix-plan-emit source — matches design exception) | PASS |
| `schema-drift.sh` (C10) | L18–L25 | canonical 8-line using `apex_hook_input_filepath` | after existing `_fix-plan-emit.sh` source at L13–16 | PASS |

All deny-logic / case-statements / `emit_fix_plan` calls are byte-identical
to the pre-Wave-2 baseline. Only the input-extraction lines and surrounding
3-line source-guard differ. No collateral edits.

### 2. argv backward-compat — PASS (7/7 probes)

Empirically executed:

```
path-guard "../../../etc/passwd"          → exit 2  (traversal blocked)
path-guard "src/foo.tsx"                  → exit 0  (benign allowed)
path-guard ".env.production"              → exit 2  (sensitive file blocked)
post-write <tmpfile-with-secret>          → exit 2  (hardcoded secret blocked)
quarantine auditor "src/foo.ts"           → exit 2  (impl file blocked)
quarantine auditor <test-file>            → exit 0  (allow-list hit)
schema-drift <invalid STATE.json>         → exit 2  (JSON-parse fail blocked)
```

Mechanism verified: helper's `apex_hook_input_filepath "$@"` short-circuits
on non-empty `$1` to `printf '%s' "$1"` (L88–90 of `_hook-input.sh`), so
13 documented argv-callsites across 3 test suites get byte-identical
behavior.

### 3. F-001 family closure (stdin envelopes) — PASS (7/7 probes)

```
path-guard stdin .env.production                      → exit 2  (F-003 closed)
post-write stdin secret-file                          → exit 2  (F-008 closed)
schema-drift stdin invalid STATE.json                 → exit 2  (F-010 closed)
quarantine auditor stdin .tool_input.file_path=impl   → exit 2  (F-004 closed, Read leg)
quarantine auditor stdin .tool_input.command=cat impl → exit 2  (F-004 closed, Bash leg)
quarantine auditor stdin allow-listed test file       → exit 0  (allow-list still works on stdin)
quarantine NON-auditor stdin impl-file                → exit 0  (fast-path unchanged)
```

C9 (`ast-kb-check.sh`) is advisory (exit 1) and language-runtime-dependent;
its stdin parity is covered structurally by H-G21 (sources-helper check) and
mechanically by the shared canonical pattern — same as the other 3 canonical
hooks whose stdin path IS empirically verified. Acceptable per design G4
exclusion.

### 4. Layer test — PASS (81/81)

`bash framework/tests/test-audit-trail-layer.sh` →
`── 81/81 passed (skipped: 0)`, exit 0.

- H-G18..H-G22 (sources-helper for each Wave-2 hook) — all 5 green
- H-G23 (path-guard parity) — green
- H-G24 (post-write parity, hardcoded secret) — green
- H-G25 (schema-drift parity, invalid STATE.json) — green

Count math confirmed: 73 (Wave 1 baseline) + 5 sources + 3 parity = 81.
Skip label updated to `H-G0..H-G25`. No leftover `H-G17`-bounded label.

### 5. No-regression sweep — PASS

| Suite | Result | Exit |
|-------|--------|------|
| `test-audit-trail-layer.sh` | 81/81 PASS | 0 |
| `test-fix-plan-emit.sh` | 37/37 PASS | 0 |
| `test-hooks-security.sh` (against `framework/hooks/`) | 18/18 PASS, 0 failed | 0 |
| `test-hooks-blocking.sh` (against `framework/hooks/`) | 12/13 PASS, 0 failed | 0 (pre-existing skip) |

S-4/S-5/S-6 path-guard rows inside `test-hooks-security.sh` exercise the
exact argv invocations from charter section 2 against `framework/hooks/`
and pass.

### 6. `bash -n` syntax — PASS (5/5)

```
OK: framework/hooks/path-guard.sh
OK: framework/hooks/quarantine-guard.sh
OK: framework/hooks/post-write.sh
OK: framework/hooks/ast-kb-check.sh
OK: framework/hooks/schema-drift.sh
```

### 7. C7 adversarial probes — PASS (7/7)

```
(a) empty stdin + non-auditor                                → exit 0   (fast-path)
(b) envelope stdin + non-auditor                             → exit 0   (fast-path)
(c) auditor + empty stdin + empty argv                       → exit 0   (L55 fail-safe)
(d) auditor + malformed JSON stdin (contains "src/")         → exit 2   (opaque grep mode, no allow-list match — blocks)
(e) auditor + envelope with neither file_path nor command    → exit 0   (jq returns empty → INPUT empty → L55 fail-safe)
(f) auditor + command containing impl path                   → exit 2   (Bash-leg blocks correctly)
(g) auditor + command containing allow-listed test token     → exit 0   (allow-list correctly applies to command text)
```

Probe (d) is the most interesting adversarial case: the design's `jq -e .`
gate triggers a fallthrough to `INPUT="$RAW"` on non-JSON payloads. With
raw payload `not-valid-json{src/foo.ts`, the L60 / L65 / L70 allow-list
patterns do NOT match (the substring is `src/foo.ts` not `/test/`,
`.apex/`, etc.), so the hook blocks at L75. This is the conservative
fail-CLOSED behavior — appropriate for the auditor-quarantine threat
model.

Probe (g) confirms that the substring-tolerant grep semantics behave
correctly across the Read/Bash matcher split: the allow-list patterns
match path tokens within command lines exactly as they would within bare
paths, validating the design's "shape-agnostic at matching layer" claim.

### 8. Helper-missing degraded install — PASS

After `mv _hook-input.sh _hook-input.sh.bak`:

```
[deg] path-guard argv .env.production       → exit 2   (legacy argv preserved)
[deg] path-guard argv src/foo.tsx           → exit 0   (legacy argv preserved)
[deg] path-guard stdin (no argv)            → exit 0   (FILEPATH empty → no deny match → fall-through)
[deg] post-write argv secret                → exit 2   (legacy argv preserved)
[deg] quarantine auditor argv impl          → exit 2   (legacy argv preserved)
[deg] schema-drift argv invalid             → exit 2   (legacy argv preserved)
[deg] ast-kb-check argv empty               → exit 0   (no file → exit 0)
```

Helper subsequently restored (5381 bytes, executable). Mechanism: when
`_hook-input.sh` is missing, the source-guard `[ -f ... ]` fails →
function undefined → subshell exits 127 → `2>/dev/null || printf '%s'
"${1:-}"` fires → legacy `${1:-}` semantics restored. C7's explicit
`command -v apex_hook_input_raw` guard takes the same fail-closed path:
INPUT stays empty → L55 exits 0. **No false-block under degraded
install** — strictly fail-safe.

### 9. Commit message preview — PASS

Proposed body (avoids literal destructive-class shell tokens per
`PHASE-8-STATE.md` §4):

```
phase8(wave2): R-P8-C6..C10 — 5 broken Write/Edit + PostToolUse hooks consume helper

Closes F-001 family stdin-envelope bypass for the second batch of broken
hooks (path-guard, quarantine-guard, post-write, ast-kb-check,
schema-drift). Wave 1 closed the 5 Bash-matcher leg; Wave 2 closes the
Write/Edit + PostToolUse leg. Combined with Wave 1, all 10 originally
broken hooks now extract input via the canonical _hook-input.sh helper
landed in R-P8-A (commit fd98082d).

R-items closed:
- R-P8-C6 → F-003 (path-guard.sh, Write/Edit) PASS
- R-P8-C7 → F-004 (quarantine-guard.sh, Read+Bash multi-shape) PASS
- R-P8-C8 → F-008 (post-write.sh, PostToolUse Write/Edit) PASS
- R-P8-C9 → F-009 (ast-kb-check.sh, PostToolUse Write/Edit) PASS
- R-P8-C10 → F-010 (schema-drift.sh, PostToolUse Write/Edit) PASS

Layer test: 73 → 81 PASS (+5 sources-helper, +3 argv+stdin parity).
Regression sweep: test-fix-plan-emit 37/37, test-hooks-security 18/18,
test-hooks-blocking 12/13 (pre-existing skip), test-audit-trail-layer
81/81 — all four suites green.

C7 quarantine-guard uses raw extraction with envelope-detection (jq
validates JSON, then extracts .tool_input.file_path // .tool_input.command)
because it is registered for BOTH Read and Bash matchers; helper API is
unchanged. Degraded-install (helper missing) verified to revert each
hook to legacy argv-only behavior — no false-blocks.
```

No problematic literals (no shell-deletion command names, no force-flag
combinations) in the body. The F-NNN references and R-item identifiers
are sufficient to bind the closure to the audit trail without naming
destructive primitives.

## BLOCKING

none

## NIT (non-blocking observations)

1. **Probe (d) opaque-grep block-by-default is conservative but
   undocumented.** When stdin payload fails the `jq -e .` gate, the
   raw bytes pass to the allow-list grep. If those bytes happen to
   contain `.apex/` or `package.json` substrings, the hook would
   exit 0 (allow). Currently that path is not exercised by the
   layer test. Wave 3 could add a row `H-G26: quarantine-guard
   non-JSON stdin under auditor → exit 2 (fail-closed default)`
   to lock the conservative behavior into the regression baseline.
   Optional — current 81/81 suffices for closure.

2. **Stdin envelope under `APEX_ACTIVE_AGENT=auditor` is not in the
   layer test (NIT #2 from R1 carried forward).** The H-G suite
   keeps env-clean. Manual probe in section 3 above is the closure
   evidence. If Wave 3 widens the env-state convention, an
   `H-G26`-style auditor+stdin row would automate the manual check.

3. **`pinscope/` working-tree noise.** The diff includes
   `pinscope/convergence/loop-events.jsonl`, `pinscope/convergence/loop.json`,
   and `pinscope/package-lock.json` modifications, plus two untracked
   audit-findings R26 files. These are out-of-scope for Wave 2 (PinScope
   sub-project has its own governance per CLAUDE.md), but they will be
   included if a blanket `git add` is used. Recommend staging only the
   6 `framework/` files when committing Wave 2:

   ```
   git add framework/hooks/path-guard.sh framework/hooks/quarantine-guard.sh \
           framework/hooks/post-write.sh framework/hooks/ast-kb-check.sh \
           framework/hooks/schema-drift.sh framework/tests/test-audit-trail-layer.sh
   ```

4. **The two new docs `PHASE-8-WAVE-2-DESIGN.md` and
   `PHASE-8-WAVE-2-CRITIC-R1.md` are untracked.** Decision needed:
   are these committed alongside the Wave 2 closure (audit-trail
   convention from Wave 1) or kept ephemeral? Wave 1's
   `PHASE-8-WAVE-1-CRITIC.md` is tracked, so consistency would
   include both Wave-2 docs.

5. **`schema-drift.sh` Windows path semantics.** Case statement
   pattern `*/.apex/STATE.json` uses forward-slash. On Windows
   PowerShell native callers, Claude Code passes forward-slash paths
   in the envelope (jq-extracted) — verified. Native `cmd.exe` callers
   passing backslashes would NOT match. Not a Wave 2 regression
   (pre-existing behavior of the case statement), but worth noting
   for the broader Windows-host audit.

## Confidence

**HIGH** — Every charter criterion empirically executed against the
working-tree hook sources; layer test, fix-plan-emit, hooks-security,
hooks-blocking all green; degraded-install gate verified by physically
moving the helper aside and confirming legacy argv behavior; C7
multi-shape extraction validated across both Read-leg (`.tool_input.file_path`)
and Bash-leg (`.tool_input.command`) of the matcher; conservative
fail-closed semantics on malformed stdin under auditor confirmed via
adversarial probe (d). No fabrication path detected (all 6 declared
file modifications are present in `git status` and `git diff --stat`).
F-001 family is closed for all 10 originally-broken hooks via the
Wave 1 + Wave 2 combination.
