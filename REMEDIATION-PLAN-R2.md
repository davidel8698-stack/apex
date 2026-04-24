# REMEDIATION PLAN — Round R2

**Plan date:** 2026-04-23
**Planner:** Claude Opus 4.6 (Remediation Planner mode)
**Audit source:** `apex-audit-findings-R2.md` (R2, commit 277e34d)
**Spec anchor:** `apex-spec.md`
**Finding count:** 11 open findings (0 P0, 2 P1, 6 P2, 3 P3)

---

## Remediation R-001

**Linked finding:** F-001 (R2-F-001)
**Severity:** P2
**Spec anchor:** "Defense-in-Depth Security Layer: `apex-prompt-guard.js`, Path Traversal Prevention, `apex-workflow-guard.js`, CI scanner, `security.cjs` module." (apex-spec.md, Failure 9 section)

### Ecosystem analysis

1. **Purpose of this component:** `security.cjs` is specified as a consolidated security module — a single entry point for all security policy enforcement across APEX hooks.

2. **Why here (architectural justification):** The spec envisions a centralized security module that all guard hooks reference. This creates a single source of truth for security policy — update one file, all guards benefit.

3. **Current malfunction:** There is no single consolidated security module. The functionality is distributed across `_security-common.sh` (3 utility functions: `_sec_normalize`, `_sec_pattern_match`, `_sec_block`) and 5 individual guard scripts (`prompt-guard.sh`, `path-guard.sh`, `workflow-guard.sh`, `destructive-guard.sh`, `quarantine-guard.sh`). All security *functions* exist — the gap is architectural (distributed vs. consolidated).

4. **Root cause:** Design decision to use shell scripts (.sh) instead of JavaScript (.js/.cjs). `_security-common.sh` was created as a shared library but does not consolidate all security *policy* — only shared *utilities*. Individual guards define their own patterns independently.

5. **Ideal state per spec:** 6 named security mechanisms all present, with `security.cjs` as a consolidated policy module.

6. **Correct fix approach:** Document `_security-common.sh` as the `security.cjs` equivalent. Create a `security-policy.md` that maps each spec mechanism to its .sh implementation and serves as the authoritative security architecture reference.

7. **Downstream components affected:** `framework/hooks/_security-common.sh`, `framework/hooks/prompt-guard.sh`, `framework/hooks/path-guard.sh`, `framework/hooks/workflow-guard.sh`, `framework/hooks/destructive-guard.sh`, `framework/hooks/quarantine-guard.sh`, `framework/hooks/ci-scan.sh`.

8. **Pre-fix changes required elsewhere:** R-006 (workflow-guard wiring) should be completed first so the security policy document reflects the final wiring state.

9. **Do-not-touch zones:** All individual guard hook implementations — their logic is correct and tested. Only add documentation mapping, do not refactor guard internals.

10. **Non-obvious insights:** The spec names JavaScript files (`security.cjs`), but the framework has zero JavaScript runtime dependencies (documented in `apex-design-notes` concept, visible in SC-001). The fix is documentation + mapping, not code creation. Creating a monolithic `security-policy.sh` would violate the existing distributed architecture that works well.

### Execution plan

**Files to modify:**
- `framework/hooks/_security-common.sh` (header comment — add spec equivalence declaration)

**Files to create:**
- `framework/security-policy.md` (consolidated security architecture map)

**Files that MUST remain untouched:**
- All individual guard .sh files — their logic is correct (reason: no functional gap, only architectural documentation gap)
- `framework/settings.json` — hook wiring is addressed by R-006 separately

**Order of operations:**
1. Create `framework/security-policy.md` mapping all 6 spec mechanisms to their .sh implementations
2. Update `_security-common.sh` header comment to declare spec equivalence: "This file + individual guard hooks collectively implement the security.cjs module described in the APEX spec"
3. Verify: `security-policy.md` lists all 6 mechanisms with file paths and status

**Rollback trigger:** If the security-policy.md creates confusion about which file to edit for security changes (i.e., developers start editing the doc instead of the hooks), remove it.

### Acceptance criteria

- [ ] Criterion 1: `security-policy.md` maps all 6 spec-named mechanisms to their .sh equivalents with file paths
- [ ] Criterion 2: `_security-common.sh` header explicitly declares itself as the `security.cjs` spec equivalent
- [ ] Criterion 3: `grep -c "security.cjs" framework/security-policy.md` returns at least 1
- [ ] Regression check: `bash framework/tests/test-hooks-security.sh` passes
- [ ] Spec re-check: Reviewer can trace every mechanism in spec anchor to a concrete .sh file via security-policy.md

### Dependencies

- **Blocks:** None
- **Blocked by:** R-006 (workflow-guard wiring must land first so security-policy.md reflects correct trigger type)
- **Conflicts with:** None (creates new file, modifies only header comment)

### Risk assessment

- **Blast radius:** low
- **Reversibility:** trivial (documentation only)
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-002

**Linked finding:** F-002 (R2-F-002)
**Severity:** P3
**Spec anchor:** "DORA self-monitoring." and "The First Framework That Improves DORA." (apex-spec.md, branding position 6)

### Ecosystem analysis

1. **Purpose of this component:** DORA `lead_time_avg` tracks the average hours from phase planning to phase completion. It's an informational metric displayed by `/apex:status` and `/apex:milestone-summary`.

2. **Why here (architectural justification):** Computed in `phase-tag.sh` because that hook runs at the exact moment a phase is verified complete (git tag creation). This is the natural measurement point.

3. **Current malfunction:** `phase-tag.sh:50-51` uses `(prev_avg + new_hours) / 2` — an exponentially weighted moving average. After N phases, phase 1 contributes only `1/2^N` to the average. For 10 phases: phase 1 contributes 0.1%. A 5-phase project with lead times [10, 20, 30, 40, 50] gives 40.6 instead of true average 30.0 (35% error).

4. **Root cause:** Implementation shortcut — rolling `(a+b)/2` is simpler than tracking cumulative sum and count, but it's mathematically incorrect for a true average.

5. **Ideal state per spec:** DORA metrics that accurately represent project-wide performance. `lead_time_avg` should equal `total_lead_time / phases_completed`.

6. **Correct fix approach:** Track `lead_time_sum` and `lead_time_count` in STATE.json. Compute `lead_time_avg = lead_time_sum / lead_time_count`. Backward-compatible: if STATE.json has old `lead_time_avg` but no `lead_time_sum`, initialize `lead_time_sum = lead_time_avg` and `lead_time_count = 1`.

7. **Downstream components affected:** `framework/commands/apex/status.md` (reads `.dora.lead_time_avg`), `framework/commands/apex/milestone-summary.md` (reads `.dora`). Both only read — no changes needed there.

8. **Pre-fix changes required elsewhere:** R-005 (cross-platform date parsing) must be completed first — it refactors `phase-tag.sh` date handling. Applying R-002 before R-005 creates merge conflict risk.

