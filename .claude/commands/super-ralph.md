---
description: "Autonomous agentic loop — decompose, test, build, debug, learn, merge"
argument-hint: "QUERY"
---

# /super-ralph

The user wants to run the Super Ralph autonomous agentic loop.

Use the local wrapper skill at `.claude/skills/super-ralph/SKILL.md` as the entrypoint. That wrapper routes into the bundled Super Ralph source that ships inside this repo.

Start from:
- `$CLAUDE_PROJECT_DIR/.claude/skills/super-ralph/commands/super-ralph.md`
- `$CLAUDE_PROJECT_DIR/.claude/skills/super-ralph/skills/super-ralph/SKILL.md`
- `$CLAUDE_PROJECT_DIR/.claude/skills/super-ralph/agents/`

The bundled workflow handles everything:

1. Brainstorm (interactive Q&A to explore intent, scope, and edge cases with the user)
2. Tooling discovery (scan available skills/agents, recommend a custom toolset for the run)
3. Pre-flight scoping (ask user about workspace boundaries)
4. Once user says "go ahead" → **fully autonomous from here, zero questions**
5. Decompose the query into tasks with high quality standards (using selected skills/agents)
6. For each task: write tests first, then implement until tests pass
7. Self-debug on failure (debug.md → cold analysis → retry)
8. Auto-skip tasks that fail after 6 attempts (log to learnings)
9. Capture learnings to learnings.md
10. Merge all outputs into a cohesive deliverable

The user's query is: ${ARGUMENTS}

**Start by following the bundled Super Ralph workflow now.**
