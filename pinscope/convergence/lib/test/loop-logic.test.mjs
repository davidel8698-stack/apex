import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  recomputeMetric,
  applyResults,
  applyNarrativeCoverage,
  updateFindings,
  attestManual,
  breakerState,
  breakerAutoReset,
  hasHarnessError,
  checkMonotonicity,
} from '../core/loop-logic.mjs';

function baseLoop() {
  return {
    round: 1,
    loop_status: 'IN_PROGRESS',
    metric: { closed: 1, open: 1, blocked: 0, manual_pending: 0, total: 2, pct: 50 },
    metric_history: [],
    criteria: {
      'AC-001': { status: 'CLOSED', round: 1 },
      'AC-002': { status: 'OPEN', round: 1 },
    },
    findings: [],
    current_round: { phase: 'idle' },
  };
}

test('recomputeMetric counts every status', () => {
  const m = recomputeMetric({
    a: { status: 'CLOSED' },
    b: { status: 'OPEN' },
    c: { status: 'BLOCKED' },
    d: { status: 'MANUAL_PENDING' },
  });
  assert.deepEqual(m, { closed: 1, open: 1, blocked: 1, manual_pending: 1, total: 4, pct: 25 });
});

test('applyResults closes a passing AC and converges', () => {
  const { loop, metric, monotonic } = applyResults(
    baseLoop(), { 'AC-002': { verdict: 'PASS' } }, {}, 2, 'now');
  assert.equal(loop.criteria['AC-002'].status, 'CLOSED');
  assert.equal(metric.closed, 2);
  assert.equal(monotonic.ok, true);
  assert.equal(loop.loop_status, 'CONVERGED');
});

test('applyResults flags a monotonicity violation when closed drops', () => {
  const { monotonic } = applyResults(
    baseLoop(), { 'AC-001': { verdict: 'FAIL' } }, {}, 2, 'now');
  assert.equal(monotonic.ok, false);
});

test('applyResults maps MANUAL verdict to MANUAL_PENDING', () => {
  const { loop } = applyResults(
    baseLoop(), { 'AC-002': { verdict: 'MANUAL' } }, {}, 2, 'now');
  assert.equal(loop.criteria['AC-002'].status, 'MANUAL_PENDING');
});

test('applyResults never regresses an attested manual AC', () => {
  const loop = baseLoop();
  loop.criteria['AC-002'] = { status: 'CLOSED', round: 1, manual_attestation: { verdict: 'pass' } };
  const out = applyResults(loop, { 'AC-002': { verdict: 'MANUAL' } }, {}, 2, 'now');
  assert.equal(out.loop.criteria['AC-002'].status, 'CLOSED');
});

test('applyResults never records a HARNESS_ERROR verdict', () => {
  const { loop } = applyResults(
    baseLoop(), { 'AC-002': { verdict: 'HARNESS_ERROR' } }, {}, 2, 'now');
  assert.equal(loop.criteria['AC-002'].status, 'OPEN');
});

test('applyResults preserves a tripped breaker', () => {
  const loop = baseLoop();
  loop.loop_status = 'BREAKER_TRIPPED';
  const { loop: next } = applyResults(loop, { 'AC-002': { verdict: 'PASS' } }, {}, 2, 'now');
  assert.equal(next.loop_status, 'BREAKER_TRIPPED');
});

test('hasHarnessError detects a HARNESS_ERROR verdict', () => {
  assert.equal(hasHarnessError({ a: { verdict: 'PASS' } }), false);
  assert.equal(hasHarnessError({ a: { verdict: 'HARNESS_ERROR' } }), true);
});

test('updateFindings opens, ages, then resolves a finding', () => {
  let f = updateFindings([], { 'AC-002': { verdict: 'FAIL' } }, {}, 1);
  assert.equal(f.length, 1);
  assert.equal(f[0].rounds_unchanged, 0);
  f = updateFindings(f, { 'AC-002': { verdict: 'FAIL' } }, {}, 2);
  assert.equal(f[0].rounds_unchanged, 1);
  f = updateFindings(f, { 'AC-002': { verdict: 'PASS' } }, {}, 3);
  assert.equal(f[0].status, 'RESOLVED');
});

