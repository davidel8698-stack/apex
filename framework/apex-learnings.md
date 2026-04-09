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