# Wave 3 Execution Result

**Executed:** 2026-04-24
**Executor:** Wave Executor (Claude Opus 4.7)
**Source plans:** `WAVES-R2.md` (Wave 3 section), `REMEDIATION-PLAN-R2.md` (R-009, R-001, R-003)

## Summary

| Field | Value |
|-------|-------|
| R-IDs attempted | R-009, R-001, R-003 |
| R-IDs completed successfully | R-009, R-001, R-003 |
| R-IDs failed and reverted | None |
| R-IDs skipped | None |
| Execution order | R-009 → R-001 → R-003 (independent — order chosen by smallest blast radius first) |

**Wave status: PARTIAL** — all three R-IDs landed with every acceptance criterion green, but the two wave-level test-suite failures from the Wave 2 baseline remain (C-4 `micro.md` in `test-wiring.sh`; S-11 `ci-scan` in `test-hooks-security.sh`). Both are documented pre-existing failures unrelated to any Wave 3 change. No revert warranted.

---

## Per-R Details

### R-009 — Mode-based model escalation for test-architect veto decisions

| Field | Value |
|-------|-------|
| Status | DONE |
| Commit | `e005883` |
| Files changed | `framework/apex-model-routing.json` (test-architect entry lines 51–56, 3 additions); `framework/commands/apex/next.md` (line 163: `resolve_model()` gains `mode` param + new precedence rule; line 250: Wave 0 invocation passes mode="phase") |
| Spec anchor | "Cost-awareness as principle, not add-on." (+ "apex-test-architect module with veto power.") |

**Acceptance criteria:**
- [x] **C1** — `jq '.routing["test-architect"].escalate_on_mode.phase'` returns `"sonnet"`
  *Verification:* Direct jq query against `framework/apex-model-routing.json` returns `"sonnet"`.
- [x] **C2** — `resolve_model()` accepts and processes `mode` parameter
  *Verification:* `sed -n '163,170p' framework/commands/apex/next.md` shows signature `resolve_model(agent_type, verify_level, mode)` with new precedence clause `If mode AND routing[agent_type].escalate_on_mode[mode] exists → use that (overrides all — veto decisions must not be cost-downgraded)`.
- [x] **C3** — Wave 0 (phase mode) resolves to sonnet
  *Verification:* Line 250 now reads `Resolve model: resolve_model("test-architect", null, "phase") from apex-model-routing.json.` Passing mode="phase" hits `escalate_on_mode.phase` → `sonnet`.
- [x] **C4** — Step F.5 (task mode, no mode parameter) resolves to haiku (default)
  *Verification:* Line 361 left untouched — `Resolve model: routing["test-architect"] from apex-model-routing.json.` No mode argument → falls through to `.default` → `haiku`.
- [x] **Regression** — `bash framework/scripts/self-test.sh wiring` reports 27/28 (same pre-existing C-4 failure as Wave 2 baseline). `jq '.routing.executor.default'` → `"sonnet"` (other agents unchanged).
- [x] **Spec re-check** — Cost-awareness preserved for non-veto paths (Step F.5 stays on haiku); veto path (Wave 0) correctly escalates to sonnet so high-stakes judgment calls don't run on the smallest model.

**Spec anchor re-verification:** The spec principle "Cost-awareness as principle, not add-on" is honored — cost is considered at every decision point, and the most cost-effective model is chosen when stakes permit. For veto decisions that can block a phase, the safety-critical path escalates (following the same precedence pattern established by `escalate_on_retry`).

**Deviations from execution plan:** Line-number drift only. The plan specified `resolve_model()` at lines 155–162; actual location is lines 163–168 because of Wave 1 R-010's adaptive-gate block at line 134 and Wave 2 R-007's observation-masking comment at line 318. Logic-level execution exactly matches the plan. Also: plan's jq smoke-check used `.agents["test-architect"].escalate_on_mode.phase`, but the actual JSON key is `.routing["test-architect"]`; corrected in verification.

**Unexpected observations:** None beyond the line-number drift above.

---

### R-001 — `security-policy.md` consolidates defense-in-depth mapping

