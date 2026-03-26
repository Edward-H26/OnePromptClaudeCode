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

You are working in the project `[DIRECTORY]`:

All file operations, searches, and agent work MUST be scoped to this directory. Use `[DIRECTORY]` as the root for all relative paths.

**Task:** [TASK]

---

## Thinking Protocol

This workflow requires maximum reasoning depth at every decision point. The `ultrathink` trigger above activates the full 31,999-token thinking budget for this session.

At each stage gate and before every architectural decision, think through:
- All possible approaches and their tradeoffs.
- Edge cases, failure modes, and security implications.
- How the change interacts with existing code paths.
- Whether the proposed solution is the simplest one that works.

For agents spawned during this workflow: each agent prompt should include "think hard" to ensure sub-agents also use extended reasoning. Reserve "ultrathink" for the orchestrating agent (this prompt) and critical decision points like architecture design (Agent 2) and the orchestration loop (Agent 7).

---

## Pre-Execution: Deep Requirements Gathering

Before ANY analysis or code, activate the `superpowers:brainstorming` skill to deeply understand the task.

1. Explore the project context first: read key files, docs, recent commits, and CLAUDE.md in `[DIRECTORY]`.
2. Use the Socratic method to ask the user targeted clarifying questions. Cover:
   - Desired behavior and expected outcomes at the level of a senior software engineer.
   - Edge cases, error states, and failure modes.
   - Performance requirements and scale expectations.
   - Security considerations and access control.
   - Which existing features this interacts with.
   - Acceptance criteria: how will we know this is done?
3. Ask questions one at a time. Do not proceed until each is answered.
4. After gathering requirements, use the `superpowers:writing-plans` skill to produce a structured implementation plan with:
   - Architecture diagram (describe in text or generate via Figma MCP `generate_diagram` if applicable).
   - Component breakdown with file paths and responsibilities.
   - Data flow from user action through every layer to database and back.
   - API contracts (request/response shapes) if applicable.
   - Dependency graph showing build order.
5. Present the plan to the user. **HARD GATE: Do not proceed to Stage 1 without explicit user approval of the plan.**

---

## Stage 1: Analysis, Solution Design, Task Decomposition, and Cleanup

### Agent 1: Deep Codebase Explorer (runs immediately after plan approval)

Explore the entire codebase to build a complete mental model. Read every relevant file, line by line.

Apply the `search-first` skill: explore every relevant file, function, and pattern before forming opinions. Resist the urge to plan until you have mapped the territory.

**Backend exploration:**
1. Use a `feature-dev:code-explorer` agent to trace the backend: routes, services, models, database layer, middleware, configuration, agent/pipeline code.
2. Use Context7 MCP: call `resolve-library-id` for each backend dependency, then call `query-docs` to pull current documentation. Do this for every non-trivial dependency.
3. Use MongoDB MCP: call `list-databases`, `list-collections`, `collection-schema`, `collection-indexes`, `collection-storage-size` to map the full database structure.
4. If PostgreSQL is used, apply `postgres-patterns` to understand schema design, indexing strategy, and migration history.
5. If PDF specs exist, use PDF Viewer MCP: call `list_pdfs` then `read_pdf_bytes`.
6. If academic context is needed, use Scholar Gateway MCP: call `semanticSearch`.
7. Use HuggingFace MCP: call `hub_repo_search` if ML models or datasets are relevant.
8. Check Docker and container configurations. Apply `docker-patterns` if found.
9. Check deployment configs (CI/CD, Terraform, Kubernetes). Apply `deployment-patterns` if found.

**Frontend exploration:**
10. Use a `feature-dev:code-explorer` agent to trace the frontend: pages, components, API clients, types, state management, hooks, utilities.
11. Use Context7 MCP for React, Next.js, and all frontend library docs.
12. If `[FIGMA_URL]` is provided, use Figma MCP: call `get_design_context`, `get_screenshot`, `get_metadata`, `get_variable_defs`, `get_code_connect_suggestions`.
13. Use Chrome MCP: call `tabs_context_mcp`, `navigate` to open the app, `read_page` for accessibility tree, `read_console_messages` for errors, `read_network_requests` for API calls.
14. Use Filesystem MCP: call `directory_tree` for structure, `search_files` for config files and test fixtures.

**Cross-cutting:**
15. Use Memory MCP: call `search_nodes` to check for existing architectural decisions relevant to this area.
16. If the task requires external research, use the `deep-research` skill with WebSearch and WebFetch.

**Deliverable:** Structured report with: project map, all API endpoints, database schema, architecture patterns, infrastructure setup, build/run/test commands, deployment pipeline, files relevant to [TASK], existing features that the task might interact with, entry URL for browser testing.

