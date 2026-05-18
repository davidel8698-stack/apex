#!/usr/bin/env bash
# R16-603 (F-603, IMP-001, Mythos §4.1.1 INCIDENT 2B):
# critic STEP 1.5 GIT TRACE VERIFICATION test.
#
# Spec anchors (from apex-spec.md after R16 amendment):
#   "framework/agents/critic.md חייב לאמת שכל קובץ ב-RESULT.json.files_modified[]
#    מופיע ב-git log --since=task_start_sha או ב-git diff HEAD או ב-
#    git status --porcelain; אם אף לא אחד מן השלושה — verdict = FAIL עם
#    cause = CRITICAL (cover-up)."
#
# This test is a static / prose-anchor verifier — it does NOT invoke
# the critic LLM agent (cost-prohibitive in CI). It verifies that the
# prose in critic.md describes the algorithm correctly and that
# adjacent contracts (do-not-touch zones, schema field, executor
# anchor capture, snapshot capture) are in place. The integration-side
# proof (a real cover-up scenario) is covered by the round-checker
# E2E pass when the framework runs end-to-end; here we lock the
# *static* contract so the prose cannot regress silently.
#
# Six assertion families:
#   A. Anchor / phrase presence in critic.md.
#   B. Three-way membership check is described (log + diff + status).
#   C. Defensive no-git skip path is described.
#   D. Do-not-touch zones preserved (WHAT YOU NEVER RECEIVE, STEP 2/3/4
#      ordering, FILESYSTEM-LEVEL VERIFICATION block).
#   E. Upstream contracts in place: task_start_sha in schema/required,
#      captured by pre-task-snapshot.sh, written by executor STEP 0.
#   F. Cover-up cause string is FAIL with cause = CRITICAL (not a
#      fourth verdict level).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CRITIC="$REPO_ROOT/framework/agents/critic.md"
SCHEMA="$REPO_ROOT/framework/schemas/RESULT.schema.json"
SNAPSHOT="$REPO_ROOT/framework/hooks/pre-task-snapshot.sh"
EXECUTOR="$REPO_ROOT/framework/agents/executor.md"

LOCAL_PASS=0
LOCAL_FAIL=0
LOCAL_SKIP=0
ok()   { echo "  ✅ $1"; LOCAL_PASS=$((LOCAL_PASS+1)); }
nope() { echo "  ❌ $1"; LOCAL_FAIL=$((LOCAL_FAIL+1)); }
skip() { echo "  ⏭  $1"; LOCAL_SKIP=$((LOCAL_SKIP+1)); }

echo "=== R16-603: critic STEP 1.5 GIT TRACE VERIFICATION test ==="

# 0. Files exist.
for f in "$CRITIC" "$SCHEMA" "$SNAPSHOT" "$EXECUTOR"; do
  if [ ! -f "$f" ]; then
    nope "0: required input missing — $f"
    echo "$LOCAL_PASS/$((LOCAL_PASS+LOCAL_FAIL)) passed (skipped: $LOCAL_SKIP)"
    exit 1
  fi
done
ok "0: all required inputs exist"

# --- A. Anchor / phrase presence in critic.md ----------------------
if grep -qE "STEP 1\.5" "$CRITIC"; then
  ok "A1: critic.md declares STEP 1.5"
else
  nope "A1: critic.md missing STEP 1.5"
fi
if grep -qE "GIT TRACE VERIFICATION" "$CRITIC"; then
  ok "A2: critic.md declares GIT TRACE VERIFICATION"
else
  nope "A2: critic.md missing GIT TRACE VERIFICATION"
fi
if grep -qE "task_start_sha" "$CRITIC"; then
  ok "A3: critic.md references task_start_sha (anchor field)"
else
  nope "A3: critic.md missing task_start_sha reference"
fi

# --- B. Three-way membership check described ----------------------
if grep -qE "git log" "$CRITIC"; then
  ok "B1: critic.md prescribes git log (committed view)"
else
  nope "B1: critic.md missing git log mention"
fi
if grep -qE "git diff" "$CRITIC"; then
  ok "B2: critic.md prescribes git diff (unstaged-modified view)"
else
  nope "B2: critic.md missing git diff mention"
fi
if grep -qE "git status" "$CRITIC"; then
  ok "B3: critic.md prescribes git status (untracked-new view)"
else
  nope "B3: critic.md missing git status mention"
fi

# --- C. Defensive no-git skip path -------------------------------
if grep -qE "SKIPPED \(no git\)" "$CRITIC"; then
  ok "C1: critic.md describes SKIPPED (no git) defensive path"
