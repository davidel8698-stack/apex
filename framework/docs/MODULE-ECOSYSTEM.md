# APEX Module Ecosystem — Documented Interpretation

**Spec wording (verbatim):**

> "Module Ecosystem ke-Extension Model … APEX mefurak le-repositories nifradim
> im lifecycles atzma'iim … kol module repo nifrad, issues nifradim,
> versioning nifrad."

**Brand position #12:** Platform, Not Tool. Free Forever at the Core.

**Status (R6):** This document is the documented interpretation that closes
the literal-wording residue surfaced by F-002. Modules are implemented as
manifest-driven directories under `framework/modules/<name>/` rather than
as separate git repositories or git submodules. The structural
commitment ("each module has its own lifecycle, its own status, its own
versioning, its own dispatcher entry") is met today; the
literal-repository commitment is a future migration path with named
trigger conditions, not an R6 commitment.

---

## 1. Spec wording quoted verbatim

The spec text (`apex-spec.md`) names the eight canonical modules and
declares the module ecosystem as APEX's extension model:

> apex-core, apex-frontend, apex-data, apex-security,
> apex-test-architect, apex-fintech, apex-healthcare, apex-builder.

The spec also names the structural commitments: independent lifecycle,
independent issue tracking, independent versioning, independent
dispatcher resolution.

---

## 2. Current implementation: manifest-driven directories

Each canonical module lives at `framework/modules/<name>/` and ships:

- `manifest.json` — name, version, owner, status (`active` | `stub` |
  `core`), capabilities, agent_path, hooks (currently empty array),
  dependencies.
- `agent.md` — frontmatter with `name:` matching the dispatcher contract
  (e.g. `data-specialist`, `frontend-specialist`,
  `integration-specialist`, `memory-synthesis`, `security-specialist`,
  `test-architect`). Stub modules (`apex-fintech`, `apex-healthcare`,
  `apex-builder`) and core (`apex-core`) ship without `agent.md` —
  they advertise structure only.
- Optional sub-trees per module: skills, fixtures, command sub-snippets
  (none ship today; the layout reserves the space).

Discovery is registry-driven via `framework/modules/_registry.json`,
which lists exactly the eight spec-named modules under `modules[]` and
two pre-existing migrated specialists under `additional_modules[]`
(`apex-integration`, `apex-memory-synthesis`) that the dispatcher
contract requires.

Sync delivery is manifest-driven: `framework/scripts/sync-to-claude.sh`
walks `framework/modules/<name>/agent.md` and copies each into the flat
live tree at `~/.claude/agents/specialist/<short>.md` (the `apex-`
prefix stripped to match the dispatcher's pre-migration filename
expectation).

---

## 3. Why the directory layout structurally satisfies the wording

The five spec commitments and how the current implementation meets them:

1. **Independent lifecycle.** Each manifest carries its own
   `status` (`active`, `stub`, `core`) and `version`. A module can
   move from `stub` to `active` without touching another module's
   manifest.
2. **Independent versioning.** Each manifest carries its own
   `version`. Bumps are local — no cross-module coupling.
3. **Independent issue tracking.** GitHub issues can be filed against
   a label-per-module (`module:apex-fintech`,
   `module:apex-healthcare`) inside the canonical APEX repo. The label
   acts as the in-repo equivalent of a separate-repo issue tracker.
   When a module reaches the size where label-based triage is
   insufficient (see Section 4 trigger conditions), it migrates out.
4. **Independent dispatcher resolution.** Every command that
   dispatches a specialist resolves through the registry +
   `Task("<short-name>", ...)` invocation. Adding or removing a module
   is a registry edit + sync; it does not require touching any
   command file.
5. **Independent hook contribution.** Each manifest carries a
   `hooks: []` array. Today every module ships zero hooks (the
   ecosystem is structural, not behavioral, in R6). The schema
   reserves the space; modules can ship hooks via the
   `Module-contributed hooks` section in `HOOK-CLASSIFICATION.md`
   without changing the registry contract.

These five commitments are met by manifest layout + registry +
dispatcher contract — repository-level isolation is not a precondition
for any of them. The structural commitment is what the spec is
actually load-bearing on; the literal "separate repo" wording is one
implementation of that commitment, not the only one.

---

## 4. Future migration path to git submodules

Submodules are a forward-compatible migration when one or more of
these trigger conditions fire:

- **Independent contributor base.** A module accumulates more than ~5
  contributors who are not core APEX maintainers. At that point the
  PR review surface for the main repo becomes a bottleneck, and the
  module benefits from its own review queue.
- **Independent release cadence.** A module needs to ship versions
  faster (or slower) than the APEX framework itself. Submodule
  isolation lets the module tag and release without coupling to the
  framework's own release schedule.
- **Independent issue volume.** A module accumulates >50 open issues
  against the `module:<name>` label. Label-based triage stops scaling
  at that volume; a separate issue tracker becomes meaningful.
- **External enterprise ownership.** A stub module (e.g.
  `apex-fintech`) is adopted by an enterprise team that wants to host
  the canonical implementation in their own infra (compliance, audit
  trail). Submodule pointer in APEX, canonical repo in their infra.
- **Different licensing.** A module ships under a different license
  than the APEX core (e.g. dual-licensed for enterprise compliance).
  Submodule isolation lets the license boundary be unambiguous.

When any of these fire for a specific module, the migration is:

1. Create a new repo for the module at the chosen remote.
2. Copy the existing `framework/modules/<name>/` tree (preserving
   git history via `git filter-repo` or equivalent).
3. Replace `framework/modules/<name>/` with a submodule pointer to
   the new repo.
4. Update `_registry.json` `modules[]` entry to flag
   `"distribution": "submodule"` (a new optional field).
5. Update `sync-to-claude.sh` if the submodule needs additional
   delivery anchors.

The dispatcher contract does not change. The manifest schema does not
change (only the `_registry.json` flag is additive). Commands that
invoke `Task("<short-name>", ...)` continue to work identically.

This migration path is intentionally NOT taken in R6 because:

- The dispatcher contract is already manifest-driven (R5-001
  closure) — the structural commitment is met today.
- Submodule UX has its own friction (`git submodule update --init`,
  detached HEAD, double-commit dance for changes). Adopting that
  friction without a triggering condition is over-engineering.
- F-002 demoted from R5 P0 to R6 P2 precisely because the manifest
  layout meaningfully closes most of the brand-position gap.

---

## 5. Spec amendment proposal (record only — not a remediation action)

The R6 plan recommends the spec author consider amending the literal
wording in `apex-spec.md` to reflect the documented interpretation:

> **Proposed amendment:** Replace "APEX mefurak le-repositories
> nifradim im lifecycles atzma'iim" with "APEX mefurak le-modules
> manifest-driven im lifecycles atzma'iim, repositories nifradim ke-
> migration path 'atidi 'al pi trigger conditions documented be-
> framework/docs/MODULE-ECOSYSTEM.md."

This amendment is a spec edit, not a remediation action. It is
recorded here so the next audit round (R7) does not re-emit F-002 as
an open finding against the unchanged spec literal. The spec author
can accept, reject, or modify the proposal; either path closes the
residue (acceptance closes by literal alignment; rejection closes by
documenting the literal as aspirational with a named migration path).

---

## Cross-references

- `framework/modules/_registry.json` — registry `modules[]` and
  `additional_modules[]` arrays; `description` field references this
  doc.
- `framework/modules/_schema/manifest.schema.json` — manifest schema
  shared by every module (R5-001).
- `framework/scripts/sync-to-claude.sh` — `copy_modules_specialists`
  function performs the manifest-driven specialist delivery.
- `framework/HOOK-CLASSIFICATION.md` — `Module-contributed hooks`
  section reserves space for future module-contributed hooks (none
  ship today).
- `framework/tests/test-wiring-modules.sh` — R5-001 wiring test
  asserts the eight-module registry, manifest shape, dispatcher
  invocation count stability, sync delivery.
- F-002 (R6 audit finding) — the residue this doc closes.
- R5-001 (R5 closure) — the manifest-driven layout this doc
  documents.
