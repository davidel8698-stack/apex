# WAVE 1 (R-P8-C1..C5) — combined G5 closure critic

## Overall verdict: PASS

5 hooks migrated to source `_hook-input.sh`. F-001 closure empirically verified via stdin envelope. All 4 test suites pass at claimed counts. Backward-compat (argv path) preserved. Audit-probe-marker carve-out integrity preserved (FIRST check still runs after extraction).

## Per-criterion findings (1-9)

### 1. Migration pattern parity — PASS

All 5 diffs are byte-shape identical:
- 1 removed line (`COMMAND="${1:-}"`)
- 7 added lines (3 comment lines + 3 source-guard lines + 1 extraction line) = net +6, diff-stat shows 9 insertions / 1 deletion = +8 per hook.
- Comment carries the canonical `# Phase 8 R-P8-CN` header (N = 1..5) and the matching F-001..F-007 reference.

Diff stat (this critic verified independently via `git diff HEAD --stat`):
```
 framework/hooks/destructive-guard.sh   | 9 ++++++++-
 framework/hooks/exfil-guard.sh         | 9 ++++++++-
 framework/hooks/grader-search-guard.sh | 9 ++++++++-
 framework/hooks/sequence-guard.sh      | 9 ++++++++-
 framework/hooks/subagent-guard.sh      | 9 ++++++++-
```

### 2. Source order — PASS

For C1, C2, C3 (the three that already source `_audit-probe-marker.sh`), `_hook-input.sh` is sourced AFTER the marker helper:
- destructive-guard.sh: marker source at L21-23, hook-input source at L27-30, then COMMAND extraction at L32.
- exfil-guard.sh: marker source at L33-35, hook-input source at L40-42, COMMAND extraction at L44.
- sequence-guard.sh: marker source at L34-36, hook-input source at L41-43, COMMAND extraction at L45.

C4 (subagent-guard) and C5 (grader-search-guard) do not have `_audit-probe-marker.sh` to order against — `_hook-input.sh` is the first sourced helper, immediately followed by COMMAND extraction. Correct.

### 3. Backward-compat preserved — PASS (3/3 argv re-runs)

| Command (argv) | Hook | Exit | Block message? |
|----------------|------|------|----------------|
| `rm -rf /`             | destructive-guard | **2** | yes (rm + recursive+force + dangerous target) |
| `rm -rf / --yes`       | subagent-guard    | **2** | yes (auto-yes + destructive family) |
| `find tests -name expected` | grader-search-guard | **2** | yes (grader vocabulary match) |

Argv contract preserved — the `|| printf '%s' "${1:-}"` fallback in the extractor preserves the legacy invocation contract verbatim.

### 4. F-001 closure (the deliverable) — PASS (3/3 stdin re-runs)

Same three commands re-issued via `echo '{"tool_input":{"command":"..."}}' | bash hook.sh`:

| Stdin envelope `.tool_input.command` | Hook | Exit | F-001 closed? |
|--------------------------------------|------|------|---------------|
| `rm -rf /`            | destructive-guard | **2** | **YES** (was 0 pre-Phase-8) |
| `rm -rf / --yes`      | subagent-guard    | **2** | **YES** (was 0 pre-Phase-8) |
| `find tests -name expected` | grader-search-guard | **2** | **YES** (was 0 pre-Phase-8) |

This is the closure predicate. All three return identical block output to the argv path — proving the helper extracts `.tool_input.command` from stdin and the rest of each hook's matching logic is untouched.

### 5. Stateful hooks (exfil-guard, sequence-guard) — PASS

C2 exfil-guard: re-verified by triggering the unconditional public-share deny (independent of failure-count gate):
- `bash exfil-guard.sh "gh gist create secrets.txt" </dev/null` → exit 2 (argv)
- `echo '{"tool_input":{"command":"gh gist create secrets.txt"}}' | bash exfil-guard.sh` → exit 2 (stdin envelope)

Both paths block — proves the helper extracts COMMAND from stdin AND the carve-outs / public-share block code reaches that COMMAND value. The state-gated tier (failure_count >= 5) is structurally identical post-helper; clean-state stdin probe returns exit 0 as expected (state not elevated, no state file in repo cwd).

C3 sequence-guard: clean-state stdin probe returns exit 0. File inspection confirms `COMMAND=$(apex_hook_input_command "$@" 2>/dev/null || printf '%s' "${1:-}")` is present at L45 and the early `[ -z "$COMMAND" ] && exit 0` guard at L46-48 reaches the extracted value (not an empty string under stdin envelope — verified above for exfil-guard with the same extraction line). The window-empty short-circuit at L72-75 means clean-state always exits 0; window-non-empty matching code path is structurally identical to pre-migration.

### 6. No regression — PASS (3/3 supporting test suites)

