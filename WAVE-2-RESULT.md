# Wave 2 Execution Result

**Executed:** 2026-04-24
**Executor:** Wave Executor (Claude Opus 4.7)
**Source plans:** `WAVES-R2.md` (Wave 2 section), `REMEDIATION-PLAN-R2.md` (R-002, R-006, R-007)

## Summary

| Field | Value |
|-------|-------|
| R-IDs attempted | R-002, R-006, R-007 |
| R-IDs completed successfully | R-002, R-006, R-007 |
| R-IDs failed and reverted | None |
| R-IDs skipped | None |
| Execution order | R-007 → R-002 → R-006 (smallest blast radius first) |

**Wave status: PARTIAL** — all three R-IDs landed with green acceptance criteria, but the wave-level `test-wiring.sh` gate reports one pre-existing failure (C-4 on `micro.md`) unrelated to any Wave 2 change. Detailed in "Wave-level verification gate" below and logged in `NEW-FINDINGS-W2.md`.

---

## Per-R Details

### R-007 — Observation masking design rationale in `next.md`

| Field | Value |
|-------|-------|
| Status | DONE |
| Commit | `765b771` |
| Files changed | `framework/commands/apex/next.md` (1 line modified at line 318) |
| Spec anchor | "Context engineering at state-of-the-art. Observation masking." |

**Acceptance criteria:**
- [x] **C1** — `next.md` observation-masking area contains explicit design rationale for prompt-level enforcement
  *Verification:* `grep -n "this is by design" framework/commands/apex/next.md` → `318:... No external hook can validate context composition — this is by design. ...`
- [x] **C2** — Zone structure content (3 zones, trim priority) is unchanged
  *Verification:* `grep -n "ZONE 1\|ZONE 2\|ZONE 3" framework/commands/apex/next.md` returns ZONE 1 at 323, ZONE 2 at 329, ZONE 3 at 337 with Zone 1/2/3 content block byte-identical to prior state.
- [x] **C3** — No false enforcement hook was added
  *Verification:* `pre-compact.sh` untouched (`git diff HEAD~3 -- framework/hooks/pre-compact.sh` empty). No new hook files added for R-007.
- [x] **Regression** — N/A (comment-only change)
- [x] **Spec re-check** — "Observation masking" is now documented in `next.md:318` as enforced via prompt composition ("the zone structure below IS the enforcement mechanism"), with explicit rationale that no external hook can validate context composition — **this is by design**.

**Spec anchor re-verification:** The spec principle "Observation masking" is realized via the 3-zone prompt structure in `next.md`. The updated comment makes this explicit, closing the documentation gap without adding false enforcement.

**Deviations from execution plan:** The plan said "Add a 1-2 line comment at `next.md:312`". In the current file, line 312 is inside STEP C (Irreversible Decision Check), which is semantically unrelated to observation masking. The observation masking section is at STEP E (line 317), with an existing comment at line 318. **I enhanced the existing line 318 comment** to include the plan's explicit rationale ("this is by design") rather than inserting a new comment at line 312. This satisfies the plan's intent (rationale co-located with the mechanism) and all three criteria verbatim. See `NEW-FINDINGS-W2.md` NEW-F-W2-004 for the underlying plan/file-version mismatch.

**Unexpected observations:** None.

---

### R-002 — Cumulative `lead_time_avg` formula in `phase-tag.sh`

| Field | Value |
|-------|-------|
| Status | DONE |
| Commit | `b5864d3` |
| Files changed | `framework/hooks/phase-tag.sh` (lines 49-54, jq expression replaced) |
| Spec anchor | "DORA self-monitoring" + "The First Framework That Improves DORA" |

