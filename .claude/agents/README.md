# Agents

Local agent definitions for this workspace.

## Local Agents

Role agents, with the model and effort of each (see the Model roles rule of `.claude/CLAUDE.md`):
- `explorer` (Haiku 5.5, max: read-only search and the context pack)
- `runner` (Haiku 5.5, max: runs commands and reports)
- `designer` (Fable 5.2, xhigh: design notes, no code)
- `builder` (Opus 5.5, xhigh: large code)
- `writer` (Sonnet 5.5, max: small edits and small code)
- `verifier` (Opus 5.5, xhigh: verification of each delivery)
- `checker` (Fable 5.2, max: final verification once per push)

## Plugin-Provided Agents

Plugin-provided agents below become available only when their plugin is installed and enabled. Check the `enabledPlugins` block in `.claude/settings.json` or the local override at `.claude/settings.local.json` before invoking them. If a plugin is not installed, the agent will not resolve and the task should fall back to a local agent or a specialist Explore or Plan dispatch.

- `feature-dev:code-explorer`
- `feature-dev:code-architect`
- `feature-dev:code-reviewer`
- `superpowers:code-reviewer`
- `code-simplifier`

## Usage Guidance

- Use these as local prompts or subagent definitions only when their assumptions match the active task.
- `task-orchestrator` is for lightweight, interactive coordination. Use `/super-ralph` for fully autonomous multi-phase execution.
- The Ralph sub-agents live under `.claude/skills/super-ralph/agents/` and are part of that bundled workflow, not standalone top-level agents.

## Maintenance Rule

If an agent file describes tools or APIs that are not present in the current environment, update the file before relying on it.
