# R-P8-A — Shared input-extraction helper (Design R2)

> **R2 revision:** addresses 5 BLOCKING items from G2-CRITIC-R1 (audit-trail-review/PHASE-8-R-P8-A-CRITIC-R1.md). Specifically: subshell cache hazard, `[ ! -t 0 ]` semantics, invocation-count correction, H-G test row definitions, missing test rows for standalone/double-source/subshell-capture/set-u-empty-argv.

## G1-R2 — Revised API and algorithm

**File:** `framework/hooks/_hook-input.sh`

### Critical design correction (BLOCKING-1 fix): SOURCE-TIME stdin read

The R1 design's lazy-cache pattern (`_apex_hook_stdin_load` called from inside a function) is broken under the canonical consumer pattern `FOO=$(apex_hook_input_command "$@")` — the function runs in a `$(...)` subshell, sets the cache there, then returns to parent which never sees the cache update. Second extractor call re-reads drained stdin → returns empty.

**Fix:** read stdin AT MODULE-SOURCING TIME (top-level of the helper file, not inside any function). Module-scope variables set at source-time are PRESENT in the parent shell and INHERITED by all subsequent subshells. The extractor functions then simply query the cached payload — no stdin consumption inside any function.

```bash
# === Sourced at module load time (in PARENT shell) ===
if [ -z "${_APEX_HOOK_INPUT_SOURCED:-}" ]; then
  _APEX_HOOK_INPUT_SOURCED=1
  _APEX_HOOK_STDIN_PAYLOAD=""
  if [ ! -t 0 ]; then
    _APEX_HOOK_STDIN_PAYLOAD=$(cat 2>/dev/null || true)
  fi
fi
```

**Reentrance:** `${_APEX_HOOK_INPUT_SOURCED:-}` flag prevents re-reading on double-source (the second `source` returns immediately, payload preserved).

### Public API (4 functions, all return via stdout)

```bash
apex_hook_input_command   "$@"   # echoes .tool_input.command — for Bash matchers
apex_hook_input_filepath  "$@"   # echoes .tool_input.file_path (or .path) — for Write/Edit matchers
apex_hook_input_tool_name "$@"   # echoes .tool_name — for shape-routing (test-deletion-guard)
apex_hook_input_raw       "$@"   # echoes full stdin payload — for hooks doing custom jq
```

**Return contract (NIT-Axis-1 fix):** every extractor echoes its result to **stdout**. Consumers capture via `FOO=$(apex_hook_input_command "$@")`. Functions never set caller-side variables, never `exit`, only `return 0`.

**Function export (NIT-Axis-1 fix):** functions are NOT `export -f`'d. They do not need to be — bash `$(...)` subshells inherit functions from the parent shell automatically (this is the normal bash subshell semantics). The module-scope variables `_APEX_HOOK_STDIN_PAYLOAD` + `_APEX_HOOK_INPUT_SOURCED` are likewise inherited as environment-style variables in subshells.

### Algorithm per extractor (illustrative for `apex_hook_input_command`)

```bash
apex_hook_input_command() {
  # Priority 1: positional argv
  if [ -n "${1:-}" ]; then
    printf '%s' "$1"
    return 0
  fi
  # Priority 2: cached payload + jq extraction
  if [ -n "${_APEX_HOOK_STDIN_PAYLOAD:-}" ] && command -v jq >/dev/null 2>&1; then
    printf '%s' "$_APEX_HOOK_STDIN_PAYLOAD" | jq -r '.tool_input.command // empty' 2>/dev/null
  fi
  return 0
}
```

**Quote-idiom (NIT-Axis-2 fix):** `printf '%s' "$X"` (not `echo "$X"`) — avoids backslash interpretation and leading-`-` corruption. Matches `_security-common.sh:39` idiom verbatim.

**`set -u` compatibility (NIT-Axis-2 fix):** all variable references use `${VAR:-}` default-expansion. Helper header includes `set -u` so a consumer that forgets to source it under `set -u` still surfaces unbound-variable bugs.

