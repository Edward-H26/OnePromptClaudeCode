# Super Ralph Template

## How to Use

Fully autonomous multi-agent implementation. Super Ralph decomposes the task, spawns specialized agents, self-debugs, and merges results.

```text
[TASK]: Describe the feature, fix, or change you want built.
[DIRECTORY]: The project directory to work in (e.g., /path/to/project).
[CONSTRAINTS]: Any constraints (e.g., "no new dependencies", "must pass existing tests", "backend only").
```

## Execution Prompt

You are working in the project directory: **[DIRECTORY]**

**Task:** [TASK]

**Constraints:** [CONSTRAINTS]

Invoke `/super-ralph` and read the local wrapper at `$CLAUDE_PROJECT_DIR/.claude/skills/super-ralph/SKILL.md`. Then use the bundled Super Ralph files under `$CLAUDE_PROJECT_DIR/.claude/skills/super-ralph/` and run the full autonomous loop.

Before launching, use available tools to set up the context:

1. Apply `search-first` to deeply explore the codebase in [DIRECTORY]. Map the project structure, tech stack, conventions, and test infrastructure before Ralph begins.
2. Use Context7 MCP: call `resolve-library-id` and `query-docs` for every significant dependency so Ralph's agents have up-to-date API docs.
3. If the project has a database, use MongoDB MCP (`collection-schema`, `collection-indexes`) or apply `postgres-patterns` to understand the data layer.
4. Use repo file search and reads to get a structural overview Ralph can reference.
5. Use Memory MCP: call `search_nodes` to check for prior architectural decisions or constraints relevant to this task.
6. Consider activating `/careful` if the task touches critical systems, or `/freeze [MODULE_DIR]` to restrict edits to a specific module.

Super Ralph will then autonomously:

**Phase 1: Brainstorm** — Explore alternatives, evaluate tradeoffs, select the best approach. Ralph may use `office-hours` or `plan-eng-review` internally for complex features.

**Phase 2: Pre-flight** — Verify the repo builds, tests pass, and the starting state is clean.

**Phase 3: Decompose** — Break the task into independent subtasks with clear boundaries. Each subtask gets assigned to a specialized Ralph agent:
- `ralph-worker` for implementation
- `ralph-tester` for test writing and coverage
- `ralph-debugger` for fixing failures
- `ralph-judge` for quality evaluation
- `ralph-merger` for combining results

**Phase 4: Execute** — Agents work in parallel where possible. Each agent has access to the full tool ecosystem:
- Backend work uses `backend-dev-guidelines`, `docker-patterns`, `postgres-patterns`, `deployment-patterns`
- Frontend work uses `frontend-dev-guidelines`, `ui-styling`, `liquid-glass-design`, `e2e-testing`
- All agents can use Context7 MCP, MongoDB MCP, Chrome MCP, Playwright MCP, Figma MCP as needed
- Testing uses `tdd-workflow`, `verification-loop`, `/qa` for browser testing
- Security checks use `security-review` and `security-scan`

**Phase 5: Merge** — Combine all agent outputs, resolve conflicts, run the full verification suite.

**Phase 6: Learn** — Record what worked and what did not for future sessions.

After Ralph completes, run these additional verification steps:

1. Run `/quality-gate` to validate the combined output against quality criteria.
2. Run `/codex review` for an independent cross-model review of all changes.
3. Consider `/codex challenge` to adversarially stress-test the result.
4. Use Chrome MCP or Playwright MCP to verify any UI changes in the browser.
5. Use the `verification-loop` skill for a final structured 6-phase check.
6. Run `/checkpoint` to save the verified state.

Rules:

- Do not git commit or push. The user owns all commits.
- If Ralph gets stuck (3 failed attempts on any subtask), it escalates with BLOCKED status.
- All work stays within [DIRECTORY].
- Respect [CONSTRAINTS] throughout the entire process.
- After completion, suggest `/retro` to the user if the task was significant.
- Consider `/document-release` if the changes warrant documentation updates.
