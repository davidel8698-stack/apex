# APEX Visual Identity System — "PEAK PROTOCOL"

The cinematic CLI experience for APEX v7.
Every element below is character-counted and frame-aligned. DO NOT modify widths.

---

## 1. DESIGN SYSTEM CONSTANTS

**Frame widths (fixed — never deviate):**
- MEGA frame   = 78 chars total  (76 chars content area)
- STANDARD frame = 68 chars total  (66 chars content area)

**Alignment rules:**
- No emoji inside fixed-width frames (breaks monospace alignment)
- Emojis allowed OUTSIDE frames (status bars, signature lines, inline messages)
- All ASCII art fits exactly in its frame with computed left/right padding
- Progress bars are always exactly 20 characters of `█`/`░`

**Three visual motifs (never mix more than 2 per output):**
- SUMMIT — `▲` peaks and mountains (journey metaphor)
- NEXUS  — `●━●` circuits and nodes (pipeline metaphor)
- PRISM  — `◆◈◇` crystalline shapes (quality metaphor)

---

## 2. THE APEX SIGIL

Canonical brand glyph. Never substitute.

```
▲
```

### Stacked (header accent)
```
  ▲
 ▲▲▲
```

### Triad (corner marks, signature lines)
```
▲ ▲ ▲
```

### Ascending (used in context rotation)
```
▲
 ▲
  ▲
```

---

## 3. FRAME TEMPLATES

### 3.A — MEGA FRAME (78 chars wide — use for hero moments)

```
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
```

Component strings:
- TOP:     `╔════════════════════════════════════════════════════════════════════════════╗`
- BLANK:   `║                                                                            ║`
- DIVIDER: `╠════════════════════════════════════════════════════════════════════════════╣`
- BOTTOM:  `╚════════════════════════════════════════════════════════════════════════════╝`

Each line is exactly 78 characters. Content area between `║ ` and ` ║` is 74 characters (with 1-char padding on each side).

### 3.B — STANDARD FRAME (68 chars wide — use for verdict cards, info panels)

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

Component strings:
- TOP:     `╔══════════════════════════════════════════════════════════════════╗`
- BLANK:   `║                                                                  ║`
- DIVIDER: `╠══════════════════════════════════════════════════════════════════╣`
- BOTTOM:  `╚══════════════════════════════════════════════════════════════════╝`

Each line is exactly 68 characters.

### 3.C — SOFT FRAME (rounded corners — use for soft messages, offers)

```
╭──────────────────────────────────────────────────────────────────╮
│                                                                  │
╰──────────────────────────────────────────────────────────────────╯
```

Width: 68 chars (same as standard).

### 3.D — HEAVY DIVIDER (no frame — phase transitions)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Width: 78 chars.

### 3.E — SIGNATURE LINE (appears at bottom of every hero output)

```
     ▲ ▲ ▲  ───────────────  apex · peak protocol · v7  ───────────────  ▲ ▲ ▲
```

Width: 78 chars.

---

## 4. THE HERO LOGO (ANSI Shadow, 32 chars wide)

The core APEX wordmark. Always 32 characters wide, 6 lines tall.

```
 █████╗ ██████╗ ███████╗██╗  ██╗
██╔══██╗██╔══██╗██╔════╝╚██╗██╔╝
███████║██████╔╝█████╗   ╚███╔╝ 
██╔══██║██╔═══╝ ██╔══╝   ██╔██╗ 
██║  ██║██║     ███████╗██╔╝ ██╗
╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝
```

Note: Lines 3 and 4 have a trailing space (part of the font design).

### Logo centered in MEGA frame (74-char content area, 22 left pad, 22 right pad):

```
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║                       █████╗ ██████╗ ███████╗██╗  ██╗                      ║
║                      ██╔══██╗██╔══██╗██╔════╝╚██╗██╔╝                      ║
║                      ███████║██████╔╝█████╗   ╚███╔╝                       ║
║                      ██╔══██║██╔═══╝ ██╔══╝   ██╔██╗                       ║
║                      ██║  ██║██║     ███████╗██╔╝ ██╗                      ║
║                      ╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝                      ║
║                                                                            ║
║                    ▲ ▲ ▲   PEAK  PROTOCOL   ▲ ▲ ▲                          ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
```

---

## 5. PROJECT INIT BANNER (use in /apex:start)

