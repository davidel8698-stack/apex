---
description: Refinement pipeline for improving existing code. Distinct from /apex:build.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

Task from $ARGUMENTS.

## PURPOSE
Dedicated pipeline for refining existing code — refactoring, performance optimization,
code quality improvement, and technical debt reduction. This is NOT for new features.

**Build vs. Refine:** Build creates new capabilities. Refine improves existing ones.
Different risk profiles, different verification strategies, different defaults.

## GUARD
If no .apex/STATE.json: "❌ No APEX project. Run /apex:start first." STOP.
If $ARGUMENTS is empty: "❌ /apex:refine requires a description of what to improve." STOP.

## PIPELINE MODE
Set in STATE.json: `"pipeline_mode": "refine"`

This flag tells downstream agents (architect, executor, verifier) to use refine defaults:
- Architect: decompose around existing code boundaries, not new feature boundaries
- Executor: mandatory regression tests for every change
- Verifier: diff-based verification (before/after comparison)

## EXECUTION

### Step 1: Existing Code Analysis
Before planning, analyze the target area:
- Read the code to be refined
- Identify current behavior, tests, and dependencies
- Capture baseline metrics where applicable (file size, complexity, test coverage)
- Document "before" state for diff-based verification later

### Step 2: Improvement Identification
Classify the refinement type:
- **Refactoring** — restructure without changing behavior (extract, rename, simplify)
- **Performance** — optimize speed, memory, or resource usage
- **Quality** — improve readability, reduce duplication, fix code smells
- **Debt** — upgrade dependencies, remove deprecated patterns, modernize

### Step 3: Plan Phases
Route to architect with refine context:
- Default verify_level: **B** (standard rigor — refine is lower risk than build)
- User can override to C/D for critical refactors
- Each phase MUST include regression test requirements
- Phases should be structured around code boundaries (modules, files, layers)

### Step 4: Execute with Regression Guard
Route to /apex:next with pipeline_mode = refine.
- Executor MUST run existing tests before AND after each change
- If any existing test breaks → STOP, revert, report
- New tests are optional but regression tests are mandatory

### Step 5: Diff-Based Verification
Verifier compares before/after state:
- Behavioral equivalence: same inputs → same outputs (for refactoring)
- Performance delta: measurable improvement (for optimization)
- Quality delta: reduced complexity, fewer code smells (for quality)
- No regression: all pre-existing tests still pass

## KEY DIFFERENCES FROM BUILD
| Aspect | Build | Refine |
|--------|-------|--------|
| Input | New feature description | Existing code to improve |
| Spec | Creates new SPEC.md | Uses existing spec |
| Default verify_level | C (high rigor) | B (standard rigor) |
| Test strategy | Feature tests + regression | Regression only (mandatory) |
| Verification | Feature-based (does it work?) | Diff-based (what changed?) |
| Phase structure | Feature boundaries | Code boundaries |
| Risk profile | Higher (new code) | Lower (existing code) |

NOTE: For new features → use /apex:build or /apex:full.
For trivial tasks → use /apex:fast.
For small tasks → use /apex:quick.
</context>
