---
name: super-ralph
description: Autonomous agentic loop that decomposes any user query into tasks, writes tests first, implements with fresh sub-agents, self-debugs on failure, and learns over time. Use when the user says "super ralph", "ralph this", "break this down and build it", or wants autonomous multi-task execution with quality enforcement.
---

# Super Ralph

Autonomous agentic loop: decompose → test → build → debug → learn → merge.

## Quick Reference

```
User Query
  → Brainstorm: interactive Q&A to explore intent, scope, edge cases (AskUserQuestion loop)
  → Intent Profile: 3 questions (priority, audience, lifespan) → JUDGE_RUBRIC
  → Tooling: scan available skills/agents, ask user about goals, assemble custom toolset
  → Pre-Flight: scope workspace + set MAX_RETRIES (AskUserQuestion)
  → Decompose: orchestrator breaks query into tasks directly (no separate manager/planner agent)
  → Per Task (parallel if independent — never use run_in_background):
      → ralph-tester: write tests → JUDGE: pass? → retry tester if fail
      → ralph-worker: implement → JUDGE: pass? → retry worker if fail → run tests
      → Fail MAX_RETRIES/2? → debug.md → ralph-debugger → JUDGE: pass? → fresh ralph-worker
      → Fail MAX_RETRIES? → auto-skip + log to learnings
      → Pass → clear debug.md
  → ralph-merger: combine outputs → JUDGE: pass? → retry merger if fail → deliver
```

## Agents

| Agent | File | Role |
|-------|------|------|
| ralph-tester | `agents/ralph-tester.md` | Writes strict tests before implementation |
| ralph-worker | `agents/ralph-worker.md` | Implements until tests pass, writes debug.md on attempt 3 |
| ralph-debugger | `agents/ralph-debugger.md` | Cold analysis of failures, writes fix plan |
| ralph-judge | `agents/ralph-judge.md` | Universal quality gate — evaluates every sub-agent's output against task criteria |
| ralph-merger | `agents/ralph-merger.md` | Combines outputs into cohesive deliverable |

**Note:** Planning/decomposition is handled directly by the orchestrator (this skill), not a separate manager or planner agent. The orchestrator already has the brainstorm summary, tooling config, learnings, and codebase context, so an extra control layer would just duplicate work.

**Note:** The ralph-judge agent evaluates every sub-agent's output before the loop continues. If the judge rejects, the same agent is retried with the judge's specific feedback. There is no retry limit on judge rejections — the agent keeps retrying until the judge passes. Each retry is a fresh agent with zero prior context.

---

## IMPORTANT: Fully Autonomous After Pre-Flight

After Phase 0, the entire loop runs **without any user interaction**. No `AskUserQuestion` calls, no confirmations, no escalations. If something fails after max retries, auto-skip it and log to learnings. The user said "go ahead" — respect that.

---

## Phase -1: Brainstorm (BLOCKING — prehook-style interactive Q&A)

Before scoping the workspace or planning tasks, **explore the user's idea through conversation**. The goal is to deeply understand what the user actually wants — not just what they typed.

**This phase is interactive.** Use `AskUserQuestion` as prehook gates — one question at a time, each with a "Chat about this" escape hatch that fully stops the workflow.

### Prehook Rules (apply to ALL setup phases: Brainstorm, Tooling, Pre-Flight)

- **One question at a time** — never batch multiple unrelated questions
- **Every question MUST include a "Chat about this" option** that fully stops the workflow
- **If "Chat about this" is selected:** stop completely, read what the user says, and respond. Do NOT continue the setup. Resume only when they explicitly say to.
- **Never skip a question** — even if you think you know the answer
- **Never proceed past a phase** until the user explicitly approves

### How it works

1. **Restate the query** — show the user your understanding of what they're asking for in 2-3 sentences. This surfaces misunderstandings early.

2. **Ask clarifying questions** — use `AskUserQuestion` as prehook gates:

```
question: "[Specific question about the user's intent, scope, or approach]"
header: "Clarify"
options:
  - label: "[Most likely answer]"
    description: "[What this means for the build]"
  - label: "[Alternative interpretation]"
    description: "[What this means for the build]"
  - label: "[Simpler/narrower version]"
    description: "[What this means for the build]"
  - label: "Chat about this"
    description: "Stop — I want to discuss this before deciding"
multiSelect: false
```

