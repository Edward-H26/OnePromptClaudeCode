#!/bin/bash
# Pre-compact hook (PreCompact)
# Snapshots in-progress task state to runtime/last-precompact.md so important
# context survives auto-compaction. Reads optional task list and edited-files
# trail when available. Silent on success.

command -v jq >/dev/null 2>&1 || exit 0

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/hook-metrics.sh"
CLAUDE_HOME_DIR="$(resolve_claude_home)"
record_hook_invocation "pre-compact"

LOG_DIR="${CLAUDE_HOME_DIR}/runtime"
mkdir -p "$LOG_DIR"
SNAPSHOT="${LOG_DIR}/last-precompact.md"

HOOK_INPUT=$(cat 2>/dev/null || echo "{}")
TRIGGER=$(echo "$HOOK_INPUT" | jq -r '.trigger // ""' 2>/dev/null || echo "")
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

EDITED_TRACKER="${LOG_DIR}/edited-files.txt"
EDITED_LIST=""
if [[ -f "$EDITED_TRACKER" ]]; then
    EDITED_LIST=$(tail -50 "$EDITED_TRACKER" 2>/dev/null)
fi

{
    echo "# Pre-compact snapshot"
    echo
    echo "- timestamp: $TS"
    echo "- trigger: ${TRIGGER:-unknown}"
    echo
    if [[ -n "$EDITED_LIST" ]]; then
        echo "## Recently edited files"
        echo
        echo "\`\`\`"
        echo "$EDITED_LIST"
        echo "\`\`\`"
    fi
} > "$SNAPSHOT" 2>/dev/null || true

exit 0
