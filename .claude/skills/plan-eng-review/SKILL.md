---
name: plan-eng-review
description: Repo-local wrapper for engineering plan review. Validate the implementation plan against this repo's real structure and rules.
---

# Plan Engineering Review

Use this skill for architecture review, implementation planning, and technical risk assessment.

## Repo Rules

- Ground the review in the current repo layout, hooks, commands, and constraints.
- Ignore vendored telemetry and global-home setup.
- Prefer concrete file and interface impacts over abstract guidance.

## Workflow

1. Validate the proposed approach against the current repo.
2. Identify missing decisions, technical risks, and testing gaps.
3. Return a decision-complete engineering plan.
