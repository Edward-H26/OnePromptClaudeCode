---
name: setup-browser-cookies
description: Repo-local wrapper for authenticated browser setup. Use local browser tooling only when available and do not depend on global gstack cookie state.
---

# Setup Browser Cookies

Use this skill when authenticated browser testing needs imported cookies or session state.

## Repo Rules

- Use only the browser tooling available in this environment.
- Do not write to `~/.gstack`, `~/.claude`, or any global cookie store.
- If the local environment cannot import cookies, say so directly.

## Workflow

1. Confirm the target browser or testing flow.
2. Use local tooling to import or reuse session state if available.
3. Report any environment limitation clearly instead of inventing setup steps.
