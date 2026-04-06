---
description: "Super Ralph oneshot — fully autonomous, zero questions, just deliver"
argument-hint: "QUERY"
---

# /ralph

The user wants to run Super Ralph in **oneshot mode** — fully autonomous with zero interactive questions.

> Additive Codex note: this file is the Claude slash-command entrypoint for oneshot mode. In Codex environments without slash commands, trigger the same flow when the user says "ralph this", "oneshot ralph", or equivalent, and pass the user request as the query argument to the `super-ralph` skill.

**Invoke the `super-ralph` skill immediately** with the user's query AND the following directive:

**Set `MODE = oneshot` immediately. Do NOT ask the Phase -2 mode selection question.** The user chose oneshot by invoking `/ralph` instead of `/super-ralph`. Proceed directly to Phase -3 (Permissions Bootstrap), then run the entire pipeline with Ralph making every decision autonomously.

The full pipeline still runs — brainstorm analysis, intent profiling, tooling selection, pre-flight scoping, decomposition, test-first execution, self-debugging, learning, and merge. The only difference is Ralph decides at every gate instead of asking the user.

The user's query is: ${ARGUMENTS}

**Start by invoking the super-ralph skill now with MODE = oneshot.**
