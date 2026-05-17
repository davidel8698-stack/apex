#!/usr/bin/env bash
# dora-collect.sh — M18.1 DORA Measurement Engine (Phase 12.12).
#
# Hook type: Command-Invoked (fired by /apex:milestone-summary and
# /apex:ship; also safe to run standalone for ad-hoc inspection).
#
# Purpose
#   Extracts the DORA quartet — Deployment Frequency, Lead Time for
#   Changes, Change Failure Rate, Mean Time to Restore — from `git log`
#   alone, and writes the aggregate to `.apex/DORA.json`. This is the
#   measurement engine that makes the "First Framework That Improves
#   DORA" claim falsifiable (per CLAIMS-MEASUREMENT.md).
#
# The 4 metrics (see framework/docs/CLAIMS-MEASUREMENT.md §"DORA
# measurement engine" for committed definitions + rejected alternatives
# + heuristic limitations):
#   DF   — deploy-tag count over the window, normalized to per-week.
#   LT   — median seconds from first-new-commit on the deploy branch
#          to the tag commit.
#   CFR  — per-commit proxy: revert/hotfix/rollback prefix count /
#          total commits in window.
#   MTTR — median seconds from each failing commit (revert/hotfix
#          prefix) to the next forward deploy tag.
#
# Configurable inputs (env):
#   APEX_DORA_DEPLOY_TAG_PATTERN      (default: release/*)
#   APEX_DORA_DEPLOY_TAG_PATTERN_ALT  (default: deploy/*)
#   APEX_DORA_WINDOW_DAYS             (default: 28)
#
# Spec anchors
#   apex-spec.md — "The First Framework That Improves DORA" claim block.
#   framework/docs/CLAIMS-MEASUREMENT.md §"DORA measurement engine".
#   .apex/phases/12-apex-evolution-v8/PLAN.md task 12.12.
#
# Usage
#   bash framework/hooks/dora-collect.sh
#
# Exit codes
#   0 = .apex/DORA.json written (may contain null fields when sparse)
#   1 = git not available, or no commits at all (caller decides)
#   2 = invocation error (e.g., no .apex/ in cwd, bad env)

set -uo pipefail

# ── Invocation guards ───────────────────────────────────────────────
if [ ! -d ".apex" ]; then
  echo "🚫 dora-collect: no .apex/ in cwd — nothing to write" >&2
  exit 2
fi

if ! command -v git >/dev/null 2>&1; then
  echo "🚫 dora-collect: git is required" >&2
  exit 1
fi

# Are we even in a git repo? `git rev-parse` will fail if not.
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "🚫 dora-collect: not a git repo" >&2
  exit 1
fi

DEPLOY_PAT="${APEX_DORA_DEPLOY_TAG_PATTERN:-release/*}"
DEPLOY_PAT_ALT="${APEX_DORA_DEPLOY_TAG_PATTERN_ALT:-deploy/*}"
WINDOW_DAYS="${APEX_DORA_WINDOW_DAYS:-28}"

# Validate WINDOW_DAYS is a positive int (defensive — env input).
case "$WINDOW_DAYS" in
  ''|*[!0-9]*) echo "🚫 dora-collect: APEX_DORA_WINDOW_DAYS must be a positive integer (got '$WINDOW_DAYS')" >&2; exit 2 ;;
esac
[ "$WINDOW_DAYS" -gt 0 ] || { echo "🚫 dora-collect: APEX_DORA_WINDOW_DAYS must be > 0" >&2; exit 2; }

NOW_EPOCH=$(date -u +%s)
WINDOW_SECS=$(( WINDOW_DAYS * 86400 ))
WINDOW_START_EPOCH=$(( NOW_EPOCH - WINDOW_SECS ))
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ── Total commits in window ─────────────────────────────────────────
# `git log --since` accepts unix-epoch via @<ts>. Count commits whose
# committer-time falls inside the window.
TOTAL_COMMITS=$(git log --since="@${WINDOW_START_EPOCH}" --pretty=oneline 2>/dev/null | wc -l | tr -d ' ')

