#!/usr/bin/env bash
# APEX Self-Test Harness — assert helpers, setup/teardown, coverage scanner.

PASS=0; FAIL=0; TOTAL=0; SKIP=0

harness_setup() {
  TEMP_REPO=$(mktemp -d)
  ORIG_DIR="$(pwd)"
  cd "$TEMP_REPO"
  git init -q && git config user.email "test@apex" && git config user.name "APEX"
  echo "init" > init.txt && git add . && git commit -qm "init"
  mkdir -p .apex/phases/01
  # NOTE: Tests run against installed hooks/commands ($HOME/.claude/), not framework source.
  # After modifying framework/hooks/ or framework/commands/, re-install before running self-test.
  HOOKS_DIR="$HOME/.claude/hooks"
  SCHEMAS_DIR="$HOME/.claude/schemas"
  COMMANDS_DIR="$HOME/.claude/commands/apex"
  TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

harness_teardown() {
  cd "$ORIG_DIR" 2>/dev/null || cd /tmp
  rm -rf "$TEMP_REPO"
}

assert_exit() {
  TOTAL=$((TOTAL + 1))
  local expected="$1" actual="$2" msg="$3"
  if [ "$expected" -eq "$actual" ] 2>/dev/null; then
    echo "  ✅ $msg"; PASS=$((PASS + 1))
  else
    echo "  ❌ $msg (expected exit $expected, got $actual)"; FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  TOTAL=$((TOTAL + 1))
  local file="$1" pattern="$2" msg="$3"
  if grep -qiE "$pattern" "$file" 2>/dev/null; then
    echo "  ✅ $msg"; PASS=$((PASS + 1))
  else
    echo "  ❌ $msg ('$pattern' not in $(basename "$file"))"; FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  TOTAL=$((TOTAL + 1))
  local file="$1" pattern="$2" msg="$3"
  if ! grep -qiE "$pattern" "$file" 2>/dev/null; then
    echo "  ✅ $msg"; PASS=$((PASS + 1))
  else
    echo "  ❌ $msg ('$pattern' found in $(basename "$file"))"; FAIL=$((FAIL + 1))
  fi
}

assert_jq() {
  TOTAL=$((TOTAL + 1))
  local file="$1" expr="$2" msg="$3"
  if jq -e "$expr" "$file" >/dev/null 2>&1; then
    echo "  ✅ $msg"; PASS=$((PASS + 1))
  else
    echo "  ❌ $msg (jq failed on $(basename "$file"))"; FAIL=$((FAIL + 1))
  fi
}

# R8-009: corpus-style aggregation bridge.
#
# Three corpus tests (test-decision-mode.sh, test-proposals.sh,
# test-roundtable-classifier.sh) use private CORRECT/TOTAL counters
# because the spec's accuracy-floor pattern (e.g., 80%+ on a corpus)
# does not map naturally to per-row PASS/FAIL. Without this helper the
# harness globals stay at zero for those tests and the per-file summary
# reports `PASS=0 FAIL=0` even when 80 corpus rows ran.
#
# Signature: harness_assert_corpus <correct> <total> <msg> <threshold_pct>
# Semantics:
#   - TOTAL += total
#   - PASS  += correct
#   - if (correct * 100 / total) < threshold_pct:
#       FAIL += (total - correct), prints accuracy-breach diagnostic
#     else:
#       FAIL unchanged, prints accuracy-met diagnostic
#
# Rationale: mirrors the accuracy-floor semantics — a 95%-correct corpus
# is a passing test even though 5% of rows missed. Per-row honesty
# (always FAIL the misses) would break the spec's accuracy-floor pattern.
harness_assert_corpus() {
  local correct="$1" total="$2" msg="$3" threshold_pct="$4"
  TOTAL=$((TOTAL + total))
  PASS=$((PASS + correct))
  local pct=0
  if [ "$total" -gt 0 ]; then
    pct=$(( correct * 100 / total ))
  fi
  if [ "$pct" -lt "$threshold_pct" ]; then
    echo "  ❌ $msg (accuracy ${pct}% < ${threshold_pct}% floor): $correct/$total"
    FAIL=$((FAIL + (total - correct)))
  else
    echo "  ✅ $msg ($correct/$total at or above ${threshold_pct}% floor)"
  fi
}

# R9-002: fixed-row aggregation bridge.
#
# 16 fixed-row test files (test-adapter-contracts.sh, test-circuit-
# breaker-recovery.sh, test-decision-gate.sh, test-dream-cycle-
# completion.sh, test-fix-plan-emit.sh, test-owner-guard.sh,
# test-plan-recipes.sh, test-quarantine-regex.sh, test-self-test-
# runner.sh, test-sqlite-mirror.sh, test-start-memory-init.sh,
# test-state-rebuild.sh, test-threat-model-bootstrap.sh,
# test-wiring-mutation.sh, test-wiring-tdad-cross-phase.sh, plus
# transient peers) maintain private PASS/FAIL counters because each
# test's assertion semantics are heterogeneous and grew independently.
# Each file's top-level `PASS=0; FAIL=0` line is NOT a `local`
# declaration (bash has no lexical scoping at file scope), so the
# private counter and the harness global `PASS` are the SAME variable.
# By the time the test finishes, harness `PASS` already holds the
# per-file pass count; only `TOTAL` lags at zero because the file's
# private `assert_pass()` increments PASS but never TOTAL. This trips
# the R8-002 totals-invariant guard with exit 99 even on a clean tree.
#
# Signature: harness_assert_local <local_pass> <local_fail> <label>
# Semantics:
#   - Snapshots the two scalars into local positional variables
#     (collision-immune by construction — F-010 fix), so a caller's
#     mid-call `PASS`/`FAIL` reassignment cannot shadow the helper's
#     view of the per-file count.
#   - TOTAL += local_pass + local_fail  (close the per-file gap)
#   - PASS and FAIL are NOT re-added: the local-as-global aliasing
#     means harness `PASS`/`FAIL` already hold the per-file count.
#     Re-adding them would double-count and re-trip the invariant.
#   - Idempotent for zero values (no-op).
#
# Rationale: mirrors the intent of the informal tail-bridge in
# `test-pre-task-snapshot.sh` (close the F-009 family) without
# inheriting its double-count side effect. Each of the 16 fixed-row
# files calls this exactly once at end-of-body, after its own private
# summary print, before any cleanup that could exit non-zero.
harness_assert_local() {
  local local_pass="${1:-0}" local_fail="${2:-0}" label="${3:-unlabelled}"
  local local_total=$((local_pass + local_fail))
  if [ "$local_total" -eq 0 ]; then
    return 0
  fi
  TOTAL=$((TOTAL + local_total))
}

coverage_scan() {
  echo ""
  echo "━━━ Coverage Scan ━━━"
  local UNTESTED=0

  for hook in "$HOOKS_DIR"/*.sh; do
    [ -f "$hook" ] || continue
    local HOOK_NAME=$(basename "$hook" .sh)
    [[ "$HOOK_NAME" == _* ]] && continue
    if ! grep -rq "$HOOK_NAME" "$TEST_DIR"/test-*.sh 2>/dev/null; then
      echo "  ⚠️  UNTESTED HOOK: $HOOK_NAME.sh"
      UNTESTED=$((UNTESTED + 1))
    fi
  done

  for cmd in "$COMMANDS_DIR"/*.md; do
    [ -f "$cmd" ] || continue
    local CMD_NAME=$(basename "$cmd" .md)
    [[ "$CMD_NAME" == _* ]] && continue
    if ! grep -rq "$CMD_NAME" "$TEST_DIR"/test-*.sh 2>/dev/null; then
      echo "  ⚠️  UNTESTED COMMAND: $CMD_NAME.md"
      UNTESTED=$((UNTESTED + 1))
    fi
  done

  for schema in "$SCHEMAS_DIR"/*.json; do
    [ -f "$schema" ] || continue
    local SCHEMA_NAME=$(basename "$schema")
    if ! grep -rq "$SCHEMA_NAME" "$TEST_DIR"/test-*.sh 2>/dev/null; then
      echo "  ⚠️  UNTESTED SCHEMA: $SCHEMA_NAME"
      UNTESTED=$((UNTESTED + 1))
    fi
  done

  if [ "$UNTESTED" -gt 0 ]; then
    echo ""
    echo "  ⚠️  $UNTESTED components have no test coverage."
  else
    echo "  ✅ All components have test coverage"
  fi
}

harness_report() {
  coverage_scan
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "  APEX self-test: $PASS/$TOTAL passed, $FAIL failed"
  # R8-002: Totals-invariant guard — fail loud on counter inconsistency.
  # If PASS + FAIL > TOTAL, the runner's per-file aggregation drifted
  # (private-counter convention drift, double counting, missing
  # harness_assert_corpus call site). Treat the run as INFRASTRUCTURE
  # DEGRADED even when FAIL=0, because consumers (round-checker,
  # /apex:start, /apex:health-check) read the aggregate banner as
  # truth. Spec anchors: "Fail-loud, never fail-silent." +
  # "Honest scope over marketing scope." + "Proof-of-process beats
  # proof-of-promise." Exit code 99 is distinct from $FAIL so
  # consumers can disambiguate "test failed" from "runner counters
  # inconsistent" downstream.
  if [ $((PASS + FAIL)) -gt "$TOTAL" ]; then
    echo "  ❌ TOTALS INVARIANT VIOLATED: PASS=$PASS FAIL=$FAIL TOTAL=$TOTAL — runner reports inconsistent counters"
    echo "  ❌ INFRASTRUCTURE DEGRADED (counters)"
    echo "═══════════════════════════════════════════════"
    exit 99
  fi
  if [ "$FAIL" -gt 0 ]; then
    echo "  ❌ INFRASTRUCTURE DEGRADED"
  else
    echo "  ✅ ALL MECHANISMS VERIFIED"
  fi
  echo "═══════════════════════════════════════════════"
  exit "$FAIL"
}

# R7-001: subshell-isolation sidecar.
# Writes the current PASS/FAIL/TOTAL/SKIP counters to the file named in
# $HARNESS_COUNTERS_FILE so a parent shell can aggregate them after the
# subshell exits. Safe to call multiple times; idempotent. Used by
# self-test.sh to wrap each per-test `source` in a subshell whose `exit`
# does not terminate the runner loop.
harness_export_counters() {
  local target="${HARNESS_COUNTERS_FILE:-}"
  [ -n "$target" ] || return 0
  printf '%s %s %s %s\n' "${PASS:-0}" "${FAIL:-0}" "${TOTAL:-0}" "${SKIP:-0}" > "$target"
}
