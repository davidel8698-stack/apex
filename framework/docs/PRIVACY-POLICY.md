# APEX Privacy Policy — Telemetry & Quality Drift

**Version:** v0.1.x (local-only)
**Last updated:** Phase 12.09 (M16.1)
**Spec anchors:** PLAN.md task 12.09 (M16.1 opt-out telemetry) · User Decision #3 (opt-out from start) · R2-C214 (quality drift falsification)

---

## English version

### Why this document exists

APEX makes specific, falsifiable claims — "context preservation across long
sessions", "task #50 quality ≈ task #1 quality", "DORA improvement". To prove
those claims are not theatre, APEX collects a small set of **anonymous,
numeric counters** locally. Without measurement, every promise is unfalsifiable
marketing.

This document is the **complete and only** data inventory. If a piece of
information is not listed under "What we collect", APEX does not collect it.

### What we collect

| Field | Type | Purpose |
|---|---|---|
| `ts` | ISO 8601 timestamp | Order events for drift computation |
| `event` | string identifier (e.g., `quality_drift`, `task_complete`) | Categorize the counter |
| `project_hash` | 8 hex chars — `sha256(basename $PWD)[0:8]` | Distinguish projects without revealing identity |
| `phase` (optional) | string identifier (e.g., `12-apex-evolution-v8`) | Per-phase aggregation |
| `counters` | JSON object — numeric values only | The actual measurement |

`counters` numeric examples: `drift_pct: -2.3`, `baseline_avg: 0.91`,
`current_avg: 0.89`, `tasks_completed: 47`, `deploys_in_window: 3`,
`cfr_numerator: 0`, `tokens_total: 142000`, `cache_hit_rate: 0.82`.

The qualitative `confidence` field on `RESULT.json` is mapped at emit time to
a numeric value (high = 1.0, medium = 0.5, low = 0.0) and **averaged over a
rolling window of 10 tasks**. The raw `confidence` string is never written to
telemetry — only the numeric drift derived from it.

### What we do NOT collect

The following are **never** written to `.apex/telemetry.jsonl`:

- File paths (`framework/hooks/foo.sh`, `/home/user/myproject/...`).
- Source code content (functions, comments, identifiers).
- Repository URLs or remote names.
- Branch names (`main`, `feature/...`).
- Commit messages or commit SHAs.
- User identity (git user.name, user.email, OS username).
- Environment variables (other than the opt-out flags themselves).
- File names or directory names from your project tree.
- Free-text strings from `confidence` reasoning, `decisions_made` text,
  or any other RESULT.json prose field.

**Verification — anonymization is testable.** Run:
```bash
grep "$(basename "$PWD")" .apex/telemetry.jsonl
```
This MUST return zero matches. `framework/tests/test-telemetry-anonymization.sh`
asserts this on every CI run.

### How to opt out

Two independent paths — either works, defense-in-depth:

1. **Per-session env var:**
   ```bash
   export APEX_TELEMETRY=off
   ```
   When set, `_telemetry-emit.sh` returns 0 (silent no-op) and never writes
   to `.apex/telemetry.jsonl`. Affects only the current shell session.

2. **Persistent opt-out flag:**
   ```bash
   touch ~/.claude/telemetry-opt-out.flag
   ```
   When this file exists, `_telemetry-emit.sh` returns 0 (silent no-op).
   Affects every project and every session of the current user, indefinitely.

Both paths are checked **before any disk write** — no telemetry line is
written even partially when either opt-out is active.

### Where data lives

`.apex/telemetry.jsonl` — **project-local file**. One JSON object per line,
append-only. APEX v0.1.x performs **no remote upload** under any circumstances.

There is no APEX-controlled remote endpoint. There are no third-party data
processors. There is no telemetry shipped off your machine.

### Anonymization mechanism

Project identifier is `sha256(basename "$PWD")` truncated to the first 8 hex
chars. Example:
```
$PWD = /home/alice/secret-project-name
basename = "secret-project-name"
sha256(basename) = "8e4c9a7e1b2..." (64 hex chars)
project_hash = "8e4c9a7e"  (first 8 hex chars)
```
The original basename does not appear anywhere in the telemetry file. Even
if the file is leaked, the basename cannot be recovered from the 8-char
prefix (the truncation is intentionally irreversible).

### GDPR-like rights — your data, your control

- **Right to inspect:** `cat .apex/telemetry.jsonl` — the file is plain JSON
  Lines, human-readable.
- **Right to delete:** `rm .apex/telemetry.jsonl` — single-file removal.
  No backups, no shadow copies, no remote.
- **Right to opt out retroactively:** delete the file, then set
  `APEX_TELEMETRY=off` or create the persistent flag. APEX will never
  re-write the file unless you remove the opt-out.
