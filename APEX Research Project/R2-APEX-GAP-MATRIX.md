# R2-APEX Gap Matrix — Claim × APEX Status Cross-Reference

> **Phase-3 artifact** of R2↔APEX gap analysis.
> **Method:** Each of 235 claims from `R2-CLAIMS-INDEX.md` mapped to APEX state from `R2-APEX-INVENTORY.md`.
> **Status legend:** `✅ ALIGNED` | `⚠️ PARTIAL` | `❌ MISSING` | `🚨 THEATRE` (declared but no implementation) | `↪ CONTRADICTED` | `— N/A` (META: gap/disagreement/source — non-actionable)
> **Severity:** `P0` (highest-leverage R2 gap, addresses §9 missing piece) | `P1` (HIGH-confidence ARCH gap) | `P2` (improvement) | `P3` (nice-to-have / emerging)
> **Effort:** `S` (<2h, config edit) | `M` (<1d, hook/schema) | `L` (<1w, agent/subsystem) | `XL` (project-scale)
> **Leverage score:** higher = better fix-target. Formula: P0=4/P1=3/P2=2/P3=1 × 1/effort{S=4,M=2,L=1,XL=0.5}.

---

## §1 Headline Findings (R2-C001 — R2-C007)

| ID | Summary | Status | Evidence | Sev | Eff | Lev | Prior | Notes |
|---|---|---|---|---|---|---|---|---|
| C001 | Context degradation universal physics | ✅ | apex-design-notes.md:7 | — | — | — | R2 | Acknowledged design constraint |
| C002 | Effective capacity 10-30% theoretical | ⚠️ | CONTEXT_BUDGET.default.json:50 capacity=200K, target 55%=110K | P1 | M | 6 | R7 | Architect cap 40K/200K=20% exceeds R2's 10-15% orchestrator ceiling |
| C003 | Observation masking > LLM summarization | 🚨 | apex-design-notes.md:8 declares; zero impl (Agent B audit) | **P0** | M | **8** | declared R2 | Highest-leverage gap |
| C004 | Fresh subagent context, orchestrator drift unsolved | ✅ | architect.md, executor.md fresh-context Task() | — | — | — | R3, R5 | Already implemented |
| C005 | Retrieval architecture > model choice | ⚠️ | TASK_MAP plan-driven, not Aider-graph | P2 | L | 2 | R6 P2-3 | Phase-2/3 per R6 |
| C006 | Verification must be isolated | ✅ | critic.md:2-3, RESULT.schema.json:5 | — | — | — | R3, R4 | Solved |
| C007 | Context engineering = discipline w/ 4 strategies | ✅ | Whole APEX framework alignment | — | — | — | All rounds | Foundational |

---

## §2 Physics of Context (R2-C008 — R2-C047)

