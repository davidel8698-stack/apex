# APEX Round 7 — סינתזת מחקר מזוקקת
# Cost Optimization in Agentic Workflows — Maximum Quality Per Token
### מסמך מאוחד מ-4 מודלי Deep Research | מרץ 2026

---

## 1. תקציר מנהלים

מחקר זה מזקק ומצליב ממצאים מ-4 מודלי AI שונים שנחקרו במקביל. רמת הביטחון בכל ממצא מסומנת לפי מספר המודלים שתמכו בו ומספר המקורות העצמאיים שאומתו.

**ממצא מרכזי #1: קוד פרודוקטיבי הוא רק 1–9% מסך הטוקנים.** ב-workflows של סוכני קוד, הרוב המוחלט של הטוקנים נשרף על review, verification, orchestration, context loading, ו-retries — לא על כתיבת קוד. מחקר Tokenomics (MSR 2026) מצא ש-code review לבדו צורך 59.4% מהטוקנים, בעוד coding ראשוני רק 8.6%. מחקר AgentTaxo (ICLR 2025) מצא שיעורי שכפול של 53–86% במערכות multi-agent. **רמת ביטחון: גבוהה (4/4 מודלים, 5+ מקורות עצמאיים).**

**ממצא מרכזי #2: אופטימיזציה של 70–90% בעלות אפשרית בלי פגיעה משמעותית באיכות.** הטכניקות הן אורתוגונליות ומשתלבות מולטיפליקטיבית: prompt caching (90% חיסכון ב-input חוזר), model routing (50–85% הפחתת עלות), observation masking (50% הפחתה), context pruning (23–54% הפחתה), ו-token-budget-aware reasoning (67% הפחתת output). **רמת ביטחון: גבוהה (4/4 מודלים).**

**ממצא מרכזי #3: יותר טוקנים ≠ תוצאה טובה יותר.** SWE-Pruner שיפר success rates תוך קיצוץ 23–38% טוקנים. AgentDiet שיפר ביצועים ב-1–2% דווקא ע"י הסרת waste. TALE עלה על vanilla CoT בחלק מה-benchmarks עם 67% פחות טוקנים. תופעת "Lost in the Middle" מראה ירידה של 30%+ כשמידע קריטי נקבר באמצע context ארוך. **רמת ביטחון: גבוהה (4/4 מודלים, מקורות אקדמיים מרובים).**

**ממצא מרכזי #4: model routing הוא הזדמנות חסכון ענקית.** Sonnet 4.6 משיג 98% מביצועי Opus 4.6 ב-SWE-bench (79.6% vs 80.8%) בחמישית מהעלות. Haiku 4.5 משיג ~90% מביצועי Sonnet ב-tasks מסוימים בשליש מהעלות. מחקרי routing (RouteLLM, FrugalGPT, AutoMix, EcoAssistant) מדגימים חיסכון של 35–98% עם שמירה על 95%+ מאיכות GPT-4. **רמת ביטחון: גבוהה (4/4 מודלים).**

**ממצא מרכזי #5: verification צריך להיות risk-adaptive, לא stack קבוע.** 3 שכבות verification תופסות את רוב הבאגים בכ-60% מעלות 5 שכבות. שכבות 1–2 (hooks דטרמיניסטיים + executor self-check) הן כמעט חינמיות עם ROI אינסופי. שכבה 3 (critic) נותנת את רוב הערך הנותר. שכבות 4–5 מוצדקות רק ב-high-risk tasks. **רמת ביטחון: בינונית-גבוהה (4/4 מודלים, אבל מבוסס בחלקו על inference תפעולי).**

**ממצא מרכזי #6: APEX יכול לעמוד ביעד <5% framework overhead** — בתנאי שמיישמים: delta-only state reads, explicit model assignment per agent, multi-tier caching עם stable prefix, ו-circuit breakers מתקדמים. **רמת ביטחון: בינונית (מבוסס על שילוב ממצאים, לא מדידה ישירה).**

---

## 2. Token Flow Analysis — לאן הולכים הטוקנים

### 2.1 התפלגות טוקנים לפי שלב

מקור הנתונים המרכזי הוא מחקר Tokenomics (Salim et al., MSR 2026) שנמדד על מערכת ChatDev — כל 4 המודלים מצטטים אותו. ההתפלגות:

| שלב | % מהטוקנים | הערות |
|------|-----------|-------|
| Code Review | 59.4% | הצרכן הגדול ביותר — refinement, לא generation |
| Documentation | 10–20.1% | פערים בין מודלים; 20.1% נראה מדויק יותר |
| Testing | 10.3% | כולל הרצת tests + ניתוח כשלונות |
| Coding (initial) | 8.6% | פלט קוד ראשוני — קטן באופן מפתיע |
| Code Completion | 7.3–26.8% | תלוי ב-task type |
| Design/Planning | 2.4% | זול מאוד — ROI גבוה |

**יחס input/output כללי:** 53.9% input, 24.4% output, 21.6% reasoning tokens (inference). הממצא הזה מאושש ע"י כל 4 המודלים ומייצג את "מס התקשורת" (communication tax) — הצורך לשדר context גדול שוב ושוב.

**ממצאים תומכים נוספים:**

- **CodeMonkeys** (SWE-bench Verified): edits 59.6%, generated tests 19.2%, context/relevance 14.6%, selection 5.8%, ranking 0.9%. עלות כוללת: $2,291.90 על ה-benchmark המלא. Context generation שעולה ~15% אם ממחזרים אותו — אחרת הרבה יותר. *(מודלים 1,2)*
- **ניתוח Claude Code:** system prompt floor של ~14,328 tokens + tool definitions 14–17K tokens. ב-turn 15, history מגיע ל-~25K + tool results ~12K. Compaction buffer שומר 16.5% מ-200K window כ-overhead קבוע. *(מודל 3)*
- **Beam AI:** ~45% context loading, ~25% conversation history, ~20% output, ~10% retries — כלומר ~70% על קריאת context שלא השתנה. *(מודל 1)*
- **SWE-rebench:** חלק מהמודלים צורכים 3.7–8.1M tokens ו-100–154 turns per issue. MiniMax M2.5: 3.52M tokens per task. *(מודלים 1,3)*

### 2.2 זיהוי בזבוז (Waste Identification)

כל 4 המודלים מזהים את אותם קטגוריות waste, עם נתונים כמותיים:

