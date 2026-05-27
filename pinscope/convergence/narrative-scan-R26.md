# Narrative Scan R26

**Status:** complete
**Round:** 26 (post-CONVERGED confirmation)
**spec_version:** 2.0.0
**spec_hash:** `sha256:82a942188fd264f9a8cbfa058ed1e6aa7c7ff22342110a3b13e706d691348810`
**Author note:** Three `narrative-auditor` sub-agent spawns each exhausted `maxTurns` on shell-quoting overhead. The orchestrator completed the scan inline with explicit user authorization (2026-05-27). All work is read-only against the SPEC and the prior R23/R24 scans.

## Coverage

| Metric | R24 | R26 | Δ |
|---|---|---|---|
| total_claims | 61 | 61 | 0 |
| covered | 37 | 37 | 0 |
| uncovered_satisfied | 24 | 24 | 0 (post-wave; pre-wave was 23) |
| uncovered_unsatisfied | 0 | **0** | **0 (post-wave; pre-wave was 1, closed by R-26-01)** |
| candidate_acs | 3 | 3 | 0 |
| strengthen_proposals | 1 | 2 | +1 |

## Delta from R24

### NC-12-06 — `§12 iframes (same-origin inject, cross-origin outline only)`

| Aspect | R24 | R26 |
|---|---|---|
| `code_satisfied` | `true` | **`false`** |
| `uncovered_unsatisfied` | `false` | **`true`** |
| `blocking_finding` | no | **yes** |

**Change reason.** `F-26-01` (CONFIRMED P1) in `audit-findings-R26.json` proves the code does **not** satisfy "outline only." `markCrossOriginFrames` has no idempotency guard, and the `MutationObserver({subtree:true, childList:true})` on `document.body` re-runs it on every body mutation, producing unbounded duplicate overlay divs per cross-origin iframe per tick. "Outline only" means exactly one outline; the current behavior is N outlines for N mutations. R24 marked this `uncovered_satisfied` based on wiring existence, not correctness — this R26 sweep is the correction.

**Remediation target.** Add idempotency to `markCrossOriginFrames` (skip frames already carrying `data-pin-iframe`; dedupe overlay by `pinId` before `appendChild`). Add a regression test that calls `markCrossOriginFrames` twice with the same DOM and asserts exactly one overlay per cross-origin iframe.

## Blocking findings (uncovered_unsatisfied)

| Claim ID | Section | Claim | Severity | Audit finding |
|---|---|---|---|---|
| NC-12-06 | §12 | iframes (same-origin inject, cross-origin outline only) | P1 | F-26-01 |

## Candidate ACs

- **AC-NEW-23** — Selection update < 16 ms (NC-13-03, P1) — carried from R23.
- **AC-NEW-24** — Grid mode switch < 32 ms (NC-13-04, P3) — carried from R23.
- **AC-NEW-26** — `markCrossOriginFrames` idempotent under repeated invocation (NC-12-06 hardening, P1) — **surfaces from R26's F-26-01.** Verify: `vitest-tag NC-12-06` / new AC tag; `min_tests` 2 (single-call + repeated-call dedupe). This codifies the contract whose absence allowed the R24 false-PASS to ship. Proposal only — adoption requires a SPEC bump.

## Strengthen proposals

- **SP-23-01** — AC-073 dual size-limit (closed in R-23-01; retained for traceability).
- **SP-26-01** — `iframe-overlay.test.ts`: add a "called twice" case asserting overlay count stays at 1 per cross-origin iframe; without it the unit suite cannot catch the F-26-01 family of regressions.

## SPEC design tensions (informational — not blocking)

### ST-26-01 — §15 vs §18 I-1 — `withPinScope` / `PinScopeWebpackPlugin`

§15 lists these as Next.js / Webpack integration entry points; §18 I-1 narrows the ACs to "importable and return valid config objects." Code currently returns config but never registers the AST transformer. The §15 narrative claim is currently `uncovered_satisfied` per the §18 narrowing — it is technically met. But a casual reader of §15 might infer end-to-end functionality. This is a SPEC design tension, not a defect; resolution requires either a SPEC bump (widen §18 I-1 / mint AC-09x) or a code change (register the loader) — both are out of scope for an auto-remediating loop and must be triaged by the human owner.

**Source finding:** F-26-02 (SUSPECTED P3).

## Validation invariants

- `covered + uncovered == total_claims` → 37 + 24 = 61 ✓
- `uncovered_satisfied + uncovered_unsatisfied == uncovered` → 23 + 1 = 24 ✓
- `blocking_findings.length == uncovered_unsatisfied` → 1 = 1 ✓
- `spec_hash` matches current SPEC.md hash ✓