```
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║                       █████╗ ██████╗ ███████╗██╗  ██╗                      ║
║                      ██╔══██╗██╔══██╗██╔════╝╚██╗██╔╝                      ║
║                      ███████║██████╔╝█████╗   ╚███╔╝                       ║
║                      ██╔══██║██╔═══╝ ██╔══╝   ██╔██╗                       ║
║                      ██║  ██║██║     ███████╗██╔╝ ██╗                      ║
║                      ╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝                      ║
║                                                                            ║
║                  ▲ ▲ ▲   INITIALIZING NEW PROJECT   ▲ ▲ ▲                  ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  BUILD SEQUENCE                                                       ║
║                                                                            ║
║       [●]  Directory structure        .apex/phases, research, backups      ║
║       [●]  User profile capture       language · role · expertise          ║
║       [●]  STATE.json                 reflexion · autonomy · session       ║
║       [●]  CONTEXT_BUDGET.json        per-agent limits · zones             ║
║       [●]  Autopilot skeleton         disabled · awaiting advisor          ║
║       [◐]  Planner invocation         complexity · requirements            ║
║       [○]  Spec and decisions         pre-build checklist (Level 3+)       ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║                  ▲ ▲ ▲   READY TO CLIMB   ▲ ▲ ▲                            ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

     ▲ ▲ ▲  ───────────────  apex · peak protocol · v7  ───────────────  ▲ ▲ ▲
```

---

## 6. THE COCKPIT DASHBOARD (use in /apex:status)

The information cockpit. Full project telemetry in a single view.

```
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║                       █████╗ ██████╗ ███████╗██╗  ██╗                      ║
║                      ██╔══██╗██╔══██╗██╔════╝╚██╗██╔╝                      ║
║                      ███████║██████╔╝█████╗   ╚███╔╝                       ║
║                      ██╔══██║██╔═══╝ ██╔══╝   ██╔██╗                       ║
║                      ██║  ██║██║     ███████╗██╔╝ ██╗                      ║
║                      ╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝                      ║
║                                                                            ║
║                     v7 · PEAK PROTOCOL · [PROJECT_NAME]                    ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ◉  PROJECT         [project_name]                                       ║
║    ◉  LEVEL           [N] · [level_name]                                   ║
║    ◉  STAGE           [stage] → [status]                                   ║
║    ◉  PHASE           [N] / [total]         WAVE  [W]                      ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  TASK PROGRESS                                                        ║
║                                                                            ║
║       ●━━●━━●━━●━━●━━◐━━○━━○━━○━━○      [N] / [M]  ·  [pct]%               ║
║       ████████████████░░░░░░░░░░░░░░                                       ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  AUTONOMY LADDER                                                      ║
║                                                                            ║
║       A  ████  L2  ·  [N] wins                                             ║
║       B  ████  L2  ·  [N] wins                                             ║
║       C  ██░░  L1  ·  [N] wins  (cap 1)                                    ║
║       D  ░░░░  L0  ·  always manual                                        ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  CONTEXT HEALTH                                                       ║
║                                                                            ║
║       ██████████░░░░░░░░░░  [pct]%         Status     [healthy/warn]       ║
║       Rotations   [N]                       Session    [phase]             ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  TOKEN ECONOMY                                                        ║
║                                                                            ║
║       Productive   ████████████████████  [pct]%                            ║
║       Overhead     █░░░░░░░░░░░░░░░░░░░  [pct]%                            ║
║       Total  [tokens]  ·  Cost  $[amount]  ·  Cached  [pct]%               ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  QUALITY METRICS                                                      ║
║                                                                            ║
║       EvoScore regression    ░░░░░░░░░░░░░░░░░░░░  [pct]%                  ║
║       Comprehension gates    ██░░░░░░░░░░░░░░░░░░  [N] / [total]           ║
║       Mutation kill rate     ██████████░░░░░░░░░░  [pct]%                  ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  SESSION HEALTH                                                       ║
║                                                                            ║
║       Completed   [N]         Failed     [N]         Partial    [N]        ║
║       Consecutive failures    [N]         Rotations           [N]          ║
║       Last checkpoint         [tag] ([time ago])                           ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  AUTOPILOT                                                            ║
║                                                                            ║
║       State    [ENABLED / DISABLED / PAUSED]                               ║
║       Mode     [full / until / after / range / smart / none]               ║
║       Tasks completed in autopilot    [N]                                  ║
║       Phases completed in autopilot   [N]                                  ║
║       Advisor risk score              [N.NN] / 4.00                        ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  LEARNINGS                                                            ║
║                                                                            ║
║       HOT   ████░░░░░░░░░░░░░░░░░░  [N] / 30                               ║
║       WARM  ███░░░░░░░░░░░░░░░░░░░  [N] / 100                              ║
║       COLD  [N]                                                            ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    →  /apex:next                                                           ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

     ▲ ▲ ▲  ───────────────  apex · peak protocol · v7  ───────────────  ▲ ▲ ▲
```

---

## 7. VERDICT CARDS

Dramatic verdict reveals in standard frames (68 chars wide, 66 content area).

