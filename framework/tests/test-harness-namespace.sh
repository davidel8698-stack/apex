#!/usr/bin/env bash
# test-harness-namespace.sh — R10-008 (F-105) meta-test.
#
# Enforces the harness namespace contract documented at the top of
# framework/tests/_harness.sh:
#
#   The four globals PASS, FAIL, TOTAL, SKIP are harness-owned. Test
#   files must NOT declare these names at file scope with a literal
#   value (e.g., `PASS=0`).
#
# Bash has no lexical scoping at file scope, so a file-scope literal
# assignment to any of the four names silently aliases the harness
# global. R9-002's harness_assert_local protects the existing fixed-row
# + corpus consumers via positional snapshotting, but the broader
# test-author contract is uncodified. This meta-test scans every
# framework/tests/test-*.sh file at runner time and fails if a NEW
# file (outside the historical allow-list snapshotted at R10-008
# landing) introduces fresh shadowing.
#
# Allow-list semantics (state-derived, not literal):
#   - The snapshot below was captured at R10-008 landing time: every
#     test-*.sh file that currently has a file-scope literal
#     assignment of PASS/FAIL/TOTAL/SKIP is allow-listed.
#   - If a legacy shadowing file is later removed from disk, its name
#     stays in the allow-list harmlessly — no test file means no
#     scan match means no failure.
#   - If a legacy shadowing file is refactored to remove its
#     shadowing, the meta-test still passes; the allow-list entry
#     becomes a dead reference, also harmless.
#   - If a NEW file (not in the allow-list) introduces shadowing,
#     the meta-test fails with the file name and offending line.
#
# Pattern semantics: `^(PASS|FAIL|TOTAL|SKIP)=[^$]` — matches a
# file-scope assignment to a literal value (anything that doesn't
# start with `$`). The arithmetic-aggregation idiom
# `PASS=$((PASS + 1))` is NOT a violation: it's contractually
# equivalent to what every assert_* helper does internally.

set -uo pipefail

# Use BASH_SOURCE so this works both as a standalone script and when
# sourced by self-test.sh's runner.
NS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source _harness.sh ONLY if running standalone. When run via
# self-test.sh, the runner has already sourced _harness.sh and the
# harness globals (PASS/FAIL/TOTAL/SKIP) belong to it. We must not
# re-source.
if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ ! -f "$NS_SCRIPT_DIR/_harness.sh" ]; then
    echo "  ❌ Harness not found at $NS_SCRIPT_DIR/_harness.sh"
    exit 1
  fi
  # shellcheck disable=SC1091
  source "$NS_SCRIPT_DIR/_harness.sh"
fi

# Historical allow-list — snapshot of test files that already had
# file-scope literal assignments to PASS/FAIL/TOTAL/SKIP at R10-008
# landing time. State-derived: if any of these files is removed or
# refactored, the allow-list entry simply becomes inert.
NS_ALLOW_LIST=(
  test-adapter-contracts.sh
  test-agent-dispatch.sh
  test-agent-lint.sh
  test-ast-kb-check.sh
  test-ci-scan-wiring.sh
  test-circuit-breaker-recovery.sh
  test-command-structure.sh
  test-corpus-thresholds.sh
  test-decision-gate.sh
  test-decision-mode.sh
  test-dream-cycle-completion.sh
  test-fix-plan-emit.sh
  test-harness-exit-trap.sh
  test-hook-classification.sh
  test-learnings-emit.sh
  test-owner-guard.sh
  test-phantom-check.sh
  test-plan-recipes.sh
  test-pre-task-snapshot.sh
  test-proposals.sh
  test-quarantine-regex.sh
  test-roundtable-classifier.sh
  test-safety-net-commands.sh
  test-self-test-runner.sh
  test-sqlite-mirror.sh
  test-start-memory-init.sh
  test-state-rebuild.sh
  test-sync-coverage.sh
  test-sync-doc-coverage.sh
  test-threat-model-bootstrap.sh
  test-wiring-mutation.sh
  test-wiring-tdad-cross-phase.sh
)

ns_is_allowed() {
  local name="$1" allowed
  for allowed in "${NS_ALLOW_LIST[@]}"; do
    [ "$name" = "$allowed" ] && return 0
  done
  return 1
}

NS_NEW_VIOLATIONS=()

shopt -s nullglob
for test_file in "$NS_SCRIPT_DIR"/test-*.sh; do
  bn="$(basename "$test_file")"
  # Don't scan ourselves.
  [ "$bn" = "test-harness-namespace.sh" ] && continue
  if grep -qE '^(PASS|FAIL|TOTAL|SKIP)=[^$]' "$test_file"; then
    if ! ns_is_allowed "$bn"; then
      first_match="$(grep -nE '^(PASS|FAIL|TOTAL|SKIP)=[^$]' "$test_file" | head -1)"
      NS_NEW_VIOLATIONS+=("$bn:$first_match")
    fi
  fi
done

# Increment harness globals directly (the namespace contract obeyed
# by example: we use PASS/FAIL/TOTAL as the harness counters, not as
# private locals). Each assertion increments TOTAL by 1 and either
# PASS or FAIL by 1.
ns_violation_count="${#NS_NEW_VIOLATIONS[@]}"

TOTAL=$((TOTAL + 1))
if [ "$ns_violation_count" -eq 0 ]; then
  echo "  ✅ R10-008-a: no NEW file-scope shadowing of PASS/FAIL/TOTAL/SKIP"
  PASS=$((PASS + 1))
else
  echo "  ❌ R10-008-a: NEW file(s) shadow harness namespace globals (PASS/FAIL/TOTAL/SKIP):"
  for v in "${NS_NEW_VIOLATIONS[@]}"; do
    echo "       $v"
  done
  echo "       Rename your file-scope counters (e.g., LOCAL_PASS, ROW_TOTAL)."
  echo "       See # RESERVED NAMESPACE block at the top of _harness.sh."
  FAIL=$((FAIL + 1))
fi

TOTAL=$((TOTAL + 1))
if grep -q 'RESERVED NAMESPACE' "$NS_SCRIPT_DIR/_harness.sh"; then
  echo "  ✅ R10-008-b: # RESERVED NAMESPACE block present in _harness.sh"
  PASS=$((PASS + 1))
  ns_header_present=1
else
  echo "  ❌ R10-008-b: # RESERVED NAMESPACE block missing from _harness.sh header"
  FAIL=$((FAIL + 1))
  ns_header_present=0
fi

# Standalone exit semantics: if running outside the runner, exit
# non-zero on any new violation so a developer running this directly
# gets a clean signal. When run via the runner, the runner reads our
# PASS/FAIL contributions from the sidecar.
if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ "$ns_violation_count" -gt 0 ] || [ "$ns_header_present" -ne 1 ]; then
    exit 1
  fi
  exit 0
fi
