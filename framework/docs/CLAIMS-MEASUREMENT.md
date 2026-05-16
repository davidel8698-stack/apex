# CLAIMS-MEASUREMENT.md — Methodology SSoT for APEX Aspirational Claims

> **Status:** Authoritative. This file is the single source of truth
> for every aspirational claim APEX makes about itself. Each claim is
> paired with a baseline, a measurement method, a target with a
> timeline, and a single canonical **Honesty Contract** the framework
> binds itself to. If a claim cannot be operationalized in this file,
> it does not belong in `apex-spec.md` or `README.md`.

---

## Honesty Contract (canonical)

The same language MUST appear (verbatim) in every claim below and in
the body of `apex-spec.md` next to each strengthened claim:

> **Honesty contract:** APEX commits to publish the measurement
> methodology (this file), the data-collection pipeline
> (`dora-collect.sh`, forward-reference — to land in Phase 12 M16.1),
> and the rolling sample as it accrues. If the published metric
> diverges from the claimed target after the N-and-timeline budget
> below is exhausted, APEX rephrases the claim within 30 days of
> publication.

Notes on the contract:
- "Rephrase within 30 days" is a self-commitment, not a legal
  guarantee.
- "Diverges" means: rolling sample mean is outside the claim's
  declared band (per-claim section below).
- Data collection is **opt-in** with a published privacy policy.

> **Forward-reference banner:** `framework/PRIVACY-POLICY.md` and
> `framework/hooks/dora-collect.sh` are Phase 12 deliverables (M16.1 /
> M18.1). Until then, references to them in this file and in
> `apex-spec.md` are intentional placeholders. A `404` on these links
> is expected pre-Phase-12 and tracked in `CHANGELOG.md` as a known
> pending dependency, not a broken link.

---

## DORA metric definitions (one canonical per metric)

APEX commits to a single definition per DORA metric. Variants in the
literature exist; APEX uses these and only these:

- **Deployment Frequency (DF):** count of `/apex:ship` invocations per
  active project per week, where "active" = ≥1 commit in the rolling
  7-day window.
- **Lead Time for Changes (LT):** wall-clock seconds from the first
  commit on a task branch to the merge commit on `main`, measured
  per-task and aggregated as the median across the rolling 28-day
  window.
- **Change Failure Rate (CFR):** fraction of `/apex:ship` events
  followed within 24h by a `/apex:rollback` or a hotfix commit that
  reverts the shipped diff. Numerator: rollback + hotfix-revert.
  Denominator: total ship events.
- **Mean Time To Restore (MTTR):** for each CFR-counted incident,
  wall-clock seconds from the failing-ship commit to the restoring
  commit on `main`; aggregated as the median across the rolling
  28-day window.

---

## Claim 1: "The First Framework That Improves DORA"

**Aspirational target (verbatim from `apex-spec.md`):** *"The First
Framework That Improves DORA."*

**Baseline (from research):** DORA 2024 found AI adoption correlates
with **-7.2% delivery stability** (N ≈ 39K respondents). The dominant
mode for AI-augmented teams is *worse* DORA outcomes, not better.

**Method of measurement:**
- Opt-in telemetry via `framework/hooks/dora-collect.sh` (forward-
  reference). Each opted-in project emits a `dora-event.jsonl` line
  per shipping/rollback event; aggregated weekly by
  `framework/scripts/dora-aggregate.sh` (forward-reference).
- The four DORA metrics defined above are computed on the rolling
  28-day window per project, then aggregated across projects via
  median-of-medians.
- Methodology, raw definitions, and aggregation script SHALL be
  public; the raw per-project data SHALL stay local (opt-in upload
  only).

**N and timeline budget:**
- **N target:** ≥ 50 opted-in projects, ≥ 6 months of continuous
  telemetry per project.
- **Timeline:** by 2027-Q2. If N or timeline is not met by 2027-Q3,
  the claim is rephrased per the Honesty Contract.

**Divergence band:**
- The claim is "improves DORA". The threshold for improvement is
  measured against the DORA 2024 baseline (-7.2% stability) and
  declared satisfied if APEX-using projects produce DORA metrics
  **above** the AI-augmented industry mean on at least 3 of the 4
  metrics, with the 4th not worse than industry mean by more than
  one standard deviation.
- If the rolling sample fails this band after the budget is
  exhausted, the claim is rephrased.

**Honesty contract:** APEX commits to publish the measurement
methodology (this file), the data-collection pipeline
(`dora-collect.sh`, forward-reference — to land in Phase 12 M16.1),
and the rolling sample as it accrues. If the published metric
diverges from the claimed target after the N-and-timeline budget is
exhausted, APEX rephrases the claim within 30 days of publication.

**Cross-references:**
- `apex-spec.md` claim block "The First Framework That Improves DORA"
- `README.md` "9 failures" table footer (DORA mirror — byte-identical
  to the strengthened body in `apex-spec.md`)
- `PRIVACY-POLICY.md` (forward-reference)
- Phase 12 M16.1 (`dora-collect.sh`)
- Phase 12 M18.1 (rolling-sample aggregator)

---

## Claim 2: "First-hour, first-session usability"

**Aspirational target (verbatim from `apex-spec.md`):** *"First-hour,
first-session usability is non-negotiable."* (apex-spec.md, principle-
line)

**Baseline (from research):** Empirical study of non-technical users
on AI coding assistants (R5 §3.B internal survey, N=22 internal +
external user-test) reported a median 4.5 hours to first successful
end-to-end deliverable. The dominant first-hour outcome is
incomplete-or-broken state.

**Method of measurement:**
- Opt-in **First-Hour-Telemetry** event stream emitted by
  `framework/hooks/first-hour-telemetry.sh` (forward-reference Phase
  12 M16.1 sub-deliverable).
