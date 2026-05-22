# Wave Result — PS-R18

## Wave 1

### R-18-01 — history persist single-owner consolidation

**id:** R-18-01
**status:** closed
**linked finding:** F-18-01 (CONFIRMED, P2 — `.pinscope/history.json` double-written and lossy on the §10-C flow)

#### Root cause addressed

The §10-C history-append responsibility was split across two unsynchronised
sites: `CommandBar.tsx`'s Enter handler appended a `parsed: null` placeholder
*and* persisted, while `ClaudeBridge.send` appended the real
`parsed: <Operation>` entry *and never persisted*. The persisted file therefore
carried duplicate rows and lagged a submit behind (the session's last operation
never reached disk). Fix: the `HistoryManager` `append()` is now the single
commit point — an optional persist hook fires exactly once per append, after
the cap slice; `PinScope.tsx` wires that hook as the sole `/__pinscope/history`
POST owner; `CommandBar.tsx` no longer appends a placeholder for
operation/class/query submits (it appends one recall entry only for the
local-only kinds that never reach `ClaudeBridge`).

#### Red → green transition

New test: `pinscope/tests/unit/runtime/history-persist-ownership.test.tsx`
(`history persist ownership (R-18-01, §8.6/§10-C)`).

**RED — before the fix** (`npx vitest run tests/unit/runtime/history-persist-ownership.test.tsx`):

```
 ❯ tests/unit/runtime/history-persist-ownership.test.tsx  (1 test | 1 failed) 1083ms
   ❯ ... > persists exactly the committed operations — no placeholder, no duplicate, last op reaches disk
     → expected 3 to be 2 // Object.is equality

 FAIL  tests/unit/runtime/history-persist-ownership.test.tsx > history persist ownership (R-18-01, §8.6/§10-C) > persists exactly the committed operations ...
AssertionError: expected 3 to be 2 // Object.is equality
- Expected   2
+ Received   3
 ❯ tests/unit/runtime/history-persist-ownership.test.tsx:97:36

 Test Files  1 failed (1)
      Tests  1 failed (1)
```

The persisted POST body carried **3** rows (`[parsed:null, op:sent, parsed:null]`)
instead of 2 — exactly the finding's `lastPersistedEntries=3 kinds=[null,op:sent,null]`
live trace. Failed for the right reason: the duplicate `parsed: null`
placeholder and the lag.

**GREEN — after the fix** (`npx vitest run tests/unit/runtime/history-persist-ownership.test.tsx`):

```
 ✓ tests/unit/runtime/history-persist-ownership.test.tsx  (1 test) 182ms

 Test Files  1 passed (1)
      Tests  1 passed (1)
```

The test asserts: last POST body `entries.length === 2`; both `entries[*].parsed`
non-null `Operation`s with matching pin/property/value; submission order;
no duplicate `raw_input`+`timestamp` rows; the session's final operation
(`e_7.padding → 8px`) is present in a persisted body (reaches disk).

#### Files modified

- `pinscope/src/runtime/managers/HistoryManager.ts` — added optional
  `onPersist?: HistoryPersist` constructor parameter; invoked once at the end of
  `append()` after the `MAX_ENTRIES` cap slice. No-op when absent. `MAX_ENTRIES`
  (1000) and `list()` semantics unchanged.
- `pinscope/src/runtime/PinScope.tsx` — added the `persistHistory` single
  persist owner (POST `{version, entries}` to `/__pinscope/history`); wired it
  as the `HistoryManager` persist hook in the `command` `useMemo`.
- `pinscope/src/runtime/components/CommandBar.tsx` — removed the local
  `persistHistory`/`HISTORY_ENDPOINT`; the Enter handler now appends only for
  local-only kinds (`select`/`measure`/`snapshot`, via `isLocalOnlyCommand`),
  with `result: 'applied'`; operation/class/query submits get their single real
  row from `ClaudeBridge.send`.
- `pinscope/tests/unit/runtime/history-persist-ownership.test.tsx` — **new**
  R-18-01 closure test (DoD condition 1).
- `pinscope/tests/unit/runtime/controls.test.tsx` — updated 4 tests that
  encoded the now-removed CommandBar persist/placeholder behaviour (see
  `scope notes`).

