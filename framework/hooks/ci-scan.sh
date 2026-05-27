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

# --- M19 / Phase 12.13: per-task debounce gate ---
#
# PostToolUse fires after every Write|Edit. Without a debounce the
# scanner re-runs on every file in a multi-file task even though only
# one of them is a workflow file (the path-filter exit below catches
# non-workflow files, but the gate-and-jq cost is still paid per call).
# This gate skips the re-scan when:
#   - APEX_CURRENT_TASK_ID is set (we have a task context to debounce
#     against — manual edits without a task context fall through to the
#     normal flow), AND
#   - the same task_id was already scanned recently (<60s window), AND
#   - the file-set being scanned has not changed since the last scan
#     (hashed list of currently-present workflow paths).
#
# Cap the debounce window at 60s to bound the multi-file vulnerability
# window — the silent_failure_risks[1] in PLAN_META.json task 12.13
# names "debounce too wide → multi-file vulnerability lands between
# scans" as the failure mode this cap mitigates.
#
# Atomic writes: rename-temp to avoid a half-written state file.
_apex_ci_scan_debounce() {
  local task_id="${APEX_CURRENT_TASK_ID:-}"
  [ -z "$task_id" ] && return 1
  command -v jq >/dev/null 2>&1 || return 1
  command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1 || return 1

  local repo_root=""
  if command -v git >/dev/null 2>&1; then
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
  fi
  [ -z "$repo_root" ] && repo_root="$(pwd)"
  [ -d "$repo_root/.apex" ] || return 1

  local state_file="$repo_root/.apex/.ci-scan-state.json"
  local now_iso
  now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "1970-01-01T00:00:00Z")
  local now_epoch
  now_epoch=$(date -u +"%s" 2>/dev/null || echo "0")

  # Compute current file-list hash (sorted list of workflow basenames
  # currently under the scan target). When the target directory does
  # not exist yet, hash the empty string so the gate still works.
  # Portable: avoid GNU-only `find -printf`.
  local file_list_hash
  local file_listing=""
  if [ -d "$repo_root/.github/workflows" ]; then
    file_listing=$(ls -1 "$repo_root/.github/workflows" 2>/dev/null | grep -E '\.(yml|yaml)$' | LC_ALL=C sort)
  fi
  if command -v sha256sum >/dev/null 2>&1; then
    file_list_hash=$(printf '%s' "$file_listing" | sha256sum 2>/dev/null | awk '{print $1}')
  else
    file_list_hash=$(printf '%s' "$file_listing" | shasum -a 256 2>/dev/null | awk '{print $1}')
  fi

  # Compare against last-scan record. Skip rule = same task_id AND
  # same file-list-hash AND <60s elapsed.
  if [ -f "$state_file" ]; then
    local last_task last_ts last_hash
    last_task=$(jq -r '.last_scan_task_id // empty' "$state_file" 2>/dev/null)
    last_ts=$(jq -r '.last_scan_epoch // 0' "$state_file" 2>/dev/null)
    last_hash=$(jq -r '.last_scan_files_hash // empty' "$state_file" 2>/dev/null)
    if [ "$last_task" = "$task_id" ] && [ "$last_hash" = "$file_list_hash" ]; then
      local age=$((now_epoch - last_ts))
      if [ "$age" -ge 0 ] && [ "$age" -lt 60 ]; then
        # Hit — debounce skip.
        return 0
      fi
    fi
  fi

  # Miss — record current scan and let the scanner run.
  local tmp_file="${state_file}.tmp.$$"
  jq -n \
    --arg task "$task_id" \
    --arg ts "$now_iso" \
    --argjson epoch "$now_epoch" \
    --arg hash "$file_list_hash" \
    '{
      last_scan_task_id: $task,
      last_scan_ts:      $ts,
      last_scan_epoch:   $epoch,
      last_scan_files_hash: $hash
    }' > "$tmp_file" 2>/dev/null && mv "$tmp_file" "$state_file" 2>/dev/null
  rm -f "$tmp_file" 2>/dev/null
  return 1
}

if _apex_ci_scan_debounce; then
  exit 0
fi

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
#
# Phase 8 R-P8-C12: consolidate stdin extraction to shared helper.
# 3-shape routing preserved by invoking the helper ONLY inside the
# no-argv branch — so argv-style test invocations (S-11..S-14) bypass
# the self-filter exactly as before. Narrowing note: the pre-migration
# code read stdin whenever stdin was piped, even with argv present
# (rare unreachable corner case under Claude Code runtime); the new
# code prefers argv when both are present. Tests do not exercise this
# corner; production never produces it.
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi

WORKFLOWS_DIR=""
if [ -z "${1:-}" ]; then
  HOOK_PATH=""
  if command -v apex_hook_input_filepath >/dev/null 2>&1; then
    HOOK_PATH=$(apex_hook_input_filepath 2>/dev/null || true)
  fi
  if [ -n "$HOOK_PATH" ]; then
    case "$HOOK_PATH" in
      .github/workflows/*|*/.github/workflows/*)
        WORKFLOWS_DIR="$(dirname "$HOOK_PATH")"
        ;;
      *)
        exit 0
        ;;
    esac
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
