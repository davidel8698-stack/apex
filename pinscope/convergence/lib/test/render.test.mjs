import { test } from 'node:test';
import assert from 'node:assert/strict';
import { renderStatus } from '../core/render.mjs';

const loop = {
  north_star: 'pinscope/SPEC.md',
  north_star_version: '2.0.0',
  round: 9,
  loop_status: 'CONVERGED',
  metric: { closed: 2, open: 0, blocked: 1, manual_pending: 0, total: 3, pct: 67 },
  metric_history: [{ round: 9, closed: 2, pct: 67, note: 'final' }],
  criteria: {
    'AC-001': { status: 'CLOSED', round: 1 },
    'AC-002': { status: 'CLOSED', round: 2 },
    'AC-003': { status: 'BLOCKED', round: 3, blocked_reason: 'browser', unblocks_on: 'browser-capable CI' },
  },
  findings: [],
  breaker_log: [],
};
const matrix = {
  'AC-001': { phase: 'P1', severity: 'P0' },
  'AC-002': { phase: 'P1', severity: 'P1' },
  'AC-003': { phase: 'P2', severity: 'P2' },
};

test('renderStatus emits the header, ledger and totals', () => {
  const md = renderStatus(loop, matrix);
  assert.match(md, /# PinScope Convergence — STATUS/);
  assert.match(md, /AC-001/);
  assert.match(md, /Total: 3 ACs · 2 CLOSED · 0 OPEN · 1 BLOCKED/);
  assert.match(md, /67% converged/);
});

test('renderStatus lists the BLOCKED criteria with reasons', () => {
  const md = renderStatus(loop, matrix);
  assert.match(md, /## The 1 BLOCKED criteria/);
  assert.match(md, /AC-003.*browser/);
});

test('renderStatus shows TRIPPED when the breaker is tripped', () => {
  const md = renderStatus({ ...loop, loop_status: 'BREAKER_TRIPPED' }, matrix);
  assert.match(md, /TRIPPED/);
});

test('renderStatus surfaces MANUAL_PENDING in the total line', () => {
  const withManual = {
    ...loop,
    metric: { closed: 2, open: 0, blocked: 0, manual_pending: 1, total: 3, pct: 67 },
    criteria: { ...loop.criteria, 'AC-003': { status: 'MANUAL_PENDING', round: 3 } },
  };
  assert.match(renderStatus(withManual, matrix), /1 MANUAL_PENDING/);
});

test('renderStatus emits the Narrative coverage section when present', () => {
  const withNc = {
    ...loop,
    narrative_coverage: {
      last_scanned_round: 9, total_claims: 84, covered: 71, uncovered: 13,
      candidate_acs: 13, strengthen_proposals: 4, uncovered_satisfied: 9, uncovered_unsatisfied: 4,
    },
  };
  const md = renderStatus(withNc, matrix);
  assert.match(md, /## Narrative coverage/);
  assert.match(md, /71\/84/);
  assert.match(md, /uncovered claim\(s\) the code does NOT/);
});

test('renderStatus omits Narrative coverage when the block is absent', () => {
  assert.doesNotMatch(renderStatus(loop, matrix), /## Narrative coverage/);
});
