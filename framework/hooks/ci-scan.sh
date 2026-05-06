#!/bin/bash
set -u
# CI supply-chain vector scanner — defense-in-depth layer
# Hook type: Auto-PostToolUse (Write|Edit, self-filtered to .github/workflows/*) [R5-010]
#            Also retains command-invoked usage (CI pipeline / manual sweep).
#
# Scans .github/workflows/*.yml for known CI supply-chain vectors.
# Exit 2 = vectors found, Exit 0 = clean or path outside .github/workflows/
# or no workflows directory.
#
# Path-filter contract (R5-010): Claude Code's PostToolUse matcher is
# tool-name level (Write|Edit), not path-level. So when invoked from
# settings.json this hook receives the touched path on stdin (Claude
# Code hook protocol) or as $1; if it does not begin with
# `.github/workflows/`, exit 0 fast. The detection logic below is
# preserved byte-for-byte from the manual-invocation era.

source "$(dirname "$0")/_security-common.sh"

# --- R5-010: Path-filter early-exit for auto-PostToolUse invocation ---
# When invoked from settings.json the hook receives a JSON payload on
# stdin describing the tool call. We support three invocation shapes:
#   1) Auto-PostToolUse: stdin = JSON like {"tool_input":{"file_path":"..."}}
#      → if file_path is outside .github/workflows/, exit 0.
#   2) Direct command-invocation with explicit dir: bash ci-scan.sh path/
#      → scan that dir.
#   3) Default (no arg, no stdin): scan .github/workflows/.
#
# Note: under shape (2), if $1 is a *file* path (e.g., a touched
# workflow), we treat its parent dir as the scan target.
WORKFLOWS_DIR=""
if [ -p /dev/stdin ] || [ ! -t 0 ]; then
  # stdin is piped — try to parse Claude Code hook payload.
  STDIN_BUF=$(cat 2>/dev/null || true)
  if [ -n "$STDIN_BUF" ] && command -v jq >/dev/null 2>&1; then
    HOOK_PATH=$(echo "$STDIN_BUF" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)
    if [ -n "$HOOK_PATH" ]; then
      # Auto-PostToolUse path: enforce self-filter. Only scan workflow files.
      case "$HOOK_PATH" in
        .github/workflows/*|*/.github/workflows/*)
          # Scan the parent directory of the touched file.
          WORKFLOWS_DIR="$(dirname "$HOOK_PATH")"
          ;;
        *)
          # Path is outside .github/workflows/ — fast exit, do not scan.
          exit 0
          ;;
      esac
    fi
  fi
fi

# Fall through to argv / default if stdin parsing did not set WORKFLOWS_DIR.
if [ -z "$WORKFLOWS_DIR" ]; then
  ARG="${1:-.github/workflows}"
  if [ -f "$ARG" ]; then
    # Treat a file argument as "scan its parent dir" for parity with the
    # auto-PostToolUse path. Self-filter still applies.
    case "$ARG" in
      .github/workflows/*|*/.github/workflows/*)
        WORKFLOWS_DIR="$(dirname "$ARG")"
        ;;
      *)
        exit 0
        ;;
    esac
  else
    WORKFLOWS_DIR="$ARG"
  fi
fi

if [ ! -d "$WORKFLOWS_DIR" ]; then
  # No workflows directory — nothing to scan
  exit 0
fi

FINDINGS=()

for yml_file in "$WORKFLOWS_DIR"/*.yml "$WORKFLOWS_DIR"/*.yaml; do
  [ -f "$yml_file" ] || continue

  # --- Unpinned GitHub Actions (no SHA commit hash) ---
  # Match: uses: owner/repo@v4  or  uses: owner/repo@main  (both block-scalar and list-item forms)
  # Skip: uses: owner/repo@<40-char-hex> (pinned to SHA)
  # Skip: uses: ./local-action (local actions, both list and block form)
  if grep -nE '^\s*(-\s+)?uses:\s+[a-zA-Z]' "$yml_file" 2>/dev/null | grep -vE '@[0-9a-f]{40}' | grep -qvE '^\s*(-\s+)?uses:\s+\./' 2>/dev/null; then
    FINDINGS+=("UNPINNED ACTION in $yml_file — use full SHA commit hash instead of tag/branch")
  fi

  # --- Secret exposure in echo/run ---
  if grep -nE '(echo|printf|cat|>>)\s+.*\$\{\{\s*secrets\.' "$yml_file" 2>/dev/null | grep -qvE '#' 2>/dev/null; then
    FINDINGS+=("SECRET EXPOSURE in $yml_file — secrets echoed/logged in run step")
  fi

  # --- Overly permissive permissions ---
  if grep -qE '^\s*permissions:\s*write-all' "$yml_file" 2>/dev/null; then
    FINDINGS+=("WRITE-ALL PERMISSIONS in $yml_file — use least-privilege permissions")
  fi

  # --- pull_request_target without explicit ref pinning ---
  if grep -qE 'pull_request_target' "$yml_file" 2>/dev/null; then
    if ! grep -qE '(ref:|sha:|commit:)' "$yml_file" 2>/dev/null; then
      FINDINGS+=("UNSAFE pull_request_target in $yml_file — no explicit ref pinning")
    fi
  fi
done

if [ ${#FINDINGS[@]} -gt 0 ]; then
  echo "APEX CI SCAN: BLOCKED — ${#FINDINGS[@]} supply-chain vector(s) detected" >&2
  echo "" >&2
  for finding in "${FINDINGS[@]}"; do
    echo "  - $finding" >&2
  done
  echo "" >&2
  echo "Fix these issues before proceeding." >&2
  exit 2
fi

exit 0
