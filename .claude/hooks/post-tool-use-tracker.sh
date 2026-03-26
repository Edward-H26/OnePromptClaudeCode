#!/bin/bash
# Note: set -e intentionally omitted. This hook must not abort on
# individual file tracking failures; it handles errors inline.

command -v jq >/dev/null 2>&1 || exit 0

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

HOOK_INPUT=$(cat)

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")

if [[ ! "$TOOL_NAME" =~ ^(Edit|MultiEdit|Write)$ ]]; then
    exit 0
fi

if [[ "$TOOL_NAME" == "MultiEdit" ]]; then
    FILE_PATHS=$(echo "$HOOK_INPUT" | jq -r '.tool_input.edits[].file_path // empty' 2>/dev/null || echo "")
else
    FILE_PATHS=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")
fi

if [[ -z "$FILE_PATHS" ]]; then
    exit 0
fi

CACHE_DIR="$CLAUDE_PROJECT_DIR/.claude/tsc-cache/${SESSION_ID:-default}"
mkdir -p "$CACHE_DIR"

while IFS= read -r file_path; do
    [[ -z "$file_path" ]] && continue
    [[ "$file_path" =~ \.(md|mdx|markdown)$ ]] && continue

    repo=$(get_repo_for_file "$file_path")
    if [[ -z "$repo" ]]; then
        echo "post-tool-use-tracker: Could not determine repo for $file_path" >&2
        continue
    fi

    printf "%s\t%s\t%s\n" "$(date +%s)" "$file_path" "$repo" >> "$CACHE_DIR/edited-files.log"

    if [[ "$file_path" =~ \.(ts|tsx|js|jsx)$ ]]; then
        repo_path="$CLAUDE_PROJECT_DIR/$repo"
        tsc_cmd=$(get_tsc_command "$repo_path")

        if [[ -n "$tsc_cmd" ]]; then
            if ! grep -qxF "$repo" "$CACHE_DIR/affected-repos.txt" 2>/dev/null; then
                echo "$repo" >> "$CACHE_DIR/affected-repos.txt"
            fi

            TSC_LINE=$(printf "%s\ttsc\tcd \"%s\" && %s" "$repo" "$repo_path" "$tsc_cmd")
            if ! grep -qxF "$TSC_LINE" "$CACHE_DIR/commands.txt" 2>/dev/null; then
                printf "%s\n" "$TSC_LINE" >> "$CACHE_DIR/commands.txt"
            fi
        fi
    fi
done <<< "$FILE_PATHS"

if [[ -f "$CACHE_DIR/commands.txt" ]]; then
    atomic_sort_unique "$CACHE_DIR/commands.txt"
fi

if [[ -f "$CACHE_DIR/affected-repos.txt" ]]; then
    atomic_sort_unique "$CACHE_DIR/affected-repos.txt"
fi

exit 0
