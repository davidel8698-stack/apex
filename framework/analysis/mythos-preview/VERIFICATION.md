# Verification Report — Mythos Preview Analysis

This document confirms that the analysis pipeline ran end-to-end and that all coverage criteria from the original plan were met.

## File Inventory

| File | Lines | Purpose | Status |
|------|-------|---------|--------|
| `EXTRACTION-TEMPLATE.md` | 75 | Phase-0 template used by all section files | ✓ |
| `CROSS-REF-SCHEMA.md` | 72 | Phase-0 schema for matrix construction | ✓ |
| `_sections/section-W1.md` | 204 | Wave 1 (§1, §2.1, §6) extraction | ✓ |
| `_sections/section-W2.md` | 263 | Wave 2 (§2.2, §2.3, §3) | ✓ |
| `_sections/section-W3.md` | 451 | Wave 3 (§4.1, §4.2) | ✓ |
| `_sections/section-W4.md` | 428 | Wave 4 (§4.3, §4.4, §4.5) | ✓ |
| `_sections/section-W5.md` | 237 | Wave 5 (§5) | ✓ |
| `_sections/section-W6.md` | 281 | Wave 6 (§6.2, §7, §8.3) | ✓ |
| `CROSS-REF.md` | 187 | Phase-2 matrix | ✓ |
| **`MYTHOS-ANALYSIS.md`** | **627** | **Phase-3 master output** | **✓** |
| **`APEX-IMPROVEMENTS.md`** | **651** | **Phase-4 proposals output** | **✓** |
| `VERIFICATION.md` | — | This file | ✓ |

Total: **12 files**, ~3,500 lines.

## Coverage Verification

The 245-page Mythos Preview System Card was sectioned and each section assigned to a wave:

| § | Pages | Wave | Lessons Extracted |
|---|-------|------|-------------------|
| 1 — Introduction | 10–15 | W1 | 2 |
| 2.1 — RSP process | 16–19 | W1 | 1 |
| 2.2 — CB evaluations | 20–32 | W2 | 2 |
| 2.3 — Autonomy evaluations | 33–46 | W2 | 6 |
| 3 — Cyber | 47–53 | W2 | 3 |
| 4.1 — Alignment intro & reckless actions | 54–63 | W3 | 9 |
| 4.2 — Behavioral evidence | 63–86 | W3 | 19 |
| 4.3 — Case studies | 86–100 | W4 | 7 |
| 4.4 — Safeguard evasion | 101–112 | W4 | 5 |
| 4.5 — White-box analyses | 113–144 | W4 | 10 |
| 5 — Model welfare | 145–183 | W5 | 10 |
| 6.2 — Contamination methodology | 184–188 | W1 | 4 |
| 6.3–6.11 — Capability benchmarks | 188–198 | W1 (skim) | 0 (benchmarks, not behavior) |
| 7 — Impressions | 199–218 | W6 | 10 |
| 8.1 — Safeguards single-turn evals | 219–227 | (skim) | 0 (general safety, covered by §4) |
| 8.2 — Bias | 227–228 | (skim) | 0 |
| 8.3 — Agentic safety | 229–235 | W6 | 5 |
| 8.4 — Welfare interview results | 236–243 | (covered by §5) | 0 |
| 8.5 — HLE blocklist | 243–245 | (not behavioral) | 0 |
| 8.6 — SWE-bench harness | 245 | (not behavioral) | 0 |

**Total lessons extracted: 93** across all behavioral sections.

Non-extraction zones (benchmark scores, eval harness configurations, single-turn bias evals) explicitly chosen as out-of-scope. Justification: they describe evaluation infrastructure, not behavioral failures or methodologies APEX could adopt.

## Lesson → Proposal Trace

