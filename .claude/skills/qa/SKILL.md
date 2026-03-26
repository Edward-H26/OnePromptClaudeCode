---
name: qa
description: Repo-local wrapper for browser QA with fixes. Use local browser tooling, keep fixes minimal, and never commit or push.
---

# QA

Use this skill to test the current application, fix issues, and verify the result.

## Repo Rules

- Use local browser tooling when available.
- Keep fixes minimal and tied directly to observed issues.
- Never commit, push, or create a PR from this workflow.
- Ignore vendored gstack telemetry and global-home setup.

## Workflow

1. Inspect the target surface and reproduce the issue in the browser.
2. Prioritize high-signal failures first.
3. Apply the smallest useful fixes.
4. Re-test and report fixes, evidence, and residual issues.
