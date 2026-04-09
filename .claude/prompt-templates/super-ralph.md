# Super Ralph Template

## How to Use

Fully autonomous multi-agent implementation. Super Ralph decomposes the task, spawns specialized agents, self-debugs, and merges results. Two modes: **oneshot** (zero-setup, fully autonomous) and **brainstorm** (interactive Q&A before execution).

```text
[TASK]: Describe the feature, fix, or change you want built.
[DIRECTORY]: The project directory to work in (e.g., /path/to/project).
[CONSTRAINTS]: Any constraints (e.g., "no new dependencies", "must pass existing tests", "backend only").
[MODE]: oneshot (default) or brainstorm.
[TYPE]: feature (default), debug, refactor, review, or security-audit.
```

## Execution Prompt

You are working in the project directory: **[DIRECTORY]**

**Task:** [TASK]

**Constraints:** [CONSTRAINTS]

**Mode:** [MODE]

**Type:** [TYPE]

Invoke `/super-ralph` and read the local wrapper at `.claude/skills/super-ralph/SKILL.md`. Then use the bundled Super Ralph files under `.claude/skills/super-ralph/` and run the full autonomous loop.

### Pre-Launch Context Setup

Before Ralph begins its phases, gather context so the tooling discovery and task decomposition have real data to work with.

**Codebase exploration:**
1. Apply `search-first` to deeply explore the codebase in [DIRECTORY]. Map the project structure, tech stack, conventions, and test infrastructure.
2. Use repo file search and reads to build a structural overview Ralph can reference during decomposition.

**Dependency documentation (when available):**
3. If Context7 MCP is configured locally, call `resolve-library-id` and `query-docs` for every significant dependency. Otherwise use web fetches and repo docs.

**Data layer (when applicable):**
4. If the project has a database, use any available database MCP connector or apply `postgres-patterns` to understand the schema and query patterns.

**Safety scoping:**
5. Consider activating `/careful` if the task touches critical systems, or `/freeze [MODULE_DIR]` to restrict edits to a specific module.

### Task Type Guidance

The [TYPE] parameter shapes how Ralph decomposes and executes the task:

**feature** (default): Full build cycle. Ralph decomposes into implementation subtasks, writes tests first, builds, and merges. Uses the standard tester/worker/judge/merger agent pipeline.

**debug**: Root-cause analysis and fix. Before decomposition, Ralph:
1. Activates `systematic-debugging` or `/investigate` to force root-cause analysis before any fix attempt.
2. Reproduces the issue with the smallest reliable command, test, or browser flow.
3. If `[DIRECTORY]` has a specific module at fault, applies `/freeze` to restrict edits.
4. Decomposes the fix into: reproduce test, root-cause identification, minimal fix, regression test.
5. Uses `ralph-debugger` early (not just at MAX_RETRIES/2) since debugging is the primary activity.

**refactor**: Behavior-preserving structural improvement. Ralph:
1. Maps all usages before editing. Activates `code-refactor` for controlled, scoped transformations.
2. Decomposes into independent refactoring units that can be tested in isolation.
3. Each subtask must prove behavior is unchanged via existing or new tests.
4. `ralph-judge` evaluates against "no behavior change" as the primary criterion.
5. Summarizes files changed and residual risks in the merge report.

**review**: Read-only code review, no edits. Ralph:
1. Activates `security-review` for application risks and `security-scan` for config/workflow risks.
2. Decomposes the codebase into review zones (auth, data flow, API surface, config, etc.).
3. Each `ralph-worker` reviews its zone and produces findings ordered by severity.
4. `ralph-merger` consolidates findings into a single report with deduplicated issues.
5. No files are modified. Output is a structured report with file references and fix direction.

**security-audit**: Deep security-focused review. Ralph:
1. Activates both `security-review` and `security-scan`.
2. Decomposes into OWASP categories: injection, auth/access, secrets exposure, config hardening, dependency risks.
3. Each subtask scans its category and produces findings with severity, evidence, and remediation.
4. `ralph-merger` produces a consolidated security report with prioritized action items.
5. No files are modified unless [CONSTRAINTS] explicitly say "fix found issues."

### Mode Selection

If [MODE] is **oneshot**, pass the mode preference to Ralph so it skips the mode selection question and enters oneshot mode directly:
- Ralph auto-analyzes the query, infers intent/scope/constraints, and writes the `BRAINSTORM_SUMMARY` silently.
- Defaults to middle-tier intent: solid and correct, team audience, weeks-to-months lifespan.
- Auto-selects the recommended toolset from available skills and agents.
- Scopes to [DIRECTORY] as writable with MAX_RETRIES=6.
- Proceeds directly to autonomous execution with zero further questions.

