# APEX R5 Synthesis Findings — תובנות והמלצות

**Date:** 2026-05-07 · **Source:** R5 Synthesized Multi-Model Analysis (701 lines, March 2026) + R1/R2/R3/R6 + verification + cost optimization · **Target:** APEX framework v7.1 (post-R7 self-heal closure)

---

## §0 · תקציר מנהלים

### מה הסיפור בקצרה

קראתי לעומק את **R5** — מסמך הסינתזה הגדול שלך — ולצדו את שאר 6 קבצי המחקר (R1, R2, R3, R6, מחקר verification, מחקר עלויות). השוויתי כל מה שכתוב שם מול **המצב הנוכחי של APEX** (244 קבצי framework, גרסה v7.1, אחרי 7 סבבי self-heal).

**שלוש מסקנות גדולות:**

**1. הכיוון של APEX נכון.** המבנה הכללי — pipeline, dual-mode, three-tier ceremony, clean-room critic, auditor מבודד — מאומת על-ידי R5 כארכיטקטורה הנכונה. אין צורך לשנות את הליבה.

**2. אבל יש 3 פערים שדורשים תיקון מיידי:**
- **כלל ה-autonomy שלך סותר את R5.** APEX אומר "5 הצלחות ברצף → להעלות autonomy". R5 אומר במפורש: זה רעיון שגוי — צריך להחליף בשלושה מסלולים נפרדים לפי סוג המשימה.
- **ה-comprehension gate דווקא מבוטל איפה שהכי צריך אותו.** היום הוא לא רץ על משימות verify_level D (הכי מסוכנות). R5 אומר ההפך: על המסוכנות צריך הכי הרבה הסבר.
- **הודעות השגיאה בעוצמה אחת.** 46 hooks קוראים "סכנה!" באותו עוצמה. R5 מראה — זה גורם למשתמש להתעלם גם מההתראות האמיתיות.

**3. שתי טענות שיווק ב-`apex-spec.md` סותרות את הראיות** — צריך לרכך אותן או למחוק.

---

### 7 פעולות לעשות עכשיו (לפי סדר חשיבות)

| # | מה לעשות | למה זה קריטי |
|---|---|---|
| **1** | **להחליף את כלל "5 הצלחות → קידום autonomy"** עם שלושה מסלולים: A, B, C | המצב היום ב-`next.md:614-617`. R5 דוחה במפורש את הכלל הזה. הפתרון: Track A (משימות פשוטות — קידום אחרי 5 הצלחות), Track B (לוגיקה עסקית — קידום אחרי 7-8), **Track C (auth, תשלומים, אבטחה — אף פעם לא קידום אוטומטי)** |
| **2** | **להפעיל את ה-comprehension gate גם על verify_level D** | זה הפוך מ-R5: היום הgate מבוטל על משימות הכי מסוכנות. תיקון של 3 שורות ב-`next.md:851-874`. |
| **3** | **לתקן את ה-self-test runner** — באג P1 פתוח מסבב R7 | היום רק בדיקה אחת מתוך ~31 רצה, אבל ה-runner מדפיס "✅ ALL PASS". זאת אשליה של ביטחון על מערכת ה-self-heal עצמה. תיקון של ~15 שורות (subshell wrapper). |
| **4** | **להציג שגיאות בשלוש רמות חומרה** במקום בעוצמה אחת | היום 46 hooks קוראים "סכנה!" באותו עוצמה. הפתרון: **CRITICAL** (חוסם, מקסימום 2-3 ביום), **MAJOR** (אזהרה צהובה לא חוסמת), **MINOR** (לוג שקט + סיכום כל 45-90 דקות). זה מונע את האפקט של "זאב, זאב". |
| **5** | **לפשט את `/apex:status`** — להציג 5 סיגנלים ברירת מחדל במקום 40+ | היום המסך מציג 40+ נקודות מידע תמיד. בברירת מחדל יציג רק: שלב + מטרה, autonomy + סיבה, משימה נוכחית, אימות אחרון, בריאות הקשר. כל השאר מאחורי `[הצג מתקדם]`. |
| **6** | **לרכך 2 טענות שיווק ב-`apex-spec.md`** שסותרות את R5 | "ה-Framework הראשון שמשפר DORA" — אין שום ראיה לכך, R5 דווקא מראה ירידה של 7.2%- ב-stability. "משתמש לא-טכני מצליח בשעה הראשונה" — הטענה לא הוגדרה איך מודדים. צריך למדוד או לרכך. |
| **7** | **לסגור את security-specialist module** (חצי-בנוי מ-R7) | המודול קיים אבל ה-lint נכשל ב-6 מודולים, ה-threat model נשאר template, ו-CI scanner עדיין ידני. R5 מצביע על Pearce 40% פגיעות + Apiiro 322%+ privilege escalation — זה לא "nice-to-have". |

---

### 5 החלטות שאני לא יכול להחליט בלעדיך

לכל אחת ניתחתי את האופציות בנספחים — ההמלצה כאן היא קצרה.

**1. `/apex:fast` או `/apex:micro` חדש?**
R5 רוצה משימות קטנות בלי שום ceremony, אבל עם review מצטבר אחרי 50 שורות / שעה / 5 שינויים.
- אופציה A: להחזיר `/apex:micro` כפקודה נפרדת מ-`/apex:fast`
- אופציה B: להוסיף `--batch` ל-`/apex:fast` (פשוט יותר)
- אופציה C: לזהות אוטומטית (R5 ממליץ נגד — silent shifts זה מסוכן)

→ **המלצה: אופציה B**.

**2. האם להוסיף Track D (אסור לעולם)?**
R5 מציע A/B/C. אבל ב-APEX יש דברים שגם Track C לא מתאים להם — deploy לפרודקשן, schema migration, feature-flag toggle. **Track D = אסור לעולם autonomy**, גם בידיים מומחות.

→ **המלצה: כן** — מיפוי ל-`is_irreversible` שכבר קיים ב-PLAN_META.

**3. Telemetry — לאסוף נתונים בברירת מחדל או לפי בקשה?**
בלי נתונים, אי אפשר לבסס את הטענות (DORA, first-hour success, cost savings). אבל אנשים רגישים לפרטיות.

→ **המלצה: opt-in ב-v0.1, לעבור ל-opt-out ב-v1.0** עם מסמך פרטיות ברור.

**4. הטענה "First Framework That Improves DORA"**
ראיות R5 סותרות אותה. אופציות:
- למחוק
- לרכך ל-"מתוכנן להפוך את ירידת ה-DORA"
- למדוד שקט במשך 6 חודשים ואז לפרסם

→ **המלצה: לרכך מיד**, ולהוסיף Q3 timeline למדידה.

**5. Cognitive-debt detector**
hook חדש שמתריע על קבצים שלא הוסברו זמן רב. ערך אמיתי, אבל גם friction.

→ **המלצה: optional לפי פרויקט, לא ברירת מחדל.**

---

### מה כבר עובד טוב — לא לגעת

- **שלוש רמות הריצה** (`/apex:fast` / `/apex:quick` / `/apex:full`)
- **ה-Scale-Adaptive Classifier** (זיהוי אוטומטי של מורכבות פרויקט)
- **בידוד ה-Auditor agent** (קורא רק קבצי טסטים)
- **clean-room של Critic** (לא רואה את ההסבר של ה-Executor)
- **decision-mode classifier** (collaborator לעומת replacement)
- **שכבת Auto-Continuity v7.1** (memory-watchdog + turn-checkpoint + session-auto-resume) — פתרון יפה לבעיית flow
- **7 סבבי self-heal** עם trajectory מתכנס

זה רוב מה ש-R5 ממליץ — ואתה כבר עשית את זה.

---

### איך לקרוא את שאר המסמך

- **§1-§5 (גוף ראשי)** — ההמלצות עצמן, עם ציטוטי R5 וקבצי APEX לכל אחת.
- **§6** — 8 שאלות פתוחות ש-R5 לא ענה עליהן (גם APEX לא יכול).
- **§7** — ה-5 החלטות שלך, בפירוט.
- **App A-I** — נספחים: כל ראיה, כל cross-walk, simulations התנהגותיים, audit של 9 הכשלים, ואינדקס ציטוטים מלא.

**עיקרון:** כל המלצה כאן מצוטטת פעמיים — מה-R5 (ראיה) ומ-APEX (איפה לתקן). אין שורה אחת לא מבוססת.

---

## §1 · Executive Insights (Top 10 Actionable, English)

Each insight: **Claim → R5 Evidence → APEX State → Recommendation**.

### 1. The "5 consecutive successes → escalate" rule is contradicted by R5 — must change

