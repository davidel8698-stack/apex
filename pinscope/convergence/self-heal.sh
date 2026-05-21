#!/usr/bin/env bash
# PinScope self-healing convergence loop.
#
# One command runs the full repair mechanism — audit -> remediate -> wave ->
# execute -> verify -> close — round after round, until PinScope converges on
# its frozen North-Star (pinscope/SPEC.md) or a circuit breaker halts it.
#
#   bash pinscope/convergence/self-heal.sh            # heal until converged
#   bash pinscope/convergence/self-heal.sh --once     # run a single round
#   bash pinscope/convergence/self-heal.sh --verify   # mechanical re-verify only
#
# The audit and remediation steps need judgement, so the loop is driven by
# Claude (the `claude` CLI, or the /ps-heal slash command inside Claude Code).
# This script runs the mechanical verification itself and then hands the
# round-by-round loop to Claude.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

MODE="${1:-loop}"

echo "▲ PinScope self-heal"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f pinscope/SPEC.md ]; then
  echo "❌ pinscope/SPEC.md not found — run this from the apex repo root."
  exit 1
fi

# 1. Mechanical verification — build + typecheck + the full test suite.
#    This is the falsifiable health check; it catches regressions.
echo "▸ Verifying current state (build + typecheck + tests)…"
( cd pinscope && npm run typecheck && npm test ) > /tmp/ps-self-heal.log 2>&1
VERIFY_EXIT=$?
tail -6 /tmp/ps-self-heal.log
if [ "$VERIFY_EXIT" -eq 0 ]; then
  echo "✅ verification passed"
else
  echo "⚠ verification reported failures — the loop will remediate them"
  echo "  full log: /tmp/ps-self-heal.log"
fi

# 2. Current convergence metric.
echo ""
grep -E '^\*\*Total:|loop status' pinscope/convergence/STATUS.md | head -2 || true
echo ""

if [ "$MODE" = "--verify" ]; then
  exit "$VERIFY_EXIT"
fi

# 3. Drive the convergence loop through Claude.
SCOPE="round after round until the terminal condition (zero OPEN acceptance criteria) or a circuit breaker"
if [ "$MODE" = "--once" ]; then
  SCOPE="for exactly one round, then stop"
fi

if command -v claude >/dev/null 2>&1; then
  echo "▸ Driving the convergence loop via Claude…"
  claude -p "Run the PinScope self-healing convergence loop exactly as specified in .claude/commands/ps-heal.md. Run ${SCOPE}. Commit and push each round."
else
  echo "ℹ The 'claude' CLI is not on PATH."
  echo "  Open this repo in Claude Code and run the slash command:  /ps-heal"
  exit 1
fi
