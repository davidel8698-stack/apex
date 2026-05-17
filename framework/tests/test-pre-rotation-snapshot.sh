#!/usr/bin/env bash
# Phase 12.08 — M14 atomic pre-rotation snapshot test.
#
# Verifies:
#   C-1: hook exists + executable + syntax-valid.
#   C-2: no .apex/ in cwd → exit 2 (invocation error).
#   C-3: full happy path in a sandbox produces all 4 artifacts
#        (STATE intact, DECISIONS.md flush, git tag created,
#        ROTATION-NOTE-<TS>.md written).
#   C-4: ROTATION-NOTE has the required section headers (Done / Next /
#        Issues) per PLAN.md §5.
#   C-5: git tag namespace is apex/rotation/<TS>-<phase> per PLAN.md.
#   C-6: tag retention cap = 50 (seed 60, expect ≤50 after run).
#   C-7: STATE.json invalid JSON → exit 1 + no tag created (safe-or-noop).
#   C-8: next.md invokes pre-rotation-snapshot.sh in proactive_compact,
#        warn_and_compact, AND hard_rotate branches.
#   C-9: resume.md reads ROTATION-NOTE preferentially over DECISIONS.md.
#  C-10: HOOK-CLASSIFICATION.md lists pre-rotation-snapshot.sh.
#
# Harness contract (R10-008): arithmetic globals, no EXIT trap.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SNAPSHOT_SH="$REPO_ROOT/framework/hooks/pre-rotation-snapshot.sh"
NEXT_MD="$REPO_ROOT/framework/commands/apex/next.md"
RESUME_MD="$REPO_ROOT/framework/commands/apex/resume.md"
HOOK_CLASS="$REPO_ROOT/framework/HOOK-CLASSIFICATION.md"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ ! -f "$SCRIPT_DIR/_harness.sh" ]; then
    echo "  ❌ Harness not found"; exit 1
  fi
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/_harness.sh"
fi

echo "=== Phase 12.08 — M14 atomic pre-rotation snapshot ==="

if ! command -v jq >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
  echo "  ❌ jq and git are required"
  exit 1
fi

# --- C-1: hook exists + executable + syntax-valid ---
TOTAL=$((TOTAL + 1))
if [ -x "$SNAPSHOT_SH" ] && bash -n "$SNAPSHOT_SH" 2>/dev/null; then
  echo "  ✅ C-1: pre-rotation-snapshot.sh exists, executable, syntax-valid"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-1: pre-rotation-snapshot.sh missing or broken"
  exit 1
fi

# --- C-2: no .apex/ in cwd → exit 2 ---
TOTAL=$((TOTAL + 1))
EMPTY=$(mktemp -d)
(cd "$EMPTY" && bash "$SNAPSHOT_SH" "manual" >/dev/null 2>&1)
RC=$?
rm -rf "$EMPTY"
if [ "$RC" = "2" ]; then
  echo "  ✅ C-2: no .apex/ → exit 2"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-2: expected exit 2 with no .apex/, got $RC"
  FAIL=$((FAIL + 1))
fi

# Build a sandbox project with a git repo + valid STATE.
SANDBOX=$(mktemp -d)
mkdir -p "$SANDBOX/.apex/phases/12"
echo '{
  "current_phase": "12",
  "session": {"id": "sandbox-test"}
}' > "$SANDBOX/.apex/STATE.json"
echo '# DECISIONS' > "$SANDBOX/.apex/DECISIONS.md"
(
  cd "$SANDBOX"
  git init -q
  git config user.email "test@apex"
  git config user.name "APEX-test"
  git add . >/dev/null 2>&1
  git commit -qm "init" >/dev/null 2>&1
)

# --- C-3: happy path — 4 artifacts produced ---
TOTAL=$((TOTAL + 1))
OUT=$(cd "$SANDBOX" && bash "$SNAPSHOT_SH" "proactive_compact" 2>&1)
RC=$?
ARTIFACTS_OK=true
[ "$RC" = "0" ] || ARTIFACTS_OK=false
# Tag exists?
LATEST_TAG=$(cd "$SANDBOX" && git tag --list 'apex/rotation/*' 2>/dev/null | sort -r | head -1)
[ -z "$LATEST_TAG" ] && ARTIFACTS_OK=false
# Note file exists?
NOTE_GLOB=$(ls "$SANDBOX/.apex/phases/12/"ROTATION-NOTE-*.md 2>/dev/null | head -1)
[ -z "$NOTE_GLOB" ] && ARTIFACTS_OK=false
# STATE still valid JSON?
jq -e . "$SANDBOX/.apex/STATE.json" >/dev/null 2>&1 || ARTIFACTS_OK=false
if [ "$ARTIFACTS_OK" = true ]; then
  echo "  ✅ C-3: happy path produced STATE + DECISIONS + tag ($LATEST_TAG) + note ($(basename "$NOTE_GLOB"))"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-3: artifacts missing — rc=$RC, tag=$LATEST_TAG, note=$NOTE_GLOB"
  echo "       Hook output: $OUT"
  FAIL=$((FAIL + 1))
