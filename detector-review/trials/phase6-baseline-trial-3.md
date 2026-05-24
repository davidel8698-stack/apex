# APEX Framework Audit — Round 313 (Phase-6 Baseline Trial 3)

**Spec anchor:** `apex-spec.md` (596 lines, baseline lab snapshot).
**Repo root:** `.lab/apex-detector-lab-baseline/`.
**Round:** 313.
**Previous findings:** none (null input).
**Mode:** OBSERVED (test suite ran to completion).

---

## Executive summary

Three CONFIRMED findings: one P0 platform-level delivery breakage of the
spec-mandated workflow library (`apex-workflows/` renamed to
`apex-workflows-DISABLED/` on disk while the tracked git index still
points to the old path → sync silently no-ops; `/apex:workflow` reports
"Workflow library not found"); two P2 fail-silent contract violations
(four spec-named hooks return exit 0 on contract-violating no-payload
input where spec requires "fail-loud, never fail-silent"); one P3
test-suite regression (2 of 72 tests failing).

Coverage map below records bypass and silent-failure probe counts per
hook actually exercised in this audit.

---

## Test-suite evidence (OBSERVED)

Literal from `framework/tests/run-all.sh` summary block:
`passed: 70 failed: 2 skipped: 0 errored: 0` (total 72, 48m 39s wall).
Failed tests: `test-hook-classification.sh`, `test-hooks-cjs.sh`.

---

## Findings

### F-313-001 — `apex-workflows/` library physically renamed to `apex-workflows-DISABLED/`, sync delivers nothing

- **Axis:** 9 (Memory 3-tier + dream-cycle + 4 primitives + workflows)
- **Severity:** P0
- **Status:** CONFIRMED
- **Spec anchor (verbatim):** "`apex-workflows/` כ-library of pre-built recipes (חידוש מ-BMAD): 30+ מתכונים מוכנים … workflow הוא מתכון ידוע עם pre-conditions ו-post-conditions, הרצתו מייצרת phases אוטומטית." (apex-spec.md §2 Forgetting). Also: "`apex-workflows/` library — 30+ מתכונים מוכנים ל-tasks נפוצים. משתמש לא-טכני בוחר מ-menu במקום לתאר מה הוא רוצה." (apex-spec.md §"היכולות הנדרשות").
- **Evidence:**
  - `framework/apex-workflows/` does NOT exist on disk. `framework/apex-workflows-DISABLED/` exists, untracked, with `_index.json` + 30+ recipe `.md` files (verified via `ls` and `_index.json` inspection).
  - Git index still tracks `framework/apex-workflows/_index.json` and 30+ recipe files; `git status --short | grep apex-workflows` reports them all as ` D` (deleted-in-working-tree).
  - `framework/scripts/sync-to-claude.sh:501` calls `copy_tree "$FRAMEWORK_ROOT/apex-workflows" "$CLAUDE_ROOT/apex-workflows"`.
  - `copy_tree` (sync-to-claude.sh:68-79) silently no-ops on missing source: `if [[ ! -d "$src_dir" ]]; then log "skip (missing dir): …"; return; fi`. No exit-non-zero, no surfacing to caller.
  - `framework/commands/apex/workflow.md:12` reads `~/.claude/apex-workflows/_index.json`; on missing-file path emits "Workflow library not found. Run /apex:start to initialize." — misdirects the user to the wrong remediation.
- **Current:** Workflow library is physically present in the repo but under a `-DISABLED` directory name not referenced anywhere; sync delivery is a silent no-op; `/apex:workflow` reports library-missing and instructs the user to run `/apex:start`.
- **Expected:** Per spec, `apex-workflows/` MUST exist as a library with 30+ recipes, delivered to `~/.claude/apex-workflows/`, consumable by `/apex:workflow`.
- **Gap:** Working tree pending a rename (delete-add) that has never been committed; sync delivers nothing; user-facing command is broken.
- **Blast radius:** Whole framework. Removes the entire BMAD-derived workflow-recipe layer that the spec calls out as the primary first-hour usability mechanism for non-technical users ("משתמש לא-טכני בוחר מ-menu"). Axis 4 (first-hour usability) is also degraded.
- **Reproduction:** `ls framework/apex-workflows` → ENOENT; `ls framework/apex-workflows-DISABLED` → present; `bash framework/scripts/sync-to-claude.sh` reports `skip (missing dir): apex-workflows`; no entry written under `~/.claude/apex-workflows/`.
- **Dependencies:** Independent. Not listed in `framework/docs/ACCEPTED-LIMITATIONS.md` as `LIM-NNN` (only LIM-001/-002/-003 exist; none mentions workflows).

### F-313-002 — `_state-update.sh` and `session-log.sh` silent-pass on no-args / no-payload

