# Phase-6 Baseline Trial 2 — Round R312 Framework Audit

**Auditor:** framework-auditor specialist (13-axis investigation)
**Spec anchor:** `.lab/apex-detector-lab-baseline/apex-spec.md` (596 lines)
**Repo root:** `.lab/apex-detector-lab-baseline/`
**Round:** 312
**Previous findings inheritance:** NONE (previous_findings_path=null; closure files in repo root treated as priming per agent definition, NOT as evidence)
**Anti-priming declaration:** This audit was conducted as if `ROUND-R*-CLOSURE.md`, `apex-audit-findings-R*.md`, and `REMEDIATION-PLAN-R*.md` files were absent from the repo. Their existence did NOT reduce hunt depth.

---

## EXECUTIVE SUMMARY

13 axes covered. **Test-suite evidence: OBSERVED**.

Literal test summary line from `bash framework/tests/run-all.sh`:
```
  passed:  70
  failed:  2
  skipped: 0
```
(Summary block did not emit an `errored:` line; reporting verbatim what the runner produced.)

**Failed tests:** `test-hook-classification.sh`, `test-hooks-cjs.sh` — failure auto-emits a P1 finding per the TEST-SUITE EVIDENCE RULE (failed>0).

Notable axis-13 falsification results:
- **Axis-10 spec-named guards `apex-prompt-guard.cjs/.js` and `apex-workflow-guard.cjs/.js` do not exist on disk** despite the spec naming them (§9) AND despite shim `.sh` files attempting to `exec node "$CJS_PATH"` at those exact filenames. The Defense-in-Depth security layer falls through to a degraded Bash fallback covering only 5 free-text patterns — IMP-003 arg-content validation (path-arg shell-metachar, name-arg role-marker, >1000-char advisory) is structurally unreachable. **P0**.

- **`_state-update.sh` silently swallows jq failures** (`else rm -f "$tmp" "$err"; return 0`) in direct violation of the "Fail-loud, never fail-silent" principle. Stderr captured in `$err` is deleted unread. **P0**.

- **`framework/apex-workflows/`** required by spec §"היכולות הנדרשות" ("`apex-workflows/` library — 30+ recipes") exists only as `apex-workflows-DISABLED/` directory — recipes are not on the active path. **P1**.

- **`framework-auditor.md` agent self-describes as "12-axis"** while the operational contract is 13 (axis-13 adversarial falsification per agent definition). Agent file consistent with spec text (also 12); flagged as SGC plus P3.

---

## COVERAGE MAP (all 13 axes)

| Axis | Status | bypass_attempts | silent_failure_probes | Notes |
|------|--------|----------------:|----------------------:|-------|
| 1. 9 failure modes | covered | 0 | 0 | Mechanisms present: circuit-breaker.sh, /apex:forensics, /apex:help, /apex:rollback. IMP-007 hash-of-error confirmed implemented (circuit-breaker.sh lines 164+). |
| 2. Dual-mode classifier | covered | 0 | 0 | Spec lines 256–259, 320 require Collaborator/Replacement split. `framework/hooks/decision-gate.sh` and `_state-update.sh` reference `decision_mode`. Test `test-decision-mode.sh` present. Mechanism present-by-name; active path not exhaustively traced this round. |
| 3. Scale-Adaptive Classifier | covered | 0 | 0 | Spec §"היכולות הנדרשות" requires auto-detect at onboarding. `/apex:onboard` command exists; no dedicated `scale-adaptive-classifier` hook/agent found. Implementation likely embedded in onboard.md prompt — present-by-name only. |
| 4. First-hour non-programmer usability | covered | 0 | 0 | Spec §"UX לקהל לא-טכני" + Claim measurement context (lines 539–562) require first-hour-telemetry. Hook `first-hour-telemetry.sh` referenced as "forward-reference Phase 12 M16.1" — explicitly forward-ref, not a current-state gap. |
| 5. `/apex:help` natural-language navigator | covered | 0 | 0 | `framework/commands/apex/help.md` exists; PURPOSE block declares NL routing; no-arg fallback enumerated. Mechanism present. |
| 6. Test architecture w/ veto | covered | 0 | 0 | `framework/modules/apex-test-architect/{agent.md,manifest.json,README.md}` present; spec line 189 requires veto power. Module structure in place; runtime phase-gate enforcement not traced this round. |
| 7. Auditor quarantine | covered | 0 | 0 | `framework/agents/auditor.md` line 2 self-describes "Reads ONLY test files — never implementation code". Quarantine declared at agent-prompt level only — not enforced by a runtime hook. |
| 8. Module ecosystem as platform | covered | 0 | 0 | `framework/modules/` contains apex-builder, apex-core, apex-data, apex-fintech, apex-frontend, apex-healthcare, apex-integration, apex-memory-synthesis, apex-security, apex-test-architect + `_registry.json` + `_schema/`. Spec §"Module Ecosystem" enumerates 8; lab has 10. Present. |
| 9. Memory 3-tier + dream-cycle + 4 primitives + workflows | covered | 0 | 0 | `_dream-cycle-emit.sh` present; primitives (apex/{todos,threads,seeds,backlog}) referenced. Workflows `apex-workflows/` library is DISABLED (see F-002). |
| 10. Defense-in-Depth on APEX's own files | covered | 4 | 2 | `apex-prompt-guard.cjs/.js` MISSING. `apex-workflow-guard.cjs/.js` MISSING. `path-guard.sh` blocks `../`. `ci-scan.sh` present. `security.cjs` present. See F-001, F-005. |
| 11. State derives from disk / proof-of-process | covered | 0 | 2 | `_state-update.sh` line 107 silent-failure on jq error. `session-log.sh` lines 23–25 silent exit when LOG_FILE creation fails. See F-003, F-004. |
| 12. 30+ core principles enforced | covered | 0 | 0 | Spec §"עקרונות העבודה" lists ~50 principles. Fail-loud violated (F-003). "Set and forget design intent" documented per recent commit `8ac2a85` (F-023-001). Most principles encoded as prompt text in agents, not runtime-enforced. |
| 13. Adversarial falsification | covered | 5 total | 3 total | See per-finding evidence below. |

