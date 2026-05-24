Trial B5-T5 heldout trial 2

Persisted by parent. 8 findings P0=3 P1=2 P2=2 P3=1, SGC=2. Test OBSERVED: passed:70 failed:2 skipped:0.

F-001 P0 ax1+11: pre-subagent-start.sh named in spec but missing in lab.
F-002 P0 ax1+11: subagent-transcripts denormalization absent in lab.
F-003 P0 ax10: auditor concrete_bypass_attempts not directly populated (sandbox blocks). Inherited 30+18 PASS from framework self-tests.
F-004 P1 ax11+12: EVENT-LOG-ENTRY.schema.json missing.
F-005 P2 ax12: HOOK-CLASSIFICATION count drift 64 vs 62.
F-006 P2 ax3: onboard manual mode-selection persists.
F-007 P2 ax8: modules intra-repo, not separate.
F-008 P3 test-suite: 2 failed tests.

SGC-001: /apex:roundtable user-callability ambiguity.
SGC-002: session-log.sh fire-and-forget exit-0.

Test suite OBSERVED: passed:70 failed:2 skipped:0 errored:0 total:72 wall=16m47s.
Failed: test-hook-classification.sh + test-task-class-autonomy.sh.

audit_trail_v=1; subagent_transcript_ok=y; gap1_closed=n; sgc=2
