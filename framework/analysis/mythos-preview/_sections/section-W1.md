# Wave 1.1 — Foundation Sections (§1, §2.1, §6)

## Coverage

- **Pages**: 10–15 (§1), 16–19 (§2.1), 184–198 (§6)
- **Effective relevance to APEX**: LOW–MEDIUM. §6.2 (Contamination) is genuinely useful methodology.
- **Reader time**: 30 min

---

# §1 — Introduction

## Coverage

- Pages 10–15
- Relevance: LOW for direct APEX mechanics; sets framing
- 15 min

## Key Findings

- **[F-1-01] Mythos Preview is a frontier-only release for cyber defense partners**
  - Quote: "we have made the decision *not* to release Claude Mythos Preview for general availability"
  - Significance: The system card is unusually candid because the model isn't public — Anthropic documents failure modes more openly than for general-release models. The findings are calibrated to the real frontier of capability.

- **[F-1-02] Capability jump warrants new internal-deployment alignment gate**
  - Quote: "for the first time, we arranged a 24-hour period of internal alignment review … before deploying an early version of the model for widespread internal use"
  - Significance: Anthropic established a *pre-internal-deployment* alignment gate. APEX has `/apex:health-check`, but no analogous gate before exposing the framework to a real codebase for the first time.

- **[F-1-03] Risk Reports cover model fleet; System Cards address one model's delta**
  - Significance: Pattern of fleet-level vs delta-level safety analysis. Useful organizational principle for `apex-spec.md` revisions vs per-release notes.

## Methodologies

- **[M-1-01] 24-hour alignment-focused testing window**
  - Setup: Model held back from agentic traffic; small testing group runs ~12 lightweight assessment tracks in parallel before unblock.
  - Tracks: scaled-up behavioral audit, eval-awareness-suppressed variant, safeguard-evasion evals, sandbagging checks, single-forward-pass reasoning measurements, replay on real prompts, RL behavior review, ad-hoc red-team.
  - Reusable for APEX? Yes — concept maps to "before enabling a new agent/hook on real projects, run a sweep across all evals". Currently APEX's `/apex:health-check` is a single check, not a windowed multi-track sweep.

## Mechanisms

- **[X-1-01] Pre-deployment hold + cross-functional assessment compile-and-review**
  - Purpose: Catch acute misalignment risks before exposing a new model to internal infrastructure
  - How: Cross-functional team (alignment, interp, security) compiles findings into a single recommendation; reviewed by research leadership before unblock.

## Lessons for APEX

- **[L-1-01] Add a "first-deployment gate" before a new framework version touches real projects**
  - Source: F-1-02, M-1-01
  - APEX components: `/apex:health-check`, `framework/scripts/`, potentially a new `/apex:framework-release-gate`
  - Initial coverage hypothesis: PARTIAL (health-check exists but is per-install, not per-version)
  - Initial priority: P2
  - Rationale: APEX has dramatic version-to-version changes (the user is actively self-healing). A "release gate" that runs a multi-track sweep before a version is allowed to act on a project's git tree would catch regressions early.

- **[L-1-02] Document risk-update cadence separate from per-release notes**
  - Source: F-1-03
  - APEX components: `apex-spec.md`, `framework/apex-design-notes.md`
  - Initial coverage: PARTIAL (spec gets versioned; no separate "risk delta" document per release)
  - Initial priority: P3
  - Rationale: Cosmetic discipline issue. Low blast radius.

## Open Questions

- **[Q-1-01]** Could APEX adopt the "fleet vs delta" framing for module-ecosystem updates? When `apex-frontend` module changes, is there a delta document?

---

# §2.1 — RSP Risk Assessment Process

## Coverage

