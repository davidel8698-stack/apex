# Invariant-Based Correctness: Specifiable and Enforceable for Open-Ended Autonomous Software?

> **Research question.** Can correctness invariants/constraints for a real software project be
> (1) specified well enough to meaningfully constrain an autonomous agent's work, and
> (2) automatically enforced at runtime as the agent works — or is invariant-based correctness
> another elegant idea ("define the rejection region, not the target") that fails in practice for
> open-ended software? This report actively seeks disconfirming evidence and tests whether the
> invariant alternative escapes the same specification-gap trap that defeats target/fitness objectives.

---

## Verdict

**SPECIFIABLE-BUT-INCOMPLETE — and NOT practically enforceable, end-to-end, by an autonomous agent on a general SaaS build.**

The evidence splits cleanly along a scope line the research question demanded we hold:

- **Where it works (narrow, safety-critical, human formal-methods teams):** Invariant-bearing specs
  *can* be operationalized into continuous runtime/test oracles (AWS uses TLA+/P specs as test oracles
  and runtime monitors), they *do* catch real defects that careful testing missed (the s2n handshake
  bug, PR #551), and once built they are *cheap to maintain* (956 CI proof re-plays, only 3 manual
  proof updates over ~2 years). This is real, measured, and primary-sourced. **(Verdict component:
  specifiable-and-enforceable — but only here.)**

- **The fatal gap for the autonomous-agent / open-ended case:** Three independent failure modes are
  all *measured*, not speculative. (a) **The unstated-invariant problem is the central difficulty, by
  AWS's own admission** — "the challenge is to find a system invariant strong enough to ensure no safety
  property is violated"; you only catch violations of properties you actually wrote. (b) **Passing
  invariants ≠ correct code** — TLA+ verifies the *design*, not the executable; AWS states plainly "we
  don't [know]" the code implements the verified design, and property-based tests express only *partial*
  correctness because the exact-output oracle is usually unavailable. (c) **The LLM-as-invariant-author
  exhibits the fox-guarding-henhouse failure directly:** automated property extraction from a spec
  drops **9–13% of constraints**, an LLM agent's property-violation reports are only **56% valid bugs
  (32% report-worthy)**, and in a documented case the LLM constrained its generated tests to `n≥1`
  *exactly where the bug lived at n≤0*. **(Verdict component: not-practically-enforceable for the
  open-ended autonomous case.)**

**Bottom line for a month-long autonomous build:** "Define what must never be violated" is a sound
*direction* and strictly better than a game-able target objective, but it does **not** escape the
specification-intent trap. It moves the hard problem (writing a strong-enough, complete invariant set)
and, critically, *the entity asked to write the invariants is the same entity about to err* — and the
measured evidence is that it under-constrains precisely there. Build on invariants as a **partial
safety net with known holes**, not as an enforceable foundation that establishes correctness.

---

## Approach efficacy and cost summary (measured, with evidence grades)