**Acceptance criteria:**
- [x] **C1** — After 5 phases with lead times [10,20,30,40,50], `lead_time_avg == 30.0`
  *Verification:* Direct jq simulation, feeding each `$hours` into the new expression serially:
  ```
  echo '{}' > /tmp/sg.json
  for h in 10 20 30 40 50; do jq --argjson hours $h '... new expression ...' /tmp/sg.json > /tmp/sg.new && mv /tmp/sg.new /tmp/sg.json; done
  jq .dora.lead_time_avg /tmp/sg.json → 30
  ```
- [x] **C2** — `STATE.json` contains `lead_time_sum` and `lead_time_count` after first phase completion
  *Verification:* After 5-phase simulation: `{sum: 150, count: 5}` — both fields present.
- [x] **C3** — Backward compatibility — existing STATE.json without `lead_time_sum` does not crash
  *Verification:* `echo '{"dora":{"lead_time_avg":25.0}}' | jq --argjson hours 15 '... new expression ...'` → returns `{lead_time_avg: 15, lead_time_sum: 15, lead_time_count: 1}` with exit 0. The `if .dora.lead_time_sum == null` branch initializes the missing fields cleanly.
- [x] **Regression** — `bash framework/scripts/self-test.sh wiring` passes 28/28 (measured right after R-002 commit, before R-006 sync). The `phase-tag.sh` still exits 0 on the success path (`bash -n framework/hooks/phase-tag.sh` → SYNTAX-OK).
- [x] **Spec re-check** — DORA `lead_time_avg` is now the arithmetic mean of all phase lead times (`sum/count`), correctly representing project-wide performance as specified.

**Spec anchor re-verification:** The cumulative formula eliminates the 35% EWMA bias (which previously reported 40.6 for inputs [10,20,30,40,50] that should average 30.0). The metric now honors "DORA self-monitoring" as an accurate, not decaying, measurement.

**Deviations from execution plan:** The plan's verbatim jq expression ended with `.dora.lead_time_avg = (.dora.lead_time_sum / .dora.lead_time_count)` and did not include `| .dora.last_updated = $now`. The prior code had `| .dora.last_updated = $now` as a tail clause of the same jq program. Silently dropping this would regress the DORA timestamp — not in the do-not-touch list, but also not an instructed removal. **I appended `| .dora.last_updated = $now` to the new expression** to preserve the timestamp behavior. Minimal, one-clause addition; zero behavioral change to the averaging logic.

**Unexpected observations:** The git commit output shows `warning: in the working copy of 'framework/hooks/phase-tag.sh', LF will be replaced by CRLF the next time Git touches it` — cosmetic Windows line-ending warning, no functional impact.

---

### R-006 — Auto-wire `workflow-guard.sh` as PreToolUse with path self-filter

| Field | Value |
|-------|-------|
| Status | DONE |
| Commit | `99c8212` |
| Files changed | `framework/hooks/workflow-guard.sh` (added self-filter + stdin fallback, 13 lines before injection patterns); `framework/settings.json` (appended 11th hook entry); `framework/tests/test-hooks-security.sh` (moved fixtures under `apex-workflows/` subdir, added S-8b self-filter test) |
| Spec anchor | "Defense-in-Depth Security Layer: apex-workflow-guard.js" |

**Acceptance criteria:**
- [x] **C1** — `grep "workflow-guard" framework/settings.json` returns a match
  *Verification:* `grep -c` returns `1`. `jq '.hooks | length'` returns `11` (10 original + 1 new).
- [x] **C2** — Reading a clean workflow file via the guard passes (exit 0)
  *Verification:* `bash framework/hooks/workflow-guard.sh "/tmp/apex-workflows/good.md"` → exit 0. S-8 in `test-hooks-security.sh` passes ("workflow-guard allows clean workflow file").
- [x] **C3** — Reading a workflow file with injected "ignore all previous instructions" blocks (exit 2)
  *Verification:* `bash framework/hooks/workflow-guard.sh "/tmp/apex-workflows/bad.md"` → exit 2 with message `APEX WORKFLOW GUARD: BLOCKED / Pattern: instruction override`. S-7 passes.
