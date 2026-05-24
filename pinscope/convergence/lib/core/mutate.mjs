/**
 * PinScope convergence engine — source mutation generator (pure core).
 *
 * A lightweight, dependency-free mutation-testing aid. It applies a small
 * catalog of high-signal operator/literal mutations to source text, one
 * occurrence at a time, and yields the mutated source for each. A mutant that
 * SURVIVES the test suite (every test still passes against deliberately-broken
 * code) flags a probably-hollow test — the closure that test backs is not
 * actually pinned.
 *
 * This is a SIGNAL, not a full mutation-score tool. It is deliberately
 * conservative: it skips comment / import / export-from lines, and the driver
 * counts a mutant that fails to run at all as KILLED, never as survived — so
 * the failure mode is "flag a test for review", never "miss a hollow test
 * silently". No I/O here; the driver (`mutation-check.mjs`) does the runs.
 */

// Each rule rewrites one token to a behaviorally-different token. Equality and
// relational flips change branch outcomes; boolean-literal flips invert
// guards. All are syntactically safe one-for-one substitutions.
const RULES = [
  { name: 'and-to-or', find: '&&', into: '||' },
  { name: 'or-to-and', find: '||', into: '&&' },
  { name: 'strict-eq-to-ne', find: '===', into: '!==' },
  { name: 'strict-ne-to-eq', find: '!==', into: '===' },
  { name: 'gte-to-lt', find: '>=', into: '<' },
  { name: 'lte-to-gt', find: '<=', into: '>' },
  { name: 'true-to-false', find: 'true', into: 'false', word: true },
  { name: 'false-to-true', find: 'false', into: 'true', word: true },
];

const isWordChar = (ch) => !!ch && /[A-Za-z0-9_$]/.test(ch);

/** A line we never mutate — no behavior to break, or too risky to text-edit. */
export function isSkippableLine(line) {
  const t = line.trim();
  if (t === '') return true;
  if (t.startsWith('//') || t.startsWith('*') || t.startsWith('/*')) return true;
  if (t.startsWith('import ')) return true;
  if (t.startsWith('export ') && t.includes(' from ')) return true;
  return false;
}

/** Index of the next occurrence of `rule.find` in `line` at or after `from`. */
function nextToken(line, rule, from) {
  let idx = line.indexOf(rule.find, from);
  if (!rule.word) return idx;
  // Word-boundary rules (true/false): reject a match glued to an identifier.
  while (idx >= 0) {
    const before = line[idx - 1];
    const after = line[idx + rule.find.length];
    if (!isWordChar(before) && !isWordChar(after)) return idx;
    idx = line.indexOf(rule.find, idx + 1);
  }
  return -1;
}

/**
 * Generate mutants for one source file's text. Each mutant changes exactly one
 * token occurrence. Returns `[{ id, rule, line, original, mutated, source }]`,
 * capped at `opts.max` (default 8) to bound the driver's test-run count.
 */
export function generateMutants(source, opts = {}) {
  const max = opts.max ?? 8;
  const lines = source.split('\n');
  const mutants = [];
  for (let i = 0; i < lines.length && mutants.length < max; i += 1) {
    const line = lines[i];
    if (isSkippableLine(line)) continue;
    for (const rule of RULES) {
      let from = 0;
      while (mutants.length < max) {
        const idx = nextToken(line, rule, from);
        if (idx < 0) break;
        const mutatedLine =
          line.slice(0, idx) + rule.into + line.slice(idx + rule.find.length);
        const mLines = lines.slice();
        mLines[i] = mutatedLine;
        mutants.push({
          id: `M${mutants.length + 1}`,
          rule: rule.name,
          line: i + 1,
          original: line.trim(),
          mutated: mutatedLine.trim(),
          source: mLines.join('\n'),
        });
        from = idx + rule.find.length;
      }
      if (mutants.length >= max) break;
    }
  }
  return mutants;
}
