---
description: PinScope self-healing loop — audit pinscope/ against its frozen North-Star, remediate gaps in dependency-ordered waves, verify, and repeat until converged. Usage: /ps-heal (heal to convergence) or /ps-heal once (single round).
---

<context>
## PURPOSE
Run the PinScope `PS-R{N}` self-healing convergence loop. One invocation of
this command drives the **entire repair mechanism** — audit → remediate →
wave → execute → verify → close — round after round, until PinScope converges
on its North-Star specification or a circuit breaker halts it.

Task / mode from $ARGUMENTS. If $ARGUMENTS contains `once`, run a single round
then stop; otherwise loop until the terminal condition.

## GUARD
- Run from the apex repo root. If `pinscope/SPEC.md` is missing:
  "❌ pinscope/SPEC.md not found." STOP.
- `pinscope/SPEC.md` must be `status: FROZEN`. If it is not:
  "❌ North-Star not frozen — freeze pinscope/SPEC.md before healing." STOP.
- The North-Star is **READ-ONLY**. NEVER edit `pinscope/SPEC.md`. The loop
  changes the `pinscope/` reality tree to match the spec, never the reverse.

## INPUTS
- North-Star: `pinscope/SPEC.md` — frozen; Appendix A is the 69 machine-checkable
  acceptance criteria; Appendix B is the loop contract.
- Dashboard: `pinscope/convergence/STATUS.md` — per-AC status + round metric.
- Remediation style: `framework/docs/REMEDIATION-STYLE.md`.

## PROCEDURE — one round, repeated until terminal

Determine round number N = (highest `PS-R{N}` in `STATUS.md`) + 1, then:

1. **Audit.** Diff every Appendix-A AC against the real `pinscope/` tree. Write
   `pinscope/convergence/audit-findings-R{N}.md`. Each finding carries: an id,
   the AC reference, severity, current state, and a **re-read verification
   step** — re-confirm the gap exists in current code before acting (APEX
   learning AP-006, "The Unchecked Audit"). Also re-run the carry-forward
   check (`cd pinscope && npm run typecheck && npm test`): any previously
   `CLOSED` AC that now fails is a new finding (regression).

2. **Terminal check.** If there are zero `OPEN` findings (every AC `CLOSED` or
   `BLOCKED`) and no regression: report "✅ CONVERGED — nothing to heal" with
   the current metric, and STOP. This is the correct no-op when PinScope is
   already healthy.

3. **Remediate.** Write `pinscope/convergence/REMEDIATION-PLAN-R{N}.md` per
   `framework/docs/REMEDIATION-STYLE.md` — content anchors (not line numbers),
   five mandatory sections per R-item.

4. **Wave.** Write `pinscope/convergence/WAVES-R{N}.md` — dependency-ordered,
   write-serial-safe (one file = one owner per wave; build module before
   runtime).

5. **Execute.** Implement each wave.

6. **Verify.** Run `cd pinscope && npm run typecheck && npm test`. For build /
   example / size criteria also run their specific checks (production build of
   `examples/vite-react` + `grep` of `dist/` for AC-010; `npx size-limit` for
   AC-073). Re-run the `verify:` check of every AC the round claims to close.
   **A claim without a passing check stays `OPEN`.** An AC whose `verify:`
   genuinely requires a browser engine or a `~/.claude/` APEX install that is
   unavailable in the environment is marked `BLOCKED` — never `CLOSED` from a
   weak proxy.

7. **Close.** Write `pinscope/convergence/WAVE-R{N}-RESULT.md` and
   `ROUND-R{N}-CLOSURE.md`; update `STATUS.md`. The convergence metric
   (`closed_AC / total_AC`) MUST be monotonically non-decreasing.

8. **Commit + push** the round to the current working branch.

9. If $ARGUMENTS contains `once`: STOP. Otherwise loop back to step 1 for
   round N+1.

## CIRCUIT BREAKER
Halt and escalate to the user if: a finding survives 3 consecutive rounds with
no status change, OR a wave fails verification 3 times. Do not mark the loop
converged when the breaker trips — report where it is stuck.

## TERMINAL CONDITION
The loop terminates when zero `OPEN` findings remain (every Phase-DoD AC is
`CLOSED` or `BLOCKED`). On termination, refresh
`pinscope/convergence/CONVERGENCE-REPORT.md`.

## OUTPUT
A concise report: starting % and ending %, rounds run this invocation, ACs
newly closed, any new `BLOCKED` entries (with what unblocks each), and the
terminal status.
</context>