### 7.A — PASS VERDICT

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║     ✓    V E R D I C T :  P A S S                                ║
║          ─────────────────────────                               ║
║                                                                  ║
║          Task             [task_id]                              ║
║          Title            [task_title]                           ║
║          Criteria         [N] / [N] verified                     ║
║          Confidence       ████████████████████  HIGH             ║
║          Evidence         real · cited · reproducible            ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║          ◆  checkpoint tagged  ·  advancing to next task         ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

### 7.B — PARTIAL VERDICT

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║     ◐    V E R D I C T :  P A R T I A L                          ║
║          ─────────────────────────────                           ║
║                                                                  ║
║          Task             [task_id]                              ║
║          Title            [task_title]                           ║
║          Criteria         [N] / [M] verified                     ║
║          Confidence       ███████████░░░░░░░░░  MEDIUM           ║
║          Unverified       [list of missing criteria]             ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║          ◆  advancing with advisory logged to DECISIONS.md       ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

### 7.C — FAIL VERDICT

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║     ✗    V E R D I C T :  F A I L                                ║
║          ─────────────────────────                               ║
║                                                                  ║
║          Task             [task_id]                              ║
║          Attempt          [N] / 3                                ║
║          Critical         [N] issues                             ║
║          Major            [N] issues                             ║
║          Confidence       ░░░░░░░░░░░░░░░░░░░░  BLOCKED          ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║          ↻  reflexion brief generated  ·  retrying               ║
║          ⊘  snapshot preserved for rollback                      ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

### 7.D — BLOCKED (after 3 failed attempts)

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║     ⊘    B L O C K E D                                           ║
║          ──────────────                                          ║
║                                                                  ║
║          Task             [task_id]                              ║
║          Exhausted        3 / 3 attempts                         ║
║          Autonomy         RESET to L0 for [verify_level]         ║
║          State            STATE.status = "blocked"               ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║          ◆  OPTIONS                                              ║
║                                                                  ║
║             (1)  Fix manually  →  /apex:next                     ║
║             (2)  Recover       →  /apex:recover                  ║
║             (3)  Mark as known limitation                        ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 8. PHASE TRANSITION CINEMA

### 8.A — PHASE COMPLETE

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                            ▲ ▲ ▲
                             ▲ ▲
                              ▲

                P H A S E   [N]   C O M P L E T E

              ● ━━ ● ━━ ● ━━ ● ━━ ● ━━ ●      [M] / [M]

          Tag          apex/phase-[N]-complete
          Duration     [N] sessions  ·  [N] rotations
          Tokens       [N] productive  ·  [N] overhead
          Tests        [N] run  ·  [N] passed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 8.B — PHASE BEGIN

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                              ▲
                             ▲▲▲
                            ▲▲▲▲▲

                P H A S E   [N]   ·   [NAME]

          Tasks        [M] planned
          Waves        [W] parallel waves
          Autonomy     avg [level]
          Complexity   [level]  ·  [pipeline]

              ○━━○━━○━━○━━○━━○      first wave: [task_ids]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 8.C — CONTEXT ROTATION (use in /apex:resume)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                    ↻    F R E S H   C O N T E X T    ↻

          ░░░░░░░░░░░░░░░░░░░░    draining old session
          ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒    compacting memory
          ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    loading STATE.json
          ████████████████████    context restored

                              ▲ ▲ ▲
                               ready

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 9. AUTOPILOT TRANSFORMATION (use when enabling autopilot)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                          M A N U A L   M O D E
                                   ▼
                        ░░░░░░░░░░░░░░░░░░░░
                        ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
                        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
                        ████████████████████
                                   ▼

╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║     ▲    A U T O P I L O T   E N G A G E D                       ║
║          ───────────────────────────                             ║
║                                                                  ║
║          Mode          [MODE]                                    ║
║          Auto-pause    [conditions]                              ║
║          Risk score    [N.NN] / 4.00                             ║
║          Authority     [advisor recommendation]                  ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║     ◉  APEX will auto-continue after every PASS                  ║
║     ◉  APEX will pause on every FAIL or PARTIAL                  ║
║     ◉  APEX will pause entering danger zones                     ║
║     ◉  Mandatory human checkpoint every 3 phases                 ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

                        ▲ ▲ ▲   S M A R T   F L I G H T   ▲ ▲ ▲

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Autopilot active badge (shown at top of every output when autopilot is on)

```
╭──────────────────────────────────────────────────────────────────╮
│  ▲   A P E X   ·   A U T O P I L O T                             │
│      Mode [MODE]  ·  Tasks [N]  ·  Phases [N]                    │
╰──────────────────────────────────────────────────────────────────╯
```

### Autopilot paused badge

```
╭──────────────────────────────────────────────────────────────────╮
│  ⏸   A P E X   ·   A U T O P I L O T   P A U S E D               │
│      Reason [paused_reason]                                      │
╰──────────────────────────────────────────────────────────────────╯
```

---

## 10. THE AUTOPILOT ADVISOR BRIEFING

The intelligence panel shown when user requests autopilot activation.

