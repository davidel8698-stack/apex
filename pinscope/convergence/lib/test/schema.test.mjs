import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateLoop, validateMatrix, validateResults } from '../core/schema.mjs';

const goodLoop = {
  round: 1,
  loop_status: 'CONVERGED',
  metric: { closed: 1, open: 0, blocked: 0, total: 1, pct: 100 },
  criteria: { 'AC-001': { status: 'CLOSED' } },
  findings: [],
  current_round: {},
};

test('validateLoop accepts a well-formed loop', () => {
  assert.equal(validateLoop(goodLoop).ok, true);
});

test('validateLoop rejects a bad criterion status, field-level message', () => {
  const bad = { ...goodLoop, criteria: { 'AC-001': { status: 'DONE' } } };
  const r = validateLoop(bad);
  assert.equal(r.ok, false);
  assert.ok(r.errors.some((e) => e.includes('AC-001') && e.includes('DONE')));
});

test('validateLoop rejects an unknown loop_status', () => {
  assert.equal(validateLoop({ ...goodLoop, loop_status: 'WAT' }).ok, false);
});

test('validateMatrix rejects an unknown verify kind', () => {
  const r = validateMatrix({ criteria: [{ id: 'AC-001', verify: { kind: 'magic' } }] });
  assert.equal(r.ok, false);
  assert.ok(r.errors.some((e) => e.includes('magic')));
});

test('validateMatrix rejects a non-AC id', () => {
  assert.equal(validateMatrix({ criteria: [{ id: 'XYZ', verify: { kind: 'manual' } }] }).ok, false);
});

test('validateResults rejects an unknown verdict', () => {
  const r = validateResults({ results: { 'AC-001': { verdict: 'MAYBE' } } });
  assert.equal(r.ok, false);
  assert.ok(r.errors.some((e) => e.includes('MAYBE')));
});

test('validateResults accepts known verdicts including HARNESS_ERROR', () => {
  const r = validateResults({
    results: { 'AC-001': { verdict: 'PASS' }, 'AC-002': { verdict: 'HARNESS_ERROR' } },
  });
  assert.equal(r.ok, true);
});

test('validateLoop accepts a well-formed narrative_coverage block', () => {
  const withNc = {
    ...goodLoop,
    narrative_coverage: { total_claims: 80, covered: 70, uncovered: 10, candidate_acs: 10 },
  };
  assert.equal(validateLoop(withNc).ok, true);
});

test('validateLoop rejects a non-numeric narrative_coverage field', () => {
  const bad = {
    ...goodLoop,
    narrative_coverage: { total_claims: 80, covered: 'lots', uncovered: 10, candidate_acs: 10 },
  };
  const r = validateLoop(bad);
  assert.equal(r.ok, false);
  assert.ok(r.errors.some((e) => e.includes('narrative_coverage.covered')));
});