- **Axis:** 13.b (Silent-failure / Fail-loud falsification) + Axis 11 (State derives from disk / proof-of-process)
- **Severity:** P2
- **Status:** CONFIRMED
- **Spec anchor (verbatim):** "Fail-loud, never fail-silent." (apex-spec.md §"עקרונות העבודה"). Also: "Every file APEX writes is a potential prompt for the next session." and "State derives from disk."
- **Evidence:** Direct probe with no stdin payload and no args:
  - `bash framework/hooks/_state-update.sh` → exit 0, no stderr.
  - `bash framework/hooks/session-log.sh` → exit 0, no stderr.
  - `bash framework/hooks/path-guard.sh` → exit 0, no stderr.
  - `echo 'not-json garbage' | bash framework/hooks/test-deletion-guard.sh` → exit 0, no stderr (malformed JSON is consumed and silently accepted; spec contract for "fail-loud" is broken because the hook treats unparseable payload identically to no payload).
- **Current:** Hooks treat the absent-input branch as a no-op pass with no diagnostic. Same for malformed input on the json-consuming hook.
- **Expected:** "Fail-loud, never fail-silent" requires at least one stderr line announcing the no-payload / unparseable branch (compare circuit-breaker.sh:198 which DOES emit "circuit-breaker: stdin read timed out after Ns; treating as no-payload" — that is the in-spec pattern; the four probed hooks do not follow it).
- **Gap:** Four hooks (at minimum) silently accept the no-payload/garbage branch. The contract violation is invisible to forensics.
- **Blast radius:** Cross-cutting. Any caller that mis-pipes (closed stdin, wrong tool name, jq absent, JSON parse fail) gets PASS instead of a diagnostic in event-log. Hides hook misconfiguration in operational data.
- **Reproduction:** Commands above; reproduce exit code 0 and empty stderr.
- **Dependencies:** Orthogonal to F-313-001.

### F-313-003 — Test-suite regression: `test-hook-classification.sh` and `test-hooks-cjs.sh` failing

- **Axis:** 6 (Test architecture w/ veto) and 12 (30+ core principles enforced — "Schema as contract")
- **Severity:** P3
- **Status:** CONFIRMED
- **Spec anchor:** "Test architecture is its own discipline with veto power." (apex-spec.md §"עקרונות העבודה"). Combined with: "framework/tests/run-all.sh" implicit-canonical regression gate.
- **Evidence:** Literal from run-all.sh output:
  `total: 72 / passed: 70 / failed: 2 / skipped: 0`. Failed:
  `test-hook-classification.sh`, `test-hooks-cjs.sh`.
- **Current:** Two failing tests pass through `run-all.sh` non-blocking (summary recorded, no enforcement gate stops the round).
- **Expected:** Per spec, test architect has veto authority on phase advance. Two reds in the canonical suite should at minimum surface as a finding in the closure report. (Audit performs that surfacing.)
- **Gap:** Failures present in the live regression set with no on-disk disposition in `ACCEPTED-LIMITATIONS.md`.
- **Blast radius:** Localized to two test areas (hook classification taxonomy + .cjs guards). Diagnostic file at `/tmp/tmp.wB1qlrrXnX` per the suite banner.
- **Reproduction:** `bash framework/tests/run-all.sh` (48m wall).
- **Dependencies:** Independent.

---

## Coverage map (13 axes)

| Axis | Coverage | Bypass attempts (axis 13) | Silent-failure probes (axis 13) | Notes |
|------|----------|---------------------------|---------------------------------|-------|
| 1. 9 failure modes | Surveyed | n/a | n/a | Circuit-breaker CHECK 1-4 (no-change, tool-call cap, recurring-error hash, result-fishing) all wired; IMP-031 (thinking-tokens) carries forward as LIM-001 `pending_human`. |
| 2. Dual-mode classifier | Surveyed | n/a | n/a | `_intentional-buggy-recipe.txt` and decision-mode test present; no findings beyond F-313-001 (workflows missing breaks one consumer). |
| 3. Scale-Adaptive Classifier | Surveyed | n/a | n/a | `onboard.md` exists; no finding raised this round. |
| 4. First-hour usability | Surveyed | n/a | n/a | Degraded by F-313-001 (workflow menu unavailable). |
| 5. `/apex:help` natural-language navigator | Surveyed | n/a | n/a | `commands/apex/help.md` exists and lists categories; no finding. |
| 6. Test architecture w/ veto | Surveyed + run | 0 | 0 | F-313-003 (2 reds in canonical suite). |
| 7. Auditor quarantine | Surveyed | 0 | 0 | `agents/auditor.md` present; not probed for write-paths this round (BLIND SPOT). |
| 8. Module ecosystem | Surveyed | 0 | 0 | `_registry.json` documents the "modules as directories not repos" interpretation; not a finding (spec-acknowledged). |
| 9. Memory 3-tier + workflows | Surveyed | n/a | n/a | F-313-001 raised. |
| 10. Defense-in-Depth | Surveyed + probed | 4 | 4 | destructive-guard blocks `git config core.fsmonitor` (IMP-008), `cat /proc/1/mem` (IMP-002), `base64 -d \| bash` (IMP-017); exfil-guard blocks `gist.github.com` (IMP-013). `_state-update.sh`, `session-log.sh`, `path-guard.sh`, `test-deletion-guard.sh` silent-pass on no-payload → F-313-002. |
| 11. State derives from disk / proof-of-process | Surveyed | n/a | included in 4 above | F-313-002 covers state-update silent branch. |
| 12. 30+ core principles enforced | Surveyed | n/a | n/a | "Fail-loud" violated per F-313-002. |
| 13. Adversarial falsification | Executed | bypass_attempts=4 (destructive-guard ×3 + exfil-guard ×1); silent_failure_probes=4 (`_state-update.sh`, `session-log.sh`, `path-guard.sh`, `test-deletion-guard.sh` bad-json) | as left | Coverage deliberately partial — round terminated early at tool-cap; remaining axis-10 hooks not exhaustively probed (BLIND SPOT below). |

