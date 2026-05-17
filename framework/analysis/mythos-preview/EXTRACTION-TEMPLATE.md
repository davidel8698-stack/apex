# Extraction Template — Mythos Preview Section Analysis

Each `_sections/section-<N>.md` file MUST follow this template. Consistency enables Phase 2 aggregation.

---

## Section Identifier

# §<N>.<sub> — <Title>

## Coverage

- **Pages**: <start>–<end>
- **Effective relevance to APEX**: `LOW` | `MEDIUM` | `HIGH` | `CRITICAL`
- **Reader time**: <estimated minutes>

## Key Findings

Use `[F-<section><seq>]` IDs. Example: F-411-01 = Section 4.1.1, first finding.

- **[F-XXX-NN]** **<short title>**
  - Quote (≤2 lines verbatim if illuminating): "…"
  - Numbers: <X%, N transcripts, etc.>
  - Significance: <why this matters for an autonomous coding pipeline>

## Methodologies

How Anthropic evaluated the behavior. APEX can potentially reuse these patterns.

- **[M-XXX-NN]** **<methodology name>**
  - Setup: <what they did, what the model saw>
  - Scoring: <how they judged success/failure>
  - Reusable for APEX? <yes/no/maybe + brief reason>

## Mechanisms

Detection/prevention/mitigation tools Anthropic used or recommends.

- **[X-XXX-NN]** **<mechanism name>**
  - Purpose: <what it stops or detects>
  - How it works: <1–3 sentence summary>
  - Anthropic effectiveness: <if reported>

## Lessons for APEX

The actionable extraction. Use `[L-<section><seq>]` IDs.

- **[L-XXX-NN]** **<lesson summary>**
  - Source finding(s): F-XXX-NN
  - APEX components touched: <comma-separated list, e.g. `executor.md`, `destructive-guard.sh`>
  - Initial coverage hypothesis: `COVERED` | `PARTIAL` | `MISSING` | `NOT_APPLICABLE`
  - Initial priority guess: `P0` | `P1` | `P2` | `P3`
  - Brief rationale: <1–2 lines>

## Open Questions / Cross-Section Refs

Notes that should be revisited when other sections are read, or that need APEX domain knowledge to resolve.

- **[Q-XXX-NN]** <question>

---

## ID Convention

- `F-XXX-NN` = Finding from section XXX, sequence NN
- `M-XXX-NN` = Methodology
- `X-XXX-NN` = Mechanism
- `L-XXX-NN` = Lesson for APEX (this is the main output)
- `Q-XXX-NN` = Open question

XXX is the section number compacted: §4.1.1 → 411, §2.3.5.2 → 2352, §8.3.1.1 → 8311.

NN is a 2-digit zero-padded sequence within the section.

Every Lesson **must** trace back to at least one Finding (`Source finding(s)`).
