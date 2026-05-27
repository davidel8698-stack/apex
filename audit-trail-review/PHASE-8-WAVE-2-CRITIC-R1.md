# Wave 2 (R-P8-C6..C10) — G2 critic R1

## Overall verdict: PASS

Design is internally consistent, all argv-style regression baselines accounted for (13 callsites verified independently), C7 multi-shape extraction is the right choice (no helper-API widening), and the three parity probes (H-G23/24/25) are individually verified to fire exit 2 against the real deny patterns of each hook. No BLOCKING issues found.

## BLOCKING (must fix before G3)

none

## Per-check findings (against critic charter items 1–7)

### Charter #1 — C7 quarantine-guard multi-shape design — PASS (all 6 sub-claims verified)

a. **argv-style fix-plan-emit at L125 preserved** — explicit `if [ -n "${1:-}" ]; then INPUT="$1"` branch is byte-identical to legacy `INPUT="${1:-}"` in the `$1`-non-empty case. `APEX_ACTIVE_AGENT=auditor bash quarantine-guard.sh "src/foo.ts"` still hits this branch.

b. **Read tool envelope → file_path** — `jq -r '.tool_input.file_path // .tool_input.command // empty'` extracts `.tool_input.file_path` first; existing grep patterns at L36/41/46 match path strings without modification.

c. **Bash tool envelope → command** — `.tool_input.command` fallback fires; grep patterns at L36 (`/test/`, `\.test\.`, etc.) and L41 (`.apex/`, `STATE.json`, etc.) are substring-tolerant — they match path tokens within `cat src/foo.ts` exactly as they would within `src/foo.ts`. Design's claim of shape-agnostic matching is correct.

d. **Envelope + `APEX_ACTIVE_AGENT=auditor` together** — auditor fast-path at L23 runs BEFORE the source-block and extraction block (design says "Replaces line 28 + nothing else"). For auditor, control flows through extraction → existing grep logic. For non-auditor, L23 exits 0 immediately; helper sourcing and extraction never run. Confirmed.

e. **Non-auditor fast-path overhead unchanged** — L20 (`ACTIVE_AGENT="${APEX_ACTIVE_AGENT:-}"`) and L23 (`if [ "$ACTIVE_AGENT" != "auditor" ]; then exit 0; fi`) are upstream of all Wave-2-added code. Zero extra work for the common case.

f. **Non-JSON literal stdin payload** — design's `jq -e . >/dev/null 2>&1` validates JSON; on failure the `else INPUT="$RAW"` branch falls through to opaque-string mode. A test that pipes a literal path (`printf 'src/foo.ts' | bash quarantine-guard.sh` under auditor env) lands in this branch and the grep logic runs on `src/foo.ts` exactly as in the argv path. Correct handling.

### Charter #2 — Canonical pattern (C6/C8/C9/C10) correctness — PASS

`VAR=$(apex_hook_input_filepath "$@" 2>/dev/null || printf '%s' "${1:-}")`

Verified against `_hook-input.sh` L86–100 (helper always `return 0`):
- **Helper present, argv non-empty:** L88–90 short-circuits to `printf '%s' "$1"`. Subshell exits 0. `||` does NOT fire. VAR = argv. Matches Wave 1 contract exactly.
- **Helper present, stdin envelope, no argv:** L92–98 runs jq on stdin payload. Subshell exits 0. `||` does NOT fire. VAR = extracted path. Production fix path.
- **Helper present, empty stdin, no argv:** function echoes nothing, returns 0. `||` does NOT fire. VAR = empty. Same as legacy `${1:-}`. Fail-safe.
- **Helper not sourced (degraded install):** `apex_hook_input_filepath` is an undefined command → subshell exits 127, stderr suppressed by `2>/dev/null`, `||` fires, `printf '%s' "${1:-}"` runs. Legacy argv-only behavior preserved.

The `||` fallback semantics are exactly what the design claims. Confirmed.

### Charter #3 — post-write.sh argv-style invocation count — PASS (6 confirmed)

