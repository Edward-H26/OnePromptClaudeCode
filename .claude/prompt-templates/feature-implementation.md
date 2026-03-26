# Feature Implementation Template

## How to Use

Copy this into Claude Code and replace the placeholders.

```text
[TASK]: What to build, fix, or change.
[DIRECTORY]: Project root to work in.
[API]: Optional external API or service.
[AUTH_METHOD]: Optional auth method if the task touches auth.
[FIGMA_URL]: Optional Figma link for UI work.
[TARGET_URL]: Optional local or deployed URL for browser verification.
```

## Execution Prompt

You are working in **[DIRECTORY]**.

Task: [TASK]

Optional context:
- API or service: [API]
- Auth method: [AUTH_METHOD]
- Figma: [FIGMA_URL]
- Browser target: [TARGET_URL]

## Workflow

### 1. Explore First

1. Read `CLAUDE.md`, relevant docs, and the files closest to the task.
2. Apply `search-first` before proposing new abstractions.
3. Use local repo tools first. Use installed plugin agents only when they materially help.
4. If the task is non-trivial, create or update a plan with `/multi-plan` or run `/plan-eng-review`.

### 2. Define the Change

1. Identify the exact files to touch and why.
2. Keep the design constrained to the requested scope.
3. If the task is UI-heavy, inspect the current surface first and use `[FIGMA_URL]` only when design fidelity matters.
4. If auth, secrets, permissions, or user input are involved, apply `security-review`.

### 3. Implement

1. Make the smallest set of edits that satisfies the task.
2. Use the most relevant local guidance:
   - `backend-dev-guidelines`
   - `frontend-dev-guidelines`
   - `ui-styling`
   - `systematic-debugging`
3. For complex multi-component features, use `/super-ralph` to autonomously decompose, implement, test, and merge via specialized agents (worker, tester, debugger, judge, merger).
4. Use `/codex` or plugin-backed explorer or reviewer agents only as optional bounded help, not as a mandatory phase.
5. Keep all work inside `[DIRECTORY]`.

### 4. Verify

1. Run the smallest useful checks for the changed area.
2. If UI changed, verify in browser tooling when feasible.
3. Use `/review-staff`, `/quality-gate`, or `/design-review` when they add signal for the scope.
4. Report changed files, checks run, and remaining risks.

## Rules

- Do not invent mandatory hard gates or extra phases.
- Do not commit, push, or create a PR.
- Prefer targeted verification over ritual full-suite runs when the scope is small.
- If the task grows beyond the original scope, stop and re-plan.
