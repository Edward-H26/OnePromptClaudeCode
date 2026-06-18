#!/bin/bash
# This hook uses explicit exit-code handling throughout.
# Do not enable set -e here, because the script intentionally aggregates failures.
#
# PostToolUse on Edit|MultiEdit|Write. Merges three concerns:
#   1. TypeScript check on affected repos (logic copied verbatim from tsc-check).
#   2. Native linter on each edited file (ruff, flake8, eslint, biome, shellcheck).
#   3. Python type check via pyright (or ruff fallback) on edited .py files.
# It also records every edited file path to edited-files.log so the Stop hook
# can read the change set. Exits non-zero when any check finds errors.

command -v jq >/dev/null 2>&1 || exit 0

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"
CLAUDE_HOME_DIR="$(resolve_claude_home)"

HOOK_INPUT=$(cat)
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")
SESSION_ID="$(sanitize_session_id "${SESSION_ID:-default}")"
CACHE_DIR="$CLAUDE_HOME_DIR/tsc-cache/$SESSION_ID"

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
        cd "$repo_path" 2>/dev/null || exit 2

        local tsc_cmd
        local cache_stale=""
        if [ -f "$cache_file" ] && [ -z "$FORCE_DETECT" ]; then
            for tsconf in tsconfig.json tsconfig.app.json tsconfig.build.json; do
                if [ -f "$repo_path/$tsconf" ] && [ "$repo_path/$tsconf" -nt "$cache_file" ]; then
                    cache_stale=1
                    break
                fi
            done
        fi
        if [ -f "$cache_file" ] && [ -z "$FORCE_DETECT" ] && [ -z "$cache_stale" ]; then
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

TOOL_INPUT=$(echo "$HOOK_INPUT" | jq '.tool_input // {}')
if [ "$TOOL_NAME" = "MultiEdit" ]; then
    EDITED_FILES=$(echo "$TOOL_INPUT" | jq -r '[.file_path // empty, (.edits[]?.file_path // empty)] | unique | .[]')
else
    EDITED_FILES=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
fi

while IFS= read -r edited_file; do
    [[ -z "$edited_file" ]] && continue
    printf "%s\t%s\n" "$TOOL_NAME" "$edited_file" >> "$CACHE_DIR/edited-files.log"
done <<< "$EDITED_FILES"

REPOS_TO_CHECK=""
if [[ -f "$CACHE_DIR/affected-repos.txt" ]]; then
    REPOS_TO_CHECK=$(sort -u "$CACHE_DIR/affected-repos.txt" | tr '\n' ' ')
else
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
        CHECK_OUTPUT=$(run_tsc_check "$repo" 2>&1)
        CHECK_EXIT_CODE=$?

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

        echo "# Commands by Repo" > "$CACHE_DIR/commands.txt"
        for repo in $FAILED_REPOS; do
            repo_key="$(repo_cache_key "$repo")"
            cmd=$(cat "$CACHE_DIR/$repo_key-tsc-cmd.cache" 2>/dev/null || echo "npx tsc --noEmit")
            repo_path="$CLAUDE_PROJECT_DIR/$repo"
            printf "%s\ttsc\tcd \"%s\" && %s\n" "$repo" "$repo_path" "$cmd" >> "$CACHE_DIR/commands.txt"
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
            ts_error_count=$(echo "$ERROR_OUTPUT" | grep -c "error TS" || echo "0")
            if [ "${ts_error_count:-0}" -gt 10 ]; then
                echo "... and $((ts_error_count - 10)) more errors"
            fi
        } >&2

        exit_code=1
    fi
fi

detect_linter() {
    local file="$1"
    local dir
    dir="$(dirname "$file")"
    while [[ "$dir" != "/" && "$dir" != "." ]]; do
        case "$file" in
            *.py)
                if [[ -f "$dir/pyproject.toml" ]] && grep -q "ruff" "$dir/pyproject.toml" 2>/dev/null; then
                    echo "ruff"; return 0
                fi
                if [[ -f "$dir/.ruff.toml" || -f "$dir/ruff.toml" ]]; then
                    echo "ruff"; return 0
                fi
                if [[ -f "$dir/.flake8" || -f "$dir/setup.cfg" ]]; then
                    echo "flake8"; return 0
                fi
                ;;
            *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs)
                if [[ -f "$dir/eslint.config.js" || -f "$dir/eslint.config.mjs" || -f "$dir/.eslintrc" || -f "$dir/.eslintrc.js" || -f "$dir/.eslintrc.json" ]]; then
                    echo "eslint"; return 0
                fi
                if [[ -f "$dir/biome.json" || -f "$dir/biome.jsonc" ]]; then
                    echo "biome"; return 0
                fi
                ;;
            *.sh)
                if command -v shellcheck >/dev/null 2>&1; then
                    echo "shellcheck"; return 0
                fi
                ;;
        esac
        dir="$(dirname "$dir")"
    done
    echo ""
    return 1
}

run_linter() {
    local linter="$1"
    local file="$2"
    case "$linter" in
        ruff)
            ruff check --quiet "$file" 2>&1
            ;;
        flake8)
            flake8 "$file" 2>&1
            ;;
        eslint)
            npx --no-install eslint --max-warnings 0 "$file" 2>&1
            ;;
        biome)
            npx --no-install biome check "$file" 2>&1
            ;;
        shellcheck)
            shellcheck -S warning "$file" 2>&1
            ;;
    esac
}

LINT_FAILURES=""
LINT_FAIL_COUNT=0
while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    [[ ! -f "$file" ]] && continue
    linter=$(detect_linter "$file")
    [[ -z "$linter" ]] && continue
    if ! command -v "${linter%% *}" >/dev/null 2>&1 && [[ "$linter" != "eslint" && "$linter" != "biome" ]]; then
        continue
    fi
    output=$(run_linter "$linter" "$file")
    rc=$?
    if [[ $rc -ne 0 && -n "$output" ]]; then
        LINT_FAILURES="${LINT_FAILURES}
=== $linter on $file ===
$output"
        LINT_FAIL_COUNT=$((LINT_FAIL_COUNT + 1))
    fi
done <<< "$EDITED_FILES"

if [[ $LINT_FAIL_COUNT -gt 0 ]]; then
    {
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "LINT: $LINT_FAIL_COUNT file(s) have lint violations"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "$LINT_FAILURES" | head -40
    } >&2
    exit_code=1
fi

PY_FAILURES=""
PY_FAIL_COUNT=0
while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    [[ ! -f "$file" ]] && continue
    [[ "$file" != *.py ]] && continue
    if command -v pyright >/dev/null 2>&1; then
        output=$(pyright "$file" 2>&1)
        rc=$?
    elif command -v ruff >/dev/null 2>&1; then
        output=$(ruff check "$file" 2>&1)
        rc=$?
    else
        continue
    fi
    if [[ $rc -ne 0 && -n "$output" ]]; then
        PY_FAILURES="${PY_FAILURES}
=== python check on $file ===
$output"
        PY_FAIL_COUNT=$((PY_FAIL_COUNT + 1))
    fi
done <<< "$EDITED_FILES"

if [[ $PY_FAIL_COUNT -gt 0 ]]; then
    {
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "PYTHON: $PY_FAIL_COUNT file(s) failed the Python check"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "$PY_FAILURES" | head -40
    } >&2
    exit_code=1
fi

exit ${exit_code:-0}
