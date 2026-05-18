# THREAT_MODEL — {{TASK_ID}}

> **Auto-generated.** This file is produced by the architect at planning
> time (Step 1.11 in `framework/agents/architect.md`) for every task whose
> classification triggers threat-model generation. Hand-edit only if you
> are intentionally overriding the auto-fill — and record the override in
> `DECISIONS.md` so the auditor sees it.
>
> Generation contract:
>   Source template: `framework/modules/apex-security/THREAT_MODEL.template.md`
>   Trigger gate: `task.task_class ∈ {C, D}` AND
>                 `task.task_type ∈ {auth, payments, multi-tenancy,
>                  encryption}` (matched via
>                 `framework/docs/RISK-KEYWORDS.md`).
>   Output path: `framework/modules/apex-security/threat-models/<task_id>.md`
>   Companion field: `task.security_envelope` in `PLAN_META.json`.
>
> **Failure-loud rule (M19 / Phase 12.13).** When the trigger gate fires
> but the RISK-KEYWORDS match is ambiguous, the architect MUST emit this
> file with `{{MATCHED_RISK_KEYWORDS}}` populated by the partial match AND
> add an entry to `unresolved_risks` in the task's RESULT.json. Silent
> substitution of a generic template (without the actual matched keywords
> being recorded) is the prohibited failure mode — see
> `silent_failure_risks[0]` in PLAN_META.json task `12.13`.

---

## 1. Task identifier

- **Task ID:** {{TASK_ID}}
- **Task name:** {{TASK_NAME}}
- **Phase:** {{PHASE_ID}}
- **Generated at:** {{GENERATED_AT_ISO8601}}

## 2. Classification

- **task_class:** {{TASK_CLASS}}    (one of A | B | C | D — see RISK-KEYWORDS.md)
- **task_type:**  {{TASK_TYPE}}     (one of auth | payments | multi-tenancy | encryption | new_code | bug_fix | …)
- **Matched RISK-KEYWORDS:** {{MATCHED_RISK_KEYWORDS}}
  - These are the keywords from `framework/docs/RISK-KEYWORDS.md` that
    tripped the trigger gate for this task. If the list reads `["__AMBIGUOUS__"]`
    the architect could not confidently match a single keyword cluster —
    treat the auto-fill below as a stub and review manually.

## 3. Attack surfaces (simplified STRIDE)

For each surface the task touches, the architect ticks the applicable
threats. Untouched surfaces are removed (not left as no-op rows) so the
file reads as a contract, not a checklist of irrelevant rows.

- **Spoofing — identity / auth bypass**
  - Touches authentication credentials, session cookies, or tokens?
  - Mitigation gate: `negative_auth_required = true` must hold for the task
    and at least one test must match the
    `deny|denied|unauthorized|forbidden|reject|401|403` pattern
    (see verifier.md negative-auth enforcement).
- **Tampering — integrity of stored / in-flight data**
  - Touches DB writes, schema migrations, payment objects?
  - Mitigation gate: parameterized queries only; signed payloads at trust
    boundaries.
- **Repudiation — audit trail loss**
  - Touches actions that need provable history (payment, consent,
    deletion)?
  - Mitigation gate: append-only audit log; user_id + tenant_id on every
    write.
- **Information disclosure — leak of secrets / PII**
  - Touches secret storage, error messages, logs, response bodies?
  - Mitigation gate: env-var secrets only; PII never in logs; error
    messages do not echo internal state.
- **Denial of service — auth / payment endpoints under flood**
  - Touches login, password reset, OTP, checkout, webhook receivers?
  - Mitigation gate: rate limiting per IP + per user; idempotency keys on
    payment writes.
- **Elevation of privilege — tenant boundary or role boundary crossing**
  - Touches RBAC, tenant filter, multi-tenant query path?
  - Mitigation gate: `WHERE tenant_id = $param` or RLS on every read/
    write; user A cannot access user B data (verified by paired
    positive + negative test).

## 4. Negative-auth test requirements

Listed below are the negative-auth tests this task MUST ship. The
verifier promotes the task to PARTIAL if none of the patterns in
`tests_run[].name` match the negative-auth regex
(`/(deny|denied|unauthorized|unauthorised|forbidden|reject|rejected|invalid_token|401|403)|\b(לא[ -]מורש|נדחה|אסור|חסום)\b/i`).

- {{NEGATIVE_AUTH_TESTS}}
  - The architect populates this list from
    `task.security_envelope.required_capabilities`. At minimum one entry
    is required when `task.negative_auth_required = true`.

## 5. Known gaps (cross-reference)

Threat-model auto-fill is heuristic. The following residual risks are
documented in `framework/modules/apex-security/REMAINING-GAPS.md` and
explicitly NOT covered by the auto-fill above:

- Supply-chain scanning depth — `ci-scan.sh` covers GitHub Actions
  vectors only, not full SBOM.
- Multi-tenant data isolation gates — currently document-only (no
  PreToolUse hook).
- Encryption-at-rest enforcement — no hook coverage.
- Novel attack vectors — auto-fill matches RISK-KEYWORDS literally; a
  novel vector that does not match any keyword cluster slips through
  silently. The critic SHOULD review every Track C/D auto-fill output
  for missing-vector coverage.

If a gap above blocks the task, route the task to manual threat-model
review (architect reads `REMAINING-GAPS.md` and writes a per-task
override under `framework/modules/apex-security/threat-models/<task_id>.md`
with the standard auto-fill REPLACED, not appended).
