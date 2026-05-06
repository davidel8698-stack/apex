#!/usr/bin/env bash
# Test type: Structural — universal command coverage (R6-007).
#
# Spec anchor: "Verification universal, not TDD universal."
#
# Iterates every command file under framework/commands/apex/*.md
# (excluding the two helpers `_debate.md` and `_roundtable.md` from the
# user-facing surface check; helpers still get the description+GUARD
# checks below) and asserts three structural invariants per file:
#
#   (a) frontmatter has a non-empty `description:` field.
#   (b) body contains either `## PROPOSALS MODE GUARD` or a documented
#       exemption marker `<!-- proposals-mode-exempt: <reason> -->`.
#   (c) the command name (basename without .md) is referenced in
#       framework/commands/apex/help.md (the static help table) OR the
#       file declares an exemption marker
#       `<!-- help-exempt: <reason> -->`.
#
# Exits 0 on universal coverage; exits 1 with a per-file failure list
# otherwise.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CMD_DIR="$REPO_ROOT/framework/commands/apex"
HELP_MD="$CMD_DIR/help.md"

if [ ! -d "$CMD_DIR" ]; then
  echo "FAIL: command directory not found at $CMD_DIR" >&2
  exit 1
fi
if [ ! -f "$HELP_MD" ]; then
  echo "FAIL: help.md not found at $HELP_MD" >&2
  exit 1
fi

echo "=== R6-007: command-structure (universal coverage) ==="

TOTAL=0
PASS=0
FAIL=0
FAILURES=()

for f in "$CMD_DIR"/*.md; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  name="${base%.md}"
  TOTAL=$((TOTAL+1))
  fail_reasons=()

  # (a) frontmatter description
  if ! head -10 "$f" | grep -qE '^description:[[:space:]]*.+'; then
    fail_reasons+=("missing frontmatter 'description:'")
  fi

  # (b) PROPOSALS MODE GUARD or exemption marker
  if ! grep -qE '^## PROPOSALS MODE GUARD' "$f" \
     && ! grep -q 'proposals-mode-exempt' "$f"; then
    fail_reasons+=("missing '## PROPOSALS MODE GUARD' (or '<!-- proposals-mode-exempt: ... -->' marker)")
  fi

  # (c) help.md cross-reference OR help-exempt marker.
  # Helpers (_debate.md, _roundtable.md) are intentionally not in help.md
  # — they are subagent-only; they get an implicit help-exempt.
  case "$name" in
    _*) ;;
    *)
      if ! grep -q "/apex:$name\b" "$HELP_MD" \
         && ! grep -q 'help-exempt' "$f"; then
        fail_reasons+=("not referenced in help.md (or '<!-- help-exempt: ... -->' marker)")
      fi
      ;;
  esac

  if [ "${#fail_reasons[@]}" -eq 0 ]; then
    PASS=$((PASS+1))
  else
    FAIL=$((FAIL+1))
    for r in "${fail_reasons[@]}"; do
      FAILURES+=("$base: $r")
    done
  fi
done

echo
echo "Iterated $TOTAL command files."
echo "PASS=$PASS  FAIL=$FAIL"

if [ "$FAIL" -ne 0 ]; then
  echo
  echo "Failures:"
  for f in "${FAILURES[@]}"; do
    echo "  - $f"
  done
  exit 1
fi

echo "OK: every command satisfies (description) AND (GUARD or exempt) AND (help-ref or exempt)."
exit 0