**1. Redundant Context (עד 86% שכפול)**
- AgentTaxo מצא: 72% שכפול ב-MetaGPT, 86% ב-CAMEL, 53% ב-AgentVerse. *(מודל 3)*
- ניתוחי Claude Code מראים עד 99.4% input tokens, בעיקר CLAUDE.md חוזר, repo maps, ו-histories. *(מודל 1)*
- פחות מ-30% מה-context הוא "שימושי" ב-deployments נאיביים. *(מודלים 1,3)*

**2. Verbose Tool Outputs (50K+ tokens)**
- Anthropic מדווחת שמערכי tools מסוימים מוסיפים 50K+ tokens לפני שהסוכן קורא את הבקשה. *(מודלים 1,2)*
- 5-server MCP setup צורך ~55K tokens עוד לפני query. Jira לבד: ~17K. ב-enterprise scale: overhead של כ-$4M בשנה. *(מודל 3)*
- Tool Search של Anthropic הוריד 85% מ-tool definition overhead (מ-134K tokens). *(מודל 3)*

**3. Stale Observations / Expired Data**
- Observation masking — מחיקת tool outputs ישנים (>3 turns) — חותך ~50% מהעלות בלי פגיעה באיכות. *(כל 4 המודלים)*
- Qwen3-Coder: $0.61/instance עם masking vs $1.29 raw — 52.7% הפחתה. *(מודל 3)*
- LLM-based summarization דווקא מאריכה trajectories ב-7.2% — masking פשוט עדיף. *(מודל 3)*

**4. Over-broad Context**
- SWE-Pruner: 23–38% הפחתה ב-SWE-bench Verified, עד 54% ב-benchmarks אחרים, עם שיפור success. *(כל 4)*
- Context editing של Anthropic: 84% הפחתה ב-100 turns. *(כל 4)*
- Lazy loading מפחית מ-12K ל-4.5K tokens per request עם פחות מ-10% irrelevant content. *(מודל 1)*

**5. Failed Attempts Without Learning**
- SWE-Effi: ניסיונות כושלים צורכים 4x+ יותר טוקנים מהצלחות (8.8M vs 1.8M ב-SWE-Agent). *(מודלים 1,2)*
- EET: early termination מפחית 19–55% עלות (ממוצע 31.8%) עם עד 0.2% ירידה ב-resolution rate. *(מודלים 1,2)*
- AgentDiet: הסרת trajectory waste מפחיתה 39.9–59.7% input tokens ומשפרת ביצועים ב-1–2%. *(מודל 3)*

**6. Prompt Bloat / Orchestration Chatter**
- איחוד boilerplate instructions הפחית prompt sizes ב-40–69% ו-total input ב-~60%. *(מודל 1)*
- Dynamic toolsets (Speakeasy): 90.7–96.4% token reduction עם 100% success, אך ~50% slower. *(מודל 2)*
- MCP code execution pattern: עד 98.7% פחות context overhead. *(מודלים 1,2)*

**7. Output Format Waste (ממצא ייחודי)**
- TOON (Token-Oriented Object Notation) מפחית 27–40% מ-JSON overhead. *(מודל 4)*
- Plain text tool calls: 31% פחות tokens + 18pp שיפור accuracy + 70% הפחתת variance לעומת JSON schemas. *(מודל 4)*
- JSON compliance דווקא מפחיתה model logic ב-10–15%. *(מודל 4)*

### 2.3 The Orchestration Tax

**Anthropic Agent Teams: ~7x tokens** מסשן רגיל (כל 4 המודלים). כל teammate מפעיל Claude instance מלא עם context window נפרד, נגבה בנפרד. עלות גדלה כמעט לינארית עם מספר teammates.

**נתונים נוספים על overhead:**
- Single agent vs chat: 4x *(מודל 3, Anthropic measured)*
- Multi-agent vs chat: 15x *(מודל 3, Anthropic measured)*
- Deep Agents framework: 34x overhead על bug-fix task (4,492 → 151,120 tokens). *(מודל 3)*
- GSD: 4:1 orchestration-to-code ratio. *(כל 4)*
- BMAD TEA: 86% מ-200K window לפני שמתחיל coding. *(מודלים 1,3)*

**Thin-agent architecture:** מעבר מ-monolithic prompts ל-gateway routing הפחית spawn cost מ-~24K ל-~2.7K tokens per invocation. *(מודלים 3,4)*

**המינימום האפשרי:** עם prompt caching, deferred tool loading, ו-context isolation אופטימלי — ~1.5–2x overhead ביחס ל-raw single calls. *(מודל 3, estimate מבוסס)*.

**עבור APEX:** כדי לעמוד ב-<5% framework overhead, חובה להפחית **מספר invocations** (לא רק גודל כל אחד), להשתמש ב-delta-only state reads, ולשמור tool loading ל-on-demand. *(מודלים 2,4)*

---

## 3. ניתוח Pareto — עלות מול איכות

### 3.1 עקומת Quality vs. Tokens

הקשר בין טוקנים לאיכות הוא **לא מונוטוני** — יותר טוקנים יכולים לתת תוצאה **גרועה יותר**:

| טכניקה | הפחתת טוקנים | השפעה על איכות | מקור |
|---------|-------------|---------------|------|
| TALE budget-aware CoT | ~67–69% output | <3–5% ירידה; לעיתים שיפור | ACL Findings 2025 |
| SWE-Pruner | 23–38% (SWE-bench Verified) | שיפור של ~1.2–1.4pp | arXiv 2026 |
| Observation masking | ~50% session cost | שווה או מעט טוב יותר | arXiv 2508.21433 |
| AgentDiet | 39.9–59.7% input | שיפור 1–2% | arXiv 2509.23586 |
| EET early termination | 19–55% (avg 32%) | ≤0.2pp ירידה | arXiv 2601.05777 |
| CodeAgents pseudocode | 55–87% input, 41–70% output | שיפור planning accuracy | arXiv (CodeAgents) |
| Context editing | 84% (100-turn) | שיפור 39% על baseline | Anthropic |
| Refine architecture | 90% total tokens | שיפור מ-10% ל-70% success | Refine case study |

**ה-cliff קיים** — אבל הוא מופיע כשחותכים planning signal, repository grounding, או verification evidence, לא כשחותכים verbosity. *(מודלים 1,2)*

