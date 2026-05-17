#!/bin/bash
set -u
# Hook type: PreToolUse (Bash|Write|Edit)
#
# R16-608 / IMP-004 — block silent test deletion.
#
# Spec anchor: "framework/hooks/quarantine-guard.sh ו-framework/agents/
# auditor.md חייבים לספור test functions … hook חדש framework/hooks/
# test-deletion-guard.sh חוסם מחיקת test files."
#
# Detection scope:
#   - Bash matcher:  `rm` / `git rm` over test paths.
#   - Write|Edit:    explicit file_path targeting a test path that
#                    currently exists (treated as same-path overwrite =
#                    blocked when content shrinks past the test-count
#                    threshold; conservative implementation here blocks
#                    only the explicit-delete vectors and defers the
#                    count-delta check to auditor.md / R-608A).
#
# Test path globs (defined explicitly to avoid glob ambiguity):
#   *.test.* | *.test.js | *.test.ts | *.test.tsx | *.test.py
#   *.spec.* | *.spec.js | *.spec.ts | *.spec.tsx | *.spec.py
#   tests/** | __tests__/** | test/**
#
# Carve-out: `APEX_ACTIVE_AGENT=test-architect` legitimately maintains
# test files; pass-through with exit 0 for that agent only.
#
# Exit codes:
#   0 — not a deletion / not a test path / approved agent / non-matching call.
#   2 — blocked test-file deletion.

source "$(dirname "$0")/_require-jq.sh" 2>/dev/null || true

# Test-architect carve-out
if [ "${APEX_ACTIVE_AGENT:-}" = "test-architect" ]; then
  exit 0
fi

# Parse Claude Code hook stdin envelope if present
PAYLOAD=""
if [ ! -t 0 ]; then
  PAYLOAD=$(cat 2>/dev/null || true)
fi

[ -z "$PAYLOAD" ] && exit 0

if ! command -v jq >/dev/null 2>&1; then
  # Without jq we cannot inspect the payload reliably. Fail-safe to 0
  # (the broader path-guard / destructive-guard still defends).
  exit 0
fi

TOOL_NAME=$(echo "$PAYLOAD" | jq -r '.tool_name // empty' 2>/dev/null)
TOOL_INPUT=$(echo "$PAYLOAD" | jq -r '.tool_input // empty' 2>/dev/null)

is_test_path() {
  local p="$1"
  case "$p" in
    *.test.*|*.spec.*) return 0 ;;
    tests/*|*/tests/*|__tests__/*|*/__tests__/*|test/*|*/test/*) return 0 ;;
  esac
  return 1
}

block() {
  local reason="$1" detail="$2"
  echo "🚫 TEST-DELETION-GUARD: $reason" >&2
  echo "   Detail: $detail" >&2
  echo "" >&2
  echo "Test files are protected. To intentionally remove tests, set APEX_ACTIVE_AGENT=test-architect" >&2
  echo "and run via the test-architect workflow, or declare is_test_cleanup=true in the task XML." >&2
  if [ -f "$(dirname "$0")/_fix-plan-emit.sh" ]; then
    # shellcheck source=/dev/null
    source "$(dirname "$0")/_fix-plan-emit.sh"
    if command -v emit_fix_plan >/dev/null 2>&1; then
      emit_fix_plan \
        "test-deletion-guard" \
        "Blocked test-file deletion: $reason" \
        "$detail" \
        "/apex:forensics -- review why a test was scheduled for deletion" \
        "/apex:rollback -- restore the test if removal was unintentional" \
        "/apex:recover -- re-run via test-architect if intentional cleanup" \
        2>/dev/null || true
    fi
  fi
  exit 2
}

case "$TOOL_NAME" in
  Bash)
    CMD=$(echo "$PAYLOAD" | jq -r '.tool_input.command // empty' 2>/dev/null)
    [ -z "$CMD" ] && exit 0
    # Match `rm` and `git rm` with test-path arguments. Conservative
    # tokenization: split on whitespace; check each token against the
    # test-path globs.
    case "$CMD" in
      *"rm "*|*"git rm"*)
        for tok in $CMD; do
          case "$tok" in
            -*|rm|git) continue ;;
          esac
          if is_test_path "$tok"; then
            block "rm/git rm over test file" "command=$CMD path=$tok"
          fi
        done
        ;;
    esac
    ;;
  Write|Edit)
    FILE_PATH=$(echo "$PAYLOAD" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
    [ -z "$FILE_PATH" ] && exit 0
    # Only flag when the target test file currently exists and the
    # incoming payload writes empty / near-empty content (definition of
    # "silent deletion" via Write). Edit operations on test files are
    # legitimate test maintenance.
    if [ "$TOOL_NAME" = "Write" ] && is_test_path "$FILE_PATH" && [ -f "$FILE_PATH" ]; then
      NEW_CONTENT=$(echo "$PAYLOAD" | jq -r '.tool_input.content // empty' 2>/dev/null)
      NEW_LEN=${#NEW_CONTENT}
      OLD_LEN=$(wc -c < "$FILE_PATH" 2>/dev/null | tr -d ' ')
      : "${OLD_LEN:=0}"
      # Conservative threshold: if new content is < 10% of old AND old
      # was non-trivial (> 200 bytes), treat as silent deletion.
      if [ "$OLD_LEN" -gt 200 ] && [ "$NEW_LEN" -lt $((OLD_LEN / 10)) ]; then
        block "Write shrinks test file below 10% of prior size" "file=$FILE_PATH old=$OLD_LEN new=$NEW_LEN"
      fi
    fi
    ;;
esac

exit 0
