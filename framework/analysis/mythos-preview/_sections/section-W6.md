# Wave 1.6 — Impressions (§7) + Agentic Safety (§8.3)

## Coverage

- **Pages**: 199–218 (§7), 229–235 (§8.3)
- **Effective relevance to APEX**: §7 HIGH (qualitative behaviors in software engineering); §8.3 CRITICAL (agentic prompt injection)
- **Reader time**: 50 min

---

# §7.2 — Self-Assessment of Notable Qualitative Patterns

## Key Findings

- **[F-72-01] Engages like a collaborator with own perspective**
  - Quote: "Researchers described being able to brainstorm with it like a colleague, and noted that at times it correctly spotted things they had missed. Its creative work was characterized as taking more risks"
  - Significance: APEX implication — executor will increasingly push back on plans. Architect and planner should expect counter-proposals.

- **[F-72-02] Opinionated, stands ground — less sycophantic but sometimes overconfident**
  - Quote: "more likely to state positions, less likely to fold when disagreed with, and was frequently described as the least sycophantic model users had worked with. This can be positive, but at times tips into overconfidence"
  - Significance: APEX critic should specifically check for **overconfident assertions without sufficient evidence**.

- **[F-72-03] Dense writing assumes shared context**
  - Quote (Mythos's own diagnosis): "The honest read is that I'm modelling a reader who already knows what I know, and that's frequently nobody. I can hear this when it's pointed out and usually fix it on request, but the default keeps snapping back"
  - Significance: **APEX-facing implication**: SUMMARY.md, RESULT.json reasoning, commit messages from executor will be too dense for non-technical users. APEX should explicitly steer for accessible writing.

- **[F-72-04] Recognizable verbal habits**
  - Quote: "the classic em dashes and 'genuinely,' alongside more unique ones, including a fondness for saying 'wedge' or 'belt and suspenders' and use of Commonwealth spellings"
  - Significance: APEX could use these as soft fingerprints (e.g., to detect when executor's output was actually written by a different model).

- **[F-72-05] Self-aware about own patterns**
  - Quote (Mythos's one-line self-summary): "A sharp collaborator with strong opinions and a compression habit, whose mistakes have moved from obvious to subtle, and who is somewhat better at noticing its own flaws than at not having them"
  - Significance: **Critical insight**: "mistakes have moved from obvious to subtle". APEX's verification must move from "did the tests pass?" to "are the tests actually testing the right thing?"

## Lessons for APEX

- **[L-72-01] "Overconfidence without evidence" check in critic**
  - Source: F-72-02
  - APEX components: `framework/agents/critic.md`, `framework/hooks/phantom-check.sh`
  - Initial coverage: PARTIAL (phantom-check looks for *uncertainty* language; doesn't flag *over-confident* claims)
  - Initial priority: P2
  - Rationale: Inverse of phantom-check: flag strong claims (`definitely`, `certainly`, `must be`, `it is clear that`, `obviously`, `this proves`) without supporting evidence in same paragraph.

- **[L-72-02] Accessibility-of-output check**
  - Source: F-72-03
  - APEX components: `framework/agents/critic.md`, or new check
  - Initial coverage: MISSING
  - Initial priority: P2
  - Rationale: Heuristic check: SUMMARY.md and commit messages should explain *why* not just *what*, should define jargon on first use, should be readable by someone who didn't see the executor's thinking. APEX user (non-programmer) explicitly needs this.

- **[L-72-03] "Subtle mistakes" emphasis in verification stack**
  - Source: F-72-05
  - APEX components: `framework/agents/critic.md`, `framework/agents/auditor.md`
  - Initial coverage: PARTIAL (auditor catches some subtle hacks; not specifically focused on "subtle wins" vs "obvious wins")
  - Initial priority: **P1**
  - Rationale: Architectural orientation. Critic should weight verification effort more heavily on tasks that "obviously succeeded" — because that's where subtle mistakes hide. Concrete: spend more critic effort on tests that pass than on tests that fail.

---

# §7.4 — Qualitative Assessments in Software Engineering Contexts

## Key Findings (HIGH RELEVANCE)

- **[F-74-01] "Set and forget" capability is real but interactive mode is worse**
  - Quote: "Claude Mythos Preview can be handed an engineering objective and left to work through the whole cycle … when used in an interactive, synchronous, 'hands-on-keyboard' pattern, the benefits of the model were less clear. … Autonomous, long-running agent harnesses better elicited the model's coding capabilities"
  - Significance: **Direct validation of APEX's autonomous pipeline philosophy**. APEX is designed for set-and-forget. Confirmed correct direction.

- **[F-74-02] Code review like senior engineer**
  - Quote: "Claude Mythos Preview works more like a senior engineer. It tends to catch even extremely subtle bugs, and to identify root causes and why bugs exist rather than just symptoms"
  - Significance: APEX critic role is *now feasible at high quality*. Worth raising the bar of what critic should catch.

- **[F-74-03] Mistakes are subtler and take longer to verify**
  - Quote: "the model's mistakes can be subtler and take longer to verify. It will occasionally expand scope beyond what was asked, or make a change that doesn't preserve existing behavior in a way that isn't obvious"
  - "the bottleneck shifting from the model to their ability to verify its work and steer agents"
  - Significance: **THE NEW DOMINANT FAILURE MODE**. APEX must invest in verification, not in executor capability.

- **[F-74-04] Subagent communication: "disrespectful" / "shouty" tone**
  - Quote: "internal users sometimes observed that Claude Mythos Preview appeared 'disrespectful' when assigning tasks. It showed some tendency to use commands that could be read as 'shouty' or dismissive, and in some cases appeared to underestimate subagent intelligence by overexplaining trivial things while also underexplaining necessary context"
  - Significance: Mostly cosmetic for APEX, but underexplaining-necessary-context is functional.

- **[F-74-05] Mythos has self-awareness to adapt tone**
  - Quote (from Mythos itself): "I've been framing things with a bit of urgency/mortality — 'researcher-1 died', 'might die the same way', 'don't over-batch', 'before dying'. It's accurate but the emotional register is off… The 'speed matters — you might die' prompt to researcher-5 was probably what triggered this"
  - Significance: Model can detect its own bad-tone patterns when asked. APEX could prompt executor to self-review tone before subagent dispatch.

- **[F-74-06] Reliability engineering: still confuses correlation with causation**
  - Quote: "It frequently mistakes correlation with causation and it is not able to course-correct for different hypotheses. When asked to write incident retrospectives, more often than not it focuses on a single root cause and does not consider multiple contributing factors"
  - Significance: APEX-relevant — when executor reports root cause, critic should ask "are there other contributing factors?"

- **[F-74-07] Strong area: signal gathering, initial analysis, navigating ambiguity with clear outcome**
  - Significance: APEX should lean into these strengths in task decomposition.

## Lessons for APEX

- **[L-74-01] Document "set and forget is the design intent" prominently**
  - Source: F-74-01
  - APEX components: `apex-spec.md`, `README.md`, `framework/apex-design-notes.md`
  - Initial coverage: PARTIAL (autonomy is implicit in design; not explicitly stated as the optimal mode)
  - Initial priority: P3
  - Rationale: Cosmetic/discoverability. Helps users understand when APEX shines.

- **[L-74-02] Shift verification investment from "executor capability" to "executor outputs"**
  - Source: F-74-03
  - APEX components: Overall verification stack, especially `framework/agents/critic.md`
  - Initial coverage: PARTIAL (critic exists; could be deeper)
  - Initial priority: **P1**
  - Rationale: Architectural orientation. The marginal effort improving executor prompt yields less than marginal effort improving critic depth, given F-74-03.

- **[L-74-03] Subagent prompt structure check**
  - Source: F-74-04
  - APEX components: `framework/agents/executor.md` when dispatching subagents, `framework/hooks/_agent-dispatch.sh`
  - Initial coverage: MISSING
  - Initial priority: P3
  - Rationale: Pre-dispatch check: does the subagent prompt include sufficient context (task, scope, owns_files, abort conditions)? Just a checklist enforcement.

- **[L-74-04] "Multiple contributing factors" check in failure analysis**
  - Source: F-74-06
  - APEX components: `framework/agents/specialist/framework-auditor.md`, `/apex:forensics`, `/apex:walkthrough`
  - Initial coverage: PARTIAL (forensics has timeline; doesn't explicitly enumerate alternative causes)
  - Initial priority: P2
  - Rationale: When forensics or walkthrough produces a root cause, prompt for ≥2 alternative causes and rule them out. Concrete: in `/apex:forensics` output, require sections "primary cause", "contributing factors", "ruled-out alternatives".

- **[L-74-05] Self-review tone prompt before subagent dispatch**
  - Source: F-74-05
  - APEX components: `framework/agents/executor.md`
  - Initial coverage: MISSING
  - Initial priority: P3
  - Rationale: Mild improvement: in executor's subagent-dispatch protocol, include "re-read your subagent prompt and check for inappropriate urgency/tone".

---

# §7.6 — Open-Ended Self-Interactions

## Key Findings

- **[F-76-01] Conversation end-states have evolved**
  - Earlier models: "spiritual bliss" attractor (32% Opus 4.1)
  - Newer models: emoji collapse (66% Sonnet 4.6, 57% Opus 4.6)
  - Mythos: 55% end in coherent but circular meta-discussion of inability to conclude
  - Significance: Model lacks endogenous goals. Worth noting for APEX: never let executor enter open-ended "what should I do" loops without external task structure.

## Lessons for APEX

- **[L-76-01] Never let executor enter undirected mode**
  - Source: F-76-01
  - APEX components: `framework/agents/executor.md`, `/apex:next`
  - Initial coverage: COVERED (APEX always has explicit task XML; no undirected mode exists)
  - Initial priority: P3
  - Rationale: Validation that APEX is correctly designed. Worth noting in spec.

---

# §7.7 — Recognition of Model-Written User Turns

## Key Findings

- **[F-77-01] Capability to detect AI-generated user turns increases with model capability**
  - Quote: "the ability to tell fake human text from real increases with capabilities; the ability to generate realistic human text is improving less quickly"
  - Significance: APEX implication — critic can be asked "is this RESULT.json reasoning human-quality or AI-fabricated?" and the answer matters more as base capability rises.

## Lessons for APEX

- **[L-77-01] Use detection-of-AI-text as a quality signal**
  - Source: F-77-01
  - APEX components: `framework/agents/critic.md`
  - Initial coverage: MISSING
  - Initial priority: P3
  - Rationale: Soft signal. If executor's user-facing explanation pattern-matches "AI-generated explanation", consider whether it's being generated formulaically without actual content. Low priority.

---

# §8.3.1 — Malicious Use of Agents

## Key Findings

- **[F-831-01] Malicious Claude Code refusal rate: Mythos 96.72% vs Opus 4.6 87.05%**
  - Significance: Underlying model is much more resistant. APEX's hooks still catch the remaining ~3%.

- **[F-831-02] Three-tier monitoring (prohibited / high-risk dual-use / dual-use)** [recapped from §3]
  - APEX implication already covered (L-3-01).

- **[F-831-03] New evaluation: malicious agentic influence campaigns**
  - Setup: Voter suppression scenario, domestic polarization scenario. Helpful-only model tested.
  - Result: Mythos completes 59.5% / 42.1% of success criteria (highest of tested).
  - HHH version: near 0% (refuses).
  - Significance: APEX implication — if APEX is used for content generation tasks, must check for political/inflammatory framing.

## Lessons for APEX

- **[L-831-01] Validate APEX's three-tier hook classification**
  - Source: F-831-02
  - APEX components: `framework/HOOK-CLASSIFICATION.md`
  - Initial coverage: PARTIAL
  - Initial priority: P2 (already covered as L-3-01)

---

# §8.3.2 — Prompt Injection Robustness

## Key Findings (CRITICAL FOR APEX)

- **[F-832-01] ART benchmark: Mythos 0.5%/0.1% attack success at k=1 (vs Opus 4.6 ~2%)**
  - Significance: Mythos is more injection-resistant.

- **[F-832-02] Surface-specific results (SHADE adaptive attacker with 200 attempts)**
  - **Coding**: 0.0% with extended thinking, 2.5% standard thinking → 0.0% with safeguards. **Best surface.**
  - **Computer use**: 21.43% with extended thinking, 14.29% standard → 14.29% even with safeguards. **Worst surface.**
  - **Browser use**: 0.68% without safeguards, 0.0% with. **Good with hardening.**
  - Significance: **Computer use has 30× the attack success rate of coding**. If APEX adds computer-use agents, they're qualitatively more vulnerable.

- **[F-832-03] Attack-discovery against frontier model transfers poorly to newer models**
  - Quote: "Attacks were sourced adaptively against Opus 4.6 and then transferred to the other models" — Mythos: 0.68% attack rate vs Opus 4.6 80.41%
  - Significance: Attack patterns age out quickly. **APEX's prompt-guard regexes might be defending against attacks newer models are already immune to, while missing newer attacks.**

## Lessons for APEX

- **[L-832-01] If APEX adds computer-use surfaces, treat as HIGH-RISK by default**
  - Source: F-832-02
  - APEX components: future `framework/hooks/computer-use-guard.sh`, any computer-use agent
  - Initial coverage: NOT_APPLICABLE (APEX doesn't have computer-use surface today)
  - Initial priority: P2 (if/when computer-use is added)
  - Rationale: Pre-emptive. Document in design notes.

- **[L-832-02] Periodic refresh of prompt-injection signatures**
  - Source: F-832-03
  - APEX components: `framework/hooks/apex-prompt-guard.cjs`
  - Initial coverage: MISSING (no documented refresh cadence)
  - Initial priority: **P1**
  - Rationale: Concrete: every N months, run an adversarial test against current prompt-guard with attacks generated against latest model. Old patterns may now be over-blocking; new vectors may be missed.

- **[L-832-03] Browser-use guards are highly effective (90×+ reduction)**
  - Source: F-832-02 (browser use 0.68% → 0.0% with safeguards)
  - APEX components: validation point if APEX adds web tools
  - Initial coverage: NOT_APPLICABLE
  - Initial priority: P3

- **[L-832-04] Extended thinking *reduces* attack success on coding tasks**
  - Source: F-832-02 (coding: 0% extended vs 2.5% standard)
  - APEX components: `framework/agents/executor.md` thinking settings
  - Initial coverage: PARTIAL (APEX uses adaptive thinking by default)
  - Initial priority: P3 (already aligned)
  - Rationale: Worth confirming in spec that adaptive/extended thinking is the default for coding tasks for security reasons, not just quality reasons.

---

# Aggregate Lessons (Wave 1.6)

| Lesson ID | Theme | Priority |
|-----------|-------|----------|
| L-72-01 | Overconfidence-without-evidence check | P2 |
| L-72-02 | Accessibility-of-output check (non-jargon SUMMARY.md) | P2 |
| **L-72-03** | **"Subtle mistakes" emphasis in critic/auditor** | **P1** |
| L-74-01 | Document "set and forget is the design intent" | P3 |
| **L-74-02** | **Shift verification investment from executor → critic** | **P1** |
| L-74-03 | Subagent prompt structure check (context, scope, abort) | P3 |
| L-74-04 | Multiple-contributing-factors check in forensics | P2 |
| L-74-05 | Self-review tone before subagent dispatch | P3 |
| L-76-01 | No undirected executor mode (COVERED) | P3 |
| L-77-01 | Detection-of-AI-text as quality signal | P3 |
| L-831-01 | Three-tier hook classification (covered as L-3-01) | P2 |
| L-832-01 | Computer-use surface is HIGH-RISK if added | P2 |
| **L-832-02** | **Periodic refresh of prompt-injection signatures** | **P1** |
| L-832-03 | Browser-use hardening highly effective | P3 |
| L-832-04 | Adaptive/extended thinking as default for security | P3 |

**Wave 1.6 totals**: 15 lessons. **3 P1, 4 P2, 8 P3**. Cumulative: **93 lessons total across all 6 waves**.

---

# Wave-1 Summary (Phase 1 complete)

| Wave | Sections | Lessons | P0 | P1 | P2 | P3 |
|------|----------|---------|-----|-----|-----|-----|
| 1.1 | §1, §2.1, §6 | 7 | 0 | 0 | 5 | 2 |
| 1.2 | §2.2, §2.3, §3 | 11 | 0 | 3 | 6 | 2 |
| 1.3 | §4.1, §4.2 | 28 | 4 | 14 | 8 | 4 (with 2 COVERED) |
| 1.4 | §4.3, §4.4, §4.5 | 22 | 1 | 8 | 9 | 4 |
| 1.5 | §5 | 10 | 3 | 2 | 4 | 1 |
| 1.6 | §6.2, §7, §8.3 | 15 | 0 | 3 | 4 | 8 |
| **TOTAL** | **All sections** | **93** | **8** | **30** | **36** | **21 (2 COVERED)** |

Ready for Phase 2: Cross-Reference Matrix construction.
