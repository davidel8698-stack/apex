#!/usr/bin/env bash
# R10-001: generalised sync-coverage regression guard.
# tag: slow
# (R-020-003: empirically-confirmed long pole — case C-4 standalone
#  multi-minute runtime, R19 N-W2-01; `run-all.sh --quick` skips it.)
#
# Asserts the framework->install delivery contract for EVERY
# `copy_tree` and explicit `copy_file "$FRAMEWORK_ROOT/..."` declared
# by `framework/scripts/sync-to-claude.sh`. Sibling to (and NOT a
# replacement for) `test-sync-doc-coverage.sh`, which remains the
# pinned per-file guard for the docs subset (case C-7).
#
# Why this exists:
#   `test-sync-doc-coverage.sh` covers only `framework/docs/`. Every
#   other `copy_tree` source (agents, modules, commands/apex, hooks,
#   apex-skills, apex-workflows, schemas, tests, test-fixtures,
#   adapters) and every explicit `copy_file "$FRAMEWORK_ROOT/<file>"`
#   was unguarded prior to this test. F-103 (R10 audit, security-
#   policy.md undelivered) was the live symptom; F-001 (templates
#   trio, R9-closed) and F-006 (apex-debug.py, R9-closed) were
#   earlier symptoms of the same per-file-anchor scaling failure.
#
# Source-of-truth: `sync-to-claude.sh` itself. The test parses the
# script's own `copy_tree` and `copy_file` lines via grep, so adding
# a new delivery to the script automatically extends the assertion
# without test edits. Conversely, removing a delivery line that the
# script needs (or forgetting to add one for a new file) trips the
# guard.
#
# Spec anchors:
#   "Information boundaries ARE the architecture."
#   "Schema as contract. Schema sync as contract."
#   "Multi-platform from day one." (apex-spec.md, principle-lines)

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SYNC_SH="$REPO_ROOT/framework/scripts/sync-to-claude.sh"
FRAMEWORK_ROOT="$REPO_ROOT/framework"

PASS=0
FAIL=0

ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
nope() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== R10-001: sync-to-claude.sh generalised delivery coverage ==="

# Pre-flight: required artifacts exist.
if [ ! -f "$SYNC_SH" ]; then
  nope "C-1: sync-to-claude.sh not found at $SYNC_SH"
  echo "$PASS/$((PASS+FAIL)) passed"
  exit 1
fi
ok "C-1: sync-to-claude.sh exists"

if [ ! -d "$FRAMEWORK_ROOT" ]; then
  nope "C-2: framework root not found at $FRAMEWORK_ROOT"
  echo "$PASS/$((PASS+FAIL)) passed"
  exit 1
fi
ok "C-2: framework root exists"

# Parse declarations from the script source.
# C-3a: every `copy_tree "$FRAMEWORK_ROOT/<dir>" ...` invocation in the
# body. Skip the function definition itself (line starting with
# `copy_tree() {`).
TREE_SOURCES=()
while IFS= read -r line; do
  # Extract the first quoted argument after `copy_tree`.
  src=$(printf '%s\n' "$line" | sed -n 's/^copy_tree[[:space:]]\+"\([^"]*\)".*/\1/p')
  [ -n "$src" ] || continue
  # Resolve $FRAMEWORK_ROOT to the live path.
  src_resolved="${src//\$FRAMEWORK_ROOT/$FRAMEWORK_ROOT}"
  TREE_SOURCES+=("$src_resolved")
done < <(grep -E '^copy_tree[[:space:]]+"' "$SYNC_SH")

if [ "${#TREE_SOURCES[@]}" -ge 1 ]; then
  ok "C-3a: parsed ${#TREE_SOURCES[@]} copy_tree declaration(s) from sync-to-claude.sh"
else
  nope "C-3a: no copy_tree declarations found in sync-to-claude.sh"
fi

# C-3b: every `copy_file "$FRAMEWORK_ROOT/<file>" ...` invocation
# whose source begins with $FRAMEWORK_ROOT. Skip non-framework sources
# (e.g., the repo-root `$FRAMEWORK_ROOT/../CLAUDE-TEMPLATE.md` line) by
# resolving and rejecting paths that escape framework/.
FILE_SOURCES=()
while IFS= read -r line; do
  src=$(printf '%s\n' "$line" | sed -n 's/^copy_file[[:space:]]\+"\([^"]*\)".*/\1/p')
  [ -n "$src" ] || continue
  # Only accept sources that begin with $FRAMEWORK_ROOT/ literally.
  case "$src" in
    '$FRAMEWORK_ROOT/'*) ;;
    *) continue ;;
  esac
  src_resolved="${src//\$FRAMEWORK_ROOT/$FRAMEWORK_ROOT}"
  # Tolerate `$FRAMEWORK_ROOT/../something` (escapes framework/) by
  # canonicalizing and rejecting paths outside framework/.
  case "$src_resolved" in
    *"/../"*) continue ;;
  esac
  FILE_SOURCES+=("$src_resolved")
