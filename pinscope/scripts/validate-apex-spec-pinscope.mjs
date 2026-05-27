#!/usr/bin/env node
/**
 * R-25-20b — AC-105 content validator for apex-spec.md PinScope section.
 *
 * The original AC-105 verify recipe was a grep for the literal string
 * `PinScope` — that grep passes against any incidental mention. This
 * script asserts apex-spec.md has a DEDICATED `## ` (or `## §`)
 * section header naming PinScope, AND that the section body covers
 * substantive PinScope contract points (scope, source-of-truth, dev-
 * only invariant).
 *
 * Usage: node pinscope/scripts/validate-apex-spec-pinscope.mjs
 * Exit codes: 0 = pass, 1 = fail (one-line stderr diagnostic).
 */

import fs from 'node:fs';
import path from 'node:path';

const target = process.argv[2] ?? 'apex-spec.md';
const abs = path.resolve(target);

function fail(msg) {
  process.stderr.write(`validate-apex-spec-pinscope: FAIL — ${msg}\n`);
  process.exit(1);
}

if (!fs.existsSync(abs)) fail(`file not found: ${abs}`);
const raw = fs.readFileSync(abs, 'utf8');

// Find a level-2 header that NAMES PinScope (case-sensitive).
const headerMatch = /^##\s+[^\n]*PinScope[^\n]*$/m.exec(raw);
if (!headerMatch) {
  fail('no `## …PinScope…` section header found in apex-spec.md');
}

// Extract the section body from the matched header to the next `## ` line.
const headerIdx = headerMatch.index;
const after = raw.slice(headerIdx + headerMatch[0].length);
const nextHeader = /\n##\s/.exec(after);
const body = nextHeader ? after.slice(0, nextHeader.index) : after;

const checks = [
  {
    name: 'states PinScope scope (bundled UI-feedback product or visual-debug HUD)',
    re: /bundled|visual[-\s]debug|UI[-\s]?feedback/i,
  },
  {
    name: 'names the PinScope source-of-truth (pinscope/SPEC.md)',
    re: /pinscope\/SPEC\.md/i,
  },
  {
    name: 'states the dev-only / production-stripped invariant',
    re: /dev[-\s]only|stripped|zero\s+bytes|tree[-\s]shaken|never\s+ships/i,
  },
];

const missed = checks.filter((c) => !c.re.test(body)).map((c) => c.name);
if (missed.length > 0) {
  fail(`PinScope section in apex-spec.md lacks: ${missed.join('; ')}`);
}

process.stdout.write(
  `validate-apex-spec-pinscope: PASS — ${target} has a dedicated PinScope section covering scope + source-of-truth + dev-only invariant\n`,
);
process.exit(0);
