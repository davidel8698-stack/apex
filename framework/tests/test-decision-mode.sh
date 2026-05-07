#!/usr/bin/env bash
# R5-018: Decision-mode classifier accuracy test (heuristic-as-proxy).
# The architect.md STEP 1.6 prompt classifies each task as collaborator vs
# replacement using a content-based heuristic. This test extracts the same
# heuristic into a deterministic Bash classifier, runs it across the
# ground-truth corpus, and asserts ≥90% accuracy.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CORPUS="$REPO_ROOT/framework/test-fixtures/decision-mode-corpus.json"

# R7-009: shared IO helpers (jq_lines for CRLF-safe read loops).
# shellcheck source=_test-utils.sh
[ -f "$SCRIPT_DIR/_test-utils.sh" ] && source "$SCRIPT_DIR/_test-utils.sh"

if [ ! -f "$CORPUS" ]; then
  echo "FAIL: corpus not found at $CORPUS" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not available — required to parse corpus."
  exit 0
fi

# Deterministic classifier — proxy for the architect's STEP 1.6 prompt.
#
# Product (collaborator) signals — user is the expert:
#   - feature, user-facing, UX, business rule, pricing, copy, onboarding,
#     CTA, privacy, empty-state, profile, page, badge, illustration,
#     marketing, landing, search results, sort order, dashboard layout
#
# Technical (replacement) signals — AI is the expert:
#   - architecture, performance, database, schema, migration, index,
#     OAuth, security, encryption, hash, CI, infra, cache, replication,
#     observability, queue, websocket, microservice, optimize, JVM, pool
#
# Tie-breaker: prefer product when both fire, since CLAUDE.md project memory
# and the spec's "respect the difference" principle err on the side of
# treating ambiguous cases as collaborator.
classify() {
  local text; text="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"

  local product=0 technical=0

  # Product keywords
  local p_kw=(
    "feature" "user-facing" "ux " " ux" "business rule" "pricing" "copy"
    "onboarding" "cta" "privacy" "empty-state" "profile" "landing"
    "marketing" "badge" "illustration" "icons" "colors" "sort order"
    "modal" "page that" "in-app" "buyer" "seller" "loyalty"
    "discounts" "search results"
  )
  local t_kw=(
    "architecture" "performance" "database" "schema" "migration" "index"
    "oauth" "security" "encryption" "hash" "ci pipeline" "ci/cd"
    "infra" "cache" "replication" "observability" "queue" "websocket"
    "microservice" "optimize" "jvm" "pool" "constant-time" "n+1"
    "rabbitmq" "redis" "postgres" "logging" "trace id" "polling"
    "tune" "connection pool" "type-check" "lint" "unit tests"
  )

  local kw
  for kw in "${p_kw[@]}"; do
    if printf '%s' "$text" | grep -qF "$kw"; then
      product=$((product + 1))
    fi
  done
  for kw in "${t_kw[@]}"; do
    if printf '%s' "$text" | grep -qF "$kw"; then
      technical=$((technical + 1))
    fi
  done

  if [ "$product" -gt "$technical" ]; then
    echo "collaborator"
  elif [ "$technical" -gt "$product" ]; then
    echo "replacement"
  else
    # Tie — fall back to product (Layer 1 precedence per architect.md).
    echo "collaborator"
  fi
}

TOTAL=0
CORRECT=0
declare -a MISSES=()

# Parse corpus
LEN=$(jq '.entries | length' "$CORPUS")
for i in $(seq 0 $((LEN - 1))); do
  # R7-009: jq_lines strips any CR contamination from CRLF-tainted JSON
  # so scalar comparisons below are not corrupted by trailing \r.
  if command -v jq_lines >/dev/null 2>&1; then
    desc=$(jq_lines ".entries[$i].description" "$CORPUS")
    expected=$(jq_lines ".entries[$i].expected_mode" "$CORPUS")
    id=$(jq_lines ".entries[$i].id" "$CORPUS")
  else
    desc=$(jq -r ".entries[$i].description" "$CORPUS")
    expected=$(jq -r ".entries[$i].expected_mode" "$CORPUS")
    id=$(jq -r ".entries[$i].id" "$CORPUS")
  fi

  predicted=$(classify "$desc")
  TOTAL=$((TOTAL + 1))
  if [ "$predicted" = "$expected" ]; then
    CORRECT=$((CORRECT + 1))
  else
    MISSES+=("id=$id expected=$expected got=$predicted desc=\"$desc\"")
  fi
done

if [ "$TOTAL" -lt 20 ]; then
  echo "FAIL: corpus has only $TOTAL entries (need >=20)"
  exit 1
fi

# Compute integer percent (CORRECT*100/TOTAL).
PCT=$(( CORRECT * 100 / TOTAL ))

echo "=== R5-018: Decision-mode classifier accuracy ==="
echo "  Corpus size: $TOTAL"
echo "  Correct:     $CORRECT"
echo "  Accuracy:    $PCT%"
echo "  Threshold:   90%"

if [ ${#MISSES[@]} -gt 0 ]; then
  echo "  Misses:"
  for m in "${MISSES[@]}"; do
    echo "    - $m"
  done
fi

if [ "$PCT" -lt 90 ]; then
  echo ""
  echo "FAIL: accuracy $PCT% is below threshold (90%)"
  exit 1
fi

echo "  PASS"
exit 0
