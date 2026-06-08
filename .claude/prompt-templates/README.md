# Prompt Templates

Prompt templates are pre-built starting points for common workflows. Copy a template into Claude Code, replace the `[PLACEHOLDERS]`, and the template activates the right skills, agents, and verification steps automatically.

## Quick Decision Guide

| You want to... | Use this template |
|----------------|-------------------|
| Build a feature from scratch | `feature-implementation.md` |
| Fix a bug | `debug.md` |
| Review, refactor, or audit code | `code-quality.md` |
| Implement a Figma design | `design-to-code.md` |

## When to Use Which

### feature-implementation.md
**Best for:** Feature work where you want a structured, interactive process with brainstorming, intent profiling, and checkpoint reviews. Placeholders cover task, directory, requirements, API, auth, Figma URL, target URL, and git history depth.

**Use when:** You are building or changing a feature and want explicit scoping and confirmation gates before autonomous work begins.

### debug.md
**Best for:** Single bugs or focused failures where you want a lightweight, targeted workflow. Forces root-cause analysis before any fix attempt, with optional scope freezing for safety.

**Use when:** The bug is contained, the fix is likely small, and you want disciplined hypothesis testing via the `investigate` skill.

### code-quality.md
**Best for:** Code review, targeted refactoring, or security audits on existing code. A `MODE` placeholder selects review, refactor, or security-audit, each with a focused workflow.

**Use when:** You want a quick, focused quality pass on a defined scope.

### design-to-code.md
**Best for:** Translating visual designs (Figma files or descriptions) into production code. Integrates the Figma plugin for design inspection and `ui-styling` for implementation.

**Use when:** You have a design to implement, whether from Figma, a description, or a reference screenshot.

## Skills Activated by Each Template

| Template | Skills Used |
|----------|-------------|
| **feature-implementation.md** | `search-first`, `frontend-dev-guidelines`, `backend-dev-guidelines`, `ui-styling`, `review`, `qa`, `webapp-testing`, `refine` |
| **debug.md** | `investigate`, `search-first`, `backend-dev-guidelines`, `frontend-dev-guidelines`, `ui-styling` |
| **code-quality.md** | `search-first`, `review`, `code-refactor`, `refine` |
| **design-to-code.md** | `search-first`, `frontend-dev-guidelines`, `ui-styling`, `figma` plugin, `frontend-design` plugin |

## How Templates Work

1. You fill in the placeholders and paste the template into Claude Code.
2. The `UserPromptSubmit` hook scans the prompt and suggests relevant skills from `skill-rules.json`.
3. The template instructions activate specific skills and workflows in sequence.
4. Post-completion steps guide you through verification and optional follow-ups.

Templates do not commit, push, or create PRs. The user owns all git operations.
