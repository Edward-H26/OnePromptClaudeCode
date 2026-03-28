---
name: guard
description: Repo-local combined safety wrapper. Apply both careful and freeze behavior for high-risk tasks.
---

# Guard

Use this skill when the task needs both destructive-command caution and a strict edit boundary.

## Repo Rules

- Apply the `careful` and `freeze` behaviors together.
- Keep the scope local to the current repo and user request.
- Prefer blocking risky expansion over speed.

## Activation

`guard` turns on both repo-local safety flags:

1. Activate `careful`:

```bash
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/runtime/gstack"
printf "active\n" > "$CLAUDE_PROJECT_DIR/.claude/runtime/gstack/careful-mode.txt"
```

2. Activate `freeze` for the requested directory:

```bash
FREEZE_DIR="$(cd "<target-directory>" 2>/dev/null && pwd)"
test -n "$FREEZE_DIR"
printf "%s/\n" "${FREEZE_DIR%/}" > "$CLAUDE_PROJECT_DIR/.claude/runtime/gstack/freeze-dir.txt"
echo "Guard mode is active. Careful mode enabled and freeze boundary set to $FREEZE_DIR/"
```

If the user did not provide a directory, ask for one before enabling `guard`.
