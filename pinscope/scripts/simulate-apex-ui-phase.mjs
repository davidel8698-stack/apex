#!/usr/bin/env node
/**
 * R-25-18 — AC-102 content validator for /apex:ui-phase PinScope scaffolding.
 *
 * The original AC-102 verify recipe was a grep for the literal string
 * `PINSCOPE INSTRUMENTATION` — that grep passes against any file that
 * mentions the heading in a comment or example block, even if the
 * scaffolding instructions themselves are missing.
 *
 * This script reads `framework/commands/apex/ui-phase.md`, finds the
 * `## PINSCOPE INSTRUMENTATION` section, and asserts the section body
 * contains substantive scaffolding instructions:
 *   (1) names the Vite plugin (e.g., `pinscope/vite` or `pinscope/next`)
 *   (2) names the runtime mount (`<PinScope />` or `<PinScope/>`)
 *   (3) clarifies the dev-only / production-stripped contract
 *
 * Usage: node pinscope/scripts/simulate-apex-ui-phase.mjs
 * Exit codes: 0 = pass, 1 = fail (one-line stderr diagnostic).
 */

import fs from 'node:fs';
import path from 'node:path';

const target = process.argv[2] ?? 'framework/commands/apex/ui-phase.md';
const abs = path.resolve(target);

function fail(msg) {
  process.stderr.write(`simulate-apex-ui-phase: FAIL — ${msg}\n`);
  process.exit(1);
}

if (!fs.existsSync(abs)) fail(`file not found: ${abs}`);
const raw = fs.readFileSync(abs, 'utf8');

const sectionMatch = /##\s+PINSCOPE INSTRUMENTATION[\s\S]*?(?=\n##\s|\Z)/.exec(raw);
if (!sectionMatch) {
  fail('missing "## PINSCOPE INSTRUMENTATION" section header');
}
const body = sectionMatch[0];

const checks = [
  {
    name: 'names the Vite plugin (pinscope/vite or pinscope/next)',
    re: /pinscope\/(vite|next)/i,
  },
  {
    name: 'names the runtime mount (<PinScope />)',
    re: /<PinScope\s*\/>/,
  },
  {
    name: 'clarifies dev-only / stripped-from-production contract',
    re: /dev[- ]only|stripped\s+from\s+production|never\s+ships/i,
  },
];

const missed = checks.filter((c) => !c.re.test(body)).map((c) => c.name);
if (missed.length > 0) {
  fail(`PINSCOPE INSTRUMENTATION section lacks: ${missed.join('; ')}`);
}

process.stdout.write(
  `simulate-apex-ui-phase: PASS — ${target} PINSCOPE INSTRUMENTATION section covers plugin import + runtime mount + dev-only contract\n`,
);
process.exit(0);
