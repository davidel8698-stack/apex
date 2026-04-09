# APEX v7 — Design Rationale Reference

This file documents WHY each design decision was made. It is NOT loaded into agent context.
Reference the research round (R1-R8) for full evidence.

## Context Architecture
- Design for 100-160K working set within 200K limit (R2: coding degrades severely at 70%+)
- Observation masking > LLM summarization (R2: JetBrains study, 50% cost, equal quality)
- Primacy-recency ordering: critical instructions first, task last (R2: U-shaped attention curve)
- CLAUDE.md <200 lines for 92% rule application (R2, R6)
- Prompt caching: stable prefix first, volatile last → 90% input cost reduction (R7)
- Orchestrator must stay lean: 72% of tokens go to coordination in MetaGPT (R3)
- Fresh context per worker, thin orchestrator (R2: Anthropic multi-agent 90.2% improvement)

## Verification
- Clean-room: never let critic see executor reasoning (R3: 88.2% adversarial success with framing)
- Clean-room + debiasing → 93.75% detection (R2, R3, R4)
- Simple verification prompts outperform complex by 20-40pp (R3)
- Reflexion briefs intentionally simple — complex analysis causes 20-40pp overcorrection (R3)
- TDAD reduces regressions 70%: 6.08% → 1.82% (R4)
- Mutation testing: 93% line coverage → only 59% mutation kill rate (R4)
- 3 verification layers catch ~95% of bugs at ~60% cost of 5 layers (R7)

## Agent Architecture
- 3 focused agents >> 7 chatty ones: AgentCoder 96.3% HumanEval (R3)
- Beyond ~4 agents, returns go negative (R3: DeepMind 180-config study)
- Structured artifacts crush free-text: 87% token reduction (R3)
- More communication usually makes things worse: CooperBench 30% lower success (R3)

## Autonomy & Human Collaboration
- Generation-then-comprehension achieves 86% comprehension (R5)
- AI delegation patterns score <40% comprehension (R5)
- METR RCT: experienced devs 19% slower with AI, 43-point perception gap (R5)
- Per-verify-level autonomy: D=always ask, C=cap level 1, A/B=can reach level 2 (R5)

## Learning & Memory
- Cross-project learning: 5-22% improvement with quality-controlled memory (R6)
- Performance peaks at 40-60 heuristics then degrades (R6: ERL)
- Compact summaries (204 words) >> full trajectories (24,765 words) (R6: SWE-ContextBench)
- Failure-derived knowledge +14.3% more valuable than success-derived (R6)
- Memory poisoning: >95% injection success with MINJA (R6)

## Cost
- Productive code is only 1-9% of total tokens (R7: Tokenomics MSR 2026)
- Sonnet = 98% of Opus at 1/5 cost on SWE-bench (R7)
- Failed trajectories cost 4x+ tokens — hard cap at 3 retries (R7)
- Target: <5% framework overhead achievable (R7)

## AI Code Quality
- 1.7x more defects, 2.74x more security vulns, 8x more I/O issues (R4: CodeRabbit)
- AI tests cheat: hard-coded returns, self-mocking, vacuous assertions (R1, R4)
- Naive TDD prompting increases regressions from 6.08% to 9.94% (R4: TDAD paper)

## v8 Changes (research-validated only)
- Security persona for D-level critic: <1% → 93.7% vuln detection (R4: persona swing study)
- Haiku routing for A-level tasks: ~90% quality at 1/3 cost (R7: model comparison)
- confidence + attempt_number in RESULT.json: enables routing decisions (R3: typed artifacts)
- Type-specific decay for learnings: safety=∞, framework=3mo, project=30d (R6: knowledge half-lives)