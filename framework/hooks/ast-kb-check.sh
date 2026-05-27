#!/bin/bash
set -u
# AST-KB Hallucination Gate — import validation hook
# Hook type: PostToolUse (Write|Edit) — ADVISORY only (exit 1, never exit 2)
# Rationale: dynamic-import resolution produces high false-positives;
# advisory feeds critic.md, which decides on block.
#
# Validates that imported modules exist in the project or installed packages.
# 19.7% of AI-generated imports reference non-existent modules (USENIX research).

# Phase 8 R-P8-C9: canonical input extraction via shared helper.
# Closes F-009 (stdin-envelope bypass — auditor axis-13.e discovery).
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi

FILE=$(apex_hook_input_filepath "$@" 2>/dev/null || printf '%s' "${1:-}")

# No file provided or file doesn't exist — pass through
[ -z "$FILE" ] && exit 0
[ -f "$FILE" ] || exit 0

# Determine language by extension
case "$FILE" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs)
    LANG="js"
    ;;
  *.py)
    LANG="py"
    ;;
  *)
    # Unsupported language — skip
    exit 0
    ;;
esac

HALLUCINATED=()

if [ "$LANG" = "js" ]; then
  # Extract non-relative imports: import ... from 'package' or require('package')
  # Skip relative imports (./  ../)
  IMPORTS=$(grep -oE "(from\s+['\"])([^./][^'\"]*)['\"]|require\(\s*['\"]([^./][^'\"]*)['\"]" "$FILE" 2>/dev/null | \
    sed -E "s/from\s+['\"]//; s/['\"]$//; s/require\(\s*['\"]//; s/['\"]\s*$//; s/['\"]//g" | \
    sed 's|/.*||' | \
    sort -u)

  for pkg in $IMPORTS; do
    [ -z "$pkg" ] && continue
    # Skip Node.js built-in modules
    case "$pkg" in
      fs|path|os|http|https|url|util|stream|events|crypto|child_process|net|tls|dns|cluster|zlib|readline|assert|buffer|console|module|process|querystring|string_decoder|timers|tty|dgram|v8|vm|worker_threads|perf_hooks|async_hooks|inspector)
        continue ;;
    esac
    # Try to resolve
    if ! node -e "require.resolve('$pkg')" 2>/dev/null; then
      HALLUCINATED+=("$pkg")
    fi
  done
fi

if [ "$LANG" = "py" ]; then
  # Extract top-level module names from import statements
  IMPORTS=$(grep -oE "^(import |from )([a-zA-Z_][a-zA-Z0-9_]*)" "$FILE" 2>/dev/null | \
    sed -E 's/^(import |from )//' | \
    sort -u)

  for module in $IMPORTS; do
    [ -z "$module" ] && continue
    # Try to import
    if ! python3 -c "import $module" 2>/dev/null; then
      HALLUCINATED+=("$module")
    fi
  done
fi

if [ ${#HALLUCINATED[@]} -gt 0 ]; then
  echo "APEX AST-KB CHECK: ADVISORY — ${#HALLUCINATED[@]} potentially hallucinated import(s)" >&2
  echo "File: $FILE" >&2
  for pkg in "${HALLUCINATED[@]}"; do
    echo "  - $pkg (not found in installed packages)" >&2
  done
  echo "" >&2
  echo "Verify these imports exist. This is advisory only — not blocking." >&2
  exit 1
fi

exit 0
