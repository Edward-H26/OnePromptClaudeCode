# Debug Template

## How to Use

Copy this into Claude Code and replace the placeholders.

```text
[BUG]: What is broken, what should happen, and what actually happens.
[DIRECTORY]: Project root.
[MODULE_DIR]: Optional directory to freeze for safety.
[TARGET_URL]: Optional URL if browser reproduction matters.
```

## Execution Prompt

You are debugging inside **[DIRECTORY]**.

- Bug: [BUG]
- Optional freeze boundary: [MODULE_DIR]
- Optional browser target: [TARGET_URL]

## Workflow

### 1. Scope and Reproduce

1. If `[MODULE_DIR]` is present, use `/freeze [MODULE_DIR]`.
2. Use `/investigate` to force root-cause analysis before fixing.
3. Reproduce the issue with the smallest reliable command, test, or browser flow.
4. If the bug is route-related, use `/route-research-for-testing`.

### 2. Trace the Root Cause

1. Read the exact code path involved.
2. Inspect recent related changes and surrounding assumptions.
3. If helpful, use plugin-backed explorer or reviewer agents as bounded support, not as mandatory phases.
4. State the root cause clearly before editing.

### 3. Fix Minimally

1. Change only what the root cause requires.
2. Use the relevant local skill:
   - `backend-dev-guidelines`
   - `frontend-dev-guidelines`
   - `ui-styling`
   - `security-review`
3. Write or update a focused reproduction test when the project supports it and the bug warrants it.

### 4. Verify

1. Re-run the failing reproduction.
2. Run the smallest useful set of additional checks for the touched surface.
3. If the bug is browser-visible, verify it in browser tooling when feasible.
4. If config or workflow files changed, run `security-scan`.

## Rules

- Fix the cause, not just the symptom.
- Do not turn a bug fix into an unrelated refactor.
- If three fix attempts fail, stop and re-assess the architecture or constraints.
- Do not commit, push, or create a PR.
