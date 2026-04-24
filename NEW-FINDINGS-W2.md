# New Findings Discovered During Wave 2 Execution

**Source:** Wave 2 executor (R-002, R-006, R-007) — 2026-04-24
**Status:** Recorded, NOT fixed in this wave (per executor rule 1 — scope-limited).
**Next action:** Carry into next audit round (R3) for disposition.

---

## NEW-F-W2-001 — test-wiring.sh C-4 checks `micro.md` for "Mission Briefing", but `micro.md` is a redirect stub to `/apex:fast`

**Severity:** P3 (test infrastructure inconsistency, not a user-facing defect)

**Evidence:**
- `framework/commands/apex/micro.md` is a 5-line stub:
  ```
  ---
  description: Renamed to /apex:fast. Use /apex:fast instead.
  ---
  ```
- `framework/tests/test-wiring.sh:15-17` asserts `Mission Briefing|10-B|briefing` in `micro.md`:
  ```bash
  for cmd in quick micro spec _debate; do
    assert_contains "$COMMANDS_DIR/${cmd}.md" "Mission Briefing|10-B|briefing" "C-4: ${cmd}.md has Mission Briefing"
  done
  ```
- `grep -c "Mission Briefing\|10-B\|briefing" framework/commands/apex/micro.md` returns `0` → C-4 fails.
- `framework/commands/apex/fast.md` now owns the Mission Briefing (confirmed in skills listing: `apex:fast: Execute trivial task with zero ceremony`).

**Root cause:** When `/apex:micro` was renamed to `/apex:fast`, the rename moved the Mission Briefing content to `fast.md` and stub-ified `micro.md`, but `test-wiring.sh:15` was not updated to match. The test loop still iterates `micro` instead of `fast`.

**Why this surfaced during Wave 2 (not before):** Wave 2 required syncing `framework/` → `~/.claude/` (via `sync-to-claude.sh`) so hook/test changes would be visible to the self-test harness. The sync replaced an older, pre-rename `~/.claude/commands/apex/micro.md` (which still had the briefing) with the current stub. The test was passing in Wave 1's result because Wave 1 did not require a sync. This is a silent test/code desync that has existed since the `micro → fast` rename commit.

**Wave 2 impact:** Wave 2 verification gate reports `test-wiring.sh 27/28 passed, 1 failed` solely due to this item. All R-002, R-006, R-007 acceptance criteria passed independently. None of the three R-IDs touch `micro.md`, `fast.md`, or `test-wiring.sh:15-17`.

**Suggested fix (for R3):** Replace `micro` with `fast` in the `test-wiring.sh:15` loop, OR remove `micro` from the loop entirely (since it's now a redirect stub with no behavior of its own).

**Files that would be touched:** `framework/tests/test-wiring.sh` (one-line change to the `for cmd in ...` loop).

---

## NEW-F-W2-002 — `circuit-breaker.sh` emits `PostToolUse:Bash hook blocking error` with no stderr for every Bash invocation

**Severity:** P3 (noisy but non-blocking — commits still complete, tool exit codes are respected)

**Evidence:** During every single Bash tool call in Wave 2 execution, the harness printed:
```
PostToolUse:Bash hook blocking error from command: "bash ~/.claude/hooks/circuit-breaker.sh": [bash ~/.claude/hooks/circuit-breaker.sh]: No stderr output
```

The tool output itself arrives correctly (exit codes, stdout intact). The hook appears to exit with a non-zero status and no stderr message, which the Claude Code harness reports as "blocking error" even though no actual block happens.

**Root cause (probable, unverified):** `circuit-breaker.sh` may be exiting with a non-zero status in a non-error path (e.g., `set -u` tripping on an unset variable, or a conditional that returns unintentionally), without writing an explanatory stderr line. Need to read the script to confirm.

**Wave 2 impact:** None on the work itself. Noise in the operator console. No commit was blocked.

**Suggested fix (for R3):** Audit `framework/hooks/circuit-breaker.sh` for unconditional non-zero exit paths that emit no stderr. Ensure every non-zero exit writes an explanatory line to stderr (matches "Fail-loud, never fail-silent" spec principle).

**Files that would be touched:** `framework/hooks/circuit-breaker.sh`.

---

## NEW-F-W2-003 — `sync-to-claude.sh` does NOT sync `settings.json`

**Severity:** P2 (defeats auto-wiring of new hooks for users running sync)

**Evidence:** `framework/scripts/sync-to-claude.sh` explicitly excludes `settings.json` from its copy list. R-006 added a new `workflow-guard.sh` PreToolUse entry to `framework/settings.json`. After running `bash framework/scripts/sync-to-claude.sh`, the hook file was copied to `~/.claude/hooks/` but the user's `~/.claude/settings.json` was NOT updated, so the auto-wiring does not actually engage in the user's live Claude Code sessions unless they manually edit their settings.

**Why the sync is scoped this way:** Per the script comment, `settings.json` is considered user-owned, so merging would risk stomping user customizations.

**Wave 2 impact:** Criterion C1 (`grep "workflow-guard" framework/settings.json` returns match) passed against the source-of-truth file as specified by the remediation plan. But in a real user install, the hook won't auto-fire until the user merges the new entry into their `~/.claude/settings.json`. This is a deployment gap, not a framework defect per se, but it means R-006's "Defense-in-Depth" spec anchor is only partially realized — the guard works when wired, but wiring requires a manual user action.

**Suggested fix (for R3):**
- Either: extend `sync-to-claude.sh` to merge (not overwrite) `settings.json` hook entries with a 3-way merge against a last-known-good template.
- Or: document the required manual `settings.json` merge in release notes for any R-ID that adds a hook entry.
- Or: add a standalone `framework/scripts/install-hooks.sh` that idempotently merges the framework's hooks array into the user's `settings.json`.

**Files that would be touched:** `framework/scripts/sync-to-claude.sh` or a new installer script.

---

## NEW-F-W2-004 — REMEDIATION-PLAN-R2.md line references for R-007 are against a pre-Wave-1 file version

**Severity:** P3 (plan-documentation inconsistency)

**Evidence:** R-007 order of operations says: "Add a 1-2 line comment at `next.md:312` clarifying: ..." and "Zone structure (lines 316-338) is unchanged". In the current `framework/commands/apex/next.md`:
- Line 311 is `"🔵 Roundtable complete."` (end of STEP C)
- Line 312 is blank
- Line 317 is `## STEP E: Build Executor Context — Observation Masking Protocol`
- Line 318 is the observation masking comment (target of R-007)
- Lines 322-340 contain the 3-zone structure

Literal line 312 is mid-STEP-C (Irreversible Decision Check), which is semantically unrelated to observation masking. I interpreted the plan's intent (rationale co-located with the mechanism) and enhanced the existing line 318 comment. Documented as a deviation in `WAVE-2-RESULT.md`.

**Why this surfaced:** The plan was likely written against an earlier file snapshot. Wave 1's R-010 fix touched `next.md:134` (much earlier in the file, before line 311), so the shift isn't from Wave 1 — this mismatch pre-dates Wave 1.

**Suggested fix (for R3, if a future plan references `next.md` line numbers):** Use content-addressable references (grep patterns, section headers) instead of raw line numbers when planning edits to long markdown files. Line numbers are fragile across commits.

**Files that would be touched:** Planning/process change — no code file.

---

## Summary

4 new findings, none classified as higher than P2. None directly caused by any R-002 / R-006 / R-007 change. All three Wave 2 R-IDs' individual acceptance criteria passed; only the wave-level gate reports 1 pre-existing test failure (NEW-F-W2-001) surfaced by the required sync step.
