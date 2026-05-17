#!/bin/bash
set -u
# agent-lint.sh — Module/agent contract validator (R5-021).
#
# Hook type: Command-Invoked
#
# Purpose
#   Validates that a generated module under framework/modules/<name>/
#   conforms to the manifest schema (R5-001) and the agent prompt
#   conventions (frontmatter, required sections, no name collision).
#   Powers the validation step of /apex:new-agent: scaffold → lint →
#   on failure, emit FIX_PLAN.md.
#
# Spec anchor
#   "/apex:new-agent (חידוש מ-BMAD's Builder)" + "Platform, Not Tool."
#   Without contract validation, community agents fail silently — the
#   platform thesis breaks.
#
# Usage
#   bash agent-lint.sh <module-path>
#     where <module-path> is e.g. framework/modules/apex-analytics
#   Optional second arg: <fix-plan-path> — where to write FIX_PLAN.md
#   on failure (defaults to <module-path>/FIX_PLAN.md).
#
# Exit codes
#   0 = lint passed
#   2 = lint failed (FIX_PLAN.md written if path given/derivable)
#   1 = invocation error (bad args, missing module dir)

source "$(dirname "$0")/_require-jq.sh"
require_jq

MODULE_PATH="${1:-}"
FIX_PLAN_PATH="${2:-}"

if [ -z "$MODULE_PATH" ]; then
  echo "🚫 agent-lint: module path required" >&2
  echo "   Usage: bash agent-lint.sh <module-path> [fix-plan-path]" >&2
  exit 1
fi

if [ ! -d "$MODULE_PATH" ]; then
  echo "🚫 agent-lint: module directory not found: $MODULE_PATH" >&2
  exit 1
fi

# Default FIX_PLAN.md location: inside the module dir.
[ -z "$FIX_PLAN_PATH" ] && FIX_PLAN_PATH="$MODULE_PATH/FIX_PLAN.md"

MANIFEST="$MODULE_PATH/manifest.json"
AGENT_MD="$MODULE_PATH/agent.md"

# Resolve schema + registry paths. Walk up from the module dir until
# we find _schema/manifest.schema.json (sibling under modules/) or
# fall through to a hardcoded REPO_ROOT/framework path.
SCHEMA_PATH=""
REGISTRY_PATH=""
PARENT="$MODULE_PATH"
for _ in 1 2 3 4 5 6; do
  PARENT="$(dirname "$PARENT")"
  [ -z "$PARENT" ] && break
  if [ -f "$PARENT/_schema/manifest.schema.json" ]; then
    SCHEMA_PATH="$PARENT/_schema/manifest.schema.json"
    REGISTRY_PATH="$PARENT/_registry.json"
    break
  fi
done

# Fallbacks if walk-up didn't find them.
# R8-003: install-side path (~/.claude/modules/_schema/manifest.schema.json)
# is prepended so a `~/.claude/`-only install (no framework checkout)
# resolves the schema first. Source-side fallbacks remain unchanged so
# framework-tree invocations continue to work.
if [ -z "$SCHEMA_PATH" ]; then
  for candidate in \
      "$HOME/.claude/modules/_schema/manifest.schema.json" \
      "$(dirname "$0")/../modules/_schema/manifest.schema.json" \
      "$(dirname "$0")/../../framework/modules/_schema/manifest.schema.json" \
      "framework/modules/_schema/manifest.schema.json"; do
    if [ -f "$candidate" ]; then
      SCHEMA_PATH="$candidate"
      REGISTRY_PATH="$(dirname "$candidate")/../_registry.json"
      break
    fi
  done
fi

REQUIRED_SECTIONS=(
  "## Role"
  "## Domain Invariants"
  "## Named Failure Prohibitions"
  "## Output Contract"
)

ISSUES=()

# --- Check 1: manifest.json exists ---
if [ ! -f "$MANIFEST" ]; then
  ISSUES+=("missing-manifest: $MANIFEST does not exist")
fi

