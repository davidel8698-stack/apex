# Wave 2 (R-P8-C6..C10) — design

> Combined design doc covering 5 R-items: path-guard, quarantine-guard, post-write, ast-kb-check, schema-drift. 4 of 5 share the canonical `apex_hook_input_filepath` pattern; quarantine-guard (C7) needs a multi-shape extraction (Read + Bash matchers both registered).

## G0 — research summary

| R-item | File | Variable | Hook type | Matcher(s) | Pattern |
|--------|------|----------|-----------|------------|---------|
| C6 | `framework/hooks/path-guard.sh` (L16) | `FILEPATH` | PreToolUse | Write, Edit | canonical filepath |
| C7 | `framework/hooks/quarantine-guard.sh` (L28) | `INPUT` | PreToolUse | Read, Bash | **multi-shape (raw)** |
| C8 | `framework/hooks/post-write.sh` (L11) | `FILE` | PostToolUse | Write, Edit | canonical filepath |
| C9 | `framework/hooks/ast-kb-check.sh` (L11) | `FILE` | PostToolUse | Write, Edit | canonical filepath |
| C10 | `framework/hooks/schema-drift.sh` (L18) | `FILE` | PostToolUse | Write, Edit | canonical filepath |

**Argv-style test invocations that must remain green (regression baseline):**

| Test file | Invocations of Wave-2 hooks | Hook |
|-----------|------------------------------|------|
| `test-fix-plan-emit.sh` | L105, L138, L165 | path-guard, schema-drift, post-write |
| `test-fix-plan-emit.sh` | L125 | quarantine-guard (argv+`APEX_ACTIVE_AGENT=auditor`) |
| `test-hooks-security.sh` | L43, L47, L51 | path-guard ×3 |
| `test-hooks-blocking.sh` | L16, L38, L52, L58, L64, L70 | post-write ×6 |

**Total argv-callsites preserved by argv-first contract: 13.** All hit `$1` non-empty → helper returns argv verbatim → byte-identical behavior pre/post.

**Helper API available (from R-P8-A landed in `fd98082d`):**
- `apex_hook_input_filepath "$@"` → echoes `.tool_input.file_path // .tool_input.path // empty`
- `apex_hook_input_raw "$@"` → echoes full stdin payload (for hooks doing custom jq)

---

## G1 — migration design (canonical: C6, C8, C9, C10)

Identical 8-line block per hook, inserted AFTER existing `_fix-plan-emit.sh` source (where present) or at the original `<VAR>="${1:-}"` site (C9 ast-kb-check, which sources nothing).

```bash
# Phase 8 R-P8-CN: canonical input extraction via shared helper.
# Closes F-NNN (stdin-envelope bypass — auditor axis-13.e discovery).
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi

<VAR>=$(apex_hook_input_filepath "$@" 2>/dev/null || printf '%s' "${1:-}")
```

Replace each existing `<VAR>="${1:-}"` line:
- **C6** path-guard: replaces `FILEPATH="${1:-}"` at L16 — closes F-003
- **C8** post-write: replaces `FILE="${1:-}"` at L11 — closes F-008
- **C9** ast-kb-check: replaces `FILE="${1:-}"` at L11 — closes F-009
- **C10** schema-drift: replaces `FILE="${1:-}"` at L18 — closes F-010

### Pattern correctness (canonical 4)

1. **Argv-first preservation:** when `$1` is non-empty, `apex_hook_input_filepath` short-circuits to `printf '%s' "$1"`. The 13 argv-style test callsites listed above all hit this path → byte-identical exit codes pre/post.
2. **Stdin envelope path (production fix):** when invoked by Claude Code with no argv, helper reads stdin via `cat`, queries `.tool_input.file_path // .tool_input.path // empty` with jq → returns the path. F-NNN closure predicate.
3. **Helper-missing degraded install:** `2>/dev/null || printf '%s' "${1:-}"` fallback. If `_hook-input.sh` is removed or source-guard fails, behavior reverts to legacy argv-only — same as pre-Phase-8. Fail-safe.
4. **`set -u` compatibility:** every Wave-2 hook starts with `set -u`. Helper functions use `${VAR:-}` defaults internally. No unbound-variable surface.

---

## G1.b — C7 quarantine-guard special design

### Why C7 differs

`quarantine-guard.sh` is registered as PreToolUse for **both** `Read` and `Bash` matchers. The semantics of "what `INPUT` carries" depend on which tool fired:

- **Read tool** → `.tool_input.file_path` (e.g., `src/foo.ts`)
- **Bash tool** → `.tool_input.command` (e.g., `cat src/foo.ts`)

