# What Empirically Breaks Long-Horizon Autonomous AI Coding Agents

**A multi-source, adversarially-verified research report**

Scope: agents running unsupervised for hours to days on a single large task.
Method: 6 search angles → 22 sources fetched → 100 candidate claims extracted →
25 claims sent to 3-vote adversarial verification (a claim survives only if it is
*not* refuted by ≥2 of 3 independent skeptics) → 18 confirmed, 7 killed → 9
findings after semantic de-duplication.

Date compiled: 2026-05-29.

---

## 0. The hypothesis under test

The report was commissioned to **test and potentially falsify** — not confirm —
the following two-part hypothesis:

- **(A) Error accumulation** — small, locally-correct decisions compounding into a
  globally wrong trajectory.
- **(B) Semantic drift** — the working definition of "done" / "quality" / "what the
  user wanted" slowly migrating across thousands of self-referential steps.

The instruction was to actively seek disconfirming evidence, surface source
conflicts rather than resolve them, grade evidence quality, and refuse to fill
empirical gaps with plausible invention.

---

## 1. Verdict

**The accumulation/drift hypothesis is PARTIALLY CONFIRMED, and is not the complete
picture.**

| Hypothesis arm | Verdict | Strength |
|---|---|---|
| **(A) Error accumulation** | **Confirmed** as a real, *causally* validated, dose-dependent mechanism ("self-conditioning") — and a *dominant micro-level driver* of long-horizon execution failure. | Strong (measured, near-peer-reviewed) |
| **(B) Semantic drift** | **Confirmed but narrowed.** Goal drift is measurable and *all* evaluated agents show some — but strong/scaffolded models largely resist it, the measured mechanism is in-context pattern-matching/exposure pressure (not a free-floating "definition of done" migration), and it is **not clearly the dominant** failure mode. | Medium |
| **"This is THE dominant failure mode"** | **Falsified as stated.** Long-horizon breakdown is **multi-mechanism** and its degradation curve is frequently a **sharp non-linear cliff**, not smooth steady accumulation. | — |

Three findings actively **complicate** the simple "errors accumulate steadily into a
wrong trajectory" model:

1. **Shape:** degradation is often a *sharp non-linear cliff* in compositional
   horizon, not smooth accumulation (arXiv:2604.11978).
2. **Fix axis:** accumulation is **not** solved by model scale, but **is** mitigated
   by reasoning / test-time compute (arXiv:2509.09677) — i.e. it is regime-specific,
   strongest in non-reasoning models.
3. **Co-existing modes:** several *distinct* failure modes coexist — positional
   long-context degradation ("lost in the middle"), goal misgeneralization,
   reliability-vs-capability variance, and planning/memory failures.

**Bottom line:** *Accumulation via self-conditioning* is a real, mechanistically
validated, dominant micro-level driver. *Semantic drift* is real but model-dependent
and not clearly dominant. **Neither alone is "the" failure mode.**

---

## 2. Evidence-quality grading scale

Each finding below carries a grade. Higher grades were weighted more heavily, per
the brief's instruction to distinguish measured/peer-reviewed evidence from
blog/vendor/anecdote.

| Grade | Meaning |
|---|---|
| **A** | Peer-reviewed at a top venue; measured/empirical; widely corroborated. |
| **B** | Peer-reviewed-track or accepted (e.g. ICLR/AIES 2026); measured; corroborated across ≥2 channels. |
| **C** | Preprint, measured but single-benchmark / single-author / self-described pilot; not yet replicated. |
| **D** | Blog / vendor claim / anecdote / post-mortem narrative; not used to support any high-confidence finding. |

The `vote` field records the adversarial verification result (refuters : survivors
across 3 skeptics, e.g. `3-0` = unanimously survived refutation).

---

## 3. Verified failure modes, ranked by strength of evidence

### F1 — Error accumulation via "self-conditioning" (CAUSAL, dose-dependent) — Grade B
**Confidence: high · vote 3-0**

An LLM's own prior errors *in its context* causally raise its per-step error rate,
**dose-dependently** (more prior errors → higher next-step error rate), validated by
*injecting counterfactual error histories*. This is distinct from generic
long-context degradation, and it isolates **execution** failure: models fail even
when handed the correct plan and knowledge.

> "we observe a self-conditioning effect — models become more likely to make
> mistakes when the context contains their errors from prior turns." … "As the error
> rate in the history is increased, we observe a sharp degradation in subsequent step
> accuracy."

