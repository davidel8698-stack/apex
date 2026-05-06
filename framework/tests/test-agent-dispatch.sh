#!/usr/bin/env bash
# R5-009: Agent dispatcher test — validates env var set/unset and the
# three-places contract for _agent-dispatch.sh.
#
# Tested invariants:
#   1. The helper file exists.
#   2. apex_dispatch_enter <agent> exports APEX_ACTIVE_AGENT=<agent>.
#   3. apex_dispatch_exit unsets APEX_ACTIVE_AGENT.
#   4. apex_dispatch_enter with no argument fails (exit 2).
#   5. The subcommand form `bash _agent-dispatch.sh enter <agent>`
#      prints an `export APEX_ACTIVE_AGENT="<agent>"` line.
#   6. The subcommand form `bash _agent-dispatch.sh exit` prints an
#      `unset APEX_ACTIVE_AGENT` line.
#   7. next.md no longer contains the inline `export APEX_ACTIVE_AGENT=auditor`
#      pattern — it routes through the dispatcher.
#   8. grep -r "APEX_ACTIVE_AGENT=auditor" framework/commands/ returns zero hits
#      (acceptance criterion from REMEDIATION-PLAN-R5.md).
#   9. auditor.md contains a preflight directive checking APEX_ACTIVE_AGENT.
#  10. HOOK-CLASSIFICATION.md lists _agent-dispatch.sh.
#  11. sync-to-claude.sh delivers the helper.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DISPATCH="$REPO_ROOT/framework/hooks/_agent-dispatch.sh"
NEXT_MD="$REPO_ROOT/framework/commands/apex/next.md"
AUDITOR_MD="$REPO_ROOT/framework/agents/auditor.md"
HOOK_CLASS="$REPO_ROOT/framework/HOOK-CLASSIFICATION.md"
SYNC_SH="$REPO_ROOT/framework/scripts/sync-to-claude.sh"

PASS=0
FAIL=0

ok()    { echo "  PASS: $1"; PASS=$((PASS+1)); }
nope()  { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== R5-009: Agent dispatcher ==="

# C-1: file exists
if [ -f "$DISPATCH" ]; then
  ok "C-1: _agent-dispatch.sh exists"
else
  nope "C-1: _agent-dispatch.sh missing at $DISPATCH"
  echo "$PASS/$((PASS+FAIL)) passed"
  exit 1
fi

# C-2: sourced enter exports APEX_ACTIVE_AGENT
out=$(bash -c "
  unset APEX_ACTIVE_AGENT
  source '$DISPATCH'
  apex_dispatch_enter auditor
  echo \"\$APEX_ACTIVE_AGENT\"
")
if [ "$out" = "auditor" ]; then
  ok "C-2: sourced apex_dispatch_enter exports APEX_ACTIVE_AGENT=auditor"
else
  nope "C-2: expected 'auditor', got '$out'"
fi

# C-3: sourced exit unsets APEX_ACTIVE_AGENT
out=$(bash -c "
  source '$DISPATCH'
  export APEX_ACTIVE_AGENT=auditor
  apex_dispatch_exit
  if [ -z \"\${APEX_ACTIVE_AGENT+x}\" ]; then
    echo unset
  else
    echo set:\$APEX_ACTIVE_AGENT
  fi
")
if [ "$out" = "unset" ]; then
  ok "C-3: sourced apex_dispatch_exit unsets APEX_ACTIVE_AGENT"
else
  nope "C-3: expected 'unset', got '$out'"
fi

# C-4: enter with no argument exits non-zero (sourced returns 2)
rc=$(bash -c "
  source '$DISPATCH'
  apex_dispatch_enter
  echo \$?
" 2>/dev/null)
if [ "$rc" = "2" ]; then
  ok "C-4: apex_dispatch_enter with no argument returns 2"
else
  nope "C-4: expected return 2, got '$rc'"
fi

# C-5: subcommand `enter <agent>` prints export line
out=$(bash "$DISPATCH" enter auditor)
if echo "$out" | grep -q '^export APEX_ACTIVE_AGENT="auditor"$'; then
  ok "C-5: bash _agent-dispatch.sh enter auditor prints export line"
else
  nope "C-5: expected 'export APEX_ACTIVE_AGENT=\"auditor\"', got: $out"
fi

# C-6: subcommand `exit` prints unset line
out=$(bash "$DISPATCH" exit)
if [ "$out" = "unset APEX_ACTIVE_AGENT" ]; then
  ok "C-6: bash _agent-dispatch.sh exit prints unset line"
else
  nope "C-6: expected 'unset APEX_ACTIVE_AGENT', got: $out"
fi

# C-7: next.md no longer contains inline `export APEX_ACTIVE_AGENT=auditor`
if grep -qE "^[[:space:]]*export APEX_ACTIVE_AGENT=auditor" "$NEXT_MD"; then
  nope "C-7: next.md still contains inline 'export APEX_ACTIVE_AGENT=auditor'"
else
  ok "C-7: next.md has no inline 'export APEX_ACTIVE_AGENT=auditor'"
fi

# C-8: grep across framework/commands/ returns zero inline-export hits
if grep -rE "^[[:space:]]*export APEX_ACTIVE_AGENT=auditor" "$REPO_ROOT/framework/commands/" >/dev/null 2>&1; then
  nope "C-8: grep -r 'export APEX_ACTIVE_AGENT=auditor' framework/commands/ found inline pattern"
else
  ok "C-8: zero inline 'export APEX_ACTIVE_AGENT=auditor' hits in framework/commands/"
fi

# C-9: next.md routes through the dispatcher
if grep -q "_agent-dispatch.sh" "$NEXT_MD" && grep -q "apex_dispatch_enter auditor" "$NEXT_MD"; then
  ok "C-9: next.md sources _agent-dispatch.sh and calls apex_dispatch_enter auditor"
else
  nope "C-9: next.md missing dispatcher invocation"
fi

# C-10: auditor.md preflight directive
if grep -q "APEX_ACTIVE_AGENT" "$AUDITOR_MD" && grep -q "QUARANTINE-FAIL" "$AUDITOR_MD"; then
  ok "C-10: auditor.md has preflight directive checking APEX_ACTIVE_AGENT"
else
  nope "C-10: auditor.md missing preflight directive"
fi

# C-11: HOOK-CLASSIFICATION lists _agent-dispatch.sh
if grep -q "_agent-dispatch.sh" "$HOOK_CLASS"; then
  ok "C-11: HOOK-CLASSIFICATION.md lists _agent-dispatch.sh"
else
  nope "C-11: HOOK-CLASSIFICATION.md missing _agent-dispatch.sh"
fi

# C-12: sync-to-claude.sh delivers the helper
if grep -q "_agent-dispatch.sh" "$SYNC_SH"; then
  ok "C-12: sync-to-claude.sh delivers _agent-dispatch.sh"
else
  nope "C-12: sync-to-claude.sh missing _agent-dispatch.sh delivery"
fi

# C-13: header contains the Library — Sourced classification
if grep -q "Library — Sourced" "$DISPATCH" || grep -q "Library — Sourced" "$DISPATCH" || head -10 "$DISPATCH" | grep -q "Library"; then
  ok "C-13: _agent-dispatch.sh header documents Library — Sourced classification"
else
  nope "C-13: _agent-dispatch.sh header missing Library — Sourced documentation"
fi

TOTAL=$((PASS+FAIL))
echo ""
echo "$PASS/$TOTAL passed"
[ "$FAIL" -eq 0 ]
