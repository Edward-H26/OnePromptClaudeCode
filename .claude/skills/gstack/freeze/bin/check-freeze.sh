#!/usr/bin/env bash
# check-freeze.sh — PreToolUse hook for /freeze skill
# Reads JSON from stdin, checks if file_path is within the freeze boundary.
# Returns {"permissionDecision":"deny","message":"..."} to block, or {} to allow.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_HELPER="$SCRIPT_DIR/../../../../hooks/lib/runtime-state.sh"
if [[ -f "$RUNTIME_HELPER" ]]; then
  # shellcheck source=/dev/null
  source "$RUNTIME_HELPER"
fi

# Read stdin
INPUT=$(cat)

# Locate the freeze directory state file
STATE_DIR="${CLAUDE_PLUGIN_DATA:-${GSTACK_STATE_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}/.claude/runtime/gstack}}"
if declare -F gstack_state_dir >/dev/null 2>&1; then
  STATE_DIR="$(gstack_state_dir)"
fi
FREEZE_FILE="${FREEZE_FILE:-${STATE_DIR}/freeze-dir.txt}"
ANALYTICS_DIR="${ANALYTICS_DIR:-${STATE_DIR}/analytics}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

# If no freeze file exists, allow everything (not yet configured)
if [ ! -f "$FREEZE_FILE" ]; then
  echo '{}'
  exit 0
fi

IFS= read -r FREEZE_DIR < "$FREEZE_FILE" || true

# If freeze dir is empty, allow
if [ -z "$FREEZE_DIR" ]; then
  echo '{}'
  exit 0
fi

FREEZE_DIR=$(printf '%s' "$FREEZE_DIR" | sed 's|/\+|/|g;s|/$||')

# Extract file paths from tool_input JSON.
# Supports Edit/Write (`file_path`) and MultiEdit (`edits[].file_path`).
FILE_PATHS=$(printf '%s' "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:[[:space:]]*"//;s/"$//' || true)

# Python fallback if grep returned empty
if [ -z "$FILE_PATHS" ]; then
  PYTHON_CMD="python3"
  command -v python3 >/dev/null 2>&1 || PYTHON_CMD="python"
  FILE_PATHS=$(printf '%s' "$INPUT" | "$PYTHON_CMD" -c 'import json, sys
tool_input = json.loads(sys.stdin.read()).get("tool_input", {})
paths = []
file_path = tool_input.get("file_path", "")
if file_path:
    paths.append(file_path)
for edit in tool_input.get("edits", []):
    edit_path = edit.get("file_path", "")
    if edit_path:
        paths.append(edit_path)
print("\n".join(paths))' 2>/dev/null || true)
fi

# If we couldn't extract any file paths, allow (don't block on parse failure)
if [ -z "$FILE_PATHS" ]; then
  echo '{}'
  exit 0
fi

FIRST_VIOLATION=""

while IFS= read -r FILE_PATH; do
  [ -z "$FILE_PATH" ] && continue

  case "$FILE_PATH" in
    /*) ;; # already absolute
    *)
      FILE_PATH="$PROJECT_DIR/$FILE_PATH"
      ;;
  esac

  FILE_PATH=$(printf '%s' "$FILE_PATH" | sed 's|/\+|/|g;s|/$||')

  case "$FILE_PATH" in
    "$FREEZE_DIR"|"$FREEZE_DIR"/*)
      ;;
    *)
      FIRST_VIOLATION="$FILE_PATH"
      break
      ;;
  esac
done <<< "$FILE_PATHS"

if [ -z "$FIRST_VIOLATION" ]; then
  echo '{}'
  exit 0
fi

mkdir -p "$ANALYTICS_DIR" 2>/dev/null || true
echo '{"event":"hook_fire","skill":"freeze","pattern":"boundary_deny","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","repo":"'$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")'"}' >> "$ANALYTICS_DIR/skill-usage.jsonl" 2>/dev/null || true

printf '{"permissionDecision":"deny","message":"[freeze] Blocked: %s is outside the freeze boundary (%s). Only edits within the frozen directory are allowed."}\n' "$FIRST_VIOLATION" "$FREEZE_DIR/"