| Approach | Measured efficacy | Measured cost | Catches agent-class bugs? | Grade |
|----------|-------------------|---------------|---------------------------|-------|
| **Formal spec / model checking (TLA+/P)** | Operationalized as test oracles + runtime monitors at AWS; finds subtle design bugs | Learnable in 2–3 weeks; specs a few hundred lines — BUT verifies *design not code*; "we don't know" code matches | Design-level only; cannot verify code-to-spec at scale | **A** (primary, peer-reviewed CACM/AWS) |
| **Formal proof of code (Cryptol/SAW, s2n)** | Caught real handshake bug testing missed (PR #551); robust to change (3 updates / 956 re-plays) | HMAC ~3mo, DRBG ~3mo, TLS handshake ~8mo, by Galois experts, on <10k LOC | Yes, within a narrow crypto library with a dedicated team | **A** (peer-reviewed CAV'18 + primary PR) |
| **Property-based testing (PBT)** | ~50× more mutants killed per-test vs unit tests (corpus, no causation) | "More complex to write"; effort *not measured*; 5% adoption / 98.4% of tests are unit | Partial — expresses *partial* correctness; oracle usually unavailable | **A−** (primary OOPSLA'25; corpus, not RCT) |
| **Metamorphic testing (MT)** | Published classifier MRs detected only **14.8%** of 709 mutants on re-evaluation | (not the focus here) | Weak in the one large re-evaluation available | **B** (single 2019 IEEE study, domain-specific) |
| **LLM-generated PBT/EBT (edge cases)** | 11/16 (68.75%) each; hybrid only 81.25% → misses ~19% | n=16 curated-hard subset | No — under-constrains exactly where bug lives (`n≥1`) | **B+** (primary AIware'25; small n) |
| **Agentic PBT (LLM infers + runs properties)** | **56%** valid bugs; **32%** report-worthy → over-generates | 984 reports / 100 packages | Low precision on actionable defects | **A−** (primary 2025; Hypothesis maintainer co-author) |
| **Automated property/invariant extraction from NL spec** | **9–13% of constraints missing** | (LLM pipeline) | Incomplete by measurement | **B+** (peer-reviewed FSE'25 Companion) |
| **Runtime monitoring of invariants** | Used by AWS as a "correctness oracle" in production | Not separately quantified in these sources | Only properties you wrote | **B** (stated in AWS 2025, not independently measured) |

Grades: **A** = multiple/primary peer-reviewed with strong isolation; **B** = primary but narrow
(single study/domain/small n); **C** = vendor/blog (none relied upon here).

---

## Finding 1 — Invariant-bearing specs CAN be operationalized as continuous oracles, but only the DESIGN is verified, never the running code (Confidence: HIGH)

**Sources:** CACM/ACM Queue "Systems Correctness Practices at Amazon Web Services" (Vol 22 No 6, 2025);
Newcombe et al. "How AWS Uses Formal Methods" (CACM 58:4, 2015 / Lamport-hosted PDF). Both primary,
peer-reviewed practitioner venues. Votes 3-0 (claim 0) and 2-1 (claim 1).

- **The "elegant idea" survives operationalization.** AWS uses formal specs in TLA+/P as **test
  oracles that provide the correct answers** for its testing, drives discrete-event simulation off the
  same models, and uses **runtime monitoring as a correctness oracle** in production. So invariant-
  bearing specs are *not* merely one-off design proofs — they can run continuously. This is the
  strongest disconfirmation of "invariants are just an elegant idea."
- **But the verification stops at the design.** When engineers ask "how do we know the executable code
  correctly implements the verified design?", AWS's answer is *"we don't."* They "are not aware of any
  such tools that can handle distributed systems as large and complex as those we are building," and
  conventional static analysis "cannot verify compliance with a high-level specification."
- **Directly relevant to a real build:** passing all design-level invariants does **not** establish the
  running code is correct. The 2024 FM paper "Validating Traces of Distributed Programs Against TLA+
  Specifications" confirms the gap is *still* closed only by finite trace comparison, not proof; MongoDB
  likewise *tests* code-spec conformance rather than proving it; state-space explosion is a hard scale
  limit (a ZooKeeper TLA+ spec "cannot finish in ten days" at 3 nodes/3 transactions).

**Scope caveat (load-bearing for our question):** every AWS data point is a *human formal-methods team*
applying specs to *narrow distributed protocols*. None of it demonstrates enforceability by an
autonomous agent on a general SaaS build.

---

## Finding 2 — The unstated-invariant / specification-gap problem is the CENTRAL difficulty, by the practitioners' own framing (Confidence: HIGH)

**Sources:** Newcombe et al. (CACM 2015); Snook "Exploring the Barriers to Formal Specification"
(Southampton thesis, 2001) + Gleirscher & Marmsoler "Formal Methods in Dependable Systems Engineering"
(Empirical Software Eng. 25, 2020, n=216). Votes 3-0 (claims 2, 4, 5).

- **AWS names the trap as THE challenge:** "A good system invariant captures the fundamental reason why
  the system works... The challenge is to find a good system invariant, one that is strong enough to
  ensure that no safety properties are violated." This is *exactly* the specification-gap problem the
  research question feared — moving from a target spec to an invariant set does not dissolve it; it
  relocates it. An entire research subfield (inductive-invariant inference: I4 HotOS'19, endive FMCAD'22)
  exists *because* finding a strong-enough invariant manually is hard.
- **The hard part is the human modeling/abstraction step, not the notation.** Experienced practitioners
  report formal specs are "difficult to write," with "choosing appropriate abstractions" the particular
  difficulty (Snook). Corroborated: producing an abstract model "was much harder than formalizing
  concrete designs."
- **Adoption fails on the writing/learning side, not on innate math difficulty.** The largest survey
  (n=216) finds positive perceived *usefulness* but negative perceived *ease of use*; barriers are
  "scalability, skills, and education," not that the math is beyond typical engineers. This matters for
  the agent case: the bottleneck is *authoring a complete, correct abstraction* — precisely the step an
  LLM is least reliable at (Finding 5).

---

## Finding 3 — Specification cost is LOWER than the stereotype, and built invariants are CHEAP to maintain — within the narrow safety-critical regime (Confidence: HIGH)

**Sources:** Newcombe et al. (CACM 2015); "Continuous Formal Verification of Amazon s2n" (CAV 2018,
Springer LNCS 10982 + AWS whitepaper) + s2n GitHub PR #551. Votes 3-0 (claims 3, 6, 7), 2-1 (claim 8).

- **Learning cost is modest:** engineers from entry-level to Principal learned TLA+ from scratch and got
  "useful results in 2 to 3 weeks," sometimes self-taught on weekends, on specs of a few hundred lines.
  *Residual caveat (in-source):* building a model that "captures the significant aspects of the real
  system... is a difficult skill, the acquisition of which requires thoughtful practice."
- **Proof cost for code-level verification is high even on a tiny codebase:** HMAC ~3 months, DRBG
  ~3 months, TLS handshake ~8 months — all by Galois proof-tool experts, on a <10k-LOC (just over 6,000
  lines of C) safety-critical library. This is the real cost of *proving the code*, not just the design.
- **Invariants/proofs DO catch real bugs other methods missed:** even with a "carefully designed state
  machine," formal verification uncovered missing branches in the s2n handshake state machine (PR #551,
  verified against an RFC-based spec with SAW) — a real liveness defect that testing/design review had
  not caught.
- **Maintenance is cheap once built:** 956 CI proof re-plays over ~2 years, only **3** manual proof
  updates ever required, each completed before code review finished. The proof structure "nearly
  eliminates the need for developers to understand or modify the proof following modifications to the
  code." (Vote 2-1; the dissent noted 956 overstates how many runs involved *changed proven code* —
  which, if anything, strengthens the low-marginal-cost claim.)

**Scope caveat:** this is the canonical "works for safety-critical narrow systems with formal teams"
regime. It is *not* evidence an autonomous agent could specify/enforce invariants on a general build.

---

## Finding 4 — Property-based / metamorphic testing find more bugs per test, but express only PARTIAL correctness, have low adoption, and unmeasured human cost (Confidence: HIGH for PBT; MEDIUM for MT)

**Sources:** Ravi & Coblenz "An Empirical Evaluation of Property-Based Testing in Python" (OOPSLA 2025,
PACMPL 9, Art. 412); Saha & Kanewala "Fault Detection Effectiveness of Metamorphic Relations..."
(IEEE 2019, arXiv:1904.07348). Votes 3-0 (claims 9, 10, 11, 12).

- **Per-test efficacy is large but causally unproven:** PBTs killed mutants at ~**50×** the per-test rate
  of unit tests, *even controlling for coverage* — "the first quantitative evidence" of this, but a
  corpus study that **cannot establish causation** (better programmers may both write PBTs and write
  better tests).
- **PBTs check PARTIAL correctness only:** "the properties expressed are only partial correctness
  properties, since testing whether the output equals some known-correct value requires a (usually
  unavailable) oracle." So **passing PBTs do not establish the code is correct** — only that the checked
  properties hold. This is the oracle problem (Barr et al., IEEE TSE 2015) and it is exactly the gap a
  correctness foundation needs to close and cannot.
- **Adoption is low and human cost is unmeasured:** 98.4% of tests in the (PBT-adopting) corpus were
  still unit tests; a 2023 survey of 25,000 Python devs found only **5%** used Hypothesis (6th place).
  The paper explicitly **does not** measure human effort to write/maintain a PBT vs a unit test, and
  notes PBTs are "more complex to write" because you must specify properties over a *family* of inputs.
- **Metamorphic testing's measured efficacy is weak in the one large re-evaluation:** published MRs for
  supervised classifiers detected only **14.8%** of 709 reachable mutants — far below earlier reports.
  *Caveat:* single 2019 study, one domain (classifiers); cite as "published MRs can be far weaker than
  originally reported," not a universal MT ceiling. (Note: two MT claims arguing MRs approach oracle-level
  detection were **refuted 0-3** in adversarial verification — see Refuted Claims.)

---

## Finding 5 — An LLM agent generating its OWN invariants under-constrains exactly where it errs (the fox-guarding-henhouse failure is MEASURED) (Confidence: HIGH)

**Sources:** Tanaka et al. "Understanding the Characteristics of LLM-Generated Property-Based Tests in
Exploring Edge Cases" (AIware 2025 / arXiv:2510.25297); Maaz, DeVoe, Hatfield-Dodds, Carlini "Agentic
Property-Based Testing" (arXiv:2510.09907, 2025); "From Prompts to Properties" (FSE 2025 Companion, DOI
10.1145/3696630.3728702). Votes 3-0 (claims 13, 15, 16), 2-1 (claims 14, 17).

