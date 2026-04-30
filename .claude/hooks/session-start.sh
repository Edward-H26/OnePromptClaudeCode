#!/bin/bash
# Session start hook (SessionStart)
# Validates required local tools and surfaces a one-time onboarding banner so a
# fresh clone fails fast with a useful message instead of silently misbehaving.
# Exits 0 even on missing tools so the session always starts.

command -v jq >/dev/null 2>&1 || exit 0

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/hook-metrics.sh"
CLAUDE_HOME_DIR="$(resolve_claude_home)"
record_hook_invocation "session-start"

LOG_DIR="${CLAUDE_HOME_DIR}/runtime"
mkdir -p "$LOG_DIR"
SESSIONS_LOG="${LOG_DIR}/sessions.jsonl"

HOOK_INPUT=$(cat 2>/dev/null || echo "{}")
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""' 2>/dev/null || echo "")
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

MISSING=()
for tool in node python3 git; do
    command -v "$tool" >/dev/null 2>&1 || MISSING+=("$tool")
done

jq -cn \
    --arg ts "$TS" \
    --arg session_id "$SESSION_ID" \
    "{ts:\$ts,event:\"start\",session_id:\$session_id,missing:\$ARGS.positional}" \
    --args "${MISSING[@]}" \
    >> "$SESSIONS_LOG" 2>/dev/null || true

if [[ ${#MISSING[@]} -gt 0 ]]; then
    {
        echo "SessionStart: missing local tools — ${MISSING[*]}"
        echo "Install them or some hooks/skills will fail on use."
    } >&2
fi

exit 0
