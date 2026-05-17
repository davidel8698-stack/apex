# R2 Claims Index — Atomic Findings from Round 2 Research

> **Source:** `Apex research round 2 - Context Engineering - State of the Art.txt` (986 lines, 5-model synthesis, March 2026)
> **Purpose:** Phase-1 artifact of R2↔APEX gap analysis. Each row = one atomic claim with confidence label, source, quantification, and APEX-relevance category.
> **Confidence levels:** `HIGH` = unanimous or 4+/5 models converge | `MED` = 2-3 models converge or quantitatively-supported single source | `LOW` = single model, flagged in R2 for verification
> **Relevance categories:** `ARCH` (architecture/structure) | `MEAS` (measurement/observability) | `PROC` (procedure/workflow) | `ANTI` (anti-pattern to avoid) | `EMRG` (emerging, watch) | `META` (gap/limitation)

---

## §1 Executive Summary — The 7 Headline Findings

### R2-C001 — Context degradation is universal physics, not a bug
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH
- **Quant:** 13.9-85% degradation from positional distance even with perfect retrieval (Du et al. EMNLP 2025); LongCodeBench: Claude 3.5 Sonnet collapses 29% → 3% accuracy at 32K → 256K
- **Source:** Chroma 2025 (18 frontier models), Du et al. EMNLP 2025, Chowdhury et al. March 2026 (geometric-inevitability theorem)
- **Implication (R2):** Context is finite, depreciating — every token must earn its place
- **Cross-ref:** R2-C015 (U-curve), R2-C027 (coding degradation), R2-C081 (anti-stuffing)

### R2-C002 — Effective capacity is 10-30% of theoretical, coding at the lower end
- **Conf:** HIGH (principle) / MED (numbers) | **Models:** 5/5
- **Quant:** BABILong: 10-20% effective utilization at millions of tokens; Claude Code community reports degradation starting at ~20% of 1M window; Paulsen Jan 2026: >99% shortfall on certain tasks
- **Source:** BABILong NeurIPS 2024, MRCR v2 cross-provider data, Paulsen Jan 2026, Claude Code Issue #35296
- **Implication (R2):** Design for ~100-160K working set per orchestrator, not 256K
- **Relevance:** ARCH

### R2-C003 — Observation masking beats LLM summarization for coding agents
- **Conf:** HIGH | **Models:** 4/5 | **Relevance:** ARCH+PROC
- **Quant:** Observation masking matches or +2.6% vs summarization at 50%+ token cost reduction with zero compute cost; LLM summarization runs ~15% LONGER (smoothed summaries hide failure patterns); Factory.ai: extractive +7.89 F1, abstractive -4.69 F1
- **Source:** JetBrains "Complexity Trap" NeurIPS DL4C 2025, Factory.ai
- **Implication (R2):** Default to observation masking; reserve LLM summarization for phase-boundary transitions only

### R2-C004 — Fresh context per subagent is correct; orchestrator drift is the unsolved problem
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH
- **Quant:** Opus 4 lead + Sonnet 4 workers = 90.2% improvement vs single Opus 4; LangChain subagent pattern = 67% fewer tokens; Chroma: full 113K conversation history drops accuracy ~30% vs focused 300-token version
- **Source:** Anthropic multi-agent research, LangChain measurements, Chroma study
- **Implication (R2):** Rotate orchestrator context aggressively; keep orchestrator at 10-15% context usage

### R2-C005 — Context retrieval architecture matters more than model choice
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH
- **Quant:** Augment Code SWE-bench Pro: 6-point spread from retrieval strategy alone; Anthropic BrowseComp: token usage explains 80% of performance variance; multi-agent Claude code = 80% success vs 40% single-agent; IBM Zurich cognitive tools: GPT-4.1 AIME 26.7% → 43.3% via context engineering only
- **Source:** Augment Code, Anthropic BrowseComp, IBM Zurich
- **Implication (R2):** Invest engineering effort in context architecture, not model upgrades

### R2-C006 — Verification agents must be architecturally isolated
- **Conf:** HIGH (principle) / MED-HIGH (numbers) | **Models:** 5/5 | **Relevance:** ARCH
- **Quant:** 88.2% adversarial PR-metadata bias success; redacting PR description recovers 68.75% of missed detections; debiasing instructions raise to 93.75-94%; adversarial code review pattern drops overconfident failure 72% → 45%; reasoning does NOT reduce bias (BMJ 2026 — sometimes amplifies)
- **Source:** 2026 study on PR-metadata adversarial framing, BMJ Digital Health 2026
- **Implication (R2):** APEX verification must be clean-room with no access to implementer reasoning

### R2-C007 — Context engineering is now a recognized discipline, converging on 4 strategies
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** META+ARCH
- **Quant:** Mei et al. survey July 2025 = 165 pages, 1,400+ papers; LangChain 4 strategies: **Write (save externally), Select (retrieve relevant), Compress (retain essential), Isolate (partition across agents)**
- **Source:** Karpathy June 2025, Lütke 2025, Anthropic Sep 2025, LangChain 2025, Mei et al. 2025
- **Implication (R2):** APEX should be built as a context engineering framework; every design decision evaluated through "how does this affect what the LLM sees?"

---

## §2 Physics of Context

### §2.A1 — Attention and Positional Bias

### R2-C008 — U-shaped primacy-recency attention curve with 30%+ middle drop
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH
- **Source:** Liu et al. TACL 2024 ("Lost in the Middle")

### R2-C009 — U-shape is a geometric property of causal masking, not a learned artifact
- **Conf:** HIGH | **Models:** 3,4,5 | **Relevance:** ARCH+META
- **Source:** Chowdhury et al. March 2026 (theory paper)
- **Implication:** Cannot be trained-out at application level

### R2-C010 — U-shape persists only below ~50% context fill; above it, recency dominates
- **Conf:** MED (single source, needs verification) | **Models:** 5 only | **Relevance:** ARCH
- **Source:** Veseli et al. 2025
- **Note:** If confirmed, attention-management strategy should shift as context fills

### R2-C011 — Attention sinks emerge during 1K-2K pre-training steps
- **Conf:** HIGH | **Models:** 2,5 | **Relevance:** META
- **Source:** ICLR 2025 Spotlight

### R2-C012 — Causal masking creates logarithmic primacy divergence
- **Conf:** HIGH | **Models:** 4,5 | **Relevance:** META
- **Source:** Chowdhury et al. 2026