3. **Explore iteratively** — after each answer, ask follow-up questions if new ambiguities surface. Cover these areas:

| Area | Example Questions |
|------|-------------------|
| **Intent** | "Is this a prototype or production-grade?" |
| **Scope** | "Should this include X, or is that out of scope?" |
| **Edge cases** | "What should happen when Y occurs?" |
| **Users** | "Who will use this — just you, your team, or end users?" |
| **Constraints** | "Any specific tech stack, libraries, or patterns to use/avoid?" |
| **Existing work** | "Is this building on something that already exists, or greenfield?" |

4. **Produce a brainstorm summary** — when you have enough clarity, write a summary:

```markdown
## Brainstorm Summary

**Query:** {original user query}
**Intent:** {what the user actually wants, in your words}

### Scope
- {what's in scope}
- {what's explicitly out of scope}

### Key Decisions
- {decision 1 from the Q&A}
- {decision 2 from the Q&A}

### Edge Cases Discussed
- {edge case and agreed handling}

### Constraints
- {any tech/approach constraints from the user}
```

5. **Confirm the summary** — show the summary to the user with one final `AskUserQuestion`:

```
question: "Here's what I'll build. Does this capture it?"
header: "Confirm"
options:
  - label: "Yes, go ahead"
    description: "This is right — proceed to workspace setup and autonomous execution"
  - label: "Almost — let me adjust"
    description: "I'll clarify what needs changing"
  - label: "Chat about this"
    description: "Stop — I want to discuss this before deciding"
multiSelect: false
```

If "Almost" → incorporate feedback, update summary, re-confirm. If "Yes" → store the summary as `BRAINSTORM_SUMMARY` and proceed to Phase -0.75 (Intent Profile).

### Rules

- Ask **2-5 questions total** — enough to remove ambiguity, not so many it feels like an interrogation
- Batch related questions into a single `AskUserQuestion` when possible (up to 4 per call)
- Don't ask questions the user already answered in their original query
- Don't ask about workspace scope here — that's Phase 0's job
- If the query is dead simple and unambiguous (e.g., "add a .gitignore"), skip brainstorming entirely

### Passing the summary forward

The `BRAINSTORM_SUMMARY` is used by the orchestrator during task decomposition (Phase 1) alongside learnings, tooling config, and workspace rules. This ensures tasks are decomposed based on the *explored, confirmed intent* — not just the raw query.

---

## Phase -0.75: Intent Profile (BLOCKING — after brainstorm, before tooling)

After confirming the brainstorm summary, capture the user's **intent profile** through 3 direct questions. The answers determine how strictly the judge grades every agent's output — a prototype gets lenient judging on polish, a production system gets strict on everything.

### How it works

Ask these 3 questions using `AskUserQuestion` prehook gates. Each includes a "Chat about this" escape hatch.

**Question 1 — Priority:**
```
question: "What matters most for this build?"
header: "Priority"
options:
  - label: "Just get it working"
    description: "Speed over polish — I need something functional fast"
  - label: "Solid and correct"
    description: "Take the time to handle errors and edge cases properly"
  - label: "Ship-ready quality"
    description: "Production-grade — clean code, full error handling, security"
  - label: "Chat about this"
    description: "Stop — I want to discuss this before deciding"
multiSelect: false
```

**Question 2 — Audience:**
```
question: "Who will use what gets built?"
header: "Audience"
options:
  - label: "Just me"
    description: "Personal tool — I know the quirks, no need for polish"
  - label: "My team"
    description: "Others will read and maintain this code"
  - label: "End users"
    description: "Real people will interact with this — UX and reliability matter"
  - label: "Chat about this"
    description: "Stop — I want to discuss this before deciding"
multiSelect: false
```

**Question 3 — Lifespan:**
```
question: "How long does this need to last?"
header: "Lifespan"
options:
  - label: "Throwaway / experiment"
    description: "Use it once or twice, then toss it"
  - label: "Weeks to months"
    description: "Needs to work reliably for a while"
  - label: "Long-lived"
    description: "This will be maintained and extended over time"
  - label: "Chat about this"
    description: "Stop — I want to discuss this before deciding"
multiSelect: false
```

### Building the INTENT_PROFILE

Store the answers as `INTENT_PROFILE`:

```markdown
## Intent Profile

**Priority:** [just working | solid and correct | ship-ready]
**Audience:** [just me | my team | end users]
**Lifespan:** [throwaway | weeks to months | long-lived]
```

