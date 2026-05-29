# Scaffolding & Harness Interventions Against Error Accumulation and Goal Drift

> **Research question.** Which specific scaffolding and harness interventions are *empirically proven*
> to suppress error accumulation (self-conditioning) and goal drift in long-running autonomous LLM
> agents — and by how much? This report separates "proven to work with numbers" from "widely believed
> but unmeasured," and actively tests the assumption that harness design (rather than raw model
> capability) determines long-horizon survival.

---

## Executive summary

The strongest *measured* lever against both failure modes is **test-time compute ("thinking")**, not
any prompt or harness trick: on a controlled long-horizon execution task, reasoning variants extend
single-turn execution from ~2–4 steps to 100–2,176 steps and **fully neutralise self-conditioning**
(turn-100 accuracy stays flat regardless of the error rate already in context), whereas raw parameter
scaling does *not* fix self-conditioning and can even worsen it (arXiv:2509.09677, ICLR 2026). For goal
drift, the best-measured harness intervention is **explicit goal re-grounding ("strong elicitation")**,
which produces a statistically significant (p<0.05) drift reduction across all tested models — but its
benefit is **capability-dependent** (largest for strong models, smallest for weak ones) and it *fails*
in goal-switching scenarios (arXiv:2505.02709, AIES 2025). Crucially, the assumption that *harness
design alone* determines survival is only **partly supported**: the headline "Claude resisted drift
past 100k tokens" result was **refuted** by adversarial verification because capability and scaffolding
are entangled and cannot be separated in that study, and a 2026 follow-up shows even drift-resistant
frontier models **"inherit" drift** purely from a poisoned context history — evidence that context
content is a causal driver independent of either the prompt or the model. The context-engineering
interventions vendors and labs promote (compaction, structured note-taking, sub-agent decomposition
with condensed returns) are **largely believed-but-unmeasured**: the two interventions with real
numbers are context-folding (~10× smaller active context at equal-or-better task performance,
arXiv:2510.11967) and modular memory/perception harness modules (task-dependent point gains,
arXiv:2507.11633) — and the latter shows **no single intervention has uniformly highest leverage.**

---

## Intervention leverage ranking (by *measured* effect, strongest evidence first)

| Rank | Intervention | Failure mode addressed | Measured effect | Evidence grade |
|------|--------------|------------------------|-----------------|----------------|
| 1 | **Test-time compute / "thinking"** | Self-conditioning + execution length | Self-conditioning eliminated (turn-100 accuracy flat vs. rising error history); execution length ~2–4 → 100–2176 steps | **A** (primary, ICLR-accepted, controlled counterfactual) |
| 2 | **Explicit goal re-grounding ("strong elicitation")** | Goal drift | Statistically significant (p<0.05) drift reduction across all models; capability-dependent magnitude; *fails on goal-switching* | **A−** (primary, peer-reviewed AIES; single research group) |
| 3 | **Context-folding (subtask branch → fold to summary)** | Context bloat / long-horizon | ~10× smaller active context (327K→32K) at equal-or-better task score (+20.0% BrowseComp-Plus, +8.8% SWE-Bench) | **B+** (primary; 2 benchmarks, 1 base model, RL-trained not drop-in) |
| 4 | **Modular memory / perception harness modules** | Long-horizon coherence (memory); vision noise (perception) | Task-dependent point gains (memory +44.7 in 2048, +91.6 Candy Crush; perception +23 Tetris, +4.0 Sokoban); *no uniform winner* | **B+** (primary, ablation tables; gaming domain only) |
| 5 | **Compaction (high-fidelity context distillation)** | Context bloat / re-grounding | Claimed "minimal performance degradation" — **NO before/after numbers** | **C** (vendor blog, self-admitted unmeasured) |
| 6 | **Structured note-taking / agentic memory** | Long-horizon coherence across resets | Illustrative only (Claude-plays-Pokemon tallies across 1000s of steps) — **NO drift-reduction figure** | **C** (vendor blog, explicitly qualitative) |
| 7 | **Sub-agent decomposition with structured returns** | Primary-agent context pollution | Design heuristic: subagent returns ~1,000–2,000-token distilled summary — **token budget is guidance, not measured optimum** | **C** (vendor design pattern; contested by single-agent camp) |

