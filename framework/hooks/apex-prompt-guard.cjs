#!/usr/bin/env node
// apex-prompt-guard.cjs — Node port of prompt-guard.sh.
//
// Spec anchor: apex-spec.md, Failure 9 — "apex-prompt-guard.js" in the
//   Defense-in-Depth Security Layer roster. CommonJS chosen over ESM to
//   avoid a package.json "type":"module" requirement (zero npm deps).
//   R6-014 (Wave 2) renamed prompt-guard.cjs → apex-prompt-guard.cjs to
//   match the spec literal `apex-` prefix; .cjs/.js extension equivalence
//   is documented in framework/docs/SECURITY-RUNTIME.md.
//
// Hook type
//   Auto-PreToolUse (Write|Edit|Agent) — invoked via:
//     node ~/.claude/hooks/apex-prompt-guard.cjs
//   from framework/settings.json. The .sh shim `prompt-guard.sh` (name
//   preserved per R6-014's preservation contract) delegates here when
//   node is available; otherwise it falls back to the original Bash logic
//   (no behavior change for Bash-only hosts).
//
// Behavior parity
//   Detection patterns are loaded from
//   framework/test-fixtures/security-patterns.json and are byte-equivalent
//   to the regex literals in prompt-guard.sh. Exit code 2 on match (block),
//   0 on clean — same contract as the .sh.
//
// Input
//   1. CLI argv[2] — the raw input string (test invocation pattern).
//   2. stdin JSON  — Claude Code hook protocol. Looks at
//      tool_input.content / tool_input.prompt / tool_input.new_string /
//      tool_input.command, whichever is present.
//
// R5-003 — Wave 5.

'use strict';

const sec = require('./security.cjs');

function extractInput() {
  // Priority 1: explicit argv (test path / shim fallback).
  const argv = process.argv.slice(2);
  if (argv.length > 0 && argv[0]) {
    return argv[0];
  }

  // Priority 2: stdin JSON (Claude Code hook protocol).
  if (process.stdin.isTTY) return '';
  const raw = sec.readStdinSync();
  if (!raw) return '';
  const parsed = sec.parseHookStdin(raw);
  if (parsed && typeof parsed === 'object') {
    const ti = parsed.tool_input || {};
    // Try the most common payload fields in priority order.
    return (
      ti.content ||
      ti.new_string ||
      ti.prompt ||
      ti.command ||
      ti.description ||
      ''
    );
  }
  // Non-JSON stdin → treat as the input string itself.
  return raw;
}

function main() {
  const input = extractInput();
  if (!input) {
    process.exit(0);
  }
  const hit = sec.matchPromptInjection(input);
  if (hit) {
    sec.emitBlock('PROMPT GUARD', hit.name, hit.matched);
    process.exit(2);
  }
  process.exit(0);
}

main();
