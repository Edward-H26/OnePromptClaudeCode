---
name: super-ralph
description: Wrapper skill for the vendored Super Ralph autonomous workflow. Use when running /super-ralph or when the user explicitly asks for Super Ralph, Ralph, or autonomous multi-agent execution in this workspace.
---

# Super Ralph

This directory vendors the upstream Super Ralph bundle. The canonical implementation lives in:

- `./skills/super-ralph/SKILL.md`
- `./agents/`
- `./commands/super-ralph.md`

## How To Use It Here

1. Start with `./skills/super-ralph/SKILL.md`.
2. Follow the vendored workflow and agent definitions from that bundle.
3. Keep the vendored bundle intact unless the task is specifically about maintaining the bundle itself.

## Local Contract

- Treat this wrapper as the entrypoint used by local skill routing, prompt templates, and slash-command documentation.
- If local docs and the vendored bundle disagree, update the local docs to point at the vendored bundle rather than rewriting the vendored internals.
