---
name: testing-verification
description: Verification protocol for finishing a code change. Use when deciding what to run before claiming work is done, choosing between targeted and full-suite checks, or reporting verification evidence.
---

# Testing and Verification Protocol

> **Related**: [website-workflow](../website-workflow/SKILL.md) for browser and UI verification.

## Core Rule

Use verification that matches the scope of the change.

- Run existing tests when they cover the code you changed.
- Prefer targeted checks before full-suite checks.
- Do not add new tests unless the task requires them or the change is large enough that missing tests would be unsafe.
- Do not rely on nonexistent hooks or promised automation. Verify with the commands and tools that are actually available.

## Baseline Workflow

### 1. Before Editing
- Identify which tests, type checks, or builds are relevant.
- Check whether the area already has tests.

### 2. During Implementation
- Re-run the smallest useful verification after meaningful changes.
- Use Bash or the available MCP and plugin tools to inspect outputs.

### 3. After Implementation
Run the project's own test, type-check, lint, and build commands, using only the ones that exist in the target project. Read the package manifest's scripts rather than assuming a package manager.

### 4. Frontend Validation
If the task changes visible UI, verify it in the browser. See the `website-workflow` skill for the browser tooling preference order.

## Failure Response

- **Type checks fail**: fix the root cause instead of suppressing the error.
- **Browser verification is not possible**: say so explicitly, and state what was verified instead.

## Evidence to Report

When you finish a non-trivial code task, report:

- What checks ran
- Whether they passed
- What could not be run
