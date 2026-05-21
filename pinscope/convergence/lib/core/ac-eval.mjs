/**
 * PinScope convergence engine — verification-matrix evaluation (pure core).
 *
 * No I/O: every shell-out is an injected callback. Extracted from ac-verify.mjs
 * so the matrix logic is unit-testable.
 */

/** Parse a vitest JSON report into a tag → {passed,failed} map. */
export function parseVitestReport(jsonText) {
  let data;
  try {
    data = JSON.parse(jsonText);
  } catch (err) {
    return { ok: false, tags: {}, error: `vitest report is not valid JSON: ${err.message}` };
  }
  if (!data || !Array.isArray(data.testResults)) {
    return { ok: false, tags: {}, error: 'vitest report has no testResults array' };
  }
  const tags = {};
  for (const file of data.testResults) {
    for (const a of file.assertionResults || []) {
      const full = [...(a.ancestorTitles || []), a.title || ''].join(' ');
      for (const tag of full.match(/AC-\d{3}/g) || []) {
        tags[tag] = tags[tag] || { passed: 0, failed: 0 };
        if (a.status === 'passed') tags[tag].passed += 1;
        else tags[tag].failed += 1;
      }
    }
  }
  return { ok: true, tags, error: null };
}

/** Parse a Playwright JSON report into a tag → {passed,failed} map. */
export function parsePlaywrightReport(jsonText) {
  let data;
  try {
    data = JSON.parse(jsonText);
  } catch (err) {
    return { ok: false, tags: {}, error: `playwright report is not valid JSON: ${err.message}` };
  }
  if (!data || !Array.isArray(data.suites)) {
    return { ok: false, tags: {}, error: 'playwright report has no suites array' };
  }
  const tags = {};
  const walk = (suite) => {
    for (const spec of suite.specs || []) {
      const ok = (spec.tests || []).every((t) =>
        (t.results || []).every((res) => ['passed', 'expected'].includes(res.status)),
      );
      for (const tag of (spec.title || '').match(/AC-\d{3}/g) || []) {
        tags[tag] = tags[tag] || { passed: 0, failed: 0 };
        if (ok) tags[tag].passed += 1;
        else tags[tag].failed += 1;
      }
    }
    for (const s of suite.suites || []) walk(s);
  };
  for (const s of data.suites) walk(s);
  return { ok: true, tags, error: null };
}

/** Merge two tag maps. */
export function mergeTagMaps(a, b) {
  const out = {};
  for (const src of [a, b]) {
    for (const [tag, s] of Object.entries(src || {})) {
      out[tag] = out[tag] || { passed: 0, failed: 0 };
      out[tag].passed += s.passed || 0;
      out[tag].failed += s.failed || 0;
    }
  }
  return out;
}

/** Whether an AC's required environment is available. */
export function envAvailable(env, caps) {
  if (env === 'node') return true;
  if (env === 'browser') return Boolean(caps && caps.browser === true);
  if (env === 'apex-install') return Boolean(caps && caps.apex_install === true);
  return false;
}

/** Is any in-scope criterion a vitest-tag check whose env is available? */
export function needsVitest(criteria, onlySet, caps) {
  return criteria.some(
    (c) =>
      (!onlySet || onlySet.has(c.id)) &&
      c.verify.kind === 'vitest-tag' &&
      envAvailable(c.env, caps),
  );
}

/** vitest-tag ACs whose tests import the built dist/ tree. */
const DIST_DEPENDENT_TAGS = new Set(['AC-090', 'AC-092']);

/** Does the pinscope `npm run build` need to run before the vitest suite? */
export function needsBuild(criteria, onlySet) {
  return criteria.some(
    (c) =>
      (!onlySet || onlySet.has(c.id)) &&
      c.verify.kind === 'vitest-tag' &&
      DIST_DEPENDENT_TAGS.has(c.verify.tag),
  );
}

