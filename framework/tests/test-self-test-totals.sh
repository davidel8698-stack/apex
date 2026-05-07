#!/usr/bin/env bash
# R8-002: meta-test — runner totals invariant guard.
#
# Spec anchors:
#   "Fail-loud, never fail-silent."
#   "Verification universal, not TDD universal."
#   "Proof-of-process beats proof-of-promise."
#   "Honest scope over marketing scope."
#
# Asserts the per-file aggregation in self-test.sh and the
# totals-invariant guard in _harness.sh's harness_report fire on
# arithmetic counter inconsistencies even when FAIL=0. Three fixture
# cases:
#   1. A passing fixture (assert_exit 0 0 "ok") yields a clean banner.
#   2. A failing fixture (assert_exit 0 1 "fail") yields exit-non-zero
#      and an INFRASTRUCTURE DEGRADED banner.
#   3. A private-counter fixture (sets local TOTAL/CORRECT only) yields
#      a per-file `counters inconsistent` warning when its private
#      counters violate PASS+FAIL>TOTAL after sidecar export.
#
# The meta-test exits 0 when all three observable assertions hold.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SELF_TEST="$REPO_ROOT/framework/scripts/self-test.sh"
HARNESS="$REPO_ROOT/framework/tests/_harness.sh"

# Private counters — this meta-test is itself a self-contained driver
# that invokes self-test.sh in a sandbox. Aggregating into harness
# globals via assert_* would conflict with the sandbox runs.
M_PASS=0
M_FAIL=0
m_ok()   { echo "  ✅ $1"; M_PASS=$((M_PASS+1)); }
m_nope() { echo "  ❌ $1"; M_FAIL=$((M_FAIL+1)); }

echo "=== R8-002: self-test totals-invariant meta-test ==="

# 0. Sanity: artifacts exist.
if [ ! -f "$SELF_TEST" ]; then
  m_nope "0: self-test.sh missing at $SELF_TEST"
  echo "$M_PASS/$((M_PASS+M_FAIL)) passed"
  exit 1
fi
if [ ! -f "$HARNESS" ]; then
  m_nope "0: _harness.sh missing at $HARNESS"
  echo "$M_PASS/$((M_PASS+M_FAIL)) passed"
  exit 1
fi
m_ok "0: self-test.sh and _harness.sh present"

# 0a. Anchor checks — guard and warning literals are in place.
if grep -qE 'TOTALS INVARIANT VIOLATED' "$HARNESS"; then
  m_ok "0a: harness_report contains TOTALS INVARIANT VIOLATED literal"
else
  m_nope "0a: harness_report missing TOTALS INVARIANT VIOLATED literal"
fi
if grep -qE 'counters inconsistent' "$SELF_TEST"; then
  m_ok "0b: self-test.sh contains per-file 'counters inconsistent' warning"
else
  m_nope "0b: self-test.sh missing per-file 'counters inconsistent' warning"
fi

# Build a fixture tree under a tempdir. Each fixture is a test-*.sh
# file that the runner discovers via its glob and sources in a
# subshell. We override TEST_DIR by copying _harness.sh next to the
# fixtures and pointing the runner at a fresh tests/ directory via
# symlink-style path manipulation. Since self-test.sh derives TEST_DIR
# from its own location ($SCRIPT_DIR/../tests), the simplest sandbox
# is to place a copy of self-test.sh + _harness.sh in a tempdir with
# a parallel tests/ subdir.
SANDBOX=$(mktemp -d 2>/dev/null || mktemp -d -t apex-meta)
# Note: deliberately NOT setting `trap … EXIT` — the runner's parent
# subshell already installs `trap 'harness_export_counters' EXIT` so
# overriding it here would silently zero this file's per-file summary
# (the F-009 family bug we are guarding against). Sandbox cleanup is
# handled below at end of script.

mkdir -p "$SANDBOX/scripts" "$SANDBOX/tests"
cp "$SELF_TEST"  "$SANDBOX/scripts/self-test.sh"
cp "$HARNESS"   "$SANDBOX/tests/_harness.sh"

# Fixture 1: pure pass.
cat > "$SANDBOX/tests/test-fixturepass.sh" <<'EOF'
echo "=== fixture-pass ==="
assert_exit 0 0 "fixture-pass: trivial ok"
EOF

# Fixture 2: pure fail.
cat > "$SANDBOX/tests/test-fixturefail.sh" <<'EOF'
echo "=== fixture-fail ==="
assert_exit 0 1 "fixture-fail: trivial mismatch"
EOF

