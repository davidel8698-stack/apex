/** Guard: engine tests stay isolated from the vitest AC-tag scan. */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const HERE = path.dirname(fileURLToPath(import.meta.url));

test('engine tests live in convergence/lib/test/ and are .mjs', () => {
  // vitest scans only pinscope/tests/unit/**/*.test.{ts,tsx}. Engine tests are
  // .mjs files in a different directory — a double isolation that keeps their
  // titles out of ac-verify's AC-tag grep no matter what they contain.
  assert.ok(
    HERE.endsWith(path.join('convergence', 'lib', 'test')),
    `engine tests must live in convergence/lib/test/, found: ${HERE}`,
  );
  const testFiles = readdirSync(HERE).filter((f) => f.includes('.test.'));
  assert.ok(testFiles.length > 0, 'expected engine test files');
  for (const f of testFiles) {
    assert.ok(
      f.endsWith('.test.mjs'),
      `engine test "${f}" must be .mjs — vitest globs .ts/.tsx`,
    );
  }
});
