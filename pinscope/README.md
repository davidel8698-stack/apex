# PinScope

A visual debug layer that wraps web applications during development and lets
non-technical users communicate UI changes to AI agents with total certainty —
without requiring professional vocabulary.

Point at an element carrying a visual label, read its numeric properties, and
send a structured operation. UI-change communication rounds drop from 5–10 to
1–2.

## Status

This package is under construction. It is built and converged by the **PinScope
self-healing loop** (`PS-R{N}`):

- **`SPEC.md`** — the frozen north-star specification (the ideal state).
- **`convergence/`** — the loop's audit / remediation / wave / closure
  artifacts, and `STATUS.md`, the live convergence dashboard.

The loop audits the `pinscope/` reality tree against `SPEC.md` round by round,
closing the gaps in dependency-ordered waves until every acceptance criterion
in `SPEC.md` Appendix A passes.

## Relationship to APEX

PinScope is a sanctioned APEX extension. The `pinscope` APEX skill
(`framework/apex-skills/pinscope.md`) teaches APEX agents the Pin / Operation /
Snapshot model, and `/apex:ui-phase` scaffolds PinScope into the projects APEX
builds, so every APEX-built UI ships instrumented.

## License

MIT