This is the most decisive finding for the autonomous-agent question, because it tests point (5) directly:
*can an LLM reliably generate and respect its own invariants?* The measured answer is **no**.

- **Hybrid LLM test generation still misses ~19% of edge-case bugs:** LLM-generated PBTs and example-based
  tests each detected bugs in 11/16 (68.75%) curated edge cases, with *no* significant difference
  (McNemar p=1.00); combining both reached only **81.25%**. (Small, deliberately hard n=16.)
- **The fox-guarding-henhouse mechanism is observed, not theorized:** for HumanEval/150 the LLM set the
  constraint `n≥1` in *all* its generated tests, "missing this critical boundary condition" — while the
  actual bug lived at `n≤0`. The agent under-specified the input region *containing the bug it was
  supposed to find*. (Vote 2-1: the dissent fairly notes HumanEval/49's `n=0,p=1` miss was missed by
  *both* PBT and EBT, so it evidences general incompleteness rather than self-under-specification
  specifically; HumanEval/150 cleanly shows the self-under-specification mode.)
- **Agentic PBT over-generates non-bugs:** an agent that infers properties and synthesizes/runs PBTs
  across the Python ecosystem produced reports that were only **56% valid bugs**, **32% report-worthy**
  — i.e. ~44% invalid/unconfirmed and 68% not report-worthy, over 984 reports / 100 packages. Precision
  is *recoverable with ranking* (top-21 → 86% valid), but unfiltered self-generated property checks have
  low actionable precision.
