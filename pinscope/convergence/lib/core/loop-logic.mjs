/**
 * PinScope convergence engine — loop-state transforms (pure core).
 *
 * No I/O, no process.exit, no Date.now — `now` is injected. Every function is
 * a pure transform on plain objects. Extracted from loop-state.mjs.
 */
import { VERDICT_TO_STATUS } from './verdict.mjs';

const BREAKER_ROUNDS = 3;
const BREAKER_WAVE_FAILS = 3;
// Divergence: OPEN P0/P1 findings growing by more than this between the two
// most recent recorded rounds means the loop is making things worse — it must
// halt + escalate, even when no single finding is individually stalled.
const BREAKER_DIVERGENCE_DELTA = 2;

function clone(obj) {
  return structuredClone(obj);
}

/** Recompute the convergence metric from the criteria map. */
export function recomputeMetric(criteria) {
  let closed = 0;
  let open = 0;
  let blocked = 0;
  let manualPending = 0;
  for (const c of Object.values(criteria || {})) {
    if (c.status === 'CLOSED') closed += 1;
    else if (c.status === 'OPEN') open += 1;
    else if (c.status === 'BLOCKED') blocked += 1;
    else if (c.status === 'MANUAL_PENDING') manualPending += 1;
    // BACKLOG counts toward none.
  }
  const total = Object.keys(criteria || {}).length;
  return {
    closed,
    open,
    blocked,
    manual_pending: manualPending,
    total,
    pct: total ? Math.round((closed / total) * 100) : 0,
  };
}

/** Whether a results map carries any HARNESS_ERROR verdict. */
export function hasHarnessError(results) {
  return Object.values(results || {}).some((r) => r.verdict === 'HARNESS_ERROR');
}

/** { ok, prevClosed, newClosed } — a round may never decrease `closed`. */
export function checkMonotonicity(metric, prevClosed) {
  return { ok: metric.closed >= prevClosed, prevClosed, newClosed: metric.closed };
}

/**
 * Apply an ac-results map to a loop — the pure core of `record-round`.
 * Returns { loop (new), metric, monotonic }. Never mutates the input.
 */
export function applyResults(loopIn, results, matrixById, round, now) {
  const loop = clone(loopIn);
  loop.criteria = loop.criteria || {};
  const prevClosed = loop.metric?.closed ?? 0;

  for (const [id, r] of Object.entries(results)) {
    if (r.verdict === 'HARNESS_ERROR') continue; // never recorded — rejected upstream
    const status = VERDICT_TO_STATUS[r.verdict] || 'OPEN';
    const cur = loop.criteria[id] || {};
    // An attested manual AC stays CLOSED — a later MANUAL_PENDING never regresses it.
    if (status === 'MANUAL_PENDING' && cur.status === 'CLOSED' && cur.manual_attestation) {
      cur.last_verified_round = round;
      loop.criteria[id] = cur;
      continue;
    }
    if (cur.status !== status) cur.round = round;
    cur.status = status;
    cur.last_verified_round = round;
    if (status === 'BLOCKED') {
      cur.blocked_reason = matrixById[id]?.env || 'environment';
      cur.unblocks_on =
        matrixById[id]?.env === 'apex-install' ? 'APEX-installed CI' : 'browser-capable CI';
    } else {
      delete cur.blocked_reason;
      delete cur.unblocks_on;
    }
    // Provenance ledger (D5.5): every CLOSED criterion records HOW it closed —
    // an auditable trail of round, verify method, evidence artifact, and wave.
    // A closure with no provenance is indistinguishable from a fabricated one.
    if (status === 'CLOSED') {
      cur.provenance = {
        closed_round: round,
        verify: matrixById[id]?.verify ?? null,
        evidence: r.evidence ?? null,
        wave: r.wave ?? null,
        at: now,
      };
    } else {
      delete cur.provenance;
    }
    loop.criteria[id] = cur;
  }

  loop.findings = updateFindings(loop.findings || [], results, matrixById, round);

  const metric = recomputeMetric(loop.criteria);
  loop.metric = metric;
  loop.round = round;
  // OPEN P0/P1 findings — the trajectory signal the divergence breaker reads.
  const p01Open = loop.findings.filter(
    (f) => f.status === 'OPEN' && (f.severity === 'P0' || f.severity === 'P1'),
  ).length;
  // Convergence gate (D1.2): a narrative claim with a real, un-AC'd code gap
  // (`uncovered_unsatisfied`) blocks CONVERGED exactly as an OPEN AC would.
  // The loop must never declare victory while a known real failure stands.
  const narrativeBlocks = (loop.narrative_coverage?.uncovered_unsatisfied ?? 0) > 0;
  // A genuinely-tripped breaker is preserved — only breakerAutoReset clears it.
  loop.loop_status =
    loop.loop_status === 'BREAKER_TRIPPED'
      ? 'BREAKER_TRIPPED'
      : metric.open === 0 && !narrativeBlocks
        ? 'CONVERGED'
        : 'IN_PROGRESS';

  const priorNote = (loop.metric_history || []).find((m) => m.round === round)?.note;
  loop.metric_history = (loop.metric_history || []).filter((m) => m.round !== round);
  loop.metric_history.push({
    round,
    closed: metric.closed,
    open: metric.open,
    p01_open: p01Open,
    pct: metric.pct,
    ...(priorNote ? { note: priorNote } : {}),
  });
  loop.metric_history.sort((a, b) => a.round - b.round);

  return { loop, metric, monotonic: checkMonotonicity(metric, prevClosed) };
}