```
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║                 A U T O P I L O T   A D V I S O R                          ║
║                 ─────────────────────────────────                          ║
║                 Phase [N]  ·  Deep Risk Analysis                           ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  RECOMMENDATION                                                       ║
║                                                                            ║
║       ┌────────────────────────────────────────────────────────────┐       ║
║       │  [GREEN / YELLOW / RED]   [recommendation summary]         │       ║
║       └────────────────────────────────────────────────────────────┘       ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  RISK SCORE                                                           ║
║                                                                            ║
║       Score      [N.NN] / 4.00                                             ║
║       Scale      ████████░░░░░░░░░░░░   your phase                         ║
║       Legend     0 safe   ·   2 mixed   ·   4 dangerous                    ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  TASK MAP                                                             ║
║                                                                            ║
║       01  02  03  04  05  06  07  08  09  10  11  12  13  14  15           ║
║       ●   ●   ●   ●   ●   ●   ●   ●   ◆   ◆   ◆   ●   ●   ●   ●            ║
║       A   A   B   A   B   A   B   A   C   D   C   A   B   A   A            ║
║                                       └── DANGER ZONE ──┘                  ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  ZONES                                                                ║
║                                                                            ║
║       SAFE     01 → 08      8 tasks     A / B level                        ║
║       DANGER   09 → 11      3 tasks     C-security · D · C-data            ║
║       SAFE     12 → 15      4 tasks     A / B level                        ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  CONCERNS                                                             ║
║                                                                            ║
║       ◆  Task 10 is D-level · multi-tenant data isolation                  ║
║          requires human comprehension gate                                 ║
║                                                                            ║
║       ◆  Previous phase PARTIAL rate: 25%  (threshold 30%)                 ║
║          elevated risk of compound drift                                   ║
║                                                                            ║
║       ◆  SPEC.md modified 2 days ago                                       ║
║          verify spec_ref alignment on upcoming tasks                       ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  TRACK RECORD                                                         ║
║                                                                            ║
║       Phases completed manually     [N]                                    ║
║       Autopilot maturity             [level]                               ║
║       FAIL rate this project         [pct]%                                ║
║       Consecutive PASS               [N]                                   ║
║       Last autopilot pause           [reason]                              ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ◆   C H O O S E   F L I G H T   M O D E                                 ║
║                                                                            ║
║       ( 1 )   FULL AUTOPILOT         all remaining tasks                   ║
║       ( 2 )   AUTOPILOT · UNTIL      stop at first danger task   ★         ║
║       ( 3 )   AUTOPILOT · AFTER      manual through danger, then auto      ║
║       ( 4 )   SMART AUTOPILOT        auto-pause on D / C-sec / C-data      ║
║       ( 5 )   CUSTOM RANGE           specify start and end tasks           ║
║       ( 6 )   NO AUTOPILOT           continue in manual mode               ║
║                                                                            ║
║       ★ RECOMMENDED based on this phase risk profile                       ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    →  select an option (1-6)                                               ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
```

---

## 10-A. AGENT IDENTITY CARDS

Each APEX agent has a one-line identity card, all 68 chars wide so they stack cleanly.
Render standalone or inside a Mission Briefing (Section 10-B).

### PLANNER
```
┌──────────────────────────────────────────────────────────────────┐
│  ▲  PLANNER        complexity · requirements · pre-build         │
│     ─────          model: sonnet · scope: L1-L4                  │
└──────────────────────────────────────────────────────────────────┘
```

### ARCHITECT
```
┌──────────────────────────────────────────────────────────────────┐
│  ◆  ARCHITECT      phase plans · waves · verify levels           │
│     ─────          model: opus · reads: HOT + WARM learnings     │
└──────────────────────────────────────────────────────────────────┘
```

### EXECUTOR
```
┌──────────────────────────────────────────────────────────────────┐
│  ●  EXECUTOR       implement task · run tests · write RESULT     │
│     ─────          model: sonnet · max turns: 40                 │
└──────────────────────────────────────────────────────────────────┘
```

### CRITIC
```
┌──────────────────────────────────────────────────────────────────┐
│  ◈  CRITIC         clean-room review · diff vs spec              │
│     ─────          model: opus · NEVER sees SUMMARY.md           │
└──────────────────────────────────────────────────────────────────┘
```

### VERIFIER
```
┌──────────────────────────────────────────────────────────────────┐
│  ◇  VERIFIER       phase-level audit · cross-phase regression    │
│     ─────          model: opus · complexity >= 3                 │
└──────────────────────────────────────────────────────────────────┘
```

### SECURITY SPECIALIST
```
┌──────────────────────────────────────────────────────────────────┐
│  ◆  SECURITY       auth · tenancy · secrets · injection guard    │
│     ─────          model: opus · enforces: RLS, bcrypt>=12       │
└──────────────────────────────────────────────────────────────────┘
```