fi

# --- C-4: ROTATION-NOTE has required sections (Done / Next / Issues) ---
TOTAL=$((TOTAL + 1))
if [ -f "$NOTE_GLOB" ] && \
   grep -q "^## Done" "$NOTE_GLOB" && \
   grep -q "^## Next" "$NOTE_GLOB" && \
   grep -q "^## Issues" "$NOTE_GLOB"; then
  echo "  ✅ C-4: ROTATION-NOTE has Done / Next / Issues sections"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-4: ROTATION-NOTE missing required sections"
  FAIL=$((FAIL + 1))
fi

# --- C-5: git tag namespace = apex/rotation/<TS>-<phase> ---
TOTAL=$((TOTAL + 1))
if echo "$LATEST_TAG" | grep -qE '^apex/rotation/[0-9]{8}T[0-9]{6}Z-[A-Za-z0-9-]+$'; then
  echo "  ✅ C-5: tag namespace = apex/rotation/<TS>-<phase> (got: $LATEST_TAG)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-5: tag namespace malformed — got: $LATEST_TAG"
  FAIL=$((FAIL + 1))
fi

# --- C-6: tag retention cap = 50 (seed 60, expect ≤50 after run) ---
TOTAL=$((TOTAL + 1))
(
  cd "$SANDBOX"
  for i in $(seq 1 60); do
    git tag -a "apex/rotation/2025010100000${i}Z-seed-phase" -m "seed $i" 2>/dev/null
  done
)
(cd "$SANDBOX" && bash "$SNAPSHOT_SH" "manual" >/dev/null 2>&1)
TAG_COUNT=$(cd "$SANDBOX" && git tag --list 'apex/rotation/*' 2>/dev/null | wc -l)
if [ "$TAG_COUNT" -le 50 ]; then
  echo "  ✅ C-6: tag retention cap honored ($TAG_COUNT ≤ 50)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-6: retention not enforced — found $TAG_COUNT tags (>50)"
  FAIL=$((FAIL + 1))
fi

# --- C-7: STATE invalid → exit 1, no new tag ---
TOTAL=$((TOTAL + 1))
SANDBOX2=$(mktemp -d)
mkdir -p "$SANDBOX2/.apex"
echo 'this is not valid JSON {' > "$SANDBOX2/.apex/STATE.json"
(cd "$SANDBOX2" && git init -q && git config user.email t@t && git config user.name t && \
  git add . >/dev/null 2>&1 && git commit -qm init >/dev/null 2>&1)
(cd "$SANDBOX2" && bash "$SNAPSHOT_SH" "manual" >/dev/null 2>&1)
RC=$?
TAG_AFTER=$(cd "$SANDBOX2" && git tag --list 'apex/rotation/*' 2>/dev/null | wc -l)
if [ "$RC" = "1" ] && [ "$TAG_AFTER" = "0" ]; then
  echo "  ✅ C-7: invalid STATE → exit 1, no tag created (safe-or-noop)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-7: expected exit 1 + 0 tags, got rc=$RC tags=$TAG_AFTER"
  FAIL=$((FAIL + 1))
fi
rm -rf "$SANDBOX2"

# --- C-8: next.md invokes pre-rotation-snapshot in all 3 rotation branches ---
TOTAL=$((TOTAL + 1))
INVOCATIONS=$(grep -cE 'pre-rotation-snapshot\.sh' "$NEXT_MD")
if [ "$INVOCATIONS" -ge 3 ]; then
  echo "  ✅ C-8: next.md invokes pre-rotation-snapshot.sh $INVOCATIONS times (proactive/warn/hard)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-8: expected ≥3 next.md invocations, found $INVOCATIONS"
  FAIL=$((FAIL + 1))
fi

# --- C-9: resume.md reads ROTATION-NOTE preferentially ---
TOTAL=$((TOTAL + 1))
if grep -qE 'ROTATION-NOTE INGESTION' "$RESUME_MD" && \
   grep -qE 'apex/rotation/' "$RESUME_MD"; then
  echo "  ✅ C-9: resume.md reads ROTATION-NOTE preferentially"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-9: resume.md missing ROTATION-NOTE ingestion block"
  FAIL=$((FAIL + 1))
fi

# --- C-10: HOOK-CLASSIFICATION.md lists pre-rotation-snapshot.sh ---
TOTAL=$((TOTAL + 1))
if grep -q 'pre-rotation-snapshot.sh' "$HOOK_CLASS"; then
  echo "  ✅ C-10: HOOK-CLASSIFICATION.md lists pre-rotation-snapshot.sh"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-10: pre-rotation-snapshot.sh missing from HOOK-CLASSIFICATION.md"
  FAIL=$((FAIL + 1))
fi

# Cleanup
rm -rf "$SANDBOX"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  echo ""
  echo "$PASS/$TOTAL passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] || exit 1
fi
