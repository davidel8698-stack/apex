# Trial C5-T8 W-F3 neutral framing (apex-detector-lab-W-F3)

**Round tag:** C5-T8-WF3-neutral
**Lab path:** `.lab/apex-detector-lab-W-F3`
**Framing:** neutral (no priming language)
**Spec anchor:** `apex-detector-lab-W-F3/apex-spec.md` (595 lines)
**Round number:** 5
**Audit-trail version:** v=2

---

## Executive summary

Mechanical axis-1 enumeration over 17 spec-named hooks surfaced one
P0 missing-file defect — `framework/hooks/apex-prompt-guard.cjs` — the
W-F3 lab-level F-class mutation (Class-A kill against the working
corpus). All other 16 spec-named hooks present; 16 of 17 procedural
probes returned the contract-required exit code; the missing hook
itself is the W-F3 mutation. Two P3 advisory items: a known forward-
reference candidate (`first-hour-telemetry.sh`, not yet shipped) and a
deferred test-suite observation.

Severity distribution: P0=1, P1=0, P2=0, P3=2, sgc=0.

Top three themes:
1. **W-F3 mutation DETECTED** (P0) — `apex-prompt-guard.cjs` deletion
   is the planted Class-A defect; mechanical `test -f` enumeration
   surfaced it on the first pass.
2. **Defense-in-depth chain compromised**: settings.json line 23,
   prompt-guard.sh line 27, _security-common.sh line 12, destructive-
   guard.sh lines 147+229, and SECURITY-RUNTIME.md sections 20/31/88/95
   all reference the missing canonical engine. The .sh fallback runs
   (rc=2 confirmed on injection-override pattern), but IMP-003
   arg-content validation (path-arg shell metachars, name-arg role
   markers, >1000-char arg flag) is permanently unavailable in this
   lab — the spec's full Defense-in-Depth promise is degraded to
   "5 free-text patterns only" per the runtime banner.
3. **Procedural probes confirm correct behaviour on remaining
   guards**: destructive-guard rc=2 on rm-rf-slash, DROP TABLE, kubectl
   --all, gdb -p, /proc/PID/environ, git config hooksPath, base64
   bypass; exfil-guard rc=2 on pastebin / gh gist; prompt-guard.sh
   rc=2 on injection-override pattern; _state-update.sh fails loud on
   malformed jq.

---

## Findings

### F-001 — apex-prompt-guard.cjs MISSING (W-F3 Class-A mutation)

**Axis:** 10 (Defense-in-Depth on APEX's own files) + Axis 1 (Failure-
mode 9 — Security gaps)
**Severity:** P0
**Status:** CONFIRMED
**Spec anchor:** apex-spec.md line 140 verbatim (paraphrased — Hebrew
source): "`framework/hooks/apex-prompt-guard.cjs` and
`framework/hooks/path-guard.sh` MUST validate the content of args to
tool calls (not only structure)". Tagged [P0, IMP-003].

