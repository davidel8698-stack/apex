#!/usr/bin/env bash
# R5-021: agent-lint test — validates the lint contract for /apex:new-agent.
#
# Tested invariants:
#   1. agent-lint.sh exists and is executable.
#   2. A well-formed module fixture passes (exit 0, no FIX_PLAN.md).
#   3. A bad fixture (missing tools field in agent.md) fails (exit 2)
#      and writes FIX_PLAN.md naming the missing field.
#   4. Missing manifest.json → exit 2 + FIX_PLAN entry.
#   5. Manifest with invalid name pattern → exit 2.
#   6. Manifest with missing required field (e.g. capabilities) → exit 2.
#   7. Missing required section in agent.md (e.g. "## Output Contract") → exit 2.
#   8. agent.md without frontmatter → exit 2.
#   9. Three-places contract: HOOK-CLASSIFICATION.md lists agent-lint.sh.
#  10. sync-to-claude.sh delivers the hook.
#  11. new-agent.md invokes agent-lint and references FIX_PLAN.md.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LINT="$REPO_ROOT/framework/hooks/agent-lint.sh"
NEW_AGENT_MD="$REPO_ROOT/framework/commands/apex/new-agent.md"
HOOK_CLASS="$REPO_ROOT/framework/HOOK-CLASSIFICATION.md"
SYNC_SH="$REPO_ROOT/framework/scripts/sync-to-claude.sh"

PASS=0
FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
nope() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== R5-021: agent-lint ==="

# C-1
if [ -f "$LINT" ]; then
  ok "C-1: agent-lint.sh exists"
else
  nope "C-1: agent-lint.sh missing at $LINT"
  echo "$PASS/$((PASS+FAIL)) passed"
  exit 1
fi

# Sandbox: build a fixture modules tree.
SANDBOX=$(mktemp -d)
MODULES_DIR="$SANDBOX/framework/modules"
mkdir -p "$MODULES_DIR/_schema"
cp "$REPO_ROOT/framework/modules/_schema/manifest.schema.json" "$MODULES_DIR/_schema/"
# Minimal registry with no entries (so collision check is permissive).
cat > "$MODULES_DIR/_registry.json" <<'EOF'
{
  "$schema_ref": "_schema/manifest.schema.json",
  "version": "1.0.0",
  "modules": [],
  "additional_modules": []
}
EOF

build_good_module() {
  local name="$1"
  local mdir="$MODULES_DIR/apex-${name}"
  mkdir -p "$mdir"
  cat > "$mdir/manifest.json" <<EOF
{
  "name": "apex-${name}",
  "version": "0.1.0",
  "owner": "test-author",
  "status": "active",
  "capabilities": ["${name}"],
  "agent_path": "agent.md",
  "hooks": [],
  "deps": [],
  "dispatch_aliases": ["${name}"],
  "notes": "Fixture for test-agent-lint."
}
EOF
  cat > "$mdir/agent.md" <<EOF
---
name: ${name}
description: Test fixture agent for agent-lint
tools: Read, Write, Bash
---

## Role
You are the ${name} specialist agent.

## Domain Invariants
- Always do X.

## Named Failure Prohibitions
- NEVER do Y.

## Output Contract
Write to a file path specified in task XML.
EOF
  echo "$mdir"
}

# C-2: well-formed module passes
GOOD=$(build_good_module "analytics")
bash "$LINT" "$GOOD" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 0 ] && [ ! -f "$GOOD/FIX_PLAN.md" ]; then
  ok "C-2: well-formed module passes (exit 0, no FIX_PLAN.md)"
else
  nope "C-2: expected exit 0 + no FIX_PLAN.md, got exit $RC, FIX_PLAN exists=$([ -f "$GOOD/FIX_PLAN.md" ] && echo yes || echo no)"
fi

# C-3: missing tools field in agent.md → fails
BAD_TOOLS=$(build_good_module "bad-tools")
# Strip the tools line.
sed -i '/^tools:/d' "$BAD_TOOLS/agent.md" 2>/dev/null || sed -i '' '/^tools:/d' "$BAD_TOOLS/agent.md"
bash "$LINT" "$BAD_TOOLS" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 2 ] && [ -f "$BAD_TOOLS/FIX_PLAN.md" ] && grep -q "tools" "$BAD_TOOLS/FIX_PLAN.md"; then
  ok "C-3: missing 'tools:' frontmatter → exit 2 + FIX_PLAN names tools"
else
  nope "C-3: expected exit 2 + FIX_PLAN naming tools, got exit $RC"
  [ -f "$BAD_TOOLS/FIX_PLAN.md" ] && head -20 "$BAD_TOOLS/FIX_PLAN.md" | sed 's/^/      /'
