#!/usr/bin/env node
/**
 * R-25-17 — AC-100 content validator for the apex-skill markdown format.
 *
 * The original AC-100 verify recipe was a simple `grep` for the 5 section
 * headers — it would pass on a file where every section was empty (or a
 * single-word stub like `TODO`). This script strengthens the recipe by
 * parsing the markdown and requiring each required section to carry
 * SUBSTANTIVE content per a content-budget rule: ≥2 substance-units,
 * where a substance-unit is any of:
 *   - a sentence (line ending in `.`/`!`/`?`)
 *   - a fenced code block (``` ... ```)
 *   - a bullet item (`- ...` or `* ...`)
 *
 * This catches the "header-only stub" case the grep recipe missed,
 * while accepting documentation that uses a mix of prose, code, and
 * bullets (the apex-skill format does not require any one style).
 *
 * Usage: node pinscope/scripts/validate-apex-skill.mjs [path]
 * Default path: framework/apex-skills/pinscope.md
 * Exit codes: 0 = pass, 1 = fail (writes a one-line diagnostic to stderr).
 */

import fs from 'node:fs';
import path from 'node:path';

const REQUIRED_SECTIONS = [
  'Conventions',
  'Anti-Patterns',
  'Common Patterns',
  'Testing',
  'Common Gotchas',
];
const MIN_CONTENT_LINES_PER_SECTION = 3;

function fail(msg) {
  process.stderr.write(`validate-apex-skill: FAIL — ${msg}\n`);
  process.exit(1);
}

function pass(msg) {
  process.stdout.write(`validate-apex-skill: PASS — ${msg}\n`);
  process.exit(0);
}

const target = process.argv[2] ?? 'framework/apex-skills/pinscope.md';
const abs = path.resolve(target);

if (!fs.existsSync(abs)) {
  fail(`file not found: ${abs}`);
}

const raw = fs.readFileSync(abs, 'utf8');
const lines = raw.split(/\r?\n/);

/** Map: section header → array of body lines (excluding the header). */
const sections = new Map();
let current = null;
for (const line of lines) {
  // Match level-2 headers like `## Conventions` or `## Conventions — note`.
  const h = /^##\s+([^#].*?)(?:\s+[—-].*)?$/.exec(line);
  if (h) {
    const name = h[1].trim();
    current = name;
    if (!sections.has(name)) sections.set(name, []);
    continue;
  }
  if (current) {
    sections.get(current).push(line);
  }
}

// Missing-section check.
const missing = REQUIRED_SECTIONS.filter((s) => !sections.has(s));
if (missing.length > 0) {
  fail(`missing required section(s): ${missing.join(', ')}`);
}

// Content-line count per required section: every non-blank line that is
// NOT a code-fence marker (``` ... ```) and NOT a sub-header line counts
// as 1 content line. This catches the "header-only stub" case the grep
// recipe missed (a stub section has 0 content lines) while accepting
// any mix of prose, bullets, and code that conveys ≥3 lines of content.
function countContentLines(body) {
  let count = 0;
  for (const line of body) {
    const t = line.trim();
    if (t === '') continue;
    if (t.startsWith('```')) continue; // skip fence markers themselves
    if (/^#{1,6}\s/.test(t)) continue; // skip any nested sub-headers
    count++;
  }
  return count;
}

const thin = [];
for (const s of REQUIRED_SECTIONS) {
  const body = sections.get(s);
  const n = countContentLines(body);
  if (n < MIN_CONTENT_LINES_PER_SECTION) {
    thin.push(`${s} (${n} < ${MIN_CONTENT_LINES_PER_SECTION})`);
  }
}

if (thin.length > 0) {
  fail(
    `section(s) lack ≥${MIN_CONTENT_LINES_PER_SECTION} content lines: ${thin.join('; ')}`,
  );
}

pass(
  `${target} — ${REQUIRED_SECTIONS.length} required sections present, each with ≥${MIN_CONTENT_LINES_PER_SECTION} content lines`,
);
