---
name: freeze
description: Repo-local edit-scope wrapper. Restrict changes to the requested directory and avoid accidental repo-wide edits.
---

# Freeze

Use this skill when edits must stay inside a narrow directory or feature boundary.

## Repo Rules

- Restrict changes to the user-approved path.
- Do not widen scope without explicit need.
- Keep the boundary local to this repo, not any global gstack state.

## Activation

This repo keeps the freeze boundary in `.claude/runtime/gstack/freeze-dir.txt`.

If the user did not provide a directory yet, ask for one before proceeding.

When a target directory is known, activate the boundary with Bash:

```bash
FREEZE_DIR="$(cd "<target-directory>" 2>/dev/null && pwd)"
test -n "$FREEZE_DIR"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/runtime/gstack"
printf "%s/\n" "${FREEZE_DIR%/}" > "$CLAUDE_PROJECT_DIR/.claude/runtime/gstack/freeze-dir.txt"
echo "Freeze boundary set to $FREEZE_DIR/"
```

After the file exists, the tracked `check-freeze.sh` hook will block edits outside that directory.
