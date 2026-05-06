#!/bin/bash
set -u
# Auditor quarantine enforcement — agent-aware file access control
# Hook type: PreToolUse (Read|Bash)
#
# First agent-aware hook in APEX. Checks APEX_ACTIVE_AGENT env var.
# When auditor is active, only test files and .apex/ state files are allowed.
# Non-auditor context: instant pass-through (microsecond overhead).
# Exit 2 = blocked (quarantine violation), Exit 0 = allowed

ACTIVE_AGENT="${APEX_ACTIVE_AGENT:-}"

# Fast path: if not auditor, pass through immediately
if [ "$ACTIVE_AGENT" != "auditor" ]; then
  exit 0
fi

# Auditor is active — enforce quarantine
INPUT="${1:-}"

# Allow empty input (shouldn't happen, but safe)
[ -z "$INPUT" ] && exit 0

# Allow-list patterns for auditor — anchored to actual test files / test directories
# R5-008: regex tightened to avoid substring matches like "spec" → "specialist"/"specification"
# Matches: /test/, /tests/, /__tests__/, .test., .spec., paths starting with test_ (or /test_)
if echo "$INPUT" | grep -qE "(/test/|/tests/|/__tests__/|\.test\.|\.spec\.|^test_|/test_)" 2>/dev/null; then
  exit 0
fi

# APEX state files (auditor needs to read STATE.json, RESULT.json, etc.)
if echo "$INPUT" | grep -qE "(\.apex/|STATE\.json|RESULT\.json|SUMMARY\.md|CRITIC\.md|PLAN_META\.json)" 2>/dev/null; then
  exit 0
fi

# Package manifests (auditor may need to check dependencies)
if echo "$INPUT" | grep -qE "(package\.json|requirements\.txt|Cargo\.toml|go\.mod|pyproject\.toml)" 2>/dev/null; then
  exit 0
fi

# Everything else: blocked
echo "APEX QUARANTINE GUARD: BLOCKED" >&2
echo "Agent: auditor" >&2
echo "Path: $INPUT" >&2
echo "" >&2
echo "Auditor agent cannot access implementation files." >&2
echo "Only test files, .apex/ state, and package manifests are allowed." >&2
exit 2
