#!/usr/bin/env node
/**
 * R-25-19 — AC-103 content validator for /apex:ui-review Snapshot consumption.
 *
 * The original AC-103 verify recipe was a grep for the literal string
 * `PINSCOPE EVIDENCE`. This script reads
 * `framework/commands/apex/ui-review.md`, finds the
 * `## PINSCOPE EVIDENCE` section, and asserts the section body contains
 * substantive review-evidence ingestion instructions:
 *   (1) references the `Snapshot` artifact (or `.pinscope/snapshots/`)
 *   (2) references pending `Operations` to ingest
 *   (3) makes clear what review value each artifact carries (rect /
 *       computed state / intended change)
 *
 * Usage: node pinscope/scripts/simulate-apex-ui-review.mjs
 * Exit codes: 0 = pass, 1 = fail (one-line stderr diagnostic).
 */

import fs from 'node:fs';
import path from 'node:path';

const target = process.argv[2] ?? 'framework/commands/apex/ui-review.md';
const abs = path.resolve(target);

function fail(msg) {
  process.stderr.write(`simulate-apex-ui-review: FAIL — ${msg}\n`);
  process.exit(1);
}

if (!fs.existsSync(abs)) fail(`file not found: ${abs}`);
const raw = fs.readFileSync(abs, 'utf8');

const sectionMatch = /##\s+PINSCOPE EVIDENCE[\s\S]*?(?=\n##\s|\Z)/.exec(raw);
if (!sectionMatch) {
  fail('missing "## PINSCOPE EVIDENCE" section header');
}
const body = sectionMatch[0];

const checks = [
  {
    name: 'references Snapshot artifact or .pinscope/snapshots/ path',
    re: /Snapshot|\.pinscope\/snapshots/i,
  },
  {
    name: 'references pending Operations to ingest',
    re: /pending\s+(PinScope\s+)?Operations?|Operations?\s+(JSON|to\s+ingest)/i,
  },
  {
    name: 'states what review value the artifact carries (rect/computed/state)',
    re: /rect|computed|numeric\s+state|element\s+state/i,
  },
];

const missed = checks.filter((c) => !c.re.test(body)).map((c) => c.name);
if (missed.length > 0) {
  fail(`PINSCOPE EVIDENCE section lacks: ${missed.join('; ')}`);
}

process.stdout.write(
  `simulate-apex-ui-review: PASS — ${target} PINSCOPE EVIDENCE section covers Snapshot + pending Operations + per-artifact review value\n`,
);
process.exit(0);