**"Lost in the Middle"** (Liu et al., Stanford/Berkeley): ביצועים נופלים 30%+ כשמידע קריטי באמצע context ארוך. GPT-3.5-Turbo ביצע **גרוע יותר** עם documents מאשר בלי. ירידה מתחילה כבר ב-20 documents (~4–8K tokens). *(מודל 3)*

**מסקנה מעשית:** ה-Pareto frontier ב-coding הוא: **keep the right context + compress the wrong context + escalate only when uncertainty remains**.

### 3.2 ROI לפי שלב Pipeline

מכל המודלים עולה תמונה עקבית:

**Planning/Specification — ROI הגבוה ביותר:**
- צורך רק ~2.4% מהטוקנים אבל מונע rework דרמטי downstream.
- TALE ו-CodeAgents מראים ש-planning tokens נוספים חוסכים 40–80% downstream. *(מודלים 1,2)*
- כלל IBM: bug שמתגלה ב-production עולה 100x יותר מאשר ב-design. *(מודל 3)*
- **Anthropic ממליצה plan mode לפני implementation.** *(מודל 2)*

**Architecture/Design — ROI גבוה ב-Level 3+:**
- Routing של task difficulty (cheap model ל-easy, premium ל-hard) חותך 50–60% API costs. *(מודלים 1,2)*
- ב-Level 1–2 tasks, design מינימלי מספיק.

**Code Generation — ROI בינוני-גבוה:**
- לא ה-driver העלות הראשי (רק 8.6%).
- Additional CoT length מראה diminishing returns — TALE מוכיח ש-budgeted reasoning שווה ל-unconstrained. *(מודלים 1,3,4)*

**Testing/Verification — ROI גבוה עד נקודה, אח"כ diminishing returns:**
- Code review = 59.4% מהטוקנים, אבל marginal gain של review subagent נוסף הוא רק ~0.5pp (Verdent SWE-bench). *(מודל 1)*
- EET מדגים ש-truncating low-yield verification cycles חוסך ~32% בלי loss. *(מודלים 1,2)*

**Reflexion/Retries — ROI יורד מהר:**
- "AI Agents That Matter" מצא שארכיטקטורות יקרות יותר לא בהכרח נותנות שיפור מובהק. *(מודל 2)*
- Reflexion on HumanEval: 80% → 91% pass@1, אבל רוב השיפור ב-1–3 retries הראשונים. *(מודל 3)*
- מעבר ל-3 retries: probability of success נופל בעוד עלות נותרת גבוהה. *(כל 4)*

### 3.3 Verification ROI — ניתוח 5 השכבות של APEX

| שכבה | עלות | ROI | המלצה |
|------|------|-----|--------|
| L1: Post-write hooks (linter, types, secrets) | כמעט אפס tokens | ∞ | **Always-on** |
| L2: Executor self-check | כלול ב-execution | גבוה מאוד | **Always-on** |
| L3: Clean-room critic | Full agent invocation | גבוה | **Always-on, עם context pruned** |
| L4: Phase verifier | Full agent invocation | נמוך-בינוני | **רק על Level 3+ / milestones** |
| L5: Human comprehension gate | ~0 tokens | גבוה (cost = human time) | **תמיד כשאפשר** |

**מסקנה:** 3 שכבות (L1+L2+L3) תופסות ~95% מהבאגים בכ-60% מעלות 5 שכבות. *(כל 4 המודלים מסכימים)*. L4 מוצדקת רק ל-high-risk, multi-file changes, ו-phase transitions. L5 תמיד כדאית כי עלות token = אפס.

**עלות false-pass:** $100 ב-requirements, $500 ב-design, $1,000 ב-implementation, $5,000 ב-testing, $10,000+ ב-production. Emergency fix: $8,000+. *(מודל 3)*

---

## 4. אסטרטגיית בחירת מודלים (Model Selection)

### 4.1 תמחור מרץ 2026

**Anthropic:**

| מודל | Input/1M | Output/1M | Cache Read | Cache Write (5m) | Cache Write (1h) | Batch |
|------|----------|-----------|------------|-----------------|-----------------|-------|
| Opus 4.6 | $5.00 | $25.00 | $0.50 (90%) | $6.25 (1.25x) | $10.00 (2x) | 50% off |
| Sonnet 4.6 | $3.00 | $15.00 | $0.30 (90%) | $3.75 (1.25x) | $6.00 (2x) | 50% off |
| Haiku 4.5 | $1.00 | $5.00 | $0.10 (90%) | $1.25 (1.25x) | $2.00 (2x) | 50% off |

**OpenAI:**

| מודל | Input/1M | Cached/1M | Output/1M | Batch |
|------|----------|-----------|-----------|-------|
| GPT-5.4 | $2.50 | $0.25 | $15.00 | 50% off |
| GPT-5.4 mini | $0.75 | $0.075 | $4.50 | 50% off |
| GPT-5.4 nano | $0.20 | $0.02 | $1.25 | 50% off |
| GPT-4.1 | $2.00 | $0.50 | $8.00 | 50% off |
| GPT-4.1 mini | $0.40 | $0.10 | $1.60 | 50% off |

**Google:**

| מודל | Input/1M | Output/1M | Batch |
|------|----------|-----------|-------|
| Gemini 2.5 Pro | $1.25–$2.50 | $10.00–$15.00 | 50% off |
| Gemini 2.5 Flash | $0.30 | $2.50 | 50% off |
| Gemini 2.5 Flash-Lite | $0.10 | $0.40 | 50% off |

> **הערה:** מודל 4 מזכיר גם Gemini 3.1 Pro ($2/$12, 80.6% SWE-bench) אך מקור יחיד — יש לאמת עדכניות.

**OpenAI prompt caching:** אוטומטי, zero write premium, retention 5min–24h, עד 90% חיסכון. *(מודלים 2,3)*

**Google context caching:** ~90% discount על cached tokens, explicit + implicit. *(מודלים 1,2)*

**מגמת מחירים:** ירידה של 50–200x בשנה. Opus ירד 66.7% מ-Opus 4.0 ($15/$75) ל-Opus 4.5/4.6 ($5/$25). תחרות סינית (DeepSeek: $0.28/$0.42) מואצת את הירידה. *(מודלים 1,3)*

### 4.2 יכולות מודלים לפי task type