# Greenfield short-circuit: no commits at all in the repo's history.
ALL_COMMITS=$(git log --pretty=oneline 2>/dev/null | wc -l | tr -d ' ')
if [ "$ALL_COMMITS" = "0" ]; then
  # Honest emit: every metric null, with sample_size=0 and explicit
  # generated_at. Exit 1 per contract ("no commits") — caller decides.
  cat > .apex/DORA.json.tmp <<EOF
{
  "schema_version": 1,
  "generated_at": "${NOW_ISO}",
  "window_days": ${WINDOW_DAYS},
  "deploy_tag_patterns": ["${DEPLOY_PAT}", "${DEPLOY_PAT_ALT}"],
  "deployment_frequency": {"deploys_in_window": 0, "deploys_per_week": null},
  "lead_time": {"median_seconds": null, "sample_size": 0},
  "change_failure_rate": {"ratio": null, "numerator": 0, "denominator": 0, "cfr_definition": "per_commit_proxy"},
  "mean_time_to_restore": {"median_seconds": null, "sample_size": 0, "heuristic": "next_forward_tag_after_revert"}
}
EOF
  mv .apex/DORA.json.tmp .apex/DORA.json
  echo "ℹ️  dora-collect: no commits in repo — wrote null DORA.json" >&2
  exit 1
fi

# ── Deploy tags in window ───────────────────────────────────────────
# Strategy: list ALL tags matching either pattern, resolve each to its
# commit's committer-epoch via `git log -1 --format=%ct`. Filter to
# those whose epoch >= WINDOW_START_EPOCH.
#
# We use `git for-each-ref` for the listing because `git tag --list`
# does not give us the commit hash directly in a portable way.

DEPLOY_TAGS_ALL=$(git for-each-ref \
  --format='%(refname:short) %(objectname)' \
  "refs/tags/${DEPLOY_PAT}" "refs/tags/${DEPLOY_PAT_ALT}" 2>/dev/null)

DEPLOYS_IN_WINDOW=0
# Comma-separated `epoch:sha` records of in-window deploy tags
# (so we can later compute per-tag lead time and MTTR).
DEPLOY_RECORDS=""
if [ -n "$DEPLOY_TAGS_ALL" ]; then
  while IFS=' ' read -r tag sha; do
    [ -z "$tag" ] && continue
    [ -z "$sha" ] && continue
    # Tags may be annotated (objectname = tag object SHA) or
    # lightweight (objectname = commit SHA). Resolve to commit-time
    # via `git log -1` which dereferences annotated tags transparently.
    tag_epoch=$(git log -1 --format=%ct "$sha" 2>/dev/null)
    [ -z "$tag_epoch" ] && continue
    if [ "$tag_epoch" -ge "$WINDOW_START_EPOCH" ]; then
      DEPLOYS_IN_WINDOW=$(( DEPLOYS_IN_WINDOW + 1 ))
      DEPLOY_RECORDS="${DEPLOY_RECORDS}${tag_epoch}:${sha}|"
    fi
  done <<EOF
$DEPLOY_TAGS_ALL
EOF
fi

# Deploys-per-week: DEPLOYS_IN_WINDOW / (WINDOW_DAYS / 7).
# Compute via awk for floating-point.
if [ "$DEPLOYS_IN_WINDOW" -gt 0 ]; then
  DEPLOYS_PER_WEEK=$(awk -v d="$DEPLOYS_IN_WINDOW" -v w="$WINDOW_DAYS" 'BEGIN{ printf "%.4f", d / (w / 7.0) }')
else
  DEPLOYS_PER_WEEK="null"
fi

# ── Lead Time: median seconds from first-new-commit to tag-commit ──
# For each in-window deploy tag, find the earliest commit reachable
# from that tag that is NOT reachable from any earlier deploy tag.
# Lead time = tag_commit_time - first_new_commit_time.
#
# Implementation: sort deploys ascending by epoch. For the first
# deploy in repo history, "previous deploy" = none → first-new-commit
# is the root commit. For subsequent deploys, exclude commits reachable
# from the previous deploy via `git rev-list prev..tag`.

LEAD_TIMES=""
LT_SAMPLE_SIZE=0

