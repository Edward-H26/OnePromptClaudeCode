# Feature Implementation Template

## How to Use

Copy this into Claude Code and replace the placeholders.

```text
[TASK]: What to build, fix, or change.
[DIRECTORY]: Project root to work in.
[REQUIREMENTS]: Requirements document, rubric, or acceptance criteria.
[API]: Optional external API or service.
[AUTH_METHOD]: Optional auth method if the task touches auth.
[FIGMA_URL]: Optional Figma link for UI work.
[TARGET_URL]: Optional local or deployed URL for browser verification.
[REFERENCE_NOTEBOOK]: Optional reference notebook path for methodology or examples.
[DATASET_URL]: Optional dataset or resource URL for domain-specific context.
[DAYS_BACK]: Number of days of git history to analyze (default: 25).
```

## Execution Prompt

ultrathink

You are working in `[DIRECTORY]`: `[DIRECTORY]`

All file reads, searches, edits, tests, and browser checks must stay scoped to `[DIRECTORY]`.

`[TASK]`: [TASK]

Context:
- Requirements: [REQUIREMENTS]
- API: [API]
- Auth method: [AUTH_METHOD]
- Figma: [FIGMA_URL]
- Browser target: [TARGET_URL]
- Reference notebook: [REFERENCE_NOTEBOOK]
- Dataset URL: [DATASET_URL]
- Git history window: [DAYS_BACK]

---

## Phase 0: Interactive Setup

This phase is interactive. Use `AskUserQuestion` prehook gates, one question at a time, each with a "Chat about this" escape hatch. After this phase completes, the pipeline runs autonomously with zero user interaction until the Phase 1 checkpoint.

### Step 0.1: Brainstorm (superpowers:brainstorming)

Explore the user's intent through Socratic conversation before scoping any work.

1. Restate the query in 2-3 sentences to surface misunderstandings early.
2. Ask 2-5 clarifying questions using `AskUserQuestion` covering intent, scope, edge cases, users, constraints, and existing work.
3. Produce a `BRAINSTORM_SUMMARY` capturing confirmed intent, scope, key decisions, edge cases, and constraints.
4. Confirm the summary with the user. If "Almost," incorporate feedback and re-confirm. If "Yes," proceed.

If the query is dead simple and unambiguous (e.g., "add a .gitignore"), skip brainstorming.

### Step 0.2: Intent Profile

Capture the user's quality expectations through 3 direct questions:

1. **Priority**: "What matters most?" (just get it working / solid and correct / ship-ready quality)
2. **Audience**: "Who will use it?" (just me / my team / end users)
3. **Lifespan**: "How long does it need to last?" (throwaway / weeks to months / long-lived)

Map the answers to a `JUDGE_RUBRIC`, a per-dimension strictness matrix. This rubric is the judge's grading contract for the run, so every Ralph quality decision should follow the user's stated intent profile rather than a fixed maximum-strictness default:

| Dimension | Prototype | Balanced | Production |
|-----------|-----------|----------|------------|
| Core functionality | strict | strict | strict |
| Error handling | skip | moderate | strict |
| Edge cases | skip | moderate | strict |
| Code readability | lenient | moderate | strict |
| Security | lenient | moderate | strict |
| Test coverage | happy path only | happy + edges | comprehensive |
| Documentation | skip | inline comments | full docs |

For blended profiles (e.g., "just working" + "end users"), use the highest tier that any answer maps to. User-facing code gets strict security even if the user wants speed.

### Step 0.3: Tooling Discovery

Scan the environment for available skills and agents, match them to the brainstorm summary, and present recommendations.

1. Scan `.claude/skills/` and `.claude/agents/` for all available capabilities.
2. Match available tools to the task domain:
   - Backend work: `backend-dev-guidelines`
   - Frontend work: `frontend-dev-guidelines`
   - UI styling: `ui-styling`, `shadcn-ui`
   - Refactors: `code-refactor`
   - Bugs: `systematic-debugging`
   - Security: `security-review`, `security-scan`
   - Research: `deep-research`
   - Verification: `verification-loop`
   - Browser/E2E: `e2e-testing`, `webapp-testing`
   - HTML deliverables: `web-artifacts-builder`
   - Claude API: `claude-api`
   - Postgres: `postgres-patterns`
   - Docker/deploy: `docker-patterns`, `deployment-patterns`
   - Superpowers plugin skills:
     - `superpowers:brainstorming`, `superpowers:writing-plans`, `superpowers:test-driven-development`
     - `superpowers:executing-plans`, `superpowers:subagent-driven-development`
     - `superpowers:dispatching-parallel-agents`, `superpowers:using-git-worktrees`
     - `superpowers:systematic-debugging`, `superpowers:requesting-code-review`
     - `superpowers:receiving-code-review`, `superpowers:verification-before-completion`
     - `superpowers:finishing-a-development-branch`