### Generating the JUDGE_RUBRIC

Map the intent profile to a `JUDGE_RUBRIC` — a per-dimension strictness matrix that tells the judge how hard to grade each quality dimension. Use this mapping:

| Dimension | Just working + Just me + Throwaway | Solid + Team + Weeks | Ship-ready + End users + Long-lived |
|-----------|-------------------------------------|----------------------|--------------------------------------|
| Core functionality | **strict** | **strict** | **strict** |
| Error handling | skip | moderate | **strict** |
| Edge cases | skip | moderate | **strict** |
| Code readability | lenient | moderate | **strict** |
| Security | lenient | moderate | **strict** |
| Test coverage | happy path only | happy + edges | comprehensive |
| Documentation | skip | inline comments | full docs |

**Strictness levels:**
- **strict** — judge FAILS output that doesn't meet this dimension
- **moderate** — judge NOTES issues but passes if core functionality is solid
- **lenient** — judge ignores this dimension unless it's egregiously bad
- **skip** — judge does not evaluate this dimension at all

**Blended profiles:** When the 3 answers don't all point to the same tier (e.g., "just get it working" + "end users" + "long-lived"), use the **highest tier that any answer maps to** for each dimension. User-facing and long-lived code gets strict security even if the user wants speed — that's a safety floor.

Store the result as `JUDGE_RUBRIC`:

```markdown
## Judge Rubric

| Dimension | Strictness |
|-----------|------------|
| Core functionality | strict |
| Error handling | [strict/moderate/lenient/skip] |
| Edge cases | [strict/moderate/lenient/skip] |
| Code readability | [strict/moderate/lenient/skip] |
| Security | [strict/moderate/lenient/skip] |
| Test coverage | [comprehensive/happy + edges/happy path only] |
| Documentation | [full docs/inline comments/skip] |
```

### Passing forward

The `JUDGE_RUBRIC` is injected into every ralph-judge dispatch alongside the task definition and WORKSPACE_RULES. It tells the judge what to care about and how much — adapted to this specific user's intent.

### Skip condition

If brainstorming was skipped (dead simple query), default to the middle tier: **solid and correct + my team + weeks to months**.

---

## Phase -0.5: Tooling Discovery (BLOCKING — after intent profile, before pre-flight)

After understanding *what* the user wants to build, figure out *what tools will help build it*. Scan available skills and agents, match them to the user's goals, and let the user confirm or adjust the toolset.

### How it works

#### Step 1: Scan available skills and agents

Search for all available skills and agents in the environment:

```bash
# Scan for skills
find ~/.claude/skills/ -name "SKILL.md" 2>/dev/null
find .claude/skills/ -name "SKILL.md" 2>/dev/null

# Scan for agents
find ~/.claude/agents/ -name "*.md" 2>/dev/null
find .claude/agents/ -name "*.md" 2>/dev/null

# Also check for project-local skills
find . -path "*/.claude/skills/*/SKILL.md" 2>/dev/null
```

Read the `name` and `description` fields from each discovered skill/agent file. Build an inventory:

```
AVAILABLE_SKILLS:
- frontend-design: Create distinctive, production-grade frontend interfaces
- system-arch: Plan major architecture changes and evaluate patterns
- claude-api: Build apps with the Claude API or Anthropic SDK
- doc-search: Search third-party API documentation before writing code
- ...

AVAILABLE_AGENTS:
- code-reviewer: Validate work against plan and coding standards
- root-cause-hunter: Drive root-cause analysis for failures
- integration-test-validator: Comprehensive testing validation
- ...
```

#### Step 2: Match tools to the user's goals

Based on the `BRAINSTORM_SUMMARY`, identify which skills and agents would be useful. Consider:

| User's Goal | Relevant Tools |
|------------|----------------|
| Building a frontend/UI | `frontend-design`, `landing-page` |
| API development | `doc-search`, `claude-api`, `system-arch` |
| Complex architecture | `system-arch`, `validation`, `debate` |
| Refactoring | `code-reviewer`, `integration-test-validator` |
| Using third-party APIs | `doc-search` (auto-fetch docs before coding) |
| Full-stack app | `frontend-design`, `system-arch`, `doc-search` |

#### Step 3: Present recommendations to user

