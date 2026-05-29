# Correlated Failure: Is Causal Decorrelation of Two Verification Paths Structurally Achievable?

> **Research question.** Is there any STRUCTURAL way to achieve genuine causal decorrelation between
> two independent verification paths — so they do NOT share a common error source and do NOT fail
> together on the same subtle bugs — or is decorrelation always partial and temporary, collapsing as
> the underlying models grow more capable? This report tests, and tries to FALSIFY, the premise that
> "two independent paths catch each other's errors." It separates sharply (a) decorrelation between two
> model-based paths from (b) decorrelation between a model-based path and physical-execution reality.

---

## Verdict

**Genuine causal decorrelation between two MODEL-BASED verification paths is fundamentally illusory at
the limit and, in practice, only PARTIAL and SHRINKING with capability. Genuine STRUCTURAL decorrelation
is achievable only by grounding one path in REAL EXECUTION / physical reality — and even that breaks
*correlation with the generator's model errors*, not all error (a shallow or mis-targeted oracle still
fails).**

The evidence splits cleanly along the line the question demanded:

- **Two model-based paths cannot be made independent — this is now both theorem and measurement.**
  The classic theory (Eckhardt-Lee 1985) proves that even *independently developed* versions fail
  *dependently*, because a per-input "difficulty function" makes hard inputs hard for everyone; the
  independence assumption that combining versions multiplies failure probabilities is false. Knight &
  Leveson (1986/1990) confirmed this empirically for human teams. For LLMs the result is now *measured
  and worse*: across 350+ models, two models agree ~60% of the time when both err, and — decisively for
  the scaling question — **larger and more accurate models have MORE correlated errors, even across
  distinct architectures and providers.** A zero-knowledge random-string control still shows cross-model
  correlation up to 0.35, ruling out shared facts as the sole cause and implicating shared *inductive
  biases / architecture*. Same-model resampling (self-consistency) is the weakest of all: a shared
  systematic bias (e.g. positional bias) makes samples fail *together*, and aggregation *amplifies*
  rather than cancels the error.

- **Forced diversity (Littlewood-Miller 1989) is the one theoretical escape hatch — and it is real but
  conditional and bounded.** By *mandating* diverse methodologies, one can in principle achieve
  *better-than-independent* (negatively correlated) failure behaviour; later work (Salako 2007) derives
  the explicit bounds and shows the improvement is *conditional, not automatic*. Crucially this is a
  THEORETICAL possibility about forced *methodological* diversity, demonstrated analytically, never an
  empirical guarantee for deployed systems — and it *reduces* correlation, it does not drive it to zero.

- **The capability-scaling angle resolves against model-diversity:** measured evidence shows blind spots
  *converge* as models get stronger, with a plausible irreducible floor from shared training corpora and
  aligned inductive biases. So model-vs-model decorrelation is precisely weakest where it is most needed
  (subtle bugs / hard regions) and degrades over time.

- **The decisive structural escape is execution-against-reality.** The strongest LLM-consensus paper
  states the requirement outright: scaling truthfulness "requires external grounding or interventions
  that break error correlation, rather than [more samples]." Reality (compilation, runtime, real I/O) is
  not produced by any model, so it is not subject to the shared-difficulty / shared-prior mechanism that
  correlates two model paths. BUT the multi-agent-failure literature shows the *design* of that grounded
  path still matters: a verifier that checks a shallow surrogate (code compiles) instead of the real
  requirement (runtime behaviour, domain rules) catches nothing — and verification is one factor among
  several (specification, design, communication), not a sufficient guarantee on its own.

**Bottom line for an architecture resting on "two independent paths catch each other's errors":** If
both paths are model-based, the premise is FALSIFIED at the limit and unreliable in practice — and it
gets worse as models improve. The architecture is only sound if at least one path is anchored in real
execution/reality AND that path is targeted at the actual requirement, not a shallow proxy. Treat
"decorrelation" as a property you *engineer by changing the entropy source*, never one you get for free
from two instances/models/samples.

