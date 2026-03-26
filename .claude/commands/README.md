# Commands

Custom slash commands for this workspace.

## Active Command Files

Available commands:
- `autoresearch.md`
- `build-fix.md`
- `careful.md`
- `checkpoint.md`
- `codex.md`
- `design-consultation.md`
- `design-review.md`
- `dev-docs-update.md`
- `dev-docs.md`
- `document-release.md`
- `freeze.md`
- `guard.md`
- `investigate.md`
- `multi-execute.md`
- `multi-plan.md`
- `office-hours.md`
- `orchestrate.md`
- `plan-ceo-review.md`
- `plan-design-review.md`
- `plan-eng-review.md`
- `qa.md`
- `qa-only.md`
- `quality-gate.md`
- `retro.md`
- `review-staff.md`
- `route-research-for-testing.md`
- `ship.md`
- `simplify.md`
- `super-ralph.md`
- `unfreeze.md`

`README.md` is documentation only.

## Notes

- Hook behavior comes from `.claude/hooks/`, not from synthetic commands like `ultra-think`.
- Gstack-backed and Super Ralph command wrappers should read the local `.claude/skills/` entries directly, so the tracked repo remains self-contained.
- If a command depends on a local skill or script, that dependency should resolve inside this repo first.
- `/multi-plan` and `/multi-execute` are repo-local workflows that use the bundled Codex bridge and installed plugin agents, not personal wrapper tooling.
- `/ship` is a release-readiness handoff in this repo. It does not authorize commit, push, or PR creation.
- `/super-ralph` is the local entry point for the bundled `super-ralph` workflow in `.claude/skills/super-ralph/`.
