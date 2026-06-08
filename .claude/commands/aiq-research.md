---
description: Strict 5-stage research pipeline (intent classify → clarify → shallow → deep → evaluate) with inline citations, executed on Claude Code's built-in tools (WebSearch, WebFetch, context7, HF MCP). No NVIDIA backend required.
argument-hint: "Research question, topic, or research brief"
---

Invoke the `aiq-research` skill. Read the SKILL at `.claude/skills/aiq-research/SKILL.md` and follow the 5-stage pipeline exactly.

Stages:
1. **Classify** the intent (Factual / Comparative / Synthesis / Investigative).
2. **Clarify** scope, recency, depth, format, audience via `AskUserQuestion` (skip if prompt is unambiguous).
3. **Shallow research** — WebSearch broad pass, capture 5-10 URLs, pick top 3-5 for deep reading.
4. **Deep research** — WebFetch top sources, extract claims and quotes, cross-reference.
5. **Evaluate and synthesize** — produce a structured report with executive summary, themed findings, disagreements section, recommendation, and inline-cited sources list.

Quality bar: at least 3 independent sources cited; every load-bearing claim has a `[N]` marker; Disagreements section filled in honestly; recommendation is concrete.

For a lighter free-form research run, use `/deep-research` instead.

Research target: $ARGUMENTS
