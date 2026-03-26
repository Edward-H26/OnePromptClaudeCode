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

ultrathink

You are working in `[DIRECTORY]`.

All file reads, searches, edits, tests, and browser checks must stay scoped to `[DIRECTORY]`.

Task: [TASK]

Optional context:
- API: [API]
- Auth method: [AUTH_METHOD]
- Figma: [FIGMA_URL]
- Browser target: [TARGET_URL]

## Required Workflow

1. Explore before editing.
   - Read the relevant code, docs, tests, and local workflow instructions first.
   - Apply `search-first`.
   - If the task touches hooks, skills, templates, commands, agents, plugins, or `.claude/settings.json`, apply `skill-developer`.

2. Build a concrete implementation plan before code.
   - Name the exact files you expect to touch.
   - Explain why each file is needed.
   - Keep the plan minimal and consistent with the existing codebase.
   - For architecturally complex tasks, generate a visual outline of the implementation plan using Figma MCP `generate_diagram` or a Mermaid/ASCII diagram in the plan itself.
   - Ask clarifying questions only if the request is genuinely ambiguous or blocked on missing requirements.

3. Activate only the skills that fit the task.
   - Backend work: `backend-dev-guidelines`
   - Frontend work: `frontend-dev-guidelines`
   - UI styling: `ui-styling`
   - shadcn/ui component work: `shadcn-ui`
   - Refactors: `code-refactor`
   - Bugs and regressions: `systematic-debugging`
   - Security, secrets, auth, permissions, gitignore, workflow hardening: `security-review` and `security-scan`
   - External research: `deep-research`
   - Verification: `verification-loop`
   - Browser or E2E work: `e2e-testing` or `webapp-testing`
   - Self-contained HTML deliverables: `web-artifacts-builder`
   - Claude API work: `claude-api`
   - Postgres work: `postgres-patterns`
   - Docker or deploy work: `docker-patterns` or `deployment-patterns`
   - Superpowers plugin (when installed):
     - Design exploration: `superpowers:brainstorming`
     - Task decomposition: `superpowers:writing-plans`
     - Test-first implementation: `superpowers:test-driven-development`
     - Plan execution with review checkpoints: `superpowers:executing-plans`
     - Per-task subagent dispatch with 2-stage review: `superpowers:subagent-driven-development`
     - Concurrent independent subtasks: `superpowers:dispatching-parallel-agents`
     - Workspace isolation for parallel branches: `superpowers:using-git-worktrees`
     - 4-phase root cause investigation: `superpowers:systematic-debugging`
     - Pre-merge review checklist: `superpowers:requesting-code-review`
     - Technical evaluation of received feedback: `superpowers:receiving-code-review`
     - Evidence-based completion verification: `superpowers:verification-before-completion`
     - Branch finalization and merge/PR decision: `superpowers:finishing-a-development-branch`

4. Use installed plugins and MCP tools only when they are relevant and available.
   - `context7` for current library documentation
   - `playwright` for browser verification
   - `figma` for design context if `[FIGMA_URL]` is provided
   - `frontend-design` for stronger UI direction when the task is design-heavy
   - `github`, `mongodb`, `pyright-lsp`, and `typescript-lsp` only when the task benefits from them
   - Do not assume plugin sub-skills or MCP methods that are not present in the current environment

5. Implement with minimal, contained changes.
   - Match existing patterns and naming exactly.
   - Do not create speculative abstractions.
   - Do not add logs, TODOs, or extra cleanup unless they are directly required.
   - Do not commit or push.

6. Verify with the smallest useful checks.
   - Run targeted tests first.
   - Use `verification-loop` thinking for build, typecheck, lint, test, security, and diff review.
   - If `[TARGET_URL]` is available and the task affects visible behavior, run browser verification with Playwright.
   - If browser tooling or auth is unavailable, say so clearly and verify what you can.

## Advanced Workflow (Optional)

Use these techniques for complex, multi-step, or high-stakes features.

### Superpowers Pipeline

When the superpowers plugin is installed, use its skills via the Skill tool with prefix `superpowers:`. The recommended pipeline for non-trivial features:

1. **Design phase:** `superpowers:brainstorming` for Socratic design exploration. Produces a spec document. Do not skip this for features that touch multiple files or introduce new patterns.
2. **Planning phase:** `superpowers:writing-plans` to decompose into bite-sized tasks (2-5 min each) with exact file paths and acceptance criteria.
3. **Implementation phase:** Choose one:
   - `superpowers:subagent-driven-development` dispatches a fresh subagent per task with 2-stage review (spec compliance, then code quality). Best for same-session execution.
   - `superpowers:executing-plans` executes the written plan with human review checkpoints. Best for separate-session execution.
   - `superpowers:dispatching-parallel-agents` for 2+ independent subtasks that share no state.
4. **Debugging (if needed):** `superpowers:systematic-debugging` for 4-phase root cause investigation before proposing fixes.
5. **Review phase:** `superpowers:requesting-code-review` runs a pre-review checklist. `superpowers:receiving-code-review` evaluates any feedback received with technical rigor.
6. **Completion phase:** `superpowers:verification-before-completion` requires evidence (test output, build output) before any success claims. `superpowers:finishing-a-development-branch` handles merge/PR decisions and cleanup.

Priority hierarchy: process skills first (brainstorming, debugging), then implementation skills (TDD, subagent dev).

### Iterative Refinement with Super Ralph

For features requiring autonomous iteration until quality is proven:

1. After initial implementation, invoke `/super-ralph` with remaining polish, integration, or complex subtasks.
2. Super Ralph decomposes remaining work, spawns specialized agents (ralph-worker, ralph-tester, ralph-debugger, ralph-judge, ralph-merger), and self-debugs until all tests pass.
3. If Ralph gets stuck (3 failed attempts on any subtask), it escalates with BLOCKED status for human intervention.
4. After Ralph completes, run `superpowers:verification-before-completion` to confirm evidence-based quality.
5. Use `/quality-gate` and `/codex review` for independent cross-model verification of Ralph's output.

### Visual Verification Loop

When `[TARGET_URL]` is available and the task affects visible UI:

1. After implementation, use Playwright MCP to capture the current state:
   - `browser_navigate` to load the page
   - `browser_snapshot` to get the accessibility tree
   - `browser_take_screenshot` to capture the visual output
2. Compare the screenshot against the design intent or expected behavior.
3. If the visual output does not match the specification:
   - Diagnose the specific gap (layout, spacing, color, interaction)
   - Make targeted CSS/component fixes
   - Re-navigate and re-screenshot to verify the fix
4. Repeat steps 2-3 until the visual output matches the specification.
5. For Chrome-specific testing, use Chrome MCP (`navigate`, `read_page`, `upload_image`) as an alternative.
6. For responsive testing, use `browser_resize` to check multiple viewport sizes.

This loop replaces manual "looks good" checks with evidence captured via browser tooling.

## Expected Deliverable

Return:
- The plan you followed
- Files changed and why
- Checks you ran and whether they passed
- Risks, assumptions, or follow-up items

## Guardrails

- Stay inside `[DIRECTORY]`
- Prefer repo-local scripts, docs, and config over home-directory conventions
- Keep the user as the sole author of any future commit
- Do not invent mandatory phases, agents, plugin actions, or MCP methods