Show the matched tools and let the user select which to activate for this run:

```
question: "Based on what you're building, these skills/agents could help. Which should I use during this run?"
header: "Tooling"
options:
  - label: "[Recommended set]"
    description: "Use {skill-1}, {skill-2}, {agent-1} — covers {reason}"
  - label: "All available"
    description: "Activate everything — I'll use whatever helps"
  - label: "Just the defaults"
    description: "Only use Ralph's 4 built-in agents, no extra skills"
  - label: "Chat about this"
    description: "Stop — I want to discuss this before deciding"
multiSelect: false
```

If the user picks "Recommended set" or "All available", also ask if there are specific tools they want to add or exclude:

```
question: "Anything to add or exclude from the toolset?"
header: "Adjust"
options:
  - label: "Looks good — proceed"
    description: "Use the selected toolset as-is"
  - label: "Add a skill"
    description: "I'll name a specific skill or capability to include"
  - label: "Remove something"
    description: "I'll say what to exclude"
  - label: "Chat about this"
    description: "Stop — I want to discuss this before deciding"
multiSelect: false
```

#### Step 4: Build TOOLING_CONFIG

Store the selected toolset as `TOOLING_CONFIG`:

```markdown
## Tooling Config

### Active Skills
- {skill-name}: {how it will be used in this run}
- {skill-name}: {how it will be used in this run}

### Active Agents (beyond Ralph defaults)
- {agent-name}: {when to invoke during the run}

### Skill Integration Rules
- {skill-name} → invoke before {phase/step} (e.g., "doc-search → invoke before ralph-worker writes API calls")
- {skill-name} → invoke during {phase/step} (e.g., "frontend-design → invoke when ralph-worker builds UI components")
```

### How TOOLING_CONFIG is used

The config is used by the orchestrator and injected into sub-agent prompts:

- **Orchestrator** uses `TOOLING_CONFIG` during task decomposition to tag tasks with `skills_to_use` (e.g., "Use `doc-search` to check the Stripe API before implementing payment logic")
- **ralph-worker** gets the skill integration rules so it knows when to invoke skills during implementation (e.g., invoke `frontend-design` before building a component, invoke `doc-search` before calling a third-party API)
- **ralph-merger** gets the list so it can note which tools were used in the summary report

### Rules

- Don't overwhelm the user — recommend 2-4 tools max, not every skill in the system
- If no extra skills are relevant (e.g., the task is pure backend with standard libraries), say so and suggest "Just the defaults"
- Skills that the user's project already has in its local `.claude/skills/` take priority over global ones
- If a skill would clearly help but isn't installed, mention it: "You don't have a {X} skill, but it might help here. Want to skip it or create one?"
- If the brainstorm summary makes the tooling obvious (e.g., "build a landing page" → `landing-page` skill), pre-select it as the recommended option

---

## Phase 0: Pre-Flight Scoping (BLOCKING — prehook-style workspace setup)

Before any agent runs, scope the workspace using `AskUserQuestion` prehook gates — one question at a time, each with "Chat about this." This is the last interactive phase before full autonomy.

**Question 1 — Writable directories:**
```
question: "Which files/folders should I work in? (I'll create and modify files here)"
header: "Work in"
options:
  - label: "Current directory"
    description: "Work in the current project root and subdirectories"
  - label: "Specific paths"
    description: "I'll list the exact directories/files"
  - label: "Chat about this"
    description: "Stop — I want to discuss this before deciding"
multiSelect: false
```

**Question 2 — Read-only context:**
```
question: "Any files I should read for context but NOT modify?"
header: "Read-only"
options:
  - label: "None — figure it out"
    description: "Explore the codebase yourself"
  - label: "I'll list them"
    description: "Specific files/dirs to read but not touch"
  - label: "Chat about this"
    description: "Stop — I want to discuss this before deciding"
multiSelect: false
```

**Question 3 — Off-limits:**
```
question: "Anything off-limits? (files/folders I must never touch)"
header: "Off-limits"
options:
  - label: "Nothing off-limits"
    description: "You can work anywhere within the writable scope"
  - label: "I'll list exclusions"
    description: "Specific paths to avoid"
  - label: "Chat about this"
    description: "Stop — I want to discuss this before deciding"
multiSelect: false
```