/** Pure finding-ledger transform: track FAIL ACs across rounds. */
export function updateFindings(findingsIn, results, matrixById, round) {
  const findings = clone(findingsIn);
  const failing = new Set(
    Object.entries(results)
      .filter(([, r]) => r.verdict === 'FAIL')
      .map(([id]) => id),
  );
  let seq = findings.filter((f) => f.round_opened === round).length;
  for (const id of failing) {
    const open = findings.find((f) => f.ac === id && f.status === 'OPEN');
    if (open) {
      open.rounds_unchanged = (open.rounds_unchanged || 0) + 1;
      open.history = open.history || [];
      open.history.push({ round, status: 'OPEN' });
    } else {
      seq += 1;
      findings.push({
        id: `F-${round}-${String(seq).padStart(3, '0')}`,
        ac: id,
        severity: matrixById[id]?.severity || 'P2',
        round_opened: round,
        status: 'OPEN',
        rounds_unchanged: 0,
        history: [{ round, status: 'OPEN' }],
      });
    }
  }
  for (const f of findings) {
    if (f.status === 'OPEN' && !failing.has(f.ac)) {
      f.status = 'RESOLVED';
      f.rounds_unchanged = 0;
      f.history = f.history || [];
      f.history.push({ round, status: 'RESOLVED' });
    }
  }
  return findings;
}

/**
 * Merge a narrative-scan `coverage` block into the loop — the pure core of
 * `record-narrative`. The narrative deep-scan is a SECONDARY signal: this
 * function never touches `criteria`, `metric`, or `loop_status`, so AC
 * convergence is wholly unaffected. There is no monotonicity guard — coverage
 * may legitimately fall when a candidate AC is adopted (a claim moves to
 * `covered`). Returns a new loop; never mutates the input.
 */
export function applyNarrativeCoverage(loopIn, scan, round) {
  const loop = clone(loopIn);
  const cov = (scan && scan.coverage) || {};
  const num = (v) => (typeof v === 'number' ? v : 0);
  const prior = loop.narrative_coverage || {};
  const history = (prior.history || []).filter((h) => h.round !== round);
  history.push({
    round,
    covered: num(cov.covered),
    total: num(cov.total_claims),
    candidate_acs: num(cov.candidate_acs),
  });
  history.sort((a, b) => a.round - b.round);
  loop.narrative_coverage = {
    last_scanned_round: round,
    total_claims: num(cov.total_claims),
    covered: num(cov.covered),
    uncovered: num(cov.uncovered),
    candidate_acs: num(cov.candidate_acs),
    strengthen_proposals: num(cov.strengthen_proposals),
    uncovered_satisfied: num(cov.uncovered_satisfied),
    uncovered_unsatisfied: num(cov.uncovered_unsatisfied),
    history,
  };
  return loop;
}