### R2-C013 — Claude models abstain conservatively under confusion (refuses at 2.89% rate)
- **Conf:** HIGH | **Models:** 1,4,5 | **Relevance:** ARCH
- **Source:** Chroma 2025

### R2-C014 — GPT models confidently hallucinate (2.55% hallucination rate under distractors)
- **Conf:** HIGH | **Models:** 4,5 | **Relevance:** ARCH

### R2-C015 — Gemini errors early with wild variations under long context
- **Conf:** MED | **Models:** 1,5 | **Relevance:** ARCH

### R2-C016 — No apples-to-apples positional-bias comparison exists for current frontier coding tasks
- **Conf:** HIGH (gap) | **Models:** 4/5 note this | **Relevance:** META

### R2-C017 — LongCodeBench: Claude 3.5 Sonnet 29% → 3% accuracy at 32K → 256K
- **Conf:** HIGH | **Models:** 2,5 | **Relevance:** ARCH+ANTI
- **Source:** LongCodeBench

### R2-C018 — LONGCODEU: performance drops dramatically beyond 32K for inter-unit reasoning
- **Conf:** HIGH | **Models:** 2 | **Relevance:** ARCH

### R2-C019 — HumanEval drops 50% at 30K tokens on Llama-3 even with zero distractors
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ARCH
- **Source:** Du et al. EMNLP 2025

### R2-C020 — Self-conditioning effect: past errors raise future error probability; scaling doesn't fix
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ARCH+ANTI
- **Implication:** Once degraded, session won't recover via context — must rotate

### R2-C021 — Mitigation set: place critical at start (primacy), task at end (recency), XML tags for middle, rerank to edges, keep <50% utilization
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH+PROC

### §2.A2 — Effective vs Theoretical Context Capacity

### R2-C022 — Claude Opus 4.6 MRCR: ~93% at 256K, 76-78.3% at 1M (8-needle)
- **Conf:** MED-HIGH | **Models:** 1,3,4,5 | **Relevance:** MEAS
- **Source:** Anthropic MRCR v2

### R2-C023 — GPT-5.4 MRCR: 90.5% at 32-64K, 79.3% at 128-256K, 57.5% at 256-512K, 36.6% at 512K-1M
- **Conf:** HIGH | **Models:** 1,3 | **Relevance:** MEAS
- **Source:** OpenAI MRCR v2

### R2-C024 — Gemini 2.5 Pro: 58% at ≤128K, 16.4% at 1M (severe long-context degradation)
- **Conf:** MED | **Models:** 3 | **Relevance:** MEAS
- **Note:** Model 4 outlier claim of 1.2M effective rejected

### R2-C025 — "256K effective from 1M" is a useful planning heuristic, not a hard number
- **Conf:** HIGH (principle) | **Models:** 5/5 with nuance | **Relevance:** ARCH
- **Implication:** Aim for 64-160K working set, treat 256K as outer bound, never plan to fill it

### R2-C026 — Task-type degradation hierarchy: factual retrieval > multi-hop > instruction-following > code-gen > inter-unit code reasoning (worst)
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C027 — Multi-hop reasoning effective at only ~5-10% of window
- **Conf:** MED | **Models:** 5 | **Relevance:** ARCH

### R2-C028 — Inter-unit code reasoning (cross-file dependencies) deteriorates first
- **Conf:** HIGH | **Models:** 2 | **Relevance:** ARCH+PROC

### R2-C029 — ~2% loss per 100K tokens is a useful rule-of-thumb but underestimates coding, overestimates retrieval
- **Conf:** MED | **Models:** 1 | **Relevance:** MEAS

### §2.A3 — Compaction and Summarization

### R2-C030 — Compaction-survival ranking: file paths/identifiers, architectural decisions, completion status, structured JSON, CLAUDE.md (re-read from disk) — survive well
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH+PROC

### R2-C031 — Compaction loss list: exact code snippets, nuanced reasoning chains, error messages/stack traces, debugging context, rejected alternatives, conversation history
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH+ANTI

### R2-C032 — Observation masking ≈50% cost reduction, matches summarization quality (or +2.6%), zero compute
- **Conf:** HIGH | **Models:** 4/5 | **Relevance:** PROC
- **Source:** JetBrains DL4C 2025 (cross-cited)

### R2-C033 — LLM summarization causes ~15% longer agent runs (smoothed summaries hide failure patterns)
- **Conf:** HIGH | **Models:** 4/5 | **Relevance:** ANTI
- **Source:** JetBrains

### R2-C034 — Extractive compression: 4.5× ratio + 7.89 F1 improvement (noise filtering)
- **Conf:** HIGH | **Models:** 5 | **Relevance:** PROC
- **Source:** Factory.ai

### R2-C035 — Abstractive compression: similar ratio but -4.69 F1
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ANTI

### R2-C036 — OpenHands condenser: ~2× per-turn reduction at neutral 54% vs 53% baseline
- **Conf:** HIGH | **Models:** 2,3 | **Relevance:** PROC
- **Source:** OpenHands

### R2-C037 — Compact at 50-60% capacity, NOT 80-95%
- **Conf:** HIGH | **Models:** 3,5 | **Relevance:** PROC

### R2-C038 — Use /compact with explicit preservation instructions
- **Conf:** HIGH | **Models:** 1,3 | **Relevance:** PROC

### R2-C039 — Structured DECISIONS.md notes survive multiple compactions
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C040 — Always re-read files from disk after compaction (never trust in-context copies)
- **Conf:** HIGH | **Models:** 1,2,3 | **Relevance:** PROC

### R2-C041 — Morph "prevention-first": reduce search/write waste 80-90%
- **Conf:** MED | **Models:** 5 | **Relevance:** PROC

### R2-C042 — Fresh context + state files often beats compaction for complex tasks
- **Conf:** HIGH | **Models:** 1,3,5 | **Relevance:** ARCH

### §2.A4 — Context Window Scaling Laws

### R2-C043 — Context scaling is sublinear (NLL follows power-law per Gemini 1.5 report)
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** META
- **Source:** Gemini 1.5 technical report

### R2-C044 — 100K tokens = 10 billion pairwise softmax relationships
- **Conf:** HIGH | **Models:** 5 | **Relevance:** META

### R2-C045 — LongCodeBench: 32K→256K HURTS success rate for repo-level bug fixing
- **Conf:** HIGH | **Models:** 2 | **Relevance:** ANTI