**Question 4 — Retry limit per task:**
```
question: "How many retries per task before giving up?"
header: "Max retries"
options:
  - label: "6 (default)"
    description: "3 normal attempts + debug analysis + 3 more attempts"
  - label: "4"
    description: "2 normal attempts + debug analysis + 2 more attempts"
  - label: "10"
    description: "5 normal attempts + debug analysis + 5 more attempts"
  - label: "Chat about this"
    description: "Stop — I want to discuss this before deciding"
multiSelect: false
```

Store the retry limit as `MAX_RETRIES`. The debug trigger fires at `MAX_RETRIES / 2` (halfway). After `MAX_RETRIES` total attempts, auto-skip.

Store the answers as `WORKSPACE_RULES` — inject into every sub-agent prompt:

```
WORKSPACE RULES:
- You may READ and WRITE files in: [writable paths]
- You may READ (not modify): [read-only paths]
- Do NOT touch: [off-limits paths]
- HARD BOUNDARY: You must NEVER access files outside the paths listed above. No reading, writing, or executing commands that touch anything outside the project directory. This is non-negotiable.
- All permissions granted within these boundaries — do not ask for confirmation on any action.
```

---

## Phase 1: Plan & Decompose (orchestrator does this directly)

The orchestrator decomposes the query itself — no separate manager/planner agent needed. It already has everything: BRAINSTORM_SUMMARY, INTENT_PROFILE, TOOLING_CONFIG, learnings, codebase context, and WORKSPACE_RULES.

### Step 1: Gather context

1. Read `learnings.md` — extract relevant past insights (per-task entries + run summaries). If a pattern failed before, don't repeat it.
2. Read the scoped codebase files to understand existing patterns and conventions.

### Step 2: Decompose into tasks

Break the query into the smallest independent tasks possible. Apply these principles:

- **Set the bar HIGH** — every task must produce work worth shipping
- **Be specific, not vague** — "handles edge cases" is useless. "Returns 404 with JSON error body when resource not found" is testable.
- **Prevent laziness upfront** — anti-patterns tell the worker what NOT to do before they start cutting corners
- **Smallest independent units** — if a task can be split further without creating artificial dependencies, split it
- **Reference available skills** — use TOOLING_CONFIG to tag tasks with `skills_to_use` where relevant

Output a JSON task array:

```json
[
  {
    "task_id": 1,
    "title": "Short descriptive title",
    "description": "Detailed description of what to build. Be explicit about behavior, inputs, outputs, and constraints.",
    "quality_standard": "What 'excellent' looks like. Be specific. No shortcuts, no TODOs, no stubs. Production-grade or it doesn't count.",
    "success_criteria": [
      "Specific testable outcome — an assertion, not a wish",
      "Another specific testable outcome"
    ],
    "anti_patterns": [
      "Don't stub or mock the hard parts",
      "Don't skip error handling",
      "Don't leave TODOs or placeholder logic"
    ],
    "dependencies": [],
    "test_strategy": "What tests to write, what to assert, what framework to use",
    "skills_to_use": ["skill-name — when and why to invoke it during this task"]
  }
]
```

### Quality rules for decomposition

- Success criteria must be **assertions** — things a test can verify, not feelings
- Anti-patterns should target the **most common lazy shortcuts** for this specific task
- If a task touches existing code, specify which files and what the expected behavior change is
- If a task has no dependencies, say `"dependencies": []` — don't invent false dependencies
- Each task should be completable by a single agent in one session
- If you're unsure whether something should be one task or two, make it two

### Step 3: Set up workspace

```bash
mkdir -p workspace/task-{id}/tests workspace/task-{id}/output
```

### Step 4: Dispatch tasks

Dispatch independent tasks **in parallel** by making multiple Agent tool calls in a single message. Tasks with dependencies wait for their dependencies to complete first. **Never use `run_in_background: true`** — instead, dispatch multiple foreground agents concurrently.

---

## CRITICAL: Agent Dispatch Rule

**Never set `run_in_background: true`** when dispatching agents via the Agent tool. Background agents cannot prompt the user for tool permission approvals (WebSearch, WebFetch, Bash, etc.), causing tools to be auto-denied and agents to fail silently.

**To parallelize:** dispatch multiple foreground agents in a single message (multiple Agent tool calls). They run concurrently and can each prompt for tool permissions. Use this for independent tasks with no shared dependencies.

---

## Phase 2: Per-Task Execution Loop