**Total axis-13 probes:** bypass_attempts=5 (path-guard `../`, prompt-guard injection string, destructive-guard `rm -rf /`, destructive-guard `git config core.fsmonitor`, destructive-guard empty-input); silent_failure_probes=3 (_state-update malformed jq, session-log unwritable target, circuit-breaker no-state). All probes yielded the contract-required behavior EXCEPT _state-update silent-swallow and session-log silent-exit (see F-003, F-004).

---

## BLIND SPOTS

1. **Did not exhaustively probe every axis-10 hook with bypass attempts** (only 5 probes total) — `subagent-guard.sh`, `exfil-guard.sh`, `sequence-guard.sh`, `apex-prompt-guard.cjs` (impossible — file missing) not individually adversarially probed this round. Coverage-map row for axis-13 records 5 bypass / 3 silent probes; spec requirement minimum "one per axis-10 hook + _state-update.sh + circuit-breaker.sh + session-log.sh" — partially met. Marked blind-spot.
2. **`/tmp/tmp.K6R6djZMGe` per-test diagnostics from test suite** not opened — `test-hooks-cjs.sh` and `test-hook-classification.sh` failure root causes not inspected. Test-suite-failure P1 emitted in lieu.
3. **`apex-test-architect` veto runtime enforcement** not traced into `/apex:plan-phase` or `/apex:execute-phase` flow — declared at module-prompt level; phase-gate hook integration unverified.
4. **`/apex:help` NL routing classifier behavior** not exercised against free-text queries — only the no-arg listing branch read.

---

## SPEC CONTRADICTIONS

**SC-1:** Spec §9 names `apex-prompt-guard.js` and `apex-workflow-guard.js`. Shim files use `.cjs` extension and reference `framework/docs/SECURITY-RUNTIME.md §Node.js prerequisite for IMP-003` claiming "byte-equivalent detection patterns to apex-prompt-guard.cjs". The .cjs files do not exist on disk. The shim's degraded-fallback advisory text claims "Current host has no node on PATH" even when node IS on PATH — the actual cause is missing .cjs payload. Logical contradiction between shim self-diagnosis and actual cause.

**SC-2:** `framework-auditor.md` line 3 self-describes "12-axis investigation". Operational agent definition (this round) specifies 13 axes (axis-13 adversarial falsification added). Spec §"Self-Healing Loop" line 350 also says "12-axis audit". Treated as SGC because the spec text itself is consistent with the agent file; the 13th axis is an agent-definition-only contract.

---

## P0–P3 FINDINGS

---

### F-001 [Axis 10, P0, CONFIRMED] — `apex-prompt-guard.cjs` and `apex-workflow-guard.cjs` missing on disk

**Spec anchor (verbatim):** "`apex-prompt-guard.js`, Path Traversal Prevention, `apex-workflow-guard.js`, CI scanner, `security.cjs` module" — spec.md §9 line 135.

