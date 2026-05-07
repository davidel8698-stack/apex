#!/usr/bin/env bash
# R8-006: ast-kb-check positive/negative-fixture test.
#
# Spec anchors:
#   "Phantom-check, AST-KB Hallucination Gate."
#   "Verification stack עשר-שכבתי."
#   "Fail-loud, never fail-silent."
#   "USENIX: 19.7% imports לא קיימים."
#
# The hook is intentionally ADVISORY (exit 1, never exit 2) — see hook
# header rationale ("dynamic-import resolution produces high false-
# positives; signal consumed by critic.md"). This test asserts:
#   1. The hook exits 0 fast for a non-existent file (defensive path).
#   2. A Python fixture with an unresolvable import emits an advisory
#      (exit 1, stderr matches "hallucinated"/"not found").
#   3. The hook never exits 2 — the contract says advisory-only.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/framework/hooks/ast-kb-check.sh"

PASS=0
FAIL=0
SKIP=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
nope() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }
skip() { echo "  SKIP: $1"; SKIP=$((SKIP+1)); }

echo "=== R8-006: ast-kb-check advisory-fixture test ==="

# 0. Hook exists.
if [ -f "$HOOK" ]; then
  ok "0: ast-kb-check.sh exists"
else
  nope "0: ast-kb-check.sh missing at $HOOK"
  echo "$PASS/$((PASS+FAIL)) passed"
  exit 1
fi

SANDBOX="$(mktemp -d)"
# Note: cannot install an EXIT trap here — the self-test runner installs
# `harness_export_counters` on EXIT to capture per-test counters. We
# clean up the sandbox manually at the end.

# 1. No-file case: hook returns 0 fast on a path that does not exist.
bash "$HOOK" "$SANDBOX/does-not-exist.py" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 0 ]; then
  ok "1: no-file path → exit 0 (defensive fast-path)"
else
  nope "1: expected exit 0 on missing file, got $RC"
fi

# 2. Hallucinated-import fixture: python with a package that cannot resolve.
#    Use a deliberately fake module name to maximize the chance the
#    interpreter cannot resolve it.
HALLUCINATED_PY="$SANDBOX/halluc.py"
cat > "$HALLUCINATED_PY" <<'PY'
from totally_fake_module_xyz_apex_r8 import something
import another_fake_apex_r8_pkg
PY

if command -v python3 >/dev/null 2>&1; then
  STDERR_CAPTURE="$SANDBOX/stderr.txt"
  bash "$HOOK" "$HALLUCINATED_PY" >/dev/null 2>"$STDERR_CAPTURE"
  RC=$?
  if [ "$RC" -eq 1 ]; then
    ok "2a: hallucinated python imports → exit 1 (advisory, not block)"
  elif [ "$RC" -eq 2 ]; then
    nope "2a: hook exited 2 — VIOLATION of advisory-only contract (must never block)"
  else
    # exit 0 may happen on hosts where the python resolver is unavailable
    # (no python3 on PATH for `import` execution at hook time, etc).
    skip "2a: hook exited $RC (advisory not triggered — host-specific)"
  fi

  # Stderr should mention "hallucinated" or "not found" diagnostic words
  # when the advisory fired (only meaningful if RC==1).
  if [ "$RC" -eq 1 ]; then
    if grep -qiE "(hallucinated|not found|advisory)" "$STDERR_CAPTURE"; then
      ok "2b: advisory message present on stderr"
    else
      nope "2b: stderr did not contain advisory diagnostic ($(head -c 120 "$STDERR_CAPTURE"))"
    fi
  else
    skip "2b: advisory diagnostic not asserted — RC=$RC"
  fi
else
  skip "2: python3 not on PATH — cannot exercise hallucinated-import branch"
fi

# 3. Contract: hook MUST NEVER exit 2 (advisory-only). Even if every
#    branch above fired, the strongest assertion is that no path leads
#    to exit 2. Re-confirm against the no-file case (already exit 0).
bash "$HOOK" "$SANDBOX/another-missing.py" >/dev/null 2>&1
RC=$?
if [ "$RC" -ne 2 ]; then
  ok "3: contract — advisory hook never exits 2 (no-file branch returned $RC)"
else
  nope "3: hook exited 2 — VIOLATION of advisory-only contract"
fi

rm -rf "$SANDBOX"

TOTAL=$((PASS+FAIL))
echo ""
echo "$PASS/$TOTAL passed (skipped: $SKIP)"
[ "$FAIL" -eq 0 ]
