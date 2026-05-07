# APEX — הגדרה

## מה זה APEX (במשפט)

APEX הוא **multi-agent framework ופלטפורמה לסוכני קוד** (Claude Code, Cursor, OpenClaw, Codex, Copilot, Gemini, Windsurf, Antigravity דרך thin adapters) שהופך אותם ממסייעי-קוד session-by-session למערכת **engineering autonomous, stateful, falsifiable, cost-aware, multi-platform, scope-honest, honestly-heavy, injection-hardened, dual-mode, scale-adaptive, ו-non-technical-first** — היחידה בקטגוריה שמתוכננת מראש **לאוכלוסיית הלא-מתכנתים** (לא למפתחים), **בתחום מוצהר וברור** (TypeScript/Python/Go עם git ו-test framework), שפועלת **כ-collaborator בהחלטות מוצר (שם המשתמש הוא המומחה) וכ-replacement בהחלטות טכניות (שם הוא לא)**, כדי להחזיק פרויקט תוכנה שלם מההתחלה ועד הסוף, **בלי לשבור את עצמה, בלי לשרוף תקציב, בלי לדרוש ידע טכני, בלי להיות נעולה לפלטפורמה אחת, בלי להבטיח יותר ממה שהיא מקיימת, בלי שמשתמש זדוני יוכל להחדיר הוראות דרך הקבצים שלה, בלי להחמיר את delivery stability, ובלי להיות tool סגור אלא platform פתוחה שקהילה יכולה להרחיב.** הוא **גשר מעל חסם הידע והשפה** עבור אנשים שאינם מפתחים, **חינמי לעד בליבה** (enterprise services paid, core free forever — trust-first).

## מה APEX צריך לדעת לעשות

למנוע 9 כשלים מובחנים שהורגים פרויקטי AI היום, בעלות נמוכה ב-70-90%, בחוויית שימוש שמשתמש לא-טכני יכול להצליח איתה בסשן ובשעה הראשונה, במדדי DORA שמשתפרים, עם proof-of-process פומבי וחי, **ועם Scale-Adaptive Classifier שמאבחן את הפרויקט אוטומטית ומתאים את עצמו** — מ-bug fixes קטנים ועד enterprise systems.

---

## תשעת הכשלים — הרחבה מלאה

### 1. Failure (כשל פייפליין)
**מה זה:** Pipeline נשבר, אובדים שעות. **הסימן הקליני:** המשתמש לא סומך על המערכת לכל דבר ארוך מ-30 דקות.
**למה זה קורה:** אין circuit breakers, snapshots, recovery menu, state פרסיסטנטי. גם — המשתמש שנכנס למצב debug-the-framework מאבד אמון מיידית.
**איך APEX מטפל:** Circuit breakers, **auto-commit ל-hidden git tree** עם one-click rollback, pre-task snapshots, recovery menu. **State derives from disk**. **Standalone debugging discipline** דרך `__main__.py`. **`/apex:forensics`**. **`/apex:help [שאלה חופשית]`** (חידוש מ-BMAD) — context-aware conversational navigator בשפה טבעית. דוגמאות: "I'm stuck" → `/apex:forensics` + הסבר, "How do I undo this?" → `/apex:rollback` + contextual explanation, "The AI got it wrong" → `/apex:walkthrough`. זה סוגר את **framework vocabulary gap** — משתמש לא-טכני אף פעם לא צריך לזכור שמות של commands.

### 2. Forgetting (שכחה לאורך זמן)
**מה זה:** קונטקסט חשוב נעלם.
**למה זה קורה:** חלון קונטקסט סופי.
**איך APEX מטפל:** ארכיטקטורת זיכרון תלת-שכבתית עם **Memory Synthesis dream-cycle agent**. **PROJECT-APEX.md** (Two-Tier Methodology). ארבעה primitives: `apex/todos/`, `apex/threads/`, `apex/seeds/`, `apex/backlog/`. **`apex-workflows/` כ-library of pre-built recipes** (חידוש מ-BMAD): 30+ מתכונים מוכנים (add-authentication, migrate-to-postgres, prepare-for-production, accessibility-audit). workflow הוא מתכון ידוע עם pre-conditions ו-post-conditions, הרצתו מייצרת phases אוטומטית. זה גם **זיכרון ארגוני** — כל פעם שAPEX מצליח workflow חדש, הוא יכול להציע אותו כ-template ל-projects אחרים.