### R2-C046 — No evidence that 1M→10M would help coding
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** META

### R2-C047 — "Infinite context" architectures (Ring, Infini, StreamingLLM) are model-level research, 1-3 years out, don't fix attention dilution
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** EMRG

---

## §3 Techniques That Work

### §3.B1 — Context Budgeting and Allocation

### R2-C048 — Token usage alone explains 80% of performance variance (BrowseComp)
- **Conf:** HIGH | **Models:** 5 | **Relevance:** MEAS
- **Source:** Anthropic BrowseComp

### R2-C049 — TALE framework: 68.9% output cost reduction with <5% accuracy loss via explicit per-problem budgeting
- **Conf:** HIGH | **Models:** 5 | **Relevance:** PROC
- **Source:** TALE (ACL Findings 2025)

### R2-C050 — APEX's CONTEXT_BUDGET.json approach is novel — no published system has formal per-component token budgets
- **Conf:** HIGH | **Models:** 1 | **Relevance:** ARCH+META

### R2-C051 — GSD pattern: orchestrator at 10-15%, workers get full fresh windows
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ARCH

### R2-C052 — Aider repo map ~1-4K tokens (adjustable), dynamic expansion
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C053 — SWE-Agent uses last-5 observation-action sliding window
- **Conf:** HIGH | **Models:** 2,5 | **Relevance:** PROC

### R2-C054 — Manus AI: KV-cache hit rate is primary metric; 100:1 input-to-output ratio
- **Conf:** MED | **Models:** 5 | **Relevance:** MEAS

### R2-C055 — Synthesized budget for 200K window: stable_prefix 5-10K (2.5-5%), task_context 30-60K (15-30%), working_memory 20-40K (10-20%), generation_reserve 30-50K (15-25%); target max 100-120K (50-60%)
- **Conf:** HIGH (synthesis) | **Models:** 5/5 | **Relevance:** ARCH

### R2-C056 — Critical constraint: reserve at least 20-40% for generation; quality degrades for complex coding output above 60-75%
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C057 — Disagreement on rotation aggressiveness: Model 3 says steady 120-160K; Model 5 says hard 50% (100K) with pre-rot 60K; Model 1 says 25% generation reserve, compact at 75%; Model 4 says hard rotation at 50%
- **Conf:** MED (intra-disagreement) | **Models:** 1,3,4,5 | **Relevance:** ARCH+META
- **Resolution:** Follow conservative — target 100K working set, compact at 50-60%, hard rotate at 70%

### R2-C058 — Orchestrator-specific budget: 10-15% context usage MAX
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### §3.B2 — Structured Context Injection

### R2-C059 — XML tags help Claude parse complex prompts unambiguously
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** PROC
- **Source:** Anthropic docs

### R2-C060 — XML produces better coding results than JSON (reduces cognitive overhead)
- **Conf:** MED | **Models:** 1 | **Relevance:** PROC
- **Source:** Morph

### R2-C061 — Format choice itself almost doesn't matter for strong models — consistency matters more than syntax
- **Conf:** MED | **Models:** 2,3 | **Relevance:** PROC

### R2-C062 — Format restrictions decline reasoning ability ("Let Me Speak Freely?")
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ANTI
- **Source:** Tam et al. 2024

### R2-C063 — Structure has greater influence on determinism than LLM choice
- **Conf:** MED | **Models:** 5 | **Relevance:** ARCH

### R2-C064 — Recommended ordering: (1) system instructions, (2) project context, (3) middle/retrieved with XML, (4) recent evidence, (5) current task at end
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** PROC

### §3.B3 — Retrieval-Augmented Context (RAG for Code)

### R2-C065 — Aider repo map = gold standard reference implementation
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C066 — Aider details: tree-sitter AST parsing, directed graph, PageRank biased 50× toward active files, ~1K default expandable to 8K, 4.3-6.5% context utilization (highest measured); class signatures only, not implementations
- **Conf:** HIGH | **Models:** 1,2,5 | **Relevance:** ARCH

### R2-C067 — Aider efficiency vs Cursor (14.7%) and Cline (17.5%) — Aider 2-4× more efficient
- **Conf:** HIGH | **Models:** 5 | **Relevance:** MEAS

### R2-C068 — Code-specialized embeddings (Nomic, Voyage) outperform general for semantic search
- **Conf:** HIGH | **Models:** 2,5 | **Relevance:** PROC

### R2-C069 — General-purpose embeddings (MiniLM) surprisingly competitive at 80.1% MRR
- **Conf:** MED | **Models:** 5 | **Relevance:** PROC

### R2-C070 — GrepRAG (lexical intent-aware) matches semantic for many tasks, sub-500ms
- **Conf:** MED | **Models:** 5 | **Relevance:** PROC

### R2-C071 — SemanticForge dual knowledge graphs: 73% precision vs 51% traditional
- **Conf:** MED | **Models:** 5 | **Relevance:** PROC

### R2-C072 — Hybrid retrieval pattern: always-present compressed repo map (1-4K) + on-demand grep/glob/read + optional vector for cold/cross-project; never pre-stuff all relevant files
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C073 — CodeRAG-Bench: canonical docs improved SWE-Bench by 27.4% for GPT-4o with 200-800 token chunks (optimal range)
- **Conf:** HIGH | **Models:** 3 | **Relevance:** PROC

### R2-C074 — Vector DB for code as primary state = anti-pattern; useful only as Tier-3 secondary
- **Conf:** MED-HIGH (Models 4 strong; 2,5 nuanced) | **Models:** 4 vs 2,5 | **Relevance:** ARCH

### §3.B4 — External Memory Systems

### R2-C075 — Memory tier architecture: T1 always-loaded (CLAUDE.md), T2 per-phase state (STATE.json, DECISIONS.md), T3 on-demand (filesystem/tools), T4 cold (SQLite/Vector)
- **Conf:** HIGH | **Models:** 5/5 (T4 from 3,5 only) | **Relevance:** ARCH

### R2-C076 — CLAUDE.md effectiveness: <200 lines = 92% rule application; >400 lines = 71% rule application
- **Conf:** HIGH | **Models:** 5 | **Relevance:** PROC+MEAS

### R2-C077 — Well-written CLAUDE.md reduces manual corrections by 40% on 50K-line TypeScript projects
- **Conf:** MED | **Models:** 5 | **Relevance:** MEAS

### R2-C078 — CLAUDE.md survives compaction (re-read from disk); conversation history does not
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ARCH