Independently counted in `test-hooks-blocking.sh`:
| Line | Invocation | Test |
|------|------------|------|
| L16 | `bash "$HOOKS_DIR/post-write.sh" bad.ts` | A-3a |
| L38 | `bash "$HOOKS_DIR/post-write.sh" good.ts` | A-3b |
| L52 | `bash "$HOOKS_DIR/post-write.sh" bad.ts` | A-3c |
| L58 | `bash "$HOOKS_DIR/post-write.sh" "$TEMP_REPO/COMMIT_EDITMSG"` | R-020a |
| L64 | `bash "$HOOKS_DIR/post-write.sh" "$TEMP_REPO/COMMIT_EDITMSG"` | R-020b |
| L70 | `bash "$HOOKS_DIR/post-write.sh" "$TEMP_REPO/COMMIT_EDITMSG"` | R-020c |

Design claim of "6" matches. Plus 1 more in test-fix-plan-emit.sh L165 → 7 argv-style total for post-write, but design's per-suite breakdown is correct.

### Charter #4 — C9 ast-kb-check exclusion from parity probes — PASS (well-justified)

Design's rationale ("ADVISORY exit 1, requires node/python3 runtime") is sound. The hook's exit-1 mode requires:
- A real file on disk (`[ -f "$FILE" ] || exit 0` at L15)
- A supported extension (.ts/.tsx/.js/.jsx/.mjs/.cjs/.py)
- An import statement that fails `node -e "require.resolve(...)"` or `python3 -c "import ..."`

A parity-probe that exercised the ADVISORY exit-1 path would couple the layer test to node-resolution semantics on the runner's PATH. Defensible exclusion.

**Minor observation (non-blocking):** a parity probe of the trivial pass-through path (e.g., empty file or `.txt` extension → exit 0 via L15 or L27) would prove extraction-layer parity without runtime dependencies, but would prove nothing about deny-logic. Skipping is fine; H-G21 (sources-helper check) already gates the integration. See NIT #1.

### Charter #5 — Layer test insertion site — PASS (file structure confirmed)

Independent verification of `test-audit-trail-layer.sh`:
- **L727:** `if [ -f "$HOOKS_DIR/_hook-input.sh" ]; then` (outer gate)
- **L729–819:** H-G0..H-G14 (Wave 0 + Wave 1 sources-helper)
- **L821–846:** H-G15..H-G17 (Wave 1 parity probes)
- **L847:** `fi` (closes H-G17 if-block)
- **L848:** `else`
- **L849:** `skip "H-G0..H-G17: _hook-input.sh helper not installed (R-P8-A not landed)"`
- **L850:** `fi` (closes outer L727 gate)

Design's "between current H-G17 (line ~847) and the closing `else skip` branch (line ~848)" is accurate (off-by-one is only in whether "L848" refers to `else` keyword or the skip-message line — both unambiguous). Insertion before `else` at L848 keeps the outer `if [ -f ... _hook-input.sh ]` gate intact and the skip label update to `H-G0..H-G25` is the only required textual edit. Confirmed.

### Charter #6 — H-G24 post-write secret regex match — PASS

Pattern under test: `const password = "abcdef1234567890XYZ"`
Regex (post-write.sh L14): `(password|secret|token|key|api_key|credential|private_key|bearer)\s*[:=]\s*['"][a-zA-Z0-9_/+=-]{8,}`

Trace:
- `password` → matches first group
- ` = ` → matches `\s*[:=]\s*`
- `"` → matches `['"]`
- `abcdef1234567890XYZ` (19 chars, all `[a-zA-Z0-9]`) → matches `[a-zA-Z0-9_/+=-]{8,}` (≥8)

Argv path: `bash post-write.sh "$HG24_TMP"` → `FILE=$HG24_TMP` → `grep -E ... "$HG24_TMP"` matches → exit 2.
Stdin path: helper extracts `.tool_input.file_path` = `$HG24_TMP` → same grep call → exit 2.

