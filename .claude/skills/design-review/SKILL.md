---
name: design-review
description: Repo-local wrapper for visual review and polish. Use local browser tooling, keep fixes minimal, and never commit or push.
---

# Design Review

Use this skill for UI audit, visual polish, and fixing design issues in the current repo.

## Repo Rules

- Use local browser tooling when available.
- Never commit, push, or create a PR from this workflow.
- Ignore vendored gstack preambles, telemetry, and global-home setup.

## Workflow

1. Inspect the relevant UI state in code and in the browser.
2. Identify the highest-signal visual issues first.
3. Apply minimal fixes only when the task calls for changes.
4. Re-verify and report remaining risks.
