# APEX Meta-Plan v8 — "Next-Level" Unified Roadmap

> **תאריך:** 2026-05-15
> **בסיס:** סינתזה צולבת של 5 מסמכי-תוצר (R5 Synthesis Findings, R2-CLAIMS-INDEX, R2-APEX-INVENTORY, R2-APEX-GAP-MATRIX, R2-RECOMMENDATIONS) + 2 מחקרי-מקור (R5 Brief, R2 Source) + 4 מסמכי-תמיכה (R1, R3, R6, verification, cost optimization).
> **מצב APEX מנותח:** v7.1 + שמירת תיקוני self-heal עד R11 (`97c0408` — R11-003).
> **תפוקה:** מטא-תוכנית אחת, סדורה לפי גלים, הופכת את APEX לדור הבא — מבלי לערער את הליבה שעובדת.

---

## 0 · תקציר מנהלים — בעברית פשוטה

### מה למדנו מ-5 המסמכים

**שני סוגי פערים — שניהם קריטיים, כל אחד מסוג אחר:**

1. **פערי-תיאטרון (R2)** — APEX מצהיר על יכולת, יש לזה schema, יש לזה banner ב-hook — אבל אין קוד שעושה את הפעולה. שלושה כאלה:
   - **Observation Masking** — דגל boolean מאותחל ל-`true` ולעולם לא נקרא ולא משנה כלום. R2-C003: זו השיטה היחידה ב-state-of-the-art עם 50% הפחתת tokens, איכות שווה או טובה יותר.
   - **Token Counter** — `tokens.total_input` בסכמה, ב-context-monitor יש קריאה — אבל **אף hook לא כותב את הערך**. כל ה-thresholds (55%, 70%) חיים על fallback heuristic של 20K-לפי-מספר-קריאות-agent. כל ה-metrics dashboard בלתי-אפשרי בלי זה.
   - **Prompt Caching** — apex-design-notes.md:11 מצהיר "90% input cost reduction". `grep -r "cache_control" framework/` = **0 התאמות**.

2. **פערי-אבולוציה (R5)** — APEX בנוי על הנחות-יסוד שמחקרים חדשים הפריכו. שניים הכי חמורים:
   - **כלל "5 הצלחות → קידום autonomy"** — R5 §7 F2 מצטט METR (RCT, 16 devs, 246 משימות) ואומר במפורש: **להחליף ב-Track A/B/C לפי סוג המשימה**, לא לפי number of successes. כיום `next.md:614-617` מיישם בדיוק את הכלל ש-R5 דוחה.
   - **Comprehension Gate על LOC-largest, לא על criticality** — R5 §3 (Anthropic RCT, 52 engineers) מראה 86% הבנה כש-pattern הוא "generation-then-comprehension עם הסבר מילולי" לעומת 24% כש-pattern הוא "iterative delegation". כיום ב-`next.md:851-874` ה-gate בוחר לפי diff size, מקבל 'y' בלי הסבר, ורץ פעם אחת בסוף phase במקום כל 60-90 דקות.

**מה כן עובד (לא לגעת!):** Multi-Agent Isolation, Clean-Room Critic, Auditor Filesystem Quarantine, Three-Tier Memory architecture, TDAD, Scale-Adaptive Classifier, three-tier ceremony, R5-style isolation, schemas/RESULT contract, v7.1 Auto-Continuity, ו-7 סבבי self-heal עם trajectory מתכנס. R2-C228 מאמתת את הליבה הזו במפורש.

### מסקנה אסטרטגית

APEX לא צריך **שכתוב**. הוא צריך **השלמת הצהרות**: לסגור את 3 פערי-התיאטרון (R01-R03), לעדכן כללי-יסוד שמחקר חדש הפריך (F1-F2), לשפר UX עם severity tiers ו-progressive disclosure (F4-F5), ולהוסיף 4 יכולות-תוספת (task-adaptive profiles, memory integrity, model diversity, quality-drift metric).

**14 R-Items סופיים**, מאורגנים ב-4 גלים, סך הכל ~12-16 ימי עבודה ממוקדת. כל R-item ניתן ל-`/apex:next` או ל-`/apex:self-heal` כ-R-ID יחיד עם acceptance criteria מוגדרים.

### מטריקות צפויות אחרי גל 1+2 בלבד

- **~50% הפחתת input-cost לכל task** (Observation Masking + Prompt Caching בשטח, מהבסיס של JetBrains DL4C 2025 + Anthropic Sep 2024 prompt-caching docs).
- **~85% הפחתת latency** על stable_prefix אחרי החילה הראשונה (R2-C092).
- **כל ה-rotation triggers פועלים בפועל** (לא רק מוגדרים ב-config).
- **תצוגת Context Health אמיתית** ב-`/apex:status` — gauge ירוק/צהוב/אדום, cache hit rate, last mask, drift indicators.
- **2-3 מתוך 6 חוסרי R2 §9 — סגורים פיזית** (Observability, Proactive Rotation, Observation Masking).

