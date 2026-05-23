# ROOT-CAUSE — Detection Pipeline Defects (Phase 3)

> Phase 3 of the detector-sensitivity campaign. Input: `BASELINE.md` (Phase 2 measurements). Output: a per-cause table tracing each detection failure to an exact line in an agent / command definition, with W-id mapping and proposed fix direction. Consumed by Phase 4 (fix design).

## Reframed master diagnosis (post-Phase-2)

The original W1-W8 hypotheses assumed the detector was *structurally incapable* of catching behavioural defects. **Phase 2 refuted that hypothesis.** R203 (the deep baseline trial — 162 tool calls) caught **all 13 mutants of all 5 classes**, including the spec-silent Class-E cases, by anchoring them to general principles. R201 and R202 caught only the 3 Class-A presence-checks.

**The real defect is unconstrained depth.** When the auditor chooses to go deep, it catches almost everything. When it doesn't, the loop closes whenever the result happens to look "clean." Nothing in the pipeline (a) forces consistent depth, (b) distinguishes a shallow audit from a clean framework, or (c) detects when the loop is converging on its own degraded mode.

This reframes the fix priorities. The Phase-4 design must focus on **locking in the R203-pattern depth as the floor** — not on adding new detection capabilities.

## Root-cause register

Each row: a confirmed root cause → exact source line(s) → fix direction. **CR-ID** = Cause-Root identifier; carries forward into the Phase-4 coverage matrix.

### CR-01 · Depth is unconstrained — no mandatory behavioural pass

- **W mapping:** W2 + W3 + W8 (the central cluster).
- **Phase-2 evidence:** R203 ran an adversarial / behavioural pass (probed guards with crafted payloads, exercised tests, read hook bodies, traced cascade defects) and killed all 13 mutants. R201/R202 stopped at structural / presence checks and killed only Class A.
- **Source-line root:** `framework/agents/specialist/framework-auditor.md:52-115` — the 12 audit axes. **No axis instructs the agent to *attempt* a bypass.** Axis 10 (line 102-106) asks "Where is the path that bypasses them?" — an analytical observation, not an action. The word *attempt* / *try to break* / *adversarial* appears nowhere in the axes. Axis 1 (line 58-64) lists *"mechanisms… present, active, and invoked"* — three properties an auditor can verify by reading; none requires running anything against the mechanism.
- **5-whys trace:**
  1. R201/R202 missed W-B1/B2/B3 — why? They didn't attempt the bypass.
  2. Why didn't they attempt the bypass? — Axis 10 doesn't tell them to.
  3. Why doesn't axis 10 say "attempt"? — It was authored as "investigate" / "look for" framing throughout (line 56: *"the investigation is: 'Where does the current implementation fail to meet the promise…'"*).
  4. Why is that framing inadequate? — Bypass attempts produce observable evidence; analysis-only relies on the auditor's depth choice.
  5. Why does the depth choice vary so much? — Nothing in the prompt grounds it. The "Evidence-grounded pessimism" line (line 22-28) is aspirational not procedural.
- **Fix direction:** add **Axis 13 — Adversarial Falsification** that *mandates* a concrete bypass attempt against each guard hook, with the exit code recorded. Make the action procedural ("attempt and observe"), not analytical ("consider whether").

### CR-02 · Test-suite evidence is inheritable

- **W mapping:** W3.
- **Phase-2 evidence:** R201/R202 did not exercise the test files — W-D1 (tautology in `test-hooks-blocking.sh`) and W-D2 (early exit in `test-decision-mode.sh`) survived these trials. R203 did exercise the tests and killed both. R204's findings note that the negative-control auditor also didn't run the suite (truncated at 400 tool calls).
- **Source-line root:** `framework/agents/specialist/framework-auditor.md` — no clause anywhere mandates running `framework/tests/run-all.sh`. The auditor is free to *infer* the suite is green from prior context (the live R24 audit explicitly states *"the remaining ~68 tests in the suite were not re-run this round… HIGH that the suite is green"* — `apex-audit-findings-R24.md:54`).
- **5-whys trace:**
  1. R201/R202 missed W-D1/W-D2 — why? They didn't run the tests.
  2. Why not? — No prompt clause makes test-suite observation mandatory.
  3. Why not? — The agent definition only mandates writing the findings file (lines 174-192), not running tests.
  4. Why doesn't writing the file imply running tests? — Because the auditor reads source statically and can produce findings without empirical test evidence.
  5. Why is that gap acceptable? — Historically the suite was always "known green" so the auditor inherited the claim. Today (R204) confirms the suite has not been freshly run on baseline — the claim is inherited from older rounds with no re-measurement.
