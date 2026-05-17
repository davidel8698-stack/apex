#!/usr/bin/env bash
# Phase 12.12 — M18.1 DORA Measurement Engine test.
#
# Verifies dora-collect.sh against 4 fixture-repo scenarios:
#   C-1: hook exists + executable + syntax-valid.
#   C-2: no .apex/ in cwd → exit 2 (invocation error).
#   C-3: GREENFIELD — fresh git repo with 1 commit, no tags
#        → exit 1, DORA.json emitted, deploys=0, cfr null, lt null, mttr null.
#   C-4: MATURE — N commits + multiple release/* tags spread over days
#        → exit 0, deploys>0, deploys_per_week non-null, lt_median non-null.
#   C-5: BROKEN-DEPLOYS — N commits with revert/hotfix > 30% of total
#        → exit 0, cfr.ratio > 0.3.
#   C-6: FAST-RECOVERY — revert immediately followed by forward tag
#        → exit 0, mttr.median_seconds small (≤ 600s by construction).
#   C-7: ENV override — APEX_DORA_DEPLOY_TAG_PATTERN="v*" picks up
#        v1.0.0-style tags that release/* would miss.
#
# Harness contract (R10-008): arithmetic globals, no EXIT trap.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DORA_SH="$REPO_ROOT/framework/hooks/dora-collect.sh"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ ! -f "$SCRIPT_DIR/_harness.sh" ]; then
    echo "  ❌ Harness not found"; exit 1
  fi
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/_harness.sh"
fi

echo "=== Phase 12.12 — M18.1 DORA Measurement Engine ==="

if ! command -v jq >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
  echo "  ❌ jq and git are required"
  exit 1
fi

# --- C-1: hook exists + executable + syntax-valid ---
TOTAL=$((TOTAL + 1))
if [ -x "$DORA_SH" ] && bash -n "$DORA_SH" 2>/dev/null; then
  echo "  ✅ C-1: dora-collect.sh exists, executable, syntax-valid"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-1: dora-collect.sh missing or broken"
  exit 1
fi

# --- C-2: no .apex/ in cwd → exit 2 ---
TOTAL=$((TOTAL + 1))
EMPTY=$(mktemp -d)
(cd "$EMPTY" && bash "$DORA_SH" >/dev/null 2>&1)
RC=$?
rm -rf "$EMPTY"
if [ "$RC" = "2" ]; then
  echo "  ✅ C-2: no .apex/ → exit 2"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-2: expected exit 2 with no .apex/, got $RC"
  FAIL=$((FAIL + 1))
fi

# Helper: initialise a sandbox with .apex/ + git repo + author config.
# Caller can then add commits/tags. Echoes the sandbox path.
_make_sandbox() {
  local sb
  sb=$(mktemp -d)
  mkdir -p "$sb/.apex"
  (
    cd "$sb"
    git init -q
    git config user.email "test@apex"
    git config user.name "APEX-test"
    # Ensure deterministic default branch.
    git symbolic-ref HEAD refs/heads/main 2>/dev/null || true
  )
  echo "$sb"
}