Secondary gates verified non-firing for `mktemp`-style tmpfile:
- L32 test-naming check: tmpfile path lacks `.test.`/`.spec.`/`test_` → skipped
- L53 `.ts|.tsx` gate: tmpfile has no extension → skipped

Hook exits 2 at L27 (secret block) before reaching either. Parity holds.

### Charter #7 — H-G25 schema-drift path glob match — PASS

Design constructs:
```
HG25_TMP=$(mktemp -d)/.apex     # e.g., /tmp/tmp.abc123/.apex
mkdir -p "$HG25_TMP"            # creates the .apex subdir
echo 'not-valid-json{' > "$HG25_TMP/STATE.json"
```

So the path passed to schema-drift is `/tmp/tmp.abc123/.apex/STATE.json`.

Schema-drift case statement at L22: `*/.apex/STATE.json`. Bash `case` glob: `*` matches any sequence (including `/`). `/tmp/tmp.abc123/.apex/STATE.json` ends in `/.apex/STATE.json` → matched → REQUIRED_KEYS for STATE.json shape is set → `jq empty "$FILE"` at L52 fails on `not-valid-json{` → emit_fix_plan + exit 2.

Argv path delivers the file via `$1`. Stdin path delivers via `.tool_input.file_path` in envelope. Both reach the same `case "$FILE" in */.apex/STATE.json)` arm. Parity holds.

## NIT (recommended but non-blocking)

1. **C9 trivial-pass parity probe**: an additional row `H-G26: ast-kb-check.sh argv+stdin parity (empty file → both exit 0)` would extend coverage without runtime dependencies. Optional — Wave 1 didn't probe its advisory hook either, so the precedent supports the exclusion.

2. **C7 stdin-envelope manual probe deferred to G5 critic, not codified in H-G**: an `H-G26` (or H-G18b) that runs `APEX_ACTIVE_AGENT=auditor` plus envelope `{"tool_input":{"file_path":"src/foo.ts"}}` and asserts exit 2 would automate what the design currently treats as a one-shot G5 manual check. Adding it would harden the regression baseline. Argument for skipping: it adds env-state to the layer test, which has been kept env-clean so far.

3. **Design line "Replaces lines 28 (`INPUT="${1:-}"`) + nothing else"** could be more precise: the source-block for `_hook-input.sh` is inserted ABOVE line 28 (between L26 comment and L28), then L28 is replaced by the new multi-branch block. As written it's ambiguous whether the source-block is inserted or appended. Suggest restating as: "Inserts the source-guard immediately below line 26 (existing comment) and replaces line 28 with the new INPUT-extraction block."

4. **Line number drift between design and current file**: design refers to "line ~847" / "line ~848" for the layer test insertion. Actual file is 858 lines total; H-G17 closes at L847, `else` at L848, `skip` at L849. `~` qualifier is appropriate but tighter anchors (e.g., "after the H-G17 closing `fi` at L847") would survive future renumbering better. Style match with Wave 1 critic which used precise line numbers (e.g., "L21-23", "L40-42").

5. **G5 success-criteria item 5 layer count claim** (`73 → 81`): the count math is correct (73 + 5 sources + 3 parity = 81), but H-G24's tmpfile cleanup (`rm -f "$HG24_TMP"`) and H-G25's `rm -rf "$(dirname "$HG25_TMP")"` happen between the bash invocations and the assertion. If any future H-G inserted between them depends on the tmpfile, ordering would break — not a Wave 2 issue, but a note for Wave 3 authors. Cosmetic.

6. **Ecosystem 10Q answer #9** has a typo: "Helper helper continues to be SSoT" — should be "Helper continues to be SSoT".

## Confidence

**HIGH** — All 7 charter sub-claims independently verified against actual file contents (hook source, helper source, layer test structure, test invocations); the design's correctness predicates trace through bash semantics without surprises (argv-first via `[ -n "${1:-}" ]`, `||` fires only on subshell-exit-nonzero, jq validation gate for malformed envelopes, case-glob `*` matches across `/`); no helper-API widening required for C7 (raw extractor is sufficient); 13 argv-callsite regression baseline counted and matches design.
