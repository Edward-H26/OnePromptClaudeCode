---
name: playwright
description: Repo-local wrapper for the Playwright plugin. Use for browser automation, local page interaction, screenshots, and end-to-end validation.
---

# Playwright

Use this wrapper when a task requires browser automation, UI interaction, screenshots, or end-to-end validation.

## Repo Rules

- Prefer the Playwright plugin when it is enabled locally.
- If the plugin is unavailable, use repo-local browser or chrome-devtools tooling when available.
- For local apps, verify the relevant route and viewport before claiming UI work is complete.

## Workflow

1. Identify the URL, app route, or user flow.
2. Open and interact with the page through Playwright when available.
3. Capture screenshots or test evidence that matches the user-facing claim.