**SWE-bench Verified scores:**
- Opus 4.6: 80.8%
- Sonnet 4.6: 79.6% — **98% מביצועי Opus בחמישית העלות** *(מודלים 2,3,4)*
- Haiku 4.5: ~70–73.3% — **~90% מביצועי Sonnet בשליש העלות** *(מודלים 2,3)*
- Gemini 2.5 Pro: comparable *(מודלים 1,3)*
- MiniMax M2.5: 80.2% resolve rate, $0.13/problem *(מודלים 1,3)*

**"Coding inversion"** — Gemini 3 Flash beats Gemini 3 Pro (78% vs 76.2%) *(מודל 3)* — מודל קטן יותר עולה על הגדול.

**הדפוס הברור:** מודלים קטנים מצטיינים ב-pattern matching (code completion, simple edits, test gen, docs). מודלים גדולים נדרשים בעיקר ל-architecture decisions, multi-file refactoring, novel algorithms, ו-complex debugging.

### 4.3 אסטרטגיות Routing

| Framework | גישה | חיסכון | השפעה על איכות |
|-----------|------|--------|----------------|
| FrugalGPT | LLM cascade + scorer | עד 98% | +4% accuracy אפשרי |
| RouteLLM | Preference-trained router | 35–85% | ≥95% של GPT-4 |
| AutoMix | Self-verification + POMDP | >50% | Comparable |
| EcoAssistant | Hierarchy + solution RAG | >50% | +10pp success |
| Hybrid LLM | Encoder router | >60% cloud reduction | <1% drop |
| LLM-AT | "Starter" classifier | $41.56→$16.89 | 0.778 vs 0.793 accuracy |
| FORC | Meta-model routing | 63% | Matched |

**FrugalGPT:** מפנה 86% מהקריאות למודל הזול ביותר, מעלה רק 14% ל-GPT-4. אפילו משפר accuracy ב-4% דרך ensemble diversity. *(מודלים 1,3)*

**EcoAssistant:** היחיד שנבדק ספציפית על code generation — עולה על GPT-4 ב-10pp ב-<50% מהעלות, דרך solution caching שמאפשר למודלים זולים להתמודד עם tasks מורכבים יותר לאורך זמן. *(מודל 3)*

**כשלי routing:** מודל זול שנותן תשובה בטוחה אך שגויה; router לא מכויל תחת distribution shift. פתרונות: self-verification, random audit, conservative thresholds על high-risk tasks. *(מודלים 1,2)*

### 4.4 המלצת Model Assignment ל-APEX

| Agent | מודל מומלץ | רציונל | חיסכון vs All-Opus |
|-------|-----------|--------|-------------------|
| **Diagnostician** | Haiku 4.5 / Flash-Lite / GPT-5.4 nano | Classification, pattern matching, scoping | ~80% |
| **Interviewer** | Haiku 4.5 / GPT-5.4 mini / Flash | שיחה עם user — latency חשוב, לא deep reasoning | ~60–80% |
| **Architect** | Sonnet 4.6 / GPT-5.4 / Gemini 2.5 Pro; **Opus רק ל-Level 3–4** | Deep reasoning, cross-repo, architecture | Baseline / 40% |
| **Executor** | Sonnet 4.6 כ-default; **Opus רק אחרי כשל או Level 4** | 98% מביצועי Opus ב-coding | ~40% |
| **Critic** | Sonnet 4.6 עם **context pruned** (diffs + local surroundings) | Pattern recognition + moderate reasoning | ~40% |
| **Verifier** | Haiku 4.5 / Flash | Binary pass/fail; log parsing; deterministic checks | ~80% |
| **Specialists** | Sonnet 4.6 default; premium רק כש-error cost גבוה | Domain expertise | ~40–60% |

**חיסכון מוערך מ-model assignment אופטימלי: 40–70%** ביחס ל-all-Sonnet/Opus baseline. *(כל 4 המודלים מסכימים על הטווח)*

**runtime escalation:** cascade — נסה tier זול קודם, escalate אם קוד לא מקמפל, tests נכשלים, critic disagreement, large diff radius, או repeated no-progress. *(מודלים 2,3)*

---

## 5. Caching ו-Reuse

### 5.1 Prompt Caching — Deep Dive

**Anthropic:**
- Cache read: 0.1x input cost (90% הנחה)
- Cache write 5-min TTL: 1.25x input cost; break-even אחרי ~1 hit
- Cache write 1-hour TTL: 2.0x input cost; break-even אחרי ~2 hits
- Prefix matching; hierarchy: tools → system → messages
- שינוי ברמה כלשהי מבטל cache לאותה רמה ומטה
- Minimum cacheable size: 1,024 tokens per checkpoint

**הנתון החזק ביותר:** SWE-rebench — לפני caching, Claude Sonnet 4 עלה $5.29/problem; אחרי caching: $0.91 — **83% הפחתה מטכניקה בודדת.** Cache usage = >97% מ-total token reads ב-workflows מוגדרים נכון. *(מודל 3)*

**100K-token prompt:** latency ירד מ-11.5 שניות ל-2.4 — **85% הפחתת latency.** *(מודל 3)*

**ה-trap של 5-min TTL:** אם developer עוצר ל-6 דקות לעשות review — cache expires, cache write surcharge חוזר. ב-heavy automation: cache write surcharge יכול להיות 60% מהחשבון. *(מודל 4, Reddit/OpenClaw)*

**המלצה ל-APEX: 1-hour TTL** ל-interactive sessions. למרות 2x write premium, break-even מגיע אחרי 2 hits בלבד, וב-iterative debugging ה-hit rate גבוה מאוד. *(מודלים 2,3,4)*

**OpenAI:** zero write premium, automatic, 5min–24h retention, 90% read discount. *(מודלים 2,4)*

**Google:** ~90% discount, explicit + implicit caching, מתאים במיוחד ל-recurring code repo analysis. *(מודלים 1,2)*

### 5.2 מה Cacheable ב-APEX

**Tier 1 — 1-hour cache (stable prefix):**
- APEX system protocol
- CLAUDE.md / agent handbook
- Tool schemas קבועים
- Repo map
- Coding standards
- State schema / PLAN_META schema
- Specialist instructions

**Tier 2 — 5-min cache (semi-volatile):**
- Active phase context
- Current task spec
- Current diff
- Recent decisions

**Tier 3 — No cache / delta only:**
- Volatile tool outputs
- Recent failing traces
- Changed files only

**חובה טכנית:** לשמור volatility ordering נכון — stable content ראשון, dynamic content אחרון. *(מודלים 2,3,4)*

### 5.3 Response Caching / Semantic Caching