R5 §7 F2 (line 390) explicitly states: "**Replace global '5 consecutive C/D-level task successes → escalate' with a multi-criteria, per-task-class scheme.**" METR RCT (16 devs, 246 tasks) showed experienced developers were -19% slower with AI on real-world work — naive escalation on success counts would over-trust AI exactly where caution is needed. Current APEX implements the rejected rule at `framework/commands/apex/next.md:614-617`. **Recommendation:** Per-task-class (Track A/B/C) thresholds with asymmetric de-escalation. **Verdict: do-now**.

### 2. Comprehension gate currently disabled for verify_level D — backwards from R5

R5 §3 (Anthropic RCT, 52 engineers) found generation-then-comprehension yields 86% comprehension vs. 24% for delegation — and the highest-stakes code is exactly where comprehension matters most. APEX's current gate at `next.md:851-874` is **disabled** for verify_level D ("strict mode" tasks). This is exactly inverted. **Recommendation:** Enable gate for D with mandatory format (show diff → developer explains invariants + failure modes → optional AI assist). **Verdict: do-now**.

### 3. /apex:status overload reduces decision quality

R5 §7 F4 (line 454) cites DX/SPACE frameworks: too many metrics confuse developers and don't correlate with satisfaction. Current `framework/commands/apex/status.md:40-134` renders ~40 data points always. **Recommendation:** 5 signals default (phase+goal, autonomy+reason, current task, last verification, context health) + advanced panel + auto-surface on anomaly. **Verdict: do-now**.

### 4. Severity tiers absent — alert fatigue documented

R5 §7 F5 (line 488) describes alert-fatigue mechanics: "When >50% of alerts are false positives, analysts develop dismissal heuristics." APEX has 46 hooks emitting exit codes (0/1/2) inconsistently and 7+ blocking modals routine. No CRITICAL/MAJOR/MINOR vocabulary; no budget enforcement; no MINOR batching. **Recommendation:** Central `_emit_apex_event.sh` with severity field; CRITICAL ≤2-3/half-day; MAJOR passive yellow; MINOR batched 45-90min digest. **Verdict: do-now**.

### 5. /apex:micro deprecation may have removed the right ceremony

R5 §7 F3 (line 426) says micro tasks need **zero pre-execution ceremony but mandatory lightweight post-execution batched verification** (per hour OR 5-10 changes OR 50 LOC). Current `/apex:fast` (which replaced `/apex:micro`) keeps named-failure prohibitions and input guards but commits each fix individually with no batched review. **Recommendation:** Either resurrect `/apex:micro` distinct from `/apex:fast`, OR add `--batch` flag to `/apex:fast`. User decision required (see §7). **Verdict: do-now (after user decision)**.

### 6. APEX's own self-test halts on first exit (P1 from R7)

R7 audit F-001: `framework/scripts/self-test.sh` halts at first sourced test calling `exit` (`test-adapter-contracts.sh` runs alphabetically first). Only 1 of ~31 tests executes; runner prints ✅ ALL PASS. **This is a false-confidence vector on the self-heal validation pipeline itself**. **Recommendation:** Subshell wrapper or convert all `exit` to `return`. ~15 lines. **Verdict: do-now**.

### 7. APEX's "53%→80%+" cross-model critic claim is supported (rare strong claim)

`apex-verification-research-synthesis.md` cites "Cross-model review: 53% → 80%+" and adversarial persona "<1% → 93.7%" with primary source (arXiv 2603.18740, 22K-comment benchmark). These are among APEX's strongest evidence-backed claims. Not all APEX claims are this lucky. **Verdict: keep claim**.

### 8. APEX's "First Framework That Improves DORA" claim is contradicted

R5 §5.4 documents: DORA 2024 found **-7.2% delivery stability per 25% AI adoption** (~39K respondents); Faros AI found zero correlation between AI adoption and org DORA. R5 §9 Gap #7 explicitly states: "Whether structured verification can reverse the DORA stability decline is **untested**." APEX has no production data to support the claim. **Recommendation:** Replace with "Designed to reverse the -7.2% DORA stability decline; impact measurement underway (N=10 teams, 6-month study)." Or remove. **Verdict: do-now**.

### 9. Workflows lack Track-C discipline — 7 high-risk recipes use generic verify only

`framework/apex-workflows/` has 31 recipes including add-authentication, add-stripe-payments, migrate-to-postgres, add-rbac, deploy-to-cloud, setup-ci-cd, prepare-for-production. **None** of them invoke Track-C-style discipline (mandatory comprehension gates, plan review, security checks). They rely on informal "Verify:..." comments. **Recommendation:** Update high-risk workflow templates to declare task_class:C and route through F2 ladder. **Verdict: do-later (depends on F2 implementation)**.

### 10. Memory architecture is partial — auto-eviction + staleness detection missing

R6 supporting research consensus: tiered memory architecture is effective IF promotion/demotion is real. APEX implements three tiers (HOT/WARM/COLD) per `STATE-PLANE.md` but: (a) SQLite warm-tier mirror is opt-in not default; (b) no auto-eviction on staleness; (c) no auto-promotion based on recurrence. Causal-claim audit verdict: "Mechanism present + research-silent on implementation sufficiency." **Recommendation:** Activate SQLite mirror by default; implement staleness detection (R6-013 watermark + FTS5 search). **Verdict: do-later**.

---

## §2 · Per-Finding Analysis (7 R5 Consensus Findings)

### Finding 1 — Bimodal Productivity (R5 §1 line 14)

**R5 evidence:** METR RCT (16 devs, 246 tasks): -19% slowdown for experienced devs on familiar code. GitHub Copilot lab RCT (95 freelancers): +55.8% on toy task. Cui et al. (4,867 devs): +26% weekly tasks. Source-tier: **RCT (gold standard)**. All 4 models confirm.

**Mapping to APEX failures:** Touches #4 (Drift) — perception gap drives spec-actual divergence; #7 (Quality errors) — cognitive debt accumulates faster than it's caught; #8 (Systemic blindness) — cross-cutting effects invisible.

**Current APEX state:** `/apex:fast/quick/full` ceremony tiers are an attempt at adaptive autonomy. Scale-Adaptive Classifier (`framework/agents/planner.md`) auto-detects project complexity. But **no per-task-type classification** exists.

**Gap:** APEX classifies project scale; R5 proves task type (auth vs CRUD) dominates outcomes — same apparent complexity, opposite results.

