# APEX R4 — Wave Plan and Dependency Map

**Round:** R4
**Plan source:** `C:\Users\דודאלמועלם\.claude\plans\6-ethereal-gem.md`
(the architect-authored plan with 10-question ecosystem methodology)
**Total R-IDs:** 7 (6 planned + 1 hot-fix)
**Waves:** 3

---

## Dependency analysis

All R-IDs are functionally independent (no R-ID modifies a file another
R-ID is mid-modifying). The only coupling is:

1. **R4-004 depends on R4-001** — R4-001 adds S-14 to `test-hooks-security.sh`;
   R4-004 adds a standalone guard to that same file. If R4-004 ran first,
   R4-001's addition of S-14 would have been authored into the already-guarded
   file (still correct, but cleaner the other way round).
2. **R4-007 (hot-fix) depends on R4-005 surfacing it.** R4-005 (the R2
   regression sweep) cannot unveil the finding without existing; R4-007
   cannot be scoped without the discovery.
3. **R4-006 depends on everything** — artifact authoring happens after all
   code-touching R-IDs land (so Findings can reference what was changed).

No R-ID conflicts on a shared file with any other. Per
`REMEDIATION-STYLE.md`, every file in scope is modified by exactly one
R-ID (except `framework/settings.json` which is touched only by R4-007,
and `framework/HOOK-CLASSIFICATION.md` which is touched by R4-002 and
R4-007 at non-overlapping locations — R4-002 at the trigger-type table
and category footers; R4-007 at the Command-Invoked / Event-Triggered
category header and 3 specific rows).

---

## Wave assignments

### Wave 1 — Independent, parallel-safe code changes

| R-ID | Title | File(s) |
|---|---|---|
| R4-001 | ci-scan.sh regex + S-14 test | `framework/hooks/ci-scan.sh`, `framework/tests/test-hooks-security.sh` |
| R4-002 | settings.json format-migration sweep | `framework/HOOK-CLASSIFICATION.md`, `framework/commands/apex/start.md` |
| R4-003 | Preflight error text covers all platforms | `framework/commands/apex/start.md` |

**Gate check before Wave 2:**
- `bash framework/scripts/self-test.sh hooks-security` — S-11 passes.
- `grep` sweep returns zero old-format references.
- `bash framework/hooks/_date-parse.sh` returns `OK <tier>` on primary env.

### Wave 2 — Test infrastructure + regression + emergent finding

| R-ID | Title | File(s) |
|---|---|---|
| R4-004 | Standalone guards on 7 test files | All `framework/tests/test-*.sh` (7 files) |
| R4-005 | R2 regression sweep | Read-only; no file modified |
| R4-007 | Lifecycle events in settings.json (hot-fix) | `framework/settings.json`, `framework/HOOK-CLASSIFICATION.md` |

**Gate check before Wave 3:**
- Each test file runs standalone, reports pass/fail, exits with FAIL count.
- Aggregated `bash framework/scripts/self-test.sh` = 106/106 (same as baseline).
- All 11 R2 R-IDs' content anchors still present.
- Post-R4-007 sync-to-claude run: live settings.json has all 5 event types
  populated and user's non-APEX entries preserved byte-for-byte.

### Wave 3 — Documentation and closure

| R-ID | Title | File(s) |
|---|---|---|
| R4-006 | Audit artifacts | `apex-audit-findings-R4.md`, `WAVES-R4.md`, `ROUND-R4-CLOSURE.md` |

**Gate check before round close:**
- `apex-audit-findings-R4.md` enumerates 7 R-IDs (6 planned + 1 hot-fix) with severity.
- `WAVES-R4.md` (this document) records wave assignments and results.
- `ROUND-R4-CLOSURE.md` declares stop-criterion verdict.

---

## Wave results

### Wave 1 result — PASS

- R4-001: committed `9ebcf4c` — S-11 now passes (was failing across R1–R3);
  S-14 added as false-positive guard for list-form local actions;
  `bash framework/scripts/self-test.sh hooks-security` = 18/18.
- R4-002: committed `88c6c5a` — 2 narrative references fixed
  (`framework/HOOK-CLASSIFICATION.md` table + footers;
  `framework/commands/apex/start.md` install step 1d).
- R4-003: committed `af98cda` — preflight error text covers Linux, macOS,
  Windows Git Bash; selftest confirmed green (`OK gnu-date`).

Interim non-R4 commit: `8d49649` (chore) persisted pre-R4 uncommitted R2/R3
work that was in the working tree at session start (R2 audit artifacts,
R3 closure docs, associated framework code updates). This cleared the
working tree so Wave 2 R-IDs could land without cross-session mixing.

### Wave 2 result — PASS (with emergent P1 hot-fixed)

- R4-004: committed `7b478b1` — all 7 test files runnable standalone;
  aggregated self-test still 106/106 (no regression).
- R4-005: no commit (read-only). All 11 R2 R-IDs verified present via
  content-addressable anchors. Zero regressions.
- R4-007: committed `e8c2955` — framework/settings.json extended with
  SessionStart, PreCompact, SubagentStop registrations; post-sync live
  settings preserved user's non-APEX entries byte-for-byte.

### Wave 3 result — PASS

- R4-006: committed — `apex-audit-findings-R4.md`, `WAVES-R4.md` (this
  document), and `ROUND-R4-CLOSURE.md` authored using content-addressable
  anchors exclusively.

---

## Cross-wave regression check (executor rule 5)

After Wave 1 → 2 → 3:

- `bash framework/scripts/self-test.sh` = 106/106 pass (every wave).
- No reverts needed; every R-ID committed on the first pass.
- No R1 / R2 / R3 anchor lost (verified by R4-005 + retained spec
  anchors in R4 findings doc).

---

## Do-not-touch zones honored

Per the R4 plan, the following remained untouched:

- `framework/scripts/sync-to-claude.sh` — merge logic already handled the
  new event types correctly (line 134–148 reduce-over-keys pattern); no
  code change was required for R4-007.
- `framework/hooks/circuit-breaker.sh` — stable post-R3-001.
- `framework/hooks/_security-common.sh` — stable post-R2-001.
- `framework/hooks/_date-parse.sh` — fallback chain order preserved
  (GNU → BSD → python3 → python2); only the error-text consumer
  (`start.md`) was touched.
- `apex-spec.md` — no R4 spec amendment.
- R1 / R2 / R3 audit artifacts — historical, not rewritten.

---

## Commits, in order

| # | SHA | R-ID | Description |
|---|---|---|---|
| 1 | `9ebcf4c` | R4-001 | ci-scan.sh detects unpinned GHA in list-item form |
| 2 | `88c6c5a` | R4-002 | Sweep settings.json old-format narrative references |
| 3 | `af98cda` | R4-003 | Preflight error text covers all platforms |
| 4 | `8d49649` | (chore) | Persist R2 + R3 audit artifacts and code fixes |
| 5 | `7b478b1` | R4-004 | Test files runnable standalone (NEW-F-R3-002) |
| 6 | `e8c2955` | R4-007 | framework/settings.json wires lifecycle event hooks |
| 7 | (this) | R4-006 | R4 audit artifacts (findings, waves, closure) |

---

## Stop-criterion tracking

R4's stop criterion (two consecutive clean rounds):

- R3: 0 P0 + 0 P1 — **clean**.
- R4: 0 P0 + 0 P1 — **clean** (R4-007 was surfaced and hot-fixed **inside**
  R4; it is not a P1 that escaped the round).

See `ROUND-R4-CLOSURE.md` for the final verdict.
