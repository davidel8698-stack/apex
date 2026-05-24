#!/usr/bin/env node
/**
 * PinScope convergence — render STATUS.md from loop.json (thin driver).
 *
 *   node render-status.mjs
 *
 * STATUS.md is GENERATED — every number computed from loop.json. The render
 * logic is the pure `renderStatus` in core/render.mjs.
 *
 * Exit: 0 ok · 1 missing file · 5 schema-invalid.
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { renderStatus } from './core/render.mjs';
import { validateLoop, validateMatrix } from './core/schema.mjs';
import { EXIT } from './core/verdict.mjs';

const LIB = path.dirname(fileURLToPath(import.meta.url));
const CONV = path.dirname(LIB);

function loadJson(name, validator) {
  const p = path.join(CONV, name);
  if (!existsSync(p)) {
    console.error(`render-status: ${name} not found`);
    process.exit(EXIT.BAD_INPUT);
  }
  let obj;
  try {
    obj = JSON.parse(readFileSync(p, 'utf8'));
  } catch (e) {
    console.error(`render-status: ${name} is not valid JSON — ${e.message}`);
    process.exit(EXIT.SCHEMA_INVALID);
  }
  const v = validator(obj);
  if (!v.ok) {
    console.error(`render-status: ${name} failed schema validation:`);
    for (const err of v.errors) console.error(`  - ${err}`);
    process.exit(EXIT.SCHEMA_INVALID);
  }
  return obj;
}

const loop = loadJson('loop.json', validateLoop);
const matrix = loadJson('ac-matrix.json', validateMatrix);
const matrixById = {};
for (const c of matrix.criteria) matrixById[c.id] = c;

writeFileSync(path.join(CONV, 'STATUS.md'), renderStatus(loop, matrixById));
console.log(
  `render-status: STATUS.md written — ${loop.metric.closed}/${loop.metric.total} CLOSED (${loop.metric.pct}%)`,
);
process.exit(EXIT.OK);
