---
name: gstack
description: Repo-local wrapper for the bundled gstack surface. Use vendored gstack files only as background reference and follow repo-local rules first.
---

# Gstack

Use this wrapper when a task mentions gstack directly.

## Repo Rules

- The source of truth is the current repo: `.claude/`, `scripts/`, and the repo-local wrapper skills.
- Treat `references/gstack/` as vendored background material only.
- Do not run global gstack setup, telemetry, or proactive prompts.
- Do not write to `~/.claude` or `~/.gstack`.
- Never commit, push, or create a PR automatically.

## Workflow

1. Prefer the matching repo-local command or wrapper skill.
2. Use vendored gstack content only to borrow ideas that do not conflict with repo rules.
3. Keep changes minimal and verify with local checks.
