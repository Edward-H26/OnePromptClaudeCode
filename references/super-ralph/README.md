# Super Ralph

Autonomous agentic loop plugin for Claude Code. Give it a query, answer 4 setup questions, and walk away. It decomposes your request into tasks, writes tests first, implements with fresh sub-agents, self-debugs when stuck, and learns from every run.

## How It Works

```
You: "/super-ralph build me a REST API with auth and rate limiting"

Super Ralph:
  0. Brainstorm ── interactive Q&A to explore your intent, scope, and edge cases
  0.25 Intent  ── 3 questions (priority, audience, lifespan) → shapes how strictly outputs are judged
  0.5 Tooling  ── scans available skills/agents, recommends a custom toolset for the run
  1. Pre-Flight ── asks 4 setup questions (workspace scope + retry limit)
  2. Plan       ── decomposes query into independent tasks with high quality bar
  3. Per Task   ── test agent writes strict tests → worker implements → tests validate
  4. Debug      ── if stuck at halfway mark, writes debug.md → fresh debugger analyzes cold → retry
  5. Learn      ── every outcome (pass or fail) logged to learnings.md
  6. Merge      ── combines all task outputs into one cohesive deliverable
  7. Deliver    ── summary report + merged output in workspace/final/
```

After brainstorming and pre-flight, the entire loop runs **fully autonomously** with zero user interaction. Failed tasks are auto-skipped and logged. No escalations, no confirmations, no interruptions.

---

## Architecture

### The Loop

```
User Query
  -> Brainstorm: interactive Q&A with user (explore intent, scope, edge cases)
  -> Intent Profile: 3 questions (priority, audience, lifespan) → JUDGE_RUBRIC
  -> Tooling: scan skills/agents, recommend toolset, user confirms
  -> Pre-Flight: scope workspace + set MAX_RETRIES
  -> Decompose: orchestrator breaks query into tasks directly (no separate agent)
  -> Per Task (parallel if independent):
      -> ralph-tester: write tests -> JUDGE: pass? (retry tester if fail, no limit)
      -> ralph-worker: implement -> JUDGE: pass? (retry worker if fail, no limit) -> run tests
         -> attempt 1..MAX_RETRIES/2: normal retries with failure context
         -> at MAX_RETRIES/2: worker writes debug.md (full reasoning trail)
         -> ralph-debugger: write fix plan -> JUDGE: pass? (retry debugger if fail)
         -> attempt MAX_RETRIES/2+1..MAX_RETRIES: fresh worker follows fix plan
         -> still failing at MAX_RETRIES? auto-skip, log to learnings
      -> Pass -> capture learnings, clear debug.md
  -> ralph-merger: combine outputs -> JUDGE: pass? (retry merger if fail) -> deliver
```

### Agents

Super Ralph uses 5 specialized sub-agents, each dispatched as a fresh process with no shared context (prevents bias and sunk-cost reasoning). Task decomposition is handled directly by the orchestrator — it already has all the context it needs.

| Agent | Type | Role |
|-------|------|------|
| **ralph-tester** | `opus` | Writes adversarial tests before any implementation exists. Covers happy path, edge cases, and failure modes. All tests runnable with a single command. |
| **ralph-judge** | `opus` | Universal quality gate. Evaluates every sub-agent's output against the task definition's quality standard, success criteria, and anti-patterns. Returns PASS or FAIL with specific feedback. No retry limit — agents keep going until the judge is satisfied. |
| **ralph-worker** | `opus` | Reads tests first, then implements production-grade code. On retries, gets failure context. At the debug trigger, writes `debug.md` with full reasoning trail. |
| **ralph-debugger** | `opus` | Cold failure analyst. Reads `debug.md` with zero bias. Identifies the shared wrong assumption across all failed attempts. Writes a concrete, step-by-step fix plan. |
| **ralph-merger** | `opus` | Combines independently-built task outputs into one cohesive deliverable. Resolves import conflicts, naming collisions, and missing glue code. Produces summary report. |

---

## Brainstorming

Before anything else, Super Ralph explores your idea through interactive Q&A:

1. **Restates your query** -- shows its understanding so you can catch misunderstandings early
2. **Asks clarifying questions** -- intent, scope, edge cases, constraints, users (2-5 questions)
3. **Produces a summary** -- captures the confirmed intent, scope, key decisions, and constraints
4. **You confirm** -- "yes, go ahead" or "let me adjust"