9. **Do-not-touch zones:** `phase-tag.sh` lines 56-75 (deployment_freq and change_failure_rate) — those formulas are mathematically correct. `phase-tag.sh` lines 1-35 (tag creation logic) — unrelated to DORA.

10. **Non-obvious insights:** The `lead_time_count` must NOT use `phases_completed` from STATE.json because `phases_completed` includes phases that might not have `PLAN_META.json` (and thus no `created_at` to compute lead time from). The count must track only phases where lead time was actually computed.

### Execution plan

**Files to modify:**
- `framework/hooks/phase-tag.sh` (lines 48-52)

**Files to create:** None

**Files that MUST remain untouched:**
- `framework/commands/apex/status.md` — reads `.dora.lead_time_avg`, format unchanged
- `framework/commands/apex/milestone-summary.md` — same reason

**Order of operations:**
1. In `phase-tag.sh:48-52`, replace the rolling average jq expression with:
   ```
   if .dora.lead_time_sum == null then
     .dora.lead_time_sum = $hours | .dora.lead_time_count = 1
   else
     .dora.lead_time_sum = (.dora.lead_time_sum + $hours) | .dora.lead_time_count = (.dora.lead_time_count + 1)
   end | .dora.lead_time_avg = (.dora.lead_time_sum / .dora.lead_time_count)
   ```
2. Verify with manual calculation: 5 phases → avg must equal arithmetic mean

**Rollback trigger:** If `_state_update` fails due to jq syntax error (the expression is more complex than the original).

### Acceptance criteria

- [ ] Criterion 1: After 5 phases with lead times [10, 20, 30, 40, 50], `lead_time_avg` == 30.0
- [ ] Criterion 2: `STATE.json` contains `lead_time_sum` and `lead_time_count` after first phase completion
- [ ] Criterion 3: Backward compatibility — existing STATE.json without `lead_time_sum` does not crash `phase-tag.sh`
- [ ] Regression check: `bash framework/tests/test-wiring.sh` passes (hook still exits 0 on success)
- [ ] Spec re-check: DORA metrics accurately represent project-wide performance

### Dependencies

- **Blocks:** None
- **Blocked by:** R-005 (both modify `phase-tag.sh` — R-005 refactors date parsing first)
- **Conflicts with:** R-005 (same file: `phase-tag.sh`, overlapping region lines 43-52)

### Risk assessment

- **Blast radius:** low (DORA metrics are informational, not pipeline-blocking)
- **Reversibility:** trivial (revert jq expression)
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-003

**Linked finding:** F-003 (R2-F-003)
**Severity:** P2
**Spec anchor:** "Hook system — 24+ hooks" and "Fail-loud, never fail-silent." (apex-spec.md, capabilities section + principles)

### Ecosystem analysis

1. **Purpose of this component:** A hook classification document maps each hook to its trigger mechanism (auto-wired, command-invoked, manual/CI), enabling developers to understand which hooks fire automatically and which require explicit invocation.

2. **Why here (architectural justification):** The hook system is the primary enforcement layer of APEX. Without a classification document, a developer must cross-reference `settings.json` (10 auto-wired hooks) and grep all 44 command .md files to determine how each of the 28 hooks fires.

3. **Current malfunction:** No classification document exists. Hook trigger types are implicit in code, not explicit in documentation. This violates "Fail-loud, never fail-silent" — if a command forgets to invoke a manual hook, there's no reference to catch the omission.

4. **Root cause:** Missing deliverable — hooks were built incrementally without a central registry.

5. **Ideal state per spec:** All hooks documented with trigger type, matcher, invoking commands, and purpose.

6. **Correct fix approach:** Create `framework/HOOK-CLASSIFICATION.md` with a table classifying each of the 28 hook files by trigger type.

7. **Downstream components affected:** None directly — this is a documentation artifact. But it informs health-check tests and future hook additions.

8. **Pre-fix changes required elsewhere:** R-006 (workflow-guard wiring) should be completed first so the classification document reflects the correct trigger type for `workflow-guard.sh`.

9. **Do-not-touch zones:** All hook .sh files — this remediation is documentation-only. No hook behavior changes.

10. **Non-obvious insights:** There are 28 files in `framework/hooks/`: 5 prefixed with `_` (library/utility: `_require-git.sh`, `_require-jq.sh`, `_security-common.sh`, `_state-read.sh`, `_state-update.sh`), 1 Python file (`tdad-impact.py`), and 22 functional hooks. Of these, 10 are auto-wired in `settings.json`. The remaining 12 are invoked by commands or manually. The classification must capture all 28 files including the `_` prefixed ones (as "library — sourced, not invoked").

### Execution plan

**Files to modify:** None

**Files to create:**
- `framework/HOOK-CLASSIFICATION.md`

**Files that MUST remain untouched:**
- All 28 hook files in `framework/hooks/` — documentation only
- `framework/settings.json` — wiring is addressed by R-006

**Order of operations:**
1. Create `framework/HOOK-CLASSIFICATION.md` with:
   - Header explaining the 4 trigger types: Auto-PreToolUse, Auto-PostToolUse, Command-Invoked, Library-Sourced
   - Full table listing all 28 files with: filename, trigger type, matcher (if auto), invoking commands (if manual), purpose
   - Cross-reference to `settings.json` for auto-wired hooks
2. Verify: count of files in table == `ls framework/hooks/ | wc -l`

**Rollback trigger:** N/A — documentation artifact, no runtime impact.

### Acceptance criteria

- [ ] Criterion 1: All 28 files from `framework/hooks/` appear in the classification table
- [ ] Criterion 2: All 10 `settings.json` hooks are marked as "auto" with correct matcher
- [ ] Criterion 3: `_` prefixed files marked as "Library — sourced by other hooks"
- [ ] Criterion 4: `workflow-guard.sh` correctly reflects its trigger type (auto if R-006 done, or manual-only if not)
- [ ] Regression check: N/A (new file, no existing tests)
- [ ] Spec re-check: "Hook system — 24+ hooks" — document accounts for all hooks with classification

### Dependencies

- **Blocks:** None
- **Blocked by:** R-006 (workflow-guard trigger type depends on R-006 outcome)
- **Conflicts with:** None (creates new file)

### Risk assessment

- **Blast radius:** low (documentation only)
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-004

**Linked finding:** F-004 (R2-F-004)
**Severity:** P1
**Spec anchor:** "apex-test-architect module with veto power." and "Roles must produce typed artifacts." (apex-spec.md, Failure 5 section + principles)

### Ecosystem analysis

1. **Purpose of this component:** `test-architect.md` is the agent prompt for the test architecture specialist. Its `tools:` declaration tells the Claude Code runtime which tools the agent is allowed to use.

