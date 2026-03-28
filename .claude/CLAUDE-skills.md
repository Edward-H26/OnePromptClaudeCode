> **Parent**: [CLAUDE.md](./CLAUDE.md) | **Related**: [CLAUDE-testing.md](./CLAUDE-testing.md), [CLAUDE-website-workflow.md](./CLAUDE-website-workflow.md)

# Claude Code Skills and Components

For the complete inventory of skills, commands, agents, hooks, plugins, MCP servers, and prompt templates, see [WORKFLOW-REFERENCE.md](./WORKFLOW-REFERENCE.md).

## Source vs Runtime

- **Source** (tracked): `.claude/CLAUDE*.md`, `hooks/`, `commands/`, `prompt-templates/`, `agents/`, `skills/`, `settings.json`
- **Runtime** (gitignored): `plugins/`, `projects/`, `shell-snapshots/`, `.claude/runtime/`, `.claude.json`, `settings.local.json`
- **Bundled source**: tracked skill directories under `skills/` are the published runtime surface for this repo, including the bundled `gstack` and `super-ralph` content.
- **Vendored references**: `references/` holds tracked upstream workflow sources that several repo-local wrapper skills and a smaller set of vendored passthrough entries consult as background material.
- **Bundled assets**: `skills/ui-styling/canvas-fonts/` is intentionally tracked as part of the design workflow bundle.
- **Skill rules**: `skills/skill-rules.json` drives auto-suggestion via the `skill-activation-prompt.sh` hook.
- **Optional plugins**: auth-sensitive or duplicate integrations should be enabled through `.claude/settings.local.json`, not the shared tracked config.
- **Counts**: 54 skill entries total, all available directly from the tracked repo surface.