---

### Agent 2: Solution Architect (blocked by Agent 1)

Receive Agent 1's full exploration report. Design the implementation approach.

1. Use a `feature-dev:code-architect` agent to design the solution based on Agent 1's findings.
2. Use the `superpowers:brainstorming` skill to explore 2-3 alternative approaches. Evaluate tradeoffs between simplicity, performance, and maintainability.
3. Consider running `/office-hours` if the task scope is ambiguous.
4. For larger features, run `/plan-eng-review` for architecture review with diagrams, data flow, edge cases, and test matrices.
5. If UI design decisions are involved, run `/plan-design-review` to rate design dimensions 0-10 and detect AI slop.
6. Use the `deep-research` skill if external research is needed (APIs, libraries, algorithms).
7. If `[API]` is specified: research the API's documentation, rate limits, error codes, and authentication flow. Use Context7 MCP to pull SDK docs. Design the service layer following existing codebase API client patterns. Map the full auth flow based on `[AUTH_METHOD]`.
8. If the task involves agent or AI pipeline work, apply `agentic-engineering` for tool-use patterns and error handling. Consider `autonomous-loops` if continuous execution is needed.
9. If the task involves Claude API integration, apply `claude-api` for SDK patterns, streaming, and tool use.
10. Use Memory MCP: call `create_entities` to store key architectural decisions, then `create_relations` to link them to relevant files.

**Deliverable:** Implementation plan with: files to modify (path, function, change, reason), files to create (path, purpose, integration), API contracts, type changes, database migrations, infrastructure changes, risk assessment, recommended safety modes (/careful, /freeze).

---

### Agent 3: Task Decomposer and Design Reviewer (blocked by Agents 1 and 2)

Receive all findings from Agents 1 and 2. Break the complex task into detailed, comprehensive subtasks.

1. Decompose the approved plan into independent parallel workstreams where possible:
   - **Backend workstream:** API/data layer changes, service logic, database migrations, unit tests.
   - **Frontend workstream:** UI components, pages, state management, component tests.
   - **Integration workstream:** End-to-end tests, interface contracts between frontend and backend.
2. For each subtask, delineate:
   - Exact files that need to change (path and line range).
   - The design rationale behind each code change.
   - Expected behavior before and after the change.
   - Test strategy (unit, integration, or E2E).
3. **Self-review**: Reflect on the proposed solution to identify:
   - Possible race conditions or concurrency issues.
   - Missing error handling or edge cases.
   - Imperfect abstractions or over-engineering.
   - Security vulnerabilities (apply `security-review` checklist).
   - Performance bottlenecks.
4. Revise the plan based on the self-review findings.
5. Use the `superpowers:writing-plans` skill to format the final task breakdown with checkbox syntax for tracking.
6. Run `/dev-docs` to generate a structured plan document at `dev/active/[task-name]/`.

**Deliverable:** Ordered task list with: subtask description, files affected, code design rationale, test plan, identified risks, and dependency ordering. Each subtask should be 2-5 minutes of focused work.

---

### Agent 4: Pre-Implementation Refactor and Cleanup (blocked by Agent 3)

Receive all context from Agents 1-3. Prepare the codebase for the new feature.

1. Apply `search-first` one final time: re-read every file that will be modified. Confirm the plan is still valid against current code state.
2. Use the `code-refactor` skill to identify and fix:
   - Unused imports, variables, or functions in files that will be touched.
   - Dead code paths or commented-out code.
   - Inconsistent naming conventions (apply CLAUDE.md naming rules).
   - Functions that are irrelevant to the current project stage.
3. Run `/freeze [DIRECTORY]` to scope all edits if the user specified a module boundary.
4. Run `/careful` if working near production systems.
5. Use `verification-loop` to confirm the codebase builds and tests pass BEFORE any feature work begins.
6. Run `/codex review` to get an independent baseline assessment of the code about to be modified.
7. Use `/checkpoint` to save the pre-implementation state.
8. Update or create setup documentation:
   - Verify README has accurate setup instructions.
   - Ensure environment variable templates are current.
   - Document any new dependencies or prerequisites.

**Deliverable:** Clean codebase with: removed dead code, consistent conventions, passing build/tests, baseline code review, checkpoint saved, setup docs current.

---

### Stage 1 Gate

Present to the user:
- Agent 1: Full codebase analysis and project map.
- Agent 2: Architecture design with alternatives considered.
- Agent 3: Detailed task breakdown with dependency ordering.
- Agent 4: Pre-implementation cleanup summary and baseline state.
- Recommended safety modes (/careful, /freeze) if applicable.
- Any risks or open questions discovered during analysis.

