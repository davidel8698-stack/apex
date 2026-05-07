#requires -Version 5.1
<#
.SYNOPSIS
  APEX Auto-Continuity Layer D -- external Windows watchdog for Claude Code.

.DESCRIPTION
  Monitors the Claude Code (Bun) process from outside, surviving any in-process
  crash including OOM. When memory exceeds the configured threshold, requests a
  graceful pause via .apex/SHUTDOWN_REQUEST.flag (the in-process /apex:next Step
  F.4 will consume this flag and run /apex:pause cleanly). When the Claude Code
  process exits -- whether by graceful pause, crash, or explicit user-quit -- the
  watchdog logs the event and (optionally) respawns Claude Code in the project
  directory with `--resume-apex` semantics.

  Designed as the OUTERMOST safety layer of APEX Auto-Continuity. APEX itself
  works without it; this layer adds true crash-survival to the picture.

  Read the full design rationale in:
    framework/scripts/README-watchdog.md
    framework/commands/apex/self-heal.md (plan Sec 1, Layer D)

.PARAMETER Mode
  install   -- Register a Windows Scheduled Task to run this script at logon.
  uninstall -- Remove the scheduled task.
  status    -- Show current status (PID being monitored, last sample, etc.).
  monitor   -- Run the monitoring loop in the foreground (default when scheduled).
  sample    -- One-shot: print a memory sample for the current Claude Code PID.

.PARAMETER ProjectPath
  Absolute path to the APEX project directory containing .apex/. Defaults to
  the value in $env:USERPROFILE\.claude\watchdog-config.json or the current dir.

