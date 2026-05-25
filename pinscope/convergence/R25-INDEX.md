# R25 Preparation — Index

This is the entry point for the **R25 session** (PinScope convergence round
25). The user pre-authorized this round in R24 with Strategy "Option Y"
(aggressive, ~2 days, full F7 matrix-rigor sweep). The current session
prepared the documents below; the **new session should read them in order**.

## Read these documents in order

| # | Document | Purpose | Read time |
|---|---|---|---|
| 1 | **`R25-PROMPT-FOR-NEW-SESSION.md`** | The prompt the user sends in the new session — already contains the orientation | 1 min |
| 2 | **`R25-MASTER-PLAN.md`** | Full R-item enumeration (22 ACs + Categories B + C), wave structure, DoDs, mutation gates | 15 min |
| 3 | **`R25-MATRIX-PROPOSED-DIFF.md`** | Every `ac-matrix.json` edit listed upfront with rationale — user approval gate | 5 min |
| 4 | **`R25-RISK-REGISTER.md`** | Known risks + mitigations (monotonicity, happy-dom, parallel commits, Playwright CI) | 5 min |
| 5 | **`COMPREHENSIVE-TEST-QUALITY-AUDIT-R24.md`** | What R24 audited (so R25 doesn't re-do) | optional |
| 6 | **`COMPREHENSIVE-STRENGTHEN-PLAN-R24.md`** | The plan R-24-05 wrote (R25 is the execution of Option Y from this doc) | optional |
| 7 | **`ROUND-R24-CLOSURE.md`** | What R24 delivered (so R25 knows what's already done) | optional |

## State snapshot at R25 entry

- **Round:** 24 (CONVERGED)
- **HEAD commit:** `60b9eb1` (R24 close)
- **Metric:** 63 CLOSED · 0 OPEN · 6 BLOCKED · 0 MANUAL_PENDING · 91%
- **Test count:** 333 / 333 PASS (full suite)
- **Mutation watchlist:** EMPTY (all R21+R23 survivors discharged in R24)
- **Narrative blocking:** 0 (NF-23-01 closed in R-24-01)
- **Last ps-verifier verdict:** PASS (R24)
- **Sub-agent write access to `pinscope/convergence/`:** DENIED (orchestrator-records pattern)

## R25 scope (Option Y per user)

| Category | Items | Severity | Est. effort |
|---|---|---|---|
| **A — F7 matrix-rigor sweep (FULL)** | 22 ACs (8 P0/P1 + 14 P2/P3) | Mixed | ~1.5 days |
| **B — AC-024 / AC-025 isolation → integration** | 2 ACs | P2 | ~30 min |
| **C — Polish from R-24-04 audit** | AC-053 fold + AC-001 dedup | LOW | ~30 min |

**Total:** ~26 R-items across ~5-7 waves.

## Critical constraints (don't violate)

1. **SPEC.md is FROZEN** (v2.0.0) — only docs-only footnotes allowed without
   user-approved version bump. R-23-05 added the §8.11 footnote (already
   in matrix as hash `82a942...`).
2. **`ac-matrix.json` edits require explicit user approval** — `/ps-heal`
   GUARD: "the loop never auto-edits the matrix." The matrix-diff doc
   (`R25-MATRIX-PROPOSED-DIFF.md`) is the user's review artifact.
3. **rigor-delta expected:** R25's strengthened verify recipes will likely
   cause `closed_count` to TEMPORARILY DROP from 63 to ~56-60 as some ACs
   that were previously false-PASS reveal real gaps. Document the drop as
   "RIGOR-IMPROVING with transient regression" — do NOT trip the
   monotonicity guard via `record-round` until fixes land.
4. **6 browser-env BLOCKED ACs** (AC-023, AC-030, AC-061, AC-063, AC-082,
   AC-083) — cannot close without Playwright CI. Defer the strengthening
   work for these to a separate Playwright milestone.
5. **Parallel-commit collisions** — user works in parallel on
   `framework/`, `audit-trail-review/`, `apex-spec.md`. Stage only
   pinscope-related files; verify HEAD before committing.

## Files this session created (the R25 prep set)

- `R25-INDEX.md` (this file)
- `R25-PROMPT-FOR-NEW-SESSION.md`
- `R25-MASTER-PLAN.md`
- `R25-MATRIX-PROPOSED-DIFF.md`
- `R25-RISK-REGISTER.md`

All committed in the R24 close window + a follow-up prep commit.
