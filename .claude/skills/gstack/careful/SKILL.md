---
name: careful
description: Repo-local safety wrapper for destructive operations. Warn before dangerous commands and follow the repo's no-commit, no-push rules.
---

# Careful

Use this skill when the task risks destructive commands or sensitive workflow mutations.

## Repo Rules

- Warn before destructive commands, history rewrites, or broad deletes.
- Follow repo policy: no commit, no push, no force-push, no reset-hard.
- Scope any cleanup or deletion to the smallest necessary target.
