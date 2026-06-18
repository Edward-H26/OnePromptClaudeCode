# Commands

Custom slash commands for this workspace.

## Active Command Files

Available commands:
- `aiq-research.md`
- `backend-dev.md`
- `build-fix.md`
- `chrome-devtools.md`
- `code-refactor.md`
- `deep-research.md`
- `design-review.md`
- `frontend-dev.md`
- `investigate.md`
- `office-hours.md`
- `plan-design-review.md`
- `plan-eng-review.md`
- `qa-only.md`
- `refine.md`
- `remotion.md`
- `review-staff.md`
- `search-first.md`
- `ui-styling.md`
- `webapp-testing.md`

`README.md` is documentation only.

## Notes

- Hook behavior comes from `.claude/hooks/`, not from synthetic commands like `ultra-think`.
- Gstack-backed and Super Ralph command wrappers should read the local `.claude/skills/` entries directly, so the tracked repo remains self-contained.
- If a command depends on a local skill or script, that dependency should resolve inside this repo first.
