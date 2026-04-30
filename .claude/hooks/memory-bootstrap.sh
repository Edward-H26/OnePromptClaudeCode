#!/bin/bash
# Memory bootstrap (UserPromptSubmit)
# If a repo-local MEMORY.md exists (either at the project root or under
# .claude/memory/), print its first 30 lines so the model can recall
# durable context without waiting for the global auto-memory injection.
# Silent when no local memory file is present.

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/hook-metrics.sh"
CLAUDE_HOME_DIR="$(resolve_claude_home)"
record_hook_invocation "memory-bootstrap"

CANDIDATES=(
    "$CLAUDE_PROJECT_DIR/MEMORY.md"
    "$CLAUDE_PROJECT_DIR/.claude/MEMORY.md"
    "$CLAUDE_PROJECT_DIR/.claude/memory/MEMORY.md"
)

PROJECT_SLUG="$(printf "%s" "$CLAUDE_PROJECT_DIR" | sed 's|/|-|g')"
if [[ -f "$HOME/.claude/projects/$PROJECT_SLUG/memory/MEMORY.md" ]]; then
    CANDIDATES+=("$HOME/.claude/projects/$PROJECT_SLUG/memory/MEMORY.md")
fi

for path in "${CANDIDATES[@]}"; do
    if [[ -f "$path" ]]; then
        {
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "REPO MEMORY INDEX (from $path)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            head -30 "$path"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        }
        exit 0
    fi
done

exit 0
