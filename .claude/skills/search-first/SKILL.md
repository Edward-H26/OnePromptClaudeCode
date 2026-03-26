---
name: search-first
description: Explore the current repo before editing. Search the codebase, settings, hooks, and docs first; use vendored references only as background context.
---

# Search First

Use this skill when the task starts with audit, review, exploration, or "find where this lives".

## Repo Rules

- Search the tracked repo-local workflow first: `.claude/`, `scripts/`, and the active project files.
- Treat `references/` as vendored background material, not the source of truth for this repo's behavior.
- Do not assume any global `~/.claude` install layout.

## Workflow

1. Search for relevant files, symbols, commands, hooks, and settings before proposing edits.
2. Prefer repo-local command wrappers, hook scripts, and docs over vendored upstream instructions.
3. Separate first-party findings from vendored-reference observations in your report.

## Preferred Tools

- `rg` for text search
- `find` or `rg --files` for file discovery
- targeted reads of the files most likely to control the behavior in question
