---
name: context7
description: Repo-local wrapper for the context7 documentation plugin. Use when a task asks for current library, framework, SDK, API, CLI, or cloud-service documentation.
---

# Context7

Use this wrapper when the user asks for up-to-date technical documentation or version-specific API usage.

## Repo Rules

- Prefer the context7 plugin when it is enabled locally.
- If the plugin is unavailable, use official documentation through web search.
- Do not treat this wrapper as a blocker. It routes to better documentation access when available.

## Workflow

1. Identify the library, framework, SDK, API, CLI, or service.
2. Use context7 to retrieve current documentation when available.
3. Cite the documentation used and keep implementation changes scoped to the user request.
