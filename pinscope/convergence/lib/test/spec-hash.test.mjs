import { test } from 'node:test';
import assert from 'node:assert/strict';
import { hashText, checkSpecDrift } from '../core/spec-hash.mjs';

test('hashText is deterministic and sha256-prefixed', () => {
  assert.equal(hashText('hello'), hashText('hello'));
  assert.match(hashText('hello'), /^sha256:[0-9a-f]{64}$/);
  assert.notEqual(hashText('a'), hashText('b'));
});

test('checkSpecDrift — no drift when the hash matches', () => {
  const text = 'SPEC content';
  const r = checkSpecDrift(text, { generated_from_hash: hashText(text) });
  assert.equal(r.drift, false);
  assert.equal(r.firstRun, false);
});

test('checkSpecDrift — drift when the SPEC changed', () => {
  const r = checkSpecDrift('new spec', { generated_from_hash: hashText('old spec') });
  assert.equal(r.drift, true);
});

test('checkSpecDrift — firstRun when no hash is recorded', () => {
  const r = checkSpecDrift('spec', {});
  assert.equal(r.firstRun, true);
  assert.equal(r.drift, false);
});