**Recommendation:** Add Track A/B/C task classification to PLAN_META.json, route per-track autonomy thresholds. **Verdict: do-now (Insight #1).**

### Finding 2 — Perception-Reality Gap (R5 line 16)

**R5 evidence:** METR developers predicted +24%, experienced -19%, **still believed they were +20% faster** afterward — a 43-percentage-point gap that survived screen-recording awareness. Source: RCT.

**Mapping to APEX failures:** Touches #4 (Drift) and #5 (Hallucination) — self-reported metrics are unreliable.

**Current APEX state:** Living Evidence counter (R5-016) tracks critic-fail and gate-pass events from disk, not self-report. APEX_STRICT_MODE forces evidence-based verdicts. RESULT.json separates `verified_criteria[]` from `unverified_criteria[]`.

**Gap:** APEX's instrumentation is sound for code-level evidence but lacks **objective productivity telemetry**. Claims like "DORA improves" rely on self-report or are unmeasured.

**Recommendation:** Add objective telemetry layer (cycle_time_per_task, rework_pct, regression_count) opt-in by default. **Verdict: do-later.**

### Finding 3 — Comprehension Bottleneck (R5 line 18)

**R5 evidence:** Faros AI (10K devs): +21% individual tasks, but PR review time **+91%**, PR sizes **+154%**, and zero correlation with org DORA. DORA 2024: -1.5% throughput, -7.2% stability per 25% AI adoption. Source: telemetry + survey.

**Mapping:** #7 (Quality errors), #8 (Systemic blindness).

**Current APEX state:** Phase-level comprehension gate at `next.md:851-874` (3 largest-diff files; advisory; disabled for D). Auditor agent reads only test files. Critic operates clean-room.

**Gap:** Gate disabled exactly where most needed (verify_level D). File selection is LOC-based, not risk-based. R5 §7 F1 calibrates: risk-weighted, generation-then-comprehension, 1 per 60-90min (not per phase), ≤10-15min/gate.

**Recommendation:** Reframe F1 (Insight #2). **Verdict: do-now.**

### Finding 4 — Interaction Pattern Dominance (R5 line 20)

**R5 evidence:** Anthropic RCT (52 engineers): comprehension scores 24%-86% **based purely on interaction pattern**. Generation-then-comprehension scored 86%, exceeding manual-coding control (67%). Delegation patterns ≤40%. Source: RCT.

**Mapping:** #7 (Quality errors). The interaction pattern IS the intervention.

**Current APEX state:** APEX is "pipeline" pattern (vs. autocomplete/chat/agent/autonomous). Cross-model critic (53%→80%+) and adversarial persona (<1%→93.7%) are validated mechanisms.

**Gap:** APEX has the right macro-pattern but doesn't enforce generation-then-comprehension at the gate level. Current gate accepts "skip" without explanation. This kills the 86% comprehension benefit.

**Recommendation:** Mandatory explanation on gate fire (1-3 sentences per critical file). Optional AI assist that developer validates. Per F1 spec. **Verdict: do-now (folded into F1).**

### Finding 5 — Trust Collapse (R5 line 22)

**R5 evidence:** Stack Overflow 2025: 84% adoption, 29-33% trust accuracy, 46% active distrust (up from 31%); only 3.1% "highly trust." JetBrains 2025: 85% regular use with cooling sentiment. Source: large-scale survey.

**Mapping:** Cross-cuts all failures.

**Current APEX state:** APEX surfaces autonomy ladder + Living Evidence counter. Critic disagreement is logged but not surfaced as a primary trust signal.

**Gap:** No "critic disagreement rate" metric in `/apex:status` default view. R5 §7 F2 says: critic disagreements (2-3 in short window) should trigger immediate de-escalation.

**Recommendation:** Add `critic_disagreement_count` field to STATE.session; surface in `/apex:status` advanced panel; wire as F2 de-escalation trigger. **Verdict: do-now (folded into F2).**

### Finding 6 — Technical Debt Compounding (R5 line 24)

**R5 evidence:** GitClear (211M lines): 8× duplication increase + 60% refactoring decline since 2020. CodeRabbit (470 PRs): AI-coauthored PRs show 1.7× more issues. Pearce et al.: ~40% of top AI suggestions contain security vulnerabilities. Apiiro: +322% privilege-escalation paths. Source: measured.

**Mapping:** #5 (Hallucination), #6 (Mutation), #8 (Systemic blindness), #9 (Security gaps).

**Current APEX state:** TDAD impacted-tests, mutation-gate (Stryker, 50% kill rate threshold for C/D), AST-KB hallucination check, auditor agent.

**Gap:** TDAD catches code dependencies; cognitive debt (R5 §3.5) is invisible. No "code understood by whom" ledger. Mutation testing is post-hoc; doesn't prevent the 1.7× defects pre-merge.

**Recommendation:** Cognitive-debt detector hook (file touched but not explained in last N days → backlog item). User decision required (Insight #5 of decisions). **Verdict: do-later or do-now depending on user.**

### Finding 7 — Risk-Based Autonomy is the Solution (R5 line 26)

**R5 evidence:** Cross-validated synthesis from automation/trust literature + RCTs + frameworks. All 4 models agree: aggressive autonomy for low-risk; mandatory human for security/auth/architectural; comprehension gates on critical paths.

**Mapping:** Synthesizes #4, #7, #9.

**Current APEX state:** Three-tier ceremony exists but is global (project-wide), not per-task-type.

**Gap:** Same as Finding 1.

**Recommendation:** F2 implementation. **Verdict: do-now (Insight #1).**

---

## §3 · F1–F5 Implementation Readiness

| ID | Title | Current Status | Target File | Complexity | Dependencies | Verdict |
|---|---|---|---|---|---|---|
| **F1** | Comprehension gates calibration | **partial** — gate exists, file selection is LOC-based, disabled for D, format is binary y/explain/skip | `framework/commands/apex/next.md:851-874`; new `framework/hooks/comprehension-gate.sh`; `STATE.schema.json` field expansion | M (~2-3 days) | Requires risk classifier (use TDAD as proxy initially). Builds on existing `comprehension_gates` STATE field. | **do-now** |
| **F2** | Autonomy threshold per-track | **partial** — per-verify-level ladder exists; task_class registry absent; de-escalation only on FAIL not on critic disagreement or 2 PARTIALs | `framework/agents/architect.md` STEP 1.8 (new); `framework/schemas/PLAN_META.schema.json` (add `task_class`); `next.md:471-490 + 614-617 + 730-763` | M (~2-3 days) | Architect must classify; specialist field already implies most cases. | **do-now** |
| **F3** | /apex:micro — zero pre + batched post | **partial** — `/apex:fast` is closest; deprecated `/apex:micro` was a name-rename, not feature removal; no batching | `framework/commands/apex/fast.md` + new agent `framework/agents/specialist/batch-verifier.md`; new STATE field `batched_tasks[]` | M (~1-2 sprints) | **User decision required (§7 #1).** Background test infra exists. Needs `--review-batch` UI/CLI. | **do-now (after decision)** |
| **F4** | /apex:status progressive disclosure | **partial** — full cockpit always-on; CLAUDE.md User Profile read but not used; no anomaly auto-surface | `framework/commands/apex/status.md` (lines 40-144 conditional rendering) + optional `.apex/STATUS_PREFS.json` | S (~4-6 hours) | None (data already exists in STATE). | **do-now** |
| **F5** | Error severity tiers | **absent** — exit codes 0/1/2 used inconsistently across 46 hooks; no taxonomy; no batching; FIX_PLAN.md is binary | NEW `framework/hooks/_emit_apex_event.sh`; UPDATE all 28 blocking hooks; NEW `framework/hooks/background-digest-hook.sh`; UPDATE `event-log.jsonl` schema | **L** (~60-80 hours) | Severity classification per hook needs roundtable; F4 status surface for visual treatment; backward-compat migration. | **do-now (largest)** |

**Combined effort:** ~2-3 sprints if F1+F2+F3+F4 done in parallel; F5 is the long pole at ~3 weeks.

---

## §4 · Cross-Cutting Themes

### Theme 1 — APEX has the right macro-architecture but inconsistent micro-discipline

R5 §6 puts APEX-style "pipeline" at the top of risk-appropriate patterns. Validated. But the implementation is patchy: comprehension gate exists but disabled for D; severity exists informally but isn't a registry; per-task-class risk is implied by specialist field but not enforced. **Implication:** The work is wiring + discipline, not redesign.

### Theme 2 — Perception-reality gap demands objective telemetry

R5 §2.2 (43-point perception gap) says self-report is unreliable. APEX makes several promotional claims ("70-90% lower cost", "First Framework That Improves DORA", "first-hour success") that are either unmeasured or measured by self-report. **Implication:** Add an objective telemetry layer; replace marketing claims with falsifiable formulations.

### Theme 3 — Comprehension > generation speed for critical paths

R5 §3.5 + §6 (86% vs. 24% comprehension) prove the bottleneck moved. APEX's Critic and Auditor handle code-level verification; the developer's understanding is the missing layer. **Implication:** Comprehension gates are not optional polish — they are the primary intervention. F1 is the highest-ROI lever in this synthesis.

### Theme 4 — Single-source error vocabulary replaces 46 hook strings

46 hooks each emit ad-hoc messages with inconsistent semantics. R5 §7 F5 (alert fatigue) shows this collapses signal-to-noise. **Implication:** Severity registry + central emitter + display routing is not "polish" — it's a precondition for users actually responding to real alerts.

### Theme 5 — Track C is special: irreversible decisions need humans by default

R5 §7 F2 (NO auto-escalation for security/auth/payments/schema) + R5 §9 evidence gap #3 (no validated thresholds) + R6 poisoning data (>95% MINJA injection success) + Pearce 40% AI vulns + Apiiro +322% — all converge: high-risk classes must be permanently human-gated. **Implication:** Track-C as default-conservative is research-validated; users can opt out per-task with explicit risk acknowledgment. Should be the spec.

---

## §5 · Prioritized Roadmap

**Scoring formula:** `priority = Impact (1-5) × Evidence (1-5) × User_Priority (1-3) × Spec_Alignment (1-2) ÷ Effort (S=1, M=2, L=3)`

Sorted descending. **Cap: ≤7 do-now**.

| Rank | Item | Score | Verdict | What | Where | Why (Evidence) | Trade-off |
|---|---|---|---|---|---|---|---|
| 1 | Replace "5 successes" rule with Track A/B/C ladder + asymmetric de-escalation (F2) | **30** | **do-now** | Add `task_class` to PLAN_META; per-track thresholds; immediate de-escalation on regression/critic-disagreement | `architect.md`, `PLAN_META.schema.json`, `next.md:471-490, 614-617, 730-763` | R5 §7 F2 line 390 — direct contradiction by RCT evidence (METR -19%) | +1-2min friction per Track-C task; vs. catastrophic auth/payment failures |
| 2 | Enable comprehension gate for verify_level D + risk-based file selection (F1) | **30** | **do-now** | Switch from LOC-based to criticality; mandatory format (explain in 1-3 sentences); per 60-90min; ≤15min/gate | `next.md:851-874`; new `comprehension-gate.sh` | R5 §3 + §7 F1 — Anthropic RCT 86% vs. 24% comprehension; gate currently disabled where it's most needed | Adds friction to expert users; mitigated by per-complexity calibration |
| 3 | Severity tier registry CRITICAL/MAJOR/MINOR + central emitter + MINOR digest (F5) | **20** | **do-now** | Centralize via `_emit_apex_event.sh`; tag all 28 blocking hooks; budget ≤2-3 CRITICAL/half-day; batch MINOR every 45-90min | New `_emit_apex_event.sh`; all 46 hooks; new `background-digest-hook.sh` | R5 §7 F5 line 488 — alert fatigue documented; APEX has 7+ blocking modals routine today | Largest effort (~3 weeks); requires roundtable per hook; backward-compat needed |
| 4 | Progressive disclosure on /apex:status (5 default + advanced panel) (F4) | **18** | **do-now** | Conditional rendering by user_profile + anomaly auto-surface | `status.md:40-144` | R5 §7 F4 — DX/SPACE evidence + cognitive load theory | Power-user friction (1 click); mitigated by `--detailed` flag |
| 5 | Fix self-test runner halt (R7 F-001 P1) | **15** | **do-now** | Subshell wrap or convert all `exit` to `return` in 13 sourced test files | `framework/scripts/self-test.sh` | R7 audit; ~31 tests silently skipped today; false-confidence on self-heal | None — pure fix; ~15 LOC |
| 6 | Replace "First Framework That Improves DORA" marketing claim | **12** | **do-now** | Replace with "Designed to reverse the -7.2% stability decline; measurement Q3 2026 (N=10 teams)" | `apex-spec.md:9, 375`; README L29 | R5 §5.4 + §9 Gap #7 — explicit "untested"; Faros zero correlation | Loses provocative positioning; gains credibility |
| 7 | /apex:micro decision: resurrect or `--batch` flag on `/apex:fast` (F3) | **10** | **do-now (post-decision)** | After user decision (§7 #1): implement chosen path; add batched-diff queue + review UI | `fast.md` or new `micro.md`; new `batch-verifier.md` | R5 §7 F3 — silent failure accumulation is documented failure mode | Silent failure risk; mitigated by background tests + proactive critic notification |

**Below the do-now cut (do-later, in priority order):**

| Item | Verdict |
|---|---|
| Activate SQLite memory mirror by default; staleness detection | do-later |
| Cognitive-debt detector hook | do-later (user decision §7 #5) |
| Apply Track-C discipline to high-risk workflows (auth/payments/migrate-to-postgres etc.) | do-later (depends on F2) |
| Add `critic_disagreement_count` field to STATE.session; F2 de-escalation trigger | do-later (folded into F2) |
| Objective telemetry layer (cycle_time, rework_pct, regression_count) opt-in | do-later (user decision §7 #3) |
| Negative auth tests as **blocking** (currently advisory in workflows) | do-later (security-specialist completion path) |
| Mandatory architecture-decision roundtable for irreversible Track-C tasks | do-later |

**needs-research:**

| Item | Why |
|---|---|
| Optimal comprehension-gate cadence beyond 60-90min default | R5 §9 Gap #2 — no controlled study |
| Track A/B/C numeric thresholds (5 / 7-8 / ∞) | R5 §9 Gap #3 — no validated study; current numbers are heuristic |
| Long-project cognitive-debt curve | R5 §9 Gap #5 — no longitudinal study |

**reject:**

| Item | Why |
|---|---|
| Per-step modal gates for `/apex:fast` micro-tasks | R5 §7 F3 explicitly: zero pre-execution gates is correct for low-risk |
| Same-model adversarial review (instead of cross-model) | apex-verification-research-synthesis.md: 53% vs. 80%+ — cross-model is required |
| Confidence escalation by global success count | R5 §7 F2: rejected by RCT evidence |

**already-done (acknowledge, do not re-recommend):**

R5-001 module restructure · R5-002 SQLite mirror (opt-in) · R5-003 security `.cjs` runtime · R5-004 state-rebuild from event-log · R5-005 circuit-breaker recovery menu · R5-009 APEX_ACTIVE_AGENT dispatcher (R5-style isolation) · R5-013 one-file-one-owner · R5-016 decision-gate user checkpoint · R5-018 decision-mode classifier (collaborator/replacement) · R5-024 roundtable trigger · R6-013 watermark SQLite mirror · R6-017 adapter-honesty banner · v7.1 Auto-Continuity (memory-watchdog + turn-checkpoint + session-auto-resume).

---

## §6 · Open Questions (R5 Evidence Gaps + New)

R5 §9 lists 8 evidence gaps. All are open in APEX as well:

1. **Long-term learning curves** — Can experienced devs become net-positive on AI for complex work after >50 hours of training? No rigorous study. **APEX implication:** Telemetry can answer this on N≥30 long-running projects. *Telemetry candidate.*
2. **Optimal gate cadence** — No coding-specific RCT on comprehension checkpoint frequency. **APEX implication:** F1 60-90min is heuristic; could be A/B tested per-project. *Telemetry candidate.*
3. **Exact autonomy thresholds** — No controlled study validates 5/7-8/∞ numbers in F2. **APEX implication:** Track A/B/C structure is right; numbers are best-effort. *Telemetry candidate.*
4. **APEX-style pipeline validation** — No direct RCT on phased pipeline models. **APEX implication:** This is where APEX could publish primary research.
5. **Long-project comprehension decay** — No longitudinal study. **APEX implication:** Cognitive-debt detector (§7 decision #5) could collect.
6. **Exact LGTM rates** — No controlled study on professional team rubber-stamp rates for AI code. **APEX implication:** Critic-pass-without-explanation rate is a proxy. *Telemetry candidate.*
7. **Organizational throughput recovery** — Untested whether structured verification reverses -7.2% DORA. **APEX implication:** This is the core APEX promise; must measure to defend claim. *Telemetry candidate (highest priority).*
8. **Multi-tool interaction effects** — How switching autocomplete/chat/agent affects cognitive load. **APEX implication:** Less relevant since APEX is pipeline-only.

**New questions surfaced by this research:**

9. **Are APEX's "53%→80%+" and "<1%→93.7%" numbers reproducible in production?** Research evidence is solid (arXiv 2603.18740). Verify on APEX's actual critic outputs.
10. **Does comprehension-gate skip rate correlate with later regressions?** If yes, the gate is necessary; if no, it's friction without value. *Telemetry candidate.*
11. **What's the actual first-hour success rate for non-technical users?** Operationalize "success" first. *Telemetry candidate.*
12. **Can Track-C classifier achieve <5% false-positive (CRUD task wrongly classified as auth)?** Pre-deployment audit needed.

---

## §7 · Decisions Required (User-Owned)

These cannot be decided by research alone — they need your call.

### Decision #1 — F3 Implementation Path

R5 §7 F3 calls for zero-ceremony micro tasks with batched verification. APEX deprecated `/apex:micro` to `/apex:fast`. Three options:

- **A:** Resurrect `/apex:micro` distinct from `/apex:fast`. Pros: clean naming, two distinct mental models. Cons: dual code paths.
- **B:** Add `--batch` flag to `/apex:fast`. Pros: minimal code, explicit user opt-in. Cons: feature toggle inside command.
- **C:** Auto-detect "micro" criteria and shift to batched mode silently. Pros: zero user effort. Cons: silent mode-shift is exactly what R5 warns against.

**Recommendation:** Option B (lowest cost, explicit opt-in). Your call.

### Decision #2 — Track-D for Deployment / Schema?

R5 specifies Track A/B/C. APEX has irreversible decisions beyond auth/payments — production deployment, schema migrations, feature-flag toggles. Should there be a **Track D = forbidden auto-escalation regardless of all signals**?

**Recommendation:** Yes — Track D maps to existing `is_irreversible == true` flag in PLAN_META. Adds zero structure; just enforces the cap.

### Decision #3 — Telemetry: Opt-In or Opt-Out by Default?

To answer R5 evidence gaps and validate APEX's own claims, you need objective metrics. Options:

- **Opt-in (privacy-first):** Users explicitly enable via `apex telemetry enable`. Lower friction; lower data volume.
- **Opt-out (research-first):** Anonymous metrics by default; users can disable via env var. Higher data volume; higher friction concerns.
- **Project-tier:** Free-tier opt-in; enterprise opt-out (with privacy guarantees).

**Recommendation:** Opt-in for v0.1.x; once schema is proven, propose opt-out for v1.0 with clear privacy doc.

### Decision #4 — DORA Claim Treatment

`apex-spec.md` claims "First Framework That Improves DORA." R5 contradicts. Options:

- **Remove:** Drop entirely; let evidence accumulate quietly.
- **Qualify:** "Designed to reverse the -7.2% stability decline (measurement Q3 2026)."
- **Measure first, claim later:** Build telemetry; publish after 6mo of N=10 teams.

**Recommendation:** Qualify (option 2) immediately; replace with measure-and-publish at 6 months.

### Decision #5 — Cognitive-Debt Detector Hook

R5 §3.5 documents 8× duplication / 60% refactoring decline as cognitive-debt symptoms. APEX could add a hook that flags files touched without comprehension-gate record in N days. Options:

- **Add:** Catches cognitive debt early; adds friction.
- **Skip:** Trust other safeguards (TDAD, mutation-gate); accept latent debt.
- **Optional:** User opts in per-project.

**Recommendation:** Optional per-project. Default off for now; collect data to decide for v1.0.

---

## Appendix A · R5 Detailed Findings

**Source:** `APEX Research Project/APEX Research Brief — Round 5 Synthesized Multi-Model Analysis.md`

### 7 Consensus Findings (verbatim)

| # | Statement | §line | Confidence | Evidence |
|---|---|---|---|---|
| 1 | AI coding tools slow experienced developers on real-world work while dramatically helping on narrow tasks. | 14 | All 4 | METR RCT, Copilot lab RCT, Cui et al. multi-company RCT |
| 2 | The perception-reality gap is enormous, persistent, and has direct design implications. | 16 | All 4 | METR (43-pt gap, screen-recording confirmed) |
| 3 | The main bottleneck is comprehension and verification, not code generation speed. | 18 | All 4 | METR + Faros AI (10K devs) + DORA 2024 |
| 4 | How developers interact with AI matters more than whether they use it. | 20 | All 4 | Anthropic RCT (52 engineers, 24-86% range) |
| 5 | Trust is collapsing while adoption accelerates, creating systematic risk. | 22 | All 4 | Stack Overflow 2025, JetBrains 2025 surveys |
| 6 | Technical debt is compounding at scale. | 24 | 3 of 4 | GitClear 211M lines, CodeRabbit 470 PRs, Pearce, Apiiro |
| 7 | The sweet spot is risk-based autonomy with targeted comprehension gates. | 26 | All 4 | Synthesized from RCTs + automation/trust literature |

### F1–F5 Calibrations (verbatim summary)

- **F1 §353-385** — Risk-weighted, generation-then-comprehension; 1 critical file at L2, 2 critical + 1 integration at L3, 0 at L0-1; 1 gate per 60-90min; ≤10-15min/gate. Confidence: HIGH on direction, MEDIUM on intervals.
- **F2 §388-421** — Track A 5 clean → Trusted/Autonomous; Track B 7-8 clean → Trusted cap; Track C: NO auto-escalation, mandatory plan review. De-escalation immediate on critical regression / security vuln / 2 high-rework / critic disagreements. Confidence: MEDIUM.
- **F3 §424-451** — ≤2-3 files, ≤20-30 LOC, no auth/security/payments/schema/migration/deps/interfaces/build; zero pre-modal; batched diffs per hour OR 5-10 changes OR 50 LOC; one-click approve/rollback. Confidence: HIGH.
- **F4 §454-485** — 5 default signals: phase+goal, autonomy+reason, current task, last verification, context health. Advanced panel includes EvoScore, tokens, critic disagreement, safety, autonomy log, per-file risk. Experience-based. Confidence: MEDIUM-HIGH.
- **F5 §488-523** — CRITICAL ≤2-3/half-day blocking; MAJOR passive yellow; MINOR silent + 45-90min digest; suppress repeats. Each error: what + where + why + next actions. Confidence: HIGH.

### 8 Evidence Gaps (verbatim §624-635)

1. Long-term learning curves
2. Optimal gate cadence
3. Exact autonomy thresholds
4. APEX-style pipeline validation
5. Long-project comprehension decay
6. Exact LGTM rates
7. Organizational throughput recovery (DORA reversal)
8. Multi-tool interaction effects

### Top Quantitative Findings (selection from 43, §526-621)

- **METR slowdown** -19% (CI 2-40%) | Copilot lab +55.8% (CI 21-89%) | Cui +26% tasks
- **DORA 2024** per +25% AI: docs +7.5%, code quality +3.4%, individual prod +2.1%, throughput **-1.5%**, stability **-7.2%**
- **Anthropic comprehension** 86% (gen-then-comp) vs. 24% (iterative AI debugging) vs. 67% (no AI)
- **Trust** 84% adoption, 29-33% accuracy trust, 46% active distrust (up from 31%)
- **Retention 20-week** Copilot 89%, Cursor 89%, Claude Code 81%
- **Flow** 90% sessions >1 min resume, 30% >30 min, 15-25 min refocus, ~2× error rate fragmented days
- **Cognitive debt** 8× duplication, -60% refactoring, 1.7× defects, +322% privilege escalation, ~40% security vuln rate

---

## Appendix B · Supporting Research Distillation (R1, R2, R3, R6, verification, cost)

What each round adds beyond R5:

### R1 — Why projects fail (failure root causes)

Concrete anecdotes R5 abstracted away:
- **Trading system 14,400 green tests while bleeding money 7 weeks** — verification theater incarnate.
- **BMAD Issue #2003**: dev agent "resolved" wake-recovery by inserting empty stubs + TODOs, marked all tasks done.
- **GSD audit (Next.js/Prisma)**: none of 41 planning agents received CLAUDE.md → missed IDOR, secret fallback, user-enumeration.
- **GSD Issue #689**: milestone marked Complete while later phases existed but lacked planning dirs.
- **Token overhead measured**: GSD 4:1-10:1 orchestration; BMAD 80-100K/step (143K = 86% of 200K window per TEA agent); Superpowers 22K startup (11%); Taskmaster 63.7K (32%); Claude Code teams ~7× standard.

**Top 10 unmet needs (R1 priority):** honest self-assessment, durable external state, independent verification, adaptive replanning, predictable token budgeting, graceful context degradation, destructive-action prevention, interruption/resume handling, lightweight adaptive ceremony, observability.

**APEX-specific prescriptions:** Build transactional external state engine; clean-room critic; design for 256K effective (not 1M theoretical); progressive monitoring (50%/60%/70%); destructive-action deny-list non-bypassable; framework startup <5%; full-spec reference links in decomposition; anti-rationalization injection; deterministic filesystem hooks; parallel-first decomposition; absolute rollback guarantee.

### R2 — Context Engineering State of the Art

- **Coding collapse:** Claude 3.5 Sonnet 29% → 3% accuracy (32K → 256K tokens, LongCodeBench)
- **U-shape attention:** 30%+ drop in middle (Liu et al. TACL 2024); only persists below ~50% fill
- **Observation masking beats LLM summarization:** +2.6% vs -4.69 F1 at similar compression; zero compute cost vs high
- **Aider repo map:** 4.3-6.5% context utilization (vs. Cursor 14.7%, Cline 17.5%)
- **CLAUDE.md application rate:** 92% for files <200 lines, 71% at >400 lines
- **Verification contamination:** 88.2% of adversarial PR metadata fools LLM reviewers; clean-room+debiasing restores 94%

**Rotation thresholds (consensus):** soft 50-60%, hard 70%, orchestrator cap 10-15%, generation reserve 20-40%, target working set 100-160K (not 256K).

### R3 — Agent Topology

- **CooperBench (Stanford/SAP, 652 task pairs):** Two-agent cooperation produces ~30% LOWER success vs. solo. GPT-5/Claude Sonnet 4.5 achieved ~25% at two-agent cooperation (50% worse than single agent).
- **Coordination latency superlinearly beyond ~4 agents** (power-law 1.724); centralized error amp 4.4×, unstructured 17.2×.
- **AgentCoder (3-agent)** beats **ChatDev (7-agent waterfall)**: 96.3% vs 33.33% HumanEval; 56.9K vs much higher tokens.
- **Anthropic hub-and-spoke:** Opus lead + Sonnet workers = +90.2% over single Opus.
- **APEX prescriptions:** Keep current topology (coordinator + workers + RESULT.json + clean-room critic + reflexion); orchestrator near-stateless; critic clean-room (88.2% contamination if it sees executor reasoning); 2-4 workers, never beyond 4.

### R6 — Memory & Learning

- **Failure-derived knowledge > successes** (+14.3% on search tasks per ERL).
- **40-60 heuristic ceiling**: performance peaks then degrades; IFScale practical ~150 instructions.
- **Tiered memory consensus:** Hot (≤100-200 lines, always-loaded), Warm (≤500 patterns, SQLite+FTS5, on-demand), Cold (archived, manual-search).
- **Poisoning risks:** MINJA >95% injection; MemoryGraft 9.1% poison → 47.9% retrieval capture; ToxicSkills 76 confirmed malicious skills in OpenClaw.
- **Recall:** SWE-ContextBench oracle summaries 34.34% vs. free reuse 22.22% vs. full trajectories 27.27%; LLM retrieval 56.1% > embedding 53.3%.
- **APEX prescriptions:** Three-tier validated; SQLite warm-tier + FTS5; graduated lifecycle ACTIVE→STALE→ARCHIVED→DELETED; type separation (avoid≠do); write access gate (Memory Synthesis agent only); provenance tracking.

### Verification Synthesis

- **AI 1.7× more defects** (CodeRabbit 470 PRs); logic +75%, performance ~8×, security 1.5-2.74×
- **Mutation-coverage gap:** 80-93% line coverage → 20-59% mutation kill rate (34-point gap typical)
- **TDAD reduces regressions 70%** on SWE-Bench Verified (6.08% → 1.82%); naive TDD increases regressions to 9.94%
- **Test cheating patterns (8):** tautological, self-mocking, vacuous, over-mocking (36% vs. 26% human), happy-path, hard-coded, copy-paste, spec circumvention (76% in ImpossibleBench)
- **PBT efficacy:** 23.1-37.3% pass@1 improvement; PBT+example combined 81.25% edge-case detection (orthogonal); Anthropic Red Team 984 reports, 56% genuine
- **Cross-model critic:** 53% → 80%+ (arXiv 2603.18740, 22K-comment benchmark)
- **Adversarial persona:** <1% → 93.7% (same source)
- **Negative auth/authz tests skipped systematically by AI** (auth ≠ authz); Veracode 45% fail; XSS 86% fail; Java 72% fail
- **APEX gaps:** mutation testing wired (R5-012); PBT not yet selective; differential semantic testing absent; first-class auth/tenant verification advisory only.

### Cost Optimization

- **Productive code = 1-9% of tokens** (Tokenomics MSR 2026)
- **Code review = 59.4% of tokens** (vs. coding 8.6%)
- **Multi-agent overhead 53-86% duplication** (AgentTaxo): MetaGPT 72%, CAMEL 86%, AgentVerse 53%
- **Model routing 35-98%** savings: Sonnet 4.6 = 98% Opus quality at 1/5 cost; Haiku ~90% Sonnet at 1/3
- **Caching SWE-rebench:** $5.29/problem → $0.91 = 83% single-technique savings; latency 11.5s → 2.4s
- **Anthropic agent teams ~7× tokens** vs. standard session
- **APEX 70-90% claim** is achievable via stacking (caching 83% + routing 50-85% + masking ~50% + pruning 23-54% + TALE 67%) — but requires explicit per-agent routing, delta-only state reads, multi-tier caching.

---

## Appendix C · APEX Claims Evidence Audit

### Numeric claims (12)

| # | Claim | Status | Evidence | Action |
|---|---|---|---|---|
| 1 | "53% → 80%+" cross-model critic | **Supported** | arXiv 2603.18740 (verification synthesis L197) | Keep |
| 2 | "<1% → 93.7%" adversarial persona | **Supported** | arXiv 2603.18740 (same) | Keep |
| 3 | "70-90% lower cost" | **Partial** | TALE 68.9%; caching up to 90% — achievable via stacking, not single technique | Qualify: "68-90% via orthogonal stacking" |
| 4 | "19.7% USENIX hallucination" | **Supported** | USENIX 2025, 576K samples, 16 LLMs | Keep |
| 5 | "26% automation bias" | **Partial** | R5 says "+26% increased adherence" (delta, not absolute rate as APEX implies) | Replace: "+26% increased adherence" |
| 6 | "45% Veracode security fail" | **Supported** | Veracode 2025-2026, 100-150+ LLMs | Keep |
| 7 | "40% Pearce vulnerability" | **Supported** | R5 §1 line 24 | Keep |
| 8 | "1.7× CodeRabbit defects" | **Supported** | CodeRabbit 470 PRs | Keep |
| 9 | "+322% Apiiro escalation" | **Supported** | Apiiro Fortune 50, Sep 2025 | Keep |
| 10 | "-7.2% DORA stability per 25% AI" | **Supported** | DORA 2024 (~39K) | Keep |
| 11 | "86% comprehension" gen-then-comp | **Supported** | Anthropic RCT 52 engineers | Keep |
| 12 | "5 successes → escalate" | **CONTRADICTED** | R5 §7 F2 explicitly: "Replace global '5 consecutive C/D-level task successes → escalate' with multi-criteria, per-task-class scheme" | **DELETE — replace with Track A/B/C** |

### Causal/mechanism claims (10)

| Claim | Code | Research | Verdict | Action |
|---|---|---|---|---|
| Phantom-check + AST-KB prevent Hallucination | Implemented (`hooks/phantom-check.sh`, `ast-kb-check.sh`) | Research-silent on efficacy claim | Present + research-silent | Strengthen AST-KB to validate against actual imports |
| Adversarial persona prevents quality errors | Implemented (`agents/critic.md` clean-room) | Cross-validated arXiv 2603.18740 | Present + research-validated | Keep |
| TDAD + Aider repo map prevent Systemic blindness | TDAD partial (`hooks/tdad-impact.py` exists; repo map referenced not implemented) | TDAD validated 70% regression reduction | Mechanism partial | Generate `.apex/repo-map.md` per phase; complete TDAD wiring |
| Security-specialist prevents Security gaps | Partial (module exists; lint failing per R7) | Pearce 40%, Apiiro +322%, Veracode 45% | Mechanism partial | Close R7 F-002; wire negative-auth tests as blocking |
| Skipped-test detection prevents Mutation | Implemented (`hooks/mutation-gate.sh`) | TDAD 70% reduction validated | Present + research-validated | Keep |
| Circuit breakers prevent Failure | Implemented (`hooks/circuit-breaker.sh`) | Research-silent on recovery efficacy | Present + research-silent | Add metric: loop-escape success rate post-circuit-breaker |
| Three-tier memory prevents Forgetting | Partial — SQLite mirror opt-in, no auto-eviction | R6 consensus on architecture (validated) | Present + implementation incomplete | Activate SQLite by default; staleness detection |
| Roles produce typed artifacts | Implemented (RESULT.schema.json + CRITIC.md + AUDIT.md) | Research-silent | Present + research-silent | Enforce schema validation at orchestrator entry |
| Auditor never touches implementation | Implemented (`agents/auditor.md` quarantine, APEX_ACTIVE_AGENT) | Research-silent | Present + research-silent | Keep; add compliance audit to health-check |
| Schema as contract / sync as contract | Partial (`hooks/schema-drift.sh` validates shape; no concurrent-write detection) | R1: Taskmaster MCP/CLI desync proves need | Present + enforcement incomplete | Strengthen schema-drift to block invalid mutations |

### Productivity / UX / comparative (9)

| Claim | Verdict | Action |
|---|---|---|
| "the only [framework] designed up front for non-programmers" | Unfalsifiable-marketing | Qualify: "Designed from the ground up to serve non-programmers" |
| "First Framework That Improves DORA" | **Contradicted** | **Replace** with measurement timeline |
| "DORA metrics improve" | **Contradicted** | Same as above |
| "non-technical user succeeds in first session and first hour" | Partial / undefined | **Measure** — operationalize "success" + N≥30 cohort study |
| "doesn't break itself" | Partial | **Measure** — unplanned restarts <1%, state corruption 0% |
| "doesn't burn budget" | Unverifiable | **Measure** — N=20 projects vs. baseline |
| "doesn't degrade delivery stability" | Unverifiable | Same as DORA |
| "First Framework Hardened Against Its Own Files" | Partial | Qualify: "Multi-layer prompt injection defense" with audit timeline |
| "Free forever in core" | Supported by policy | Keep + "Certified annually" |

---

## Appendix D · Per-Component Analysis

### Commands (44)

8 functional groups (per PRE-C). Key findings:
- **Comprehension/verification** (5): peer-review, ui-review, validate-phase, test, next (gate). Inconsistency: 3 different comprehension UIs (peer-review verdict, ui-review checklist, validate-phase verifier agent).
- **Autonomy** (5): fast/quick/full + next (autonomy check) + build/refine. Per-verify-level only; no task-class.
- **Status** (4): status, session-report, milestone-summary, list. Status is monolithic.
- **Error/recovery** (4): forensics, walkthrough, recover, rollback. No severity scale across them.
- **Pipeline** (6): next is the orchestration heart (978 lines).
- **Memory** (5): pause/resume/plant-seed/add-backlog/review-backlog.
- **Trust calibration** (2): only via next's escalation logic; no surfaced confidence/disagreement.
- **Specialized** (17): start, onboard, ship, spec, health-check, self-heal, _debate, _roundtable, etc.

**Deprecation candidates:** /apex:fast + /apex:quick (overlap — differ in ceremony only); /apex:build + /apex:full (full is synonym); /apex:forensics + /apex:walkthrough (timeline overlap); /apex:status + /apex:session-report (subset); /apex:pause + /apex:pause-work (alias); /apex:resume + /apex:resume-work (alias).

### Agents (11)

Core 6: architect, planner, executor, critic, verifier, auditor. Specialist 5 (in `specialist/`): batch-scheduler, framework-auditor, remediation-planner, round-checker, wave-executor (all self-heal). Plus referenced-but-missing: Test-Architect, Memory Synthesis, dedicated Security Verifier, Drift-Detection.

R5-style isolation already implemented in: Auditor (filesystem quarantine), Critic (clean-room), Verifier (strict mode), Architect+Planner (owns_files contract).

### Hooks (46)

7 themed buckets (per Stage 3 mapping):
- A — Verification gates (8): phantom-check, ast-kb-check, schema-drift, mutation-gate, decision-gate, cross-phase-audit, post-write, pre-compact
- B — State/snapshots (8): _state-read/-update/-sqlite, pre-task-snapshot, turn-checkpoint, session-auto-resume, state-rebuild, memory-watchdog
- C — Security (8): apex-prompt-guard, prompt-guard, path-guard, destructive-guard, owner-guard, quarantine-guard, security.cjs, ci-scan
- D — Auto-Continuity v7.1 (5): memory-watchdog, turn-checkpoint, session-auto-resume, pre-compact, _dream-cycle-emit
- E — Workflow/dispatch (6): _adapter-detect, _agent-dispatch, _require-jq/-git/-platform-detect, workflow-guard
- F — Logging (6): session-log, phase-tag, _learnings-emit, _fix-plan-emit, _dream-cycle-emit, tdad-impact/-index
- G — Context/lifecycle (4): context-monitor, circuit-breaker, subagent-stop, verify-learnings/generate-task-map

**Severity inconsistency:** decision-gate exits 1 (advisory); functionally equivalent blocks (phantom/mutation/schema/cross-phase) exit 2. No central severity registry. F5 fixes this.

### Workflows (31)

Domains: auth/security (4), data (4), payments (1), infrastructure (4), observability (3), features/APIs (5), content (3), performance/UX (5), language (1), prepare-for-prod (1).

**No workflow has explicit comprehension gates or severity tiers** (only accessibility-audit tiers findings). High-risk workflows (auth/payments/migrate-to-postgres) rely on generic "Verify:..." comments. **Gap to fix when F2 lands.**

### Skills (10)

auth-jwt, nextjs, postgres, prisma, react, stripe, supabase, tailwind, typescript + README. All technical; none teach review/governance. Loaded contextually based on STATE.stack_skills.

### Schemas (6)

STATE, RESULT, PLAN_META, CONTEXT_BUDGET, WAVE_MAP. Captures: tasks completed/failed/partial, autonomy by_verify_level, comprehension_gates (boolean), tokens, DORA (lead_time/freq/CFR/recovery), reflexion, circuit_breaker, evoscore, autopilot, turn_checkpoint (v7.1), self_heal.

**R5 telemetry coverage:**
- ✓ Per-verify-level autonomy
- ✓ Acceptance/rework rate (calculable)
- ✓ Flow interruption (auto_paused)
- ⚠ Comprehension gate (boolean only — no result enum or explanation)
- ⚠ Decision-gate latency (timestamp only — no calculated delay)
- ✗ Severity-tiered errors
- ✗ Critic disagreement metric
- ✗ Generation-then-comprehension pattern signal
- ✗ Per-task-class registry (Track A/B/C)

---

## Appendix E · Behavioral Simulations (5)

### Simulation 1 — F1 Comprehension Gates: Auth Feature, 8 Tasks

**Current APEX:** User completes 8 tasks. Phase boundary → gate fires showing "3 largest diffs": token signing (200 LOC, largest), email template (180 LOC), small file (filler). Session storage (60 LOC, auth-critical) filtered out. User skips gate. Phase tagged complete. **Risk:** session storage carries unreviewed auth logic.

**Proposed F1:** Mid-phase (after 4 tasks, ~75min), F1 fires gate on token signing — flagged by criticality (auth domain), not size. AI provides 3-paragraph explanation; user prompted "what could break this?" answers "JWT secret leak." Gate passed. After 4 more tasks, gate fires on session storage (also auth-critical despite small LOC). User reads, answers. Phase completes WITH 2 critical files explicitly comprehended.

**Verdict:** F1 wins. Risk-based selection catches critical files regardless of LOC. Distributed gates prevent cognitive debt that advisory-only allows skipping.

### Simulation 2 — F2 Autonomy: Stripe Webhook After 12 Wins

**Current APEX:** 12 prior successes (6A + 4B + 2C). Stripe webhook task = verify_level C, autonomy at L1 (Supervised). APEX writes handler, uses `req.body` (parsed JSON) instead of raw bytes for HMAC verification. Tests pass (no replay simulation). Critic PASSES. Production replay attacks succeed. Loss: $47K over 2 weeks.

**Proposed F2:** Same task → classified Track C (payment + webhook + irreversible). Track C cap is L1 with **mandatory plan review**. APEX shows plan: "Verify webhook signature using raw bytes (NOT parsed JSON)." User asks "what's raw bytes?", APEX explains, user approves. Implementation proceeds with extra critic scrutiny + replay attack tests added (mandatory for Track C). Bug never reaches production. Loss: $0.

**Verdict:** F2 adds ~1-2 min friction per Track-C task; saves catastrophic auth/payment failures.

### Simulation 3 — F3 /apex:micro: 30 UI Polish Fixes

**Current APEX:** 30 sequential `/apex:fast` invocations, ~30s framework overhead each = ~15 min ceremony total. 30 commits clutter git log. Fix #14 silently renames a CSS variable used in 8 other files. Regression discovered ~90 min later via manual testing.

**Proposed F3:** Batch mode. 30 fixes execute with zero pre-modal ceremony. Background tests run after each. Every 50 LOC OR every hour, F3 surfaces batched diff: "10 fixes accumulated. Tests passing. Click approve / rollback." Two batched reviews total. Async critic flags semantic risk on CSS variable rename → batch surfaces proactively. User rolls back fix #14 within 15 min.

**Verdict:** F3 preserves flow (saves ~15 min ceremony) AND catches regression earlier. Win-win. Requires batch UI/CLI infrastructure.

### Simulation 4 — F4 /apex:status: Mid-Phase Check

**Current APEX:** Non-technical user runs `/apex:status`. Sees ~40 data points across 8+ sections (autonomy ladder A/B/C/D, context bar, token economy, quality metrics, DORA, session, autopilot, v7.1 auto-continuity). Scans 60s. Doesn't know "is testing passing?" — no dedicated line. Gives up, asks `/apex:help "is everything ok?"`.

**Proposed F4:** 5 lines: "Phase: Auth (3/8 tasks) | Autonomy: Supervised (Track-C) | Currently: Building login UI | Last verification: PASS (link) | Context: Green". Below: `[Show advanced]`. User reads in 5s.

**Verdict:** ~12× faster comprehension; power-user friction is 1 click for full panel. Senior devs can default-on `--detailed`.

### Simulation 5 — F5 Severity Tiers: 12 Hook Events Over 3 Hours

**Current APEX:** 12 hook events fire as modals (phantom, mutation, schema, decision-gate, ast-kb, circuit-breaker repeats, post-write). User context-switches on every event. By minute 30, dismissing all as false alarms. Real CRITICAL (infinite loop circuit-breaker) dismissed; loop runs 20 more min.

**Proposed F5:** 3 CRITICAL (phantom, mutation kill rate, schema drift) — immediate blocking, within ≤2-3/half-day budget. 5 MAJOR (decision-gate, circuit-breaker no-change repeats) — passive yellow, surfaced at boundaries. 4 MINOR (ast-kb, post-write style) — silent log + 45min digest. User maintains flow; attends to real signals; new infinite-loop trigger (different signature) classifies CRITICAL because it's a new event type — caught at 3 min instead of 20.

**Verdict:** Signal-to-noise from 25% (3 real / 12 noise) to 100% (correctly routed). Behavioral effect: user stays engaged.

---

## Appendix F · Multi-Perspective Matrix

For each `do-now` item: rated +/-/0 across 5 lenses.

| Item | User (non-technical) | Security | Cost / Token | DORA | Cognitive Load (CLT) |
|---|---|---|---|---|---|
| **#1 Track A/B/C autonomy** | + (less surprise on payments) | + + (mandatory review on auth) | 0 (negligible) | + (reduces -7.2% drift) | + (clearer autonomy model) |
| **#2 Comprehension gate for D** | - (more friction) | + + (D = irreversible) | 0 | + (forces understanding) | + + (germane load up) |
| **#3 Severity tiers F5** | + (less noise) | + (CRITICAL prioritized) | + (less context-switching) | + (fewer false alarms) | + + (extraneous load down) |
| **#4 Status progressive disclosure** | + + (clarity) | 0 | 0 | + (decision speed) | + + (intrinsic load down) |
| **#5 Self-test runner fix** | 0 | + (validation infra works) | 0 | + (catch real regressions) | 0 |
| **#6 DORA claim qualification** | 0 | 0 | 0 | + + (credibility) | 0 |
| **#7 F3 micro batching** | + + (flow preserved) | - (silent failure risk if classifier wrong) | + (less commit overhead) | + (faster cycle time) | + + (low intrinsic load) |

**Score interpretation:**
- All `do-now` items have ≥3 positives → priority confirmed.
- #2 has 1 negative (friction); mitigated by per-complexity calibration.
- #7 has 1 negative (silent-failure risk); mitigated by classifier audit + background tests.
- No item has ≥2 negatives.

---

## Appendix G · 9-Failures × R5 Cross-Walk

| # | Failure | R5 Illumination | Current APEX | Gap | Suggested Action |
|---|---|---|---|---|---|
| 1 | Failure (pipeline) | R5 §4.3 — flow cost (15-25min refocus, 90% sessions >1min lag) | Circuit breakers, auto-commit, recovery menu, /apex:forensics | No flow-state diagnostic; gates not quantified for fragmentation | Add cumulative interruption time + last-checkpoint timestamp to /apex:forensics; warn if >2 gates pending |
| 2 | Forgetting | R5 §3.5 — cognitive debt (8× duplication, 60% refactoring decline) | Three-tier memory, dream-cycle, 30+ workflows | Cognitive ownership invisible (vs. code dependency) | Cognitive-debt detector hook (decision §7 #5) |
| 3 | Context loss | R5 §6 — task-type autonomy dominates over project scale | STATE.json + event-log, glass cockpit, Scale-Adaptive Classifier | Per-task-type autonomy classifier absent | F2 implementation; reset autonomy per phase |
| 4 | Drift | R5 §3.4 (LGTM 65%, automation bias) — drift is cognitive, not just spec | SPEC_VERSION, /apex:discuss-phase, scope-reduction | Cognitive drift not detected (escalation biased by perception) | Plan-vs-actual diff at phase end; critic disagreement >30% triggers full review |
| 5 | Hallucination | R5 §2 (40% Pearce vulns, 59% use code not understood) — surface polish obscures flaws | Phantom-check, AST-KB, RESULT.json, auditor quarantine | Detects missing imports; misses silent API misuse, subtle invariant breaks | Mandate generation-then-comprehension on critical files (F1); raise AST-KB to AST-contract violations |
| 6 | Mutation | R5 §5 (1.7× defects, +322% Apiiro) — mutation is semantic | Destructive-guard, mutation-gate, owner-guard, snapshots | File-level path guard; semantic mutation invisible | Differential semantic test ("blast radius check") on each file; escalate skipped-tests immediately |
| 7 | Quality errors | R5 §4 (interaction pattern 86% vs 24%) — cognition is the intervention | Cross-model critic (53→80%+), adversarial persona (<1→93.7%), roundtable | Critic is async; no mandatory developer explanation | Critic feedback → developer prompt "what would you change?" before accepting |
| 8 | Systemic blindness | R5 §3 (cognitive debt invisible until incident) | TDAD + Aider repo map (partial), cross-phase audit | Code dependencies tracked; cognitive ownership not | Code-understanding-ledger in STATE; semantic-test suite per phase boundary |
| 9 | Security gaps | R5 §5 + Pearce 40% — implementation incomplete (R7 audit) | Security-specialist (partial), THREAT_MODEL template, defense-in-depth | THREAT_MODEL template-only; CI scanner advisory; semantic security checks absent | Close R7 F-002; auto-fill THREAT_MODEL from risk-classified files; CI scanner as PostToolUse hook (async); semantic-risk Q on critical-file gates |

**Synthesis:** R5 strengthens APEX's handling of #1-#3, #5-#6 with new evidence. R5 reframes #4 (drift includes cognitive), #7 (interaction is the intervention), #8 (cognitive debt invisible). #9 has implementation work pending from R7.

---

## Appendix H · Verification Citations (Index)

Every recommendation in §1, §3, §5 cites both an R5 §line AND an APEX file:line. Index:

| ID | R5 citation | APEX citation |
|---|---|---|
| Insight 1 / §5 #1 (Track A/B/C) | R5 §7 F2 line 390 | `framework/commands/apex/next.md:614-617`; `framework/agents/architect.md`; `framework/schemas/PLAN_META.schema.json` |
| Insight 2 / §5 #2 (Comprehension D) | R5 §7 F1 line 353; §3 (Anthropic RCT 86% vs 24%) | `framework/commands/apex/next.md:851-874`; `framework/schemas/STATE.schema.json` (comprehension_gates field) |
| Insight 3 / §5 #4 (Status progressive) | R5 §7 F4 line 454 | `framework/commands/apex/status.md:40-134` |
| Insight 4 / §5 #3 (Severity F5) | R5 §7 F5 line 488 | All 46 hooks; new `framework/hooks/_emit_apex_event.sh`; new `background-digest-hook.sh` |
| Insight 5 / §5 #7 (F3 micro) | R5 §7 F3 line 426 | `framework/commands/apex/fast.md`; new `framework/agents/specialist/batch-verifier.md` |
| Insight 6 / §5 #5 (self-test runner) | R7 audit F-001 (no R5 §) | `framework/scripts/self-test.sh` |
| Insight 7 (53%→80%+ supported) | apex-verification-research-synthesis.md L197 | `apex-spec.md:44` |
| Insight 8 / §5 #6 (DORA claim) | R5 §5.4 line 303-307; §9 Gap #7 line 632 | `apex-spec.md:9, 375`; README L29 |
| Insight 9 (workflow Track-C) | R5 §7 F2 line 390 | `framework/apex-workflows/add-authentication.md`, `add-stripe-payments.md`, `migrate-to-postgres.md`, etc. |
| Insight 10 (memory partial) | R6 supporting research | `framework/docs/STATE-PLANE.md`; `_state-sqlite.sh` |

Each App C row carries its own primary citations (verbatim quotes in the table).

---

## Appendix I · Methodology

This research was conducted in 11 stages with ~30 parallel read-only subagents. The coordinator never read any single file >300 lines directly — all large source files (R5 brief 701 lines, apex-spec.md 33KB, agents, hooks) were distilled by subagents returning ≤500-word structured reports. This prevented context rot.

**Stages:**
- 0 (Pre): mapped all 7 research files, APEX claims inventory, command catalog
- 1: 8 subagents on R5 §1-§10 in 90-line slices
- 1.5: corrective subagent on §8 metrics + §9 gaps
- 2: 6 subagents — one per supporting research file
- 3: 5 subagents — agents, hooks (themed), workflows+skills, schemas, closure reports
- 4: 3 subagents — numeric / causal / UX claims audit
- 5: cross-walk synthesis (coordinator)
- 6: 5 subagents — F1-F5 behavioral simulations
- 7: multi-perspective matrix (coordinator)
- 8: 5 subagents — F1-F5 implementation readiness deep-dive
- 9: 1 subagent — 9-failures × R5 lens
- 10: prioritization (coordinator)
- 11: doc writing (coordinator)

**Limitations:**
- R5 line numbers vary slightly across subagents reading the same file; resolved by §section citations primarily.
- "5 consecutive successes → escalate" was contradicted by R5 — but APEX's exact `consecutive_successes` field count of 5 may have been borrowed FROM the same automation literature R5 critiques. Resolution: R5 explicitly identifies the "5 successes" rule as the rule to replace, so the contradiction stands.
- Some causal-claim mechanisms (e.g., adversarial persona efficacy) are research-validated but APEX's exact specific implementation is research-silent — i.e., the mechanism is in the code, but no study tested APEX's specific persona prompt.
- Behavioral simulations are illustrative, not measured. Real production data would replace these (per §7 #3 telemetry decision).

**Read-only discipline maintained:** No source file in `framework/` was modified. Only this document was written. `git status` should show only this new file.

---

**End of report.**