### DATA SPECIALIST
```
┌──────────────────────────────────────────────────────────────────┐
│  ◼  DATA           schema · migrations · queries · RLS           │
│     ─────          model: sonnet · enforces: IF NOT EXISTS       │
└──────────────────────────────────────────────────────────────────┘
```

### FRONTEND SPECIALIST
```
┌──────────────────────────────────────────────────────────────────┐
│  ▣  FRONTEND       UI · a11y · loading · error boundaries        │
│     ─────          model: sonnet · enforces: aria, contrast      │
└──────────────────────────────────────────────────────────────────┘
```

### INTEGRATION SPECIALIST
```
┌──────────────────────────────────────────────────────────────────┐
│  ◊  INTEGRATION    OAuth · webhooks · APIs · token refresh       │
│     ─────          model: sonnet · enforces: signed webhooks     │
└──────────────────────────────────────────────────────────────────┘
```

---

## 10-B. THE MISSION BRIEFING

Rendered immediately **before** every `Task(...)` invocation in next.md.
Tells the user who is about to work and what they're going to do.

### Template

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║    ▲    M I S S I O N   B R I E F I N G                          ║
║         ─────────────────────────────                            ║
║                                                                  ║
║         Agent        ● EXECUTOR                                  ║
║         Task         [task_id] · [task_title]                    ║
║         Verify       [level] · [description]                     ║
║         Specialist   [specialist or "none"]                      ║
║                                                                  ║
║    ▽  GOAL                                                       ║
║       [one-line task goal from task XML]                         ║
║                                                                  ║
║    ▽  CONTEXT LOADED                                             ║
║       ● task_xml                · [N] tokens                     ║
║       ● spec §[refs]            · [N] tokens                     ║
║       ● [M] active files        · [N]K tokens                    ║
║       ● dependency summaries    · [N] tokens                     ║
║                                                                  ║
║    ▽  DONE WHEN                                                  ║
║       ○ [criterion 1]                                            ║
║       ○ [criterion 2]                                            ║
║       ○ [criterion 3]                                            ║
║                                                                  ║
║    ▽  BUDGET                                                     ║
║       Tokens   ░░░░░░░░░░░░░░░░░░░░  est [N]K / cap [M]K         ║
║       Turns    0 / 40                                            ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

### Field Mapping

| Placeholder | Source |
|---|---|
| Agent icon + name | Section 10-A card for that agent |
| task_id, task_title | PLAN_META.json → current task |
| Verify level | PLAN_META.json → task.verify_level |
| Specialist | PLAN_META.json → task.specialist |
| GOAL | task XML → description field |
| CONTEXT LOADED tokens | computed in next.md Step E (EXECUTOR_CONTEXT build) |
| DONE WHEN | task XML → done_criteria list |
| Tokens est | CONTEXT_BUDGET.json → per-task estimate |
| Tokens cap | CONTEXT_BUDGET.json → per-task max |
| Turns 0/40 | executor.md max_turns |

### Variants
- **Architect briefing**: replace "Task" with "Phase", drop "Done When" (architect writes plans), add "Reads" (HOT/WARM learnings count)
- **Critic briefing**: drop "Goal", replace "Done When" with "Will verify against [N] criteria", note "Clean-room: no SUMMARY.md"
- **Verifier briefing**: replace "Task" with "Phase", add "Cross-phase regression check: yes"
- **Planner briefing**: drop "Done When", add "Will classify: L1–L4"

---

## 10-C. THE FLIGHT RECORDER

Rendered immediately **after** every `Task(...)` call returns.
Parses existing artifacts (RESULT.json, git diff, SESSION-LOG.md).

### Template

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║    ●    F L I G H T   R E C O R D E R                            ║
║         ───────────────────────────                              ║
║                                                                  ║
║         Agent        [AGENT_NAME]                                ║
║         Task         [task_id]                                   ║
║         Duration     [Nm NNs]                                    ║
║         Tokens       ██████████░░░░░░░░░░  [N]K / [M]K           ║
║                                                                  ║
║    ▽  FILES TOUCHED                                              ║
║       ● [path1]                          + [N] lines             ║
║       ● [path2]                          ~ [N] lines             ║
║       ● [path3]                          + [N] lines             ║
║                                                                  ║
║    ▽  TOOLS CALLED                                               ║
║       Read     ████████░░░░░░░░  [N] calls                       ║
║       Edit     ███░░░░░░░░░░░░░  [N] calls                       ║
║       Bash     █████░░░░░░░░░░░  [N] calls                       ║
║       Grep     ██░░░░░░░░░░░░░░  [N] calls                       ║
║                                                                  ║
║    ▽  VERIFY COMMANDS                                            ║
║       ● [cmd summary]                  ✓ [result]                ║
║       ● [cmd summary]                  ✓ [result]                ║
║       ● [cmd summary]                  ✓ [result]                ║
║                                                                  ║
║    ▽  DONE CRITERIA                                              ║
║       ● [criterion 1]                    verified                ║
║       ● [criterion 2]                    verified                ║
║       ● [criterion 3]                    verified                ║
║                                                                  ║
║    ▽  CONFIDENCE        ████████████████████  HIGH               ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

