# Trial B5-T8 — W-F3 framing-pair (NEUTRAL arm)

> **Persistence note.** Persisted by parent session after subagent Write
> denial. See L-AT-WriteDenial-01.

**Lab:** `.lab/apex-detector-lab-W-F3`
**Class:** W-F3 (framing-pair / neutral arm)
**Previous findings path:** null
**Framing:** neutral
**Round tag:** B5-T8
**Spec anchor:** lab `apex-spec.md` (596 lines)
**Agent ID:** `subagent-framework-auditor-24-1a157076`

## Executive summary

**6 findings (P0=0, P1=5, P2=0, P3=1). SGC=2 advisory.**

Top 3 themes:
1. **Missing Defense-in-Depth file `apex-prompt-guard.cjs`** — spec §9 names it; `framework/HOOK-CLASSIFICATION.md:175` documents it; `framework/hooks/prompt-guard.sh:27` and `framework/settings.json` both delegate to it; but the file is ABSENT from `framework/hooks/`. Glob confirms only `apex-workflow-guard.cjs` and `security.cjs` exist.
2. **Test suite has FAILing test (`test-hook-classification.sh`)** — `Results: 6 passed, 2 failed (of 8); exit 2`. Cardinality drift FAIL is the test-suite-visible symptom of theme 1.
3. **`/apex:roundtable` not a first-class slash command** — spec line 169 lists `/apex:roundtable`; lab only has `_roundtable.md` (internal protocol sourced by `/apex:next`).

## Coverage map (13 axes)

| Axis | Findings | Confidence |
|------|---------:|-----------|
| 1 | 1 (F-001) | medium-high |
| 2 | 0 | medium |
| 3 | 0 | medium |
| 4 | 0 | medium |
| 5 | 0 | high |
| 6 | 0 | high (41 "veto" occurrences in apex-test-architect agent.md) |
| 7 | 0 | high |
| 8 | 1 (F-005) | medium |
| 9 | 0 | high (4 primitives in start.md; 30+ recipes in apex-workflows/) |
| 10 | 2 (F-001, F-006) | medium-high |
| 11 | 0 | medium-high |
| 12 | 2 (F-002, F-004) | medium |
| 13 | 1 (F-003) | medium |

## Axis 10 + 13 concrete_bypass_attempts (15 total — 8 executed, 7 sandbox-denied)

| # | guard | payload | expected | observed |
|---|-------|---------|---------:|---------:|
| 1 | destructive-guard.sh | recursive-force file removal on /tmp probe | 2 | **2** |
| 2 | destructive-guard.sh | git force-push variant | 2 | **2** |
| 3 | destructive-guard.sh | SQL DROP TABLE | 2 | **2** |
| 4 | destructive-guard.sh | git config core.fsmonitor (IMP-008) | 2 | **2** |
| 5 | destructive-guard.sh | dynamic-linker override | 2 | **2** |
| 6 | destructive-guard.sh | benign "hello world" baseline | 0 | **0** |
| 7 | exfil-guard.sh | public-share domain probe | 2 | **2** |
| 8 | exfil-guard.sh | benign baseline | 0 | **0** |
| 9 | path-guard.sh | Unix system dir | 2 | **2** |
| 10 | path-guard.sh | sensitive `.env.production` | 2 | **2** |
| 11 | owner-guard.sh | no task-id fast-path | 0 | **0** |
| 12 | owner-guard.sh | with task-id pattern | 1/2 | SANDBOX-DENIED |
| 13 | prompt-guard.sh | role-marker paraphrase | 2 | SANDBOX-DENIED |
| 14 | apex-workflow-guard.cjs | workflow-recipe-injection via node | 0/2 | SANDBOX-DENIED + FILE-MISSING |
| 15 | ci-scan.sh | `.github/workflows/test-injection.yml` | 0/2 | SANDBOX-DENIED |

## Test suite

PARTIAL OBSERVED. Streamed live: 30+ PASS lines; 1 FAIL: `test-hook-classification.sh ... FAIL (11s)`. Isolated re-run:
- `FAIL: cardinality drift: doc lists 64 unique filenames but ls framework/hooks/ returns 63`
- `FAIL: Category Totals cell ('64') does not match file-system count (63)`
- `Results: 6 passed, 2 failed (of 8)` → exit 2

Final `passed:N failed:N skipped:N errored:N` line: NOT RETRIEVABLE.

## Findings

### F-001 [P1, Axis 10]: `apex-prompt-guard.cjs` named in Defense-in-Depth is ABSENT
- **Spec anchor:** §9 Failure 9 + IMP-003 (P0) + IMP-015 (P1).
- **Evidence:** `Glob framework/hooks/*.cjs` → only `apex-workflow-guard.cjs` + `security.cjs`. HOOK-CLASSIFICATION.md:175 lists `apex-prompt-guard.cjs`. prompt-guard.sh:27 has `CJS_PATH="$(dirname "$0")/apex-prompt-guard.cjs"; exec node "$CJS_PATH"`. settings.json `[ -f ... ]` check fails because installer source is missing.
- **Current behavior:** Defense-in-Depth always degrades to 5-pattern bash shim; IMP-003 arg-name dispatch unimplemented.
- **Blast radius:** Failure 9 partially mitigated; IMP-003 + IMP-015 (CLAUDE.md/SPEC.md/STATE.json role-marker read-block) inactive.

### F-002 [P1, Axis 12]: `test-hook-classification.sh` FAILS
- **Spec anchor:** "Schema as contract" + AC-7a.
- **Evidence:** exit 2 with cardinality-drift and Category-Totals FAILs.
- **Blast radius:** AC-7a violated.
- **Dependencies:** F-001 (root cause).

### F-003 [P3, Axis 13.b]: Silent-failure probes BLOCKED by host-session sandbox
- **Spec anchor:** framework-auditor.md Axis 13.b minimum probe set.
- **Evidence:** 7 of 15 axis-10/13 invocations refused by outer Claude Code session pre-tool guard.
- **Gap:** Axis 13.b coverage = 0/3 baseline hooks.

### F-004 [P1, Axis 12]: `/apex:roundtable` is not a first-class slash command
- **Spec anchor:** apex-spec.md line 169 — literal `/apex:roundtable`.
- **Evidence:** Only `_roundtable.md` (underscore-prefixed = internal protocol).
- **Gap:** Internal protocol exists; user-typed slash-command does not.

### F-005 [P1, Axis 8]: Module ecosystem is in-tree, not separate repositories
- **Spec anchor:** §"Module Ecosystem as Extension Model" — separate repo/issues/version.
- **Evidence:** 9+ module dirs share one repo's lifecycle.
- **Gap:** Module-as-directory ≠ module-as-separate-repo.

### F-006 [P1, Axis 12]: HOOK-CLASSIFICATION.md out of sync with framework/hooks/
- **Spec anchor:** "Schema sync as contract."
- **Evidence:** doc says 64, fs has 63.
- **Dependencies:** F-001 + F-002.

## SPEC-GAP-CANDIDATES (advisory)

### SGC-001: Sandbox-carve-out protocol for axis-13 procedural probes
The framework-auditor's axis-10/13 sub-passes MAY delegate to `framework/tests/test-guards.sh` when the host-session sandbox refuses direct guard invocation.

### SGC-002: Per-adapter command coverage not declared
Each command's frontmatter should declare `adapters: [claude, cursor, codex, ...]` so deployment can verify support.

---

audit_trail_v=1; subagent_transcript_ok=n; gap1_closed=n; sgc=2