#### Definition of Done — clause-by-clause

**DoD 1 — a new red→green test exists and passes.** `verified: true`.
`history-persist-ownership.test.tsx` was RED (`expected 3 to be 2`) against the
buggy code and GREEN after the fix (output pasted above). It asserts last-body
length exactly 2, both `parsed` non-null with matching target/value, submission
order, no duplicate `raw_input`+`timestamp` pair, and final-operation-persisted.

**DoD 2 — single-persist-owner predicate.** `verified: true`.

```
$ grep -rn '/__pinscope/history' pinscope/src/runtime
src/runtime/PinScope.tsx:116:const HISTORY_ENDPOINT = '/__pinscope/history';

$ grep -rn 'persistHistory|HISTORY_ENDPOINT' pinscope/src/runtime/components/CommandBar.tsx
(0 matches — confirmed gone)
```

The `/__pinscope/history` route resolves to exactly one site (the
`HistoryManager` persist hook in `PinScope.tsx`); `EndpointSnapshotStore`'s
`fetch` targets the unrelated `/__pinscope/snapshot` flow-D route. The local
`persistHistory` function and `HISTORY_ENDPOINT` const are gone from
`CommandBar.tsx`.

**DoD 3 — no placeholder duplication predicate.** `verified: true`. No code path
appends a `parsed: null` `HistoryEntry` for an operation/class/query submit:
`CommandBar.tsx`'s remaining `parsed: null` (line 117) is reached only when
`isLocalOnlyCommand(command)` is true (`select`/`measure`/`snapshot`), which
produce no `Operation` and so correctly carry `parsed: null` per §9.4. An
operation submit yields exactly one `command.history` row, from
`ClaudeBridge.send`. The R-18-01 test asserts this (length-2, no `parsed: null`,
no duplicate).

**DoD 4 — no regression.** `verified: true`. Full suite green — 303/303 (302
baseline + 1 new R-18-01 test). AC-053 `ClaudeBridge`-isolation test passes its
`entries.length` `toBe(1)` assertion (the persist hook is an optional
constructor parameter, absent in that directly-constructed manager). AC-054
autocomplete-latency and the 1000-entry cap test pass unchanged.

#### Wave regression check

```
$ cd pinscope && npx vitest run
 Test Files  30 passed (30)
      Tests  303 passed (303)
   Duration  8.03s

$ npx vitest run tests/unit/claude-bridge.test.ts
 ✓ tests/unit/claude-bridge.test.ts  (2 tests) 769ms
 Test Files  1 passed (1)
      Tests  2 passed (2)

$ npx tsc --noEmit
TSC_EXIT=0
```

Baseline was 302/302; suite is now 303/303 (the +1 is the new R-18-01 test).
The "at Proxy..." lines printed above the file list are stack-trace noise from
an existing test's intentional error path, not a failure — the summary reports
`30 passed (30)` / `303 passed (303)`.

#### scope notes

- Source files modified are exactly the three the R-item's Execution plan names:
  `HistoryManager.ts`, `PinScope.tsx`, `CommandBar.tsx`. Preservation contract
  honoured — `src/plugin/index.ts` and `src/runtime/managers/ClaudeBridge.ts`
  are untouched (`git status` clean for both); `MAX_ENTRIES` (1000) and `list()`
  semantics unchanged.
- `pinscope/tests/unit/runtime/controls.test.tsx` was modified — a **test
  file**, in-scope under the DoD's `pinscope/tests/` allowance, not a source
  file. Four tests there directly encoded the *exact buggy behaviour R-18-01
  removes* (CommandBar appending a `parsed: null` placeholder for an operation
  command, and CommandBar owning the `/__pinscope/history` `fetch` POST). They
  were updated to the redesigned contract: recall/append tests now use
  local-only kinds (`select`/`measure`, the kinds CommandBar still appends for);
  the persist test now renders the real `<PinScope/>` and asserts the POST
  fires once through the single `HistoryManager`-hook owner. Operation-kind
  recall remains covered end-to-end by the new R-18-01 test (via the shared
  manager `ClaudeBridge` appends into). No other file touched.
```
fix(pinscope): R-18-W1 — consolidate history persist into a single HistoryManager-owned hook
```