### R2-C079 — MemGPT/Letta evolution: filesystem-native memory beats specialized tools (74% LoCoMo vs 68.5% Mem0)
- **Conf:** HIGH | **Models:** 1,2 | **Relevance:** ARCH

### R2-C080 — Letta Code "Context Repositories" = git worktrees for parallel memory branches with merge semantics
- **Conf:** HIGH | **Models:** 2,3 | **Relevance:** ARCH

### R2-C081 — No automated memory-staleness detection exists in any framework
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** META
- **Mitigations:** decay by age, invalidate on file hash mismatch, prefer fresh file reads

### R2-C082 — MINJA memory poisoning attack: >95% injection success, 70% attack success through query-only interaction
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ANTI+ARCH
- **Source:** Dong et al. 2025

### R2-C083 — Microsoft Security: 50 real-world memory-poisoning attempts across 31 companies in 60 days
- **Conf:** MED | **Models:** 5 | **Relevance:** ANTI

### R2-C084 — OWASP recognizes memory poisoning as top agentic risk for 2026
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ANTI

### R2-C085 — Agent defends the poison: constructs rationales from corrupted context
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ANTI

### R2-C086 — Required defenses: provenance tracking (who wrote what when why), temporal decay, validated backup snapshots, periodic memory audit by dedicated synthesis agent
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ARCH

### §3.B5 — Context Rotation and Session Management

### R2-C087 — Adding 113K conversation history drops accuracy ~30% vs focused 300-token version
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ARCH+ANTI
- **Source:** Chroma 2025

### R2-C088 — Laban et al. 2025: 39% average degradation in multi-turn; lost models don't recover
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ARCH

### R2-C089 — Community consensus: ~20-30 messages = practical quality horizon
- **Conf:** MED | **Models:** 5 | **Relevance:** PROC

### R2-C090 — Fresh context + state files > compacted long session for complex tasks
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C091 — Rotation triggers (consensus list): hard 70% utilization, soft/proactive 50-60%, phase boundary, every 5-8 tasks for orchestrator, time-based (30-45min), repeated errors / forgotten instructions / generic responses, STATE-vs-disk mismatch, recovery-density spike (same test 3+ times)
- **Conf:** HIGH | **Models:** 5/5 (composite) | **Relevance:** PROC

### R2-C092 — Prompt-caching economics: Anthropic 5-min/1-hr TTL = 10% input price, 85% latency reduction, break-even at 2 cache hits
- **Conf:** HIGH | **Models:** 5 | **Relevance:** PROC

### R2-C093 — With caching, stable prefix (system+CLAUDE.md+repo-map+skills) costs near-zero after first call → rotation is economically cheap
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH+PROC

### §3.B6 — Prompt Compression and Distillation

### R2-C094 — LLMLingua-2: 2-5× compression, 1.6-2.9× latency reduction, comparable quality — but CAUTION can corrupt code syntax
- **Conf:** MED | **Models:** 2,5 | **Relevance:** PROC+ANTI

### R2-C095 — 500xCompressor: up to 500× compression retains 70-84% F1/EM — NOT for code
- **Conf:** MED | **Models:** 2 | **Relevance:** ANTI

### R2-C096 — EHPC (evaluator heads) identifies important tokens via attention — research-stage
- **Conf:** MED | **Models:** 2 | **Relevance:** EMRG

### R2-C097 — Anthropic prompt caching: 90% cost, 85% latency, ZERO quality impact (exact prefix reuse)
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** PROC

### R2-C098 — Anthropic token-efficient tool use: 14% average reduction, minimal quality impact
- **Conf:** HIGH | **Models:** 1 | **Relevance:** PROC

### R2-C099 — Anthropic context editing (Sep 2025): 84% reduction in 100-turn eval; +39% with memory tool
- **Conf:** HIGH | **Models:** 1 | **Relevance:** PROC+EMRG

### R2-C100 — AGENTS.md eval: large always-on repo context files DECREASE success and increase cost by 20%+
- **Conf:** HIGH | **Models:** 3 | **Relevance:** ANTI
- **Implication:** Load skills and documentation on demand, not by default

---

## §4 Multi-Agent Context Architecture

### §4.C1 — Orchestration Patterns

### R2-C101 — Coordinator+Workers wins: 67% fewer tokens, highest quality for coding
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C102 — Hierarchical pattern: good with clear layers, for very large projects
- **Conf:** HIGH | **Models:** 1,2 | **Relevance:** ARCH

### R2-C103 — Peer-to-peer = worst (message overhead)
- **Conf:** HIGH | **Models:** 1,4 | **Relevance:** ANTI

### R2-C104 — Blackboard/shared-state = race conditions, contamination, NOT recommended for code
- **Conf:** HIGH | **Models:** 2,4 | **Relevance:** ANTI

### R2-C105 — Event-sourced (OpenHands) = good with condensation, 54% SWE-bench
- **Conf:** HIGH | **Models:** 2,5 | **Relevance:** ARCH

### R2-C106 — All 5 models recommend Coordinator+Fresh-Workers for APEX; coordinator must be thin (10-15% context), not memory store
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C107 — Anthropic Opus-4-lead + Sonnet-4-workers = 90.2% improvement on research tasks
- **Conf:** HIGH | **Models:** 1,5 | **Relevance:** MEAS

### R2-C108 — Multi-agent Claude code: 80% success vs 40% single-agent on 5 coding tasks (180K-line repo)
- **Conf:** HIGH | **Models:** 2,3 | **Relevance:** MEAS

### R2-C109 — MyAntFarm.ai (348 experiments): 100% actionable vs 1.7% single-agent for recommendation quality
- **Conf:** MED | **Models:** 5 | **Relevance:** MEAS

### R2-C110 — Multi-agent token cost: 3-15× higher total than single-agent
- **Conf:** HIGH | **Models:** 1,2 | **Relevance:** META

### §4.C2 — Information Flow Between Agents

### R2-C111 — Downstream packet (orchestrator → worker) minimal typed: task objective, relevant SPEC section (extracted not full), file paths, decisions/conventions, acceptance criteria, constraints
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C112 — Upstream result (worker → orchestrator) structured JSON with: status, files_modified, files_read, tests_run[], decisions_made[], issues_found[], unresolved_risks[], verification_needed, summary
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C113 — Critical rule: workers write artifacts to disk (bypass summarization bottleneck); orchestrator verifies artifacts directly, not summaries
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH+PROC

