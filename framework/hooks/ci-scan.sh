#!/bin/bash
set -u
# CI supply-chain vector scanner — defense-in-depth layer
# Hook type: Manual invocation (not wired to settings.json)
#
# Scans .github/workflows/*.yml for known CI supply-chain vectors.
# Exit 2 = vectors found, Exit 0 = clean or no workflows directory

source "$(dirname "$0")/_security-common.sh"

WORKFLOWS_DIR="${1:-.github/workflows}"

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