The brainstorm summary feeds directly into the orchestrator, so tasks are decomposed based on *explored, confirmed intent* -- not just the raw query. If the query is dead simple, brainstorming is skipped.

---

## Intent-Driven Judging

After brainstorming, Super Ralph asks 3 questions to understand what you actually care about:

1. **Priority** -- "What matters most?" → just get it working / solid and correct / ship-ready quality
2. **Audience** -- "Who will use it?" → just me / my team / end users
3. **Lifespan** -- "How long does it need to last?" → throwaway / weeks to months / long-lived

These answers produce a **JUDGE_RUBRIC** -- a per-dimension strictness matrix that tells the judge how hard to grade each quality dimension:

| Dimension | Prototype (fast + me + throwaway) | Balanced (solid + team + months) | Production (ship-ready + users + long-lived) |
|-----------|----------------------------------|----------------------------------|----------------------------------------------|
| Core functionality | strict | strict | strict |
| Error handling | skip | moderate | strict |
| Edge cases | skip | moderate | strict |
| Code readability | lenient | moderate | strict |
| Security | lenient | moderate | strict |
| Test coverage | happy path only | happy + edges | comprehensive |
| Documentation | skip | inline comments | full docs |

**Why this matters:** A prototype shouldn't fail the judge for missing edge-case tests. A production system should. The user's intent shapes the quality bar instead of always demanding maximum strictness.

**Blended profiles:** When answers don't all point to the same tier (e.g., "just get it working" + "end users"), the rubric uses the highest tier that any answer maps to. User-facing code gets strict security even if the user wants speed -- that's a safety floor.

---

## Tooling Discovery

After brainstorming, Super Ralph scans your environment for available skills and agents, then assembles a custom toolset for the run:

1. **Scans** -- finds all skills in `~/.claude/skills/`, `.claude/skills/`, and project-local skill directories, plus all available agents
2. **Matches** -- compares what you're building (from the brainstorm summary) to what each skill/agent does
3. **Recommends** -- presents 2-4 relevant tools (e.g., `frontend-design` for UI work, `doc-search` for third-party APIs, `system-arch` for complex architecture)
4. **You confirm** -- pick the recommended set, activate everything, or stick with Ralph's 5 default agents only

The selected tools become the `TOOLING_CONFIG`, which is injected into agent prompts:
- The **orchestrator** references available skills in task definitions (e.g., "use `doc-search` before calling the Stripe API")
- The **worker** invokes skills at the right moment during implementation
- The **merger** notes which tools were used in the summary report

This means Super Ralph adapts to your project's tech stack and available capabilities instead of always using the same fixed pipeline.

---

## Pre-Flight Setup

After brainstorming, Super Ralph asks exactly 4 questions to scope the workspace:

**1. Writable directories** -- Where should it create and modify files?
- Current directory (default)
- Specific paths you list

**2. Read-only context** -- Files to read for context but never modify?
- None (figure it out)
- Specific files you list

**3. Off-limits** -- Files/folders it must never touch?
- Nothing off-limits
- Specific exclusions you list

**4. Retry limit** -- How many retries per task before auto-skipping?
- 4 (2 normal + debug + 2 more)
- 6 (3 normal + debug + 3 more) -- default
- 10 (5 normal + debug + 5 more)
- Or type any number

These answers become `WORKSPACE_RULES` injected into every sub-agent prompt. After brainstorming and pre-flight, the loop runs without asking anything else.

---

## Task Decomposition

The orchestrator doesn't just split work -- it sets a quality bar. Each task includes:

```json
{
  "task_id": 1,
  "title": "User authentication endpoint",
  "description": "POST /auth/login accepting email+password, returning JWT...",
  "quality_standard": "Production-grade. Proper bcrypt hashing, constant-time comparison, token expiry...",
  "success_criteria": [
    "Returns 200 with valid JWT for correct credentials",
    "Returns 401 with JSON error body for wrong password",
    "Returns 422 for missing email field",
    "JWT expires after configured TTL"
  ],
  "anti_patterns": [
    "Don't store passwords in plaintext",
    "Don't skip input validation",
    "Don't use hardcoded secrets"
  ],
  "dependencies": [],
  "test_strategy": "pytest with httpx test client, mock database layer"
}
```