פחות חזק ב-coding (tasks ייחודיים) אבל יש niches:
- GPTCache: עד 68.8% הפחתת API calls עם >97% accuracy. *(מודל 3)*
- Redis LangCache: עד ~73% cost reduction ב-high-repetition workloads. *(מודל 3)*
- ~31% מ-LLM queries מראים semantic similarity למוקדמות יותר. *(מודל 1)*

**מתאים ל-APEX ב:** diagnostic questionnaires, health checks, common remediation templates, onboarding prompts, static repo summaries. *(מודלים 1,2)*

### 5.4 Context Reuse

**CodeMonkeys נותן את הראיה הטובה ביותר:** repository scan/context building פעם אחת, מיחזור על פני 10 edit attempts — משנה economics מהותית. *(מודל 2)*

**עם prompt caching:** re-reading 100K-token prefix 12 פעמים עולה 80–90% פחות מאשר בלי caching — עדיף מאחזקת context ארוך. *(מודלים 1,2)*

**המלצה:** aggressive context rotation ב-55–70% של budget, rolling summaries ל-history מעבר ל-sliding window, tool logs off-context עם summaries קצרים cached. *(מודלים 1,2)*

### 5.5 Computation Reuse (Non-LLM)

מזכרון (memoization) של:
- Test results על unchanged commits
- Static analysis / type-check outputs keyed by file hash
- Repo map — incremental update, לא recompute
- Dependency graph snapshots
- Critic findings keyed by diff hash
- Verification evidence per task

אלה מאוחסנים ב-file-based state של APEX, מוזכרים ב-prompts רק דרך IDs קצרים. *(מודלים 1,2)*

---

## 6. טכניקות הפחתת טוקנים

### 6.1 Prompt Efficiency

**פורמט קומפקטי עובד טוב יותר:**
- CodeAgents pseudocode prompting: 55–87% פחות input, 41–70% פחות output, עם שיפור planning accuracy. *(מודלים 1,3)*
- איחוד boilerplate ל-shared includes: 40–70% הפחתת prompt sizes. *(מודל 1)*
- TALE-style budgeting: הגדרת token caps מפורשים לשלבי reasoning. *(מודלים 1,3,4)*
- **Thinking tokens:** Anthropic מחייבת כ-output; budget default יכול להגיע לעשרות אלפי tokens. המלצה: להוריד thinking effort או להגביל MAX_THINKING_TOKENS ב-tasks פשוטים. *(מודל 2)*

**Minimum effective prompt עדיף על prompt bloated.** אין תמיכה ב-"longer is better" ב-coding; SWE-Pruner, observation masking, TALE כולם מצביעים על "less but sharper wins." *(מודלים 2,4)*

### 6.2 Context Compression

**מומלץ (safe for code):**

| טכניקה | הפחתה | בטיחות לקוד | מנגנון |
|---------|--------|-------------|--------|
| Observation masking | ~50% | כן — אפקטיבי ביותר | מחיקת tool outputs ישנים |
| Context editing | 84% (100-turn) | כן | ניהול אקטיבי של memory |
| SWE-Pruner (line-level) | 23–54% | כן — שומר מבנה | Neural skimmer 0.6B |
| Extractive context (function/class/diff hunks) | Variable | כן | רק הקוד הרלוונטי |
| Factory.ai structured summarization | Comparable | כן | שומר paths, errors, decisions |

**מסוכן לקוד:**
- LLMLingua-2 (token-level): עד 20x compression, אבל **הורס מבנה קוד** — success rate נופל ל-48.67–54%. SWE-Pruner שומר 57.58 באותם conditions. *(מודלים 3,4)*

**כלל ברזל ל-APEX:** line-level או block-level compression בלבד. לעולם לא token-level לקוד. System prompts ו-hard requirements — compress בזהירות. Logs, error traces, narrative history — compress אגרסיבית. *(מודלים 1,3,4)*

### 6.3 Output Efficiency

Output tokens יקרים **2–5x** יותר מ-input. לכן:

- **Machine-parseable and terse:** RESULT.json מינימלי — status, changed_files, evidence pointers, residual risks, next action. *(מודל 2)*
- **TOON במקום JSON:** 27–40% הפחתה. *(מודל 4)*
- **Plain text tool calls:** 31% פחות tokens, 18pp שיפור accuracy. *(מודל 4)*
- **אל לשנות unchanged code** ב-output.
- **Natural-language explanations:** רק כש-human-readability flag מופעל. *(מודלים 1,2)*
- **Skeleton-of-Thought:** generate outline → expand in parallel — 2.39x faster generation. *(מודל 3)*
- **Concise prompting:** 30–70% input reduction עם comparable quality. *(מודל 3)*

### 6.4 File-Based Inter-Agent Communication (ממצא ייחודי)

כתיבת tool outputs לקבצים במקום העברה דרך context: **46.9% הפחתה** ב-agent tokens ב-A/B testing. *(מודל 3)*

זה מתיישב עם עקרון ה-APEX של file-based state — agents כותבים ל-RESULT.json / STATE.json, לא מעבירים text בין agent contexts.

### 6.5 Batch Optimization

50% discount אחיד אצל Anthropic, OpenAI, Google — async עם latency של עד 24 שעות.

**מתאים ל-APEX:**
- Wave tasks עצמאיים (כשה-user מוכן לחכות)
- Nightly verification sweeps
- Bulk documentation
- Parallel low-priority critics
- Retrospective repo analysis
- Test suite generation
- Large-scale refactor suggestions

**לא מתאים:** interactive debugging, real-time pair programming, live code completion.

**Combined: Cache + Batch = עד 95% discount על input tokens.** *(מודל 3)*

---

## 7. Budget Planning ו-Monitoring

### 7.1 הערכת עלות לפי סוג פרויקט

**נתוני SWE-bench כ-anchor:**
- MiniMax M2.5: 3.52M tokens/task, ~$8.45 output cost, $0.13/problem *(מודלים 1,3)*
- Claude Code: $4.91/problem (SWE-rebench) *(מודל 3)*
- Claude Code average developer cost: $6/day, $100–200/month *(מודל 3, Anthropic official)*
- CodeMonkeys: $2,291.90 על full SWE-bench Verified *(מודל 2)*

**הערכת עלות ל-APEX (לאחר אופטימיזציה):**

