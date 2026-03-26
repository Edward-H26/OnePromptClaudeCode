---
name: strategic-compact
description: Repo-local wrapper for context compaction. Summarize active repo state without relying on global Claude home files.
---

# Strategic Compact

Use this skill when context pressure is high and the task needs a clean continuation point.

## Repo Rules

- Summarize the current repo state, decisions, and open work from this task only.
- Do not rely on `~/.claude` memory files or global compact helpers.
- Keep the compact output actionable for the next turn or next engineer.

## Workflow

1. Capture the goal, current state, and important decisions.
2. List the exact remaining work and blockers.
3. Keep the summary short, concrete, and repo-specific.