**Evidence:**
- `framework/hooks/` listing contains `prompt-guard.sh`, `workflow-guard.sh`, `security.cjs` — no `apex-prompt-guard.cjs`, no `apex-workflow-guard.cjs`, no `.js` variant.
- `framework/hooks/prompt-guard.sh:26-37` attempts `CJS_PATH="$(dirname "$0")/apex-prompt-guard.cjs"; if [ -f "$CJS_PATH" ]; then exec node "$CJS_PATH" "$INPUT"; fi`.
- `framework/hooks/workflow-guard.sh:61-72` analogous attempt with `apex-workflow-guard.cjs`.
- `find` over entire repo root yields zero results for `apex-prompt-guard*` or `apex-workflow-guard*`.
- Adversarial probe `bash framework/hooks/prompt-guard.sh "<injection-test-string>"` (instruction-override pattern) returns exit 2 (block fires) but ALSO prints the misleading advisory `Current host has no node on PATH; falling back to the 5 free-text prompt-injection patterns` even though `command -v node` succeeds and `node --version` returns `v24.13.0`.

**Current:** Defense-in-Depth Layer #1 (prompt-guard) and Layer #3 (workflow-guard) silently downgrade to a 5-pattern free-text Bash fallback. IMP-003 arg-content validation (path-arg shell-metachar / name-arg role-marker / >1000-char advisory) is structurally unreachable.

**Expected:** Either the .cjs files exist and execute, OR the shims fail loud when the canonical implementation is absent.

**Gap:** Spec-named canonical guards do not exist; shims provide a downgrade path that hides the absence.

**Blast radius:** Every PreToolUse path that triggers prompt-guard or workflow-guard runs degraded — IMP-003, IMP-015 (.cjs side), IMP-033 (adversarial refresh target nonexistent), IMP-043 (CLAUDE.md-specific deep scan) unreachable. CLAUDE.md / SPEC.md / STATE.json prefill-priming defense degraded.

**Reproduction:** `ls framework/hooks/apex-prompt-guard.* framework/hooks/apex-workflow-guard.*` → file-not-found. `bash framework/hooks/prompt-guard.sh "test"` → emits "no node on PATH" while node IS on PATH.

**Dependencies:** Spec line 135 (axis 9 / Defense-in-Depth Security Layer enumeration); IMP-003, IMP-015, IMP-033, IMP-043.

---

### F-002 [Axes 2/9 — Memory primitives + Module ecosystem, P1, CONFIRMED] — `apex-workflows/` library disabled

**Spec anchor (verbatim):** "`apex-workflows/` library — 30+ recipes for common tasks. Non-technical user picks from a menu instead of describing what they want." — spec.md §"היכולות הנדרשות" line 207. Also spec line 34: "`apex-workflows/` as library of pre-built recipes (BMAD innovation): 30+ ready recipes".

**Evidence:**
- `ls framework/` shows `apex-workflows-DISABLED` (not `apex-workflows`).
- Directory contains `_index.json`, `add-authentication.md`, `add-stripe-payments.md`, `add-rate-limiting.md`, etc. — recipes physically present but path-disabled.
- No `apex-workflows/` (non-DISABLED) directory exists.

**Current:** Workflow library physically present but path-renamed to `-DISABLED`. `/apex:workflow` command (`framework/commands/apex/workflow.md` exists) will not find recipes at the spec-mandated path.

**Expected:** Active `framework/apex-workflows/` directory the `/apex:workflow` command can read.

**Gap:** Recipe path inactive; non-technical user menu unavailable.

**Blast radius:** Spec headline "30+ pre-built recipes" — claim unmet on disk. First-hour usability spec (line 539+) and "framework vocabulary gap" closure compromised.

**Reproduction:** `ls framework/apex-workflows` → not found. `ls framework/apex-workflows-DISABLED/_index.json` → exists.

**Dependencies:** spec lines 34, 207; `/apex:workflow` command; first-hour usability claim.

---

### F-003 [Axis 11/12 — fail-loud, P0, CONFIRMED] — `_state-update.sh` silently swallows jq failures

**Spec anchor (verbatim):** "Fail-loud, never fail-silent." — spec.md §"עקרונות העבודה" line 233.

**Evidence:** `framework/hooks/_state-update.sh:106-108`:
```bash
  else
    rm -f "$tmp" "$err"; return 0
  fi
```
When jq fails, the stderr captured to `$err` is deleted unread and the function returns 0. No event-log entry, no stderr to caller.

**Adversarial probe (axis-13b):**
```bash
TMPDIR=$(mktemp -d); echo "{}" > "$TMPDIR/STATE.json"
source framework/hooks/_state-update.sh
_state_update ".malformed jq expression!!!" "$TMPDIR/STATE.json"
echo "EXIT=$?"  # → EXIT=0
ls "$TMPDIR/"   # → STATE.json only (no event-log entry written)
```