- **Future:** `apex telemetry purge` command is on the v1.0+ backlog. For
  v0.1.x, the single-file `rm` is the canonical deletion path. (TODO)

### Future remote upload — opt-in only, v1.0+

If APEX ever ships remote telemetry, it will:

1. Be **opt-in** (default off), not opt-out.
2. Use a **separate env flag**: `APEX_TELEMETRY_REMOTE=on`.
3. Use a **user-configurable URL** — no hardcoded endpoint.
4. Be documented in this file with the same level of detail as the local
   collection above.
5. **Not be implemented in v0.1.x.** The flag is reserved and ignored.

This document is part of the spec contract. Removing or weakening any of the
above five guarantees requires a major version bump (v1.0 minimum) and an
explicit DECISIONS.md entry — never a silent change.

### Why a quality counter and not a quality "snapshot"

The `confidence` field on RESULT.json is qualitative (high/medium/low). A
qualitative drift signal is fragile. The numeric mapping (high=1.0,
medium=0.5, low=0.0) and the 10-task rolling window average together produce
a **single floating-point number per emit** — small enough to be unambiguous,
large enough to detect a 5%+ degradation.

This number is the falsification mechanism for R2-C214's claim. Without it,
"task #50 ≈ task #1 quality" is an unfalsifiable promise. With it, any drift
above the configurable threshold (default ±5%) fires a `quality_drift`
event consumed by the rotation engine — APEX itself reacts to its own
degradation signal.

---

## גרסה עברית (Hebrew version)

### למה המסמך הזה קיים

APEX טוען טענות ספציפיות וניתנות לבדיקה — "שימור הקשר על פני שיחות ארוכות",
"איכות משימה #50 ≈ איכות משימה #1", "שיפור DORA". כדי להוכיח שהטענות הללו
אינן ריקות מתוכן, APEX אוסף מספר מועט של **מוני מספרים אנונימיים** באופן
מקומי. ללא מדידה — כל הבטחה היא שיווק שלא ניתן להפריך.

המסמך הזה הוא **המלאי המלא והיחיד** של נתונים שנאספים. אם מידע מסוים אינו
מופיע ברשימת "מה אנחנו אוספים", APEX אינו אוסף אותו.

### מה אנחנו אוספים

| שדה | סוג | מטרה |
|---|---|---|
| `ts` | חותמת זמן ISO 8601 | סידור אירועים לחישוב סחיפה |
| `event` | מחרוזת מזהה (לדוגמה, `quality_drift`) | קטגוריזציה של המונה |
| `project_hash` | 8 תווים הקסדצימליים — `sha256(basename $PWD)[0:8]` | להבחין בין פרויקטים בלי לחשוף זהות |
| `phase` (אופציונלי) | מחרוזת מזהה | אגרגציה לפי שלב |
| `counters` | אובייקט JSON — ערכים מספריים בלבד | המדידה עצמה |

דוגמאות של ערכים ב-`counters`: `drift_pct: -2.3`, `baseline_avg: 0.91`,
`current_avg: 0.89`, `tasks_completed: 47`.

השדה האיכותי `confidence` ב-`RESULT.json` ממופה בזמן הפליטה לערך מספרי
(high = 1.0, medium = 0.5, low = 0.0) ו**ממוצע על פני חלון מתגלגל של 10
משימות**. המחרוזת המקורית `confidence` לא נכתבת לעולם לטלמטריה — רק
הסחיפה המספרית הנגזרת ממנה.

### מה אנחנו לא אוספים

הדברים הבאים **לעולם** לא נכתבים ל-`.apex/telemetry.jsonl`:

- נתיבי קבצים.
- תוכן קוד מקור (פונקציות, הערות, מזהים).
- כתובות URL של מאגרים או שמות remotes.
- שמות branch.
- הודעות commit או SHA של commit.
- זהות משתמש (git user.name, user.email, שם המשתמש במערכת ההפעלה).
- משתני סביבה (מלבד דגלי ה-opt-out עצמם).
- שמות קבצים או תיקיות מעץ הפרויקט שלך.
- מחרוזות טקסט חופשי משדות ה-prose ב-RESULT.json.

**אימות — האנונימיזציה ניתנת לבדיקה.** הרץ:
```bash
grep "$(basename "$PWD")" .apex/telemetry.jsonl
```
פקודה זו **חייבת** להחזיר אפס התאמות. הבדיקה
`framework/tests/test-telemetry-anonymization.sh` מאמתת זאת בכל ריצת CI.

### איך לבטל הסכמה (opt out)

שני נתיבים בלתי תלויים — כל אחד מהם עובד (הגנה לעומק):

