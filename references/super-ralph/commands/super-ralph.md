---
description: "Autonomous agentic loop — decompose, test, build, debug, learn, merge"
argument-hint: "QUERY"
---

# /super-ralph

The user wants to run the Super Ralph autonomous agentic loop.

> Additive Codex note: this file is the Claude slash-command entrypoint. In Codex environments without slash commands, trigger the same flow when the user says "super ralph", "ralph this", or equivalent, and pass the user request as the query argument to the `super-ralph` skill.

**Invoke the `super-ralph` skill immediately** with the user's query. The skill handles everything:

1. Mode selection (oneshot or brainstorm — single question)
2. Brainstorm (if brainstorm: interactive Q&A; if oneshot: auto-analyzed silently)
3. Tooling discovery (scan available skills/agents, recommend or auto-select toolset)
4. Pre-flight scoping (if brainstorm: ask about workspace; if oneshot: use defaults)
5. Once setup completes → **fully autonomous from here, zero questions**
6. Decompose the query into tasks with high quality standards (using selected skills/agents)
7. For each task: write tests first, then implement until tests pass
8. Self-debug on failure (debug.md → cold analysis → retry)
9. Auto-skip tasks that fail after 6 attempts (log to learnings)
10. Capture learnings to learnings.md
11. Merge all outputs into a cohesive deliverable

The user's query is: ${ARGUMENTS}

**Start by invoking the super-ralph skill now.**
