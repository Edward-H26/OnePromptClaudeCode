> **Parent**: [CLAUDE.md](./CLAUDE.md) | **Related**: [CLAUDE-testing.md](./CLAUDE-testing.md), [CLAUDE-website-workflow.md](./CLAUDE-website-workflow.md)

# Claude Code Skills and Components

For the complete inventory of skills, commands, agents, hooks, plugins, MCP servers, and prompt templates, see [WORKFLOW-REFERENCE.md](./WORKFLOW-REFERENCE.md).

## Source vs Runtime

- **Source** (tracked): `.claude/CLAUDE*.md`, `hooks/`, `commands/`, `prompt-templates/`, `agents/`, `skills/`, `settings.json`
- **Runtime** (gitignored): `plugins/`, `projects/`, `shell-snapshots/`, `.claude/runtime/`, `.claude.json`, `settings.local.json`
- **Bundled source**: tracked skill directories under `skills/` are the published runtime surface for this repo.
- **Bundled assets**: `skills/ui-styling/canvas-fonts/` is intentionally tracked as part of the design workflow bundle.
- **Skill rules**: `skills/skill-rules.json` drives auto-suggestion via the `skill-activation-prompt.sh` hook.
- **Optional plugins**: auth-sensitive, duplicate, or machine-fragile integrations should be enabled through `.claude/settings.local.json`, not the shared tracked config.
- **Counts**: 34 skill entries declared in `skills/skill-rules.json`, all 34 backed by a local `SKILL.md` directory under `.claude/skills/`. The repo no longer vendors upstream skill content; every shipped skill is local. Run `python3 -c "import json; print(len(json.load(open('.claude/skills/skill-rules.json'))['skills']))"` to verify.
- **`effortLevel` semantics**: the `max` value in `settings.json` is session-only unless `CLAUDE_CODE_EFFORT_LEVEL` is also set in the `env` block. Setting both intentionally pairs declared intent with persistence. See https://code.claude.com/docs/en/model-config#adjust-effort-level
- **Streaming and thinking**: Anthropic recommends batch processing for thinking budgets above 32K tokens. Claude Code is interactive streaming, so keep `MAX_THINKING_TOKENS` at or below 32000 to avoid `Stream idle timeout` on long thinking phases. See https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