- Operationalized success criterion: a project counts as "first-hour
  success" iff, within 60 wall-clock minutes of `/apex:start`, the
  user has produced **at least one** verified-and-committed task
  (PLAN.md exists, at least one task with `verify_level` in
  {A,B,C,D}, at least one commit on `main`, `STATE.json` shows
  `current_phase` populated). Failure modes: pipeline halt, decision-
  gate timeout, manual abandonment.
- Aggregated as the per-week first-hour success rate across opted-in
  new projects.

**N and timeline budget:**
- **N target:** ≥ 100 first-hour user sessions across ≥ 30 distinct
  users.
- **Timeline:** by 2027-Q1. If N or timeline is not met by 2027-Q2,
  the claim is rephrased per the Honesty Contract.

**Divergence band:**
- The claim is "non-negotiable", which APEX operationalizes as: ≥ 70%
  of opted-in new-user sessions achieve first-hour success. The 70%
  threshold is the divergence boundary; below it, the claim is
  rephrased.

**Honesty contract:** APEX commits to publish the measurement
methodology (this file), the data-collection pipeline
(`dora-collect.sh`, forward-reference — to land in Phase 12 M16.1),
and the rolling sample as it accrues. If the published metric
diverges from the claimed target after the N-and-timeline budget is
exhausted, APEX rephrases the claim within 30 days of publication.

**Cross-references:**
- `apex-spec.md` principle-line "First-hour, first-session usability
  is non-negotiable"
- `PRIVACY-POLICY.md` (forward-reference)
- Phase 12 M16.1 (`first-hour-telemetry.sh`)

---

## Claim 3: "The First Framework Hardened Against Its Own Files"

**Aspirational target (verbatim from `apex-spec.md`):** *"The First
Framework Hardened Against Its Own Files."*

**Baseline (from research):** R5 §6 enumerated 9 documented incidents
across 2024–2025 in which framework-internal files (CLAUDE.md
templates, agent prompts, state schemas) were successfully used as
prompt-injection vectors against AI coding tools. Defense-in-depth
across filesystem, content, schema, scope, and prompt-injection
layers is the documented gap industry-wide.

**Method of measurement:**
- **Annual third-party security audit** of the APEX codebase against
  the OWASP LLM Top-10 prompt-injection / supply-chain criteria.
- Audit report archived at `framework/docs/audits/AUDIT-<YYYY>.md`
  (forward-reference; the audit directory is created lazily by the
  first audit landing).
- Auditor independence: audit-firm rotation every 3 years; current
  audit-firm name and report-checksum published in the project's
  `SECURITY.md`.
- **Operationalized "Hardened" criterion:** no Critical or High
  prompt-injection / supply-chain finding in the most-recent audit.

**N and timeline budget:**
- **N target:** ≥ 2 consecutive annual audits with no Critical/High
  prompt-injection or supply-chain findings.
- **Timeline:** first audit by 2027-Q2; second audit by 2028-Q2. If
  the budget is not met by 2028-Q3, the claim is rephrased per the
  Honesty Contract.

**Divergence band:**
- Any Critical-or-High prompt-injection / supply-chain finding in any
  audit during the 2-audit budget window puts the claim in the
  rephrase queue (30-day clock starts on report publication).

**Honesty contract:** APEX commits to publish the measurement
methodology (this file), the data-collection pipeline
(`dora-collect.sh`, forward-reference — to land in Phase 12 M16.1),
and the rolling sample as it accrues. If the published metric
diverges from the claimed target after the N-and-timeline budget is
exhausted, APEX rephrases the claim within 30 days of publication.

**Cross-references:**
- `apex-spec.md` claim block "The First Framework Hardened Against Its
  Own Files"
- `framework/docs/SECURITY-RUNTIME.md`
- `.github/SECURITY.md`
- `framework/docs/audits/` (lazy-created on first audit landing)

---

## "First Framework" footnote

APEX's "First Framework" claims (Claim 1 "First Framework That
Improves DORA"; Claim 3 "First Framework Hardened Against Its Own
Files") are scoped to the comparison frame of **open, multi-platform,
config-as-code coding-agent frameworks** (i.e., the BMAD / SuperAGI /
AutoGen / Phidata / OpenDevin frame). APEX does NOT claim primacy
against closed-source vendor offerings (Cursor, GitHub Copilot
Workspace, Cognition Devin) whose internal mechanisms are not
publicly auditable. This footnote MUST accompany either "First
Framework" claim wherever it appears outside of `apex-branding.md`.

---

## Calendar commitments (CHANGELOG.md cross-reference)

The timeline dates in each claim are **commitments**, not estimates.
They are tracked alongside spec changes in `CHANGELOG.md` and
re-asserted at every round closure (`ROUND-R<N>-CLOSURE.md` mentions
each pending claim-timeline when a deadline is within 90 days).

- Claim 1 (DORA): 2027-Q2 target; 2027-Q3 rephrase deadline.
- Claim 2 (First-hour): 2027-Q1 target; 2027-Q2 rephrase deadline.
- Claim 3 (Hardened): 2027-Q2 first audit; 2028-Q2 second audit;
  2028-Q3 rephrase deadline.

---

## Update protocol

This file is updated when:
- A new aspirational claim is added to `apex-spec.md`.
- A measurement methodology changes for an existing claim.
- A timeline date is met or missed (CHANGELOG entry mandatory).
- A divergence triggers the 30-day rephrase clock.

Any change to this file MUST be paired with a synchronized edit to
the corresponding claim block in `apex-spec.md` and, if the claim is
DORA-class, in `README.md` (byte-identical for the headline + body
paragraph).
