#!/bin/bash
# _require-platform-detect.sh — OS detection + cross-platform Bun/Claude Code
# memory sampling helpers for the Auto-Continuity Layer (v7.1).
#
# Sourced by hooks that need to read process memory in a portable way:
#   - memory-watchdog.sh (PostToolUse:Bash)
#
# Exposes:
#   detect_apex_platform                — sets APEX_PLATFORM=windows|macos|linux|unknown
#   sample_bun_memory_mb                — echoes "<rss_mb> <commit_mb>" for the
#                                          ancestor Bun/Claude Code process, or
#                                          "0 0" with stderr warning on failure.
#                                          Always exits 0 (fail-soft, never blocks).
#
# Design contract:
#   • Never block (always exit 0)
#   • fail-loud-and-skip: print one warning line on failure, then return zeros
#   • Sample is best-effort; one missed reading is not a crisis
#   • Throttle is the caller's job (memory-watchdog.sh decides cadence)

# --- detect_apex_platform ---
# Sets APEX_PLATFORM env var. Idempotent — safe to call repeatedly.
detect_apex_platform() {
  if [ -n "${APEX_PLATFORM:-}" ]; then
    return 0
  fi
  case "$(uname -s 2>/dev/null || echo unknown)" in
    Linux*)             APEX_PLATFORM="linux" ;;
    Darwin*)            APEX_PLATFORM="macos" ;;
    MINGW*|MSYS*|CYGWIN*|Windows_NT) APEX_PLATFORM="windows" ;;
    *)                  APEX_PLATFORM="unknown" ;;
  esac
  # Git-Bash on Windows reports MINGW64 — the case above catches it.
  # Claude Code's Bun on Windows runs under MINGW; verify with $OS for safety.
  if [ "${OS:-}" = "Windows_NT" ]; then
    APEX_PLATFORM="windows"
  fi
  export APEX_PLATFORM
}

# --- find_bun_ancestor_pid ---
# Walk up the process tree looking for a `bun` or `claude` ancestor.
# Falls back to PPID if no match found (still useful — at least samples *some*
# parent process). Echoes the PID; returns 0 on success.
find_bun_ancestor_pid() {
  local pid="${PPID:-$$}"
  local hop=0
  local max_hops=12
  detect_apex_platform
  while [ "$hop" -lt "$max_hops" ] && [ -n "$pid" ] && [ "$pid" != "0" ] && [ "$pid" != "1" ]; do
    local pname=""
    case "$APEX_PLATFORM" in
      linux)
        if [ -r "/proc/$pid/comm" ]; then
          pname=$(cat "/proc/$pid/comm" 2>/dev/null | tr '[:upper:]' '[:lower:]')
        fi
        ;;
      macos|linux)
        # ps fallback (works on both macOS and Linux)
        if [ -z "$pname" ]; then
          pname=$(ps -p "$pid" -o comm= 2>/dev/null | tr '[:upper:]' '[:lower:]' | xargs basename 2>/dev/null)
        fi
        ;;
      windows)
        # On Git-Bash, $PPID is MSYS-internal and not visible to PowerShell.
        # We instead delegate the search to PowerShell — which scans for the
        # claude/bun process by name. One PowerShell call total, not per-hop.
        # Echo "WINDOWS_DELEGATE" — sample_bun_memory_mb interprets this as
        # "find by name in PowerShell".
        echo "WINDOWS_DELEGATE"
        return 0
        ;;
    esac
    case "$pname" in
      bun*|claude*|node*)
        echo "$pid"
        return 0
        ;;
    esac
    # Walk up
    case "$APEX_PLATFORM" in
      linux)
        if [ -r "/proc/$pid/status" ]; then
          pid=$(awk '/^PPid:/ {print $2}' "/proc/$pid/status" 2>/dev/null)
        else
          break
        fi
        ;;
      macos)
        pid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ')
        ;;
      *)
        break
        ;;
    esac
    hop=$((hop + 1))
  done
  # Fallback: return original PPID
  echo "${PPID:-$$}"
  return 0
}

