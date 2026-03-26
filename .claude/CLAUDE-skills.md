> **Parent**: [CLAUDE.md](./CLAUDE.md) | **Related**: [CLAUDE-testing.md](./CLAUDE-testing.md), [CLAUDE-website-workflow.md](./CLAUDE-website-workflow.md)

# Claude Code Skills and Components

For the complete inventory of skills, commands, agents, hooks, plugins, MCP servers, and prompt templates, see [WORKFLOW-REFERENCE.md](./WORKFLOW-REFERENCE.md).

## Source vs Runtime

- **Source** (tracked): `.claude/CLAUDE*.md`, `hooks/`, `commands/`, `prompt-templates/`, `agents/`, `skills/`, `settings.json`
- **Runtime** (gitignored): `plugins/`, `projects/`, `shell-snapshots/`, `.claude.json`, `settings.local.json`
- **Bundled source**: tracked skill directories under `skills/` are the published runtime surface for this repo, including the bundled `gstack` and `super-ralph` content.
- **Optional references**: `references/` holds local upstream comparison clones. It is not required for the tracked workflow to function.
- **Bundled assets**: `skills/ui-styling/canvas-fonts/` is intentionally tracked as part of the design workflow bundle.
- **Skill rules**: `skills/skill-rules.json` drives auto-suggestion via the `skill-activation-prompt.sh` hook.
- **Counts**: 54 skill entries total, all available directly from the tracked repo surface.
