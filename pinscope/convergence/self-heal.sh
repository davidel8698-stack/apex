#!/usr/bin/env bash
# PinScope self-healing convergence loop — terminal entry point.
#
#   bash pinscope/convergence/self-heal.sh            # heal until converged
#   bash pinscope/convergence/self-heal.sh once       # one round, then stop
#   bash pinscope/convergence/self-heal.sh --verify   # verification matrix only
#   bash pinscope/convergence/self-heal.sh --audit    # audit only, no remediation
#
# Audit and remediation need judgement, so the round loop is driven by Claude
# (the `/ps-heal` slash command — see .claude/commands/ps-heal.md). This script
# runs the deterministic preflight + verification itself, then hands the loop
# to `claude -p`. The mechanics live in pinscope/convergence/lib/.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
LIB="pinscope/convergence/lib"
MODE="${1:-loop}"

echo "▲ PinScope self-heal"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f pinscope/SPEC.md ]; then
  echo "❌ pinscope/SPEC.md not found — run this from the apex repo root."
  exit 1
fi

# 1. Preflight — probe environment capabilities (deterministic, read-only).
bash "${LIB}/preflight.sh"

# 2. --verify: run the per-AC verification matrix + render STATUS.md, stop.
if [ "$MODE" = "--verify" ]; then
  ROUND="$(node "${LIB}/loop-state.mjs" read round)"
  node "${LIB}/ac-verify.mjs" --round "$ROUND"
  rc=$?
  node "${LIB}/render-status.mjs"
  grep -E '^\*\*Total:' pinscope/convergence/STATUS.md || true
  [ "$rc" -eq 0 ] && echo "✅ verification passed" || echo "❌ verification found gaps"
  exit "$rc"
fi

# 3. Drive the convergence loop through Claude.
SCOPE="round after round until the terminal condition (zero OPEN criteria) or a circuit breaker"
case "$MODE" in
  once)    SCOPE="for exactly one round, then stop" ;;
  --audit) SCOPE="in --audit mode — audit and write findings only, no remediation, no commit" ;;
esac

if command -v claude >/dev/null 2>&1; then
  echo "▸ Driving the convergence loop via Claude…"
  claude -p "Run the PinScope self-healing convergence loop exactly as specified in .claude/commands/ps-heal.md. Run ${SCOPE}. Commit and push each round."
else
  echo "ℹ The 'claude' CLI is not on PATH."
  echo "  Open this repo in Claude Code and run the slash command:  /ps-heal ${MODE}"
  exit 1
fi
