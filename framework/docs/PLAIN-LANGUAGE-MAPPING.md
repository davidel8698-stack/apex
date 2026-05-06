# Plain-Language Mapping

Spec anchors: "משתמש לא-טכני יכול להצליח איתה בסשן ובשעה הראשונה" — A non-technical user must succeed in their first session and first hour. "User-facing complexity is a 4-button menu, not a 14-toggle dashboard." Linked finding: F-015 (R5-015).

This document is the canonical jargon-to-plain-language map for APEX user-facing surfaces.

---

## Authoring rule (single source of truth)

When user-facing strings appear in:

- `framework/commands/apex/*.md` (headers, prompts, status messages, help text)
- stderr lines from `framework/hooks/circuit-breaker.sh`, `phantom-check.sh`, `schema-drift.sh` (and any other hook whose stderr is shown to the user)

apply this rule:

> **Plain language first, technical term in parens second.**
>
> Example: `Step 0: make sure tests can detect what we're about to fix (Nyquist Validation Layer)`
> NOT: `Wave 0: Nyquist Validation Layer`
> NOT: `Step 0: make sure tests can detect what we're about to fix` (loses searchability for technical users)

The parens form preserves grep-ability for senior/architect users while keeping non-programmers oriented. Both audiences win.

## Scope (what this rule does NOT touch — preservation contracts)

- **JSON schema field names** (`STATE.schema.json`, `WAVE_MAP.schema.json`, `PLAN_META.json`): unchanged. Field names are an internal API.
- **Variable names in shell/JS scripts** (`circuit-breaker.sh`, `_state-update.sh`, etc.): unchanged.
- **Test fixture file names and field names**: unchanged.
- **Internal log keys** in `session-log.sh` (`phantom_fail`, `coherence_fail`, `time_gate`, `wave_complete`, etc.): unchanged. These are event types consumed by `state-rebuild.sh` and the Cockpit Dashboard's decision filter.
- **Session-log Hebrew prose lines**: preserved verbatim (Live Ticker exception per `apex-branding.md`).
- **Comment lines `##` inside command markdown** that document orchestration logic for future maintainers: technical terms are allowed; the rule applies to text the user sees, not to executor-facing pseudocode.

## Mapping table

| Technical term (jargon) | Plain-language form (canonical) | Notes |
|---|---|---|
| Wave 0 | Step 0 (Wave 0) | Numeric meaning preserved; "step" is the universal word for stage. |
| Nyquist Validation Layer | tests-can-detect-the-fix layer (Nyquist Validation Layer) | The Nyquist analogy is poetic but opaque. The plain form names the actual function. |
| Nyquist | tests-can-detect-the-fix check (Nyquist) | Bare-word form for inline use. |
| TDAD | test-aware design index (TDAD) | TDAD = Test-Driven Architectural Design. Plain form names the artifact: an index that links tests to design. |
| AST-KB | code-structure knowledge base (AST-KB) | AST = Abstract Syntax Tree. "Code-structure" is the meaning a non-programmer can attach to. |
| phantom check | fake-completion check (phantom check) | "Phantom" is jargon. "Fake-completion" describes what's being detected. |
| phantom verification | fake-completion language (phantom verification) | Used when explaining what was caught. |
| schema drift | state file changed unexpectedly (schema drift) | "Schema drift" hides the user-relevant fact: a file APEX expected didn't have the fields it should. |
| circuit breaker | safety-stop (circuit breaker) | Plain term. The stop is what the user perceives; "circuit breaker" is mechanism vocabulary. |
| circuit-breaker triggered | safety-stop fired (circuit-breaker triggered) | |
| reflexion | retry-with-lessons-from-last-attempt (reflexion) | Reflexion is a research term; the plain form names the behavior. |
| dream-cycle | sleep-and-consolidate pass (dream-cycle) | "Dream-cycle" is metaphor. Plain form names the action: APEX consolidates memory between work bursts. |
| critic | reviewer (critic) | "Critic" is technical-pipeline vocabulary. "Reviewer" is everyday English / Hebrew. |
| executor | builder (executor) | "Executor" is pipeline vocabulary. "Builder" matches what the agent does for a non-programmer. |
| auditor | test-quality reviewer (auditor) | Plural reviewers in one pipeline; auditor specifically reviews tests. |
| coherence_fail | regression-between-tasks detected (coherence_fail) | Internal log key stays; user-visible explanation gets plain form. |
| spec drift | spec changed since last plan (spec drift) | Names the user-relevant fact. |
| tool-call cap | too-many-tool-calls cap (tool-call cap) | Plain form for non-programmers; tool-call still in parens for searchability. |
| no-change loop | stuck loop — no file changes (no-change loop) | Names the symptom in user terms. |
| forensics | timeline reconstruction (forensics) | Plain form for headers; the command name `/apex:forensics` stays. |
| walkthrough | guided explanation (walkthrough) | The command name stays; user-facing description uses plain form. |
| verify_level | rigor level (verify_level) | Plain word for the A/B/C/D ladder. |
| autopilot | hands-off mode (autopilot) | "Autopilot" is recognizable but framing as a mode helps non-programmers. |

## How to apply

1. Start with the PRIMARY user-facing text (headers, prompts, error messages the user reads).
2. Replace bare jargon with the plain-language form.
3. Append the technical term in parentheses on the same line for searchability.
4. Leave internal log keys and schema field names alone.
5. When a string appears multiple times in close proximity, the parens-form may be omitted on subsequent occurrences within the same block.

## Test

`framework/tests/test-plain-language.sh` greps user-facing sections of the command files for known bare-jargon (jargon NOT followed by parentheses). It reports any violation as a prioritized list. The test is informational on its first run — the goal is to prevent regression after the R5-015 sweep is applied.

## Non-goals

- This is not a translation layer. The mapping does NOT replace strings at render time based on `TECH_LEVEL`. The strings ARE the canonical user-facing form for every level. Senior/architect users get the same plain-language headers and read past the parens; they lose nothing.
- This is not a banned-word list for internal docs (`apex-spec.md`, design notes). Those are technical artifacts; jargon is acceptable there.
- This is not a globally-applied stylistic rewrite. The R5-015 sweep is targeted at the surfaces enumerated in REMEDIATION-PLAN-R5.md §R5-015.
