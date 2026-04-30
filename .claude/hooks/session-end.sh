#!/bin/bash
# Session end hook (SessionEnd)
# Appends a session-close summary to runtime/sessions.jsonl and rotates the log
# at 5 MB. Silent on success.

command -v jq >/dev/null 2>&1 || exit 0

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/hook-metrics.sh"
CLAUDE_HOME_DIR="$(resolve_claude_home)"
record_hook_invocation "session-end"

LOG_DIR="${CLAUDE_HOME_DIR}/runtime"
mkdir -p "$LOG_DIR"
SESSIONS_LOG="${LOG_DIR}/sessions.jsonl"

if [[ -f "$SESSIONS_LOG" ]]; then
    LOG_SIZE=$(stat -f%z "$SESSIONS_LOG" 2>/dev/null || stat -c%s "$SESSIONS_LOG" 2>/dev/null || echo 0)
    if [[ "$LOG_SIZE" -gt 5242880 ]]; then
        mv "$SESSIONS_LOG" "${SESSIONS_LOG}.1" 2>/dev/null || true
    fi
fi

HOOK_INPUT=$(cat 2>/dev/null || echo "{}")
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""' 2>/dev/null || echo "")
REASON=$(echo "$HOOK_INPUT" | jq -r '.reason // ""' 2>/dev/null || echo "")
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

EDITED_TRACKER="${LOG_DIR}/edited-files.txt"
EDITED_COUNT=0
[[ -f "$EDITED_TRACKER" ]] && EDITED_COUNT=$(wc -l < "$EDITED_TRACKER" 2>/dev/null | tr -d ' ' || echo 0)

printf '{"ts":"%s","event":"end","session_id":"%s","reason":"%s","edited_files":%s}\n' \
    "$TS" "$SESSION_ID" "$REASON" "$EDITED_COUNT" \
    >> "$SESSIONS_LOG" 2>/dev/null || true

exit 0
