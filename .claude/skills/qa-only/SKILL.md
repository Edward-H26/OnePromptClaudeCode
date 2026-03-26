---
name: qa-only
description: Repo-local wrapper for report-only QA. Inspect with browser tooling when available and do not make code changes.
---

# QA Only

Use this skill for browser-based QA when the task is report-only.

## Repo Rules

- Do not edit files in this workflow.
- Use local browser tooling when available.
- Ignore vendored telemetry and global-home setup.

## Workflow

1. Test the target surface.
2. Capture clear findings with reproduction steps and severity.
3. Return a report without applying fixes.