| Level | תיאור | טוקנים | עלות לא-מאופטמזת | עם routing | + caching | **עם כל האופטימיזציות** |
|-------|-------|--------|------------------|-----------|-----------|----------------------|
| 1 | Bug fix / single file | 0.1–0.5M | $3–$10 | $1–$4 | $0.50–$2 | **$0.30–$1.50** |
| 2 | Feature / small change | 0.5–1.5M | $10–$30 | $4–$12 | $2–$6 | **$1–$5** |
| 3 | Complex multi-file | 1.5–4M | $30–$80 | $12–$32 | $5–$15 | **$3–$15** |
| 4 | Large feature / refactor | 4–8M | $50–$150 | $20–$60 | $8–$25 | **$5–$40** |

> **הערה:** מודל 4 נתן מחירי base נמוכים יותר ($0.075–$1.80) — אלה מתייחסים ל-raw API cost ללא retries/orchestration. הטבלה משקפת real-world costs עם overhead.

**שיפור 3–5x ביחס לארכיטקטורות נאיביות ריאלי; עד 10–20x ל-batch workloads.** *(מודלים 1,3)*

### 7.2 הקצאת תקציב לפי שלב

**סינתזה מכל המודלים — Template מומלץ:**

| שלב | % מתקציב | הערות |
|------|----------|-------|
| Planning / Architecture | 10–15% | ROI הגבוה ביותר per token — **אל תחסכו כאן** |
| Execution (coding + immediate self-check) | 40–50% | עיקר העבודה; Sonnet-tier |
| Testing / Verification / Review | 20–30% | **Risk-adaptive**, לא fixed |
| Retry / Escalation reserve | 5–10% | מוגבל — max 3 retries |
| Framework overhead | **<5%** | Hard cap |

**Allocation דינמית:** unused planning tokens זורמים ל-testing. Budget per-phase ב-CONTEXT_BUDGET.json, adjustable לפי historical data. *(מודלים 1,2)*

### 7.3 Monitoring ו-Alerts

**Metrics ל-tracking realtime:**
- Tokens per task / phase / agent
- Input vs output ratios
- Cache hit rate (target: >90% *(מודל 3)* או >60% *(מודל 2)*)
- Cost per successful task
- Retry count + delta improvement per retry
- Tool-output token share
- Verification cost share
- Framework overhead_pct
- No-progress streak
- Context rebroadcast frequency

**Alert thresholds מומלצים:**

| מצב | Alert | Action |
|------|-------|--------|
| Task > 1M tokens (Level 1–2) | Warning | Review efficiency |
| Task > 2M tokens | Hard stop / human confirmation | (scaled by complexity) |
| >3 retries בלי improvement | Warning | EET-style futility detection |
| Framework overhead > 5% | Warning | Investigate |
| Framework overhead > 10% | Hard stop | Investigate |
| Verification share > 35% ב-Level 1–2 | Warning | Reduce verification layers |
| Cache hit rate < 60% | Warning | Review prefix structure |
| Tool-output tokens > 25% of task budget | Warning | Apply masking |
| 50% budget consumed | Warning | — |
| 80% budget consumed | Throttle | Switch to cheaper models |
| 95% budget consumed | Pause | Route to human |
| 3 consecutive errors | Circuit breaker | Stop + human intervention |
| Cost > 300% of estimate for single sub-task | Hard stop | Human intervention |

### 7.4 Retry Economics

**הנתונים ברורים — diminishing returns חדים:**
- EET: 2–3 retries capture most benefits; beyond that, probability drops while tokens remain high. *(מודלים 1,2)*
- Failed trajectories: 4x+ יותר טוקנים מהצלחות. *(מודלים 1,2)*
- Reflexion (HumanEval): 80% → 91% — אבל רוב השיפור ב-retries 1–3. *(מודל 3)*
- "AI Agents That Matter": ארכיטקטורות expensive-reflection לא תמיד מצדיקות עלות. *(מודל 2)*

**Economic break-even:** ב-developer rate של $75–150/hr, human intervention זולה יותר אחרי 3–5 retry cycles או כש-total retry cost עולה על $5–10 ל-task בודד. *(מודל 3)*

**המלצת retry policy ל-APEX:**
- Retry 1: cheap self-correction (same model)
- Retry 2: escalate model or add context
- Retry 3: human handoff / explicit stop אלא אם expected value עדיין גבוה
- **Max 3 — עם condition שכל retry מביא מידע חדש** (different plan, diagnostics, not just rerun)

---

## 8. המלצות ספציפיות ל-APEX

### 8.1 שינויים בסדר עדיפות (Implementation Priority)

| # | שינוי | חיסכון צפוי | מורכבות | תזמון |
|---|-------|------------|---------|-------|
| 1 | **Prompt caching עם 1h TTL** על stable prefixes | 83–90% על cached input | נמוכה | מיידי |
| 2 | **Explicit model routing per agent** | 40–70% overall | בינונית | שבוע 1 |
| 3 | **Observation masking** על tool outputs >2–3 turns | ~50% session cost | נמוכה | שבוע 1 |
| 4 | **Context editing** — clear old tool calls at threshold | 84% ב-long sessions | בינונית | שבוע 2 |
| 5 | **File-based inter-agent communication** (results to files, not context) | 46.9% inter-agent | בינונית | שבוע 2 |
| 6 | **SWE-Pruner-style context pruning** | 23–38% code context | גבוהה | חודש 1 |
| 7 | **Adaptive CoT budgeting** (TALE-style) | 67% output reduction | בינונית | חודש 1 |
| 8 | **Risk-adaptive verification** (3 layers default, 5 for high-risk) | 40% verification cost | בינונית | חודש 1 |
| 9 | **TOON / plain text** במקום JSON ל-internal state | 27–40% output | נמוכה | חודש 1 |
| 10 | **Batch API** ל-non-interactive operations | 50% flat | בינונית | חודש 1 |
| 11 | **Dynamic tool exposure** (on-demand, not all upfront) | 85–96% tool overhead | גבוהה | חודש 2 |
| 12 | **Semantic response caching** | 30–70% repetitive patterns | גבוהה | חודש 2 |
| 13 | **EET-style early termination** | ~32% average | בינונית | חודש 2 |
| 14 | **EcoAssistant-style solution caching** (query-code pairs for future) | Progressive improvement | גבוהה | חודש 3 |

### 8.2 Caching Strategy מלאה

