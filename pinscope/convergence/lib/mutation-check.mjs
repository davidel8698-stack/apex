#!/usr/bin/env node
/**
 * PinScope convergence — mutation check (driver).
 *
 *   node mutation-check.mjs --round N --files src/a.ts,src/b.ts [--max-per-file 5]
 *
 * For each changed source file, applies one-token mutations (core/mutate.mjs)
 * and re-runs the vitest suite per mutant. A mutant the suite still passes is a
 * SURVIVOR — the test backing that code is probably hollow, so the closure it
 * supports is not actually pinned. Writes mutation-R{N}.json for ps-verifier.
 *
 * Files are restored after every run AND in a finally block — a crash can
 * never leave the working tree mutated. Exit 0 always: this is a report, not a
 * gate; ps-verifier interprets the survivors.
 */
import { execSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { generateMutants } from './core/mutate.mjs';

const LIB = path.dirname(fileURLToPath(import.meta.url));
const CONV = path.dirname(LIB);
const ROOT = path.dirname(path.dirname(CONV));
const PINSCOPE = path.join(ROOT, 'pinscope');

function arg(name, def) {
  const i = process.argv.indexOf(name);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : def;
}
const round = arg('--round', '0');
const filesArg = arg('--files', '');
const maxPerFile = Number(arg('--max-per-file', '5'));
const TOTAL_CAP = 12; // bounds the per-round test-run count

// Mutate only real source files (never tests) that exist on disk.
const SRC = /\.(ts|tsx|mjs|js)$/;
const targets = filesArg
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean)
  .map((rel) => ({ rel, abs: path.join(ROOT, rel) }))
  .filter((t) => SRC.test(t.rel) && !/\.(test|spec)\./.test(t.rel) && existsSync(t.abs));

/** Run the vitest suite. true = suite PASSED (the mutant SURVIVED). */
function suitePasses() {
  try {
    execSync('npx vitest run --reporter=dot', {
      cwd: PINSCOPE,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
      timeout: 120000,
      maxBuffer: 64 * 1024 * 1024,
    });
    return true; // exit 0 → every test passed → mutant survived
  } catch {
    return false; // non-zero / timeout / crash → a test caught it → killed
  }
}

const report = {
  round: Number(round),
  generated_at: new Date().toISOString(),
  files: [],
  summary: { mutants: 0, killed: 0, survived: 0 },
};
let total = 0;

for (const t of targets) {
  if (total >= TOTAL_CAP) break;
  const original = readFileSync(t.abs, 'utf8');
  const entry = { file: t.rel, mutants_run: 0, killed: 0, survived: [] };
  try {
    const mutants = generateMutants(original, { max: Math.min(maxPerFile, TOTAL_CAP - total) });
    for (const m of mutants) {
      writeFileSync(t.abs, m.source);
      const survived = suitePasses();
      writeFileSync(t.abs, original); // restore immediately, before anything else
      entry.mutants_run += 1;
      total += 1;
      report.summary.mutants += 1;
      if (survived) {
        entry.survived.push({
          id: m.id, rule: m.rule, line: m.line, original: m.original, mutated: m.mutated,
        });
        report.summary.survived += 1;
      } else {
        entry.killed += 1;
        report.summary.killed += 1;
      }
    }
  } finally {
    writeFileSync(t.abs, original); // guarantee restore even if a run threw
  }
  report.files.push(entry);
}

const outPath = path.join(CONV, `mutation-R${round}.json`);
writeFileSync(outPath, `${JSON.stringify(report, null, 2)}\n`);
console.log(
  `mutation-check R${round}: ${report.summary.mutants} mutants · ` +
    `${report.summary.killed} killed · ${report.summary.survived} survived → ${outPath}`,
);
if (report.summary.survived > 0) {
  console.log('  survivors flag probably-hollow tests — ps-verifier keeps those ACs OPEN.');
}
process.exit(0);