# Fixture 3: private-counter pattern that violates the invariant.
# This mimics the F-009 family — sets local counters, never touches
# harness globals via assert_*. To force the per-file warning we have
# to make the *exported* sidecar PASS exceed the exported TOTAL, which
# the existing harness_export_counters writes from $PASS/$FAIL/$TOTAL.
# We therefore set $PASS positive while leaving $TOTAL at zero.
cat > "$SANDBOX/tests/test-fixtureprivate.sh" <<'EOF'
echo "=== fixture-private ==="
echo "  (private counters only — not bridged to harness)"
PASS=$((PASS + 5))
# TOTAL remains 0 — this is the F-009 drift we want to detect.
EOF

# Run the sandbox runner against the fixtures. Capture output + rc.
# Avoid `|| true` after the command-substitution because that would
# overwrite $? with the rc of `true` instead of the runner.
SANDBOX_OUT=$(bash "$SANDBOX/scripts/self-test.sh" fixture* 2>&1)
SANDBOX_RC=$?

# Case (i): banner contains "passed,".
if echo "$SANDBOX_OUT" | grep -qE 'passed,'; then
  m_ok "1: sandbox banner contains 'passed,' line"
else
  m_nope "1: sandbox banner missing 'passed,' line — output: $(echo "$SANDBOX_OUT" | tail -5)"
fi

# Case (ii): rc is non-zero (FAIL fixture forces this).
if [ "$SANDBOX_RC" -ne 0 ]; then
  m_ok "2: sandbox runner exits non-zero on FAIL fixture (rc=$SANDBOX_RC)"
else
  m_nope "2: sandbox runner exit 0 despite FAIL fixture — INVARIANT BROKEN"
fi

# Case (iii): per-file warning appears for the private-counter fixture.
if echo "$SANDBOX_OUT" | grep -qE 'counters inconsistent'; then
  m_ok "3: per-file 'counters inconsistent' warning fired on private-counter fixture"
else
  m_nope "3: per-file 'counters inconsistent' warning did NOT fire — guard ineffective"
fi

# Case (iv): harness_report did NOT print "ALL MECHANISMS VERIFIED"
# given the FAIL fixture present (and possibly the totals-invariant
# violation). The assertion is "no false-green banner".
if echo "$SANDBOX_OUT" | grep -qE 'ALL MECHANISMS VERIFIED'; then
  m_nope "4: harness_report printed 'ALL MECHANISMS VERIFIED' despite a known FAIL fixture"
else
  m_ok "4: harness_report did not emit a false-green banner"
fi

# Case (v): rerun with a fixture set that ONLY contains the private-
# counter drifter — FAIL fixture removed. The aggregate banner must
# fire the totals-invariant guard (rc=99) when PASS exceeds TOTAL.
rm -f "$SANDBOX/tests/test-fixturefail.sh" "$SANDBOX/tests/test-fixturepass.sh"
SANDBOX2_OUT=$(bash "$SANDBOX/scripts/self-test.sh" fixture* 2>&1)
SANDBOX2_RC=$?

if echo "$SANDBOX2_OUT" | grep -qE 'TOTALS INVARIANT VIOLATED'; then
  m_ok "5: aggregate banner fires TOTALS INVARIANT VIOLATED on PASS>TOTAL"
else
  m_nope "5: aggregate guard did NOT fire on PASS>TOTAL — output: $(echo "$SANDBOX2_OUT" | tail -8)"
fi

if [ "$SANDBOX2_RC" -eq 99 ]; then
  m_ok "6: aggregate guard exit code is 99 (distinct from FAIL=0)"
else
  m_nope "6: aggregate guard exit code is $SANDBOX2_RC, expected 99"
fi

M_TOTAL=$((M_PASS + M_FAIL))
echo ""
echo "$M_PASS/$M_TOTAL passed"

# Bridge private counters into harness globals so the per-file summary
# reflects this test's actual assertion count (closing the F-009 drift
# on this file specifically). Use 100% threshold — this meta-test
# either passes every assertion or it fails the run.
if declare -F harness_assert_corpus >/dev/null 2>&1; then
  harness_assert_corpus "$M_PASS" "$M_TOTAL" "self-test totals-invariant meta-test" 100
fi

rm -rf "$SANDBOX"
[ "$M_FAIL" -eq 0 ]
