#!/bin/bash
# This hook uses explicit exit-code handling throughout.
# Do not enable set -e here, because the script intentionally aggregates failures.

# Stop event hook that re-runs tracked TypeScript checks and provides
# instructions for error resolution.

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed" >&2; exit 0; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"
CLAUDE_HOME_DIR="$(resolve_claude_home)"

EVENT_INFO=$(cat)

SESSION_ID=$(echo "$EVENT_INFO" | jq -r '.session_id // empty' 2>/dev/null || echo "")

CACHE_DIR="$CLAUDE_HOME_DIR/tsc-cache/${SESSION_ID:-default}"

if [[ ! -d "$CACHE_DIR" ]]; then
    exit 0
fi

if [[ ! -f "$CACHE_DIR/affected-repos.txt" ]]; then
    exit 0
fi

if [[ ! -f "$CACHE_DIR/commands.txt" ]]; then
    exit 0
fi

RESULTS_DIR="$CACHE_DIR/results"
mkdir -p "$RESULTS_DIR"

TOTAL_ERRORS=0
HAS_ERRORS=false

count_tsc_errors() {
    local output="$1"
    echo "$output" | grep -cE "\.tsx?.*:.*error TS[0-9]+:" 2>/dev/null || echo "0"
}

> "$RESULTS_DIR/error-summary.txt"

while IFS= read -r repo; do
    [[ -z "$repo" ]] && continue
    repo_key="$(repo_cache_key "$repo")"

    tsc_cmd=$(awk -F'\t' -v r="$repo" '$1 == r && $2 == "tsc" {print $3}' "$CACHE_DIR/commands.txt" 2>/dev/null || echo "")

    if [[ -z "$tsc_cmd" ]]; then
        continue
    fi

    output=$(validate_and_run_tsc "$tsc_cmd" 2>&1)
    tsc_exit=$?

    if [[ $tsc_exit -ne 0 ]]; then
        if [[ $tsc_exit -eq 2 ]]; then
            continue
        fi
        HAS_ERRORS=true

        error_count=$(count_tsc_errors "$output")
        TOTAL_ERRORS=$((TOTAL_ERRORS + error_count))

        echo "$output" > "$RESULTS_DIR/$repo_key-errors.txt"
        printf "%s\t%s\t%s\n" "$repo_key" "$repo" "$error_count" >> "$RESULTS_DIR/error-summary.txt"
    else
        printf "%s\t%s\t0\n" "$repo_key" "$repo" >> "$RESULTS_DIR/error-summary.txt"
    fi
done < <(sort -u "$CACHE_DIR/affected-repos.txt")

if [[ "$HAS_ERRORS" == "true" ]]; then
    > "$CACHE_DIR/last-errors.txt"
    while IFS=$'\t' read -r repo_key repo_name error_count; do
        [[ -z "$repo_key" ]] && continue
        if [[ "$error_count" -gt 0 ]] && [[ -f "$RESULTS_DIR/$repo_key-errors.txt" ]]; then
            echo "=== Errors in $repo_name ===" >> "$CACHE_DIR/last-errors.txt"
            cat "$RESULTS_DIR/$repo_key-errors.txt" >> "$CACHE_DIR/last-errors.txt"
            echo "" >> "$CACHE_DIR/last-errors.txt"
        fi
    done < "$RESULTS_DIR/error-summary.txt"

    AFFECTED_REPOS=$(cat "$CACHE_DIR/affected-repos.txt" 2>/dev/null | sort -u | tr '\n' ' ')
    TSC_COMMANDS=$(cat "$CACHE_DIR/commands.txt" 2>/dev/null || echo "")
    ERROR_PREVIEW=$(grep "error TS" "$CACHE_DIR/last-errors.txt" 2>/dev/null | head -5)

    if [[ $TOTAL_ERRORS -ge ${AUTO_ERROR_THRESHOLD:-5} ]]; then
        echo "" >&2
        echo "## TypeScript Build Errors Detected" >&2
        echo "" >&2
        echo "Found $TOTAL_ERRORS TypeScript errors across the following repos:" >&2
        while IFS=$'\t' read -r _ repo count; do
            if [[ $count -gt 0 ]]; then
                echo "- $repo: $count errors" >&2
            fi
        done < "$RESULTS_DIR/error-summary.txt"
        echo "" >&2
        echo "Please use the auto-error-resolver agent to fix these errors systematically." >&2
        echo "" >&2
    else
        echo "" >&2
        echo "## Minor TypeScript Errors" >&2
        echo "" >&2
        echo "Found $TOTAL_ERRORS TypeScript error(s). Here are the details:" >&2
        echo "" >&2
        sed 's/^/  /' "$CACHE_DIR/last-errors.txt" >&2
        echo "" >&2
        echo "Please fix these errors directly in the affected files." >&2
        echo "" >&2
    fi

    cat << RESOLUTION

================================================================================
BUILD ERROR RESOLUTION NEEDED
================================================================================

ERRORS DETECTED: $TOTAL_ERRORS TypeScript errors
AFFECTED AREAS: $AFFECTED_REPOS

RECOMMENDED ACTION:
Use the auto-error-resolver agent to fix these TypeScript errors automatically.

TSC COMMANDS FOR VERIFICATION:
$TSC_COMMANDS

ERROR PREVIEW:
$ERROR_PREVIEW
$([ "$TOTAL_ERRORS" -gt 5 ] && echo "... and $((TOTAL_ERRORS - 5)) more errors")

================================================================================
RESOLUTION

    exit 1
else
    exit 0
fi
