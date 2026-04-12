> **Parent**: [CLAUDE.md](./CLAUDE.md) | **Related**: [CLAUDE-website-workflow.md](./CLAUDE-website-workflow.md), [CLAUDE-skills.md](./CLAUDE-skills.md)
>
> This document extends the main execution rule with testing and verification guidance.

# Testing and Verification Protocol

## Core Rule

Use verification that matches the scope of the change.

- Run existing tests when they cover the code you changed.
- Prefer targeted checks before full-suite checks.
- Do not add new tests unless the task requires them or the change is large enough that missing tests would be unsafe.
- Do not rely on nonexistent hooks or promised automation. Verify with the commands and tools that are actually available.

## Baseline Workflow

### 1. Before Editing
- Identify which tests, type checks, or builds are relevant.
- Check whether the area already has tests.

### 2. During Implementation
- Re-run the smallest useful verification after meaningful changes.
- Use Bash or the available MCP and plugin tools to inspect outputs.

### 3. After Implementation

Choose from the following as appropriate:

```bash
# Targeted tests
npm test -- path/to/test
pnpm test -- path/to/test
yarn test path/to/test

# Type checking
npx tsc --noEmit

# Linting
npm run lint
pnpm lint
yarn lint

# Build checks
npm run build
pnpm build
yarn build

# Browser and UI verification, preferred order
# 1. chrome-devtools skill when Chrome is configured locally
node .claude/skills/chrome-devtools/scripts/navigate.js --url http://localhost:3000
node .claude/skills/chrome-devtools/scripts/screenshot.js --url http://localhost:3000 --output ./docs/screenshots/page.png
# 2. Playwright plugin for cross-browser coverage or existing spec suites
npx playwright test
```

### 4. Frontend Validation
- If the task changes visible UI, verify behavior in the browser tooling that is available in the session.
- Prefer the `chrome-devtools` skill when Chrome is already configured locally. The Puppeteer scripts at `.claude/skills/chrome-devtools/scripts/` are lighter weight than a full Playwright install and produce structured JSON output.
- Fall back to the Playwright plugin when Firefox or WebKit coverage is needed, when the project already has Playwright specs, or when chrome-devtools node modules are not installed.
- Use the generic browser MCP connector only when neither of the first two is available.

### Note on Computer Use

Computer Use is an Anthropic API feature where the model drives the user's desktop with mouse, keyboard, and screenshot primitives. Claude Code CLI does not ship a Computer Use harness, so pixel-level control of native apps or OS dialogs is not available here. The CLI covers the common browser cases through `chrome-devtools` (Puppeteer) and Playwright, which are sufficient for almost every UI verification task a developer needs.

## Hooks in This Repo

These hooks exist and should be treated as helpers, not as a substitute for judgment:

- `post-tool-use-tracker.sh` tracks edited files and affected repos
- `tsc-check.sh` attempts a targeted TypeScript check after file edits
- `stop-build-check-enhanced.sh` re-checks tracked repos on stop
- `workflow-completion-gate.sh` now acts as a reminder and cleanup step, not a stale hard blocker for imaginary workflow steps

## Failure Response

### If tests fail
- Stop and fix the failure before declaring success
- Re-run the failed check

### If type checks fail
- Fix the root cause instead of suppressing the error

### If browser verification is not possible
- State that it could not be run
- Explain what was verified instead

## Evidence to Report

When you finish a non-trivial code task, report:

- What checks ran
- Whether they passed
- What could not be run
