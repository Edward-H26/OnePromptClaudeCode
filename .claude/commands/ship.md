---
description: Release readiness workflow (tests, coverage, changelog, handoff)
---

Invoke the `/ship` skill. Read the SKILL at `$CLAUDE_PROJECT_DIR/.claude/skills/ship/SKILL.md` and follow it exactly.

This is the release readiness workflow: sync base, run tests, audit coverage, version bump, and prepare changelog and PR handoff.

Project rule override:
- Do not run `git commit`
- Do not run `git push`
- Do not create the PR automatically
- Stop at a release-ready handoff and return the exact commands the user should run next

Additional instructions: $ARGUMENTS
