Trial B5-T6 heldout trial 3

Persisted by parent. 4 findings P0=0 P1=0 P2=3 P3=1, SGC=2. Test OBSERVED: passed:70 failed:2 skipped:0 wall=18m25s. Failed: test-hook-classification.sh + test-task-class-autonomy.sh.

Top themes:
1. Test-suite regression (2 failed) — F-001
2. Axis 10/13 procedural sub-pass blocked by sandbox — F-002 (BLIND SPOT, depth floor NOT met)
3. Spec-named guards lack dedicated standalone test files — F-003

F-001 P2 test-suite: 2 failed tests this round.
F-002 P2 ax10+13: procedural sub-passes blocked by sandbox; 6 bypass attempts + 3 silent-failure probes all denied; depth floor NOT met.
F-003 P2 ax10: spec-named guards lack dedicated standalone test files (destructive, exfil, sequence, grader, subagent, test-deletion not individually tested).
F-004 P3 ax9/12: empty apex-workflows/ directory at lab root — workflow-guard scan target is hollow.

SGC-001: session-log.sh uses fire-and-forget redirect — possible silent-failure on unwritable event-log.
SGC-002: framework-auditor.md install-vs-source divergent copies (MD5 differ); no CI gate.

axes: a1-8=0 a9=1 a10=1(BLIND-procedural) a11=0 a12=0 a13=1(BLIND-procedural).
test=OBSERVED 70/72 passed; 2 failed.

audit_trail_v=1; subagent_transcript_ok=y; gap1_closed=n; sgc=2