If [MODE] is **brainstorm**, Ralph asks clarifying questions through its interactive prehook sequence before going autonomous.

### Ralph Phases

**Phase -2: Mode Selection** — Single question: Oneshot, Brainstorm, or Chat. Skipped if [MODE] is specified.

**Phase -1: Brainstorm** — Restate the request, ask clarifying questions, and confirm a `BRAINSTORM_SUMMARY`. In oneshot mode, Ralph auto-analyzes the query silently and proceeds.

**Phase -0.75: Intent Profile** — Three questions (priority, audience, lifespan) that generate a `JUDGE_RUBRIC` controlling how strictly the judge grades every agent output. In oneshot mode, defaults to middle tier.

**Phase -0.5: Tooling Discovery** — Scans all available skills and agents in the environment, matches them to the task, and builds a `TOOLING_CONFIG`. This is where Ralph selects from the repo's full skill inventory:

| Task Domain | Skills Ralph May Select |
|------------|------------------------|
| Backend/API | `backend-dev-guidelines`, `docker-patterns`, `deployment-patterns`, `claude-api` |
| Frontend/UI | `frontend-dev-guidelines`, `ui-styling`, `liquid-glass-design`, `shadcn-ui` |
| Design Intelligence | `ui-ux-pro-max` (style selection, color palettes, font pairing, UX guidelines, design system generation) |
| Database | `postgres-patterns` |
| Testing | `tdd-workflow`, `e2e-testing`, `python-testing` |
| Security | `security-review`, `security-scan` |
| Design | `design-consultation`, frontend-design plugin |
| Architecture | architect agent, architecture-review-system agent |
| Debugging | `systematic-debugging`, `investigate` |

Ralph also picks from the 14 local agents (architect, build-error-resolver, code-refactor-master, database-reviewer, frontend-developer, frontend-error-fixer, etc.) and installed plugin agents (code-review, code-simplifier, feature-dev).

**Phase 0: Pre-Flight** — Locks workspace boundaries, read-only paths, off-limits paths, and MAX_RETRIES. In oneshot mode, uses [DIRECTORY] as writable scope with 6 retries.

**Phase 1: Decompose** — Breaks the task into independent subtasks with explicit dependencies, success criteria, anti-patterns, and test strategy. Tags each task with `skills_to_use` from the TOOLING_CONFIG.

**Phase 2: Execute** — Per-task loop, parallel where independent:
- `ralph-tester` writes adversarial tests (happy path, edge cases, failure modes)
- `ralph-judge` evaluates every output against the JUDGE_RUBRIC (no retry limit)
- `ralph-worker` implements until tests pass, gets failure context on retries
- At MAX_RETRIES/2: worker writes `debug.md`, then `ralph-debugger` does cold root-cause analysis
- At MAX_RETRIES: auto-skip, log to learnings
- Learnings from completed tasks flow forward to dependent tasks

**Phase 3: Merge and Learn** — `ralph-merger` combines all outputs, resolves conflicts, produces the deliverable in `workspace/final/`. Writes per-task learnings and a cross-task run summary to `learnings.md`.

### Post-Completion Verification

After Ralph delivers, run these verification steps:

1. `/quality-gate` to validate the combined output against quality criteria.
2. `/codex review` for an independent cross-model review of all changes.
3. `/codex challenge` to adversarially stress-test the result (optional but recommended for ship-ready work).
4. If UI changes: use Chrome MCP, Playwright MCP, or `/qa` for browser verification.
5. `verification-loop` skill for a structured 6-phase check (build, type, lint, test, security, diff).
6. `/checkpoint` to save the verified state.

### Post-Completion Suggestions

After verification, consider:
- `/retro` if the task was significant, to capture workflow lessons.
- `/document-release` if the changes warrant documentation updates.
- `/simplify` to review the output for unnecessary complexity.
- `/review-staff` for a staff-engineer-level code review pass.

### Rules

- Do not git commit or push. The user owns all commits.
- After setup completes, Ralph runs fully autonomously with zero user interaction.
- Failed tasks auto-skip at MAX_RETRIES and log the reason plus learnings.
- All work stays within [DIRECTORY]. Respect [CONSTRAINTS] throughout.
- Never use `run_in_background: true` for agent dispatch. Parallelize with multiple foreground Agent calls in a single message.
- Every sub-agent output passes through `ralph-judge` before proceeding. No retry limit on judge rejections.
- Fresh agent context per dispatch. No shared state, no sunk-cost reasoning.