1. **משתנה סביבה לסשן בודד:**
   ```bash
   export APEX_TELEMETRY=off
   ```
   כאשר המשתנה הזה מוגדר, `_telemetry-emit.sh` מחזיר 0 (no-op שקט) ולא
   כותב כלל ל-`.apex/telemetry.jsonl`. משפיע רק על הסשן הנוכחי.

2. **דגל ביטול הסכמה קבוע:**
   ```bash
   touch ~/.claude/telemetry-opt-out.flag
   ```
   כאשר הקובץ הזה קיים, `_telemetry-emit.sh` מחזיר 0 (no-op שקט).
   משפיע על כל פרויקט וכל סשן של המשתמש הנוכחי, ללא הגבלת זמן.

שני הנתיבים נבדקים **לפני כל כתיבה לדיסק** — אף שורת טלמטריה אינה
נכתבת אפילו חלקית כאשר אחד מהם פעיל.

### היכן הנתונים נמצאים

`.apex/telemetry.jsonl` — **קובץ מקומי של הפרויקט**. אובייקט JSON אחד
בכל שורה, append-only בלבד. APEX v0.1.x **לא מבצע כל העלאה מרחוק** בשום
תנאי.

אין endpoint מרוחק בשליטת APEX. אין מעבדי נתונים של צד שלישי. אין
טלמטריה שיוצאת מהמחשב שלך.

### מנגנון האנונימיזציה

מזהה הפרויקט הוא `sha256(basename "$PWD")` מקוצץ ל-8 התווים ההקסדצימליים
הראשונים. הקיצוץ מכוון להיות בלתי הפיך — את ה-basename המקורי אי אפשר
לשחזר מתוך 8 התווים.

### זכויות דמויות-GDPR — הנתונים שלך, השליטה שלך

- **זכות לעיין:** `cat .apex/telemetry.jsonl` — הקובץ הוא JSON Lines רגיל,
  קריא לאדם.
- **זכות למחוק:** `rm .apex/telemetry.jsonl` — מחיקת קובץ בודד. אין גיבויים,
  אין עותקי צל, אין מרוחק.
- **זכות לבטל הסכמה רטרואקטיבית:** מחק את הקובץ, אז הגדר
  `APEX_TELEMETRY=off` או צור את הדגל הקבוע. APEX לא יכתוב את הקובץ מחדש
  אלא אם תסיר את ה-opt-out.
- **עתיד:** פקודה `apex telemetry purge` נמצאת ב-backlog לגרסה v1.0+. עבור
  v0.1.x, המחיקה הקנונית היא ה-`rm` של הקובץ הבודד. (TODO)

### העלאה מרחוק עתידית — opt-in בלבד, מגרסה v1.0+

אם APEX אי פעם תכלול טלמטריה מרחוק, היא תהיה:

1. **opt-in** (כבוי כברירת מחדל), לא opt-out.
2. תשתמש ב**דגל סביבה נפרד**: `APEX_TELEMETRY_REMOTE=on`.
3. תשתמש ב**URL הניתן לקונפיגורציה על ידי המשתמש** — ללא endpoint קשיח.
4. תתועד במסמך הזה באותה רמת פירוט שבה מתועד האיסוף המקומי לעיל.
5. **לא תיושם ב-v0.1.x.** הדגל שמור ומתעלמים ממנו.

מסמך זה הוא חלק מחוזה המפרט. הסרה או החלשה של אחת מחמש הערבויות הללו
דורשת קפיצת גרסת major (v1.0 מינימום) ורשומה מפורשת ב-DECISIONS.md —
לעולם לא שינוי שקט.

---

## Cross-references

- `framework/hooks/_telemetry-emit.sh` — the implementation of every
  guarantee above. Every disk write is gated by the two opt-out checks
  at the top of `apex_telemetry_emit`.
- `framework/hooks/quality-drift.sh` — the only writer of `quality_drift`
  telemetry events in v0.1.x. Other writers will be added with the same
  guarantees.
- `framework/tests/test-telemetry-opt-out.sh` — asserts both opt-out paths
  produce silent no-op + zero-byte writes.
- `framework/tests/test-telemetry-anonymization.sh` — asserts the project
  basename does NOT appear in the emitted file and that `project_hash` is
  reproducible from `sha256(basename $PWD)[0:8]`.
- `framework/docs/CLAIMS-MEASUREMENT.md` — the measurement methodology
  cross-references this policy when discussing the qualitative→numeric
  confidence mapping.
- PLAN.md task 12.09 §5–6 — implementation contract for M16 + M16.1.
- User Decision #3 — promoted opt-out from v1.0 backlog to v0.1.x P1.