3. Present 2-4 recommended tools. Let the user select: recommended set, all available, or just defaults.
4. Store the result as `TOOLING_CONFIG` with active skills, active agents, and skill integration rules.

### Step 0.4: Pre-Flight Scoping

Ask 4 scoping questions to establish `WORKSPACE_RULES`:

1. **Writable directories**: Where to create and modify files.
2. **Read-only context**: Files to read but never modify.
3. **Off-limits**: Files and folders that must never be touched.
4. **Retry limit**: How many retries per task before auto-skipping (default: 6, debug trigger at halfway).

Store as `WORKSPACE_RULES` and inject into every sub-agent prompt.

---

## Phase 1: Analysis, Design, and Planning

Activate `search-first`. If the task touches hooks, skills, templates, commands, agents, plugins, or `.claude/settings.json`, also activate `skill-developer`.

Run Agents 1 and 2 in parallel using `superpowers:dispatching-parallel-agents`. Agent 3 depends on their output. Agent 4 depends on all three.

### Agent 1: Explorer (Deep Codebase Analysis)

Launch an Explore subagent with thoroughness "very thorough" or use `feature-dev:code-explorer`.

- Read every documentation file and map the project architecture.
- Analyze each folder and file to understand how components connect.
- Identify all existing features, patterns, utilities, and conventions.
- Map the tech stack, dependencies, testing infrastructure, and build system.
- Catalog reusable functions and abstractions.

Output: a comprehensive codebase map including architecture, patterns, dependencies, and reusable utilities.

### Agent 2: Researcher (Recent Changes and Domain Context)

Launch an Explore subagent or use `deep-research`.

- Analyze the git history from the past `[DAYS_BACK]` days (`git log --since="[DAYS_BACK] days ago" --stat`).
- Read each commit diff to understand what changed and why.
- Trace how each new feature builds on the existing codebase.
- If `[REFERENCE_NOTEBOOK]` is provided, read it and extract methodology and patterns.
- If `[DATASET_URL]` is provided, use HuggingFace MCP or WebFetch to examine the data.
- Use Context7 MCP (`resolve-library-id`, `query-docs`) for up-to-date documentation on key dependencies.

Output: a changelog analysis with feature evolution, dependency changes, and domain context.

### Agent 3: Critical Reviewer (Requirements Gap Analysis)

Launch a Plan subagent or use `code-review:code-review` and `superpowers:requesting-code-review`.

- Receive the codebase map from Agent 1 and the changelog analysis from Agent 2.
- Check every requirement in `[REQUIREMENTS]` against the current codebase state.
- For quantitative requirements (e.g., "at least 3 examples"), verify the codebase exceeds them.
- Verify each deliverable by reading actual code, not assuming from file names.
- Produce a detailed gap report with file paths and specific deficiencies.

Output: a gap report listing fulfilled requirements, unfulfilled requirements with file paths, and improvement opportunities.

### Agent 4: Architect (Task Decomposition and Design)

Launch a Plan subagent or use `superpowers:writing-plans` and `feature-dev:code-architect`.

- Synthesize output from Agents 1, 2, and 3.
- Break the remaining work into detailed, ordered subtasks (2-5 minutes each).
- For each subtask, specify: exact files to create or modify, design rationale, acceptance criteria, anti-patterns to avoid, and test strategy.
- Reference `TOOLING_CONFIG` to tag tasks with `skills_to_use`.
- Produce a visual outline using Figma MCP `generate_diagram` or a Mermaid diagram when the task involves multiple interacting components.
- Consider `/plan-eng-review` for architecturally complex decisions.

Output: a numbered implementation plan with file paths, code design rationale, risk flags, skill integration points, and a dependency graph.

**Checkpoint**: Confirm the implementation plan and gap report with the user before proceeding. Use `AskUserQuestion` if any requirement is ambiguous. After confirmation, the pipeline runs fully autonomously.

---

## Phase 2: Eval Definition

Before any implementation, define what "done" looks like using eval-driven development.

### Step 2.1: Define Capability Evals

From Agent 4's implementation plan, extract testable success criteria:

```markdown
[CAPABILITY EVAL: feature-name]
Task: Description of what should be accomplished
Success Criteria:
  - [ ] Criterion 1 (specific, testable assertion)
  - [ ] Criterion 2
  - [ ] Criterion 3
Expected Output: Description of expected result
```

