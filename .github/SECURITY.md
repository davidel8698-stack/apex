# Security Policy

## Reporting a vulnerability

If you discover a security vulnerability in APEX, **please do not open a public issue.** Instead:

1. Email **davidel8698@gmail.com** with the subject line `[APEX SECURITY] <short summary>`.
2. Include:
   - A description of the issue
   - Steps to reproduce
   - The affected component (command / agent / hook / skill / workflow)
   - The version or commit SHA you tested against
   - The potential impact

You will receive an acknowledgement within **72 hours**, and a status update within **7 days**.

## Disclosure timeline

- **Day 0** — report received and acknowledged.
- **Day 1–7** — initial triage; severity assigned (Critical / High / Medium / Low).
- **Day 7–30** — fix developed and tested.
- **Day 30+** — fix released; reporter credited (if they wish) in the release notes.

For Critical issues, we will move faster — typically a patch within 7 days.

## Supported versions

| Version | Supported |
|---------|-----------|
| 0.1.x   | ✅ active |
| < 0.1.0 | ❌ pre-release, no support |

Once APEX hits 1.0, the latest minor and the previous minor will both be supported.

## Threat model — what APEX defends against

APEX explicitly addresses these threats (see `apex-spec.md`, Failure 9):

1. **Indirect Prompt Injection** through planning artifacts (`SPEC.md`, `PLAN.md`, etc.).
2. **Path traversal** in file operations (Read, Write, Edit).
3. **Destructive commands** in agent-issued bash (rm -rf, force push, etc.).
4. **Workflow tampering** — adversarial workflow recipes.
5. **Secret leakage** — entropy-based scanning before commits.

Defense layers:

| Layer | Implementation |
|-------|----------------|
| Prompt-injection guard | `framework/hooks/prompt-guard.sh` |
| Path-traversal guard | `framework/hooks/path-guard.sh` |
| Workflow guard | `framework/hooks/workflow-guard.sh` |
| Destructive-command guard | `framework/hooks/destructive-guard.sh` |
| CI scanner | `framework/hooks/ci-scan.sh` |
| Shared policy library | `framework/hooks/_security-common.sh` |

For the full mechanism map, see [framework/security-policy.md](../framework/security-policy.md).

## What is *out of scope*

- Vulnerabilities in **Claude Code itself** — please report those to Anthropic.
- Vulnerabilities in third-party tools that APEX integrates with (Cursor, Copilot, etc.) — please report to those vendors.
- Issues that require physical access to the user's machine.
- Issues caused by the user disabling APEX hooks (`APEX_DISABLE_GUARDS=1` is documented as user-opt-out).

## Recognition

Security researchers who report valid vulnerabilities will be credited (with their permission) in:

- The release notes for the fix
- A `SECURITY-CREDITS.md` file (added once the first credit is earned)

Thank you for helping keep APEX safe.
