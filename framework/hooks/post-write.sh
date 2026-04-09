#!/bin/bash
FILE="$1"

if [[ "$FILE" == *.ts ]] || [[ "$FILE" == *.tsx ]]; then
  npx tsc --noEmit --skipLibCheck 2>&1 | head -5

  # BLOCKING: secret detection
  if grep -E "(password|secret|token|key|api_key)\s*=\s*['\"][a-zA-Z0-9_-]{8,}" "$FILE" 2>/dev/null; then
    echo "🚫 BLOCKED: Potential hardcoded secret in $FILE"
    exit 2
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

exit 0
