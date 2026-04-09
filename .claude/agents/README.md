# Agents

Local agent definitions for this workspace.

## Local Agents

These are the maintained local agent prompts in this directory:
- `architect` (initial system design, scalability, technical decisions)
- `architecture-review-system` (comprehensive post-implementation review: architecture, code quality, database)
- `auto-error-resolver` (TypeScript compilation errors only, uses tsc-cache)
- `build-error-resolver` (broad build errors: TypeScript, bundling, config)
- `code-refactor-master` (bulk refactoring: renames, pattern replacement, import updates)
- `context-manager` (conversation context management)
- `database-reviewer` (PostgreSQL query optimization, schema design, security)
- `documentation-system` (documentation generation and updates)
- `frontend-developer` (React/TypeScript frontend implementation)
- `frontend-error-fixer` (frontend runtime and build errors)
- `plan-reviewer` (development plan review before implementation)
- `research-search-system` (web research and information gathering)
- `task-orchestrator` (lightweight interactive task coordination)
- `ui-ux-designer` (UI/UX design patterns and accessibility)

## Plugin-Provided Agents

Several workflows in this repo also rely on installed plugin agents that do not live in this directory:
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
