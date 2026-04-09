---
description: Send a task to Codex CLI for parallel execution in the background
argument-hint: Task description (e.g., "refactor auth middleware", "add error handling to api.ts --file src/api.ts")
---

Send this task to Codex CLI to work on in the background while you continue other work.

## Task
$ARGUMENTS

## Instructions

1. Parse the task for any file references (paths mentioned, `--file` flags)
2. Determine the workspace (current working directory)
3. Run the Codex script in the background:

```bash
"$CLAUDE_PROJECT_DIR/.claude/skills/codex/scripts/ask_codex.sh" "$ARGUMENTS" -w <workspace> --file <detected_files>
```

Run it as a background shell process if parallel execution is useful in the current session.

4. Report the output path to the user so they can check results later
5. Continue with any other work the user needs

## Flags Passthrough

The user can include these flags inline with their task:
- `--file <path>` or `-f <path>`: Priority files for Codex to read first
- `--read-only`: Run in read-only mode (evaluation only, no file changes)
- `--session <id>`: Resume a previous Codex session

## Examples

```
/codex refactor the auth middleware to use JWT --file src/middleware/auth.ts
/codex review this code for bugs --file src/api.ts --read-only
/codex add input validation to all API endpoints --file src/routes/users.ts --file src/routes/posts.ts
```
