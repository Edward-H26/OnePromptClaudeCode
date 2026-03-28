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
2. If Context7 is configured locally, call `resolve-library-id` and `query-docs` for every significant dependency. Otherwise use the repo docs and web fetches that are available in the environment.
3. If the project has a database, use any available repo-specific database connector or apply `postgres-patterns` to understand the data layer.
4. Use repo file search and reads to get a structural overview Ralph can reference.
5. Use Memory MCP: call `search_nodes` to check for prior architectural decisions or constraints relevant to this task.
6. Consider activating `/careful` if the task touches critical systems, or `/freeze [MODULE_DIR]` to restrict edits to a specific module.

Super Ralph will then autonomously:

**Phase 1: Brainstorm** — Restate the request, ask clarifying questions, and confirm a `BRAINSTORM_SUMMARY` so task decomposition reflects explored user intent instead of the raw query.

**Phase 2: Intent + Tooling + Pre-flight** — Capture the intent profile, derive a `JUDGE_RUBRIC`, scan available skills and agents, and lock workspace boundaries plus retry limits.

**Phase 3: Decompose** — Break the task into independent subtasks with clear boundaries, explicit dependencies, success criteria, anti-patterns, and test strategy. Each subtask gets assigned to a specialized Ralph agent:
- `ralph-worker` for implementation
- `ralph-tester` for test writing and coverage
- `ralph-debugger` for fixing failures
- `ralph-judge` for intent-aware quality evaluation
- `ralph-merger` for combining results

**Phase 4: Execute** — Agents work in parallel where possible. The judge evaluates each output against the task definition and the `JUDGE_RUBRIC`, so grading matches the user's stated priority, audience, and lifespan. Tasks with dependencies receive extracted prerequisite learnings from completed upstream tasks before implementation retries continue. Each agent has access to the full tool ecosystem:
- Backend work uses `backend-dev-guidelines`, `docker-patterns`, `postgres-patterns`, `deployment-patterns`
- Frontend work uses `frontend-dev-guidelines`, `ui-styling`, `liquid-glass-design`, `e2e-testing`
- All agents can use Context7 MCP, Chrome MCP, Playwright MCP, Figma MCP, and any repo-specific database connector when those integrations are configured locally
- Testing uses `tdd-workflow`, `verification-loop`, `/qa` for browser testing
- Security checks use `security-review` and `security-scan`

**Phase 5: Merge** — Combine all agent outputs, resolve conflicts, run the full verification suite, and keep the merged result aligned with the same intent-aware quality bar.

**Phase 6: Learn** — Write per-task and per-agent learnings. Dependency learnings are summarized and passed forward to downstream tasks instead of leaving each fresh sub-agent to rediscover prior mistakes.

After Ralph completes, run these additional verification steps:

1. Run `/quality-gate` to validate the combined output against quality criteria.
2. Run `/codex review` for an independent cross-model review of all changes.
3. Consider `/codex challenge` to adversarially stress-test the result.
4. Use available browser tooling, such as Chrome MCP or Playwright MCP when configured locally, to verify any UI changes in the browser.
5. Use the `verification-loop` skill for a final structured 6-phase check.
6. Run `/checkpoint` to save the verified state.

Rules:

- Do not git commit or push. The user owns all commits.
- After the interactive setup, Ralph runs autonomously without asking more questions.
- If a task still fails after the configured retry limit, auto-skip it and log the reason plus learnings.
- All work stays within [DIRECTORY].
- Respect [CONSTRAINTS] throughout the entire process.
- After completion, suggest `/retro` to the user if the task was significant.
- Consider `/document-release` if the changes warrant documentation updates.