### 3. Context loss (אובדן הקשר בין session-ים ובתוכם)
**מה זה:** הסוכן לא יודע איפה הוא נמצא.
**למה זה קורה:** אין observable state. U-shaped attention.
**איך APEX מטפל:** STATE.json + event-log.jsonl control plane (git-diff-able, jq-queryable). Glass cockpit עם 3-5 פריטי decision-required עליונה. Context ordering לפי U-shape. Aider-style repo map. **`/apex:list`**, **`/apex:onboard`**. **`/apex:resume-work`** ו-**`/apex:pause-work`** עם structured handoff. **`/apex:session-report`**. **Scale-Adaptive Classifier ב-onboarding** (חידוש מ-BMAD): APEX מסיק scale אוטומטית על בסיס גודל קוד, נוכחות tests, CI/CD, production deployment, team size, ומתאים את ההגדרות. המשתמש יכול לעקוף, אבל ברירת המחדל מתאימה את עצמה. זה מוריד decision burden מהמשתמש הלא-טכני — במקום שיבחר preset, ה-system מנחש נכון ומציג.

### 4. Drift (סטייה מהתוכנית)
**מה זה:** הוחלט X. הסוכן עושה Y. גם — drift סגנוני.
**איך APEX מטפל:** `SPEC_VERSION` hash + `SPEC_DELTA.json`. **Spec-to-verification ledger ב-Layer 0**. **Iterative decomposition עם `originating_requirement_id`**. **`/apex:build` ו-`/apex:refine` כ-pipelines נפרדים**. **Phase-Gating doctrine**. **`/apex:discuss-phase` עם gray-area classifier**. **Scope-reduction detector**. **`/apex:ui-phase` עם 6-pillar Design Contract + Domain-specific contract templates**.

