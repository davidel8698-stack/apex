#!/usr/bin/env node
/**
 * PinScope convergence — per-AC verification matrix runner (thin driver).
 *
 *   node ac-verify.mjs --round N [--only AC-001,AC-073]
 *
 * Runs each AC's verify method against the live `pinscope/` tree, writes
 * ac-results-R{N}.json. Pure evaluation logic lives in core/ac-eval.mjs.
 *
 * Exit: 0 = all PASS / UNAVAILABLE / MANUAL · 1 = >=1 FAIL ·
 *       2 = HARNESS_ERROR (verifier engine failed — not an impl gap) ·
 *       4 = SPEC drift · 5 = schema-invalid matrix.
 */
import { execSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync, rmSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { EXIT } from './core/verdict.mjs';
import { validateMatrix } from './core/schema.mjs';
import { checkSpecDrift } from './core/spec-hash.mjs';
import {
  parseVitestReport,
  parsePlaywrightReport,
  mergeTagMaps,
  evalCriterion,
  needsVitest,
  needsBuild,
  summarize,
} from './core/ac-eval.mjs';

const LIB = path.dirname(fileURLToPath(import.meta.url));
const CONV = path.dirname(LIB);
const ROOT = path.dirname(path.dirname(CONV));
const PINSCOPE = path.join(ROOT, 'pinscope');

function arg(name, def) {
  const i = process.argv.indexOf(name);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : def;
}
const round = arg('--round', '0');
const only = arg('--only', null);
const onlySet = only ? new Set(only.split(',').map((s) => s.trim())) : null;

function shell(cmd, cwd) {
  try {
    const out = execSync(cmd, {
      cwd: cwd ? path.join(ROOT, cwd) : ROOT,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
      maxBuffer: 64 * 1024 * 1024,
    });
    return { code: 0, out };
  } catch (e) {
    return { code: e.status ?? 1, out: `${e.stdout || ''}${e.stderr || ''}` };
  }
}

// --- matrix + schema ---
let matrix;
try {
  matrix = JSON.parse(readFileSync(path.join(CONV, 'ac-matrix.json'), 'utf8'));
} catch (e) {
  console.error(`ac-verify: cannot read ac-matrix.json — ${e.message}`);
  process.exit(EXIT.SCHEMA_INVALID);
}
{
  const v = validateMatrix(matrix);
  if (!v.ok) {
    console.error('ac-verify: ac-matrix.json failed schema validation:');
    for (const err of v.errors) console.error(`  - ${err}`);
    process.exit(EXIT.SCHEMA_INVALID);
  }
}

// --- SPEC-drift check ---
{
  const specPath = path.join(PINSCOPE, 'SPEC.md');
  if (existsSync(specPath)) {
    const drift = checkSpecDrift(readFileSync(specPath, 'utf8'), matrix);
    if (drift.drift) {
      console.error(`ac-verify: SPEC.md changed — recorded ${drift.recorded}, current ${drift.current}.`);
      console.error('  ac-matrix.json is stale. Regenerate it from SPEC Appendix A before');
      console.error('  running the loop — the loop must not verify against an outdated matrix.');
      process.exit(EXIT.SPEC_DRIFT);
    }
    if (drift.firstRun) {
      console.error('ac-verify: note — ac-matrix.json has no `generated_from_hash`; add one to enable drift detection.');
    }
  }
}

// --- environment capabilities ---
const capsPath = path.join(CONV, 'env-capabilities.json');
const caps = existsSync(capsPath)
  ? JSON.parse(readFileSync(capsPath, 'utf8'))
  : { browser: false, npm_registry: false, apex_install: false };

// --- collect test tags (only when an in-scope vitest-tag AC needs them) ---
let tags = {};
let harnessOk = true;
let harnessError = null;

if (needsVitest(matrix.criteria, onlySet, caps)) {
  if (needsBuild(matrix.criteria, onlySet)) shell('npm run build', 'pinscope');
  const tmp = path.join(CONV, '.vitest-results.json');
  if (existsSync(tmp)) rmSync(tmp, { force: true });
  shell(`npx vitest run --reporter=json --outputFile=${JSON.stringify(tmp)}`, 'pinscope');
  if (!existsSync(tmp)) {
    harnessOk = false;
    harnessError = 'vitest produced no JSON report';
  } else {
    const parsed = parseVitestReport(readFileSync(tmp, 'utf8'));
    rmSync(tmp, { force: true });
    if (!parsed.ok) {
      harnessOk = false;
      harnessError = parsed.error;
    } else {
      tags = parsed.tags;
    }
  }
  if (harnessOk && caps.browser === true) {
    const pw = shell('npx playwright test --reporter=json', 'pinscope');
    const parsed = parsePlaywrightReport(pw.out);
    if (!parsed.ok) {
      harnessOk = false;
      harnessError = parsed.error;
    } else {
      tags = mergeTagMaps(tags, parsed.tags);
    }
  }
}

// --- evaluate every in-scope criterion ---
const ctx = { tags, caps, harnessOk, shell, resolve: (p) => path.join(ROOT, p) };
const results = {};
for (const c of matrix.criteria) {
  if (onlySet && !onlySet.has(c.id)) continue;
  results[c.id] = evalCriterion(c, ctx);
}

const out = {
  generated_at: new Date().toISOString(),
  round: Number(round),
  harness_ok: harnessOk,
  ...(harnessError ? { harness_error: harnessError } : {}),
  results,
};
const outPath = path.join(CONV, `ac-results-R${round}.json`);
writeFileSync(outPath, `${JSON.stringify(out, null, 2)}\n`);

const { counts, fails, harnessErrors } = summarize(results);
console.log(
  `ac-verify R${round}: ` +
    ['PASS', 'FAIL', 'UNAVAILABLE', 'MANUAL', 'HARNESS_ERROR']
      .filter((k) => counts[k])
      .map((k) => `${counts[k]} ${k}`)
      .join(' · '),
);
console.log(`→ ${outPath}`);

if (harnessErrors > 0) {
  console.error(`ac-verify: HARNESS ERROR — ${harnessError || 'the verifier engine failed'}.`);
  console.error('  This is NOT 69 implementation gaps. Fix the test harness and re-run.');
  process.exit(EXIT.HARNESS_ERROR);
}
process.exit(fails > 0 ? EXIT.FAIL : EXIT.OK);
