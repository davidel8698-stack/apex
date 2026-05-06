# apex-fintech

**Status:** stub

Spec-named enterprise module. Scaffolded in R5-001 as a manifest + README placeholder so the discoverable shape exists. No agent prompt body yet.

## Future work

- Define `agent.md` with fintech-domain invariants (PCI-DSS scoping, idempotent transactions, audit-trail immutability, signed-amount conventions, currency-precision rules).
- Add domain-specific verify commands (numeric-precision lints, transaction-isolation checks).
- Promote `status` to `active` in `manifest.json` and add `dispatch_aliases` once the agent ships.