test('breakerState trips on a finding stalled 3 rounds', () => {
  const loop = baseLoop();
  loop.findings = [{ id: 'F-1', ac: 'AC-002', status: 'OPEN', rounds_unchanged: 3 }];
  assert.equal(breakerState(loop).tripped, true);
});

test('breakerAutoReset un-trips once the stall clears', () => {
  const loop = baseLoop();
  loop.loop_status = 'BREAKER_TRIPPED';
  loop.findings = [{ id: 'F-1', ac: 'AC-002', status: 'RESOLVED', rounds_unchanged: 0 }];
  const r = breakerAutoReset(loop, 'now');
  assert.equal(r.reset, true);
  assert.equal(r.loop.loop_status, 'IN_PROGRESS');
  assert.equal(r.loop.breaker_log.length, 1);
});

test('breakerAutoReset does NOT un-trip while still stalled', () => {
  const loop = baseLoop();
  loop.loop_status = 'BREAKER_TRIPPED';
  loop.findings = [{ id: 'F-1', ac: 'AC-002', status: 'OPEN', rounds_unchanged: 4 }];
  assert.equal(breakerAutoReset(loop, 'now').reset, false);
});

test('attestManual closes a manual AC on pass', () => {
  const loop = baseLoop();
  loop.criteria['AC-002'] = { status: 'MANUAL_PENDING', round: 1 };
  const matrix = { 'AC-002': { verify: { kind: 'manual' } } };
  const r = attestManual(loop, 'AC-002', true, 'evidence', 'tester', 2, 'now', matrix);
  assert.equal(r.ok, true);
  assert.equal(r.loop.criteria['AC-002'].status, 'CLOSED');
  assert.equal(r.loop.criteria['AC-002'].manual_attestation.verdict, 'pass');
});

test('attestManual rejects a non-manual AC', () => {
  const loop = baseLoop();
  const matrix = { 'AC-001': { verify: { kind: 'vitest-tag' } } };
  assert.equal(attestManual(loop, 'AC-001', true, 'x', 'y', 2, 'now', matrix).ok, false);
});

test('checkMonotonicity', () => {
  assert.equal(checkMonotonicity({ closed: 5 }, 4).ok, true);
  assert.equal(checkMonotonicity({ closed: 3 }, 4).ok, false);
});

test('applyNarrativeCoverage merges the coverage block without touching ACs', () => {
  const before = baseLoop();
  const scan = {
    coverage: {
      total_claims: 80, covered: 70, uncovered: 10, candidate_acs: 10,
      strengthen_proposals: 3, uncovered_satisfied: 7, uncovered_unsatisfied: 3,
    },
  };
  const loop = applyNarrativeCoverage(before, scan, 5);
  assert.equal(loop.narrative_coverage.covered, 70);
  assert.equal(loop.narrative_coverage.last_scanned_round, 5);
  assert.equal(loop.narrative_coverage.history.length, 1);
  assert.equal(loop.narrative_coverage.history[0].covered, 70);
  // AC convergence state is untouched — the narrative scan is a secondary signal.
  assert.deepEqual(loop.criteria, before.criteria);
  assert.deepEqual(loop.metric, before.metric);
  assert.equal(loop.loop_status, before.loop_status);
});

test('applyNarrativeCoverage upserts the history row on a re-run round', () => {
  let loop = applyNarrativeCoverage(baseLoop(), { coverage: { total_claims: 80, covered: 70 } }, 5);
  loop = applyNarrativeCoverage(loop, { coverage: { total_claims: 80, covered: 72 } }, 5);
  assert.equal(loop.narrative_coverage.history.length, 1);
  assert.equal(loop.narrative_coverage.history[0].covered, 72);
});

test('applyNarrativeCoverage tolerates a missing coverage block', () => {
  const loop = applyNarrativeCoverage(baseLoop(), {}, 5);
  assert.equal(loop.narrative_coverage.total_claims, 0);
  assert.equal(loop.narrative_coverage.candidate_acs, 0);
});