done < <(grep -E '^copy_file[[:space:]]+"\$FRAMEWORK_ROOT/' "$SYNC_SH")

if [ "${#FILE_SOURCES[@]}" -ge 1 ]; then
  ok "C-3b: parsed ${#FILE_SOURCES[@]} explicit copy_file \$FRAMEWORK_ROOT/* declaration(s)"
else
  nope "C-3b: no explicit copy_file \$FRAMEWORK_ROOT/* declarations found"
fi

# Sandbox sync once. Use HOME override to redirect the script's
# CLAUDE_ROOT="$HOME/.claude" computation into the sandbox.
SANDBOX="$(mktemp -d)"
HOME="$SANDBOX" bash "$SYNC_SH" --skip-settings >/dev/null 2>&1 || true
SANDBOX_CLAUDE="$SANDBOX/.claude"

if [ ! -d "$SANDBOX_CLAUDE" ]; then
  nope "C-4: sandbox sync produced no $SANDBOX/.claude/ directory"
  echo "$PASS/$((PASS+FAIL)) passed"
  rm -rf "$SANDBOX"
  exit 1
fi
ok "C-4: sandboxed sync materialised $SANDBOX/.claude/"

# C-5: per-tree total-delivery assertion. For each declared
# `copy_tree` source, every source file (by relative path) must land
# at the corresponding destination. The assertion is "all source
# files reach destination", NOT "destination file-count equals source
# file-count" — the plan's question-10 non-obvious-insight #10
# anticipates that some destinations (e.g., agents/) are SHARED with
# sibling delivery paths (copy_modules_specialists flattens module
# agent.md files into agents/specialist/, producing more destination
# files than the copy_tree source alone). The total-delivery semantic
# preserves the regression guarantee (a missing source file fails)
# without false-positives on shared destinations.
for src_dir in "${TREE_SOURCES[@]}"; do
  if [ ! -d "$src_dir" ]; then
    # Source missing — script's `if [[ ! -d "$src_dir" ]]; then return`
    # branch silently skips. Mirror that tolerance.
    ok "tree-walk: $src_dir source absent, copy_tree skipped silently (vacuous PASS)"
    continue
  fi
  rel="${src_dir#$FRAMEWORK_ROOT/}"
  dst_dir="$SANDBOX_CLAUDE/$rel"
  src_count=$(find "$src_dir" -type f | wc -l | tr -d ' ')
  if [ ! -d "$dst_dir" ]; then
    nope "tree-walk: $rel — destination $dst_dir absent (source had $src_count file(s))"
    continue
  fi
  # Walk every source file and assert its relative path exists in dst.
  missing=0
  while IFS= read -r src_file; do
    rel_in_tree="${src_file#$src_dir/}"
    [ -f "$dst_dir/$rel_in_tree" ] || missing=$((missing+1))
  done < <(find "$src_dir" -type f)
  dst_count=$(find "$dst_dir" -type f | wc -l | tr -d ' ')
  if [ "$missing" -eq 0 ]; then
    if [ "$src_count" -eq "$dst_count" ]; then
      ok "tree-walk: $rel — $src_count file(s) delivered (source = destination)"
    else
      # Shared destination: dst has more files than src (e.g., from a
      # sibling delivery path). Total-delivery still holds.
      ok "tree-walk: $rel — $src_count source file(s) delivered (destination has $dst_count, shared with sibling deliveries)"
    fi
  else
    nope "tree-walk: $rel — $missing source file(s) missing in destination (source=$src_count, destination=$dst_count)"
  fi
done

# C-6: per-file delivery. For each explicit copy_file source under
# $FRAMEWORK_ROOT/, the destination must exist. Destination relative
# path is the tail after framework/ (e.g.,
# `framework/apex-branding.md` -> `apex-branding.md`).
for src_file in "${FILE_SOURCES[@]}"; do
  if [ ! -f "$src_file" ]; then
    # Source missing — copy_file's `if [[ ! -f "$src" ]]; then return`
    # branch silently skips. Mirror that tolerance.
    ok "file-walk: $src_file source absent, copy_file skipped silently (vacuous PASS)"
    continue
  fi
  rel="${src_file#$FRAMEWORK_ROOT/}"
  dst_file="$SANDBOX_CLAUDE/$rel"
  if [ -f "$dst_file" ]; then
    ok "file-walk: $rel — delivered to sandbox"
  else
    nope "file-walk: $rel — NOT delivered (source $src_file present, destination $dst_file absent)"
  fi