**Variable-naming idiom (NIT-Axis-5 fix):** module-scope uppercase (`_APEX_HOOK_*`); function-internal lowercase with `local` keyword. Header documents the convention.

### `[ ! -t 0 ]` semantics (BLOCKING-2 fix — explicit documentation)

- `[ ! -t 0 ]` is TRUE when stdin is not a TTY. This covers:
  - Closed stdin (`bash hook.sh "arg" </dev/null`) → `cat </dev/null` returns immediately empty
  - Piped stdin (`echo '{...}' | bash hook.sh`) → `cat` consumes the pipe
  - Heredoc (`bash hook.sh "arg" <<< '{...}'`) → `cat` consumes the heredoc
- Use `[ ! -t 0 ]` (not `[ -p /dev/stdin ] || [ ! -t 0 ]`): matches owner-guard.sh:65 precedent; `[ -p /dev/stdin ]` not portable to all shells.
- **No deadlock risk:** `cat` against closed stdin returns immediately. The helper does NOT block on EOF.

### Sourcing pattern (consumer-side, defensive)

```bash
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi
```

Matches `_audit-probe-marker.sh` precedent. Degraded install survives missing helper.

## G4-R2 — Layer tests (10 explicit rows, BLOCKING-4 + BLOCKING-5 fix)

**Insertion anchor (NIT-Axis-4 fix):** in `framework/tests/test-audit-trail-layer.sh`, insert new `# === H-G section ===` block immediately after line 718 (`run_hd_test "H-F3" ...`) and before line 720+ (summary block beginning with `# ----- summary -----`). Wrap entire H-G block in `if [ -f "$HOOKS_DIR/_hook-input.sh" ]; then ... else skip H-G* ... fi` guard.

| Row | Asserts | Mechanism | Expected |
|-----|---------|-----------|----------|
| **H-G0** | `_hook-input.sh` exists at `$HOOKS_DIR` | `[ -f "$HOOKS_DIR/_hook-input.sh" ]` | exit 0 → ok |
| **H-G1** | Sourcing exposes 4 public functions | `( source "$HOOKS_DIR/_hook-input.sh" && type -t apex_hook_input_command )` × 4 | each prints `function` |
| **H-G2** | Helper does NOT execute when invoked directly (BLOCKING-5a) | `bash "$HOOKS_DIR/_hook-input.sh" </dev/null; echo $?` | exit 0, no side effects, no stdout |
| **H-G3** | argv path: `apex_hook_input_command "rm -rf /"` echoes `rm -rf /` | direct call inside subshell sourcing helper | stdout = `rm -rf /` |
| **H-G4** | Empty stdin + no argv → empty (set -u safe) | `( source helper && apex_hook_input_command ) </dev/null` | stdout empty; exit 0 |
| **H-G5** | Malformed JSON stdin → empty output, exit 0 | `( source helper && apex_hook_input_command ) <<<"not-json{"` | stdout empty; exit 0 |
| **H-G6** | stdin envelope path: `{"tool_input":{"command":"abc"}}` via stdin → `abc` | `( source helper && apex_hook_input_command ) <<<'{"tool_input":{"command":"abc"}}'` | stdout = `abc` |
| **H-G7** | argv-priority when both present (BLOCKING-1 verification): stdin `{"tool_input":{"command":"FROM_STDIN"}}` + argv `FROM_ARGV` → `FROM_ARGV` | `( source helper && apex_hook_input_command "FROM_ARGV" ) <<<'{"tool_input":{"command":"FROM_STDIN"}}'` | stdout = `FROM_ARGV` |
| **H-G8** | Subshell-capture pattern (BLOCKING-1 root verification): two `$(...)` extractor calls in same hook each get correct field from the same stdin payload | `( source helper; A=$(apex_hook_input_command); B=$(apex_hook_input_tool_name); echo "$A:$B" ) <<<'{"tool_name":"Bash","tool_input":{"command":"ls"}}'` | stdout = `ls:Bash` (proves source-time read works under `$()` subshells) |
| **H-G9** | Double-source reentrance (BLOCKING-5b): sourcing twice in one shell preserves cache; functions not redefined incorrectly | `( source helper; source helper; A=$(apex_hook_input_command); echo "$A" ) <<<'{"tool_input":{"command":"x"}}'` | stdout = `x`; no errors |

