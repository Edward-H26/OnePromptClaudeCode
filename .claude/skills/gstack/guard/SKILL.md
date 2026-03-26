---
name: guard
description: Repo-local combined safety wrapper. Apply both careful and freeze behavior for high-risk tasks.
---

# Guard

Use this skill when the task needs both destructive-command caution and a strict edit boundary.

## Repo Rules

- Apply the `careful` and `freeze` behaviors together.
- Keep the scope local to the current repo and user request.
- Prefer blocking risky expansion over speed.
