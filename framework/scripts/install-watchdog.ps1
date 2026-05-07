#requires -Version 5.1
<#
.SYNOPSIS
  Install / uninstall the APEX external watchdog as a Windows Scheduled Task.

.DESCRIPTION
  Friendly installer for non-technical APEX users. Creates a Scheduled Task that
  runs apex-watchdog.ps1 -Mode monitor at user logon, with the user's APEX
  project as the target. Also writes %USERPROFILE%\.claude\watchdog-config.json.

  Pre-flight checks (per plan section 4 insight Vav):
    - Are we on Windows? (yes / abort)
    - Is the project path an APEX project? (.apex/ exists)
    - Is Task Scheduler available?
    - Is apex-watchdog.ps1 in the same folder as this installer?

.PARAMETER Mode
  install   - Create the Scheduled Task (default).
  uninstall - Remove the Scheduled Task and the config file.
  status    - Show whether the task is installed.

.PARAMETER ProjectPath
  Absolute path to the APEX project. REQUIRED for install.

.PARAMETER ThresholdMB
  Memory threshold in MB. Default 2048 (matches CONTEXT_BUDGET default).

.PARAMETER IntervalSeconds
  Sample interval. Default 30.

.PARAMETER GracePeriodSeconds
  Seconds the watchdog waits after requesting a graceful pause before
  force-killing Claude Code. Default 60.

.PARAMETER NoRespawn
  Pass through to apex-watchdog.ps1: do not auto-spawn Claude Code after exit.

.PARAMETER DryRun
  Print what would happen without actually creating the task.

.EXAMPLE
  pwsh -File install-watchdog.ps1 -Mode install -ProjectPath "C:\my\apex\project"

.EXAMPLE
  pwsh -File install-watchdog.ps1 -Mode uninstall

.NOTES
  Requires:
    - Windows 10+
    - PowerShell 5.1+ (built-in)
    - User-level Scheduled Task permissions (no admin needed for tasks under
      Task Scheduler\Tasks\ApexWatchdog at the user-context level)
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [ValidateSet('install', 'uninstall', 'status')]
  [string]$Mode = 'install',

  [Parameter(Mandatory = $false)]
  [string]$ProjectPath = '',

  [Parameter(Mandatory = $false)]
  [int]$ThresholdMB = 2048,

  [Parameter(Mandatory = $false)]
  [int]$IntervalSeconds = 30,

  [Parameter(Mandatory = $false)]
  [int]$GracePeriodSeconds = 60,

  [Parameter(Mandatory = $false)]
  [switch]$NoRespawn,

  [Parameter(Mandatory = $false)]
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$TaskName = 'ApexWatchdog'
$ConfigDir = Join-Path $env:USERPROFILE '.claude'
$ConfigFile = Join-Path $ConfigDir 'watchdog-config.json'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WatchdogScript = Join-Path $ScriptDir 'apex-watchdog.ps1'

function Test-Preflight {
  $issues = @()
  if (-not $IsWindows -and $env:OS -ne 'Windows_NT') {
    $issues += 'Watchdog is Windows-only. Detected non-Windows OS.'
  }
  if (-not (Test-Path $WatchdogScript)) {
    $issues += "apex-watchdog.ps1 not found at $WatchdogScript. Make sure both scripts are in the same folder."
  }
  $hasTaskCmd = Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue
  if (-not $hasTaskCmd) {
    $issues += 'Get-ScheduledTask cmdlet missing. Install Windows ScheduledTasks module or use Task Scheduler GUI manually.'
  }
  return $issues
}

function Ensure-ProjectPath {
  param([string]$Path)
  if (-not $Path) {
    Write-Host 'ERROR: -ProjectPath is required.' -ForegroundColor Red
    Write-Host 'Example: install-watchdog.ps1 -Mode install -ProjectPath "C:\my\apex\project"'
    return $false
  }
  if (-not (Test-Path $Path)) {
    Write-Host "ERROR: ProjectPath does not exist: $Path" -ForegroundColor Red
    return $false
  }
  $apexDir = Join-Path $Path '.apex'
  if (-not (Test-Path $apexDir)) {
    Write-Host "ERROR: $Path is not an APEX project (.apex/ missing). Run /apex:start or /apex:onboard first." -ForegroundColor Red
    return $false
  }
  return $true
}

function Write-WatchdogConfig {
  param([string]$Path, [int]$ThreshMB, [int]$Interval, [int]$Grace, [bool]$Respawn)
  if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
  }
  $cfg = @{
    project_path         = $Path
    threshold_mb         = $ThreshMB
    interval_seconds     = $Interval
    grace_period_seconds = $Grace
    process_name_pattern = @('claude', 'bun')
    auto_respawn         = $Respawn
    claude_executable    = 'claude.exe'
  }
  $cfg | ConvertTo-Json -Depth 4 | Set-Content -Path $ConfigFile -Encoding UTF8
  Write-Host "Wrote config: $ConfigFile"
}

