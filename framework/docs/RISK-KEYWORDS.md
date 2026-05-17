# Risk Keywords — Shared Classifier Vocabulary (M08 / M12 / M15)

**Purpose.** Single source of truth for the word lists APEX uses to classify
tasks by risk and by type. M08 reads this to decide `task_class` (A/B/C/D).
M12 reads this to decide `task_type` (new_code / bug_fix / refactor /
test_writing / code_review / frontend). M15 (`/apex:fast`) reads this to
decide whether a task qualifies as micro (and if not, what bumped it out).

**Spec anchors.**
- `apex-spec.md` — `היכולות הנדרשות` + `עקרונות העבודה`. Risk-aware autonomy
  is one of the named capabilities.
- `.apex/phases/12-apex-evolution-v8/PLAN.md` task 12.02 §6 ("classification
  rules"), §8 pre-conditions ("RISK-KEYWORDS.md (new) — shared keyword list
  for classification"). The architect consumes this list in Step 1.10 of
  `framework/agents/architect.md` (named "Step 1.10" rather than the
  PLAN.md draft's "Step 1.8" to avoid collision with the pre-existing Step
  1.8 Jagged Frontier Assessment).
- Research basis: R5 §3 (METR RCT — task *type* dominates outcomes more
  than complexity), R2-C107 (high-risk surface enumeration), Veracode 45%
  + Pearce 40% + Apiiro +322% (security keyword importance).

## How classifiers consume this file

Each keyword set below is grouped by **dimension** (risk class, task type,
domain). Classifiers read the file at boot and match against the task
PLAN.md description, files-modified list, and verify-commands. Matching is
**case-insensitive**, **substring**, **conservative**: when a keyword
matches in *any* of the three fields, the classification bumps to the
higher class. The conservative-default-higher rule prevents low-risk
misclassification of high-risk tasks; the symmetric false-positive (a UI
label containing "logout" tagged Track C) is mitigated by the auditor
review pass that runs after architect classification.

The match function ignores keywords that appear only inside Markdown code
fences (triple-backtick) or within block-quote citation lines (`> ...`) so
the classifier does not trip on incidental keyword mentions in research
notes or quoted spec excerpts.

## Class A — Low risk (allow Trusted autonomy after 5 clean)

Tasks where the executor mistakes have **mechanical, easily-reversible
consequences**. Documentation tweaks, formatting passes, README updates,
test-suite additions that do not touch implementation logic, dependency
version bumps in lockfiles (not direction changes), comment rewrites.

Trigger keywords (any one match → bump candidate to A unless a higher
class also matches):

- `docs:`, `documentation`, `README`, `CHANGELOG`, `comment`, `typo`,
  `wording`, `grammar`, `prose`
- `style:`, `lint:`, `format:`, `prettier`, `eslint --fix`, `gofmt`,
  `rustfmt`, `black .`, `ruff check`
- `bump`, `update dependency`, `lockfile`, `package-lock`, `yarn.lock`,
  `Cargo.lock`, `go.sum`, `pnpm-lock`
- `test fixture`, `test helper`, `snapshot update`, `golden file`

## Class B — Medium risk (allow Trusted autonomy after 7-8 clean)

Tasks that modify production code paths but are **localized** and have
**clear test coverage**. Bug fixes in single functions, new utility
helpers, refactors within a single file, adding new endpoints that follow
existing patterns, new UI components built from established design
primitives.

Trigger keywords:

- `bug fix`, `fix:`, `fixes #`, `repro`, `regression test`,
  `edge case handling`
- `add helper`, `utility`, `extract function`, `inline`,
  `rename variable`, `extract constant`
- `new endpoint` (when not auth/payments — see C), `new component`,
  `new view`, `add field` (non-sensitive)
- `refactor` (within a file), `simplify`, `consolidate`, `dedupe` (when
  scope ≤1 file)
- `caching` (non-sensitive data only), `pagination`, `sort order`,
  `filter`, `pagination cursor`

## Class C — High risk (NO auto-escalation, permanent Supervised)

Tasks that touch **cross-cutting concerns**, **shared state**, **security
boundaries**, or **data integrity surfaces**. Auth/payments/PII flows,
schema changes (even backward-compatible), migrations, public-API
contract changes, anything multi-file.

Trigger keywords (matching ANY single one is enough — Track C is
permanent supervised, so false-positives only cost a confirmation
click, not autonomy loss):

- `auth`, `authentication`, `authorization`, `oauth`, `oidc`, `saml`,
  `session`, `cookie` (when auth-related), `JWT`, `bearer`, `csrf`,
  `cors`
- `password`, `credential`, `token` (when secret), `api key`, `secret`,
  `vault`, `hsm`, `keychain`
- `payment`, `stripe`, `paypal`, `invoice`, `subscription`, `billing`,
  `charge`, `refund`, `chargeback`
- `PII`, `personal data`, `GDPR`, `CCPA`, `data subject`, `consent`,
  `opt-out`, `unsubscribe`
- `schema change`, `add column`, `drop column`, `rename column`,
  `alter table`, `index`, `unique constraint`, `foreign key`
- `migration`, `migrate`, `data migration`, `backfill`, `forward fill`
- `public API`, `breaking change`, `version bump` (major), `protocol`,
  `wire format`
- `RBAC`, `role`, `permission`, `policy`, `ACL`, `IAM`, `tenant`,
  `multi-tenant`, `isolation`
- `cross-phase`, `cross-cutting`, `shared state`, `global config`,
  `feature flag` (rollout-critical only)

## Class D — Irreversible (NO auto-escalation EVER, hard cap)

Tasks whose actions **cannot be safely rolled back** by `git revert`
alone or that require explicit user consent for ethical / regulatory
reasons. Deploys, force-pushes, schema-destructive migrations, secret
rotations, public announcements, telemetry-policy changes.

Trigger keywords (matching ANY → Track D; user approval mandatory):

- `deploy`, `release tag`, `production`, `prod env`, `prod database`,
  `prod cluster`, `promote to prod`
- `force-push`, `git push --force`, `rebase main`, `rebase master`,
  `--force-with-lease` (still Track D — lease helps but does not undo)
- `drop table`, `truncate`, `delete from` (without LIMIT in
  production-class), `wipe`, `purge`, `factory reset`
- `rotate secret`, `regenerate key`, `revoke token`,
  `invalidate session` (mass), `kill switch`
- `feature flag` (when killing live traffic; rollout-only is C)
- `data export to third party`, `share with vendor`,
  `outbound webhook` (new destinations)
- `email blast`, `mass notification`,
  `push notification (broadcast)`, `SMS campaign`
- `terms of service`, `privacy policy` (publication, not draft),
  `cookie banner change`, `consent flow change`
- `telemetry` (when changing what is collected), `analytics opt-in`,
  `tracking pixel` addition

## Task-type vocabulary (for M12 — orthogonal to risk class)

`new_code`: `add feature`, `implement`, `create new`, `green-field`,
`from scratch`, `new module`, `new service`.

`bug_fix`: `bug:`, `fix:`, `regression`, `crash`, `panic`,
`wrong result`, `off-by-one`, `null deref`, `race condition` (in tests;
in prod it is Track C).

`code_review`: `review PR`, `LGTM`, `code review`, `audit`,
`walk through changes`.

`refactor`: `refactor:`, `rename`, `extract`, `inline`, `consolidate`,
`simplify`, `restructure`, `move to`, `split file`.

`test_writing`: `add test`, `new test`, `test coverage`,
`cover edge case`, `integration test`, `e2e test`, `mutation test`,
`property test`.

`frontend`: `UI`, `component`, `style`, `CSS`, `Tailwind`, `shadcn`,
`React`, `Vue`, `Svelte`, `view`, `template`, `layout`, `responsive`,
`accessibility`, `a11y`, `WCAG`, `ARIA`.

## Conservative-default rules

1. **Multi-match → highest class wins.** A task whose description
   contains both `style:` (→A) and `auth` (→C) is Track C.
2. **Domain noun beats verb.** `change password reset email template`
   contains `email` (→D for blasts) AND `password` (→C). The
   classifier reads context: a template *change* is C (auth surface);
   an email *blast* is D (mass send). When in doubt → higher class.
3. **`is_irreversible_now` overrides everything.** A task may classify
   as C statically but execute as D dynamically (a generally reversible
   flag flip but THIS flip kills live traffic). The architect sets
   `is_irreversible_now: true` on the PLAN_META task; next.md treats
   it as Track D regardless of `task_class`.
4. **Architect uncertainty → bump up.** If the heuristic produces a
   confidence score below the architect-internal threshold, the
   architect must bump to the next-higher class. PLAN.md task 12.02
   §10: "False-positive rate target <5%" applies to upward
   misclassification, NOT downward — under-classifying is structurally
   riskier than over-classifying.

## How the auditor verifies architect classifications

After architect emits `task_class` for each task in PLAN_META.json, the
auditor performs a second-opinion pass:

1. Re-run the same keyword match on each task `name + spec_ref + files`.
2. Compare auditor class vs architect class.
3. **Auditor classifies higher → architect classification is
   over-permissive → bump to auditor class.** The conservative-higher
   rule applies symmetrically: between two classifiers, the higher
   wins.
4. **Auditor classifies lower → architect classification holds.** The
   architect saw something the auditor did not (e.g., spec excerpt that
   mentions a Track D surface only indirectly).

The auditor records its independent classification in
`.apex/phases/<phase>/AUDIT-CLASS.json` for telemetry; mismatches feed
the M16 telemetry stream so the keyword list itself can be tuned over
time.

## Negative space — what these keywords are NOT

- They are NOT a regex for code-review (the critic does that with
  diff + spec).
- They are NOT a substitute for THREAT_MODEL.md (M19 / 12.13 handles
  threat modeling proper).
- They are NOT scored — keyword presence is binary; the bump is class-
  level, not numeric.
- They do NOT pre-empt user override — a user can always force
  Track D approval via `/apex:status` annotation or the next.md
  EFFECTIVE_LEVEL=0 path.

## Updating this file

Adding a keyword: append to the relevant class section, then run
`bash framework/tests/test-task-class-autonomy.sh` to confirm no
existing classification flips inadvertently. The classifier allowlist
(in test fixtures) is checked against the keyword diff; fixture updates
land in the same PR.

Removing or moving a keyword between classes is a **Track C** change
(it changes runtime behavior of every future architect classification).
File the change as its own PLAN_META task, not as a doc-only edit.
