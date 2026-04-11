#!/bin/bash
set -u
FILE="${1:-}"

# BLOCKING: secret detection (all source files — not gated on file type)
if grep -E "(password|secret|token|key|api_key|credential|private_key|bearer)\s*[:=]\s*['\"][a-zA-Z0-9_/+=-]{8,}" "$FILE" 2>/dev/null; then
  echo "🚫 BLOCKED: Potential hardcoded secret in $FILE"
  exit 2
fi

if [[ "$FILE" == *.ts ]] || [[ "$FILE" == *.tsx ]]; then
  # BLOCKING: TypeScript type check (only if project has tsconfig.json)
  if [ -f tsconfig.json ] && command -v npx &>/dev/null; then
    TSC_OUTPUT=$(npx tsc --noEmit --skipLibCheck 2>&1)
    TSC_EXIT=$?
    if [ "$TSC_EXIT" -ne 0 ]; then
      echo "$TSC_OUTPUT" | head -10
      echo "🚫 BLOCKED: TypeScript errors detected (exit code $TSC_EXIT)"
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

# ADVISORY: conventional commit format validation [R-027]
# Detects commit message files (COMMIT_EDITMSG, .commit-msg) and validates format
if [[ "$FILE" == *COMMIT_EDITMSG ]] || [[ "$FILE" == *.commit-msg ]] || [[ "$FILE" == *commit-message* ]]; then
  FIRST_LINE=$(head -1 "$FILE" 2>/dev/null | tr -d '\r')
  if [ -n "$FIRST_LINE" ] && [[ ! "$FIRST_LINE" =~ ^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?:[[:space:]].+ ]]; then
    echo "⚠️ WARNING: Commit message does not follow conventional format: type(scope): description"
    echo "   Valid types: feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert"
    echo "   Got: $FIRST_LINE"
  fi
fi

exit 0
