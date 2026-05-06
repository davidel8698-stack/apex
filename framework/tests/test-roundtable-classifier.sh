#!/usr/bin/env bash
# R5-024: Roundtable trigger classifier corpus test.
# A deterministic Bash classifier (mirroring the rules documented in
# framework/docs/ROUNDTABLE-TRIGGERS.md and copied into architect.md
# STEP 1.9) is run across a ground-truth corpus and must agree on every
# entry.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CORPUS="$REPO_ROOT/framework/test-fixtures/roundtable-corpus.json"
DOC="$REPO_ROOT/framework/docs/ROUNDTABLE-TRIGGERS.md"

if [ ! -f "$CORPUS" ]; then
  echo "FAIL: corpus not found at $CORPUS" >&2
  exit 1
fi
if [ ! -f "$DOC" ]; then
  echo "FAIL: ROUNDTABLE-TRIGGERS.md not found at $DOC" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not available — required to parse corpus."
  exit 0
fi

# Anti-rule first: cosmetic / typo / docs / unit tests / single-file refactor.
fires_anti_rule() {
  local text; text="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  printf '%s' "$text" | grep -qE "(^| )(typo|cosmetic|css class|readme|documentation|update the readme|unit tests for|test addition|single-file refactor)" && return 0
  printf '%s' "$text" | grep -qE "(refactor.*no contract change|fix a typo|update the readme)" && return 0
  return 1
}

# Trigger rules R1..R5
fires_R2() {
  local text; text="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  printf '%s' "$text" | grep -qE "(prod deploy|production deploy|destructive migration|drops the .* table|payment integration|public api release|package publish|publish .* package|publish the .* package|publish the [a-z0-9-]+ npm package)" && return 0
  return 1
}
fires_R3() {
  local text; text="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  printf '%s' "$text" | grep -qE "(schema change|contract version bump|breaking api change|database migration|event-schema update|message-format change|bump the public api contract|breaking api)" && return 0
  return 1
}
fires_R4() {
  local text; text="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  printf '%s' "$text" | grep -qE "(cross-team dependency|requires sign-off|coordinated rollout|feature flag handoff|dual-write window|sign-off)" && return 0
  return 1
}
fires_R5() {
  local text; text="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  printf '%s' "$text" | grep -qE "( adr$|— adr|architecture decision|foundational|decide between|trade-off|first task in foundation|foundation phase)" && return 0
  return 1
}
fires_R1() {
  # Multi-specialist surface — proxy: count of distinct specialist keywords >= 3
  local text; text="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  local n=0
  for kw in "frontend" "data team" "security" "integration" "test-architect" "memory-synthesis" "data " "ops team" "support team" "ui" "api" "schema" "auth" "deploy" "infra" "migration" "observability"; do
    if printf '%s' "$text" | grep -qF "$kw"; then
      n=$((n+1))
    fi
  done
  [ "$n" -ge 3 ] && return 0
  return 1
}

classify() {
  local text="$1"
  # Trigger rules first; if any fire, true.
  if fires_R2 "$text"; then echo true; return; fi
  if fires_R3 "$text"; then echo true; return; fi
  if fires_R5 "$text"; then echo true; return; fi
  if fires_R4 "$text"; then echo true; return; fi
  if fires_R1 "$text"; then echo true; return; fi
  # Anti-rule check second (only matters when no trigger fired — anti-rule then keeps it false).
  if fires_anti_rule "$text"; then echo false; return; fi
  echo false
}

TOTAL=0
CORRECT=0
declare -a MISSES=()

LEN=$(jq '.entries | length' "$CORPUS")
for i in $(seq 0 $((LEN - 1))); do
  desc=$(jq -r ".entries[$i].description" "$CORPUS")
  expected=$(jq -r ".entries[$i].expected" "$CORPUS")
  id=$(jq -r ".entries[$i].id" "$CORPUS")

  predicted=$(classify "$desc")
  TOTAL=$((TOTAL + 1))
  if [ "$predicted" = "$expected" ]; then
    CORRECT=$((CORRECT + 1))
  else
    MISSES+=("id=$id expected=$expected got=$predicted desc=\"$desc\"")
  fi
done

if [ "$TOTAL" -lt 10 ]; then
  echo "FAIL: corpus has only $TOTAL entries (need >=10)"
  exit 1
fi

echo "=== R5-024: Roundtable trigger classifier ==="
echo "  Corpus size: $TOTAL"
echo "  Correct:     $CORRECT"
if [ ${#MISSES[@]} -gt 0 ]; then
  echo "  Misses:"
  for m in "${MISSES[@]}"; do
    echo "    - $m"
  done
fi

if [ "$CORRECT" -ne "$TOTAL" ]; then
  echo ""
  echo "FAIL: classifier disagrees with corpus on $((TOTAL - CORRECT)) entries"
  exit 1
fi

echo "  PASS — exact agreement"
exit 0