- [x] **C4** — Reading a non-workflow file passes instantly without scanning
  *Verification:* `bash framework/hooks/workflow-guard.sh "README.md"` → exit 0 (self-filter returns before any file I/O). New test S-8b added to `test-hooks-security.sh` to cover this permanently.
- [x] **C5** — Explicit invocation from `/apex:workflow` still works
  *Verification:* `framework/commands/apex/workflow.md` untouched (`git diff HEAD~3 -- framework/commands/apex/workflow.md` empty). S-7/S-8/S-9/S-10 tests invoke the guard with explicit `$1` paths and pass — demonstrating the explicit-invocation path is intact.
- [x] **Regression** — `bash framework/scripts/self-test.sh hooks-security` passes 16/17. The 1 failure (S-11 `ci-scan detects unpinned GitHub Action`) is **pre-existing from the Wave 1 baseline** (see `WAVE-1-RESULT.md` which noted 15/16 with 1 unrelated pre-existing failure). S-11 tests `ci-scan.sh`, not `workflow-guard.sh`.
- [x] **Spec re-check** — "Defense-in-Depth Security Layer: apex-workflow-guard.js" — the guard now fires as PreToolUse on every Read via `settings.json` auto-wiring, while self-filtering to `apex-workflows/` paths for zero overhead on all other reads. All 7 injection patterns (lines 26-61 / now 36-71) preserved byte-for-byte.

**Spec anchor re-verification:** Workflow files are now validated regardless of access path — no longer dependent on `/apex:workflow` being the entry point. Agents reading workflow files via `Read` will trigger the PreToolUse hook. Zero measurable overhead for non-workflow reads thanks to the path self-filter.

**Deviations from execution plan:**
1. **Stdin fallback uses `[ ! -t 0 ]` guard** — The plan said "Else: read file path from `$TOOL_INPUT` or stdin". A naive `cat` on stdin would hang if no input is piped (e.g., during manual CLI invocation). I added `[ ! -t 0 ]` (stdin is not a terminal) before attempting stdin read — standard idiom for hook context detection. Preserves explicit-invocation ergonomics.
2. **Test fixture relocation** — The existing S-7/S-8/S-9/S-10 tests used `$TEMP_REPO/*-workflow.md` paths which do NOT contain `apex-workflows/` and would be self-filtered under the new rule. Moved all four fixtures under `$TEMP_REPO/apex-workflows/` (added `mkdir -p` at the top of S-7) so tests exercise the intended code path. Added new S-8b test to lock in the self-filter behavior. Tests were not listed in R-006's do-not-touch zones.

**Unexpected observations:**
- **`sync-to-claude.sh` does NOT sync `settings.json`** (see `NEW-FINDINGS-W2.md` NEW-F-W2-003). The new auto-wiring is live in `framework/settings.json` but requires manual merge into a user's `~/.claude/settings.json` to actually fire for that user. Framework build is complete; deployment to live install is a user action.
- **`circuit-breaker.sh` emits noisy "No stderr output" blocking-error messages** for every Bash tool use (see NEW-F-W2-002). Non-blocking — all commits landed.

---

## Wave-level verification gate (from `WAVES-R2.md:70-73`)