function Install-Watchdog {
  $issues = Test-Preflight
  if ($issues.Count -gt 0) {
    Write-Host 'Pre-flight checks failed:' -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  - $_" }
    exit 1
  }
  if (-not (Ensure-ProjectPath -Path $ProjectPath)) {
    exit 1
  }

  Write-Host ''
  Write-Host 'APEX Watchdog Installer' -ForegroundColor Cyan
  Write-Host '======================='
  Write-Host "Project path:       $ProjectPath"
  Write-Host "Memory threshold:   $ThresholdMB MB"
  Write-Host "Sample interval:    $IntervalSeconds s"
  Write-Host "Grace period:       $GracePeriodSeconds s"
  Write-Host "Auto-respawn:       $(-not $NoRespawn)"
  Write-Host ''

  if ($DryRun) {
    Write-Host '[DryRun] Would write config and create scheduled task. Stopping here.' -ForegroundColor Yellow
    return
  }

  Write-WatchdogConfig -Path $ProjectPath -ThreshMB $ThresholdMB -Interval $IntervalSeconds -Grace $GracePeriodSeconds -Respawn (-not $NoRespawn)

  $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
  if ($existing) {
    Write-Host "Existing scheduled task '$TaskName' found. Updating in place."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
  }

  $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$WatchdogScript`" -Mode monitor"
  $trigger = New-ScheduledTaskTrigger -AtLogOn
  $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
  $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
  Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description 'APEX Auto-Continuity Layer D - external watchdog for Claude Code memory-pressure safety.'

  Write-Host ''
  Write-Host "Installation complete." -ForegroundColor Green
  Write-Host ''
  Write-Host 'Verify with:'
  Write-Host "  Get-ScheduledTask -TaskName $TaskName"
  Write-Host '  pwsh -File install-watchdog.ps1 -Mode status'
  Write-Host ''
  Write-Host 'The watchdog will start automatically at next user logon. To start it'
  Write-Host 'immediately without rebooting:'
  Write-Host "  Start-ScheduledTask -TaskName $TaskName"
  Write-Host ''
  Write-Host 'To uninstall:'
  Write-Host '  pwsh -File install-watchdog.ps1 -Mode uninstall'
}

function Uninstall-Watchdog {
  Write-Host ''
  Write-Host 'APEX Watchdog Uninstaller' -ForegroundColor Cyan
  Write-Host '========================='
  $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
  if ($existing) {
    if ($DryRun) {
      Write-Host "[DryRun] Would unregister scheduled task '$TaskName'." -ForegroundColor Yellow
    } else {
      Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
      Write-Host "Removed scheduled task '$TaskName'."
    }
  } else {
    Write-Host "No scheduled task '$TaskName' found - nothing to remove."
  }

  if (Test-Path $ConfigFile) {
    if ($DryRun) {
      Write-Host "[DryRun] Would delete $ConfigFile." -ForegroundColor Yellow
    } else {
      Remove-Item -Path $ConfigFile -Force
      Write-Host "Removed $ConfigFile"
    }
  }

  Write-Host ''
  Write-Host 'Uninstall complete. APEX itself is unaffected - the in-process'
  Write-Host 'memory-watchdog and turn-checkpoint hooks continue to operate.' -ForegroundColor Green
}

function Show-Status {
  Write-Host ''
  Write-Host 'APEX Watchdog Status' -ForegroundColor Cyan
  Write-Host '===================='
  $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
  if ($existing) {
    Write-Host "Scheduled task:    $($existing.State) (TaskName: $TaskName)"
    $info = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($info) {
      Write-Host "Last run:          $($info.LastRunTime)"
      Write-Host "Last result:       0x$('{0:X}' -f $info.LastTaskResult)"
      Write-Host "Next scheduled:    $($info.NextRunTime)"
    }
  } else {
    Write-Host "Scheduled task:    NOT INSTALLED"
  }
  if (Test-Path $ConfigFile) {
    Write-Host "Config file:       $ConfigFile"
    $cfg = Get-Content $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Host "  project_path:    $($cfg.project_path)"
    Write-Host "  threshold_mb:    $($cfg.threshold_mb)"
    Write-Host "  interval_s:      $($cfg.interval_seconds)"
    Write-Host "  grace_s:         $($cfg.grace_period_seconds)"
    Write-Host "  auto_respawn:    $($cfg.auto_respawn)"
  } else {
    Write-Host "Config file:       NOT FOUND"
  }
}

# ---------- Dispatch ----------
switch ($Mode) {
  'install'   { Install-Watchdog }
  'uninstall' { Uninstall-Watchdog }
  'status'    { Show-Status }
  default     { Write-Host "Unknown mode: $Mode" -ForegroundColor Red; exit 1 }
}
