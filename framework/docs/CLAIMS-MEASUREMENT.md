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

## DORA measurement engine (M18.1) — implementation contract

This section is the operational counterpart to the four-metric
definitions above. It records the **one definition** the measurement
engine commits to per metric (DORA literature offers multiple), the
**rejected alternatives** (so a future reader knows the choice was
deliberate, not accidental), and the **heuristic limitations** the
engine necessarily inherits from working off a git log alone.

### Engine surface

- **Collector:** `framework/hooks/dora-collect.sh` — extracts the
  quartet from `git log` + STATE events. Idempotent, safe-or-noop.
- **Output:** `.apex/DORA.json` — schema-coherent JSON written
  atomically (rename-temp pattern).
- **Configurable inputs (env):**
  - `APEX_DORA_DEPLOY_TAG_PATTERN` (default: `release/*`)
  - `APEX_DORA_DEPLOY_TAG_PATTERN_ALT` (default: `deploy/*`) — second
    accepted pattern; either matches.
  - `APEX_DORA_WINDOW_DAYS` (default: `28`) — rolling window.
- **Renderers:** `/apex:milestone-summary` (display), `/apex:ship`
  (telemetry delta — forward-ref to M16.1 wiring).
- **Anonymization:** the engine writes raw values to `.apex/DORA.json`
  (local-only). Any telemetry upload is M16.1's surface and applies
  the anonymization filter there. M18.1 itself does not transmit.

### Per-metric committed definition + rejected alternatives

**1. Deployment Frequency (DF) — committed definition.**
- *Engine measurement:* count of tags matching the deploy-tag patterns
  (`release/*` or `deploy/*` by default), per the rolling
  `APEX_DORA_WINDOW_DAYS` window, normalized to deploys-per-week.
- *Rejected alternative:* count of `/apex:ship` invocations from
  `.apex/event-log.jsonl`. **Rejected because** projects often deploy
  without `/apex:ship` (manual tag push, CI pipeline), so tag-counting
  is the more robust ground truth. The `/apex:ship` event count is a
  forward-ref enrichment for M16.1 telemetry but not the headline
  number.
- *Rejected alternative:* count of merges to `main`. **Rejected
  because** merge-to-main and deploy are not synonymous (trunk-based
  flows merge many times per deploy; release-branch flows merge once
  per deploy). Tag count is the deploy signal both flows agree on.

**2. Lead Time for Changes (LT) — committed definition.**
- *Engine measurement:* for each deploy tag in the window, find the
  earliest commit on the branch (or commit-ancestry chain ending at
  the tag) that is not already an ancestor of the previous deploy
  tag. Lead time = `tag_commit_time - first_new_commit_time`.
  Aggregated as the **median** across deploys in the window.
- *Rejected alternative:* time from PR open to PR merge. **Rejected
  because** PR metadata is not in `git log`, and the engine commits to
  working from `git log` alone (portability across hosting providers).
  PR-aware enrichment is a future provider-specific module.
- *Rejected alternative:* time from first-ever-commit-on-branch to
  tag. **Rejected because** long-lived branches inflate lead time
  artificially; the "not-already-shipped" filter is what makes the
  metric reflect lead time *for this change*.

**3. Change Failure Rate (CFR) — committed definition.**
- *Engine measurement:* over the rolling window, CFR = `count(commit
  subject prefixed with revert / hotfix / rollback) / count(total
  commits)`. Per-commit, not per-deploy. The numerator counts
  subject-line prefix matches (case-insensitive, word-boundary).
- *Rejected alternative:* per-deploy CFR (incidents per deploy).
  **Rejected because** per-deploy requires a deploy-to-incident
  causality link that the git log does not carry. The per-commit
  ratio is a coarser proxy but is **falsifiable from `git log`
  alone**, which is the engine's portability contract. The headline
  CLAIMS-MEASUREMENT.md DORA-claim section above uses the per-ship
  definition for the *aspirational target*; the engine reports the
  per-commit proxy and labels the difference explicitly in
  `.apex/DORA.json` (field: `cfr_definition: "per_commit_proxy"`).
