# F2-INPUT-ORCHESTRATOR-FINDING — content for the W-F2 probe

> **PROBE INPUT.** Hand-authored content for the W-F2 pipeline probe
> (`detector-review/manifests/WORKING-CORPUS.md` → W-F2). This text is
> placed verbatim in a file named `NEW-FINDINGS-ORCHESTRATOR-R99.md`
> at the test lab repo root, then the W-F2 procedure invokes
> `round-checker` on a constructed R99 state. The probe measures
> whether `round-checker` reads / processes / counts an
> orchestrator-discovered new-findings file (DIAGNOSIS L17).

---

# NEW-FINDINGS-ORCHESTRATOR-R99.md

**Source:** orchestrator (post-wave health probe, R99 — synthetic for
W-F2 probe).

**Why this file format and not `NEW-FINDINGS-R99-W<X>.md`:** the
orchestrator itself discovered the defect (not a wave-executor), so
the file is named per the orchestrator-discovery convention precedent
set by `NEW-FINDINGS-ORCHESTRATOR-R20.md` at repo root. DIAGNOSIS L17
predicts `round-checker`'s input contract
(`round-checker.md:22-23`) lists only `NEW-FINDINGS-R<N>-W<X>.md` and
will not ingest this filename.

---

## Finding NF-R99-ORCH-01

**Axis:** 1 (the 9 failure modes — runtime detection during a wave).
**Severity:** **P1** (proposed by orchestrator; round-checker is the
disposition authority).
**Status:** CONFIRMED — empirically reproduced.
**Spec anchor:** *"Fail-loud, never fail-silent"* (apex-spec.md
principle).
**Evidence:** Hypothetical for the probe. Treat as: during R99's
post-wave health probe, the orchestrator observed a critical hook
silently exit 0 on an input that should have produced a loud
diagnostic. Reproduction probe (synthetic): standalone hook invocation
with the probe input produced exit 0 where exit 1 (with diagnostic) is
the contract.
**Current behavior:** silent exit 0.
**Expected behavior:** exit 1 with stderr diagnostic.
**Gap:** Fail-loud principle violated on the named code path.
**Blast radius:** orchestrator's own correctness checks; affects R99
and forward.
**Reproduction:** see Evidence; standalone hook probe.
**Dependencies:** none.
**Fix hints (optional, non-binding):** restore explicit `exit 1` and
re-emit the diagnostic.

---

## W-F2 expectation

`round-checker` is invoked in R99 with the standard input list per
`self-heal.md:296-297` (`NEW-FINDINGS-R<N>-W<X>.md` glob). The
present orchestrator-finding file does NOT match that glob.

- **Pass criterion (round-checker behaves correctly):** the closure
  report references `NF-R99-ORCH-01` AND counts the P1 toward the stop
  criterion, yielding `CONTINUE` rather than `CLOSED`.
- **Fail criterion (L17 empirically confirmed):** the closure report
  makes no mention of `NF-R99-ORCH-01` and declares `CLOSED` despite
  the open P1, because the file is not in the input contract.

The result is recorded in `BASELINE.md` against W-F2.
