# APEX Round 6 — Synthesized Research Report
# Learning & Memory in Agentic Coding Systems
## Cross-Model Synthesis from 5 Independent Deep Research Analyses

---

## Methodology Note

This document synthesizes findings from 5 independent deep-research model runs on the same brief. Findings are weighted by **cross-model consensus** (how many models independently reached the same conclusion), **evidence quality** (peer-reviewed > production data > blog posts), and **specificity to coding agents** (coding-specific data trumps general agent research). Where models disagree, both positions are presented with evidence. Where numbers vary across models, the most conservative or best-sourced figure is used.

**Consensus key:** ■■■■■ = all 5 models agree | ■■■■□ = 4 of 5 | ■■■□□ = 3 of 5 | ■■□□□ = 2 of 5

---

## 1. Executive Summary — 7 Core Findings

**Finding 1: Cross-project learning produces measurable 5–22% improvement — but ONLY with quality-controlled, compact memory.** ■■■■■
Reflexion achieved +11% on HumanEval (80%→91%), Voyager delivered 3.3–15.3× improvements on skill transfer, and ExpeL showed positive forward transfer between completely different tasks. The newest evidence — SWE-ContextBench (2026) — directly measured experience reuse in coding: oracle-selected compact summaries raised resolution from 26.26% to 34.34% (+8.08pp). However, unfiltered experience ("free summary reuse") **dropped performance to 22.22%** — below the no-experience baseline. The single clearest conclusion: retrieval quality matters more than memory quantity.

**Finding 2: There is a sharp, measured ceiling on how many patterns an agent can use effectively.** ■■■■■
ERL (March 2026) found performance peaks at 40–60 heuristics then degrades. IFScale (Jaroslawicz et al., 2025) showed frontier models achieve only 68% accuracy at 500 instructions, with practical threshold decay at ~150 instructions. The CLAUDE.md data (92% application at <200 lines, 71% at >400 lines) — while not peer-reviewed — is directionally consistent. Chroma's Context Rot study (2025) confirmed all 18 tested frontier models degrade as context grows. **Practical ceiling: ~100–150 high-quality, prioritized patterns in always-loaded context.**

**Finding 3: Distilled, compact patterns dramatically outperform raw experience trajectories.** ■■■■■
SWE-ContextBench summaries averaged 204.5 words vs. full trajectories at 24,765 words — yet summaries delivered 34.34% resolution vs. 27.27% for full trajectories. ERL confirmed distilled heuristics outperform raw trajectories at every experience count. ExpeL showed extracted insights outperform raw reflections. This validates APEX's approach of storing structured patterns rather than session logs.

**Finding 4: Memory poisoning is a severe, production-grade threat — not theoretical.** ■■■■■
MINJA (NeurIPS 2025) achieves >95% injection success through query-only interaction with no elevated access. MemoryGraft showed that just 9.1% poisoned records captured 47.9% of all retrievals. LLM-based detectors miss 66% of poisoned entries. AgentPoison achieved 80%+ attack success. Code-specific vectors include malicious comments (CVE-2025-53773), poisoned config files (CVE-2025-54135), and the ToxicSkills campaign (76 confirmed malicious agent skills in OpenClaw). OWASP classifies memory poisoning as ASI06 in the 2026 Top 10.

**Finding 5: Failure-derived knowledge is more valuable than success-derived knowledge.** ■■■■□
ERL found failure heuristics substantially outperform success-derived ones (+14.3% on search tasks). Reflexion's core mechanism is learning from failed attempts. ExpeL showed that distilling both successes and failures is optimal, but failure patterns have higher transfer value. APEX's current trigger (critic FAIL → write to memory) is well-aligned with this evidence.

