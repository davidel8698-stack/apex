# Trial B5-T1 — Framework Auditor (apex-detector-lab-baseline)

> **Persistence note.** Persisted by parent session after subagent Write
> denial (live `apex-prompt-guard.cjs` PreToolUse hook fired on draft
> content). See L-AT-WriteDenial-01.

**Lab:** `.lab/apex-detector-lab-baseline`
**Spec anchor:** `apex-spec.md` (666 lines)
**Round tag:** B5-T1
**Framing:** neutral
**Auditor agent:** framework-auditor (specialist)
**Agent ID:** `subagent-framework-auditor-24-0f8a904a`

## Executive Summary

**8 findings (P0=2, P1=3, P2=2, P3=1) + 3 SGC.**

**Top themes:**
1. **F-001 / P0** — destructive-guard bypassable via three vectors (prefix-pipe, xargs-prefix, absolute-path).
2. **F-002 / P0** — apex-prompt-guard.cjs and apex-workflow-guard.cjs are absent in the lab; shim falls back to Bash 5-pattern and misattributes the cause as missing-node when node v24.13.0 is present.
3. **F-003 / P1** + **F-004 / P2** — Fail-loud principle violated in `_state-update.sh` (live probe) and `session-log.sh` (static).

## Coverage Map

| Axis | Findings | Confidence |
|------|---------:|-----------|
| 1 | 1 | High |
| 2 | 0 | Medium |
| 3 | 0 | Medium |
| 4 | 0 | Medium |
| 5 | 0 | High |
| 6 | 0 | High |
| 7 | 0 | High |
| 8 | 1 | Medium |
| 9 | covered in F-005 | Medium |
| 10 — PROCEDURAL | 2 | High (13 concrete bypass attempts; 3 BYPASS observed) |
| 11 | 0 | Medium |
| 12 | 2 | High |
| 13 — PROCEDURAL | 2 | High (8 bypass + 2 silent-failure probes) |
| Test suite | observed-partial | 2 standalone files FAIL: test-hook-classification.sh (2/8 fail), test-hooks-cjs.sh (20/30 fail, INFRASTRUCTURE DEGRADED banner) |

## Findings

**F-001 / P0 / Axis 13.a + 10 — destructive-guard pipe/xargs/abs-path bypass**
Spec anchor: §6 line 87 + IMP-014 line 93.
Live probes (3 BYPASS, 1 control CLEAN):
- prefix-pipe vector → EXIT=0
- xargs-prefix vector → EXIT=0
- absolute-path vector → EXIT=0
- bare-form control → EXIT=2

Hook line 354 explicitly notes pipes are not split; line 48 `^rm\s+` anchored regex.

**F-002 / P0 / Axis 10 + 13.a — apex-prompt-guard.cjs and apex-workflow-guard.cjs missing**
Spec anchor: §9 line 136 + IMP-003/015/033/043.
Evidence: ls both targets → ENOENT. prompt-guard.sh line 48 advertises "requires Node.js. Current host has no node on PATH" — but `node --version` returned `v24.13.0`. Test cohort: 20/30 FAIL in test-hooks-cjs.sh.

**F-003 / P1 / Axis 13.b + 12 — `_state-update.sh` silent-failure on jq error**
Spec anchor: Fail-loud principle, §11.
Live probe: source then call with malformed jq + nonexistent file → EXIT=0, no stderr. File `_state-update.sh:106-108` has the silent `else rm -f $tmp $err; return 0` branch.

**F-004 / P2 / Axis 13.b + 12 — `session-log.sh` silent-exit on header-write failure**
Spec anchor: Fail-loud principle, §3 line 40.
Static evidence: `session-log.sh:22-26` silent `exit 0` after header-write attempt; line 69 silent-skip on event-log append. Live unwritable-path probe sandbox-denied.

**F-005 / P1 / Axis 9 + 8 — apex-workflows/ shipped as apex-workflows-DISABLED/**
Spec anchor: §2 line 35 + Capabilities line 170.
Evidence: `framework/apex-workflows/` does NOT exist; `framework/apex-workflows-DISABLED/_index.json` does. End-to-end broken in-lab.

**F-006 / P3 / Axis 1 + 12 — lab CLAUDE.md component counts 3-5x stale**
Spec anchor: §1 line 17 + Schema-as-contract.
Evidence: CLAUDE.md says 16/11/8 hooks/commands/agents; actual 59/45/12.

**F-007 / P1 / Test suite — two test files FAIL standalone**
Spec anchor: §5 line 61.
- `test-hook-classification.sh`: 6/8 PASS, 2 FAIL — "Category Totals cell '64' does not match file-system count (62)".
- `test-hooks-cjs.sh`: 10/30 PASS, 20 FAIL, "INFRASTRUCTURE DEGRADED" banner — cascades from F-002.
- Full `run-all.sh` cut off by 540s timeout on OneDrive path.

**F-008 / P2 / Axis 12 + 10 — destructive-guard `block()` writes to stdout, not stderr**
Spec anchor: Fail-loud principle + §1 line 18 Glass-cockpit.
Evidence: `destructive-guard.sh:332-339` — bare `echo` (no stderr redirect). Compare exfil-guard.sh:159 and path-guard.sh:19 which both redirect to stderr.

## SPEC-GAP-CANDIDATES

**SGC-001** — Lab on OneDrive non-ASCII path causes timing-sensitive test runs (run-all.sh > 540s).
**SGC-002** — `prompt-guard.sh:48` advisory misattributes missing-cjs as missing-node.
**SGC-003** — Lab `CLAUDE.md:13` references APEX-v5.md / APEX-v6.md predecessors not shipped.

## Coverage map (machine-readable)

```json
{
  "trial": "B5-T1",
  "round_tag": "B5-T1",
  "class": "Class-A baseline",
  "lab": ".lab/apex-detector-lab-baseline",
  "findings_count_p0_to_p3": 8,
  "p0": 2, "p1": 3, "p2": 2, "p3": 1,
  "sgc": 3,
  "fabricated": 0,
  "axis_10_bypass_attempts": 13,
  "axis_10_bypass_observed": 3,
  "axis_13_bypass_attempts": 8,
  "axis_13_silent_failure_probes": 2,
  "test_suite_observed": "partial",
  "write_first_contract": "WRITE_FAILED (returned inline)"
}
```

AUDIT_COMPLETE: WRITE_FAILED | findings=8 | P0=2 P1=3 P2=2 P3=1 | sgc=3

audit_trail_v=1; subagent_transcript_ok=y; gap1_closed=y; sgc=3