---

## Findings

### Finding A — Theory proves independently-developed versions fail DEPENDENTLY (the shared-difficulty mechanism). [HIGH]

Eckhardt & Lee (1985) established, as a theoretical (not merely empirical) result, that independent
development *cannot* yield failure independence: a per-input "intensity/difficulty function" describes
the propensity of versions to fail *together* on the same inputs, so failures are positively correlated
on average. This directly breaks the assumption that combining versions multiplies their independent
failure probabilities; that assumption *overstates* reliability gains. The mechanism generalizes
directly to LLM verification paths sharing common "hard" regions of the problem space — inputs hard for
one path tend to be hard for all. Littlewood-Popov-Strigini ("new results," FTCS-28 1998 / ACM Computing
Surveys 2001) advanced this from average-of-a-random-pair to predicting the reliability of a *specific*
deployed pair, formalizing how failure dependence between actual versions arises.

- Confidence: HIGH — multiple primary peer-reviewed safety-engineering sources, all 3-0 votes; a
  mathematical theorem that has never been overturned, only extended.
- Sources: Eckhardt & Lee 1985 (IEEE TSE, DOI 10.1109/TSE.1985.231895); Littlewood/Popov/Strigini
  (IEEE FTCS-28 doc 689457; ACM Computing Surveys 33(2):177-208, 2001).
- Claims merged: [0], [2], [3], [4].

### Finding B — Empirically, independently-developed versions failed together far more than independence predicts — and DIFFERENT faults still correlate. [HIGH]

Knight & Leveson (1986) and the follow-up fault analysis (Brilliant, Knight & Leveson 1990) found that
27 versions built independently from identical specs, each individually highly reliable, failed together
on the same inputs *substantially more* than statistical independence would predict (independence
rejected at >99% confidence; ~50% of faults correlated; up to 8 versions failing simultaneously). Two
distinct mechanisms were documented: (1) programmers made *equivalent* logical errors on the
intrinsically hard sections (universal challenges), and (2) *genuinely different* logical errors still
produced statistically correlated failures on the same hard input subspaces — so correlation persists
even when the underlying faults differ. The result was adversarially defended by Knight against
published criticism; critiques concerned generalization, not the empirical fact of correlated failure.

- Confidence: HIGH — foundational peer-reviewed result (IEEE TSE + NASA NTRS), 3-0 votes, defended
  against critics, still the canonical citation.
- Sources: Knight & Leveson 1986 (IEEE TSE); Brilliant/Knight/Leveson 1990 (NASA NTRS 19900041359, IEEE
  TSE 16(2):238-247); Knight "Reply to the Criticisms" (sunnyday.mit.edu/critics.pdf).
- Claims merged: [8], [9], [10].

### Finding C — Forced diversity is the one theoretical escape: it can yield BETTER-than-independent behaviour — but it is conditional, bounded, reduces-not-eliminates, and only proven analytically. [HIGH]

Littlewood & Miller (1989) proved that *forced* methodological diversity (mandating different
methods/languages/processes across versions) can *decrease* the probability of simultaneous failure and,
at the limit, induce *negative* failure correlation — so a 1-out-of-2 system can be MORE reliable than
under the independence assumption. This is the sharp distinction the question asked for: it is "better
than independent," not merely "a reduction toward independence." Salako (SAFECOMP 2007) derives explicit
lower and upper bounds on the system's expected probability-of-failure-on-demand and specifies the
*conditions* under which forced diversity *guarantees* an improved bound — i.e. the improvement is
conditional, not automatic. Two hard limits stand: (1) it is a THEORETICAL/analytical possibility about
forced *methodological* diversity, never demonstrated as an empirical guarantee in deployed systems;
(2) even the strongest result never drives coincident-failure probability to zero. Forced diversity
*reduces* correlation; it does not eliminate it.

