---
name: ship
description: Repo-local release-readiness workflow. Verify the repo, prepare a release handoff, and stop before commit, push, or PR creation.
---

# Ship

Use this skill for release readiness, not for automated git operations.

## Repo Rules

- Follow `.claude/CLAUDE.md`, `.claude/commands/ship.md`, and repo permissions first.
- Never commit, push, or create a PR automatically.
- Ignore vendored gstack preambles, telemetry, proactive prompts, and global-home plan discovery.

## Workflow

1. Inspect the current branch, diff, and release-facing files.
2. Run the smallest useful verification set for the release surface.
3. Update version or changelog files only when the task clearly requires it.
4. Stop at a release-ready handoff with exact user-run next commands.
