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

## End-to-End Multi-Agent Workflow

For large, complex, or high-stakes features that require deep analysis, multi-file implementation, requirements validation, and end-to-end testing, use this structured 8-agent workflow. It orchestrates two stages: analysis and planning (Agents 1-4), then implementation and validation (Agents 5-8).

### Additional Placeholders

```text
[REQUIREMENTS]: Requirements document, rubric, or acceptance criteria.
[REFERENCE_NOTEBOOK]: Optional reference notebook path for methodology or examples.
[DATASET_URL]: Optional dataset or resource URL for domain-specific context.
[DAYS_BACK]: Number of days of git history to analyze (default: 25).
```

### Stage 1: Analysis, Design, and Planning

Run Agents 1 and 2 in parallel. Agent 3 depends on their output. Agent 4 depends on all three.

#### Agent 1: Explorer (Deep Codebase Analysis)

Launch an Explore subagent with thoroughness "very thorough" or use `feature-dev:code-explorer`.

Responsibilities:
- Read every documentation file and map the project architecture
- Analyze each folder and file to understand how components connect
- Identify all existing features, patterns, utilities, and conventions
- Map the tech stack, dependencies, testing infrastructure, and build system
- Apply `search-first` to catalog reusable functions and abstractions

Output: a comprehensive codebase map including architecture, patterns, dependencies, and reusable utilities.

#### Agent 2: Researcher (Recent Changes and Domain Context)

Launch an Explore subagent or use `deep-research`.

Responsibilities:
- Analyze the git history from the past `[DAYS_BACK]` days on the main branch (`git log --since="[DAYS_BACK] days ago" --stat`)
- Read each commit diff line by line to understand what changed and why
- Trace how each new feature builds on the existing codebase
- If `[REFERENCE_NOTEBOOK]` is provided, read it and extract methodology and patterns
- If `[DATASET_URL]` is provided, use HuggingFace MCP or WebFetch to examine the data and find suitable examples
- Use Context7 MCP (`resolve-library-id`, `query-docs`) for up-to-date documentation on key dependencies

Output: a changelog analysis with feature evolution, dependency changes, and domain context.

#### Agent 3: Critical Reviewer (Requirements Gap Analysis)

Launch a Plan subagent or use `code-review:code-review` and `superpowers:requesting-code-review`.

Responsibilities:
- Receive the codebase map from Agent 1 and the changelog analysis from Agent 2
- Check every requirement in `[REQUIREMENTS]` against the current codebase state
- For quantitative requirements (e.g., "at least 3 examples"), verify the codebase exceeds them (e.g., provide 5)
- Check all deliverables: screenshots, JSON outputs, forms, UI components, API endpoints
- Verify each deliverable by reading the actual code, not assuming from file names
- If any requirement is not met or could be improved, produce a detailed gap report with file paths and specific deficiencies

Output: a gap report listing fulfilled requirements, unfulfilled requirements with specific file paths, and improvement opportunities.

#### Agent 4: Architect (Task Decomposition and Design)

Launch a Plan subagent or use `superpowers:writing-plans` and `feature-dev:code-architect`.

Responsibilities:
- Synthesize output from Agents 1, 2, and 3
- Break the remaining work into detailed, ordered subtasks (2-5 minutes each)
- For each subtask, specify: exact files to create or modify, the design rationale for each code change, and acceptance criteria
- Reflect on the proposed changes to identify potential issues, edge cases, or imperfect design choices
- Consider `/plan-eng-review` for architecturally complex decisions
- Produce a visual outline using a Mermaid diagram or Figma MCP `generate_diagram` when the task involves multiple interacting components

Output: a numbered implementation plan with file paths, code design rationale, risk flags, and a dependency graph.

**Checkpoint**: After Stage 1, confirm the implementation plan and gap report with the user before proceeding. Use AskUserQuestion if any requirement is ambiguous.

### Stage 2: Implementation, Validation, and Documentation

Agent 5 runs first to establish the baseline. Agents 6 and 7 run iteratively until all checks pass. Agent 8 runs last.

#### Agent 5: Validator (Feature Testing and Baseline)

Launch a general-purpose subagent or use `verification-loop`, `webapp-testing`, and `e2e-testing`.

Responsibilities:
- Get the implementation plan from Agent 4 and the gap analysis from Agent 3
- Test all existing features to establish a baseline (nothing is broken before changes)
- Run the project's test suite, build, and typecheck
- If `[TARGET_URL]` is available, use Playwright MCP to navigate every major page and verify functionality
- After implementation changes are made, re-run all tests and compare against the baseline
- Report any regressions introduced by the changes

Output: a test report with baseline results, post-change results, and any regressions.

#### Agent 6: Codex Reviewer (Cross-Model Review and Refinement)

Use the `/codex` skill to invoke cross-model review.

Responsibilities:
- Run `/codex review` on all changed files to get an independent code review
- Run `/codex challenge` to adversarially stress-test the implementation
- Check code changes against `[REQUIREMENTS]` for completeness
- Use `code-simplifier` to identify unnecessary complexity
- If Codex identifies issues, iterate: fix the issue, re-run `/codex review`, repeat until clean

Output: a Codex review report with all findings addressed.

#### Agent 7: Orchestrator (End-to-End Testing Loop)

Launch a general-purpose subagent or use `/orchestrate` with Chrome MCP and Playwright MCP.

Responsibilities:
- Use Chrome MCP (`navigate`, `read_page`, `javascript_tool`, `gif_creator`) or Playwright MCP (`browser_navigate`, `browser_click`, `browser_snapshot`, `browser_take_screenshot`) to test every feature end-to-end
- Simulate real user workflows: navigate pages, fill forms, click buttons, verify outputs
- If any feature fails or behaves incorrectly, dispatch a sub-agent to fix it (use `superpowers:dispatching-parallel-agents` for independent fixes)
- After each fix, re-test the specific feature and all related features
- Continue this loop until every feature works correctly
- If stuck after 3 attempts on any issue, escalate with BLOCKED status for human intervention
- Use `/qa` for structured browser QA testing when comprehensive coverage is needed

Output: an end-to-end test report with evidence (screenshots, GIF recordings) showing all features working.

#### Agent 8: Documenter (Documentation Update)

Launch a general-purpose subagent or use the `documentation-system` agent and `/document-release`.

Responsibilities:
- Collect all changes from Agents 1 through 7
- Update README, ARCHITECTURE, CONTRIBUTING, and any project-specific documentation to reflect the changes
- Add setup instructions if new dependencies or configuration steps were introduced
- Update any referenced screenshots or examples that changed
- Ensure documentation is accurate and matches the current state of the code
- Remove references to deleted features or outdated patterns

Output: updated documentation files with a summary of what changed and why.

### Agent Dispatch Pattern

```
Stage 1 (parallel where possible):
  Agent 1 (Explorer)  ──┐
  Agent 2 (Researcher) ─┤──> Agent 3 (Reviewer) ──> Agent 4 (Architect)
                         │
                    [user checkpoint]

Stage 2 (sequential with iteration):
  Agent 5 (Validator) ──> Agent 6 (Codex) ──> Agent 7 (Orchestrator) ──> Agent 8 (Documenter)
                              │                      │
                              └── fix loop ──────────┘
```

Use `superpowers:dispatching-parallel-agents` for Agents 1 and 2. Use `superpowers:subagent-driven-development` for the Stage 2 sequential pipeline. Use `superpowers:verification-before-completion` before declaring Stage 2 complete.

---

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
