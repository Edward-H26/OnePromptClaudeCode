---
description: Coordinate a complex task with local and plugin agents
argument-hint: "Task description"
---

# Orchestrate Command

Coordinate a complex task with the local agents and installed plugin agents that actually exist in this workspace.

## Usage

`/orchestrate [workflow-type] [task-description]`

## Supported Workflows

### feature

Recommended sequence:
- `task-orchestrator` for breakdown and scope control
- `feature-dev:code-explorer` for codebase mapping
- `feature-dev:code-architect` or `architect` for solution design
- implementation
- `feature-dev:code-reviewer` or `superpowers:code-reviewer` for review
- `security-review` if the feature touches auth, permissions, secrets, or user input

### bugfix

Recommended sequence:
- `/investigate`
- `feature-dev:code-explorer` for execution-path tracing when needed
- `frontend-error-fixer`, `build-error-resolver`, or `architecture-review-system` depending on the failure mode
- `verification-loop`

### refactor

Recommended sequence:
- `code-refactor-master`
- implementation
- `feature-dev:code-reviewer` or `superpowers:code-reviewer`
- `verification-loop`

### security

Recommended sequence:
- `security-review`
- `feature-dev:code-reviewer`
- `architect` or `architecture-review-system` if structural changes are involved

## Rules

- Use only real local agents or installed plugin-backed agents.
- Prefer plugin-backed explorer or reviewer agents when their scope matches the task.
- Use handoff notes between stages only when multiple agents are actually involved.
- Keep orchestration scoped to the task. Do not build a control plane unless the task genuinely needs one.

## Arguments

$ARGUMENTS:
- `feature <description>` - New feature workflow
- `bugfix <description>` - Bug investigation and fix workflow
- `refactor <description>` - Safe refactoring workflow
- `security <description>` - Security review workflow
- `custom <agents> <description>` - Custom sequence using real local or plugin-backed agents

## Tips

1. Start with `task-orchestrator` or `feature-dev:code-explorer` for complex features.
2. Always include a real reviewer before merge.
3. Use `security-review` for auth, payment, or PII work.
4. Keep handoffs concise, focused on what the next agent actually needs.
5. Run verification between stages if the task has moved past a major checkpoint.
