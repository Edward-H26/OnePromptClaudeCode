---
description: Drive Chrome via the chrome-devtools-mcp plugin (screenshot, navigate, console, network, Lighthouse, performance, click, fill, evaluate)
argument-hint: "URL or browser task (e.g. 'screenshot https://example.com', 'lighthouse https://example.com', 'click .submit on /checkout')"
---

Invoke the `chrome-devtools` skill. Read the SKILL at `.claude/skills/chrome-devtools/SKILL.md` and follow it.

This skill is a direct route to the `chrome-devtools-mcp` plugin's MCP tools. It covers: new_page, navigate_page, take_screenshot, take_snapshot, click, fill, fill_form, evaluate_script, list_console_messages, list_network_requests, lighthouse_audit, performance_start_trace, take_memory_snapshot, and ~20 more.

For cross-browser (Firefox / WebKit), use `playwright` instead. For local-app QA with full server lifecycle, use `webapp-testing` or `/qa-only`.

Task: $ARGUMENTS