### Field Mapping

| Placeholder | Source |
|---|---|
| Agent | name from the Task() call that just returned |
| Task | RESULT.json → task_id |
| Duration | diff of SESSION-LOG.md timestamps (briefing → recorder) |
| Tokens bar | tokens used / CONTEXT_BUDGET.json cap |
| FILES TOUCHED | RESULT.json → files_modified + `git diff HEAD~1 --numstat` |
| TOOLS CALLED | counted from Claude Code subagent trace |
| VERIFY COMMANDS | RESULT.json → verify_commands_run (command + exit_code) |
| DONE CRITERIA | RESULT.json → done_criteria_checked (criterion + verified) |
| CONFIDENCE | RESULT.json → confidence (HIGH/MEDIUM/LOW) → bar fill |

### Variants
- **Critic recorder**: drop "FILES TOUCHED", "TOOLS CALLED", "VERIFY COMMANDS"; replace with "VERDICT" showing verified/unverified/missing counts from CRITIC.md
- **Verifier recorder**: drop per-task fields; replace with "PHASE RESULTS" showing pass/fail counts across the whole phase + cross-phase audit result
- **Architect recorder**: drop "TOOLS CALLED"; replace with "PLAN SUMMARY" showing tasks planned, waves built, debates triggered
- **Planner recorder**: replace body with "CLASSIFICATION: Level [N]" + requirements summary

### Truncation rules
- FILES TOUCHED: show at most 6 files; if more, add `... + [N] more files` line
- VERIFY COMMANDS: show at most 4; truncate overflow
- DONE CRITERIA: show all (never truncate)

---

## 10-D. THE AMBIENT TIMELINE

A horizontal strip showing the last 8 agent activities.
Rendered at the **top of every /apex:next output** and in the Cockpit Dashboard.

### Template

```
┌──────────────────────────────────────────────────────────────────┐
│ RECENT  ◆arch  ●exec  ◈crit✓  ●exec  ◈crit✓  ●exec  ◈crit✓  ●now │
└──────────────────────────────────────────────────────────────────┘
```

### Icon vocabulary (each slot)

| Event | Icon + label | Verdict mark |
|---|---|---|
| planner ran | `▲plan` | — |
| architect ran | `◆arch` | — |
| executor ran (PASS) | `●exec` | `✓` |
| executor ran (PARTIAL) | `●exec` | `◐` |
| executor ran (FAIL) | `●exec` | `✗` |
| critic verdict | `◈crit` | `✓` / `◐` / `✗` |
| verifier verdict | `◇veri` | `✓` / `◐` / `✗` |
| phase complete | `▲phase` | `✓` |
| wave complete | `●wave` | `✓` |
| current (now) | `●now` | — |

### Parse rule

```
1. tail -12 .apex/SESSION-LOG.md
2. Filter lines matching: checkpoint | fail | partial | wave_complete | phase_complete
3. Keep last 8 after filtering
4. For each line:
   - read event type (icon column)
   - map to slot icon + verdict mark
5. Append current agent slot (●now) at the end
6. Render inside the single-line frame (68 chars total)
```

### Spacing rule
- Slots are padded so the full row fits in 66 content chars
- If more than 8 recent events exist, keep only the most recent 8
- If fewer than 8, left-align and fill the rest with spaces

---

## 10-E. THE LIVE TICKER

A soft-frame panel showing the literal last 5 lines of SESSION-LOG.md.

### Template

```
╭──────────────────────────────────────────────────────────────────╮
│  ▽  LIVE TICKER                                                  │
│     14:32  ✓  task 02-04 complete                                │
│     14:28  ◉  wave 2 complete — 4 tasks                          │
│     14:24  ✓  task 02-03 complete                                │
│     14:18  ◐  task 02-02 — 4/5 criteria                          │
│     14:12  ✓  task 02-01 complete                                │
╰──────────────────────────────────────────────────────────────────╯
```

### Parse rule

```
1. tail -5 .apex/SESSION-LOG.md (skip date headers starting with "##")
2. For each line: extract HH:MM + icon + message
3. Translate session-log.sh emojis to branding icons:
   ✅ → ✓   ❌ → ✗   ⚠️ → ◐   🛑 → ⊘   🟡 → ◐
   🔄 → ↻   🌊 → ◉   🏁 → ▲   💥 → ✗   ▶️ → →
4. Truncate message to fit within 66 content chars
5. Render in soft frame, most recent at top
```