```
CACHE HIERARCHY:
  Tier 1 (1h TTL):
    - APEX system protocol
    - CLAUDE.md / agent handbook
    - Tool schemas (stable)
    - Repo map
    - Coding standards
    - State/PLAN_META schema
    - Specialist instructions
    → Volatility: None. Cache once per session.
    
  Tier 2 (5m TTL):
    - Active phase context
    - Current task spec
    - Current diff / recent decisions
    → Volatility: Changes per task.
    
  Tier 3 (No cache / delta only):
    - Tool outputs (volatile, masked after 2-3 turns)
    - Failing traces
    - Changed files only
    → Always fresh.

STRUCTURAL RULE:
  prompt = [Tier 1 content] → [Tier 2 content] → [Tier 3 content]
  Tools first, system second, dynamic last.
  Changes at any level invalidate that level + all below.

SHARED CACHE KEYS:
  All agents share cache keys for common prefixes → maximize hit rates.
```

### 8.3 Budget Allocation Template

```
PER-TASK BUDGET (normalized to 100 units):

  Level 1 (Simple):
    Planning:     10
    Execution:    50
    Verification: 20 (L1+L2+L3 only)
    Retry:        10
    Framework:    5
    Buffer:       5
    
  Level 2 (Moderate):
    Planning:     15
    Execution:    45
    Verification: 25 (L1+L2+L3 default)
    Retry:        10
    Framework:    5
    
  Level 3 (Complex):
    Planning:     20
    Execution:    35
    Verification: 30 (L1–L4 + human gate)
    Retry:        10
    Framework:    5
    
  Level 4 (Architecture):
    Planning:     25
    Execution:    30
    Verification: 30 (full 5-layer stack)
    Retry:        10
    Framework:    5

TOKEN CEILINGS per level:
    Level 1: 1M tokens
    Level 2: 2M tokens
    Level 3: 4M tokens
    Level 4: 8M tokens
```

### 8.4 Circuit Breakers מורחבים

מעבר ל-"3 no-change actions → halt" הקיים, להוסיף:

1. **Cost spiral detection:** עלייה רציפה ב-input בלי שינוי artifacts
2. **Retry inefficiency:** retry ללא מידע חדש (same approach)
3. **Context rebroadcast:** broad context loads חוזרים על אותו content
4. **Budget ceiling:** hard stop ב-300% של estimate ל-sub-task
5. **Invocation count:** alert אם invocations > 2x expected
6. **Token velocity:** alert אם burn rate > projected

### 8.5 Delta-Only State Management

APEX חייב לעבור ל-delta reads:
- **STATE.json:** לא לקרוא full state בכל invocation; לקרוא רק שדות ששינו מאז last read
- **PLAN_META.json:** inject רק task-relevant section, לא full plan
- **Tool outputs:** masking אוטומטי אחרי 2–3 turns
- **File context:** function/class/diff hunks בלבד — לא full files
- **Conversation history:** rolling summary + recent N turns

---

## 9. Quantitative Findings — כל המספרים

### Token Flow & Waste

| מטריקה | ערך | רמת ביטחון | מקורות |
|---------|-----|-----------|--------|
| Code Review share of tokens | 59.4% | גבוהה | Tokenomics (MSR 2026) |
| Coding initial share | 8.6% | גבוהה | Tokenomics |
| Design/Planning share | 2.4% | גבוהה | Tokenomics |
| Input/Output/Reasoning split | 53.9% / 24.4% / 21.6% | גבוהה | Tokenomics |
| Actual code output share | 1–3% (multi-agent) | בינונית | AgentTaxo, financial benchmarks |
| Token duplication (multi-agent) | 53–86% | גבוהה | AgentTaxo (ICLR 2025) |
| Agent Teams overhead | 7x standard session | גבוהה | Anthropic official |
| Single agent vs chat | 4x | גבוהה | Anthropic measured |
| Multi-agent vs chat | 15x | בינונית | Anthropic measured |
| Deep Agents overhead | 34x (bug-fix task) | בינונית | Single source |
| GSD orchestration-to-code | 4:1 to 10:1 | בינונית | Community reports |
| BMAD TEA context consumption | 86% of 200K | בינונית | GitHub Issue |
| Failed vs successful trajectory cost | 4x+ (8.8M vs 1.8M) | גבוהה | SWE-Effi, SWE-Agent |
| Tool definition overhead (pre-optimization) | 55K–134K tokens | גבוהה | Anthropic engineering |
| Claude Code system prompt floor | ~14,328 tokens | בינונית | Community analysis |
| Legacy agent spawn cost | ~24,000 tokens | בינונית | Praetorian (39-agent platform) |
| Optimized spawn cost (thin-agent) | ~2,700 tokens | בינונית | Praetorian |
| Typical context: useful vs waste | <30% useful | בינונית | Beam AI, AgentCenter |
| Production app token waste | ~30% of budget | בינונית | CodeAnt AI |

### Token Reduction Techniques

| טכניקה | הפחתה | השפעה על איכות | רמת ביטחון |
|---------|--------|---------------|-----------|
| Observation masking | ~50% session cost | Neutral/positive | גבוהה |
| SWE-Pruner | 23–38% (SWE-bench V), up to 54% | +1.2–1.4pp (improved) | גבוהה |
| TALE budget-aware CoT | ~67–69% output | <3–5% loss; sometimes +1–3% | גבוהה |
| Context editing (Anthropic) | 84% (100-turn) | +39% performance | גבוהה |
| AgentDiet | 39.9–59.7% input | +1–2% (improved) | בינונית |
| EET early termination | 19–55% (avg 32%) | ≤0.2pp loss | גבוהה |
| CodeAgents pseudocode | 55–87% input, 41–70% output | Improved planning | בינונית |
| Dynamic toolsets | 90.7–96.4% | 100% success | בינונית |
| MCP code execution pattern | Up to 98.7% context | - | בינונית |
| Tool Search optimization | 85% tool definition | - | גבוהה (Anthropic) |
| File-based inter-agent comm | 46.9% agent tokens | Neutral | בינונית |
| Tiered context loading | 76% startup cost | - | בינונית |
| Plan caching | 46.6–50.3% cost, 27.3% latency | - | בינונית |
| Prompt consolidation (boilerplate) | 40–69% prompt size | - | בינונית |
| Subagent vs Skills pattern | 67% fewer tokens | - | בינונית (LangChain) |
| TOON vs JSON | 27–40% output | Neutral/positive | בינונית |
| Plain text vs JSON tool calls | 31% tokens, +18pp accuracy | Improved | בינונית |
| Concise prompting | 30–70% input | Comparable | בינונית |

