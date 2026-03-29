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
- `.claude/settings.local.example.json` is the tracked starting point for optional local plugin enablement and leaves those optional plugins disabled by default.
- Auth-sensitive or duplicate plugin integrations belong in `.claude/settings.local.json`, not the shared tracked config.
- `.claude/CLAUDE*.md`, `.claude/hooks/`, `.claude/commands/`, `.claude/prompt-templates/`, `.claude/agents/`, and `.claude/skills/` are maintained source files.
- `.claude/skills/` is the published workflow surface in this repo, including the bundled `gstack` and `super-ralph` content.
- Repo-local orchestration commands should rely on bundled scripts and installed plugins, not personal wrapper tooling in a machine-local Claude home directory.
- Root-level `projects/`, `file-history/`, `history.jsonl`, `statsig/`, `debug/`, `shell-snapshots/`, `sessions/`, `tasks/`, `usage-data/`, `paste-cache/`, and `cache/` are runtime data.
- Root-level `plugins/` is local plugin installation state and should not be published.
- Root-level `social/` is optional promotional material and is gitignored for workflow-only publishing.
- `.claude/runtime/` is repo-local ignored runtime state for safety flags, Codex home, and Codex artifacts.
- `references/gstack/`, `references/super-ralph/`, and `references/everything-claude-code/` are tracked vendored upstream sources. Repo-local wrapper skills and a smaller set of vendored passthrough skill entries use them as background material. `references/setup.sh` refreshes a curated subset and prunes upstream runtime-only artifacts that are not part of the published workflow surface.
- Runtime mirrors that appear under `.claude/` should be treated as disposable state unless explicitly documented as source.

## Current Inventory

- Local agent prompts live in `.claude/agents/`.
- Local slash-command wrappers live in `.claude/commands/`.
- Prompt templates live in `.claude/prompt-templates/`.
- `.claude/skills/` contains the maintained local skills and bundled workflow content used at runtime.
- Project hooks are registered through [settings.json](./settings.json).
- The shared tracked plugin set is intentionally smaller than a power-user local setup so fresh clones avoid duplicate MCP servers and missing-auth breakage.
- The published source intentionally includes the workflow code it needs at runtime, plus bundled `ui-styling` font assets.
- Run `bash references/setup.sh` only when you want to refresh the tracked vendored sources under `references/`.
- Run `bash scripts/audit-workflow.sh` after changing hooks, skills, commands, or vendored reference wiring.
- Run `bash scripts/doctor-workflow.sh` when you need a live readiness check for plugins, MCP connectivity, and Codex.

## Working Principles

1. Explore first, then edit.
2. Keep changes minimal and local to the task.
3. Prefer workflow guidance that matches the installed environment.
4. Keep maintained workflow assets inside this directory tree, not in machine-local install state.
5. Treat runtime state as disposable unless the user explicitly asks to preserve it.