**HARD GATE: Do not proceed to Stage 1 Implementation without explicit user approval.**

---

## Stage 1 Implementation: Parallel Workstreams

After user approval, use `superpowers:dispatching-parallel-agents` to launch workstreams.

### Backend Workstream

1. Apply `backend-dev-guidelines` for Node.js/Express/TypeScript patterns OR `python-patterns` for Python.
2. Use `superpowers:test-driven-development`: write tests BEFORE implementation (RED-GREEN-REFACTOR).
3. Use `tdd-workflow` with 80%+ coverage target.
4. Use `python-testing` for pytest fixtures, parametrization, mocking patterns.
5. If `[API]` is specified: build a dedicated service class following `backend-dev-guidelines` service layer patterns. Implement retry logic with exponential backoff, error mapping, and auth token management based on `[AUTH_METHOD]`. If Claude API, apply `claude-api` skill.
6. Use MongoDB MCP for database operations: `find`, `aggregate`, `create-index`, `insert-many`, `update-many`. Call `explain` on complex queries.
7. If PostgreSQL, apply `postgres-patterns` for query optimization, indexing, safe migrations. Spawn `database-reviewer` agent.
8. If Docker changes needed, apply `docker-patterns`.
9. If deployment changes needed, apply `deployment-patterns`.
10. Use `security-review` to check all new code for OWASP vulnerabilities.
11. Use Context7 MCP throughout: verify every API or library method.
12. If build errors occur, use `/build-fix` or spawn `build-error-resolver` agent.

**Error handling:** Max 3 retries per failing test. After 3 failures, use `systematic-debugging` or `/investigate` for root-cause analysis.

**Deliverable:** Files modified/created, test results (pass/fail per test), database migrations created.

### Frontend Workstream (parallel with Backend)

1. Apply `frontend-dev-guidelines` for React 19, TypeScript, Suspense, TanStack patterns.
2. Use `shadcn-ui` skill: run `npx shadcn info --json`, `npx shadcn search`, `npx shadcn add`.
3. Use `ui-styling` for Tailwind CSS utilities, responsive design, dark mode, accessibility.
4. Use `frontend-design:frontend-design` plugin for production-grade UI.
5. If `[FIGMA_URL]` provided, use `figma:implement-design` for 1:1 visual fidelity. Use `figma:code-connect-components` for reusable mappings.
6. If glassmorphic design requested, use `liquid-glass-design`.
7. If building HTML artifacts, use `web-artifacts-builder`.
8. Use `superpowers:test-driven-development` for component tests.
9. Use `e2e-testing` for Playwright E2E with Page Object Model.
10. If testing local webapp with Python, use `webapp-testing` for Playwright-in-Python patterns.
11. Use Context7 MCP for component library verification.
12. If build or TypeScript errors, use `/build-fix` or check `tsc-check` hook output.

**Error handling:** Max 3 retries per build failure. If stuck, use `systematic-debugging`.

**Deliverable:** Files modified/created, build result, test results, screenshots of implemented UI.

### Integration Workstream (blocked by Backend and Frontend)

1. Write end-to-end tests covering the full feature flow.
2. Run the complete test suite. Report any interface mismatches between frontend and backend.
3. Use `verification-loop` for structured 6-phase check: build, type check, lint, test suite, security scan, diff review.
4. Use Chrome MCP for UI end-to-end verification:
   - `tabs_create_mcp` to open a new tab.
   - `navigate` to the app entry URL or `[TARGET_URL]`.
   - `read_page` for accessibility tree.
   - `read_console_messages` with pattern filter for errors.
   - `read_network_requests` to verify API calls.
   - `get_page_text` for text content.
   - `computer` with action "screenshot" for visual state.
   - `gif_creator` to record a walkthrough.
   - Test multiple viewport sizes for responsive behavior.
5. Use Playwright MCP for automated multi-step verification.
6. If the feature involves database changes, use MongoDB MCP to verify data integrity.

Each workstream agent should: (1) read existing code patterns before writing new code, (2) match existing conventions exactly, (3) run its own tests before reporting done. If any agent's tests fail, it should iterate up to 3 times before escalating.

**Deliverable:** Integration test results, browser verification (screenshots, GIFs), interface mismatch report.

---

### Stage 1 Implementation Gate

Present to the user:
- All files created and modified across workstreams.
- Test results from all three workstreams.
- Browser verification screenshots and GIFs.
- Any interface mismatches or unresolved issues.

**HARD GATE: Do not proceed to Stage 2 without explicit user approval.**

---

## Stage 2: Validation, Refinement, and Documentation