Existing argv-style logic treats `INPUT` as a single opaque string and runs grep patterns over it. The patterns (`/test/`, `.env`, `.apex/`, `package.json`, etc.) match equally well against either a bare file path OR a command line containing that path — so the existing logic IS shape-agnostic at the matching layer. The bug is purely at the extraction layer.

### C7 design — raw-extraction + envelope detection

```bash
# Phase 8 R-P8-C7: canonical input extraction via shared helper.
# Closes F-004 (stdin-envelope bypass — auditor axis-13.e discovery).
# quarantine-guard is registered for BOTH Read AND Bash matchers, so the
# envelope may carry either .tool_input.file_path OR .tool_input.command.
# Strategy: use raw extractor, then either parse JSON envelope (stdin path)
# or fall back to argv literal (test path) — single string in either case.
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi

INPUT=""
if [ -n "${1:-}" ]; then
  # Argv-first (legacy test contract preserved verbatim).
  INPUT="$1"
elif command -v apex_hook_input_raw >/dev/null 2>&1; then
  RAW=$(apex_hook_input_raw 2>/dev/null || true)
  if [ -n "$RAW" ] && command -v jq >/dev/null 2>&1 \
      && printf '%s' "$RAW" | jq -e . >/dev/null 2>&1; then
    INPUT=$(printf '%s' "$RAW" \
      | jq -r '.tool_input.file_path // .tool_input.command // empty' 2>/dev/null)
  else
    INPUT="$RAW"
  fi
fi
```

Replaces lines 28 (`INPUT="${1:-}"`) + nothing else. The fast-path `if [ "$ACTIVE_AGENT" != "auditor" ]; then exit 0; fi` at line 23 runs before any of this and is unchanged — overhead for non-auditor invocations is unchanged (zero extra work).

### C7 correctness analysis

1. **Argv-first:** explicit `if [ -n "${1:-}" ]` — preserves `bash quarantine-guard.sh "src/foo.ts"` test invocation in `test-fix-plan-emit.sh:125`.
2. **Stdin from Read tool:** `RAW` = JSON envelope with `.tool_input.file_path` set → jq returns the path → INPUT matches existing grep patterns correctly.
3. **Stdin from Bash tool:** `RAW` = JSON envelope with `.tool_input.command` set → jq returns the command → INPUT contains the command string; the existing grep patterns are substring-tolerant (`/test/`, `.apex/`, etc.) so they match path tokens within the command line — matches argv-style semantics where a tester could pass either a path OR a command.
4. **Empty/malformed envelope:** `jq -e . >/dev/null 2>&1` validates JSON; on failure `INPUT="$RAW"` falls through to opaque-string mode. Empty INPUT → line 31 `[ -z "$INPUT" ] && exit 0` (existing) → no false-block.
5. **Helper-missing degraded install:** `command -v apex_hook_input_raw` guard — if helper failed to source, INPUT remains empty → line 31 exits 0 instead of running grep on undefined. Strictly fail-safer than pre-Phase-8 (which would have set `INPUT="${1:-}"` = empty → same exit 0).
6. **Non-auditor fast-path unchanged:** line 23 still exits 0 immediately when `APEX_ACTIVE_AGENT != "auditor"`. The extraction code only runs for auditor.

### C7 alternative considered & rejected

**Alternative:** use `apex_hook_input_filepath` only (returns `.tool_input.file_path // .tool_input.path`). **Rejected** because: Bash-matcher invocations from Claude Code would return empty `INPUT` → line 31 exits 0 → auditor running `cat /etc/passwd` would NOT be blocked. That re-opens F-004 for the Bash leg of the matcher.

**Alternative:** add a new helper function `apex_hook_input_path_or_command`. **Rejected** because: helper API is stable in R-P8-A; adding functions mid-phase widens blast radius and would require a critic re-pass on the helper. The custom-jq pattern (already documented in helper header for multi-field consumers) is the sanctioned mechanism for hooks with non-canonical needs.

---

## G3 — implementation plan

5 file edits (parallel-safe, independent files):

1. `framework/hooks/path-guard.sh` — replace L16, insert 7 lines above
2. `framework/hooks/quarantine-guard.sh` — replace L28, insert ~15 lines above (C7 special)
3. `framework/hooks/post-write.sh` — replace L11, insert 7 lines above
4. `framework/hooks/ast-kb-check.sh` — replace L11, insert 7 lines above (no existing source line)
5. `framework/hooks/schema-drift.sh` — replace L18, insert 7 lines above