# --- sample_bun_memory_mb ---
# Echoes "<rss_mb> <commit_mb>" rounded down to integers. On Linux/macOS,
# commit_mb may equal rss_mb (no separate commit metric available without
# /proc/<pid>/status VmSize). On Windows, commit_mb reports PrivateMemorySize64
# (the OOM-relevant metric per the Bun crash post-mortem).
#
# On any failure, echoes "0 0" and prints one warning line to stderr.
sample_bun_memory_mb() {
  detect_apex_platform
  local pid
  pid=$(find_bun_ancestor_pid)
  if [ -z "$pid" ] || [ "$pid" = "0" ]; then
    echo "0 0"
    return 0
  fi
  local rss_mb=0 commit_mb=0
  case "$APEX_PLATFORM" in
    linux)
      if [ -r "/proc/$pid/status" ]; then
        local vmrss vmsize
        vmrss=$(awk '/^VmRSS:/ {print $2}' "/proc/$pid/status" 2>/dev/null)
        vmsize=$(awk '/^VmSize:/ {print $2}' "/proc/$pid/status" 2>/dev/null)
        # Both are in KB
        if [ -n "$vmrss" ]; then rss_mb=$((vmrss / 1024)); fi
        if [ -n "$vmsize" ]; then commit_mb=$((vmsize / 1024)); fi
      else
        echo "0 0"
        return 0
      fi
      ;;
    macos)
      # ps -o rss returns KB
      local vmrss
      vmrss=$(ps -p "$pid" -o rss= 2>/dev/null | tr -d ' ')
      if [ -n "$vmrss" ]; then
        rss_mb=$((vmrss / 1024))
        commit_mb=$rss_mb  # macOS has no easy commit metric without vm_stat parsing
      else
        echo "0 0"
        return 0
      fi
      ;;
    windows)
      # Single PowerShell call — outputs "<workingset_mb> <private_mb>".
      # When pid == "WINDOWS_DELEGATE" we search by name (claude/bun) and pick
      # the largest by PrivateMemorySize64 (the OOM-relevant metric).
      local out
      if [ "$pid" = "WINDOWS_DELEGATE" ] || [ -z "$pid" ] || [ "$pid" = "0" ]; then
        out=$(powershell.exe -NoLogo -NoProfile -Command "
\$ErrorActionPreference='SilentlyContinue';
\$candidates = Get-Process -Name claude,bun -ErrorAction SilentlyContinue;
if (-not \$candidates) {
  Write-Output '0 0';
} else {
  \$p = \$candidates | Sort-Object PrivateMemorySize64 -Descending | Select-Object -First 1;
  \$ws = [int](\$p.WorkingSet64 / 1MB);
  \$pm = [int](\$p.PrivateMemorySize64 / 1MB);
  Write-Output \"\$ws \$pm\";
}
" 2>/dev/null)
      else
        out=$(powershell.exe -NoLogo -NoProfile -Command "
\$ErrorActionPreference='SilentlyContinue';
\$p = Get-Process -Id $pid 2>\$null;
if (\$p) {
  \$ws = [int](\$p.WorkingSet64 / 1MB);
  \$pm = [int](\$p.PrivateMemorySize64 / 1MB);
  Write-Output \"\$ws \$pm\";
} else {
  Write-Output '0 0';
}
" 2>/dev/null)
      fi
      out=$(printf '%s' "$out" | tr -d '\r' | head -1)
      if [ -n "$out" ]; then
        rss_mb=$(printf '%s' "$out" | awk '{print $1}')
        commit_mb=$(printf '%s' "$out" | awk '{print $2}')
        rss_mb=${rss_mb:-0}
        commit_mb=${commit_mb:-0}
      else
        echo "⚠️ memory-watchdog: PowerShell sample failed for PID $pid (continuing)" >&2
        echo "0 0"
        return 0
      fi
      ;;
    *)
      echo "⚠️ memory-watchdog: unsupported platform '$APEX_PLATFORM' (sampling disabled)" >&2
      echo "0 0"
      return 0
      ;;
  esac
  echo "$rss_mb $commit_mb"
  return 0
}
