#!/usr/bin/env bash
# Phase 12.01 — M04 model diversity test.
#
# Verifies:
#   C-1: framework/apex-model-routing.json is valid JSON with the
#        required top-level `routing` map.
#   C-2: critic, verifier, auditor each declare `expected_model: opus`
#        in their YAML frontmatter (the agent's own assertion).
#   C-3: routing defaults for critic, verifier, auditor are "opus"
#        (matches the frontmatter assertion).
#   C-4: routing defaults for executor and architect are "sonnet"
#        (diversity invariant lower half).
#   C-5: model-diversity invariant holds — routing.executor.default
#        != routing.critic.default (the actual M04 win).
#   C-6: framework/docs/MODEL-ROUTING.md exists (rationale + cost
#        table required by the M04 ecosystem analysis §6).
#   C-7: agent-lint.sh expected_model check is wired and accepts a
#        matching agent (regression guard).
#
# Spec anchor: apex-spec.md §"היכולות הנדרשות" + apex-spec.md
# §"עקרונות העבודה" (adversarial isolation invariants).
# Source plan: .apex/phases/12-apex-evolution-v8/PLAN.md task 12.01.
#
# Harness contract (R10-008): no file-scope shadowing of PASS / FAIL /
# TOTAL / SKIP. Assertions increment the harness globals directly via
# arithmetic. The file is allow-list-clean.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROUTING="$REPO_ROOT/framework/apex-model-routing.json"
DOC="$REPO_ROOT/framework/docs/MODEL-ROUTING.md"
AGENTS_DIR="$REPO_ROOT/framework/agents"
LINT="$REPO_ROOT/framework/hooks/agent-lint.sh"

# Source the harness only when running standalone — under self-test.sh
# the runner has already sourced it and owns the counter globals.
if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ ! -f "$SCRIPT_DIR/_harness.sh" ]; then
    echo "  ❌ Harness not found at $SCRIPT_DIR/_harness.sh"
    exit 1
  fi
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/_harness.sh"
fi

echo "=== Phase 12.01 — M04 model diversity ==="

if ! command -v jq >/dev/null 2>&1; then
  TOTAL=$((TOTAL + 1))
  FAIL=$((FAIL + 1))
  echo "  ❌ jq is required (install jq or run via framework/scripts/self-test.sh)"
  exit 1
fi

# --- C-1: routing JSON valid ---
TOTAL=$((TOTAL + 1))
if [ ! -f "$ROUTING" ]; then
  echo "  ❌ C-1: routing config missing at $ROUTING"; FAIL=$((FAIL + 1))
elif ! jq -e . "$ROUTING" >/dev/null 2>&1; then
  echo "  ❌ C-1: $ROUTING is not valid JSON"; FAIL=$((FAIL + 1))
elif ! jq -e '.routing | type == "object"' "$ROUTING" >/dev/null 2>&1; then
  echo "  ❌ C-1: $ROUTING missing top-level .routing object"; FAIL=$((FAIL + 1))
else
  echo "  ✅ C-1: routing config is valid JSON"; PASS=$((PASS + 1))
fi

get_expected_model() {
  awk '
    BEGIN { in_fm = 0; n = 0 }
    /^---$/ { n++; if (n == 1) { in_fm = 1; next } if (n == 2) { exit } }
    in_fm && /^expected_model:[[:space:]]*/ {
      sub(/^expected_model:[[:space:]]*/, "", $0)
      gsub(/[[:space:]]+$/, "", $0)
      print
      exit
    }
  ' "$1"
}

get_routing_default() {
  jq -r --arg a "$1" '.routing[$a].default // ""' "$ROUTING"
}

# --- C-2 + C-3: critic / verifier / auditor declare opus, routing agrees ---
for agent in critic verifier auditor; do
  AGENT_MD="$AGENTS_DIR/$agent.md"
  TOTAL=$((TOTAL + 1))
  if [ ! -f "$AGENT_MD" ]; then
    echo "  ❌ C-2/$agent: agent file missing at $AGENT_MD"; FAIL=$((FAIL + 1))
    TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
    continue
  fi
  declared=$(get_expected_model "$AGENT_MD")
  routed=$(get_routing_default "$agent")
  if [ "$declared" = "opus" ]; then
    echo "  ✅ C-2/$agent: frontmatter declares expected_model: opus"; PASS=$((PASS + 1))
  else
    echo "  ❌ C-2/$agent: expected expected_model: opus, got '${declared:-<missing>}'"; FAIL=$((FAIL + 1))
  fi
  TOTAL=$((TOTAL + 1))
  if [ "$routed" = "opus" ]; then
    echo "  ✅ C-3/$agent: routing default = opus"; PASS=$((PASS + 1))
  else
    echo "  ❌ C-3/$agent: routing default expected opus, got '${routed:-<missing>}'"; FAIL=$((FAIL + 1))
  fi
done

# --- C-4: executor + architect default to sonnet (diversity lower half) ---
for agent in executor architect; do
  TOTAL=$((TOTAL + 1))
  routed=$(get_routing_default "$agent")
  if [ "$routed" = "sonnet" ]; then
    echo "  ✅ C-4/$agent: routing default = sonnet"; PASS=$((PASS + 1))
  else
    echo "  ❌ C-4/$agent: routing default expected sonnet, got '${routed:-<missing>}'"; FAIL=$((FAIL + 1))
  fi
done

# --- C-5: diversity invariant ---
TOTAL=$((TOTAL + 1))
exec_model=$(get_routing_default "executor")
critic_model=$(get_routing_default "critic")
if [ -n "$exec_model" ] && [ -n "$critic_model" ] && [ "$exec_model" != "$critic_model" ]; then
  echo "  ✅ C-5: diversity invariant holds (executor=$exec_model, critic=$critic_model)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-5: diversity invariant violated (executor=$exec_model, critic=$critic_model)"
  FAIL=$((FAIL + 1))
fi

# --- C-6: doc exists ---
TOTAL=$((TOTAL + 1))
if [ -f "$DOC" ] && grep -q "Phase 12.01" "$DOC" 2>/dev/null; then
  echo "  ✅ C-6: MODEL-ROUTING.md exists and references Phase 12.01"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-6: MODEL-ROUTING.md missing or stale at $DOC"
  FAIL=$((FAIL + 1))
fi

# --- C-7: agent-lint.sh has the expected_model check wired ---
TOTAL=$((TOTAL + 1))
if [ -f "$LINT" ] && grep -q "expected_model" "$LINT" 2>/dev/null; then
  echo "  ✅ C-7: agent-lint.sh references expected_model"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-7: agent-lint.sh missing expected_model handling at $LINT"
  FAIL=$((FAIL + 1))
fi

# Standalone exit semantics — non-zero on any failure when run directly.
if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  echo ""
  echo "$PASS/$TOTAL passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] || exit 1
fi
