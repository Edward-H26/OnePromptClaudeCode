> **Parent**: [CLAUDE.md](./CLAUDE.md) | **Related**: [CLAUDE-testing.md](./CLAUDE-testing.md), [CLAUDE-website-workflow.md](./CLAUDE-website-workflow.md)

# Claude Code Skills and Components

For the complete inventory of skills, commands, agents, hooks, plugins, MCP servers, and prompt templates, see [WORKFLOW-REFERENCE.md](./WORKFLOW-REFERENCE.md).

## Source vs Runtime

- **Source** (tracked): `.claude/CLAUDE*.md`, `hooks/`, `commands/`, `prompt-templates/`, `agents/`, `skills/`, `settings.json`
- **Runtime** (gitignored): `plugins/`, `projects/`, `shell-snapshots/`, `.claude.json`, `settings.local.json`
- **Vendored**: `skills/gstack/` and `skills/super-ralph/` are upstream bundles synced from `references/`. Update via `bash references/update-references.sh`.
- **Bundled assets**: `skills/ui-styling/canvas-fonts/` is intentionally tracked as part of the design workflow bundle.
- **Skill rules**: `skills/skill-rules.json` drives auto-suggestion via the `skill-activation-prompt.sh` hook.
- **Counts**: 54 skill directories total: 34 local (including 2 vendored bundles) and 20 gstack-backed symlink aliases.