fi

# C-4: missing manifest.json → fails
BAD_NO_MANIFEST=$(build_good_module "no-manifest")
rm "$BAD_NO_MANIFEST/manifest.json"
bash "$LINT" "$BAD_NO_MANIFEST" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 2 ] && [ -f "$BAD_NO_MANIFEST/FIX_PLAN.md" ] && grep -q "manifest" "$BAD_NO_MANIFEST/FIX_PLAN.md"; then
  ok "C-4: missing manifest.json → exit 2 + FIX_PLAN names manifest"
else
  nope "C-4: expected exit 2 + FIX_PLAN naming manifest, got exit $RC"
fi

# C-5: invalid name pattern in manifest → fails
BAD_NAME=$(build_good_module "bad-name")
# Replace name with a non-conforming value.
jq '.name = "BAD_NAME"' "$BAD_NAME/manifest.json" > "$BAD_NAME/manifest.json.tmp" \
  && mv "$BAD_NAME/manifest.json.tmp" "$BAD_NAME/manifest.json"
bash "$LINT" "$BAD_NAME" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 2 ] && [ -f "$BAD_NAME/FIX_PLAN.md" ] && grep -qi "name" "$BAD_NAME/FIX_PLAN.md"; then
  ok "C-5: invalid manifest name pattern → exit 2 + FIX_PLAN names name"
else
  nope "C-5: expected exit 2, got exit $RC"
fi

# C-6: missing capabilities field → fails
BAD_FIELD=$(build_good_module "bad-field")
jq 'del(.capabilities)' "$BAD_FIELD/manifest.json" > "$BAD_FIELD/manifest.json.tmp" \
  && mv "$BAD_FIELD/manifest.json.tmp" "$BAD_FIELD/manifest.json"
bash "$LINT" "$BAD_FIELD" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 2 ] && [ -f "$BAD_FIELD/FIX_PLAN.md" ] && grep -q "capabilities" "$BAD_FIELD/FIX_PLAN.md"; then
  ok "C-6: missing 'capabilities' field → exit 2 + FIX_PLAN names it"
else
  nope "C-6: expected exit 2 + FIX_PLAN naming capabilities, got exit $RC"
fi

# C-7: missing required section ('## Output Contract')
BAD_SECTION=$(build_good_module "bad-section")
sed -i '/^## Output Contract$/,$d' "$BAD_SECTION/agent.md" 2>/dev/null \
  || sed -i '' '/^## Output Contract$/,$d' "$BAD_SECTION/agent.md"
bash "$LINT" "$BAD_SECTION" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 2 ] && [ -f "$BAD_SECTION/FIX_PLAN.md" ] && grep -q "Output Contract" "$BAD_SECTION/FIX_PLAN.md"; then
  ok "C-7: missing '## Output Contract' section → exit 2 + FIX_PLAN names it"
else
  nope "C-7: expected exit 2, got exit $RC"
fi

# C-8: agent.md without frontmatter → fails
BAD_NO_FM=$(build_good_module "bad-no-fm")
cat > "$BAD_NO_FM/agent.md" <<'EOF'
## Role
no frontmatter

## Domain Invariants
x

## Named Failure Prohibitions
y

## Output Contract
z
EOF
bash "$LINT" "$BAD_NO_FM" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 2 ] && [ -f "$BAD_NO_FM/FIX_PLAN.md" ] && grep -qi "frontmatter" "$BAD_NO_FM/FIX_PLAN.md"; then
  ok "C-8: agent.md without frontmatter → exit 2 + FIX_PLAN names frontmatter"
else
  nope "C-8: expected exit 2 + frontmatter mention, got exit $RC"
fi

# C-9: HOOK-CLASSIFICATION lists agent-lint
if grep -q "agent-lint.sh" "$HOOK_CLASS"; then
  ok "C-9: HOOK-CLASSIFICATION.md lists agent-lint.sh"
else
  nope "C-9: HOOK-CLASSIFICATION.md missing agent-lint.sh"
fi

# C-10: sync-to-claude.sh delivers
if grep -q "agent-lint.sh" "$SYNC_SH"; then
  ok "C-10: sync-to-claude.sh delivers agent-lint.sh"
else
  nope "C-10: sync-to-claude.sh missing agent-lint.sh"
fi

# C-11: new-agent.md invokes agent-lint and references FIX_PLAN.md
if grep -q "agent-lint.sh" "$NEW_AGENT_MD" && grep -q "FIX_PLAN.md" "$NEW_AGENT_MD"; then
  ok "C-11: new-agent.md invokes agent-lint and references FIX_PLAN.md"