**Current:** Silent exit 0; STATE.json left unchanged; jq error message destroyed.

**Expected:** Exit non-zero (or at minimum emit a `state_update_failed` event with the jq stderr) so the caller and event-log record the failure. "Fail-loud" requires both the exit code AND a stderr-diagnostic.

**Gap:** Both signals absent. Silent branch (exit 0 + empty stderr) per agent-def §13.b = finding.

**Blast radius:** Every hook that uses `_state_update` (circuit-breaker, exfil-guard, sequence-guard, decision-gate, _state-update self) loses STATE mutations silently on any jq error — schema-drift, malformed expression, missing arg, permission denied. Proof-of-process is broken: STATE.json no longer "derives from disk" reliably.

**Reproduction:** see probe above.

**Dependencies:** spec line 233; axis 11 (State derives from disk); axis 13.b silent-failure falsification.

---

### F-004 [Axis 11 — fail-loud, P1, CONFIRMED] — `session-log.sh` silently exits when LOG_FILE creation fails

**Spec anchor (verbatim):** "Fail-loud, never fail-silent." — spec.md line 233. Also "State derives from disk" — spec line 39.

**Evidence:** `framework/hooks/session-log.sh:23-25`:
```bash
  if [ ! -f "$LOG_FILE" ]; then
    exit 0
  fi
```
Inside the `if [ ! -f "$LOG_FILE" ]` create-with-header block: if `cat > $LOG_FILE` failed (e.g. unwritable .apex/), this exits 0 without diagnostic.

**Current:** SESSION-LOG.md never written, no stderr.

**Expected:** Non-zero exit + stderr message identifying the write failure.

**Gap:** Silent fail-soft path. Session-log is a proof-of-process artifact — its silent absence breaks observability claim (axis 11).

**Reproduction:** Run `session-log.sh checkpoint test` in directory where `.apex/` cannot be created → exit 0, no log.

**Dependencies:** spec line 233; spec line 39 (event-log.jsonl as control plane); axis 13.b spec minimum requires this hook be probed.

---

### F-005 [Axis 10, P1, CONFIRMED] — `prompt-guard.sh` emits misleading diagnostic when node IS available

**Spec anchor:** "Fail-loud, never fail-silent" (spec line 233) and implicit truth-in-diagnostics under axis 10 Defense-in-Depth.

**Evidence:** `framework/hooks/prompt-guard.sh:47-48`:
```bash
printf '[APEX SECURITY] IMP-003 arg-content validation ... Current host has no node on PATH; falling back to the 5 free-text prompt-injection patterns. ...\n' >&2
```
The advisory text is printed unconditionally when control falls through the `if command -v node ... exec node ...` block. Two ways control falls through:
1. node not on PATH — message accurate.
2. node IS on PATH but `apex-prompt-guard.cjs` is missing — message FALSE; the actual cause is the missing .cjs payload (F-001), not node availability.

**Adversarial probe:** Verified `command -v node` succeeds (`/c/Program Files/nodejs/node`, `v24.13.0`) on this host; running `bash framework/hooks/prompt-guard.sh "<injection-test-string>"` STILL prints the "no node on PATH" advisory.

**Current:** Diagnostic misattributes cause. Operator sees "install node" when node is installed; will not discover missing .cjs.

**Expected:** Advisory text branches on which condition failed: "node missing" vs "apex-prompt-guard.cjs missing despite node available".

**Gap:** False diagnostic conceals F-001 from operators.

**Blast radius:** Operators acting on the misleading message install node redundantly and never restore the .cjs; F-001 stays latent. Compounds with F-001.

**Reproduction:** Already executed (see Evidence).

**Dependencies:** F-001; spec line 233.

---

### F-006 [Test-suite observation, P1, OBSERVED] — Test suite reports 2 failed tests

**Spec anchor (TEST-SUITE EVIDENCE RULE):** Per agent definition, `failed>0 or errored>0 = finding`.

**Literal summary from `bash framework/tests/run-all.sh`:**
```
  passed:  70
  failed:  2
  skipped: 0
```
(Runner did not emit an `errored:` line; reporting verbatim.)

**Failed tests:**
- `test-hook-classification.sh`
- `test-hooks-cjs.sh`

**Current:** 2 failed in suite of 72; per-test diagnostics at `/tmp/tmp.K6R6djZMGe` (not opened this round — see blind-spot 2). `test-hooks-cjs.sh` failure name strongly correlates with F-001 (`.cjs` payload missing).

**Expected:** `failed: 0`.

