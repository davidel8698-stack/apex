#!/usr/bin/env bash
# R5-010: CI scanner wiring + path-filter test.
#
# Tested invariants:
#   1. settings.json contains a PostToolUse Write|Edit entry referencing ci-scan.sh.
#   2. ci-scan.sh header reads "Auto-PostToolUse" (not "Manual").
#   3. HOOK-CLASSIFICATION.md lists ci-scan.sh under Auto-PostToolUse.
#   4. Hook exits 0 fast when stdin payload references a path outside .github/workflows/.
#   5. Hook exits 2 on a malicious-workflow fixture (unpinned action).
#   6. Hook exits 0 on a clean workflow fixture (SHA-pinned action, least-privilege perms).
#   7. Hook exits 0 with no args when .github/workflows/ doesn't exist (default behavior).
#   8. Three-places contract honored.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CI_SCAN="$REPO_ROOT/framework/hooks/ci-scan.sh"
SETTINGS="$REPO_ROOT/framework/settings.json"
HOOK_CLASS="$REPO_ROOT/framework/HOOK-CLASSIFICATION.md"

PASS=0
FAIL=0

ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
nope() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== R5-010: CI scanner wiring + path-filter ==="

# C-1: settings.json wiring (PostToolUse, Write|Edit, ci-scan.sh)
if jq -e '
  .hooks.PostToolUse[]
  | select(.matcher == "Write|Edit")
  | .hooks[]
  | select(.command | contains("ci-scan.sh"))
' "$SETTINGS" >/dev/null 2>&1; then
  ok "C-1: settings.json contains PostToolUse Write|Edit entry for ci-scan.sh"
else
  nope "C-1: settings.json missing PostToolUse Write|Edit ci-scan.sh entry"
fi

# C-2: header reflects Auto-PostToolUse (not Manual)
if grep -q "Auto-PostToolUse" "$CI_SCAN"; then
  ok "C-2: ci-scan.sh header reads 'Auto-PostToolUse'"
else
  nope "C-2: ci-scan.sh header missing 'Auto-PostToolUse'"
fi

if grep -q "^# Hook type: Manual invocation" "$CI_SCAN"; then
  nope "C-2b: ci-scan.sh header still reads 'Manual invocation'"
else
  ok "C-2b: ci-scan.sh header no longer reads 'Manual invocation'"
fi

# C-3: HOOK-CLASSIFICATION lists ci-scan under Auto-PostToolUse
# (look for ci-scan.sh row in the Auto-PostToolUse table)
if awk '
  /^## Auto-PostToolUse/ { in_section=1; next }
  /^## / && in_section { in_section=0 }
  in_section && /ci-scan\.sh/ { found=1 }
  END { exit !found }
' "$HOOK_CLASS"; then
  ok "C-3: HOOK-CLASSIFICATION.md lists ci-scan.sh under Auto-PostToolUse"
else
  nope "C-3: HOOK-CLASSIFICATION.md missing ci-scan.sh under Auto-PostToolUse"
fi

# C-4: stdin payload outside .github/workflows/ → exit 0 fast
SANDBOX=$(mktemp -d)
cd "$SANDBOX"
echo '{"tool_input":{"file_path":"src/foo.ts"}}' | bash "$CI_SCAN" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 0 ]; then
  ok "C-4: ci-scan exits 0 when stdin file_path is outside .github/workflows/"
else
  nope "C-4: ci-scan exited $RC (expected 0) for path outside .github/workflows/"
fi

# C-5: malicious workflow fixture → exit 2 (unpinned action)
mkdir -p .github/workflows
cat > .github/workflows/bad.yml <<'EOF'
name: bad
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    permissions: write-all
    steps:
      - uses: actions/checkout@v4
      - run: echo "${{ secrets.MY_SECRET }}"
EOF

# Auto-PostToolUse path: stdin payload referring to the malicious file.
echo '{"tool_input":{"file_path":".github/workflows/bad.yml"}}' | bash "$CI_SCAN" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 2 ]; then
  ok "C-5: ci-scan exits 2 on malicious workflow fixture (auto-PostToolUse path)"
else
  nope "C-5: ci-scan exited $RC (expected 2) on malicious workflow"
fi

# C-5b: command-invoked path with explicit dir
bash "$CI_SCAN" .github/workflows >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 2 ]; then
  ok "C-5b: ci-scan exits 2 on malicious workflow fixture (command-invoked path)"
else
  nope "C-5b: ci-scan exited $RC (expected 2) on malicious workflow (command-invoked)"
fi

# C-6: clean workflow → exit 0
rm -rf .github
mkdir -p .github/workflows
cat > .github/workflows/good.yml <<'EOF'
name: good
on: [push]
permissions:
  contents: read
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
EOF

echo '{"tool_input":{"file_path":".github/workflows/good.yml"}}' | bash "$CI_SCAN" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 0 ]; then
  ok "C-6: ci-scan exits 0 on clean SHA-pinned workflow"
else
  nope "C-6: ci-scan exited $RC (expected 0) on clean workflow"
fi

# C-7: no .github/workflows/ directory → exit 0
rm -rf .github
bash "$CI_SCAN" >/dev/null 2>&1 < /dev/null
RC=$?
if [ "$RC" -eq 0 ]; then
  ok "C-7: ci-scan exits 0 when .github/workflows/ does not exist"
else
  nope "C-7: ci-scan exited $RC (expected 0) on missing workflows dir"
fi

# C-8: stdin payload with no file_path → fall through to default (.github/workflows)
# without a workflows dir → exit 0
echo '{"tool_name":"Bash","tool_input":{}}' | bash "$CI_SCAN" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 0 ]; then
  ok "C-8: ci-scan exits 0 when stdin payload has no file_path and no workflows dir"
else
  nope "C-8: ci-scan exited $RC (expected 0) on payload without file_path"
fi

cd "$SCRIPT_DIR"
rm -rf "$SANDBOX"

TOTAL=$((PASS+FAIL))
echo ""
echo "$PASS/$TOTAL passed"
[ "$FAIL" -eq 0 ]