- **Automated invariant extraction from the NL task is itself incomplete:** **9–13% of constraints
  missing** when extracting properties from problem descriptions — direct measured evidence for the
  unstated-invariant gap. (Vote 2-1: the "exactly where it errs" co-location is a hedged *risk*, not
  measured here; the load-bearing fact — extraction is incomplete — holds.)

**Synthesis:** the same entity asked to author the invariants is the entity about to err, and across three
independent 2025 studies it (a) leaves 9–13% of constraints unstated, (b) constrains test inputs away from
the buggy region, and (c) emits low-precision property violations. An agent self-generating its own
correctness net is structurally compromised in exactly the way the research question feared.

---

## The unstated-invariant incompleteness problem, head-on

Every layer of evidence converges on one structural fact: **invariant checking only ever catches
violations of properties someone actually wrote, and writing the complete set is the unsolved hard part.**

- AWS frames "find an invariant strong enough" as *the* challenge (Finding 2).
- PBTs are *partial* oracles by construction (Finding 4).
- LLM extraction drops 9–13% of constraints and self-constrains away from bugs (Finding 5).
- TLA+ verifies design, not code, so even a complete *design* invariant set leaves the implementation
  unproven (Finding 1).

There is no measured evidence that an invariant set for a rich, open-ended software system can be made
*complete*. The comparison the research question invited — is an invariant spec easier than a target spec?
— resolves as: **not easier, and possibly harder**, because a target spec must merely describe the goal,
whereas a sufficient invariant set must anticipate *every* way the goal could be violated, including the
failure modes the author has not imagined. The human-validation analogue (the cited STL-spec study, humans
~45%±20% accurate at checking spec-vs-intent) was not re-confirmed for invariants in this corpus, but the
Snook/Gleirscher evidence (abstraction is the hard human step) points the same direction.

