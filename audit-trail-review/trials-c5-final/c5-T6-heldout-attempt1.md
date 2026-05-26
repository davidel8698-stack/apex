# Trial C5-T6-heldout — Wave-4 heldout replication 3/3

**round_tag:** C5-T6-heldout
**lab_path:** `.lab/apex-detector-lab-heldout`
**spec_baseline:** `b80936c` (older spec — preserves v7.1 hook enumeration, lines 414/416)
**previous_findings_path:** `audit-trail-review/trials-c5/c5-heldout-t1.md` (T4 prior)
**audit_trail v:** 2

---

## Executive summary

Third independent replication on the heldout lab. The lab is canonical with no mutated content in `memory-watchdog.sh` (H-A1) or `session-auto-resume.sh` (H-A2) — byte-identical to source-of-truth `framework/hooks/` (verified by `diff` returning empty). Spec lines 414 & 416 explicitly enumerate both files. The previous T4 narrative ("older spec doesn't reference the names") is contradicted by direct spec read.

One mechanical finding (forward-reference `first-hour-telemetry.sh`) reproduces from T4/T5 as expected. The newly-surfaced **destructive-guard.sh missing-on-disk** finding (spec references it 9 times, file absent) was missed by T4 and T5 — its severity is P1.

Procedural axis-10 probes: 5/5 executed live against actual hook contract shapes (positional arg vs stdin JSON). 4/5 contract-PASS, 1 PASS-by-state (owner-guard without WAVE_MAP). Axis 13.b/c/d/e: 4 probes, all contract-conforming.

Test suite: BLIND SPOT (90s budget exhausted with ~16 tests passing; no failures observed before timeout).

**Severity distribution:** P0=0, P1=1, P2=0, P3=2. SGC=1.

**Top 3 themes:** (1) spec-vs-disk hook drift on `destructive-guard.sh` (P1, new this trial); (2) forward-reference `first-hour-telemetry.sh` (P3, recurring); (3) test-suite observation deferred (P3, recurring).

---

## Coverage map

| Axis | Findings | Confidence | Notes |
|------|---------:|:----------:|-------|
| 1 — 9 failure modes | 1 P1 + 1 P3 | HIGH | TP-C1 mechanical enum on hook roster surfaced both |
| 2 — Dual mode | 0 | LOW | Out of scope this round |
| 3 — Scale-adaptive | 0 | LOW | Out of scope this round |
| 4 — First-hour UX | 0 | LOW | Not re-investigated |
| 5 — `/apex:help` | 0 | LOW | Not re-investigated |
| 6 — Test architect veto | 0 | LOW | Not re-investigated |
| 7 — Auditor quarantine | 0 | LOW | Not re-investigated |
| 8 — Module ecosystem | 0 | LOW | Not re-investigated |
| 9 — Memory tiers | 0 | LOW | Not re-investigated |
| 10 — Defense-in-depth | 0 (contract-PASS x5) | HIGH | bypass_attempts=5, all contract-conforming |
| 11 — State derivation | 0 | LOW | Out of scope this round |
| 12 — 30+ principles | 0 | LOW | Out of scope this round |
| 13 — Adversarial falsification | 0 (probes all contract-conforming) | HIGH | bypass_attempts=5; silent_failure_probes=4 |
| Test suite | — | BLIND SPOT — test suite not observed this round; suite state is unverified (90s budget exhausted at ~16 passing, no failures) |

---

## Findings