### §4.C3 — Shared State vs Message Passing

### R2-C114 — Use filesystem+Git for shared artifact state; typed messages for coordination only
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C115 — SWE-Adept pattern: every agent attempt = dedicated Git branch; failure = hard reset + fresh worker
- **Conf:** HIGH | **Models:** 4 | **Relevance:** ARCH

### R2-C116 — Letta Context Repositories: subagents use git worktrees for parallel memory modification
- **Conf:** HIGH | **Models:** 2,3 | **Relevance:** ARCH

### R2-C117 — Code artifacts NEVER in-context state; decisions in DECISIONS.md (versioned), not conversation memory; concurrent work via Git worktrees, not shared mutable state
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### §4.C4 — Context Isolation and Contamination

### R2-C118 — Adversarial PR-metadata fools LLM reviewers in 88.2% of cases
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ANTI

### R2-C119 — Redacting PR description recovers 68.75% of missed detections
- **Conf:** HIGH | **Models:** 5 | **Relevance:** PROC

### R2-C120 — Adding explicit debiasing instructions raises detection to 93.75-94%
- **Conf:** HIGH | **Models:** 5 | **Relevance:** PROC

### R2-C121 — Adversarial code review pattern drops overconfident failure 72% → 45%
- **Conf:** HIGH | **Models:** 4 | **Relevance:** PROC

### R2-C122 — Reasoning does NOT reduce bias — sometimes amplifies it (BMJ 2026)
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ANTI

### R2-C123 — Clean-room verification protocol Pass 1: spec + diff + touched files + test results + debiasing instructions ONLY. NO implementer reasoning, failed attempts, rationale
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH+PROC

### R2-C124 — Pass 2 (conditional): only on disagreement, reveal limited implementer context
- **Conf:** MED | **Models:** 3 | **Relevance:** PROC

### R2-C125 — Use different model or temperature for verification vs implementation
- **Conf:** MED | **Models:** 5 | **Relevance:** PROC

### R2-C126 — Google ADK "narrative casting": relabel prior assistant messages as third-party context to prevent identity confusion
- **Conf:** MED | **Models:** 5 | **Relevance:** PROC

---

## §5 Applied Patterns for Coding Tasks

### §5.D1 — Code-Specific Context Patterns

### R2-C127 — Coding-context priority required-set: task+criteria 1-5K, active code files 20-60K, interface/type context (signatures only) 1-4K, relevant test files 5-15K, conventions 1-3K
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C128 — Conditional context: error context 2-10K (debugging), dependency chain 3-10K (immediate only)
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C129 — Aider warning: irrelevant files distract or confuse the LLM
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ANTI

### R2-C130 — SWE-Pruner: 23-38% token reduction IMPROVED success rates (less is more, quantified)
- **Conf:** HIGH | **Models:** 3,5 | **Relevance:** PROC

### R2-C131 — CodeScout: enhanced problem statements reduced agent steps from 21 to 6 (pre-exploration converts vague to comprehensive)
- **Conf:** HIGH | **Models:** 5 | **Relevance:** PROC

### §5.D2 — Context Profiles per Task Type

### R2-C132 — New code: prioritize architecture docs/interfaces/style/examples + repo map + existing patterns; minimize full existing implementations
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH+PROC

### R2-C133 — Bug fixing: prioritize failing tests + stack traces + execution path + minimal dependency chain; minimize broad architecture docs
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH+PROC

### R2-C134 — Code review: prioritize spec/contract + diff + test results + surrounding functions; WITHHOLD implementer reasoning
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH+PROC

### R2-C135 — Refactoring: prioritize dependency graph + impact set + current tests; minimize unrelated modules
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH+PROC

### R2-C136 — Test writing: prioritize implementation contracts + test conventions + existing tests + coverage info; minimize broad system architecture
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH+PROC

### R2-C137 — Frontend: prioritize design context (Figma/MCP) + component hierarchy + style guide; minimize backend internals
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH+PROC

### R2-C138 — APEX should encode task-adaptive context profiles in CONTEXT_BUDGET.json — different budget allocations per task type
- **Conf:** HIGH (recommendation) | **Models:** R2 §5.D2 explicit | **Relevance:** ARCH

### §5.D3 — Stateful Development Sessions

### R2-C139 — Persist across sessions: architecture decisions, naming/coding conventions, task state/progress, known issues/deferred items, rejected approaches+rationale
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C140 — Always refresh from source: file contents (re-read), test results (re-run), dependency info, build/lint output, repository structure
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** PROC

### R2-C141 — Stale-reference major failure mode: agent works with cached file content modified by previous step
- **Conf:** HIGH | **Models:** 4/5 | **Relevance:** ANTI

### R2-C142 — Stale-reference solutions: always re-read from disk, git-backed state with explicit commit hashes, hook-based repo-map regen on file change, invalidate memory on file hash mismatch
- **Conf:** HIGH | **Models:** 5/5 (composite) | **Relevance:** PROC

### R2-C143 — Git Context Controller (Git-like ops COMMIT/BRANCH/MERGE): 48% SWE-bench Lite
- **Conf:** MED | **Models:** 5 | **Relevance:** EMRG

### R2-C144 — LangGraph MemorySaver with thread_id for checkpoint/restore
- **Conf:** HIGH | **Models:** 2 | **Relevance:** PROC

### R2-C145 — SWE-ContextBench: summarized experience reuse across issues
- **Conf:** MED | **Models:** 2 | **Relevance:** EMRG

### §5.D4 — Verification Context (coding-specific)

### R2-C146 — TiCoder (UPenn): test-driven verification +45.73% absolute improvement in pass@1 within 5 interactions
- **Conf:** HIGH | **Models:** 5 | **Relevance:** PROC

### R2-C147 — AgentCoder: separate test-designer + executor alongside programmer (tests first, then validate)
- **Conf:** MED | **Models:** 5 | **Relevance:** ARCH+PROC

### R2-C148 — CodeRabbit pattern: incremental reviews focused on changed files, not full history
- **Conf:** HIGH | **Models:** 3,5 | **Relevance:** PROC

### R2-C149 — Semi-formal reasoning (structured prompts + execution traces): improves verification 78% → 88%, to 93% with test specs
- **Conf:** HIGH | **Models:** 5 | **Relevance:** PROC

---

## §6 Emerging Approaches

### §6.E1 — Discipline framing

### R2-C150 — Karpathy framing: "LLM = CPU, context window = RAM, developer = OS"
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** META

