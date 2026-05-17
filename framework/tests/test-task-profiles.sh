#!/usr/bin/env bash
# Phase 12.03 — M12 task-type profiles test.
#
# Verifies the per-task-type context profile machinery is wired:
#   C-1..C-7: CONTEXT_BUDGET.default.json declares all 7 profiles
#             (default + new_code + bug_fix + code_review + refactor +
#             test_writing + frontend) with the right include/exclude
#             slice shapes.
#   C-8: CONTEXT_BUDGET.schema.json declares the profile definition
#        and references it from properties.profiles.
#   C-9: PLAN_META.schema.json declares task_type enum.
#   C-10: architect.md declares Step 1.11 task-type classification.
#   C-11: TASK-TYPE-PROFILES.md exists and documents all 6 non-default
#         profiles.
#   C-12: bug_fix profile excludes broad_architecture_docs (the M12
#         load-bearing distinction).
#   C-13: frontend profile preloads apex-frontend module.
#   C-14: test_writing profile preloads test-architect module.
#
# Harness contract (R10-008): no file-scope shadowing of PASS / FAIL /
# TOTAL / SKIP.
#
# Spec anchor: PLAN.md task 12.03 §5 (ideal functioning).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUDGET="$REPO_ROOT/framework/CONTEXT_BUDGET.default.json"
BUDGET_SCHEMA="$REPO_ROOT/framework/schemas/CONTEXT_BUDGET.schema.json"
PLAN_META_SCHEMA="$REPO_ROOT/framework/schemas/PLAN_META.schema.json"
ARCHITECT_MD="$REPO_ROOT/framework/agents/architect.md"
DOC="$REPO_ROOT/framework/docs/TASK-TYPE-PROFILES.md"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ ! -f "$SCRIPT_DIR/_harness.sh" ]; then
    echo "  ❌ Harness not found at $SCRIPT_DIR/_harness.sh"
    exit 1
  fi
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/_harness.sh"
fi

echo "=== Phase 12.03 — M12 task-type profiles ==="

if ! command -v jq >/dev/null 2>&1; then
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
  echo "  ❌ jq is required"
  exit 1
fi

# --- C-1..C-7: each of the 7 profiles exists in CONTEXT_BUDGET ---
for profile in default new_code bug_fix code_review refactor test_writing frontend; do
  TOTAL=$((TOTAL + 1))
  if jq -e --arg p "$profile" '.profiles[$p] | type == "object"' "$BUDGET" >/dev/null 2>&1; then
    echo "  ✅ C-1/$profile: profile declared in CONTEXT_BUDGET.default.json"
    PASS=$((PASS + 1))
  else
    echo "  ❌ C-1/$profile: missing or wrong type"
    FAIL=$((FAIL + 1))
  fi
done

# --- C-8: schema declares profile definition ---
TOTAL=$((TOTAL + 1))
if jq -e '.definitions.profile.type == "object" and .properties.profiles.type == "object"' "$BUDGET_SCHEMA" >/dev/null 2>&1; then
  echo "  ✅ C-8: CONTEXT_BUDGET schema declares profile definition + properties.profiles"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-8: CONTEXT_BUDGET schema missing profile / profiles wiring"
  FAIL=$((FAIL + 1))
fi

# --- C-9: PLAN_META schema declares task_type enum with the 6 expected values ---
TOTAL=$((TOTAL + 1))
if jq -e '
  .properties.tasks.items.properties.task_type.enum
  | (index("new_code") != null and index("bug_fix") != null and
     index("code_review") != null and index("refactor") != null and
     index("test_writing") != null and index("frontend") != null)
' "$PLAN_META_SCHEMA" >/dev/null 2>&1; then
  echo "  ✅ C-9: PLAN_META schema declares task_type enum with all 6 values"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-9: PLAN_META schema task_type enum incomplete"
  FAIL=$((FAIL + 1))
fi

# --- C-10: architect.md declares Step 1.11 task-type classification ---
TOTAL=$((TOTAL + 1))
if grep -qE "## STEP 1\.11: Task-Type Classification" "$ARCHITECT_MD"; then
  echo "  ✅ C-10: architect.md declares Step 1.11"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-10: architect.md missing Step 1.11"
  FAIL=$((FAIL + 1))
fi

# --- C-11: TASK-TYPE-PROFILES.md exists and names all 6 non-default profiles ---
TOTAL=$((TOTAL + 1))
if [ -f "$DOC" ] && \
   grep -q '### `new_code`' "$DOC" && \
   grep -q '### `bug_fix`' "$DOC" && \
   grep -q '### `code_review`' "$DOC" && \
   grep -q '### `refactor`' "$DOC" && \
   grep -q '### `test_writing`' "$DOC" && \
   grep -q '### `frontend`' "$DOC"; then
  echo "  ✅ C-11: TASK-TYPE-PROFILES.md documents all 6 profiles"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-11: TASK-TYPE-PROFILES.md missing or incomplete"
  FAIL=$((FAIL + 1))
fi

# --- C-12: bug_fix profile excludes broad_architecture_docs ---
TOTAL=$((TOTAL + 1))
if jq -e '.profiles.bug_fix.exclude | index("broad_architecture_docs") != null' "$BUDGET" >/dev/null 2>&1; then
  echo "  ✅ C-12: bug_fix excludes broad_architecture_docs (M12 load-bearing distinction)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-12: bug_fix profile missing broad_architecture_docs exclusion"
  FAIL=$((FAIL + 1))
fi

# --- C-13: frontend profile preloads apex-frontend module ---
TOTAL=$((TOTAL + 1))
if jq -e '.profiles.frontend.preload_modules | index("apex-frontend") != null' "$BUDGET" >/dev/null 2>&1; then
  echo "  ✅ C-13: frontend profile preloads apex-frontend module"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-13: frontend profile missing apex-frontend preload"
  FAIL=$((FAIL + 1))
fi

# --- C-14: test_writing profile preloads test-architect module ---
TOTAL=$((TOTAL + 1))
if jq -e '.profiles.test_writing.preload_modules | index("test-architect") != null' "$BUDGET" >/dev/null 2>&1; then
  echo "  ✅ C-14: test_writing profile preloads test-architect module"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-14: test_writing profile missing test-architect preload"
  FAIL=$((FAIL + 1))
fi

# Standalone exit semantics
if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  echo ""
  echo "$PASS/$TOTAL passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] || exit 1
fi