For each task from the orchestrator. **Parallelize independent tasks** by dispatching multiple foreground agents in a single message (no shared dependencies). Never use `run_in_background`.

### Step 2a: Test Agent + Judge Gate

```
while true:
    Dispatch ralph-tester with: task definition + WORKSPACE_RULES
      + ralph-tester-learnings.md (agent-specific learnings from past runs)

    Tester writes tests to workspace/task-{id}/tests/ and reports the test command.

    Dispatch ralph-judge with:
      agent_type: "tester"
      task definition + output location (workspace/task-{id}/tests/) + JUDGE_RUBRIC + WORKSPACE_RULES

    if judge passes:
        break → proceed to Step 2b
    else:
        Dispatch fresh ralph-tester with:
          original prompt + "JUDGE REJECTED YOUR PREVIOUS OUTPUT:\n{judge_verdict}\nFix these issues."
        (loop until judge passes — no retry limit)
```

### Step 2b: Worker Agent (with judge gate + test validation + retry loop)

```
attempt = 0
debug_trigger = MAX_RETRIES / 2   # e.g. 3 if MAX_RETRIES=6

while true:
    attempt += 1

    if attempt == 1:
        failure_context = ""
    else:
        failure_context = "PREVIOUS ATTEMPT FAILED:\n{last_test_output}\n\nFix the root cause."

    if attempt == debug_trigger:
        Add to prompt: "This is attempt {debug_trigger}. You MUST write debug.md before exiting."

    Dispatch fresh ralph-worker with:
      task definition + test locations + failure_context + TOOLING_CONFIG + WORKSPACE_RULES
      + ralph-worker-learnings.md (agent-specific learnings from past runs)
      + PREREQUISITE_LEARNINGS (if task has dependencies — from completed prerequisite tasks)

    # ── Judge gate (runs BEFORE tests) ──────────────────────────
    while true:
        Dispatch ralph-judge with:
          agent_type: "worker"
          task definition + output location (workspace/task-{id}/output/) + JUDGE_RUBRIC + WORKSPACE_RULES

        if judge passes:
            break → proceed to test validation
        else:
            Dispatch fresh ralph-worker with:
              original prompt + "JUDGE REJECTED YOUR PREVIOUS OUTPUT:\n{judge_verdict}\nFix these issues."
            (loop until judge passes — no retry limit)

    # ── Test validation (runs AFTER judge passes) ───────────────
    Run tests via Bash: {test_command}

    if tests pass:
        break → clear debug.md if it exists

    if attempt == debug_trigger and tests still fail:
        enter Phase 2c (self-debugging)

    if attempt >= MAX_RETRIES:
        enter Phase 2c Step 4 (auto-skip)
```

### Step 2c: Test Validator

Run tests via Bash after each worker attempt (only reached if judge already passed):
- **Pass** → clear debug.md, proceed to Step 2d
- **Fail** → increment attempt counter, retry worker with failure output

### Step 2d: Per-Task Learnings (after task passes)

Immediately after a task passes all tests, the orchestrator writes a learnings entry to `learnings.md`:

```markdown
### {date} — Task {id}: {title}
- **Attempts:** {attempt_count}
- **Learnings:**
  - {generalizable insight from this task — NOT task-specific details}
  - {library gotcha, pattern that worked, or assumption that was wrong}
- **Debug insights:** {root cause if debug mode was used, otherwise "N/A"}
```

**Rules for per-task learnings:**
- Only write **general insights** that would help future runs — not "I implemented X using Y"
- If the task passed on attempt 1 with no issues, write: "Clean pass — no notable learnings."
- If debug mode was used, always include the root cause as a learning
- Keep each entry to 2-5 bullet points max

**Store the per-task learnings in memory** for passing to dependent tasks.

### Step 2e: Inject Learnings into Dependent Tasks

When dispatching a task that has dependencies, include the learnings from completed prerequisite tasks in the prompt:

```
Dispatch ralph-tester/worker with:
  task definition + WORKSPACE_RULES + ...
  + PREREQUISITE_LEARNINGS:
    "Task 1 (Auth endpoint) learned:
     - bcrypt.hashpw() returns bytes, must decode to UTF-8 before storing
     - Always use constant-time comparison for password verification"
```

This gives dependent tasks context from the work that came before them — without polluting independent parallel tasks with irrelevant information.

---

