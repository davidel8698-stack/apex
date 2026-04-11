# Threat Model — [PROJECT_NAME]

Created: [DATE]
Stack: [DETECTED_STACK]

## Default Threats

### T-001: Indirect Prompt Injection via Planning Artifacts
- **Description:** .apex/ files (SPEC.md, PLAN_META.json, RESULT.json) are read by all agents. A compromised or maliciously crafted artifact can steer agent behavior — changing plans, skipping tests, or injecting code.
- **Risk level:** HIGH
- **Attack vector:** Attacker modifies .apex/ files directly or via dependency that writes to project root.
- **Mitigation:** SPEC_VERSION hash drift detection. File integrity checks before agent reads. Destructive-guard hook blocks dangerous operations.
- **Status:** MITIGATED (partial — hash detection exists, full sanitization pending)

### T-002: Secret Exposure
- **Description:** API keys, tokens, credentials, or connection strings committed to repository or logged in agent output.
- **Risk level:** HIGH
- **Attack vector:** Secrets hardcoded in source, leaked via RESULT.json/SUMMARY.md, or exposed in CI logs.
- **Mitigation:** post-write.sh secret detection hook. .gitignore enforcement. Agent instructions prohibit logging secrets.
- **Status:** MITIGATED (partial — post-write detection active, no pre-commit scanning)

### T-003: Destructive Operations
- **Description:** Unintended execution of rm -rf, git push --force, DROP TABLE, terraform destroy, or similar irreversible commands.
- **Risk level:** HIGH
- **Attack vector:** Agent executes destructive command due to hallucination, drift, or prompt injection.
- **Mitigation:** destructive-guard.sh hook blocks known destructive patterns. Verify level D requires human confirmation.
- **Status:** MITIGATED (destructive-guard v7 active)

## Stack-Specific Threats

<!-- Populated based on detected stack during /apex:start -->
<!-- Examples below — keep only those matching your stack -->

### Web Applications
- **T-100: Cross-Site Scripting (XSS)** — User input rendered without sanitization.
- **T-101: SQL Injection** — User input interpolated into database queries.
- **T-102: CSRF** — State-changing requests without token validation.
- **T-103: Authentication Bypass** — Missing or weak auth checks on protected routes.

### API Services
- **T-200: Broken Access Control** — Missing authorization checks on endpoints.
- **T-201: Rate Limiting Absent** — No throttling on public-facing endpoints.
- **T-202: Mass Assignment** — Accepting unvalidated fields in request body.

### Data Pipelines
- **T-300: Data Exfiltration** — Sensitive data leaking to logs, monitoring, or third-party services.
- **T-301: Schema Poisoning** — Malformed input corrupting downstream data stores.

## Project-Specific Threats

<!-- Add threats specific to this project's domain and requirements -->
<!-- Format: T-4xx with Description, Risk level, Attack vector, Mitigation, Status -->

## Review Schedule

- Initial review: during /apex:start
- Update: at each phase boundary
- Full review: before production deployment