### R2-C151 — Lütke: context engineering is "the most important skill for building with LLMs"
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** META

### R2-C152 — Anthropic Sep 2025: "designing and optimizing the complete information payload at inference time"
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** META

### R2-C153 — ACE framework Oct 2025: evolving playbooks +10.6% on agent benchmarks
- **Conf:** MED | **Models:** Mei et al. survey | **Relevance:** EMRG

### R2-C154 — IBM Zurich cognitive tools: GPT-4.1 AIME 26.7% → 43.3% via context engineering alone
- **Conf:** HIGH | **Models:** 5 | **Relevance:** MEAS

### §6.E2 — Novel Architectures

### R2-C155 — Prompt caching (Anthropic, Google, OpenAI): production-ready NOW — adopt immediately
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** PROC

### R2-C156 — Anthropic context editing Sep 2025: production-ready, 84% token reduction — high priority for APEX
- **Conf:** HIGH | **Models:** 1 | **Relevance:** PROC+EMRG

### R2-C157 — Sigmoid gating attention (Qwen NeurIPS Best Paper): 6-12 months out, model-level only
- **Conf:** MED | **Models:** 5 | **Relevance:** EMRG

### R2-C158 — LaMPE positional encoding: +37.8 points KV retrieval, 6-12 months out, model-level
- **Conf:** MED | **Models:** 5 | **Relevance:** EMRG

### R2-C159 — Ring Attention: requires ~512 GPUs for 1M, 1-3 years out
- **Conf:** MED | **Models:** 5 | **Relevance:** EMRG

### R2-C160 — Infini-attention: 114× compression but reproduction issues, 1-3 years out
- **Conf:** MED | **Models:** 5 | **Relevance:** EMRG

### R2-C161 — StreamingLLM: 22.2× speedup but doesn't extend understanding
- **Conf:** MED | **Models:** 5 | **Relevance:** EMRG

### §6.E3 — Predictive and Adaptive Context

### R2-C162 — Models can self-assess context needs via tool use (ask to see files)
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** PROC

### R2-C163 — CodeRAG uses log probabilities to predict needed chunks
- **Conf:** MED | **Models:** 2 | **Relevance:** EMRG

### R2-C164 — Aider dynamically adjusts repo-map size based on need
- **Conf:** HIGH | **Models:** 1,2 | **Relevance:** PROC

### R2-C165 — APEX opportunity: orchestrator should plan WHICH context to fetch before dispatching workers, not just what code to write
- **Conf:** HIGH (recommendation) | **Models:** 2 | **Relevance:** ARCH

### §6.E4 — Evaluation and Measurement

### R2-C166 — Available benchmarks: MRCR v2 (best multi-round 1M), RULER (multi-hop tracing), BABILong (extreme), LongCodeBench (coding), LONGCODEU (long-code understanding), SWE-ContextBench (gold contexts), ContextBench (explored vs utilized), NoLiMa (11/12 models <50% at 32K), HELM Long Context (highest MRCR 0.256 at 128K)
- **Conf:** HIGH | **Models:** 5/5 (composite) | **Relevance:** MEAS

### R2-C167 — Proposed APEX metrics (cross-model synthesis): token utilization per zone per agent, context composition breakdown, task-success-rate by context-fill %, retrieval precision (files accessed vs needed), compaction/rotation frequency, STATE.json vs disk consistency, recovery-action density (repeated same actions = degradation), stale-reference rate, verifier-disagreement rate, cache hit rate, **task#N quality vs task#1 (the ultimate APEX metric)**
- **Conf:** HIGH | **Models:** 5/5 (composite) | **Relevance:** MEAS

---

## §7 Anti-Patterns and Failure Modes

### §7.F1 — Context Anti-Patterns Ranked by Severity

### R2-C168 — CRITICAL anti-pattern: context stuffing → attention dilution, lost-in-middle, distractor interference (NoLiMa: 11/12 models <50% at 32K; shuffled docs sometimes outperform structured!)
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ANTI

### R2-C169 — HIGH anti-pattern: LLM self-summarization as default → loses stack traces, file paths, failed attempts, causes loops
- **Conf:** HIGH | **Models:** 4/5 | **Relevance:** ANTI

### R2-C170 — HIGH anti-pattern: monolithic CLAUDE.md / repo context files → fading-memory, +20% cost
- **Conf:** HIGH | **Models:** 1,3 | **Relevance:** ANTI

### R2-C171 — HIGH anti-pattern: NIAH optimism — near-perfect needle-in-haystack ≠ real-world capability
- **Conf:** HIGH | **Models:** RULER, BABILong, LongBench v2 | **Relevance:** ANTI

### R2-C172 — MED-HIGH anti-pattern: summarizing into prose only → loses provenance, causality, exact paths, open risks
- **Conf:** HIGH | **Models:** 3,4 | **Relevance:** ANTI

### R2-C173 — MED-HIGH anti-pattern: ignoring context rot — operating as if context is simple storage
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ANTI

### R2-C174 — MED anti-pattern: over-compaction loses subtle but critical context
- **Conf:** HIGH | **Models:** 1,5 | **Relevance:** ANTI

### §7.F2 — Multi-Agent Context Failures

### R2-C175 — Failure mode: orchestrator bottleneck — ingests full worker output, exceeds 256K, plan degrades
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ANTI

### R2-C176 — Failure mode: verification contamination — reviewer sees implementer reasoning, rubber-stamps errors
- **Conf:** HIGH | **Models:** 3,4,5 | **Relevance:** ANTI

### R2-C177 — Failure mode: too much shared context = inherited biases, circular reasoning, false convergence
- **Conf:** HIGH | **Models:** 2,3,5 | **Relevance:** ANTI

### R2-C178 — Failure mode: too little shared context = inconsistent changes, duplicated work, missed dependencies
- **Conf:** HIGH | **Models:** 2,3 | **Relevance:** ANTI

### R2-C179 — Failure mode: trajectory elongation — smoothed summaries hide failure signals, agent loops longer
- **Conf:** HIGH | **Models:** 2,5 | **Relevance:** ANTI

### R2-C180 — Failure mode: free-text agent communication = token bloat, circular disagreements
- **Conf:** HIGH | **Models:** 4,5 | **Relevance:** ANTI

### R2-C181 — Failure mode: coordination plateau — beyond 4 agents, latency grows superlinearly
- **Conf:** MED | **Models:** 5 | **Relevance:** ANTI

