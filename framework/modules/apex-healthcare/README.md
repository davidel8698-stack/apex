# apex-healthcare

**Status:** stub

Spec-named enterprise module. Scaffolded in R5-001 as a manifest + README placeholder so the discoverable shape exists. No agent prompt body yet.

## Future work

- Define `agent.md` with healthcare-domain invariants (HIPAA compliance, PHI redaction, audit-access logging, minimum-necessary disclosure, consent management).
- Add domain-specific verify commands (PHI-leak grep on logs, encryption-at-rest checks, access-audit completeness).
- Promote `status` to `active` in `manifest.json` and add `dispatch_aliases` once the agent ships.
