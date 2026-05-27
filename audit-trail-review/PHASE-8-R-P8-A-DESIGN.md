# R-P8-A — Shared input-extraction helper `framework/hooks/_hook-input.sh`

## G0 research synthesis

Surveyed 5 templates. **Canonical choice:** owner-guard pattern (argv-first → stdin-fallback). Preserves all 9 argv-style test invocations; production stdin envelope covered by fallback.

## G1 API design

**File:** `framework/hooks/_hook-input.sh`

**Public API:**
- `apex_hook_input_command   "$@"` → `.tool_input.command`
- `apex_hook_input_filepath  "$@"` → `.tool_input.file_path` (or `.path`)
- `apex_hook_input_tool_name "$@"` → `.tool_name`
- `apex_hook_input_raw       "$@"` → full stdin payload

**Algorithm:** argv-first; else stdin via `[ ! -t 0 ]` + `cat`; else empty. Module-scope flag `_APEX_HOOK_STDIN_CACHED` prevents double-read.

**Edge cases:** empty/empty→empty; malformed JSON→jq returns empty; both present→argv wins; double-source→cached; jq missing→empty.

**Sourcing pattern (consumer-side):**
```bash
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi
```

## G4 layer tests (H-G0..H-G5)

Added in `test-audit-trail-layer.sh` before summary block.

## Critic R1 focus

1. Stdin double-read deadlock under multiple extractor calls
2. argv-vs-stdin priority (preserves backward-compat with 9 test invocations)
3. Quote handling parity (`printf '%s' "$1"` vs jq `-r`)
4. Sourcing pattern matches `_audit-probe-marker.sh` precedent
5. Helper NEVER `exit`s when sourced (only `return`)
6. `set -u` compatibility (all `${VAR:-}` default-expanded)

## Critic R2 acceptance

1. H-G0..H-G5 PASS standalone (6/6).
2. Reentrant (double-source safe).
3. 0 new dependencies.
4. Byte-equivalent to owner-guard's existing private extractor for matched input.
5. `bash -n` clean.
6. Wave-1 pilot hook sources cleanly under `set -u`.

## Ecosystem 10-question gate

(Answered in plan file `~/.claude/plans/calm-cuddling-corbato.md` § R-P8-A.)

## Blast radius

R-P8-A is pure additive (new file only). Zero existing hooks affected. Rollback: delete file + revert test rows.
