---
name: Bug report
about: Report a defect in an APEX command, agent, hook, skill, or workflow
title: "[BUG] "
labels: bug
assignees: ''
---

## Summary

<!-- One sentence: what's broken? -->

## Component affected

- [ ] Command (`framework/commands/apex/...`)
- [ ] Agent (`framework/agents/...`)
- [ ] Hook (`framework/hooks/...`)
- [ ] Skill (`framework/apex-skills/...`)
- [ ] Workflow (`framework/apex-workflows/...`)
- [ ] Schema (`framework/schemas/...`)
- [ ] Other / unsure

**Specific file(s):** <!-- e.g. framework/hooks/destructive-guard.sh -->

## Environment

- **APEX version / commit SHA:** <!-- e.g. v0.1.0 or commit abc1234 -->
- **Claude Code version:** <!-- run `claude --version` -->
- **Operating system:** <!-- Windows / macOS / Linux + version -->
- **Shell:** <!-- bash / zsh / pwsh + version -->

## Steps to reproduce

1. ...
2. ...
3. ...

## Expected behavior

<!-- What should have happened -->

## Actual behavior

<!-- What did happen -->

## Logs / artifacts

<!--
Helpful (please redact anything sensitive):
- The command you ran
- The exit code
- Relevant lines from .apex/event-log.jsonl
- Any error message
-->

```
<paste here>
```

## Has this worked before?

- [ ] Yes — first broke after commit / version: ___
- [ ] No — never worked for me
- [ ] Unsure

## Additional context

<!-- Anything else that might help -->