| Field | Value |
|-------|-------|
| Status | DONE |
| Commit | `0f8838f` |
| Files changed | `framework/security-policy.md` (created, 91 lines); `framework/hooks/_security-common.sh` (6-line spec-equivalence block inserted into header, before existing "Sourced by" line) |
| Spec anchor | "Defense-in-Depth Security Layer: `apex-prompt-guard.js`, Path Traversal Prevention, `apex-workflow-guard.js`, CI scanner, `security.cjs` module." |

**Acceptance criteria:**
- [x] **C1** — `security-policy.md` maps all 6 spec-named mechanisms to their .sh equivalents with file paths
  *Verification:* The "Mechanism → Implementation Map" table lists: `apex-prompt-guard.js` → `prompt-guard.sh`; Path Traversal Prevention → `path-guard.sh`; `apex-workflow-guard.js` → `workflow-guard.sh`; CI scanner → `ci-scan.sh`; `security.cjs` module → `_security-common.sh` + 5 guard hooks (distributed); Destructive command blocking → `destructive-guard.sh`.
- [x] **C2** — `_security-common.sh` header explicitly declares itself as the `security.cjs` spec equivalent
  *Verification:* Lines 3–8 of `_security-common.sh` now contain `Spec equivalence: this file + the five individual guard hooks ... collectively implement the security.cjs module described in apex-spec.md (Failure 9 — Defense-in-Depth Security Layer). See framework/security-policy.md for the full mechanism-to-file mapping.`
- [x] **C3** — `grep -c "security.cjs" framework/security-policy.md` returns at least 1
  *Verification:* Returns **4** (header bullet + table row + "Why distributed" paragraph + policy note).
- [x] **Regression** — `bash framework/scripts/self-test.sh hooks-security` reports 16/17 (same pre-existing S-11 `ci-scan` failure as Wave 1/2 baseline). No new failures introduced.
- [x] **Spec re-check** — Reviewer can trace every mechanism named in the spec anchor to a concrete `.sh` file via `security-policy.md`.

**Spec anchor re-verification:** All 6 spec-named mechanisms resolve to a concrete file in `framework/hooks/`, with trigger type and wiring status documented. The `security.cjs` → `_security-common.sh + distributed guards` mapping is now declared both in the policy doc and in the library file's own header, closing the architectural-vs-textual gap.

**Deviations from execution plan:** The plan specified a one-line spec-equivalence comment in `_security-common.sh`. I expanded to a 6-line block because a one-line declaration would have been cryptic without naming the five guard hooks and pointing at the policy doc. Still additive, still in the header (`Sourced by` line and functions below untouched). No scope expansion beyond documentation.