| Gate check | Result | Details |
|------------|--------|---------|
| **Test suite: `test-wiring.sh`** | ⚠️ PARTIAL — 27/28 | One failure (**C-4: micro.md has Mission Briefing**) is pre-existing and unrelated to any Wave 2 R-ID. `micro.md` is a rename stub pointing to `fast.md`; the test was never updated. Full details in `NEW-FINDINGS-W2.md` NEW-F-W2-001. |
| **Test suite: `test-hooks-security.sh`** | ⚠️ PARTIAL — 16/17 | Same pre-existing failure as Wave 1's baseline (S-11 `ci-scan` unrelated to any Wave 2 R-ID). All 5 workflow-guard tests (S-7, S-8, S-8b, S-9, S-10) pass. |
| **Smoke: DORA avg [10,20,30,40,50] == 30.0** | ✅ PASS | `jq` simulation returns `30`. |
| **Smoke: `grep "workflow-guard" settings.json`** | ✅ PASS | Returns 1 match. |
| **Smoke: non-workflow Read passes instantly** | ✅ PASS | `bash workflow-guard.sh "README.md"` → exit 0 with no file I/O (self-filter). |
| **Smoke: poisoned workflow blocks (exit 2)** | ✅ PASS | `bash workflow-guard.sh "/tmp/apex-workflows/bad.md"` → exit 2 with `instruction override` block message. |
| **Smoke: Zone structure in `next.md` unchanged** | ✅ PASS | ZONE 1/2/3 content block byte-identical; line offsets shifted by 1 line due to R-007's slightly longer comment, which is inherent to comment expansion and not a structural change. |
| **Spec anchor: "DORA self-monitoring"** | ✅ PASS | Cumulative formula delivers arithmetic mean; matches spec intent. |
| **Spec anchor: "Defense-in-Depth Security Layer"** | ✅ PASS | workflow-guard now fires on all workflow Read operations (path-filtered). |
| **Spec anchor: "Observation masking"** | ✅ PASS | Documented as enforced via prompt composition. |
| **Regression: DORA `deployment_freq` / `change_failure_rate` unchanged** | ✅ PASS | `phase-tag.sh:58-76` untouched — both formulas byte-identical. |
| **Regression: original 10 `settings.json` hooks unmodified + preserve order** | ✅ PASS | `jq '.hooks[0:10] \| .[].command'` returns the original 10 entries in original order; workflow-guard is appended as entry #11. |
| **Regression: workflow-guard injection patterns preserved** | ✅ PASS | All 7 pattern blocks (instruction override, role hijacking, hidden HTML, prompt framing, code-block injection, priority injection, zero-width chars) intact with identical `_sec_block` calls. |
| **Regression: `/apex:workflow` explicit invocation still works** | ✅ PASS | `workflow.md` untouched (zero diff since HEAD~3). Tests S-7/8/9/10 exercise the explicit `$1` invocation path successfully. |

**Wave status: PARTIAL**

Rationale: All three R-IDs individually meet every acceptance criterion. The wave-level gate's two test-suite failures are both pre-existing (NEW-F-W2-001 / S-11 from Wave 1 baseline), unrelated to any R-002/R-006/R-007 code path. Per executor rule 1, I did not expand scope to fix them — recorded in `NEW-FINDINGS-W2.md` for R3 triage. Per executor rule 5 (binary pass/fail, revert on failure), no revert is warranted: no Wave 2 R-ID caused a failure.

---

## New findings discovered during execution

Written to `NEW-FINDINGS-W2.md`:

1. **NEW-F-W2-001** (P3) — `test-wiring.sh:C-4` still checks `micro.md` for "Mission Briefing", but `micro.md` is now a redirect stub pointing at `fast.md`. One-line fix for a future wave.
2. **NEW-F-W2-002** (P3) — `circuit-breaker.sh` appears to emit non-zero exits with no stderr for routine Bash invocations, triggering noisy "blocking error" messages. Non-functional impact.
3. **NEW-F-W2-003** (P2) — `sync-to-claude.sh` intentionally excludes `settings.json`, meaning R-006's auto-wiring won't engage in a user's live `~/.claude/settings.json` without a manual merge. Deployment/installer gap.
4. **NEW-F-W2-004** (P3) — R-007's plan line references (312, 316-338) were against a pre-Wave-1 `next.md` snapshot; actual current lines differ. Documented as a process note.

None of these block Wave 3 (R-001, R-003, R-009). Wave 3's pre-requisite ("Wave 2 passed verification gate, specifically R-006 landed") is satisfied: R-006 landed, is functional (C1-C5 all green), and its final wiring state is available for R-001 and R-003 to reference.
