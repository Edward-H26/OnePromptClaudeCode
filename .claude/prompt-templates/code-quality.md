# Code Quality Template

## How to Use

Copy this into Claude Code and replace the placeholders.

```text
[DIRECTORY]: Project root.
[SCOPE]: What to inspect, such as "recent changes" or "src/auth/".
[GOAL]: What to optimize for, such as correctness, security, or simplification.
[MODE]: review, refactor, or security-audit.
[RISK_AREAS]: Known risky surfaces.
[CONSTRAINTS]: Optional refactor constraints.
```

## Execution Prompt

You are working in **[DIRECTORY]**.

- Scope: [SCOPE]
- Goal: [GOAL]
- Mode: [MODE]
- Risk areas: [RISK_AREAS]
- Constraints: [CONSTRAINTS]

Start with `search-first`. Review the real code and settings before drawing conclusions.

## Mode Guidance

### Review

1. Prioritize bugs, regressions, security issues, and missing tests.
2. Use `security-review` for code risks and `security-scan` for workflow or config risks.
3. Use `/codex review` or `/codex challenge` only when an independent second opinion adds value.
4. If UI behavior is in scope, verify it in browser tooling when feasible.
5. Present findings first, ordered by severity, with file references and fix direction.

### Refactor

1. Map usages before editing.
2. Apply `code-refactor` for controlled, scoped edits.
3. For large-scale refactors spanning multiple files or modules, use `/super-ralph` to autonomously decompose, implement, and verify each transformation.
4. Keep behavior unchanged unless the task explicitly allows otherwise.
5. Run targeted verification after each meaningful step.
6. Summarize files changed, verification run, and residual risks.

### Security Audit

1. Use `security-review` for application risks.
2. Use `security-scan` for `.claude`, hooks, permissions, plugins, and related config.
3. Focus on secrets exposure, injection paths, auth and permission boundaries, and unsafe automation.
4. Report findings by severity with remediation steps.

## Rules

- Prefer concrete defects over style comments.
- If there are no findings, say so and note testing gaps.
- Do not commit, push, or create a PR.