**Unexpected observations:**
- The initial `git status` shows `framework/hooks/_security-common.sh` was *untracked* at Wave 3 start — it was created in an earlier wave but never tracked. The R-001 commit is also the file's first git add. This is a working-tree artifact, not a Wave 3 gap; the file had been sitting on disk since Wave 2 (referenced by `workflow-guard.sh`'s `source "$(dirname "$0")/_security-common.sh"` line).
- [framework/hooks/workflow-guard.sh:4](framework/hooks/workflow-guard.sh#L4) still reads `Hook type: Explicit invocation by /apex:workflow (NOT auto-fired)` — stale after R-006 auto-wired it. File is in R-001's do-not-touch zone. Logged as `NEW-F-W3-001`.

---

### R-003 — `HOOK-CLASSIFICATION.md` catalogs all 29 hooks

| Field | Value |
|-------|-------|
| Status | DONE |
| Commit | `62ba3a4` |
| Files changed | `framework/HOOK-CLASSIFICATION.md` (created, 135 lines) |
| Spec anchor | "Hook system — 24+ hooks" + "Fail-loud, never fail-silent." |

**Acceptance criteria:**
- [x] **C1** — All files from `framework/hooks/` appear in the classification table
  *Verification:* `ls framework/hooks/ \| wc -l` → **29**; `grep -c "^\| \`" framework/HOOK-CLASSIFICATION.md` → **29** (one table row per file). Category totals 6+5+12+6 = 29.
- [x] **C2** — All 11 `settings.json` hooks marked as "auto" with correct matcher
  *Verification:* 6 Auto-PreToolUse rows (`destructive-guard`, `prompt-guard`, `path-guard`, `pre-task-snapshot`, `quarantine-guard`, `workflow-guard`) + 5 Auto-PostToolUse rows (`post-write`, `schema-drift`, `ast-kb-check`, `phantom-check`, `circuit-breaker`) = 11 auto-wired hooks. Matchers transcribed byte-identically from `framework/settings.json`.
- [x] **C3** — `_`-prefixed files marked as "Library — sourced by other hooks"
  *Verification:* The "Library — Sourced (6)" category table includes all six `_`-prefixed files with their provided functions and sourcing hooks. These are explicitly described as "Never invoked directly."
- [x] **C4** — `workflow-guard.sh` correctly reflects its trigger type (auto if R-006 done)
  *Verification:* Listed under "Auto-PreToolUse" with matcher `Read`, annotated "post-R-006 auto-wiring".
- [x] **Regression** — N/A (new file; no existing tests).
- [x] **Spec re-check** — "Hook system — 24+ hooks" — spec's "24+" is comfortably met with 29 files documented, each with trigger type. Fail-loud satisfied: trigger information is now explicit, not implicit.

**Spec anchor re-verification:** Developers can now determine "how does hook X fire?" by consulting one document. For auto-wired hooks, rows reference `settings.json` matchers exactly; for the 12 command-invoked / event-triggered hooks, rows identify the commands or events that invoke them.

**Deviations from execution plan:** The plan stated **28 files** as the target count; the actual current count is **29** because Wave 1 R-005 added `framework/hooks/_date-parse.sh` (bringing library-sourced files from 5 to 6). The document itself notes this explicitly in a "Delta from R-003 original acceptance criterion" paragraph so future readers don't trip on the number. All 29 files are accounted for; the "28" in the plan was a pre-Wave-1 snapshot. See `NEW-F-W3-002` in `NEW-FINDINGS-W3.md`.

The R-003 plan listed 4 trigger types (Auto-PreToolUse, Auto-PostToolUse, Command-Invoked, Library-Sourced). I kept 4 categories but labelled the third "Command-Invoked / Event-Triggered" to accommodate `pre-compact.sh` and `subagent-stop.sh`, which are lifecycle-event hooks (PreCompact / SubagentStop) rather than command-`.md`-invoked in the strict sense. They fit no better in the other three categories, and separating them into a 5th category would have violated the plan's "4 types" guidance. Documented inside the category header so the scope is clear.

**Unexpected observations:**
- `framework/hooks/` contains one Python file (`tdad-impact.py`) alongside 28 `.sh` files. Classification row added with Python-specific annotation.
- `subagent-stop.sh` (stdin-consuming) and `pre-compact.sh` (fires during compaction) are Claude-Code lifecycle-event hooks, not `settings.json`-wired or command-invoked. Classified under "Command-Invoked / Event-Triggered" with the event name called out.

---

## Wave-level verification gate (from `WAVES-R2.md:103-107`)

| Gate check | Result | Details |
|------------|--------|---------|
| **Test suite: `test-wiring.sh`** | ⚠️ PARTIAL — 27/28 | Same pre-existing C-4 (`micro.md has Mission Briefing`) failure as Wave 2 baseline. Not caused by any Wave 3 R-ID. See `NEW-FINDINGS-W2.md` NEW-F-W2-001. |
| **Test suite: `test-hooks-security.sh`** | ⚠️ PARTIAL — 16/17 | Same pre-existing S-11 (`ci-scan detects unpinned GitHub Action`) failure as Wave 1 baseline. Not caused by any Wave 3 R-ID. |
| **Smoke: `jq` returns "sonnet" for test-architect phase mode** | ✅ PASS | `jq '.routing["test-architect"].escalate_on_mode.phase' framework/apex-model-routing.json` → `"sonnet"`. |
| **Smoke: `security-policy.md` maps all 6 mechanisms** | ✅ PASS | Mechanism table lists prompt-guard, path-guard, workflow-guard, ci-scan, `_security-common.sh` + guards (distributed), destructive-guard. |
| **Smoke: `HOOK-CLASSIFICATION.md` lists all hook files** | ✅ PASS | 29 table rows match 29 files under `framework/hooks/`. |
| **Smoke: `_security-common.sh` header declares spec equivalence** | ✅ PASS | `grep "security.cjs" framework/hooks/_security-common.sh` returns match (1 occurrence on the "Spec equivalence" comment block). |
| **Spec anchor: "Cost-awareness as principle"** | ✅ PASS | Veto escalation added; pattern-matching stays cheap. |
| **Spec anchor: "Defense-in-Depth Security Layer"** | ✅ PASS | 6 mechanisms traceable; distributed architecture declared. |
| **Spec anchor: "Hook system — 24+ hooks"** | ✅ PASS | 29 hooks catalogued by trigger type. |
| **Regression: `resolve_model()` defaults unchanged for other agents** | ✅ PASS | `jq '.routing.executor.default'` → `"sonnet"` (unchanged). No other routing entries modified by the commit. |
| **Regression: Step F.5 still resolves test-architect to haiku** | ✅ PASS | Line 361 untouched — passes no mode argument, falls through to `.default` → `haiku`. |
| **Regression: All individual guard hook implementations untouched** | ✅ PASS | `git diff e005883~1 -- framework/hooks/prompt-guard.sh framework/hooks/path-guard.sh framework/hooks/workflow-guard.sh framework/hooks/destructive-guard.sh framework/hooks/quarantine-guard.sh` yields zero lines. |
| **Regression: `settings.json` untouched in this wave** | ✅ PASS | `git diff e005883~1 -- framework/settings.json \| wc -l` returns `0`. |

**Wave status: PARTIAL**

Rationale: All three R-IDs individually meet every acceptance criterion. The wave-level gate's two test-suite failures are both pre-existing and unrelated to any R-009/R-001/R-003 code path. Per executor rule 1, I did not expand scope to fix them — they remain recorded in `NEW-FINDINGS-W2.md` for R3 triage. Per executor rule 5 (binary pass/fail, revert on failure), no revert is warranted: no Wave 3 R-ID caused a failure.

---

## Commits summary

| Commit | R-ID | Files | Insertions |
|---|---|---|---|
| `e005883` | R-009 | 2 | 7 insertions, 3 deletions |
| `0f8838f` | R-001 | 2 (+1 new: `security-policy.md`; first-tracking of `_security-common.sh`) | 137 insertions |
| `62ba3a4` | R-003 | 1 (new: `HOOK-CLASSIFICATION.md`) | 135 insertions |

All three commits follow the required `fix(apex): R-<FindingID> — <short>` conventional format. One commit per R-ID (executor rule 7).

---

## New findings discovered during execution

Written to `NEW-FINDINGS-W3.md`:

1. **NEW-F-W3-001** (P3) — Stale header comment in `framework/hooks/workflow-guard.sh:4` still says "NOT auto-fired" after R-006 auto-wired it. File is in R-001's do-not-touch zone so cannot be corrected this wave.
2. **NEW-F-W3-002** (P3) — R-003 plan acceptance criterion referenced "28 files" but Wave 1 R-005 added `_date-parse.sh`, bringing the count to 29. Plan/reality mismatch is cosmetic (all files are documented) but flagging so R3 audit can update the count.
3. **NEW-F-W3-003** (P3) — `resolve_model()` in `next.md:163` is a narrative/pseudocode block, not executable code. The mode-parameter fix is therefore a documentation/contract change that the AI executing `/apex:next` is expected to honor — Claude Code has no runtime that parses this as real code. Works as designed, but flagging because future automated validation would need a parser for this block.
4. **NEW-F-W3-004** (P2) — `circuit-breaker.sh` continues to emit "No stderr output" blocking errors on every Bash tool invocation (also logged as NEW-F-W2-002 in Wave 2). Non-functional for commit pipeline; noise that should be triaged in R3.

None of these block completion of Wave 3. All three approved R-IDs landed with commits on master and acceptance criteria met.