| ID | Summary | Status | Evidence | Sev | Eff | Lev | Prior | Notes |
|---|---|---|---|---|---|---|---|---|
| C008 | U-shaped attention 30%+ middle drop | ✅ | apex-design-notes.md:9 primacy-recency | — | — | — | R2 | Honored in prompt ordering |
| C009 | U-shape geometric inevitability | — | Theory finding | — | — | — | — | N/A — cannot fix at app level |
| C010 | U-shape persists <50% fill only | — | Single-source MED | — | — | — | — | N/A — uncertain finding |
| C011 | Attention sinks emerge 1K-2K steps | — | Model-level | — | — | — | — | N/A |
| C012 | Causal masking → log primacy divergence | — | Theory | — | — | — | — | N/A |
| C013 | Claude conservative abstention | ✅ | Behavioral; affects critic UNVERIFIED handling | — | — | — | — | Honored implicitly |
| C014 | GPT confident hallucination | — | Cross-model concern, not APEX | — | — | — | — | N/A |
| C015 | Gemini wild errors | — | Cross-model | — | — | — | — | N/A |
| C016 | No frontier-model coding comparison | — | META gap | — | — | — | — | N/A |
| C017 | LongCodeBench 29%→3% Claude 3.5 | ✅ | apex-design-notes.md:7 (drives 100-160K target) | — | — | — | R2 | Already drives design |
| C018 | LONGCODEU drops at 32K | ✅ | Same driver | — | — | — | R2 | |
| C019 | HumanEval -50% at 30K | ✅ | Same | — | — | — | R2 | |
| C020 | Self-conditioning: errors compound | ⚠️ | Reflexion 3-cap (executor.md) but no rotation on degradation | P2 | M | 4 | R3 | Could feed quality-signal trigger |
| C021 | Mitigation set: primacy/recency/XML/<50% | ✅ | next.md:404, ordering convention | — | — | — | R2 | Convention only — no automated check |
| C022 | Opus 4.6 MRCR 76-78% at 1M | — | MEAS source | — | — | — | — | N/A |
| C023 | GPT-5.4 MRCR | — | MEAS source | — | — | — | — | N/A |
| C024 | Gemini 2.5 Pro 16% at 1M | — | MEAS source | — | — | — | — | N/A |
| C025 | "256K effective" is heuristic | ✅ | apex-design-notes.md:7 100-160K target | — | — | — | R2 | |
| C026 | Task-type degradation hierarchy | ❌ | No task-adaptive profiles in CONTEXT_BUDGET | P1 | M | 6 | None | R2 §9 missing piece #5 |
| C027 | Multi-hop reasoning at 5-10% window | — | MED single-source | — | — | — | — | N/A |
| C028 | Inter-unit code reasoning fails first | ⚠️ | TDAD addresses but inter-file context still bulky | P2 | L | 2 | R4 (TDAD) | TDAD reduces regressions 70% |
| C029 | ~2% loss per 100K tokens | — | MED rule of thumb | — | — | — | — | N/A |
| C030 | Compaction-survival: paths/decisions/JSON | ✅ | DECISIONS.md, RESULT.json patterns | — | — | — | R6 | |
| C031 | Compaction loss: snippets/CoT/traces | ✅ | Acknowledged design (next.md:404) | — | — | — | R6 | |
| C032 | Observation masking 50%+ cost cut | 🚨 | (See C003) | **P0** | M | **8** | declared R2 | Theatre |
| C033 | LLM summarization runs 15% longer | ⚠️ | APEX uses /compact (LLM summary) by default | P1 | M | 6 | None | Same root as C003 |
| C034 | Extractive +7.89 F1 | ⚠️ | No extractive compression in APEX | P2 | M | 4 | None | Coupled with C032 fix |
| C035 | Abstractive -4.69 F1 | — | Anti-pattern reference | — | — | — | — | N/A — informs choice of C034 |
| C036 | OpenHands condenser ~2× per turn | — | Reference impl | — | — | — | — | N/A |
| C037 | Compact at 50-60% not 80-95% | ⚠️ | Configured 55% but unreachable (counter dead) | **P0** | S | **16** | declared R2 | Trivial once token-counter fixed |
| C038 | Use /compact w/ explicit preservation | ⚠️ | Claude's /compact lacks preservation hints in invocation | P2 | S | 8 | None | Add prompt to /compact wrapper |
| C039 | DECISIONS.md survives compaction | ✅ | Architectural — re-read from disk | — | — | — | All | |
| C040 | Re-read files from disk after compact | ✅ | critic.md:12, executor.md:91-93 explicit | — | — | — | All | |
| C041 | Morph prevention-first 80-90% waste | — | Single-source MED | — | — | — | — | N/A |
| C042 | Fresh + state files > compaction | ✅ | /apex:resume design | — | — | — | R6 | |
| C043 | Sublinear scaling power-law | — | META | — | — | — | — | N/A |
| C044 | 100K = 10B pairwise softmax | — | META | — | — | — | — | N/A |
| C045 | 32K→256K HURTS coding | ✅ | Drives 100-160K target | — | — | — | R2 | |
| C046 | 1M→10M won't help coding | — | META | — | — | — | — | N/A |
| C047 | Infinite-context architectures 1-3y out | — | EMRG | — | — | — | — | N/A — out of scope |

---

## §3 Techniques That Work (R2-C048 — R2-C100)

