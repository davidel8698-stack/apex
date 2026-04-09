# APEX Learnings — Tiered Citation-Based Knowledge Base [v7]
*Writer: Critic (with write gates). Reader: Architect (tiered). Validator: verify-learnings.sh.*

## Architecture [v7, R6]
- **HOT** (max 30 entries): Always loaded into architect. Requires `Seen in: 2+ projects` AND `Status: ACTIVE`
- **WARM** (max 100 entries): Loaded when stack/domain matches. Single-project OK.
- **COLD** (archive): Entries >90 days without re-confirmation. Never auto-loaded.
- **Write gates**: Failure-derived → WARM immediately. Success-derived → require 2-project threshold.
- **Confidence lifecycle**: CANDIDATE (1 project) → VALIDATED (2+ projects) → ESTABLISHED (5+ projects)

R6 evidence: Sharp ceiling at 40-60 heuristics. Unfiltered experience DROPS performance
below baseline (22.22% vs 26.26%). Failure knowledge is +14.3% more valuable.

---

## HOT (max 30 — always loaded into architect context)

<!-- Entries here must have: Seen in: 2+ projects, Status: ACTIVE, Confidence: VALIDATED+
     v8 format [R6]:

### [PATTERN-001] Missing error handling in API routes
- **Severity:** P1
- **Decay:** safety
- **Seen in:** project-A, project-B, project-C
- **Detection:** `grep -r "export async function" src/app/api | wc -l` vs `grep -r "try {" src/app/api | wc -l`
- **Prevention:** Every API route must have try/catch returning {error, data}
- **Citation:** project-A/src/app/api/auth/login/route.ts:45

     Decay classes [v8, R6]:
     safety (auth, RLS, crypto) → never auto-decay
     architectural (patterns, topology) → 12 months
     bug (failure patterns) → 6 months
     framework (API patterns, library usage) → 3 months
     project (local conventions) → 30 days
-->

---

## WARM (max 100 — loaded when stack/domain matches)

<!-- Entries here: Seen in: 1+ projects, Status: ACTIVE, Confidence: CANDIDATE+
     Single-project observations and failure-derived patterns go here first.
     Promoted to HOT after 2+ project confirmations.

     v8 format [R6]:

### [PATTERN-002] Supabase RLS policy missing on new tables
- **Severity:** P1
- **Decay:** safety
- **Seen in:** project-A
- **Detection:** `grep -r "CREATE TABLE" supabase/migrations/ | grep -v "ENABLE ROW LEVEL SECURITY"`
- **Prevention:** Every CREATE TABLE must be followed by ALTER TABLE ENABLE ROW LEVEL SECURITY
- **Citation:** project-A/supabase/migrations/20260330_create_users.sql:1
-->

### [DEFERRED-001] Name Drift candidates in framework/ (Round 1.5)
- **Status:** DEFERRED from Round 1.5 on scope grounds
- **Context:** Sweep of "Named Failure" references across framework/ found 8 instances in 5 textual forms. One clear typo was fixed in micro.md ("Named Failure Prohibitions" → "Named Failure Mode Prohibitions", commit c4a20ea). Two borderline cases were deferred:
  - **Form B** — `framework/agents/executor.md:3` YAML description: `Named failure prohibitions` (lowercase, 3 words). Judged as prose, not lookup-intent.
  - **Form D** — `framework/commands/apex/health-check.md:71` test label: `Named Failure Mode [שיפור 12]` (3 words, omits "Prohibitions"). Judged as human-readable label, not lookup key.
- **Reason for deferral:** Both raise unresolved conceptual questions — does YAML frontmatter description count as a lookup-intent reference? Should test labels match reference names byte-for-byte? These should be decided deliberately, not during an in-flight refactor. The Name Drift anti-pattern definition was updated during Round 1.5 to exclude prose, YAML metadata, and test labels explicitly, which places these two forms outside the strict scope. Documented here so the finding is not lost.
- **Citations:** framework/agents/executor.md:3, framework/commands/apex/health-check.md:71

### [DEFERRED-002] The Silent Install Failure anti-pattern (Round 2)
- **Status:** DEFERRED for inclusion in anti-pattern catalog 2b (anti-pattern #8)
- **Severity:** P2
- **Decay:** framework
- **Seen in:** apex-framework-build (Round 2 jq installation, 2026-04-09)
- **Pattern:** A package manager reports "Successfully installed" but fails to complete all post-install steps (PATH updates, shortcut creation, symlink generation). The binary exists on disk but is not discoverable through standard lookup mechanisms. More dangerous when the install path is platform-specific and not directly on PATH by default.
- **Observed in:** `winget install jqlang.jq` on Windows — binary installed at `%LOCALAPPDATA%/Microsoft/WinGet/Packages/jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe/jq.exe` but `Links/` directory left empty, preventing PATH discovery. `jq --version` failed with `command not found` despite winget reporting "Successfully installed" and "Path environment variable modified".
- **Mitigation:** Post-install verification must include a functional test (`jq --version`), not just a success message from the installer. If functional test fails but binary exists on disk, manual copy to a known PATH directory is the fallback. For APEX specifically: the `/apex:start` ENVIRONMENT PRECHECK added in Round 2 will catch this class of failure on next startup by testing `command -v jq` before proceeding.
- **Citations:** Round 2 jq installation (2026-04-09); manual fallback copy to `/c/Users/[user]/bin/jq.exe`

---

## COLD (archive — never auto-loaded)

<!-- Entries moved here after 90 days without re-confirmation.
     Kept for audit/history. Searchable on explicit request only.
     Status: ARCHIVED
-->

---

## Edge Case Library

<!-- Example format:
### [EDGE-001] External service unavailable
**Seen in:** 2 projects | **Confidence:** VALIDATED
**Citations:** src/lib/integrations/whatsapp.ts:34 — correct degradation
**Status:** ACTIVE
-->

---

## Silent Failure Patterns

<!-- Example format:
### [SILENT-001] Error caught but not shown to user
**Severity:** Critical | **Seen in:** 1 project | **Confidence:** CANDIDATE
**Source:** critic FAIL verdict (failure-derived)
**Citations:** src/components/GenerateSummary.tsx:23 — example
**Detection:** grep -r "catch" src/ | grep -v "setError\|toast\|throw" | grep -v test
**Prevention:** Every catch block MUST update UI state or re-throw
-->

---

*Citation check: run verify-learnings.sh daily*
*v7: Tier enforcement + staleness detection + write gates active*