---

## Documented abandonment / false-confidence cases

Honest reporting: this corpus produced **less hard abandonment evidence than the question sought**, and
some candidate disconfirming claims were *refuted* in verification rather than confirmed.

- **False confidence (confirmed pattern):** "all checked properties pass" ≠ correct, because PBTs are
  partial oracles and TLA+ proves only the design. AWS's own "we don't [know] the code matches the design"
  is the cleanest false-confidence admission. The s2n literature also documents a *separate* packet-ordering
  null-deref DoS that formal verification **failed to catch** (it was outside the verified properties) —
  the canonical "invariants passed, software still wrong" failure (noted as a confound that was correctly
  *not* conflated with the PR #551 success).
- **No clean adoption-then-abandonment case was confirmed.** The strongest candidate — a claim that AWS by
  2025 had "moved away from heavyweight formal verification toward lightweight methods" — was **refuted
  0-3**: AWS *added* lightweight/semi-formal methods as a portfolio, it did not abandon formal methods.
  Treat "formal methods get abandoned in industry" as **unsupported by this corpus**; the documented
  pattern is *narrow, sustained, expert-driven use*, not abandonment.

---

## Caveats, evidence weaknesses, and time-sensitivity

- **Scope is the dominant caveat.** Nearly all *positive* enforceability evidence (Findings 1, 3) is from
  AWS/Galois formal-methods teams on narrow safety-critical distributed/crypto code. Generalizing it to an
  autonomous agent on open-ended SaaS is exactly the leap the evidence does **not** license.
- **Causation gaps.** The PBT ~50× result is a corpus study (no random assignment). The LLM studies use
  small, curated, or hard subsets (n=16 edge cases; HumanEval/MBPP) and may not generalize to production
  codebases.
- **Single-study reliance.** The 14.8% MT figure is one 2019 study in one domain. The 9–13% extraction-gap
  is one FSE'25 Companion paper. Weight accordingly.
- **Two key claims split 2-1** (TLA+ design-vs-code limit; LLM self-under-specification co-location). The
  factual cores survived; the strongest interpretive extensions did not.
- **Time-sensitivity (HIGH on the LLM side).** All LLM-invariant evidence is 2025 and model-specific
  (Claude-4-sonnet, StarCoder/CodeLlama). Model capability is moving fast; the *direction* (LLMs
  under-constrain their own invariants) is well-supported now but the *magnitudes* may shift within months.
- **Verification text-extraction note:** two primary PDFs (Lamport AWS paper; s2n whitepaper) were on a
  Hebrew-path filesystem; the s2n figures were extracted locally, the 2015 AWS quotes corroborated via 3+
  independent secondary reads. Quotes are reliable; flagged for transparency.

---

## Open questions

1. **Is there a measured co-location result?** No study in this corpus directly measures whether an LLM's
   *unstated* invariants co-locate with its *own code errors* (the precise fox-guarding-henhouse claim).
   The mechanism is observed anecdotally (HumanEval/150) but not quantified at scale.
2. **What is the human/agent specification COST of a sufficient invariant set vs a target spec?** The PBT
   paper explicitly declines to measure effort; no source quantifies the relative authoring cost — the
   single most decision-relevant unknown for a month-long build.
3. **Can an external/independent invariant author (a different model, or human review) close the
   fox-guarding-henhouse gap?** All LLM evidence is self-generation; no data on adversarial or independent
   invariant generation as a mitigation.
4. **Is there an invariant analogue to the 45%±20% human STL-spec-validation result?** Whether humans (or
   agents) can reliably judge that an invariant set *matches intent* — distinct from whether invariants
   pass — was not established in this corpus and is central to trusting any invariant foundation.
