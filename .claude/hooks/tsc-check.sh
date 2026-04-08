#!/bin/bash
set -e

# TSC Hook with Visible Output
# Uses stderr for visibility in Claude Code main interface

command -v jq >/dev/null 2>&1 || exit 0

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

HOOK_INPUT=$(cat)
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")
SESSION_ID="${SESSION_ID:-default}"
CACHE_DIR="$CLAUDE_PROJECT_DIR/.claude/tsc-cache/$SESSION_ID"

exit_code=0
mkdir -p "$CACHE_DIR"

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // ""')

run_tsc_check() {
    local repo="$1"
    local repo_path="$CLAUDE_PROJECT_DIR/$repo"
    local repo_key
    repo_key="$(repo_cache_key "$repo")"
    local cache_file="$CACHE_DIR/$repo_key-tsc-cmd.cache"

    (
        cd "$repo_path" 2>/dev/null || exit 1

        local tsc_cmd
        if [ -f "$cache_file" ] && [ -z "$FORCE_DETECT" ]; then
            tsc_cmd=$(cat "$cache_file")
        else
            tsc_cmd=$(get_tsc_command "$repo_path")
            echo "$tsc_cmd" > "$cache_file"
        fi

        if [ -z "$tsc_cmd" ]; then
            echo "Skipping TSC check for $repo: no TypeScript config found" >&2
            exit 2
        fi

        validate_and_run_tsc "$tsc_cmd"
    )
}

if [[ ! "$TOOL_NAME" =~ ^(Edit|MultiEdit|Write)$ ]]; then
    exit 0
fi

REPOS_TO_CHECK=""
if [[ -f "$CACHE_DIR/affected-repos.txt" ]]; then
    REPOS_TO_CHECK=$(sort -u "$CACHE_DIR/affected-repos.txt" | tr '\n' ' ')
else
    TOOL_INPUT=$(echo "$HOOK_INPUT" | jq '.tool_input // {}')
    if [ "$TOOL_NAME" = "MultiEdit" ]; then
        FILE_PATHS=$(echo "$TOOL_INPUT" | jq -r '.edits[].file_path // empty')
    else
        FILE_PATHS=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
    fi
    REPOS_TO_CHECK=$(echo "$FILE_PATHS" | grep -E '\.(ts|tsx|js|jsx)$' | while read -r file_path; do
        if [ -n "$file_path" ]; then
            repo=$(get_repo_for_file "$file_path")
            [ -n "$repo" ] && echo "$repo"
        fi
    done | sort -u | tr '\n' ' ')
fi
REPOS_TO_CHECK=$(echo "$REPOS_TO_CHECK" | tr -s ' ' | sed 's/^ //;s/ $//')

if [ -n "$REPOS_TO_CHECK" ]; then
    ERROR_COUNT=0
    ERROR_OUTPUT=""
    FAILED_REPOS=""

    echo "⚡ TypeScript check on: $REPOS_TO_CHECK" >&2

    while IFS= read -r repo; do
        [[ -z "$repo" ]] && continue
        echo -n "  Checking $repo... " >&2

        CHECK_EXIT_CODE=0
        set +e
        CHECK_OUTPUT=$(run_tsc_check "$repo" 2>&1)
        CHECK_EXIT_CODE=$?
        set -e

        if [ $CHECK_EXIT_CODE -eq 2 ]; then
            echo "⏭ Skipped" >&2
        elif [ $CHECK_EXIT_CODE -ne 0 ] || echo "$CHECK_OUTPUT" | grep -qE "(error TS[0-9]+|Cannot find module|has no exported member|is not assignable to)"; then
            echo "❌ Errors found" >&2
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED_REPOS="$FAILED_REPOS $repo"
            ERROR_OUTPUT="${ERROR_OUTPUT}

=== Errors in $repo ===
$CHECK_OUTPUT"
        else
            echo "✅ OK" >&2
        fi
    done <<< "$(echo "$REPOS_TO_CHECK" | tr ' ' '\n')"

    if [ $ERROR_COUNT -gt 0 ]; then
        echo "$ERROR_OUTPUT" > "$CACHE_DIR/last-errors.txt"
        for repo in $FAILED_REPOS; do
            [[ -z "$repo" ]] && continue
            printf "%s\n" "$repo" >> "$CACHE_DIR/affected-repos.txt"
        done
        atomic_sort_unique "$CACHE_DIR/affected-repos.txt"

        echo "# TSC Commands by Repo" > "$CACHE_DIR/tsc-commands.txt"
        for repo in $FAILED_REPOS; do
            repo_key="$(repo_cache_key "$repo")"
            cmd=$(cat "$CACHE_DIR/$repo_key-tsc-cmd.cache" 2>/dev/null || echo "npx tsc --noEmit")
            echo "$repo: $cmd" >> "$CACHE_DIR/tsc-commands.txt"
        done

        {
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🚨 TypeScript errors found in $ERROR_COUNT repo(s): $FAILED_REPOS"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "👉 IMPORTANT: Use the auto-error-resolver agent to fix the errors"
            echo ""
            echo "WE DO NOT LEAVE A MESS BEHIND"
            echo "Error Preview:"
            echo "$ERROR_OUTPUT" | grep "error TS" | head -10
            echo ""
            if [ $(echo "$ERROR_OUTPUT" | grep -c "error TS") -gt 10 ]; then
                echo "... and $(($(echo "$ERROR_OUTPUT" | grep -c "error TS") - 10)) more errors"
            fi
        } >&2

        exit_code=1
    fi
fi

exit ${exit_code:-0}
