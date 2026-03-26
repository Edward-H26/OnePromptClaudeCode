---
name: autonomous-loops
description: Repo-local wrapper for autonomous loop workflows. Prefer local orchestration commands and never rely on global Claude home state.
---

# Autonomous Loops

Use this skill only when the user explicitly asks for autonomous or self-running loops.

## Repo Rules

- Prefer repo-local orchestration flows such as `/super-ralph`, `/orchestrate`, `/multi-plan`, and `/multi-execute`.
- Treat vendored reference material as background only.
- Do not rely on `~/.claude`, `~/.gstack`, or any global session files.
- Never commit, push, or create a PR automatically.

## Workflow

1. Confirm the task is safe to run with delegated or looped execution.
2. Keep execution bounded to the current repo and the user's stated scope.
3. Use repo-local commands, hooks, and wrappers as the source of truth.
4. Return clear checkpoints, findings, and any remaining manual steps.
