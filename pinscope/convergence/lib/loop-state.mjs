#!/usr/bin/env node
/**
 * PinScope convergence — loop.json reader / writer (thin driver).
 *
 *   node loop-state.mjs read [field]            field: round|loop_status|phase|metric
 *   node loop-state.mjs set-phase <phase>
 *   node loop-state.mjs record-round <ac-results.json> <round>
 *   node loop-state.mjs record-narrative <narrative-scan.json> <round>
 *   node loop-state.mjs add-finding '<json>'
 *   node loop-state.mjs breaker-check
 *   node loop-state.mjs log-event <event> [note]
 *   node loop-state.mjs manual-attest <AC-id> <pass|fail> "<evidence>" [--by <name>]
 *
 * Pure transforms live in core/loop-logic.mjs; this driver only does I/O,
 * schema validation, and exit codes. loop.json is written atomically
 * (temp + rename) so a crash mid-write can never corrupt loop state.
 *
 * Exit: 0 ok · 1 bad input · 2 breaker tripped / harness-error round refused ·
 *       3 monotonicity violation · 5 schema-invalid.
 */
import { readFileSync, writeFileSync, existsSync, renameSync, appendFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { EXIT } from './core/verdict.mjs';
import { validateLoop, validateMatrix, validateResults } from './core/schema.mjs';
import {
  applyResults,
  applyNarrativeCoverage,
  breakerState,
  breakerAutoReset,
  hasHarnessError,
  attestManual,
} from './core/loop-logic.mjs';

const LIB = path.dirname(fileURLToPath(import.meta.url));
const CONV = path.dirname(LIB);
const LOOP = path.join(CONV, 'loop.json');
const MATRIX = path.join(CONV, 'ac-matrix.json');

function die(msg, code) {
  console.error(`loop-state: ${msg}`);
  process.exit(code ?? EXIT.BAD_INPUT);
}

function loadValidated(file, name, validator) {
  if (!existsSync(file)) die(`${name} not found at ${file}`, EXIT.BAD_INPUT);
  let obj;
  try {
    obj = JSON.parse(readFileSync(file, 'utf8'));
  } catch (e) {
    die(`${name} is not valid JSON — ${e.message}`, EXIT.SCHEMA_INVALID);
  }
  const v = validator(obj);
  if (!v.ok) {
    console.error(`loop-state: ${name} failed schema validation:`);
    for (const err of v.errors) console.error(`  - ${err}`);
    process.exit(EXIT.SCHEMA_INVALID);
  }
  return obj;
}

const LOOP_TMP = `${LOOP}.tmp`;
const EVENTS = path.join(CONV, 'loop-events.jsonl');

const loadLoop = () => loadValidated(LOOP, 'loop.json', validateLoop);

// Atomic write — a crash mid-write must never leave loop.json half-written.
function saveLoop(loop) {
  writeFileSync(LOOP_TMP, `${JSON.stringify(loop, null, 2)}\n`);
  renameSync(LOOP_TMP, LOOP);
}

// Append-only round event log (D4.5) — every phase transition and orchestrator
// event, one JSON object per line, for full round auditability.
function logEvent(round, event, note) {
  appendFileSync(
    EVENTS,
    `${JSON.stringify({ at: now(), round: round ?? null, event, note: note ?? null })}\n`,
  );
}
function loadMatrixById() {
  const m = loadValidated(MATRIX, 'ac-matrix.json', validateMatrix);
  const byId = {};
  for (const c of m.criteria) byId[c.id] = c;
  return byId;
}

const now = () => new Date().toISOString();
const cmd = process.argv[2];

if (cmd === 'read') {
  const loop = loadLoop();
  const field = process.argv[3];
  if (!field) process.stdout.write(`${JSON.stringify(loop, null, 2)}\n`);
  else if (field === 'phase') process.stdout.write(`${loop.current_round?.phase ?? 'idle'}\n`);
  else if (field === 'metric') process.stdout.write(`${JSON.stringify(loop.metric)}\n`);
  else process.stdout.write(`${loop[field] ?? ''}\n`);
  process.exit(EXIT.OK);
}

if (cmd === 'set-phase') {
  const phase = process.argv[3];
  if (!phase) die('set-phase: missing <phase>');
  const loop = loadLoop();
  if (phase === 'idle') {
    loop.current_round = { phase: 'idle', started_at: null, wave_snapshot_ref: null };
  } else {
    loop.current_round = loop.current_round || {};
    loop.current_round.phase = phase;
    if (!loop.current_round.started_at) loop.current_round.started_at = now();
  }
  saveLoop(loop);
  logEvent(loop.round, `phase:${phase}`);
  console.log(`loop-state: phase = ${phase}`);
  process.exit(EXIT.OK);
}

if (cmd === 'log-event') {
  const event = process.argv[3];
  if (!event) die('log-event: usage: log-event <event> [note]');
  const note = process.argv[4];
  const loop = loadLoop();
  logEvent(loop.round, event, note);
  console.log(`loop-state: event '${event}' logged`);
  process.exit(EXIT.OK);
}

if (cmd === 'add-finding') {
  const raw = process.argv[3];
  if (!raw) die('add-finding: missing <json>');
  let finding;
  try {
    finding = JSON.parse(raw);
  } catch (e) {
    die(`add-finding: bad JSON — ${e.message}`);
  }
  const loop = loadLoop();
  loop.findings = loop.findings || [];
  loop.findings.push(finding);
  saveLoop(loop);
  console.log(`loop-state: finding ${finding.id || '(unnamed)'} added`);
  process.exit(EXIT.OK);
}

if (cmd === 'record-round') {
  const resultsPath = process.argv[3];
  const round = Number(process.argv[4]);
  if (!resultsPath || !Number.isInteger(round)) {
    die('record-round: usage: record-round <ac-results.json> <round>');
  }
  const ac = loadValidated(path.resolve(resultsPath), 'ac-results', validateResults);
  if (ac.harness_ok === false || hasHarnessError(ac.results)) {
    die(
      `REFUSING to record round ${round} — ac-results carries HARNESS_ERROR. ` +
        'The verifier engine failed; this is not an implementation gap. ' +
        'Fix the harness and re-run ac-verify.',
      EXIT.HARNESS_ERROR,
    );
  }
  let loop = loadLoop();
  const matrixById = loadMatrixById();
  const reset = breakerAutoReset(loop, now());
  loop = reset.loop;
  if (reset.reset) console.log('loop-state: circuit breaker auto-reset — stalling condition cleared');
  const { loop: next, metric, monotonic } = applyResults(loop, ac.results, matrixById, round, now());
  if (!monotonic.ok) {
    console.error(
      `loop-state: MONOTONICITY VIOLATION — closed ${monotonic.newClosed} < previous ` +
        `${monotonic.prevClosed}. A round may not decrease closed ACs; remediate the ` +
        'regression, do not commit it as convergence.',
    );
    process.exit(EXIT.MONOTONICITY);
  }
  saveLoop(next);
  console.log(
    `loop-state: round ${round} recorded — ${metric.closed} CLOSED · ${metric.open} OPEN · ` +
      `${metric.blocked} BLOCKED` +
      (metric.manual_pending ? ` · ${metric.manual_pending} MANUAL_PENDING` : '') +
      ` · ${metric.pct}%`,
  );
  process.exit(EXIT.OK);
}

if (cmd === 'record-narrative') {
  const scanPath = process.argv[3];
  const round = Number(process.argv[4]);
  if (!scanPath || !Number.isInteger(round)) {
    die('record-narrative: usage: record-narrative <narrative-scan.json> <round>');
  }
  const resolved = path.resolve(scanPath);
  if (!existsSync(resolved)) die(`record-narrative: scan file not found at ${resolved}`);
  let scan;
  try {
    scan = JSON.parse(readFileSync(resolved, 'utf8'));
  } catch (e) {
    die(`record-narrative: scan file is not valid JSON — ${e.message}`, EXIT.SCHEMA_INVALID);
  }
  if (typeof scan !== 'object' || scan === null || typeof scan.coverage !== 'object' || scan.coverage === null) {
    die('record-narrative: scan file has no `coverage` object', EXIT.SCHEMA_INVALID);
  }
  const loop = loadLoop();
  const next = applyNarrativeCoverage(loop, scan, round);
  saveLoop(next);
  const nc = next.narrative_coverage;
  console.log(
    `loop-state: narrative coverage recorded — round ${round}: ${nc.covered}/${nc.total_claims} ` +
      `claims AC-covered · ${nc.candidate_acs} candidate ACs · ${nc.strengthen_proposals} strengthen proposals`,
  );
  process.exit(EXIT.OK);
}

if (cmd === 'breaker-check') {
  const loop = loadLoop();
  const reset = breakerAutoReset(loop, now());
  if (reset.reset) {
    saveLoop(reset.loop);
    console.log('loop-state: circuit breaker auto-reset — stalling condition cleared');
    process.exit(EXIT.OK);
  }
  const state = breakerState(loop);
  if (state.tripped) {
    const wasTripped = loop.loop_status === 'BREAKER_TRIPPED';
    loop.loop_status = 'BREAKER_TRIPPED';
    const reasons = [];
    if (state.stalled.length > 0) reasons.push('stalled-finding');
    if (state.waveFails >= 3) reasons.push('wave-fails');
    if (state.diverging) reasons.push('diverging');
    const reason = reasons.join('+');
    if (!wasTripped) {
      loop.breaker_log = loop.breaker_log || [];
      loop.breaker_log.push({ round: loop.round, event: 'breaker_tripped', reason, at: now() });
    }
    saveLoop(loop);
    logEvent(loop.round, 'breaker_tripped', reason);
    console.error('loop-state: CIRCUIT BREAKER TRIPPED');
    for (const f of state.stalled) {
      console.error(`  finding ${f.id} (${f.ac}) unchanged for ${f.rounds_unchanged} rounds`);
    }
    if (state.waveFails >= 3) console.error(`  a wave failed verification ${state.waveFails} times`);
    if (state.diverging) {
      const t = state.trajectory;
      console.error(
        `  trajectory DIVERGING — OPEN P0/P1 findings grew by ${t.delta} between rounds ` +
          `${t.samples[0].round} and ${t.samples[1].round}. The loop is making things ` +
          'worse round over round; halt and escalate to a human.',
      );
    }
    process.exit(EXIT.BREAKER);
  }
  console.log('loop-state: circuit breaker clear');
  process.exit(EXIT.OK);
}

if (cmd === 'manual-attest') {
  const acId = process.argv[3];
  const verdict = process.argv[4];
  const note = process.argv[5];
  const byIdx = process.argv.indexOf('--by');
  const by = byIdx >= 0 ? process.argv[byIdx + 1] : 'unknown';
  if (!acId || !['pass', 'fail'].includes(verdict) || !note) {
    die('manual-attest: usage: manual-attest <AC-id> <pass|fail> "<evidence>" [--by <name>]');
  }
  const loop = loadLoop();
  const matrixById = loadMatrixById();
  const res = attestManual(loop, acId, verdict === 'pass', note, by, loop.round, now(), matrixById);
  if (!res.ok) die(`manual-attest: ${res.error}`);
  if (!res.monotonic.ok) {
    die('MONOTONICITY VIOLATION on manual-attest', EXIT.MONOTONICITY);
  }
  saveLoop(res.loop);
  console.log(
    `loop-state: ${acId} manual attestation '${verdict}' recorded — status ` +
      `${res.loop.criteria[acId].status}`,
  );
  process.exit(EXIT.OK);
}

die(
  `unknown command '${cmd ?? ''}' ` +
    '(read|set-phase|record-round|record-narrative|add-finding|breaker-check|' +
    'log-event|manual-attest)',
);