/**
 * Evaluate one criterion.
 * ctx = { tags, caps, harnessOk, shell(cmd,cwd?)->{code,out}, resolve(path)->abs }
 */
export function evalCriterion(criterion, ctx) {
  const v = criterion.verify;
  const available = envAvailable(criterion.env, ctx.caps);

  if (v.kind === 'manual') {
    return available
      ? { verdict: 'MANUAL', detail: v.note || 'manual verification required' }
      : { verdict: 'UNAVAILABLE', detail: `env '${criterion.env}' unavailable` };
  }
  if (!available) {
    return { verdict: 'UNAVAILABLE', detail: `env '${criterion.env}' unavailable` };
  }

  if (v.kind === 'vitest-tag') {
    if (ctx.harnessOk === false) {
      return {
        verdict: 'HARNESS_ERROR',
        detail: 'test harness produced no parseable results — not an implementation gap',
      };
    }
    const t = ctx.tags[v.tag] || { passed: 0, failed: 0 };
    const total = t.passed + t.failed;
    const min = v.min_tests || 1;
    if (total === 0) return { verdict: 'FAIL', detail: `no tests tagged ${v.tag}` };
    if (t.failed > 0) {
      return { verdict: 'FAIL', detail: `${t.failed}/${total} ${v.tag} tests failed` };
    }
    if (t.passed < min) {
      return { verdict: 'FAIL', detail: `${t.passed} ${v.tag} tests < min ${min}` };
    }
    return { verdict: 'PASS', detail: `${t.passed} ${v.tag} tests pass` };
  }

  if (v.kind === 'command') {
    const r = ctx.shell(v.cmd);
    const want = v.expect_exit ?? 0;
    return r.code === want
      ? { verdict: 'PASS', detail: `exit ${r.code}` }
      : { verdict: 'FAIL', detail: `exit ${r.code}, expected ${want}` };
  }

  if (v.kind === 'grep') {
    let count = 0;
    for (const p of v.paths || []) {
      const r = ctx.shell(
        `grep -E -c ${JSON.stringify(v.pattern)} ${JSON.stringify(ctx.resolve(p))}`,
      );
      count += parseInt((r.out || '').trim() || '0', 10) || 0;
    }
    if (v.expect_count !== undefined) {
      return count === v.expect_count
        ? { verdict: 'PASS', detail: `${count} matches` }
        : { verdict: 'FAIL', detail: `${count} matches, expected ${v.expect_count}` };
    }
    const min = v.min_count ?? 1;
    return count >= min
      ? { verdict: 'PASS', detail: `${count} matches >= ${min}` }
      : { verdict: 'FAIL', detail: `${count} matches < ${min}` };
  }

  if (v.kind === 'build-grep') {
    const b = ctx.shell(v.build_cmd, v.build_cwd);
    if (b.code !== 0) return { verdict: 'FAIL', detail: `build failed (exit ${b.code})` };
    const g = v.grep;
    const r = ctx.shell(
      `grep -rlE ${JSON.stringify(g.pattern)} ${JSON.stringify(ctx.resolve(g.path))} 2>/dev/null | wc -l`,
    );
    const count = parseInt((r.out || '').trim() || '0', 10) || 0;
    const want = g.expect_count ?? 0;
    return count === want
      ? { verdict: 'PASS', detail: `${count} files match` }
      : { verdict: 'FAIL', detail: `${count} files match, expected ${want}` };
  }

  return { verdict: 'FAIL', detail: `unknown verify kind '${v.kind}'` };
}

/** Tally a results map. */
export function summarize(results) {
  const counts = {};
  let fails = 0;
  let harnessErrors = 0;
  for (const r of Object.values(results)) {
    counts[r.verdict] = (counts[r.verdict] || 0) + 1;
    if (r.verdict === 'FAIL') fails += 1;
    if (r.verdict === 'HARNESS_ERROR') harnessErrors += 1;
  }
  return { counts, fails, harnessErrors };
}
