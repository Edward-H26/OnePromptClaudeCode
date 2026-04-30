#!/bin/bash
# Lint-check hook (PostToolUse on Edit|MultiEdit|Write)
# Detects the linter native to each edited file's project, runs it on the
# specific file only, and feeds violations back so the model can self-correct.
# Silent when no linter is configured or none of the edited files are lintable.

command -v jq >/dev/null 2>&1 || exit 0

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/hook-metrics.sh"
CLAUDE_HOME_DIR="$(resolve_claude_home)"
record_hook_invocation "lint-check"

HOOK_INPUT=$(cat)
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // ""')
if [[ ! "$TOOL_NAME" =~ ^(Edit|MultiEdit|Write)$ ]]; then
    exit 0
fi

TOOL_INPUT=$(echo "$HOOK_INPUT" | jq '.tool_input // {}')
if [ "$TOOL_NAME" = "MultiEdit" ]; then
    FILE_PATHS=$(echo "$TOOL_INPUT" | jq -r '[.file_path // empty, (.edits[]?.file_path // empty)] | unique | .[]')
else
    FILE_PATHS=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
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

FAILURES=""
FAIL_COUNT=0
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
        FAILURES="${FAILURES}
=== $linter on $file ===
$output"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done <<< "$FILE_PATHS"

if [[ $FAIL_COUNT -gt 0 ]]; then
    {
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "LINT: $FAIL_COUNT file(s) have lint violations"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "$FAILURES" | head -40
    } >&2
fi

exit 0
