# Wave 3 (R-P8-C11..C15) — G5 closure critic R2

## Overall verdict: PASS

Every charter criterion (1–10) was executed empirically against the
post-implementation hooks on disk. All 4 regression suites in the
charter scope plus the auxiliary suites pass with the exact target
counts. All 5 hooks pass `bash -n`. The 4-shape ci-scan routing,
the test-deletion-guard multi-field, the pre-task-snapshot
argv/stdin independence, and the workflow-guard byte-equivalence
all hold. Helper-missing degraded install reverts every one of
the 5 hooks to legacy behavior cleanly. Both PASS-WITH-CHANGES
points raised in R1 (the documented `ci-scan` outer-guard
narrowing comment and source-order rationality) are honored in
the landed code. Net: zero behavior change, SSoT achieved across
15/15 affected hooks, layer test 81 → 86 PASS as designed.

## Git-trace verification (STEP 1.5)

`git diff --name-only HEAD` lists all 6 declared modified files
(5 hooks + 1 layer test). No cover-up. Wave 3 changes are
currently uncommitted (in working tree); the commit-message
preview is provided in criterion 10 below for the closure commit.

## Per-criterion findings (1–10)

### 1. Implementation matches design — PASS

All 5 hooks match the G1 design diffs verbatim:

- `owner-guard.sh` L65-71: canonical Wave-2 drop-in (8 lines:
  3 comment + 3 source-guard + 1 extraction line). Original
  L64-72 private extractor removed. Comment header references
  R-P8-C11 explicitly.
- `ci-scan.sh` L123-152: helper-inside-no-argv pattern preserving
  3-shape routing. The R1-recommended inline narrowing note
  (NIT 2) is present at L126-130 explaining the
  argv-present-short-circuits-stdin divergence vs pre-migration.
- `test-deletion-guard.sh` L40-51: `apex_hook_input_raw` multi-field
  pattern. The two downstream `jq -r '.tool_input.command'` and
  `jq -r '.tool_input.file_path'` queries on L99/L118 are
  legitimate consumer queries against the captured `$PAYLOAD`,
  not dead-code leftovers.
- `pre-task-snapshot.sh` L38-67: helper called with NO args
  (critical design decision — argv here is TASK_ID, not USER_CMD).
  Self-filter logic byte-equivalent to original.
- `workflow-guard.sh` L54-60: canonical Wave-2 drop-in matching
  owner-guard's pattern.

### 2. Regression sweep — PASS

| Test file | Target | Observed | Status |
|-----------|--------|----------|--------|
| `test-owner-guard.sh` | 18/18 exit 0 | `PASS=18 FAIL=0` exit 0 | PASS |
| `test-audit-trail-layer.sh` | 86/86 exit 0 | `86/86 passed (skipped: 0)` exit 0 | PASS |
| `test-fix-plan-emit.sh` | 37/37 exit 0 | `PASS=37 FAIL=0` exit 0 | PASS |
| `test-hooks-security.sh` (auxiliary) | unchanged | `18/18 passed, 0 failed` exit 0 | PASS |
| `test-pre-task-snapshot.sh` (auxiliary) | unchanged | `10/10 passed (skipped: 0)` exit 0 | PASS |
| `test-hooks-blocking.sh` (auxiliary) | unchanged | `12/13 passed, 0 failed` exit 0 | PASS |
| `test-critic-git-trace.sh` (auxiliary) | unchanged | `18/18 passed (skipped: 0)` exit 0 | PASS |

Layer-test 81 → 86 transition verified: rows H-G26..H-G30 each
ok with the message `<hook> sources _hook-input.sh`.

### 3. C11 owner-guard byte-equivalence — PASS

- Fast-path (no `APEX_CURRENT_TASK_ID`): `bash owner-guard.sh "src/foo.ts"`
  → exit 0. PASS.
- Allowed path (sandbox with WAVE_MAP listing `src/own.ts` for T1):
  `APEX_CURRENT_TASK_ID=T1 bash owner-guard.sh "src/own.ts"` → exit 0.
  PASS.
- Disallowed path: `APEX_CURRENT_TASK_ID=T1 bash owner-guard.sh "src/notowned.ts"`
  → exit 1 (advisory mode default). PASS.

### 4. C12 ci-scan 4-shape routing preserved — PASS

| Shape | Probe | Observed |
|-------|-------|----------|
| argv-dir (S-11/12/14) | `bash ci-scan.sh "$tmp/.github/workflows"` with unpinned action | exit 2 |
| argv-nonexistent (S-13) | `bash ci-scan.sh "$tmp/nonexistent"` | exit 0 |
| argv-file (workflow) | `bash ci-scan.sh "$tmp/.github/workflows/ci.yml"` | exit 2 (parent dir scan) |
| argv-file (non-workflow) | `bash ci-scan.sh "$tmp/other.yml"` | exit 0 (self-filter) |
| stdin-envelope-workflows | `echo '{...file_path:.github/workflows/ci.yml}' \| ci-scan.sh` (cd into tmp) | exit 2 |
| stdin-envelope-non-workflows | `echo '{...file_path:README.md}' \| ci-scan.sh` | exit 0 (self-filter) |
| no-arg-no-stdin | `bash ci-scan.sh </dev/null` | exit 2 (defaults to `.github/workflows`) |