### Model Routing

| Framework | חיסכון | איכות | רמת ביטחון |
|-----------|--------|-------|-----------|
| FrugalGPT | Up to 98% | +4% accuracy possible | גבוהה |
| RouteLLM | 35–85% | ≥95% of GPT-4 | גבוהה |
| AutoMix | >50% compute | Comparable | גבוהה |
| EcoAssistant | >50% cost | +10pp success | גבוהה |
| Hybrid LLM | >60% cloud, ~40% latency | <1% drop | גבוהה |
| LLM-AT | $41.56→$16.89 | 0.778 vs 0.793 | בינונית |
| FORC | 63% | Matched | בינונית |

### Caching & Batch

| טכניקה | חיסכון | הערות |
|---------|--------|-------|
| Prompt caching (read) | 90% input cost | All 3 providers |
| SWE-rebench before/after caching | 83% ($5.29→$0.91) | Claude Sonnet 4 |
| Prompt caching latency reduction | Up to 85% | 100K prompt: 11.5s→2.4s |
| Batch API | 50% flat | All providers, async |
| Cache + Batch combined | Up to 95% input | Anthropic confirmed |
| Semantic response caching | Up to 68.8% API calls, >97% accuracy | GPTCache |
| Redis LangCache | Up to ~73% cost | High-repetition workloads |

### SWE-bench Performance & Cost

| מודל | SWE-bench Verified | Cost/problem | הערות |
|------|-------------------|-------------|-------|
| Claude Opus 4.6 | 80.8% | - | Flagship |
| Claude Sonnet 4.6 | 79.6% | $0.91 (cached) | 98% of Opus at 1/5 cost |
| Claude Haiku 4.5 | ~70–73.3% | - | ~90% of Sonnet at 1/3 cost |
| Claude Code | - | $4.91 | SWE-rebench |
| MiniMax M2.5 | 80.2% | $0.13 | 3.52M tokens avg |
| GPT-5.4 | ~80% | $0.63 (0.77M tokens) | - |
| Gemini 2.5 Pro | Comparable | - | - |

### Multi-Agent Efficiency

| מטריקה | ערך | מקור |
|---------|-----|------|
| Coordination plateau | Beyond 4 agents | Google DeepMind |
| Error amplification (unstructured) | Up to 17.2x | Google DeepMind 2025 |
| MAST failure rates | 41–86.7% across 7 frameworks | MAST study |
| Multi-agent cost multiplier (4 agents) | 3.5x | TDS measured |
| Coordination failure cause | 36.9% of all failures | MAST study |
| Reflexion improvement (HumanEval) | 80%→91% pass@1 | Shinn et al. NeurIPS 2023 |
| Single retry improvement | +18.1% (function calling), +34.7% (math) | - |
| Productive retries before diminishing returns | 3 max | Multiple sources |

---

## 10. מגבלות המחקר

1. **Tokenomics data מבוסס על ChatDev** — ייתכנו הבדלים בארכיטקטורות אחרות. אין מדידה ישירה של APEX-specific flows.

2. **Cost estimates הם projections** — אין benchmark של APEX running end-to-end עם כל האופטימיזציות מיושמות יחד.

3. **Pricing data subject to rapid change** — מחירי מרץ 2026 יכולים להשתנות תוך שבועות. המודלים המספריים מדויקים ל-snapshot נוכחי.

4. **Model capability overlaps** — ה-claim ש-Haiku 4.5 משיג 90% מביצועי Sonnet מבוסס על Anthropic claims ו-SWE-bench, לא על מדידה across all APEX task types.

5. **Routing savings in coding specifically** — רוב מחקרי routing (RouteLLM, FrugalGPT) נמדדו על NLP benchmarks, לא coding-specific. EcoAssistant הוא היוצא מן הכלל.

6. **Verification layer ROI** — אין מדידה ישירה של "% bugs caught per layer" ב-stack זהה ל-APEX. ההמלצה ל-3 layers = 95% מבוססת על inference, לא מדידה.

7. **TOON format** — מקור יחיד (TensorLake). דורש אימות נוסף לפני adoption.

8. **Gemini 3.1 Pro** — מוזכר ע"י מודל אחד בלבד. יש לאמת מול Google pricing page.

---

## 11. מקורות עיקריים

### מחקרים אקדמיים
- **Tokenomics** — Salim et al., MSR 2026, arXiv:2601.14470
- **SWE-Pruner** — Gu et al., arXiv:2601.16746
- **TALE** — Han et al., ACL Findings 2025
- **EET** — arXiv:2601.05777
- **FrugalGPT** — Stanford, arXiv:2305.05176
- **RouteLLM** — LMSYS/Berkeley, arXiv:2406.18665
- **AutoMix** — NeurIPS 2024, arXiv:2310.12963
- **Hybrid LLM** — Microsoft, arXiv:2404.14618
- **EcoAssistant** — Microsoft, arXiv (2024)
- **CodeMonkeys** — arXiv:2501.14723
- **AgentTaxo** — ICLR 2025 Workshop
- **AgentDiet** — arXiv:2509.23586
- **SWE-Effi** — arXiv (2025)
- **CodeAgents** — arXiv (2025)
- **LLM-AT** — ACL Findings 2025
- **"AI Agents That Matter"** — OpenReview (2025)
- **"Lost in the Middle"** — Liu et al., Stanford/UC Berkeley, TACL
- **MAST / Google DeepMind multi-agent** — (2025)

### תיעוד רשמי
- Anthropic: Pricing, Prompt Caching, Claude Code Costs, Agent Teams, Tool Use, Context Editing
- OpenAI: API Pricing, Prompt Caching, GPT-5.4 docs
- Google: Gemini API Pricing, Context Caching, Model docs

### מקורות תעשייתיים
- SWE-rebench leaderboard data
- Beam AI cost optimization report
- Speakeasy dynamic toolsets
- Praetorian 39-agent architecture
- TensorLake TOON benchmarks
- Reddit/HN community cost reports

---

*מסמך זה מזקק ממצאים מ-4 מודלי AI שונים שביצעו מחקר עמוק על אותה הנחיה. כל ממצא מסומן ברמת ביטחון לפי כלל 3 העדויות העצמאיות. מספרים המופיעים ללא סימון רמת ביטחון מופיעים ב-3+ מודלים עם מקורות תומכים.*