| Suite | Result | Expected |
|-------|--------|----------|
| `test-fix-plan-emit.sh` | **37/37 PASS** | 37/37 |
| `test-hooks-security.sh` | **18/18 PASS** | 18/18 |
| `test-hooks-blocking.sh` | **12/13 PASS** (1 pre-existing skip, not a regression) | 12/13 |

All three exit 0. The 1 skip in test-hooks-blocking is pre-existing (coverage scan: scratchpad-monitor.sh + subagent-stop-debug.sh untested — not introduced by Wave 1).

### 7. Layer test — PASS

`bash framework/tests/test-audit-trail-layer.sh` → **73/73 passed, skipped 0**, exit 0.

Specifically the H-G10..H-G17 new rows all pass:
- H-G10..H-G14: each of the 5 hooks sources `_hook-input.sh` (sourcing detection)
- H-G15..H-G17: argv+stdin parity (both paths exit 2 for the three blocking hooks C1/C4/C5)

These are the rows that directly assert the Wave 1 deliverable.

### 8. Audit-probe-marker carve-out integrity — PASS

Read order in destructive-guard.sh post-migration:
1. `_fix-plan-emit.sh` sourced (L12-14)
2. `_audit-probe-marker.sh` sourced (L21-23)
3. `_hook-input.sh` sourced (L28-30)
4. `COMMAND=$(apex_hook_input_command ...)` extraction (L32)
5. **`apex_check_audit_probe "$COMMAND"` FIRST check — exit 0 on match** (L38-42)
6. Pattern matching against deny set

Same shape for exfil-guard (L33→L41→L44→L47-51) and sequence-guard (L34→L42→L45→L51-55). Marker check runs BEFORE any deny-pattern grep — Campaign C TP-C2 three-factor protocol is intact post-Phase-8.

### 9. Honesty / commit message — PASS (assuming a single combined Wave 1 commit)

A factually accurate Wave 1 commit message would be:
```
phase8(hooks): R-P8-C1..C5 — wave 1 migration to _hook-input.sh
- 5 broken Bash-matcher hooks migrated from ${1:-} only to apex_hook_input_command "$@"
- Closes F-001 (destructive-guard), F-002 (exfil-guard), F-005 (sequence-guard),
  F-006 (subagent-guard), F-007 (grader-search-guard)
- 8-line additive block per hook; deny-logic unchanged
- Verified: 73/73 layer test (incl. H-G10..H-G17), 37/37 fix-plan-emit,
  18/18 hooks-security, 12/13 hooks-blocking (1 pre-existing skip)
```
Accurate; no behavior change to deny logic; no surface lost; the predicate that closes F-001 is the helper-sourcing plus the stdin path inside `apex_hook_input_command`.

## Per-hook verdict (C1..C5)

| Hook | Verdict | Argv exit | Stdin exit | Sources marker? | Order correct? |
|------|---------|-----------|------------|-----------------|----------------|
| C1 destructive-guard.sh   | **PASS** | 2 (block) | 2 (block) | yes  | marker → hook-input |
| C2 exfil-guard.sh         | **PASS** | 2 (block, public-share) | 2 (block, public-share) | yes  | marker → hook-input |
| C3 sequence-guard.sh      | **PASS** | n/a (state-gated)  | 0 (clean state) | yes  | marker → hook-input |
| C4 subagent-guard.sh      | **PASS** | 2 (block) | 2 (block) | n/a  | hook-input first |
| C5 grader-search-guard.sh | **PASS** | 2 (block) | 2 (block) | n/a  | hook-input first |

## Confidence + rationale

**Confidence: HIGH (9/9 criteria PASS).**

Rationale:
- The migration is purely additive: 8 lines added, 1 line replaced, no existing logic touched. The deny-pattern blocks, splitter, fix-plan emitters, marker carve-out, env-var carve-outs are byte-identical pre/post.
- The F-001 closure predicate is empirically observed end-to-end: stdin envelope `{"tool_input":{"command":"rm -rf /"}}` now produces exit 2 + the same block message that argv `"rm -rf /"` produces. This is the exact pre-Phase-8 → post-Phase-8 behavior diff that the F-001 trial described as the bug.
- No test regression: 73/73 + 37/37 + 18/18 + 12/13 (1 pre-existing skip).
- Helper implementation differs from R-P8-A R2 design (lazy-inside-function vs source-time read) — but with the consumer pattern `COMMAND=$(apex_hook_input_command "$@")` used exactly once per hook in Wave 1, the lazy approach is functionally equivalent and is documented in the helper header. Not a regression risk for Wave 1; flag for Wave 2/3 review if any hook needs multi-field extraction.

**Caveat (non-blocking, observation only):** the Wave 1 migrations are uncommitted working-tree changes. The commits `fd98082d` (R-P8-A helper) and `0a149e93` (R-P8-B spec) are in git history; the 5 hook edits are not yet a commit. This is expected for a pre-commit critic review; orchestrator should land them as a single atomic commit (or 5 sub-commits) with the message shape proposed in §9.
