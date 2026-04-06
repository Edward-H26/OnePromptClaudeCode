---
description: Execute an approved plan using repo-local tooling and Codex bridge
argument-hint: "Plan or task description"
---

# Multi-Execute

Execute an approved plan using repo-local tooling, installed plugin agents, and the bundled Codex bridge.

$ARGUMENTS

## Expected Input

- Preferred: `plans/<name>.md`
- Allowed: a concise task description when the approved plan is already in context

## Toolchain For This Repo

- Local file edits by Claude
- Optional Codex delegation through `"$CLAUDE_PROJECT_DIR/.claude/skills/codex/scripts/ask_codex.sh"`
- Optional review and exploration through installed `feature-dev` and `superpowers` plugin agents
- Standard project verification commands and browser tooling

## Workflow

1. Read the approved plan and extract the scope, key files, and acceptance criteria.
2. Inspect the referenced files before editing.
3. Apply the smallest set of code changes needed to satisfy the plan.
4. If parallel help is useful, use one bounded Codex call or plugin-backed reviewer or explorer agents. Keep delegated work tightly scoped.
5. Run the smallest useful verification set for the touched area.
6. Report the changed files, checks run, and any remaining risks.

## When To Use Codex

Use the bundled Codex bridge only when it materially helps:
- batch refactors
- repetitive edits across multiple files
- a bounded second opinion on implementation or review

Default review mode:
```bash
"$CLAUDE_PROJECT_DIR/.claude/skills/codex/scripts/ask_codex.sh" \
  --read-only \
  --reasoning high \
  -w "$PWD" \
  "Review the approved plan implementation for bugs, regressions, and missing tests."
```

## Rules

- Do not rely on personal wrapper binaries outside this repo.
- Do not rely on external prompt packs outside this repo.
- Do not rely on `ace-tool`, wrapper-specific session IDs, or background-task control primitives.
- Keep edits within the approved plan scope.
- Run verification before declaring completion.