/** Record a human/agent manual verification — the only path that closes a manual AC. */
export function attestManual(loopIn, acId, pass, note, by, round, now, matrixById) {
  const loop = clone(loopIn);
  const cur = loop.criteria?.[acId];
  if (!cur) return { ok: false, error: `${acId} not found in loop.criteria` };
  if (matrixById[acId]?.verify?.kind !== 'manual') {
    return { ok: false, error: `${acId} is not a manual-kind criterion` };
  }
  if (!['MANUAL_PENDING', 'BLOCKED', 'OPEN'].includes(cur.status)) {
    return {
      ok: false,
      error: `${acId} status is ${cur.status}; manual attestation applies to MANUAL_PENDING/BLOCKED/OPEN`,
    };
  }
  const prevClosed = loop.metric?.closed ?? 0;
  cur.manual_attestation = {
    verdict: pass ? 'pass' : 'fail',
    note,
    by: by || 'unknown',
    round,
    at: now,
  };
  if (pass) {
    cur.status = 'CLOSED';
    cur.round = round;
    cur.last_verified_round = round;
    cur.provenance = {
      closed_round: round,
      verify: matrixById[acId]?.verify ?? null,
      evidence: note ?? null,
      wave: null,
      manual: true,
      at: now,
    };
    delete cur.blocked_reason;
    delete cur.unblocks_on;
  } else {
    cur.status = 'OPEN';
    cur.round = round;
    delete cur.provenance;
  }
  loop.criteria[acId] = cur;
  const metric = recomputeMetric(loop.criteria);
  loop.metric = metric;
  if (loop.loop_status !== 'BREAKER_TRIPPED') {
    const narrativeBlocks = (loop.narrative_coverage?.uncovered_unsatisfied ?? 0) > 0;
    loop.loop_status = metric.open === 0 && !narrativeBlocks ? 'CONVERGED' : 'IN_PROGRESS';
  }
  return { ok: true, loop, metric, monotonic: checkMonotonicity(metric, prevClosed) };
}

/**
 * Trajectory analysis (D4.2) — is the loop IMPROVING, STAGNANT, or DIVERGING?
 *
 * Reads the two most recent `metric_history` rows that carry a `p01_open`
 * count. DIVERGING = OPEN P0/P1 findings grew by more than
 * `divergenceDelta` between them: the loop is actively making things worse.
 * This catches the thrash case the stall breaker misses entirely — findings
 * churning (new ones open while old ones resolve) so no single finding is
 * ever "unchanged 3 rounds", yet the failure count climbs every round.
 *
 * Returns `{ classification, diverging, delta, samples }`. With fewer than
 * two p01-bearing rows the verdict is `UNKNOWN` (never diverging) — the
 * signal needs history to exist.
 */
export function trajectoryState(loop, opts) {
  const o = { divergenceDelta: BREAKER_DIVERGENCE_DELTA, ...(opts || {}) };
  const hist = (loop.metric_history || [])
    .filter((m) => m && typeof m.p01_open === 'number')
    .slice(-2);
  if (hist.length < 2) {
    return { classification: 'UNKNOWN', diverging: false, delta: 0, samples: hist };
  }
  const [prev, cur] = hist;
  const delta = cur.p01_open - prev.p01_open;
  let classification = 'STAGNANT';
  if (delta < 0) classification = 'IMPROVING';
  else if (delta > o.divergenceDelta) classification = 'DIVERGING';
  return {
    classification,
    diverging: classification === 'DIVERGING',
    delta,
    samples: [prev, cur],
  };
}

/** Current circuit-breaker state — a function of present findings, not a latch. */
export function breakerState(loop, opts) {
  const o = { breakerRounds: BREAKER_ROUNDS, breakerWaveFails: BREAKER_WAVE_FAILS, ...(opts || {}) };
  const stalled = (loop.findings || []).filter(
    (f) => f.status === 'OPEN' && (f.rounds_unchanged || 0) >= o.breakerRounds,
  );
  const waveFails = loop.current_round?.wave_verify_fails || 0;
  const trajectory = trajectoryState(loop, opts);
  return {
    tripped: stalled.length > 0 || waveFails >= o.breakerWaveFails || trajectory.diverging,
    stalled,
    waveFails,
    diverging: trajectory.diverging,
    trajectory,
  };
}

/**
 * If the loop is BREAKER_TRIPPED but the stalling condition has cleared,
 * un-trip it. Returns { loop (new if reset), reset }.
 */
export function breakerAutoReset(loop, now, opts) {
  if (loop.loop_status !== 'BREAKER_TRIPPED') return { loop, reset: false };
  const state = breakerState(loop, opts);
  if (state.tripped) return { loop, reset: false };
  const next = clone(loop);
  next.loop_status = 'IN_PROGRESS';
  next.breaker_log = next.breaker_log || [];
  next.breaker_log.push({ round: next.round, event: 'breaker_reset', at: now });
  return { loop: next, reset: true };
}
