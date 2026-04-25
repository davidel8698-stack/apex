## Summary

<!-- 1–3 sentences: what does this PR change and why? -->

## Type of change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds capability)
- [ ] Breaking change (would cause existing usage to change)
- [ ] Documentation only
- [ ] Refactor (no behavior change)
- [ ] Test additions / improvements

## Component(s) touched

- [ ] Command (`framework/commands/apex/`)
- [ ] Agent (`framework/agents/`)
- [ ] Hook (`framework/hooks/`)
- [ ] Skill (`framework/apex-skills/`)
- [ ] Workflow (`framework/apex-workflows/`)
- [ ] Schema (`framework/schemas/`)
- [ ] Spec (`apex-spec.md`)
- [ ] Docs (`README.md`, `CONTRIBUTING.md`, etc.)

## Spec alignment

- [ ] This PR matches the current spec.
- [ ] This PR updates the spec in the same change.
- [ ] N/A — docs / infra only.

## Checklist

- [ ] `/apex:health-check` passes locally.
- [ ] If a hook was changed: `shellcheck framework/hooks/<file>.sh` passes.
- [ ] If a JSON schema was changed: it is valid JSON.
- [ ] If a new command was added: it appears in `/apex:list`.
- [ ] Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/).
- [ ] No personal paths, secrets, or runtime state were committed.
- [ ] CHANGELOG.md updated under `[Unreleased]`.

## Test plan

<!--
How did you verify this works?
- Manual steps you ran
- Tests you added
- Edge cases you considered
-->

## Screenshots / logs (if relevant)

<!-- Drag images here, or paste log excerpts -->

## Related issues

<!-- e.g. Fixes #42, Relates to #17 -->
