#!/usr/bin/env bash
# migrate-plan-meta-v8.sh — Phase 12.02 / M08 migration.
#
# Adds the v8 task_class field (default "B" — medium tier, conservative)
# to every task in every PLAN_META.json under .apex/phases/*/. Also adds
# task_type (default "new_code") and is_irreversible_now (default false)
# so the v8 schema validates against the migrated file.
#
# Idempotent: tasks that already declare task_class are left untouched.
# A second invocation against a fully-migrated tree is a no-op.
#
# Spec anchor: .apex/phases/12-apex-evolution-v8/PLAN.md task 12.02 §8
# pre-conditions ("Migration of existing PLAN_META.json").
#
# Usage:
#   bash framework/scripts/migrate-plan-meta-v8.sh                  # migrate every PLAN_META.json found
#   bash framework/scripts/migrate-plan-meta-v8.sh <path-to-file>   # migrate one file
#   bash framework/scripts/migrate-plan-meta-v8.sh --dry-run        # report what would change without writing
#   bash framework/scripts/migrate-plan-meta-v8.sh --class C <path> # override the default class (escape hatch for hand-classified phases)
#
# Exit codes:
#   0 = success (zero or more files migrated)
#   1 = invocation error or jq unavailable
#   2 = a file failed to migrate (write or validate failure)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Walk up from framework/scripts/ to the project root (where .apex/ lives).
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if ! command -v jq >/dev/null 2>&1; then
  echo "🚫 migrate-plan-meta-v8: jq is required" >&2
  exit 1
fi

DEFAULT_CLASS="B"
DEFAULT_TYPE="new_code"
DRY_RUN=0
TARGETS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --class)
      shift
      case "${1:-}" in
        A|B|C|D) DEFAULT_CLASS="$1" ;;
        *) echo "🚫 --class must be one of A B C D" >&2; exit 1 ;;
      esac
      shift
      ;;
    --type)
      shift
      DEFAULT_TYPE="${1:?}"; shift
      ;;
    -h|--help)
      sed -n '1,30p' "$0" | grep -E '^# ' | sed 's/^# //'
      exit 0
      ;;
    *)
      TARGETS+=("$1")
      shift
      ;;
  esac
done

if [ "${#TARGETS[@]}" -eq 0 ]; then
  # Auto-discover under .apex/phases/.
  shopt -s nullglob
  for f in "$REPO_ROOT"/.apex/phases/*/PLAN_META.json; do
    TARGETS+=("$f")
  done
fi

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "ℹ️  migrate-plan-meta-v8: no PLAN_META.json files found"
  exit 0
fi

MIGRATED=0
SKIPPED=0
FAILED=0

for f in "${TARGETS[@]}"; do
  if [ ! -f "$f" ]; then
    echo "  ❌ $f: not found"
    FAILED=$((FAILED + 1))
    continue
  fi

  if ! jq -e . "$f" >/dev/null 2>&1; then
    echo "  ❌ $f: invalid JSON"
    FAILED=$((FAILED + 1))
    continue
  fi

  # Check whether all tasks already declare task_class. If yes, skip.
  PENDING=$(jq --arg c "$DEFAULT_CLASS" '
    [.tasks[] | select(has("task_class") | not)] | length
  ' "$f")

  if [ "$PENDING" -eq 0 ]; then
    echo "  ✓ $f: all tasks already declare task_class (skip)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  → $f: $PENDING task(s) would receive task_class=\"$DEFAULT_CLASS\""
    continue
  fi

  TMP="$(mktemp)"
  jq --arg c "$DEFAULT_CLASS" --arg t "$DEFAULT_TYPE" '
    .tasks = (.tasks | map(
      (if has("task_class") then . else . + {task_class: $c} end) |
      (if has("task_type")  then . else . + {task_type:  $t} end) |
      (if has("is_irreversible_now") then . else . + {is_irreversible_now: false} end)
    ))
  ' "$f" > "$TMP"

  if [ ! -s "$TMP" ]; then
    echo "  ❌ $f: jq produced empty output"
    rm -f "$TMP"
    FAILED=$((FAILED + 1))
    continue
  fi

  # Post-write validation: make sure the result is still valid JSON.
  if ! jq -e . "$TMP" >/dev/null 2>&1; then
    echo "  ❌ $f: post-migration JSON invalid"
    rm -f "$TMP"
    FAILED=$((FAILED + 1))
    continue
  fi

  mv "$TMP" "$f"
  echo "  ✅ $f: migrated $PENDING task(s) → task_class=\"$DEFAULT_CLASS\""
  MIGRATED=$((MIGRATED + 1))
done

echo
echo "━━━ migrate-plan-meta-v8 summary ━━━"
echo "  migrated: $MIGRATED   skipped: $SKIPPED   failed: $FAILED"

if [ "$FAILED" -gt 0 ]; then
  exit 2
fi
exit 0