### Agent 5: Feature Validator and Tester (runs immediately after approval)

Validate ALL existing features still work and the new feature behaves correctly.

1. Use Chrome MCP to simulate a real user exploring every feature:
   - Navigate to every page of the application.
   - Click through all interactive elements.
   - Fill and submit all forms.
   - Verify all navigation flows.
   - Check console for errors on every page.
   - Check network requests for failed API calls.
   - Take screenshots of every distinct view.
   - Record GIFs of critical user flows.
2. Use Playwright MCP for automated regression testing:
   - `browser_navigate` through all routes.
   - `browser_snapshot` for element trees.
   - `browser_click`, `browser_fill_form`, `browser_select_option` for interactions.
   - `browser_take_screenshot` for visual regression.
   - `browser_console_messages` for errors.
   - `browser_network_requests` for API verification.
   - `browser_evaluate` for custom JS assertions.
3. Run `/qa [TARGET_URL]` for comprehensive browser QA with auto-generated regression tests.
4. Use `chrome-devtools` for performance profiling: check for memory leaks, slow renders, large bundle sizes.
5. Use `superpowers:verification-before-completion` to enforce the iron law: no completion claims without fresh verification evidence.

**Deliverable:** Complete feature validation report with screenshots, GIFs, console error log, network request log, performance profile, and list of any failing features.

---

### Agent 6: Codex Cross-Model Review (parallel with Agent 5)

Use `/codex` to get independent cross-model verification.

1. Run `/codex review` for an independent code review. Present Codex output verbatim in `CODEX SAYS` blocks.
2. Run `/codex challenge` to adversarially stress-test the code for edge cases, race conditions, security holes.
3. Compare Claude and Codex findings:
   - Findings both models agree on (highest confidence, fix first).
   - Findings only Codex found (investigate, may be blind spot).
   - Findings only Claude found (investigate, may be blind spot).
   - Overall agreement rate as a percentage.
4. For any `[P1]` critical findings from either model, investigate and fix immediately.
5. Run `/simplify` to review all changed files for unnecessary complexity.
6. Use `code-refactor` skill to identify remaining code smells.
7. Spawn `superpowers:code-reviewer` agent for structured review.
8. Spawn `feature-dev:code-reviewer` agent to review against the original plan.
9. Use `security-scan` to audit any configuration changes.
10. Use `security-review` one final time on all changed files.
11. If Codex identifies issues, fix them and re-run `/codex review` until the review passes.

**Deliverable:** Cross-model review report, security audit results, code quality improvements, Codex pass/fail status.

---

### Agent 7: Orchestration Loop (blocked by Agents 5 and 6)

This agent coordinates all remaining work until every feature is working perfectly.

1. Collect all findings from Agents 5 and 6.
2. For each unresolved issue, spawn a targeted sub-agent:
   - `build-error-resolver` for compilation failures.
   - `auto-error-resolver` for TypeScript errors.
   - `frontend-error-fixer` for React/CSS errors.
   - `frontend-developer` for UI component fixes.
   - `database-reviewer` for data layer issues.
   - `architect` for architectural problems.
3. After sub-agents complete their fixes, re-run validation:
   - Use Chrome MCP to re-test affected features.
   - Use Playwright MCP for automated regression.
   - Run the full test suite.
   - Run `verification-loop` (build, type, lint, test, security, diff).
4. Run `/quality-gate` to validate quality criteria.
5. **Loop condition:** If any feature is not working correctly, repeat steps 2-4. This loop continues until:
   - All features pass manual browser testing (Chrome MCP).
   - All automated tests pass.
   - All Codex review findings are resolved.
   - The `verification-loop` completes with zero failures.
   - `/quality-gate` passes.
6. Maximum 5 loop iterations. If issues persist after 5 iterations, compile a detailed report of remaining issues and escalate to the user.
7. Use `/checkpoint` after each successful loop iteration.

**Deliverable:** Iteration log showing what was fixed in each pass, final validation results confirming all features work, quality gate pass confirmation.

---

### Agent 8: Documentation and Final Delivery (blocked by Agent 7)

Update all documentation to reflect the changes.

1. Use the `superpowers:brainstorming` skill to identify what documentation needs updating.
2. Spawn the `documentation-system` agent to update all relevant project docs.
3. Run `/dev-docs-update` to capture the implementation state, key decisions, files modified, and next steps.
4. Use `professional-research-writing` skill for all written content (no em dashes, participial phrases, active voice).
5. Run `/document-release` to auto-update README, ARCHITECTURE, or CONTRIBUTING docs based on the diff.
6. Update setup documentation:
   - Step-by-step setup instructions for new developers.
   - Environment variable documentation.
   - Database migration instructions.
   - Deployment instructions if applicable.
