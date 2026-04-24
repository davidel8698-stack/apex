# WAVES-R2.md — Batch Execution Schedule

**Plan date:** 2026-04-23
**Scheduler:** Claude Opus 4.6 (Batch Scheduler mode)
**Source:** `REMEDIATION-PLAN-R2.md` (11 R-IDs, 0 P0, 2 P1, 6 P2, 3 P3)
**DAG status:** Acyclic, verified. No cycles.

---

## Wave 1

**R-IDs:** R-004, R-005, R-008, R-010

**Rationale for grouping:** All four have zero inbound DAG dependencies (no "blocked by"). They touch completely disjoint file sets, enabling full parallel execution. Both P1 fixes (R-004, R-005) land in Wave 1 for earliest severity reduction. R-010 (P3) is included because it touches `next.md:134` — a file that R-007 (Wave 2) and R-009 (Wave 3) also touch in different sections. Placing R-010 here eliminates a conflict-matrix collision in later waves.

**Independence proof:**
| R-ID | Files touched | Overlap with peers? |
|------|--------------|---------------------|
| R-004 | `test-architect.md` | None |
| R-005 | `_date-parse.sh` (new), `phase-tag.sh`, `verify-learnings.sh` | None |
| R-008 | `thread.md`, `plant-seed.md`, `add-backlog.md` | None |
| R-010 | `next.md` (line 134 only) | None |

No DAG edges between any pair. No shared files. ✓

**Estimated scope:**
- `framework/agents/test-architect.md` — tool declaration + constraint clarification
- `framework/hooks/_date-parse.sh` — new shared utility (portable date parsing)
- `framework/hooks/phase-tag.sh` — replace inline date parsing with `parse_epoch` calls
- `framework/hooks/verify-learnings.sh` — replace inline date parsing with `parse_epoch` calls
- `framework/commands/apex/thread.md` — add `mkdir -p`
- `framework/commands/apex/plant-seed.md` — add `mkdir -p`
- `framework/commands/apex/add-backlog.md` — add `mkdir -p`
- `framework/commands/apex/next.md` — adaptive gate threshold (line 134 area)

**Verification gate:**
- **Test suite:** `bash framework/tests/test-wiring.sh` && `bash framework/tests/test-hooks-security.sh`
- **Smoke test:** `grep "tools:" framework/agents/test-architect.md` includes Write. `source framework/hooks/_date-parse.sh && parse_epoch "2026-04-23T12:00:00Z"` returns non-empty on Windows Git Bash. `grep "mkdir" framework/commands/apex/thread.md` returns match. L4 project gates at 60 min (no regression), L1 project gates at 90 min.
- **Spec anchors re-checked:** R-004 ("Roles must produce typed artifacts"), R-005 ("Multi-platform from day one"), R-008 ("Failure produces a fix plan"), R-010 ("Decision gates per 60-90 minutes")
- **Regression check:** All existing tests pass. `phase-tag.sh` still exits 0. `test-architect.md` "NEVER write code" constraints preserved. Decision gate still fires with 3 options.

**Abort conditions:** If `_date-parse.sh` Python fallback fails on Windows AND the empty-string fallback means DORA metrics silently degrade → revert R-005 and investigate Git Bash Python availability. If `test-wiring.sh` fails after any R-ID → revert that specific R-ID, continue others.

**Pre-requisites:** None. This is the first wave.

---

## Wave 2

**R-IDs:** R-002, R-006, R-007

**Rationale for grouping:** R-002 is blocked by R-005 (Wave 1) — both modify `phase-tag.sh` in overlapping line regions. R-006 is independent but blocks R-001 and R-003 (Wave 3). R-007 is independent. All three touch disjoint files within this wave.

**Independence proof:**
| R-ID | Files touched | Overlap with peers? |
|------|--------------|---------------------|
| R-002 | `phase-tag.sh` (lines 48-52) | None |
| R-006 | `settings.json`, `workflow-guard.sh` | None |
| R-007 | `next.md` (line 312 area) | None |

No DAG edges between R-002↔R-006, R-002↔R-007, R-006↔R-007. No shared files. ✓

**Estimated scope:**
- `framework/hooks/phase-tag.sh` — replace rolling average with cumulative sum/count formula
- `framework/settings.json` — add workflow-guard.sh PreToolUse entry
- `framework/hooks/workflow-guard.sh` — add self-filtering for non-workflow paths + hook input adaptation
- `framework/commands/apex/next.md` — add observation masking design rationale comment (line 312)

**Verification gate:**
- **Test suite:** `bash framework/tests/test-wiring.sh` && `bash framework/tests/test-hooks-security.sh`
- **Smoke test:** Simulate 5 phases with lead times [10,20,30,40,50] → `lead_time_avg` must equal 30.0 (not 40.6). `grep "workflow-guard" framework/settings.json` returns match. Reading a non-workflow file passes instantly. Reading a workflow file with "ignore all previous instructions" blocks (exit 2). Zone structure in `next.md:316-338` unchanged.
- **Spec anchors re-checked:** R-002 ("DORA self-monitoring"), R-006 ("Defense-in-Depth Security Layer"), R-007 ("Observation masking")
- **Regression check:** DORA `deployment_freq` and `change_failure_rate` formulas unchanged. Existing `settings.json` hooks unmodified. `workflow-guard.sh` explicit invocation from `/apex:workflow` still works. Zone structure preserved.