## Phase 2c: Self-Debugging (after MAX_RETRIES/2 failed attempts)

### Step 1: debug.md already written
The worker at attempt `MAX_RETRIES/2` writes `debug.md` with all attempts so far, reasoning, and pattern analysis.

### Step 2: Fresh Debug Agent + Judge Gate

```
while true:
    Dispatch ralph-debugger with: debug.md + task definition + WORKSPACE_RULES
      + ralph-debugger-learnings.md (agent-specific learnings from past runs)
    Debugger reads debug.md cold, identifies root cause, appends fix plan.

    Dispatch ralph-judge with:
      agent_type: "debugger"
      task definition + debug.md + JUDGE_RUBRIC + WORKSPACE_RULES

    if judge passes:
        break → proceed to Step 3
    else:
        Dispatch fresh ralph-debugger with:
          original prompt + "JUDGE REJECTED YOUR FIX PLAN:\n{judge_verdict}\nRevise it."
        (loop until judge passes — no retry limit)
```

### Step 3: Fresh Worker follows fix plan (with judge gate)
Dispatch fresh **ralph-worker** (attempts `MAX_RETRIES/2 + 1` through `MAX_RETRIES`) with debug.md. Worker follows the fix plan exactly.

The worker's output goes through the same judge gate as Step 2b (judge must pass before tests run).

Run tests again:
- **Pass** → clear debug.md, continue to next task
- **Fail after attempt MAX_RETRIES** → auto-skip (Step 4)

### Step 4: Auto-Skip (MAX_RETRIES reached, still failing)

**Do NOT ask the user.** The loop is fully autonomous after pre-flight.

1. Mark the task as **FAILED**
2. Write a per-task learnings entry to `learnings.md` (include the root cause from debug.md if available)
3. Keep the task's failure trail (attempts, debug analysis) in memory for the merger
4. Continue with remaining tasks — do not stop the loop

---

## Phase 3: Merge, Learn & Deliver

After ALL tasks complete, dispatch **ralph-merger** in the **foreground** (never background) with:
- All task titles, statuses, attempt counts, and output directories
- Per-task notes: what worked, what failed, debug insights (passed in prompt, not in learnings.md)
- WORKSPACE_RULES

### Step 3a: Merge outputs + Judge Gate

```
while true:
    Dispatch ralph-merger with: task outputs + notes + WORKSPACE_RULES

    Merger combines outputs into workspace/final/, resolves integration issues.

    Dispatch ralph-judge with:
      agent_type: "merger"
      task definitions + output location (workspace/final/) + JUDGE_RUBRIC + WORKSPACE_RULES

    if judge passes:
        break → proceed to Step 3b
    else:
        Dispatch fresh ralph-merger with:
          original prompt + "JUDGE REJECTED YOUR DELIVERABLE:\n{judge_verdict}\nFix these issues."
        (loop until judge passes — no retry limit)
```

### Step 3b: Write Run Summary to learnings.md

Per-task learnings were already written during Phase 2 (Step 2d). The merger now appends a **run summary** that ties them together:

```markdown
## {date} — {original user query (shortened)}

**Result:** {passed}/{total} tasks passed | **Attempts:** {total_attempts} | **Time:** {elapsed}

### Run Summary
- {1-2 sentence overview of what was built and how it went}

### Cross-Task Patterns
- {pattern that emerged across multiple tasks — e.g., "all 3 tasks hit the same bcrypt gotcha"}
- {architectural insight from how the pieces fit together}

### Anti-Patterns to Avoid
- {approach that failed across tasks — only if it's a trap others would fall into}
```

**Rules for the run summary:**
- This is a **summary**, not a repeat of per-task learnings — add cross-cutting insights only
- Include timing so future runs can estimate duration for similar queries
- If all tasks passed cleanly on first attempt, keep it minimal:
  ```markdown
  ## {date} — {query}
  **Result:** {N}/{N} passed | **Attempts:** {N} | **Time:** {elapsed}
  Clean run — no cross-task patterns to note.
  ```
- The per-task entries (written in Step 2d) provide the detail; this provides the big picture

### Step 3c: Clear debug.md

If debug.md was used during the run, clear it:
```
_Empty — ready for next debug session._
```

debug.md is a scratch pad. learnings.md is the permanent record.

### Step 3d: Summary report

Produce the summary report and present it to the user. The merged output in `workspace/final/` is the deliverable.
