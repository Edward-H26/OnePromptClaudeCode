#!/bin/bash
# Note: set -e intentionally omitted, consistent with other hooks in this directory.

command -v jq >/dev/null 2>&1 || exit 0

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"
CLAUDE_HOME_DIR="$(resolve_claude_home)"

HOOK_INPUT=$(cat)
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")
SESSION_ID="$(sanitize_session_id "${SESSION_ID:-default}")"
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")

STEPS_DIR="$CLAUDE_HOME_DIR/tsc-cache/$SESSION_ID/workflow-steps"
mkdir -p "$STEPS_DIR"

if [[ "$TOOL_NAME" == "Bash" ]]; then
    COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // .tool_input.cmd // empty' 2>/dev/null)

    if echo "$COMMAND" | grep -q "ask_codex.sh"; then
        if echo "$COMMAND" | grep -q -- "--read-only"; then
            mkdir -p "$STEPS_DIR/codex-eval"
        else
            mkdir -p "$STEPS_DIR/codex-kickoff"
        fi
    fi
fi

if [[ "$TOOL_NAME" == "Skill" ]]; then
    SKILL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null)
    if [[ "$SKILL_NAME" == "simplify" ]] || [[ "$SKILL_NAME" == "code-simplifier" ]]; then
        mkdir -p "$STEPS_DIR/simplify-review"
    fi
fi

if [[ "$TOOL_NAME" == mcp__claude-in-chrome__* ]] || [[ "$TOOL_NAME" == mcp__plugin_playwright_playwright__* ]] || [[ "$TOOL_NAME" == mcp__playwright__* ]]; then
    mkdir -p "$STEPS_DIR/chrome-verification"
fi

exit 0