# --- R6-005 Stub fast-path -----------------------------------------------
# Spec-named stub modules (status == "stub" with agent_path == null) are
# canonical placeholders, not contract failures. Lint passes them with a
# stub-acknowledged stderr message and writes no FIX_PLAN.md. Active
# modules continue to follow the full check pipeline below.
if [ -f "$MANIFEST" ] && jq -e . "$MANIFEST" >/dev/null 2>&1; then
  STUB_STATUS=$(jq -r '.status // empty' "$MANIFEST" 2>/dev/null)
  STUB_AGENT_PATH=$(jq -r '.agent_path // "null"' "$MANIFEST" 2>/dev/null)
  if [ "$STUB_STATUS" = "stub" ] && [ "$STUB_AGENT_PATH" = "null" ]; then
    echo "✅ agent-lint: $MODULE_PATH stub acknowledged (status=stub, agent_path=null)" >&2
    # Clear any stale FIX_PLAN.md from a prior run that pre-dated the fast-path.
    [ -f "$FIX_PLAN_PATH" ] && rm -f "$FIX_PLAN_PATH"
    exit 0
  fi
fi

# --- Check 2: agent.md exists ---
if [ ! -f "$AGENT_MD" ]; then
  ISSUES+=("missing-agent-md: $AGENT_MD does not exist")
fi

# --- Check 3: manifest schema validation ---
# We do a minimal schema check using jq (no external validator dep):
# verify required fields and field types. This is faithful to
# manifest.schema.json's required: [name, version, owner, status, capabilities].
if [ -f "$MANIFEST" ]; then
  if ! jq -e . "$MANIFEST" >/dev/null 2>&1; then
    ISSUES+=("manifest-invalid-json: $MANIFEST is not valid JSON")
  else
    # Required fields per schema
    for field in name version owner status capabilities; do
      if ! jq -e "has(\"$field\")" "$MANIFEST" >/dev/null 2>&1; then
        ISSUES+=("manifest-missing-field: $field is required")
      fi
    done
    # name pattern: ^apex-[a-z][a-z0-9-]*$
    NAME=$(jq -r '.name // empty' "$MANIFEST" 2>/dev/null)
    if [ -n "$NAME" ] && ! echo "$NAME" | grep -qE '^apex-[a-z][a-z0-9-]*$'; then
      ISSUES+=("manifest-name-pattern: name '$NAME' must match ^apex-[a-z][a-z0-9-]*\$")
    fi
    # version pattern: SemVer
    VERSION=$(jq -r '.version // empty' "$MANIFEST" 2>/dev/null)
    if [ -n "$VERSION" ] && ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$'; then
      ISSUES+=("manifest-version-pattern: version '$VERSION' must be SemVer")
    fi
    # status enum
    STATUS=$(jq -r '.status // empty' "$MANIFEST" 2>/dev/null)
    if [ -n "$STATUS" ] && [ "$STATUS" != "active" ] && [ "$STATUS" != "stub" ] && [ "$STATUS" != "core" ]; then
      ISSUES+=("manifest-status-enum: status '$STATUS' must be active|stub|core")
    fi
    # capabilities must be array
    if ! jq -e '.capabilities | type == "array"' "$MANIFEST" >/dev/null 2>&1; then
      ISSUES+=("manifest-capabilities-type: capabilities must be an array")
    fi
  fi
fi

