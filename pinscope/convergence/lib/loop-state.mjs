#!/usr/bin/env node
/**
 * PinScope convergence — loop.json reader / writer.
 *
 *   node loop-state.mjs read [field]            field: round|loop_status|phase|metric
 *   node loop-state.mjs set-phase <phase>
 *   node loop-state.mjs record-round <ac-results.json> <round>
 *   node loop-state.mjs add-finding '<json>'
 *   node loop-state.mjs breaker-check
 *
 * `loop.json` is the loop's single source of truth; `STATUS.md` is rendered
 * from it. The convergence metric is computed here, never hand-typed.
 *
 * Exit: 0 ok · 1 bad input · 2 circuit-breaker tripped · 3 monotonicity
 * violation (a round that would decrease `closed` — a regression).
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const LIB = path.dirname(fileURLToPath(import.meta.url));
const CONV = path.dirname(LIB);
const LOOP = path.join(CONV, 'loop.json');
const MATRIX = path.join(CONV, 'ac-matrix.json');

const BREAKER_ROUNDS = 3;
const BREAKER_WAVE_FAILS = 3;

function die(msg, code) {
  console.error(`loop-state: ${msg}`);
  process.exit(code ?? 1);
}

function loadLoop() {
  if (!existsSync(LOOP)) die(`loop.json not found at ${LOOP}`, 1);
  try {
    return JSON.parse(readFileSync(LOOP, 'utf8'));
  } catch (e) {
    return die(`loop.json is not valid JSON — ${e.message}`, 1);
  }
}

function saveLoop(loop) {
  writeFileSync(LOOP, `${JSON.stringify(loop, null, 2)}\n`);
}

function loadMatrix() {
  const m = JSON.parse(readFileSync(MATRIX, 'utf8'));
  const byId = {};
  for (const c of m.criteria) byId[c.id] = c;
  return byId;
}

function recomputeMetric(loop) {
  let closed = 0;
  let blocked = 0;
  let open = 0;
  for (const c of Object.values(loop.criteria)) {
    if (c.status === 'CLOSED') closed += 1;
    else if (c.status === 'BLOCKED') blocked += 1;
    else open += 1;
  }
  const total = Object.keys(loop.criteria).length;
  return { closed, blocked, open, total, pct: Math.round((closed / total) * 100) };
}

const cmd = process.argv[2];

// --- read ---
if (cmd === 'read') {
  const loop = loadLoop();
  const field = process.argv[3];
  if (!field) {
    process.stdout.write(`${JSON.stringify(loop, null, 2)}\n`);
  } else if (field === 'phase') {
    process.stdout.write(`${loop.current_round?.phase ?? 'idle'}\n`);
  } else if (field === 'metric') {
    process.stdout.write(`${JSON.stringify(loop.metric)}\n`);
  } else {
    process.stdout.write(`${loop[field] ?? ''}\n`);
  }
  process.exit(0);
}

// --- set-phase ---
if (cmd === 'set-phase') {
  const phase = process.argv[3];
  if (!phase) die('set-phase: missing <phase>', 1);
  const loop = loadLoop();
  loop.current_round = loop.current_round || {};
  loop.current_round.phase = phase;
  if (phase !== 'idle' && !loop.current_round.started_at) {
    loop.current_round.started_at = new Date().toISOString();
  }
  if (phase === 'idle') {
    loop.current_round = { phase: 'idle', started_at: null, wave_snapshot_ref: null };
  }
  saveLoop(loop);
  console.log(`loop-state: phase = ${phase}`);
  process.exit(0);
}

// --- add-finding ---
if (cmd === 'add-finding') {
  const raw = process.argv[3];
  if (!raw) die('add-finding: missing <json>', 1);
  let finding;
  try {
    finding = JSON.parse(raw);
  } catch (e) {
    die(`add-finding: bad JSON — ${e.message}`, 1);
  }
  const loop = loadLoop();
  loop.findings = loop.findings || [];
  loop.findings.push(finding);
  saveLoop(loop);
  console.log(`loop-state: finding ${finding.id || '(unnamed)'} added`);
  process.exit(0);
}

// --- record-round ---
if (cmd === 'record-round') {
  const resultsPath = process.argv[3];
  const round = Number(process.argv[4]);
  if (!resultsPath || !Number.isInteger(round)) {
    die('record-round: usage: record-round <ac-results.json> <round>', 1);
  }
  if (!existsSync(resultsPath)) die(`record-round: ${resultsPath} not found`, 1);

  const loop = loadLoop();
  const matrix = loadMatrix();
  const ac = JSON.parse(readFileSync(resultsPath, 'utf8'));
  const results = ac.results || {};
  const prevClosed = loop.metric?.closed ?? 0;

  const VERDICT_TO_STATUS = {
    PASS: 'CLOSED',
    FAIL: 'OPEN',
    UNAVAILABLE: 'BLOCKED',
    MANUAL: 'OPEN',
  };

  for (const [id, r] of Object.entries(results)) {
    const status = VERDICT_TO_STATUS[r.verdict] || 'OPEN';
    const cur = loop.criteria[id] || {};
    if (cur.status !== status) cur.round = round; // round of the status change
    cur.status = status;
    cur.last_verified_round = round;
    if (status === 'BLOCKED') {
      cur.blocked_reason = matrix[id]?.env || 'environment';
      cur.unblocks_on =
        matrix[id]?.env === 'apex-install' ? 'APEX-installed CI' : 'browser-capable CI';
    } else {
      delete cur.blocked_reason;
      delete cur.unblocks_on;
    }
    loop.criteria[id] = cur;
  }

  // --- findings: track FAIL ACs across rounds for the circuit breaker ---
  loop.findings = loop.findings || [];
  const failing = new Set(
    Object.entries(results)
      .filter(([, r]) => r.verdict === 'FAIL')
      .map(([id]) => id),
  );
  let seq = loop.findings.filter((f) => f.round_opened === round).length;
  for (const id of failing) {
    const open = loop.findings.find((f) => f.ac === id && f.status === 'OPEN');
    if (open) {
      open.rounds_unchanged = (open.rounds_unchanged || 0) + 1;
      open.history = open.history || [];
      open.history.push({ round, status: 'OPEN' });
    } else {
      seq += 1;
      loop.findings.push({
        id: `F-${round}-${String(seq).padStart(3, '0')}`,
        ac: id,
        severity: matrix[id]?.severity || 'P2',
        round_opened: round,
        status: 'OPEN',
        rounds_unchanged: 0,
        history: [{ round, status: 'OPEN' }],
      });
    }
  }
  for (const f of loop.findings) {
    if (f.status === 'OPEN' && !failing.has(f.ac)) {
      f.status = 'RESOLVED';
      f.rounds_unchanged = 0;
      f.history = f.history || [];
      f.history.push({ round, status: 'RESOLVED' });
    }
  }

  // --- metric + monotonicity guard ---
  const metric = recomputeMetric(loop);
  if (metric.closed < prevClosed) {
    console.error(
      `loop-state: MONOTONICITY VIOLATION — closed ${metric.closed} < previous ${prevClosed}. ` +
        'A round may not decrease closed ACs; this is a regression to remediate, not convergence.',
    );
    process.exit(3);
  }
  loop.metric = metric;
  loop.round = round;
  loop.loop_status = metric.open === 0 ? 'CONVERGED' : 'IN_PROGRESS';
  const priorNote = (loop.metric_history || []).find((m) => m.round === round)?.note;
  loop.metric_history = (loop.metric_history || []).filter((m) => m.round !== round);
  loop.metric_history.push({
    round,
    closed: metric.closed,
    pct: metric.pct,
    ...(priorNote ? { note: priorNote } : {}),
  });
  loop.metric_history.sort((a, b) => a.round - b.round);

  saveLoop(loop);
  console.log(
    `loop-state: round ${round} recorded — ` +
      `${metric.closed} CLOSED · ${metric.open} OPEN · ${metric.blocked} BLOCKED · ${metric.pct}%`,
  );
  process.exit(0);
}

// --- breaker-check ---
if (cmd === 'breaker-check') {
  const loop = loadLoop();
  const stalled = (loop.findings || []).filter(
    (f) => f.status === 'OPEN' && (f.rounds_unchanged || 0) >= BREAKER_ROUNDS,
  );
  const waveFails = loop.current_round?.wave_verify_fails || 0;
  if (stalled.length > 0 || waveFails >= BREAKER_WAVE_FAILS) {
    loop.loop_status = 'BREAKER_TRIPPED';
    saveLoop(loop);
    console.error('loop-state: CIRCUIT BREAKER TRIPPED');
    for (const f of stalled) {
      console.error(`  finding ${f.id} (${f.ac}) unchanged for ${f.rounds_unchanged} rounds`);
    }
    if (waveFails >= BREAKER_WAVE_FAILS) {
      console.error(`  a wave failed verification ${waveFails} times`);
    }
    process.exit(2);
  }
  console.log('loop-state: circuit breaker clear');
  process.exit(0);
}

die(`unknown command '${cmd ?? ''}' (read|set-phase|record-round|add-finding|breaker-check)`, 1);