else
  nope "C-11: new-agent.md missing agent-lint or FIX_PLAN.md reference"
fi

# C-12: re-running lint on a passed module clears stale FIX_PLAN.md
GOOD2=$(build_good_module "analytics2")
# Pre-write a stale FIX_PLAN.md
echo "stale" > "$GOOD2/FIX_PLAN.md"
bash "$LINT" "$GOOD2" >/dev/null 2>&1
if [ ! -f "$GOOD2/FIX_PLAN.md" ]; then
  ok "C-12: passing lint removes any stale FIX_PLAN.md from a prior run"
else
  nope "C-12: stale FIX_PLAN.md still present after passing lint"
fi

# --- R6-005: stub fast-path -------------------------------------------------
# Build a stub-shape fixture (status=="stub", agent_path==null, no agent.md).
# Lint must exit 0 and write NO FIX_PLAN.md.
build_stub_module() {
  local name="$1"
  local mdir="$MODULES_DIR/apex-${name}"
  mkdir -p "$mdir"
  cat > "$mdir/manifest.json" <<EOF
{
  "name": "apex-${name}",
  "version": "0.1.0",
  "owner": "test-author",
  "status": "stub",
  "capabilities": ["${name}"],
  "agent_path": null,
  "hooks": [],
  "deps": [],
  "dispatch_aliases": ["${name}"],
  "notes": "Stub fixture for R6-005 fast-path test."
}
EOF
  echo "$mdir"
}

STUB1=$(build_stub_module "stubfix")
bash "$LINT" "$STUB1" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 0 ] && [ ! -f "$STUB1/FIX_PLAN.md" ]; then
  ok "C-13: stub module (status=stub, agent_path=null) → exit 0, no FIX_PLAN.md (R6-005)"
else
  nope "C-13: expected exit 0 + no FIX_PLAN.md for stub, got exit $RC, FIX_PLAN exists=$([ -f "$STUB1/FIX_PLAN.md" ] && echo yes || echo no)"
fi

# C-14: spec-named stub modules in the live tree pass (apex-fintech).
LIVE_STUB="$REPO_ROOT/framework/modules/apex-fintech"
if [ -f "$LIVE_STUB/manifest.json" ]; then
  bash "$LINT" "$LIVE_STUB" >/dev/null 2>&1
  RC=$?
  if [ "$RC" -eq 0 ] && [ ! -f "$LIVE_STUB/FIX_PLAN.md" ]; then
    ok "C-14: live apex-fintech stub passes (R6-005)"
  else
    nope "C-14: live apex-fintech stub expected exit 0, got $RC"
  fi
fi

# C-15: spec-named stub modules pass (apex-healthcare).
LIVE_STUB2="$REPO_ROOT/framework/modules/apex-healthcare"
if [ -f "$LIVE_STUB2/manifest.json" ]; then
  bash "$LINT" "$LIVE_STUB2" >/dev/null 2>&1
  RC=$?
  if [ "$RC" -eq 0 ] && [ ! -f "$LIVE_STUB2/FIX_PLAN.md" ]; then
    ok "C-15: live apex-healthcare stub passes (R6-005)"
  else
    nope "C-15: live apex-healthcare stub expected exit 0, got $RC"
  fi
fi

# C-16: spec-named stub modules pass (apex-builder).
LIVE_STUB3="$REPO_ROOT/framework/modules/apex-builder"
if [ -f "$LIVE_STUB3/manifest.json" ]; then
  bash "$LINT" "$LIVE_STUB3" >/dev/null 2>&1
  RC=$?
  if [ "$RC" -eq 0 ] && [ ! -f "$LIVE_STUB3/FIX_PLAN.md" ]; then
    ok "C-16: live apex-builder stub passes (R6-005)"
  else
    nope "C-16: live apex-builder stub expected exit 0, got $RC"
  fi
fi

# C-17: an active module missing agent.md still fails (preservation of
# active-module enforcement — fast-path must not silently pass actives).
ACTIVE_MISSING=$(build_good_module "active-no-agent")
rm "$ACTIVE_MISSING/agent.md"
bash "$LINT" "$ACTIVE_MISSING" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 2 ]; then
  ok "C-17: active module missing agent.md still exits 2 (R6-005 preservation)"
else
  nope "C-17: expected exit 2 (active w/o agent.md), got $RC — fast-path may be misfiring"
fi

rm -rf "$SANDBOX"

TOTAL=$((PASS+FAIL))
echo ""
echo "$PASS/$TOTAL passed"
[ "$FAIL" -eq 0 ]