# --- Check 4: agent.md frontmatter (description, tools required) ---
if [ -f "$AGENT_MD" ]; then
  # Extract YAML frontmatter (between leading --- and next ---).
  FM=$(awk 'BEGIN{in_fm=0; n=0} /^---$/{n++; if(n==1){in_fm=1; next} if(n==2){in_fm=0; exit}} in_fm{print}' "$AGENT_MD")
  if [ -z "$FM" ]; then
    ISSUES+=("agent-md-no-frontmatter: $AGENT_MD missing YAML frontmatter")
  else
    if ! echo "$FM" | grep -qE '^name:[[:space:]]*[a-z][a-z0-9-]*[[:space:]]*$'; then
      ISSUES+=("agent-md-frontmatter-name: missing or malformed 'name:' field")
    fi
    if ! echo "$FM" | grep -qE '^description:[[:space:]]*.+'; then
      ISSUES+=("agent-md-frontmatter-description: missing 'description:' field")
    fi
    if ! echo "$FM" | grep -qE '^tools:[[:space:]]*.+'; then
      ISSUES+=("agent-md-frontmatter-tools: missing 'tools:' field")
    fi
  fi

  # Required sections in the prompt body.
  for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -qE "^$section\$" "$AGENT_MD" && ! grep -qE "^$section[[:space:]]*\$" "$AGENT_MD"; then
      ISSUES+=("agent-md-missing-section: '$section' header not found")
    fi
  done

  # --- M04 (Phase 12.01): expected_model frontmatter advisory ---
  # If the agent declares `expected_model:`, warn (do NOT fail) when it
  # disagrees with the routing default. Missing field → no warning, no
  # action (legacy modules are unaffected). The routing JSON is the
  # source of truth; the frontmatter is the agent's own assertion.
  DECLARED_MODEL=$(echo "$FM" | sed -nE 's/^expected_model:[[:space:]]*([^[:space:]]+).*$/\1/p' | head -1)
  if [ -n "$DECLARED_MODEL" ]; then
    AGENT_NAME=$(echo "$FM" | sed -nE 's/^name:[[:space:]]*([a-z][a-z0-9-]*).*$/\1/p' | head -1)
    # Walk up to find apex-model-routing.json (mirrors the schema walk above).
    ROUTING_PATH=""
    PARENT_R="$AGENT_MD"
    for _ in 1 2 3 4 5 6; do
      PARENT_R="$(dirname "$PARENT_R")"
      [ -z "$PARENT_R" ] && break
      if [ -f "$PARENT_R/apex-model-routing.json" ]; then
        ROUTING_PATH="$PARENT_R/apex-model-routing.json"
        break
      fi
    done
    if [ -z "$ROUTING_PATH" ]; then
      for candidate in \
          "$HOME/.claude/apex-model-routing.json" \
          "$(dirname "$0")/../apex-model-routing.json" \
          "framework/apex-model-routing.json"; do
        if [ -f "$candidate" ]; then
          ROUTING_PATH="$candidate"
          break
        fi
      done
    fi
    if [ -n "$ROUTING_PATH" ] && [ -n "$AGENT_NAME" ] && jq -e . "$ROUTING_PATH" >/dev/null 2>&1; then
      ROUTED=$(jq -r --arg a "$AGENT_NAME" '.routing[$a].default // ""' "$ROUTING_PATH" 2>/dev/null)
      if [ -n "$ROUTED" ] && [ "$ROUTED" != "$DECLARED_MODEL" ]; then
        echo "⚠️  agent-lint: expected_model='$DECLARED_MODEL' but routing default for '$AGENT_NAME' is '$ROUTED' (M04 advisory; not blocking)" >&2
      fi
    fi
  fi
fi