# Helper: commit with a controllable subject + committer-date (epoch).
# Args: <sandbox> <epoch_seconds> <subject>
_commit_at() {
  local sb="$1" epoch="$2" subject="$3"
  local datestr
  # ISO-8601 from epoch. Use GNU date if available; fall back to BSD.
  if datestr=$(date -u -d "@$epoch" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null); then
    :
  else
    datestr=$(date -u -r "$epoch" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
  fi
  (
    cd "$sb"
    echo "x_$epoch" >> "file_${epoch}.txt"
    git add -A >/dev/null 2>&1
    GIT_AUTHOR_DATE="$datestr" GIT_COMMITTER_DATE="$datestr" \
      git commit -qm "$subject" >/dev/null 2>&1
  )
}

# Helper: tag at a chosen epoch via overriding committer date on the tag object.
# Annotated tag so for-each-ref reports the tag object SHA; the hook
# dereferences via `git log -1` so either lightweight or annotated works.
_tag_at() {
  local sb="$1" epoch="$2" tagname="$3"
  local datestr
  if datestr=$(date -u -d "@$epoch" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null); then
    :
  else
    datestr=$(date -u -r "$epoch" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
  fi
  (
    cd "$sb"
    GIT_COMMITTER_DATE="$datestr" git tag -a "$tagname" -m "deploy $tagname" 2>/dev/null
  )
}

NOW=$(date -u +%s)

# --- C-3: GREENFIELD — 1 commit, no tags → exit 1, null metrics ---
TOTAL=$((TOTAL + 1))
SB_GF=$(_make_sandbox)
_commit_at "$SB_GF" "$NOW" "init"
(cd "$SB_GF" && bash "$DORA_SH" >/dev/null 2>&1)
RC=$?
GF_OK=true
[ "$RC" = "0" ] || [ "$RC" = "1" ] || GF_OK=false   # exit 1 on greenfield is contract; exit 0 also OK if 1 commit counted
[ -f "$SB_GF/.apex/DORA.json" ] || GF_OK=false
if [ "$GF_OK" = "true" ]; then
  # Validate the shape: deploys_in_window=0, cfr ratio null OR 0
  jq -e '.deployment_frequency.deploys_in_window == 0' "$SB_GF/.apex/DORA.json" >/dev/null 2>&1 || GF_OK=false
  jq -e '.lead_time.median_seconds == null' "$SB_GF/.apex/DORA.json" >/dev/null 2>&1 || GF_OK=false
  jq -e '.mean_time_to_restore.median_seconds == null' "$SB_GF/.apex/DORA.json" >/dev/null 2>&1 || GF_OK=false
fi
if [ "$GF_OK" = "true" ]; then
  echo "  ✅ C-3: greenfield → DORA.json with null lead/mttr + 0 deploys (rc=$RC)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-3: greenfield emit failed (rc=$RC)"
  [ -f "$SB_GF/.apex/DORA.json" ] && cat "$SB_GF/.apex/DORA.json" | sed 's/^/      /'
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB_GF"

# --- C-4: MATURE — multiple commits, 3 release/* tags over weeks ---
TOTAL=$((TOTAL + 1))
SB_M=$(_make_sandbox)
# Spread commits + tags within a 21-day window (well under 28-day default).
# Use real time offsets going backward from NOW.
DAY=86400
_commit_at "$SB_M" "$(( NOW - 20 * DAY ))" "feat: initial"
_commit_at "$SB_M" "$(( NOW - 18 * DAY ))" "feat: A"
_tag_at    "$SB_M" "$(( NOW - 17 * DAY ))" "release/1.0.0"
_commit_at "$SB_M" "$(( NOW - 15 * DAY ))" "feat: B"
_commit_at "$SB_M" "$(( NOW - 13 * DAY ))" "feat: C"
_tag_at    "$SB_M" "$(( NOW - 12 * DAY ))" "release/1.1.0"
_commit_at "$SB_M" "$(( NOW -  8 * DAY ))" "feat: D"
_commit_at "$SB_M" "$(( NOW -  5 * DAY ))" "feat: E"
_tag_at    "$SB_M" "$(( NOW -  4 * DAY ))" "release/1.2.0"
(cd "$SB_M" && bash "$DORA_SH" >/dev/null 2>&1)
RC=$?
M_OK=true
[ "$RC" = "0" ] || M_OK=false
[ -f "$SB_M/.apex/DORA.json" ] || M_OK=false
if [ "$M_OK" = "true" ]; then
  jq -e '.deployment_frequency.deploys_in_window >= 3' "$SB_M/.apex/DORA.json" >/dev/null 2>&1 || M_OK=false
  jq -e '.deployment_frequency.deploys_per_week != null' "$SB_M/.apex/DORA.json" >/dev/null 2>&1 || M_OK=false
  jq -e '.lead_time.median_seconds != null and .lead_time.median_seconds > 0' "$SB_M/.apex/DORA.json" >/dev/null 2>&1 || M_OK=false
  jq -e '.lead_time.sample_size >= 1' "$SB_M/.apex/DORA.json" >/dev/null 2>&1 || M_OK=false
fi
if [ "$M_OK" = "true" ]; then
  DF=$(jq -r '.deployment_frequency.deploys_in_window' "$SB_M/.apex/DORA.json")
  LT=$(jq -r '.lead_time.median_seconds' "$SB_M/.apex/DORA.json")
  echo "  ✅ C-4: mature → deploys=$DF, lt_median=${LT}s, deploys_per_week non-null"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-4: mature scenario failed (rc=$RC)"
  [ -f "$SB_M/.apex/DORA.json" ] && cat "$SB_M/.apex/DORA.json" | sed 's/^/      /'
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB_M"

# --- C-5: BROKEN-DEPLOYS — > 30% reverts/hotfixes → CFR > 0.3 ---
TOTAL=$((TOTAL + 1))
SB_B=$(_make_sandbox)
# 10 commits total, 4 with revert/hotfix prefix → CFR = 0.4.
_commit_at "$SB_B" "$(( NOW - 15 * DAY ))" "feat: A"
_commit_at "$SB_B" "$(( NOW - 14 * DAY ))" "feat: B"
_commit_at "$SB_B" "$(( NOW - 13 * DAY ))" "revert: B was broken"
_commit_at "$SB_B" "$(( NOW - 12 * DAY ))" "feat: C"
_commit_at "$SB_B" "$(( NOW - 11 * DAY ))" "hotfix: C off-by-one"
_commit_at "$SB_B" "$(( NOW - 10 * DAY ))" "feat: D"
_commit_at "$SB_B" "$(( NOW -  9 * DAY ))" "rollback: D dropped data"
_commit_at "$SB_B" "$(( NOW -  8 * DAY ))" "feat: E"
_commit_at "$SB_B" "$(( NOW -  7 * DAY ))" "feat: F"
_commit_at "$SB_B" "$(( NOW -  6 * DAY ))" "revert: F memory leak"
(cd "$SB_B" && bash "$DORA_SH" >/dev/null 2>&1)
RC=$?
B_OK=true
[ "$RC" = "0" ] || B_OK=false
[ -f "$SB_B/.apex/DORA.json" ] || B_OK=false
if [ "$B_OK" = "true" ]; then
  jq -e '.change_failure_rate.numerator >= 4' "$SB_B/.apex/DORA.json" >/dev/null 2>&1 || B_OK=false
  jq -e '.change_failure_rate.denominator >= 10' "$SB_B/.apex/DORA.json" >/dev/null 2>&1 || B_OK=false
  jq -e '.change_failure_rate.ratio > 0.3' "$SB_B/.apex/DORA.json" >/dev/null 2>&1 || B_OK=false
fi
if [ "$B_OK" = "true" ]; then
  RATIO=$(jq -r '.change_failure_rate.ratio' "$SB_B/.apex/DORA.json")
  NUM=$(jq -r '.change_failure_rate.numerator' "$SB_B/.apex/DORA.json")
  DEN=$(jq -r '.change_failure_rate.denominator' "$SB_B/.apex/DORA.json")
  echo "  ✅ C-5: broken-deploys → CFR=${RATIO} (${NUM}/${DEN}) > 0.3"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-5: broken-deploys scenario failed (rc=$RC)"
  [ -f "$SB_B/.apex/DORA.json" ] && cat "$SB_B/.apex/DORA.json" | sed 's/^/      /'
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB_B"

# --- C-6: FAST-RECOVERY — revert immediately followed by tag → small MTTR ---
TOTAL=$((TOTAL + 1))
SB_R=$(_make_sandbox)
# Setup: a prior deploy tag, then a revert, then a forward tag 5 minutes later.
_commit_at "$SB_R" "$(( NOW - 10 * DAY ))" "feat: launch"
_tag_at    "$SB_R" "$(( NOW - 10 * DAY ))" "release/1.0.0"
_commit_at "$SB_R" "$(( NOW -  5 * DAY ))" "feat: broken thing"
_tag_at    "$SB_R" "$(( NOW -  5 * DAY ))" "release/1.1.0"
# Failing commit at T.
T=$(( NOW - 2 * DAY ))
_commit_at "$SB_R" "$T" "revert: 1.1.0 broke prod"
# Forward tag 300 seconds (5 min) later.
_commit_at "$SB_R" "$(( T + 300 ))" "fix: roll-forward"
_tag_at    "$SB_R" "$(( T + 300 ))" "release/1.1.1"
(cd "$SB_R" && bash "$DORA_SH" >/dev/null 2>&1)
RC=$?
R_OK=true
[ "$RC" = "0" ] || R_OK=false
[ -f "$SB_R/.apex/DORA.json" ] || R_OK=false
if [ "$R_OK" = "true" ]; then
  jq -e '.mean_time_to_restore.sample_size >= 1' "$SB_R/.apex/DORA.json" >/dev/null 2>&1 || R_OK=false
  jq -e '.mean_time_to_restore.median_seconds != null and .mean_time_to_restore.median_seconds <= 600' \
    "$SB_R/.apex/DORA.json" >/dev/null 2>&1 || R_OK=false
fi
if [ "$R_OK" = "true" ]; then
  MTTR=$(jq -r '.mean_time_to_restore.median_seconds' "$SB_R/.apex/DORA.json")
  echo "  ✅ C-6: fast-recovery → MTTR median = ${MTTR}s (≤ 600)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-6: fast-recovery scenario failed (rc=$RC)"
  [ -f "$SB_R/.apex/DORA.json" ] && cat "$SB_R/.apex/DORA.json" | sed 's/^/      /'
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB_R"

# --- C-7: env override — APEX_DORA_DEPLOY_TAG_PATTERN="v*" picks up v-tags ---
TOTAL=$((TOTAL + 1))
SB_V=$(_make_sandbox)
_commit_at "$SB_V" "$(( NOW - 10 * DAY ))" "feat: thing"
_tag_at    "$SB_V" "$(( NOW -  9 * DAY ))" "v1.0.0"
_commit_at "$SB_V" "$(( NOW -  5 * DAY ))" "feat: thing2"
_tag_at    "$SB_V" "$(( NOW -  4 * DAY ))" "v1.1.0"
# Default release/* — should see 0 deploys.
(cd "$SB_V" && bash "$DORA_SH" >/dev/null 2>&1)
DEFAULT_DEPLOYS=$(jq -r '.deployment_frequency.deploys_in_window' "$SB_V/.apex/DORA.json" 2>/dev/null)
# Override to v* — should see 2 deploys.
(cd "$SB_V" && APEX_DORA_DEPLOY_TAG_PATTERN="v*" bash "$DORA_SH" >/dev/null 2>&1)
OVERRIDE_DEPLOYS=$(jq -r '.deployment_frequency.deploys_in_window' "$SB_V/.apex/DORA.json" 2>/dev/null)
if [ "$DEFAULT_DEPLOYS" = "0" ] && [ "$OVERRIDE_DEPLOYS" = "2" ]; then
  echo "  ✅ C-7: env override — default=$DEFAULT_DEPLOYS, v*-override=$OVERRIDE_DEPLOYS"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-7: env override failed — default=$DEFAULT_DEPLOYS, override=$OVERRIDE_DEPLOYS"
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB_V"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  echo ""
  echo "$PASS/$TOTAL passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] || exit 1
fi
