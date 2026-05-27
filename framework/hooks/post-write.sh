#!/bin/bash
set -u
# R5-014: On block (exit 2), source `_fix-plan-emit.sh` and write
# `.apex/FIX_PLAN.md`. Detection logic below is unchanged.

# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_fix-plan-emit.sh" ]; then
  source "$(dirname "$0")/_fix-plan-emit.sh"
fi

# Phase 8 R-P8-C8: canonical input extraction via shared helper.
# Closes F-008 (stdin-envelope bypass — auditor axis-13.e discovery).
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi

FILE=$(apex_hook_input_filepath "$@" 2>/dev/null || printf '%s' "${1:-}")

# BLOCKING: secret detection (all source files — not gated on file type)
if grep -E "(password|secret|token|key|api_key|credential|private_key|bearer)\s*[:=]\s*['\"][a-zA-Z0-9_/+=-]{8,}" "$FILE" 2>/dev/null; then
  echo "🚫 BLOCKED: Potential hardcoded secret in $FILE"
  # R5-014: structured fix plan
  if command -v emit_fix_plan >/dev/null 2>&1; then
    emit_fix_plan \
      "post-write" \
      "Potential hardcoded secret detected in a written file." \
      "Last-written file: $FILE" \
      "/apex:forensics -- locate the secret and trace where it was added" \
      "/apex:rollback -- revert the write that introduced the secret" \
      "/apex:recover -- reset and re-run with the secret moved to env/secret store" \
      2>/dev/null || true
  fi
  exit 2
fi

# BLOCKING: skipped-test regression detection
# Catches .skip(), .only(), xit(), xdescribe(), @pytest.mark.skip, etc. in test files
if echo "$FILE" | grep -qE '\.(test|spec)\.|test_[^/]*$|_test\.'; then
  SKIP_HITS=$(grep -nE '\.skip\(|\.only\(|\bxit\(|\bxdescribe\(|@pytest\.mark\.skip|@unittest\.skip|#\[ignore\]|\bpending\(' "$FILE" 2>/dev/null || true)
  if [ -n "$SKIP_HITS" ]; then
    echo "🚫 BLOCKED: Skipped/disabled tests detected in $FILE:"
    echo "$SKIP_HITS"
    echo "   If intentional, document in PLAN_META.json as accepted risk."
    # R5-014: structured fix plan
    if command -v emit_fix_plan >/dev/null 2>&1; then
      emit_fix_plan \
        "post-write" \
        "Skipped or disabled tests detected in a test file." \
        "Test file: $FILE" \
        "/apex:forensics -- inspect which skip directive was added and why" \
        "/apex:rollback -- revert the skip directive" \
        "/apex:recover -- if the skip is intentional, document it in PLAN_META.json as accepted risk and re-run" \
        2>/dev/null || true
    fi
    exit 2
  fi
fi

if [[ "$FILE" == *.ts ]] || [[ "$FILE" == *.tsx ]]; then
  # BLOCKING: TypeScript type check (only if project has tsconfig.json)
  if [ -f tsconfig.json ] && command -v npx &>/dev/null; then
    TSC_OUTPUT=$(npx tsc --noEmit --skipLibCheck 2>&1)
    TSC_EXIT=$?
    if [ "$TSC_EXIT" -ne 0 ]; then
      echo "$TSC_OUTPUT" | head -10
      echo "🚫 BLOCKED: TypeScript errors detected (exit code $TSC_EXIT)"
      # R5-014: structured fix plan
      if command -v emit_fix_plan >/dev/null 2>&1; then
        emit_fix_plan \
          "post-write" \
          "TypeScript errors detected after a write." \
          "Last-written file: $FILE (tsc exit code $TSC_EXIT)" \
          "/apex:forensics -- inspect the tsc output above for the failing types" \
          "/apex:rollback -- revert the write that broke type-checking" \
          "/apex:recover -- reset and re-run with the types corrected" \
          2>/dev/null || true
      fi
      exit 2
    fi
  fi

  # ADVISORY: multi-tenant leak risk
  if grep -E "\.from\(['\"].*['\"].*\)\.select" "$FILE" 2>/dev/null | \
     grep -v "eq.*tenant\|eq.*business_id\|eq.*customer_id\|eq.*org_id" > /dev/null 2>&1; then
    echo "⚠️ WARNING: DB query may be missing tenant isolation filter in $FILE"
  fi

  # ADVISORY: silent catch detection [שיפור 6]
  if grep -A2 "catch" "$FILE" 2>/dev/null | grep -q "console\." && \
     ! grep -A3 "catch" "$FILE" 2>/dev/null | grep -q "setError\|toast\|alert\|throw\|return.*error"; then
    echo "⚠️ WARNING: Potential silent catch in $FILE — errors must reach the user"
  fi
fi

# BLOCKING: conventional commit format validation [R-027]
# Detects commit message files (COMMIT_EDITMSG, .commit-msg) and validates format
if [[ "$FILE" == *COMMIT_EDITMSG ]] || [[ "$FILE" == *.commit-msg ]] || [[ "$FILE" == *commit-message* ]]; then
  FIRST_LINE=$(head -1 "$FILE" 2>/dev/null | tr -d '\r')
  if [ -n "$FIRST_LINE" ] && [[ ! "$FIRST_LINE" =~ ^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?:[[:space:]].+ ]]; then
    echo "⚠️ WARNING: Commit message does not follow conventional format: type(scope): description"
    echo "   Valid types: feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert"
    echo "   Got: $FIRST_LINE"
    # R5-014: structured fix plan
    if command -v emit_fix_plan >/dev/null 2>&1; then
      emit_fix_plan \
        "post-write" \
        "Commit message does not follow conventional format (type(scope): description)." \
        "Commit message file: $FILE — first line: $FIRST_LINE" \
        "/apex:forensics -- inspect the commit message and amend manually" \
        "/apex:rollback -- abandon this commit attempt" \
        "/apex:recover -- reset and re-run the commit with a conventional-format subject (feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)" \
        2>/dev/null || true
    fi
    exit 2
  fi
fi

exit 0