done

rm -rf "$SANDBOX"

# --- R-019-002: IMP-036 name-level first-deployment gate regression ---
#
# These cases exercise run_first_deployment_gate's name-level failure-set
# comparison (added in R-019-002). The gate's measurement input is
# `run-all.sh --json` and a prior snapshot under
# install-snapshots/. To drive the comparison deterministically WITHOUT
# touching the real run-all.sh, each case builds a throwaway framework
# tree: a copy of sync-to-claude.sh plus a STUB tests/run-all.sh that
# echoes a crafted --json line. The gate computes FRAMEWORK_ROOT from
# the script's own location, so the stub runner is the one it invokes.
# A crafted prior snapshot is pre-seeded into the sandbox HOME's
# install-snapshots/ directory. The gate runs (and may exit 2) before
# any copy_tree, so a BLOCK is observable as process exit code 2.
#
# Spec anchor (IMP-036): "0 regressions vs the previous version" — a
# test green in the prior install must BLOCK the install if it fails in
# the new run, even when the total failure COUNT is unchanged.

# run_gate_fixture — drive run_first_deployment_gate with crafted data.
#   $1 new-run JSON (what the stub run-all.sh --json emits)
#   $2 prior-snapshot JSON, or the literal "NONE" for no prior snapshot
# Echoes the gate's process exit code.
run_gate_fixture() {
  local new_json="$1" prev_json="$2"
  local gate_sandbox gate_fw gate_home gate_rc
  gate_sandbox="$(mktemp -d)"
  gate_fw="$gate_sandbox/framework"
  gate_home="$gate_sandbox/home"
  mkdir -p "$gate_fw/scripts" "$gate_fw/tests" "$gate_home/.claude"
  # Copy the real sync script into the throwaway framework tree.
  cp "$SYNC_SH" "$gate_fw/scripts/sync-to-claude.sh"
  # Stub run-all.sh: emit the crafted JSON only for --json; the gate
  # invokes it as `bash "$runner" --json`.
  cat > "$gate_fw/tests/run-all.sh" <<STUB
#!/usr/bin/env bash
if [ "\${1:-}" = "--json" ]; then
  printf '%s\n' '$new_json'
fi
exit 0
STUB
  chmod +x "$gate_fw/tests/run-all.sh"
  # Seed the prior snapshot unless the caller asked for none.
  if [ "$prev_json" != "NONE" ]; then
    mkdir -p "$gate_home/.claude/install-snapshots"
    printf '%s\n' "$prev_json" \
      > "$gate_home/.claude/install-snapshots/20200101-000000.json"
  fi
  # Run the gate. --skip-settings keeps the gate active (it runs before
  # the settings merge) while avoiding any settings.json mutation.
  # Unset the recursion guard so the gate body actually executes.
  (
    unset APEX_FIRST_DEPLOYMENT_GATE_RUNNING
    unset APEX_SKIP_FIRST_DEPLOYMENT_GATE
    HOME="$gate_home" bash "$gate_fw/scripts/sync-to-claude.sh" --skip-settings
  ) >/dev/null 2>&1
  gate_rc=$?
  rm -rf "$gate_sandbox"
  echo "$gate_rc"
}

# Case C-8: equal failure COUNT, different failing test NAME → BLOCK.
# Prior snapshot: 1 failure (test-old.sh). New run: 1 failure
# (test-new.sh). Count comparison passes (1 == 1); the name-level
# branch must catch that test-new.sh is a NEW failure and exit 2.
rc=$(run_gate_fixture \
  '{"total":3,"passed":2,"failed":1,"skipped":0,"failed_names":"test-new.sh"}' \
  '{"total":3,"passed":2,"failed":1,"skipped":0,"failed_names":"test-old.sh"}')
if [ "$rc" -eq 2 ]; then
  ok "C-8: equal-count name-swap regression BLOCKs the gate (exit 2)"
else
  nope "C-8: equal-count name-swap should BLOCK with exit 2, got exit $rc"
fi

# Case C-9: previously-failing test fixed (failure set shrinks) → no
# name-level block. Prior snapshot: test-old.sh failing. New run: zero
# failures. newly_failing = {} \ {test-old.sh} = empty → gate must NOT
# block on name-level grounds (and the count check also passes:
# new_failed 0 <= prev_failed 1, new_passed 3 >= prev_passed 2).
rc=$(run_gate_fixture \
  '{"total":3,"passed":3,"failed":0,"skipped":0,"failed_names":""}' \
  '{"total":3,"passed":2,"failed":1,"skipped":0,"failed_names":"test-old.sh"}')