Net delta: ~+8 lines for canonical 4; ~+15 lines for C7. All deny-logic / fix-plan-emit / case-statement code remains byte-identical.

---

## G4 — layer test additions (H-G18..H-G25)

Insert into `test-audit-trail-layer.sh` inside the existing `if [ -f "$HOOKS_DIR/_hook-input.sh" ]` block, between current H-G17 (line ~847) and the closing `else skip H-G0..H-G17` branch (line ~848). Update the skip label to `H-G0..H-G25`.

### Sources-helper rows (5)

Per existing Wave-1 H-G10..H-G14 idiom:

```bash
for HG_PAIR in "H-G18:path-guard.sh" "H-G19:quarantine-guard.sh" \
               "H-G20:post-write.sh" "H-G21:ast-kb-check.sh" \
               "H-G22:schema-drift.sh"; do
  HG_ID="${HG_PAIR%%:*}"
  HG_HOOK="${HG_PAIR#*:}"
  if grep -q "source.*_hook-input.sh" "$HOOKS_DIR/$HG_HOOK" 2>/dev/null; then
    ok "$HG_ID: $HG_HOOK sources _hook-input.sh"
  else
    nope "$HG_ID: $HG_HOOK missing _hook-input.sh source"
  fi
done
```

### Argv+stdin parity probes (3)

Stateless probes only — same idiom as H-G15..H-G17. C7 quarantine-guard parity is NOT included here because it requires the `APEX_ACTIVE_AGENT=auditor` env stateful precondition; verification of C7 is via the existing fix-plan-emit case (argv path) + manual stdin probe in G5 critic. C9 ast-kb-check parity excluded because it is ADVISORY (exit 1) and requires `node`/`python3` runtime — non-deterministic in CI.

```bash
# H-G23: path-guard.sh argv+stdin parity (file_path .env.production).
HG23_ARGV_EXIT=$( bash "$HOOKS_DIR/path-guard.sh" ".env.production" </dev/null >/dev/null 2>&1; echo $? )
HG23_STDIN_EXIT=$( echo '{"tool_input":{"file_path":".env.production"}}' | bash "$HOOKS_DIR/path-guard.sh" >/dev/null 2>&1; echo $? )
if [ "$HG23_ARGV_EXIT" = "2" ] && [ "$HG23_STDIN_EXIT" = "2" ]; then
  ok "H-G23: path-guard.sh argv+stdin parity (both exit 2 on .env.production)"
else
  nope "H-G23: parity broken (argv=$HG23_ARGV_EXIT, stdin=$HG23_STDIN_EXIT)"
fi

# H-G24: post-write.sh argv+stdin parity (file with hardcoded secret).
HG24_TMP=$(mktemp)
echo 'const password = "abcdef1234567890XYZ"' > "$HG24_TMP"
HG24_ARGV_EXIT=$( bash "$HOOKS_DIR/post-write.sh" "$HG24_TMP" </dev/null >/dev/null 2>&1; echo $? )
HG24_STDIN_EXIT=$( echo "{\"tool_input\":{\"file_path\":\"$HG24_TMP\"}}" | bash "$HOOKS_DIR/post-write.sh" >/dev/null 2>&1; echo $? )
rm -f "$HG24_TMP"
if [ "$HG24_ARGV_EXIT" = "2" ] && [ "$HG24_STDIN_EXIT" = "2" ]; then
  ok "H-G24: post-write.sh argv+stdin parity (both exit 2 on hardcoded secret)"
else
  nope "H-G24: parity broken (argv=$HG24_ARGV_EXIT, stdin=$HG24_STDIN_EXIT)"
fi

# H-G25: schema-drift.sh argv+stdin parity (invalid JSON STATE.json).
HG25_TMP=$(mktemp -d)/.apex
mkdir -p "$HG25_TMP"
echo 'not-valid-json{' > "$HG25_TMP/STATE.json"
HG25_ARGV_EXIT=$( bash "$HOOKS_DIR/schema-drift.sh" "$HG25_TMP/STATE.json" </dev/null >/dev/null 2>&1; echo $? )
HG25_STDIN_EXIT=$( echo "{\"tool_input\":{\"file_path\":\"$HG25_TMP/STATE.json\"}}" | bash "$HOOKS_DIR/schema-drift.sh" >/dev/null 2>&1; echo $? )
rm -rf "$(dirname "$HG25_TMP")"
if [ "$HG25_ARGV_EXIT" = "2" ] && [ "$HG25_STDIN_EXIT" = "2" ]; then
  ok "H-G25: schema-drift.sh argv+stdin parity (both exit 2 on invalid JSON)"
else
  nope "H-G25: parity broken (argv=$HG25_ARGV_EXIT, stdin=$HG25_STDIN_EXIT)"
fi
```