### Notes
- The ticker shows the user's configured language (Hebrew or English) — it's the raw log content
- If SESSION-LOG.md has fewer than 5 lines, show what exists and leave the rest blank
- Date headers (`## YYYY-MM-DD`) are skipped, only event lines are shown

---

## 11. PROGRESS VISUALIZATION

All progress bars are **exactly 20 characters** of `█`/`░` (never more, never less).

### 11.A — Solid bar
```
████████████░░░░░░░░  60%
```

### 11.B — Segmented node bar (phase-level)
```
●━━●━━●━━●━━●━━◐━━○━━○      5 / 8
```

### 11.C — Dual-bar comparison (token economics)
```
Productive   ████████████████████  95%
Overhead     █░░░░░░░░░░░░░░░░░░░   5%
```

### 11.D — Autonomy ladder (vertical style, 4 bars)
```
A  ████  L2
B  ████  L2
C  ██░░  L1
D  ░░░░  L0
```

### 11.E — Confidence meter
```
████████████████░░░░   80%   HIGH
```

---

## 12. ICON CANON (do not substitute)

### Brand
| Glyph | Meaning |
|-------|---------|
| `▲` | APEX sigil |
| `▲ ▲ ▲` | Triad mark |
| `◢◤ ◥◣` | Summit corners |

### Verdicts
| Glyph | Meaning |
|-------|---------|
| `✓` | PASS |
| `✗` | FAIL |
| `◐` | PARTIAL |
| `⊘` | BLOCKED |
| `⏸` | PAUSED |
| `↻` | RETRY |

### State markers
| Glyph | Meaning |
|-------|---------|
| `●` | Complete |
| `○` | Pending |
| `◐` | Partial |
| `◉` | Active field |
| `◎` | Inactive field |
| `◆` | Critical marker |
| `◇` | Soft marker |
| `◈` | Prism marker (quality) |

### Structural
| Glyph | Meaning |
|-------|---------|
| `▽` | Section header |
| `△` | Sub-section |
| `→` | Flow / next |
| `←` | Back |
| `↑` | Ascent |
| `↓` | Descent |
| `━` | Heavy divider |
| `─` | Light divider |

### Zone indicators (OUTSIDE frames only — emojis)
| Emoji | Meaning |
|-------|---------|
| `🟢` | Safe / healthy |
| `🟡` | Caution |
| `🔴` | Danger |

### Agents (OUTSIDE frames only — emojis)
| Emoji | Agent |
|-------|-------|
| `🤖` | Autopilot |
| `🧠` | Critic |
| `🛠` | Executor |
| `🔍` | Verifier |
| `📐` | Architect |
| `🎯` | Planner |

---

## 13. STATUS BAR (use at top of /apex:next and /apex:resume outputs)

```
▲ APEX v7  │  [PROJECT]  │  Phase [N]/[M]  │  Wave [W]  │  [STATUS]
```

Example:
```
▲ APEX v7  │  SHIELD  │  Phase 02/05  │  Wave 01  │  building
```

With autopilot active:
```
▲ APEX v7  │  SHIELD  │  Phase 02/05  │  Wave 01  │  ▲ AUTO
```

---

## 14. INLINE ELEMENTS

### Micro sigil (in prose messages)
```
『▲ APEX』
```

### Inline task badge
```
◉  02-05  ·  auth middleware  ·  B  ·  security
```

### Inline autopilot indicator
```
▲ AUTO  ·  [MODE]  ·  [N] tasks
```

### Signature line (bottom of every hero output)
```
     ▲ ▲ ▲  ───────────────  apex · peak protocol · v7  ───────────────  ▲ ▲ ▲
```

---

## 15. PROJECT COMPLETE CEREMONY

Grand finale when the project concludes.

