import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  parseVitestReport,
  parsePlaywrightReport,
  mergeTagMaps,
  envAvailable,
  needsVitest,
  needsBuild,
  evalCriterion,
  summarize,
} from '../core/ac-eval.mjs';

test('parseVitestReport — good report builds the tag map', () => {
  const json = JSON.stringify({
    testResults: [
      {
        assertionResults: [
          { ancestorTitles: ['s'], title: 'a thing (AC-001)', status: 'passed' },
          { ancestorTitles: ['s'], title: 'another (AC-001)', status: 'passed' },
          { ancestorTitles: [], title: 'untagged', status: 'passed' },
        ],
      },
    ],
  });
  const r = parseVitestReport(json);
  assert.equal(r.ok, true);
  assert.deepEqual(r.tags['AC-001'], { passed: 2, failed: 0 });
});

test('parseVitestReport — malformed JSON returns ok:false (NOT silent)', () => {
  const r = parseVitestReport('{ not json');
  assert.equal(r.ok, false);
  assert.match(r.error, /not valid JSON/);
});

test('parseVitestReport — structurally empty report returns ok:false', () => {
  assert.equal(parseVitestReport(JSON.stringify({ foo: 'bar' })).ok, false);
});

test('parseVitestReport — counts a failed assertion', () => {
  const json = JSON.stringify({
    testResults: [{ assertionResults: [{ ancestorTitles: [], title: 'x (AC-009)', status: 'failed' }] }],
  });
  assert.deepEqual(parseVitestReport(json).tags['AC-009'], { passed: 0, failed: 1 });
});

test('parsePlaywrightReport — walks nested suites', () => {
  const json = JSON.stringify({
    suites: [
      {
        specs: [{ title: 'pw (AC-023)', tests: [{ results: [{ status: 'passed' }] }] }],
        suites: [],
      },
    ],
  });
  const r = parsePlaywrightReport(json);
  assert.equal(r.ok, true);
  assert.deepEqual(r.tags['AC-023'], { passed: 1, failed: 0 });
});

test('parsePlaywrightReport — malformed returns ok:false', () => {
  assert.equal(parsePlaywrightReport('xxx').ok, false);
});

test('mergeTagMaps sums passed/failed', () => {
  const m = mergeTagMaps(
    { 'AC-001': { passed: 1, failed: 0 } },
    { 'AC-001': { passed: 2, failed: 1 } },
  );
  assert.deepEqual(m['AC-001'], { passed: 3, failed: 1 });
});

test('envAvailable — node always; browser/apex gated by caps', () => {
  assert.equal(envAvailable('node', {}), true);
  assert.equal(envAvailable('browser', { browser: false }), false);
  assert.equal(envAvailable('browser', { browser: true }), true);
  assert.equal(envAvailable('apex-install', { apex_install: true }), true);
});

test('evalCriterion — vitest-tag PASS when tagged tests pass', () => {
  const c = { id: 'AC-001', env: 'node', verify: { kind: 'vitest-tag', tag: 'AC-001', min_tests: 1 } };
  const r = evalCriterion(c, { tags: { 'AC-001': { passed: 3, failed: 0 } }, caps: {}, harnessOk: true });
  assert.equal(r.verdict, 'PASS');
});

test('evalCriterion — vitest-tag FAIL when no tagged tests', () => {
  const c = { id: 'AC-001', env: 'node', verify: { kind: 'vitest-tag', tag: 'AC-001' } };
  assert.equal(evalCriterion(c, { tags: {}, caps: {}, harnessOk: true }).verdict, 'FAIL');
});

test('evalCriterion — vitest-tag becomes HARNESS_ERROR when the harness broke', () => {
  const c = { id: 'AC-001', env: 'node', verify: { kind: 'vitest-tag', tag: 'AC-001' } };
  const r = evalCriterion(c, { tags: {}, caps: {}, harnessOk: false });
  assert.equal(r.verdict, 'HARNESS_ERROR');
});

test('evalCriterion — browser env unavailable → UNAVAILABLE', () => {
  const c = { id: 'AC-023', env: 'browser', verify: { kind: 'vitest-tag', tag: 'AC-023' } };
  assert.equal(evalCriterion(c, { tags: {}, caps: { browser: false }, harnessOk: true }).verdict, 'UNAVAILABLE');
});

test('evalCriterion — manual kind: UNAVAILABLE without env, MANUAL with env', () => {
  const c = { id: 'AC-082', env: 'browser', verify: { kind: 'manual' } };
  assert.equal(evalCriterion(c, { caps: { browser: false }, harnessOk: true }).verdict, 'UNAVAILABLE');
  assert.equal(evalCriterion(c, { caps: { browser: true }, harnessOk: true }).verdict, 'MANUAL');
});

test('evalCriterion — command kind via an injected shell', () => {
  const c = { id: 'AC-073', env: 'node', verify: { kind: 'command', cmd: 'x', expect_exit: 0 } };
  assert.equal(evalCriterion(c, { caps: {}, harnessOk: true, shell: () => ({ code: 0, out: '' }) }).verdict, 'PASS');
  assert.equal(evalCriterion(c, { caps: {}, harnessOk: true, shell: () => ({ code: 1, out: '' }) }).verdict, 'FAIL');
});

test('evalCriterion — grep kind counts matches against min_count', () => {
  const c = { id: 'AC-100', env: 'node', verify: { kind: 'grep', pattern: 'x', paths: ['a'], min_count: 5 } };
  const ctx = (out) => ({ caps: {}, harnessOk: true, shell: () => ({ code: 0, out }), resolve: (p) => p });
  assert.equal(evalCriterion(c, ctx('5\n')).verdict, 'PASS');
  assert.equal(evalCriterion(c, ctx('2\n')).verdict, 'FAIL');
});

test('evalCriterion — build-grep expects zero matching files', () => {
  const c = {
    id: 'AC-010', env: 'node',
    verify: { kind: 'build-grep', build_cmd: 'b', grep: { pattern: 'p', path: 'd', expect_count: 0 } },
  };
  const ctx = (grepOut) => ({
    caps: {}, harnessOk: true, resolve: (p) => p,
    shell: (cmd) => (cmd === 'b' ? { code: 0, out: '' } : { code: 0, out: grepOut }),
  });
  assert.equal(evalCriterion(c, ctx('0\n')).verdict, 'PASS');
  assert.equal(evalCriterion(c, ctx('2\n')).verdict, 'FAIL');
});

test('needsVitest / needsBuild honour the --only scope', () => {
  const crit = [
    { id: 'AC-001', env: 'node', verify: { kind: 'vitest-tag', tag: 'AC-001' } },
    { id: 'AC-090', env: 'node', verify: { kind: 'vitest-tag', tag: 'AC-090' } },
    { id: 'AC-073', env: 'node', verify: { kind: 'command', cmd: 'x' } },
  ];
  assert.equal(needsVitest(crit, null, {}), true);
  assert.equal(needsVitest(crit, new Set(['AC-073']), {}), false);
  assert.equal(needsBuild(crit, null), true);
  assert.equal(needsBuild(crit, new Set(['AC-001'])), false);
});

test('summarize tallies fails and harness errors', () => {
  const s = summarize({
    a: { verdict: 'PASS' },
    b: { verdict: 'FAIL' },
    c: { verdict: 'HARNESS_ERROR' },
  });
  assert.equal(s.fails, 1);
  assert.equal(s.harnessErrors, 1);
});