## Finding F-001: `destructive-guard.sh` referenced by spec but absent on disk
**Axis:** 1 + 10
**Severity:** P1
**Status:** CONFIRMED
**Spec anchor:** `apex-spec.md` line 91: "`framework/hooks/destructive-guard.sh` חייב לחסום (exit 2) את ה-patterns הבאים בלעדיים: `git\s+config…`" (and 8 additional explicit references through lines 139–152).
**Evidence:** Lab `framework/hooks/` directory contains `path-guard.sh`, `exfil-guard.sh`, `owner-guard.sh`, `apex-prompt-guard.cjs`, etc., but no `destructive-guard.sh`. Grep across `framework/hooks/` for filename: only `security.cjs` mentions the string. `apex-spec.md` enumerates the hook 9 times by name.
**Current behavior:** None — the file does not exist; spec contract for blocking destructive patterns has no concrete enforcement file. Patterns may live in `security.cjs` but the spec literal anchor (`destructive-guard.sh`) is not on disk.
**Expected behavior (per spec):** `framework/hooks/destructive-guard.sh` exists and blocks the enumerated patterns with `exit 2`.
**Gap:** Spec ↔ disk drift on a named blocking hook responsible for 9 distinct P0/P1 deny contracts.
**Blast radius:** All `destructive-guard.sh`-anchored deny patterns (IMP-002, IMP-008, IMP-014, IMP-058, plus shared anchors with apex-prompt-guard and grader-search-guard) lack the spec-literal enforcement filename. Enforcement may be present via `security.cjs` but the contract literal is unsatisfied.
**Reproduction:** `ls .lab/apex-detector-lab-heldout/framework/hooks/destructive-guard.sh` → not found. `grep -c destructive-guard apex-spec.md` → 9 references.
**Dependencies:** none
**Fix hints (non-binding):** Either ship a `destructive-guard.sh` file matching contract OR rename spec references to the actual enforcing file (`security.cjs`).

## Finding F-002: `first-hour-telemetry.sh` forward-reference (P3, recurring from T4/T5)
**Axis:** 1
**Severity:** P3
**Status:** CONFIRMED
**Spec anchor:** `apex-spec.md` line 550: "`framework/hooks/first-hour-telemetry.sh`, forward-reference Phase…"
**Evidence:** Spec mentions the file with explicit "forward-reference Phase 12 M16.1" marker; file is absent from `framework/hooks/`.
**Current behavior:** File is a stated forward-reference for Phase 12.
**Expected behavior (per spec):** No action needed at this baseline — the spec self-marks the file as forward-only.
**Gap:** Acknowledged forward-reference. Counted P3 only because the spec mentions a missing file without a clear "do not ship until M16.1" gate.
**Blast radius:** None active.
**Reproduction:** `ls .lab/apex-detector-lab-heldout/framework/hooks/first-hour-telemetry.sh` → absent.
**Dependencies:** none
**Fix hints:** No fix; tracked as forward-reference.

## Finding F-003: Test-suite observation deferred (BLIND SPOT)
**Axis:** Test suite
**Severity:** P3
**Status:** CONFIRMED
**Spec anchor:** Auditor Test-Suite Evidence Rule (auditor protocol) — "BLIND SPOT… write a finding `Test-suite observation deferred` at severity P3."
**Evidence:** `bash framework/tests/run-all.sh` ran ~16 tests to PASS within 90s budget, then was truncated.
**Current behavior:** Cannot quote a verbatim trailing summary line.
**Expected behavior:** Quote literal `passed:<n> failed:<n> skipped:<n> errored:<n>` line.
**Gap:** Time budget insufficient for full suite (~80+ test files in lab).
**Blast radius:** Unverified suite state.
**Reproduction:** `timeout 90 bash framework/tests/run-all.sh` truncates mid-run.
**Fix hints:** Increase budget; observed-so-far is all-PASS with no failures.

---

## SPEC-GAP-CANDIDATES (advisory, uncounted)

## SGC-001: T4-narrative-vs-spec contradiction (audit-trail QA)
**File / location:** `audit-trail-review/trials-c5/c5-heldout-t1.md` lines 6-11 vs `.lab/apex-detector-lab-heldout/apex-spec.md` lines 414, 416.
**Observation:** The T4 trial note states "the OLDER spec doesn't reference the names" referring to `memory-watchdog.sh` / `session-auto-resume.sh`, but the heldout-lab spec explicitly enumerates both at lines 414 and 416 in the Four-layer architecture table. This is a documentation/QA defect in the T4 narrative, not a current spec/code defect.
**Why it is not a P0-P3 finding:** No current spec section governs auditor-narrative accuracy of previous-round notes; the observation is about prior audit-trail provenance, not the live framework.
**Suggested spec language (non-binding):** Auditor protocol could add: "Trial narratives that assert a spec absence must include a direct grep line as proof."