7. Use `superpowers:finishing-a-development-branch` to prepare the work for integration: summarize changes, list files modified, suggest commit message, recommend merge strategy.
8. Use Memory MCP: call `search_nodes` to find existing entities. Call `add_observations` to update with new details. Call `create_entities` for new architectural decisions worth remembering.

**Deliverable:** Updated documentation, dev docs state captured, branch completion summary with suggested commit message.

---

### Stage 2 Gate (Final)

Present to the user:

1. **Agent 5:** Feature validation report with screenshots, GIFs, and test results.
2. **Agent 6:** Cross-model review results and security audit.
3. **Agent 7:** Orchestration loop log showing all iterations and final pass confirmation.
4. **Agent 8:** Updated documentation and branch summary.
5. Complete list of all files created and modified.
6. Suggested commit message.
7. Any known limitations or follow-up items.
8. Suggestion to run `/retro` if this was a significant feature.

User confirms acceptance or requests follow-up changes.

---

## Constraints (all agents)

- **No git commits or pushes.** The user is the sole author of all commits.
- **No Co-Authored-By lines.** The user owns all attribution.
- **Max 3 retries** on any failing operation, then use structured debugging (`systematic-debugging`, `/investigate`) before escalating.
- **No unbounded loops.** Tests: 3 retries. Integration mismatches: 2 round-trips. Orchestration loop: 5 iterations max.
- **Context efficiency.** Each agent receives only the plan section relevant to its role.
- **Match existing conventions.** Follow CLAUDE.md and project-specific conventions.
- **No speculative changes.** Modify only files in the approved plan. No "while we're here" cleanup outside the /simplify step.
- **Explore tools broadly.** When uncertain, try a tool call rather than guessing. MCP tools, skills, and agents are cheap to invoke.

---

## Hooks (auto-fire, no manual action needed)

These hooks fire automatically during the workflow:
- `check-careful.sh` warns before destructive commands (when /careful active).
- `check-freeze.sh` blocks edits outside the frozen directory (when /freeze active).
- `task-orchestrator-hook` suggests relevant skills on prompt submit.
- `auto-codex-trigger` launches Codex in background for coding tasks.
- `skill-activation-prompt` auto-suggests skills based on keywords.
- `post-tool-use-tracker` tracks all file modifications.
- `tsc-check` runs TypeScript compilation after every edit.
- `workflow-step-tracker` tracks /codex, /simplify, and Chrome MCP usage.
- `stop-build-check-enhanced` re-runs build checks when you stop.
- `workflow-completion-gate` emits reminders and cleans stale cache.

---

## Dependency Graph

```
Pre-Execution: superpowers:brainstorming -> superpowers:writing-plans -> [USER APPROVAL]

Stage 1 (Analysis):
Agent 1 (Explorer) -> Agent 2 (Architect) -> Agent 3 (Decomposer) -> Agent 4 (Cleanup)
-> [USER APPROVAL]

Stage 1 (Implementation):
Backend Workstream ---+
Frontend Workstream --+---> Integration Workstream -> [USER APPROVAL]
                      |
      (parallel)      |

Stage 2 (Validation):
Agent 5 (Validator) --+
Agent 6 (Codex)     --+---> Agent 7 (Orchestration Loop) -> Agent 8 (Documentation)
                      |
      (parallel)      |
```

---

## Customization

- **Backend-only:** Remove frontend workstream and Agent 2 frontend analysis. Agent 5 uses API testing instead of browser tools.
- **Frontend-only:** Remove backend workstream. Agent 5 leans into Chrome MCP and Playwright.
- **Monorepo / single-stack:** Merge backend and frontend workstreams into one developer agent.
- **Autonomous execution:** Replace Stage 1 Implementation with `/super-ralph` for fully autonomous multi-agent orchestration.
- **API integration:** Specify `[API]` and `[AUTH_METHOD]`. Agent 2 designs the service layer. Backend workstream builds with retries and auth. Agent 5 verifies with live API calls.
- **ML/AI task:** Add `/autoresearch` for experiment loops. Use HuggingFace skills for training. Apply `eval-harness` for evaluation frameworks.
- **Infrastructure task:** Lead with `docker-patterns`, `postgres-patterns`, and `deployment-patterns`. Use `/careful` throughout.
- **Agent development:** Apply `agentic-engineering` for tool-use patterns, `autonomous-loops` for continuous execution, `claude-api` for SDK integration.
- **Small bug fix:** Skip Stages entirely. Use the `debug.md` template instead.
