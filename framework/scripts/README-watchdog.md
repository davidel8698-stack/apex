# APEX External Watchdog (Auto-Continuity Layer D)

> **TL;DR (Hebrew):** סקריפט PowerShell שעובד ברקע, מנטר את Claude Code, מבקש pause לפני OOM, ופותח חלון חדש אם הוא מת. **רכיב אופציונלי** — APEX עובד גם בלעדיו.

The external watchdog is the **outermost** layer of APEX Auto-Continuity. It is
the only layer that can survive a true Bun runtime crash, because it runs in
a separate process. APEX itself works fine without it; the in-process layers
(memory-watchdog hook, turn-checkpoint hook, session-auto-resume hook) handle
the common cases. The external watchdog is for the long-tail "Bun OOM at 2am"
scenario.

---

## Quick Install (Windows 10+)

Open PowerShell, then:

```powershell
cd C:\path\to\APEX\framework\scripts
pwsh -File install-watchdog.ps1 -Mode install -ProjectPath "C:\path\to\my-apex-project"
```

That's it. The watchdog will start automatically at next user logon. To start
it immediately:

```powershell
Start-ScheduledTask -TaskName ApexWatchdog
```

To check status:

```powershell
pwsh -File install-watchdog.ps1 -Mode status
```

To uninstall:

```powershell
pwsh -File install-watchdog.ps1 -Mode uninstall
```

---

## What It Does

Every 30 seconds (configurable):

1. Find the Claude Code process by name (`claude` or `bun`).
2. Read its memory: `WorkingSet64` (RSS) and `PrivateMemorySize64` (Commit).
3. Compare commit to threshold (default 2048MB).
4. If commit exceeds threshold for 3 consecutive samples:
   - Write `.apex/SHUTDOWN_REQUEST.flag` in the project directory.
   - The next time `/apex:next` runs, its **Step F.4** consumes the flag and
     runs `/apex:pause` cleanly.
   - If Claude Code is unresponsive after 60 seconds (configurable
     "grace period"), force-kill it.
5. After Claude Code exits (graceful or forced):
   - Log to `%USERPROFILE%\.claude\watchdog.log`.
   - Spawn a new Claude Code session in the project directory (auto-respawn).
   - The new session's `SessionStart` hook (`session-auto-resume.sh`) detects
     `auto_paused = true` and emits a banner instructing Claude to invoke
     `/apex:resume` immediately.

The user sees no interruption beyond a brief window-close + window-open. All
state is preserved through `STATE.json`, `event-log.jsonl`, and
`TURN_CHECKPOINT.json`.

---

## Files Created

| Path | Purpose |
|------|---------|
| `%USERPROFILE%\.claude\watchdog-config.json` | Config: project path, threshold, intervals |
| `%USERPROFILE%\.claude\watchdog.log` | Watchdog event log (rotates manually if it grows large) |
| Scheduled Task: `ApexWatchdog` | At-logon trigger, runs `apex-watchdog.ps1 -Mode monitor` |
| `<project>\.apex\SHUTDOWN_REQUEST.flag` | Lazy-created on threshold trip; consumed by `/apex:next` Step F.4 |

---

## Configuration

Edit `%USERPROFILE%\.claude\watchdog-config.json` directly, or re-run the
installer with new values. Example:

```json
{
  "project_path": "C:\\path\\to\\my-apex-project",
  "threshold_mb": 2048,
  "interval_seconds": 30,
  "grace_period_seconds": 60,
  "process_name_pattern": ["claude", "bun"],
  "auto_respawn": true,
  "claude_executable": "claude.exe"
}
```

After editing, restart the task:

```powershell
Stop-ScheduledTask -TaskName ApexWatchdog
Start-ScheduledTask -TaskName ApexWatchdog
```

---

## Why a Separate Process?

When Bun OOMs, the entire Claude Code process dies. **No hook can fire** — the
hooks live inside the dying process. Only an external monitor can:

- Notice that Claude Code is gone.
- Spawn a fresh Claude Code session.
- Avoid the user having to manually re-open the window and type `/apex:resume`.

This is not a Bug-fix vs. apex-watchdog. It is the **outermost safety net**.
The in-process layers handle the *predictable* cases (memory growing slowly,
context filling up); the external watchdog handles the *catastrophic* cases
(OOM, hung process, lockup).

---

## Diagnostics

### One-shot memory sample

```powershell
pwsh -File apex-watchdog.ps1 -Mode sample
```

Prints `PID=N NAME=claude RSS=NMB PM=NMB` for the live Claude Code process.

### Tail the log

```powershell
Get-Content "$env:USERPROFILE\.claude\watchdog.log" -Tail 30 -Wait
```

### Run the monitor in foreground (debugging)

```powershell
pwsh -File apex-watchdog.ps1 -Mode monitor -ProjectPath "C:\my\apex\project"
```

Press `Ctrl+C` to stop.

---

## Limitations & Future Work

| Limitation | Workaround |
|-----------|-----------|
| Windows-only (PowerShell 5.1+) | Linux/macOS parity is planned for a future round (see plan section 9) |
| Cannot survive a Windows reboot mid-session | The Scheduled Task auto-runs at next user logon, so the next session starts auto-resumed |
| Watches one project at a time | Edit `watchdog-config.json` or run multiple instances under different task names |
| Does not see Claude Code processes started under a different user | By design - Scheduled Task runs as the installing user only |

---

## Uninstalling Cleanly

```powershell
pwsh -File install-watchdog.ps1 -Mode uninstall
```

This removes:

- The Scheduled Task `ApexWatchdog`
- The config file `%USERPROFILE%\.claude\watchdog-config.json`

It does NOT remove:

- The watchdog log (keep for forensics)
- Any APEX state files (`STATE.json`, `event-log.jsonl`, etc.)
- The in-process hooks - they're part of APEX itself and continue to operate

After uninstall, APEX continues to operate with its three in-process layers.
You lose only the OOM/crash safety net. To re-install, run install again.

---

## Hebrew Quick Reference

- **התקנה:** `pwsh -File install-watchdog.ps1 -Mode install -ProjectPath "C:\נתיב\לפרויקט"`
- **סטטוס:** `pwsh -File install-watchdog.ps1 -Mode status`
- **הסרה:** `pwsh -File install-watchdog.ps1 -Mode uninstall`
- **לוג:** `Get-Content "$env:USERPROFILE\.claude\watchdog.log" -Tail 30`

זה רכיב אופציונלי. APEX עובד גם בלעדיו - אבל בלעדיו, אם Bun קורס מ-OOM,
תצטרך לפתוח חלון חדש ולהקליד `/apex:resume` ידנית. עם ה-watchdog - הכל קורה
אוטומטית.