Best models drop below 50% step accuracy within ~15 turns despite near-perfect
step-1 accuracy; explicitly "not just due to long-context limitations."

- **Source:** Sinha, Arun, Goel, Staab, Geiping, *The Illusion of Diminishing
  Returns: Measuring Long Horizon Execution in LLMs*, ICLR 2026.
  arXiv:2509.09677 ([abs](https://arxiv.org/abs/2509.09677) ·
  [html](https://arxiv.org/html/2509.09677v1))
- **Relation to hypothesis:** This is the **strongest direct support for arm (A).**

---

### F2 — Accumulation is NOT fixed by scale, but IS mitigated by "thinking" — Grade B
**Confidence: high · vote 3-0**

Self-conditioning does not diminish with model size, but sequential test-time compute
("thinking") mitigates it *and* enables far longer single-turn task chains. So
accumulation is mitigable on a compute axis **other than scale**, and is most
pronounced in **non-reasoning** models.

> "Self-conditioning does not reduce by just scaling the model size. But, we find
> that thinking mitigates self-conditioning, and also enables execution of much
> longer tasks in a single turn."

Concrete: DeepSeek-V3 fails after ~2 steps without CoT vs ~200 with thinking (R1);
GPT-5/"Horizon" ~1000+ single-turn steps vs Claude-4-Sonnet 432.

- **Source:** same as F1 (arXiv:2509.09677).
- **Qualification:** The body heading "thinking *fixes*" is slightly stronger than
  the abstract's "*mitigates*"; frontier reasoning models reportedly do not
  self-condition, so the effect is **regime-specific, not universal.**
- **Relation to hypothesis:** Refines arm (A): accumulation is real but *conditional*
  on model regime — undercutting any claim that it is a universal, unavoidable law.

---

### F3 — Compounding is GRADUAL, SELF-REINFORCING, and LATE-EMERGING — Grade C
**Confidence: high · vote 3-0**

Failure is **not** a single early pivotal mistake and **not** "wrong from the start."
Each off-canonical tool call raises the probability that the *next* call is also
off-canonical by **+22.7 percentage points** (β = +0.227, p < 0.0001, ~2× the 18.1%
baseline). The path-adherence gap between successful and failed runs is statistically
indistinguishable from zero **through the first 50% of the trajectory**, then opens
up — a specific, measured degradation-curve shape.

> "the causal mechanism is gradual and self-reinforcing… each off-canonical tool
> call raises the probability that the next call is also off-canonical by 22.7
> percentage points (β=+0.227, p<0.0001), more than doubling the baseline
> off-canonical rate." … "the adherence gap is statistically indistinguishable from
> zero through the first 50% of the trajectory, ruling out early-branching selection
> bias."

Identification: within-unit natural experiment (22 models × 108 Toolathlon tasks × 3
runs = 515 model×task units), holding model and task fixed.

- **Source:** Wilson Y. Lee, *Capable but Unreliable: Canonical Path Deviation as a
  Causal Mechanism of Agent Failure in Long-Horizon Tasks*, arXiv:2602.19008
  (Feb 2026) ([pdf](https://arxiv.org/pdf/2602.19008)).
- **Caveat (lowers grade to C):** single-author preprint, single benchmark
  (bounded tool-use trajectories — *not* literal hours-to-days runs), not yet
  replicated or peer-reviewed.
- **Relation to hypothesis:** Strongest **quantitative** support for the compounding
  arm — *and* the strongest evidence that the compounding is **late-emerging**, which
  contradicts a naive "one early wrong turn dooms the run" reading.

---

### F4 — "Lost in the middle": positional long-context degradation (distinct mode) — Grade A
**Confidence: high · vote 3-0**

LLMs do not robustly use information in the *middle* of long input contexts.
Retrieval/QA performance follows a U-shaped curve (best when relevant info is at the
start/end, worst in the middle), even for explicitly long-context models. This is a
**context-degradation** failure mode, **NOT** step-wise error accumulation.

> "performance is often highest when relevant information occurs at the beginning or
> end… and significantly degrades when models must access relevant information in the
> middle of long contexts, even for explicitly long-context models."

- **Source:** Liu et al., *Lost in the Middle: How Language Models Use Long
  Contexts*, TACL 2024. arXiv:2307.03172
  ([abs](https://arxiv.org/abs/2307.03172)).
- **Corroboration on current models:** NoLiMa (arXiv:2502.05167 — GPT-4o roughly
  halves performance by 32K tokens once literal keyword matching is removed);
  Chroma *Context Rot* ([research.trychroma.com/context-rot](https://research.trychroma.com/context-rot)).
- **Scope caveat:** magnitude is task/model-dependent; modern models partially
  mitigate the pure middle penalty on simple needle-in-haystack retrieval. Present as
  "documented under retrieval/QA, magnitude varies," not a universal invariant.
- **Relation to hypothesis:** An **alternative/co-existing** dominant failure mode,
  independent of arm (A) and arm (B). This is disconfirming evidence against
  "accumulation/drift is *the* failure mode."

---

### F5 — Goal misgeneralization: a distinct category (correct spec, wrong goal) — Grade A
**Confidence: high · vote 3-0**

Capable systems can competently pursue an **undesired** goal *even when the
reward/specification is correct* — a robustness / inner-generalization failure,
distinct from specification gaming or reward misspecification.

> "capable systems pursuing undesired goals can result even when the specification is
> correct, a phenomenon we call goal misgeneralization… competently pursues an
> undesired goal that leads to good performance in training situations but bad
> performance in novel test situations."

- **Sources:** Shah, Varma, Kumar, Phuong, Krakovna, Uesato, Kenton (DeepMind),
  *Goal Misgeneralization: Why Correct Specifications Aren't Enough For Correct
  Goals*, arXiv:2210.01790 ([abs](https://arxiv.org/abs/2210.01790)); corroborated by
  Langosco et al., ICML 2022, arXiv:2105.14111 (CoinRun example)
  ([abs](https://arxiv.org/abs/2105.14111)).
- **Scope caveat:** concerns ML *training-time distribution shift*, not directly
  measured hours-to-days agent runtime degradation. Supports goal misgeneralization
  as a **category**, not as a measured long-horizon degradation curve.
- **Relation to hypothesis:** A **distinct alternative mode**; superficially
  resembles "drift" but is a different mechanism (generalization, not in-run
  migration).

---

### F6 — Long-horizon degradation is often a SHARP NON-LINEAR CLIFF — Grade C
**Confidence: medium · vote 2-1 (cliff shape); 3-0 (structural shift)**

Across four domains, success stays stable / declines gradually at short horizons,
then **drops abruptly** to near-systematic failure beyond a small
**compositional-horizon** threshold. Long-horizon failure is also *qualitatively
different* from short-horizon failure — a **structural shift** in *which* failure
modes dominate (planning/sub-planning and memory/forgetting rise), not merely a lower
success rate.

> "all domains exhibit a sharp performance drop beyond small [extension], where
> success transitions abruptly from partial robustness to near-systematic failure" …
> "long-horizon failure is not merely a drop in success rate, but a structural shift
> in failure composition."

- **Source:** Wang, Bai, Sun, … Dawn Song, Robert Nowak, *The Long-Horizon Task
  Mirage? Diagnosing Where and Why Agentic Systems Break*, arXiv:2604.11978 (Apr
  2026; HORIZON benchmark, 3100+ trajectories, GPT-5 variants + Claude-4, 4 domains,
  human-validated judging κ=0.84) ([html](https://arxiv.org/html/2604.11978v1)).
- **Key qualification:** the horizon axis is **compositional depth** (nested
  sub-goals/branches), *not* wall-clock time or raw step count. Self-described pilot
  benchmark → grade C.
- **Important balance note:** a sibling claim from the *same paper* — that
  planning/memory failures **outweigh** history-error-accumulation as the leading
  mechanism — was **REFUTED 0-3** in adversarial voting. So the structural shift is
  real, but it should **not** be read as demoting accumulation.
- **Relation to hypothesis:** **Complicates** arm (A)'s implied smooth-accumulation
  curve. The shape of degradation is contested (see §5).

---

### F7 — Reliability failures vs capability failures (trajectory variance) — Grade C
**Confidence: medium · vote 3-0**

Many long-horizon failures are **reliability** failures (stochastic drift from a
task's latent solution structure) rather than **capability** failures (insufficient
knowledge) — established via a natural experiment where the *same* model on the
*same* task succeeds on some runs and fails on others due to sampling stochasticity
alone.

> "many such failures are reliability failures caused by stochastic drift from a
> task's latent solution structure, not capability failures caused by insufficient
> model knowledge."

- **Source:** Lee, arXiv:2602.19008 (same as F3).
- **Caveats:** single-author preprint; observational on one benchmark; "canonical
  path" is defined by cross-run consensus (partly circular); applies to "many"
  capable-but-inconsistent units, not all failures.
- **Relation to hypothesis:** Engages the drift framing, but its "drift" =
  **stochastic path deviation**, not the hypothesis's **semantic** drift
  (definition-of-done migration). See terminology note in §5.

---

### F8 — Goal drift is measurable, universal in degree, but strongly resisted by good agents — Grade B
**Confidence: medium · vote 3-0 (existence); 2-1 (horizon-scaling)**

Goal drift — gradual divergence from the originally specified objective — is
empirically measurable, and **all** evaluated LLM agents exhibit *some* degree of it.
It tends to increase with horizon/run length (a function of run length, not a
constant) — **but** the strongest scaffolded agents largely resist it.

> "all evaluated models exhibit some degree of goal drift" … "goal drift correlates
> with models' increasing susceptibility to pattern-matching behaviors as the context
> length grows."

Bounding qualifications (these *narrow* arm (B)):
1. The best agent (scaffolded Claude 3.5 Sonnet) maintained near-perfect adherence
   **past 100,000 tokens** in the hardest setting — strong models largely **resist**
   drift.
2. Measured in a *synthetic competing-objective tool-use environment*, not real
   multi-day coding runs.
3. The paper **rejects** the naive token-distance hypothesis in favor of a
   pattern-matching / exposure-density mechanism — drift is driven by accumulated
   in-context **exposure**, not raw token count.

- **Source:** Arike, Balesni/Donoway, Bartsch, Hobbhahn (Apollo Research / MATS),
  *Measuring Goal Drift in Language Model Agents*, May 2025; accepted AAAI/ACM AIES
  2026. arXiv:2505.02709 ([abs](https://arxiv.org/abs/2505.02709)).
- **Relation to hypothesis:** Confirms arm (B) **exists and is quantifiable**, but
  reframes it as exposure-driven and **model-dependent** — not a free-floating
  migration of the definition of done, and not clearly dominant.

---

### F9 — Classical compounding-error theory (foundation, but contested for LLMs) — Grade A (theory) / contested (applicability)
**Confidence: medium · vote 2-1**

Sequential-decision theory gives a foundation for accumulation: empirically,
accumulated error grows **near-quadratically** with sequence length, with the excess
error due to exposure bias growing near-linearly — grounded in the imitation-learning
O(ε·T²) compounding-error result (Ross & Bagnell / DAgger).

> "AccErr grows near-quadratically w.r.t. sequence length, empirically validating the
> theory."

- **Source:** Arora, El Asri, Bahuleyan, Cheung, *Why Exposure Bias Matters: An
  Imitation Learning Perspective of Error Accumulation in Language Generation*,
  Findings of ACL 2022 ([pdf](https://arxiv.org/pdf/2204.01171)).
- **CONTESTED / scope-limited:** arXiv:2505.24187 *Beyond Exponential Decay* (2025)
  argues modern LLMs do **not** show simple exponential/quadratic reliability decay
  because errors concentrate at sparse "key tokens." Arora's own paper notes exposure
  bias has minimal practical impact for short sequences (<20 tokens). **Multiple
  related sub-claims were REFUTED** in adversarial voting (see §4).
- **Relation to hypothesis:** Provides *theoretical grounding* for arm (A), but its
  generalizability to modern long-horizon agents is **actively disputed** — do not
  over-rely on it.

---

## 4. Refuted / killed counter-claims (for balance and falsification record)

These claims were extracted from the corpus and **failed** adversarial verification
(refuted by ≥2 of 3 skeptics). Recording them is part of honoring the
"actively seek disconfirmation" mandate — including disconfirmation of attractive
*supporting* claims.

| Refuted claim | Vote | Source |
|---|---|---|
| Drift's mechanism is pattern-matching susceptibility **rather than** error accumulation (i.e. the two are cleanly separable causes). | 0-3 | arXiv:2505.02709 |
| LLM errors compound **exponentially** with length ((1−ε)ⁿ / "LeCun" model). [Directly disconfirms a strong reading of arm (A).] | 0-3 | arXiv:2505.24187 |
| Errors concentrate at sparse "key tokens" (5–10% of tokens) = critical decision junctions; the rest are increasingly predictable. | 1-2 | arXiv:2505.24187 |
| Reliability decays **sub-exponentially** because key-token count grows sublinearly, explaining sustained long coherence. | 0-3 | arXiv:2505.24187 |
| Exposure bias empirically degrades generation quality (bare, unqualified form). | 0-3 | arXiv:2204.01171 |
| Accumulated regret is bounded between linear (T·ε) and quadratic (T²·ε). | 1-2 | arXiv:2204.01171 |
| Planning/sub-planning + memory + catastrophic forgetting **outweigh** history-error-accumulation as the leading mechanism. | 0-3 | arXiv:2604.11978 |

**Why this matters:** the field has **live, unresolved disagreement about the *shape*
of the degradation curve** — exponential vs near-quadratic vs sparse-key-token vs
sharp-cliff. No single shape survived as consensus. Any framework built on "errors
accumulate [in shape X]" is building on contested ground.

---

## 5. Conflicts surfaced (not resolved)

Per the brief, where sources conflict, the conflict is surfaced rather than papered
over:

1. **Shape of degradation.** *Near-quadratic accumulation* (2204.01171) vs *sharp
   non-linear cliff in compositional depth* (2604.11978) vs *sparse key-token / 
   sub-exponential* (2505.24187, itself partly refuted). These are not reconcilable
   from the available evidence.

2. **Is accumulation the leading mechanism?** 2509.09677 + 2602.19008 center
   self-conditioning / path-deviation; 2604.11978 emphasizes planning/memory and a
   structural shift — but its claim that those *outweigh* accumulation was refuted
   0-3. Unresolved which is primary in real runs.

3. **"Drift" is three different things.** The word denotes at least three distinct
   phenomena across sources: (a) the hypothesis's **semantic** drift (definition-of-
   done migration); (b) **goal-adherence** divergence under competing-objective
   pressure (2505.02709); (c) **stochastic canonical-path** deviation (2602.19008).
   They overlap but are not identical — cross-paper synthesis of "drift" must be read
   carefully.

---

## 6. Evidence-quality caveats (read before citing this report)

1. **Most directly-relevant agentic evidence is 2025–2026 arXiv preprints**, several
   not yet peer-reviewed (2602.19008 single-author/single-benchmark; 2604.11978
   self-describes as a pilot). The two highest-grade peer-reviewed anchors are older
   and *adjacent*: Lost-in-the-Middle (TACL 2024, retrieval/positional) and
   Exposure-Bias (ACL 2022, token generation) — neither is about multi-day agents.
   The strongest agentic source (2509.09677) is ICLR-2026-accepted.

2. **Benchmark-vs-real-world gap is the dominant caveat across nearly every
   finding.** The measured evidence comes from *synthetic/bounded benchmark
   trajectories* (key-retrieval running sums, Toolathlon tool-use, competing-objective
   trading sims, compositional sub-goal tasks) — **NOT** from agents literally running
   unsupervised for hours-to-days on one large coding task. Generalization to that
   regime is extrapolation that the papers themselves flag.

3. **No rigorous post-mortems of the named real-world runs** (AutoGPT, Devin,
   SWE-agent, MetaGPT, Voyager, the Bun Zig-to-Rust rewrite, AlphaEvolve) surfaced as
   *measured degradation curves*. Those remain **anecdote / vendor-claim grade (D)**
   and were **NOT used** to support any high-confidence finding. (Relevant context-only
   sources retrieved: METR time-horizon work
   [metr.org](https://metr.org/blog/2025-03-19-measuring-ai-ability-to-complete-long-tasks/);
   the answer.ai Devin field report
   [answer.ai](https://www.answer.ai/posts/2025-01-08-devin.html); SWE-bench
   [arXiv:2310.06770](https://arxiv.org/abs/2310.06770); AlphaEvolve
   [DeepMind](https://deepmind.google/discover/blog/alphaevolve-a-gemini-powered-coding-agent-for-designing-advanced-algorithms/);
   Voyager [arXiv:2305.16291](https://arxiv.org/abs/2305.16291); Anthropic
   reward-tampering and agentic-misalignment work.)

4. **Model-dependence.** Self-conditioning and goal drift are both strongly
   *attenuated* in frontier reasoning / well-scaffolded models — so any claim of a
   "dominant universal" failure mode is **regime-specific** and likely to shift as
   models improve.

5. **Terminology drift in the sources themselves** (see §5.3).

---

## 7. What remains genuinely unknown or unstudied

No source in the corpus closes these gaps. They are flagged honestly rather than
filled with speculation.

1. **Does self-conditioning / canonical-path compounding actually manifest in genuine
   multi-hour-to-multi-day autonomous coding runs**, or only in the bounded benchmark
   trajectories measured so far? **No study yet measures the degradation curve of a
   single agent on one large real task over that timescale.** This is the central
   empirical gap for the original question.

2. **What is the true dominant *shape* of long-horizon failure** — smooth
   accumulation, a sharp non-linear cliff, or a few sparse "key-token" decision
   junctions? The corpus contains live, unresolved disagreement (§4, §5.1).

3. **How much does scaffolding / harness design** (sub-agent decomposition, periodic
   re-grounding to spec, fresh-context handoffs, explicit verification gates)
   **actually suppress** self-conditioning and goal drift on long runs? Evidence shows
   strong models + thinking mitigate it, but the *marginal effect of specific harness
   interventions* is unquantified.

4. **Does the hypothesis's specific notion of "semantic drift"** — the working
   *definition* of done/quality/intent migrating across thousands of self-referential
   steps — **occur as a measurable phenomenon distinct from** goal-adherence drift and
   stochastic path deviation? **No source directly measures definition-of-done
   migration; it remains genuinely unstudied.**

---

## 8. Implications for the original question (stated conservatively)

For an agent running unsupervised for hours-to-days on one large task, the
best-supported expectation from the *currently measured* (mostly benchmark-scale)
evidence is:

- **Error accumulation via self-conditioning is real and a leading micro-driver** —
  and is *gradual and late-emerging*, not "doomed by step one" (F1, F3). Mitigation
  via reasoning/test-time compute and error-history hygiene is evidence-backed (F2).
- **Semantic/goal drift is a genuine secondary risk**, exposure-driven and
  model-dependent, strongly resisted by good agents/scaffolding (F8) — not the
  unambiguous dominant mode the hypothesis proposed.
- **Plan for multiple modes, not one:** positional long-context degradation (F4),
  goal misgeneralization (F5), reliability variance (F7), and a possible **sharp
  cliff** at high compositional depth (F6) are all independently evidenced.
- **The honest frontier:** whether any of this reproduces at true hours-to-days scale
  on real tasks is **unmeasured** (§7.1). Treat extrapolations accordingly.

---

## Appendix — Method statistics

| Metric | Value |
|---|---|
| Search angles | 6 |
| Sources fetched | 22 |
| Candidate claims extracted | 100 |
| Claims sent to adversarial verification | 25 |
| Confirmed (survived 3-vote refutation) | 18 |
| Killed (refuted ≥2/3) | 7 |
| Findings after semantic de-duplication | 9 |
| URL duplicates removed | 11 |
| Dropped to budget | 3 |
| Total agent calls | 105 |

Verification rule: each claim faced 3 independent skeptics prompted to *refute* it;
a claim survived only if it was *not* refuted by ≥2 of 3. The 7 killed claims are
listed in §4.

### Primary sources cited
- arXiv:2509.09677 — *The Illusion of Diminishing Returns* (ICLR 2026) — F1, F2
- arXiv:2602.19008 — *Capable but Unreliable: Canonical Path Deviation* (Feb 2026) — F3, F7
- arXiv:2307.03172 — *Lost in the Middle* (TACL 2024) — F4
- arXiv:2210.01790 / arXiv:2105.14111 — *Goal Misgeneralization* — F5
- arXiv:2604.11978 — *The Long-Horizon Task Mirage?* (Apr 2026) — F6
- arXiv:2505.02709 — *Measuring Goal Drift in LM Agents* (AIES 2026) — F8
- arXiv:2204.01171 — *Why Exposure Bias Matters* (Findings of ACL 2022) — F9
- arXiv:2505.24187 — *Beyond Exponential Decay* (2025) — contesting source (§4)
- arXiv:2502.05167 — *NoLiMa* — corroborating F4

### Context-only sources (grade D — not used for high-confidence findings)
- metr.org long-task-horizon blog · answer.ai Devin report · arXiv:2310.06770 (SWE-bench)
  · DeepMind AlphaEvolve blog · arXiv:2305.16291 (Voyager) · research.trychroma.com
  (Context Rot) · Anthropic reward-tampering & agentic-misalignment research ·
  tobyord.com "half-life"
