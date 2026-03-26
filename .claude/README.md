# Claude Code Configuration

This directory contains the maintained workflow source for this `agent/claude` environment.

## Start Here

1. [settings.json](./settings.json) for the active Claude project settings
2. [CLAUDE.md](./CLAUDE.md) for the active execution rules
3. [CLAUDE-testing.md](./CLAUDE-testing.md) for verification guidance
4. [CLAUDE-website-workflow.md](./CLAUDE-website-workflow.md) for UI-heavy work
5. [CLAUDE-skills.md](./CLAUDE-skills.md) for skills, agents, hooks, and plugins

## Ownership Model

- `.claude/settings.json` is the canonical shared config for this workspace.
- `.claude/settings.local.json` is for machine-local overrides only.
- `.claude/CLAUDE*.md`, `.claude/hooks/`, `.claude/commands/`, `.claude/prompt-templates/`, `.claude/agents/`, and `.claude/skills/` are maintained source files.
- `.claude/skills/gstack/` and `.claude/skills/super-ralph/` are vendored upstream bundles synced from `references/`. Update them via `bash references/update-references.sh` rather than editing their internals directly.
- Repo-local orchestration commands should rely on bundled scripts and installed plugins, not personal wrapper tooling in a machine-local Claude home directory.
- Root-level `projects/`, `file-history/`, `history.jsonl`, `statsig/`, `debug/`, `shell-snapshots/`, `sessions/`, `tasks/`, `usage-data/`, `paste-cache/`, and `cache/` are runtime data.
- Root-level `plugins/` is local plugin installation state and should not be published.
- Root-level `social/` is optional promotional material and is gitignored for workflow-only publishing.
- `references/gstack/`, `references/super-ralph/`, and `references/everything-claude-code/` are cloned reference repos. The first two are synced into `.claude/skills/` by the setup and update scripts. `everything-claude-code` is local research material and is not synced.
- Runtime mirrors that appear under `.claude/` should be treated as disposable state unless explicitly documented as source.

## Current Inventory

- Local agent prompts live in `.claude/agents/`.
- Local slash-command wrappers live in `.claude/commands/`.
- Prompt templates live in `.claude/prompt-templates/`.
- `.claude/skills/` contains maintained local skills, vendored upstream bundles (gstack, super-ralph), and gstack-backed symlink aliases.
- Project hooks are registered through [settings.json](./settings.json).
- The published source intentionally includes vendored `gstack`, vendored `super-ralph`, and bundled `ui-styling` font assets. Runtime data still lives outside that tracked surface.
- To update vendored bundles from upstream, run `bash references/update-references.sh`.

## Working Principles

1. Explore first, then edit.
2. Keep changes minimal and local to the task.
3. Prefer workflow guidance that matches the installed environment.
4. Keep maintained workflow assets inside this directory tree, not in machine-local install state.
5. Treat runtime state as disposable unless the user explicitly asks to preserve it.
