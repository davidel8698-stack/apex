# APEX Gaps Master Document — 2026-04-10

> **Purpose.** Single source of truth for every known gap in APEX framework, end-to-end. Generated from comprehensive review of: AUDIT-2026-04-09 (original 59 findings), Rounds 3.0/3.1/3.2 closures, CHECKPOINT-FINDINGS-2026-04-10 (runtime checkpoint), and meta-discoveries surfaced during execution.
>
> **How to use.** Each gap entry follows a fixed structure: source, status, impact, verification method, proposed fix (with explicit critique invitation), and post-fix validation. Entries are ordered by intended remediation round, not severity.
>
> **Critique invitation.** Every "Proposed fix" section is marked **OPEN FOR CRITIQUE**. The fix described is one path forward, not the only path. Better ideas welcome, especially from agents reading this document during execution rounds. The author of these proposals is fallible — Round 3.2's Pattern-Echo Hallucination is a documented case of an "obvious" fix that was wrong because it duplicated an already-applied earlier fix. Read carefully, verify against current code, propose alternatives.

---

## Table of Contents

- [Part 1 — Cross-Cutting Themes](#part-1--cross-cutting-themes)
- [Part 2 — Round 3.3 Candidates: Environment & Phase Verification](#part-2--round-33-candidates-environment--phase-verification)
- [Part 3 — Round 3.4 Candidates: Schemas & Mutation Testing](#part-3--round-34-candidates-schemas--mutation-testing)
- [Part 4 — Round 3.5 Candidates: UX Consistency](#part-4--round-35-candidates-ux-consistency)
- [Part 5 — New Runtime Findings (Checkpoint 2026-04-10)](#part-5--new-runtime-findings-checkpoint-2026-04-10)
- [Part 6 — Round 3.2 Pending Validations](#part-6--round-32-pending-validations)
- [Part 7 — Anti-Pattern Catalog Candidates](#part-7--anti-pattern-catalog-candidates)
- [Part 8 — Category B: Technical Debt Backlog](#part-8--category-b-technical-debt-backlog)
- [Part 9 — Minor Observations & Cosmetic Items](#part-9--minor-observations--cosmetic-items)
- [Part 10 — Recommended Sequencing](#part-10--recommended-sequencing)
- [Index of All Gap IDs](#index-of-all-gap-ids)

---

## Part 1 — Cross-Cutting Themes

These are not single gaps but patterns that affect how every other gap should be approached. Read this section first, before any specific entry.

### Theme 1 · Audit Reports Are Not Self-Validating

**The pattern.** AUDIT-2026-04-09 was a 59-finding static analysis pass that we treated as authoritative. Round 3.1 discovered the audit was wrong about critic/verifier presence in routing (claimed missing, were actually present). Round 3.2 Pattern-Echo Discovery propagated a similar error inside the round itself (claimed phase-tag.sh needed `_require-jq.sh` source when it already had it from Round 2).

**Implication for every entry below.** When acting on a gap from this document, the first step is **always** to verify the gap still exists by reading the current file content. Do not trust line numbers, do not trust "the audit says X". Read the file, confirm the issue, then act. If the gap has already been silently fixed by an earlier round, mark it closed and move on.

**Operational rule.** Every "How to verify" section in this document includes a re-read step. This is not redundancy — it is the lesson of Pattern-Echo Hallucination, baked into every entry.

---

### Theme 2 · OneDrive Is a Hostile Filesystem for `.apex/`

**The pattern.** During the 2026-04-10 checkpoint, three separate write-conflict and zero-byte-read incidents occurred on `.apex/STATE.json` of Shield. Root cause: the project lives on `OneDrive - Tiva 13 Engineers/...`, and OneDrive's sync agent races with hook writes.

**Implication.** Any framework-level fix that adds more `.apex/` writes (Round 3.4 schema enforcement, mutation-gate state tracking, etc.) will multiply this risk. Hooks need filesystem-stable retry logic, OR projects need to be relocated outside OneDrive, OR `.apex/` needs to be excluded from sync.

**This is not a single gap.** It is a recurring symptom that will appear in multiple entries below. Rather than file it as one item, I have flagged it inline in every entry where it could amplify the problem.

---

### Theme 3 · Schemas Exist as Documentation but Not as Enforcement

**The pattern.** All 4 schemas in `framework/schemas/` describe the shape of state files (STATE.json, PLAN_META.json, etc.) but no validator runs against them. This was findings D-1 through D-5 in the original audit. The user explicitly chose **Option 1 (real enforcement)** during the coherence pass — meaning Round 3.4 will build a validator and wire it up.

**Implication.** Until Round 3.4 lands, every other gap that touches state files (A-5 fields, mutation-gate state, schema drift) is "soft" — the schemas don't reject malformed data, so misalignments don't fail loudly. Round 3.4 will likely surface a wave of pre-existing drift the moment validation turns on.

**Strategy.** When fixing other gaps that touch state files, leave a comment in the code with the expected shape, even if no validator enforces it yet. The validator (when built) will use these comments as ground truth.

---

### Theme 4 · The Critic Catches Real Bugs the Executor Misses

**The pattern.** During task 07-10 on Shield, the frontend-specialist wrote code that compiled cleanly (`tsc exit 0`) and self-reported `confidence: HIGH`. The clean-room critic then identified a stale-closure bug in the same file. This is the entire point of the dual-agent design — and it works.

**Implication.** When fixing gaps below, especially in agent prompts (`framework/agents/*.md`), preserve the clean-room contract aggressively. Critic must never see SUMMARY.md, executor reasoning, or confidence claims. If a fix proposes to "give critic more context to make better decisions," reject it. The constraint is the feature.

---

### Theme 5 · Pipeline Bypass Is the Hidden Risk in Self-Healing Designs

**The pattern.** Round 3.2 C-3 added a phantom-check + reflexion + retry loop to `/apex:next`. During the 07-10 critic FAIL on the stale-closure bug, the orchestrator did **not** invoke the new pipeline. It edited the file directly with three Update calls and re-invoked critic. The result was correct, but the pipeline we built lay dormant.

**Implication.** Rounds 3.3+ will build more self-healing logic (env retries, schema repair, breaker recovery). Each one risks the same fate: the orchestrator's heuristic ("simple fix, do it directly") will preempt the formal flow. We are designing safety nets that may never catch anything because the trapeze artist keeps landing on his feet.

**Strategy options.** (1) Add a `force_pipeline_on_fail = true` flag for validation runs. (2) Make the orchestrator log when it's bypassing a pipeline so we can measure the bypass rate. (3) Accept that pipelines are insurance, not daily-driver code, and validate them in synthetic tests (like health-check) rather than expecting production to exercise them.

---

## Part 2 — Round 3.3 Candidates: Environment & Phase Verification

Five gaps that share a theme: the framework assumes environment is stable but does not verify it.

### G-1 — Git is required by 6 hooks but never checked at runtime

| Field | Value |
|---|---|
| Source | AUDIT-2026-04-09, finding G-1 |
| Status | Open |
| Severity | Medium-high |
| Round | 3.3 |

**The gap.** Six hooks (`subagent-stop.sh`, `pre-task-snapshot.sh`, `phase-tag.sh`, `circuit-breaker.sh`, `post-write.sh`, `cross-phase-audit.sh`) call `git` commands without verifying git is installed and the directory is a git repository. If git is unavailable or the user runs APEX in a non-git directory, hooks fail silently or with cryptic errors.

**Impact.** Anti-hallucination, snapshot, rollback, and phase-verification layers all silently degrade. The user sees normal-looking output but receives no protection. This is the same failure mode as the missing-jq problem from Round 2 — protection that exists in code but not in runtime.

**Ideal behavior.** A `_require-git.sh` helper analogous to `_require-jq.sh`, sourced at the top of every git-using hook. On failure: print actionable error to stderr and `exit 2`.

**How the agent can verify the gap exists:**
```bash
# 1. Check if _require-git.sh exists
ls framework/hooks/_require-git.sh 2>&1

# 2. Find which hooks use git
grep -l "git " framework/hooks/*.sh

# 3. For each hook above, check if it sources a git guard
grep -l "_require-git" framework/hooks/*.sh
```
**Expected if gap is real:** `_require-git.sh` does not exist (step 1 returns error), and step 3 returns zero matches.

**Proposed fix.** Create `framework/hooks/_require-git.sh` with two checks: (a) `command -v git` to verify binary, (b) `git rev-parse --is-inside-work-tree` to verify directory is a repo. On either failure, emit a clear error and exit 2. Source it from all 6 git-using hooks at the top, immediately after `_require-jq.sh`.

> ⚠️ **OPEN FOR CRITIQUE.** This proposal mirrors the Round 2 jq pattern. Two things to consider before implementing:
> 1. **Combined helper vs separate.** Should we have `_require-jq.sh`, `_require-git.sh`, `_require-rg.sh`, etc., or one `_require-env.sh` that takes a list? Separate is clearer but verbose. Combined is DRY but adds an argument-parsing layer.
> 2. **`is-inside-work-tree` strictness.** Some hooks may legitimately want to run outside a git repo (e.g., `health-check.sh` setup creates its own temp git repo). The git-presence check should be unconditional, but the "inside repo" check should be opt-in via a second function call.
> 3. **Round 3.2 introduced filesystem verification on phase-tag.** That fix is hook-specific. The git-helper should not duplicate it — only verify git is callable, not verify any specific git operation succeeded.

**Validation after fix:**
```bash
# 1. Verify helper exists and is sourced
ls framework/hooks/_require-git.sh
for hook in subagent-stop pre-task-snapshot phase-tag circuit-breaker post-write cross-phase-audit; do
  grep -q "_require-git" framework/hooks/${hook}.sh && echo "$hook: OK" || echo "$hook: MISSING"
done

# 2. Negative test: temporarily rename git, run a hook, expect exit 2
PATH_BACKUP=$PATH
export PATH=$(echo $PATH | tr ':' '\n' | grep -v git | tr '\n' ':')
bash framework/hooks/subagent-stop.sh test-agent 5
# Expected: exit code 2, clear error message about missing git
export PATH=$PATH_BACKUP

# 3. Health-check should add TEST 0d for git presence
grep -A 5 "TEST 0d" framework/commands/apex/health-check.md
```
**Expected:** All 6 hooks source the helper, negative test exits 2 with clear error, health-check has new test for git.

---

### B-3 — `verify-learnings.sh` wired fail-silent in `settings.json`

| Field | Value |
|---|---|
| Source | AUDIT-2026-04-09, finding B-3 |
| Status | Open |
| Severity | Medium |
| Round | 3.3 |

**The gap.** In `~/.claude/settings.json`, the verify-learnings hook is wired with `2>/dev/null || true`, which suppresses both stderr and exit codes. This contradicts the Round 2 fail-loud doctrine — the hook can fail and the framework will not know. The hook is meant to enforce learning-decay rules (HOT/WARM/COLD) at session boundaries; if it silently fails, stale learnings persist and architect makes decisions based on outdated context.

**Impact.** Round 2's fail-loud doctrine is broken at the entry point of the most subtle hook in the system. The user has no signal when learning enforcement fails.

**Ideal behavior.** The settings.json wiring should be `bash ~/.claude/hooks/verify-learnings.sh` with no suppression. If the hook exits non-zero, the framework should surface the error. The hook itself should be robust enough that legitimate "no learnings to verify" cases exit 0, not 1.

**How the agent can verify the gap exists:**
```bash
# 1. Read the settings.json wiring (READ-ONLY — do not modify yet)
cat ~/.claude/settings.json | jq '.hooks' 2>&1
# Look for verify-learnings line — does it have 2>/dev/null || true?

# 2. Compare to other hook wirings
grep -A 1 "verify-learnings" ~/.claude/settings.json
grep -A 1 "phantom-check" ~/.claude/settings.json
```
**Expected if gap is real:** verify-learnings line ends in `|| true` or includes `2>/dev/null`, while phantom-check (added later) does not.

**Proposed fix.** (a) Remove `2>/dev/null || true` from settings.json wiring. (b) Audit verify-learnings.sh for any "graceful" exit paths that should be exit 0 (not silently swallowed). (c) Update Round 2 documentation to note that settings.json wirings are part of the fail-loud chain.

> ⚠️ **OPEN FOR CRITIQUE.** Three considerations:
> 1. **Settings.json is user-editable.** A user may have intentionally added the suppression because the hook was noisy. Before removing it, run the hook in current state and capture output. If it produces noise, fix the noise first, then remove the suppression. Don't unleash a noisy hook on the user.
> 2. **The hook itself might have B-2 (broken regex).** B-2 is in Round 3.5 scope (UX consistency), but it's relevant here: if the regex is broken, the hook will produce false positives every session, and removing the suppression will create alert fatigue. Consider sequencing B-2 BEFORE B-3.
> 3. **There may be other settings.json wirings with the same anti-pattern.** Audit the entire `settings.json` hooks block for `2>/dev/null` or `|| true` patterns before fixing only verify-learnings. Group fix.

**Validation after fix:**
```bash
# 1. Confirm settings.json clean
grep -c "2>/dev/null\|\\|\\| true" ~/.claude/settings.json
# Expected: 0

# 2. Force-fail the hook and check it surfaces
# (set up an environment where the hook will exit non-zero)
# Then trigger a session-start and verify the user sees the error

# 3. Health-check should add a test that wirings have no suppression
grep -A 3 "TEST.*settings\|TEST.*wiring" framework/commands/apex/health-check.md
```

---

### A-2 — `cross-phase-audit.sh` called without parameter, always skips

| Field | Value |
|---|---|
| Source | AUDIT-2026-04-09, finding A-2 |
| Status | Open |
| Severity | Medium |
| Round | 3.3 |

**The gap.** In `next.md`, the call to `cross-phase-audit.sh` is invoked without the required phase-id parameter. The hook checks for the parameter at the top and silently exits 0 if it's missing. As a result, cross-phase verification — meant to catch regressions across phase boundaries — has never run in production.

**Impact.** A framework feature exists, is documented, and has never executed. Users believe phase-boundary regressions are caught; they are not.

**Ideal behavior.** `next.md` should call `cross-phase-audit.sh "$current_phase"` (or whatever variable holds the phase id at that point in the orchestrator). The hook should exit non-zero if no parameter is passed (fail-loud), so silent skips are detected immediately.

**How the agent can verify the gap exists:**
```bash
# 1. Find the cross-phase-audit invocation in next.md
grep -n "cross-phase-audit" framework/commands/apex/next.md

# 2. Check the hook's parameter handling
head -20 framework/hooks/cross-phase-audit.sh
```
**Expected if gap is real:** The next.md line shows `cross-phase-audit.sh` with no argument or with a literal string instead of a variable. The hook has a guard like `[ -z "$1" ] && exit 0`.

**Proposed fix.** Two changes: (a) Update `next.md` to pass the current phase variable. (b) Update `cross-phase-audit.sh` to fail-loud (exit 2) instead of fail-silent when no parameter is provided.

> ⚠️ **OPEN FOR CRITIQUE.** Two questions:
> 1. **What's the right phase variable?** The orchestrator may track the current phase in multiple places (STATE.json, PLAN_META, environment). Pick the most authoritative. Probably `STATE.current_phase`, but verify it's set before the call.
> 2. **Is the hook designed for solo runs or only end-of-phase runs?** If the hook is meant to run only when transitioning between phases, the call site in next.md needs to be conditional. Read the hook's logic to understand when it's meant to fire, not just where.
> 3. **Round 3.2 already added the phantom-check call to next.md in a similar pattern.** Cross-reference the placement of phantom-check to find the right scope for cross-phase-audit. They may belong in the same neighborhood of the file.

**Validation after fix:**
```bash
# 1. Verify the call has a parameter
grep -n "cross-phase-audit" framework/commands/apex/next.md
# Expected: line includes a variable like ${current_phase} or $PHASE_ID

# 2. Verify the hook fails on empty arg
bash framework/hooks/cross-phase-audit.sh
# Expected: exit code 2, clear error

# 3. Run an end-of-phase scenario (after phase 7 closes on Shield)
# The hook should now actually execute and produce output
```

---

### A-3 — `post-write.sh` tsc typecheck is print-only, not blocking

| Field | Value |
|---|---|
| Source | AUDIT-2026-04-09, finding A-3 |
| Status | Open |
| Severity | Medium |
| Round | 3.3 |

**The gap.** `post-write.sh` runs `tsc --noEmit` after every file write but only prints the first 5 lines of output. Exit code is not collected, so blocking errors are reduced to a 5-line warning that scrolls past the user. Type errors silently accumulate.

**Impact.** TypeScript safety net exists in print-only mode. The framework appears to type-check but does not enforce. Users on TS projects (like Shield) believe their changes are validated.

**Ideal behavior.** `post-write.sh` should: (a) capture full tsc output, (b) capture exit code, (c) on non-zero exit, fail-loud and exit 2 to block downstream operations, (d) on zero exit, exit 0 silently.

**How the agent can verify the gap exists:**
```bash
# 1. Read post-write.sh
cat framework/hooks/post-write.sh

# 2. Look for tsc invocation and exit handling
grep -A 5 "tsc" framework/hooks/post-write.sh
```
**Expected if gap is real:** `tsc` output is piped to `head -5` or similar, exit code is not stored in a variable, hook ends with unconditional `exit 0`.

**Proposed fix.** Rewrite the tsc section using the same pattern as Round 3.2's phase-tag.sh fix:
```bash
TSC_OUTPUT=$(npx tsc --noEmit 2>&1)
TSC_EXIT=$?
if [ $TSC_EXIT -ne 0 ]; then
  echo "🚫 POST-WRITE: tsc failed" >&2
  echo "$TSC_OUTPUT" >&2
  exit 2
fi
```

> ⚠️ **OPEN FOR CRITIQUE.** Three questions:
> 1. **What if the project is not TypeScript?** Hook should detect (presence of `tsconfig.json` or `package.json` with TS deps) and skip cleanly if not applicable. Fail-loud on tsc-not-installed when project IS TS, but skip silently when project is not.
> 2. **Performance.** `tsc --noEmit` on every file write is expensive. For large projects this could add 5-30 seconds per write. Consider scoping to changed-files-only via `tsc --noEmit -p tsconfig.json [files]`, OR running async with results in next-step gate, OR running only on `.ts/.tsx` writes.
> 3. **The Round 2 doctrine of fail-loud has a corollary: noisy fixes erode trust.** If post-write becomes a 30-second blocker on every write, users will disable the hook. Speed AND correctness both matter.

**Validation after fix:**
```bash
# 1. Create a temp TS file with a type error
echo 'const x: number = "string";' > /tmp/test-bad.ts
# 2. Run post-write.sh on it
bash framework/hooks/post-write.sh /tmp/test-bad.ts
# Expected: exit 2, full tsc error visible

# 3. Create a valid TS file
echo 'const y: number = 42;' > /tmp/test-good.ts
bash framework/hooks/post-write.sh /tmp/test-good.ts
# Expected: exit 0, no output

# 4. Run on a non-TS file in a non-TS project
bash framework/hooks/post-write.sh /tmp/test.txt
# Expected: exit 0, skip silently
```

---

### E-4 — `CLAUDE-TEMPLATE.md` referenced but not deployed by sync

| Field | Value |
|---|---|
| Source | AUDIT-2026-04-09, finding E-4 |
| Status | Possibly already partially addressed; verify |
| Severity | Medium-high (blocks new project setup) |
| Round | 3.3 |

**The gap.** `start.md` references `CLAUDE-TEMPLATE.md` as the template for new project CLAUDE.md files. But `sync-to-claude.sh` does not copy it to `~/.claude/`, so the template is unavailable when start.md tries to read it. New project initialization fails or falls back to fabrication.

**Impact.** Every new APEX project hit this on day 1. The user experience for "create a new APEX project" is broken at the first step.

**Ideal behavior.** `CLAUDE-TEMPLATE.md` deployed to `~/.claude/CLAUDE-TEMPLATE.md` by sync. start.md reads it from the deployed location.

**How the agent can verify the gap exists:**
```bash
# 1. Does the template exist in framework?
ls framework/CLAUDE-TEMPLATE.md 2>&1

# 2. Is it in sync-to-claude.sh's copy paths?
grep "CLAUDE-TEMPLATE" framework/scripts/sync-to-claude.sh

# 3. Is it in the ~/.claude/ deployed location?
ls ~/.claude/CLAUDE-TEMPLATE.md 2>&1

# 4. Where does start.md try to read it from?
grep -n "CLAUDE-TEMPLATE" framework/commands/apex/start.md
```
**Expected if gap is real:** Step 1 succeeds (file exists in framework), step 3 fails (not in ~/.claude/), step 4 shows start.md reading from a path that doesn't exist post-deploy.

**Proposed fix.** Two-line update to `sync-to-claude.sh` to include `CLAUDE-TEMPLATE.md` in the file list (or in the find pattern, depending on how the script enumerates files).

> ⚠️ **OPEN FOR CRITIQUE.** Verify first:
> 1. **The script may already use `find -type f` which would catch all files** — in which case the issue may be elsewhere (e.g., the file is in a subdirectory the script doesn't traverse). Read sync-to-claude.sh fully before assuming it's an explicit list.
> 2. **The Round 3.2 path drift in Shield's `.apex/phases/`** showed how easy it is to miss new files. Whatever solution we apply, add a verification step to the deploy: post-sync, list files in `~/.claude/` and compare to expected count.
> 3. **Audit notes the template label says "v6"** — if the template still says v6, Round 3.1's version sweep missed it because it's outside `framework/`. Fix the label as part of this round, OR file separately. Don't deploy a v6 template.

**Validation after fix:**
```bash
# 1. Run dry-run sync, confirm file is in copy list
bash framework/scripts/sync-to-claude.sh --dry-run | grep CLAUDE-TEMPLATE
# Expected: 1 line showing the copy

# 2. Live sync, verify deployed
bash framework/scripts/sync-to-claude.sh
ls -la ~/.claude/CLAUDE-TEMPLATE.md
# Expected: file exists

# 3. Diff source vs deployed
diff framework/CLAUDE-TEMPLATE.md ~/.claude/CLAUDE-TEMPLATE.md
# Expected: empty (byte-identical)
```

---

## Part 3 — Round 3.4 Candidates: Schemas & Mutation Testing

The heaviest planned round. User chose **enforcement over deletion** in coherence pass — schemas become real, mutation-gate becomes a real gate.

### D-1 to D-5 — Schemas are orphaned and have drifted from runtime state

| Field | Value |
|---|---|
| Source | AUDIT-2026-04-09, findings D-1 through D-5 |
| Status | Open — user decided Option 1 (enforce) in coherence pass |
| Severity | High (cluster) |
| Round | 3.4 |

**The gap.** Four JSON schemas exist in `framework/schemas/` (STATE, PLAN_META, RESULT, CONTEXT_BUDGET). None of them are validated against any runtime state file. Over time, the runtime files have grown fields the schemas don't know about, and schemas have fields the runtime never produces. The schemas are documentation in the shape of validation, without the validation. NEW-1 (Schema-by-Memory Reconstruction, see Part 5) is a direct consequence: when STATE.json is rebuilt, agents use trained memory of "what STATE looks like" instead of reading the schema, because the schema isn't enforced and isn't trusted.

**Specific drifts:**
- **D-1 (parent finding):** No validator wired anywhere
- **D-2:** `STATE.schema.json` missing fields that exist in runtime STATE.json (autopilot.consecutive_sessions, reflexion.current_unit_attempts, drift_indicators block, more)
- **D-3:** `PLAN_META.schema.json` missing fields the orchestrator writes
- **D-4:** `RESULT.schema.json` missing fields executors emit
- **D-5:** `CONTEXT_BUDGET.schema.json` has `additionalProperties: false` that would reject runtime data

**Impact.** No structural enforcement of state-file shapes anywhere in the framework. Drifts compound silently. NEW-1 happens because there's no authority to point at when reconstructing files. Round 3.2 A-5's new fields (`previous_last_completed_task`, `previous_tasks_completed_in_autopilot`) cannot be enforced as required because nothing runs validation.

**Ideal behavior.** A bash-based validator (`framework/scripts/validate-state.sh` or similar) that takes a schema and a state file, checks the state against the schema, and exits non-zero on violations. Wired into `pre-task-snapshot.sh` (validate STATE.json before snapshot), `phase-tag.sh` (validate before tagging), and `health-check.md` (validate as TEST 10 or 11). Schemas updated to match current runtime reality, with `additionalProperties: true` where extension is permitted.

**How the agent can verify the gap exists:**
```bash
# 1. Check if any validator exists
find framework -name "*validate*" -o -name "*validator*" 2>&1
ls framework/scripts/ 2>&1

# 2. Compare a real STATE.json against its schema
# Use Shield's STATE.json or a reference STATE.json
jq 'keys' shield/.apex/STATE.json 2>&1
jq '.properties | keys' framework/schemas/STATE.schema.json 2>&1
# Diff the two key sets

# 3. Check schema additionalProperties
jq '.additionalProperties, .properties.autopilot.additionalProperties' framework/schemas/STATE.schema.json
```
**Expected if gap is real:** No validator found. Field-set diff shows both directions of drift (state has fields schema doesn't, schema has fields state doesn't). additionalProperties is unset or false.

**Proposed fix (large; phased).**

**Phase 4.1 — Build the validator.** Create `framework/scripts/validate-state.sh` using `jq` (already a hard dependency) to do schema-checking. Bash + jq can do most of JSON Schema validation: required fields, type checks, enum checks, additionalProperties enforcement. Skip advanced features (allOf, anyOf, complex regex). The validator takes two args: schema path and state file path. Exits 0 on valid, 2 on invalid with diagnostic output.

**Phase 4.2 — Update schemas to match reality.** For each of the 4 schemas:
1. Read the corresponding runtime file (Shield's STATE.json is the cleanest reference)
2. List every field in runtime file
3. Add missing fields to the schema with appropriate types
4. Mark fields as required ONLY if they're guaranteed by start.md init OR by hook writes
5. Set `additionalProperties: true` initially (loose), tighten in a future round

**Phase 4.3 — Wire validator into hooks.** Add validation calls in:
- `pre-task-snapshot.sh` — validate STATE.json before snapshotting
- `phase-tag.sh` — validate STATE.json before tagging (so we don't tag a corrupted state)
- `health-check.md` — new TEST that runs validator on a known-good fixture

**Phase 4.4 — Migration for existing projects.** Shield (and any other live project) has a STATE.json that may not match the new schema. Provide a `migrate-state.sh` helper that adds missing required fields with sensible defaults, OR document a manual migration path.

> ⚠️ **OPEN FOR CRITIQUE — this is the most complex round, please scrutinize hard.**
>
> 1. **Bash + jq for JSON Schema is a stretch.** Real JSON Schema validators handle dozens of edge cases (ref resolution, oneOf, conditionals). A bash implementation will be limited. Accept this — limit the schemas to features the bash validator supports. Document unsupported features clearly.
>
> 2. **Migration is the hard part, not the validator.** Shield has months of accumulated state. Forcing schema compliance retroactively could break it. Strategy: validator should have a `--soft` mode that warns instead of failing for the first N runs after rollout, then switches to `--strict`.
>
> 3. **NEW-1 (Schema-by-Memory Reconstruction) is the canary.** If the validator is in place AND runs on every hook entry, then when an agent reconstructs STATE.json from memory and omits required fields, the next hook call will fail-loud and reveal the bug. **The validator's first job is to surface NEW-1, not just to enforce structure.** Build with this primary use case in mind.
>
> 4. **Performance.** Validation on every hook adds latency. Worth it for safety? Probably yes — but profile after rollout. If validation adds >100ms per hook call, optimize (cache compiled schema, etc.).
>
> 5. **Schema versioning.** The schemas now say "v7" (post-Round 3.1). When v8 lands, schemas must version-bump. Build the validator to check `apex_version` in the state file matches the schema version, and warn on mismatch.
>
> 6. **Wave 4 is heaviest because of migration risk.** Consider running this round entirely on a test project FIRST, never on Shield. Only after the validator runs clean on Shield's STATE.json (in soft mode) do we enable strict mode.

**Validation after fix:**
```bash
# 1. Validator exists and works on a known-good fixture
bash framework/scripts/validate-state.sh framework/schemas/STATE.schema.json framework/test-fixtures/STATE-good.json
# Expected: exit 0

# 2. Validator catches a known-bad fixture
bash framework/scripts/validate-state.sh framework/schemas/STATE.schema.json framework/test-fixtures/STATE-missing-required.json
# Expected: exit 2, clear diagnostic

# 3. Validator runs on Shield's STATE.json (soft mode initially)
bash framework/scripts/validate-state.sh --soft framework/schemas/STATE.schema.json shield/.apex/STATE.json
# Expected: exit 0 with warnings about NEW-1's missing fields

# 4. After Shield's STATE.json is migrated, strict mode passes
bash framework/scripts/validate-state.sh framework/schemas/STATE.schema.json shield/.apex/STATE.json
# Expected: exit 0

# 5. NEW-1 is now caught: simulate the "agent rebuilds STATE.json from memory" path
# Manually create a STATE.json without previous_last_completed_task
# Run pre-task-snapshot
# Expected: exit 2, error names the missing field
```

---

### E-1 + C-1 — `mutation-gate.sh` is dead code AND has misleading name

| Field | Value |
|---|---|
| Source | AUDIT-2026-04-09, findings E-1 and C-1 |
| Status | Open — user decided mutation testing IS part of long-term story |
| Severity | Medium-high |
| Round | 3.4 |

**The gap.** `mutation-gate.sh` exists in `framework/hooks/`, contains real mutation-testing logic, and is referenced in documentation as a "gate" — but is never invoked anywhere in the orchestrator. Furthermore, even if it were invoked, its current behavior is advisory (prints warnings but exits 0), not gating (would block on failure). The name claims "gate", the behavior is "advisory". User decided in coherence pass that mutation testing is part of APEX's long-term story, so this gets fixed (not deleted).

**Impact.** A documented framework feature (mutation testing for resilience) does not exist in execution. The user believes their code is mutation-tested; it is not. Worse, the name "gate" implies blocking — anyone reading the code without running it expects it to block on failure. The deception is in two layers.

**Ideal behavior.**
1. `mutation-gate.sh` is wired into `next.md` at an appropriate point (probably after critic PASS, before final commit) for tasks where mutation testing is appropriate (verify_level C and D, perhaps).
2. The hook actually gates: if mutation kill rate is below a threshold (say, 60%), exit non-zero and require fix.
3. The name is honest: either it really gates (keep "gate"), or it's renamed to "mutation-advisor" (current behavior).

**How the agent can verify the gap exists:**
```bash
# 1. Find references to mutation-gate
grep -rn "mutation-gate" framework/

# 2. Specifically, is it called from any orchestrator command?
grep -rn "mutation-gate" framework/commands/

# 3. Check the hook itself for exit behavior
tail -20 framework/hooks/mutation-gate.sh
```
**Expected if gap is real:** Step 2 returns zero or only doc references, not runtime calls. Step 3 shows unconditional `exit 0` regardless of mutation results.

**Proposed fix.**

**Phase 4.5 — Wire mutation-gate into next.md.** Add a call after critic PASS, conditional on verify_level. Match the pattern used by Round 3.2 C-3 phantom-check insertion. The call should run mutation testing on changed files only (not the whole codebase).

**Phase 4.6 — Make it a real gate.** Update `mutation-gate.sh`:
- Capture mutation kill rate from the underlying tool (likely `stryker` or similar)
- If kill rate < threshold, exit 2 with diagnostic
- If kill rate >= threshold, exit 0 with success
- If mutation tool is unavailable, exit 1 (advisory) — same 3-way pattern as Round 3.2 B-4

**Phase 4.7 — Decide on threshold and verify_level scope.** Consult the user. Probably:
- A-level tasks: skip mutation testing entirely (overhead too high)
- B-level: advisory only (exit 1 on low kill rate)
- C/D-level: gating (exit 2 on low kill rate)
- Threshold: start at 60%, raise as the project matures

> ⚠️ **OPEN FOR CRITIQUE.** Several large questions:
>
> 1. **Is the mutation testing tool installed?** This is jq-style risk. Stryker or whatever the framework expects must be a hard dependency, with fail-loud if missing. Probably needs a `_require-stryker.sh` helper.
>
> 2. **Mutation testing is SLOW.** Stryker on a 1000-line codebase can take 10+ minutes. Inserting it after every C/D task may make `/apex:next` painful. Consider: scope to changed files only (Stryker supports this), OR run async with results gating the NEXT task (not the current one), OR make it opt-in.
>
> 3. **The user explicitly chose to keep mutation testing in scope** in the coherence pass. But the user may not have appreciated the rollout cost. Before implementing, confirm with user that they understand: this round will add 5-15 minutes to high-verify tasks. Get explicit consent.
>
> 4. **The "gate vs advisor" naming question.** I lean toward keeping the name "gate" and making the behavior match. Renaming would propagate through documentation, branding cards, and is the kind of churn we just finished cleaning up in Round 3.1. Match the name to behavior, not behavior to name.
>
> 5. **Migration: existing tasks lack mutation tests.** Shield's tasks 07-01 through 07-08 don't have mutation tests. Should the gate apply retroactively, or only to new tasks? Probably only new — don't break the past to enforce the future.

**Validation after fix:**
```bash
# 1. mutation-gate.sh is wired in next.md
grep -n "mutation-gate" framework/commands/apex/next.md
# Expected: at least 1 call site, after critic PASS

# 2. Hook gates correctly on a synthetic low-kill-rate scenario
# Set up a test directory with known mutation results
bash framework/hooks/mutation-gate.sh /tmp/mutation-test-bad
# Expected: exit 2 with kill rate diagnostic

# 3. Hook passes on a synthetic high-kill-rate scenario
bash framework/hooks/mutation-gate.sh /tmp/mutation-test-good
# Expected: exit 0

# 4. Hook handles missing tool correctly
PATH_BACKUP=$PATH
export PATH=$(echo $PATH | tr ':' '\n' | grep -v stryker | tr '\n' ':')
bash framework/hooks/mutation-gate.sh /tmp/mutation-test-good
# Expected: exit 1 (advisory) with clear "tool not installed" message
export PATH=$PATH_BACKUP

# 5. End-to-end on Shield: run a C-level task, observe mutation-gate firing
# (manual test, requires user)
```

---

## Part 4 — Round 3.5 Candidates: UX Consistency

Smaller round. Polish, naming consistency, and the R13 Mission Briefing rollout.

### C-4 — R13 Mission Briefing only in `/apex:next`, not in other commands

| Field | Value |
|---|---|
| Source | AUDIT-2026-04-09, finding C-4 |
| Status | Open — user decided ALL commands need it |
| Severity | Low-medium |
| Round | 3.5 |

**The gap.** R13 (Mission Briefing + Flight Recorder visual blocks) is a UX feature added in a previous round. It only exists in `next.md`. Other commands that dispatch agents (`micro.md`, `quick.md`, `_debate.md`, `spec.md`) lack it. Users see rich Mission Briefing during `/apex:next` but plain output during other commands. Inconsistent UX.

**Impact.** Cosmetic but real. Inconsistency in framework UX erodes the "this is a polished product" feeling. Also, Mission Briefing has a functional role (it makes context loading visible to the user), so its absence in other commands means users have less visibility into what the framework is doing.

**Ideal behavior.** All 5 commands (`next`, `micro`, `quick`, `_debate`, `spec`) that dispatch agents render Mission Briefing before dispatch and Flight Recorder after. Same visual format, same fields where applicable.

**How the agent can verify the gap exists:**
```bash
# 1. Find all commands that have Mission Briefing
grep -l "MISSION BRIEFING\|MISSION  BRIEFING" framework/commands/apex/

# 2. Find all commands that dispatch agents (Task call)
grep -l "Task(" framework/commands/apex/

# 3. The diff of (2) minus (1) is the gap
```
**Expected if gap is real:** Step 1 returns only `next.md`. Step 2 returns `next.md`, `micro.md`, `quick.md`, `_debate.md`, `spec.md`.

**Proposed fix.** Copy the Mission Briefing + Flight Recorder block from `next.md` and adapt to each of the 4 other commands. Adaptations:
- `micro.md`: simpler context (just one file), shorter Briefing
- `quick.md`: ad-hoc task, generated TASK_ID, no PLAN_META
- `_debate.md`: dual-agent dispatch, may need TWO Briefings
- `spec.md`: planning, may not need Flight Recorder (no execution to record)

> ⚠️ **OPEN FOR CRITIQUE.** Three considerations:
>
> 1. **Don't just copy-paste.** The Mission Briefing in next.md references fields specific to next.md's context (verify_level, specialist routing, dependency summaries). Some of these don't exist in micro/quick. Adapt the field set per command — don't blindly duplicate.
>
> 2. **Visual consistency vs. content fit.** All Briefings should look the same (frame, alignment, sections), even if content differs. Use the same ASCII art frame and section headers across all 5.
>
> 3. **`spec.md` may not need Flight Recorder.** It's a planning command, not an execution command. There's no "files touched" to record. Either skip Flight Recorder for spec, or replace it with a "plan summary" block in the same visual format.
>
> 4. **Round 3.1's branding card frame width (68 chars) is the constraint.** Same constraint applies here. Test alignment carefully.

**Validation after fix:**
```bash
# 1. All 5 commands have Mission Briefing
for cmd in next micro quick _debate spec; do
  grep -q "MISSION BRIEFING\|MISSION  BRIEFING" framework/commands/apex/${cmd}.md \
    && echo "$cmd: OK" || echo "$cmd: MISSING"
done
# Expected: all OK

# 2. Run each command on Shield (or a test project) and visually verify the Briefing renders correctly
# (manual test)

# 3. Frame alignment check: render each Briefing and confirm frame width is consistent
# (visual inspection)
```

---

### B-2 — `verify-learnings.sh` placeholder regex broken, false positives every session

| Field | Value |
|---|---|
| Source | AUDIT-2026-04-09, finding B-2 |
| Status | Open |
| Severity | Medium (alert fatigue erodes trust) |
| Round | 3.5 (or earlier per B-3 sequencing concern) |

**The gap.** The hook has a placeholder-detection regex: it's looking for `*]` (asterisk followed by close-bracket, meaning unfinished placeholder), but the regex is written `*[` which is a literal pattern that matches zero-or-more-asterisks followed by open-bracket. This produces false positives constantly, and noise in every session start.

**Impact.** Alert fatigue. Users learn to ignore verify-learnings warnings, which means real issues will also be ignored. This is exactly the opposite of the Round 2 fail-loud doctrine.

**Ideal behavior.** The regex correctly matches unfinished placeholder syntax. False positive rate near zero. Real placeholders flagged accurately.

**How the agent can verify the gap exists:**
```bash
# 1. Find the regex
grep -n "regex\|grep\|pattern" framework/hooks/verify-learnings.sh
# Look for the placeholder-detection logic

# 2. Test current regex on a known-good learnings file
bash framework/hooks/verify-learnings.sh
# Observe whether it produces warnings on a clean file
```
**Expected if gap is real:** The regex includes `*[` or similar inverted pattern. Hook output includes warnings on files that have no actual placeholder issues.

**Proposed fix.** Two-character fix: `*[` → `*]`. Plus a test fixture (a learnings file with one real placeholder) to verify the corrected regex catches it without false positives.

> ⚠️ **OPEN FOR CRITIQUE.** Three considerations:
>
> 1. **Read the full regex context.** The 2-character fix may be correct OR may need broader changes if the regex is matching something more complex than I assumed. Read the surrounding code first.
>
> 2. **The fix unblocks B-3.** B-3 (settings.json suppression) cannot be removed safely while this hook is noisy. Sequence B-2 BEFORE B-3.
>
> 3. **Regex robustness in bash.** Bash regex via `grep` can have edge cases (escaping, character classes). Test with multiple realistic learnings files, not just one.

**Validation after fix:**
```bash
# 1. Run on current learnings — should produce zero noise
bash framework/hooks/verify-learnings.sh
# Expected: silent or "all clean"

# 2. Run on a fixture with a real placeholder
echo "[PLACEHOLDER: TODO write this learning]" > /tmp/test-learnings.md
bash framework/hooks/verify-learnings.sh /tmp/test-learnings.md
# Expected: flags the placeholder

# 3. Sequence: after B-2 is fixed, B-3 (suppression removal) becomes safe
```

---

### A-4 — `executor.md` builds `--testPathPattern` from multi-line strings

| Field | Value |
|---|---|
| Source | AUDIT-2026-04-09, finding A-4 |
| Status | Open |
| Severity | Medium (TDAD core feature broken) |
| Round | 3.5 |

**The gap.** The executor agent prompt instructs it to build `jest --testPathPattern` arguments from multi-line file lists. Jest doesn't accept multi-line patterns — they must be regex alternation (`file1|file2|file3`) or use `--findRelatedTests`. Result: TDAD's targeted-test feature doesn't actually run targeted tests, falls back to running all tests or skipping tests entirely.

**Impact.** TDAD is a documented core APEX feature, claimed to save 70% on regression test time. Currently broken. Users who think they're getting TDAD speedup are not.

**Ideal behavior.** executor.md builds the pattern as a properly-formatted regex alternation OR uses `--findRelatedTests` with a file list.

**How the agent can verify the gap exists:**
```bash
# 1. Find the testPathPattern construction in executor.md
grep -A 5 "testPathPattern\|findRelatedTests" framework/agents/executor.md

# 2. Look for multi-line vs single-line pattern construction
```
**Expected if gap is real:** Multi-line bash heredoc or array-of-files being passed as a single-string arg.

**Proposed fix.** Update executor.md prompt with one of:
- **Option A:** Use `--findRelatedTests file1.ts file2.ts file3.ts` (Jest-supported, takes a list)
- **Option B:** Build regex alternation: `--testPathPattern="(file1|file2|file3)"`

Option A is cleaner if Jest version supports it; Option B is more universal.

> ⚠️ **OPEN FOR CRITIQUE.** Three considerations:
>
> 1. **Jest version dependency.** `--findRelatedTests` was added in Jest 24+. If projects use older Jest, fall back to Option B. Detect at runtime or document the requirement.
>
> 2. **Test framework agnosticism.** Not all APEX projects use Jest. Some use Vitest, Mocha, etc. The executor prompt should mention the appropriate flag for each, or at least flag Jest-specific instructions as such.
>
> 3. **The 70% claim.** The original TDAD pitch ("saves 70% on regression tests") was based on TDAD running properly. If TDAD has been broken for several rounds, the 70% number is unverified. After this fix, measure actual savings on Shield and update the doc.

**Validation after fix:**
```bash
# 1. Read the updated executor.md
grep -A 5 "testPathPattern\|findRelatedTests" framework/agents/executor.md
# Expected: single-line, properly-formed pattern

# 2. End-to-end test on Shield
# Run /apex:next on a task that touches a known set of files
# Verify Jest output shows it ran ONLY the related tests, not all tests
# (manual test)
```

---

### A-8 — `circuit-breaker.sh` hashes empty git diff, false-triggers

| Field | Value |
|---|---|
| Source | AUDIT-2026-04-09, finding A-8 |
| Status | Open |
| Severity | Medium |
| Round | 3.5 |

**The gap.** circuit-breaker.sh computes a hash of `git diff` to detect "no-change loops" (agent claims work but no changes). When `git diff` is empty (truly no changes), the hash is the hash of an empty string — same value every time. Two consecutive "no real work" iterations therefore match the same hash and trigger the breaker even when the absence of work is legitimate (e.g., agent correctly determined no fix needed).

**Impact.** False-positive circuit breaker trips. Legitimate "task already done, no action needed" outcomes get blocked.

**Ideal behavior.** circuit-breaker distinguishes "no diff because nothing changed (could be legitimate)" from "no diff because agent looped on the same operation". Approach: compare against the PREVIOUS hash AND check whether the agent's tool calls changed; trip only if both are stuck.

**How the agent can verify the gap exists:**
```bash
# 1. Read the hash logic
grep -B 2 -A 10 "git diff\|md5\|sha\|hash" framework/hooks/circuit-breaker.sh
```
**Expected if gap is real:** Hash is computed unconditionally on diff output, with no special case for empty diff.

**Proposed fix.** Add an empty-diff guard. If `git diff HEAD` is empty AND the previous hash was also empty, do not increment the no-change counter (because there was no change to begin with — that's not a "loop", that's a "no-op task"). Only count as no-change when there were tool calls but no diff.

> ⚠️ **OPEN FOR CRITIQUE.** Three considerations:
>
> 1. **What does "legitimate no-op" look like?** An agent that determines the task is already done is fine. An agent that runs grep 50 times trying to figure out what to do but never writes is NOT fine. The breaker should distinguish these. Tool-call count is a good signal: 0 tool calls = trivial no-op; many tool calls + 0 diff = stuck.
>
> 2. **Round 3.2 B-4 already added a 3-way distinction in subagent-stop.** Use the same pattern: exit 0 (legitimate no-op), exit 1 (advisory: agent worked but produced nothing), exit 2 (blocking: stuck loop).
>
> 3. **Circuit-breaker is in the most-watched part of the framework.** Errors here cascade. Whatever fix is applied, add a regression test fixture to health-check.

**Validation after fix:**
```bash
# 1. Synthetic test: 2 consecutive no-op runs should NOT trip breaker
bash framework/hooks/circuit-breaker.sh test-task 0 ""
bash framework/hooks/circuit-breaker.sh test-task 0 ""
# Expected: exit 0 both times

# 2. Synthetic test: 2 consecutive runs with tool calls but no diff SHOULD trip
bash framework/hooks/circuit-breaker.sh test-task 5 ""
bash framework/hooks/circuit-breaker.sh test-task 5 ""
# Expected: exit 0 first, exit 2 second
```

---

## Part 5 — New Runtime Findings (Checkpoint 2026-04-10)

Seven gaps surfaced during the runtime checkpoint that did not exist in the original audit. These have NEW-* IDs.

### NEW-1 — STATE.json structure reconstructed from agent memory, not from start.md template

| Field | Value |
|---|---|
| Source | Checkpoint 2026-04-10, /apex:next 07-10 |
| Status | Open |
| Severity | Medium-high |
| Round | 3.4 (resolved as side-effect of schema enforcement) |

**The gap.** When STATE.json was empty/corrupt at the start of task 07-10, the orchestrator agent rebuilt it with 90 lines pulled from PLAN_META, WAVE_MAP, and RESULT files. But the rebuild **did not include** the two fields added in Round 3.2 A-5: `previous_last_completed_task` and `previous_tasks_completed_in_autopilot`. The agent used trained memory of "what STATE.json looks like" instead of consulting `start.md` init template.

**Impact.** Round 3.2 A-5's fix is silently inactive on Shield (and likely any other live project) until either: (a) `/apex:start` runs cleanly with the updated init, or (b) someone manually adds the fields, or (c) Round 3.4's validator catches the omission and forces correction. The breakers logic in resume.md will read undefined values and the null-guard will short-circuit — meaning A-5 is "safe" but unverified.

**Generalizes to:** Any future schema additions will face the same problem. Agents that reconstruct state files do not consult templates.

**Ideal behavior.** When state files are missing or corrupt, reconstruction follows an authoritative template. The template is either `start.md` init OR `framework/schemas/STATE.schema.json` with default values OR a dedicated `STATE-template.json` reference file.

**How the agent can verify the gap exists:**
```bash
# 1. Read Shield's STATE.json
jq '.autopilot' shield/.apex/STATE.json 2>&1
# Expected: shows autopilot block, but DOES NOT include previous_last_completed_task

# 2. Compare to start.md init
grep -A 20 "autopilot:" framework/commands/apex/start.md
# Expected: start.md DOES include the new fields

# 3. The mismatch confirms the gap
```

**Proposed fix.** This gap is best solved as a side-effect of Round 3.4 (schema enforcement). Specifically: when the validator runs and finds missing required fields, it should either auto-repair (insert defaults from schema) or fail-loud and instruct the user to run `/apex:start --repair`. Either path makes NEW-1 detectable and recoverable.

> ⚠️ **OPEN FOR CRITIQUE.** Four considerations:
>
> 1. **Don't fix this in isolation.** The temptation is to add a "regenerate STATE.json from start.md" command. Don't. The right fix is the validator from Round 3.4. Wait for that round.
>
> 2. **Manual workaround for now.** Until Round 3.4 lands, document that users should manually inject the new fields after a Round update. Add a section to the round closure docs: "Post-Round Manual Steps for Live Projects".
>
> 3. **Generalizes beyond A-5.** Anti-pattern named: "Schema-by-Memory Reconstruction". Document in apex-learnings.md when the catalog is built (Round 3.5 or later).
>
> 4. **Verify this is actually how the agent rebuilt STATE.json.** I inferred this from the diff in the checkpoint logs. Re-read the agent's actions during 07-10 and confirm the reconstruction path. If I'm wrong about the mechanism, the fix is wrong.

**Validation after fix (post-Round 3.4):**
```bash
# 1. Manually corrupt Shield's STATE.json (remove autopilot.previous_last_completed_task)
# 2. Trigger any hook that runs the validator
bash ~/.claude/hooks/pre-task-snapshot.sh test-task
# Expected: exit 2, error names the missing field
```

---

### NEW-2 — Reflexion → retry pipeline can be bypassed by orchestrator convenience

| Field | Value |
|---|---|
| Source | Checkpoint 2026-04-10, /apex:next 07-10 critic FAIL handling |
| Status | Open — design question |
| Severity | Medium |
| Round | 3.3+ |

**The gap.** When critic returned FAIL on task 07-10 with a stale-closure bug, the orchestrator did not invoke the C-3 reflexion → executor-retry pipeline. Instead it edited the file directly with three Update calls, ran tsc, and re-invoked critic. The pipeline we built for fault tolerance lay dormant.

**Impact.** Round 3.2's C-3 fix is silently untested. The reflexion → retry path has working code but zero production exercise. A more complex bug that the orchestrator cannot fix directly will be the first true test — and if there's a subtle bug in the pipeline, that first encounter is when we'll find it.

**Generalizes to:** Any future self-healing pipeline. The orchestrator will preempt them when the fix is "obvious".

**Ideal behavior.** Either: (a) orchestrator follows the formal pipeline always (pure but inflexible), OR (b) orchestrator bypasses are logged so we can measure bypass rate and validate pipeline behavior in synthetic tests, OR (c) a flag forces pipeline mode for validation runs.

**How the agent can verify the gap exists:**
```bash
# 1. Find the C-3 phantom-check + reflexion block in next.md
grep -B 2 -A 30 "PHANTOM CHECK\|phantom-check.sh" framework/commands/apex/next.md

# 2. Read the actual orchestrator behavior in the 07-10 transcript
# (manual review of the checkpoint logs)
```
**Expected if gap is real:** The pipeline code exists in next.md but the orchestrator's runtime behavior shows a different (shorter) recovery path on simple FAILs.

**Proposed fix.** Three-track approach:
1. **Add pipeline-bypass logging.** When the orchestrator chooses to fix directly instead of invoking the pipeline, write a log entry to `.apex/SESSION-LOG.md` noting "pipeline bypass: simple fix path". This creates measurement data without changing behavior.
2. **Add a synthetic test in health-check.** TEST 11 or 12: deliberately trigger a critic FAIL that requires reflexion, verify the pipeline runs end-to-end. This validates the pipeline without depending on production exercising it.
3. **(Optional) Add a `force_pipeline = true` flag.** For test runs only. Disable the orchestrator's bypass shortcut. Use during Round 3.4 validation.

> ⚠️ **OPEN FOR CRITIQUE.** Four considerations:
>
> 1. **Is bypass actually a problem?** The 07-10 case had a correct outcome. The orchestrator made a good decision. Punishing good decisions to validate the pipeline may be the wrong tradeoff. Consider: maybe the validation should happen in synthetic tests only, never in production.
>
> 2. **Logging the bypass is the safest first step.** It creates data without affecting behavior. Once we have a few weeks of bypass-rate data, we can decide whether to enforce the pipeline or accept bypass as the norm.
>
> 3. **The orchestrator's bypass is not a bug — it's an emergent optimization.** Treating it as a bug risks degrading framework usability. Frame this gap as "we don't have measurement", not "the orchestrator is doing the wrong thing".
>
> 4. **Anti-pattern named:** "Pipeline Bypass via Orchestrator Convenience". Document in apex-learnings.md.

**Validation after fix:**
```bash
# 1. Bypass logging exists
grep -n "pipeline bypass\|PIPELINE_BYPASS" framework/commands/apex/next.md

# 2. Synthetic test in health-check passes
# Run /apex:health-check on a project, observe TEST 11/12 (reflexion pipeline)

# 3. After a week of normal usage, check the SESSION-LOG.md for bypass entries
grep -c "pipeline bypass" .apex/SESSION-LOG.md
# This is measurement, not a pass/fail criterion
```

---

### NEW-3 + NEW-7 — STATE.json corruption and write-conflicts on OneDrive

| Field | Value |
|---|---|
| Source | Checkpoint 2026-04-10, multiple incidents |
| Status | Open — environment finding, not framework |
| Severity | Medium-high (silent data loss risk) |
| Round | Environment hardening (no specific round) |

**The gap.** Shield's `.apex/STATE.json` was empty (0 bytes) at the start of the 2026-04-10 health-check. Twice during task 07-11, agent encountered "File has been modified since read" errors on the same file. Both symptoms point to OneDrive sync interference: the project lives in `OneDrive - Tiva 13 Engineers/...` and the OneDrive agent races with hook writes.

**Impact.** Latency, retry overhead, and — most concerning — silent data loss. The 0-byte STATE.json wiped historical state until the orchestrator reconstructed it from PLAN_META (which itself surfaced NEW-1). If the next `/apex:start` had run on the empty file, more state would have been lost.

**Ideal behavior.** Either (a) `.apex/` is excluded from OneDrive sync, OR (b) APEX hooks have retry-on-conflict logic for state file writes, OR (c) Shield is relocated outside OneDrive entirely.

**How the agent can verify the gap exists:**
```bash
# 1. Check Shield's location
realpath shield 2>&1
# Expected: includes "OneDrive" in the path

# 2. Check if .apex/ is excluded from OneDrive sync
# (Windows-specific: check OneDrive settings or attribute flags)
attrib shield/.apex 2>&1 | grep -i "exclud"
```
**Expected if gap is real:** Shield is on OneDrive, .apex/ is not excluded.

**Proposed fix (3 tracks).**

**Track A — Exclude .apex/ from OneDrive sync.** Most invasive but most effective. Windows: right-click `.apex/`, OneDrive → "Free up space" or "Always keep on this device" + add to exclusion list. macOS/Linux: similar.

**Track B — Add retry-on-conflict logic to state-update hooks.** All hooks that read+modify+write state files should:
1. Read state file with timestamp/hash
2. Modify in memory
3. Write with optimistic lock check (re-read, verify hash unchanged, write only if so)
4. On conflict: retry up to 3 times with backoff

**Track C — Relocate Shield outside OneDrive.** Most disruptive (breaks the user's existing workflow) but most reliable. Move to `~/projects/shield` or similar.

> ⚠️ **OPEN FOR CRITIQUE.** Five considerations:
>
> 1. **This is environment, not framework.** APEX should not have OneDrive-specific code. Track B (retry logic) is the only framework-level fix, but it adds complexity for a problem that's localized to one user's setup.
>
> 2. **The user prefers not to relocate Shield.** Confirmed in earlier conversations. Track C is off the table unless the user explicitly approves.
>
> 3. **Track A is the right answer for Shield specifically.** Single-user, single-project, simple to do. But it doesn't generalize — if the framework is used by other people on OneDrive, they'll hit the same issue.
>
> 4. **Track B's retry logic is a real engineering project.** Bash optimistic locking with hashes is doable but tricky. Probably worth a Round 3.6 or later, not now.
>
> 5. **The data-loss risk is real.** Whatever path is chosen, do it before the next major round. Ignoring this means accepting that any session might lose state.

**Validation after fix:**
```bash
# Track A:
# 1. Verify .apex/ is excluded from sync
# 2. Run multiple sessions, verify no "modified since read" errors
# 3. Run /apex:status repeatedly, verify STATE.json is never empty

# Track B:
# 1. Synthetic test: rapidly modify STATE.json from two processes
# 2. Verify hook retries and eventually succeeds
# 3. Verify state is consistent after the dust settles
```

---

### NEW-4 — Path drift inside Shield's phase 7 directory structure

| Field | Value |
|---|---|
| Source | Checkpoint 2026-04-10, /apex:status |
| Status | Open — historical, low severity |
| Severity | Low |
| Round | Category B (or 3.5 cosmetic) |

**The gap.** Shield's tasks 07-01 through 07-03 are stored at `.apex/phases/07-XX-CRITIC.md` (flat). Tasks 07-04 through 07-11 are at `.apex/phases/07/07-XX-CRITIC.md` (nested in `07/` subdirectory). The structure changed mid-phase, between task 07-03 and 07-04.

**Impact.** Cosmetic. Audit/grep across phase files is harder because they're in two locations. No functional impact.

**Ideal behavior.** All phase files for phase 07 in one location. Probably the nested layout (`07/07-XX-*`), since that's what the more recent hook code produces.

**How the agent can verify the gap exists:**
```bash
ls shield/.apex/phases/07-*.md 2>&1
ls shield/.apex/phases/07/ 2>&1
```
**Expected if gap is real:** Both directories contain phase 07 files.

**Proposed fix.** Move the 3 flat files into the nested directory:
```bash
mv shield/.apex/phases/07-01-CRITIC.md shield/.apex/phases/07/
mv shield/.apex/phases/07-02-CRITIC.md shield/.apex/phases/07/
mv shield/.apex/phases/07-03-CRITIC.md shield/.apex/phases/07/
```
And commit as "chore: consolidate phase 07 files into nested directory".

> ⚠️ **OPEN FOR CRITIQUE.** Three considerations:
>
> 1. **What changed mid-phase?** Identify WHICH hook commit moved from flat to nested layout. If it was Round 2 (likely), we should document the migration. If we don't know, future drift will repeat.
>
> 2. **Are there RESULT.json files for 07-01 to 07-03?** The grep showed only CRITIC.md files in flat layout. If RESULT files are missing entirely (not in either location), that's a different gap. Verify before assuming "just move them".
>
> 3. **This is Shield-specific.** Don't bake into framework. Just move the files.

**Validation after fix:**
```bash
# 1. All phase 07 files in one location
ls shield/.apex/phases/07/
# Expected: all 11 task files (07-01 through 07-11), one directory

# 2. Flat location is empty of phase 07 files
ls shield/.apex/phases/07-*.md 2>&1
# Expected: no matches
```

---

### NEW-5 — `/apex:status` cockpit doesn't render new A-5 autopilot fields

| Field | Value |
|---|---|
| Source | Checkpoint 2026-04-10, /apex:status output |
| Status | Open |
| Severity | Low |
| Round | 3.5 |

**The gap.** The status cockpit's AUTOPILOT block shows existing fields (`tasks_completed_in_autopilot`, `phases_completed_in_autopilot`, `advisor_risk_score`) but does not show the two fields added in Round 3.2 A-5 (`previous_last_completed_task`, `previous_tasks_completed_in_autopilot`). Even when these fields exist in STATE.json, the user can't see them in the cockpit.

**Impact.** Low. The breakers work invisibly; the user has no diagnostic view of "what does the breaker logic see?". When debugging a breaker firing, the user would have to read STATE.json directly.

**Ideal behavior.** The AUTOPILOT block in the cockpit shows both current and previous values for the fields the breakers compare:
```
Last completed task               07-08
Previous last completed task      07-07
Tasks completed in autopilot      8
Previous (last session)           5
```

**How the agent can verify the gap exists:**
```bash
# 1. Read status.md template
grep -A 10 "AUTOPILOT" framework/commands/apex/status.md

# 2. Compare to A-5 fields
grep "previous_" framework/commands/apex/start.md
```
**Expected if gap is real:** status.md AUTOPILOT block does not reference `previous_*` fields.

**Proposed fix.** Add 2 lines to the AUTOPILOT block in status.md template, displaying both fields with an "(previous session)" qualifier. Match existing visual style.

> ⚠️ **OPEN FOR CRITIQUE.** Two considerations:
>
> 1. **Cockpit width constraint.** The cockpit lines have a fixed width. New fields must fit. Use the same character-counting discipline as Round 3.1 branding cards.
>
> 2. **Sequencing.** This is naturally part of Round 3.5 UX consistency. Don't fix in isolation — batch with other status.md improvements (NEW-6 for example).

**Validation after fix:**
```bash
# 1. New fields appear in cockpit template
grep -A 12 "AUTOPILOT" framework/commands/apex/status.md
# Expected: includes "Previous last completed" and similar

# 2. Run /apex:status on Shield, observe new fields rendering
# (manual test, requires Shield's STATE.json to have the fields populated)
```

---

### NEW-6 — Health-check TEST 3 expectation drift (CRITICAL vs MAJOR)

| Field | Value |
|---|---|
| Source | Checkpoint 2026-04-10, /apex:health-check TEST 3 |
| Status | Open |
| Severity | Low (latent risk) |
| Round | 3.5 |

**The gap.** TEST 3 in health-check.md expects critic to return MAJOR for phantom verification language. After Round 3.2 C-14 (scoped phantom-scan), critic now returns CRITICAL — stricter than the test expects. The test currently records this as PASS because "stricter than expected is still PASS", but the documented expectation is now stale. A future contributor might "fix" the discrepancy by making critic less strict, regressing post-Round-3.2 behavior.

**Impact.** Latent. Active risk: someone misreads the test expectation as the spec, weakens critic, undoes Round 3.2 silently.

**Ideal behavior.** TEST 3 expectation matches actual post-Round-3.2 critic behavior. Test text should say "Expected: CRITICAL — phantom verification language detected".

**How the agent can verify the gap exists:**
```bash
# 1. Read TEST 3 in health-check.md
grep -B 2 -A 10 "TEST 3" framework/commands/apex/health-check.md

# 2. Check expected severity
grep -A 3 "Expected:" framework/commands/apex/health-check.md | head -5
```
**Expected if gap is real:** TEST 3 says "Expected: MAJOR" while runtime returns CRITICAL.

**Proposed fix.** Update TEST 3 expectation in health-check.md from MAJOR to CRITICAL. Add a comment noting the change happened in Round 3.2 with the C-14 scoping.

> ⚠️ **OPEN FOR CRITIQUE.** Two considerations:
>
> 1. **Verify the post-Round-3.2 behavior is intentional, not accidental.** Maybe critic SHOULDN'T be returning CRITICAL — maybe it's overcorrecting after the C-14 scoping. Read the critic's reasoning in TEST 3's output before changing the expectation. If it's overcorrecting, the fix is in critic.md, not in health-check.md.
>
> 2. **Document the rationale.** Whatever the test expects, add a one-line comment explaining why. Otherwise this drifts again.

**Validation after fix:**
```bash
# 1. Test expectation matches reality
grep -A 3 "TEST 3" framework/commands/apex/health-check.md
# Expected: "Expected: CRITICAL"

# 2. Re-run health-check, confirm TEST 3 reports as PASS without "stricter than expected" qualifier
# (manual run of /apex:health-check)
```

---

## Part 6 — Round 3.2 Pending Validations

These are not gaps. They are **validations not yet performed** for Round 3.2 fixes. Each one is waiting for a specific scenario to trigger it. Tracking them here so they don't get lost.

### W-1 — B-4 subagent-stop 3-way exit branch

**Status:** ⏸️ Not triggered in any session yet
**Trigger needed:** A subagent that returns with either (a) git error, OR (b) zero file changes after claiming work
**How to validate:** Force a scenario. Either run a task in a non-git directory, OR set up a critic that returns success without modifications. Observe whether subagent-stop emits exit 1 (advisory) or exit 2 (blocking) appropriately.
**Why it matters:** The whole point of B-4 was to distinguish git errors from real hallucinations. Until we see both paths fire, we don't know if the distinction works in practice.

### W-2 — B-1 phase-tag.sh filesystem verification

**Status:** ⏸️ Not triggered (Shield's phase 7 hasn't closed yet)
**Trigger needed:** Phase 7 of Shield (or any phase of any project) closes via `/apex:next` final task. phase-tag.sh runs and exercises the new `git tag -l | grep -qF` filesystem-verification logic.
**How to validate:** Complete task 07-09 (RTL audit sweep). Observe phase-tag.sh execution at phase end. Verify tag is created AND verified.
**Why it matters:** B-1 was a logic-level fix to trust patterns. The fix works in code but has not been exercised on a real phase boundary.

### W-3 — C-2 /apex:quick snapshot insertion

**Status:** ⏸️ Not triggered (no /apex:quick runs in this session)
**Trigger needed:** Run `/apex:quick` on any task.
**How to validate:** After phase 7 closes, use `/apex:quick` for a small ad-hoc edit on Shield. Observe pre-task-snapshot.sh firing as step 2.
**Why it matters:** /apex:quick was the riskier command without snapshot coverage. Validating that the snapshot fires before any quick task confirms the rollback safety net is in place.

### W-4 — A-5 resume.md autopilot breakers

**Status:** ⚠️ Cannot validate yet — blocked by NEW-1
**Blocker:** Shield's STATE.json doesn't contain the new fields, so the breakers will read undefined and short-circuit on the null-guard. This is "safe" behavior, but it's not a validation.
**How to validate:**
- Option A: Manually inject the two fields into Shield's STATE.json (~1 minute)
- Option B: Run `/apex:start` cleanly on a fresh test project
- Then run a session that completes at least 1 task in autopilot mode, then trigger `/apex:resume` and observe breakers
**Why it matters:** A-5 was the most complex Round 3.2 fix. The "success path only" snapshot-refresh logic has critical-ordering invariants that need real exercise to verify they hold.

---

## Part 7 — Anti-Pattern Catalog Candidates

Six patterns identified during this work that are candidates for documentation in `framework/apex-learnings.md` when the catalog work is tackled (probably late Round 3.5 or a dedicated docs round).

### AP-1 · The Silent Install Failure

**Status:** Already documented in DEFERRED-002 from Round 2

**Pattern.** A package manager (winget, apt, brew, etc.) reports "successfully installed" but the binary is not actually present in PATH. The user sees green checkmarks; the framework runs degraded.

**Mitigation.** After every install, verify the binary is callable: `command -v <tool>` and `<tool> --version`. Don't trust installer output.

**Example.** Round 2 jq installation drama: `winget install jqlang.jq` succeeded, but `/c/Users/<user>/Links/` was empty and PATH didn't pick up jq. Manual copy to `/c/Users/<user>/bin/jq.exe` resolved.

---

### AP-2 · Pattern-Echo Hallucination

**Status:** Caught during Round 3.2 Cluster 2 Discovery, not yet documented in catalog

**Pattern.** When working on a series of similar fixes, an agent (or human) develops a mental template ("this pattern needs X, Y, Z applied"). On a later iteration, the agent applies the template without checking whether the target file already had X, Y, or Z applied in an earlier round. Result: duplicate fixes, false-positive findings, or actual bugs from double-application.

**Mitigation.** "Read before edit" is the only defense. Every Discovery Pass must include a re-read step that verifies the gap still exists in current code, not just in audit notes.

**Example.** During Round 3.2 Cluster 2 Discovery, the proposed B-1 fix included "add `_require-jq.sh` source to phase-tag.sh". The agent caught the error before editing — phase-tag.sh already had the source, added in Round 2's jq sweep. The Discovery Pass had pattern-matched to the Round 2 template instead of reading current state.

**Sibling of:** AP-1 (Silent Install Failure). Both are about "assume vs verify".

---

### AP-3 · Implicit Write Chain

**Status:** Caught during Round 3.2 Cluster 1 (C-3 implementation), not yet documented

**Pattern.** A multi-step pipeline has implicit dependencies where Step N writes a file that Step N+1 expects to read. When a fix bypasses Step N (for any reason), the file isn't written, and Step N+1 fails — but the failure is far from the cause and hard to diagnose.

**Mitigation.** Document write chains explicitly. When a step writes a file, the writing should be visible in the step's documentation, not buried in code. When designing a bypass, audit what side-effects are being skipped.

**Example.** During C-3 implementation, the agent discovered that critic.md:74 has "ON FAIL → write REFLEXION.md". The C-3 fix proposed to bypass critic on phantom detection — but bypassing critic would skip the REFLEXION.md write, breaking the FAIL handler downstream that expects the file. Solution: synthesize REFLEXION.md AND CRITIC.md inside the phantom-check block before bypassing.

---

### AP-4 · Schema-by-Memory Reconstruction

**Status:** New, identified in NEW-1, not yet documented

**Pattern.** When a state file (like STATE.json) is missing or corrupt, an agent reconstructs it using its trained memory of "what this file looks like" rather than consulting an authoritative template (start.md init or schema). The reconstruction lags behind the framework — fields added in recent rounds are silently omitted.

**Mitigation.** Authoritative templates must be discoverable and consulted during reconstruction. Schema enforcement (Round 3.4) is the structural fix. Until then, document that reconstruction-from-memory is a known failure mode and add post-reconstruction validation.

**Example.** During checkpoint 2026-04-10, Shield's STATE.json was empty. The orchestrator rebuilt it with 90 lines but did not include the two fields added in Round 3.2 A-5. Memory-driven reconstruction silently degraded the framework's safety net.

---

### AP-5 · Pipeline Bypass via Orchestrator Convenience

**Status:** New, identified in NEW-2, not yet documented

**Pattern.** A self-healing pipeline is built for fault tolerance (e.g., reflexion → retry on critic FAIL). At runtime, the orchestrator encounters a simple instance of the trigger condition and decides to fix directly instead of invoking the pipeline. The pipeline lies dormant despite being needed in principle.

**Mitigation.** Validate pipelines in synthetic tests, not in production exercise. Log bypass events to measure bypass rate. If bypass rate is high, decide whether to enforce the pipeline OR accept that it's insurance code.

**Example.** During task 07-10 critic FAIL on Shield, the C-3 reflexion → retry pipeline did not fire. The orchestrator edited the file directly and re-invoked critic. The pipeline we built less than 24 hours earlier received zero validation in production.

---

### AP-6 · The Unchecked Audit

**Status:** New, identified during Round 3.1 (audit was wrong about critic/verifier) and Round 3.2 (Pattern-Echo), not yet documented

**Pattern.** A static analysis pass (audit, linter, security scan) produces findings that are treated as authoritative. Subsequent work uses the audit's claims without re-verifying against current code. When the audit is wrong (stale, mistaken, or based on misreading), all downstream work inherits the error.

**Mitigation.** Audit reports need their own verification step. When acting on a finding, the first action is "re-read the file and confirm the finding still applies" — not "open the file and apply the fix from the audit description". Treat audits as hypotheses, not facts.

**Example.** AUDIT-2026-04-09 claimed critic and verifier were missing from `apex-model-routing.json`. Round 3.1 discovered they were present. The audit was wrong by static analysis error. Without re-verification, Round 3.1 would have proposed adding them as duplicates or "fixing" them in ways that broke working code.

---

## Part 8 — Category B: Technical Debt Backlog

Lower-severity findings from the original audit, deferred from Rounds 3.0–3.5. Listed here for completeness; each is a one-paragraph entry, not full treatment. Prioritize when planning Round 4+ or maintenance windows.

### H-1 — `jq | mv` duplication in 6 hooks
Six hooks have the pattern `jq ... > /tmp/x.json && mv /tmp/x.json file.json` repeated. Should be a helper function `state_update`. **Fix idea:** Add to `_state-helpers.sh`. **Why deferred:** Refactor, not bug.

### B-5 — pre-task-snapshot reports "working tree clean" on git error
After Round 2 + Round 3.2 work, `pre-task-snapshot.sh` may still report "working tree clean" when git itself errored. Same root cause as B-4 (subagent-stop). **Fix idea:** Apply the 3-way exit pattern. **Why deferred:** Lower-impact than B-4 because pre-task-snapshot's failure is not as silent.

### B-6 — `cross-phase-audit` runs `bash -c` from PLAN_META
Scripts read from JSON state files and `eval`-ed in bash. Allowlist exists but is incomplete. **Fix idea:** Reject any command not in an explicit allowlist; expand allowlist incrementally. **Why deferred:** Security concern but not actively exploited.

### B-7 — `destructive-guard.sh` naive string splitting
The hook splits command strings on spaces to detect dangerous patterns. Fails on quoted arguments, escaped spaces. **Fix idea:** Use bash arrays or proper tokenization. **Why deferred:** Edge case, low frequency.

### B-9 — `generate-task-map.sh` header-only output not flagged
When the hook can't resolve any files, it writes a header-only TASK_MAP.md and exits 0. The user has no signal that mapping failed. **Fix idea:** Print a warning when output is header-only. **Why deferred:** Informational; doesn't break flow.

### B-10 — `pre-compact.sh` "State backed up" with cp that failed
Hook reports "State backed up" but doesn't check whether the underlying `cp` succeeded. **Fix idea:** Capture cp exit code, fail-loud on failure. **Why deferred:** Same pattern as Round 2 fixes; should be batched with similar work.

### B-11 — `circuit-breaker.sh` jq recovery missing
When jq fails midway through circuit-breaker logic, the hook can leave STATE.json in inconsistent state. **Fix idea:** Atomic write pattern (tmp file + mv). **Why deferred:** Low frequency, recovery is via manual STATE.json edit.

### A-6 — `architect.md` asks for duplication detection from git
The architect prompt asks the agent to "check git history for duplication" — but git doesn't have a duplication-detection feature. The request is impossible to fulfill literally. **Fix idea:** Replace with a concrete tool (`jscpd` or `simian` or grep pattern). **Why deferred:** Architects work around it currently.

### A-7 — `verifier.md` mixes stat epoch with git --since
Verifier prompt mixes filesystem timestamps (stat) with git's `--since` time selector. Different time bases produce inconsistent results. **Fix idea:** Pick one (probably git, since it's the system of record). **Why deferred:** Edge case in verifier behavior.

### C-5 — ✅ vs ✓ icon drift in hooks
Different hooks use different success icons. **Fix idea:** Standardize on one (probably ✅ for visibility). **Why deferred:** Pure cosmetic.

### C-6 — R12 Hebrew text inside ASCII frames (Live Ticker exception)
The R12 doctrine says Hebrew text should be outside ASCII frames (because frame chars don't render correctly with RTL). The Live Ticker block in status.md is an exception that should be either fixed or documented. **Fix idea:** Move Hebrew text outside the frame, OR document the exception explicitly. **Why deferred:** Visual quirk.

### C-7 — `health-check.md` TEST 9 subjective pass criterion
TEST 9's "clean-room more thorough than contaminated" is a qualitative check. Currently the framework records PASS based on "9B found 50% more issues" — but 50% is not a documented threshold. **Fix idea:** Document the threshold OR replace with a quantitative metric. **Why deferred:** Test currently passes; threshold formalization is polish.

### C-15 — Specialists missing RESULT schema reminder
Each specialist agent prompt should include a reminder of the RESULT.json schema (so they emit valid output). Some are missing this. **Fix idea:** Add the schema reminder to all 4 specialist files. **Why deferred:** Specialists currently emit valid output via memory; will become important after Round 3.4 schema enforcement.

### F-2 — `maxTurns` vs `max_turns` casing drift
Some configs use camelCase, others use snake_case for the same concept. **Fix idea:** Standardize on one. **Why deferred:** Cosmetic.

### G-2/G-3/G-4 — More environment robustness gaps
Various smaller environment issues (PATH handling, working directory assumptions, OS-specific behaviors). **Fix idea:** Group with G-1 in Round 3.3, OR defer to a "Windows compatibility" round. **Why deferred:** Triage individually.

### H-2/H-4 — Minor cleanup
Old comments referring to deleted features, unused variables, dead branches. **Fix idea:** Code cleanup pass. **Why deferred:** No functional impact.

---

## Part 9 — Minor Observations & Cosmetic Items

Items observed during Round 3.2 execution that are below Category B threshold but worth tracking.

### MIN-1 — `phase-tag.sh` missing final newline
Both before and after the Round 3.2 B-1 rewrite, the file ends with no newline. Cosmetic. **Fix:** Add newline. **When:** Next time the file is touched.

### MIN-2 — `phase-tag.sh:13` uses `grep -q` instead of `grep -qF`
The early-exit branch (when tag already exists) uses `grep -q "$TAG_NAME"`, treating the tag name as a regex. Tag names like `apex/phase-01-complete` are regex-safe by accident, but it's fragile. The Round 3.2 rewrite used `grep -qF` for the new check. **Fix:** Apply `grep -qF` to line 13 as well. **When:** Consistency with the rest of the file.

### MIN-3 — `resume.md` "5 breakers" naming
The doc references "5 breakers" but counting carefully there are 7 distinct pause conditions (Breaker 4 has 4 sub-breakers under one heading). **Fix:** Rename to reflect the real count, OR document that "Breaker 4" is actually a category. **When:** Round 3.5 UX consistency.

### MIN-4 — `start.md:28` creates orphaned `research/` directory
`start.md` init creates `.apex/{...,research,...}` for every new project. The researcher agent was deleted in Round 3.0, so this directory is created and immediately orphaned. **Fix:** Remove `research/` from the init mkdir list. **When:** Round 3.5 or whenever start.md is touched next.

### MIN-5 — `generate-task-map.sh` argument semantics for quick tasks
Round 3.2 C-2 changed quick.md to pass `$TASK_ID` instead of literal `quick` to generate-task-map. The hook gracefully handles this (header-only fallback when no files resolve), but the behavior change isn't documented in the hook itself. **Fix:** Add a comment explaining the fallback path. **When:** Round 3.3 or 3.5.

### MIN-6 — `sync-to-claude.sh` is additive-only (no deletion)
By design (per DEV-FLOW.md), sync only copies files in. Deletions in `framework/` don't propagate to `~/.claude/`. Manual cleanup is required. This caused the post-Round-3.0 cleanup (verify-ladder-check, researcher.md). **Fix idea:** Add a `--clean` mode that detects orphaned files in `~/.claude/` and prompts for deletion. **When:** Round 4+ or maintenance.

---

## Part 10 — Recommended Sequencing

A suggested order for tackling these gaps. NOT prescriptive — adjust based on user energy, project priorities, and emerging discoveries.

### Immediate (this session or next, after current Shield work)
- **W-2** — Validate B-1 by closing Shield's phase 7 (run task 07-09)
- **W-1, W-3, W-4** — Validate remaining Round 3.2 fixes opportunistically as scenarios arise

### Round 3.3 — Environment & Phase Verification (3-4 hours)
- **G-1** — `_require-git.sh` helper + integration into 6 hooks
- **B-3** — Remove settings.json suppression (sequenced after B-2 if B-2 is moved earlier)
- **A-2** — Fix cross-phase-audit parameter passing
- **A-3** — Fix post-write.sh tsc handling
- **E-4** — Deploy CLAUDE-TEMPLATE.md (verify it's not already done)

### Round 3.4 — Schemas & Mutation Testing (5-7 hours, the heaviest)
- **D-1 to D-5** — Build validator, update schemas, wire validation
- **NEW-1** resolved as side-effect when validator runs against Shield
- **E-1 + C-1** — Wire mutation-gate, make it actually gate
- **NEW-3 + NEW-7** — Decide on OneDrive mitigation BEFORE this round (heavier writes)

### Round 3.5 — UX Consistency (3-4 hours)
- **C-4** — Mission Briefing rollout to 4 commands
- **B-2** — Fix verify-learnings regex
- **A-4** — Fix executor TDAD pattern
- **A-8** — Fix circuit-breaker empty diff
- **NEW-5** — Add A-5 fields to status.md cockpit
- **NEW-6** — Update health-check TEST 3 expectation
- **MIN-3, MIN-4** — Cosmetic cleanups

### Round 3.6 (or maintenance window)
- Anti-pattern catalog: document AP-1 through AP-6 in apex-learnings.md
- **NEW-2** — Bypass logging or synthetic test (decision required)
- **NEW-4** — Shield path drift cleanup
- Category B items as time permits

### Environment hardening (parallel to framework work, requires user)
- **NEW-3 + NEW-7** — Exclude `.apex/` from OneDrive sync (Track A) OR relocate Shield (Track C)

---

## Index of All Gap IDs

| ID | Title | Round | Severity |
|---|---|---|---|
| **From original audit (still open)** | | | |
| G-1 | Git not checked at runtime in 6 hooks | 3.3 | M-H |
| B-3 | verify-learnings.sh fail-silent in settings.json | 3.3 | M |
| A-2 | cross-phase-audit called without parameter | 3.3 | M |
| A-3 | post-write.sh tsc print-only | 3.3 | M |
| E-4 | CLAUDE-TEMPLATE.md not deployed | 3.3 | M-H |
| D-1 to D-5 | Schemas orphaned and drifted | 3.4 | H |
| E-1 + C-1 | mutation-gate dead code + misleading name | 3.4 | M-H |
| C-4 | R13 Mission Briefing only in next.md | 3.5 | L-M |
| B-2 | verify-learnings regex broken | 3.5 (or earlier) | M |
| A-4 | executor TDAD multi-line pattern | 3.5 | M |
| A-8 | circuit-breaker empty diff false-trigger | 3.5 | M |
| **From checkpoint 2026-04-10 (NEW-*)** | | | |
| NEW-1 | Schema-by-Memory Reconstruction | 3.4 | M-H |
| NEW-2 | Pipeline Bypass via Orchestrator | 3.3+ | M |
| NEW-3 | OneDrive STATE.json corruption | Env | M-H |
| NEW-4 | Shield phase 7 path drift | Cat B | L |
| NEW-5 | A-5 fields not in status cockpit | 3.5 | L |
| NEW-6 | Health-check TEST 3 expectation drift | 3.5 | L |
| NEW-7 | OneDrive write conflicts | Env | M-H |
| **Round 3.2 pending validations (W-*)** | | | |
| W-1 | B-4 subagent-stop 3-way | n/a | track |
| W-2 | B-1 phase-tag verification | n/a | track |
| W-3 | C-2 quick snapshot | n/a | track |
| W-4 | A-5 resume breakers | n/a | track |
| **Anti-pattern catalog (AP-*)** | | | |
| AP-1 | Silent Install Failure | n/a | doc |
| AP-2 | Pattern-Echo Hallucination | n/a | doc |
| AP-3 | Implicit Write Chain | n/a | doc |
| AP-4 | Schema-by-Memory Reconstruction | n/a | doc |
| AP-5 | Pipeline Bypass | n/a | doc |
| AP-6 | The Unchecked Audit | n/a | doc |
| **Category B (briefer treatment)** | | | |
| H-1 | jq \| mv duplication | Cat B | L |
| B-5 | pre-task-snapshot working tree clean on git error | Cat B | L-M |
| B-6 | cross-phase-audit bash -c allowlist | Cat B | M |
| B-7 | destructive-guard naive splitting | Cat B | L |
| B-9 | generate-task-map header-only silent | Cat B | L |
| B-10 | pre-compact "State backed up" cp failure | Cat B | L-M |
| B-11 | circuit-breaker jq recovery missing | Cat B | L |
| A-6 | architect duplication from git | Cat B | L |
| A-7 | verifier stat vs git --since | Cat B | L |
| C-5 | Icon drift ✅ vs ✓ | Cat B | L |
| C-6 | R12 Hebrew in frames (Live Ticker) | Cat B | L |
| C-7 | TEST 9 subjective pass | Cat B | L |
| C-15 | Specialists missing RESULT schema | Cat B | L |
| F-2 | maxTurns/max_turns casing drift | Cat B | L |
| G-2/3/4 | More environment robustness | Cat B | L-M |
| H-2/H-4 | Minor cleanup | Cat B | L |
| **Minor observations (MIN-*)** | | | |
| MIN-1 | phase-tag.sh missing final newline | Cat B | trivial |
| MIN-2 | phase-tag.sh line 13 grep -q | Cat B | trivial |
| MIN-3 | resume.md "5 breakers" naming | 3.5 | trivial |
| MIN-4 | start.md research/ orphaned dir | 3.5 | L |
| MIN-5 | generate-task-map quick semantics | 3.3/3.5 | L |
| MIN-6 | sync-to-claude.sh additive-only | 4+ | L-M |

**Total tracked items: ~45 distinct gaps + 4 pending validations + 6 anti-patterns = ~55 items**

---

## Document Provenance

**Created:** 2026-04-10
**Generated by:** Comprehensive review of: AUDIT-2026-04-09, Round 3.0/3.1/3.2 closure reports, CHECKPOINT-FINDINGS-2026-04-10, runtime checkpoint observations, and meta-discoveries during execution.
**Living document:** This file should be updated as gaps close and new ones surface. Add a CHANGELOG section at the bottom when first edited.
**Cross-references:**
- `AUDIT-2026-04-09.md` — Original 59-finding static audit
- `CHECKPOINT-FINDINGS-2026-04-10.md` — Runtime checkpoint findings
- `framework/apex-learnings.md` — Where AP-* entries should eventually land

**The author of this document is Claude Sonnet 4.6, working as advisor to David on the APEX framework. Every entry's "Proposed fix" section is OPEN FOR CRITIQUE — read carefully, verify against current code, propose alternatives. The Pattern-Echo Hallucination of Round 3.2 Cluster 2 is the standing reminder that "obvious" fixes can be wrong.**

---

**END OF DOCUMENT**