2. **Why here (architectural justification):** Tool declarations in agent .md frontmatter are the mechanism Claude Code uses to restrict agent capabilities. This is the information boundary that defines what each agent can and cannot do.

3. **Current malfunction:** `test-architect.md:4` declares `tools: Read, Grep, Glob` (read-only). But `next.md:248` expects it to write `WAVE_0_TEST_MAP.json` and `next.md:358` expects it to write `TEST_PLAN.json`. Without `Write` in its tool list, the agent structurally cannot produce its required artifacts.

4. **Root cause:** The agent was initially designed as "read-only — never writes code," and the tool declaration was set accordingly. But it must write *plan artifacts* (JSON files in `.apex/phases/`), which are not source code.

5. **Ideal state per spec:** "Roles must produce typed artifacts" — the test-architect must be able to write its TEST_PLAN.json and WAVE_0_TEST_MAP.json artifacts.

6. **Correct fix approach:** Add `Write` to the `tools:` declaration. Add an explicit constraint limiting Write usage to `.apex/phases/` plan artifacts only.

7. **Downstream components affected:** `framework/commands/apex/next.md` (invokes test-architect at lines 245-249 and 356-359 — expects output files). No changes needed there; the invocations are already correct.

8. **Pre-fix changes required elsewhere:** None.

9. **Do-not-touch zones:** `test-architect.md` lines 89-95 and 170-175 ("Read-only" constraint sections) — these correctly prohibit writing source code and test files. They need a clarification, not removal. The constraint should read "Source-read-only" or "Never writes source code or test implementations."

10. **Non-obvious insights:** Claude Code runtime may allow agents to write regardless of declared tools (runtime behavior noted in audit blind spot). But the static declaration is the contract — fixing it ensures correctness even if runtime is permissive today. The "Read-only" statements at lines 89-95 and 170-175 specifically say "You NEVER write code, create test files, or modify source" — which is correct. Writing JSON plan artifacts to `.apex/phases/` is not "writing code" or "creating test files." But the `tools:` line is the enforcement mechanism and must include Write.

### Execution plan

**Files to modify:**
- `framework/agents/test-architect.md` (line 4: add Write; lines ~89-95: clarify scope)

**Files to create:** None

**Files that MUST remain untouched:**
- `framework/commands/apex/next.md` — invocations are already correct
- `framework/apex-model-routing.json` — model routing is addressed by R-009

**Order of operations:**
1. Change line 4 from `tools: Read, Grep, Glob` to `tools: Read, Grep, Glob, Write`
2. Add after the tools line or near the existing "Read-only" constraint: "Write is ONLY for `.apex/phases/` plan artifacts (TEST_PLAN.json, WAVE_0_TEST_MAP.json). NEVER write source code, test implementations, or files outside `.apex/`."
3. Verify: `grep "tools:" framework/agents/test-architect.md` includes Write

**Rollback trigger:** If health-check TEST 0h (U-shape audit) fails because the new constraint text changes section structure.

### Acceptance criteria

- [ ] Criterion 1: `grep "tools:" framework/agents/test-architect.md` output includes "Write"
- [ ] Criterion 2: Agent prompt contains explicit Write scope restriction to `.apex/phases/` artifacts only
- [ ] Criterion 3: Existing "NEVER write code" / "NEVER create test files" constraints preserved
- [ ] Regression check: `bash framework/tests/test-wiring.sh` passes
- [ ] Spec re-check: "Roles must produce typed artifacts" — test-architect can now produce TEST_PLAN.json and WAVE_0_TEST_MAP.json

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None (unique file)

### Risk assessment

- **Blast radius:** low (single agent file, additive change)
- **Reversibility:** trivial (revert one line)
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-005

**Linked finding:** F-005 (R2-F-005)
**Severity:** P1
**Spec anchor:** "Multi-platform from day one." (apex-spec.md, principles + branding position 7)

### Ecosystem analysis

1. **Purpose of this component:** Date-to-epoch conversion in hooks that compute time-dependent metrics. `phase-tag.sh` uses it for DORA lead time and deployment frequency. `verify-learnings.sh` uses it for learning staleness detection.

2. **Why here (architectural justification):** Date parsing happens at the hook level because hooks are the measurement points — they fire at specific pipeline events where time calculations are needed.

3. **Current malfunction:** Both files use `date -d` (GNU/Linux) with `date -j -f` (BSD/macOS) fallback. On Windows Git Bash, neither works. The `|| echo ""` fallback means silent failure — DORA metrics and learning staleness checks silently produce no data. This project itself runs on Windows 10.

4. **Root cause:** Initial implementation assumed Linux/macOS only. Windows Git Bash was not tested for `date` compatibility.

5. **Ideal state per spec:** "Multi-platform from day one" — hooks work on Linux, macOS, and Windows Git Bash.

6. **Correct fix approach:** Create a shared `_date-parse.sh` utility with a 4-tier fallback chain: GNU `date -d` → BSD `date -j -f` → Python3 `datetime` → Python2 `datetime`. Source it from both `phase-tag.sh` and `verify-learnings.sh`.

7. **Downstream components affected:** `framework/hooks/phase-tag.sh` (lines 43, 60), `framework/hooks/verify-learnings.sh` (lines 21-24).

8. **Pre-fix changes required elsewhere:** None — this is the foundation fix.

9. **Do-not-touch zones:** `phase-tag.sh` lines 48-52 (DORA formula) — that's R-002's territory. `verify-learnings.sh` lines 26+ (decay logic) — unrelated to date parsing.

10. **Non-obvious insights:** Python3 is available on Windows Git Bash if Python is installed (common for developers). `powershell.exe` is always available on Windows but spawning a PowerShell process per date parse is slow. Python should be the primary Windows fallback. The `NOW_EPOCH=$(date +%s)` pattern (current time) works on all platforms including Windows Git Bash — the issue is only with parsing arbitrary date strings. `verify-learnings.sh:16` uses `NOW_EPOCH=$(date +%s)` which is fine.

### Execution plan

**Files to modify:**
- `framework/hooks/phase-tag.sh` (lines 43, 60 — replace inline date parsing with `parse_epoch` call)
- `framework/hooks/verify-learnings.sh` (lines 20-24 — replace `parse_date_epoch()` with sourced `parse_epoch`)

**Files to create:**
- `framework/hooks/_date-parse.sh` (shared portable date parsing utility)