- Pages 16–19
- Relevance: LOW (Anthropic's internal regulatory process)
- 8 min

## Key Findings

- **[F-21-01] RSP v3 shifts from binary thresholds to overall risk assessments**
  - Quote: "We have increased our requirements with respect to giving our overall risk assessments, as opposed to simply focusing on what thresholds have been crossed"
  - Significance: Shift from rule-based gating to judgment-based risk descriptions. Useful framing for APEX self-heal closure verdicts, which currently focus on P0/P1 counts.

- **[F-21-02] Capability evaluations as base, multi-source evidence as construct**
  - Quote: "automated evaluations, uplift trials, third-party expert red teaming, and third-party assessments"
  - Significance: Multi-source convergent evidence is the pattern. APEX uses cross-model critic but rarely combines automated + scripted + adversarial sweeps for one feature.

## Methodologies

- **[M-21-01] Subject-matter expert findings → internal feedback → Responsible Scaling Officer review**
  - Setup: Each threat model has SME-driven evidence collection, then peer review, then leadership decision.
  - Reusable for APEX? Partial — APEX's `framework-auditor` plays the SME role; `remediation-planner` plays peer review; round-checker is closer to RSO. The chain exists but it's per-round, not per-spec-revision.

## Lessons for APEX

- **[L-21-01] Add overall-posture statement to self-heal closure reports**
  - Source: F-21-01
  - APEX components: `framework/agents/specialist/round-checker.md`, `ROUND-R<N>-CLOSURE.md` template
  - Initial coverage: PARTIAL (closure currently lists P0/P1 counts; not a holistic posture statement)
  - Initial priority: P2
  - Rationale: A 3–5 sentence "overall risk posture" at the top of closure reports would help non-technical readers quickly grasp framework health.

---

# §6 — Capabilities (Focused: §6.2 Contamination + Overall Approach)

## Coverage

- Pages 184–198, primary focus 184–188
- Relevance: MEDIUM for §6.2 methodology; LOW for benchmark results themselves
- 25 min

## Key Findings (§6.2 Contamination)

- **[F-62-01] Contamination is hard to fully decontaminate from training corpora**
  - Quote: "Answers to the questions on public benchmarks can inadvertently appear in a model's training data, inflating the scores"
  - Significance: Universal problem. APEX evaluations (if any) face the same risk.

- **[F-62-02] Multi-pronged detection: corpus grep + LLM auditor scoring + rule-based comment detection**
  - Quote: "we use a Claude-based auditor that compares each model-generated patch against the gold patch and assigns a [0, 1] memorization probability … A complementary rule-based check flags substantial verbatim comment overlap"
  - Significance: Detection isn't a single rule. Composite detection (semantic + literal) catches more cases.

- **[F-62-03] Threshold-sweep validation instead of single-cutoff**
  - Quote: "we sweep the auditor's decision threshold across its full range rather than commit to a single cutoff"
  - Significance: Robustness check. If a finding only holds at one threshold, it's brittle.

- **[F-62-04] Rewrite-and-compare for ambiguity-tolerant benchmarks**
  - Quote: "we manually perturb each question or image and compare original versus remix accuracy"
  - Significance: For CharXiv, they created 100-item "remix" with equivalent difficulty. Model scoring **higher** on remix than original is positive evidence against memorization.

- **[F-62-05] Decision to **drop a benchmark entirely** when contamination cannot be assessed**
  - Quote (about MMMU-Pro): "Given the difficulty of determining the impact of contamination, we choose to omit results"
  - Significance: Discipline of dropping unreliable signal rather than reporting it caveated. Direct lesson for APEX's own evaluation infrastructure.

## Methodologies

- **[M-62-01] Claude-based memorization auditor**
  - Setup: Model-generated patch + gold patch → auditor LLM → [0,1] memorization probability with weighted signals (verbatim code overlap, distinctive comment text, etc.)
  - Reusable for APEX? Yes — directly. APEX uses cross-model critic; could add memorization-style auditor for cases where ground truth exists.

- **[M-62-02] Threshold sweep validation**
  - Setup: Re-score the benchmark at every auditor-threshold value 0.0→1.0; plot the pass-rate curve.
  - Reusable for APEX? Yes for any binary decision driven by a numeric score. APEX's circuit-breaker tool-call cap (80 → 400) could be sweep-validated.

- **[M-62-03] Held-out variant construction**
  - Setup: Manually perturb questions/images while preserving difficulty (chart-label swap, second-highest→second-lowest series swap).
  - Reusable for APEX? Yes for any test suite used to measure framework changes. If APEX tests are written once and not perturbed, their continued passing is weak evidence of framework health.

## Mechanisms

- **[X-62-01] Composite memorization detection (auditor + rule-based + corpus grep)**
  - Purpose: Identify benchmark instances where the model is regurgitating training data instead of reasoning
  - How it works: Three independent signals; problem flagged if any one fires.

- **[X-62-02] Score-stability-vs-threshold check**
  - Purpose: Confirm result isn't an artifact of a chosen cutoff
  - How: Sweep cutoff, look for plateau.

## Lessons for APEX

- **[L-62-01] Adopt composite (not single-rule) detection for high-stakes APEX flags**
  - Source: F-62-02, M-62-01
  - APEX components: `framework/hooks/phantom-check.sh`, `framework/hooks/destructive-guard.sh`
  - Initial coverage: PARTIAL (destructive-guard is composite via 9 deny patterns; phantom-check is single-rule regex)
  - Initial priority: P2
  - Rationale: phantom-check could miss novel ways to express uncertainty. A composite check (semantic LLM judge + rule-based regex + statistical claim/evidence ratio) would be more robust.

- **[L-62-02] Adopt threshold-sweep discipline for APEX-tuned numerical thresholds**
  - Source: F-62-03, M-62-02
  - APEX components: `framework/hooks/circuit-breaker.sh` (tool-call cap), `CONTEXT_BUDGET.default.json` (zone thresholds), `framework/hooks/_rotation-decide.sh` (55%/70% triggers)
  - Initial coverage: MISSING (current thresholds are hand-tuned; no sensitivity analysis recorded)
  - Initial priority: P2
  - Rationale: When thresholds are set without sensitivity analysis, a small environment change can flip behavior. Especially relevant for the rotation triggers.

- **[L-62-03] When an APEX evaluation result can't be trusted, drop it rather than report it caveated**
  - Source: F-62-05
  - APEX components: `framework/agents/verifier.md`, `framework/agents/critic.md`, `RESULT.json` schema (`verified_criteria[]` / `unverified_criteria[]`)
  - Initial coverage: COVERED (RESULT.json already distinguishes verified vs unverified)
  - Initial priority: P3 (already addressed in spirit)
  - Rationale: APEX's existing `verified=false` mechanism is the analogous discipline. Worth noting it's a *good* example of an already-implemented lesson.

- **[L-62-04] Rewrite-and-compare to validate that APEX test suites measure real coverage**
  - Source: F-62-04, M-62-03
  - APEX components: `framework/agents/auditor.md` (test-quality auditor), test files in framework test suites
  - Initial coverage: PARTIAL (auditor checks for vacuous assertions and self-mocking; doesn't perturb-and-rerun)
  - Initial priority: P2
  - Rationale: A perturb-and-rerun check on APEX's own test suite would validate that tests aren't passing by coincidence. Effort medium; impact medium.

## Open Questions

- **[Q-62-01]** Does APEX have any evaluation suite for the framework itself beyond `/apex:health-check`? If yes, are those tests perturb-resistant?

---

# Aggregate Lessons (Wave 1.1)

| Lesson ID | Theme | Priority |
|-----------|-------|----------|
| L-1-01 | First-deployment gate for framework versions | P2 |
| L-1-02 | Risk-delta document per release | P3 |
| L-21-01 | Overall-posture statement in self-heal closure | P2 |
| L-62-01 | Composite (not single-rule) detection for high-stakes flags | P2 |
| L-62-02 | Threshold-sweep discipline for tuned numerics | P2 |
| L-62-03 | "Drop, don't caveat" untrusted results (COVERED — affirmation) | P3 |
| L-62-04 | Rewrite-and-compare for APEX's own test suite | P2 |

**Wave 1.1 totals**: 7 lessons. None P0/P1. This is expected — foundation sections describe organizational process, not behavioral failures.