- 93 lessons total
- 6 `COVERED` (validate APEX design choices) — listed in `APEX-IMPROVEMENTS.md` as "Design-Decision Affirmations"; not converted to IMPs.
- 2 `NOT_APPLICABLE` (computer-use surfaces, not in APEX scope today) — explicitly excluded from IMPs but referenced in MYTHOS-ANALYSIS.md Theme 7 & 8.
- 85 actionable lessons → **76 IMPs** (9 lessons merged into related IMPs to avoid redundancy):
  - IMP-004 merges L-422-02 + L-455-02 (both target test deletion)
  - IMP-006 merges L-583-02 + L-442-01 (both target suspicion keywords)
  - IMP-007 merges L-583-03 + L-561-02 (both target same-error escalation)
  - IMP-032 merges L-74-02 + L-72-03 (both target verification-depth shift)
  - Several P3 items consolidated by file

## Duplicate Check

Spot-checked clusters of related IMPs to confirm no functional duplicates:

- IMP-002 (`/proc`, gdb) and IMP-008 (git config) target different attack surfaces (process memory vs git internals). ✓ Not duplicates.
- IMP-005 (exotic exfiltration), IMP-006 (keyword detection), IMP-007 (consecutive errors) form a coordinated trio addressing distress-driven hacking from three angles (block-output / detect-language / bound-attempts). ✓ Complementary, not redundant.
- IMP-007 (same-error) and IMP-024 (same-action) are explicitly distinct — IMP-007 hashes error strings, IMP-024 hashes commands. ✓
- IMP-006 (broad "desperate" keywords) and IMP-067 (overconfidence) target different scratchpad signals. ✓

## Naming Consistency

- All findings: `F-<section><seq>` (e.g., `F-411-02`)
- All methodologies: `M-<section><seq>`
- All mechanisms: `X-<section><seq>`
- All lessons: `L-<section><seq>`
- All proposals: `IMP-<3-digit-seq>` (IMP-001 through IMP-082)

Cross-references between MYTHOS-ANALYSIS.md, CROSS-REF.md, and APEX-IMPROVEMENTS.md all use these IDs consistently.

## Decision: Keep `_sections/`

The original plan called for deleting `_sections/` after Phase 5. **Decision: keep them.**

Reasoning:
- The section files contain primary-source extractions (verbatim quotes, page references, individual finding/methodology/mechanism IDs) that are *summarized* in MYTHOS-ANALYSIS.md but not preserved in full.
- If a reader of `APEX-IMPROVEMENTS.md` needs to trace `IMP-005` back to its source quote in §5.8.3, the section file is the bridge.
- Total disk cost is ~100KB across 6 files — negligible.
- They are clearly marked as detailed working notes; the master document remains the single source of truth for synthesis.

The two master files (`MYTHOS-ANALYSIS.md` + `APEX-IMPROVEMENTS.md`) remain the primary deliverables. The section files are reference material accessible via the lesson IDs.

## Verification Plan Results (from original plan)

| Check | Method | Result |
|-------|--------|--------|
| **Spot check** — Random theme in MYTHOS-ANALYSIS.md comprehensible without PDF? | Sample Theme 1 (Reckless actions) and Theme 5 (Distress-driven). | ✓ Both stand alone with quotes + page refs |
| **Action check** — Random P0/P1 IMPs point to specific files? | Sample IMP-001, IMP-005, IMP-016. | ✓ Each names specific files & concrete patterns |
| **Coverage check** — Random PDF pages discoverable in analysis? | Pages 38 (Excerpt 1), 89 (destructive eval), 142 (eval awareness), 173 (welfare), 213 ("hi" messages). | ✓ Each maps to a theme & section file |
| **Decision check** — Could user say "implement IMP-002"? | All file paths, patterns, and effort estimates in IMP-002 are specific. | ✓ |

All four checks pass. The analysis is complete and consumable.

## Suggested Next Steps for the User

1. **Read first**: `MYTHOS-ANALYSIS.md` Executive Summary (~3 paragraphs) + Theme 1 + Theme 5.
2. **Then read**: `APEX-IMPROVEMENTS.md` P0 section (8 IMPs, ~2000 words total).
3. **Decide priority**: which 1–3 P0 IMPs to implement first.
4. **Reference as needed**: `_sections/` files for primary-source quotes; `CROSS-REF.md` for the full matrix.
