# Multi-Plan

Create a repo-local implementation plan using the workflow assets and installed plugins that actually exist in this workspace.

$ARGUMENTS

## Contract

- Planning only. Read files, explore, and write or update a plan in `plans/`.
- Do not modify production code from this command.
- Prefer repo-local tools, bundled scripts, and installed plugin agents.

## Toolchain For This Repo

- Local exploration with file search and reads
- `feature-dev:code-explorer` for deep parallel exploration
- `feature-dev:code-architect` when architecture tradeoffs need a second pass
- `superpowers:writing-plans` when a more formal task breakdown is useful
- `"$CLAUDE_PROJECT_DIR/.claude/skills/codex/scripts/ask_codex.sh" --read-only` for one bounded Codex second opinion after local exploration

## Workflow

1. Clarify the task enough to define success criteria and scope boundaries.
2. Explore the relevant code, docs, hooks, commands, and settings before forming a plan.
3. Use plugin agents only for analysis and planning. Do not offload file edits from this command.
4. If Codex is useful, run a single read-only planning call through the bundled script and fold the result into the final plan.
5. Save the plan to `plans/<slug>.md`. Reuse and update an existing plan file if one already fits the task.
6. Present the saved path and the plan summary to the user. Stop there.

## Required Plan Shape

Every saved plan should include:
- Summary
- Success criteria
- Key files and why they matter
- Ordered implementation steps
- Verification steps
- Risks and assumptions

## Rules

- Do not rely on personal wrapper binaries outside this repo.
- Do not rely on external prompt packs outside this repo.
- Do not rely on `ace-tool`, wrapper-specific session IDs, or background-task control primitives.
- Use repo-local paths and installed plugins only.
