/**
 * PinScope convergence engine — schema validators.
 *
 * Hand-rolled, dependency-free. Each validator returns
 * `{ ok: boolean, errors: string[] }` with actionable, field-level messages.
 * Pure: no I/O.
 */
import { VERDICTS, STATUSES, LOOP_STATUSES } from './verdict.mjs';

const AC_ID = /^AC-\d{3}$/;
const VERIFY_KINDS = ['vitest-tag', 'grep', 'build-grep', 'command', 'manual'];
const ENVS = ['node', 'browser', 'apex-install'];

function isObject(v) {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

/** Validate loop.json. */
export function validateLoop(obj) {
  const e = [];
  if (!isObject(obj)) return { ok: false, errors: ['loop.json: root is not an object'] };
  if (typeof obj.round !== 'number') e.push('loop.json: `round` must be a number');
  if (!LOOP_STATUSES.includes(obj.loop_status)) {
    e.push(`loop.json: \`loop_status\` "${obj.loop_status}" not one of ${LOOP_STATUSES.join('|')}`);
  }
  if (!isObject(obj.metric)) {
    e.push('loop.json: `metric` must be an object');
  } else {
    for (const k of ['closed', 'open', 'blocked', 'total', 'pct']) {
      if (typeof obj.metric[k] !== 'number') {
        e.push(`loop.json: \`metric.${k}\` must be a number`);
      }
    }
  }
  if (!isObject(obj.criteria)) {
    e.push('loop.json: `criteria` must be an object');
  } else {
    for (const [id, c] of Object.entries(obj.criteria)) {
      if (!AC_ID.test(id)) e.push(`loop.json: criteria key "${id}" is not an AC id`);
      if (!isObject(c)) {
        e.push(`loop.json: criteria["${id}"] is not an object`);
        continue;
      }
      if (!STATUSES.includes(c.status)) {
        e.push(`loop.json: criteria["${id}"].status "${c.status}" not one of ${STATUSES.join('|')}`);
      }
    }
  }
  if (!Array.isArray(obj.findings)) e.push('loop.json: `findings` must be an array');
  if (!isObject(obj.current_round)) e.push('loop.json: `current_round` must be an object');
  // `narrative_coverage` is an optional, additive block — the narrative
  // deep-scan signal. Old loop.json files predate it and stay valid.
  if (obj.narrative_coverage !== undefined) {
    if (!isObject(obj.narrative_coverage)) {
      e.push('loop.json: `narrative_coverage` must be an object');
    } else {
      for (const k of ['total_claims', 'covered', 'uncovered', 'candidate_acs']) {
        if (typeof obj.narrative_coverage[k] !== 'number') {
          e.push(`loop.json: \`narrative_coverage.${k}\` must be a number`);
        }
      }
    }
  }
  return { ok: e.length === 0, errors: e };
}

/** Validate ac-matrix.json. */
export function validateMatrix(obj) {
  const e = [];
  if (!isObject(obj)) return { ok: false, errors: ['ac-matrix.json: root is not an object'] };
  if (!Array.isArray(obj.criteria)) {
    return { ok: false, errors: ['ac-matrix.json: `criteria` must be an array'] };
  }
  for (const c of obj.criteria) {
    if (!isObject(c)) {
      e.push('ac-matrix.json: a criterion is not an object');
      continue;
    }
    const id = c.id;
    if (!AC_ID.test(id || '')) e.push(`ac-matrix.json: criterion id "${id}" is not an AC id`);
    if (!isObject(c.verify)) {
      e.push(`ac-matrix.json: ${id}: \`verify\` must be an object`);
      continue;
    }
    if (!VERIFY_KINDS.includes(c.verify.kind)) {
      e.push(`ac-matrix.json: ${id}: verify.kind "${c.verify.kind}" not one of ${VERIFY_KINDS.join('|')}`);
    }
    if (c.env && !ENVS.includes(c.env)) {
      e.push(`ac-matrix.json: ${id}: env "${c.env}" not one of ${ENVS.join('|')}`);
    }
    if (c.verify.kind === 'vitest-tag' && !c.verify.tag) {
      e.push(`ac-matrix.json: ${id}: vitest-tag verify needs a \`tag\``);
    }
  }
  return { ok: e.length === 0, errors: e };
}

/** Validate an ac-results-R{N}.json file. */
export function validateResults(obj) {
  const e = [];
  if (!isObject(obj)) return { ok: false, errors: ['ac-results: root is not an object'] };
  if (!isObject(obj.results)) {
    return { ok: false, errors: ['ac-results: `results` must be an object'] };
  }
  for (const [id, r] of Object.entries(obj.results)) {
    if (!AC_ID.test(id)) e.push(`ac-results: result key "${id}" is not an AC id`);
    if (!isObject(r)) {
      e.push(`ac-results: results["${id}"] is not an object`);
      continue;
    }
    if (!VERDICTS.includes(r.verdict)) {
      e.push(`ac-results: results["${id}"].verdict "${r.verdict}" not one of ${VERDICTS.join('|')}`);
    }
  }
  return { ok: e.length === 0, errors: e };
}