### 5. Hallucination (הזיה ו-fake reporting)
**מה זה:** הסוכן מדווח שעשה משהו שלא עשה. USENIX: 19.7% imports לא קיימים. Automation Bias: 26% יותר עקיבה אחרי עצות שגויות.
**איך APEX מטפל:** Phantom-check, AST-KB Hallucination Gate. RESULT.json עם `verified_criteria[]`/`unverified_criteria[]`. Content-level verification. Color discipline. Total elapsed time. End-to-end smoke test. **`APEX_STRICT_MODE=1`**. **Schema-drift hook**. **Nyquist Validation Layer** עם Wave 0 enforcement. **Auditor agent שלעולם לא נוגע ב-implementation code** — רק test files. **`apex-test-architect` כ-module נפרד עם זכות veto** (חידוש מ-BMAD's TEA): test architecture היא discipline נפרדת, לא תת-משימה של execution. ה-test architect רץ **לפני** ה-executor: מנתח risk profile של הפרויקט, מגדיר test pyramid לפי risk, ממפה coverage מינימלית לכל risk level, מציע mutation testing strategy, מגדיר property-based test candidates, ו**יש לו זכות veto על phase completion** אם ה-test architecture לא עומדת. זה לא עוד hook — זה role ארגוני נפרד בתוך APEX.

### 6. Mutation (שינויים לא רצויים)
**מה זה:** drop של table, force push, מחיקת קונפיג. Skipped tests בשקט.
**איך APEX מטפל:** Destructive-guard hook, pre-task snapshot, mutation-gate. One-file-one-owner עם git worktree isolation. **Read-parallel, write-serial עם Vertical Slices Enforcement**. **Skipped-test regression detection**. **`/apex:new-workspace`** — שתי רמות של בידוד (workstreams + workspaces).

### 7. Quality errors (איכות נמוכה)
**מה זה:** הקוד עובד אבל לא טוב.
**איך APEX מטפל:** **Cross-model critic** (53% → 80%+). **Adversarial persona מקובע** (<1% → 93.7%). **Mutation testing**. **Property-based testing סלקטיבי**. Critic מוגבל ל-PASS/FAIL/NEEDS_REVIEW. **Anti-rationalization injection**. **Roles must produce typed artifacts**. **`/apex:peer-review`**. **`/apex:roundtable`** (חידוש מ-BMAD's Party Mode): ל-החלטות ארכיטקטוניות רב-פנים, APEX מכנס multi-specialist collaborative session שבה security, performance, cost, UX, ו-data specialists מציגים זוויות שונות על אותה החלטה באותו session. זה שונה מ-debate (שחותר להסכמה) ומ-cross-model critic (שחותר לשלילה). **Roundtable חותר לעומק** — כולם מציגים, architect מחליט. מתאים ל-tech stack choices, trade-off decisions, בחירות ארכיטקטוניות. **לא** מתאים ל-tasks רגילים — זה overhead. **Dual-mode philosophy** (חידוש מ-BMAD): APEX מזהה "אזורים שהמשתמש הוא המומחה" (product decisions, UX flows, business rules) ו-"אזורים שהוא לא" (code architecture, security patterns, performance). ב-product decisions, APEX פועל כ-**collaborator** — מציג אפשרויות, מעודד חשיבה, לא מחליט בעצמו. ב-technical decisions, APEX פועל כ-**replacement** — מחליט ומבצע, מחזיר למשתמש רק את ה-trade-offs שהוא צריך לאשר.

### 8. Systemic blindness (עיוורון מערכתי)
**מה זה:** מתקן רכיב אחד ושובר 12 callers בשקט.
**איך APEX מטפל:** **שילוב כפול**: TDAD + Aider-style repo map. Cross-phase-audit. **Differential semantic testing**. **End-to-end smoke test**. **Structural contract למבנה phase**.

### 9. Security gaps (חורי אבטחה)
**מה זה:** Veracode: 45% נכשל. **Indirect Prompt Injection דרך planning artifacts**.
**איך APEX מטפל:** Security-specialist יסודי. **Negative authorization tests כ-blocking**. ML entropy secret scanning. AST-KB validation. Risk classification ב-Layer 0. Java risk multiplier. **Jagged Frontier classifier**. **`THREAT_MODEL.md` per-project** עם Indirect Prompt Injection כאיום ברירת מחדל. **Defense-in-Depth Security Layer**: `apex-prompt-guard.js`, Path Traversal Prevention, `apex-workflow-guard.js`, CI scanner, `security.cjs` module.

---

## היכולות הנדרשות

**Multi-agent orchestration עם hub-and-spoke מהודק.** Manager final-authority. Blind-first debate. Read-parallel, write-serial. Vertical slice enforcement. **Roundtable mode** ל-decisions רב-פנים.

**Dual-mode operation.** Collaborator mode ל-product decisions, Replacement mode ל-technical decisions. ה-classifier קובע בכל החלטה באיזה mode לפעול.

**Three-tier ceremony pyramid.** `/apex:fast` / `/apex:quick` / `/apex:full`.

**Scale-Adaptive Classifier ב-onboarding.** Auto-detection של complexity, לא preset בחירה ידנית. המשתמש יכול לעקוף.

**Pipeline commands מלאות.** `/apex:onboard`, `/apex:start`, `/apex:discuss-phase`, `/apex:ui-phase`, `/apex:plan-phase`, `/apex:execute-phase`, `/apex:roundtable`, `/apex:walkthrough`, `/apex:ship`, `/apex:next`, `/apex:fast/quick/full`, `/apex:refine`, `/apex:test`, `/apex:validate-phase`, `/apex:peer-review`, `/apex:ui-review`, `/apex:list`, `/apex:status`, `/apex:health-check`, `/apex:pause-work`, `/apex:resume-work`, `/apex:session-report`, `/apex:rollback`, `/apex:forensics`, `/apex:milestone-summary`, `/apex:new-workspace`, `/apex:thread`, `/apex:plant-seed`, `/apex:add-backlog`, `/apex:review-backlog`, **`/apex:help [natural language]`** (חידוש מ-BMAD), **`/apex:workflow [recipe-name]`** (חידוש מ-BMAD), **`/apex:new-agent`** (חידוש מ-BMAD's Builder), **`/apex:self-heal`** (framework gap-closure loop).

**APEX.md + PROJECT-APEX.md (Two-Tier Methodology).**

**Module Ecosystem כ-Extension Model** (חידוש מ-BMAD). במקום plugin registry יחיד, APEX מפורק ל-repositories נפרדים עם lifecycles עצמאיים:
- **`apex-core`** — ליבה (free forever)
- **`apex-frontend`** — UI design contracts, 6-pillar audit, shadcn gate
- **`apex-data`** — data pipeline contracts, schema evolution
- **`apex-security`** — threat modeling, defense-in-depth
- **`apex-test-architect`** — TEA equivalent עם veto power
- **`apex-fintech`** — PCI DSS, SOC2 compliance (enterprise)
- **`apex-healthcare`** — HIPAA compliance (enterprise)
- **`apex-builder`** — meta-framework ליצירת agents מותאמים

כל module repo נפרד, issues נפרדים, versioning נפרד. זה מאפשר growth אינקרמנטלי בלי שהליבה תתפח.

**State management היברידי.** Markdown + JSONL + jq (with SQLite+FTS5 as future migration path when query needs exceed jq — zero binary dependencies today, git-diff-able proof-of-process).

**Hook system** — 24+ hooks כולל prompt-guard ו-workflow-guard.

**Nyquist Validation Layer + `apex-test-architect` module.** Test infrastructure mapping לפני קוד, Wave 0, Auditor agent שלא נוגע ב-implementation, **זכות veto על phase completion**.

**Domain-specific contracts.**

**Context engineering ברמת state-of-the-art.** Aider-style repo map, U-shaped ordering, observation masking, ≤5% startup overhead.

**Cost-aware execution עם 4 model profiles + inherit mode.**

**Granularity כ-config first-class** (trivial/coarse/standard/fine) אבל **מוסק אוטומטית ע"י Scale-Adaptive Classifier**.

**Speed-vs-Quality Presets**: "Trying it out" / "Building something real" / "Going to production" / "My business depends on this". **ברירת המחדל נבחרת אוטומטית ע"י Classifier.**

**Schemas כחוזה אכיף.** RESULT.json עם כל השדות.

**Verification stack עשר-שכבתי.**

**APEX-SKILL.md generation. APEXSkin. Structural contract. APEX_STRICT_MODE. Living Evidence Counter. Conventional commits. Public proof-of-process.**

**`apex-workflows/` library** — 30+ מתכונים מוכנים ל-tasks נפוצים. משתמש לא-טכני בוחר מ-menu במקום לתאר מה הוא רוצה.

**Party Mode / Roundtable** לדיוני specialists משותפים ב-decisions רב-פנים.

**UX לקהל לא-טכני.** First-session usability + first-hour guarantee. **`PROPOSALS_MODE`**. **`/apex:walkthrough`** עם automatic fix-plan generation. Decision gates פר 60-90 דקות. Glass cockpit כפילטר. Color discipline. Total elapsed time. One-click rollback. Predictability over capability. "When NOT to use APEX" first-class. **Auto-selected presets**. **Natural language help**.

**DORA self-monitoring.**

**Cross-model critic** חובה. **Cross-AI peer review** אופציונלי.

**Autonomy ladder אסימטרי per-task-class.**

**Multi-platform from day one**.

**Honest scope statement.**

**Defense-in-Depth security.**

**Framework → Platform** (חידוש מ-BMAD). APEX אינו tool סגור — הוא platform פתוחה. **`/apex:new-agent`** מאפשר למשתמשים מתקדמים ליצור specialists מותאמים (legal-compliance-specialist, GDPR-specialist, HIPAA-specialist, fintech-specialist). כל אחד שמבין את הדומיין שלו יכול ליצור agent שלא קיים ב-core. זה ההבדל הקטגורי בין tool ל-platform: tool = מה שאני נותן, platform = מה שמשתמשים יוצרים עליה.

**Monetization decision**: **Core Free Forever, Enterprise Services Paid**. הליבה המלאה חינמית לנצח בלי gating. Monetization דרך: hosted verification service, enterprise support contracts, specialized modules (fintech/healthcare), custom specialist development, hosted training. **לא** דרך: subscription ל-core, token, gated features, gated Discord, gated docs. Trust-first monetization.

## עקרונות העבודה

**Fail-loud, never fail-silent.**

**Trust but verify at filesystem level — ועד רמת content, schema sync, ו-prompt injection.**

**Honest uncertainty over false completeness.**

**Phase-Gating doctrine: analyze before implement.**

**Clean-room critic, cross-model, adversarial persona.**

**Verification universal, not TDD universal. Test architecture is its own discipline with veto power.**

**Less context, better chosen.**

**Cost-awareness כעקרון, לא תוסף.**

**Information boundaries ARE the architecture.**

**Isolation almost always beats communication.**

**Read-parallel, write-serial. Vertical slices, never horizontal layers.**

**Manager decides, doesn't negotiate. But specialists roundtable when decisions are multi-faceted.**

**Adaptive ceremony, never one-size-fits-all. Three tiers. Scale-adaptive classifier picks the default.**

**Dual-mode operation: collaborator where the user is the expert, replacement where they're not.** אסור לאחד צד מוחלט.

**Build, refine, and onboard are different pipelines.**

**Methodology lives in two files.**

**Structural contract over flexibility.**

**Standalone debuggability.**

**Strict mode before commitment.**

**Style decisions locked before research starts.**

**Propose, don't ask.**

**Failure produces a fix plan, never a 'go debug it'.**

**Memory has retrospective, prospective, parking-lot, AND recipe layers.** dream cycle (past), seeds (future), backlog (deferred), workflows (proven patterns for reuse).

**Tests live in their own quarantine.** Auditor never touches implementation. **Test architecture is a separate discipline with veto rights.**

**Progressive autonomy, asymmetric, with hard caps.**

**Recovery before destruction.**

**Schema as contract. Schema sync as contract.**

**Scope reduction is a bug.**

**First-hour, first-session usability is non-negotiable.**

**Predictability over capability.**

**Filter, don't flood.**

**Direct the freed time.**

**U-shaped attention awareness.**

**Memory integrity by provenance, not detection.**

**Roles must produce typed artifacts.**

**Multi-platform from day one.**

**Honest scope over marketing scope.**

**Transparency of limitations builds more trust than promises.**

**Proof-of-process beats proof-of-promise.**

**Everything APEX produces should itself be agent-native.**

**APEX must be transparent to itself.**

**Threat models are project-specific, not generic.**

**The framework is honestly heavy because the problem is honestly hard.**

**Every file APEX writes is a potential prompt for the next session.**

**User-facing complexity is a 4-button menu, not a 14-toggle dashboard.** And the button is auto-selected by Scale-Adaptive Classifier.

**Natural language help, not command memorization.** Framework vocabulary gap is real and must be closed.

**Tool vs. Platform is a strategic choice — APEX chooses Platform.** Users must be able to create specialists we didn't anticipate.

**Free forever at the core, paid at the enterprise edge.** Trust is not monetizable.

**The user is the expert in some domains, not in others. Respect the difference.**

## Self-Healing Loop

APEX maintains itself via `/apex:self-heal` — a framework gap-closure
pipeline anchored on this spec file. Each round runs five sequential
agents transcribed from the user-validated 6-instruction protocol:

1. **`framework-auditor`** — performs a 12-axis audit against this
   spec, producing `apex-audit-findings-R<N>.md` at repo root with
   F-NNN findings classified P0–P3, status CONFIRMED/SUSPECTED, and
   spec-anchor citations. The agent's only measuring stick is this
   spec; nothing else.
2. **`remediation-planner`** — converts every finding into a typed
   R-item via the 10-question ecosystem analysis, producing
   `REMEDIATION-PLAN-R<N>.md`. Authored under
   `framework/docs/REMEDIATION-STYLE.md` (content-addressable anchors
   only, no raw line numbers in plan body, three-places contract for
   hook trigger changes, sync-strategy review for any new
   `framework/*` file).
3. **`batch-scheduler`** — groups R-items into independent waves
   (5–8 per wave; P0 high-blast-radius alone), producing
   `WAVES-R<N>.md` with verification gates and abort conditions.
4. **`wave-executor`** — executes one wave per invocation. Strict
   scope discipline: do-not-touch zones honored, abort-on-fail with
   full-wave revert, conventional commits per R-item, new findings
   discovered mid-wave go to `NEW-FINDINGS-W<X>.md` (never to new
   fixes). Reads-only inputs include this spec, the audit findings,
   and the remediation plan.
5. **`round-checker`** — closes the round via convergence analysis,
   producing `ROUND-R<N>-CLOSURE.md`. Reports trajectory
   (IMPROVING / STAGNANT / DIVERGING). The loop terminates when two
   consecutive rounds produce 0 P0/P1 findings and no open NEW-FINDINGS
   of P0/P1 severity remain. Safety cap: `--max-rounds N` (default 10).
   Divergence (P0+P1 growing by >2 between rounds) halts and escalates.

All round artifacts live at repo root and follow the .gitignore patterns
already established (`apex-audit-findings-*.md`, `REMEDIATION-PLAN-*.md`,
`WAVES-R*.md`, `WAVE-*-RESULT.md`, `NEW-FINDINGS-*.md`,
`ROUND-R*-CLOSURE.md`). Round state is tracked in `STATE.self_heal`
(optional schema field initialized lazily on first invocation).

The five agents live in `framework/agents/specialist/`. They are
pipeline workers, not domain specialists — each transcribes one
user-validated instruction into the APEX agent template. The
`framework-auditor` is distinct from the existing test-only `auditor`
agent (which retains its filesystem quarantine to test files).

## Auto-Continuity Layer (v7.1)

APEX is designed to run autonomously for days. The Auto-Continuity Layer
closes the last gap that prevented this: **runtime crashes** (most commonly
Bun OOM after many hours of accumulated process memory) used to require
manual user intervention to restart and resume. Auto-Continuity makes the
recovery automatic — the user sees "session ended, new session resumed
on its own" rather than "crash, lost work, restart manually".

The layer is **purely additive** — pause/resume/recover commands continue
to work manually. Every component fails-soft and is independently optional:
the system degrades gracefully if any one part is missing.

### Four-layer architecture

| Layer | Component | Trigger | What it does |
|-------|-----------|---------|--------------|
| **A** | `session-auto-resume.sh` (SessionStart hook) | Fresh Claude Code session starts | If `STATE.session.auto_paused == true` or fresh `TURN_CHECKPOINT.json` exists, write `.apex/SESSION_BOOT.md` banner and emit instruction-to-stdout that Claude reads in initial context, prompting `/apex:resume` |
| **B** | `turn-checkpoint.sh` (PostToolUse:Bash hook) | Every N tool calls inside a task (default 5) | Atomically writes `.apex/TURN_CHECKPOINT.json` mirroring `STATE.turn_checkpoint`, enabling `/apex:recover` option 6 (continue-from-turn-checkpoint). Coarser than per-call, finer than per-task. |
| **C** | `memory-watchdog.sh` (PostToolUse:Bash hook) | Every PostToolUse, throttled to a sample interval (default 30s) | Samples Bun process commit memory (`PrivateMemorySize64` on Windows, `VmSize` on Linux, `RSS` on macOS). After N consecutive samples over threshold (default 3 over 2048MB), creates `.apex/AUTO_PAUSE_REQUEST.flag`. `/apex:next` Step F.4 consumes the flag and runs `/apex:pause` cleanly. |
| **D** | `apex-watchdog.ps1` (Windows external process) | Optional — installed via `install-watchdog.ps1` as a Scheduled Task | Monitors Claude Code from outside the runtime. Survives Bun OOM. Writes `.apex/SHUTDOWN_REQUEST.flag` on threshold trip; force-kills after grace period; auto-respawns Claude Code in the project directory after exit. |

### Lifecycle

```
running session
    │
    │  (memory grows)
    ▼
memory-watchdog samples each 30s ─── threshold tripped 3x ──┐
                                                            ▼
                                       .apex/AUTO_PAUSE_REQUEST.flag
                                                            │
                                              /apex:next Step F.4 reads it
                                                            │
                                                   runs /apex:pause
                                                            │
                                              session.auto_paused = true
                                                            │
                                                       SESSION END
                                                            │
                                                  (Claude Code respawns,
                                                   either by user or by
                                                   external watchdog)
                                                            │
                                                       SESSION START
                                                            │
                              session-auto-resume hook reads STATE.session
                                                            │
                                  detects auto_paused -> writes SESSION_BOOT.md
                                                            │
                                       Claude reads SESSION_BOOT, runs /apex:resume
                                                            │
                                              session.auto_paused = false
                                                            │
                                                  back to running session
```

The cycle is observable end-to-end through `event-log.jsonl`:
`memory_sample` × N → `auto_pause_requested` → `auto_paused` → (session
boundary) → `session_auto_resumed`.

### Configuration (CONTEXT_BUDGET.json `auto_continuity` block)

| Field | Default | Purpose |
|-------|---------|---------|
| `bun_memory_threshold_mb` | 2048 | OOM-relevant threshold (commit, not RSS) |
| `bun_memory_warn_pct` | 70 | Warn-level percent of threshold (banner only) |
| `bun_memory_debounce_samples` | 3 | Consecutive samples over threshold before flag |
| `memory_sample_interval_seconds` | 30 | Throttle for sampling on PostToolUse |
| `turn_checkpoint_interval` | 5 | Checkpoint every N tool calls |
| `turn_checkpoint_freshness_minutes` | 30 | `/apex:resume` shows checkpoint if newer than this |
| `session_auto_resume` | true | Master toggle for SessionStart auto-resume banner |
| `decision_gate_default_action_minutes` | 10 | Reserved for future use |
| `max_consecutive_auto_pauses` | 3 | Breaker — halt after this many in a row |
| `auto_pause_cooldown_minutes` | 10 | Window for the breaker |

### Forensics & breakers

- All sampling and pause-request events are logged to `.apex/event-log.jsonl`.
- High-water mark of memory is preserved in `STATE.session.memory.high_water_mark_mb`
  across the session (resets on `/apex:resume`).
- An auto-resume loop breaker (`session.auto_resume_attempts`) prevents infinite
  pause-resume cycles — after `max_consecutive_auto_pauses` within
  `auto_pause_cooldown_minutes`, the system halts and surfaces a manual prompt.

### Out of scope (deferred)

- macOS / Linux external watchdog parity (Layer D is Windows-only for now)
- Multi-project parallel watchdog (one project per scheduled task)
- Cloud-resident state (everything stays local)
- Mid-tool-call atomic recovery (turn-checkpoint is the granularity contract;
  per-call recovery is intentionally not pursued)

## המיתוג שמייצר את הפער הקטגורי

APEX מגדיר קטגוריה דרך שתים-עשרה עמדות:

1. **"Stateful and Falsifiable", לא "More Agentic"**
2. **"First-Time Correctness over Speed"**
3. **"Verification Universal, Not TDD Universal"**
4. **"70% Cheaper at 98% Quality"**
5. **"Built for People Who Don't Read Code"**
6. **"The First Framework That Improves DORA"**
7. **"Multi-Platform, Open, and Provable"**
8. **"Honestly Scoped, Not Universally Promised"**
9. **"Honestly Heavy, Not Falsely Light"**
10. **"The First Framework Hardened Against Its Own Files"**
11. **"Dual-Mode: Collaborator AND Replacement"** — לא אחד מוחלט. לקהל לא-טכני, APEX מחליף את החלטות הקוד שהוא לא יכול לקבל, ומשתף פעולה עם החלטות המוצר שרק הוא יכול לקבל. אף competitor לא מכיר בהבחנה הזו.
12. **"Platform, Not Tool. Free Forever at the Core."** — מודל ה-core free של BMAD עם monetization באזור ה-enterprise. ה-ecosystem של APEX ניתן להרחבה ע"י הקהילה דרך `/apex:new-agent`, ו-apex-core לא ננעל מאחורי paywall לעולם. זו עמדה שאי אפשר להעתיק בלי לסתור monetization model קיים.

## במהות

APEX אינו רק כלי שעוזר לכתוב קוד. הוא **מערכת engineering autonomous שמחזיקה את עצמה ישרה** לאורך פרויקט שלם, **בתחום מוצהר וברור**, **לקהל מוצהר וברור** (לא-מתכנתים), **בשני modes מותאמים** (collaborator בהחלטות מוצר, replacement בהחלטות טכניות), **ב-scale שמותאם אוטומטית** ממהלך bug fix של חמש דקות ועד enterprise system של חודשים, דרך 9 שכבות הגנה כנגד 9 כשלים מובחנים, בעלות נמוכה ב-70-90%, **בחוויית שימוש שמשתמש לא-טכני יכול להצליח איתה בסשן ובשעה הראשונה**, **שלא דורשת ממנו לענות על שאלות פתוחות אלא רק לבחור בין הצעות**, **שלא מאלצת אותו לדבאג כשמשהו נשבר**, **שמנהלת אותו דרך menu של workflows מוכנים וקריאה של "מה אתה רוצה לעשות?" ולא דרך dashboard של toggles**, **שמאפשרת לו לשאול שאלות בשפה טבעית במקום לזכור שמות של commands**, **שתותאם את הרמה שלה אוטומטית לרמת הפרויקט**, **עם test architecture שהיא discipline נפרדת עם זכות veto**, **עם roundtable של specialists להחלטות ארכיטקטוניות מורכבות**, **עם module ecosystem שקהילה יכולה להרחיב**, **עם test infrastructure שממופה לפני קוד נכתב**, **עם auditor שלעולם לא נוגע ב-implementation**, **עם domain-specific contracts**, **עם proof-of-process חי**, **עם honest scope statement**, **עם threat model project-specific**, **עם Defense-in-Depth על הקבצים של עצמה**, **עם monetization שלא פוגע באמון (core free forever)**, **ועם framework-to-platform transition** — עם הכרה כנה שהסוכן (Claude) הוא רכיב fallible, **שגם המשתמש האנושי כפוף ל-Automation Bias**, **שגם ה-existence של קובץ אינה הוכחה לתוכן שלו**, **שגם graceful degradation היא סיבה לכישלון**, **שגם marketing קל הופך לאובדן אמון**, **שגם horizontal layer planning שובר write-serial**, **שגם generic security check מפספס threats פרויקט-ספציפיים**, **שגם AI שמודד tests יטה את הקוד לעבור tests סותרים**, **שגם הקבצים שAPEX יוצר בעצמו הופכים לפרומפט מורעל**, **שגם tool סגור יגיע ל-plateau אבל platform פתוחה תתפתח לנצח**, **ושגם הטוב ביותר מבין ה-AI ב-architecture אבל המשתמש מבין הכי טוב ב-product** — ולכן צריך מעקות בטיחות ברמת filesystem, content, schema, scope, ו-prompt injection, חוזים structurally enforced, adversarial verification עם cross-model decoupling וגם cross-AI external review וגם specialist roundtable, cost-awareness, U-shaped context engineering, Phase-Gating, strict mode, vertical slice enforcement, test/implementation quarantine עם veto power, dual-mode operation, scale-adaptive classification, ו-UX שלא רק **לא מציף** את המשתמש אלא גם **לא דורש ממנו ידע שאין לו**, **לא משאיר אותו לדבאג**, **לא מאלץ אותו להבין הגדרות**, **לא דורש ממנו לזכור שמות של commands**, **לא מחליט בשבילו במקומות שהוא המומחה**, **ולא נועל אותו מאחורי paywall כשהוא צריך עזרה**. לא הוראות וכוונות טובות, אלא **mechanism design שמניח טעות גם של ה-AI, גם של האדם, גם של ה-naive verification, גם של ה-environment, גם של ה-marketing, גם של ה-decomposition, גם של ה-generic security, גם של ה-test isolation, גם של ה-state files עצמם, גם של ה-monolithic architecture, וגם של ההנחה ש-AI יכול להחליף את המשתמש בכל דבר — כברירת מחדל** ובונה את כל המערכת סביב היכולת לזהות טעות לפני שהיא הופכת לנזק ולסייע למשתמש בדיוק בדברים שהוא לא יכול, בלי לקחת ממנו בדברים שהוא כן יכול — בעלות שמאפשרת לעבוד ברצינות, בקצב שמשתמש אנושי יכול לעקוב אחריו, בחוויה שלא דורשת ידע טכני, בפלטפורמה לבחירת המשתמש, בתחום שמוצהר במפורש, בליבה חינמית לנצח, **ובתוצאה הנדסית שמתרחבת לטובה לאורך הפרויקט במקום לקרוס תחת המשקל של עצמה** — והכל מוכח דרך פרויקטים פתוחים שכל אחד יכול לבדוק, וניתן להרחבה ע"י כל אחד שמבין דומיין שאנחנו לא הכרנו.