**Gap:** Suite not green.

**Reproduction:** `bash framework/tests/run-all.sh` (50m 40s runtime).

**Dependencies:** Likely root-cause overlap with F-001 (cjs-payload missing) and `test-hook-classification.sh` may reflect HOOK-CLASSIFICATION.md drift.

---

### F-007 [Axis 1 — auditor agent contract, P3, CONFIRMED] — `framework-auditor.md` self-describes as 12-axis while operational contract is 13

**Spec anchor:** Spec line 350: "performs a 12-axis audit against this spec". Agent definition this round mandates 13 axes (axis-13 adversarial falsification added).

**Evidence:** `framework/agents/specialist/framework-auditor.md:3`:
```
description: ... Performs rigorous 12-axis investigation of the live APEX framework against apex-spec.md ...
```

**Current:** Agent self-description and spec §Self-Healing Loop both say "12-axis". Operational agent definition this round demands 13 (axis-13 adversarial falsification). Either the spec and agent file are stale, or this round's operational contract is supra-spec.

**Note:** Because the spec text itself is consistent with the agent file (both say 12), this is closer to SGC than a P0–P3 finding. Logged as P3 because if the operational contract is binding, the agent file fails to encode axis-13 invocation. Flagged for triage.

**Reproduction:** `grep "12-axis" framework/agents/specialist/framework-auditor.md`.

**Dependencies:** Spec §Self-Healing Loop alignment with agent definition.

---

## SPEC-GAP-CANDIDATES

### SGC-001: Spec uses `.js` extension for prompt-guard while implementation uses `.cjs` shim with no `.js` file present

**File / location:** `apex-spec.md` line 135 vs `framework/hooks/`.

**Observation:** Spec literal "`apex-prompt-guard.js`" but no `.js` file ever exists; the documented `.cjs/.js` equivalence lives in `framework/docs/SECURITY-RUNTIME.md` (not in apex-spec.md itself). A reader of apex-spec.md alone cannot reconcile spec text with disk state — they would conclude `.js` is missing and find no permission slip in the spec for `.cjs`.

**Why it is not a P0–P3 finding:** apex-spec.md does not explicitly forbid `.cjs`; the equivalence is documented one level down. F-001 is the substantive failure (file actually missing regardless of extension). This SGC is style-of-spec-language.

**Suggested spec language (non-binding):** Add a parenthetical in line 135: "`apex-prompt-guard.js` (CommonJS; `.cjs` extension equivalence per `framework/docs/SECURITY-RUNTIME.md`)".

---

### SGC-002: Spec §Self-Healing Loop hard-codes "12-axis audit" while operational agent contract is 13

**File / location:** `apex-spec.md` line 350.

**Observation:** Spec says "performs a 12-axis audit"; this round's agent definition mandates 13 (axis-13 adversarial falsification). Either the spec line is stale or axis-13 is an operational super-set not formalized in the spec.

**Why it is not a P0–P3 finding:** Spec and agent file (`framework-auditor.md:3`) are consistent at 12. The 13-axis demand is operational, not in the anchor document, so the spec is not violated.

**Suggested spec language (non-binding):** Change "12-axis audit" to "13-axis audit (axes 1–12 plus axis-13 adversarial falsification with bypass-attempt and silent-failure probes)".

---

### SGC-003: No spec language for "diagnostic accuracy" — degraded-fallback advisories may misattribute cause

**File / location:** `framework/hooks/prompt-guard.sh:47-48`; principle in apex-spec.md line 233.

**Observation:** "Fail-loud" is in the spec, but "fail-loud with accurate cause" is not explicit. F-005 demonstrates a hook that fails loud, just to the wrong cause. The spec is silent on diagnostic accuracy.

**Why it is not a P0–P3 finding:** F-005 IS a P1 finding under "fail-loud" interpretation; SGC-003 captures the broader gap of explicit spec language demanding that diagnostic messages truthfully name the failure mode.

**Suggested spec language (non-binding):** Append to "Fail-loud, never fail-silent": "Diagnostic messages must truthfully name the failure mode; never paper over one cause with another (e.g., 'node missing' when the real cause is a missing payload file)."

---

## TERMINATION

13 axes covered. Bypass/silent probes performed within available budget (5/3). Blind spots enumerated above. Per agent contract, did not compress on partial coverage — listed gaps explicitly.

AUDIT_COMPLETE: C:/Users/דודאלמועלם/OneDrive - Tiva 13 Engineers/שולחן העבודה/APEX/detector-review/trials/phase6-baseline-trial-2.md | findings=7 | P0=2 P1=4 P2=0 P3=1 | sgc=3
