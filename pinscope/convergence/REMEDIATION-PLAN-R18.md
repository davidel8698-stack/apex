# Remediation Plan — PS-R18

## Round summary

R18 carries **1 finding**: 0 AC findings, 0 narrative blocking findings, 1
CONFIRMED off-matrix investigation finding (F-18-01, **P2**), 0 regressions.
The `narrative-auditor` `blocking_findings` set is empty (19 uncovered claims
are all `code_satisfied` proposals — out of remediation scope). The STEP 1C
test audit is **WARN** (advisory only): the AC-075 flat-tree perf-bound note is
standalone and shares no file with F-18-01's fix, so it is **not** planned as an
R-item. One root-caused R-item is authored: **R-18-01**. **Shared-root-cause
groups: 0** (a single finding cannot share a root).

Root-cause framing for R-18-01: the §10-C operation flow has **no single owner
of the `command.history` append**. Two sites independently append to the same
shared `HistoryManager` — `CommandBar.tsx`'s Enter handler appends a
`parsed: null` placeholder *and* persists, then `ClaudeBridge.send` appends the
real `parsed: <Operation>` entry *and never persists*. The result is a persisted
`.pinscope/history.json` that is both **duplicated** (two rows per operation)
and **lossy/lagging** (the real parsed row reaches disk only if a later submit
re-persists; the session's final operation is never persisted). The fix must
consolidate append-and-persist ownership, not patch either symptom alone.

---

## Remediation R-18-01

**id:** R-18-01
**Linked finding:** F-18-01 (CONFIRMED, off-matrix investigation finding)
**Severity:** P2
**Spec anchor:** §8.6 — "CommandBar history is persisted to
`.pinscope/history.json`, last 1000 entries"; §9.4 — a history entry's `parsed`
field is "the parsed Operation"; §10-C — "Operation via CommandBar ... clipboard
+ history".
**Root cause:** The §10-C history-append responsibility is **split across two
unsynchronised owners with no single writer.** `CommandBar.tsx`'s Enter handler
appends a `parsed: null` placeholder to the shared `command.history` manager and
synchronously calls `persistHistory(history.list())`; `ClaudeBridge.send` then
appends a *second*, real `parsed: <Operation>` entry to the **same** manager but
never persists, and `PinScope.onSubmit` never re-POSTs after the send. One
committed operation therefore produces two in-memory rows, and the persisted
file only ever reflects state captured *before* the bridge ran — so it is
duplicated, and the most recent (incl. the session's last) operation's real
parsed row never lands on disk.

### Ecosystem analysis

1. **Who appends to `command.history` today?** Two sites: `CommandBar.tsx`'s
   Enter branch (the `parsed: null` placeholder build + `history.append(entry)`)
   and `ClaudeBridge.send` (`this.history.append({ parsed: operation, ... })`,
   plus the `result: 'failed'` append in its `catch`).
2. **Who persists today?** Only `CommandBar.tsx` — `persistHistory` is defined
   in `CommandBar.tsx` and called from exactly one site, the Enter handler
   (confirmed by the finding's `grep -rn 'persistHistory' src` → no call site
   outside `CommandBar.tsx`).
3. **Is the manager shared?** Yes. `PinScopeHud` builds one
   `new HistoryManager(new MemoryHistoryStore())` in its `command` `useMemo` and
   passes the *same* instance to both `new ClaudeBridge(history)` and
   `<CommandBar ... history={command.history} />`. Both append targets are one
   object.
4. **Why does the placeholder exist?** The CommandBar appends *before*
   `onSubmit` runs so the ArrowUp/ArrowDown history-recall (which reads
   `history.list()` `raw_input`) works for local-only commands
   (`select`/`measure`/`snapshot`) that never reach `ClaudeBridge`. Removing the
   placeholder outright would break recall for those command kinds — the fix
   must preserve recall while eliminating the *duplicate persisted row*.
5. **What does §10-C actually commit?** Per `PinScope.onSubmit`,
   `operation`/`class`/`query` kinds route to `ClaudeBridge.send`;
   `select`/`measure`/`snapshot` are local actions that never produce an
   `Operation`. So a "committed operation" with a non-null `parsed` only ever
   originates from `ClaudeBridge`.
6. **What is the §9.4 contract for `parsed`?** A `HistoryEntry.parsed` is
   `Operation | null`; for an operation/class/query submit the persisted entry
   must carry the real `Operation`, not `null`.
7. **Is the runtime allowed to do disk I/O?** No — `runtime/` is `fs`-free by
   `HistoryManager`'s documented persistence boundary. Persistence is a POST to
   the `/__pinscope/history` dev-server route; `src/plugin/index.ts`'s
   `handleHistoryRequest` writes the file and applies the 1000-entry cap.
8. **Does the persist endpoint or cap need changes?** No.
   `handleHistoryRequest` slicing `-HISTORY_MAX_ENTRIES` (1000) and the
   `HistoryManager` `MAX_ENTRIES` cap are correct and untouched — the defect is
   purely *who appends and who persists*, on the client side.
9. **What is the minimal single-owner design?** Make the **`HistoryManager`
   append the single commit point**, and persist on every append from one
   place. Concretely: route the persist *through the manager* (a persist
   callback / persisting store) so that whoever appends — CommandBar or
   ClaudeBridge — triggers exactly one persist, and remove the duplicate
   `parsed: null` placeholder append for the operation/class/query path.
10. **What must not regress?** ArrowUp/ArrowDown recall for *all* command
    kinds; the AC-053 isolated-`ClaudeBridge` test (`entries.length` `toBe(1)`
    against a directly-constructed manager); AC-054 autocomplete latency; the
    1000-entry cap; `ClaudeBridge.send`'s `result: 'failed'` catch-path entry.

### Execution plan

**Files to modify:**

- `pinscope/src/runtime/managers/HistoryManager.ts` — give `HistoryManager` a
  single, optional persistence hook so an append is the one commit point.
  Add an optional constructor parameter (e.g. an `onPersist?:
  (data: HistoryData) => void` callback, or a second persisting-store
  collaborator) that, when present, is invoked exactly once at the end of
  `append()` after the `MAX_ENTRIES` cap is applied. When absent (the AC-053
  directly-constructed-manager case, and any test store), behaviour is
  unchanged. Do not change the `MAX_ENTRIES` cap, `list()`, or the
  `HistoryStore` read/write contract.
- `pinscope/src/runtime/PinScope.tsx` — in the `command` `useMemo` (the block
  building `new HistoryManager(new MemoryHistoryStore())`,
  `new ClaudeBridge(history)`), wire the single persist owner: construct the
  `HistoryManager` with the persist hook that POSTs `{ version, entries }` to
  `/__pinscope/history`. Move the POST logic so it lives behind this one hook —
  every append (CommandBar's *and* ClaudeBridge's) now persists through it.
- `pinscope/src/runtime/components/CommandBar.tsx` — in the Enter branch of
  `onInputKey` (the block building the `parsed: null` placeholder
  `HistoryEntry` and calling `history.append(entry)` then
  `persistHistory(history.list())`): eliminate the **duplicate** placeholder so
  an operation/class/query submit produces exactly one persisted row (the real
  `parsed: <Operation>` row from `ClaudeBridge`). The recall affordance must be
  preserved — for the command kinds that never reach `ClaudeBridge`
  (`select`/`measure`/`snapshot`, which produce no `Operation`) a single
  `result`-appropriate entry must still be appended so ArrowUp/ArrowDown recall
  keeps working. Remove the now-unused local `persistHistory` /
  `HISTORY_ENDPOINT` from `CommandBar.tsx` once persistence is owned by the
  `HistoryManager` hook (no second persist path may remain — re-grep to
  confirm).

**Files to create:** none.

**Files that MUST remain untouched:**

- `pinscope/src/plugin/index.ts` — `handleHistoryRequest` and its
  `HISTORY_MAX_ENTRIES` (1000) server-side slice/write are correct; the
  `/__pinscope/history` route contract (`{ version, entries }` POST body) is the
  fixed wire format the client persist hook must keep emitting.
- `pinscope/src/runtime/managers/ClaudeBridge.ts` — the `send` method's
  `parsed: <Operation>` append and the `result: 'failed'` `catch`-path append
  are correct as the *real* history rows; do not add a `fetch`/`persistHistory`
  call here (persistence is owned by the `HistoryManager` hook, not the bridge).
  ClaudeBridge stays persistence-agnostic.
- The `HistoryManager` `MAX_ENTRIES` cap value and `list()` semantics.

**Order of operations:**

1. **HistoryManager** — add the optional persist hook; invoke it once at the end
   of `append()`, after the cap slice. No-op when absent.
2. **PinScope.tsx** — in the `command` `useMemo`, construct the `HistoryManager`
   with the persist hook that POSTs to `/__pinscope/history`; this single hook
   now fires for every append, including `ClaudeBridge.send`'s.
3. **CommandBar.tsx** — drop the `parsed: null` placeholder append for the
   operation/class/query path so no duplicate row is created; keep a single
   recall-supporting append for local-only command kinds; delete the local
   `persistHistory`/`HISTORY_ENDPOINT` so exactly one persist path exists.

**Rollback trigger:** if, after the change, a single operation submit produces
more than one persisted row, or `select`/`measure`/`snapshot` recall via
ArrowUp/ArrowDown stops returning the submitted `raw_input`, or the AC-053
isolated-`ClaudeBridge` test's `entries.length` `toBe(1)` assertion fails —
revert all three files to their pre-R18 state.

### Acceptance criteria

- [ ] A test renders the real `<PinScope/>`, stubs `fetch`, submits two
      operation-kind commands through the CommandBar in sequence, captures every
      `/__pinscope/history` POST body, and asserts the **last** captured body's
      `entries` array equals **exactly** the two committed operations, in
      submission order, each with a **non-null** `parsed` `Operation` whose
      target/value match the input — i.e. length `2`, no `parsed: null`
      placeholder rows, no duplicate rows.
- [ ] The same test asserts the **final** operation submitted in the session
      appears in a persisted POST body (the session's last operation IS
      persisted — not in-memory only).
- [ ] `grep -rn 'persistHistory\|parsed: null' pinscope/src/runtime/components/CommandBar.tsx`
      returns **0** matches for an operation/class/query persisted placeholder
      append (the duplicate-placeholder-and-persist path is gone from
      `CommandBar.tsx`).
- [ ] `grep -rn 'fetch\|/__pinscope/history' pinscope/src/runtime` shows the
      `/__pinscope/history` POST originates from **exactly one** site (the
      `HistoryManager` persist hook wired in `PinScope.tsx`) — a single persist
      owner.
- [ ] The AC-053 test (`claude-bridge.test.ts`, `ClaudeBridge.send` in
      isolation, directly-constructed manager) still passes its
      `entries.length` `toBe(1)` assertion — the `HistoryManager` persist hook
      is optional and absent in that test, so isolated behaviour is unchanged.
- [ ] `npm test` (the full vitest unit + integration suite) is green; AC-054
      autocomplete-latency and the 1000-entry cap behaviour are unchanged.

### Definition of Done

R-18-01 is **closed** when **all** of the following mechanically-checkable
conditions hold (the verifier checks the delivered fix against exactly this
list, authored before any code change):

1. **A new red→green test exists and passes.** Add a test (suggested name
   `history-persist-ownership (R-18-01)`, in a runtime integration/unit test
   file that renders the real `<PinScope/>`) that:
   - stubs/spies `fetch` and collects every `/__pinscope/history` POST body;
   - submits, via the CommandBar Enter path, two operation-kind commands in
     order (e.g. `e_7.bg → red` then `e_7.padding → 8px`);
   - asserts the **last** collected POST body's `entries` has length **exactly
     2**;
   - asserts `entries[0].parsed` and `entries[1].parsed` are **both non-null**
     `Operation` objects (no `parsed: null` placeholder row anywhere in the
     persisted array);
   - asserts the two entries are in **submission order** (`entries[0].raw_input`
     is the first command, `entries[1].raw_input` is the second);
   - asserts there are **no duplicate rows** (no two entries with the same
     `raw_input` + `timestamp` pair);
   - asserts the **final** submitted operation (`e_7.padding → 8px`) IS present
     in a persisted POST body — i.e. the session's last operation reaches disk,
     not in-memory only.
   Run before the fix: this test is **red** (the finding's live trace shows
   `lastPersistedEntries=3 kinds=[null,op:sent,null]`). After the fix it is
   **green**.
2. **Single-persist-owner predicate.**
   `grep -rn "/__pinscope/history" pinscope/src/runtime` resolves to exactly one
   POST call site (the `HistoryManager` persist hook); the local
   `persistHistory` function and `HISTORY_ENDPOINT` const are no longer present
   in `CommandBar.tsx`.
3. **No placeholder duplication predicate.** No code path appends a
   `parsed: null` `HistoryEntry` for an operation/class/query submit; an
   operation submit yields exactly one `command.history` row, sourced from
   `ClaudeBridge.send`.
4. **No regression.** The full `npm test` suite is green, including the AC-053
   `ClaudeBridge`-isolation test's `entries.length` `toBe(1)` assertion and the
   AC-054 autocomplete-latency test.

A DoD that merely states "the history file is no longer duplicated/lossy" is
**insufficient** — condition 1's named test, with its exact length/order/
non-null/no-duplicate/last-operation assertions, is the binding check.

### Dependencies

- **None on other R-items** — R-18-01 is the only R-item in this round; it has
  no upstream or downstream R-item dependency.
- **Internal ordering** is fixed by *Order of operations* above:
  `HistoryManager` (persist hook) → `PinScope.tsx` (wire the hook) →
  `CommandBar.tsx` (drop the duplicate placeholder). All three changes land
  together in one execution unit; the fix is incomplete and the file is
  inconsistent if any one is omitted.
- Depends on the existing, unchanged `/__pinscope/history` dev-server route in
  `src/plugin/index.ts` — confirmed correct, no change required there.

### Risk assessment

- **Severity:** P2 — data-integrity defect in a persisted artifact
  (`.pinscope/history.json`), not a crash or a user-blocking failure; the HUD
  and the in-flight operation flow function. Bounded but real: the persisted
  history is the durable record of §10-C operations and is currently both
  duplicated and missing its most recent entry.
- **Regression risk — recall:** removing the CommandBar placeholder append
  risks breaking ArrowUp/ArrowDown recall for `select`/`measure`/`snapshot`
  commands (which never reach `ClaudeBridge`). *Mitigation:* keep a single
  recall-supporting append for the local-only command kinds; the AC list
  explicitly re-checks recall.
- **Regression risk — AC-053:** AC-053 tests `ClaudeBridge.send` with a
  directly-constructed `HistoryManager` and asserts `entries.length` `toBe(1)`.
  *Mitigation:* the persist hook is an **optional** `HistoryManager` constructor
  parameter — absent in AC-053's test, so isolated `append` behaviour and the
  `toBe(1)` count are unchanged.
- **Regression risk — double-persist:** if the persist hook is wired *and* the
  old `CommandBar.persistHistory` call is left in place, persists double.
  *Mitigation:* the grep predicate in the DoD (single POST call site) and the
  removal of `persistHistory`/`HISTORY_ENDPOINT` from `CommandBar.tsx` are
  mandatory acceptance checks.
- **Boundary risk:** the fix keeps `runtime/` `fs`-free — persistence remains a
  POST to the dev-server route; the `HistoryManager` hook only *invokes* a
  caller-supplied callback and never imports `node:fs`. Low risk.
- **Convergence:** this is a root-cause fix (single-owner consolidation), not a
  symptom patch, so the duplicate-row / lost-last-entry class of gap should not
  reopen under a different AC next round.
