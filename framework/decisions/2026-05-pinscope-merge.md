# Decision: Merge PinScope into APEX main + productize as bundled scaffold

**Date:** 2026-05-24
**Decided by:** david (APEX owner)
**Plan ID:** APX-PS-CAMPAIGN-001
**Author:** Claude Opus 4.7 (campaign executor) under the user's
[[feedback-rigor-standard]] + [[feedback-autonomy]] discipline

## Context

Between 2026-05-21 14:39 UTC and 2026-05-22 14:23 UTC, an Anthropic
Managed Agent authored 80 commits on branch
`origin/claude/enhance-apex-design-6l23i`, building:

- a complete React+Vite visual-debug HUD library under `pinscope/`
  (244 files; 257 tests; PS-R19 CONVERGED + PS-R20 staged)
- a bespoke `/ps-heal` self-healing loop (mirrors `/apex:self-heal`)
- 6 new APEX agents (spec-auditor, narrative-auditor,
  ps-{remediation-planner,scheduler,wave-executor,verifier})
- 1 new APEX skill (`framework/apex-skills/pinscope.md`)
- Modifications to `auditor.md`, `architect.md`, `ui-phase.md`,
  `ui-review.md`, `CLAUDE.md`, `apex-spec.md`, `.gitignore`

The branch was never merged, never PR'd, never fetched into a working
tree — it lived as a remote ref only until 2026-05-24 when the user
discovered it. Diverged from main at `86e131a` (2026-04-25); never
reconciled (224 commits on main, 80 on the branch, zero cross-commits).

## Decision

**Merge the branch to APEX `main` and productize PinScope as the
default visual-debug HUD installed by every APEX-scaffolded project.**

Specifically:
1. **Preserve** the branch state via three immortal git tags
   (`pinscope/PS-R19-converged`, `pinscope/branch-tip-R20-staged`,
   `main/pre-pinscope-merge`) — preserves all 80 commits beyond any
   branch deletion.
2. **Merge** with `--no-ff` (preserves PS-R{N} round structure as
   proof-of-process) at branch tip `959a4f7` (PS-R20 staged but
   unexecuted — see "Acceptable limitation" below).