# --- Check 5: registry collision (if registry exists) ---
if [ -f "$MANIFEST" ] && [ -n "$REGISTRY_PATH" ] && [ -f "$REGISTRY_PATH" ]; then
  NAME=$(jq -r '.name // empty' "$MANIFEST" 2>/dev/null)
  if [ -n "$NAME" ]; then
    # Look for the same name in registry, but allow self-listing
    # (the module being linted may already be in the registry).
    REG_HITS=$(jq -r --arg n "$NAME" '
      ((.modules // []) + (.additional_modules // []))
      | map(select(.name == $n))
      | length
    ' "$REGISTRY_PATH" 2>/dev/null || echo 0)
    # Hits > 1 means duplicate listings; we don't enforce that the
    # module IS listed (registry update is the caller's job).
    if [ "$REG_HITS" -gt 1 ]; then
      ISSUES+=("registry-duplicate: '$NAME' appears $REG_HITS times in $REGISTRY_PATH")
    fi
  fi
fi

# --- Verdict ---
if [ ${#ISSUES[@]} -eq 0 ]; then
  echo "✅ agent-lint: $MODULE_PATH passes (manifest + agent.md + registry checks)"
  # Clear any stale FIX_PLAN.md from a prior failed run.
  [ -f "$FIX_PLAN_PATH" ] && rm -f "$FIX_PLAN_PATH"
  exit 0
fi

# --- Failure: emit FIX_PLAN.md ---
mkdir -p "$(dirname "$FIX_PLAN_PATH")"
{
  echo "# FIX_PLAN — agent-lint failure for $(basename "$MODULE_PATH")"
  echo ""
  echo "**Module path:** \`$MODULE_PATH\`"
  echo "**Manifest:**    \`$MANIFEST\`"
  echo "**Agent prompt:** \`$AGENT_MD\`"
  echo "**Lint date:**   $(date +%Y-%m-%d)"
  echo ""
  echo "## Issues (${#ISSUES[@]})"
  echo ""
  for i in "${ISSUES[@]}"; do
    echo "- $i"
  done
  echo ""
  echo "## How to fix"
  echo ""
  for i in "${ISSUES[@]}"; do
    case "$i" in
      missing-manifest:*)
        echo "- Create \`$MANIFEST\` matching \`framework/modules/_schema/manifest.schema.json\`. Required fields: name, version, owner, status, capabilities."
        ;;
      missing-agent-md:*)
        echo "- Create \`$AGENT_MD\` with YAML frontmatter (name, description, tools) and the four required sections: Role, Domain Invariants, Named Failure Prohibitions, Output Contract."
        ;;
      manifest-invalid-json:*)
        echo "- Make \`$MANIFEST\` valid JSON. Run \`jq . \$MANIFEST\` to see the parse error."
        ;;
      manifest-missing-field:*)
        FIELD=$(echo "$i" | sed -nE 's/.*: ([a-z]+) is required.*/\1/p')
        echo "- Add \`\"$FIELD\":\` to \`$MANIFEST\`. Schema reference: \`framework/modules/_schema/manifest.schema.json\`."
        ;;
      manifest-name-pattern:*)
        echo "- Manifest \`name\` must match \`^apex-[a-z][a-z0-9-]*\$\`. Convention: \`apex-<domain>\`."
        ;;
      manifest-version-pattern:*)
        echo "- Manifest \`version\` must be SemVer (e.g. \`0.1.0\`)."
        ;;
      manifest-status-enum:*)
        echo "- Manifest \`status\` must be one of: \`active\`, \`stub\`, \`core\`."
        ;;
      manifest-capabilities-type:*)
        echo "- Manifest \`capabilities\` must be a JSON array (e.g. \`[\"analytics\"]\`)."
        ;;
      agent-md-no-frontmatter:*)
        echo "- Add YAML frontmatter to \`$AGENT_MD\` between leading and trailing \`---\` lines."
        ;;
      agent-md-frontmatter-name:*)
        echo "- Add \`name: <agent-name>\` to the frontmatter of \`$AGENT_MD\`."
        ;;
      agent-md-frontmatter-description:*)
        echo "- Add \`description: <one-line>\` to the frontmatter of \`$AGENT_MD\`."
        ;;
      agent-md-frontmatter-tools:*)
        echo "- Add \`tools: <comma-separated tool list>\` to the frontmatter of \`$AGENT_MD\` (e.g. \`tools: Read, Write, Bash\`)."
        ;;
      agent-md-missing-section:*)
        SECTION=$(echo "$i" | sed -nE "s/.*'([^']+)' header not found.*/\1/p")
        echo "- Add a \`$SECTION\` heading to \`$AGENT_MD\`."
        ;;
      registry-duplicate:*)
        echo "- Remove the duplicate listing in \`$REGISTRY_PATH\`."
        ;;
      *)
        echo "- $i"
        ;;
    esac
  done
  echo ""
  echo "After fixing, re-run: \`bash framework/hooks/agent-lint.sh $MODULE_PATH\`"
} > "$FIX_PLAN_PATH"

echo "🚫 agent-lint: ${#ISSUES[@]} issue(s) — see $FIX_PLAN_PATH" >&2
for i in "${ISSUES[@]}"; do
  echo "   - $i" >&2
done
exit 2
