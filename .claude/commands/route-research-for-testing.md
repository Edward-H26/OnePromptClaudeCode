---
description: Map edited routes and prepare a test brief
argument-hint: "[/extra/path …]"
allowed-tools: Bash(cat:*), Bash(awk:*), Bash(grep:*), Bash(sort:*), Bash(xargs:*), Bash(sed:*)
---

## Context

Changed route files this session (auto-generated):

shopt -s nullglob
for file in "$CLAUDE_PROJECT_DIR"/.claude/tsc-cache/*/edited-files.log; do
  cat "$file"
done | awk -F'\t' '{print $2}' | grep '/routes/' | sort -u

User-specified additional routes: `$ARGUMENTS`

## Your task

Follow the numbered steps **exactly**:

1. Combine the auto list with `$ARGUMENTS`, dedupe, and resolve any prefixes
   defined in `src/app.ts` if that file exists in the target project.
2. For each final route, output a JSON record with the path, method, expected
   request/response shapes, and valid + invalid payload examples.
3. Produce a compact route-testing brief for `/qa`, `/qa-only`, manual API testing, or local debugging and review agents.
   Do not reference nonexistent auth-route agents.
