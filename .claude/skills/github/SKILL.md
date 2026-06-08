---
name: github
description: Repo-local wrapper for the GitHub plugin. Use for repository inspection, pull requests, issues, review comments, and CI debugging.
---

# GitHub

Use this wrapper when a task mentions GitHub repositories, pull requests, issues, review comments, or GitHub CI.

## Repo Rules

- Prefer the GitHub plugin or `gh` CLI when available and authenticated.
- Do not commit, push, merge, or open pull requests automatically.
- Keep destructive or externally visible actions behind explicit user confirmation.

## Workflow

1. Identify the repository, issue, pull request, or CI run.
2. Inspect the relevant GitHub state through the plugin or `gh`.
3. Report findings or make local fixes without publishing changes unless the user explicitly asks.
