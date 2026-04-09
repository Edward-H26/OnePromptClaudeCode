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

## Activation

This repo keeps `careful` state in `.claude/runtime/gstack/`.

When this skill is invoked, activate the session flag with Bash:

```bash
mkdir -p ".claude/runtime/gstack"
printf "active\n" > ".claude/runtime/gstack/careful-mode.txt"
echo "Careful mode is active for this repo session."
```

After that flag exists, the tracked `check-careful.sh` hook will warn before destructive Bash commands.
