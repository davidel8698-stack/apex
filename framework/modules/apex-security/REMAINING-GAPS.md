# apex-security — Remaining Gaps Ledger

> **Status:** R7 F-002 **partial closure** (Phase 12.13, task M19).
>
> This file is the explicit ledger of security mechanisms that are
> *known to be partial* in the apex-security module as of Phase 12.13.
> R7 F-002 ("Security-Specialist Closure") closes the mechanisms listed
> as **Closed** below and explicitly *defers* the ones listed as
> **Gapped**. Adding a new mechanism that overlaps a gap below requires
> updating this file in the same PR.

## How this file is used

- Architect Step 1.11 ("Threat-Model Auto-Fill") cross-references this
  file from the generated `framework/modules/apex-security/threat-models/<task_id>.md`
  under section §5 "Known gaps". The auto-fill is *heuristic* — gaps
  here are the residual surface the heuristic does NOT cover.
- The verifier reads the **Gapped** section when deciding whether a
  Track C/D task with `negative_auth_required = true` can ship without
  manual review.
- The critic should flag any task whose `security_envelope` claims
  coverage of a capability listed under **Gapped** without an
  accompanying override file under
  `framework/modules/apex-security/threat-models/<task_id>.md`.

---

## Closed by Phase 12.13 (M19 / R7 F-002)

| # | Mechanism | Implementation | Verification |
|---|-----------|----------------|--------------|
| 1 | Per-task threat-model bootstrap | `THREAT_MODEL.template.md` + architect Step 1.11 | `test-security-specialist.sh` C-1, C-2 |
| 2 | ci-scan per-task debounce      | `ci-scan.sh` debounce gate via `.apex/.ci-scan-state.json` | `test-security-specialist.sh` C-3, C-4, C-5 |
| 3 | `security_envelope` schema slot | `PLAN_META.schema.json` additive field | `test-security-specialist.sh` C-6 |
| 4 | Negative-auth verifier check    | `verifier.md` enforcement (multilingual pattern) | `test-security-specialist.sh` C-7, C-8 |

## Gapped (deferred to a follow-up phase)

### G-1: Supply-chain scanning depth

`framework/hooks/ci-scan.sh` covers the four documented GitHub Actions
supply-chain vectors only (unpinned action, secret exposure in
`echo/printf/cat/>>`, `permissions: write-all`, unsafe
`pull_request_target` without explicit ref pinning). It does NOT
cover:

- npm / pip / cargo dependency confusion attacks
- Full SBOM generation and CVE cross-reference (no `osv-scanner`,
  `grype`, or `npm audit --production` integration)
- Lockfile poisoning detection (no diff-on-write check that flags
  unexpected transitive additions)

**Why deferred:** SBOM tooling is language-specific and would force the
framework to ship multi-runtime hooks (Node + Python + Rust minimum).
Threshold for inclusion: an APEX-managed project demonstrates a real
supply-chain incident traceable to one of the above categories.

**Until then:** projects that need dependency scanning wire it as a
separate CI job; APEX does not duplicate.

### G-2: Multi-tenant data isolation enforcement

The security-specialist's `agent.md` non-negotiables (tenant_id on every
query, RLS for Supabase, user A cannot access user B data) are
*advisory* — there is no PreToolUse hook that fails a Write when it
detects a SQL string lacking a `WHERE tenant_id =` clause. The
THREAT_MODEL.template.md §3 mitigation gate names the requirement but
does not enforce it at write time.

**Why deferred:** robust SQL parsing across multiple dialects (Postgres,
MySQL, SQLite, Supabase RLS DSL) is non-trivial; a naive grep produces
high false-positive rates that would erode trust in the guard.

**Until then:** verifier inspects critic notes for multi-tenant tasks;
the specialist's MANDATORY VERIFY COMMANDS include the
`grep -rn "findMany\|findAll\|SELECT" src/ | grep -v "tenant\|org\|team\|WHERE"`
sweep but it is per-task, not per-write.

### G-3: Encryption-at-rest enforcement

The agent prompt requires `bcrypt >= 12` for passwords, but APEX has
no hook coverage that fails a Write introducing a weaker algorithm or
a lower cost factor. Token storage (JWT secret, refresh-token table)
is similarly advisory only.

**Why deferred:** encryption choices depend on the chosen DB / KMS /
HSM; encoding the policy as a hook would require per-project config.

**Until then:** the specialist's domain-specific check #4
("Password/token storage") catches this at execution time; the
verifier flags missing coverage.

### G-4: Threat-model novel-vector coverage

The auto-fill in architect Step 1.11 matches `RISK-KEYWORDS.md`
literally. A novel attack vector that does not match any keyword
cluster slips through silently — the silent_failure_risks[0] in
PLAN_META.json task 12.13 names this exact failure mode.

**Why deferred:** novel-vector detection is a research problem (LLM-
based threat modeling, structured red-teaming) — outside the
mechanical scope of M19.

**Until then:** the critic SHOULD review every Track C/D auto-fill
output for missing-vector coverage and add `unresolved_risks` entries
to the task's CRITIC.md when novel vectors are suspected.

---

## Cross-references

- `framework/security-policy.md` §"Mechanism → Implementation Map" —
  the 6 defense-in-depth mechanisms (prompt-guard, path-guard,
  workflow-guard, ci-scan, security.cjs, destructive-guard). G-1 above
  partially extends mechanism #4 (CI scanner).
- `framework/docs/RISK-KEYWORDS.md` — keyword vocabulary the auto-fill
  consumes; G-4 above documents its inherent limit.
- `framework/modules/apex-security/agent.md` — the security-specialist
  prompt that holds the advisory rules G-2 and G-3 are deferring.
- `apex-spec.md` Failure 9 — the spec section that names the six
  mechanisms; this file documents which of them are *partial*.
