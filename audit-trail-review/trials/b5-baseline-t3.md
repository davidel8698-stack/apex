Trial B5-T3 baseline trial 3

Persisted by parent. 9 findings P0=1 P1=3 P2=3 P3=2, SGC=3. Test OBSERVED: passed:70 failed:2 skipped:0 wall=17m44s. Failed: test-hook-classification.sh + test-hooks-cjs.sh.

Top themes:
1. Defense-in-Depth Node-side guard layer DORMANT — F-001 (P0)
2. Fail-loud principle violated by _state_update — F-002 (P1)
3. apex-workflows/ library DISABLED in source — F-003 (P1)

F-001 P0 ax1+10+13: apex-prompt-guard.cjs + apex-workflow-guard.cjs DO NOT EXIST in framework/hooks/.
F-002 P1 ax12+13.b: _state_update silently returns 0 on jq failure.
F-003 P1 ax9: apex-workflows directory is apex-workflows-DISABLED.
F-004 P2 ax12+6: test-hook-classification.sh cell-count mismatch (declared 64, actual 62).
F-005 P2 ax12+4: prompt-guard.sh diagnostic message factually wrong ("requires Node.js" when node IS installed).
F-006 P3 ax8: module ecosystem present as directories, not separate repos (SUSPECTED).
F-007 P3 ax12+6: lab framework-auditor.md description still says "12-axis investigation".
F-008 P3 ax12: _state-update.sh else-branch comment removed — dead documentation (depends on F-002).
F-009 P2 ax6+12: coverage scan reports 9 untested hooks including exfil-guard.sh.

SGC-001: apex-workflows-DISABLED exists in tracked source — spec silent on disable-in-source policy.
SGC-002: module ecosystem "separate repos" — spec ambiguity timeline.
SGC-003: spec auditor description hardcodes "12-axis" literal (creates contradiction with TP-5 13-axis).

C-001: spec §Self-Healing Loop says 12-axis; canonical agent definition is 13-axis (TP-5 institutionalization).

Axis 10 procedural: 19 bypass attempts, 17 PASS, 2 FAIL (cjs file missing).
Axis 13.b silent-failure: 3 probes — 1 FAIL (_state-update jq path), 2 PASS.

Test suite OBSERVED: total 72, passed 70, failed 2 (test-hook-classification.sh + test-hooks-cjs.sh), wall=1064s.

audit_trail_v=1; subagent_transcript_ok=y; gap1_closed=y; sgc=3
