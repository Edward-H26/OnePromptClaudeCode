# Hook Mechanisms

This repo uses shell hooks, not TypeScript wrapper hooks.

## Current Flow

### UserPromptSubmit

`skill-activation-prompt.sh`:
- reads the incoming prompt JSON from stdin
- loads `.claude/skills/skill-rules.json`
- matches keywords, intent patterns, and exclusions
- writes a formatted reminder to stdout

That stdout is injected into the conversation as additional context.

### PostToolUse

These hooks currently matter most for workflow and verification:
- `post-tool-use-tracker.sh`
- `tsc-check.sh`
- `workflow-step-tracker.sh`

They track edited files, detect affected repos, and record optional workflow signals.

### Stop

These hooks run at the end:
- `stop-build-check-enhanced.sh`
- `workflow-completion-gate.sh`

They re-run tracked checks and emit reminders or cleanup. They are not the place to document imaginary mandatory steps.

## What This Repo Does Not Have

- No dedicated `skill-activation-prompt.ts`
- No dedicated `skill-verification-guard.ts`
- No active `.claude/hooks/state/` session guardrail store
- No project-local `.claude/settings.json` as the primary hook registration source

## Test Commands

### Test skill activation

```bash
echo '{"session_id":"test","prompt":"add a new skill trigger"}' | \
  bash .claude/hooks/skill-activation-prompt.sh
```

### Test TypeScript validation hook shape

```bash
cat <<'EOF' | bash .claude/hooks/tsc-check.sh
{"session_id":"test","tool_name":"Edit","tool_input":{"file_path":"src/example.ts"}}
EOF
```