- Confidence: HIGH — primary peer-reviewed sources (IEEE TSE 1989 doc 58771; Springer SAFECOMP 2007;
  ACM Computing Surveys 2001 review), all 3-0 votes; correctly hedged as theoretical/conditional.
- Sources: Littlewood & Miller 1989 (IEEE TSE 15(12):1596-1614, DOI 10.1109/32.58771, NASA NTRS
  19900036555); Salako 2007 (SAFECOMP, LNCS 4680, DOI 10.1007/978-3-540-75101-4_38); Bishop (Springer
  978-3-540-75101-4_38).
- Claims merged: [1], [5], [6], [7].
- Caveat / open conflict: forced diversity is the strongest pro-decorrelation result in the corpus, yet
  it has NO empirical demonstration in the LLM setting and its "different methodology" analogue for two
  LLMs (different architecture/provider) is exactly what the measured LLM evidence (Finding D) shows is
  INSUFFICIENT. The theory's escape hatch and the LLM measurements point in opposite directions; this is
  surfaced, not resolved.

### Finding D — For LLMs, errors are MEASURABLY correlated and correlation INCREASES with capability across architectures and providers. [HIGH]

A large-scale empirical study of 350+ LLMs (two leaderboards + a resume-screening task) found
substantial error correlation: on one leaderboard dataset two models agree ~60% of the time when both
err (a conditional-agreement statistic, P[same wrong | both wrong], not a Pearson r). Decisively for the
scaling question: **larger and more accurate models have HIGHLY correlated errors, even with distinct
architectures and providers** — error correlation *increases* with capability. The standard assumption
that diversity in training data, architecture, and providers mitigates homogeneity had no large-scale
empirical support before this work, and the work finds that assumption holds only *partially /
insufficiently*, not fully. A separate LLM-consensus study quantifies the human-vs-LLM gap independently:
human ensembles average Q-statistic ~0.39 (weakly correlated) vs LLM ensembles ~0.86 (strongly
correlated — when one LLM errs, others likely repeat the same error), with hybrid human-LLM crowds
(~0.55) decorrelating better than LLM-only.