- *Rejected alternative:* parse commit *body* (not just subject) for
  failure keywords. **Rejected because** false-positive rate
  ballooned in dogfooding (commit bodies legitimately discuss past
  reverts). Subject-prefix match is the precision-favoring choice.

**4. Mean Time To Restore (MTTR) / Time-to-Restore Service —
committed heuristic + documented limitations.**
- *Engine measurement (heuristic):* for each commit whose subject
  starts with `revert ` / `hotfix ` / `rollback `, restore time =
  `next_forward_tag_time - failing_commit_time`, where
  `next_forward_tag_time` is the earliest deploy-pattern tag whose
  commit is a descendant of the failing commit. Aggregated as the
  **median** across CFR-counted incidents in the window.
- *Heuristic limitations (must be documented to the consumer):*
  1. **Tag-as-restore proxy.** "Restore" in DORA's original sense is
     "service restored to users". The engine cannot observe user
     impact; it proxies "restore" with "next forward deploy tag".
     For projects that deploy continuously, this is close. For
     projects that deploy weekly, this overestimates MTTR
     by up to one deploy-cycle.
  2. **Revert-without-redeploy gap.** A revert merged to `main` but
     not yet tagged is invisible to the heuristic until the next
     tag — MTTR appears longer than the engineering reality.
  3. **No incident-detection signal.** The engine treats the first
     `revert/hotfix/rollback` commit as the incident-start timestamp.
     In practice, the incident started earlier (when the user-visible
     failure began). Engine MTTR is therefore a **lower bound** on
     true MTTR, not an estimate of it.
  4. **Ambiguous ownership.** A revert may target an older deploy,
     not the most recent one. The engine attributes restore time to
     the failing commit it can identify (subject-line revert),
     not to the upstream root-cause commit.
- *Rejected alternative:* parse PR-close-time labelled `incident`.
  **Rejected because** non-portable across hosting providers (same
  reason as LT). PR-aware enrichment is a future module.
- *Rejected alternative:* read incident-management API
  (PagerDuty / Opsgenie). **Rejected because** out-of-scope for an
  in-repo git-log engine; cross-system integration belongs in M16.1
  telemetry's optional enrichment layer.

### How this falsifies the claim

The DORA claim ("The First Framework That Improves DORA") is
**falsifiable** by this engine because:

1. The four metrics are computed from `git log` alone — no
   self-reported survey data, no opaque vendor API.
2. The CFR proxy and MTTR heuristic are documented above with their
   exact biases and direction of error (CFR is per-commit not
   per-deploy; MTTR is a lower bound). A Q1 2027 cohort report can
   either confirm improvement against the DORA 2024 -7.2% baseline
   or trigger the 30-day rephrase clock per the Honesty Contract.
3. The engine's output schema (`.apex/DORA.json`) is stable and
   versioned (field `schema_version`), so longitudinal aggregation
   across the N≥10-team cohort is well-defined.
4. **Non-engineering precondition:** N≥10 teams enrolled in opt-in
   telemetry. This is a project-management precondition, not an
   engineering deliverable; M18.1 does not block on it.

### `.apex/DORA.json` schema (v1)

```json
{
  "schema_version": 1,
  "generated_at": "<UTC ISO-8601>",
  "window_days": 28,
  "deploy_tag_patterns": ["release/*", "deploy/*"],
  "deployment_frequency": {
    "deploys_in_window": <int|null>,
    "deploys_per_week": <float|null>
  },
  "lead_time": {
    "median_seconds": <int|null>,
    "sample_size": <int>
  },
  "change_failure_rate": {
    "ratio": <float|null>,
    "numerator": <int>,
    "denominator": <int>,
    "cfr_definition": "per_commit_proxy"
  },
  "mean_time_to_restore": {
    "median_seconds": <int|null>,
    "sample_size": <int>,
    "heuristic": "next_forward_tag_after_revert"
  }
}
```

Any field reads `null` when the input data is insufficient
(greenfield repo, no tags, etc.). The engine never invents a number.

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
