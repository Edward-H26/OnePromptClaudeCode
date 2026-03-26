---
name: skill-developer
description: Create and maintain local Claude Code skills, skill-rules.json triggers, and hook-aligned workflow guidance for this repo. Use when adding skills, modifying triggers, updating hook behavior, or debugging skill activation.
---

# Skill Developer Guide

## Purpose

Use this skill when working on:
- `.claude/skills/*`
- `.claude/skills/skill-rules.json`
- `.claude/hooks/*`
- skill activation behavior
- local workflow documentation tied to skills

## Current Architecture in This Repo

This repo currently uses a shell-based, suggestion-first architecture.

### Active Skill-Related Hooks

**UserPromptSubmit**
- `.claude/hooks/skill-activation-prompt.sh`
- Reads `skill-rules.json`
- Suggests relevant skills by writing to stdout

**PostToolUse**
- `.claude/hooks/post-tool-use-tracker.sh`
- `.claude/hooks/tsc-check.sh`
- `.claude/hooks/workflow-step-tracker.sh`

**Stop**
- `.claude/hooks/stop-build-check-enhanced.sh`
- `.claude/hooks/workflow-completion-gate.sh`

### Important Constraint

This repo does **not** currently implement a dedicated PreToolUse skill-guardrail system. Do not document or depend on one unless you add it explicitly.

## How to Add or Update a Skill

### 1. Create the skill file

Location:

```text
.claude/skills/<skill-name>/SKILL.md
```

Keep the skill compact. Prefer progressive disclosure through extra reference files instead of one huge `SKILL.md`.

### 2. Register triggers in `skill-rules.json`

Use:
- `promptTriggers.keywords`
- `promptTriggers.intentPatterns`
- `promptTriggers.keywordExclusions` when needed
- `fileTriggers.pathPatterns`
- `fileTriggers.pathExclusions`
- `fileTriggers.contentPatterns`

In this repo, suggestion quality matters more than aggressive enforcement. Prefer precise triggers over broad ones.

### 3. Test the actual hook

```bash
echo '{"session_id":"test","prompt":"debug this workflow hook"}' | \
  bash .claude/hooks/skill-activation-prompt.sh
```

If you changed file-trigger behavior in a validation hook, test the specific hook that consumes that information. Do not point documentation at nonexistent TypeScript hook files.

## Practical Rules

- Treat `skill-rules.json` as the source of truth for trigger behavior.
- Keep descriptions explicit. They help both humans and trigger design.
- Prefer `suggest` over `block` unless the repo really has a hook that enforces blocking.
- Update related docs when changing hook or trigger behavior.
- Keep examples aligned with actual local paths, especially `.claude/settings.json` in this repo.

## Maintenance Checklist

- Skill file exists and is named correctly
- `skill-rules.json` entry matches the skill name exactly
- Trigger keywords and intent patterns reflect real user prompts
- Hook docs mention the shell hooks that actually exist
- References to the active shared settings file should point at `.claude/settings.json` in this repo
- No references to nonexistent state directories or TypeScript hook wrappers

## References

- [HOOK_MECHANISMS.md](./HOOK_MECHANISMS.md)
- [TRIGGER_TYPES.md](./TRIGGER_TYPES.md)
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
- [SKILL_RULES_REFERENCE.md](./SKILL_RULES_REFERENCE.md)
