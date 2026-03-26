---
name: investigate
description: Repo-local wrapper for root-cause investigation. Understand the issue before changing code, and ignore global gstack setup steps.
---

# Investigate

Use this skill for debugging and root-cause analysis.

## Repo Rules

- Explore the current repo first.
- Ignore vendored telemetry, proactive prompts, and global-home setup instructions.
- Do not apply speculative fixes before the cause is clear.

## Workflow

1. Reproduce the issue from the current repo state.
2. Identify the root cause with direct evidence.
3. Propose or apply the smallest fix that addresses the cause.
4. Re-run the narrowest useful verification.