### Step 2.2: Define Regression Evals

From Agent 3's gap report and the existing codebase, identify what must not break:

```markdown
[REGRESSION EVAL: feature-name]
Baseline: current state before changes
Tests:
  - existing-test-1: expected PASS
  - existing-test-2: expected PASS
```

### Step 2.3: Set Quality Targets

Based on the `JUDGE_RUBRIC` from Phase 0:

- Capability evals: pass@3 >= 0.90
- Regression evals: pass^3 = 1.00 for release-critical paths
- Use code-based graders for deterministic checks, model-based graders for open-ended outputs.

---

## Phase 3: Implementation (Super Ralph Loop)

The orchestrator decomposes Agent 4's plan into independent tasks using the Super Ralph format. It already has `BRAINSTORM_SUMMARY`, `INTENT_PROFILE`, `JUDGE_RUBRIC`, `TOOLING_CONFIG`, `learnings.md`, codebase context, and `WORKSPACE_RULES`.

### Step 3.1: Initialize Progress File and Read Learnings

Create `claude-progress.txt` in the workspace root as a cross-session state bridge. This file persists across context window resets and ensures no work is lost or repeated if the session compacts.

```markdown
## Progress: [TASK]
Started: {timestamp}
Phase: 3 (Implementation)

### Completed Tasks
(none yet)

### In Progress
(task being worked on)

### Blocked
(auto-skipped tasks with reasons)

### Key Decisions
(architectural choices made during implementation)
```

Update `claude-progress.txt` after every task completes, every debug cycle, and every phase transition.

Read `learnings.md` to extract relevant past insights. If a pattern failed before, do not repeat it.

### Step 3.2: Decompose into Tasks

Break the plan into the smallest independent tasks possible. Each task includes:

```json
{
  "task_id": 1,
  "title": "Short descriptive title",
  "description": "Detailed description with behavior, inputs, outputs, and constraints.",
  "quality_standard": "What excellent looks like. No shortcuts, no TODOs, no stubs.",
  "success_criteria": ["Specific testable assertion 1", "Specific testable assertion 2"],
  "anti_patterns": ["Do not stub the hard parts", "Do not skip error handling"],
  "dependencies": [],
  "dependency_learnings_needed": "What should be extracted from prerequisite tasks before this task starts",
  "test_strategy": "What tests to write, what to assert, what framework to use",
  "skills_to_use": ["skill-name: when and why to invoke"]
}
```

### Step 3.3: Per-Task Execution Loop

Dispatch independent tasks in parallel using multiple foreground Agent tool calls in a single message. Never use `run_in_background`. Tasks with dependencies wait for their dependencies to complete. Before any dependent task starts, extract the relevant learnings from its prerequisite tasks into a concise `PREREQUISITE_LEARNINGS` brief so the fresh sub-agent inherits concrete lessons instead of raw transcript noise.

For each task:

**A. Test Agent + Judge Gate**

```
Loop:
  Dispatch ralph-tester with: task definition + WORKSPACE_RULES + ralph-tester-learnings.md + PREREQUISITE_LEARNINGS (if task has dependencies)
  Tester writes tests to workspace/task-{id}/tests/

  Dispatch ralph-judge with: agent_type "tester", task definition, output location, JUDGE_RUBRIC, WORKSPACE_RULES, BRAINSTORM_SUMMARY
  If judge passes: break to Step B
  If judge fails: dispatch fresh ralph-tester with judge feedback (no retry limit)
```

**B. Worker Agent + Judge Gate + Test Validation**

```
attempt = 0
debug_trigger = MAX_RETRIES / 2

Loop:
  attempt += 1
  Dispatch fresh ralph-worker with: task + tests + failure_context + TOOLING_CONFIG + WORKSPACE_RULES + BRAINSTORM_SUMMARY
    + ralph-worker-learnings.md + PREREQUISITE_LEARNINGS (if task has dependencies)

  Judge gate:
    Dispatch ralph-judge with: agent_type "worker", task, output, JUDGE_RUBRIC, WORKSPACE_RULES, BRAINSTORM_SUMMARY
    If judge fails: dispatch fresh ralph-worker with judge feedback (no retry limit on judge)

  Test validation (after judge passes):
    Run tests via Bash
    If tests pass: clear debug.md, write per-task learnings, proceed
    If tests fail and attempt == debug_trigger: enter self-debugging
    If tests fail and attempt >= MAX_RETRIES: auto-skip, log to learnings, continue
```

**C. Self-Debugging (at MAX_RETRIES/2)**