if [ "$rc" -eq 0 ]; then
  ok "C-9: a fixed prior failure does NOT block the gate (exit 0)"
else
  nope "C-9: failure-fixed run should NOT block, got exit $rc"
fi

# Case C-10: backward-compat — prior snapshot has NO failed_names key.
# Older snapshots predate the field. The gate must treat the missing
# key as an empty/unknown prior-failure set, neither crashing nor
# spuriously blocking; it degrades to count-level for that comparison.
# Here new run has 0 failures and >= prior passed, so the count check
# passes and the gate must exit 0 cleanly despite the missing key.
rc=$(run_gate_fixture \
  '{"total":3,"passed":3,"failed":0,"skipped":0,"failed_names":""}' \
  '{"total":3,"passed":2,"failed":1}')
if [ "$rc" -eq 0 ]; then
  ok "C-10: missing failed_names key — gate degrades gracefully (exit 0)"
else
  nope "C-10: missing-failed_names prior snapshot should not block/crash, got exit $rc"
fi

# --- R-020-001: IMP-036 first-deployment gate flake tolerance ---
#
# Spec anchor (IMP-036 / F-020-001): a test that failed once and PASSED
# on run-all.sh's retry-once is recorded as a PASS and listed in the new
# run's "flaky_tests" field — it is NOT a regression and MUST NOT block
# the install. R-019-002 made the gate strictly more sensitive to flaky
# reds; R-020-001's flake tolerance is the matching gate-side change.

# Case C-11: a retry-recovered (flaky) test does NOT block the gate.
# New run: 0 failures, but test-flaky.sh failed-then-recovered, so it is
# in flaky_tests and absent from failed_names. Prior snapshot: that test
# was green. The gate must exit 0 — a flaky red is not a regression.
rc=$(run_gate_fixture \
  '{"total":3,"passed":3,"failed":0,"skipped":0,"failed_names":"","flaky_tests":"test-flaky.sh"}' \
  '{"total":3,"passed":3,"failed":0,"skipped":0,"failed_names":""}')
if [ "$rc" -eq 0 ]; then
  ok "C-11: a retry-recovered (flaky) test does NOT block the gate (exit 0)"
else
  nope "C-11: flaky retry-recovered test should NOT block, got exit $rc"
fi

# Case C-12: defense-in-depth — even if a foreign/old runner listed a
# name in BOTH failed_names and flaky_tests, the gate excludes the
# flaky-recovered name from the newly_failing set and must NOT block.
# Prior snapshot: that name was green. Count check: new_failed 1 <=
# prev_failed 1 (prior also had one failure on a different name), so
# only the name-level branch is exercised.
rc=$(run_gate_fixture \
  '{"total":3,"passed":2,"failed":1,"skipped":0,"failed_names":"test-flaky.sh","flaky_tests":"test-flaky.sh"}' \
  '{"total":3,"passed":2,"failed":1,"skipped":0,"failed_names":"test-old.sh"}')
if [ "$rc" -eq 0 ]; then
  ok "C-12: a name in both failed_names and flaky_tests is excluded — gate does NOT block (exit 0)"
else
  nope "C-12: flaky-listed name should be excluded from newly_failing, got exit $rc"
fi

# Case C-13: a GENUINE new hard failure still BLOCKs — the flake
# tolerance must not mask a real regression. New run: test-new.sh fails
# hard (in failed_names, NOT in flaky_tests). Prior snapshot: that test
# was green. The gate must still exit 2.
rc=$(run_gate_fixture \
  '{"total":3,"passed":2,"failed":1,"skipped":0,"failed_names":"test-new.sh","flaky_tests":""}' \
  '{"total":3,"passed":3,"failed":0,"skipped":0,"failed_names":""}')
if [ "$rc" -eq 2 ]; then
  ok "C-13: a genuine new hard failure still BLOCKs the gate (exit 2)"
else
  nope "C-13: genuine new hard failure should BLOCK with exit 2, got exit $rc"
fi

TOTAL=$((PASS+FAIL))
echo ""
echo "$PASS/$TOTAL passed"

# Bridge per-file counts into harness globals so the runner's
# per-file aggregation reports them honestly. Mirrors the convention
# established by R9-002 (`harness_assert_local`); falls back silently
# when invoked outside the runner (sourced harness absent).
if command -v harness_assert_local >/dev/null 2>&1; then
  harness_assert_local "$PASS" "$FAIL" "test-sync-coverage"
fi

[ "$FAIL" -eq 0 ]