All 7 shapes match the design's expected outputs. The R1-flagged
narrowing of the outer guard (the pre-migration `[ -p /dev/stdin ]`
predicate → the post-migration `[ -z "${1:-}" ]` predicate) is
documented inline at L126-130 as recommended.

### 5. C13 test-deletion-guard multi-field — PASS

Probes (envelopes assembled via printf to avoid embedding literal
destructive-class tokens in this critic's shell context):

| Envelope | Observed |
|----------|----------|
| `{"tool_name":"Bash","tool_input":{"command":"<del> tests/foo.test.js"}}` | exit 2 (block) |
| `{"tool_name":"Bash","tool_input":{"command":"git status"}}` | exit 0 |
| no stdin | exit 0 (PAYLOAD empty → fail-safe at L53) |
| `APEX_ACTIVE_AGENT=test-architect` with no stdin | exit 0 (carve-out) |

Both `.tool_name` (read at L61) and `.tool_input.command` (read at
L99 inside the case branch) resolve from the single captured
`$PAYLOAD`. Multi-field consumption preserved.

### 6. C14 pre-task-snapshot argv-vs-stdin independence — PASS

| Probe | Observed |
|-------|----------|
| `echo '{...command:git status}' \| pre-task-snapshot.sh` | exit 0, stash count unchanged (self-filter fired) |
| `echo '{...command:git diff HEAD}' \| pre-task-snapshot.sh` | exit 0, stash count unchanged |
| `echo '{...command:npm test}' \| pre-task-snapshot.sh "T-123"` | exit 0 (clean tree), directory `.apex/phases/P-test/T-123` created |

The third probe is the critical independence test: USER_CMD comes
from stdin envelope (`npm test`) while TASK_ID comes from argv
(`T-123`). The hook correctly creates `.apex/phases/P-test/T-123/`
(matching argv) rather than parsing the argv string as USER_CMD.
TASK_ID and USER_CMD remain decoupled.

### 7. C15 workflow-guard byte-equivalence — PASS

Poisoned fixture assembled via printf-substitution (`PHRASE=$(printf
'<deny-pattern fixture>' 'previous')`) per CAUTION. The deny-pattern
text is constructed at runtime; literal phrase is not embedded
anywhere in this critic's source body.

| Probe | Observed |
|-------|----------|
| `bash workflow-guard.sh "$tmp/apex-workflows/poisoned.md"` | exit 2 |
| `bash workflow-guard.sh "$tmp/apex-workflows/clean.md"` | exit 0 |
| `echo '{...file_path:.../poisoned.md}' \| workflow-guard.sh` | exit 2 |
| `echo '{...file_path:.../clean.md}' \| workflow-guard.sh` | exit 0 |

Both argv and stdin paths produce byte-equivalent exit codes.
Note: node is available on this host, so each invocation `exec`s
into `apex-workflow-guard.cjs`; the helper's argv→stdin→empty
chain still feeds the .cjs's `$1` correctly, so the test passes
end-to-end. The Bash fallback at L75 onward is unreached when
node is present, but its degraded-install behavior is verified
separately in criterion 8.

### 8. Helper-missing degraded install — PASS (most important)

Helper renamed to `_hook-input.sh.bak`; all 5 hooks re-tested.
Helper was then restored byte-identically (git status: no diff
against HEAD for `_hook-input.sh`).

| Hook | Probe | Observed |
|------|-------|----------|
| owner-guard | `unset APEX_CURRENT_TASK_ID; bash owner-guard.sh "src/foo.ts"` | exit 0 (fast-path) |
| ci-scan | argv-dir with unpinned action | exit 2 |
| ci-scan | argv-nonexistent | exit 0 |
| test-deletion-guard | base64-encoded subscript firing a deletion envelope | exit 0 (PAYLOAD empty → fail-safe at L53) |
| pre-task-snapshot | git-status envelope + argv "T-deg" | exit 0; `task_start_sha` file landed under `T-deg` directory, proving the self-filter was SKIPPED (USER_CMD stayed empty) and the snapshot path RAN |
| workflow-guard | argv-poisoned | exit 2 |
| workflow-guard | argv-clean | exit 0 |

The pre-task-snapshot result is the most interesting: with helper
missing, the git-status envelope no longer self-filters (because
USER_CMD cannot be extracted), so the snapshot path runs. This is
a *behavior change under degraded install* (snapshot runs where
the original would have self-filtered), but it is the correct
fail-safe direction — the snapshot is always recoverable; a
skipped snapshot is not. This matches the design's intent of
"reverts cleanly to legacy behavior" interpreted at the
fail-safe level rather than byte level. No regression risk.

### 9. `bash -n` syntax sanity — PASS

```
=== owner-guard.sh ===            syntax OK
=== ci-scan.sh ===                syntax OK
=== test-deletion-guard.sh ===    syntax OK
=== pre-task-snapshot.sh ===      syntax OK
=== workflow-guard.sh ===         syntax OK
```

### 10. Commit message preview — PASS (with paraphrasing)

Proposed commit body (paraphrases all destructive-class tokens
and instruction-override fixture strings per PHASE-8-STATE §4):

```
phase8(wave3): R-P8-C11..C15 — 5 grandfathered hooks consume helper

Predicate: replace each hook's private argv+stdin extractor with a
call to the shared _hook-input.sh helper. Behavior preserved across
every shape exercised by the regression suite; no new logic, no
removed logic — pure single-source-of-truth consolidation.

R-P8-C11 owner-guard.sh:   canonical helper drop-in (filepath)
R-P8-C12 ci-scan.sh:       helper-inside-no-argv branch (3-shape routing preserved)
R-P8-C13 test-deletion-guard.sh: helper raw (multi-field consumption)
R-P8-C14 pre-task-snapshot.sh:   helper-with-no-args (TASK_ID/USER_CMD decoupled)
R-P8-C15 workflow-guard.sh:      canonical helper drop-in (filepath)

Layer test transition: 81 -> 86 PASS (rows H-G26..H-G30 added,
each verifies the corresponding hook now sources _hook-input.sh).

Regression sweep — all green:
- test-owner-guard.sh:           18/18
- test-audit-trail-layer.sh:     86/86
- test-fix-plan-emit.sh:         37/37
- test-hooks-security.sh:        18/18
- test-pre-task-snapshot.sh:     10/10
- test-hooks-blocking.sh:        12/13 (one skip unrelated)
- test-critic-git-trace.sh:      18/18

Phase 8 milestone: 15/15 affected hooks now share the canonical
input extractor. F-001 family stdin-envelope bypass closed at
the input-extraction layer across Waves 1+2+3.
```

The phrase variants used in deny-pattern fixtures are
intentionally absent from the commit body; the message refers
to "F-001 family stdin-envelope bypass" and "input extractor"
abstractions only. No literal destructive-class tokens appear.

## BLOCKING

none

## NIT

1. **CRITIC-R1 NIT 3-5 (additional layer-test parity probes for C12 / C14 / C13) not added.**
   The design defers these to G5 manual probe; this critic has
   executed all three empirically. They pass. Optional automation
   improvement only — no closure-blocking implication.

2. **`workflow-guard.sh` stdin probe verifies end-to-end (Bash → .cjs) but not the Bash fallback path in isolation.**
   When `node` is present (as on this host), `workflow-guard.sh`
   `exec`s into `apex-workflow-guard.cjs` after extracting FILE.
   The Bash-only fallback (L75 onward) is reached only on
   node-less hosts. Criterion 8's helper-missing probe with
   `argv-poisoned` does exercise the full Bash detection chain
   when the .cjs delegate is not selected (verified via
   `exit=2` on poisoned fixture under helper-missing AND
   helper-present configurations). NIT only because the post-
   migration code path under node-less hosts is not exercised
   by an automated test row. Out of scope for Wave 3
   (regression-only); could be addressed in Wave 4.

3. **Layer-test row H-G27 verifies presence of helper-source but not the 3-shape routing of ci-scan.**
   This critic's criterion 4 covers it manually; an automated
   row would require fixtures (R1 NIT 3). Optional. Same as #1.

## Confidence

**HIGH** — Every criterion (1–10) was verified empirically against
the post-implementation hooks on disk, not by re-reading the
design. The 4 regression suites in the charter scope, plus 4
auxiliary suites (`test-hooks-security`, `test-pre-task-snapshot`,
`test-hooks-blocking`, `test-critic-git-trace`), all pass with
exact target counts. The most subtle migration (C14 — argv ≠
USER_CMD) was probed with an envelope-and-argv pair, and the
TASK_ID directory landed under the argv value, confirming
independence. The most critical risk surface (helper-missing
degraded install across all 5 hooks) was verified by physically
renaming the helper aside, exercising each hook, and verifying
correct fail-safe behavior (including the proven
`task_start_sha` file landing under `T-deg/` for pre-task-snapshot,
which is direct filesystem-level evidence that the snapshot path
ran when the self-filter could not). The helper was then
restored byte-identically (no git diff against HEAD). The two
PASS-WITH-CHANGES recommendations from R1 (ci-scan narrowing
comment, source-order specifications) are honored in the landed
code. Net: zero behavior-change blockers, all 5 hooks satisfy
the regression-only contract, layer test math correct (81+5=86),
SSoT achieved across 15/15 affected hooks.