3. **Reject** the branch's 358-line deletion of Mythos IMPs from
   `apex-spec.md` (auto-merge naturally kept main's content).
4. **Keep** main's `auditor.md` dispatch-contract preflight (R5-009)
   while adopting the branch's PinScope dual-mode and `maxTurns: 25`.
5. **Wire** PinScope into APEX scaffolds via the IMP-PS-* IMPs
   (visibility comments in `/apex:start` and `/apex:onboard`;
   ui-phase/ui-review/architect/frontend-specialist modifications
   landed via merge).
6. **Catalog** the 5 `/ps-heal` doctrines as adoption backlog in
   `framework/docs/PS-HEAL-DOCTRINES.md` (vs. bulk-landing them
   per the detector-hardening lesson on rigor in adoption).
7. **Defer** npm publication (`pinscope` package) — requires user
   credentials; user can `cd pinscope && npm publish` post-campaign.
8. **Defer** PS-R20 execution — to be done post-merge via `/ps-heal`
   on the live `pinscope/` tree. Branch tip already has the staged
   plan + waves; tags preserve the state.
9. **Delete** the now-redundant `origin/claude/enhance-apex-design-6l23i`
   branch (after verifying all 3 tags reachable + content on `main`).
10. **Update** scope docs (`CLAUDE.md` line-1, `apex-spec.md`
    additive §PinScope section, `README.md` opening message).

## Alternatives considered

1. **Archive branch as tag only** (Closed-prototype) — rejected: user
   explicitly stated "אני רוצה ש'PinScope' תיהיה בכל פרויקט שAPEX
   מפתח" (I want PinScope in every project APEX develops). Archival
   alone would not satisfy this.

2. **Extract PinScope to its own repo** (Active-product, separate) —
   rejected: monorepo is operationally simpler for a non-programmer
   ([[user-apex-owner]] + [[feedback-plan-design]] "single source of
   truth"). PinScope as a monorepo sub-project + npm-published from
   there is the simpler operating model.

3. **Cherry-pick selectively** (Surgical extraction of agents +
   skill + 4 framework edits, leave `pinscope/` directory off main) —
   rejected: requires PinScope to live elsewhere to satisfy user
   intent, reintroducing the monorepo-vs-separate-repo question;
   loses the unified history.

4. **Bulk-land /ps-heal doctrines in P6 as planned** — revised to
   "catalog only" mid-campaign: per [[feedback-rigor-standard]] each
   doctrine needs held-out validation (per detector-hardening
   lesson) and bundling 5 of them either skips validation or burns
   serial validation hours in one phase. Catalog gives rigorous
   incremental adoption path.

## Consequences

**Positive:**
- PinScope on `main` (`git ls-tree -r main pinscope/` = 244 files)
- PinScope history preserved (40+ commits in `git log main --grep=pinscope`)
- 6 new agents + 1 skill + `/ps-heal` command land on main
- `/ps-heal` command becomes invokable on PinScope post-merge
- Decision recorded; future Claude sessions know the scope change
- Three rollback anchors exist (tag-preserved)
- Doctrine adoption backlog cataloged for future rigorous adoption

**Negative / Acceptable limitations:**
- **PS-R20 not executed pre-merge.** PinScope ships at PS-R19 quality
  (62/69 CLOSED, 0 OPEN, 7 BLOCKED). The 3 confirmed R-items
  (R-20-01/02/03 — `PinScopeHud` integration: VoidBadges,
  RuntimePinObserver, Shift+P/C toggles) remain documented in
  `pinscope/convergence/REMEDIATION-PLAN-R20.md`. SC-05 (zero OPEN)
  partially met (PS-R19 has 0 OPEN; PS-R20 staged but unrun).
  **Mitigation:** Post-merge `/ps-heal` can execute the staged plan
  directly from the merged tree.
- **npm publication deferred.** SC-06 (npm view returns version)
  not yet met. User can run `cd pinscope && npm publish` to satisfy.
- **IMP-DOC-* doctrine wiring deferred** to incremental adoption per
  cataloged backlog. SC-08 (5 doctrines on `/apex:self-heal`)
  partially met (cataloged + reference implementations live in
  `pinscope/convergence/` and 6 PinScope-loop agents in
  `framework/agents/`).
- **End-to-end Playwright verification deferred** — requires a
  running React+Vite project; user can scratch-test post-campaign.

## Verification

- **SC-01 ✓** — all 3 tags verify via `git tag -v`
- **SC-02 ✓** — `git ls-tree -r main pinscope/ \| wc -l` = 244
- **SC-03 ✓** — `git log main --grep=pinscope -i \| wc -l` = 40+
- **SC-04** — `cd pinscope && npm test` deferred to user (no npm in this env)
- **SC-05** — PS-R20 deferred (acceptable per §34 cascade)
- **SC-06** — npm publish deferred
- **SC-07** — scaffold integration wired via IMP-PS-01/02; full e2e deferred
- **SC-08** — 5 doctrines cataloged (`framework/docs/PS-HEAL-DOCTRINES.md`)
- **SC-09** — branch deletion in P8.6
- **SC-10 ✓** — `head -15 CLAUDE.md \| grep -c "PinScope"` = 1+
- **SC-11 ✓** — framework tests: same 3 pre-existing failures, no regression
- **SC-12** — cross-platform: tested on Win10 host (this session)

## Tags of record

- `pinscope/PS-R19-converged` → `a1b5281` (CONVERGED state)
- `pinscope/branch-tip-R20-staged` → `959a4f7` (R20 plan + waves staged)
- `main/pre-pinscope-merge` → `bed7f09` (pre-merge main)
- `main/post-pinscope-merge` → `91eb6f0` (merge commit)

## Re-do procedure (if this decision is regretted)

1. `git reset --hard main/pre-pinscope-merge`
2. `git push --force-with-lease origin main`
3. (Optionally) `git push origin pinscope/branch-tip-R20-staged:refs/heads/claude/enhance-apex-design-6l23i` — recreates branch
4. Tags remain — PinScope work preserved either way

## Related campaigns

- [[project-detector-campaign]] (closed 2026-05-24 PASS-WITH-LIMITATION) — the empirical lesson that motivated rigorous held-out validation for IMP-DOC-* doctrine adoption (deferred to cataloged backlog vs. bulk-land)
- Audit-trail B2.x–B5 (closed 2026-05-24 — most recent at `bed7f09` pre-merge) — no overlap

Co-Authored-By: Claude <noreply@anthropic.com> (original Managed Agent who authored PinScope)
Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com> (this campaign's executor)
