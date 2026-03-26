---
name: browse
description: Repo-local wrapper for browser workflows. Prefer the browser tooling available in this environment instead of global gstack browse setup.
---

# Browse

Use this skill when the task needs a real browser session or page inspection.

## Repo Rules

- Prefer the browser tooling already available in this environment.
- Do not assume a global `~/.claude/skills/gstack/browse` install or write to `~/.gstack`.
- Treat `references/gstack/` as background reference material only.

## Workflow

1. Use the locally available browser or Playwright tools first.
2. Keep the task scoped to the user request and the current repo.
3. Summarize browser findings and screenshots without inventing extra workflow steps.
