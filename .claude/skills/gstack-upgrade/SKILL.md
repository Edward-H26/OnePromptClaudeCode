---
name: gstack-upgrade
description: Repo-local wrapper for refreshing vendored gstack content. Refresh tracked references instead of mutating any global install.
---

# Gstack Upgrade

Use this skill only when the task is to refresh the vendored gstack snapshot tracked in this repo.

## Repo Rules

- The tracked vendored source lives under `references/gstack/`.
- Do not mutate `~/.claude/skills/gstack` or any global installation.
- Use `bash references/setup.sh` only as a repo-maintenance refresh step, then review the diff.

## Workflow

1. Refresh the vendored snapshot only when the task explicitly asks for it.
2. Review and harden the resulting diff against this repo's local rules.
3. Keep repo-local wrappers authoritative after the refresh.
