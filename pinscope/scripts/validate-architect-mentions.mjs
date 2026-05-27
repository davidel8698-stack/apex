#!/usr/bin/env node
/**
 * R-25-20a — AC-104 content validator for architect + apex-frontend agent
 * PinScope skill references.
 *
 * The original AC-104 verify recipe was a grep for `pinscope` in both
 * files — that grep passes if the word appears once anywhere (even in
 * a comment dismissing PinScope). This script strengthens by asserting
 * BOTH files reference the `pinscope` skill specifically — by full path
 * (`apex-skills/pinscope`) or by qualifying it as a stack-skill /
 * skill-selection context.
 *
 * Usage: node pinscope/scripts/validate-architect-mentions.mjs
 * Exit codes: 0 = pass, 1 = fail (one-line stderr diagnostic).
 */

import fs from 'node:fs';
import path from 'node:path';

// Accept argv overrides for mutation testing; default to the canonical
// APEX-repo paths (used by the matrix `cmd` invocation in W7).
const targets =
  process.argv.length > 2
    ? process.argv.slice(2)
    : [
        'framework/agents/architect.md',
        'framework/modules/apex-frontend/agent.md',
      ];

function fail(msg) {
  process.stderr.write(`validate-architect-mentions: FAIL — ${msg}\n`);
  process.exit(1);
}

const missing = [];
const weak = [];

for (const t of targets) {
  const abs = path.resolve(t);
  if (!fs.existsSync(abs)) {
    missing.push(t);
    continue;
  }
  const raw = fs.readFileSync(abs, 'utf8');

  // Strong reference: explicit skill-path mention OR the `pinscope` token
  // qualified as a stack-skill / skill-selection context.
  const strong =
    /apex-skills\/pinscope/i.test(raw) ||
    /\bpinscope\b[^\n]*\b(skill|stack[_\s]skill|stack[_\s]skills)\b/i.test(raw) ||
    /\bstack[_\s]?skill[s]?\b[^\n]*\bpinscope\b/i.test(raw);

  if (!strong) weak.push(t);
}

if (missing.length > 0) fail(`file(s) not found: ${missing.join(', ')}`);
if (weak.length > 0) {
  fail(
    `file(s) mention pinscope but not as a stack-skill / apex-skill path: ${weak.join(', ')}`,
  );
}

process.stdout.write(
  `validate-architect-mentions: PASS — both ${targets.length} files reference the pinscope stack-skill explicitly\n`,
);
process.exit(0);