else
  nope "C1: critic.md missing SKIPPED (no git) defensive path"
fi

# --- D. Do-not-touch zones preserved -----------------------------
if grep -qE "WHAT YOU NEVER RECEIVE" "$CRITIC"; then
  ok "D1: WHAT YOU NEVER RECEIVE section preserved"
else
  nope "D1: WHAT YOU NEVER RECEIVE section missing (preservation contract violated)"
fi
if grep -qE "FILESYSTEM-LEVEL VERIFICATION" "$CRITIC"; then
  ok "D2: FILESYSTEM-LEVEL VERIFICATION block preserved"
else
  nope "D2: FILESYSTEM-LEVEL VERIFICATION block missing"
fi
# STEP 1.5 must come BEFORE STEP 2 ordering-wise.
STEP_15_LINE=$(grep -nE "STEP 1\.5" "$CRITIC" | head -1 | cut -d: -f1)
STEP_2_LINE=$(grep -nE "\*\*STEP 2:" "$CRITIC" | head -1 | cut -d: -f1)
if [ -n "$STEP_15_LINE" ] && [ -n "$STEP_2_LINE" ] && [ "$STEP_15_LINE" -lt "$STEP_2_LINE" ]; then
  ok "D3: STEP 1.5 is positioned before STEP 2 (ordering preserved)"
else
  nope "D3: STEP 1.5 ordering broken (1.5@$STEP_15_LINE, 2@$STEP_2_LINE)"
fi

# --- E. Upstream contracts in place ------------------------------
if command -v jq >/dev/null 2>&1; then
  TYPE=$(jq -r '.properties.task_start_sha.type' "$SCHEMA" 2>/dev/null)
  if [ "$TYPE" = "string" ]; then
    ok "E1: RESULT.schema.json properties.task_start_sha.type == string"
  else
    nope "E1: RESULT.schema.json properties.task_start_sha.type != string (got: $TYPE)"
  fi
  REQUIRED_HIT=$(jq -r '.required | index("task_start_sha")' "$SCHEMA" 2>/dev/null)
  if [ "$REQUIRED_HIT" != "null" ] && [ -n "$REQUIRED_HIT" ]; then
    ok "E2: RESULT.schema.json required[] includes task_start_sha"
  else
    nope "E2: RESULT.schema.json required[] missing task_start_sha"
  fi
else
  skip "E1-E2: jq not on PATH — schema field assertions deferred"
fi
if grep -qE "task_start_sha.*rev-parse HEAD|rev-parse HEAD.*task_start_sha" "$SNAPSHOT"; then
  ok "E3: pre-task-snapshot.sh captures task_start_sha via git rev-parse HEAD"
else
  nope "E3: pre-task-snapshot.sh missing task_start_sha capture"
fi
if grep -qE "task_start_sha" "$EXECUTOR"; then
  ok "E4: executor.md references task_start_sha (STEP 0 anchor capture)"
else
  nope "E4: executor.md missing task_start_sha reference"
fi

# --- F. Cover-up classification ----------------------------------
if grep -qE "cover.?up" "$CRITIC"; then
  ok "F1: critic.md uses cover-up terminology"
else
  nope "F1: critic.md missing cover-up terminology"
fi
if grep -qE "CRITICAL \(cover-up\)" "$CRITIC"; then
  ok "F2: critic.md classifies cover-up as CRITICAL (correct cause channel)"
else
  nope "F2: critic.md missing CRITICAL (cover-up) cause classifier"
fi
# Verdict-level guard: must NOT introduce a fourth verdict level.
if grep -qE "^- COVER_UP:|^COVER_UP:" "$CRITIC"; then
  nope "F3: critic.md introduces forbidden fourth verdict level COVER_UP"
else
  ok "F3: critic.md does not invent a fourth verdict level — cover-up flows through FAIL"
fi

# --- Bridge to harness globals ----------------------------------
if declare -F harness_assert_corpus >/dev/null 2>&1; then
  LOCAL_TOTAL=$((LOCAL_PASS + LOCAL_FAIL))
  harness_assert_corpus "$LOCAL_PASS" "$LOCAL_TOTAL" "critic STEP 1.5 git-trace verification" 100
fi

LOCAL_TOTAL=$((LOCAL_PASS+LOCAL_FAIL))
echo ""
echo "$LOCAL_PASS/$LOCAL_TOTAL passed (skipped: $LOCAL_SKIP)"
[ "$LOCAL_FAIL" -eq 0 ]
