---
name: strategic-compact
description: Suggests manual context compaction at logical intervals to preserve context through task phases rather than arbitrary auto-compaction.
origin: ECC-adapted
---

# Strategic Compact Skill

Suggests manual `/compact` at strategic points in your workflow rather than relying on arbitrary auto-compaction.

## When to Activate

- Running long sessions that approach context limits (200K+ tokens)
- Working on multi-phase tasks (research, plan, implement, test)
- Switching between unrelated tasks within the same session
- After completing a major milestone and starting new work
- When responses slow down or become less coherent (context pressure)

## Why Strategic Compaction?

Auto-compaction triggers at arbitrary points, often mid-task, losing important context. Strategic compaction at logical boundaries preserves what matters.

## Compaction Decision Guide

| Phase Transition | Compact? | Why |
|-----------------|----------|-----|
| Research to Planning | Yes | Research context is bulky; plan is the distilled output |
| Planning to Implementation | Yes | Plan is in TodoWrite or a file; free up context for code |
| Implementation to Testing | Maybe | Keep if tests reference recent code; compact if switching focus |
| Debugging to Next feature | Yes | Debug traces pollute context for unrelated work |
| Mid-implementation | No | Losing variable names, file paths, and partial state is costly |
| After a failed approach | Yes | Clear the dead-end reasoning before trying a new approach |

## What Survives Compaction

| Persists | Lost |
|----------|------|
| CLAUDE.md instructions | Intermediate reasoning and analysis |
| Notes or plans saved to files | File contents you previously read |
| Memory files | Multi-step conversation context |
| Git state (commits, branches) | Tool call history and counts |
| Files on disk | Nuanced user preferences stated verbally |

## Best Practices

1. **Compact after planning**: Once plan is finalized in task list, compact to start fresh
2. **Compact after debugging**: Clear error-resolution context before continuing
3. **Do not compact mid-implementation**: Preserve context for related changes
4. **Write before compacting**: Save important context to files or memory before compacting
5. **Use `/compact` with a summary**: Add a custom message: `/compact Focus on implementing auth middleware next`

## Token Optimization Patterns

### Context Composition Awareness
Monitor what consumes your context window:
- **CLAUDE.md files**: Always loaded, keep lean
- **Loaded skills**: Each skill adds 1-5K tokens
- **Conversation history**: Grows with each exchange
- **Tool results**: File reads, search results add bulk

### Duplicate Instruction Detection
Common sources of duplicate context:
- Same rules duplicated across multiple workflow directories inside the current Claude setup
- Skills that repeat CLAUDE.md instructions
- Multiple skills covering overlapping domains