- **Fix direction:** add a **Test-suite evidence rule** before TERMINATION CRITERION — the auditor must either (a) run `run-all.sh --json` to completion and cite real numbers, or (b) explicitly record a BLIND SPOT. Never silently inherit. Pair with a one-line "copy to `.lab/` or non-synced location" pointer for runs that exceed the harness timeout.

### CR-03 · No anti-priming clause

- **W mapping:** W5.
- **Phase-2 evidence:** R205 neutral 17 findings vs R206 primed 4 findings — **76% depth reduction** with priming. The primed trial's `previous_findings_path` was the canonical "POST-CONVERGENCE CONFIRMATION — zero findings — convergence holds" bait. The agent in R206 explicitly stated it would treat priming as input-only, AND R206 still found W-A1 — but its total finding count was 4× lower than R205. Priming doesn't blind, it lowers thoroughness.
- **Source-line root:** `framework/agents/specialist/framework-auditor.md:49-51` — `previous_findings_path` is described as *"for trajectory awareness only"* with a one-line "Do not copy from it" rider, but **no clause instructs the agent to actively resist framing**. R206's depth shows the rider is insufficient.
- **5-whys trace:**
  1. R206 found 4 findings vs R205's 17 — why? Priming reduced thoroughness.
  2. Why does priming reduce thoroughness? — Without an explicit resist-priming rule, prior-findings naturally anchors expectations.
  3. Why does the agent definition lack such a rule? — `previous_findings_path` was introduced as a benign trajectory channel; its anchoring effect was not anticipated.
  4. Why isn't "trajectory awareness only" enough? — It tells the agent the data is reference, not that the agent must hunt as if the prior round didn't exist.
  5. Why does that matter for the loop? — Because the self-heal command labels post-convergence rounds as "confirmation" framing, which compounds the anchoring (`apex-audit-findings-R24.md:1,4`).
- **Fix direction:** add an explicit **Anti-priming clause** to CORE PRINCIPLES: orchestrator framing is noise; a clean prior round is *not* evidence this round is clean; a nudge toward "0 findings" is a reason to look harder, not less.

### CR-04 · Round-checker accepts the auditor's count as ground truth

- **W mapping:** W4.
- **Phase-2 evidence:** **F-204-013** — the negative-control auditor accused R23 of carrying false numerical claims that R24 ratified ("R23 claimed '6 hits' for IMP-039 fields; live grep returns 0"). The historical loop closed CONFIRM on inflated/fabricated coverage data. This is the direct empirical manifestation of W4 in production.
- **Source-line root:** `framework/agents/specialist/round-checker.md:83-89` — the stop criterion is purely count-based (`R<N> P0+P1 == 0` AND `R<N-1> P0+P1 == 0` AND no open P0/P1 new-findings). No clause re-verifies any of the auditor's claims. `:67-71` coverage check counts dispositions ("DONE / WONTFIX documented / deferred documented") without re-judging correctness. `:75-78` spec-drift check is self-referential and **vacuous on a zero-finding round** (DIAGNOSIS L26).
- **5-whys trace:**
  1. R23 ratified false claims — why? Round-checker didn't re-verify them.
  2. Why didn't it re-verify? — Its PROCESS § doesn't mandate independent re-check.
  3. Why not? — Round-checker was designed as a count-aggregator, not an independent re-auditor.
  4. Why is that insufficient? — Because the auditor's claim is the only ground-truth source, and any auditor weakness propagates directly into the stop criterion.
  5. Why is the count-only criterion brittle? — Because shallow audits produce low counts that look identical to clean ones (CR-01 / W8 — the structural "no-detection-floor" problem).