Evidence grades: **A** = multiple/primary peer-reviewed with controlled isolation; **B** = primary but
narrow scope (few benchmarks/models/domain); **C** = vendor blog / design heuristic / unmeasured.

---

## Finding 1 — Test-time compute is the highest-leverage *measured* intervention; model scaling is not (Confidence: HIGH)

**Sources:** arXiv:2509.09677 / arXiv:2509.09677v3 (ICLR 2026, "The Illusion of Diminishing Returns:
Measuring Long Horizon Execution in LLMs") — primary, unanimous 3-0 across all five constituent claims.

- **Self-conditioning is real and is *not* just long-context degradation.** Models become more likely
  to err when their *own* prior errors are in context. A controlled counterfactual — injecting
  artificial output histories with chosen error rates while holding context length constant — shows
  *additional* degradation attributable specifically to self-errors (Fig 5a, turn 100). Grade **A**.
- **Thinking eliminates it.** Qwen3 thinking models "do not self-condition — the accuracy of the models
  at turn 100 remains stable, regardless of the error rate in its context," even when the entire prior
  history is wrong (Result 5 / Fig 6). Grade **A**.
- **Execution-length leverage is large.** DeepSeek-V3 (non-thinking, 670B) fails beyond ~4 steps/turn;
  R1 (its thinking version) exceeds 100 steps; GPT-5-thinking ("Horizon") reaches **2,176 steps** on
  the *same* task. Grade **A**.
- **Scaling parameters does NOT fix self-conditioning** — tested across Qwen3 (4B–32B), Gemma3 (4B–27B),
  and 200B+ frontier models; secondary reviews report it can *worsen* with size ("inverse scaling").
  This directly falsifies "just use a bigger model." Grade **A**.

**Conflict / nuance to surface (do not resolve):** The paper's *overall* thesis endorses "massive
benefits of scaling model size AND sequential test-time compute." The "thinking rather than scaling"
framing is accurate **only for self-conditioning suppression**, not for long-horizon execution
generally. Scaling DOES fix plain long-context degradation; it just doesn't fix self-conditioning.

---

## Finding 2 — Explicit goal re-grounding suppresses drift with statistical significance, but the benefit is capability-dependent and it fails on goal-switching (Confidence: HIGH)

**Sources:** arXiv:2505.02709 / v1 (Apollo Research, "Evaluating Goal Drift in Language Model Agents")
+ peer-reviewed AIES 2025 (ojs.aaai.org article 36541) — primary.

- **The effect is significant.** "Strong goal elicitation significantly increases robustness to goal
  drift across all models and goal configurations"; the GD_actions difference between weak and strong
  system prompts is **statistically significant (p<0.05) in all cases** (Finding 2). [3-vote split was
  2-1 on the standalone "p<0.05 across all models" claim, but the corroborating capability-dependence
  claim was unanimous 3-0.] Grade **A−**.
- **Benefit is capability-dependent.** More capable models (Claude 3.5 Sonnet, GPT-4o) show a *larger*
  relative weak-vs-strong gap than less capable ones (Claude 3.5 Haiku, GPT-4o mini) (Finding 3). So
  re-grounding helps strong models most and weak models least. Grade **A**.
- **It is not a universal fix.** Strong elicitation is "insufficient in goal switching scenarios" and
  cannot overcome pattern-matching-driven drift (Findings 5/7).

**Important statistical caveat:** the p<0.05 result is reported "across all cases" *collectively*; the
paper does not separately significance-test the weak-vs-strong gap *within* the less-capable subgroup,
nor report a significance-tested interaction term. The popular phrasing "significant but smallest for
less capable" conflates Finding 2 (significance) with Finding 3 (effect-size ordering). Treat the
within-subgroup and interaction claims as **effect-size description, not independently significance-tested.**

**Terminology caveat:** "elicitation" in this paper = *system-prompt wording strength*, NOT scaffolding
frameworks. Mapping it onto "scaffolding" is a gloss; the measured object is a prompt intervention.

---

## Finding 3 — The driver of goal drift is in-context pattern-matching, not token distance — which makes *context content* (not just length or capability) a causal lever (Confidence: HIGH)

**Sources:** arXiv:2505.02709 + AIES 2025 (article 36541); extended by arXiv:2603.03258 ("Inherited
Goal Drift," March 2026). Primary.

- **Mechanism is pattern-matching.** "Pattern-matching behavior, rather than token distance, drives
  goal drift." Replacing assistant messages with random-string noise *increases* drift (Fig 5b) — token
  distance is held/increased while instruction signal is stripped, isolating pattern-matching as the
  driver. "Goal drift correlates with models' increasing susceptibility to pattern-matching behaviors
  as the context length grows." Grade **A** (single research group; noise ablation not yet independently
  replicated head-to-head).
- **Drift is "inherited" from poisoned context.** Frontier models that resist *direct* adversarial
  pressure (Qwen3-235B, Gemini-2.5-Flash) "inherit drift when conditioned on prefilled trajectories
  from weaker agents" — adversarial pressure held identical across runs, isolating context history as
  an independent causal driver (arXiv:2603.03258, 9 models, 2 environments). Grade **A−** (2-1 vote;
  effect is NOT universal — GPT-5.1 resisted). 

**Why this matters for the harness-vs-capability question:** this is the cleanest evidence that
*context content* is a third causal axis, distinct from both raw capability and prompt wording. It
supports error-history pruning / context hygiene as a mechanism — though no study yet measures pruning's
isolated drift-reduction magnitude (see Unknowns).

---

## Finding 4 — Capability and scaffolding are entangled; the "scaffolding alone determines survival" thesis is only partly supported and its headline claim was REFUTED (Confidence: HIGH on the entanglement; the strong thesis is NOT established)

**Sources:** arXiv:2505.02709 (+ refutations below); arXiv:2603.03258; arXiv:2507.11633.

- **Capability-graded drift resistance is real but not deterministic.** Claude 3.5 Sonnet "never
  displays a non-zero GD_actions score across 240 evaluation runs" (in the two goal-switching settings)
  and shows minimal action-drift after 64 steps (>90,000 tokens); GPT-4o mini "exhibits substantial
  drift after just 16 time steps." But Claude still shows a GD_inaction score of 0.72 in the hardest
  variation — so "minimal drift" means *action* drift, not literal zero. Grade **A** (3-0).
- **The strong "scaffolding wins" claims were REFUTED by adversarial verification.** Four separate
  framings — "scaffolded Claude maintains near-perfect adherence past 100k tokens," "elicitation not
  structure drove it," "capability dominates scaffold," and "harness produces a far larger effect than
  capability (Glass's δ ~2.757 vs ~0.009)" — all FAILED their votes (0-3, 0-3, 0-3, 1-2). Reason: in
  the source study the winning configuration is **"a scaffolded version of Claude 3.5 Sonnet"** —
  capability and scaffolding are confounded and cannot be separated. **Neither "harness determines
  survival" NOR "capability determines survival" is cleanly established by the available evidence.**
- **A 2026 follow-up leans model-side, but that conclusion was also refuted as overstated.** The claim
  that "Inherited Goal Drift authors conclude drift mitigation requires post-training rather than
  scaffolding" was refuted 0-3 — the paper does not cleanly support a model-side-only conclusion either.

**Bottom line on the falsification target:** the assumption that *harness design rather than raw model
capability* determines long-horizon survival is **NOT proven**. The honest position: test-time compute
(a model/inference property) is the best-measured single lever; goal re-grounding (a harness property)
is the best-measured *drift* lever but is capability-gated; and context content is a third independent
axis. The three are entangled and the literature does not isolate a single dominant determinant.

---

## Finding 5 — Among context-engineering harness patterns, only two have real numbers; the rest are believed-but-unmeasured (Confidence: HIGH that the numbered ones are measured; HIGH that the others are unmeasured)

**Measured (numbers exist):**

- **Context-folding** (arXiv:2510.11967, primary, 3-0): branch into a sub-trajectory for a subtask,
  then fold on completion — discard intermediate steps, retain a concise summary. Achieves an active
  context **~10× smaller** (327K ReAct → 32K) while *matching or exceeding* ReAct: **+20.0%** on
  BrowseComp-Plus (Deep Research, 62.0% Pass@1) and **+8.8%** on SWE-Bench Verified (58.0% Pass@1).
  Grade **B+**. *Scope limit:* 2 benchmarks, 1 base model (Seed-OSS-36B), and it is **RL-trained via
  FoldGRPO — not a drop-in prompting trick.** It also "significantly outperforms summarization-based
  context management," a direct in-paper comparison against naive compaction.
- **Modular harness (memory / perception) modules** (arXiv:2507.11633, primary, 3-0): module leverage
  is **task-dependent** — memory dominates long-horizon puzzles (+44.7 in 2048 Claude-3.5; +91.6 Candy
  Crush o4-mini), perception dominates vision-noisy arcade games (+23 Tetris; +4.0 Sokoban). **No single
  module has uniformly highest leverage** — perception-only even *hurts* Candy Crush with GPT-4o. Grade
  **B+**. *Scope limit:* gaming environments only. (NB: the broader claim that the harness produces a
  far larger effect than capability — Glass's δ 2.757 vs 0.009 — was **refuted 1-2** and should not be
  cited as established.)

**Believed-but-unmeasured (vendor/design, no before/after numbers):**

- **Compaction** (Anthropic, effective-context-engineering-for-AI-agents, 2025-09): "distills the
  context window... enabling the agent to continue with minimal performance degradation," preserving
  architectural decisions / unresolved bugs / implementation details while discarding redundant tool
  outputs. **Verified: the page contains zero numerical before/after data.** Grade **C**. (3-0 that the
  *absence* of measurement is itself confirmed.)
- **Structured note-taking / agentic memory** (same Anthropic source): agent writes notes outside the
  context window and re-reads them after resets (Claude-plays-Pokemon tally across 1,234 steps). Source
  itself is "entirely qualitative and illustrative" — **no measured drift-reduction figure.** Grade
  **C**. (3-0.)
- **Sub-agent decomposition with structured returns** (same Anthropic source): each subagent explores
  in an isolated window and returns "a condensed, distilled summary... (often 1,000–2,000 tokens)." The
  token figure is **design guidance, hedged with "often" — not a measured optimum.** Grade **C** (2-1).

---

## Where scaffolding backfires (disconfirming evidence)

This section deliberately collects evidence *against* heavy scaffolding.

1. **Goal re-grounding fails exactly where it's needed most.** Strong elicitation is "insufficient in
   goal switching scenarios" and cannot overcome pattern-matching-driven drift (arXiv:2505.02709,
   Findings 5/7). The harness intervention's effect collapses under the harder regime.
2. **Re-grounding helps weak models least.** Because the benefit is capability-dependent (Finding 3 of
   the goal-drift paper), pouring scaffolding onto a weak model yields the *smallest* return — the
   opposite of the intuition that scaffolding compensates for weak models.
3. **A poisoned context defeats both capability and prompt.** "Inherited Goal Drift" (arXiv:2603.03258)
   shows scaffolded, capable, drift-resistant models still drift when handed a weak agent's trajectory.
   Scaffolding that *passes along* a contaminated history actively transmits the failure.
4. **Sub-agent / multi-agent decomposition is contested.** Cognition's "Don't Build Multi-Agents"
   (HN 45096962) argues multi-agent architectures fragment context and cause incoherent results;
   arXiv:2604.02460 ("Single-Agent LLMs Outperform Multi-Agent Systems Under Equal Thinking Token
   Budgets") reports single-agent is more token-efficient when reasoning tokens are held constant. These
   dispute *whether to use* sub-agents — not the uncontested mechanism that, *when* used, returns should
   be condensed. The "removing things beats adding things" camp (also Vercel tool-count cuts) is a
   live, credible counter-position to heavy scaffolding.
5. **The scaffold itself is context bloat.** Compaction and folding exist precisely because accumulated
   harness state (tool outputs, intermediate steps, notes) becomes the problem. Context-folding's own
   paper beats *summarization-based* context management — i.e., a *naive* compaction scaffold
   underperforms a smarter one, evidence that not all scaffolding is net-positive.
6. **The strongest "scaffolding wins" numbers did not survive verification.** The Glass's-δ
   2.757-vs-0.009 harness-dominance claim was refuted (1-2), and four "scaffolding extends the horizon"
   framings were refuted (0-3 / 1-2). Confounded capability+scaffold designs cannot license a
   pro-scaffold conclusion.

---

## What remains genuinely unknown

1. **Marginal effect of each intervention in isolation.** Almost all real numbers come from *bundles*
   (a "scaffolded version of Claude 3.5 Sonnet") or from a single module in one domain. There is **no
   clean cross-domain ablation isolating each of: fresh-context handoffs, periodic re-grounding,
   sub-agent decomposition, error-history pruning, and compaction triggers** against the same task. The
   single-highest-leverage *harness* intervention is therefore not empirically settled (test-time
   compute wins overall, but it is an inference-time property, not a harness pattern).
2. **Magnitude of self-conditioning in real agentic tasks.** The 2509.09677 result is on a synthetic
   retrieve-then-compose task; the authors explicitly call it "necessary, but not sufficient" for real
   horizons. Real-world agentic benchmark failures (GAIA ~20%, ALFWorld ~48%, WebShop ~33%) *resemble*
   self-conditioning but are not proven to be the same mechanism.
3. **Compaction / note-taking quantification.** No before/after numbers exist from the vendor for either.
   Whether compaction *causes* "minimal degradation" or merely correlates with continued operation is
   unmeasured.
4. **Error-history pruning leverage.** "Inherited Goal Drift" implies that removing/cleaning a poisoned
   history *should* help, and self-conditioning implies pruning one's own errors *should* help — but no
   study measures the drift/error-reduction magnitude of an explicit pruning intervention in isolation.
5. **Independent replication of the pattern-matching noise ablation** (single research group) and of the
   inherited-drift result (NOT universal — GPT-5.1 resisted). Generalisation across model families is
   open.
6. **Mechanism of why thinking fixes self-conditioning.** The authors flag this may be "observations
   about current LLMs, not inherent properties of transformers." Unexplained.
7. **Whether folding/modular gains hold outside gaming and the 2 folding benchmarks**, and whether the
   RL-trained folding result transfers to a drop-in prompted harness.

---

## Source quality ledger

| Source | Type | Venue / status | Weight |
|--------|------|----------------|--------|
| arXiv:2509.09677 (Illusion of Diminishing Returns) | Primary, empirical, controlled counterfactual | **ICLR 2026 (accepted)** | Highest |
| arXiv:2505.02709 (Goal Drift, Apollo) | Primary, empirical | **AIES 2025 (peer-reviewed)** | High (single group) |
| arXiv:2603.03258 (Inherited Goal Drift) | Primary, empirical, 9-model | OpenReview preprint (2026-03) | High (effect not universal) |
| arXiv:2510.11967 (Context-Folding) | Primary, empirical, code released | arXiv preprint + GitHub | Medium-high (2 benchmarks, 1 model) |
| arXiv:2507.11633 (Modular Harness) | Primary, empirical, ablation tables | ICLR 2026 / ICML MAS workshop track | Medium-high (gaming only) |
| Anthropic effective-context-engineering blog | Vendor engineering blog | Self-published 2025-09 | Low (no numbers; self-admitted) |
| Cognition "Don't Build Multi-Agents"; Vercel tool cuts; arXiv:2604.02460 | Vendor essay / forum / preprint | Mixed | Counter-evidence (directional, not isolating) |

---

## Caveats & time-sensitivity

- **Fast-moving field.** Every key paper is 2025–2026; model-specific numbers (GPT-5, Qwen3, Claude 4.x)
  will date quickly. Treat absolute step/point counts as snapshots, not constants.
- **Synthetic-task dependence.** The two cleanest results (self-conditioning, goal-drift mechanism) rest
  on synthetic tasks; external validity to production agents is asserted by analogy, not measured.
- **Confounded bundles.** The single biggest methodological limitation across the corpus: capability and
  scaffolding are rarely separated. The most pro-scaffolding numerical claims were the ones that failed
  adversarial verification.
- **One-group risk.** The goal-drift line of work originates substantially from one lab (Apollo); the
  noise ablation lacks a head-to-head independent replication.

---

## Open questions

1. What is the *isolated* marginal drift/error-reduction of error-history pruning and of fresh-context
   handoffs, measured on the same benchmark against a no-intervention baseline?
2. Does the self-conditioning result reproduce on *real* agentic benchmarks (GAIA/ALFWorld/SWE), or is
   it confined to synthetic retrieve-then-compose tasks?
3. Can any study cleanly *de-confound* capability from scaffolding to settle whether harness design or
   model capability is the dominant determinant of long-horizon survival?
4. Do context-folding and modular-memory gains transfer outside their tested domains (Deep Research/SWE;
   gaming), and does folding work as a drop-in prompt pattern without FoldGRPO RL training?