אחרי כל 14: 5 מתוך 6 חוסרי §9 סגורים (רק Aider-AST מועבר ל-backlog), 4 מתוך 5 פערי-יסוד של R5 סגורים (#7 = security-specialist closure נשאר כסעיף עצמאי).

---

## 1 · עקרונות-יסוד שמכתיבים את כל הגלים

לפני שצוללים — שמונה עקרונות נגזרים מהמחקר שכל R-item שומר עליהם:

1. **כל token חייב להרוויח את מקומו** (R2-C001) — אין הוספת payload בלי הוכחת ערך.
2. **לעולם לא לקלקל את clean-room** (R2-C232) — APEX פתר את זה; כל שינוי שומר על האיזולציה (כולל R10 model-diversity).
3. **קונפיגורציה דקלרטיבית = תיאטרון** עד שיש קוד שצורך אותה. כל R-item כולל "מי הקוד שיקרא את הערך החדש".
4. **Single source of truth** — אם ערך מתועד פעמיים (apex-design-notes.md + apex-spec.md), אחד הוא מקור והשני pointer.
5. **Cross-platform first, POSIX second** — APEX רץ על Windows (OneDrive); כל script חוצה PowerShell + bash.
6. **Fail-safe לכל hook חדש** — timeout + fallback בטוח (לא חוסם pipeline).
7. **Self-report ≠ measured** (R5 §2.2 perception gap 43-pt) — כל טענה ב-`apex-spec.md` חייבת objective evidence או disqualification.
8. **The interaction pattern is the intervention** (R5 §3-§4) — generation-then-comprehension הוא ה-intervention, לא הכלי.

---

## 2 · מפת הפערים — מאוחדת R5 × R2 × Cross-Rounds

### 2.1 פערי-תיאטרון (Theatre — Highest Leverage)

| # | פער | מקור-מחקר | מצב APEX היום | Leverage |
|---|---|---|---|---|
| T1 | Observation Masking | R2-C003 (4/5 models), R2-C231 (§9 #3); JetBrains DL4C 2025 — 50% cost cut + 2.6% איכות | `observation_masking_active` boolean — מאותחל ל-true ולא נקרא. `pre-compact.sh:35` רק מדפיס banner. | **Highest** |
| T2 | Token Counter | R2-C048 (BrowseComp: 80% perf variance), R2-C229 (§9 #1) | `tokens.total_input` בסכמה; `context-monitor.sh:25` קורא; **אף hook לא כותב**. | **Highest (unlocks T-others)** |
| T3 | Prompt Caching | R2-C092 (Anthropic 90%/85%), R2-C155 ("adopt immediately") | `apex-design-notes.md:11` מצהיר; `grep cache_control framework/` = 0. | **Highest** |
| T4 | Proactive 50-60% rotation | R2-C037, R2-C230 (§9 #2) | threshold 55% קיים; trigger רץ דרך task-count proxy (`>= 4 tasks`) כי המונה מת. | Activates after T2 |

### 2.2 פערי-אבולוציה (Evolution — R5 Direct Contradictions)

| # | פער | מקור-מחקר | מצב APEX היום |
|---|---|---|---|
| E1 | "5 הצלחות → קידום" (R5 F2) | R5 §7 line 390 — METR RCT (16 devs, 246 משימות) | `next.md:614-617` מיישם את הכלל ש-R5 דוחה במפורש. |
| E2 | Comprehension gate LOC-based + skip-able (R5 F1) | R5 §3 — Anthropic RCT (52 engineers, 86% vs 24%) | `next.md:851-874` בוחר top-3 diff; 'y' עובר בלי הסבר; per-phase לא per-60-90min. (D כבר אסור skip — שיפור חלקי.) |
| E3 | אין severity tiers; alert fatigue (R5 F5) | R5 §7 line 488 — alert fatigue research | 46 hooks עם exit-codes 0/1/2 לא עקביים, ללא vocabulary, ללא MINOR batching. |
| E4 | `/apex:status` מציג 40+ נקודות (R5 F4) | R5 §7 line 454 — DX/SPACE evidence | `status.md:40-134` מציג Hocking-Cockpit תמיד. |
| E5 | `/apex:micro` בוטל — אבד the right ceremony (R5 F3) | R5 §7 line 426 — silent failure docs | `/apex:fast` הוא הקרוב ביותר; commits per-fix; ללא batched review. |
| E6 | טענת DORA סותרת ראיות (R5 #8 do-now) | R5 §5.4; DORA 2024 -7.2% stability | `apex-spec.md:375` "First Framework That Improves DORA". |
| E7 | "first-hour success" לא מוגדר | R5 §1 + §9 Gap #7 | `apex-spec.md:9` טוען זאת ללא הגדרה איך מודדים. |

### 2.3 פערי-יכולת (Capability — Net-New)

| # | פער | מקור-מחקר | פעולה |
|---|---|---|---|
| C1 | אין task-adaptive profiles (R2 §9 #5) | R2-C026, C127-C137, C233 | 6 פרופילים: new_code, bug_fix, code_review, refactor, test_writing, frontend. |
| C2 | Memory integrity חלקי (R2 §9 #6) | R2-C081, C211, C234 + R6 §5 | provenance fields, hash-invalidation, learnings backup, audit agent scope. |
| C3 | אין model diversity לאימות | R2-C125, R2-C107 (Anthropic Opus-lead+Sonnet-workers = +90.2%) | Executor=Sonnet, Critic/Verifier/Auditor=Opus (או temperature delta). |
| C4 | Architect cap 20% מעל R2 ceiling | R2-C051/C058 (10-15% MAX) | 40K → 30K. |
| C5 | אין quality-drift metric (R2 §9 #4 ↔ R2-C214 "ultimate APEX metric") | R2-C167, R2-C214 | rolling-window task quality comparison vs baseline. |
| C6 | אין atomic pre-rotation snapshot | R2-C203 | STATE + DECISIONS + git-tag + phase-summary, atomic. |

### 2.4 פערים בסיום (Closure — R7 leftover P1)

| # | פער | מקור |
|---|---|---|
| L1 | security-specialist module — lint נכשל ב-6 מודולים, threat-model template נשאר, CI scanner ידני | R5 do-now #7; R7 F-002 |

---

## 3 · 14 R-Items סופיים — Sized & Sequenced

> כל item: **רעיון בשורה אחת** · R2/R5 anchors · APEX file:line · Effort · Dependencies · Acceptance criteria.
> 5 Items הם R5-מקור (אבולוציה + UX), 9 הם R2-מקור (פיזיקת context + יכולות חדשות). R7-residual = item נפרד.

### Wave 1 — Foundation (Theatre-Killers + Independent Quick Wins)

> רצים במקביל. סך הכל ~2-3 ימי עבודה. אחרי הגל הזה: Wave 2 נפתח.

#### M01 · Wire Real Token Counter [P0, M]
**Pred:** R02 ב-R2-RECOMMENDATIONS.md. **R2-anchors:** C048, C167, C173, C212, C229.
**Why:** השער ל-Observability והבסיס לכל metric. אחרי M01 — M02 (caching) ו-M05 (rotation) הופכים פעילים.
**Change:**
- New `framework/hooks/_tokens-update.sh` — `apex_tokens_update <agent> <in> <out> [cache_r] [cache_c]`, atomic via flock/rename-temp.
- Edit `framework/hooks/subagent-stop.sh` — call it with SubagentStop event's `usage.input_tokens/output_tokens/cache_read_input_tokens/cache_creation_input_tokens`.
- Edit `framework/hooks/context-monitor.sh:25-43` — drop heuristic fallback; emit `[ERROR]` if `total_input==0` after any agent call.
- Extend `framework/schemas/STATE.schema.json` — add `tokens.cache_hits`, `tokens.cache_writes`.

**Accept:**
1. After one task: `STATE.tokens.total_input > 0`, `by_agent[executor].calls=1`.
2. After two cached tasks: `cache_hits >= 1`.
3. New `framework/tests/test-tokens-update.sh` passes.
4. health-check test #28 — "Token counter wired" — passes.

**Effort:** ~½ day.
**Deps:** none.

---

#### M02 · Implement Observation Masking [P0, M]
**Pred:** R01 ב-R2-RECOMMENDATIONS.md. **R2-anchors:** C003, C032, C169, C191, C231.
**Why:** 50% הפחתת tokens, +2.6% איכות (R2-C032), בעלות compute אפס. ה-Single Highest-Leverage gap לפי R2.
**Change:**
- New `framework/hooks/observation-mask.sh` — Stop+soft-rotation triggers; finds tool-result blocks > N turns old (`OBSERVATION_MASKING_WINDOW=3`); replaces each with `[masked: <tool> at <turn N>, re-read from disk if needed]`; updates `STATE.context.last_mask_at`. Fail-safe: if transcript inaccessible → warn + fallback to `/compact`. Never blocks.
- Edit `framework/CONTEXT_BUDGET.default.json:14-19` — extend `working_memory` zone with `masking_rule: "delete_after_n_turns"`, `masking_window_turns: 3`.
- Edit schema `framework/schemas/CONTEXT_BUDGET.schema.json` `definitions.zone` — add optional `masking_window_turns`.
- Edit `framework/hooks/pre-compact.sh:35` — if `observation_masking_active=true` → invoke observation-mask.sh first; LLM `/compact` only if Z3 still over.
- Edit `framework/agents/architect.md` Step 0 — verify `STATE.context.last_mask_at` freshness; signal if stale.

**Accept:**
1. New `framework/tests/test-observation-masking.sh`: 8-turn fixture → after run, turns 1-5 have stubs, turns 6-8 untouched.
2. `STATE.context.last_mask_at` updates on each run.
3. Agent can still re-read original file via Read tool.
4. health-check test #27 — "Observation masking actually deletes content, not just sets flag" — passes.

**Effort:** ≤1 day.
**Deps:** none (independent of M01; combine for max win).

---

#### M03 · Architect Budget Cap 30K (R2 ceiling) [P1, S]
**Pred:** R08 ב-R2-RECOMMENDATIONS.md. **R2-anchors:** C051, C058, C175, C194.
**Why:** R2 explicit cap: orchestrator 10-15% MAX. APEX architect היום ב-20% (40K/200K).
**Change:**
- Edit `framework/CONTEXT_BUDGET.default.json:38-39` — `architect: {max_input: 30000, target_input: 20000}`.
- Edit `framework/agents/architect.md` — add explicit budget reminder: "Your input MUST stay under 30K. If you need more, write to disk and load on-demand. Do NOT load full file contents — pass paths to executor."

**Accept:**
1. `framework/tests/test-architect-budget.sh` — stub large dep tree → architect prompt ≤ 30K.
2. health-check test #33 — "Architect input ≤ 30K in any captured call" — passes.

**Effort:** 10-30 minutes.
**Deps:** none.

---

#### M04 · Model Diversity for Verification [P1, S]
**Pred:** R10 ב-R2-RECOMMENDATIONS.md. **R2-anchors:** C107, C125.
**Why:** Reduce shared blind spots between executor and critic; bonus cost optimization (Sonnet 98% of Opus at 1/5 cost per cost-optimization synthesis).
**Change:**
- Edit `.claude/apex-model-routing.json` (or canonical routing) —
  ```json
  {"executor":"claude-sonnet-4-6","architect":"claude-sonnet-4-6","critic":"claude-opus-4-7","verifier":"claude-opus-4-7","auditor":"claude-opus-4-7"}
  ```
- Edit `framework/agents/critic.md`, `verifier.md`, `auditor.md` frontmatter — add `expected_model: claude-opus-4-7`.
- New `framework/docs/MODEL-ROUTING.md` — rationale (R2-C125, cost data).
- Edit `framework/hooks/agent-lint.sh` — warn if `expected_model` ≠ routing config.

**Accept:**
1. `framework/tests/test-model-routing.sh` — verifies each agent's `expected_model` matches routing.
2. health-check test #35 — "executor and critic use different models OR temperatures" — passes.

**Effort:** ~30 minutes.
**Deps:** none.

---

### Wave 2 — Activation (Depends on Wave 1)

> רצים אחרי Wave 1 פעיל. סך הכל ~2-3 ימים. מפעיל את כל ה-cost/latency win, מאיר את ה-dashboard.

#### M05 · Activate Anthropic Prompt Caching [P0, M]
**Pred:** R03. **R2-anchors:** C092, C093, C097, C155.
**Why:** 90% cost cut, 85% latency cut, break-even at 2 cache hits.
**Change:**
- Edit each agent invocation in `framework/commands/apex/next.md` (architect step 0, executor body, critic, verifier) — wrap stable_prefix in cached block via Claude Code SDK's `cache_control: {"type":"ephemeral","ttl":"5m"}` (1h for long phases). Concretely: prepend agent frontmatter directive:
  ```yaml
  cache_breakpoints:
    - after: "<stable_prefix>"
  ```
- New `framework/docs/PROMPT-CACHING.md` — protocol: 5m vs 1h TTL; what goes in stable_prefix (system + CLAUDE.md ≤200 lines + repo-map + DECISIONS slice); what doesn't (current task, recent tool outputs).
- Edit `framework/hooks/subagent-stop.sh` — extract `cache_read_input_tokens` + `cache_creation_input_tokens`, pass to `_tokens-update.sh`.
- Edit `framework/commands/apex/status.md` — render cache hit rate.

**Accept:**
1. After 2 consecutive tasks in same session: `cache_writes > 0` after #1; `cache_hits > 0` after #2 with hit ratio > 0.5.
2. New `framework/tests/test-prompt-caching.sh` passes.
3. health-check test #29 — "Prompt caching active — cache_hits > 0 in any 2+-task session" — passes.

**Effort:** ½-1 day.
**Deps:** **M01** (token counter for cache metrics).

---

#### M06 · Activate 50-60% Proactive Rotation [P0, S]
**Pred:** R05. **R2-anchors:** C037, C188, C193, C202, C230.
**Why:** thresholds (55%/70%) configured but unreachable while token counter dead. After M01, replace task-count proxy with real %.
**Change:**
- Edit `framework/commands/apex/next.md` Step F (line ~137) — replace `tasks_completed - tasks_since_last_rotation >= 4` with:
  ```
  Read STATE.context.estimated_context_usage_pct.
  Read CONTEXT_BUDGET.rotation_triggers[].
  For each trigger in priority order:
    if trigger.type == "utilization_pct" and pct >= trigger.value:
      invoke trigger.action ; break
    if trigger.type == "pattern" and pattern matches drift_indicators:
      invoke trigger.action ; break
  ```
- New `framework/hooks/_rotation-decide.sh` — `apex_rotation_decide` consumes `rotation_triggers[]`.
- Edit `CONTEXT_BUDGET.default.json:32-36` — add 4 more triggers per R2-C091/C202:
  ```json
  {"type":"phase_boundary","value":null,"action":"proactive_compact"},
  {"type":"task_batch","value":6,"action":"warn_and_compact"},
  {"type":"time_minutes","value":40,"action":"warn_and_compact"},
  {"type":"recovery_density","value":3,"action":"hard_rotate"}
  ```

**Accept:**
1. `framework/tests/test-rotation-thresholds.sh`: stub `pct: 56` → expect proactive_compact; `pct: 71` → hard_rotate; `drift_indicators.recovery_density: 3` → hard_rotate.
2. health-check test #30 — "Rotation triggers actually fire" — passes.

**Effort:** ~2-3 hours.
**Deps:** **M01, M02**.

---

#### M07 · Context Health Dashboard [P0, S]
**Pred:** R04. **R2-anchors:** C212, C213, C229.
**Why:** All data exists post-M01/M05; render the cockpit gauge.
**Change:**
- Edit `framework/commands/apex/status.md` — add "Context Health" block. Concrete rendering:
  ```
  Context Health: 🟢 47% (target 55%, hard 70%)
  ├── Budget by zone:    stable_prefix 8K/30K · task_context 22K/50K · working_memory 14K/60K · gen_reserve 60K (reserved)
  ├── Cache efficiency:  87% hit rate (12 hits / 14 calls)
  ├── Last rotation:     2026-05-15 03:14 UTC (47 min ago) — phase_boundary
  ├── Last mask:         2026-05-15 03:51 UTC (10 min ago) — 7 stale tool-results
  ├── Drift indicators:  ▢ spec=0  ▢ cb=0  ▢ reflexion=2/9  ▢ low_conf=0
  ├── Quality (rolling): task #14/14 — verifier confidence high
  └── ALERTS:            none
  ```
  Gauge color: `🟢 <50% / 🟡 50-60% / 🔴 >60%`.
- Edit `framework/hooks/context-monitor.sh` — when invoked from `/apex:status`, output JSON of all 8 metrics.
- New `framework/schemas/HEALTH_METRICS.schema.json` — 8-metric output structure.
- Edit `framework/hooks/verify-learnings.sh` — output stale-reference rate.

**Accept:**
1. `/apex:status` after M01+M05 renders all 8 categories with non-stub values.
2. Gauge changes color across 50%/60%/70% thresholds.
3. health-check (no new test number needed — existing #28-30 cover) — manual verify.

**Effort:** ~2-3 hours.
**Deps:** **M01, M05**.

---

### Wave 3 — Evolution (R5 Direct Corrections — UX & Autonomy)

> רצים אחרי Wave 1 בלבד (לא תלויים ב-Wave 2). סך הכל ~3-4 ימים.

#### M08 · Track A/B/C/D Task-Class Autonomy + Plain-Language UX [P0, M+]
**Pred:** R5 Insight #1 / F2 + User Decision #2. **Anchors:** R5 §7 F2 line 390; `next.md:614-617`; `architect.md`; `PLAN_META.schema.json`.
**Why:** METR RCT — naive "5 successes → escalate" over-trusts AI exactly where caution is needed. Plus: non-programmer user requires plain-language modals, batched approvals, and rate-limiting to avoid Enter-fatigue defeat of the gate.
**Change:**
- Edit `framework/schemas/PLAN_META.schema.json` — add `task.task_class: enum["A","B","C","D"]` (required).
  - **A** — Low-risk codegen: unit tests, CSS, boilerplate, DTOs, logging, docs.
  - **B** — Medium-risk: CRUD endpoints, feature impl, standard refactor.
  - **C** — High-risk systemic: auth, payments, security, schema, infra, concurrency.
  - **D** — Irreversible (maps to existing `is_irreversible` flag): deploy, schema migration, feature-flag toggle.
- Edit `framework/agents/architect.md` Step 1.8 (new) — classification rules: spec-language heuristic + LLM agreement. Output: `task.task_class` in PLAN_META.
- Edit `framework/commands/apex/next.md:471-490, 614-617, 730-763` — replace global counter with per-class ladder:
  - Track A: escalate after 5 clean (≤20% rework) → Trusted/Autonomous.
  - Track B: escalate after 7-8 clean → Trusted (cap).
  - **Track C: NO auto-escalation.** Mandatory plan review, permanent Supervised cap.
  - **Track D: NO auto-escalation, ever.** Maps to existing `is_irreversible == true` hard cap.
- Add asymmetric de-escalation triggers (immediate):
  - critical regression in track,
  - security vulnerability,
  - 2 consecutive high-rework (>50% manual correction),
  - 2-3 critic disagreements in short window.
- New STATE field `STATE.autonomy.by_task_class[A|B|C|D].consecutive_successes`.

**Sub-task M08.1 (NEW — per User Decision #2):**
- **Plain-language Track D modal** — instead of programmer-language ("verify_level D, is_irreversible=true, hard cap"), present in user's language:
  > 🛑 **פעולה לא הפיכה:** {ONE-SENTENCE description in plain language, e.g., "אני עומדת להעלות את הקוד לפרודקשן — אחרי זה אי אפשר לחזור אחורה בלחיצה אחת"}
  >
  > רוצה להמשיך?
  > [`כן, להמשיך`] [`לא, עצור`] [`הסבר עוד`]
- **Batching at phase boundary:** Track D approvals that **can** wait (e.g., "delete deprecated file") batch into `.apex/pending_track_d.json`; presented as one sequential approval list at next phase boundary OR end-of-session. Only deploy/migration/flag-toggle bypass batching (immediate).
- **Rate-limit:** maximum 1 Track D modal per 30 minutes of work. If a 2nd Track D event arises, defer to next 30-min window; only fire immediately if `task.is_irreversible_now == true` (cannot be deferred).
- **Budget:** `STATE.autonomy.track_d_modals_today` counter. After 3 modals in 4 hours → switch to digest mode (events logged to `event-log.jsonl` with severity=MAJOR for batched M10 review, not modal).
- **Plain-language explanations** built from `task.description` (architect-authored in plain Hebrew/English from M08 Step 1.8) + risk-tag (auth/payments/deploy/schema/flag).

**Accept:**
1. PLAN_META validation requires `task_class` for every task.
2. `framework/tests/test-task-class-autonomy.sh`: 5 successful A-tasks → autonomy[A] advances; 8 successful C-tasks → autonomy[C] stays at Supervised.
3. Critic disagreement injection → immediate de-escalation.
4. `framework/tests/test-track-d-modal.sh`: simulate 5 Track D events in 1 hour → at most 2 modals fire (rate-limit honored); rest batched.
5. Track D modal text contains 0 programmer-jargon tokens (`verify_level`, `is_irreversible`, `cap`, etc.); contains ≥1 plain-language description from architect output.
6. health-check test #38 — "Track A/B/C/D autonomy enforced; D modal plain-language + rate-limited" — passes.

**Effort:** 3-4 days (was 2-3; +1 day for sub-task M08.1 UX).
**Deps:** none. Synergy with M10 (severity tiers — batched Track D events flow through MAJOR digest path).

---

#### M09 · Risk-Based Comprehension Gate [P0, M]
**Pred:** R5 Insight #2 / F1. **Anchors:** R5 §3 (Anthropic RCT 86% vs 24%), §7 F1; `next.md:851-874`.
**Why:** ה-gate היום בוחר top-3 diff (LOC-based). R5 דורש risk-based: criticality wins over size. ופורמט mandatory explanation, לא 'y'.
**Change:**
- Edit `framework/commands/apex/next.md:851-874` — replace gate with **risk-weighted, generation-then-comprehension** protocol:
  - **File selection:** by criticality, not LOC. Criteria (in order): tagged high-risk domain (auth/payments/migrations/schema) > large semantic diff > central to new architectural concept > files where critic disagreed.
  - **Use existing TDAD impact + new `risk_classified_files[]`** from architect Step 0 (M08 adds this).
  - **Gate depth by `task_class`** (post-M08):
    - A (low): zero mandatory gate; lightweight post-execution diff.
    - B (medium): 1 critical file — purpose + key invariant + one failure mode.
    - C/D (high): 2 critical files + 1 integration point — purpose, invariants, failure modes, modification path, alternatives.
  - **Format (mandatory):** show AI-generated diff → prompt: *What does this code do? What invariant matters most? What could break? How would you modify it for [plausible change]?* → optional AI assist that developer **validates**.
  - **Cadence:** 1 substantial gate per **60-90min of new code OR phase boundary** (not per phase only). Batch related files into a single conceptual explanation.
  - **Time cap:** ≤10-15 min per gate.
  - **No more 'y' bypass.** Three responses only: `explain` (mandatory 1-3 sentences), `defer` (records gate as pending; auto-fires at next boundary), `skip` (only with `--force` flag; logs as cognitive-debt event).
- New STATE field — extend `comprehension_gates`:
  ```
  comprehension_gates: { phase_N: { gate_id, files_reviewed[], format: gen-comp, explanation_text, response_type: explain|defer|skip, duration_sec, criticality_score } }
  ```
- New hook `framework/hooks/comprehension-gate.sh` — scheduler firing the 60-90min cadence + criticality-based file selection.

**Accept:**
1. `framework/tests/test-comprehension-gate.sh`: 8-task auth feature → gate fires mid-phase on auth-critical file (60 LOC) over filler (200 LOC); skip requires `--force`; explain text saved.
2. health-check test #39 — "Gate selects by criticality not LOC; 'explain' captured in STATE" — passes.
3. Manual simulation per R5 Appendix E Sim 1: session storage (small LOC, auth-critical) **is** selected.

**Effort:** 2-3 days.
**Deps:** **M08** (task_class drives gate depth) + uses existing TDAD.

---

#### M10 · Severity-Tiered Error Communication (F5) [P0, L]
**Pred:** R5 Insight #4 / F5. **Anchors:** R5 §7 F5 line 488; all 46 hooks.
**Why:** signal-to-noise collapsed: 46 hooks shout "סכנה!" identically. Alert fatigue research: >50% false positives → dismissal heuristics → real CRITICAL ignored.
**Change:**
- New `framework/hooks/_emit_apex_event.sh` — central emitter with severity field:
  ```sh
  apex_emit_event <severity:CRITICAL|MAJOR|MINOR> <hook_name> <what> <where> <why> <next_actions>
  ```
- Severity registry per hook (~roundtable to classify each of 46):
  - **CRITICAL** (≤2-3 per half-day budget; immediate blocking modal): phantom-check, mutation-gate ≥threshold, schema-drift on closed schema, destructive-guard ↪ deny-list, prompt-guard fail, circuit-breaker first-fire.
  - **MAJOR** (passive yellow; surfaced at next phase boundary or `/apex:status`): decision-gate, ast-kb-check (advisory), cross-phase-audit, owner-guard, path-guard, workflow-guard, ci-scan.
  - **MINOR** (silent log; 45-90min digest; suppress repeats): post-write style, tdad-impact, learnings-emit, session-log, _state-update telemetry.
- New `framework/hooks/background-digest-hook.sh` — runs every 45min via cron-equivalent (or attached to soft-rotation); emits batched MINOR digest.
- Update `framework/hooks/event-log.jsonl` schema — add `severity`, `actions_recommended[]`, `dedup_key` fields.
- Each error includes: **what** (specific check/critic) + **where** (files/modules) + **why** (short explanation) + **next-best actions** (review, revert, add tests, lower autonomy).
- Suppress dedup: same `(hook_name, severity, dedup_key)` within 5min collapsed to 1 event.

**Accept:**
1. `framework/tests/test-severity-tiers.sh`: stub 12 hook events → CRITICAL ≤3 blocking, MAJOR ≥5 passive, MINOR ≥4 batched.
2. CRITICAL budget enforcement: 4th CRITICAL in <12h → emits secondary "CRITICAL budget exceeded" notice that itself becomes the only one shown.
3. health-check test #40 — "Severity registry exists and is enforced across all 46 hooks" — passes.

**Effort:** **L** (~3 weeks). Largest single item. May benefit from `/apex:_roundtable` to classify the 46 hooks.
**Deps:** none. Synergistic with M07 (status visualization).

---

#### M11 · `/apex:status` Progressive Disclosure (F4) [P0, S]
**Pred:** R5 Insight #3 / F4. **Anchors:** R5 §7 F4 line 454; `status.md:40-134`.
**Why:** 40+ data points always-on → cognitive load up, decision quality down.
**Change:**
- Edit `framework/commands/apex/status.md:40-144` — conditional rendering:
  - **Default view (5 signals):**
    1. Phase + goal
    2. Autonomy mode + brief reason (e.g., "Trusted for CRUD based on last 8 clean B-runs")
    3. Current task status (Building / Testing / Waiting for review)
    4. Last verification (pass/partial/fail + link)
    5. Context health (gauge from M07: 🟢 / 🟡 / 🔴)
  - **Advanced panel** — `--detailed` flag OR auto-surface on anomaly (CRITICAL alert / drift > 5% / autonomy de-escalated).
  - All current 40+ points still available via `--verbose`.
- New `.apex/STATUS_PREFS.json` (optional) — user can persist `--detailed` as default.
- Auto-surface logic: read `STATE.drift_indicators`, `quality.current_drift_pct`, `event-log.jsonl` recent CRITICAL → if any anomaly, show full panel by default until cleared.

**Accept:**
1. Default `/apex:status` renders 5 signals only.
2. `/apex:status --detailed` renders all panels.
3. After CRITICAL fire, default reverts to full panel until ack.
4. health-check test #41 — "Status default ≤5 signals; advanced panel reachable" — passes.

**Effort:** ~4-6 hours.
**Deps:** **M07** (gauge data); synergy with M10 (anomaly surface trigger).

---

### Wave 4 — Capability Extensions (R2 §9 Closure + Novel)

> רצים אחרי Wave 1+2 פעילים, אחרי M08 (task_class). סך הכל ~3-4 ימים.

#### M12 · Per-Task-Type Context Profiles [P1, M]
**Pred:** R06 ב-R2-RECOMMENDATIONS.md. **R2-anchors:** C026, C127-C137, C138, C233.
**Why:** R2 §9 missing piece #5. One-size-fits-all CONTEXT_BUDGET loads architecture docs for bug fixes (wasted) and broad system context for test-writing.
**Change:**
- Edit `framework/CONTEXT_BUDGET.default.json` — add top-level `profiles`:
  - `default`: current zones.
  - `new_code`: priority=[architecture_docs, interfaces, style_rules, examples, repo_map, existing_patterns]; exclude=[full_existing_implementations].
  - `bug_fix`: priority=[failing_tests, stack_traces, execution_path, minimal_dependency_chain]; exclude=[broad_architecture_docs]; budget shift: working_memory 70K, stable_prefix 20K.
  - `code_review`: priority=[spec_contract, diff, test_results, surrounding_functions]; exclude=[implementer_reasoning] (already enforced by clean-room).
  - `refactor`: priority=[dependency_graph, impact_set, current_tests]; exclude=[unrelated_modules].
  - `test_writing`: priority=[implementation_contracts, test_conventions, existing_tests, coverage_info]; exclude=[broad_system_architecture].
  - `frontend`: priority=[design_context_figma_mcp, component_hierarchy, style_guide]; exclude=[backend_internals]; pre-load `apex-frontend` module skills.
- Edit `framework/schemas/CONTEXT_BUDGET.schema.json` — add `profiles` mirror of the 6.
- Edit `framework/schemas/PLAN_META.schema.json` — add `task.task_type: enum[new_code|bug_fix|code_review|refactor|test_writing|frontend]`. Required.
- Edit `framework/agents/architect.md` — classify `task_type` per task (Step 1.9, new). Document classification heuristics.
- Edit `framework/agents/executor.md` + `next.md` — load `profiles[task.task_type]` merged over `default`.
- New `framework/docs/TASK-TYPE-PROFILES.md` — explains 6 profiles.

**Accept:**
1. `framework/tests/test-task-profiles.sh`: bug_fix task → executor prompt contains failing_tests content, no architecture_docs. new_code → opposite.
2. PLAN_META validation requires `task_type`.
3. health-check test #31 — "PLAN_META requires task_type; architect honors profiles" — passes.

**Effort:** 1-2 days.
**Deps:** none (independent). Synergy with M05 (different profiles invalidate different cache prefixes — document).

---

#### M13 · Memory Integrity Hardening [P1, M]
**Pred:** R07 ב-R2-RECOMMENDATIONS.md. **R2-anchors:** C081, C082-086 (MINJA), C211, C234.
**Why:** R2 §9 missing piece #6. Provenance + hash-invalidation + learnings backup + audit scope.
**Change:**
- Edit `framework/apex-learnings.md` schema-comment (lines 22-37) — add 6 fields per entry:
  - `Source agent:` (architect|critic|verifier|auditor|human|memory-synthesis)
  - `Created:` (RFC 3339)
  - `Last validated:` (RFC 3339)
  - `Code hash:` (SHA256 of cited code block at time of entry)
  - `Scope:` (PROJECT | ORG | GLOBAL — default PROJECT)
  - `Invalidates on:` (file_change | version_change | period | manual)
- Edit `framework/hooks/verify-learnings.sh` — hash-validation pass: for entries with `Code hash` → compute current hash → mismatch → `Status: STALE`; if STALE + age > decay-class → auto-archive to COLD.
- Edit `framework/hooks/pre-compact.sh` — extend backup list to include `~/.claude/apex-learnings.md` → `.apex/backups/apex-learnings_$TIMESTAMP.md`.
- Edit `framework/modules/apex-memory-synthesis/agent.md` — extend DREAM-CYCLE scope to include `apex-learnings.md`:
  - Cluster similar entries; flag conflicts (new `Conflicts with:` field).
  - Re-validate entries with Last validated > 30d if Decay class < 30d.
  - Promote WARM → HOT if Evidence count ≥ 2 (HOT < 30).
  - Demote HOT → WARM if Last validated > 6mo (non-safety).
- Edit `framework/agents/critic.md` — populate new fields when writing learnings.

**Accept:**
1. `framework/tests/test-memory-integrity.sh`: add learning with code_hash X → modify cited line → verify-learnings marks STALE → simulate decay → auto-archive.
2. memory-synthesis dream-cycle includes apex-learnings.md in scope.
3. health-check test #32 — "Learning entries have provenance + code_hash; verify-learnings detects stale" — passes.

**Effort:** ~1 day.
**Deps:** none. Synergy with M14 (atomic snapshots — both extend backup discipline).

---

#### M14 · Atomic Pre-Rotation Snapshot [P1, M]
**Pred:** R09 ב-R2-RECOMMENDATIONS.md. **R2-anchors:** C203.
**Why:** State preservation fragmented across 3 hooks; on rotation, the 4 artifacts (STATE + DECISIONS + git-tag + phase-summary) may be out of sync.
**Change:**
- New `framework/hooks/pre-rotation-snapshot.sh` — invoked by M06's `_rotation-decide.sh` BEFORE any context-reduction action. Atomic 4-step:
  1. Write fresh STATE.json (canonical).
  2. Flush pending decisions to DECISIONS.md.
  3. Create git tag: `apex/rotation/<timestamp>-<phase>`.
  4. Write `.apex/phases/<current>/ROTATION-NOTE-<timestamp>.md` (200-400 word R6-style: what's done, what's next, what issues).
- On any step failure: emit error, do **NOT** proceed with rotation. (Rotation is safe-or-noop.)
- Edit `next.md` Step F — call `pre-rotation-snapshot.sh` BEFORE `observation-mask` or `/compact`.
- Edit `framework/commands/apex/resume.md` — locate most recent `apex/rotation/*` tag + corresponding ROTATION-NOTE; load note as part of resume context.

**Accept:**
1. `framework/tests/test-pre-rotation-snapshot.sh`: trigger rotation → all 4 artifacts present; resume loads the note.
2. health-check test #34 — "Pre-rotation snapshot produces 4 atomic artifacts; resume consumes" — passes.

**Effort:** ~½ day.
**Deps:** **M06** (rotation triggers).

---

### Wave 5 — Future-Leverage (P2)

> רצים אחרי כל הקודמים נטמעו וייצבו. סך הכל ~1-2 ימים.

#### M15 · `/apex:fast` Auto-Detect Micro + Plain-Language Confirm (F3) [P0, M+]
**Pred:** R5 Insight #5 / F3 + **User Decision #1 (hybrid auto-detect + confirm)**. **Anchors:** R5 §7 F3 line 426.
**Why:** R5 says micro tasks deserve **zero pre-execution ceremony + mandatory lightweight batched post-execution review**. Current `/apex:fast` commits per-fix (clutter, slow ceremony) and has no batched review. **Per User Decision #1:** non-programmer cannot be expected to know when to type `--batch` — APEX detects automatically, shows the mode-shift in plain language, asks for confirm.
**Change:**
- Edit `framework/commands/apex/fast.md` — implement **auto-detection + visible-mode-shift confirmation**:
  - **Auto-detect "micro"** before execution starts: ≤2-3 files touched (estimated from task description), ≤20-30 LOC estimated change, no auth/security/payments/schema/migration/dep-direction/public-interface/build-config/control-flow keywords. (Architect runs the heuristic; if uncertain, default = NOT-micro.)
  - **If detected = micro:**
    - Show plain-language confirmation modal (one-time per session):
      > 🪶 **זיהיתי שזו משימת micro** (תיקון קטן, ≤{N} שורות, לא נוגעת באבטחה/תשלומים/database).
      >
      > → אני עוברת ל-**מצב batch**: רצף תיקונים בלי לעצור על כל אחד.
      > → אחרי שעה / 5 שינויים / 50 שורות אציג מסך אחד "אישר/בטל" לכל הקבוצה.
      >
      > [`כן, מצב batch`] [`לא, רץ רגיל`]
    - On `כן` → enter batch mode for the session.
    - On `לא` → standard `/apex:fast` (commit per-fix); remember choice for the session, don't re-ask.
    - Default action on Enter without input → `כן` (batch mode); rationale: optimal default per R5 § 4 (interaction pattern is the intervention).
  - **In batch mode:**
    - Zero pre-execution modal gates at L0 (same as current).
    - Background tests + static checks always run.
    - Accumulate diffs in `.apex/batch_queue.json` per session.
    - **Batch surface trigger:** per hour OR ≥5 changes OR ≥50 LOC total — whichever first.
    - Auto-displayed combined diff with one-click `approve / rollback / split-and-rollback-N`.
    - If async critic flags semantic-risk file → batch surfaced **proactively** (before threshold).
  - **Manual override:** `--no-batch` flag forces standard mode (advanced user); `--batch` flag forces batch mode (overrides detection); no flag = auto-detect.
- New `framework/agents/specialist/batch-verifier.md` — async critic agent that classifies each fix into semantic-safe vs flagged.
- New STATE field `STATE.session.batch_mode: enabled|disabled|asked` + `STATE.session.batched_tasks[]`.
- Behavioral test per R5 Sim 3.

**Accept:**
1. `framework/tests/test-fast-batch-autodetect.sh`:
   - Task "תקן 10 שגיאות CSS ב-`components/*.tsx`" → detected micro → modal shown once → on Enter → batch mode → 10 fixes → 2 batched reviews surface.
   - Task "תוסיף JWT auth ל-`/login`" → NOT detected as micro (auth keyword) → modal not shown → standard flow.
2. Modal not re-shown after user answered once per session.
3. `--no-batch` flag overrides detection.
4. health-check test #42 — "fast auto-detect + visible mode shift; no silent shifts" — passes.

**Effort:** 2-3 days (was 1-2; +1 for auto-detect + UX layer).
**Deps:** **M01** (token counter — feeds size heuristic), **M07** (dashboard exposure — shows batch state in status), **M08** (task_class — auth/payments/schema classification reuses M08 architect output).

---

#### M16 · Quality Drift Metric + Opt-Out Telemetry Foundation [P1, M+]
**Pred:** R12 + **User Decision #3 (opt-out telemetry from start)**. **R2-anchors:** C167, C214.
**Why:** R2-C214: "task#50 statistically indistinguishable from task#1 in quality" is THE ultimate APEX metric. Without it, can't measure whether M01-M15 achieve R2's promise. **Per User Decision #3:** telemetry is opt-out from the start (not v1.0-future); M16 becomes the foundation for the entire claim-validation infrastructure.
**Tier change:** P2 → **P1** (opt-out telemetry promotes this to architectural-priority; ties to M18.1 DORA validation).
**Change:**
- Extend `framework/schemas/STATE.schema.json` — new field `quality`:
  ```json
  "quality": {
    "rolling_window_tasks": [],
    "baseline_window_tasks": [],
    "current_drift_pct": 0,
    "alert_threshold_pct": 5
  }
  ```
  Each entry: `{task_id, confidence_score, verifier_pass, attempts, mutation_score?}`.
- Edit `framework/hooks/subagent-stop.sh` — on verifier/critic return, append to `quality.rolling_window_tasks` (FIFO, max 10). First 10 form `baseline_window_tasks` (frozen).
- New `framework/hooks/quality-drift.sh` — compute `drift_pct = (baseline_avg - rolling_avg) / baseline_avg`; if drift > 5% AND session > 20 tasks → fire `quality_drift` rotation event (consumed by M06's `_rotation-decide.sh`).
- Edit `framework/commands/apex/status.md` — render: "Quality drift: -2.3% (task #14/14, baseline 0.91, current 0.89)".

**Sub-task M16.1 (NEW — per User Decision #3): Opt-Out Telemetry Infrastructure**
- New `framework/docs/PRIVACY-POLICY.md` — full data inventory: what's collected (counters, drift_pct, timestamps), what's NOT (code, file names, project name, repo paths). Opt-out instructions.
- New `framework/hooks/_telemetry-emit.sh` — central writer to `.apex/telemetry.jsonl` (local by default).
  - Default-on: counters fire on every session_end, phase_complete, rotation event.
  - Opt-out: env var `APEX_TELEMETRY=off` OR `~/.claude/telemetry-opt-out.flag` file presence → emitter no-ops.
  - **Anonymization at emit time:** project name → `sha256(project_root_path)[0:8]`. No file paths.
- Edit `framework/commands/apex/start.md` + `framework/commands/apex/onboard.md` — show one-time notification on first run:
  > 🔍 **APEX אוסף מטריקות אנונימיות** (כמות טסטים, מספר rotations, success rate) כדי לשפר את עצמו.
  >
  > אין מידע על הקוד שלך או על שמות פרויקטים.
  > לבטל: `apex telemetry off` או `/apex:help telemetry`.
  > למסמך מלא: [PRIVACY-POLICY.md](.../docs/PRIVACY-POLICY.md)
- Edit `framework/commands/apex/help.md` — new `telemetry` topic with full opt-out flow.
- **Remote shipping is opt-in nepart:** `APEX_TELEMETRY_REMOTE=on` + endpoint URL. Without it = local-only. (This protects users from accidental leakage in v0.1.x — local data is theirs.)

**Accept:**
1. `framework/tests/test-quality-drift.sh`: stub baseline 10×high → rolling 5×high + 5×low → drift_pct > 5% → rotation event.
2. `framework/tests/test-telemetry-opt-out.sh`: with `APEX_TELEMETRY=off` → `.apex/telemetry.jsonl` not modified after session_end.
3. `framework/tests/test-telemetry-anonymization.sh`: stub project_root_path → emit → grep `.apex/telemetry.jsonl` for literal path or project name → 0 matches; grep for sha256 prefix → match.
4. PRIVACY-POLICY.md exists and is delivered to `~/.claude/` via `sync-to-claude.sh` (extends `copy_tree docs/`).
5. health-check test #37 — "Quality drift instrumented + opt-out telemetry honored + anonymization enforced" — passes.

**Effort:** ~2 days (was 1; +1 day for opt-out infrastructure + privacy doc + tests).
**Deps:** **M01, M06, M07** (counter + rotation triggers + dashboard).

---

#### M17 · Anthropic Context Editing API [P2, M]
**Pred:** R11. **R2-anchors:** C099, C156.
**Why:** Sep 2025 Anthropic API for context editing — 84% token reduction in 100-turn eval. Synergistic with M02 (observation masking is DIY of the same idea; context editing is API-native).
**Change:**
- Research first: read latest Anthropic docs for context editing surface (post-R7); identify which Claude Code SDK calls expose it.
- New `framework/docs/CONTEXT-EDITING.md` — protocol documentation.
- Edit `framework/hooks/observation-mask.sh` (from M02) — prefer Anthropic context editing API when running on a harness that exposes it; fall back to local masking otherwise.
- Edit settings.json — opt into context editing flag.

**Accept:**
1. `framework/tests/test-context-editing.sh`: long task with simulated tool outputs → context editing API invoked, token count drops.
2. health-check test #36 — "Context editing active on supporting harnesses" — passes.

**Effort:** ~½-1 day depending on SDK surface.
**Deps:** **M02** (observation masking foundation).

---

### Standalone — Closures

#### M18 · `apex-spec.md` Aspirational-Claim Strengthening [P0, S]
**Pred:** R5 Insight #6 + #7 + **User Decision #4 (keep aspirational claim + add measurement)**. **Anchors:** R5 §5.4, §9 Gap #7; `apex-spec.md:9, 375, 379`; README L29.
**Why:** **Per User Decision #4:** the DORA claim is the **mission**, not the **marketing**. Don't soften — strengthen by attaching measurement infrastructure that makes the claim falsifiable and actionable.
**Change:**
- `apex-spec.md:375` — **strengthen** the claim with explicit measurement context (NOT replace):
  > **"The First Framework That Improves DORA."** *Aspirational target backed by an active measurement program.*
  >
  > **Baseline:** DORA 2024 found AI adoption correlates with -7.2% delivery stability (~39K respondents).
  > **Goal:** reverse this decline through structured verification + risk-based autonomy.
  > **Method:** 4 DORA metrics tracked per project via opt-out telemetry (DEFAULT-ON; see [PRIVACY-POLICY.md](.../docs/PRIVACY-POLICY.md)).
  > **Validation timeline:** N≥10 teams enrolled by Q3 2026; first published cohort report Q1 2027.
  > **Honesty contract:** if the published report fails to demonstrate DORA improvement, this claim is rephrased to reflect actual evidence within 30 days of publication.
- `apex-spec.md:9` — strengthen "non-technical user succeeds in first session" similarly:
  > "Designed for non-technical users to complete a first concrete deliverable within first session. **Success metric:** shipped artifact + checkpoint advance + zero CRITICAL events. **Validation:** N≥30 cohort study (Q3 2026 enrollment, Q2 2027 report). **Honesty contract:** same as DORA above."
- `apex-spec.md:379` — strengthen "First Framework Hardened Against Its Own Files":
  > "Multi-layer prompt-injection defense (apex-prompt-guard.cjs + workflow-guard.sh + ci-scan.sh + security.cjs + path-guard.sh). **Validation:** independent red-team audit by Q4 2026. **Honesty contract:** same as above."
- README L29 — mirror (with link to PRIVACY-POLICY.md and CLAIMS-MEASUREMENT.md).

**Sub-task M18.1 (NEW — per User Decision #4): DORA Measurement Engine**
- New `framework/docs/CLAIMS-MEASUREMENT.md` — single source of truth for all 3 claims' measurement methodology, N targets, milestones, current status.
- New `framework/hooks/dora-collect.sh` — runs on every commit + `/apex:milestone-summary`:
  - **Deployment Frequency:** count tags matching `release/*` / `deploy/*` per week.
  - **Lead Time for Changes:** for each merged commit, time from first-commit-in-branch → tag.
  - **Change Failure Rate:** count `revert ` / `hotfix ` / `rollback ` commits / total commits.
  - **Time to Restore Service:** time between first `revert`/`hotfix` and next forward tag.
  - All aggregated into `.apex/DORA.json` (anonymized per M16.1 opt-out).
- Edit `framework/commands/apex/milestone-summary.md` — render DORA quartet in milestone report.
- Edit `framework/commands/apex/ship.md` — at ship time, emit DORA delta vs. prior ship to `.apex/telemetry.jsonl` (gated by opt-out).
- New `framework/tests/test-dora-collect.sh` — 4 fixture repos (greenfield, mature, broken-deploys, fast-recovery) → assert DORA quartet values match expectations.

**Accept:**
1. All 3 claims appear in `apex-spec.md` with measurement context (no naked aspirational claims).
2. `framework/docs/CLAIMS-MEASUREMENT.md` exists with full methodology per claim.
3. `framework/docs/PRIVACY-POLICY.md` exists (delivered by M16.1).
4. `.apex/DORA.json` auto-populates with the 4 metrics in a sample project.
5. `framework/tests/test-dora-collect.sh` passes.
6. health-check test #44 (NEW) — "All 3 aspirational claims have measurement plan + honesty contract" — passes.

**Effort:** ~6-8 hours (was 1; +5-7 for measurement engine, privacy mirror, tests, doc).
**Deps:** **M16.1** (telemetry opt-out infrastructure — both M18.1 and M16.1 deliver `PRIVACY-POLICY.md`; coordinate).

---

#### M19 · Close security-specialist Module (R7 F-002 P1) [P1, M-L]
**Pred:** R5 Insight 7 do-now #7. **Anchors:** R7 audit F-002; `framework/modules/apex-security/`.
**Why:** R7 left this open. R5 echoes: Pearce 40% AI vulns + Apiiro +322% privilege-escalation paths + Veracode 45% — security is not "nice-to-have".
**Change:**
- Fix lint failures in 6 modules under `apex-security/`.
- Replace `THREAT_MODEL.template.md` with auto-filled-from-risk-classified-files via architect Step 1.10 (new — depends on M12 task_type=frontend/auth/etc.).
- Wire `ci-scan.sh` as PostToolUse hook (async), not manual.
- Make negative-auth tests **blocking** at verify_level C/D (currently advisory in workflows).

**Accept:**
1. `framework/scripts/self-test.sh` → all security module tests pass (after R7-001 subshell isolation fix already merged).
2. New PLAN_META field `security_envelope` populated for tasks classified C/D in M08.
3. `framework/tests/test-security-specialist.sh` — full module coverage.
4. health-check test #43 — "Security specialist active for C/D tasks; negative-auth blocking" — passes.

**Effort:** ~2-3 days (M-L given the lint debt + threat model auto-fill).
**Deps:** **M08, M12**.

---

### Backlog — Deferred Below the 19-cap (re-evaluate per trigger)

| Item | Source | Why deferred | Re-evaluate when |
|---|---|---|---|
| Aider-style AST + PageRank repo map | R2-C065/C066, R5 #10 | L-effort, R6 P2-3 already acknowledged | Project surpasses 100K LOC |
| Two-pass critic with conditional reveal | R2-C124/C207 | M-effort, no measured pain at single-pass | Verifier-disagreement rate > 10% in real projects |
| Vector/semantic retrieval (T4) | R2-C072/C075 | L-effort | When patterns library > 100 entries |
| Code-review parallel personas (security/arch/perf) | R2-C208, R5 §3 Sim 5 | L-effort; security persona for D-level critic exists | After M04 model-diversity proves insufficient |
| TiCoder-style test-first generation loop | R2-C146 | L-effort; TDAD already addresses 70% | If pass@1 plateaus despite M01-M17 |
| Letta git-worktree memory | R2-C080/C116 | L-effort, exotic; `/apex:new-workspace` already uses worktrees for code | Cross-project memory becomes bottleneck |
| Token-efficient tool use (14% reduction) | R2-C098 | S-effort but coupled with M04 model routing | Bundle with M04 retest |
| Cognitive-debt detector hook | R5 §7 #5 (user decision §7 #5) | User decision pending | After M09 (gates emit cognitive-debt events as inputs) |
| Workflow Track-C discipline | R5 Insight #9 | depends on M08 deployment | After M08 stabilizes; update 7 high-risk recipes |
| Telemetry layer (cycle_time, rework_pct, regression_count) | R5 §7 #3 | User decision (opt-in vs opt-out) | Before publishing DORA-reversal claim |

---

## 4 · רצף ביצוע מומלץ (rollout sequence)

### Wave 1 — Foundation (יום 1-3, מקבילי)
1. **M01 — Token counter** (M, ~½ day) — unlocks M02/M05/M06/M07.
2. **M02 — Observation masking** (M, ≤1 day) — independent, combine with M05 for max win.
3. **M03 — Architect 30K cap** (S, 30 min) — independent quick win.
4. **M04 — Model diversity** (S, 30 min) — independent quick win.

### Wave 2 — Activation (יום 3-5, רץ אחרי Wave 1)
5. **M05 — Prompt caching** (M, ½-1 day) — depends on M01.
6. **M06 — Activate rotation thresholds** (S, 2-3 hrs) — depends on M01+M02.
7. **M07 — Context Health Dashboard** (S, 2-3 hrs) — depends on M01+M05.

### Wave 3 — Evolution (יום 5-9, רץ אחרי Wave 1, מקבילי ל-Wave 2)
8. **M08 — Track A/B/C autonomy** (M, 2-3 days) — independent.
9. **M09 — Risk-based comprehension gate** (M, 2-3 days) — depends on M08.
10. **M10 — Severity tiers** (L, ~3 weeks; can stretch) — independent; biggest item.
11. **M11 — Status progressive disclosure** (S, 4-6 hrs) — depends on M07+M10.

### Wave 4 — Capability (יום 9-12, רץ אחרי Wave 1+2+M08)
12. **M12 — Task-type profiles** (M, 1-2 days) — independent.
13. **M13 — Memory integrity** (M, ~1 day) — independent.
14. **M14 — Atomic pre-rotation snapshot** (M, ½ day) — depends on M06.

### Wave 5 — Future-Leverage (יום 12-15)
15. **M15 — `/apex:fast` auto-detect + confirm** (M+, 2-3 days) — depends on M01+M07+M08.
16. **M16 + M16.1 — Quality drift + opt-out telemetry** (M+, ~2 days) — depends on M01+M06+M07. **Now P1 per Decision #3.**
17. **M17 — Context editing API** (M, ½-1 day) — depends on M02.

### Standalone (יום 1, יום 12+)
18. **M18 + M18.1 — Spec aspirational strengthening + DORA engine** (S+M, ~6-8 hrs) — depends on M16.1 (shares PRIVACY-POLICY.md).
19. **M19 — Security-specialist closure** (M-L, 2-3 days) — depends on M08+M12.

**Total nominal:** ~14-18 working days (was 12-16; +2 for Decision-driven UX/telemetry sub-tasks).
**With M10 stretched over ~3 wks (its true scope):** parallel-track Wave 4-5 to fit.

### Decision-driven sub-tasks (added per User Decisions)

| Sub-task | Decision | Parent | Effort |
|---|---|---|---|
| **M08.1** — Plain-language Track D modal + batching + rate-limit | #2 | M08 | +1 day |
| **M15** auto-detect + confirm (replaces simple `--batch` flag) | #1 | M15 | +1 day |
| **M16.1** — Opt-out telemetry infrastructure + PRIVACY-POLICY.md | #3 | M16 | +1 day |
| **M18.1** — DORA Measurement Engine + CLAIMS-MEASUREMENT.md | #4 | M18 | +5-7 hours |

These are not "extra" items — they are the discipline that **makes the parent items honest under the user's UX constraints + the user's mission framing**.

### Critical-Path Diagram

```
                         M01 ── M05 ── M07 ── M11
                          │      │      │
                          ├──────┴──────┤
                          │             │
                          M02 ─── M06 ──┤
                                  │     │
                                  M14   │
                                        │
M03 (parallel)                          │
M04 (parallel)                          │
M08 ──┬── M09                           │
      └── M19                           │
M10 ── M11 ───────────────────────────  │
M12 ──┴── M19                           │
M13                                     │
                                        │
                  M15 ──┐               │
                        ├── M16 ──── (drift detection live)
                  M17 ──┘
M18 (anytime, prefer early)
```

---

## 5 · מטריקות הצלחה — איך נדע שזה עבד

### KPIs מדידים אחרי כל גל

| גל | KPI מרכזי | יעד | מקור-מדידה |
|---|---|---|---|
| Wave 1 | `tokens.total_input > 0` ב-STATE | 100% מהמשימות | M01 acceptance #1 |
| Wave 1 | Architect prompt size ≤ 30K | 100% | M03 acceptance |
| Wave 1 | Stale tool-results masked per `OBSERVATION_MASKING_WINDOW` | ≥95% | M02 acceptance #1 |
| Wave 2 | Prompt cache hit rate from task #2 | > 80% | M05 acceptance |
| Wave 2 | Rotation triggers consume real `pct`, not task-count proxy | 100% | M06 acceptance |
| Wave 2 | `/apex:status` Context Health gauge renders 8 metrics | 100% | M07 acceptance |
| Wave 3 | Track C/D never auto-escalates | 100% | M08 acceptance #2 |
| Wave 3 | Comprehension gate selects by criticality, not LOC | manual sim per R5 App E | M09 acceptance |
| Wave 3 | CRITICAL alerts ≤ 2-3/half-day budget | per-session | M10 acceptance |
| Wave 3 | Default `/apex:status` ≤ 5 signals | always | M11 acceptance |
| Wave 4 | `task_type` mandatory in PLAN_META | 100% | M12 acceptance |
| Wave 4 | Learning entries have `Code hash` + provenance | 100% | M13 acceptance |
| Wave 4 | Pre-rotation produces 4 atomic artifacts | 100% | M14 acceptance |
| Wave 5 | `/apex:fast --batch` surfaces ≤ 2 reviews per 10 micro-fixes | per-session | M15 acceptance |
| Wave 5 | Quality drift detection live; alerts at >5% drift | per-30-task session | M16 acceptance |

### Composite metrics (R2 Context Health Dashboard, M07)

After Wave 1+2:
- **Cache efficiency:** > 80% hit rate (R2-C092 break-even).
- **Token cost per task:** -40% to -60% vs. baseline (combined M02 + M05).
- **Latency per call:** -50% to -85% (caching).
- **R2 §9 missing pieces closed:** 3 of 6 (Observability ✓, Proactive Rotation ✓, Observation Masking ✓; Clean-Room already ✓ pre-existing → 4 of 6).

After Wave 4:
- **R2 §9 missing pieces closed:** 5 of 6 (adds Task-Adaptive + Memory Integrity). Only Aider-AST deferred.
- **R5 do-now items closed:** 6 of 7 (F1, F2, F4, F5, DORA-claim, self-test-runner; F3 in M15).

After Wave 5 + M19:
- **All R5 do-now closed.**
- **R5 evidence-gap #7 (DORA reversal) becomes measurable** for the first time.

### Ultimate APEX Metric (M16)

R2-C214: "task#50 statistically indistinguishable from task#1 in quality." After all 19, `quality.current_drift_pct` should remain < 5% across sessions of ≥ 50 tasks. **Until this is measured, no claim of "framework that prevents context rot" should appear in apex-spec.md.**

---

## 6 · החלטות המשתמש (לאחר אישור 2026-05-15)

### החלטה #1 — F3 Implementation Path → **מסלול היברידי "Auto-detect + Confirm"**

**רציונל המשתמש:** משתמש APEX הוא non-programmer. אם הוא יצטרך להחליט מתי להפעיל `--batch` — הוא לא יידע, ויפעיל לא-נכון או בכלל לא. אבל R5 מזהיר נגד silent mode-shifts. הפתרון חייב לאחד את שני הצדדים.

**ההחלטה הסופית (חדשה — לא A/B/C כפי שניתנו):**
- APEX **יזהה אוטומטית** אם המשימה היא "micro" (≤2-3 קבצים, ≤20-30 LOC, לא נוגעת ב-auth/security/payments/schema/migrations/deps/interfaces/build).
- כשהיא מזוהה כ-micro — APEX **מציג למשתמש הודעה ברורה בעברית פשוטה לפני שמתחיל**:
  > 🪶 **זיהיתי שזו משימת micro** (תיקון UI קטן, ≤20 שורות, לא נוגעת באבטחה/תשלומים/database).
  > → אני עוברת ל-**מצב batch**: רצף תיקונים בלי לעצור על כל אחד, ואחרי שעה / 5 שינויים / 50 שורות אציג לך מסך אחד "אישר/בטל".
  > → להמשיך במצב הזה? (`כן` / `לא, רץ רגיל`)
- ברירת המחדל: `כן`. ב-Enter מאשרים. אבל ה-shift גלוי.
- אם המשתמש לחץ `לא` פעם אחת בסשן — APEX זוכר ולא מציע שוב באותה סשן.
- **ל-M15 נוסף sub-task M15.1: "Auto-detect + plain-language confirmation modal"** (ראה §3 — M15 עודכן).

→ הניסוח החדש משלים את ה-spec של R5: זיהוי אוטומטי **קיים** (אז המשתמש לא צריך לדעת), הצגה למשתמש **קיימת** (אז אין silent shift), וברירת מחדל היא ה-batch (אז ה-velocity מושגת).

---

### החלטה #2 — Track D Forbidden-Forever → **כן, עם UX לא-מעצבן**

**רציונל המשתמש:** הסכמה ל-Track D, **אבל** עם שני אילוצי UX נוספים:
1. ההצגה למשתמש חייבת להיות בשפה פשוטה — לא דילמות-מתכנת (אחרת ילחץ Enter אוטומטית = הגנה אבודה).
2. אסור שזה ייכנס בכל שניה ויקטע את רצף העבודה.

**ההחלטה הסופית:**
- Track D נשאר כפי שתוכנן ב-M08 (אף פעם לא autonomy escalation אוטומטי).
- **UX חדש למודאל Track D (חידוד M08):**
  - **הודעה בעברית פשוטה:** "🛑 הפעולה הזו לא ניתנת לביטול: [מה הולך לקרות, במשפט אחד]. רוצה להמשיך? (`כן` / `לא` / `הסבר עוד`)"
  - **batch גם לזה (חידוש):** APEX **מקבץ** את כל אישורי Track D של phase לבדיקה אחת בסוף השלב. רק כשאי-אפשר לדחות (deploy, migration) — מאשרים בנקודה.
  - **קצב מקסימלי:** מודאל Track D = **≤1 פעם ב-30 דקות**. יותר מזה = רע (זה fatigue).
  - **תקציב:** ≤3 מודלים בסשן של 4 שעות. אם הגענו ל-3, APEX **מסכם** את האחרים בדו"ח-סוף-סשן.
- **לא-מעצבן** מתעצב לפי R5 § 4 + R2-C212 (Context Health) — שיתקבל ב-M10 בכל מקרה (severity tiers), אז מובנה.
- **ל-M08 נוסף sub-task M08.1: "Plain-language Track D modal + batching with rate-limit"** (ראה §3 — M08 עודכן).

→ ההיגיון: ההגנה לא קיימת אם המשתמש לוחץ אוטומטית. רק כשמודאל **נדיר + ברור + מובן** הוא באמת הגנה.

---

### החלטה #3 — Telemetry: **Opt-out (מההתחלה)**

**רציונל המשתמש:** "Opt-out (לקראת v1.0): ברירת מחדל לאסוף נתונים אנונימיים. אם משתמש רוצה לבטל, הוא מבטל. יותר נתונים אבל חייב מסמך פרטיות ברור."

**ההחלטה הסופית (שינוי מההמלצה המקורית):**
- **Opt-out מההתחלה** (לא רק ב-v1.0). אנונימי בלבד.
- חובה לפני הטמעה: `framework/docs/PRIVACY-POLICY.md` מפורט — מה נאסף, מה לא, איך מבטלים, איך מוחקים נתונים-עבר. ההצהרה מקבלת `apex-prompt-guard.cjs` תיקוף אחת לתקופה כדי לא לזחול.
- מנגנון opt-out: env var `APEX_TELEMETRY=off` + `~/.claude/telemetry-opt-out.flag` (אם הקובץ קיים = כיבוי).
- **הודעה בהתקנה ראשונה** (`/apex:start` או `/apex:onboard`): "🔍 APEX אוסף מטריקות אנונימיות (כמות טסטים, מספר rotations, success rate) כדי לשפר את עצמו. אין מידע על קוד או על פרויקט. לבטל? `apex telemetry off`. למסמך מלא: `/apex:help telemetry`."
- נתונים נאספים בלבד: counters (טסטים, rotations, cache hits), aggregated drift_pct, פעולות-זמן (לא תוכן). שום קוד, שום שמות-פרויקט, שום שמות-קבצים.
- יעד אחסון: ניתן להגדרה. ברירת מחדל = local-only ב-`.apex/telemetry.jsonl` (לא שליחה). שליחה לשרת APEX = opt-in נפרד.
- **משפיע על:** M16 (quality drift) נטמע **מההתחלה כ-opt-out** (לא רק כ-future). ניתוח ה-quality drift הופך לפיצ'ר ברירת-מחדל. → ראה M16 ב-§3.
- **R-item חדש: M16.1 — PRIVACY-POLICY.md + opt-out infrastructure** (תלוי ב-M16, חייב להיות מוטמע ביחד או מוקדם יותר).

---

### החלטה #4 — DORA Claim Treatment → **השאירו את השאיפה, הוסיפו את המדידה**

**רציונל המשתמש:** "זה מה שאנחנו רוצים שיהיה — APEX = First Framework That Improves DORA. כרגע לא יכולים להוכיח, אבל צריכים לכוון לשם. נאסוף נתונים ונשפר את עצמנו עד שנגיע."

**ההחלטה הסופית (שינוי מההמלצה המקורית — לא רוככה לחלוטין):**
- **השאירו את הניסוח השאפתני** ב-`apex-spec.md:375` (`"The First Framework That Improves DORA"`) — אבל **הוסיפו לידו immediately את הקונטקסט המודד**:
  > "**The First Framework That Improves DORA** — *aspirational target backed by an active measurement program.* Baseline: DORA 2024 found AI adoption correlates with -7.2% delivery stability. Goal: reverse this. Method: 4 DORA metrics tracked per project via opt-out telemetry (DEFAULT-ON; see PRIVACY-POLICY.md); N≥10 teams enrolled by Q3 2026; first published cohort report Q1 2027."
- **משימה משלימה חדשה — M18.1: "Build the measurement engine for DORA claim validation"**:
  - `.apex/DORA.json` — auto-collected per project: deployment_frequency, lead_time_for_changes, change_failure_rate, time_to_restore.
  - שאיבה אוטומטית מ-git log + STATE.session events (כבר קיים — צריך רק to aggregate).
  - `/apex:milestone-summary` ב-end-of-milestone אוסף ל-aggregate למיפוי N=10.
  - **Opt-out** מ-החלטה #3 חל גם כאן.
- **M18 משתנה מ-"reset" ל-"strengthen + back the claim with infrastructure"**:
  - השורה שמוסיפים = הוכחה שזה לא marketing-fluff. השאיפה מקבלת ranking ב-honesty index של APEX.
  - הטענות האחרות הסותרות-ראיות (`apex-spec.md:9` "first-hour success" ו-:379 "Hardened Against Its Own Files") **כן עוברות רכון** באותו רוח: aspirational + measurement plan.
- → ראה M18 ו-M18.1 ב-§3.

→ ההיגיון: שאיפה ללא מדידה = marketing. שאיפה **עם מדידה** = mission. ההבדל הוא ה-infrastructure ש-APEX בונה לעצמו.

---

### החלטה #5 — Cognitive-Debt Detector → **כבוי כברירת מחדל, optional**

**רציונל המשתמש:** "ברירת מחדל כבוי. משתמש שרוצה — מפעיל. נאסוף נתונים שנה ונחליט לגרסה בעתיד."

**ההחלטה הסופית (תואם להמלצה המקורית):**
- Hook לא מוטמע ב-Wave 1-5 הראשי.
- ה-comprehension gate ב-M09 **כן** יכתוב cognitive-debt events ל-`event-log.jsonl` (skip events עם reason). אלה הנתונים שיאספו במשך השנה.
- אחרי שנה — review: אם events מצביעים על pattern → להטמיע hook ב-v1.0; אחרת — להוציא לחלוטין.
- → M09 כותב את ה-data; ה-hook עצמו נשאר ב-backlog (§3 — backlog table updated).

---

## 7 · Risk Register

| סיכון | סבירות | חומרה | מיטיגציה |
|---|---|---|---|
| M02 (observation masking) מבטל context שצריך לטעמ של agent | בינוני | בינוני | Fail-safe: agent יכול לקרוא מהדיסק. Window 3 turns (קטן). Always-disk re-read enforced per critic.md:12 + executor.md:91-93. |
| M05 (prompt caching) מציג cache hit על stale-CLAUDE.md | נמוך | בינוני | Caching invalidates on CLAUDE.md change (hash-based). Document in PROMPT-CACHING.md. |
| M08 (Track A/B/C classifier) מסווג CRUD-task כ-Track C (false-positive) | בינוני | נמוך | Architect classification + LLM agreement (2-pass). Manual override per-task with `task.task_class_override`. Audit FP rate target < 5%. |
| M10 (severity tiers) מסווג חיוני כ-MAJOR בטעות → מוסתר | בינוני | גבוה | Roundtable per hook for initial classification. CRITICAL budget ≤2-3 forces conservative classification — anything genuinely critical wins out. Re-classify-on-evidence loop. |
| M15 (batched mode) מצבר 50 LOC בקובץ קריטי בלי human review | נמוך | קריטי | "Bumped out automatically" criteria: auth/security/payments/schema/dep-direction/etc. Async critic flags semantic risk. Background tests after each fix. |
| M16 (drift metric) פותר positive על noise כיוון quality-score לא מובנה | בינוני | נמוך | rolling_avg over ≥10 tasks; alert threshold 5%; opt-in pause behavior, opt-out telemetry. |
| Wave-3 simultaneous deployment of M08+M09+M10+M11 = overwhelming change | בינוני | גבוה | Wave-3 staged: M08→M09→M11→M10 (M10 stretches). Health-check test gates each step. |
| Cross-platform breakage (Windows OneDrive) | בינוני | בינוני | Cross-platform first principle: every new hook tested in PowerShell + bash. Build-validators in CI. |

---

## 8 · Limitations — מה לא יענה גם אחרי כל ה-19

R2 §9 ו-R5 §9 מצהירים על 8+8 פערי-מחקר. אחרי 19 ה-M-items, השאלות הבאות **עדיין פתוחות** כי המחקר עצמו לא ענה:

1. **Long-term learning curves** (R5 #1) — מצריך N≥30 longitudinal study.
2. **Optimal gate cadence** (R5 #2) — 60-90min הוא best-effort heuristic.
3. **Exact autonomy thresholds** (R5 #3) — 5/7-8/∞ הם heuristic; אין RCT שמאמת.
4. **APEX-style pipeline validation** (R5 #4) — APEX יכולה להיות המחקר הראשון שמפרסם נתונים על זה.
5. **Long-project comprehension decay** (R5 #5) — M16 (quality drift) הוא המכשיר הראשון שיוכל למדוד.
6. **Exact LGTM rates** (R5 #6) — critic-pass-without-explanation rate הוא proxy אחרי M09.
7. **Organizational throughput recovery (DORA reversal)** (R5 #7) — מצריך telemetry layer (החלטה #3).
8. **Multi-tool interaction effects** (R5 #8) — לא רלוונטי ל-APEX (pipeline-only).

M16 (quality drift) הוא המכשיר היחיד שאחרי הטמעה יאפשר ל-APEX **בעצמו** לתרום נתונים לגישור על פערים אלה.

---

## 9 · Validation — איך אתה יודע שזה גמור

### Gate A — Coverage
- כל 235 ה-R2 claims ממופים (R2-APEX-GAP-MATRIX.md verified — 235/235 = 100%).
- כל 7 R5 consensus findings מטופלים: F1=M09, F2=M08, F3=M15, F4=M11, F5=M10.
- כל 6 חוסרי R2 §9 מטופלים: #1=M01+M07, #2=M06, #3=M02, #4 (pre-existing, no action), #5=M12, #6=M13.

### Gate B — Concreteness (LMG triad)
- כל M-item יש לו: **file paths concrete** + **specific change** + **acceptance test ID** + **health-check #**.
- 0 phrases of type "TODO/consider/maybe/perhaps" ב-`Change` blocks (verified at write time).

### Gate C — Anti-Bloat
- 19 M-items ≤ 20-cap. ✓
- Backing strength: כל M-item מבוסס על ≥1 HIGH או ≥3 MED מקורות. אין M-item על single-source LOW.
- Tier distribution: P0 (10), P1 (5), P2 (2), P0-S (M18). Heavy P0 — מוצדק לסגירת theatre + R5 contradiction.
- Backlog quarantine: 10 items explicit, כל אחד עם re-evaluation trigger.

### Gate D — Dependencies
- Critical-path diagram ב-§4 verifies acyclic.
- M01 הוא ה-root unlock. M02-M04 רצים במקביל ל-M01.
- אחרי Wave 1: Wave 2 פתוח. אחרי Wave 1 + M08: Wave 3 פתוח. אחרי Wave 1+2+M08: Wave 4 פתוח.

---

## 10 · מה לעשות עכשיו (Next Action)

**3 צעדים בלבד:**

1. **לאשר את ה-5 החלטות ב-§6** (5 דק').
2. **לאשר את ה-rollout sequence ב-§4** (5 דק'). אם רוצים סדר אחר — לציין למה.
3. **לבחור — איך להטמיע:**
   - **A:** דרך `/apex:self-heal` — להכניס את 19 ה-M-items כ-F-IDs ב-`apex-audit-findings-R12.md` ולתת ל-self-heal loop לטפל. נכון לפערים שמדידה ע"י spec drift.
   - **B:** דרך `/apex:next` Wave-by-Wave — `/apex:build` או `/apex:full` לכל גל, בסדר התלות. נכון להוספת יכולות חדשות.
   - **C (המומלץ):** היברידי. Theatre gaps (M01-M03, M05-M07) → `/apex:self-heal` R12 (פערים מול spec). Capability additions (M08-M19) → `/apex:build` או `/apex:next` כסדרת phases חדשה ב-PLAN.md.

לאחר אישור — אני יכול להתחיל מיד ב-M18 (1 שעה, no decision risk) ובמקביל לסקור פעם נוספת את ה-state של APEX לקראת M01-M04.

---

## נספח · ציטוטים מסכמים — אנקור-טבלה לכל R-Item

| M-id | R2 anchors | R5 anchors | APEX file:line |
|---|---|---|---|
| M01 | C048, C167, C173, C212, C229 | — | `framework/hooks/context-monitor.sh:25-43`, new `_tokens-update.sh`, `STATE.schema.json:186-235` |
| M02 | C003, C032, C169, C191, C231 | — | `CONTEXT_BUDGET.default.json:14-19`, `pre-compact.sh:35`, new `observation-mask.sh`, `STATE.schema.json:170` |
| M03 | C051, C058, C175, C194 | — | `CONTEXT_BUDGET.default.json:38-39`, `agents/architect.md` |
| M04 | C107, C125 | — | `.claude/apex-model-routing.json`, agent frontmatter |
| M05 | C092, C093, C097, C155 | — | `next.md:404`, agent frontmatter, new `docs/PROMPT-CACHING.md`, `subagent-stop.sh` |
| M06 | C037, C091, C188, C193, C202, C230 | — | `next.md:137`, `CONTEXT_BUDGET.default.json:32-36`, new `_rotation-decide.sh` |
| M07 | C212, C213, C229 | — | `commands/apex/status.md:40-134`, new `HEALTH_METRICS.schema.json`, `context-monitor.sh` |
| M08 | — | §7 F2 line 390 | `next.md:471-490, 614-617, 730-763`, `architect.md`, `PLAN_META.schema.json` |
| M09 | — | §3 + §7 F1 line 353 | `next.md:851-874`, new `comprehension-gate.sh`, `STATE.schema.json` |
| M10 | — | §7 F5 line 488 | All 46 hooks, new `_emit_apex_event.sh` + `background-digest-hook.sh` |
| M11 | — | §7 F4 line 454 | `commands/apex/status.md:40-144`, new `.apex/STATUS_PREFS.json` |
| M12 | C026, C127-C137, C138, C233 | — | `CONTEXT_BUDGET.default.json` (new `profiles`), `PLAN_META.schema.json`, `architect.md` |
| M13 | C081, C082-086, C211, C234 | — | `apex-learnings.md`, `verify-learnings.sh`, `pre-compact.sh`, `apex-memory-synthesis/agent.md` |
| M14 | C203 | — | new `pre-rotation-snapshot.sh`, `next.md` Step F, `commands/apex/resume.md` |
| M15 | — | §7 F3 line 426 | `commands/apex/fast.md`, new `agents/specialist/batch-verifier.md` |
| M16 | C167, C214 | — | `STATE.schema.json`, new `quality-drift.sh`, `commands/apex/status.md` |
| M17 | C099, C156 | — | new `docs/CONTEXT-EDITING.md`, `observation-mask.sh`, `settings.json` |
| M18 | — | §5.4, §9 Gap #7 | `apex-spec.md:9, 375, 379`, README L29 |
| M19 | — | Insight #7 do-now #7 | `framework/modules/apex-security/`, R7 F-002 |

---

**End of meta-plan.**

> **חתימה:** APEX Research Synthesis — 2026-05-15. Single source of truth for the next 12-16 working days of APEX evolution. Each M-id can be opened as a `/apex:next` task or a `/apex:self-heal` R-item without further translation.