Independent tasks run in parallel. Tasks with dependencies wait.

---

## Self-Debugging

The most interesting part. When a worker fails at the halfway mark (e.g., attempt 3 of 6):

**Step 1 -- Worker writes `debug.md`**

A full reasoning trail: what was tried in each attempt, why, and what failed. Plus a pattern analysis asking "what assumption did all attempts share?"

**Step 2 -- Fresh debugger reads it cold**

A brand new agent with zero context reads `debug.md`. No ego, no sunk cost. It reads the actual tests, actual code, and actual errors. Then identifies the root cause -- not "the test failed" but "the function assumes UTC but receives local time."

**Step 3 -- Fix plan**

The debugger appends a concrete, step-by-step fix plan to `debug.md`:

```markdown
## Fix Plan

**Root cause identified:** Parser assumes single-line input but test sends multiline
**Why previous attempts failed:** All 3 used line-by-line processing
**Correct approach:** Read entire input as buffer, split on record delimiter
**Step-by-step:**
1. Replace readline() with read()
2. Split on '\n\n' (record separator)
3. Process each record as a unit
```

**Step 4 -- Fresh worker follows the plan exactly**

A new worker gets `debug.md` and follows the fix plan. If this succeeds, `debug.md` is cleared. If it still fails after `MAX_RETRIES`, the task is auto-skipped.

---

## Learning System

Two files with different purposes:

| File | Purpose | Lifecycle |
|------|---------|-----------|
| `debug.md` | Scratch pad for active debugging | Written during debug, cleared after every run |
| `learnings.md` | Permanent memory across runs | Per-task entries + run summaries, read by orchestrator before every run |
| `ralph-*-learnings.md` | Per-agent memory | Each agent's own insights, read by that agent before each dispatch |

### Two-tier learning system

**Tier 1: `learnings.md`** -- system-level learnings written in real-time during execution.

Each task writes its learnings **immediately after completing** (not at the end). Tasks with dependencies receive learnings from their prerequisite tasks, so knowledge flows forward. At the end, the merger adds a run summary with timing.

```markdown
### 2026-03-07 -- Task 1: Auth endpoint
- **Attempts:** 2
- **Learnings:**
  - python-jose expects different decode params than PyJWT
  - Always set token expiry with UTC timestamps, not local time
- **Debug insights:** N/A

### 2026-03-07 -- Task 2: Rate limiter
- **Attempts:** 1
- **Learnings:**
  - Clean pass — no notable learnings.
- **Debug insights:** N/A

## 2026-03-07 -- REST API with auth and rate limiting
**Result:** 3/3 passed | **Attempts:** 5 | **Time:** 12m
### Run Summary
- Built auth, rate limiting, and DB schema for a REST API
### Cross-Task Patterns
- Middleware ordering matters — auth must run before rate limiting
```

**Tier 2: Per-agent learnings** -- each agent maintains its own learnings file with insights specific to its role:

| File | What it captures |
|------|-----------------|
| `ralph-tester-learnings.md` | Test framework gotchas, effective test patterns, edge cases easy to miss |
| `ralph-worker-learnings.md` | Implementation patterns, library quirks, approaches that work |
| `ralph-debugger-learnings.md` | Common root causes, diagnostic shortcuts, shared wrong assumptions |
| `ralph-judge-learnings.md` | Calibration notes, false-fail patterns, evaluation edge cases |
| `ralph-merger-learnings.md` | Integration conflict patterns, glue code approaches, naming mismatches |

Each agent reads its own learnings before starting work and writes a new entry if it learned something generalizable. Over time, each agent gets individually smarter at its specific job.

### Dependency-based learning flow

When tasks have dependencies, learnings flow forward:

```
Task 1 (auth) completes → writes learnings
Task 3 (depends on 1) → gets Task 1's learnings injected into its prompt
```

This means dependent tasks benefit from what earlier tasks discovered -- without polluting independent parallel tasks with irrelevant context.

### General, not specific

All learnings (both tiers) must be **generalizable** -- insights that would help a different future run. "SQLAlchemy async sessions must be closed explicitly" is good. "I implemented the auth endpoint using bcrypt" is not. The orchestrator reads `learnings.md` before every new run to avoid repeating mistakes.

---

## Usage