| ID | Summary | Status | Evidence | Sev | Eff | Lev | Prior | Notes |
|---|---|---|---|---|---|---|---|---|
| C048 | Token usage = 80% perf variance | 🚨 | tokens.total_input never written | **P0** | M | **8** | None | Unlocks all metrics |
| C049 | TALE 68.9% cost cut <5% accuracy | — | Reference framework | — | — | — | — | N/A directly |
| C050 | APEX CONTEXT_BUDGET novel | ✅ | R2 explicit endorsement | — | — | — | R7 | |
| C051 | Orchestrator 10-15%, fresh workers | ⚠️ | Architect at 20% (40K) | P1 | S | 12 | R3, R7 | Lower architect.max_input to 30K |
| C052 | Aider 1-4K repo map | ✅ | TASK_MAP 1-4K target match | — | — | — | R6 | |
| C053 | SWE-Agent last-5 sliding window | — | Reference | — | — | — | — | N/A |
| C054 | Manus KV-cache primary metric | ⚠️ | No cache hit rate tracking | P2 | S | 8 | None | Coupled with prompt-caching impl |
| C055 | Synthesized 200K budget breakdown | ✅ | CONTEXT_BUDGET.default.json:4-25 matches | — | — | — | R7 | Zone sizes fit R2 ranges |
| C056 | Reserve 20-40% for generation | ✅ | generation_reserve 60K = 30% | — | — | — | R7 | |
| C057 | Disagreement on rotation aggressiveness | — | META disagreement | — | — | — | — | N/A — resolution applied below |
| C058 | Orchestrator 10-15% MAX | ⚠️ | (See C051) | P1 | S | 12 | None | Same root |
| C059 | XML tags for Claude prompts | ✅ | Agent prompts use XML-style tags (next.md:411-417 implicit) | — | — | — | All | |
| C060 | XML > JSON for coding | ⚠️ | RESULT.json is JSON; agent inputs are XML-like | P3 | — | — | None | Hybrid is correct (machine vs prompt) |
| C061 | Format consistency > syntax | ✅ | Schema-enforced consistency | — | — | — | R3 | |
| C062 | Output format restrictions hurt reasoning | — | Anti-pattern reference | — | — | — | — | N/A |
| C063 | Structure > LLM choice for determinism | — | MED | — | — | — | — | N/A |
| C064 | Ordering: system→project→middle→evidence→task | ✅ | next.md:411-417, primacy-recency | — | — | — | R2 | |
| C065 | Aider repo map = gold standard | ⚠️ | TASK_MAP plan-driven, not graph | P2 | L | 2 | R6 P2-3 | Acknowledged backlog |
| C066 | tree-sitter+PageRank+signatures+1-4K | ⚠️ | Token-budget ✓, but no AST/PageRank | P2 | L | 2 | R6 P2-3 | |
| C067 | Aider 4.3-6.5% utilization vs Cursor 14.7% | — | MEAS reference | — | — | — | — | N/A |
| C068 | Code-specialized embeddings > general | — | Reference; no vector in APEX | — | — | — | — | N/A — vector deferred |
| C069 | MiniLM 80.1% MRR | — | Reference | — | — | — | — | N/A |
| C070 | GrepRAG matches semantic | ⚠️ | Grep tool exists, no orchestrated GrepRAG | P3 | M | 1.5 | None | Low priority |
| C071 | SemanticForge 73% precision | — | Reference | — | — | — | — | N/A |
| C072 | Hybrid: repo-map + grep + optional vector | ⚠️ | Repo-map ✓, grep ✓, no vector | P3 | L | 1 | R6 | Tier-3 deferred |
| C073 | CodeRAG-Bench +27.4% w/ docs 200-800 token chunks | — | Reference | — | — | — | — | N/A |
| C074 | Vector DB primary = anti-pattern | ✅ | APEX avoids vector primary; SQLite mirror is opt-in | — | — | — | R6 | |
| C075 | 4-tier memory T1-T4 | ⚠️ | T1-T3 done; T4 SQLite opt-in | P2 | L | 2 | R6 §3.4 | Roadmap to enable SQLite default |
| C076 | CLAUDE.md <200 lines = 92% rule | ✅ | apex-design-notes.md:10; next.md:409 slice | — | — | — | R6 | |
| C077 | CLAUDE.md -40% manual corrections | — | MEAS reference | — | — | — | — | N/A |
| C078 | CLAUDE.md survives compaction | ✅ | Re-read from disk | — | — | — | R6 | |
| C079 | Letta filesystem-native > specialized | ✅ | Architectural alignment | — | — | — | R6 | |
| C080 | Letta git-worktree memory | ⚠️ | `/apex:new-workspace` uses worktrees but for code, not memory | P3 | L | 1 | R5-024 (workspace) | Full Letta-style requires more |
| C081 | No automated staleness detection | ⚠️ | verify-learnings detect-only, no auto-archive | P1 | M | 6 | R6 | Add hash-invalidation |
| C082 | MINJA >95% injection success | ⚠️ | Smaller surface but no full defense | P1 | M | 6 | R6 §5 | |
| C083 | Microsoft 50 real-world attempts | — | Threat data | — | — | — | — | N/A |
| C084 | OWASP top agentic risk 2026 | — | Threat ranking | — | — | — | — | N/A |
| C085 | Agent defends the poison | ⚠️ | No anomaly check on memory writes | P2 | M | 4 | None | Coupled with C082 |
| C086 | Required: provenance+decay+backups+audit | ⚠️ | Decay ✓; provenance/backups/audit partial | P1 | M | 6 | R6 | Cluster of memory-integrity items |
| C087 | +113K conv history -30% accuracy | ✅ | Drives fresh-context design | — | — | — | R3 | |
| C088 | Laban: 39% multi-turn degradation | ✅ | Drives rotation policy | — | — | — | R2 | |
| C089 | ~20-30 messages quality horizon | ✅ | Implicit via rotation triggers | — | — | — | R2 | |
| C090 | Fresh + state > compacted long session | ✅ | /apex:resume design | — | — | — | R6 | |
| C091 | Multi-trigger rotation (composite) | ⚠️ | Only utilization-proxy + manual phase + memory; no quality-signal/recovery-density auto-rotate | P1 | M | 6 | None | Wire `rotation_triggers[]` array consumer |
| C092 | Prompt caching 90% cost / 85% latency | 🚨 | Zero `cache_control` in framework | **P0** | M | **8** | declared R2/R7 (apex-design-notes.md:11) | Theatre |
| C093 | Stable prefix near-zero cost after 1st call | 🚨 | Same root as C092 | **P0** | M | **8** | declared | |
| C094 | LLMLingua-2 2-5× compression | — | Reference; risky for code | — | — | — | — | N/A |
| C095 | 500xCompressor not for code | — | Anti-pattern reference | — | — | — | — | N/A |
| C096 | EHPC research-stage | — | EMRG | — | — | — | — | N/A |
| C097 | Anthropic prompt caching production | 🚨 | (See C092) | **P0** | M | **8** | None | Same root |
| C098 | Token-efficient tool use 14% reduction | ❌ | Not enabled in any agent prompt | P2 | S | 8 | None | Add to settings.json |
| C099 | Anthropic context editing 84% reduction | ❌ | `grep "context.editing" framework/` = 0 | P1 | M | 6 | None | Sep 2025 feature, post-R7 |
| C100 | AGENTS.md anti-pattern 20% cost increase | ✅ | apex-design-notes.md:10 enforces <200 lines | — | — | — | R6 | |

