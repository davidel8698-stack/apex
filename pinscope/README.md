# PinScope

A visual debug layer that wraps web applications during development and lets
non-technical users communicate UI changes to AI agents with total certainty —
without requiring professional vocabulary.

Point at an element carrying a visual label, read its numeric properties, and
send a structured operation. UI-change communication rounds drop from 5–10 to
1–2.

## Status

Built and converged by the **PinScope self-healing loop** (`PS-R{N}`) — 9
rounds, **62/69 acceptance criteria CLOSED (90%)**, 0 OPEN, 7 environment-
`BLOCKED`. 248 tests pass. See `convergence/CONVERGENCE-REPORT.md`.

- **`SPEC.md`** — the frozen north-star specification (the ideal state).
- **`convergence/`** — the loop's audit / remediation / wave / closure
  artifacts, `STATUS.md` (live dashboard), and `CONVERGENCE-REPORT.md`.

## Self-healing — re-running the loop

The convergence loop is a runnable command. It audits the `pinscope/` reality
tree against the frozen `SPEC.md`, remediates any gap (or regression) in
dependency-ordered waves, verifies, and repeats until converged.

```sh
# from the apex repo root — heal until converged
bash pinscope/convergence/self-heal.sh

bash pinscope/convergence/self-heal.sh --once     # run a single round
bash pinscope/convergence/self-heal.sh --verify   # mechanical re-verify only
```

Inside a Claude Code session the same loop is the `/ps-heal` slash command.
On an already-converged tree the loop is a safe no-op — it audits, confirms
zero gaps, and stops; it produces real work only when `SPEC.md` changes or a
regression appears.

## Relationship to APEX

PinScope is a sanctioned APEX extension. The `pinscope` APEX skill
(`framework/apex-skills/pinscope.md`) teaches APEX agents the Pin / Operation /
Snapshot model, and `/apex:ui-phase` scaffolds PinScope into the projects APEX
builds, so every APEX-built UI ships instrumented.

## License

MIT