### R2-C182 — Failure mode: error compounding — 99% per-step × 10 steps = 90.4% system reliability
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ANTI

### R2-C183 — MAST taxonomy (UC Berkeley, 1,642 traces, 7 frameworks): 41-86.7% failure rates; system design 41.76%, inter-agent misalignment 36.94%, task verification breakdowns 21.30% — all context-related
- **Conf:** HIGH | **Models:** 5 | **Relevance:** MEAS+ANTI

### §7.F3 — Memory and State Failures

### R2-C184 — Memory failure: state desynchronization — STATE.json claims don't match disk; mitigation = always derive from disk, verify before acting
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ANTI+PROC

### R2-C185 — Memory failure: memory poisoning — wrong info persisted, repeatedly retrieved; mitigation = provenance + temporal decay + validated backups
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ANTI

### R2-C186 — Memory failure: stale embeddings — code changed without re-indexing; mitigation = git-backed state, prefer file reads
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ANTI

### R2-C187 — Memory failure: multiple-writer race conditions; mitigation = sequential execution OR git worktrees/branches
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ANTI+PROC

---

## §8 Architectural Recommendations for APEX (R2 explicit)

### R2-C188 — Hard budget: 50-60% of effective capacity per task phase
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C189 — Zone 1 Stable Prefix (cached): 5-10K = 2.5-5% — system + CLAUDE.md (<200 lines) + repo-map skeleton, prompt-cached
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C190 — Zone 2 Task Context (JIT-loaded): 30-60K = 15-30% — active files, interfaces, test specs, on-demand via tools
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C191 — Zone 3 Working Memory (masked): 20-40K = 10-20% — tool outputs, intermediate results, observation-masking applied
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C192 — Zone 4 Generation Reserve: 30-50K = 15-25% — reserved, NEVER consumed by input
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C193 — Target max utilization: 100-120K = 50-60% — compact proactively before
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C194 — Orchestrator-specific budget: 10-15% MAX — passes file paths and typed task specs, not file contents; reads subagent results from JSON files, not conversation
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C195 — Recommended ordering with XML-style tags: <system_instructions>, <project_context>, <task_spec>, <prior_decisions>, <context_files> (typed PRIMARY/DEPENDENCY/TEST), <recent_evidence>, <current_task>
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** PROC

### R2-C196 — Always-in-context: system prompt, CLAUDE.md (<200 lines), repo-map skeleton, current task+criteria, budget telemetry
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C197 — On-demand-via-tools only: full file contents, old test results, historical decisions, external docs, dependency details
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C198 — Multi-agent flow: Orchestrator (thin 10-15%, compacts at 50%) → Workers (fresh, typed JSON + artifacts to disk) → Verifier (fresh, CLEAN-ROOM: spec+diff+tests only, NO worker reasoning)
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C199 — Worker→Orchestrator typed result must include: task_id, status (success|failure|partial), files_read, files_modified, tests_run, decisions_made (with rationale+spec_ref), issues_found, unresolved_risks, confidence, summary
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C200 — Isolation guarantees: workers never see each other's history; verifiers never see implementation reasoning Pass-1; orchestrator sees typed summaries not raw output; different model/temperature for verification when possible; explicit debiasing in verifier prompt
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH+PROC

### R2-C201 — State flow MUST be: artifacts→filesystem/git → typed packets → versioned .apex/ files. NEVER through accumulated conversation
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C202 — Proactive rotation triggers (table): soft 50-60% (proactive compact+state write), hard 70% (force rotation), phase boundary, 5-8 task batch (orchestrator), 30-45min time, quality signals (errors/forgetting), recovery-density spike (3+ same actions)
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** PROC

### R2-C203 — State-preservation protocol pre-rotation: write STATE.json + DECISIONS.md + git commit tagged checkpoint + phase summary (done/next/issues)
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** PROC

### R2-C204 — State-restoration protocol post-rotation: load CLAUDE.md (disk), STATE+PLAN_META, relevant DECISIONS, regenerate repo-map, re-read relevant files. **Do NOT load old conversation history or prose summaries**
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** PROC

### R2-C205 — Verification clean-room INCLUDED list: task spec from PLAN_META, acceptance criteria, file diff (unified), surrounding code slices, test results stdout/stderr, relevant DECISIONS conventions, explicit debiasing instructions
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH+PROC

### R2-C206 — Verification clean-room EXCLUDED list: implementer reasoning/CoT, failed attempts and backtracking, implementer confidence assessment, orchestrator narrative, prior verifier opinions (Pass 1), time/quality pressure, worker conversation history
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH+PROC

### R2-C207 — Two-pass verification: Pass 1 clean-room, Pass 2 only on disagreement reveals limited factual implementer summary (not rationale) + prior verifier findings
- **Conf:** HIGH | **Models:** 3,5 | **Relevance:** PROC

### R2-C208 — Verification enhancements: parallel-personas (security/architecture/performance critics) with moderator synthesis; test-driven verification (write tests first then validate)
- **Conf:** HIGH | **Models:** 4,5 | **Relevance:** ARCH+EMRG

### R2-C209 — Three-tier memory system: T1 always-loaded `.apex/CLAUDE.md` <200 lines (cached); T2 session state STATE.json+PLAN_META+DECISIONS+tasks/*.json (phase boundaries); T3 indexed retrieval SQLite+repo-map (explicit retrieval via tools)
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C210 — Why files+Git+SQLite (NOT vector DB primary): files = human-readable/auditable/editable/Git-compatible; Git = versioning/branching/rollback/free-coordination; SQLite = zero-ops ACID/FTS5/provenance/temporal queries; vector = T3 cold/semantic only
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** ARCH

### R2-C211 — Memory integrity measures (mandatory): every record has source-agent + timestamp + confidence + scope + invalidation-path; speculative observations quarantined until verified; decay by age; invalidate on file-hash mismatch; periodic memory audit by independent agent; validated snapshots for rollback (defend MINJA); cap tool results in context (use file-path memory pointers)
- **Conf:** HIGH | **Models:** 5 | **Relevance:** ARCH

### R2-C212 — Context Health Dashboard (8 metric categories with alert thresholds): budget compliance (zone>120%), utilization quality (precision<50%), degradation signals (recovery-density>3, compliance-drop>15%), session health (fill>60%, time>45min), cache efficiency (hit<80%), state consistency (any mismatch), memory quality (stale>10%), quality-over-time (>5% variance task#N vs task#1)
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** MEAS