---

## §4 Multi-Agent Context Architecture (R2-C101 — R2-C126)

| ID | Summary | Status | Evidence | Sev | Eff | Lev | Prior | Notes |
|---|---|---|---|---|---|---|---|---|
| C101 | Coordinator+Workers wins | ✅ | architect→executor→critic pattern | — | — | — | R3 | |
| C102 | Hierarchical good for very large | — | Reference | — | — | — | — | N/A |
| C103 | Peer-to-peer worst | ✅ | APEX avoids | — | — | — | R3 | |
| C104 | Blackboard not for code | ✅ | APEX avoids | — | — | — | R3 | |
| C105 | Event-sourced (OpenHands) good | — | Reference | — | — | — | — | N/A |
| C106 | Coordinator+Fresh-Workers for APEX | ✅ | Already the pattern | — | — | — | R3 | R2 explicit endorsement |
| C107 | Opus-lead+Sonnet-workers +90.2% | ⚠️ | No model differentiation in agents | P2 | M | 4 | None | Could route critic→Opus, executor→Sonnet |
| C108 | Multi-agent 80% vs 40% single-agent coding | ✅ | APEX is multi-agent | — | — | — | R3 | |
| C109 | MyAntFarm 100% vs 1.7% | — | Reference | — | — | — | — | N/A |
| C110 | Multi-agent costs 3-15× | ⚠️ | True; mitigated via prompt caching (when wired) | P1 | M | 6 | R7 (cost cap target) | Coupled with C092 |
| C111 | Downstream packet: minimal typed | ✅ | architect spawns executor with task_xml | — | — | — | R3 | |
| C112 | Upstream JSON result | ✅ | RESULT.schema.json closed | — | — | — | R3 (improvement #33) | |
| C113 | Workers write artifacts to disk | ✅ | Code/SUMMARY/RESULT all on disk | — | — | — | R3 | |
| C114 | Filesystem+Git for state, msgs for coord | ✅ | Pattern enforced | — | — | — | R3, R5 | |
| C115 | SWE-Adept dedicated git branch | ⚠️ | `/apex:new-workspace` worktrees + pre-task-snapshot | P3 | — | — | R5-024 | Already addressed |
| C116 | Letta context repos via worktrees | — | Reference | — | — | — | — | N/A |
| C117 | Code never in-context state | ✅ | Re-read from disk | — | — | — | R3 | |
| C118 | 88.2% adversarial PR-metadata bias | ✅ | Drives clean-room policy | — | — | — | R3 | |
| C119 | Redacting PR desc recovers 68.75% | ✅ | critic doesn't see SUMMARY | — | — | — | R3 | |
| C120 | Debiasing instructions → 93.75-94% | ✅ | critic.md:18-22 four explicit clauses | — | — | — | R3, R4 | |
| C121 | Adversarial review 72%→45% overconfident | ✅ | Anti-fraud rule critic.md:24-30 | — | — | — | R4 | |
| C122 | Reasoning doesn't reduce bias | ✅ | Single-pass critic doesn't reflect-then-rate | — | — | — | R4 | |
| C123 | Pass 1 clean-room contract | ✅ | critic.md:9-13, RESULT.schema.json:5 | — | — | — | R3, R4 | |
| C124 | Pass 2 conditional reveal | ❌ | Single-pass only | P2 | M | 4 | None | Likely OK; add later if disagreement-rate high |
| C125 | Different model/temp for verification | ❌ | All agents same model | P1 | S | 12 | None | Trivial: route critic→different model in apex-model-routing.json |
| C126 | Google ADK narrative casting | — | Technique reference | — | — | — | — | N/A |

---

## §5 Applied Patterns for Coding Tasks (R2-C127 — R2-C149)

| ID | Summary | Status | Evidence | Sev | Eff | Lev | Prior | Notes |
|---|---|---|---|---|---|---|---|---|
| C127 | Coding-context required-set sizes | ⚠️ | One-size-fits-all budget | P1 | M | 6 | None | Per-task profile (C138) |
| C128 | Conditional context sets | ⚠️ | Same | P1 | M | 6 | None | |
| C129 | Aider: irrelevant files distract | ✅ | TASK_MAP plan-driven (only declared files) | — | — | — | R6 | |
| C130 | SWE-Pruner 23-38% reduction IMPROVED | ⚠️ | No active pruning | P2 | M | 4 | None | Coupled with task-adaptive |
| C131 | CodeScout 21→6 steps via pre-exploration | ❌ | Architect plans tasks, not pre-explores context | P2 | M | 4 | None | Could enhance Step 0 of architect |
| C132 | New-code profile | ❌ | No profile | **P1** | M | 6 | None | R2 §9 missing piece #5 |
| C133 | Bug-fixing profile | ❌ | No profile | **P1** | M | 6 | None | Same root |
| C134 | Code-review profile (withhold reasoning) | ✅ | critic.md clean-room is exactly this | — | — | — | R3, R4 | |
| C135 | Refactoring profile | ❌ | No profile | P1 | M | 6 | None | |
| C136 | Test-writing profile | ❌ | No profile | P1 | M | 6 | None | |
| C137 | Frontend profile | ⚠️ | apex-frontend module exists with shadcn-gate | P2 | M | 4 | R5 | Module covers some but not budget profile |
| C138 | Encode task-adaptive profiles in CONTEXT_BUDGET | ❌ | Single budget; no profile selector | **P1** | M | **6** | None | R2 §9 missing piece #5 — cluster head |
| C139 | Persist across sessions | ✅ | DECISIONS, STATE, learnings | — | — | — | All | |
| C140 | Always refresh from source | ✅ | Re-read from disk policy | — | — | — | All | |
| C141 | Stale-reference major failure mode | ✅ | Re-read enforced | — | — | — | R6 | |
| C142 | Stale-ref solutions: hash invalidate, hook regen | ⚠️ | No memory-entry hash invalidation | P1 | M | 6 | R6 | (See C081/C086) |
| C143 | Git Context Controller 48% SWE-bench Lite | — | EMRG single-source | — | — | — | — | N/A |
| C144 | LangGraph MemorySaver | — | Reference | — | — | — | — | N/A |
| C145 | SWE-ContextBench experience reuse | — | EMRG | — | — | — | — | N/A |
| C146 | TiCoder +45.73% pass@1 | ❌ | TDD conditional, not generation-feedback loop | P2 | L | 2 | R4 partial | Future enhancement |
| C147 | AgentCoder test-designer agent | ⚠️ | auditor agent ≈ test-quality | P3 | L | 1 | R5 (auditor) | Different role but adjacent |
| C148 | CodeRabbit incremental reviews | ✅ | Diff-based critic (improvement #25) | — | — | — | R3 | |
| C149 | Semi-formal reasoning 78%→93% | — | Technique reference | — | — | — | — | N/A — already strong (debiasing) |

---

## §6 Emerging Approaches (R2-C150 — R2-C167)

| ID | Summary | Status | Evidence | Sev | Eff | Lev | Prior | Notes |
|---|---|---|---|---|---|---|---|---|
| C150 | Karpathy: LLM=CPU, ctx=RAM | — | META framing | — | — | — | — | N/A |
| C151 | Lütke: most important skill | — | META | — | — | — | — | N/A |
| C152 | Anthropic Sep 2025 definition | — | META | — | — | — | — | N/A |
| C153 | ACE evolving playbooks +10.6% | — | EMRG | — | — | — | — | N/A |
| C154 | IBM Zurich cognitive tools | — | Reference | — | — | — | — | N/A |
| C155 | Prompt caching production-ready NOW | 🚨 | (See C092) | **P0** | M | **8** | declared | Same root |
| C156 | Anthropic context editing Sep 2025 | ❌ | (See C099) | P1 | M | 6 | None | |
| C157 | Sigmoid gating Qwen | — | Model-level EMRG | — | — | — | — | N/A |
| C158 | LaMPE positional encoding | — | Model-level EMRG | — | — | — | — | N/A |
| C159 | Ring Attention 1-3y out | — | EMRG | — | — | — | — | N/A |
| C160 | Infini-attention reproduction issues | — | EMRG | — | — | — | — | N/A |
| C161 | StreamingLLM doesn't extend understanding | — | EMRG | — | — | — | — | N/A |
| C162 | Models self-assess via tools | ✅ | Agents have Read/Glob/Grep | — | — | — | R3 | |
| C163 | CodeRAG log-prob chunks | — | EMRG | — | — | — | — | N/A |
| C164 | Aider dynamic repo-map size | ⚠️ | Static 1-4K | P3 | M | 1.5 | None | Low priority |
| C165 | APEX should pre-plan context fetches | ⚠️ | Architect plans tasks but not pre-explores context | P2 | M | 4 | None | Could enhance architect Step 0 |
| C166 | Available benchmarks (composite) | — | MEAS reference | — | — | — | — | N/A — informs C167 |
| C167 | APEX metrics list (composite) | 🚨 | Token counter dead → metrics dashboard impossible | **P0** | M | **8** | None | Cluster head — Context Health Dashboard |

---

## §7 Anti-Patterns and Failure Modes (R2-C168 — R2-C187)

| ID | Summary | Status | Evidence | Sev | Eff | Lev | Prior | Notes |
|---|---|---|---|---|---|---|---|---|
| C168 | CRITICAL: context stuffing | ✅ | Per-zone budgets, per-agent caps | — | — | — | R7 | |
| C169 | HIGH: LLM self-summarization default | ↪ **CONTRADICTED** | APEX defaults to /compact (LLM summary) | **P0** | M | **8** | declared R2 | (See C003) — APEX uses the anti-pattern |
| C170 | HIGH: monolithic CLAUDE.md +20% cost | ✅ | <200 lines enforced | — | — | — | R6 | |
| C171 | HIGH: NIAH optimism | ✅ | Phantom-check, ast-kb-check | — | — | — | R3, R4 | |
| C172 | MED-HIGH: prose-only summarization loses provenance | ⚠️ | RESULT.json structured but reflexion is prose | P2 | S | 8 | R3 | Mostly addressed |
| C173 | MED-HIGH: ignoring context rot | 🚨 | Token counter dead → no rot detection | **P0** | M | **8** | None | (See C167) |
| C174 | MED: over-compaction | ⚠️ | Compacts at 55% (good); but LLM summary loses nuance | P2 | S | 8 | None | Coupled with C003 |
| C175 | Orchestrator bottleneck (>256K) | ⚠️ | Architect cap 40K=20% over R2 ceiling | P1 | S | 12 | None | (See C051) |
| C176 | Verification contamination | ✅ | critic clean-room | — | — | — | R3 | |
| C177 | Too much shared context | ✅ | Per-agent caps | — | — | — | R7 | |
| C178 | Too little shared context | ⚠️ | Risk on bug-fix where dependency chain matters | P2 | M | 4 | R4 (TDAD) | TDAD addresses this |
| C179 | Trajectory elongation (smoothed summaries) | ↪ | Same root as C169 | **P0** | M | **8** | declared | |
| C180 | Free-text agent comms | ✅ | Typed JSON via RESULT.schema | — | — | — | R3 | |
| C181 | Coordination plateau >4 agents | ✅ | Core stack 4 agents | — | — | — | R3 | |
| C182 | Error compounding 90.4% | ✅ | Reflexion 3-cap, circuit-breaker | — | — | — | R3 | |
| C183 | MAST 41-86% failure rates | — | MEAS reference | — | — | — | — | N/A — informs design |
| C184 | State desynchronization | ✅ | schema-drift hook, validate-state | — | — | — | R5 | |
| C185 | Memory poisoning persistence | ⚠️ | (See C082) | P1 | M | 6 | R6 | |
| C186 | Stale embeddings | — | No embeddings in APEX | — | — | — | — | N/A |
| C187 | Multiple-writer race conditions | ✅ | One-file-one-owner (owner-guard.sh) | — | — | — | R5-013 | |

---

## §8 Architectural Recommendations (R2-C188 — R2-C214)

| ID | Summary | Status | Evidence | Sev | Eff | Lev | Prior | Notes |
|---|---|---|---|---|---|---|---|---|
| C188 | Hard 50-60% per phase | ⚠️ | Configured but unreachable (counter dead) | **P0** | S | **16** | declared | Trivial after C048/C167 |
| C189 | Z1 Stable Prefix 5-10K cached | ⚠️ | Z1 = 30K (over R2's range), no cache | P1 | M | 6 | None | Reduce stable_prefix budget; add cache_control |
| C190 | Z2 Task Context 30-60K JIT | ✅ | task_context = 50K | — | — | — | R7 | |
| C191 | Z3 Working Memory masked | 🚨 | (See C003) | **P0** | M | **8** | declared | |
| C192 | Z4 Generation Reserve 30-50K | ✅ | generation_reserve = 60K | — | — | — | R7 | Slightly above range, fine |
| C193 | Target 100-120K = 50-60% | ⚠️ | Configured but unreachable | **P0** | S | **16** | declared | Same root C188 |
| C194 | Orchestrator 10-15% MAX | ⚠️ | Architect 20% (40K) | P1 | S | 12 | None | Reduce architect.max_input |
| C195 | XML-style tags ordering | ✅ | next.md prompt structure | — | — | — | All | |
| C196 | Always-in-context list | ✅ | stable_prefix zone matches | — | — | — | R7 | |
| C197 | On-demand-only list | ✅ | Read tools available | — | — | — | All | |
| C198 | Multi-agent flow chart | ✅ | architect→executor→critic | — | — | — | R3 | |
| C199 | Worker→Orchestrator typed result | ✅ | RESULT.schema (stronger than R2 baseline) | — | — | — | R3, R5 | |
| C200 | Isolation guarantees | ✅ | All listed isolation rules in place | — | — | — | R3, R4 | |
| C201 | State flow filesystem→typed→.apex/ | ✅ | Whole architecture | — | — | — | All | |
| C202 | Proactive rotation triggers (composite) | ⚠️ | (See C091) | P1 | M | 6 | None | |
| C203 | State-preservation pre-rotation | ⚠️ | Fragmented across 3 hooks | P1 | M | 6 | R5/R7 | Add `pre-rotation-snapshot.sh` |
| C204 | State-restoration post-rotation | ⚠️ | ~60% compliant; missing repo-map regen | P2 | S | 8 | R5 | Easy: add `generate-task-map.sh` to /apex:resume |
| C205 | Verification INCLUDED list | ✅ | critic.md:9-13 | — | — | — | R3 | |
| C206 | Verification EXCLUDED list | ✅ | critic.md:15-16 | — | — | — | R3 | |
| C207 | Two-pass verification | ❌ | (See C124) | P2 | M | 4 | None | |
| C208 | Verification enhancements: parallel personas, test-driven | ⚠️ | Personas for planning only; TDD partial | P2 | L | 2 | R3, R4 | Future |
| C209 | 3-tier memory T1+T2+T3 | ✅ | All three implemented | — | — | — | R6 | |
| C210 | Files+Git+SQLite, NOT vector primary | ✅ | Architecture aligned | — | — | — | R6 | |
| C211 | Memory integrity: provenance+decay+backups+audit | ⚠️ | (See C086) | P1 | M | 6 | R6 partial | Cluster head |
| C212 | Context Health Dashboard 8 metrics | 🚨 | Dependent on token counter (dead) | **P0** | M | **8** | None | Cluster head |
| C213 | User-facing indicators (gauge, timestamps) | ❌ | /apex:status doesn't render context-fill gauge | P1 | S | 12 | None | Add to /apex:status |
| C214 | Task#50 quality = Task#1 (ultimate metric) | ❌ | No quality-over-time metric | P1 | M | 6 | None | New metric in STATE.json.tokens.quality_by_task |

---

## §9 Limitations and §10 Conclusion (R2-C215 — R2-C235)

| ID | Summary | Status | Evidence | Sev | Eff | Lev | Prior | Notes |
|---|---|---|---|---|---|---|---|---|
| C215-222 | 8 META gaps in research | — | All META | — | — | — | — | N/A |
| C223-227 | 5 META disagreements | — | All META (resolved in inventory) | — | — | — | — | N/A |
| C228 | APEX architecture aligned w/ SOTA | ✅ | R2 explicit endorsement | — | — | — | All | |
| **C229** | **MISSING #1: Observability** | 🚨 | Token counter dead | **P0** | M | **8** | None | (Cluster: C048, C167, C212, C213, C214) |
| **C230** | **MISSING #2: Proactive rotation @50-60%** | ⚠️ | Configured, unreachable | **P0** | S | **16** | declared | (Cluster: C037, C188, C193) — easy after C229 |
| **C231** | **MISSING #3: Observation masking** | 🚨 | Theatre | **P0** | M | **8** | declared | (Cluster: C003, C032, C169, C179, C191) |
| **C232** | **MISSING #4: Clean-room verification** | ✅ | Solved | — | — | — | R3, R4 | The one R2 §9 piece APEX nailed |
| **C233** | **MISSING #5: Task-adaptive loading** | ❌ | One budget for all | **P1** | M | **6** | None | (Cluster: C026, C127, C128, C132-138) |
| **C234** | **MISSING #6: Memory integrity** | ⚠️ | Decay ✓, others partial | **P1** | M | **6** | R6 partial | (Cluster: C081, C086, C211) |
| C235 | "Less, better-chosen, beats more, naively-stuffed" | ✅ | Whole APEX philosophy | — | — | — | All | |

---

## Summary Statistics

### Status distribution (out of 235)

| Status | Count | % |
|---|---|---|
| ✅ ALIGNED | 64 | 27% |
| ⚠️ PARTIAL | 51 | 22% |
| ❌ MISSING | 22 | 9% |
| 🚨 THEATRE | 14 | 6% |
| ↪ CONTRADICTED | 2 | 1% |
| — N/A (META/source/EMRG) | 82 | 35% |

### Actionable items (status ≠ ALIGNED, ≠ N/A) by severity

| Sev | Count | Top examples |
|---|---|---|
| **P0** | 14 | C003, C032, C037, C048, C092, C093, C097, C155, C167, C169, C173, C179, C188, C191, C193, C212, C229, C230, C231 (overlapping clusters) |
| P1 | 22 | C002, C026, C051, C081, C082, C086, C091, C099, C110, C125, C127, C128, C132-138, C175, C194, C202, C203, C211, C213, C214, C233, C234 |
| P2 | 24 | C005, C020, C028, C034, C038, C054, C065, C066, C070, C075, C107, C124, C130, C131, C137, C146, C165, C172, C178, C204, C207, C208 |
| P3 | 5 | C060, C080, C147, C164 |

### Top-leverage targets (Lev ≥ 8, deduplicated by cluster)

| Cluster | Component IDs | Leverage | Effort | Notes |
|---|---|---|---|---|
| **R-OBS — Observation Masking impl** | C003, C032, C169, C179, C191, C231 | **8** | M | Highest single R2-cited gain (50% cost cut) |
| **R-TKN — Real Token Counter** | C048, C167, C173, C212, C229 | **8** | M | Unlocks dashboard + thresholds |
| **R-CACHE — Prompt Caching annotations** | C092, C093, C097, C155 | **8** | M | 90% cost / 85% latency |
| **R-THRESH — Activate 50-60% rotation** | C037, C188, C193, C230 | **16** | S | Trivial after R-TKN; dependent |
| **R-TASK-PROFILES — Per-task-type budgets** | C026, C127, C128, C132-138, C233 | **6** | M | R2 §9 missing #5 |
| **R-MEM-INTEG — Memory integrity hardening** | C081, C086, C211, C234 | **6** | M | R2 §9 missing #6 |
| **R-ORCH-CAP — Architect cap to 30K** | C051, C058, C175, C194 | **12** | S | Trivial single-edit |
| **R-MODEL-DIV — Model diversity for verification** | C107, C125 | **12** | S | Single edit in apex-model-routing.json |
| **R-DASHBOARD — User-facing context gauge** | C213 | **12** | S | Quick win — extends /apex:status |
| **R-CTX-EDIT — Anthropic context editing API** | C099, C156 | **6** | M | Sep 2025 feature; post-R7 |
| **R-AIDER — AST repo map** | C005, C065, C066 | **2** | L | R6 P2-3 already acknowledged |

### Cross-check: prior rounds

- **Already addressed (no new recommendation):** ~62 claims (clean-room critic, debiasing, TDAD, phase tagging, structured artifacts, etc.) — credited in `prior_round_addressed`.
- **Declared but not implemented (gap between intent and code):** 18 claims — the highest-priority cluster (theatre items).
- **Novel R2 findings not in any prior round:** ~25 claims — task-adaptive profiles, model diversity, two-pass verification, context editing API, ultimate quality metric.

**Phase 3 status:** ✅ Complete (235/235 mapped).
**Next:** Phase 4 — synthesize 10-15 prioritized recommendations from the 11 high-leverage clusters.