```
Worker at the debug trigger writes debug.md with full reasoning trail.

Loop:
  Dispatch ralph-debugger with: debug.md + task + WORKSPACE_RULES + ralph-debugger-learnings.md + BRAINSTORM_SUMMARY + PREREQUISITE_LEARNINGS (if task has dependencies)
  Debugger identifies root cause, writes fix plan.

  Dispatch ralph-judge with: agent_type "debugger", task, debug.md, JUDGE_RUBRIC, WORKSPACE_RULES, BRAINSTORM_SUMMARY
  If judge fails: dispatch fresh ralph-debugger with feedback (no retry limit)

Fresh ralph-worker follows the fix plan for remaining attempts.
Still failing at MAX_RETRIES? Auto-skip, log to learnings.
```

**D. Per-Task Learnings**

Immediately after each task completes, write a learnings entry to `learnings.md`:
- Attempt count
- Generalizable insights (not task-specific details)
- Debug insights if debug mode was used

Store per-task learnings for injection into dependent tasks via `PREREQUISITE_LEARNINGS`. Extract only the parts that matter for downstream dependencies, such as interface contracts, integration quirks, shared utility behavior, and failed approaches to avoid.

---

## Phase 4: Validation and Review

### Agent 5: Validator (Baseline and Regression Testing)

Launch a general-purpose subagent or use `verification-loop`, `webapp-testing`, and `e2e-testing`.

- Run the project's test suite, build, and typecheck to establish a post-implementation baseline.
- Re-run all regression evals defined in Phase 2.
- If `[TARGET_URL]` is available, use Playwright MCP to navigate every major page and verify functionality.
- Report any regressions introduced by the changes.
- Run `superpowers:verification-before-completion` to require evidence before any success claims.

Output: a test report with post-change results, eval results, and any regressions.

### Agent 6: Codex Reviewer (Cross-Model Review)

Use the `/codex` skill to invoke cross-model review.

- Run `/codex review` on all changed files for an independent code review.
- Run `/codex challenge` to adversarially stress-test the implementation.
- Check changes against `[REQUIREMENTS]` for completeness.
- Use `code-simplifier` to identify unnecessary complexity.
- If Codex identifies issues, iterate: fix, re-review, repeat until clean.

Output: a Codex review report with all findings addressed.

### Agent 7: Visual Verifier (Browser Testing Loop)

Launch a general-purpose subagent or use `/orchestrate` with Chrome MCP and Playwright MCP.

When `[TARGET_URL]` is available and the task affects visible UI:

- Use Playwright MCP (`browser_navigate`, `browser_snapshot`, `browser_take_screenshot`) or Chrome MCP (`navigate`, `read_page`, `javascript_tool`, `gif_creator`) to test every feature end-to-end.
- Simulate real user workflows: navigate pages, fill forms, click buttons, verify outputs.
- Compare screenshots against the design intent or expected behavior.
- If the visual output does not match the specification:
  - Diagnose the specific gap (layout, spacing, color, interaction).
  - Make targeted CSS/component fixes.
  - Re-navigate and re-screenshot to verify the fix.
- For responsive testing, use `browser_resize` to check multiple viewport sizes.
- If any feature fails, dispatch a sub-agent to fix it using `superpowers:dispatching-parallel-agents` for independent fixes.
- If stuck after 3 attempts on any issue, auto-skip and log.
- Use `/qa` for structured browser QA testing when comprehensive coverage is needed.

Output: an end-to-end test report with evidence (screenshots, GIF recordings) showing all features working.

---

## Phase 5: Merge, Learn, and Deliver

### Step 5.1: Merge Outputs + Judge Gate

```
Loop:
  Dispatch ralph-merger with: all task outputs + notes + WORKSPACE_RULES + BRAINSTORM_SUMMARY + JUDGE_RUBRIC
  Merger combines outputs into workspace/final/, resolves integration issues.

  Dispatch ralph-judge with: agent_type "merger", task definitions, output, JUDGE_RUBRIC, WORKSPACE_RULES, BRAINSTORM_SUMMARY
  If judge passes: break to Step 5.2
  If judge fails: dispatch fresh ralph-merger with judge feedback (no retry limit)
```

### Step 5.2: Run Summary to learnings.md

Append a run summary to `learnings.md`:

```markdown
## {date} -- {original user query (shortened)}

**Result:** {passed}/{total} tasks passed | **Attempts:** {total_attempts} | **Time:** {elapsed}

### Run Summary
- {1-2 sentence overview of what was built and how it went}

### Cross-Task Patterns
- {pattern that emerged across multiple tasks}
- {architectural insight from how the pieces fit together}

### Anti-Patterns to Avoid
- {approach that failed, only if it is a trap others would fall into}
```