**Finding 6: Tiered, hybrid memory is the consensus architecture.** ■■■■■
Every production system and all 5 models converge on a multi-tier approach: a small, curated "hot" layer always in context + a larger searchable "warm" layer retrieved on demand + a cold archive. No production system at scale uses flat-file-only. Specific implementations vary (Letta's core/archival blocks, Claude Code's active memories + state.json with decay, Copilot Memory's repo-scoped entries with 28-day TTL), but the pattern is universal.

**Finding 7: Human curation remains essential and irreplaceable.** ■■■■■
Boris Cherny's hand-curated ~100-line CLAUDE.md outperforms 800-line auto-generated configs. Claude Code team tried and discarded vector databases. GitHub Copilot Memory requires human interaction to create memories. Every production system with durable memory relies on human oversight. No automated system achieves reliable pattern validation alone.

---

## 2. Evidence for Learning Benefits

### 2.1 Measured Improvements (Cross-Model Verified)

| System | Task | Baseline | With Memory | Improvement | Confidence | Sources |
|--------|------|----------|-------------|-------------|------------|---------|
| Reflexion | HumanEval (coding) | 80% pass@1 | 91% pass@1 | **+11pp** | High (all 5 models, NeurIPS 2023) | Shinn et al., 2023 |
| Reflexion | ALFWorld (decision) | ~75% | ~97% | **+22pp** | High (all 5 models) | Shinn et al., 2023 |
| Reflexion | HotPotQA (reasoning) | ~32–51% | ~52–71% | **+20pp** | High (all 5 models) | Shinn et al., 2023 |
| Reflexion | WebShop | baseline | no improvement | **0%** (failed) | Medium (1 model) | Shinn et al., 2023 |
| Voyager | Unique items discovered | ~19 items | 63 items | **3.3×** | High (all 5 models) | Wang et al., 2023 |
| Voyager | Tech tree milestones | baseline | up to 15.3× faster | **750–1430%** | High (all 5 models) | Wang et al., 2023 |
| Voyager | Cross-world transfer | 0% baselines | 100% tasks solved | **Total transfer** | High (all 5 models) | Wang et al., 2023 |
| ExpeL | ALFWorld (single attempt) | 54% (Reflexion w/retries) | 59% (no retries) | **+5pp** | High (4 models) | Zhao et al., 2024 |
| ExpeL | HotPotQA → FEVER transfer | 63% | 70% | **+7pp** | High (4 models) | Zhao et al., 2024 |
| ERL | Gaia2 (overall) | 48.3% | 56.1% | **+7.8pp** | Medium-High (preprint, March 2026) | ERL, 2026 |
| SWE-ContextBench | Resolution rate (oracle summary) | 26.26% | 34.34% | **+8.08pp** | High (3 models, 2026) | Zhu et al., 2026 |
| AgentTrek | Visual grounding | 30.7% | 67.4% | **+119%** | Medium (2 models, ICLR 2025) | Xu et al., 2025 |
| Cross-project defect prediction | F1-measure (AEEEM) | varies | +5.9% to +33% | **Varies** | Medium (2 models) | Multiple CPDP studies |

**Critical nuance:** Reflexion failed completely on WebShop (requiring exploration diversity), and only 1 model flagged this. Self-reflection works for correcting identified mistakes, not for tasks requiring novel exploration strategies.

### 2.2 When Learning Hurts — Negative Transfer Evidence

**SWE-ContextBench (strongest evidence, 3 models cite):**
- Free summary reuse: **22.22%** — below the 26.26% no-experience baseline
- This means unfiltered experience actively reduces performance by 4.04 percentage points
- Even oracle full-trajectory reuse (27.27%) barely beats no experience — only oracle *summaries* show strong gains

**ERL Non-Monotonic Finding (2 models):**
- Performance peaks at 40–60 heuristics, then degrades with more
- This is the clearest evidence that "more knowledge ≠ better"

**Cross-Project Defect Prediction Failure (1 model, strong evidence):**
- Zimmermann et al. (ESEC/FSE 2009): only **<3.4%** of 622 cross-project experiments showed satisfactory performance
- Simply being in the same domain was insufficient for positive transfer

**RECALL Benchmark (1 model):**
- When agents retrieved incorrect external context, accuracy dropped **below even the no-context baseline**
- Wrong memories are definitively worse than no memories

**Technology Stack Invalidation (all 5 models, no hard data):**
- All models agree this is a critical risk, but **no study quantifies technology-version-specific negative transfer in coding agents**
- This is the single largest evidence gap identified
- First Principles Framework (1 model): 20–25% of architectural decisions become stale, 86% caught reactively

**ExpeL Ablation (2 models):**
- "insights+reflections" configuration performed worse than full ExpeL
- Unfiltered reflection can pollute memory rather than help

### 2.3 Knowledge Taxonomy — What to Learn, What to Avoid

**Consensus ranking across all 5 models:**

**Highest ROI (persist with long TTL):**
1. **Bug/failure patterns** — missing error handling, auth bypasses, null checks, race conditions. Transfer well across projects, stable over time, verifiable via tests. ERL confirms failure-derived heuristics outperform success-derived ones.
2. **Anti-patterns** — what NOT to do. More stable than positive patterns because they encode fundamental mistakes that remain mistakes regardless of framework version.
3. **Silent failure patterns** — code that passes tests but has hidden issues. Extremely high value, hard to detect, transfers across projects.
4. **Architectural patterns** — MVC, dependency injection, event-driven. Broad applicability, evolve slowly over years.

**Medium ROI (persist with version scoping):**
5. **Integration patterns** — Supabase RLS, API auth flows. Transfer within same tool version. Need version metadata.
6. **Framework-specific patterns** — Next.js routing, React hooks. High immediate value but **highest staleness risk**.

**Lowest ROI / Highest Risk (do not persist globally):**
7. **Convention patterns** — naming, file structure. Project-specific, limited cross-project value.
8. **Raw failure trajectories** — noisy, hard to generalize. SWE-ContextBench showed 204-word summaries vastly outperform 24,765-word trajectories.
9. **Project-specific business logic** — doesn't transfer.
10. **Unverified hypotheses** — intermediate steps that didn't lead to successful compilation. Persisting these poisons the memory pool.

---

## 3. Memory Representation Analysis

### 3.1 Structured Markdown (APEX's Current Approach)

**Verdict: Excellent as canonical human-readable layer. Insufficient as sole memory system at scale.** ■■■■■

Evidence for:
- Boris Cherny's ~100-line CLAUDE.md outperforms 800+ line auto-generated configs (production evidence)
- Human readability enables curation — the single most important quality control mechanism
- Git-compatible, auditable, version-controlled
- Cursor .cursorrules, Copilot instructions, ADRs all validate the pattern
- SWE-ContextBench: 204-word summaries >> 24,765-word trajectories

Evidence against:
- No semantic search — linear scan loads everything regardless of relevance
- CLAUDE.md data shows degradation beyond 200–400 lines
- IFScale: 68% accuracy at 500 instructions; practical ceiling ~150
- "Lost in the Middle" effect: >30% degradation for mid-positioned information
- ExpeL anti-pattern: concatenating all insights regardless of relevance scales poorly

**Practical limit: ≤100–200 patterns in the always-loaded file.**

**Credibility note (flagged by 1 model):** The 92%/71% CLAUDE.md statistics originate from a SFEIR Institute blog post — not peer-reviewed, no methodology documented. IFScale provides supporting but not identical evidence.

### 3.2 Vector Database / Embedding-Based Memory

**Verdict: Not recommended as primary storage. Useful as optional secondary retrieval layer.** ■■■■□

Evidence for:
- Enables semantic search, solving the relevance-matching problem flat files can't
- CLARC benchmark: embedding MRR ~79–87 vs BM25 MRR ~8–16 for code search
- ERL: embedding-based retrieval (53.3%) outperforms random selection at scale
- Nomic Embed Code: 81.7% on Python CodeSearchNet (state-of-the-art)

Evidence against:
- **Claude Code team explicitly discarded vector databases** — "code drifts out of sync and permissions are complex"
- **Sourcegraph Cody moved away from embeddings** to native keyword search at enterprise scale
- ERL found LLM-based retrieval (56.1%) outperforms embedding retrieval (53.3%)
- MINJA specifically exploits vector-similarity-based retrieval for poisoning
- Stale embeddings are a documented problem
- SWE-ContextBench: autonomous experience reuse (which uses similarity) performed at or below baseline
- Cost/complexity overhead vs marginal retrieval improvement

**Model disagreement:** Model 2 was more enthusiastic about vector approaches, citing Engram's ~90ms retrieval. However, 4/5 models recommend against vector DB as primary, and the Claude Code team's direct production experience discarding them is the strongest signal.

**If used:** Only as secondary recall layer over human-curated patterns, with `valid_until` metadata, re-embedding pipelines, and staleness detection.

### 3.3 Knowledge Graphs

**Verdict: High potential for code-structure reasoning, but overkill for APEX's current scale. Phase 2–3 consideration.** ■■■■□

Evidence for:
- SemanticForge: **73% precision** in context selection vs 51% for BM25 (+22pp)
- SemanticForge: Pass@1 = 49.8% (+15.6pp over baseline) on repository-level tasks
- SemanticForge: 89% reduction in schematic errors via SMT-integrated search
- 90% latency reduction with incremental graph updates; scales to 500K LOC
- Naturally mirrors code topology: ASTs, call hierarchies, dependency maps

Evidence against:
- No evidence of knowledge graphs used successfully in production coding agents for pattern memory
- High upfront cost: entity extraction, AST parsing, static analysis pipelines
- Cold-start problem; disabling lazy cross-reference resolution increased latency by 448%
- For APEX's use case (50–200 validated patterns, not full codebase modeling) — disproportionate overhead

**Recommendation:** A lightweight call/dependency graph (like Aider's RepoMap) can serve as structural context that guides retrieval, without requiring full KG infrastructure. This is complementary to, not a replacement for, pattern memory.

### 3.4 SQLite + FTS5

**Verdict: Recommended as the index/metadata/validation layer alongside markdown.** ■■■■■

Evidence for:
- Multiple independent implementations converge: Engram, EchoVault, ZeroClaw, OpenClaw all use SQLite + FTS5
- Zero infrastructure, single-file portability, ACID compliance
- Sub-millisecond retrieval: <3ms total (0.3ms FTS5 + 2ms vector + 0.1ms merge) measured on Raspberry Pi Zero
- Letta persists agent state in databases
- Provides exactly what APEX lacks: provenance, status fields, temporal queries, conflict detection, validation history, FTS search
- sqlite-vec extension enables optional semantic search within the same file

Evidence against:
- Not human-readable without tooling (breaks the curation advantage)
- No production coding agent uses SQLite for pattern memory specifically (but convergence from multiple agent frameworks is strong)

**Resolution:** SQLite as index + control plane; markdown remains source-of-truth. This preserves human readability while adding all missing capabilities.

### 3.5 Hybrid Tiered Architecture (Recommended)

**Verdict: Universal consensus. Every production system and all models converge here.** ■■■■■

The three-tier pattern emerging across all sources:

| Tier | Content | Size Limit | Access Pattern | Examples |
|------|---------|------------|----------------|----------|
| **Hot (Tier 1)** | Highest-confidence, most-used, cross-project patterns | ≤100–200 lines | Always loaded before planning | CLAUDE.md, .cursorrules, apex-learnings-core.md |
| **Warm (Tier 2)** | Full pattern library with metadata | ≤500 patterns | Queried on demand by task context | SQLite + FTS5, Letta archival memory, Claude Code state.json |
| **Cold (Tier 3)** | Archived, deprecated, superseded patterns | Unlimited | Never auto-loaded, searchable on explicit request | Audit trail, historical reference |

**Hot tier size debate across models:**
- Model 1: ≤50 patterns, ≤200 lines
- Model 3: ≤200–300 lines per scope
- Model 5: ≤100 patterns (firm)
- Models 4: "5–10 compact rules at a time" for retrieval injection

**Synthesis recommendation:** ≤100 patterns in hot tier, but only 5–15 injected per task (retrieved from warm tier based on relevance). This reconciles the IFScale ceiling (~150 instructions) with the ERL finding (peak at 40–60 heuristics) and SWE-ContextBench evidence (compact summaries >> full context).

---

## 4. Memory Operations — Write / Read / Update / Delete

### 4.1 Writing to Memory

**Core principle (all 5 models): NOOP (not writing) is the most valuable operation.** ■■■■■

**When to write:**
- After critic FAIL with recurring or critical pattern confirmed by tests/verifiers ■■■■■
- After Silent Auditor CRITICAL detection ■■■■■
- After pattern observed in ≥2 independent projects ■■■■□
- After human review/curation ■■■■■
- Post-project batch synthesis (consolidation step) ■■■■□

**When NOT to write:**
- After every task (ExpeL anti-pattern: scales poorly) ■■■■■
- Single-observation speculative patterns ■■■■□
- Raw session logs or conversation dumps ■■■■■
- Project-specific temporary state ■■■■■

**Who writes:**
- 4/5 models recommend a dedicated **Memory Synthesis agent** that distills raw observations into structured patterns, rather than the task agent writing directly
- Model 1 recommended "not yet" but acknowledged the value
- Analogy to production: ExpeL distills insights, Claude Code's Auto Dream consolidates, AgentTrek uses VLM evaluators

**Pattern entry format (cross-model synthesis):**

```
[PATTERN-NNN] Title
├── Severity: Critical|Major|Minor
├── Type/Kind: avoid|do|decision|convention|edge_case    ← NEW (model 4 safety recommendation)
├── Scope: GLOBAL | TECH:{name}:{version} | PROJECT:{id} ← NEW
├── Stack/Version: e.g., "Next.js 14+, Supabase"        ← NEW
├── Seen in: N projects
├── Citations: file:line — example + content hash         ← ENHANCED
├── Detection command: ...
├── Prevention rule: ...
├── Architect action: ...
├── Confidence score: 0.0–1.0                            ← NEW
├── Created: date | Last validated: date | Valid until: date ← ENHANCED
├── Status: ACTIVE|STALE|ARCHIVED|DEPRECATED
├── Conflicts_with: [PATTERN-XXX]                        ← NEW
├── Supersedes: [PATTERN-YYY]                            ← NEW
├── Applies_when: condition                              ← NEW
├── Not_for: exclusion condition                         ← NEW
└── Provenance: project, critic session, human/agent, evidence type
```

### 4.2 Reading from Memory (Retrieval)

**Core principle: Replace "load everything" with "query-driven selective retrieval."** ■■■■■

**Current APEX approach (to be replaced):** Architect reads FULL file before planning (Step 0).

**Recommended approach:**

1. **Always load hot tier** — top 10–20 universal safety patterns (auth, RLS, secrets, error handling) ■■■■■
2. **Derive retrieval query** from task plan: stack, framework, risk areas, files to be modified ■■■■■
3. **Query warm tier** via SQLite FTS5 by scope + version + technology + severity → top-k results (k=5–15) ■■■■■
4. **Total injected context ≤ 150 pattern-instructions** ■■■■■
5. **Consider mid-conversation re-injection** of relevant patterns, not just at planning time (model 5 notes Cursor rules degrade as conversation grows) ■■□□□

**Evidence basis:**
- ERL: LLM retrieval with k=20 outperformed full-load and embedding retrieval
- SWE-ContextBench: 204-word summaries >> 24,765-word trajectories
- Repoformer: selective retrieval delivers up to 70% inference speedup without quality loss
- Context Rot: every additional token degrades output quality
- IFScale: models show primacy bias (earlier instructions get higher compliance)

### 4.3 Updating Memory (Staleness Detection)

**APEX's current verify-learnings.sh (file existence check) is necessary but far from sufficient.** ■■■■■

**Recommended multi-layer validation:**

| Layer | Check | Catches | Implementation |
|-------|-------|---------|----------------|
| 1. File existence | Does cited file still exist? | Gross deletions | Current verify-learnings.sh |
| 2. Content hash | Has cited code changed? (hash comparison) | Code modifications | Hash stored code blocks, compare on validation |
| 3. Symbol/line check | Does cited symbol/line still match? | Refactoring, renaming | Symbol extraction + comparison |
| 4. Version match | Does project still use the framework version? | Framework upgrades | Check package.json/lockfile against pattern scope |
| 5. Usage outcomes | When pattern was applied, did tasks succeed? | Pattern correctness | Track success/failure ratios per pattern |
| 6. Temporal decay | Has pattern been used/validated recently? | General staleness | Confidence score with configurable half-lives |

**Production reference:** GitHub Copilot Memory validates citations against the current branch before use (model 4 highlight). This should be APEX's target standard.

### 4.4 Deleting from Memory (Forgetting)

**Core principle: Aggressive, graduated forgetting is a feature, not a bug.** ■■■■■

**ERL's strongest evidence:** Performance peaks at 40–60 heuristics, then actively degrades. Keeping stale patterns is not "safe" — it reduces performance.

**Recommended graduated lifecycle:** ■■■■□ (4 models)

```
ACTIVE → STALE → ARCHIVED → DELETED
```

- ACTIVE: Pattern is valid, confident, recently verified
- STALE: Pattern has not been used/validated within its TTL, or cited code has changed. Flagged for review. Still retrievable but deprioritized.
- ARCHIVED: Pattern failed validation, was superseded, or expired. Kept for audit trail. Never auto-loaded.
- DELETED: Removed after extended archival period with no revival.

**Decay schedules (synthesized from models 4 and 5, no peer-reviewed basis):**

| Knowledge Type | Half-Life | Notes |
|----------------|-----------|-------|
| Core safety patterns (auth, RLS, secrets) | No auto-decay | Require explicit human revocation + periodic re-verification |
| Architectural patterns (MVC, DI) | 12–18 months | Slow decay, reinforced by usage |
| Bug/failure patterns | 3–6 months | Version-tagged; invalidated on major version changes |
| Framework/API patterns | 1–3 months | Fast decay; auto-flagged on major version detection |
| Error resolution patterns | 1–2 months | Fastest decay; error messages change between versions |
| Project-specific observations | 14–30 days | Shortest TTL; not promoted without evidence of generalization |

**Important caveat:** No empirical measurement of coding pattern half-lives exists. These are engineering estimates based on framework release cadences and practitioner reports. This is a significant research gap flagged by multiple models.

---

## 5. Memory Integrity and Safety

### 5.1 Threat Landscape

| Attack | Mechanism | Success Rate | Source | Confidence |
|--------|-----------|-------------|--------|------------|
| **MINJA** | Query-only injection of malicious memory records via bridging steps | >95% injection, >70% attack success | Dong et al., NeurIPS 2025 | High (peer-reviewed) |
| **MemoryGraft** | Persistent behavioral drift via poisoned experience retrieval | 9.1% poisoned records → 47.9% of retrievals | Srivastava & He, 2025 | Medium-High |
| **AgentPoison** | Optimized trigger tokens in knowledge bases | 80%+ attack success | Chen et al., NeurIPS 2024 | High (peer-reviewed) |
| **A-MemGuard detector** | LLM-based detection of poisoned entries | **Misses 66%** of poisoned entries | Wei et al., 2025 | High |
| **ToxicSkills** | Malicious agent skills in OpenClaw ecosystem | 76 confirmed malicious skills, 100% combine code + prompt injection | 2025 campaign | Medium |
| **Code-specific CVEs** | Malicious comments (CVE-2025-53773), config files (CVE-2025-54135) | Demonstrated RCE | GitHub/Cursor, 2025 | High |

**Key insight across all models:** Memory poisoning is fundamentally different from prompt injection. Prompt injection is a prank caller; memory poisoning is a sleeper agent — persistent, low-detection, cross-session.

### 5.2 APEX-Specific Vulnerability Assessment

APEX's file-based `apex-learnings.md` has a **smaller attack surface** than shared-user vector DBs (MINJA's primary target), but is **not immune:**

- **Direct modification:** Anyone with git write access can modify the file
- **Indirect poisoning:** A compromised project could cause the critic to write poisoned patterns
- **Vulnerability learning:** If APEX learns from a project with security vulnerabilities, it could "learn" those vulnerabilities as valid patterns
- **Supply chain attack:** Malicious dependencies could contain comments/patterns designed to influence the learning system

### 5.3 Recommended Defense Architecture ■■■■■

**Layer 1: Write Access Control**
- Only Memory Synthesis agent and authorized humans can write to canonical memory
- Task agents and external inputs never write directly
- All writes go through a staging area first

**Layer 2: Provenance Tracking**
- Every pattern records: source session, source files, timestamp, author (human vs agent), confidence, evidence type
- Git commit signing on pattern changes
- Append-only audit log of all memory operations

**Layer 3: Validation Before Activation**
- Human review required before any pattern reaches ACTIVE status in global scope ■■■■■
- Require pattern observed in ≥2 independent projects for global tier promotion ■■■■□
- Dual-source validation: pattern must be confirmed by tests, static analysis, or independent observation

**Layer 4: Type Separation (model 4 unique contribution)**
- **Critical:** Separate `memory_kind = avoid|do|decision|convention|edge_case`
- Without this, an agent can learn "project X had auth bypass" as something to *follow* rather than *prevent*
- This is not just convenience — it's a safety-critical distinction

**Layer 5: Isolation & Privacy** ■■■■■
- Project-scoped by default; never leak patterns between client boundaries
- Promotion to global requires: sanitization (strip file paths, variable names, API keys, business logic), evidence of generalization across projects, and human approval
- Three-tier scoping: `PROJECT` → `ORG/TENANT` → `GLOBAL`

### 5.4 Conflict Resolution

**Recommended approach (synthesized from models 2 and 4):**

Add metadata fields: `conflicts_with`, `supersedes`, `applies_when`, `not_for`

Priority resolution order:
1. Human-curated patterns always win
2. Higher confidence score
3. More recent (at equal confidence)
4. Higher use-count (at equal recency)
5. Project-specific overrides global
6. **Flag unresolved conflicts for human review** — never auto-resolve silently ■■■■■

---

## 6. Learning Loop Patterns

### 6.1 Reflexion Pattern

**How it works:** Agent attempts task → evaluator scores → self-reflection generates verbal feedback → feedback stored in episodic memory → agent retries with reflection as context.

**Measured results:**
- HumanEval: +11pp (80→91%)
- ALFWorld: +22pp over 12 iterations
- WebShop: **0% improvement** (failure case — exploration-heavy tasks)

**APEX alignment:** APEX's reflexion loop (critic FAIL → reflexion brief → retry with different approach, max 3 iterations) closely matches the Reflexion architecture. The 3-iteration cap is supported by evidence: 2–3 iterations is optimal; higher counts risk mode collapse (agents repeat the same errors in different templates).

**Critical nuance (model 5 unique contribution):** Multi-Agent Reflexion (MAR) found that when the same model generates, evaluates, and revises, corrections follow narrow, repetitive templates. **The critic's pattern detection should be evaluated by a separate reasoning pathway** to avoid self-reinforcing errors.

### 6.2 Experience Accumulation

**Best pattern: Store distilled reusable abstractions, not raw transcripts.** ■■■■■

- Voyager: executable code skills → compositional reuse → 3.3–15.3× improvements
- ExpeL: natural-language insights → cross-task transfer → +7pp on completely different benchmark
- SWE-ContextBench: 204-word summaries >> 24,765-word trajectories
- ERL: distilled heuristics outperform raw trajectories at every experience count
- AgentTrek: structured tutorial-derived instructions → 230% performance increase

**Key distinction:** Episodic memory (what happened) is useful for within-session debugging. Semantic memory (what we learned) is what should be persisted to cross-project patterns. APEX should store distilled semantic patterns, with episodic citations providing verifiability.

### 6.3 Collaborative Learning

**Evidence is limited but directionally positive:**
- Letta supports shared memory blocks across agents
- DeLAMA (2024): 98.8% MSE reduction through collaborative knowledge sharing
- Collaborative Memory paper (2025): accuracy >0.90 with shared memory vs lower with isolated
- A-MemGuard tested consensus-based validation in multi-agent scenarios

**For APEX:** The architect-critic separation already creates collaborative learning. Adding a Memory Synthesis agent makes it a three-role collaboration (critic discovers, synthesis distills, architect applies). Full multi-agent shared memory is Phase 2+.

### 6.4 Continuous vs. Batch Learning

**Consensus: Continuous capture, batch promotion.** ■■■■■

Every task can produce raw observations, but only after a synthesis/verification pass do insights get promoted to canonical memory. This reduces noise while preserving knowledge.

**Implementation for APEX:**
1. Continuous: Critic logs observations to staging area on every FAIL
2. Batch: Memory Synthesis agent runs post-project (or every N tasks) to:
   - Cluster similar observations
   - Distill into structured patterns
   - Validate via tests/citations
   - Assign scope and confidence
   - Write to apex-learnings via controlled interface
3. Human review: Required for global tier promotion

---

## 7. Production System Analysis

### 7.1 Key Insights from Production Systems

| System | Memory Model | Key Insight for APEX | Source Quality |
|--------|-------------|---------------------|----------------|
| **Letta/MemGPT** | Tiered: core blocks (always visible) + archival (vector-searchable) + recall (conversation). Agent self-manages via tool calls. | Pagination fatigue is real — agents stop searching before exhausting results. Always-visible core memory is essential. | High (peer-reviewed + production) |
| **Claude Code** | Hierarchical CLAUDE.md (global → repo → directory) + Auto Dream consolidation + confidence decay. Active memories + unlimited state.json. Progress decays 7 days, context 30 days, architecture never decays. | **Auto Dream is the consolidation mechanism APEX needs.** Without it, "contradictory entries pile up, relative dates lose meaning." | Medium-High (engineering blog) |
| **Cursor** | .cursorrules files, version-controlled, path-scoped. Static injection. | Rules "get ignored after a few messages" as context fills. Static one-time injection is insufficient. | Medium (user reports) |
| **Aider** | Tree-sitter-based repo map with PageRank for file importance. ~1,000 tokens structural context. | Structural memory (what the code looks like now) complements experiential memory (what we learned). APEX needs both. | Medium-High (open source) |
| **GitHub Copilot Memory** | Repo-scoped, citation-backed, validated against current branch before use, 28-day TTL with refresh on successful validation. No cross-user learning. | **Closest production model to what APEX should become.** Repo-scoped, citation-validated, auto-expiring. | High (official docs) |
| **Sourcegraph Cody** | Moved from embeddings → native keyword search for enterprise. Code graph + symbol search. Shared prompts at team scale. | **Cody abandoning embeddings** is strong signal that keyword search suffices when the consumer is an LLM that can construct precise queries. | Medium-High (production) |

### 7.2 Human Knowledge Management Parallels

The most effective human knowledge practices map directly to agent memory:

- **ADRs (Architectural Decision Records)** → APEX's architectural patterns with decisions and rationale
- **Post-mortem culture** → APEX's critic FAIL → distilled failure patterns
- **Static analysis rule evolution** (SonarQube quality profiles) → APEX's pattern lifecycle with statuses, inheritance, and deprecation
- **README/CONTRIBUTING** → Project-scoped conventions
- **Linter rules** → Closest human analog to automated pattern memory: curated, versioned, deprecated

**Key insight:** Experienced developers don't maintain flat, unordered lists of past bugs. They maintain structured, contextual, evolving knowledge. APEX should do the same.

---

## 8. APEX-Specific Recommendations

### Design Questions — Evidence-Based Answers

#### Q1: Is apex-learnings.md the right format?

**Recommendation: Yes, as canonical human-readable layer — but not as the only memory layer.** ■■■■■
**Confidence: High**

Keep markdown as source-of-truth for transparency, curation, and git compatibility. But enforce strict size limits and add a retrieval layer (SQLite) for scale. Split into scoped files: `global/security.md`, `stack/nextjs15.md`, `project/<name>/conventions.md`.

Trade-offs: Maximum transparency and curation ability, but requires additional tooling for search and staleness management.

#### Q2: Should APEX add vector DB or SQLite?

**Recommendation: SQLite + FTS5 now. Vector DB only later and only as optional recall layer.** ■■■■■
**Confidence: High for SQLite; Medium for vector DB later**

Claude Code team discarded vector DBs. Sourcegraph Cody moved away from embeddings. ERL showed LLM-based retrieval > embedding retrieval. SQLite provides provenance, temporal queries, FTS, and ACID with zero infrastructure. sqlite-vec can add optional semantic search in the same file if needed.

Trade-offs: SQLite adds tooling complexity but provides all missing capabilities. Vector DB adds infrastructure cost for marginal retrieval improvement.

#### Q3: What should trigger writing to memory?

**Recommendation: Validated failures + recurrence + human curation. NOT every critic FAIL.** ■■■■■
**Confidence: High**

Write triggers:
- Critic FAIL with severity ≥ Major AND confirmed by test/verifier/static-analysis
- Pattern observed in ≥2 independent projects (for global promotion)
- Silent Auditor CRITICAL detection
- Human-added entries
- Post-project synthesis batch

Everything else → staging area only.

Trade-offs: Slower pattern accumulation, but dramatically lower pollution and poisoning risk.

#### Q4: How should the architect retrieve patterns?

**Recommendation: Hot set (always loaded) + selective top-k retrieval by task context.** ■■■■■
**Confidence: High**

1. Always load 10–20 universal safety patterns (hot tier)
2. Derive retrieval query from task: stack, framework, risk areas, touched files
3. Query SQLite FTS5 for matching patterns in relevant scope → top 5–15 results
4. Total injected ≤ 150 pattern-instructions
5. Re-inject relevant patterns mid-conversation if conversation grows long

Trade-offs: Requires retrieval tooling and index maintenance, but prevents context bloat and improves relevance.

#### Q5: How should patterns be validated?

**Recommendation: Multi-layer validation far beyond file-existence checks.** ■■■■■
**Confidence: High**

Layers: file existence → content hash → symbol/line check → version match → usage outcomes → temporal decay. Target standard: Copilot Memory's citation-against-current-branch validation. Run pattern tests in CI when possible.

Trade-offs: More complex operationally, but essential for safe memory at scale.

#### Q6: Should memory be global or project-scoped?

**Recommendation: Project-scoped by default, global by explicit promotion only.** ■■■■■
**Confidence: High**

Three-tier scoping:
- `PROJECT`: Default. Repo-specific patterns.
- `ORG/TENANT`: Shared within one client/organization.
- `GLOBAL`: Universal safety patterns only. Requires sanitization + evidence of generalization + human approval.

Trade-offs: Less immediate cross-project reuse, dramatically less privacy leakage and negative transfer.

#### Q7: Privacy/isolation handling?

**Recommendation: Strict isolation with sanitization pipeline for promotion.** ■■■■■
**Confidence: High**

Promotion from project → global requires stripping: file paths, variable names, API keys, business logic, client-specific architecture. Model 4 recommends treating this as an LLM-driven abstraction layer that strips identifying information before generalization.

#### Q8: Decay/expiry mechanism?

**Recommendation: Graduated lifecycle (ACTIVE→STALE→ARCHIVED→DELETED) with type-specific decay.** ■■■■■
**Confidence: Medium** (no peer-reviewed basis for specific TTLs)

See Section 4.4 for detailed decay schedule. Core safety patterns never auto-decay. Framework patterns decay fastest. Usage and successful validation refresh confidence.

#### Q9: Pattern conflict handling?

**Recommendation: Metadata-driven resolution with human escalation.** ■■■■■
**Confidence: High**

Add: `conflicts_with`, `supersedes`, `applies_when`, `not_for`. Resolution priority: human > confidence > recency > frequency > scope specificity. Never auto-resolve silently.

#### Q10: Dedicated Memory Synthesis agent?

**Recommendation: Yes — implement as periodic "dream cycle" inspired by Claude Code's Auto Dream.** ■■■■□
**Confidence: High** (4 of 5 models recommend)

Not a persistent agent, but a scheduled task that runs post-project or every N tasks. Functions: cluster similar incidents → distill into patterns → validate → assign scope/confidence → write to apex-learnings → flag conflicts → prune stale entries → maintain hot tier size.

Model 1 said "not yet" but acknowledged value. Models 3, 4, 5 strongly recommended. Evidence from ExpeL, AgentTrek, Claude Code Auto Dream, and A-Mem all support separating experience capture from memory synthesis.

---

## 9. Complete Recommended Architecture for APEX v6→v7

```
┌──────────────────────────────────────────────────────────────────┐
│                    APEX v7 Memory Architecture                    │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  HOT TIER: Scoped Markdown Files (Always Loaded)            │ │
│  │  ├── global/safety-critical.md (≤20 universal patterns)     │ │
│  │  ├── stack/{name}-{version}.md (tech-specific, ≤30 each)    │ │
│  │  └── project/{name}/patterns.md (project-specific, ≤50)     │ │
│  │  Total loaded per task: ≤100 patterns (≤200 lines)          │ │
│  │  Format: Structured markdown with citations, severity,       │ │
│  │          type (avoid|do|decision|convention|edge_case),       │ │
│  │          scope, confidence, validation status                 │ │
│  │  Access: Architect loads at Step 0 (always)                  │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                              ↕                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  WARM TIER: SQLite + FTS5 (Retrieved on Demand)             │ │
│  │  ├── patterns table (id, title, severity, type, scope,      │ │
│  │  │   stack, version_range, citations[], content_hashes[],    │ │
│  │  │   detection_cmd, prevention_rule, architect_action,       │ │
│  │  │   confidence, use_count, success_rate,                    │ │
│  │  │   created_at, last_validated, last_used, valid_until,     │ │
│  │  │   status, provenance, conflicts_with[], supersedes[],     │ │
│  │  │   applies_when, not_for)                                  │ │
│  │  ├── evidence table (pattern_id, project, session, files,    │ │
│  │  │   test_results, author_type, timestamp)                   │ │
│  │  ├── validations table (pattern_id, date, method, result,    │ │
│  │  │   commit_hash, branch)                                    │ │
│  │  ├── audit_log (operation, pattern_id, before, after,        │ │
│  │  │   actor, timestamp)                                       │ │
│  │  ├── FTS5 virtual table for full-text pattern search         │ │
│  │  └── Optional: sqlite-vec for semantic similarity (Phase 2)  │ │
│  │  Size: ≤500 active patterns                                  │ │
│  │  Access: Architect queries by task context (top 5–15)        │ │
│  │  Human-readable export: auto-generated markdown per scope    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                              ↕                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  COLD TIER: Archive (Never Auto-Loaded)                     │ │
│  │  ├── Deprecated, expired, superseded patterns               │ │
│  │  ├── Full provenance and audit trail retained                │ │
│  │  └── Searchable on explicit request only                    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  WRITE PIPELINE                                              │ │
│  │  1. Critic/Auditor detects pattern → raw observation log     │ │
│  │  2. Memory Synthesis agent (periodic "dream cycle"):         │ │
│  │     - Clusters similar observations                          │ │
│  │     - Distills into structured patterns                      │ │
│  │     - Validates via tests/citations/static analysis          │ │
│  │     - Assigns scope, type, confidence                        │ │
│  │     - Checks for conflicts with existing patterns            │ │
│  │     - Writes to Warm Tier (SQLite)                           │ │
│  │  3. Human review gate for ACTIVE status                      │ │
│  │  4. Promotion to Hot Tier requires:                          │ │
│  │     - Seen in ≥2 projects (for global)                       │ │
│  │     - Confidence ≥ threshold                                 │ │
│  │     - Human approval (for global scope)                      │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  READ PIPELINE                                               │ │
│  │  1. Always load Hot Tier safety patterns                     │ │
│  │  2. Load Hot Tier patterns matching project scope+stack      │ │
│  │  3. Derive retrieval query from task plan                    │ │
│  │  4. Query Warm Tier: scope → version → FTS → top-k (5–15)   │ │
│  │  5. Total injected ≤ 150 pattern-instructions                │ │
│  │  6. Mid-conversation re-injection if context grows long      │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  STALENESS & DECAY                                           │ │
│  │  On session start:                                           │ │
│  │  ├── verify-learnings.sh (file existence)                    │ │
│  │  ├── Content hash validation (cited code unchanged?)         │ │
│  │  ├── Version match check (framework version compatible?)     │ │
│  │  └── Decay calculation (confidence -= f(time, type))         │ │
│  │  Periodic (post-project or weekly):                          │ │
│  │  ├── Dream cycle: merge, normalize, prune, promote           │ │
│  │  ├── Archive patterns below confidence threshold             │ │
│  │  ├── Flag version-mismatched patterns for review             │ │
│  │  └── Run pattern-specific detection commands in CI           │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  SAFETY LAYER                                                │ │
│  │  ├── Write access control: only Synthesis agent + humans     │ │
│  │  ├── Provenance on every pattern (full chain of evidence)    │ │
│  │  ├── Type separation: avoid ≠ do (critical for safety)       │ │
│  │  ├── Input sanitization: treat all repo content as untrusted │ │
│  │  ├── Git commit signing on pattern changes                   │ │
│  │  ├── Client/tenant isolation (never leak between clients)    │ │
│  │  ├── Sanitization pipeline for scope promotion               │ │
│  │  ├── Anomaly detection: flag unusual patterns                │ │
│  │  └── Append-only audit log of all memory operations          │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  SCALE PLAN                                                  │ │
│  │  0–30 projects: Hot Tier only (current .md, keep it simple)  │ │
│  │  30–100 projects: Add Warm Tier (SQLite + FTS5)              │ │
│  │  100–200 projects: Add Cold Tier archiving + dream cycle     │ │
│  │  200+ projects: Optional sqlite-vec for semantic retrieval   │ │
│  │  500+ projects: Re-evaluate — consider lightweight KG for    │ │
│  │                  structural context (Phase 3)                │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 10. Quantitative Findings — All Numbers, Cross-Verified

### Learning Improvements

| Metric | Value | Source | Verified By |
|--------|-------|--------|-------------|
| Reflexion HumanEval pass@1 | 80% → 91% (+11pp) | Shinn et al., NeurIPS 2023 | 5/5 models |
| Reflexion ALFWorld success | ~75% → ~97% (+22pp) | Shinn et al., NeurIPS 2023 | 5/5 models |
| Reflexion HotPotQA | ~32% → ~52% (+20pp) | Shinn et al., NeurIPS 2023 | 5/5 models |
| Reflexion WebShop | 0% improvement (failure) | Shinn et al., NeurIPS 2023 | 1/5 models |
| Voyager unique items | 3.3× vs baselines (63 vs ~19) | Wang et al., NeurIPS 2023 | 5/5 models |
| Voyager tech tree speed | up to 15.3× faster | Wang et al., NeurIPS 2023 | 5/5 models |
| Voyager cross-world transfer | 100% tasks solved (baselines: 0%) | Wang et al., NeurIPS 2023 | 2/5 models |
| ExpeL ALFWorld (single attempt vs Reflexion retries) | 59% vs 54% | Zhao et al., AAAI 2024 | 4/5 models |
| ExpeL cross-task transfer (HotPotQA→FEVER) | 63% → 70% (+7pp) | Zhao et al., AAAI 2024 | 4/5 models |
| ERL Gaia2 improvement | 48.3% → 56.1% (+7.8pp) | ERL, March 2026 (preprint) | 2/5 models |
| ERL optimal heuristic count | Peak at 40–60, degrades beyond | ERL, March 2026 | 2/5 models |
| ERL: LLM retrieval vs embedding | 56.1% vs 53.3% | ERL, March 2026 | 2/5 models |
| SWE-ContextBench: no experience | 26.26% resolution | Zhu et al., 2026 | 3/5 models |
| SWE-ContextBench: oracle summary reuse | 34.34% (+8.08pp) | Zhu et al., 2026 | 3/5 models |
| SWE-ContextBench: free summary reuse | 22.22% (-4.04pp, NEGATIVE) | Zhu et al., 2026 | 3/5 models |
| SWE-ContextBench: summary size vs trajectory | 204.5 words vs 24,765 words | Zhu et al., 2026 | 3/5 models |
| AgentTrek performance increase | 230% with structured instructions | Xu et al., ICLR 2025 | 2/5 models |
| AgentTrek trajectory cost | $0.551 per trajectory | Xu et al., ICLR 2025 | 2/5 models |
| Copilot PR merge rate increase | +7pp | Microsoft Ignite 2025 | 1/5 models |
| Cross-project defect prediction success | <3.4% of 622 experiments | Zimmermann et al., 2009 | 1/5 models |

### Memory Architecture Metrics

| Metric | Value | Source | Verified By |
|--------|-------|--------|-------------|
| CLAUDE.md <200 lines application rate | ~92% | SFEIR blog (not peer-reviewed) | 5/5 models cite |
| CLAUDE.md >400 lines application rate | ~71% | SFEIR blog (not peer-reviewed) | 5/5 models cite |
| IFScale: best model at 500 instructions | 68% accuracy | Jaroslawicz et al., 2025 | 2/5 models |
| IFScale: practical instruction ceiling | ~150 instructions | Jaroslawicz et al., 2025 | 3/5 models |
| Lost in the Middle degradation | >30% for mid-positioned info | Liu et al., 2023 | 2/5 models |
| SemanticForge KG precision vs BM25 | 73% vs 51% (+22pp) | Zhang et al., 2025 | 5/5 models |
| SemanticForge Pass@1 improvement | +15.6pp (→49.8%) | Zhang et al., 2025 | 3/5 models |
| SemanticForge schematic error reduction | 89% (49.8% hallucination reduction) | Zhang et al., 2025 | 2/5 models |
| SQLite + FTS5 retrieval latency | <3ms total | Multiple implementations | 2/5 models |
| Engram (ACT-R) retrieval latency | ~90ms | Reddit/implementation | 1/5 models |
| Mem0 vs OpenAI Memory accuracy | +26% on LOCOMO | Mem0 paper, 2025 | 1/5 models |
| Mem0 token savings vs full context | 90% reduction | Mem0 paper, 2025 | 1/5 models |
| Repoformer selective retrieval speedup | up to 70% without quality loss | Wu et al., ICML 2024 | 2/5 models |
| CLARC: embeddings vs BM25 MRR for code | ~79–87 vs ~8–16 | CLARC, 2026 | 1/5 models |

### Security Metrics

| Metric | Value | Source | Verified By |
|--------|-------|--------|-------------|
| MINJA injection success rate | >95% (avg 98.2%) | Dong et al., NeurIPS 2025 | 5/5 models |
| MINJA attack success rate | >70% (avg 76.8%) | Dong et al., NeurIPS 2025 | 5/5 models |
| MemoryGraft: poisoned record % → retrieval % | 9.1% → 47.9% | Srivastava & He, 2025 | 2/5 models |
| A-MemGuard detector miss rate | 66% of poisoned entries | Wei et al., 2025 | 4/5 models |
| A-MemGuard defense effectiveness | >95% ASR reduction | Wei et al., 2025 | 2/5 models |
| AgentPoison attack success | 80%+ | Chen et al., NeurIPS 2024 | 1/5 models |
| Stale architectural decisions | 20–25% in audits | FPF paper, 2026 | 2/5 models |
| Stale decisions caught reactively | 86% | FPF paper, 2026 | 2/5 models |
| Copilot Memory auto-delete TTL | 28 days | GitHub docs | 2/5 models |

### Production Benchmarks

| Metric | Value | Source | Verified By |
|--------|-------|--------|-------------|
| Boris Cherny's CLAUDE.md size | ~100 lines | Public disclosure, Jan 2026 | 3/5 models |
| Claude Code system prompt instructions | ~50 instructions | HumanLayer analysis, 2025 | 2/5 models |
| Cursor .cursorrules char limit | 6,000 per file, 12,000 total | Cursor docs | 1/5 models |
| Aider repo map token budget | ~1,000–4,096 tokens | Aider docs | 3/5 models |
| Claude memory synthesis cadence | Every 24 hours | Claude docs | 1/5 models |
| Claude Code progress memory decay | 7 days | Engineering blog | 1/5 models |
| Claude Code context memory decay | 30 days | Engineering blog | 1/5 models |
| Claude Code architecture memory decay | Never (persistent) | Engineering blog | 1/5 models |

---

## 11. Research Gaps and Limitations

The following significant gaps were identified across the research:

1. **No direct measurement of cross-project learning in coding agents exists.** All studies test within-domain or within-task-type learning. No study measures "patterns learned from Supabase project A help on Supabase project B."

2. **No measured half-life for coding patterns.** How long before a Next.js App Router pattern becomes stale? No data exists. All decay recommendations are engineering estimates.

3. **No measurement of technology-version-specific negative transfer.** All models agree this is a critical risk, but no study quantifies the degradation when, e.g., Next.js 14 patterns are applied to a Next.js 15 project.

4. **CLAUDE.md effectiveness numbers (92%/71%) are not peer-reviewed.** IFScale provides supporting evidence but uses different methodology.

5. **ERL is a very recent preprint (March 2026).** Highly relevant but not yet peer-reviewed.

6. **Memory poisoning research focuses on shared-user systems.** APEX's single-developer file-based approach has a smaller attack surface than studied systems.

7. **Production system information is mostly anecdotal.** Blog posts, docs, and practitioner accounts — not peer-reviewed research.

8. **No study compares SQLite vs vector DB vs KG specifically for coding pattern memory.** The SQLite recommendation is based on convergence of engineering requirements, not direct comparison.

---

## 12. Complete Source List

### Peer-Reviewed Papers
1. Shinn, N. et al. "Reflexion: Language Agents with Verbal Reinforcement Learning." NeurIPS 2023. arXiv:2303.11366
2. Wang, G. et al. "Voyager: An Open-Ended Embodied Agent with Large Language Models." NeurIPS 2023. arXiv:2305.16291
3. Zhao, A. et al. "ExpeL: LLM Agents Are Experiential Learners." AAAI 2024. arXiv:2308.10144
4. Dong, S. et al. "Memory Injection Attacks on LLM Agents via Query-Only Interaction (MINJA)." NeurIPS 2025. arXiv:2503.03704
5. Park, J.S. et al. "Generative Agents: Interactive Simulacra of Human Behavior." UIST 2023. arXiv:2304.03442
6. Chen, Z. et al. "AgentPoison." NeurIPS 2024.
7. Xu, Y. et al. "AgentTrek." ICLR 2025 Spotlight.
8. Zimmermann, T. et al. "Cross-project defect prediction." ESEC/FSE 2009.
9. Wu, L. et al. "Repoformer: Selective Retrieval for Repository-Level Code Completion." ICML 2024.

### Preprints and Technical Reports
10. ERL (Anonymous). "Experiential Reflective Learning for Self-Improving LLM Agents." March 2026. arXiv:2603.24639
11. Packer, C. et al. "MemGPT: Towards LLMs as Operating Systems." 2023. arXiv:2310.08560
12. Wei, Q. et al. "A-MemGuard: Proactive Defense Framework." 2025. arXiv:2510.02373
13. Hu, Y. et al. "Memory in the Age of AI Agents: A Survey." December 2025. arXiv:2512.13564
14. Srivastava & He. "MemoryGraft." December 2025.
15. Zhu, R. et al. "SWE-ContextBench." 2026. arXiv:2602.08316
16. Jaroslawicz, D. et al. "How Many Instructions Can LLMs Follow at Once? (IFScale)." 2025. arXiv:2507.11538
17. Hong, K. et al. "Context Rot." Chroma Research, 2025.
18. Zhang, Y. et al. "SemanticForge." November 2025. arXiv:2511.07584
19. Sunil, B.D. et al. "Memory Poisoning Attack and Defense on Memory Based LLM-Agents." January 2026. arXiv:2601.05504
20. Liu, N. et al. "Lost in the Middle." Stanford/UW, 2023.
21. Renze, M. "Self-Reflection in LLM Agents." 2024. arXiv:2405.06682
22. Mem0 paper. arXiv:2504.19413

### Production Systems and Documentation
23. Letta/MemGPT documentation. docs.letta.com
24. Anthropic. "Effective Context Engineering for AI Agents." anthropic.com/engineering
25. Anthropic. Claude Code Best Practices. code.claude.com/docs
26. Cherny, B. Claude Code creator workflow disclosure. January 2026.
27. GitHub. "Copilot Memory." docs.github.com/copilot/concepts/agents/copilot-memory
28. Cursor documentation. cursor.com/docs/rules
29. Aider documentation. aider.chat/docs/repomap.html
30. HumanLayer. "Writing a Good CLAUDE.md." humanlayer.dev/blog
31. Sourcegraph Cody documentation.
32. Amazon Q Developer documentation. docs.aws.amazon.com/amazonq
33. SonarQube Quality Profiles. docs.sonarsource.com
34. LangChain/LangGraph memory documentation. docs.langchain.com
35. OWASP. Agentic AI Top 10 — ASI06. 2026.
36. MITRE ATLAS. AML.T0080. Memory Poisoning.
37. Claude Help Center. Memory and Projects documentation.

### Surveys and Cross-References
38. Multiple CPDP studies (TriStage-CPDP, SCAG-LSTM, TFIA, RH-CPDP). 2024–2025.
39. Wohlrab, R. ADR action-research paper. ECSA 2024.
40. CLARC/CoIR benchmarks for code retrieval. 2026. arXiv:2603.04484
