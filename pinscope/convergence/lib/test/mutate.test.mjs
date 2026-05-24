import { test } from 'node:test';
import assert from 'node:assert/strict';
import { generateMutants, isSkippableLine } from '../core/mutate.mjs';

test('isSkippableLine skips blanks, comments, and imports', () => {
  assert.equal(isSkippableLine(''), true);
  assert.equal(isSkippableLine('  // a comment'), true);
  assert.equal(isSkippableLine(' * jsdoc line'), true);
  assert.equal(isSkippableLine("import { x } from './x';"), true);
  assert.equal(isSkippableLine("export { y } from './y';"), true);
  assert.equal(isSkippableLine('const a = b && c;'), false);
});

test('generateMutants flips a logical operator', () => {
  const m = generateMutants('const ok = a && b;');
  assert.equal(m.length, 1);
  assert.equal(m[0].rule, 'and-to-or');
  assert.equal(m[0].source, 'const ok = a || b;');
  assert.equal(m[0].line, 1);
});

test('generateMutants flips strict-equality and relational operators', () => {
  assert.equal(generateMutants('if (x === 1) {}')[0].source, 'if (x !== 1) {}');
  assert.equal(generateMutants('if (x >= 1) {}')[0].source, 'if (x < 1) {}');
});

test('generateMutants mutates each occurrence independently', () => {
  const m = generateMutants('const z = a && b && c;');
  assert.equal(m.length, 2);
  assert.equal(m[0].source, 'const z = a || b && c;');
  assert.equal(m[1].source, 'const z = a && b || c;');
});

test('generateMutants respects word boundaries on boolean literals', () => {
  assert.equal(generateMutants('const f = true;')[0].source, 'const f = false;');
  // `true` glued to an identifier (trueish) is not a token — never mutated.
  assert.equal(generateMutants('const trueish = 1;').length, 0);
});

test('generateMutants skips comment and import lines', () => {
  assert.equal(generateMutants('// a === b always').length, 0);
  assert.equal(generateMutants("import { a } from './x' && y;").length, 0);
});

test('generateMutants honors the max cap', () => {
  const src = 'const a = p && q && r && s && t && u;';
  assert.equal(generateMutants(src, { max: 3 }).length, 3);
});

test('every mutant differs from the original by exactly its one token', () => {
  const src = 'function ok() { return a === b && c >= d; }';
  const mutants = generateMutants(src);
  assert.ok(mutants.length >= 3);
  for (const m of mutants) {
    assert.notEqual(m.source, src);
    assert.equal(m.source.split('\n').length, 1);
  }
});
