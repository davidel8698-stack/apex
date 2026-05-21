/**
 * PinScope convergence engine — North-Star spec hashing (drift detection).
 *
 * Pure: `node:crypto` is deterministic; no fs, no side effects.
 */
import { createHash } from 'node:crypto';

/** Deterministic content hash of a text blob, prefixed `sha256:`. */
export function hashText(text) {
  return `sha256:${createHash('sha256').update(String(text), 'utf8').digest('hex')}`;
}

/**
 * Compare the live SPEC text against the hash recorded in ac-matrix.json.
 *
 * @returns {{ drift: boolean, firstRun: boolean, current: string, recorded: string|null }}
 *   `drift`    — a hash was recorded and it no longer matches.
 *   `firstRun` — no hash was recorded yet (matrix predates drift detection).
 */
export function checkSpecDrift(specText, matrix) {
  const current = hashText(specText);
  const recorded = matrix && typeof matrix.generated_from_hash === 'string'
    ? matrix.generated_from_hash
    : null;
  return {
    drift: recorded !== null && recorded !== current,
    firstRun: recorded === null,
    current,
    recorded,
  };
}
