# Agents

Local agent definitions for this workspace.

## Local Agents

These are the maintained local agent prompts in this directory:
- `architect`
- `architecture-review-system`
- `auto-error-resolver`
- `build-error-resolver`
- `chief-of-staff`
- `code-refactor-master`
- `context-manager`
- `database-reviewer`
- `documentation-system`
- `frontend-developer`
- `frontend-error-fixer`
- `plan-reviewer`
- `research-search-system`
- `task-orchestrator`
- `ui-ux-designer`

## Plugin-Provided Agents

Several workflows in this repo also rely on installed plugin agents that do not live in this directory, including:
- `feature-dev:code-explorer`
- `feature-dev:code-architect`
- `feature-dev:code-reviewer`
- `superpowers:code-reviewer`
- `code-simplifier`

## Usage Guidance

- Use these as local prompts or subagent definitions only when their assumptions match the active task.
- The `task-orchestrator` agent is now a lightweight coordination reference, not the source of mandatory workflow policy.
- The Ralph sub-agents are vendored inside `.claude/skills/super-ralph/` and should be treated as part of that bundle, not as standalone top-level agents.

## Maintenance Rule

If an agent file describes tools or APIs that are not present in the current environment, update the file before relying on it.