**Files that MUST remain untouched:**
- `phase-tag.sh` lines 48-52 (DORA formula — R-002's scope)
- `verify-learnings.sh` lines 26+ (decay class logic — unrelated)

**Order of operations:**
1. Create `framework/hooks/_date-parse.sh` with `parse_epoch()` function:
   ```bash
   #!/bin/bash
   # _date-parse.sh — Portable date-to-epoch conversion.
   # Sourced by hooks that need cross-platform date parsing.
   # Fallback chain: GNU date → BSD date → Python3 → Python2
   parse_epoch() {
     local d="$1" fmt="${2:-%Y-%m-%dT%H:%M:%S}"
     date -d "$d" +%s 2>/dev/null && return 0
     date -j -f "$fmt" "${d%%.*}" +%s 2>/dev/null && return 0
     python3 -c "from datetime import datetime; print(int(datetime.strptime('${d%%.*}','$fmt').timestamp()))" 2>/dev/null && return 0
     python -c "from datetime import datetime; import calendar; dt=datetime.strptime('${d%%.*}','$fmt'); print(int(calendar.timegm(dt.timetuple())))" 2>/dev/null && return 0
     echo ""
   }
   ```
2. In `phase-tag.sh`, add `source "$(dirname "$0")/_date-parse.sh"` after line 8
3. Replace line 43: `CREATED_TS=$(parse_epoch "$CREATED_AT")`
4. Replace line 60: `PROJ_TS=$(parse_epoch "$CREATED_AT_PROJ")`
5. In `verify-learnings.sh`, replace lines 20-24 with `source` + `parse_epoch` using format `%Y-%m-%d`
6. Test on Windows: `source _date-parse.sh && parse_epoch "2026-04-23T12:00:00Z"`

**Rollback trigger:** If Python3 is not available on the target Windows environment and the fallback chain still produces empty string.

### Acceptance criteria

- [ ] Criterion 1: `source _date-parse.sh && parse_epoch "2026-04-23T12:00:00Z"` returns a non-empty epoch on Windows Git Bash
- [ ] Criterion 2: Same command returns correct epoch on Linux (GNU date path)
- [ ] Criterion 3: Same command returns correct epoch on macOS (BSD date path)
- [ ] Criterion 4: `phase-tag.sh` and `verify-learnings.sh` both source `_date-parse.sh`
- [ ] Criterion 5: No regression — existing GNU/BSD paths still hit first and return early
- [ ] Regression check: `bash framework/tests/test-hooks-security.sh` passes; `bash framework/tests/test-wiring.sh` passes
- [ ] Spec re-check: "Multi-platform from day one" — date parsing works on Linux, macOS, and Windows

### Dependencies

- **Blocks:** R-002 (R-002 modifies the same file and should apply after this refactor)
- **Blocked by:** None
- **Conflicts with:** R-002 (hard conflict: both modify `phase-tag.sh` lines 43-52 region)

### Risk assessment

- **Blast radius:** medium (touches 2 hooks + creates shared utility)
- **Reversibility:** moderate (revert 3 files)
- **Confidence in fix approach:** high (Python fallback is well-tested pattern)
- **Requires human decision:** NO

---

## Remediation R-006

**Linked finding:** F-006 (R2-F-006)
**Severity:** P2
**Spec anchor:** "Defense-in-Depth Security Layer: ... apex-workflow-guard.js" and "Indirect Prompt Injection through planning artifacts." (apex-spec.md, Failure 9 section)

### Ecosystem analysis

1. **Purpose of this component:** `workflow-guard.sh` scans workflow `.md` files for 7 injection patterns (instruction override, role hijacking, hidden HTML, system prompt framing, code block injection, priority injection, zero-width characters). It's part of the Defense-in-Depth security layer.

2. **Why here (architectural justification):** Workflow files are trusted content loaded into AI context. If poisoned, they become indirect prompt injection vectors. The guard must fire when workflow files are accessed, not only when `/apex:workflow` explicitly invokes it.

3. **Current malfunction:** `workflow-guard.sh` exists and works (63 lines, 7 patterns), but is NOT wired in `settings.json`. It only fires when `/apex:workflow` command explicitly calls `bash ~/.claude/hooks/workflow-guard.sh`. If a workflow file is read directly (e.g., by an agent via `Read`), the guard does not fire.

4. **Root cause:** The hook was built for explicit invocation by `/apex:workflow` and was never added to `settings.json` auto-wiring.

5. **Ideal state per spec:** "Defense-in-Depth" — workflow files validated regardless of how they're accessed.

6. **Correct fix approach:** Add `workflow-guard.sh` as a PreToolUse hook in `settings.json`. The matcher must be scoped to Read operations that target workflow files. However, `workflow-guard.sh` currently takes `$1` as file path — need to verify it can receive the file path from the hook system.

7. **Downstream components affected:** `framework/settings.json` (new hook entry), `framework/hooks/workflow-guard.sh` (may need adaptation for hook context), `framework/commands/apex/workflow.md` (explicit invocation still works).

8. **Pre-fix changes required elsewhere:** Need to understand how `settings.json` PreToolUse hooks receive file path context. Looking at existing hooks: `quarantine-guard.sh` (PreToolUse on Read|Bash) and `path-guard.sh` (PreToolUse on Write|Edit) both receive tool input via stdin. `workflow-guard.sh` must be adapted to the same pattern.

9. **Do-not-touch zones:** `workflow-guard.sh` injection patterns (lines 26-61) — they work correctly. Only the file path extraction mechanism may need adaptation.

10. **Non-obvious insights:** Wiring as PreToolUse on `Read` for ALL files would be too broad and would slow down every Read operation. The hook should check if the file path contains `apex-workflows/` and exit 0 immediately if not. This self-filtering pattern is already used by `quarantine-guard.sh` (checks `APEX_ACTIVE_AGENT`). Also: `workflow-guard.sh` currently reads the file from `$1` path. In PreToolUse hook context, the file path comes from `$TOOL_INPUT` or stdin. The hook needs to extract the path and self-filter.

### Execution plan

**Files to modify:**
- `framework/settings.json` (add hook entry)
- `framework/hooks/workflow-guard.sh` (add self-filtering for non-workflow paths + adapt to hook input mechanism)

**Files to create:** None

**Files that MUST remain untouched:**
- `framework/commands/apex/workflow.md` — explicit invocation still works alongside auto-wiring
- Other hooks in `settings.json` — do not reorder existing entries

**Order of operations:**
1. Modify `workflow-guard.sh` to support both explicit invocation (`$1` path) and hook context (stdin/env path):
   - If `$1` is provided and non-empty: use it (explicit invocation path)
   - Else: read file path from `$TOOL_INPUT` or stdin (hook context)
   - Self-filter: if path does not contain `apex-workflows/`, exit 0 immediately
2. Add to `settings.json` hooks array:
   ```json
   {
     "type": "PreToolUse",
     "matcher": "Read",
     "command": "bash ~/.claude/hooks/workflow-guard.sh"
   }
   ```
3. Test: Read a workflow file — guard should fire. Read a non-workflow file — guard should pass through instantly.

**Rollback trigger:** If the hook slows down Read operations noticeably (the self-filter must be instant — just a path string check before any file I/O).

### Acceptance criteria

- [ ] Criterion 1: `grep "workflow-guard" framework/settings.json` returns a match
- [ ] Criterion 2: Reading a clean workflow file via Read tool passes (exit 0)
- [ ] Criterion 3: Reading a workflow file with injected "ignore all previous instructions" pattern blocks (exit 2)
- [ ] Criterion 4: Reading a non-workflow file (e.g., `README.md`) passes instantly without scanning
- [ ] Criterion 5: Explicit invocation from `/apex:workflow` still works
- [ ] Regression check: `bash framework/tests/test-hooks-security.sh` passes
- [ ] Spec re-check: "Defense-in-Depth Security Layer: apex-workflow-guard.js" — guard fires on all workflow access paths

### Dependencies

- **Blocks:** R-001 (security-policy.md needs final wiring state), R-003 (hook classification needs final trigger type)
- **Blocked by:** None
- **Conflicts with:** None (settings.json is additive; workflow-guard.sh modification is in path extraction, not patterns)

### Risk assessment

- **Blast radius:** medium (affects every Read operation — self-filter must be fast)
- **Reversibility:** trivial (remove settings.json entry)
- **Confidence in fix approach:** medium (hook input mechanism needs verification)
- **Requires human decision:** NO

---

## Remediation R-007

**Linked finding:** F-007 (R2-F-007)
**Severity:** P2
**Spec anchor:** "Context engineering at state-of-the-art. Observation masking." and "Less context, better chosen." (apex-spec.md, capabilities section + principles)

### Ecosystem analysis

1. **Purpose of this component:** Observation masking ensures stale observations (old tool outputs, previous file reads) are replaced per-task rather than accumulated. This is a context engineering technique to keep the AI's working memory fresh and relevant.

2. **Why here (architectural justification):** Observation masking is implemented as a prompt composition pattern in `next.md:311-338` (Step E: Build Executor Context). The 3-zone structure (Stable Prefix, Task Context, Working Memory) defines what goes where and the trim priority order. This is the correct location — context assembly happens in the orchestrator.

3. **Current malfunction:** The 3-zone system is documented as instructions to the AI agent, not enforced by a runtime hook. The AI could theoretically ignore the masking guidance and carry stale observations forward.

4. **Root cause:** Observation masking is fundamentally a prompt-level architectural pattern. The context assembly happens inside the AI's reasoning during `/apex:next` execution. There is no external observation point where a hook could validate "are stale observations removed?" because the hook cannot inspect the AI's internal context window.

5. **Ideal state per spec:** "Observation masking" enforced — stale observations removed from context automatically.

6. **Correct fix approach:** Document observation masking as a prompt-level enforcement pattern (by design, not by gap). The 3-zone structure in `next.md:311-338` IS the enforcement mechanism — it's a structured prompt that the AI follows. Adding a hook would require the hook to parse the AI's context window, which is not technically feasible.

7. **Downstream components affected:** None.

8. **Pre-fix changes required elsewhere:** None.

9. **Do-not-touch zones:** `next.md:311-338` — the zone structure is correct as-is. Do not add pseudo-enforcement that creates false confidence.

10. **Non-obvious insights:** This finding is at the boundary of "spec describes ideal, implementation uses best available mechanism." The spec says "observation masking" but doesn't specify hook-level enforcement. The 3-zone prompt structure IS observation masking — it's just enforced via prompt engineering rather than runtime hooks. A `pre-compact.sh` enhancement could log zone sizes as an audit trail, but cannot enforce masking. Marking as BY-DESIGN with documentation, not WONTFIX — the gap is real but the enforcement mechanism is the correct one for the constraint.

### Execution plan

**Files to modify:**
- `framework/commands/apex/next.md` (add brief comment near line 311 explaining that observation masking is enforced via prompt structure)

**Files to create:** None

**Files that MUST remain untouched:**
- `framework/hooks/pre-compact.sh` — do not add false enforcement
- Zone structure in `next.md:316-338` — correct as-is

**Order of operations:**
1. Add a 1-2 line comment at `next.md:312` clarifying: "Observation masking enforcement: the zone structure below is the enforcement mechanism. Stale observations are replaced by re-reading active_files per-task (Zone 2). No external hook can validate context composition — this is by design."
2. Verify: the zone structure is unchanged

**Rollback trigger:** N/A — single comment addition.

### Acceptance criteria

- [ ] Criterion 1: `next.md:311-312` area contains explicit design rationale for prompt-level enforcement
- [ ] Criterion 2: Zone structure (lines 316-338) is unchanged
- [ ] Criterion 3: No false enforcement hook was added
- [ ] Regression check: N/A (comment only)
- [ ] Spec re-check: "Observation masking" — documented as enforced via prompt composition, which it is

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None

### Risk assessment

- **Blast radius:** low
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-008

**Linked finding:** F-008 (R2-F-008)
**Severity:** P3
**Spec anchor:** "Four primitives: apex/todos/, apex/threads/, apex/seeds/, apex/backlog/." and "Failure produces a fix plan, never a 'go debug it'." (apex-spec.md, Failure 2 + principles)

### Ecosystem analysis

1. **Purpose of this component:** Memory primitive commands (`/apex:thread`, `/apex:plant-seed`, `/apex:add-backlog`) create files in `.apex/threads/`, `.apex/seeds/`, `.apex/backlog/` directories for the 4-primitive memory system.

2. **Why here (architectural justification):** These are user-facing commands that non-technical users invoke. They must be defensive — a "file not found" error with no guidance violates "Failure produces a fix plan, never a 'go debug it'."

3. **Current malfunction:** All three commands write to their respective directories without `mkdir -p`:
   - `thread.md:25`: writes to `.apex/threads/${SLUG}.md` — no mkdir
   - `plant-seed.md:21`: writes to `.apex/seeds/seed-${TIMESTAMP}.md` — no mkdir
   - `add-backlog.md:21`: writes to `.apex/backlog/item-${TIMESTAMP}.md` — no mkdir

4. **Root cause:** Commands assume `/apex:start` (which runs `mkdir -p` for all 10 dirs at line 44) has already been run. If dirs are deleted, moved, or the project was initialized before memory dirs were added to start.md, writes fail.

5. **Ideal state per spec:** Commands are defensive — they ensure directories exist before writing.

6. **Correct fix approach:** Add `mkdir -p .apex/threads/` (or seeds/, backlog/) instruction before the file creation step in each command.

7. **Downstream components affected:** None — these commands are standalone.

8. **Pre-fix changes required elsewhere:** None.

9. **Do-not-touch zones:** The WRITE section content/format of each command — only add mkdir before the write, don't change what's written.

10. **Non-obvious insights:** These are markdown command files (instructions to AI), not bash scripts. The "mkdir" instruction must be expressed as an AI-executable step: "Before writing, ensure the target directory exists: `mkdir -p .apex/threads/`" — the AI will execute this via the Bash tool. The `todos/` directory command is `/apex:todo` which is not listed as having this problem — UNKNOWN whether it has the same gap. Worth checking during implementation but not adding to this R- scope.

### Execution plan

**Files to modify:**
- `framework/commands/apex/thread.md` (add before line 27, before WRITE section)
- `framework/commands/apex/plant-seed.md` (add before line 22, before WRITE section)
- `framework/commands/apex/add-backlog.md` (add before line 22, before WRITE section)

**Files to create:** None

**Files that MUST remain untouched:**
- `framework/commands/apex/start.md` — already creates dirs correctly at line 44

**Order of operations (all 3 are independent, can be done in parallel):**
1. In `thread.md`, add after PARSE INPUT section (before WRITE): `Ensure directory exists: mkdir -p .apex/threads/`
2. In `plant-seed.md`, add before WRITE section: `Ensure directory exists: mkdir -p .apex/seeds/`
3. In `add-backlog.md`, add before WRITE section: `Ensure directory exists: mkdir -p .apex/backlog/`
4. Verify: each command has `mkdir -p` before its file creation step

**Rollback trigger:** N/A — purely defensive addition with no downside.

### Acceptance criteria

- [ ] Criterion 1: `grep "mkdir" framework/commands/apex/thread.md` returns a match
- [ ] Criterion 2: `grep "mkdir" framework/commands/apex/plant-seed.md` returns a match
- [ ] Criterion 3: `grep "mkdir" framework/commands/apex/add-backlog.md` returns a match
- [ ] Criterion 4: Running `/apex:thread` on a project without `.apex/threads/` dir succeeds (directory auto-created)
- [ ] Regression check: N/A (no existing tests for these commands — they are user-facing instructions)
- [ ] Spec re-check: "Failure produces a fix plan, never a 'go debug it'" — commands are now defensive

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None (3 distinct files, no overlap)

### Risk assessment

- **Blast radius:** low
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-009

**Linked finding:** F-009 (R2-F-009)
**Severity:** P2
**Spec anchor:** "apex-test-architect module with veto power." and "Cost-awareness as principle, not add-on." (apex-spec.md, Failure 5 section + principles)

### Ecosystem analysis

1. **Purpose of this component:** Model routing determines which Claude model runs each agent. `apex-model-routing.json` maps agent names to model defaults and escalation rules.

2. **Why here (architectural justification):** Model routing is centralized in `apex-model-routing.json` to enable cost optimization. The `resolve_model()` function in `next.md:157-162` reads this config and applies escalation rules.

3. **Current malfunction:** `apex-model-routing.json:51-53` routes `test-architect` to `haiku` (smallest/cheapest model) for all invocations. But test-architect has veto power — it can block entire phases (Wave 0) or individual tasks (Step F.5). Veto is a high-stakes judgment call. Haiku's judgment on risk profile assessment and coverage adequacy may be less reliable than sonnet.

4. **Root cause:** Cost optimization applied uniformly without considering decision stakes. Haiku is correct for pattern-matching (file existence, directory structure) but veto decisions require judgment (risk assessment, coverage adequacy).

5. **Ideal state per spec:** "Cost-awareness as principle, not add-on" — cost optimization should not compromise critical safety mechanisms. Veto decisions (phase-level) should use a more capable model.

6. **Correct fix approach:** Add mode-based escalation to `apex-model-routing.json`. Phase mode (Wave 0) uses sonnet. Per-task mode (Step F.5) keeps haiku. Update `resolve_model()` in `next.md` to handle `escalate_on_mode`.

7. **Downstream components affected:** `framework/commands/apex/next.md` (lines 155-162: `resolve_model()` function, lines 244: Wave 0 model resolution, lines 355: Step F.5 model resolution).

8. **Pre-fix changes required elsewhere:** None — `resolve_model()` already has escalation precedence logic (lines 159-161). Adding `escalate_on_mode` follows the existing pattern.

9. **Do-not-touch zones:** `apex-model-routing.json` entries for other agents — only modify the `test-architect` entry. `next.md` invocation logic at lines 245-249 and 356-359 — only the model resolution mechanism needs updating, not the invocation itself.

10. **Non-obvious insights:** The `resolve_model()` function currently handles 3 escalation types: `downgrade_on_verify_level`, `escalate_on_level`, `escalate_on_retry`. Adding `escalate_on_mode` is a new pattern. The mode information is already available at invocation sites: line 246 (`mode: "phase"`) and line 356 (no mode, implying "task"). The function signature needs an optional `mode` parameter.

### Execution plan

**Files to modify:**
- `framework/apex-model-routing.json` (lines 51-53: add mode-based escalation)
- `framework/commands/apex/next.md` (lines 155-162: add mode parameter to `resolve_model()`; line 244: pass mode when resolving for Wave 0)

**Files to create:** None

**Files that MUST remain untouched:**
- `framework/agents/test-architect.md` — addressed by R-004 separately
- Other agent entries in `apex-model-routing.json` — only change test-architect

**Order of operations:**
1. Update `apex-model-routing.json` test-architect entry:
   ```json
   "test-architect": {
     "default": "haiku",
     "escalate_on_mode": {
       "phase": "sonnet"
     }
   }
   ```
2. Update `resolve_model()` in `next.md:157-162` to accept optional `mode` parameter:
   ```
   resolve_model(agent_type, verify_level, mode):
     ...existing logic...
     If mode AND routing[agent_type].escalate_on_mode[mode] exists → use that
   ```
3. At `next.md:244` (Wave 0 invocation), pass `mode: "phase"` to `resolve_model`
4. Verify: Wave 0 uses sonnet, Step F.5 uses haiku

**Rollback trigger:** If sonnet costs are prohibitive for the user's project scale.

### Acceptance criteria

- [ ] Criterion 1: `jq '.agents["test-architect"].escalate_on_mode.phase' framework/apex-model-routing.json` returns "sonnet"
- [ ] Criterion 2: `resolve_model()` in `next.md` accepts and processes `mode` parameter
- [ ] Criterion 3: Wave 0 (phase mode) resolves to sonnet
- [ ] Criterion 4: Step F.5 (task mode, no mode parameter) resolves to haiku (default)
- [ ] Regression check: `bash framework/tests/test-wiring.sh` passes
- [ ] Spec re-check: "Cost-awareness as principle, not add-on" — veto decisions use adequate model; non-veto uses cost-optimal model

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** R-010 (soft conflict — both modify `next.md` but in different sections: R-009 touches lines 155-162/244, R-010 touches line 134)

### Risk assessment

- **Blast radius:** low (config change + function signature update)
- **Reversibility:** trivial (revert JSON entry and function change)
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-010

**Linked finding:** F-010 (R2-F-010, carried from R1 F-019)
**Severity:** P3
**Spec anchor:** "Decision gates per 60-90 minutes." (apex-spec.md, UX section)

### Ecosystem analysis

1. **Purpose of this component:** Decision gates are periodic check-ins with the user during long sessions. They prevent runaway execution and give the user agency to pause, continue, or rotate context.

2. **Why here (architectural justification):** Implemented in `next.md:128-153` because `/apex:next` is the orchestration heart — every pipeline iteration passes through it, making it the natural check-in point.

3. **Current malfunction:** `next.md:134` hard-codes `ELAPSED_MINUTES >= 60 AND MINUTES_SINCE_GATE >= 60`. The spec says "60-90 minutes" — implying the interval could be adaptive within this range.

4. **Root cause:** Implementation chose the lower bound (60 min) as a safe default. No mechanism to adapt based on context.

5. **Ideal state per spec:** "Decision gates per 60-90 minutes" — adaptive interval based on project complexity.

6. **Correct fix approach:** Make the gate threshold adaptive based on `STATE.complexity_level`: L1/L2 = 90 min (simpler projects, less interruption), L3 = 75 min, L4 = 60 min (complex projects need more check-ins).

7. **Downstream components affected:** None — the decision gate is self-contained within `next.md`.

8. **Pre-fix changes required elsewhere:** None.

9. **Do-not-touch zones:** `next.md:135-153` (gate behavior after trigger) — only change the threshold comparison at line 134, not what happens when it fires.

10. **Non-obvious insights:** "Per 60-90 minutes" could be interpreted as "somewhere in this range is acceptable" (which 60 satisfies) rather than "must adapt between 60 and 90." The fix is low-risk because the fallback for unknown complexity_level defaults to 60 (no regression from current behavior). Also: `complexity_level` is set during onboarding and stored in STATE.json, so it's available at this point in the pipeline.

### Execution plan

**Files to modify:**
- `framework/commands/apex/next.md` (line 134 area)

**Files to create:** None

**Files that MUST remain untouched:**
- `next.md:135-153` — gate behavior unchanged
- `next.md:128-133` — elapsed time computation unchanged

**Order of operations:**
1. Before line 134, add complexity-based threshold resolution:
   ```
   GATE_INTERVAL = case STATE.complexity_level:
     1, 2 → 90
     3    → 75
     4    → 60
     default → 60
   ```
2. Replace line 134: `If ELAPSED_MINUTES >= 60 AND MINUTES_SINCE_GATE >= GATE_INTERVAL:`
3. Verify: L1 project gates at 90 min, L4 project gates at 60 min

**Rollback trigger:** If users report that 90-minute intervals for L1/L2 projects are too long without check-in.

### Acceptance criteria

- [ ] Criterion 1: L1/L2 complexity projects gate at 90 minutes
- [ ] Criterion 2: L3 complexity projects gate at 75 minutes
- [ ] Criterion 3: L4 complexity projects gate at 60 minutes (no regression)
- [ ] Criterion 4: Default (no complexity_level in STATE) falls back to 60 minutes
- [ ] Regression check: Gate still fires, still shows 3 options, still logs to session-log
- [ ] Spec re-check: "Decision gates per 60-90 minutes" — interval now adapts within spec range

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** R-009 (soft conflict — both modify `next.md` but different sections: R-010 at line 134, R-009 at lines 155-162/244)

### Risk assessment

- **Blast radius:** low (single threshold change)
- **Reversibility:** trivial (revert to hard-coded 60)
- **Confidence in fix approach:** high
- **Requires human decision:** NO

---

## Remediation R-011

**Linked finding:** F-011 (R2-F-011)
**Severity:** P2
**Spec anchor:** "State management hybrid. Markdown + SQLite+FTS5." (apex-spec.md:82)

### Ecosystem analysis

1. **Purpose of this component:** The spec describes the state management architecture. It currently says "SQLite+FTS5" but the implementation uses JSONL+jq.

2. **Why here (architectural justification):** `apex-spec.md` is the single source of truth for what APEX should be. When spec and implementation diverge, the spec must be updated or the implementation changed. In this case, the implementation decision (JSONL+jq) is well-reasoned: zero binary dependencies, human-readable, git-diffable, jq provides sufficient query capability.

3. **Current malfunction:** Spec says "SQLite+FTS5." Implementation uses JSONL+jq. Anyone reading the spec expects SQLite; they find JSONL.

4. **Root cause:** The spec was written during initial design when SQLite+FTS5 was the intended architecture. The implementation chose JSONL+jq for practical reasons (documented in `start.md:76-92`), but the spec was never updated.

5. **Ideal state per spec:** Spec accurately describes the actual state management architecture.

6. **Correct fix approach:** Amend `apex-spec.md` to replace "SQLite+FTS5" with the actual architecture (JSONL+jq), noting SQLite+FTS5 as a documented migration path for when query needs exceed jq capabilities.

7. **Downstream components affected:** None — this is a spec text change, not a code change.

8. **Pre-fix changes required elsewhere:** None.

9. **Do-not-touch zones:** All implementation files (`start.md`, `next.md`, `_state-update.sh`, `_state-read.sh`) — the implementation is correct; only the spec needs updating.

10. **Non-obvious insights:** This is linked to reclassified SC-002 (spec contradiction). Fixing R-011 also resolves SC-002. The spec also mentions "PEP 420 namespace" (reclassified as SC-003/N/A) — while in scope for the spec, that's a separate reclassification (Python concept N/A to markdown/bash). The amendment should focus on state management only, not attempt to clean up all spec artifacts in one change.

### Execution plan

**Files to modify:**
- `apex-spec.md` (line 82 and any other references to "SQLite+FTS5")

**Files to create:** None

**Files that MUST remain untouched:**
- All implementation files — they are correct
- `start.md:76-92` — already documents the JSONL architecture correctly

**Order of operations:**
1. In `apex-spec.md:82`, change "Markdown + SQLite+FTS5" to "Markdown + JSONL+jq (with SQLite+FTS5 migration path when query needs exceed jq)"
2. Search for any other "SQLite" or "FTS5" references in `apex-spec.md` and update consistently
3. Verify: `grep -i sqlite apex-spec.md` returns only the migration path reference

**Rollback trigger:** N/A — spec text amendment.

### Acceptance criteria

- [ ] Criterion 1: `apex-spec.md` no longer claims SQLite+FTS5 as the current state management implementation
- [ ] Criterion 2: JSONL+jq is explicitly named as the current approach
- [ ] Criterion 3: SQLite+FTS5 migration path is mentioned as future option
- [ ] Regression check: N/A (spec text, no tests)
- [ ] Spec re-check: "State management hybrid" — spec now accurately describes implementation

### Dependencies

- **Blocks:** None
- **Blocked by:** None
- **Conflicts with:** None (unique file, independent change)

### Risk assessment

- **Blast radius:** low (spec text only)
- **Reversibility:** trivial
- **Confidence in fix approach:** high
- **Requires human decision:** YES — Confirm that the spec should reflect current implementation (JSONL+jq) rather than the implementation being changed to match spec (build SQLite). This plan assumes spec amendment is correct.

---

## Dependency DAG

```
                    ┌──────────┐
                    │  R-004   │ (P1, test-architect tools)
                    │ Wave 1   │
                    └──────────┘

                    ┌──────────┐      ┌──────────┐
                    │  R-005   │─────>│  R-002   │
                    │ Wave 1   │      │ Wave 2   │
                    │ (P1)     │      │ (P3)     │
                    └──────────┘      └──────────┘
                     phase-tag.sh      phase-tag.sh

                    ┌──────────┐
                    │  R-008   │ (P3, mkdir in 3 commands)
                    │ Wave 1   │
                    └──────────┘

                    ┌──────────┐
                    │  R-011   │ (P2, spec amendment)
                    │ Wave 1   │
                    └──────────┘

                    ┌──────────┐      ┌──────────┐
                    │  R-006   │─────>│  R-001   │
                    │ Wave 2   │      │ Wave 3   │
                    │ (P2)     │      │ (P2)     │
                    └──────────┘  ┌──>└──────────┘
                         │        │
                         │        │   ┌──────────┐
                         └────────┴──>│  R-003   │
                                      │ Wave 3   │
                                      │ (P2)     │
                                      └──────────┘

                    ┌──────────┐
                    │  R-007   │ (P2, observation masking docs)
                    │ Wave 2   │
                    └──────────┘

                    ┌──────────┐
                    │  R-009   │ (P2, test-architect model)
                    │ Wave 2   │
                    └──────────┘
                     next.md (155-162, 244)
                         │ soft conflict
                    ┌──────────┐
                    │  R-010   │ (P3, decision gate interval)
                    │ Wave 2   │
                    └──────────┘
                     next.md (134)
```

**Cycles detected:** None. DAG is acyclic.

### Wave execution plan

| Wave | R-IDs | Rationale |
|------|-------|-----------|
| **Wave 1** | R-004, R-005, R-008, R-011 | Zero dependencies. Includes both P1 fixes. All files are distinct — full parallel execution. |
| **Wave 2** | R-002, R-006, R-007, R-009, R-010 | R-002 depends on R-005 (same file). R-006 is independent but feeds Wave 3. R-009 and R-010 have soft conflict (same file, different sections). |
| **Wave 3** | R-001, R-003 | Documentation capstone. Requires R-006 final state for accuracy. |

---

## Conflict Matrix

Files touched by each R-ID. `W` = writes/modifies. Cells with multiple W entries are conflicts requiring serialization.

| File | R-001 | R-002 | R-003 | R-004 | R-005 | R-006 | R-007 | R-008 | R-009 | R-010 | R-011 |
|------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|
| `phase-tag.sh` | | W | | | W | | | | | | |
| `verify-learnings.sh` | | | | | W | | | | | | |
| `_date-parse.sh` (new) | | | | | W | | | | | | |
| `test-architect.md` | | | | W | | | | | | | |
| `settings.json` | | | | | | W | | | | | |
| `workflow-guard.sh` | | | | | | W | | | | | |
| `next.md` | | | | | | | W | | W | W | |
| `apex-model-routing.json` | | | | | | | | | W | | |
| `thread.md` | | | | | | | | W | | | |
| `plant-seed.md` | | | | | | | | W | | | |
| `add-backlog.md` | | | | | | | | W | | | |
| `apex-spec.md` | | | | | | | | | | | W |
| `_security-common.sh` | W | | | | | | | | | | |
| `security-policy.md` (new) | W | | | | | | | | | | |
| `HOOK-CLASSIFICATION.md` (new) | | | W | | | | | | | | |

**Hard conflicts (same file, overlapping lines — must serialize):**
- `phase-tag.sh`: R-005 (Wave 1) → R-002 (Wave 2). **Resolved by wave ordering.**

**Soft conflicts (same file, different sections — coordinate but can parallel):**
- `next.md`: R-007 (line 312) + R-009 (lines 155-162, 244) + R-010 (line 134). All in different sections. Low risk if applied carefully.

---

## Spec Contradictions

### Contradiction 1: R-004 vs test-architect.md internal language
The agent declares "Read-only" at lines 89-95 and 170-175, but its own output specification says "Write to .apex/phases/..." at lines 59 and 144. The R-004 fix adds `Write` to tools, which contradicts the "Read-only" text. **Resolution:** Clarify "Read-only" to mean "source-code-read-only" — the agent never writes source code, test files, or files outside `.apex/`. It does write plan artifacts. No human decision needed — the clarification is unambiguous.

### Contradiction 2: R-009 vs cost optimization principle
The spec says "Cost-awareness as principle, not add-on." Escalating test-architect from haiku to sonnet for phase mode increases cost. **Resolution:** Not a true contradiction — "cost-awareness as principle" means cost is considered in every decision, not that cheapest is always chosen. Veto decisions are high-stakes; using a more capable model for them IS cost-aware (it prevents costly false positives/negatives). No human decision needed.

### Contradiction 3: R-011 spec amendment vs SC-002
R-011 proposes changing the spec to match implementation (JSONL+jq instead of SQLite+FTS5). SC-002 identified this as a spec contradiction. The fix resolves SC-002 by amending the spec. **HUMAN DECISION REQUIRED:** Confirm direction — amend spec to match implementation, or plan SQLite+FTS5 implementation to match spec? This plan assumes spec amendment. If the decision is to implement SQLite, R-011 becomes a different, much larger remediation.

---

## New findings discovered during planning

1. **`/apex:todo` mkdir gap** — The audit identified `thread.md`, `plant-seed.md`, and `add-backlog.md` as lacking `mkdir -p`. The fourth memory primitive directory is `todos/`. UNKNOWN whether the `/apex:todo` command (or equivalent) has the same gap. Not investigated — out of scope for this R2 remediation. Flag for R3 audit.

2. **`resolve_model()` mode parameter propagation** — R-009 adds `escalate_on_mode` to `resolve_model()`. This is a new escalation type. If other agents later need mode-based escalation, the pattern is now available. No action needed — this is a capability expansion, not a gap.

3. **`_date-parse.sh` Python dependency** — R-005 introduces a Python fallback for Windows date parsing. This creates a soft dependency on Python being installed. On Windows, Python may not be in PATH for Git Bash. The `echo ""` fallback (silent failure) remains as last resort. Consider documenting this dependency in a future onboarding check. Flag for R3.

4. **`workflow-guard.sh` hook input mechanism** — R-006 requires adapting `workflow-guard.sh` to receive file paths from the Claude Code hook system (stdin/env). The exact mechanism needs runtime verification — static analysis shows how other hooks (`quarantine-guard.sh`, `path-guard.sh`) handle this, but the workflow-guard adaptation needs testing. Flag for implementation.
