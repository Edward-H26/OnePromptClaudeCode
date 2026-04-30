#!/bin/bash
# MCP PreToolUse guard
# Logs every MCP tool invocation, and for mutating endpoints warns before
# the call proceeds. Does not block; permission modes remain the enforcement
# layer. Audit trail goes to .claude/runtime/mcp-log.jsonl (gitignored).

command -v jq >/dev/null 2>&1 || exit 0

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/hook-metrics.sh"
CLAUDE_HOME_DIR="$(resolve_claude_home)"
record_hook_invocation "check-mcp"

LOG_DIR="${CLAUDE_HOME_DIR}/runtime"
LOG_FILE="${LOG_DIR}/mcp-log.jsonl"
mkdir -p "$LOG_DIR"

if [[ -f "$LOG_FILE" ]]; then
    LOG_SIZE=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
    if [[ "$LOG_SIZE" -gt 5242880 ]]; then
        mv "$LOG_FILE" "${LOG_FILE}.1" 2>/dev/null || true
    fi
fi

HOOK_INPUT=$(cat)
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // ""')

if [[ ! "$TOOL_NAME" == mcp__* ]]; then
    exit 0
fi

MUTATING_PATTERNS=(
    "perform-editing-operations"
    "commit-editing-transaction"
    "start-editing-transaction"
    "create-design"
    "create-folder"
    "create-new-file"
    "send-code-connect-mappings"
    "upload-asset"
    "resize-design"
    "import-design-from-url"
    "merge-designs"
    "browser_click"
    "browser_type"
    "browser_fill_form"
    "browser_file_upload"
    "browser_select_option"
    "browser_press_key"
    "browser_evaluate"
    "browser_run_code"
    "replace_all_matching_properties"
    "set_variables"
    "batch_design"
    "open_document"
)

IS_MUTATING=0
for pattern in "${MUTATING_PATTERNS[@]}"; do
    if [[ "$TOOL_NAME" == *"$pattern"* ]]; then
        IS_MUTATING=1
        break
    fi
done

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
{
    printf '{"ts":"%s","tool":"%s","mutating":%s}\n' "$TS" "$TOOL_NAME" "$([ $IS_MUTATING -eq 1 ] && echo true || echo false)"
} >> "$LOG_FILE" 2>/dev/null

if [[ $IS_MUTATING -eq 1 ]]; then
    {
        echo "MCP guard: '$TOOL_NAME' is a mutating endpoint"
        echo "Audit trail: $LOG_FILE"
    } >&2
fi

exit 0