**Abort conditions:** If `workflow-guard.sh` self-filter adds measurable latency to every Read operation → revert R-006 settings.json entry (keep workflow-guard.sh adaptation). If `phase-tag.sh` jq expression fails due to syntax → revert R-002.

**Pre-requisites:** Wave 1 passed verification gate. Specifically: R-005 landed (phase-tag.sh date parsing refactored) before R-002 applies DORA formula fix.

---

## Wave 3

**R-IDs:** R-009, R-001, R-003

**Rationale for grouping:** R-001 and R-003 are both blocked by R-006 (Wave 2) — they are documentation capstones that need R-006's final wiring state to be accurate. R-009 is technically independent but placed here because it touches `next.md` (lines 155-162, 244) — a file already touched by R-007 (Wave 2, line 312) and R-010 (Wave 1, line 134). Separating across waves eliminates all `next.md` conflict-matrix collisions.

**Independence proof:**
| R-ID | Files touched | Overlap with peers? |
|------|--------------|---------------------|
| R-009 | `next.md` (lines 155-162, 244), `apex-model-routing.json` | None |
| R-001 | `_security-common.sh` (header), `security-policy.md` (new) | None |
| R-003 | `HOOK-CLASSIFICATION.md` (new) | None |

No DAG edges between any pair. No shared files. ✓

**Estimated scope:**
- `framework/commands/apex/next.md` — add `mode` parameter to `resolve_model()`, pass mode at Wave 0 invocation
- `framework/apex-model-routing.json` — add `escalate_on_mode` to test-architect entry
- `framework/hooks/_security-common.sh` — header comment declaring spec equivalence
- `framework/security-policy.md` — new file mapping 6 spec mechanisms to .sh implementations
- `framework/HOOK-CLASSIFICATION.md` — new file classifying all 28 hook files by trigger type

**Verification gate:**
- **Test suite:** `bash framework/tests/test-wiring.sh` && `bash framework/tests/test-hooks-security.sh`
- **Smoke test:** `jq '.agents["test-architect"].escalate_on_mode.phase' framework/apex-model-routing.json` returns "sonnet". `security-policy.md` maps all 6 mechanisms. `HOOK-CLASSIFICATION.md` lists all 28 files from `framework/hooks/`. `_security-common.sh` header declares spec equivalence.
- **Spec anchors re-checked:** R-009 ("Cost-awareness as principle, not add-on"), R-001 ("Defense-in-Depth Security Layer"), R-003 ("Hook system — 24+ hooks")
- **Regression check:** `resolve_model()` defaults unchanged for all other agents. Step F.5 still resolves test-architect to haiku. All individual guard hook implementations untouched. `settings.json` untouched in this wave.

**Abort conditions:** If `resolve_model()` mode parameter breaks existing escalation precedence logic → revert R-009 (next.md + model-routing.json). If `HOOK-CLASSIFICATION.md` count doesn't match `ls framework/hooks/ | wc -l` → fix before proceeding.

**Pre-requisites:** Wave 2 passed verification gate. Specifically: R-006 landed (workflow-guard.sh wired in settings.json) so R-001 and R-003 reflect correct trigger types.

---

## Execution Order

**Wave 1 → Wave 2 → Wave 3**

**Justification:**
1. Wave 1 first: Contains both P1 fixes (R-004, R-005) and has zero dependencies. R-005 is the foundation for R-002 (Wave 2). R-010 is placed here to avoid next.md conflicts in later waves.
2. Wave 2 second: R-002 requires R-005 (Wave 1). R-006 feeds R-001 and R-003 (Wave 3). R-007 is independent but grouped here for DAG efficiency.
3. Wave 3 last: Documentation capstones (R-001, R-003) require R-006 final state. R-009 requires separation from R-007/R-010 due to next.md conflict matrix.

**next.md conflict resolution across waves:**
- Wave 1: R-010 (line 134)
- Wave 2: R-007 (line 312)
- Wave 3: R-009 (lines 155-162, 244)

Each wave touches a different section. No concurrent modification risk.

---

## Pending Human Decisions

**R-011 (P2, spec amendment):** HUMAN DECISION REQUIRED — Confirm direction: amend `apex-spec.md` to reflect current implementation (JSONL+jq), or plan SQLite+FTS5 implementation to match spec? R-011 is excluded from all waves until this decision is made. Once decided, it can be added to any future wave as a standalone item (touches only `apex-spec.md`, no conflicts).

---

## Deferred

None. All 10 approved R-IDs (excluding R-011 pending human decision) are scheduled across 3 waves.

---

## Completion Criterion Verification

| R-ID | Status | Wave |
|------|--------|------|
| R-001 | Scheduled | Wave 3 |
| R-002 | Scheduled | Wave 2 |
| R-003 | Scheduled | Wave 3 |
| R-004 | Scheduled | Wave 1 |
| R-005 | Scheduled | Wave 1 |
| R-006 | Scheduled | Wave 2 |
| R-007 | Scheduled | Wave 2 |
| R-008 | Scheduled | Wave 1 |
| R-009 | Scheduled | Wave 3 |
| R-010 | Scheduled | Wave 1 |
| R-011 | **Pending human decision** | — |

All approved R-IDs assigned to a wave or explicitly marked as pending. No wave contains internal conflicts. Wave order is consistent with DAG. ✓