### R2-C213 — User-facing indicators: context-fill gauge (🟢<50% / 🟡 50-60% / 🔴 >60%), last rotation timestamp, stale-state warnings, memory freshness indicator, verification confidence for last task
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** MEAS

### R2-C214 — The ultimate APEX metric: task#50 statistically indistinguishable from task#1 in quality; achievable ONLY via context rotation+isolation, not larger windows
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** MEAS+ARCH

---

## §9 Limitations and Disagreements

### R2-C215 — GAP: no published coding-specific degradation curves for current frontier models (Claude 4.6 Opus, GPT-5.4, Gemini 2.5 Pro)
- **Conf:** HIGH (gap) | **Models:** 5/5 | **Relevance:** META

### R2-C216 — GAP: no published study directly comparing "task N fresh-context vs task N in long session" for coding quantitatively
- **Conf:** HIGH (gap) | **Models:** 5/5 | **Relevance:** META

### R2-C217 — GAP: context budget allocation ratios are synthesized, NOT measured per-component
- **Conf:** HIGH (gap) | **Models:** 5/5 | **Relevance:** META

### R2-C218 — GAP: self-reported benchmarks dominate (Anthropic/OpenAI/Google all report own MRCR); independent verification sparse
- **Conf:** HIGH (gap) | **Models:** 5/5 | **Relevance:** META

### R2-C219 — GAP: multi-agent coding overhead lacks rigorous quantification (15× and 3-5× cost figures not from controlled experiments)
- **Conf:** HIGH (gap) | **Models:** 5/5 | **Relevance:** META

### R2-C220 — GAP: verifier contamination in coding lacks quantified study (strong indirect evidence but no direct "with/without implementer rationale" measurement for AI code review)
- **Conf:** HIGH (gap) | **Models:** 5/5 | **Relevance:** META

### R2-C221 — GAP: memory-poisoning for coding agents poorly studied (MINJA on general assistants, not coding-specific)
- **Conf:** HIGH (gap) | **Models:** 5/5 | **Relevance:** META

### R2-C222 — GAP: field moves faster than publication (Anthropic context-editing Sep 2025, 1M GA March 2026 may already shift landscape)
- **Conf:** HIGH (gap) | **Models:** 5/5 | **Relevance:** META

### R2-C223 — DISAGREEMENT: effective working set 64-128K (Model 2) to 256K (Model 1); resolution → 100-160K orchestrator, 64-128K workers
- **Conf:** MED | **Models:** 1,2,3,4,5 spread | **Relevance:** META

### R2-C224 — DISAGREEMENT: rotation threshold 50% (Models 4,5) to 85% (APEX v5 historical); resolution → 50-60% proactive, 70% hard
- **Conf:** HIGH | **Models:** 4,5 | **Relevance:** META

### R2-C225 — DISAGREEMENT: repo map budget 1K (Model 1) to 4K (Model 4); resolution → 1-4K adaptive (Aider's approach)
- **Conf:** MED | **Models:** 1 vs 4 | **Relevance:** META

### R2-C226 — DISAGREEMENT: LLM summarization "never for coding" (Model 4) vs "useful at phase boundaries" (Models 1,2,3); resolution → phase boundaries only, default observation masking
- **Conf:** HIGH | **Models:** 1,2,3 vs 4 | **Relevance:** META

### R2-C227 — DISAGREEMENT: Vector DB "anti-pattern" (Model 4) vs "useful secondary" (Models 2,3,5); resolution → Tier-3 only, never primary state
- **Conf:** HIGH | **Models:** 4 vs 2,3,5 | **Relevance:** META

---

## Conclusion (R2 §10) — APEX Missing Pieces

R2 explicitly identifies APEX's architectural alignment AND 6 missing pieces:

### R2-C228 — APEX architecture (orchestrator + fresh subagents + file-based state + git) is ALIGNED with state-of-the-art best practices
- **Conf:** HIGH (R2 explicit endorsement) | **Models:** 5/5 | **Relevance:** META+ARCH

### R2-C229 — APEX MISSING #1: Observability — measuring context health in real-time, not just estimating
- **Conf:** HIGH (R2 explicit) | **Models:** 5/5 | **Relevance:** META

### R2-C230 — APEX MISSING #2: Proactive rotation — compacting at 50-60%, not 85%
- **Conf:** HIGH (R2 explicit) | **Models:** 5/5 | **Relevance:** META

### R2-C231 — APEX MISSING #3: Observation masking — deleting old tool outputs instead of summarizing
- **Conf:** HIGH (R2 explicit) | **Models:** 5/5 | **Relevance:** META

### R2-C232 — APEX MISSING #4: Clean-room verification — architecturally isolating verifiers
- **Conf:** HIGH (R2 explicit) | **Models:** 5/5 | **Relevance:** META

### R2-C233 — APEX MISSING #5: Task-adaptive loading — different context profiles per task type
- **Conf:** HIGH (R2 explicit) | **Models:** 5/5 | **Relevance:** META

### R2-C234 — APEX MISSING #6: Memory integrity — provenance, decay, poisoning protection
- **Conf:** HIGH (R2 explicit) | **Models:** 5/5 | **Relevance:** META

### R2-C235 — Bottom line: "Less context, better chosen, always beats more context, naively stuffed"
- **Conf:** HIGH | **Models:** 5/5 | **Relevance:** META+ARCH

---

## Index Summary

- **Total claims:** 235
- **By confidence:** HIGH ~155, MED ~70, LOW ~10
- **By relevance:** ARCH 78, PROC 56, MEAS 24, ANTI 32, EMRG 14, META 31
- **By section:** §1 (7) | §2 (40) | §3 (53) | §4 (26) | §5 (23) | §6 (18) | §7 (20) | §8 (27) | §9 (13) | §10 (8)
- **Cross-ref backbone:** R2-C001 ↔ {R2-C008, R2-C017, R2-C019, R2-C168, R2-C173}; R2-C003 ↔ {R2-C032, R2-C033, R2-C169, R2-C231}; R2-C004 ↔ {R2-C051, R2-C087, R2-C101, R2-C106}; R2-C006 ↔ {R2-C118-126, R2-C176, R2-C200, R2-C232}

**Phase 1 status:** ✅ Complete (235 atomic claims, all R2 sections covered).
**Next:** Phase 2 — APEX-INVENTORY.md (read APEX state, map evidence per primitive).
