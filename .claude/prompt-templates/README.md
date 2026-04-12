# Prompt Templates

Prompt templates are pre-built starting points for common workflows. Copy a template into Claude Code, replace the `[PLACEHOLDERS]`, and the template activates the right skills, agents, and verification steps automatically.

## Quick Decision Guide

| You want to... | Use this template |
|----------------|-------------------|
| Build a feature from scratch | `super-ralph.md` (type: feature) or `feature-implementation.md` |
| Fix a bug | `debug.md` or `super-ralph.md` (type: debug) |
| Refactor code safely | `code-quality.md` (mode: refactor) or `super-ralph.md` (type: refactor) |
| Review code for issues | `code-quality.md` (mode: review) or `super-ralph.md` (type: review) |
| Run a security audit | `code-quality.md` (mode: security-audit) or `super-ralph.md` (type: security-audit) |
| Implement a Figma design | `design-to-code.md` |
| Run a full sprint cycle | `gstack-sprint.md` |
| Fully autonomous execution | `super-ralph.md` (mode: oneshot) |

## When to Use Which

### super-ralph.md
**Best for:** Large, multi-file tasks where you want fully autonomous execution with specialized agents, test-first development, and self-debugging. Supports all task types (feature, debug, refactor, review, security-audit) and two modes (oneshot for zero-setup, brainstorm for interactive Q&A).

**Choose over feature-implementation.md when:** You want Ralph's 5-agent pipeline (tester, worker, debugger, judge, merger) to handle everything autonomously after a brief setup.

**Choose over debug.md when:** The bug spans multiple files or systems and benefits from multi-agent decomposition and cold root-cause analysis via `ralph-debugger`.

**Choose over code-quality.md when:** The review or refactor is large enough to benefit from parallel agent execution and automated quality gating via `ralph-judge`.

### feature-implementation.md
**Best for:** Feature work where you want a structured, interactive process with brainstorming, intent profiling, and checkpoint reviews. More hands-on than super-ralph, with explicit user confirmation gates.

**Choose over super-ralph.md when:** You want more control over each phase, or the task needs careful interactive scoping before any autonomous work begins.

### debug.md
**Best for:** Single bugs or focused failures where you want a lightweight, targeted workflow. Forces root-cause analysis before any fix attempt, with optional scope freezing for safety.

**Choose over super-ralph.md when:** The bug is contained, the fix is likely small, and multi-agent overhead would slow you down.

### code-quality.md
**Best for:** Code review, targeted refactoring, or security audits on existing code. Three modes (review, refactor, security-audit) each with a focused workflow.

**Choose over super-ralph.md when:** You want a quick, focused pass rather than full autonomous decomposition.

### design-to-code.md
**Best for:** Translating visual designs (Figma files or descriptions) into production code. Integrates Figma MCP, `ui-ux-pro-max` for design system generation, and `ui-styling` for implementation.

**Use when:** You have a design to implement, whether from Figma, a description, or a reference screenshot.

### gstack-sprint.md
**Best for:** A structured Think, Plan, Build, Review, Test, Ship, Reflect cycle. Good for medium-sized tasks that benefit from a disciplined phase progression.

**Choose when:** You want sprint discipline without full multi-agent autonomy.

## Template Complexity Spectrum

```
Lightweight ─────────────────────────────────── Heavyweight

debug.md  code-quality.md  design-to-code.md  gstack-sprint.md  feature-implementation.md  super-ralph.md
  (1 bug)    (focused pass)   (1 design)         (sprint)          (interactive feature)     (autonomous)
```

## Skills Activated by Each Template

| Template | Skills Used |
|----------|------------|
| **super-ralph.md** | `search-first`, `postgres-patterns`, `investigate`, `code-refactor`, `security-review`, `security-scan`, `backend-dev-guidelines`, `frontend-dev-guidelines`, `ui-styling`, `ui-ux-pro-max`, `shadcn-ui`, `liquid-glass-design`, `docker-patterns`, `deployment-patterns`, `claude-api`, `tdd-workflow`, `e2e-testing`, `python-testing`, `design-consultation`, `verification-loop` |
| **feature-implementation.md** | `search-first`, `frontend-dev-guidelines`, `ui-styling`, `ui-ux-pro-max`, `shadcn-ui`, `backend-dev-guidelines`, `postgres-patterns`, `security-review`, `tdd-workflow`, `e2e-testing`, `verification-loop` |
| **debug.md** | `investigate`, `search-first`, `backend-dev-guidelines`, `frontend-dev-guidelines`, `ui-styling`, `security-review`, `security-scan` |
| **code-quality.md** | `search-first`, `security-review`, `security-scan`, `code-refactor`, `verification-loop` |
| **design-to-code.md** | `search-first`, `ui-ux-pro-max`, `frontend-dev-guidelines`, `ui-styling`, `shadcn-ui`, `frontend-design` plugin |
| **gstack-sprint.md** | `search-first`, plus any skill relevant to the sprint goal (auto-selected per phase) |

## How Templates Work

1. You fill in the placeholders and paste the template into Claude Code.
2. The `UserPromptSubmit` hook scans the prompt and suggests relevant skills from `skill-rules.json`.
3. The template instructions activate specific skills and workflows in sequence.
4. Post-completion steps guide you through verification and optional follow-ups.

Templates do not commit, push, or create PRs. The user owns all git operations.
