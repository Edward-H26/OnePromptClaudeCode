# Oneshot Mode for Super Ralph

**Date:** 2026-03-28
**Status:** Approved

## Problem

Super Ralph currently requires 4 interactive phases (Brainstorm, Intent Profile, Tooling Discovery, Pre-Flight) before going autonomous. For users who know what they want and trust Ralph's judgment, this is friction.

## Solution

Add a **Phase -2: Mode Selection** prehook — the very first question Ralph asks. Two options:

- **Oneshot** — Ralph runs all phases autonomously, making every decision itself. No further questions. Silent until final delivery.
- **Brainstorm** — Current interactive flow, unchanged.

A `MODE` variable (`oneshot` | `brainstorm`) gates every existing `AskUserQuestion` call.

## Design

### Phase -2: Mode Selection

Single prehook gate:

```
question: "How should I approach this?"
header: "Mode"
options:
  - label: "Oneshot"
    description: "I'll handle everything autonomously — no questions, just deliver"
  - label: "Brainstorm"
    description: "Let's explore the idea together step by step"
  - label: "Chat about this"
    description: "Stop — I want to discuss this before deciding"
```

Stores `MODE` = `oneshot` | `brainstorm`.

### Per-Phase Behavior in Oneshot Mode

| Phase | Brainstorm mode (unchanged) | Oneshot mode |
|-------|---------------------------|--------------|
| **-1: Brainstorm** | Interactive Q&A via AskUserQuestion | Ralph analyzes the query, infers intent/scope/constraints, writes BRAINSTORM_SUMMARY autonomously |
| **-0.75: Intent Profile** | 3 AskUserQuestion gates | Ralph infers priority/audience/lifespan from query context; defaults to middle tier (solid + team + weeks) when ambiguous |
| **-0.5: Tooling** | Scan + AskUserQuestion to select tools | Ralph scans, auto-selects recommended toolset, builds TOOLING_CONFIG |
| **0: Pre-Flight** | 4 AskUserQuestion gates | Defaults: current directory writable, no read-only, nothing off-limits, MAX_RETRIES=6 |
| **1-3: Execution** | Already autonomous | No change |

### Rules

1. **Only one question total** — the mode selection. Everything else is self-decided.
2. **Default to safe, sensible choices** — middle-tier intent profile, current directory scope, 6 retries.
3. **All artifacts still produced** — BRAINSTORM_SUMMARY, INTENT_PROFILE, JUDGE_RUBRIC, TOOLING_CONFIG, WORKSPACE_RULES all generated without user input.
4. **Silent until delivery** — no narration of decisions in oneshot mode.

## Implementation Scope

### Files to modify:
- `skills/super-ralph/SKILL.md` — Add Phase -2, add MODE conditionals to Phases -1, -0.75, -0.5, and 0
- `commands/super-ralph.md` — Update workflow description to mention oneshot option
- `README.md` — Document oneshot mode

### No changes needed:
- Agent files (`ralph-{tester,worker,debugger,judge,merger}.md`) — they don't interact with prehook phases
- `learnings.md`, `memory.md` — no structural changes
