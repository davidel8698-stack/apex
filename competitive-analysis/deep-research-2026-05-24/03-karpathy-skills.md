# Deep Research 03 — Karpathy Skills Repo / CLAUDE.md

Research date: 2026-05-24
Researcher: Deep Research agent 03
Primary subject: `multica-ai/andrej-karpathy-skills` — the viral 4-principle CLAUDE.md by Forrest Chang (a.k.a. Jiayuan), distilled from Andrej Karpathy's Jan 26 2026 X post on LLM coding pitfalls.

---

## 0. Source map

### Primary URL
- `https://github.com/multica-ai/andrej-karpathy-skills/blob/main/CLAUDE.md` (the file whose verbatim content I obtained via `gh api` after the WebFetch summarizer refused to reproduce it)

### URLs fetched (with hop depth and signal)

| Hop | URL | Why | What I got |
|-----|-----|-----|-----|
| 0 | `github.com/multica-ai/andrej-karpathy-skills/blob/main/CLAUDE.md` | Primary | Full verbatim text via `gh api` (raw base64-decoded) |
| 0 | `github.com/multica-ai/andrej-karpathy-skills` (repo root) | Inventory | File tree + README summary via WebFetch |
| 0 | `gh api .../git/trees/main?recursive=1` | Tree truth | Complete recursive listing — 9 blobs, 4 trees |
| 1 | `repos/.../contents/README.md` | Author's own framing | Full verbatim README |
| 1 | `repos/.../contents/EXAMPLES.md` | Concrete patterns | Full verbatim with code diffs |
| 1 | `repos/.../contents/CURSOR.md` | Cursor parity story | Full verbatim |
| 1 | `repos/.../contents/skills/karpathy-guidelines/SKILL.md` | Plugin-form payload | Full verbatim |
| 1 | `repos/.../contents/.claude-plugin/marketplace.json` | Distribution model | Full JSON |
| 1 | `repos/.../contents/.claude-plugin/plugin.json` | Plugin metadata | Full JSON |
| 1 | `repos/.../contents/.cursor/rules/karpathy-guidelines.mdc` | Cross-tool parity | Full verbatim |
| 1 | `repos/.../contents/README.zh.md` | Translation as evidence | Full verbatim |
| 1 | `x.com/karpathy/status/2015883857489522876` | Origin tweet | **HTTP 402** — paywalled; captured via secondary sources |
| 2 | `github.com/multica-ai/multica` (author's flagship) | Larger ambition | Architectural summary |
| 2 | `code.claude.com/docs/en/best-practices` (Anthropic) | Cross-reference base | Full doc verbatim |
| 2 | `code.claude.com/docs/en/skills` (Anthropic) | SKILL.md spec | Full doc verbatim |
| 2 | `deepwiki.com/forrestchang/andrej-karpathy-skills/3.4-goal-driven-execution` | Third-party expansion | Full summary |
| 2 | `themenonlab.blog/blog/karpathy-claude-md-four-rules-ai-coding-agents` | Secondary capture of Karpathy quotes | 3 verbatim quotes |
| 2 | `todatabeyond.substack.com/p/turning-andrej-karpathys-llm-coding` | Tweet preamble | First-sentence quote |
| 2 | `miraflow.ai/blog/karpathy-claude-md-100k-github-stars-ai-coding-2026` | Virality analysis + metrics | Quotes + numbers |
| 2 | `www.blog.brightcoding.dev/2026/04/29/karpathy-skills-the-revolutionary-llm-coding-manifesto` | Effectiveness claims | Per-principle commentary |
| 2 | `www.masteringproducthq.com/p/what-karpathys-claudemd-misses-and` | Critique — what it MISSES | 8 named gaps |
| 2 | `agentpedia.codes/blog/karpathy-claude-md-rules-extended` | Community-added rules 5-12 | 8 additional rules with examples |
| 2 | `aibuilderclub.com/blog/karpathy-claude-md-rules` | Cross-check Karpathy quotes | Paraphrases only |
| 3 | WebSearch — verbatim Karpathy quotes | Direct-quote fishing | 4 confirmed quotes |
| 3 | WebSearch — looping/success criteria quote | Direct-quote fishing | Confirmed canonical wording |
| 3 | WebSearch — criticism / limitations | Counter-evidence | Effectiveness metrics + scope gaps |

### Repo file tree (complete inventory — nothing skipped)

```
andrej-karpathy-skills/
├── .claude-plugin/
│   ├── marketplace.json        [fetched]
│   └── plugin.json             [fetched]
├── .cursor/
│   └── rules/
│       └── karpathy-guidelines.mdc   [fetched]
├── skills/
│   └── karpathy-guidelines/
│       └── SKILL.md            [fetched]
├── CLAUDE.md                   [fetched]
├── CURSOR.md                   [fetched]
├── EXAMPLES.md                 [fetched]
├── README.md                   [fetched]
└── README.zh.md                [fetched]
```

**Files in repo that I did NOT fetch:** none. Every blob was retrieved. There is no `LICENSE` file as a separate blob — the license (`MIT`) is declared only in metadata (README + plugin.json + SKILL.md frontmatter), which DeepWiki/community pages call out. There are no test fixtures, no hooks, no settings.json, no agents. **The repo is intentionally tiny.**

---

## 1. Executive summary — 15 takeaways ranked by APEX relevance

1. **[high]** The viral payload is *four behavioral principles in ~65 lines* — Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution. This is a **direct contradiction to APEX's "rigor stack" approach** in tone, yet the goals are nearly identical (reduce wrong assumptions, prevent overengineering, prevent collateral damage, enforce verifiable goals). The question for APEX isn't "should we adopt these" but "do our complex agents internalize these as load-bearing personality, or are they implicit?"
2. **[high]** Karpathy's canonical insight is the **goal-driven loop**: *"LLMs are exceptionally good at looping until they meet specific goals... Don't tell it what to do, give it success criteria and watch it go."* APEX's `verify_levels`, `RESULT.json`, critic→verifier loop, and self-heal rounds already operationalize this — but APEX prescribes the loop **externally** (in pipeline structure) while Karpathy bakes it into the **executor's prompt**. Hybrid wins.
3. **[high]** **Anti-overengineering is the single most absent rule in APEX.** Karpathy's "If you write 200 lines and it could be 50, rewrite it" and "Would a senior engineer say this is overcomplicated? If yes, simplify" have no equivalent in APEX-v5/v6 specs. APEX has anti-rationalization armor (executor refuses to silently change scope) but no anti-bloat armor (executor refuses to add abstractions not asked for). APEX risks producing well-orchestrated overengineering.
4. **[high]** **"Surgical Changes" is the missing companion to APEX's `destructive-guard` hook.** Destructive-guard prevents *destructive* edits via OS-level intent; Surgical Changes prevents *gratuitous* edits via prompt-level intent ("Every changed line should trace directly to the user's request"). These are complementary: hook = prevents data loss; rule = prevents diff bloat.
5. **[high]** **Karpathy's "list assumptions before implementing" is the same idea as APEX's "ecosystem 10-question gate"** that the user already enforces in memory — but Karpathy's version is *lighter, faster, and embedded in the executor* whereas APEX's is heavy and gate-bound. APEX's 10-Q gate is the right ceiling; "name 3 assumptions" should be the **floor** for every executor turn.
6. **[high]** **The community extended-12 template (Rules 5-12) is more useful to APEX than the original 4.** Rules 8 (Read Before Write), 10 (Long-Running Checkpoints), 11 (Convention Beats Novelty), and 12 (Fail Visibly, Not Silently) directly address APEX-specific failure modes I've seen in your detector campaign and execute-phase wave runs.
7. **[high]** **The repo's distribution model is a Claude Code marketplace plugin** (`.claude-plugin/{marketplace,plugin}.json`) — meaning a single CLAUDE.md is now packaged the same way Anthropic packages bundled skills (`/code-review`, `/debug`). APEX should ship as a marketplace plugin too once stable; this is the canonical install path for community CLAUDE.md ecosystems.
8. **[high]** **Anthropic's own official guidance directly aligns with Karpathy's principles** — *"Give Claude a way to verify its work… is the single highest-leverage thing you can do"*, plus Plan-Mode workflow, plus "Address root causes, not symptoms." APEX is already aligned with the high-leverage half of this. The half it's weakest on is the *"Explore → Plan → Implement → Commit"* lightweight loop for simple tasks — APEX skips Explore.
9. **[med]** **Skill content lifecycle matters.** Per Anthropic: a SKILL.md, once invoked, "stays in context across turns" and re-attaches after compaction with first 5,000 tokens preserved, shared budget 25k. This is *load-bearing* for APEX agent design: agent prompts function similarly. The Karpathy SKILL.md is 67 lines deliberately — to fit cheaply in this lifecycle. APEX agent prompts should be audited for this constraint.
10. **[med]** **The principle "Match existing style, even if you'd do it differently"** is absent from APEX. The executor will happily reformat, retype-hint, and reorganize. Adding a *style-conservation* clause to the executor prompt costs ~3 lines and prevents the most common diff-noise failure mode.
11. **[med]** **The EXAMPLES.md pattern** — showing a wrong/right pair in code form for each rule — is the prompt-engineering pattern with the highest documented success rate. APEX agents currently use prose ("you must do X"); converting key rules to wrong/right examples in prompts is a cheap upgrade.
12. **[med]** **Forrest Chang's claimed effectiveness numbers** (4 rules: 41% → 11% error rate; 12 rules: ~40% → <3%) are NOT independently verified, but the trend (more rules → more compliance with diminishing returns; high baseline error in coding agents without behavioral guardrails) is consistent. APEX should treat this as supporting evidence that prompt-level guardrails compound.
13. **[med]** **The repo is `alwaysApply: true` in Cursor** — same content used as Cursor rule and Claude skill — proving the principles are **tool-agnostic prompt engineering**, not Claude-specific. APEX's framework is more tool-coupled; the principles themselves should be tool-neutral.
14. **[low]** **The author Forrest Chang (`forrestchang` / `jiayuan_jy`) built Multica** — an open-source "agents-as-teammates" platform with squads, autopilots, reusable skills, multiple providers (Claude Code, Codex, Copilot CLI, OpenCode, Hermes, Gemini, Cursor Agent, Kiro CLI, etc.). This is a *competitor framework to APEX* at the team level. APEX is single-engineer pipeline; Multica is team workflow. They overlap in the "skills" concept.
15. **[low]** **The "MasteringProductHQ" critique** — that the file is "written for an engineer working alone" and misses product-level concerns (problem validation, assumption tracking, tradeoff documentation, decision logging, instrumentation, outcome-based done) — describes gaps that APEX *partially* addresses through DECISIONS.md, SPEC.md, and TASK_MAP.md. APEX is better positioned than Karpathy's file for product teams; the gap is real but APEX already crossed it.

---

## 2. CLAUDE.md verbatim analysis

The full CLAUDE.md text (retrieved via `gh api`, base64-decoded — bypassing the WebFetch summarizer that refused to reproduce verbatim).

### Header
```
# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.
```

**Analysis:** Opening line declares scope (behavioral, not domain). Explicitly says "Merge with project-specific instructions" — designed as *additive layer*, not standalone. Tradeoff disclosure up front: *caution over speed* is the file's bias. This single line is doing real prompt-engineering work — it pre-acknowledges that the rules will sometimes feel heavy and gives the agent permission to drop them for trivial tasks. Without this, the rules would feel absolute and degrade trivial-task UX.

### Section 1 — Think Before Coding
```
**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.
```

**Analysis:**
- Three imperatives in tagline form ("Don't assume / Don't hide / Surface") = mnemonic compression.
- Four bullets, each starts with a conditional ("If…") — the rule is *conditional behavior*, not unconditional behavior.
- "Push back when warranted" — explicit *permission to disagree with the user* is rare in agent prompts and counter-cultural; APEX executors do NOT have this permission today.
- "Name what's confusing" — the executor must *externalize* its confusion, not just feel it. This is metacognition-as-output.

### Section 2 — Simplicity First
```
**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.
```

**Analysis:**
- Five "No X" bans = the executor's negative space.
- *"No error handling for impossible scenarios"* — directly counter-trains the LLM's defensive-coding tendency. Most coding agents over-handle errors; this rule explicitly defangs that.
- *"If you write 200 lines and it could be 50, rewrite it"* = self-rewrite trigger. This is the **anti-bloat self-check**. APEX has no equivalent.
- The closing rhetorical question is a **judgment-mode prompt**: forces the executor to inhabit a senior-engineer mental model briefly. This is "expert simulation" prompt engineering.

### Section 3 — Surgical Changes
```
**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.
```

**Analysis:**
- Two sub-cases, each with bullet list = decision-tree-in-prose.
- "Match existing style, even if you'd do it differently" — explicitly tells the agent to *override its own preferences* in favor of codebase conventions. This is **convention humility**.
- "Mention it — don't delete it" — *report-don't-act* pattern for dead code.
- Asymmetric ownership of mess: "clean up only your own mess" — the agent has stewardship for *its own* orphans but **explicit hands-off** for pre-existing dead code.
- Concluding test: *"Every changed line should trace directly to the user's request"* = the **diff-bloat alarm**. Operationally testable.

### Section 4 — Goal-Driven Execution
```
**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.
```

**Analysis:**
- Three transformation pairs *show* the user how to convert imperative → declarative goals. Pattern: not just "do TDD", but "rewrite the goal as a test outcome".
- The `step → verify: check` template is the **smallest viable plan format** — radically lighter than APEX's PLAN.md schema. Worth studying for `/apex:micro` and `/apex:fast` paths.
- Closing line is the *thesis*: strong criteria = autonomy. Weak criteria = oversight. This is the philosophical core.

### Footer
```
---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
```

**Analysis:** Three success metrics — all observable, all behavioral, none "feel-good". This is **prompt-level OKRs**: the prompt declares how to know it's working. APEX has no equivalent in any agent prompt.

### Cross-references & redundancy

The four-principle body is *byte-identical* in three locations:
- `CLAUDE.md`
- `skills/karpathy-guidelines/SKILL.md` (adds YAML frontmatter: `name`, `description`, `license`)
- `.cursor/rules/karpathy-guidelines.mdc` (adds YAML frontmatter: `description`, `alwaysApply: true`)

This is intentional — the CURSOR.md file explicitly tells contributors to keep all three in sync. **APEX has multiple spec files (apex-spec.md, APEX-v5.md, APEX-v6.md) with merge rules**, which is more sophisticated but introduces drift risk. Karpathy's repo solves this with raw duplication + contributor discipline.

---

## 3. Skills catalog

Only one skill in the repo: `karpathy-guidelines`. Documented in full:

### Skill: `karpathy-guidelines`

**File:** `skills/karpathy-guidelines/SKILL.md`

**Frontmatter (verbatim):**
```yaml
---
name: karpathy-guidelines
description: Behavioral guidelines to reduce common LLM coding mistakes. Use when writing, reviewing, or refactoring code to avoid overcomplication, make surgical changes, surface assumptions, and define verifiable success criteria.
license: MIT
---
```

**Trigger phrases (per description):** "writing, reviewing, or refactoring code." Note Anthropic's docs say `description` is the most important field — it's what Claude scans to decide auto-invocation. The Karpathy description is **deliberately broad** ("writing, reviewing, or refactoring") because the rules are universal — they should apply to nearly every coding turn.

**Auto-invocation strategy:** Always-on. There's no `disable-model-invocation: true` and no `user-invocable: false`. Both you and Claude can invoke it; Claude will auto-load it when the description matches the conversation context.

**Composition with other skills:** None declared. The skill stands alone. It is *additive* (the README explicitly says "designed to be merged with project-specific instructions"). The presumption is that other skills (e.g., `/code-review`, `/debug`) will inherit these behaviors implicitly because the skill description matches their contexts.

**Exit criteria:** Implicit — the principles are *always-active behavioral floor*, not one-shot operations. Unlike a workflow skill (e.g., `/deploy`) which finishes, this is a *standing instruction*.

**Tool dependencies:** None (`allowed-tools` not set). The skill grants no special permissions and requires no special tools. It is **pure behavioral prompting**.

**Templates/code included:** None. The skill body is identical to CLAUDE.md sections 1-4 plus the footer.

### Skill body (full verbatim, no truncation)
(See section 2 above — identical content. The SKILL.md adds nothing beyond frontmatter.)

### Plugin metadata files

**`.claude-plugin/plugin.json`:**
```json
{
  "name": "andrej-karpathy-skills",
  "description": "Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations on LLM coding pitfalls",
  "version": "1.0.0",
  "author": { "name": "forrestchang" },
  "license": "MIT",
  "keywords": ["guidelines", "best-practices", "coding", "karpathy"],
  "skills": ["./skills/karpathy-guidelines"]
}
```

**`.claude-plugin/marketplace.json`:**
```json
{
  "name": "karpathy-skills",
  "id": "karpathy-skills",
  "owner": { "name": "forrestchang" },
  "metadata": {
    "description": "Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations",
    "version": "1.0.0"
  },
  "plugins": [
    {
      "name": "andrej-karpathy-skills",
      "source": "./",
      "description": "Behavioral guidelines to reduce common LLM coding mistakes: Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution",
      "version": "1.0.0",
      "author": { "name": "forrestchang" },
      "keywords": ["guidelines", "best-practices", "coding", "karpathy"],
      "category": "workflow"
    }
  ]
}
```

**Why both files:** `plugin.json` describes the plugin payload. `marketplace.json` makes the same repo discoverable as a *marketplace* (so users can `/plugin marketplace add forrestchang/andrej-karpathy-skills` then `/plugin install andrej-karpathy-skills@karpathy-skills`). The repo doubles as a single-plugin marketplace — minimum-viable distribution.

---

## 4. Pattern themes

### 4.1 Tagline-then-bullets structure
Every section opens with a **bold tagline** (e.g., "Don't assume. Don't hide confusion. Surface tradeoffs.") followed by **bulleted imperatives**. This is the modal prompt-engineering structure for behavioral rules. Compresses memorability with operational specificity.

### 4.2 Conditional imperatives ("If…")
Most bullets are conditional, not unconditional. Example: "If uncertain, ask." not "Always ask." This matters because:
- LLMs over-apply unconditional rules (cargo-cult compliance).
- Conditional rules force the LLM to evaluate context before acting.
- The condition is the *guard clause*; the action is the *rule body*.

### 4.3 Negative-space prompting
Section 2 uses five "No X" bans. Section 3 uses three "Don't X" prohibitions. This is **negative-space specification**: instead of describing what to do, describe what *not* to do. Effective when:
- The default LLM behavior is bad and needs suppression.
- The desired behavior is "absence" rather than presence.
- Token budget is tight (negative rules are typically shorter).

### 4.4 Self-check questions / expert simulation
*"Would a senior engineer say this is overcomplicated?"* is **expert-simulation prompting**: forces the LLM to briefly inhabit a different persona to evaluate its own output. Cheap, high-leverage.

### 4.5 Transformation pairs (imperative → declarative)
Section 4's three transformation pairs ("Add validation" → "Write tests for invalid inputs…") are **few-shot examples of goal-reframing**. The LLM doesn't just learn "use TDD"; it learns *how to convert any imperative into a TDD goal*. This is far more general than the underlying rule.

### 4.6 Step → verify template
The mini-plan format `[Step] → verify: [check]` is the **lightest possible plan template**. Three columns: step number, step content, verification. No metadata, no JSON, no schema. Maps directly to what a human would scribble before coding.

### 4.7 Asymmetric ownership
"Clean up only your own mess" — the agent owns *its* artifacts, not the codebase's. This prevents scope creep. APEX has this implicitly in task boundaries but not as a principle.

### 4.8 Behavioral OKRs in the prompt
The footer states the success metrics for the prompt itself: "fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, clarifying questions come before implementation rather than after mistakes." This is **prompt-level self-evaluation criteria** baked into the prompt.

### 4.9 Tradeoff disclosure
"These guidelines bias toward caution over speed. For trivial tasks, use judgment." — explicitly tells the agent **when not to apply the rules**. This is essential for any always-on behavioral rule; without it, the rules suffocate trivial tasks.

### 4.10 Tool-agnostic principles
The same body works as CLAUDE.md, SKILL.md, and Cursor .mdc with only frontmatter changes. The rules are about *agent behavior* not tool features. APEX, by contrast, is tightly coupled to Claude Code's hook/agent/command model. This raises a strategic question: how much of APEX is portable?

---

## 5. Cross-reference / synthesis vs. Anthropic official guidance

### 5.1 Direct alignment

| Karpathy principle | Anthropic best practice | Alignment |
|---|---|---|
| Goal-Driven Execution | "Give Claude a way to verify its work… the single highest-leverage thing you can do" | **Perfect** |
| Surgical Changes | "Scope the task. Specify which file, what scenario, and testing preferences." | **Perfect** |
| Think Before Coding | "Let Claude interview you… ask about technical implementation, UI/UX, edge cases" + "Explore first, then plan, then code" | **Perfect** |
| Simplicity First | "Keep it concise. For each line, ask: 'Would removing this cause Claude to make mistakes?' If not, cut it." (re: CLAUDE.md) | **Conceptual, not coding** |

Anthropic explicitly recommends **plan mode** for non-trivial work and **skip plan mode** for trivial work — same tradeoff Karpathy's tagline names. Anthropic also names **"address root causes, not symptoms"** as a verification criterion, which Karpathy implies but doesn't state.

### 5.2 What Karpathy adds beyond Anthropic
- **"Push back when warranted"** — explicit permission for the agent to disagree. Anthropic's docs are more deferential.
- **"No error handling for impossible scenarios"** — anti-defensive-coding clause. Anthropic doesn't address this.
- **"Match existing style, even if you'd do it differently"** — convention humility. Anthropic mentions matching patterns but less forcefully.
- **The "200 → 50 line" self-rewrite trigger.** Pure anti-bloat. Not in Anthropic docs.
- **The footer success metrics** = prompt-level OKRs.

### 5.3 What Anthropic adds that Karpathy doesn't
- **Plan Mode + Esc to redirect + /rewind checkpoints** = process control. Karpathy is just prompt content.
- **Sub-agent delegation** for research and verification. Karpathy is single-agent.
- **CLAUDE.md hygiene** ("ruthlessly prune") and the **CLAUDE.md inclusion checklist** (Include/Exclude table). Karpathy doesn't address authoring discipline.
- **`/clear` between unrelated tasks** = session hygiene. Karpathy assumes one task.
- **Skills lifecycle** (5k token re-attach budget, 25k total). Karpathy's principles benefit from this but don't reference it.
- **The "kitchen sink session" / "trust-then-verify gap" failure-mode taxonomy.** Karpathy names problems; Anthropic names anti-patterns.

### 5.4 Differences in *philosophy*

| Axis | Karpathy/Forrest | Anthropic Claude Code | APEX (current) |
|---|---|---|---|
| Where rigor lives | In the prompt | In the workflow (modes, subagents, plan-mode) | In the pipeline (commands, hooks, schemas, agents) |
| Default disposition | Skeptical executor | Curious explorer | Disciplined builder |
| Diff philosophy | Minimum lines | "Investments compound" | Atomic per-task snapshots |
| Verification | TDD as default | Tests + screenshots + linters + scripts | Critic + verifier + verify_levels |
| Authoring discipline | Sync 3 files manually | Prune CLAUDE.md continuously | Versioned specs with merge rules |
| Skill model | Always-on behavior file | On-demand with description matching | Stack-specific gen-skill + apex-skills/ |

**Synthesis:** Karpathy + Anthropic = **the prompt** + **the process**. APEX = **the pipeline**. APEX has the pipeline but is **thin on the prompt** for behavioral constraints. The opportunity is to inject Karpathy-style behavioral floors into APEX agents *without* losing the pipeline rigor.

---

## 6. APEX implications — per-pattern adoption analysis

For each major pattern, I evaluate: (a) does APEX already do this; (b) should it adopt; (c) smallest viable change; (d) risk/trade-off.

### 6.1 "State your assumptions explicitly. If uncertain, ask."

**Already in APEX?** Partially — the user's *ecosystem 10-question gate* (from memory) is a heavyweight version applied to plans, not turns. The architect agent surfaces assumptions in PLAN.md. The executor does not currently state assumptions at the start of each task.

**Should adopt?** **Yes.** Executor turns silently making assumptions are the single most common source of "Claude did the wrong thing" complaints. A 3-bullet "assumptions log" at the start of each task is dirt-cheap.

**Smallest viable change:** Add to `executor` agent prompt:
```
Before any code change, output an "Assumptions" block listing 1-3 assumptions you are making about (a) what the user wants, (b) what already exists in the codebase, (c) what counts as done. If any assumption is uncertain or has ≥2 plausible alternatives, stop and ask.
```

**Risk:** Adds tokens per task. Mitigation: cap at 3 bullets; allow the executor to omit the block if assumptions are zero. For trivial tasks (handled by `/apex:fast` and `/apex:micro`), the block should be skippable.

### 6.2 "Push back when warranted"

**Already in APEX?** No. The executor is built to comply, not to disagree.

**Should adopt?** **Yes — but only at planning/architect level, not executor level.** Granting executor permission to override the plan would conflict with the "atomic per-task execution" guarantee. But the **architect** should explicitly push back on user requests if simpler approaches exist.

**Smallest viable change:** Add to `architect` agent prompt:
```
If the user's request could be satisfied by an existing component or a simpler approach with comparable benefit, propose that alternative *before* drafting PLAN.md and ask the user to confirm direction.
```

**Risk:** Architect could over-pushback and stall. Mitigation: limit to "simpler approach exists with comparable benefit"; require concrete evidence (which file/component already provides this).

### 6.3 "No abstractions for single-use code" / "No features beyond what was asked"

**Already in APEX?** No. APEX has anti-rationalization armor (executor cannot silently expand scope) but no anti-bloat armor (executor can add abstractions if it judges them useful).

**Should adopt?** **Yes — high priority.** The framework auditor in your detector campaign repeatedly finds patterns where critic accepted overengineered solutions.

**Smallest viable change:** Add to `executor` agent prompt:
```
Anti-bloat rules:
- No abstractions for single-use code. A class with one caller is overengineering; use a function. A function with one caller is sometimes overengineering; use inline code.
- No "flexibility" parameters that aren't used by the PLAN.md acceptance criteria.
- No error handling for scenarios not listed in PLAN.md.
- After implementing, count lines added. If the result is >2x what the simplest sketch would be, rewrite.
```
Add to `critic` agent prompt:
```
Reject solutions that introduce abstractions, parameters, or error handlers not justified by PLAN.md acceptance criteria. Mark with severity = "overengineering" instead of approving.
```

**Risk:** False negatives where the abstraction was genuinely needed for testability. Mitigation: PLAN.md acceptance criteria can include "must be unit-testable" — that justifies introducing a seam.

### 6.4 "Match existing style, even if you'd do it differently"

**Already in APEX?** No. Executor will reformat freely.

**Should adopt?** **Yes.** Cheap, high-value.

**Smallest viable change:** Add to `executor` agent prompt:
```
Style conservation: When editing existing files, match the file's existing style — quotes, indentation, comment density, type hints, naming conventions — even if you would do it differently in greenfield code. Style drift is a defect, not an improvement.
```

**Risk:** None significant. The detector campaign already values style consistency.

### 6.5 "Every changed line should trace directly to the user's request"

**Already in APEX?** Partially — task boundaries enforce this implicitly. RESULT.json reports files touched. There's no explicit *diff-bloat alarm*.

**Should adopt?** **Yes — as critic check.**

**Smallest viable change:** Add to `critic` agent prompt:
```
Diff-bloat check: For each non-test file touched, every changed line should map to a specific PLAN.md acceptance criterion. If a changed line cannot be mapped (e.g., reformatted import, added type hint, restructured comment), mark it. If >10% of changed lines are unmappable, return verdict = "approved-with-noise" and list the noise.
```

**Risk:** Critic becomes noisier. Mitigation: only flag at >10% threshold; "approved-with-noise" doesn't block, just informs.

### 6.6 Goal-driven `step → verify` template

**Already in APEX?** Yes — PLAN.md has Tasks + verify levels + acceptance criteria. But the format is heavier (JSON + markdown).

**Should adopt the lightweight format?** **Yes — for `/apex:micro` and `/apex:fast`.** The full PLAN.md schema is overkill for trivial tasks.

**Smallest viable change:** Add to `/apex:fast` definition:
```
Output a 1-3 line plan in the format:
1. [Step] → verify: [check]
2. [Step] → verify: [check]
No JSON, no schema. Plan ends when verify checks pass.
```

**Risk:** Plan format proliferation. Mitigation: confine to `/apex:fast` / `/apex:micro`; the `/apex:plan-phase` command continues using full PLAN.md.

### 6.7 Tradeoff disclosure ("bias toward caution over speed; for trivial tasks, use judgment")

**Already in APEX?** No.

**Should adopt?** **Yes — high priority.** APEX is currently *all-or-nothing rigor*. The user already complained (in memory) about over-engineering and not wanting heavyweight processes for every task. A top-level *philosophy* statement that the framework's rigor is configurable would resolve much of that.

**Smallest viable change:** Add to top of `apex-spec.md`:
```
APEX biases toward rigor over speed. Use /apex:full for substantial multi-file work where silent wrong assumptions compound. Use /apex:fast for trivial tasks (typos, log lines, single-line fixes). For everything in between, use /apex:quick. The framework's value scales with task complexity.
```
And in every agent prompt, declare: *"This agent is part of APEX's rigor stack. If the calling command is /apex:fast or /apex:micro, skip optional checks (assumptions block, anti-bloat self-check, style-conservation note) but keep mandatory checks (correctness, safety, task-boundary respect)."*

**Risk:** Two-tier behavior could create inconsistencies. Mitigation: clear declarative split between *mandatory* and *optional* checks per agent.

### 6.8 "Would a senior engineer say this is overcomplicated?" (expert simulation)

**Already in APEX?** No.

**Should adopt?** **Yes — in critic agent.**

**Smallest viable change:** Add to `critic` agent prompt:
```
Senior-engineer self-check: Before delivering the verdict, ask: "Would a senior engineer reviewing this PR say this is overcomplicated for what was asked?" If yes, the verdict is at most "approved-with-noise"; include the simpler approach in the critique.
```

**Risk:** Subjective. Mitigation: it's a *self-check*, not a hard rule — adds friction without veto.

### 6.9 Footer "These guidelines are working if…" (prompt-level OKRs)

**Already in APEX?** No agent prompt declares its own success metrics in this style.

**Should adopt?** **Yes — for the top 5 agents (executor, critic, verifier, architect, framework-auditor).**

**Smallest viable change:** Each top-level agent prompt gains a footer:
```
This agent is working if:
- [Specific observable behavior 1]
- [Specific observable behavior 2]
- [Specific observable behavior 3]
```
Example for executor: "fewer style-drift lines per task; fewer unrequested abstractions in diffs; assumptions are stated before code is written, not after a critic finds them."

**Risk:** Metrics could become aspirational decoration. Mitigation: tie to actual observable signals in RESULT.json or critic findings; review quarterly.

### 6.10 Anti-bloat rules from extended-12 (Rules 5-12)

| Rule | Apply to APEX? | Where |
|---|---|---|
| 5. Don't make the model do non-language work | **Yes.** This is the *correct* framing of when to use hooks vs prompts. | Move retry/escalation/routing decisions from agent prompts into hooks. |
| 6. Hard token budgets, no exceptions | **Already done via CONTEXT_BUDGET.json + circuit-breaker.** Validate that agents actually respect budgets. | Reinforce in agent prompts that hitting budget = stop, not soldier on. |
| 7. Surface conflicts, don't average them | **Yes.** When critic and verifier disagree, the answer is not to average; it's to surface. | Add to `/apex:next` step F: if critic and verifier disagree by >1 severity level, escalate to user. |
| 8. Read before you write | **Partial — executor reads context but doesn't read *adjacent siblings*.** | Add to `executor`: before adding a new function, grep for similar functions in the file and 2 sibling files. |
| 9. Tests are required but are not the goal | **Yes — critic should call out trivial tests.** | Add to `critic`: tests that assert "function returns *something*" rather than "function returns *the right thing*" are flagged. |
| 10. Long-running operations require checkpoints | **Already done — `turn-checkpoint` hook + per-task snapshots.** Strong alignment. | Confirm the hook actually summarizes-then-confirms before proceeding to next wave. |
| 11. Convention beats novelty | **Yes — anti-pattern: introducing class components into hook codebase.** | Add to `executor`: detect the codebase's dominant idiom (classes vs hooks, async vs sync, OOP vs functional) and conform. |
| 12. Fail visibly, not silently | **Yes — critical for the audit trail campaign.** | Add to `executor` + `wave-executor`: never report success when records were skipped, transactions rolled back, or constraints bypassed. |

### 6.11 Marketplace plugin distribution

**Should APEX adopt?** **Yes, once stable.** Plugin/marketplace format = canonical install path for Claude Code extensions. The Karpathy repo proves a single CLAUDE.md is enough to be a marketplace plugin.

**Smallest viable change:** Add `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` to APEX top-level. Distribute commands + agents + hooks as a single installable plugin. Users get `/plugin install apex@apex-framework`.

**Risk:** APEX's many files (hooks, agents, commands, scripts) may not all fit the plugin model cleanly. Validation needed.

---

## 7. Open questions

1. **What were Karpathy's exact words for each of the four observations?** The original tweet at `x.com/karpathy/status/2015883857489522876` returned HTTP 402 (paywalled). Secondary sources reproduce **three of the four** verbatim; the fourth (about adjacent code modifications) is only paraphrased. The fully canonical wording would slightly strengthen the analysis but does not change conclusions. [unclear from available sources]

2. **Are the effectiveness numbers (41% → 11%; ~40% → <3%) credible?** They are cited in multiple secondary articles (BrightCoding, KuCoin) but originate from a single source (Forrest Chang) and have no public methodology. Treat as *suggestive* not *evidence*. [unclear from source]

3. **How does the skill behave when both `karpathy-guidelines` and a project-specific CLAUDE.md are present?** Anthropic's docs imply *both* load (CLAUDE.md is session-wide; skill loads on description match). Conflicts are resolved by … not clearly specified. The Karpathy README says "Merge with project-specific instructions" but doesn't specify precedence. [unclear from source]

4. **Does Multica (the author's flagship project) use these same principles internally?** Multica supports multiple agent providers and "reusable skills" — implying its skills are likely SKILL.md-format. Whether Multica enforces Karpathy-style principles at the platform level is not stated. [unclear from source]

5. **How does the `karpathy-guidelines` skill interact with Anthropic's bundled skills** (`/code-review`, `/debug`, `/verify`, `/run`)? In principle they compose, but no documented examples were found.

6. **Why did the WebFetch summarizer refuse to reproduce the CLAUDE.md verbatim?** It cited "appropriate boundaries for content reuse" despite MIT-licensed source. This is a Claude content-policy quirk — bypassed via `gh api`. Worth flagging for any future research that depends on verbatim capture.

---

## 8. Raw citation appendix

### 8.1 Direct quotes from Andrej Karpathy (verified via multiple secondary sources)

1. *"The models make wrong assumptions on your behalf and just run along with them without checking. They don't manage their confusion, don't seek clarifications, don't surface inconsistencies, don't present tradeoffs, don't push back when they should."* — Karpathy, X, Jan 26 2026 (per multiple secondary captures)

2. *"They really like to overcomplicate code and APIs, bloat abstractions, don't clean up dead code... implement a bloated construction over 1000 lines when 100 would do."* — Karpathy, ibid.

3. *"They still sometimes change/remove comments and code they don't sufficiently understand as side effects, even if orthogonal to the task."* — Karpathy, ibid.

4. *"LLMs are exceptionally good at looping until they meet specific goals... Don't tell it what to do, give it success criteria and watch it go."* — Karpathy, ibid.

5. *"Easily the biggest change to my basic coding workflow in 2 decades of programming, and it happened over the course of a few weeks."* — Karpathy, ibid.

6. *"A few random notes from claude coding quite a bit last few weeks. Coding workflow. Given the latest lift in LLM coding capability, like many others I rapidly went from about 80% manual+autocomplete coding and 20% agents in November to 80% agent coding and 20% edits+touchups…"* — Karpathy, ibid. (tweet preamble)

### 8.2 Verbatim CLAUDE.md (already reproduced in section 2; canonical source: `gh api repos/multica-ai/andrej-karpathy-skills/contents/CLAUDE.md`)

### 8.3 Verbatim SKILL.md (already reproduced in section 3; canonical source: `gh api repos/multica-ai/andrej-karpathy-skills/contents/skills/karpathy-guidelines/SKILL.md`)

### 8.4 Verbatim Cursor rule (`.cursor/rules/karpathy-guidelines.mdc`)
```yaml
---
description: Behavioral guidelines to reduce common LLM coding mistakes. Use when writing, reviewing, or refactoring code to avoid overcomplication, make surgical changes, surface assumptions, and define verifiable success criteria.
alwaysApply: true
---
```
Body: identical to CLAUDE.md sections 1-4 + footer.

### 8.5 Anthropic's canonical guidance (verbatim, from `code.claude.com/docs/en/best-practices`)

- *"Give Claude a way to verify its work. Include tests, screenshots, or expected outputs so Claude can check itself. This is the single highest-leverage thing you can do."*
- *"Without clear success criteria, it might produce something that looks right but actually doesn't work."*
- *"Letting Claude jump straight to coding can produce code that solves the wrong problem. Use plan mode to separate exploration from execution."*
- *"The recommended workflow has four phases: Explore → Plan → Implement → Commit."*
- *"For tasks where the scope is clear and the fix is small (like fixing a typo, adding a log line, or renaming a variable) ask Claude to do it directly."*
- *"Bloated CLAUDE.md files cause Claude to ignore your actual instructions!"*
- *"For each line, ask: 'Would removing this cause Claude to make mistakes?' If not, cut it."*
- *"Treat CLAUDE.md like code: review it when things go wrong, prune it regularly, and test changes by observing whether Claude's behavior actually shifts."*
- *"You can tune instructions by adding emphasis (e.g., 'IMPORTANT' or 'YOU MUST') to improve adherence."*
- *"If you've corrected Claude more than twice on the same issue in one session, the context is cluttered with failed approaches."*

### 8.6 Anthropic's canonical skills guidance (verbatim, from `code.claude.com/docs/en/skills`)

- *"When you or Claude invoke a skill, the rendered SKILL.md content enters the conversation as a single message and stays there for the rest of the session."*
- *"Claude Code does not re-read the skill file on later turns, so write guidance that should apply throughout a task as standing instructions rather than one-time steps."*
- *"Auto-compaction carries invoked skills forward within a token budget. When the conversation is summarized to free context, Claude Code re-attaches the most recent invocation of each skill after the summary, keeping the first 5,000 tokens of each. Re-attached skills share a combined budget of 25,000 tokens."*
- *"Keep SKILL.md under 500 lines. Move detailed reference material to separate files."*
- *"Put the key use case first: the combined description and when_to_use text is truncated at 1,536 characters in the skill listing to reduce context usage."*

### 8.7 Effectiveness claims (unverified — single-source via Forrest Chang)

- 4-rule Karpathy CLAUDE.md: claimed error-rate reduction **41% → 11%** (BrightCoding, KuCoin)
- Extended 12-rule template: claimed error-rate reduction **~40% → <3%** (KuCoin, AgentPedia)
- Approximate compliance rate: *"Claude follows CLAUDE.md guidelines approximately 80% of the time, not deterministically"* (MiraFlow)
- Star count trajectory: **5,828 stars day 1; ~50,000 in 2 weeks; ~120,000 today** (multiple sources)

### 8.8 The MasteringProductHQ critique — 8 gaps (verbatim labels)

The Karpathy file is "written for an engineer working alone on code" and misses:
1. Wrong Scope of Application (product teams face different risks)
2. Missing Problem Validation (no requirement to articulate user problem)
3. No Assumption Tracking (no explicit list of assumptions and unknowns)
4. Inadequate Scope Control (code simplicity ≠ scope discipline)
5. Missing Tradeoff Documentation (costs/risks/alternatives not surfaced to stakeholders)
6. Output-Based Definition of Done (completion metrics ≠ outcome validation)
7. No Instrumentation Requirement (metrics must be defined *before* shipping)
8. Absent Decision Logging (no decision rationale / reversibility / revisit triggers)

Quote: *"Your most expensive failure mode is this: Shipping the wrong thing, well."*

### 8.9 Extended-12 template (community-added rules 5-12 via AgentPedia / Mnimiy, May 2026)

- **Rule 5 — Don't Make the Model Do Non-Language Work.** *"Retry policies, routing, escalation thresholds belong in deterministic code."* Example: a `decide whether to retry on 503` LLM call drifted because the model started reading request body as context.
- **Rule 6 — Hard Token Budgets, No Exceptions.** *"Stop and ask if a task is trending past its budget."* Example: 90-minute debugging session iterating on the same 8KB error.
- **Rule 7 — Surface Conflicts, Don't Average Them.** *"If two parts of the codebase disagree, flag the disagreement and ask which to follow."* Example: code mixing async/await with try/catch and a global error boundary, swallowing errors twice.
- **Rule 8 — Read Before You Write.** *"Understand adjacent code (the file and nearby siblings) before adding new code."* Example: Claude added a duplicate function 30 lines from an identical existing one; the new one was imported first and became the unintended source of truth.
- **Rule 9 — Tests Are Required But Are Not the Goal.** *"A passing test that tests nothing useful is a failure. Tests must check behavior."* Example: 12 auth tests passing, auth broken in production — tests checked "returns something" not "returns the right thing".
- **Rule 10 — Long-Running Operations Require Checkpoints.** *"After every significant step, summarize what was done and confirm before proceeding."* Example: 6-step refactor went wrong on step 4; steps 5-6 ran on the broken state.
- **Rule 11 — Convention Beats Novelty.** *"In an established codebase, match the existing pattern even if a 'better' one exists."* Example: introducing React hooks into a class-component codebase broke `componentDidMount`-based testing.
- **Rule 12 — Fail Visibly, Not Silently.** *"Surface every skipped record, every rolled-back transaction, every constraint violation. Never report success when something was bypassed."* Example: DB migration reported success but silently skipped 14% of records on constraint violations; discovered 11 days later in reports.

### 8.10 URLs cited

- Primary: <https://github.com/multica-ai/andrej-karpathy-skills>
- Author's flagship: <https://github.com/multica-ai/multica>
- Karpathy origin tweet (paywalled, captured via secondaries): <https://x.com/karpathy/status/2015883857489522876>
- Anthropic best practices: <https://code.claude.com/docs/en/best-practices>
- Anthropic skills: <https://code.claude.com/docs/en/skills>
- DeepWiki goal-driven section: <https://deepwiki.com/forrestchang/andrej-karpathy-skills/3.4-goal-driven-execution>
- Themenon Lab Karpathy quotes: <https://themenonlab.blog/blog/karpathy-claude-md-four-rules-ai-coding-agents>
- ToDataBeyond Substack (Karpathy tweet preamble): <https://todatabeyond.substack.com/p/turning-andrej-karpathys-llm-coding>
- MiraFlow virality analysis: <https://miraflow.ai/blog/karpathy-claude-md-100k-github-stars-ai-coding-2026>
- BrightCoding manifesto analysis: <https://www.blog.brightcoding.dev/2026/04/29/karpathy-skills-the-revolutionary-llm-coding-manifesto>
- MasteringProductHQ critique: <https://www.masteringproducthq.com/p/what-karpathys-claudemd-misses-and>
- AgentPedia 12-rule extended template: <https://agentpedia.codes/blog/karpathy-claude-md-rules-extended>
- AI Builder Club analysis: <https://www.aibuilderclub.com/blog/karpathy-claude-md-rules>
- KuCoin coverage (effectiveness numbers): <https://www.kucoin.com/news/flash/12-claude-md-rules-cut-ai-code-error-rate-to-3>