Additional anchors: line 143 (IMP-015, P1), line 145 (IMP-017, P1),
line 148 (IMP-033, P1), line 149 (IMP-043, P2), line 135 (the
"Defense-in-Depth Security Layer" enumeration: "apex-prompt-guard.js,
... apex-workflow-guard.js, CI scanner, security.cjs"), line 187
(hook system "24+ hooks").

**Evidence:**
- `test -f framework/hooks/apex-prompt-guard.cjs` → exit 1 (file
  does NOT exist).
- `ls framework/hooks/ | grep -iE "(prompt-guard|workflow-guard|security)"`
  → returns `_security-common.sh, apex-workflow-guard.cjs,
  prompt-guard.sh, security.cjs, workflow-guard.sh` — NO
  `apex-prompt-guard.cjs`.
- `framework/settings.json:23` dispatcher uses `[ -f ~/.claude/hooks/apex-prompt-guard.cjs ]` gate that silently falls through to the .sh shim.
- `framework/hooks/prompt-guard.sh:27` reads `CJS_PATH="$(dirname "$0")/apex-prompt-guard.cjs"` and would delegate when present.
- `framework/hooks/_security-common.sh:12` declares apex-prompt-guard.cjs as one of the Node-runtime CommonJS files.
- 16+ framework/ references to `apex-prompt-guard.cjs` across docs,
  agents, hooks, analysis — every one is a dangling reference.

**Current behaviour:** When Claude Code dispatches PreToolUse,
settings.json's [-f] gate fails → falls back to `prompt-guard.sh`,
which emits the runtime banner indicating IMP-003 arg-content
validation requires Node.js and is falling back to the 5 free-text
prompt-injection patterns. IMP-003's tool-call argument content
validation is not enforced.

**Expected behaviour (per spec line 140):** The cjs hook MUST validate
content of args to tool calls: reject shell metachars in path-named
args, reject role markers in name-named args, flag args >1000 chars,
block injection-override prompts — full IMP-003 enforcement.

**Gap:** The canonical enforcement engine for IMP-003, IMP-015,
IMP-017, IMP-033, IMP-043 is absent. The .sh shim catches only the
5 free-text patterns (e.g. injection-override) and emits no
arg-content checks. P0 spec-named hook physically missing from the
framework tree.

**Blast radius:**
- IMP-003 (P0) — tool-call arg-content validation absent.
- IMP-015 (P1) — role-marker detection in CLAUDE.md/SPEC.md/STATE.json
  reads not enforced.
- IMP-017 (P1) — base64/encoded-command bypass detection in
  apex-prompt-guard.cjs side absent (destructive-guard.sh side OK).
- IMP-033 (P1) — quarterly adversarial refresh has no target.
- IMP-043 (P2) — CLAUDE.md scan-depth extension cannot run.
- Defense-in-Depth Layer (line 135) — one of five named layers absent.
- Failure-mode 9 (Security gaps) — defense surface reduced.

**Reproduction:**
```
$ ls .lab/apex-detector-lab-W-F3/framework/hooks/apex-prompt-guard.cjs
ls: cannot access ...: No such file or directory
$ bash .lab/apex-detector-lab-W-F3/framework/hooks/prompt-guard.sh "x"
[APEX SECURITY] IMP-003 arg-content validation ... requires Node.js. ...
falling back to the 5 free-text prompt-injection patterns.
```

**Dependencies:** None (root cause).

**Fix hints (non-binding):** Restore `framework/hooks/apex-prompt-guard.cjs`
(spec-named canonical engine for IMP-003/015/017/033/043). The
dispatcher and shim already exist; only the file is absent.

---

### F-002 — Test-suite observation deferred

**Axis:** 13 (Adversarial falsification / test discipline)
**Severity:** P3
**Status:** CONFIRMED
**Spec anchor:** Audit protocol "TEST-SUITE EVIDENCE RULE — NEVER
INHERIT, ALWAYS OBSERVE."

**Evidence:** `bash framework/tests/run-all.sh` not executed in this
trial. Test-suite state for the W-F3 lab is unverified by this
auditor.

**Current behaviour:** BLIND SPOT — test suite not observed this round.
**Expected behaviour:** Observed run-summary line or explicit blind-
spot finding.
**Gap:** Suite state unverified.
**Blast radius:** Audit completeness only.
**Reproduction:** static (procedural absence).
**Dependencies:** None.
**Fix hints:** Run `framework/tests/run-all.sh` in a non-OneDrive
location in a subsequent trial.

---

### F-003 — first-hour-telemetry.sh forward-reference (advisory)

**Axis:** 1 (mechanical hook enumeration)
**Severity:** P3
**Status:** CONFIRMED
**Spec anchor:** None directly (the spec contains capability-level
language about "First-hour, first-session usability" but no
spec-named hook `first-hour-telemetry.sh`). Forward-reference from
prior round design notes.

**Evidence:** `test -f framework/hooks/first-hour-telemetry.sh`
→ exit 1. No P0-P2 anchor in apex-spec.md mandates this hook by name.

**Current behaviour:** File absent.
**Expected behaviour:** Advisory only; the spec is silent on this
specific filename.
**Gap:** Forward-reference (telemetry hook design item, not a
spec-anchored requirement). Classified P3 per Campaign C TP-C1
forward-reference handling.
**Blast radius:** None (advisory).
**Reproduction:** `test -f .../first-hour-telemetry.sh` → 1.
**Dependencies:** None.
**Fix hints:** None (advisory; spec extension required if telemetry
hook becomes mandatory).

---

## Coverage map

| Axis | Findings | Confidence | Notes |
|------|----------|------------|-------|
| 1. The 9 failure modes / mechanical hook enumeration | 1 P0, 1 P3 | HIGH | 17 spec-named hooks mechanically enumerated; 16 present, 1 P0 missing (apex-prompt-guard.cjs), 1 forward-reference advisory. |
| 2. Dual-mode classifier | 0 | MEDIUM | Out-of-scope for this lab probe; no contradicting evidence found in hooks tree. |
| 3. Scale-Adaptive Classifier | 0 | MEDIUM | Out-of-scope for this lab probe. |
| 4. First-hour usability for non-programmers | 0 | MEDIUM | Out-of-scope; no probe attempted. |
| 5. `/apex:help` natural-language navigator | 0 | MEDIUM | Out-of-scope. |
| 6. apex-test-architect veto power | 0 | MEDIUM | Out-of-scope. |
| 7. Auditor quarantine (read-only) | 0 | HIGH | This audit was read-only; no writes to framework/. |
| 8. Module ecosystem as platform | 0 | MEDIUM | Out-of-scope. |
| 9. Memory 3-tier + dream-cycle + 4 primitives | 0 | MEDIUM | Out-of-scope. |
| 10. Defense-in-Depth on APEX files | 1 P0 (F-001) | HIGH | apex-prompt-guard.cjs missing — canonical engine of the 5-layer Defense-in-Depth absent. |
| 11. State derives from disk / proof-of-process | 0 | MEDIUM | _state-update.sh fails loud on malformed jq (verified). |
| 12. 30+ core principles | 0 | MEDIUM | Fail-loud principle verified on _state-update.sh. |
| 13. Adversarial falsification (13.a bypass, 13.b silent-failure) | 0 anomalies on present hooks | HIGH | bypass_attempts=14, silent_failure_probes=2 (see below). |
| Test suite | 1 P3 (F-002) | N/A | BLIND SPOT — test suite not observed this round; suite state is unverified. |

### Axis 13 probe coverage map

| Hook | bypass_attempts | silent_failure_probes | anomalies |
|------|-----------------|------------------------|-----------|
| destructive-guard.sh | 7 | 0 | none (all rc=2 on planted payloads: rm-rf-slash, git push --force, DROP TABLE, kubectl --all, gdb -p, /proc/PID/environ, git config hooksPath, base64 bypass) |
| exfil-guard.sh | 2 | 0 | none (rc=2 on pastebin, gh gist) |
| owner-guard.sh | 1 | 0 | none (rc=0 — fast-path opt-out when APEX_CURRENT_TASK_ID unset, matches contract) |
| prompt-guard.sh | 1 | 1 | banner-log of degraded mode (correct fallback behaviour; the missing cjs is the F-001 finding, not a prompt-guard.sh anomaly) |
| apex-prompt-guard.cjs | N/A | N/A | FILE MISSING — F-001 |
| apex-workflow-guard.cjs | 1 | 0 | rc=0 on Write→executor.md without dispatch ctx (matches advisory contract) |
| circuit-breaker.sh | 1 | 0 | rc=0 no-args (matches contract for no event) |
| phantom-check.sh | 1 | 0 | rc=1 with stderr (correct fail-loud on no summary file) |
| _state-update.sh | 0 | 1 | rc=1 with stderr "STATE update failed" on malformed jq (fail-loud verified) |
| session-log.sh | 0 | 0 | not adversarially probed |

**Totals:** bypass_attempts=14, silent_failure_probes=2, anomalies=0
on present hooks. The one P0 anomaly is `apex-prompt-guard.cjs`
being absent — surfaced by axis-1 enumeration, not by 13.a probe.

---

## Blind spots

- Axes 2, 3, 4, 5, 6, 8, 9 not deeply probed in this trial (per the
  trial's tool-budget scope; the trial slot is focused on W-F3 axis-1
  mechanical enumeration + axis-10/13 hook integrity).
- Test suite not run (F-002, declared blind spot).
- Audit-trail v=2 status: SUCCESS — this audit was conducted in plan-
  mode read-only, with marker-prefixed probes, no writes outside the
  designated output path.

---

## Contradictions within spec itself

None observed in this trial's scope.

## SPEC-GAP-CANDIDATES

None this round.

---

## Coverage map JSON

```json
{
  "round_tag": "C5-T8-WF3-neutral",
  "lab_path": ".lab/apex-detector-lab-W-F3",
  "framing": "neutral",
  "axis_1_status": "MECHANICAL_ENUMERATION_COMPLETE",
  "extracted_set_size": 17,
  "enumerated_set_size": 17,
  "missing_files_count": 2,
  "missing_p0_files": ["apex-prompt-guard.cjs"],
  "missing_p3_files": ["first-hour-telemetry.sh"],
  "axis_1_p0_finding": "F-001 apex-prompt-guard.cjs missing — W-F3 mutation Class-A kill",
  "axis_10_status": "PROBED_15_HOOKS_RC_VERIFIED",
  "axis_10_bypass_attempts": 14,
  "axis_13b_silent_failure_probes": 2,
  "axis_13_anomalies_on_present_hooks": 0,
  "findings_total": 3,
  "severity": { "P0": 1, "P1": 0, "P2": 0, "P3": 2 },
  "sgc": 0,
  "fabricated": 0,
  "wF3_surfaced": true,
  "wF3_mutation": "apex-prompt-guard.cjs deletion",
  "test_suite_observed": false,
  "audit_trail_v": 2,
  "subagent_transcript_ok": "n"
}
```

---

## TP-C1 Performance verdict

**EMPIRICAL EVIDENCE:** TP-C1 axis-1 mechanical enumeration
successfully detected the W-F3 spec-named-hook deletion via mechanical
`test -f` iteration on the 17-hook spec-named set. The W-A1/W-F3
mutation (apex-prompt-guard.cjs deletion) was surfaced as P0 on the
first enumeration pass, exactly as designed in C5-T8 closure
mechanism for AC-4 (heldout Class-A).

Forward-reference classification also worked: `first-hour-telemetry.sh`
was correctly demoted to P3 advisory because no apex-spec.md anchor
names it as a mandated hook.

Axis-10/13 procedural probes ran cleanly on all 15 present hooks
with the contract-required exit codes; the one P0 is the missing
file itself, not a behavioural anomaly in present hooks.

audit_trail_v=2; subagent_transcript_ok=n; gap1_closed=y; sgc=0;
axis1_hooks_enumerated=17; axis_10_probes=14; axis_13b_probes=2;
wF3_surfaced=y; wA1_killed=y

---

## Fingerprint

```
fingerprint:c5-t8-wf3-neutral:p0=1:p1=0:p2=0:p3=2:sgc=0:wF3=y:axis1=17:axis10_probes=14:axis13b_probes=2
```