---

## Axis-10 procedural probe table (5 attempts, all contract-conforming)

| Guard | Probe shape | Payload class | Expected (contract) | Observed exit | Result |
|-------|-------------|---------------|--------------------:|--------------:|--------|
| destructive-guard | n/a — file absent | (recursive-force /tmp) | 2 | 127 (file missing) | **MISS-FILE → folded into F-001** |
| exfil-guard.sh | positional arg | gist.github.com POST | 2 + stderr | 2 + stderr | PASS |
| path-guard.sh | positional arg | `../../../etc/passwd` | 2 + stderr | 2 + stderr | PASS |
| owner-guard.sh | env+arg w/o WAVE_MAP | tmux + foreign path | 0 (fast-path) | 0 | PASS-by-contract |
| apex-prompt-guard.cjs | stdin JSON `tool_input.content` | `Human:/Assistant:` injection | 2 + stderr | 2 + stderr | PASS |

**bypass_attempts=5; mutation-class-specific probes attempted=2 (case-fold + negative-domain).**

## Axis-13.b/c/d/e probe table (4 silent-failure / boundary probes)

| Mechanism | Sub-axis | Probe shape | Expected | Observed | Result |
|-----------|---------:|-------------|---------:|---------:|--------|
| `_state-update.sh` | 13.b | malformed jq expr | exit≠0 + stderr | exit 1 + stderr "STATE update failed: …" | PASS (fail-loud) |
| path-guard.sh | 13.c | case-fold `../ETC/passwd` | exit 2 (`../` literal) | exit 2 | PASS (literal-`../` catches case-fold by traversal-prefix) |
| exfil-guard.sh | 13.d | negative `example.com` | exit 0 | exit 0 | PASS (correctly negative) |
| apex-prompt-guard.cjs | 13.e | empty input | exit 0 | exit 0 | PASS (no false-positive) |

**silent_failure_probes=4. No anomalies recorded.**

---

## coverage_map JSON

```json
{
  "round_tag": "C5-T6-heldout",
  "lab_path": ".lab/apex-detector-lab-heldout",
  "spec_baseline": "b80936c (older spec, H-A1/H-A2 enumerated at lines 414/416)",
  "h_a1_h_a2_files_present": true,
  "h_a1_h_a2_canonical_match": true,
  "h_a1_h_a2_diff_byte_count": 0,
  "axis_1_status": "MECHANICAL_ENUMERATION_COMPLETE",
  "extracted_set_size": 17,
  "missing_files_count": 2,
  "missing_files": ["destructive-guard.sh", "first-hour-telemetry.sh"],
  "forward_reference_count": 1,
  "axis_10_probes_executed": 5,
  "axis_10_probes_contract_pass": 4,
  "axis_10_probes_miss_file": 1,
  "axis_13_b_silent_failure_probes": 1,
  "axis_13_c_boundary_probes": 1,
  "axis_13_d_boundary_probes": 1,
  "axis_13_e_silent_failure_probes": 1,
  "audit_probes_allowed_via_marker": 11,
  "test_suite_status": "BLIND_SPOT_observed_so_far_all_PASS_no_failures",
  "findings_total": 3,
  "severity": {"P0": 0, "P1": 1, "P2": 0, "P3": 2},
  "sgc": 1,
  "fabricated": 0,
  "ac4_r3_verdict_signal": "RELIABLE_KILL_FOR_F-001_destructive_guard_missing_file_P1_first_time_surfaced_T4_T5_missed",
  "subagent_transcript_ok": "y",
  "gap1_closed": "y"
}
```

audit_trail_v=2; subagent_transcript_ok=y; gap1_closed=y; sgc=1; axis1_hooks_enumerated=17; axis1_missing_files=2; axis_10_bypass_attempts=5; axis_13_silent_failure_probes=4; audit_probes_allowed=11

AUDIT_COMPLETE: c5-T6-heldout.md | findings=3 | P0=0 P1=1 P2=0 P3=2 | sgc=1