if [ "$DEPLOYS_IN_WINDOW" -gt 0 ]; then
  # Sort DEPLOY_RECORDS ascending by epoch.
  SORTED_DEPLOYS=$(printf '%s' "$DEPLOY_RECORDS" \
    | tr '|' '\n' \
    | grep -v '^$' \
    | sort -t: -k1,1n)

  # We also need to know the chronologically-previous deploy across
  # ALL history (not just in-window), to set the lower bound for
  # "new commits since previous deploy" correctly.
  ALL_DEPLOYS=""
  if [ -n "$DEPLOY_TAGS_ALL" ]; then
    ALL_DEPLOYS=$(echo "$DEPLOY_TAGS_ALL" | while IFS=' ' read -r tag sha; do
      [ -z "$tag" ] && continue
      e=$(git log -1 --format=%ct "$sha" 2>/dev/null)
      [ -n "$e" ] && printf '%s %s\n' "$e" "$sha"
    done | sort -k1,1n)
  fi

  while IFS=: read -r tag_epoch sha; do
    [ -z "$sha" ] && continue
    # Find the immediately-prior deploy sha (across all history) whose
    # epoch is strictly less than tag_epoch.
    PREV_SHA=$(echo "$ALL_DEPLOYS" | awk -v t="$tag_epoch" '$1 < t {prev=$2} END{print prev}')

    if [ -n "$PREV_SHA" ]; then
      # Earliest new commit since prior deploy.
      FIRST_NEW=$(git rev-list --reverse "${PREV_SHA}..${sha}" 2>/dev/null | head -1)
    else
      # First-ever deploy — earliest reachable commit is the root.
      FIRST_NEW=$(git rev-list --reverse "${sha}" 2>/dev/null | head -1)
    fi

    if [ -n "$FIRST_NEW" ]; then
      FN_EPOCH=$(git log -1 --format=%ct "$FIRST_NEW" 2>/dev/null)
      if [ -n "$FN_EPOCH" ] && [ "$tag_epoch" -ge "$FN_EPOCH" ]; then
        DELTA=$(( tag_epoch - FN_EPOCH ))
        LEAD_TIMES="${LEAD_TIMES}${DELTA}\n"
        LT_SAMPLE_SIZE=$(( LT_SAMPLE_SIZE + 1 ))
      fi
    fi
  done <<EOF
$SORTED_DEPLOYS
EOF
fi

# Median helper: pipe newline-separated ints, get median.
_median() {
  awk '
    { a[NR]=$1 }
    END {
      n=NR
      if (n==0) { print "null"; exit }
      # Sort numerically.
      for (i=1;i<=n;i++) for (j=i+1;j<=n;j++) if (a[i]>a[j]) { t=a[i]; a[i]=a[j]; a[j]=t }
      if (n%2==1) print a[(n+1)/2]
      else print int((a[n/2] + a[n/2+1]) / 2)
    }
  '
}

if [ "$LT_SAMPLE_SIZE" -gt 0 ]; then
  LT_MEDIAN=$(printf '%b' "$LEAD_TIMES" | grep -v '^$' | _median)
else
  LT_MEDIAN="null"
fi

# ── Change Failure Rate: per-commit proxy in window ────────────────
# Numerator: subject-line begins with revert / hotfix / rollback
# (case-insensitive, word-boundary).
# Denominator: TOTAL_COMMITS computed above.

if [ "$TOTAL_COMMITS" -gt 0 ]; then
  CFR_NUM=$(git log --since="@${WINDOW_START_EPOCH}" --pretty=format:'%s' 2>/dev/null \
    | grep -ciE '^(revert|hotfix|rollback)([[:space:]]|:|\()' \
    | tr -d ' ')
  [ -z "$CFR_NUM" ] && CFR_NUM=0
  CFR_RATIO=$(awk -v n="$CFR_NUM" -v d="$TOTAL_COMMITS" 'BEGIN{ printf "%.4f", n / d }')
else
  CFR_NUM=0
  CFR_RATIO="null"
fi

# ── Mean Time to Restore: median secs from failing commit to next forward tag ──
# For each commit in window with revert/hotfix/rollback prefix:
#   find the earliest deploy-pattern tag whose commit is a descendant
#   of the failing commit AND whose tag_epoch >= failing_commit_epoch.
#   MTTR sample = tag_epoch - failing_commit_epoch.
# Aggregate as median.

MTTR_TIMES=""
MTTR_SAMPLE_SIZE=0

