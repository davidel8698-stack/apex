#!/usr/bin/env node
/**
 * PinScope convergence — per-AC verification matrix runner.
 *
 * Runs the verify method of every acceptance criterion in ac-matrix.json
 * against the live `pinscope/` tree and writes ac-results-R{N}.json.
 *
 *   node ac-verify.mjs --round N [--only AC-001,AC-073]
 *
 * Replaces the original loop's generic "run npm test": each AC gets its own
 * falsifiable check, so carry-forward re-verification is automatic and exact.
 *
 * Exit: 0 = all PASS / UNAVAILABLE / MANUAL · 1 = >=1 FAIL · 2 = harness error.
 */
import { execSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync, rmSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

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

let matrix;
try {
  matrix = JSON.parse(readFileSync(path.join(CONV, 'ac-matrix.json'), 'utf8'));
} catch (e) {
  console.error('ac-verify: cannot read ac-matrix.json —', e.message);
  process.exit(2);
}

const capsPath = path.join(CONV, 'env-capabilities.json');
const caps = existsSync(capsPath)
  ? JSON.parse(readFileSync(capsPath, 'utf8'))
  : { browser: false, npm_registry: false, apex_install: false };

function envAvailable(env) {
  if (env === 'node') return true;
  if (env === 'browser') return caps.browser === true;
  if (env === 'apex-install') return caps.apex_install === true;
  return false;
}

function sh(cmd, cwd) {
  try {
    const out = execSync(cmd, {
      cwd: cwd || ROOT,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
      maxBuffer: 64 * 1024 * 1024,
    });
    return { code: 0, out };
  } catch (e) {
    return { code: e.status ?? 1, out: `${e.stdout || ''}${e.stderr || ''}` };
  }
}

/** Run the vitest suite once; return tag -> {passed, failed}. */
function collectTags() {
  const tags = {};
  const tmp = path.join(CONV, '.vitest-results.json');
  if (existsSync(tmp)) rmSync(tmp, { force: true });
  sh('npm run build', PINSCOPE); // dist/ for the deployment suite
  sh(`npx vitest run --reporter=json --outputFile=${JSON.stringify(tmp)}`, PINSCOPE);
  if (existsSync(tmp)) {
    try {
      const data = JSON.parse(readFileSync(tmp, 'utf8'));
      for (const file of data.testResults || []) {
        for (const a of file.assertionResults || []) {
          const full = [...(a.ancestorTitles || []), a.title || ''].join(' ');
          for (const tag of full.match(/AC-\d{3}/g) || []) {
            tags[tag] = tags[tag] || { passed: 0, failed: 0 };
            if (a.status === 'passed') tags[tag].passed += 1;
            else tags[tag].failed += 1;
          }
        }
      }
    } catch {
      /* leave tags empty — vitest-tag ACs will FAIL, surfacing the harness gap */
    }
    rmSync(tmp, { force: true });
  }
  if (caps.browser === true) collectPlaywrightTags(tags);
  return tags;
}

/** Merge Playwright integration-suite results (only when a browser exists). */
function collectPlaywrightTags(tags) {
  const r = sh('npx playwright test --reporter=json', PINSCOPE);
  let data;
  try {
    data = JSON.parse(r.out);
  } catch {
    return;
  }
  const walk = (suite) => {
    for (const spec of suite.specs || []) {
      const ok = (spec.tests || []).every((t) =>
        (t.results || []).every((res) => ['passed', 'expected'].includes(res.status)),
      );
      for (const tag of (spec.title || '').match(/AC-\d{3}/g) || []) {
        tags[tag] = tags[tag] || { passed: 0, failed: 0 };
        if (ok) tags[tag].passed += 1;
        else tags[tag].failed += 1;
      }
    }
    for (const s of suite.suites || []) walk(s);
  };
  for (const s of data.suites || []) walk(s);
}

function evalCriterion(c, tags) {
  const v = c.verify;
  const available = envAvailable(c.env);

  if (v.kind === 'manual') {
    return available
      ? { verdict: 'MANUAL', detail: v.note || 'manual verification required' }
      : { verdict: 'UNAVAILABLE', detail: `env '${c.env}' unavailable` };
  }
  if (!available) {
    return { verdict: 'UNAVAILABLE', detail: `env '${c.env}' unavailable` };
  }

  if (v.kind === 'vitest-tag') {
    const t = tags[v.tag] || { passed: 0, failed: 0 };
    const total = t.passed + t.failed;
    const min = v.min_tests || 1;
    if (total === 0) return { verdict: 'FAIL', detail: `no tests tagged ${v.tag}` };
    if (t.failed > 0) {
      return { verdict: 'FAIL', detail: `${t.failed}/${total} ${v.tag} tests failed` };
    }
    if (t.passed < min) {
      return { verdict: 'FAIL', detail: `${t.passed} ${v.tag} tests < min ${min}` };
    }
    return { verdict: 'PASS', detail: `${t.passed} ${v.tag} tests pass` };
  }

  if (v.kind === 'command') {
    const r = sh(v.cmd, ROOT);
    const want = v.expect_exit ?? 0;
    return r.code === want
      ? { verdict: 'PASS', detail: `exit ${r.code}` }
      : { verdict: 'FAIL', detail: `exit ${r.code}, expected ${want}` };
  }

  if (v.kind === 'grep') {
    let count = 0;
    for (const p of v.paths || []) {
      const abs = path.join(ROOT, p);
      const r = sh(`grep -E -c ${JSON.stringify(v.pattern)} ${JSON.stringify(abs)}`, ROOT);
      count += parseInt((r.out || '').trim() || '0', 10) || 0;
    }
    if (v.expect_count !== undefined) {
      return count === v.expect_count
        ? { verdict: 'PASS', detail: `${count} matches` }
        : { verdict: 'FAIL', detail: `${count} matches, expected ${v.expect_count}` };
    }
    const min = v.min_count ?? 1;
    return count >= min
      ? { verdict: 'PASS', detail: `${count} matches >= ${min}` }
      : { verdict: 'FAIL', detail: `${count} matches < ${min}` };
  }

  if (v.kind === 'build-grep') {
    const b = sh(v.build_cmd, path.join(ROOT, v.build_cwd || '.'));
    if (b.code !== 0) return { verdict: 'FAIL', detail: `build failed (exit ${b.code})` };
    const g = v.grep;
    const abs = path.join(ROOT, g.path);
    const r = sh(
      `grep -rlE ${JSON.stringify(g.pattern)} ${JSON.stringify(abs)} 2>/dev/null | wc -l`,
      ROOT,
    );
    const count = parseInt((r.out || '').trim() || '0', 10) || 0;
    const want = g.expect_count ?? 0;
    return count === want
      ? { verdict: 'PASS', detail: `${count} files match` }
      : { verdict: 'FAIL', detail: `${count} files match, expected ${want}` };
  }

  return { verdict: 'FAIL', detail: `unknown verify kind '${v.kind}'` };
}

// --- run ---
const needsVitest = matrix.criteria.some(
  (c) =>
    (!onlySet || onlySet.has(c.id)) &&
    c.verify.kind === 'vitest-tag' &&
    envAvailable(c.env),
);
const tags = needsVitest ? collectTags() : {};

const results = {};
let fails = 0;
for (const c of matrix.criteria) {
  if (onlySet && !onlySet.has(c.id)) continue;
  const r = evalCriterion(c, tags);
  results[c.id] = r;
  if (r.verdict === 'FAIL') fails += 1;
}

const out = {
  generated_at: new Date().toISOString(),
  round: Number(round),
  results,
};
const outPath = path.join(CONV, `ac-results-R${round}.json`);
writeFileSync(outPath, `${JSON.stringify(out, null, 2)}\n`);

const counts = {};
for (const r of Object.values(results)) {
  counts[r.verdict] = (counts[r.verdict] || 0) + 1;
}
console.log(
  `ac-verify R${round}: ` +
    ['PASS', 'FAIL', 'UNAVAILABLE', 'MANUAL']
      .filter((k) => counts[k])
      .map((k) => `${counts[k]} ${k}`)
      .join(' · '),
);
console.log(`→ ${outPath}`);
process.exit(fails > 0 ? 1 : 0);
