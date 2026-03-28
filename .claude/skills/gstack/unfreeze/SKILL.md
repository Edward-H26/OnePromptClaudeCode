---
name: unfreeze
description: Repo-local wrapper for removing an active edit boundary in this repo.
---

# Unfreeze

Use this skill when the current task needs to remove a previously applied edit restriction.

## Repo Rules

- Only remove the boundary when the task clearly requires broader scope.
- Keep the change local to this repo.
- Do not alter any global gstack or home-directory state.

## Deactivation

This repo stores the active freeze boundary in `.claude/runtime/gstack/freeze-dir.txt`.

When this skill is invoked, remove that boundary with Bash:

```bash
rm -f "$CLAUDE_PROJECT_DIR/.claude/runtime/gstack/freeze-dir.txt"
echo "Freeze boundary removed for this repo session."
```