**Layer test count target:** 73 → 81 (+5 sources + 3 parity = +8 rows).

---

## G5 — critic R2 success criteria

1. **Migration parity:** each of 5 hooks has the canonical 8-line block (C6/C8/C9/C10) or the 15-line raw-extraction block (C7). No deny-logic / case-statement / fix-plan-emit-call modified.
2. **Argv backward-compat:** 13 argv-style test invocations preserved (4 in test-fix-plan-emit, 3 in test-hooks-security, 6 in test-hooks-blocking).
3. **F-001 family closure (C6, C8, C10):** stdin envelope `{"tool_input":{"file_path":"<deny>"}}` → exit 2 — verified via H-G23/24/25 parity probes.
4. **C7 closure (special):** `APEX_ACTIVE_AGENT=auditor` + stdin envelope with `.tool_input.file_path=src/foo.ts` → exit 2. Manual probe in G5.
5. **No regression:**
   - `test-audit-trail-layer.sh` → 81/81 PASS
   - `test-fix-plan-emit.sh` → 37/37 PASS
   - `test-hooks-security.sh` → 18/18 PASS
   - `test-hooks-blocking.sh` → 12/13 PASS (pre-existing skip, not introduced by Wave 2)
6. **Helper-missing degraded install:** removing `_hook-input.sh` reverts each hook to legacy argv-only behavior; argv tests still pass; stdin path returns empty → fail-safe-to-0.
7. **`bash -n` clean** on all 5 modified hooks.
8. **Commit message safety** per PHASE-8-STATE §4: no literal `rm` / `rm -rf` patterns in commit message body (paraphrase as "destructive-class deletion pattern" if needed).

---

## Ecosystem 10-question gate

1. **What changes** — 5 hooks gain canonical stdin-envelope extraction via shared helper. Closes F-003, F-004, F-008, F-009, F-010.
2. **Who calls / consumes** — Claude Code PreToolUse/PostToolUse runtime (production) + 13 argv-style test invocations (3 test suites).
3. **What does it break** — Nothing if helper is present; degraded-install behavior preserved if helper is missing.
4. **What spec/contract anchors** — `apex-spec.md` § "Hook input-extraction contract" (R-P8-B, landed `0a149e93`).
5. **What tests need updating** — `test-audit-trail-layer.sh` H-G section (+8 rows). No other suite needs updating.
6. **What documentation needs updating** — None at this layer; Phase 8 closure tag will update `AUDIT-TRAIL-STANDARD.md` at the end.
7. **What rollback** — `git revert <wave-2-commit>` reverts all 5 hooks to argv-only; layer test rows revert to skip-block.
8. **What invariants must hold post-change** — Every blocked argv invocation in test suites still exits 2; every blocked stdin envelope also exits 2 (new); non-matching invocations still exit 0.
9. **Where does new logic live** — Helper continues to be SSoT; per-hook diffs are mechanical adapter blocks.
10. **What follow-up landmines** — Wave 3 (grandfathered consolidation) is delicate because it replaces working private extractors; helper API needs no extension for Wave 2 (raw + filepath are sufficient).

---

## Blast radius matrix

| Surface | Wave-2 in isolation | Cumulative Phase 8 |
|---------|---------------------|--------------------|
| `framework/hooks/_hook-input.sh` | unchanged | unchanged (landed in `fd98082d`) |
| `framework/hooks/path-guard.sh` | +8 lines | replaces `${1:-}` callsite |
| `framework/hooks/quarantine-guard.sh` | +15 lines | replaces `${1:-}` callsite (multi-shape) |
| `framework/hooks/post-write.sh` | +8 lines | replaces `${1:-}` callsite |
| `framework/hooks/ast-kb-check.sh` | +8 lines | replaces `${1:-}` callsite |
| `framework/hooks/schema-drift.sh` | +8 lines | replaces `${1:-}` callsite |
| `framework/tests/test-audit-trail-layer.sh` | +8 rows (H-G18..25); skip label updated | layer count 73 → 81 |
| 13 argv test invocations | unchanged behavior | unchanged behavior |
| F-001 family closure | F-003, F-004, F-008, F-009, F-010 closed | 10/10 broken hooks closed (Wave 1 + Wave 2) |
| Remaining open | 5 grandfathered (Wave 3) + methodology (Wave 4) | — |

**Rollback dependency:** none beyond Wave 2 commit itself. Wave 1 commit `626b35fe` is independent.