**Total new rows for R-P8-A: 10.** Layer test count moves 55 → 65 after R-P8-A lands (additional H-G10..H-G24+ added in subsequent R-items).

## G2-R1 BLOCKING resolution map

| BLOCKING | Fix |
|----------|-----|
| 1: Subshell cache hazard | Source-time stdin read (module-scope), not lazy. § "Critical design correction" |
| 2: `[ ! -t 0 ]` + `cat` semantics undocumented | Explicit doc in § "`[ ! -t 0 ]` semantics" — no-deadlock guarantee |
| 3: "9 invocations" wrong (actual 27) | Restated: "preserves all argv-style test invocations across `test-fix-plan-emit.sh` (6) + `test-hooks-security.sh` (15) + `test-hooks-blocking.sh` (6) = 27 callsites covering 9 distinct hooks" |
| 4: H-G rows undefined | 10 explicit rows defined in § "G4-R2 — Layer tests" with mechanism + expected output |
| 5: Missing standalone/double-source/subshell-capture rows | Added as H-G2, H-G9, H-G8 respectively |

## G2-R1 NIT resolution map

| NIT | Fix |
|-----|-----|
| Return contract unstated | Documented: stdout-echo + capture via `$(...)`. |
| Function export semantics | Documented: NOT exported; bash `$()` subshells inherit functions automatically. |
| Quote idiom | Mandated: `printf '%s'` (not `echo`); matches `_security-common.sh:39`. |
| Helper-internal `set -u` | Added: helper header includes `set -u`. |
| test-imp016 scope | Deferred to R-AT-P7-C3 review (sequence-guard); flagged inline in plan. |
| Anchor specificity | Layer-test insertion point fixed at line 718→719 boundary. |
| Function-name distinction (`apex_*` vs `_sec_*`) | Documented in helper header: `apex_*` = project-wide public API; `_sec_*` = security-family internal. |
| Variable-naming idiom | Module-scope UPPERCASE; function-internal `local lowercase`. |
| Pure-additive honesty | Restated: "R-P8-A in isolation: zero existing hooks modified. R-P8-C waves carry per-hook risk separately." |

## Ecosystem 10-question gate (carried from R1, unchanged)

(See `~/.claude/plans/calm-cuddling-corbato.md` § R-P8-A.)

## Blast radius (R-P8-A in isolation)

- **R-P8-A in isolation: zero existing hooks modified.** Pure new-file addition.
- **R-P8-C waves carry per-hook risk separately** (15 hooks will source helper across Waves 1-3).
- **Rollback:** delete `_hook-input.sh` + revert 10 H-G layer-test rows. No state dependencies; no per-hook coupling within R-P8-A scope.

## G5 critic R2 success criteria

1. All 10 H-G rows PASS in `test-audit-trail-layer.sh` standalone (65/65 layer test count post-R-P8-A).
2. Helper reentrant: H-G9 PASS proves double-source preserves cache + functions.
3. Subshell-capture works: H-G8 PASS proves `FOO=$(apex_hook_input_command "$@")` returns correct value even when caller has multiple `$(...)` calls in same hook.
4. Standalone invocation no-op: H-G2 PASS proves `bash _hook-input.sh` exits 0 with no side effects.
5. argv backward-compat: H-G3 + H-G7 PASS prove existing argv-style test invocations preserved.
6. Empty/malformed input fail-safe: H-G4 + H-G5 PASS prove fail-safe-to-empty.
7. `bash -n framework/hooks/_hook-input.sh` clean (syntax check).
8. Helper file ≤ 100 lines.
9. Byte-equivalence (manual sweep): for each of 5 reference templates, the helper's output for that template's canonical fixture matches the template's existing private extractor output.
10. Atomic commit: `phase8(helper): R-P8-A — shared input-extraction helper _hook-input.sh`.
