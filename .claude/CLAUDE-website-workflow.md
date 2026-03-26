> **Parent**: [CLAUDE.md](./CLAUDE.md) | **Related**: [CLAUDE-testing.md](./CLAUDE-testing.md), [CLAUDE-skills.md](./CLAUDE-skills.md)
>
> This document covers UI-heavy website work in this environment.

# Website Development Workflow

Use this workflow when the task is primarily about layout, styling, interaction, or user-facing frontend behavior.

## Phase 1: Understand the Existing Surface

- Inspect the current page, components, routes, and styling system
- Identify whether the codebase already uses Tailwind, shadcn/ui, CSS modules, or another pattern
- Activate the most relevant guidance:
  - `frontend-dev-guidelines`
  - `ui-styling`
  - `frontend-design` plugin guidance when distinctive visual work is needed

## Phase 2: Plan the UI Change

- Define the affected screens or components
- Note data dependencies, responsive behavior, and interaction changes
- Keep the plan constrained to the requested scope

## Phase 3: Implement in Small Slices

For each component or screen:
- implement the UI change
- clean up any duplication introduced by that change
- keep naming, spacing, and composition consistent with the surrounding code

Do not wait until the end to fix obvious styling duplication or layout drift.

## Phase 4: Verify

Run the most relevant checks:

```bash
npx tsc --noEmit
npm run build
npm run lint
npx playwright test
```

Use only the checks that exist in the target project.

## Phase 5: Browser Validation

When there is a runnable UI target:
- verify layout
- verify core interactions
- check for console or runtime errors
- confirm responsive behavior for the important breakpoints

Prefer the Playwright plugin tooling when available. If a separate browser connector is configured in the session, it can also be used.

## Phase 6: Report

Summarize:
- the visual or interaction changes made
- the main implementation decisions
- the checks that ran
