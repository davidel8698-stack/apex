#!/usr/bin/env bash
# test-imp003-bash-fallback-advisory.sh — R17-644 (F-644, IMP-003).
#
# Asserts that prompt-guard.sh emits the IMP-003 stderr advisory ONLY when
# the Bash fallback path runs (i.e. node is not on PATH, or the .cjs
# payload is missing). When the .cjs delegation succeeds, the advisory
# MUST NOT fire — the canonical engine is reached and IMP-003 is in force.
#
# Cases:
#   (a) Spoofed no-Node environment + Bash fallback only -> stderr contains
#       "IMP-003 arg-content validation".
#   (b) Node IS on PATH and the .cjs exists (real host) -> advisory MUST NOT
#       fire (the exec node short-circuits before reaching the Bash branch).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/framework/hooks/prompt-guard.sh"
CJS="$REPO_ROOT/framework/hooks/apex-prompt-guard.cjs"

if [ ! -f "$HOOK" ]; then
  echo "FAIL: prompt-guard.sh not found at $HOOK" >&2
  exit 1
fi

LOCAL_PASS=0
LOCAL_FAIL=0
ok()   { echo "  PASS: $1"; LOCAL_PASS=$((LOCAL_PASS+1)); }
nope() { echo "  FAIL: $1"; LOCAL_FAIL=$((LOCAL_FAIL+1)); }

echo "=== R17-644: IMP-003 Bash-fallback stderr advisory ==="

# --- Case (a): force the Bash fallback by:
#     (1) copying the hook to a sandbox WITHOUT its .cjs sibling — so the
#         hook's lookup `$(dirname "$0")/apex-prompt-guard.cjs` returns
#         a non-existent file even if node happens to be on PATH, AND
#     (2) shadowing `node` with a function that makes `command -v node`
#         report it missing — belt and suspenders so the Node-delegation
#         branch's `if command -v node ...` condition is false.
#
#     The hook's logic only reaches the advisory line when neither
#     condition of the Node-delegation block is satisfied — at which point
#     the script falls through to the `# --- Native Bash fallback` section.
SANDBOX_A="$(mktemp -d)"
cp "$HOOK" "$SANDBOX_A/prompt-guard.sh"
# Deliberately do NOT copy the .cjs — so the sibling lookup fails.
chmod +x "$SANDBOX_A/prompt-guard.sh" 2>/dev/null || true

# Pass a benign input so the five Bash-branch deny patterns do NOT trigger.
# We invoke the hook in a sub-shell with PATH minus any node-bearing dir.
# Cross-platform PATH-minus-node: filter `node` out of $PATH.
ORIG_PATH="$PATH"
FILTERED_PATH=$(printf '%s' "$ORIG_PATH" | tr ':' '\n' | while read -r d; do
  [ -n "$d" ] || continue
  if [ ! -e "$d/node" ] && [ ! -e "$d/node.exe" ] && [ ! -e "$d/node.cmd" ]; then
    printf '%s:' "$d"
  fi
done)
FILTERED_PATH="${FILTERED_PATH%:}"
# Ensure bash is still on the filtered path; if not, fall back to the
# original (rare — would mean node lives next to bash, the platform-bundle
# case).
if [ -z "$FILTERED_PATH" ]; then
  FILTERED_PATH="$ORIG_PATH"
fi

STDERR_A="$SANDBOX_A/stderr.a"
( PATH="$FILTERED_PATH" bash "$SANDBOX_A/prompt-guard.sh" "hello benign input" 2>"$STDERR_A" >/dev/null ) || true

if grep -qF "IMP-003 arg-content validation" "$STDERR_A"; then
  ok "(a) Bash fallback emits IMP-003 advisory to stderr"
else
  nope "(a) advisory missing from stderr — got: $(tr '\n' ' ' < "$STDERR_A")"
fi
rm -rf "$SANDBOX_A"

# --- Case (b): the advisory MUST NOT fire when node is reachable AND the
#     .cjs sibling exists. The hook's Node-delegation block then runs
#     `exec node "$CJS_PATH"` and never reaches the Bash branch where the
#     advisory line lives.
if [ -f "$CJS" ] && command -v node >/dev/null 2>&1; then
  STDERR_B="$(mktemp)"
  # Use the source-tree hook with the source-tree .cjs sibling in place.
  ( bash "$HOOK" "hello benign input" 2>"$STDERR_B" >/dev/null ) || true
  if ! grep -qF "IMP-003 arg-content validation" "$STDERR_B"; then
    ok "(b) Node-delegation path does NOT emit the IMP-003 advisory"
  else
    nope "(b) advisory leaked into Node-delegation path: $(tr '\n' ' ' < "$STDERR_B")"
  fi
  rm -f "$STDERR_B"
else
  echo "  SKIP: (b) node or .cjs unavailable — cannot exercise the delegation path on this host"
fi

LOCAL_TOTAL=$((LOCAL_PASS+LOCAL_FAIL))
echo ""
echo "Results: $LOCAL_PASS passed, $LOCAL_FAIL failed (of $LOCAL_TOTAL)"
exit "$LOCAL_FAIL"
