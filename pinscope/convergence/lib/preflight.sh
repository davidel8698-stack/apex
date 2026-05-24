#!/usr/bin/env bash
# PinScope convergence — environment capability probe.
#
# Read-only. Never downloads anything. Detects which AC `verify:` methods can
# run here, so BLOCKED classification is deterministic from round 1 (instead
# of being discovered mid-run, as the Playwright block was in the original
# PS-R5). Writes env-capabilities.json.
#
# Exit 0 always (a missing capability is data, not an error); exit 1 only on
# a write failure.

set -uo pipefail

CONV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${CONV_DIR}/env-capabilities.json"

# --- browser: a Playwright browser binary OR a system browser ---
browser=false
if command -v chromium >/dev/null 2>&1 \
   || command -v chromium-browser >/dev/null 2>&1 \
   || command -v google-chrome >/dev/null 2>&1 \
   || command -v google-chrome-stable >/dev/null 2>&1; then
  browser=true
elif [ -d "${HOME}/.cache/ms-playwright" ] \
     && [ -n "$(ls -A "${HOME}/.cache/ms-playwright" 2>/dev/null)" ]; then
  browser=true
fi

# --- npm_registry: reachable? ---
npm_registry=false
if command -v npm >/dev/null 2>&1 && timeout 25 npm ping >/dev/null 2>&1; then
  npm_registry=true
fi

# --- apex_install: APEX framework synced to ~/.claude/ ? ---
apex_install=false
if [ -d "${HOME}/.claude/agents" ]; then
  apex_install=true
fi

# --- spec_hash: content hash of the frozen North-Star (SPEC-drift detection) ---
spec_hash="none"
SPEC_FILE="${CONV_DIR}/../SPEC.md"
if [ -f "$SPEC_FILE" ] && command -v sha256sum >/dev/null 2>&1; then
  spec_hash="sha256:$(sha256sum "$SPEC_FILE" | awk '{print $1}')"
fi

probed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if ! cat > "$OUT" <<EOF
{
  "browser": ${browser},
  "npm_registry": ${npm_registry},
  "apex_install": ${apex_install},
  "spec_hash": "${spec_hash}",
  "probed_at": "${probed_at}"
}
EOF
then
  echo "preflight: failed to write ${OUT}" >&2
  exit 1
fi

echo "▸ environment: browser=${browser}  npm_registry=${npm_registry}  apex_install=${apex_install}"
echo "  → ${OUT}"
exit 0