if [ "$TOTAL_COMMITS" -gt 0 ] && [ -n "$DEPLOY_TAGS_ALL" ]; then
  FAILING_COMMITS=$(git log --since="@${WINDOW_START_EPOCH}" \
    --pretty=format:'%H %ct %s' 2>/dev/null \
    | awk 'tolower($3) ~ /^(revert|hotfix|rollback)([[:space:]]|:|\()/ {print $1, $2}')

  if [ -n "$FAILING_COMMITS" ]; then
    # Precompute ALL deploy tags with their commit epoch (sorted ascending).
    ALL_DEPLOYS_FOR_MTTR=$(echo "$DEPLOY_TAGS_ALL" | while IFS=' ' read -r tag sha; do
      [ -z "$tag" ] && continue
      e=$(git log -1 --format=%ct "$sha" 2>/dev/null)
      [ -n "$e" ] && printf '%s %s\n' "$e" "$sha"
    done | sort -k1,1n)

    while IFS=' ' read -r fc_sha fc_epoch; do
      [ -z "$fc_sha" ] && continue
      # Find earliest deploy tag with epoch >= fc_epoch AND whose
      # commit is a descendant (i.e., contains fc_sha in its ancestry).
      NEXT_TAG_EPOCH=""
      while IFS=' ' read -r d_epoch d_sha; do
        [ -z "$d_sha" ] && continue
        if [ "$d_epoch" -ge "$fc_epoch" ]; then
          # Is fc_sha an ancestor of d_sha? `git merge-base --is-ancestor` exits 0 if yes.
          if git merge-base --is-ancestor "$fc_sha" "$d_sha" 2>/dev/null; then
            NEXT_TAG_EPOCH="$d_epoch"
            break
          fi
        fi
      done <<EOF
$ALL_DEPLOYS_FOR_MTTR
EOF
      if [ -n "$NEXT_TAG_EPOCH" ]; then
        DELTA=$(( NEXT_TAG_EPOCH - fc_epoch ))
        MTTR_TIMES="${MTTR_TIMES}${DELTA}\n"
        MTTR_SAMPLE_SIZE=$(( MTTR_SAMPLE_SIZE + 1 ))
      fi
    done <<EOF
$FAILING_COMMITS
EOF
  fi
fi

if [ "$MTTR_SAMPLE_SIZE" -gt 0 ]; then
  MTTR_MEDIAN=$(printf '%b' "$MTTR_TIMES" | grep -v '^$' | _median)
else
  MTTR_MEDIAN="null"
fi

# ── Emit .apex/DORA.json (atomic via rename-temp) ───────────────────
# Build the JSON with explicit null literals (not the string "null") —
# the helper variables already encode bare-literal "null" where data
# was insufficient, so they go in unquoted.

if [ "$DEPLOYS_IN_WINDOW" -gt 0 ]; then
  DF_DEPLOYS_FIELD="$DEPLOYS_IN_WINDOW"
else
  DF_DEPLOYS_FIELD="0"
fi

cat > .apex/DORA.json.tmp <<EOF
{
  "schema_version": 1,
  "generated_at": "${NOW_ISO}",
  "window_days": ${WINDOW_DAYS},
  "deploy_tag_patterns": ["${DEPLOY_PAT}", "${DEPLOY_PAT_ALT}"],
  "deployment_frequency": {
    "deploys_in_window": ${DF_DEPLOYS_FIELD},
    "deploys_per_week": ${DEPLOYS_PER_WEEK}
  },
  "lead_time": {
    "median_seconds": ${LT_MEDIAN},
    "sample_size": ${LT_SAMPLE_SIZE}
  },
  "change_failure_rate": {
    "ratio": ${CFR_RATIO},
    "numerator": ${CFR_NUM},
    "denominator": ${TOTAL_COMMITS},
    "cfr_definition": "per_commit_proxy"
  },
  "mean_time_to_restore": {
    "median_seconds": ${MTTR_MEDIAN},
    "sample_size": ${MTTR_SAMPLE_SIZE},
    "heuristic": "next_forward_tag_after_revert"
  }
}
EOF

# Validate JSON if jq is available; do not block emission on absence.
if command -v jq >/dev/null 2>&1; then
  if ! jq -e . .apex/DORA.json.tmp >/dev/null 2>&1; then
    rm -f .apex/DORA.json.tmp
    echo "🚫 dora-collect: emitted JSON failed jq validation (internal bug)" >&2
    exit 2
  fi
fi

mv .apex/DORA.json.tmp .apex/DORA.json

# Log to event-log if present (best-effort; failure does not block).
EVENT_LOG="./.apex/event-log.jsonl"
printf '{"ts":"%s","severity":"MINOR","hook":"dora-collect","type":"dora.collected","window_days":%s,"deploys":%s,"cfr_numerator":%s,"cfr_denominator":%s}\n' \
  "$NOW_ISO" "$WINDOW_DAYS" "$DF_DEPLOYS_FIELD" "$CFR_NUM" "$TOTAL_COMMITS" >> "$EVENT_LOG" 2>/dev/null || true

echo "✅ dora-collect: .apex/DORA.json written (window=${WINDOW_DAYS}d, deploys=${DF_DEPLOYS_FIELD}, cfr=${CFR_NUM}/${TOTAL_COMMITS})"
exit 0
