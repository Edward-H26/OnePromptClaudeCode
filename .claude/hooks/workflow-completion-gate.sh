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
SESSION_ID="$(sanitize_session_id "${SESSION_ID:-default}")"

CACHE_DIR="$CLAUDE_HOME_DIR/tsc-cache/$SESSION_ID"

if awk -F'\t' '{print $2}' "$CACHE_DIR/edited-files.log" 2>/dev/null | grep -qE '\.(tsx|jsx|css|scss)$'; then
    {
        echo ""
        echo "Browser verification reminder:"
        echo "Frontend files (.tsx/.jsx/.css/.scss) changed this session."
        echo "Verify the affected UI in the browser tooling available in this session."
        echo ""
    } >&2
fi

# Session tsc-cache uses 14-day retention because it may span multiple sessions.
TSC_CACHE_ROOT="$CLAUDE_HOME_DIR/tsc-cache"
if [[ -d "$TSC_CACHE_ROOT" ]]; then
    while IFS= read -r stale_dir; do
        safe_rm_cache "$stale_dir"
    done < <(find "$TSC_CACHE_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +14 2>/dev/null)
fi

exit 0
