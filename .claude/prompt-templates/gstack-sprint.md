# gstack Sprint Template

## How to Use

Copy this into Claude Code and replace the placeholders.

```text
[GOAL]: What to accomplish.
[DIRECTORY]: Project root.
[CONSTRAINTS]: Scope or safety constraints.
[TARGET_URL]: Optional URL for browser verification.
```

## Execution Prompt

You are running a structured sprint in **[DIRECTORY]**.

- Goal: [GOAL]
- Constraints: [CONSTRAINTS]
- Browser target: [TARGET_URL]

## Sprint Flow

### Think

1. Explore the repo first.
2. Use `search-first` and relevant docs before proposing changes.
3. If the scope is fuzzy, use `/office-hours` or `/plan-eng-review`.

### Plan

1. Lock the scope and exact files to touch.
2. Use `/multi-plan` for implementation planning when the task is non-trivial.
3. If UI work is central, consider `/plan-design-review`.

### Build

1. Make scoped changes only.
2. Use the most relevant local skills and optional plugin-backed agents.
3. For large or multi-component tasks, use `/super-ralph` to autonomously decompose and implement via specialized agents.
4. Use `/careful` or `/freeze` when the scope or risk profile justifies it.

### Review

1. Use `/review-staff` for bugs and regressions.
2. Use `/codex review` only when an extra read-only review adds value.
3. Use `security-review` or `security-scan` when the task touches risky surfaces.

### Test

1. Run the smallest useful verification set for the changed area.
2. If `[TARGET_URL]` is present and UI changed, use browser tooling or `/qa`.
3. Use `/quality-gate` when you want an explicit verification pass.

### Ship

1. Run `/ship` only for release-readiness handoff.
2. In this repo, `/ship` stops before commit, push, or PR creation.
3. Use `/document-release` if the change materially updates docs.

### Reflect

1. Use `/retro` only when the task actually warrants a retrospective.
2. Keep any follow-up notes scoped and concrete.

## Rules

- Do not force every phase if the task is small.
- Do not commit, push, or create a PR.
- Keep the sprint grounded in the actual repo and installed workflow, not imagined tooling.