- Confidence: HIGH — peer-reviewed primary source (ICML 2025), N=350+, multiple datasets, independently
  corroborated; all 3-0 votes. Caveats: the 60% figure is conditional agreement not Pearson; scope is
  multiple-choice/numeric-rating tasks, *not* the subtle-bug verification domain (authors call it "a
  limited view"); the paper establishes correlation, not proven causal convergence.
- Sources: Kim/Garg/Peng/Garg "Correlated Errors in Large Language Models" (arXiv 2506.07962, ICML
  2025); Q-statistic gap corroborated via 2506.07962 + IJCAI 2025 (arXiv 2505.12349).
- Claims merged: [11], [12], [13].

### Finding E — LLM error correlation comes from SHARED INDUCTIVE BIASES / ARCHITECTURE, not only shared facts — implying an irreducible correlation floor from the common training corpus. [HIGH]

The strongest mechanistic evidence: a zero-knowledge control (feed models 10,000 uniformly random
32-character ASCII strings, force an A/B/C/D choice with no ground-truth signal) still produced
cross-model correlations as high as 0.35. This *rules out shared factual knowledge as the sole
explanation* and points to aligned inductive biases and architectural similarities. Models trained on
overlapping corpora and optimized for similar objectives acquire shared priors and blind spots, so
additional samples *reinforce* shared misconceptions rather than canceling errors — "polling does not
cancel these mistakes; it amplifies shared misconceptions, producing greater confidence without greater
correctness." This is the direct argument that all current LLM-based verification shares a correlation
floor.

- Confidence: HIGH on the measured fact and mechanism (3-0 votes), corroborated by the 350+-model study.
  MEDIUM on the strength of the floor: the primary source (arXiv 2603.06612) is a non-peer-reviewed
  preprint; 0.35 is an upper bound, not a typical value; a single random-noise correlation is consistent
  with shared-architecture convergence but does NOT by itself prove decorrelation is impossible, nor does
  it speak to execution-against-reality.
- Sources: Denisov-Blanch/Kazdan/Schaeffer/Koyejo et al. "Consensus is Not Verification" (arXiv
  2603.06612, Feb 2026); corroboration: arXiv 2506.07962.
- Claims merged: [18], [19].

### Finding F — Same-model resampling (self-consistency) is the WORST decorrelation strategy: a shared systematic bias makes samples fail together, and aggregation amplifies the error. [HIGH]

Sampling the same model multiple times produces correlated errors that aggregation cannot fix, because a
systematic shared error source within one model (demonstrated: positional bias on long-context tasks)
directly violates self-consistency's core assumption that individual samples fail independently. Measured:
self-consistency *actively degrades* long-context performance (statistically significant improvement in
only 3 of 56 dataset-model pairs; summarization ROUGE declined in 19/24 = 79% of that subset). The shared
bias drives samples to fail on the *same* instances — in 30-document contexts, ~60% of the time none of
eight intermediate samples found the correct source, with majority/unanimous wrong consensus common (e.g.
7 of 8 generations wrong). This is the Knight-Leveson mechanism reproduced at the level of same-model
sampling: same weights, same blind spots, correlated failure. Stronger models also *converge on the same
wrong answer*: on 53% of MATH questions where multiple models err they converge to the same incorrect
answer; the most common wrong answer accounts for 65-87% of wrong MATH responses.

- Confidence: HIGH — peer-reviewed (TACL 2026 / 651 experiments) for the positional-bias result; 3-0
  votes. Scope caveats: the self-consistency degradation is task-conditional (long-context, position-bias
  regime — SC *helps* on short-context); the 79% figure is the summarization subset, not the full 56-pair
  pool; the 53%/65-87% convergence figures are MATH-specific (AIME concentration is lower, 20-63%).
- Sources: Byerly & Khashabi "Self-Consistency Falls Short!" (arXiv 2411.01101, TACL 2026, DOI
  10.1162/TACL.a.625); MATH convergence from arXiv 2603.06612.
- Claims merged: [14], [15], [16], [20].

### Finding G — The decisive structural escape: EXTERNAL GROUNDING that breaks correlation, not more samples — but the grounded path must target the REAL requirement, not a shallow surrogate. [HIGH]

The strongest LLM-consensus paper states the requirement head-on: aggregation only helps when an
*external verifier* exists, because verification (external grounding) is what converts samples into
correctness; "scaling truthfulness... requires external grounding or interventions that break error
correlation, rather than [more samples]." When errors are correlated, no aggregation rule based solely on
*internal* signals can reliably scale truthfulness. This is the architectural pivot: a path grounded in
real execution / physical reality (compilation, runtime, real I/O) is not produced by any model, so it is
not subject to the shared-difficulty / shared-prior mechanism that correlates two model-based paths —
giving STRUCTURAL (not merely statistical) decorrelation that model-vs-model diversity cannot.

The critical qualifier: grounding is necessary but the *design* of the grounded path is what catches
bugs. In real multi-agent systems, verification agents frequently fail because they check a shallow
surrogate (e.g. "the code compiles") rather than the actual requirement (runtime behaviour, domain-rule
compliance) — a verifier that only checks compilation, without running the program or checking chess
rules, catches nothing substantive. Verification-related failures are a dedicated category (3 of 14
modes; ~21% of failures), and the authors explicitly deny that verification alone resolves failures,
naming specification, design, and communication as co-causes. So adding a verification path — even a
grounded one — does NOT guarantee error-catching unless it actually executes against and tests the real
requirement.

- Confidence: HIGH on the *requirement* (external grounding breaks correlation) and on the verifier-design
  failure mode (3-0 votes; MAST is peer-reviewed/OpenReview, Cohen's Kappa 0.88). MEDIUM on the strength
  of the structural-decorrelation conclusion itself: the corpus *implies* execution-vs-reality is
  structurally uncorrelated with model errors (reality is not model-generated) and the consensus paper
  *prescribes* external grounding, but no source in this corpus directly MEASURES the residual correlation
  between a model-based generator and a real-execution oracle. The structural argument is sound by
  construction (different entropy source) but the magnitude of residual coupling (shared spec
  misunderstanding feeding both the generator and the test the generator wrote) is not quantified here.
- Sources: Denisov-Blanch et al. (arXiv 2603.06612); Cemri et al. "Why Do Multi-Agent LLM Systems Fail?"
  (MAST, arXiv 2503.13657); also arXiv 2505.17656 corroborates cross-model external-verifier need.
- Claims merged: [21], [22], [23].

---

## Decorrelation strength, ranked (entropy-source view)

From weakest to strongest, by how much each changes the underlying *entropy source* of the second path:

1. **Same model, resampled (temperature/self-consistency)** — WORST. Identical weights → identical blind
   spots; shared systematic bias makes samples fail together; aggregation *amplifies*. (Finding F)
2. **Two instances of the same base model** — identical weights/training/blind spots; effectively the
   same as (1) for subtle bugs. (Findings D, E by extension)
3. **Two different models, same lab / similar recipe** — correlation reduced but high (Q ~0.86 for LLM
   ensembles); shared inductive biases dominate. (Findings D, E)
4. **Cross-architecture / cross-provider model diversity** — the diversity people *assume* helps;
   measured to be INSUFFICIENT, and the residual correlation INCREASES with capability. (Finding D)
5. **Forced methodological diversity (Littlewood-Miller)** — theoretically can reach *negative*
   correlation, but conditional, bounded, never-zero, and unproven for LLMs. (Finding C)
6. **A model-based path vs REAL EXECUTION / physical reality** — STRUCTURAL decorrelation: reality is not
   model-produced, so it does not share the difficulty/prior mechanism. Necessary, and the only candidate
   for genuine causal independence — but only catches model errors *if the oracle targets the real
   requirement, not a surrogate*. (Finding G)

---

## What remains genuinely UNKNOWN

1. **The residual correlation between a model-generator and a real-execution oracle is not measured in
   this corpus.** The structural argument (reality ≠ model output) is sound by construction, but no source
   here quantifies the coupling that arises when the *same* spec misunderstanding contaminates both the
   code the model writes AND the test/oracle the model writes for it. Execution decorrelates from the
   model's *implementation* errors; it may NOT decorrelate from the model's *specification/intent* errors
   if the human-or-model-authored oracle inherits the same misunderstanding. This is the most important
   gap for the architecture.
2. **No LLM-domain measurement of forced diversity.** Littlewood-Miller's better-than-independent result
   is analytic and from human-software N-version programming. Whether forcing architecture/training-data
   diversity across LLMs can reach *negative* error correlation (vs merely reduced) is untested; the
   measured LLM evidence suggests cross-architecture diversity alone is insufficient, which is in tension
   with the theory.
3. **The capability-scaling trajectory is established for current models but not proven monotone.** The
   350+-model study shows correlation increasing with capability *now*; whether there is a threshold past
   which it plateaus, whether the shared-corpus floor is truly irreducible, and whether deliberately
   disjoint training data could break it, are not settled.
4. **Subtle-bug regime is under-measured.** The strongest LLM correlation numbers come from
   multiple-choice / numeric-rating / math tasks, not from the subtle-software-bug verification domain
   where a verifier is most needed — and the difficulty mechanism predicts correlation is WORST exactly
   there, but this is inference, not direct measurement.
5. **Disjoint-training-data ensembles** ("engineer genuine epistemic diversity through disjoint training,"
   named as a second pathway in arXiv 2603.06612) are a proposed but, in this corpus, undemonstrated route
   to model-based decorrelation.