.PARAMETER ThresholdMB
  Memory threshold in MB. When PrivateMemorySize64 exceeds this for 3 consecutive
  samples, the watchdog requests a graceful pause. Default 2048 (matches the
  default in framework/CONTEXT_BUDGET.default.json#auto_continuity).

.PARAMETER IntervalSeconds
  Seconds between samples. Default 30.

.PARAMETER GracePeriodSeconds
  After requesting a graceful pause, how long to wait before force-killing
  Claude Code. Default 60.

.PARAMETER NoRespawn
  Skip auto-respawn after Claude Code exits. By default, the watchdog tries to
  spawn `claude` in $ProjectPath after a clean exit so the SessionStart auto-resume
  hook can pick up where the previous session left off.

.PARAMETER DryRun
  In install mode, print what would happen without creating the scheduled task.

.EXAMPLE
  # Install the watchdog as a Windows Scheduled Task that runs at logon
  pwsh -File apex-watchdog.ps1 -Mode install -ProjectPath "C:\path\to\my-apex-project"

.EXAMPLE
  # Run the monitor loop in the foreground (for debugging)
  pwsh -File apex-watchdog.ps1 -Mode monitor -ProjectPath "C:\path\to\my-apex-project"

.NOTES
  Compatibility: Windows PowerShell 5.1+ (default Windows 10/11). PowerShell 7+
  also works. Avoids any feature unique to PS7 (no Stop-Process -Signal, no
  null-coalescing, no ternary).

  ABSOLUTELY-NEVER LIST (per plan Sec 3 #15):
    - Never edits APEX state files (STATE.json, event-log.jsonl) directly.
    - Never deletes .apex/ files.
    - Never invokes /apex:* commands itself.
    - Only writes flag files inside .apex/ (SHUTDOWN_REQUEST.flag) or its own
      log file in $env:USERPROFILE\.claude\watchdog.log.
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [ValidateSet('install', 'uninstall', 'status', 'monitor', 'sample')]
  [string]$Mode = 'monitor',

  [Parameter(Mandatory = $false)]
  [string]$ProjectPath = '',

  [Parameter(Mandatory = $false)]
  [int]$ThresholdMB = 0,

  [Parameter(Mandatory = $false)]
  [int]$IntervalSeconds = 0,

  [Parameter(Mandatory = $false)]
  [int]$GracePeriodSeconds = 0,

  [Parameter(Mandatory = $false)]
  [switch]$NoRespawn,

  [Parameter(Mandatory = $false)]
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# ---------- Config & defaults ----------
$ConfigDir = Join-Path $env:USERPROFILE '.claude'
$ConfigFile = Join-Path $ConfigDir 'watchdog-config.json'
$LogFile = Join-Path $ConfigDir 'watchdog.log'
$TaskName = 'ApexWatchdog'

function Get-Defaults {
  $d = @{
    project_path        = ''
    threshold_mb        = 2048
    interval_seconds    = 30
    grace_period_seconds = 60
    process_name_pattern = @('claude', 'bun')
    auto_respawn        = $true
    claude_executable   = 'claude.exe'
  }
  if (Test-Path $ConfigFile) {
    try {
      $cfg = Get-Content $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
      foreach ($k in $cfg.PSObject.Properties.Name) { $d[$k] = $cfg.$k }
    } catch {
      Write-Host "WARN: failed to read config $ConfigFile -- using defaults"
    }
  }
  if ($ProjectPath)        { $d.project_path = $ProjectPath }
  if ($ThresholdMB -gt 0)  { $d.threshold_mb = $ThresholdMB }
  if ($IntervalSeconds -gt 0) { $d.interval_seconds = $IntervalSeconds }
  if ($GracePeriodSeconds -gt 0) { $d.grace_period_seconds = $GracePeriodSeconds }
  if ($NoRespawn)          { $d.auto_respawn = $false }
  return $d
}

function Write-WatchdogLog {
  param([string]$Level, [string]$Message)
  $ts = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
  $line = "$ts [$Level] $Message"
  if (-not (Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null }
  Add-Content -Path $LogFile -Value $line -Encoding UTF8
  Write-Host $line
}

function Get-ClaudePid {
  param([string[]]$NamePatterns)
  $candidates = @()
  foreach ($n in $NamePatterns) {
    $procs = Get-Process -Name $n -ErrorAction SilentlyContinue
    if ($procs) { $candidates += $procs }
  }
  if (-not $candidates) { return $null }
  # Pick the candidate with the largest PrivateMemorySize64 -- that is the
  # most-likely-to-OOM process (Bun runtime hosting Claude Code).
  $top = $candidates | Sort-Object PrivateMemorySize64 -Descending | Select-Object -First 1
  return $top
}

function Sample-Memory {
  param($Process)
  if (-not $Process) { return $null }
  try {
    $Process.Refresh()
    $rssMB = [int]($Process.WorkingSet64 / 1MB)
    $pmMB  = [int]($Process.PrivateMemorySize64 / 1MB)
    return @{
      pid     = $Process.Id
      name    = $Process.ProcessName
      rss_mb  = $rssMB
      pm_mb   = $pmMB
      ts      = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
    }
  } catch {
    return $null
  }
}

function Request-GracefulPause {
  param([string]$ApexDir, [string]$Reason, $Sample)
  $flag = Join-Path $ApexDir 'SHUTDOWN_REQUEST.flag'
  if (Test-Path $flag) {
    Write-WatchdogLog 'INFO' "SHUTDOWN_REQUEST.flag already exists at $flag -- not overwriting"
    return
  }
  $body = @"
REASON: $Reason
SOURCE: apex-watchdog.ps1
TS: $($Sample.ts)
PID: $($Sample.pid)
PROCESS: $($Sample.name)
RSS_MB: $($Sample.rss_mb)
PM_MB: $($Sample.pm_mb)
NOTE: External watchdog requested graceful pause. /apex:next Step F.4 will
      consume this flag and run /apex:pause. After grace period, the watchdog
      may force-kill the process -- but normally /apex:pause completes first.
"@
  Set-Content -Path $flag -Value $body -Encoding UTF8
  Write-WatchdogLog 'WARN' "Wrote $flag (PM=$($Sample.pm_mb)MB, threshold trip)"
}

function Invoke-Monitor {
  $cfg = Get-Defaults
  if (-not $cfg.project_path -or -not (Test-Path $cfg.project_path)) {
    Write-WatchdogLog 'ERROR' "project_path missing or invalid: $($cfg.project_path). Run: -Mode install -ProjectPath <abs>"
    exit 1
  }
  $apexDir = Join-Path $cfg.project_path '.apex'
  if (-not (Test-Path $apexDir)) {
    Write-WatchdogLog 'ERROR' ".apex directory missing in $($cfg.project_path) -- not an APEX project."
    exit 1
  }
  Write-WatchdogLog 'INFO' "Watchdog start: project=$($cfg.project_path) threshold=$($cfg.threshold_mb)MB interval=$($cfg.interval_seconds)s grace=$($cfg.grace_period_seconds)s"

  $consecOver = 0
  $pauseRequested = $false
  $pauseRequestedAt = $null
  $lastPid = 0
  $forceKilled = $false

  while ($true) {
    $proc = Get-ClaudePid -NamePatterns $cfg.process_name_pattern
    if (-not $proc) {
      if ($lastPid -ne 0) {
        Write-WatchdogLog 'INFO' "Claude Code (PID $lastPid) exited."
        if ($cfg.auto_respawn -and -not $forceKilled) {
          Start-ClaudeRespawn -Cfg $cfg
        }
        $lastPid = 0
        $consecOver = 0
        $pauseRequested = $false
        $pauseRequestedAt = $null
        $forceKilled = $false
      }
      Start-Sleep -Seconds $cfg.interval_seconds
      continue
    }

    if ($proc.Id -ne $lastPid) {
      Write-WatchdogLog 'INFO' "Tracking PID $($proc.Id) ($($proc.ProcessName))"
      $lastPid = $proc.Id
      $consecOver = 0
      $pauseRequested = $false
      $pauseRequestedAt = $null
      $forceKilled = $false
    }

    $sample = Sample-Memory -Process $proc
    if (-not $sample) {
      Start-Sleep -Seconds $cfg.interval_seconds
      continue
    }

    if ($sample.pm_mb -ge $cfg.threshold_mb) {
      $consecOver++
    } else {
      $consecOver = 0
      $pauseRequested = $false
      $pauseRequestedAt = $null
    }

    # Three consecutive samples over threshold -> request pause
    if ($consecOver -ge 3 -and -not $pauseRequested) {
      Request-GracefulPause -ApexDir $apexDir -Reason 'external_watchdog_memory' -Sample $sample
      $pauseRequested = $true
      $pauseRequestedAt = Get-Date
    }

    # If pause was requested but process still alive after grace period -- force kill
    if ($pauseRequested -and $pauseRequestedAt) {
      $elapsed = (Get-Date) - $pauseRequestedAt
      if ($elapsed.TotalSeconds -gt $cfg.grace_period_seconds) {
        Write-WatchdogLog 'WARN' "Grace period of $($cfg.grace_period_seconds)s expired. Force-killing PID $($proc.Id)."
        try { Stop-Process -Id $proc.Id -Force -ErrorAction Stop } catch { Write-WatchdogLog 'ERROR' "Force-kill failed: $_" }
        $forceKilled = $true
      }
    }

    Start-Sleep -Seconds $cfg.interval_seconds
  }
}

function Start-ClaudeRespawn {
  param($Cfg)
  if (-not $Cfg.claude_executable) {
    Write-WatchdogLog 'INFO' "Auto-respawn disabled (no claude_executable configured)."
    return
  }
  Write-WatchdogLog 'INFO' "Respawning Claude Code in $($Cfg.project_path) (executable: $($Cfg.claude_executable))"
  try {
    # Start detached so the watchdog doesn't own the new process
    Start-Process -FilePath $Cfg.claude_executable -WorkingDirectory $Cfg.project_path -WindowStyle Normal
  } catch {
    Write-WatchdogLog 'ERROR' "Respawn failed: $_"
  }
}

function Show-Status {
  $cfg = Get-Defaults
  Write-Host "APEX Watchdog Status"
  Write-Host "===================="
  Write-Host "Config file:    $ConfigFile"
  Write-Host "Log file:       $LogFile"
  Write-Host "Project path:   $($cfg.project_path)"
  Write-Host "Threshold:      $($cfg.threshold_mb) MB"
  Write-Host "Interval:       $($cfg.interval_seconds) s"
  Write-Host "Grace period:   $($cfg.grace_period_seconds) s"
  Write-Host "Auto-respawn:   $($cfg.auto_respawn)"
  Write-Host ""
  $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
  if ($task) {
    Write-Host "Scheduled task: $($task.State)"
  } else {
    Write-Host "Scheduled task: NOT INSTALLED"
  }
  Write-Host ""
  $proc = Get-ClaudePid -NamePatterns $cfg.process_name_pattern
  if ($proc) {
    $s = Sample-Memory -Process $proc
    Write-Host "Live process:   PID=$($s.pid) NAME=$($s.name) RSS=$($s.rss_mb)MB PM=$($s.pm_mb)MB"
  } else {
    Write-Host "Live process:   (none -- Claude Code not running)"
  }
}

function Show-OneShotSample {
  $cfg = Get-Defaults
  $proc = Get-ClaudePid -NamePatterns $cfg.process_name_pattern
  if (-not $proc) { Write-Host "No claude/bun process found."; return }
  $s = Sample-Memory -Process $proc
  Write-Host ("PID={0} NAME={1} RSS={2}MB PM={3}MB" -f $s.pid, $s.name, $s.rss_mb, $s.pm_mb)
}

# Install/uninstall logic lives in install-watchdog.ps1 -- direct users there.
function Show-InstallHint {
  param([string]$Action)
  Write-Host "Use install-watchdog.ps1 for $Action operations:"
  Write-Host "  pwsh -File install-watchdog.ps1 -Mode $Action -ProjectPath <path>"
}

# ---------- Dispatch ----------
switch ($Mode) {
  'install'   { Show-InstallHint -Action 'install'; exit 0 }
  'uninstall' { Show-InstallHint -Action 'uninstall'; exit 0 }
  'status'    { Show-Status; exit 0 }
  'sample'    { Show-OneShotSample; exit 0 }
  'monitor'   { Invoke-Monitor }
  default     { Write-Host "Unknown mode: $Mode"; exit 1 }
}
