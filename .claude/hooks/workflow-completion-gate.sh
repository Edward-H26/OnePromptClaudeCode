#!/bin/bash
# Note: set -e intentionally omitted. This advisory gate always exits 0
# and handles cleanup failures silently by design.

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed" >&2; exit 0; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"
CLAUDE_HOME_DIR="$(resolve_claude_home)"

HOOK_INPUT=$(cat)
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")
SESSION_ID="${SESSION_ID:-default}"

CACHE_DIR="$CLAUDE_HOME_DIR/tsc-cache/$SESSION_ID"
STEPS_DIR="$CACHE_DIR/workflow-steps"

if [[ ! -f "$CACHE_DIR/affected-repos.txt" ]]; then
    if [[ ! -f "$CACHE_DIR/edited-files.log" ]]; then
        safe_rm_cache "$CACHE_DIR"
        exit 0
    fi
fi

if [[ ! -f "$CACHE_DIR/commands.txt" ]] && [[ ! -f "$CACHE_DIR/edited-files.log" ]]; then
    safe_rm_cache "$CACHE_DIR"
    exit 0
fi

if [[ -d "$CACHE_DIR/gate-fired" ]]; then
    rmdir "$CACHE_DIR/gate-fired" 2>/dev/null || true
fi

MISSING=""
COMPLETED=""

if [[ -f "$CACHE_DIR/affected-repos.txt" ]] && [[ -s "$CACHE_DIR/affected-repos.txt" ]]; then
    if [[ -d "$STEPS_DIR/codex-kickoff" ]]; then
        COMPLETED="${COMPLETED}[x] Optional Codex kickoff recorded\n"
    else
        MISSING="${MISSING}[ ] Optional Codex kickoff not recorded\n"
    fi

    if [[ -d "$STEPS_DIR/simplify-review" ]]; then
        COMPLETED="${COMPLETED}[x] Optional simplification review recorded\n"
    else
        MISSING="${MISSING}[ ] Optional simplification review not recorded\n"
    fi

    if [[ -d "$STEPS_DIR/codex-eval" ]]; then
        COMPLETED="${COMPLETED}[x] Optional Codex evaluation recorded\n"
    else
        MISSING="${MISSING}[ ] Optional Codex evaluation not recorded\n"
    fi
fi

HAS_FRONTEND_FILES=0
if awk -F'\t' '{print $2}' "$CACHE_DIR/edited-files.log" 2>/dev/null | grep -qE '\.(tsx|jsx|css|scss)$'; then
    HAS_FRONTEND_FILES=1
fi

if [[ "$HAS_FRONTEND_FILES" -gt 0 ]]; then
    if [[ -d "$STEPS_DIR/chrome-verification" ]]; then
        COMPLETED="${COMPLETED}[x] Browser verification recorded\n"
    else
        MISSING="${MISSING}[ ] Frontend files changed without recorded browser verification\n"
    fi
fi

if [[ -n "$MISSING" ]]; then
    mkdir -p "$CACHE_DIR/gate-fired" 2>/dev/null || true
    {
        echo ""
        echo "Workflow reminder:"
        printf '%b\n' "$MISSING"
        echo "These are optional workflow signals. Build and type failures are still enforced by the validation hooks."
        echo ""
    } >&2
fi

TSC_CACHE_ROOT="$CLAUDE_HOME_DIR/tsc-cache"
if [[ -d "$TSC_CACHE_ROOT" ]]; then
    while IFS= read -r stale_dir; do
        safe_rm_cache "$stale_dir"
    done < <(find "$TSC_CACHE_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +14 2>/dev/null)
fi

exit 0