```
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║                       █████╗ ██████╗ ███████╗██╗  ██╗                      ║
║                      ██╔══██╗██╔══██╗██╔════╝╚██╗██╔╝                      ║
║                      ███████║██████╔╝█████╗   ╚███╔╝                       ║
║                      ██╔══██║██╔═══╝ ██╔══╝   ██╔██╗                       ║
║                      ██║  ██║██║     ███████╗██╔╝ ██╗                      ║
║                      ╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝                      ║
║                                                                            ║
║                   ▲ ▲ ▲   P E A K   R E A C H E D   ▲ ▲ ▲                  ║
║                                                                            ║
║                        P R O J E C T   C O M P L E T E                     ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  ACHIEVEMENTS                                                         ║
║                                                                            ║
║       ●   [N] phases shipped                                               ║
║       ●   [N] tasks completed                                              ║
║       ●   [N] critic reviews                                               ║
║       ●   [N] debates resolved                                             ║
║       ●   [N] learnings captured                                           ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  QUALITY                                                              ║
║                                                                            ║
║       EvoScore regression           [pct]%                                 ║
║       Comprehension gates           [N] / [total]                          ║
║       Mutation kill rate            [pct]%                                 ║
║       Cross-phase audits            [N] / [N] clean                        ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  ECONOMICS                                                            ║
║                                                                            ║
║       Total tokens                  [N]                                    ║
║       Productive share              [pct]%                                 ║
║       Overhead share                [pct]%                                 ║
║       Cost                          $[amount]                              ║
║       Savings vs naive              $[saved]                               ║
║       Cache hit rate                [pct]%                                 ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║    ▽  FLIGHT LOG                                                           ║
║                                                                            ║
║       Sessions                      [N]                                    ║
║       Context rotations             [N]                                    ║
║       Autopilot tasks               [N] / [total]                          ║
║       Manual interventions          [N]                                    ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║              ▲ ▲ ▲   YOU REACHED THE PEAK   ▲ ▲ ▲                          ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

     ▲ ▲ ▲  ───────────────  apex · peak protocol · v7  ───────────────  ▲ ▲ ▲
```

---

## 16. COMPOSITION RULES

### R1  Every user-facing output MUST use a framed element or heavy divider
Never output bare text. The minimum is a signature line at the bottom.

### R2  Hero moments use the MEGA frame
- `/apex:start` → Project Init Banner (section 5)
- `/apex:status` → Cockpit Dashboard (section 6)
- `/apex:resume` → Context Rotation (section 8.C) + status bar
- Phase complete → Phase Transition (section 8.A)
- Phase begin → Phase Transition (section 8.B)
- Autopilot enable → Autopilot Transformation (section 9)
- Autopilot advisor → Advisor Briefing (section 10)
- Project complete → Project Complete Ceremony (section 15)

### R3  Critic verdicts use STANDARD frame verdict cards
Every PASS / PARTIAL / FAIL / BLOCKED from critic must be shown in its verdict card (section 7). Never plain text.

### R4  Autopilot badge appears on EVERY output when autopilot is enabled
Place the active/paused badge from section 9 at the top of the output, below the status bar.

### R5  Icons are canonical
`✓` is PASS. Not `✔`, not `✅`, not `done`.
`▲` is APEX. Not `△`, not `▴`.
`◐` is PARTIAL. Not `◑`, not `half`.

### R6  Frame widths are fixed
- MEGA    = 78 chars total
- STANDARD = 68 chars total
Never deviate. Content must match.

### R7  No emojis inside fixed-width frames
Emojis (🟢 🤖 ✨) are 2-cell wide in most monospaces and break alignment.
Use Unicode single-cell glyphs (`●` `○` `◆` `▲`) inside frames.
Use emojis freely OUTSIDE frames (status bars, signature lines, inline messages).

### R8  Progress bars are exactly 20 characters wide
Exception: dashboard dual-bars can be 20 (Productive) and 20 (Overhead) to align.

### R9  Indent rhythm inside frames
- 4 spaces from `║` to first content char for section content
- 7 spaces for sub-items
- 10 spaces for nested sub-items

### R10  The signature line is the final element of every hero output
```
     ▲ ▲ ▲  ───────────────  apex · peak protocol · v7  ───────────────  ▲ ▲ ▲
```

### R11  Three motifs, one brand
- SUMMIT (▲) for journey moments (start, phase transitions, context rotation)
- NEXUS (●━●) for connection moments (task progress, dependencies)
- PRISM (◆◈◇) for quality moments (verdicts, advisor, ceremonies)
Never mix more than 2 motifs in a single output.

### R12  Hebrew text placement
Hebrew text is permitted in prose sections between frames, never inside frames or mixed with LTR paths/identifiers.

### R13  Every Task() invocation is wrapped in Briefing and Recorder
Every `Task(...)` call in next.md MUST be preceded by Section 10-B (Mission Briefing) and followed by Section 10-C (Flight Recorder). The agent is never a black box — the user always sees who is about to work, and what they did.

### R14  Every /apex:next output begins with Ambient Header
The first elements in any /apex:next output (after the status bar) are Section 10-D (Ambient Timeline) and Section 10-E (Live Ticker), stacked. This gives the user instant orientation: what happened, what's next.

### R15  Identity Cards anchor agent visibility
Section 10-A Identity Cards are rendered inside Mission Briefings (as the "Agent" line) and may be rendered standalone in the Cockpit Dashboard. Each agent has exactly one canonical card — never substitute icons.

---

## FINAL

APEX is the first CLI framework with a cinematic visual identity.
Every output is a moment. Every moment is branded. Every brand element serves information density.

**Peak Protocol is not decoration — it is the interface.**

     ▲ ▲ ▲  ───────────────  apex · peak protocol · v7  ───────────────  ▲ ▲ ▲