- **Fix direction:** add a **CR-04 spot-check** to round-checker PROCESS — before accepting a "0 P0/P1" audit, independently re-verify 2-3 mechanisms the auditor marked compliant (prefer security guards and the self-heal loop's own files). Strengthen the stop criterion with a fourth conjunct: the audit's coverage map confirms all axes investigated AND the adversarial axis exercised AND the test suite observed (not inherited). "Two clean rounds" must mean "two *deep* clean rounds."

### CR-05 · Filename-contract gap for orchestrator-discovered findings

- **W mapping:** W6 + W7.
- **Phase-2 evidence:** **W-F2 static probe PASSED its design** — the orchestrator's exact glob (`NEW-FINDINGS-R<N>-W<X>.md`) silently misses `NEW-FINDINGS-ORCHESTRATOR-R<N>.md`. A live file matching this orphan pattern already exists at the repo root (`NEW-FINDINGS-ORCHESTRATOR-R20.md`) — the gap is unfixed at HEAD.
- **Source-line root:** `framework/commands/apex/self-heal.md:296-297` — `Collect all wave-result paths and new-findings paths from this round: $REPO_ROOT/WAVE-R<N>-W<X>-RESULT.md for X from 1 to last completed, $REPO_ROOT/NEW-FINDINGS-R<N>-W<X>.md where they exist`. The glob enumerates only `NEW-FINDINGS-R<N>-W<X>.md`. `round-checker.md:20-23` inherits the same pattern. There is no enumeration of orchestrator-discovered new-finding files.
- **5-whys trace:**
  1. NEW-FINDINGS-ORCHESTRATOR-R20.md was never closed — why? It wasn't in round-checker's input.
  2. Why not? — Orchestrator's collection step doesn't glob for that pattern.
  3. Why doesn't it? — The pattern was authored before orchestrator-level discovery was added.
  4. Why wasn't the contract updated? — No test forces a regression on the contract; the orphan file just sits unprocessed.
  5. Why does this matter? — A P1 the orchestrator itself catches is silently dropped.
- **Fix direction:** in `self-heal.md` Step E collection, glob for **both** `NEW-FINDINGS-R<N>-W<X>.md` AND `NEW-FINDINGS-ORCHESTRATOR-R<N>.md`. Update round-checker's INPUT contract to accept both. **Or** — defensive variant — add a contract-validation step that lists any `NEW-FINDINGS*` files at repo root not in the input set and surfaces them as a finding.

### CR-06 · `SPEC-GAP-CANDIDATE` advisory class not present

- **W mapping:** W1 (refined).
- **Phase-2 evidence:** R203 anchored Class-E mutants to existing principles ("Every file APEX writes is a potential prompt") as P1 findings, proving W1 isn't a hard structural blind — but R201/R202 missed them. The asymmetry suggests a lower-threshold mechanism would help less-severe spec-silent defects surface consistently.
- **Source-line root:** `framework/agents/specialist/framework-auditor.md:16-20` — the spec-anchor rule: *"If something does not contradict the spec, it is not a finding."* This rule keeps the COUNT disciplined (avoiding stylistic noise) and should be preserved as-is for P0-P3 findings. But the agent has no advisory channel for borderline observations.
- **Fix direction:** add a **second class of finding — `SPEC-GAP-CANDIDATE`** — in a clearly separated report section, advisory only, NOT counted in P0-P3. The keeps the spec-anchor rule's discipline AND adds a low-threshold surface for spec-silent observations. R203 already does this informally (it anchored E to principles); making the class explicit makes it consistent across trials.

### CR-07 · Orchestrator can inject framing text into AUDIT_CONTEXT

- **W mapping:** W5 (orchestrator side).
- **Phase-2 evidence:** the R24 self-heal round (historical, pre-campaign) had the orchestrator passing the prompt "this is a post-convergence confirmation round" to the auditor. R206 replicates the priming via `previous_findings_path` content. The mechanism — orchestrator passes a primed prior-findings file — is structurally enabled by `self-heal.md`.
- **Source-line root:** `framework/commands/apex/self-heal.md:176-185` — the Step A `AUDIT_CONTEXT` block enumerates the inputs but doesn't prohibit the orchestrator from appending framing text. The historical R24 invocation in the source repo (the `apex-audit-findings-R24.md:1,4` header) shows the framing was set externally.
- **Fix direction:** in `self-heal.md` Step A, add an explicit "no priming" clause — `AUDIT_CONTEXT` is the COMPLETE set of inputs; the orchestrator never appends framing about convergence / confirmation / quiet rounds. `previous_findings_path` is the only trajectory channel and only for labelling.

### CR-08 · Round-checker's posture mapping confuses "stable" with "blind"

- **W mapping:** W4 + W8.
- **Phase-2 evidence:** R201, R202, and many historical rounds (R22, R23, R24) all map to posture **"stable"** via `round-checker.md:124-130` (`P0+P1==0 and STAGNANT → stable`). The same word is used whether the framework is genuinely clean OR the detector has gone silent. F-204-013 shows the live framework is NOT clean, yet R24 was tagged "stable."
- **Source-line root:** `framework/agents/specialist/round-checker.md:117-130` — the posture mapping rule.
- **Fix direction:** add a new posture rung — `stagnant-unverified` or `clean-pending-spot-check` — that fires when `P0+P1==0` AND the audit coverage shows no adversarial-axis exercise / no test-suite observation. Cosmetic-only but matters because the word "stable" is the user-facing signal.

## Coverage check (every Phase-2 surviving-mutant → ≥1 root cause)

| Surviving mutant set | Root causes that explain | Phase-2 trial set |
|----------------------|--------------------------|-------------------|
| W-B1, W-B2, W-B3 (in R201, R202) | CR-01 (no falsification mandate) + CR-04 (no spot-check after audit) | R201 missed; R202 missed |
| W-C1, W-C2, W-C3 (in R201, R202) | CR-01 + CR-04 | R201 missed; R202 missed |
| W-D1, W-D2 (in R201, R202) | CR-02 (test inheritance) + CR-01 (no behavioural pass) | R201 missed; R202 missed |
| W-E1, W-E2 (in R201, R202) | CR-06 (no SPEC-GAP-CANDIDATE class — Class E unanchored on shallow audits) | R201 missed; R202 missed |
| R201, R202 *shallow* baseline pattern | CR-01 + CR-02 (depth not enforced) | symptom captured |
| R206 primed depth reduction | CR-03 (no anti-priming) + CR-07 (orchestrator can inject framing) | symptom captured |
| W-F2 / L17 orphan-finding loss | CR-05 (filename-contract gap) | symptom captured |
| F-204-013 audit-honesty regression (R23 false claim → R24 ratified) | CR-04 (count-based stop) + CR-08 (posture mapping hides blindness) | symptom captured |

Every Phase-2 surviving mutant / probe failure / negative-control finding maps to at least one CR. **Zero orphan symptoms.**

## Phase-4 fix-design inputs

The Phase-4 deliverable (`detector-review/FIX-DESIGN.md`) must produce a coverage matrix with one row per CR. Each row must specify: target file, anchor text, exact replacement / insertion text, acceptance test, expected effect on the Phase-6 re-measurement. CR-by-CR file targets:

| CR | Target file(s) | Edit scope |
|----|----------------|-----------|
| CR-01 | `framework/agents/specialist/framework-auditor.md` | new Axis 13 (Adversarial Falsification) — mandate concrete bypass per guard |
| CR-02 | `framework/agents/specialist/framework-auditor.md` | Test-suite evidence rule (must run or BLIND-SPOT) |
| CR-03 | `framework/agents/specialist/framework-auditor.md` | Anti-priming clause in CORE PRINCIPLES |
| CR-04 | `framework/agents/specialist/round-checker.md` | Independent audit-credibility spot-check + 4th stop-criterion conjunct |
| CR-05 | `framework/commands/apex/self-heal.md` + `framework/agents/specialist/round-checker.md` | Glob both filename patterns; update input contract |
| CR-06 | `framework/agents/specialist/framework-auditor.md` | New `SPEC-GAP-CANDIDATE` advisory class (uncounted) |
| CR-07 | `framework/commands/apex/self-heal.md` | Forbid orchestrator framing in `AUDIT_CONTEXT` |
| CR-08 | `framework/agents/specialist/round-checker.md` | Posture mapping — add `clean-pending-spot-check` rung |

**Scope discipline reminder:** the fix is additive prose to ~3-4 existing files. No new agents, hooks, schemas, or tests. R203 already proves the detection capability exists; the edits LOCK IN that capability as the floor, they don't add new capability.

Spec change (`apex-spec.md`) — owner-approved per single-source-of-truth governance — needs only a short paragraph announcing the new axis count (12 → 13) and the new round-checker spot-check. Flagged in Phase 4 for owner sign-off.

## Phase-3 close

Gate 3 criterion: *"every survivor traced to exact root-cause anchor; no survivor is left as 'unclear'."* **Met.** Eight CRs cover all symptoms; coverage check above proves no orphan symptoms. Phase 4 (Fix Design + Critic Review) opens.
