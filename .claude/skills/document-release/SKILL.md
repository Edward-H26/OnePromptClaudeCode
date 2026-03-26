---
name: document-release
description: Repo-local wrapper for release documentation updates. Sync docs to the shipped state without committing or pushing.
---

# Document Release

Use this skill when the workflow needs README, changelog, or release-note updates.

## Repo Rules

- Update tracked docs only when they are actually affected by the change set.
- Never commit, push, or create a PR automatically.
- Ignore vendored gstack steps that rely on `~/.gstack` or global installs.

## Workflow

1. Inspect the current repo diff and release-facing docs.
2. Update only the docs that drifted from actual behavior.
3. Stop at a clean handoff with any remaining manual release steps.