### Slash Command

```
/super-ralph build a CLI tool that converts CSV to JSON with streaming support
```

### Natural Language

Just say "ralph this" or "break this down and build it" in any conversation.

### Examples

```
/super-ralph add user authentication with JWT, refresh tokens, and rate limiting

/super-ralph refactor the payment module into separate services with proper error handling

/super-ralph build a real-time notification system with WebSocket, email, and SMS channels

/super-ralph create a CLI that scaffolds new projects from templates with plugin support
```

---

## Install

### As a Claude Code Plugin

Clone and add to your Claude Code configuration:

```bash
git clone https://github.com/ashcastelinocs124/super-ralph.git ~/.claude/skills/super-ralph
```

### Manual

Copy the files into your `~/.claude/skills/` directory and ensure the plugin manifest is recognized by Claude Code.

---

## Project Structure

```
super-ralph/
  .claude-plugin/
    plugin.json              # Plugin manifest (name, description, version)
  commands/
    super-ralph.md           # /super-ralph slash command entry point
  skills/
    super-ralph/
      SKILL.md               # Orchestrator — the full loop logic
  agents/
    ralph-tester.md          # Adversarial test-first agent
    ralph-judge.md           # Universal quality gate — evaluates all sub-agent output
    ralph-worker.md          # Implementation agent with retry + debug.md
    ralph-debugger.md        # Cold failure analysis agent
    ralph-merger.md          # Integration and merge agent
  docs/
    plans/                   # Design docs and implementation plans
  learnings.md               # Persistent cross-run memory
  README.md                  # This file
```

---

## Judge System

Every sub-agent's output goes through **ralph-judge** before the loop continues. The judge evaluates output against the task definition's quality standard, success criteria, and anti-patterns.

```
tester → JUDGE → pass? ──► worker → JUDGE → pass? ──► run tests
              │ fail                      │ fail
              └─ retry tester             └─ retry worker
                 (with feedback)             (with feedback)

debugger → JUDGE → pass? ──► worker retries with fix plan
                │ fail
                └─ retry debugger

merger → JUDGE → pass? ──► deliver
              │ fail
              └─ retry merger
```

**Key properties:**
- **Intent-driven rubric** -- the judge grades each dimension (error handling, security, test coverage, etc.) at the strictness level set by the user's intent profile. A prototype gets lenient grading on polish; a production system gets strict on everything.
- **No retry limit** -- agents keep going until the judge is satisfied
- **Specific feedback** -- on rejection, the judge returns exactly what's wrong and what "good" looks like
- **Fresh evaluation** -- judge starts with zero context each time, no bias from previous evaluations
- **Adapts per agent type** -- checks different criteria for testers (adversarial coverage), workers (anti-patterns, production quality), debuggers (actionable fix plans), and mergers (integration completeness)

---

## Design Principles

- **Single control layer** -- no separate manager or planner agent. The orchestrator already has brainstorm summary, tooling config, and learnings, so splitting control responsibilities would just add handoff overhead and lose context.
- **Judge everything** -- every sub-agent's output passes through ralph-judge before the loop continues. No retry limit -- agents keep going until the quality bar is met.
- **Fresh agents per task** -- no context pollution between tasks. Each sub-agent starts clean.
- **Test-first** -- tests are written before implementation. They define "done," not the worker's opinion.
- **Adversarial quality** -- anti-patterns in task definitions prevent common lazy shortcuts before they happen.
- **Cold debugging** -- the debugger has zero context from failed attempts. That's its superpower -- no bias.
- **Brainstorm first** -- interactive Q&A explores intent, scope, and edge cases before any autonomous work begins.
- **Prehook setup** -- all setup questions use prehook-style gates with "Chat about this" escape hatches.
- **Intent-driven quality** -- the judge's strictness adapts to what the user actually cares about (priority, audience, lifespan), not a fixed bar.
- **One-shot autonomy** -- after brainstorming and setup, zero user interaction. Failed tasks are auto-skipped, not escalated.
- **Two-tier learning** -- per-task learnings written in real-time to `learnings.md` (with dependency-based forwarding), plus per-agent learnings files (`ralph-*-learnings.md`) for role-specific insights.
- **Configurable retry depth** -- you control how many test-failure attempts per task. Debug triggers at the halfway point.

---

## License

MIT
