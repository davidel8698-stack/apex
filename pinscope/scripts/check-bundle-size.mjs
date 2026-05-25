#!/usr/bin/env node
/**
 * R-23-01 — AC-073 bundle-size assertion.
 *
 * SPEC §A.13 AC-073: "dev bundle < 80 KB minified / < 25 KB gzipped".
 *
 * Pre-R23, AC-073 verify was `expect_exit: 0` of `npm run size`. That
 * runs size-limit against a single 80 KB entry in package.json — the
 * 25 KB gzipped sub-budget was never asserted, and a misconfigured
 * `limit: '1 MB'` would silently pass. This script closes the
 * false-PASS by reading the actual built artifact, computing real raw
 * + gzip sizes, and asserting BOTH budgets.
 *
 * Usage:
 *   node scripts/check-bundle-size.mjs           — assert, exit 1 on
 *                                                   violation
 *   node scripts/check-bundle-size.mjs --print   — print current sizes
 *                                                   AND assert
 *
 * Mutation gate: artificially appending 200 KB of dummy data to the
 * built artifact MUST flip this script from exit 0 → exit 1.
 */
import { readFileSync, existsSync } from 'node:fs';
import { gzipSync } from 'node:zlib';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const MAX_MIN_KB = 80;
const MAX_GZ_KB = 25;
const TARGET_REL = 'dist/runtime/PinScope.js';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const PINSCOPE_ROOT = path.dirname(SCRIPT_DIR);
const target = path.join(PINSCOPE_ROOT, TARGET_REL);

if (!existsSync(target)) {
  console.error(
    `check-bundle-size: target missing — ${TARGET_REL}\n` +
      `  run \`npm run build\` first.`,
  );
  process.exit(1);
}

const printMode = process.argv.includes('--print');

const raw = readFileSync(target);
const rawKB = raw.byteLength / 1024;
const gzKB = gzipSync(raw).byteLength / 1024;

if (printMode) {
  console.log(`check-bundle-size — ${TARGET_REL}`);
  console.log(
    `  raw:  ${rawKB.toFixed(2)} KB  (budget ${MAX_MIN_KB} KB)  ${rawKB <= MAX_MIN_KB ? '✓' : '✗'}`,
  );
  console.log(
    `  gzip: ${gzKB.toFixed(2)} KB  (budget ${MAX_GZ_KB} KB)  ${gzKB <= MAX_GZ_KB ? '✓' : '✗'}`,
  );
}

if (rawKB > MAX_MIN_KB) {
  console.error(
    `check-bundle-size: FAIL — raw bundle ${rawKB.toFixed(2)} KB exceeds ${MAX_MIN_KB} KB budget.`,
  );
  process.exit(1);
}
if (gzKB > MAX_GZ_KB) {
  console.error(
    `check-bundle-size: FAIL — gzipped bundle ${gzKB.toFixed(2)} KB exceeds ${MAX_GZ_KB} KB budget.`,
  );
  process.exit(1);
}

if (!printMode) {
  console.log(
    `check-bundle-size: OK — raw ${rawKB.toFixed(2)} KB / gzip ${gzKB.toFixed(2)} KB (under ${MAX_MIN_KB} KB / ${MAX_GZ_KB} KB).`,
  );
}
process.exit(0);