### Step 5.3: Final Eval Report

Run all capability and regression evals from Phase 2 against the final merged output:

```markdown
EVAL REPORT: [TASK]
========================
Capability Evals: X/Y passed (pass@k: Z%)
Regression Evals: X/Y passed (pass^3: Z%)
Status: SHIP IT / NEEDS WORK
```

### Step 5.4: Documentation Update

Launch the `documentation-system` agent or use `/document-release`.

- Update README, ARCHITECTURE, CONTRIBUTING, and project-specific documentation.
- Add setup instructions for new dependencies or configuration.
- Update referenced screenshots or examples that changed.
- Remove references to deleted features or outdated patterns.

### Step 5.5: Branch Finalization

Use `superpowers:finishing-a-development-branch` to handle merge/PR decisions and cleanup.

---

## Pipeline Dispatch Pattern

```
Phase 0 (interactive setup):
  Brainstorm -> Intent Profile -> Tooling Discovery -> Pre-Flight
  [user confirms -> fully autonomous from here]

Phase 1 (parallel analysis):
  Agent 1 (Explorer)  --+
  Agent 2 (Researcher) -+---> Agent 3 (Reviewer) ---> Agent 4 (Architect)
                         |
                    [user checkpoint]

Phase 2 (eval definition):
  Capability Evals + Regression Evals + Quality Targets

Phase 3 (Super Ralph autonomous loop):
  Per Task (parallel if independent):
    ralph-tester -> JUDGE -> ralph-worker -> JUDGE -> tests
                                |                    |
                                +--- debug loop -----+
    Per-task learnings -> dependency injection for dependent tasks

Phase 4 (validation):
  Agent 5 (Validator) ---> Agent 6 (Codex) ---> Agent 7 (Visual Verifier)
                              |                      |
                              +--- fix loop ---------+

Phase 5 (merge and deliver):
  ralph-merger -> JUDGE -> Eval Report -> Documenter -> Branch Finalization
```

Use `superpowers:dispatching-parallel-agents` for Agents 1 and 2. Use `superpowers:subagent-driven-development` for the Phase 4 sequential pipeline. Use `superpowers:verification-before-completion` before declaring Phase 4 complete.

---

## Expected Deliverable

Return:
- The plan you followed
- Files changed and why
- Eval report with pass@k and regression results
- Evidence from browser verification (screenshots, GIFs) if applicable
- Learnings summary from the run
- Risks, assumptions, or follow-up items

## Harness Engineering Principles

These principles govern how the pipeline operates as an agent harness, the infrastructure layer that wraps around AI models to manage long-running tasks reliably.

1. **Generator/Judge separation**: Never trust the builder to grade its own work. Every sub-agent's output passes through ralph-judge before the loop continues. The judge operates with zero context from the generator, eliminating bias and sunk-cost reasoning.

2. **Automate verification, not review**: Wherever a property can be verified automatically (tests, typechecks, evals, screenshots), delegate more responsibility to the agent. Invest in automated checks rather than reading every line of agent-generated code. Human review focuses on invariants, edge cases, security assumptions, and hidden coupling.

3. **Progress file bridging**: `claude-progress.txt` carries state across context window resets. Update it after every task, debug cycle, and phase transition. If the session compacts, the progress file is the recovery point, not conversation history.

4. **Two-tier learning**: Per-task learnings in `learnings.md` flow forward to dependent tasks in real-time. Per-agent learnings (`ralph-*-learnings.md`) make each agent type individually smarter across runs. Both tiers persist only generalizable insights, not task-specific details.

5. **Cost-aware routing**: Track per task: model tier, token estimate, retries, wall-clock time, success/failure. Escalate model tier only when a lower tier fails with a clear reasoning gap. Use Haiku for classification and narrow edits, Sonnet for implementation, Opus for architecture and root-cause analysis.

6. **Eval-first execution**: Define capability evals and regression evals before implementation (Phase 2). Run them continuously during validation (Phase 4). Track pass@k metrics for reliability measurement. Evals are the unit tests of agent development.

## Guardrails

- Stay inside `[DIRECTORY]`.
- Prefer repo-local scripts, docs, and config over home-directory conventions.
- Keep the user as the sole author of any future commit. Do not commit or push.
- Do not invent mandatory phases, agents, plugin actions, or MCP methods that are not present in the current environment.
- After Phase 0 completes, the pipeline runs without user interaction. Failed tasks are auto-skipped and logged. No escalations, no confirmations, no interruptions.
- Never use `run_in_background: true` when dispatching agents. Dispatch multiple foreground agents in a single message to parallelize.