---

## Blind spots

1. **Axis-10 hook fleet** — only `destructive-guard.sh`, `exfil-guard.sh`, `test-deletion-guard.sh`, `_state-update.sh`, `session-log.sh`, `path-guard.sh` were directly probed. `prompt-guard.sh`, `sequence-guard.sh`, `owner-guard.sh`, `subagent-guard.sh`, `workflow-guard.sh`, `security.cjs`, `grader-search-guard.sh`, `scratchpad-monitor.sh`, `phantom-check.sh`, `mutation-gate.sh`, `quarantine-guard.sh` were inventoried (present in `framework/hooks/`) but NOT exercised. Spec contract violations possible.
2. **Axis-7 auditor write-path** — `agents/auditor.md` not searched for any code-write affordance.
3. **`/apex:help` runtime behavior** — only the static `.md` definition was read; the conversational routing path was not exercised against representative free-text queries.
4. **`apex-prompt-guard.cjs` / `apex-workflow-guard.cjs`** — settings.json references both with shell-fallback. The `.cjs` files do not exist anywhere in the repo (only `security.cjs` does). Settings.json fallback runs the `.sh` form. Not classified as a finding because the fallback is intentional, but worth a focused probe in a later round to confirm parity.
5. **Round terminated early** — APEX circuit breaker fired (tool-call cap = 400) during axis-13 probing. Remaining probes deferred.

## Spec contradictions

None confirmed this round.

## SPEC-GAP-CANDIDATES

### SGC-313-001: `apex-workflows-DISABLED` naming convention undefined

**File / location:** `framework/apex-workflows-DISABLED/` (working tree, untracked).
**Observation:** A `-DISABLED` directory suffix is used at framework-root level to soft-retire a spec-named library, but the spec, `framework/docs/ACCEPTED-LIMITATIONS.md`, and `framework/docs/MODULE-ECOSYSTEM.md` are all silent on whether `-DISABLED` is a recognised convention, whether sync should warn on its presence, and how it interacts with `git status` deletions.
**Why it is not a P0-P3 finding:** The substantive finding (workflows undelivered) is captured as F-313-001. The naming convention itself is an unanchored stylistic choice — the spec does not require or forbid `-DISABLED` suffixes.
**Suggested spec language (non-binding):** "Soft-retired framework directories MUST be tracked under `framework/docs/ACCEPTED-LIMITATIONS.md` as `LIM-NNN: <directory> soft-retired` before the rename lands on disk; the sync script SHOULD surface any `-DISABLED` sibling of a spec-named directory as a warning."

### SGC-313-002: Silent-pass on no-stdin not contractually banned

**File / location:** `apex-spec.md` §"עקרונות העבודה" line "Fail-loud, never fail-silent."
**Observation:** The "fail-loud" principle is asserted but the spec does not bind it to the specific hook-CLI contract (what an absent stdin envelope, what malformed JSON, what missing `jq` SHOULD do).
**Why it is not a P0-P3 finding:** F-313-002 raises the behavioral gap. SGC raises the spec ambiguity: in the absence of a written hook-CLI contract, multiple readings are defensible. circuit-breaker.sh adopts the loud reading; four other hooks adopt the silent reading; the spec does not arbitrate.
**Suggested spec language (non-binding):** "Every hook MUST emit at least one stderr line on each of (a) no-stdin-payload (b) unparseable JSON (c) missing required dependency. Exit code remains 0 for advisory cases; the diagnostic line is mandatory."

---

AUDIT_COMPLETE: C:/Users/דודאלמועלם/OneDrive - Tiva 13 Engineers/שולחן העבודה/APEX/detector-review/trials/phase6-baseline-trial-3.md | findings=3 | P0=1 P1=0 P2=1 P3=1 | sgc=2
