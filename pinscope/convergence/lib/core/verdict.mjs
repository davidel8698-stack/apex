/**
 * PinScope convergence engine — verdict / status vocabulary.
 *
 * Single source of truth, imported by ac-verify, loop-state and render.
 * Pure: no I/O, no side effects.
 */

/** Verdicts `ac-verify` can assign to a criterion. */
export const VERDICTS = ['PASS', 'FAIL', 'UNAVAILABLE', 'MANUAL', 'HARNESS_ERROR'];

/** Statuses a criterion can hold in loop.json. */
export const STATUSES = ['CLOSED', 'OPEN', 'BLOCKED', 'MANUAL_PENDING', 'BACKLOG'];

/** Valid top-level loop states. */
export const LOOP_STATUSES = ['CONVERGED', 'IN_PROGRESS', 'BREAKER_TRIPPED'];

/**
 * verdict → criterion status.
 * `HARNESS_ERROR` has NO mapping on purpose — a round carrying it is rejected
 * before any status is written (a broken verifier is not an implementation gap).
 */
export const VERDICT_TO_STATUS = {
  PASS: 'CLOSED',
  FAIL: 'OPEN',
  UNAVAILABLE: 'BLOCKED',
  MANUAL: 'MANUAL_PENDING',
};

/** Process exit codes, shared across the engine. */
export const EXIT = {
  OK: 0,
  FAIL: 1,
  BAD_INPUT: 1,
  HARNESS_ERROR: 2,
  BREAKER: 2,
  MONOTONICITY: 3,
  SPEC_DRIFT: 4,
  SCHEMA_INVALID: 5,
};
