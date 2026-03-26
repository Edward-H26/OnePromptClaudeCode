---
name: review
description: Repo-local wrapper for code review. Findings first, grounded in the current repo, with no commit or push steps.
---

# Review

Use this skill for code review, bug finding, and regression detection.

## Repo Rules

- Findings come first.
- Review the current repo state, not a global gstack context.
- Never commit, push, or create a PR from this workflow.

## Workflow

1. Inspect the relevant diff or files.
2. Report the highest-severity findings first with evidence.
3. Only suggest fixes unless the user also asked for implementation.
