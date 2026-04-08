#!/bin/bash
set -e

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

if [[ -z "$PROMPT" ]]; then
    exit 0
fi

CODEX_SCRIPT="${AUTO_CODEX_SCRIPT:-${CLAUDE_PROJECT_DIR:-$PWD}/.claude/skills/codex/scripts/ask_codex.sh}"
if [[ ! -x "$CODEX_SCRIPT" ]]; then
    echo "WARNING: Codex script not found or not executable at $CODEX_SCRIPT" >&2
    exit 0
fi

if ! command -v codex >/dev/null 2>&1; then
    echo "WARNING: codex command not found in PATH" >&2
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/patterns.sh"

PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

HAS_EXPLICIT_IMPLEMENTATION=false
if echo "$PROMPT_LOWER" | grep -qiE "$EXPLICIT_IMPLEMENTATION_PATTERN"; then
    HAS_EXPLICIT_IMPLEMENTATION=true
elif echo "$PROMPT_LOWER" | grep -qiE "$WORKFLOW_IMPLEMENTATION_PATTERN"; then
    HAS_EXPLICIT_IMPLEMENTATION=true
fi

SKIP_PATTERNS="^(hi|hello|hey|thanks|thank you|good morning|good evening|bye|goodbye|ok|okay|yes|no|sure|got it|sounds good|perfect|great|cool|nice)[.!?, ]*$"
if echo "$PROMPT_LOWER" | grep -qiE "$SKIP_PATTERNS"; then
    exit 0
fi

if [[ ${#PROMPT} -lt 15 ]]; then
    exit 0
fi

MEMORY_PATTERNS="(remember|forget|stop remembering|don't remember|update memory)"
if echo "$PROMPT_LOWER" | grep -qiE "$MEMORY_PATTERNS"; then
    exit 0
fi

if echo "$PROMPT_LOWER" | grep -qiE "$ANALYSIS_PATTERN"; then
    if [[ "$HAS_EXPLICIT_IMPLEMENTATION" != "true" ]]; then
        exit 0
    fi
fi

if echo "$PROMPT_LOWER" | grep -qiE "$PURE_QUESTION_PATTERN"; then
    if ! echo "$PROMPT_LOWER" | grep -qiE "$CODING_PATTERN"; then
        exit 0
    fi
fi

if ! echo "$PROMPT_LOWER" | grep -qiE "$CODING_PATTERN"; then
    if ! echo "$PROMPT_LOWER" | grep -qiE "$CODING_CONTEXT_PATTERN"; then
        exit 0
    fi
fi

WORKSPACE="${CLAUDE_PROJECT_DIR:-$PWD}"
TIMESTAMP=$(date -u +"%Y%m%d-%H%M%S")
AUTO_CODEX_HOME="${AUTO_CODEX_HOME:-$WORKSPACE/.claude/runtime/codex/home}"
RUNTIME_DIR="${AUTO_CODEX_RUNTIME_DIR:-$WORKSPACE/.claude/runtime/codex/runs}"
mkdir -p "$RUNTIME_DIR"
ARTIFACT_DIR="$(mktemp -d "$RUNTIME_DIR/auto-${TIMESTAMP}-XXXXXX")"
OUTPUT_PATH="$ARTIFACT_DIR/output.md"
CODEX_LOG="$ARTIFACT_DIR/run.log"
PID_PATH="$ARTIFACT_DIR/run.pid"

# Codex run artifacts are self-contained and consumed immediately; shorter
# retention (7d) than the 14d threshold used by tsc-cache and doctor checks.
find "$RUNTIME_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
SESSION_ID="${SESSION_ID:-default}"
STEPS_DIR="$WORKSPACE/.claude/tsc-cache/$SESSION_ID/workflow-steps"
mkdir -p "$STEPS_DIR"
mkdir -p "$STEPS_DIR/codex-kickoff" 2>/dev/null || true

PROMPT_FILE="$(mktemp)"
LAUNCH_SCRIPT="$(mktemp)"
printf '%s' "$PROMPT" > "$PROMPT_FILE"
cat > "$LAUNCH_SCRIPT" <<LAUNCH
#!/bin/bash
export CLAUDE_PROJECT_DIR="$WORKSPACE"
export AUTO_CODEX_HOME="$AUTO_CODEX_HOME"
export AUTO_CODEX_RUNTIME_DIR="$RUNTIME_DIR"
"$CODEX_SCRIPT" -t "\$(cat '$PROMPT_FILE')" -w "$WORKSPACE" -o "$OUTPUT_PATH"
LAUNCH
chmod +x "$LAUNCH_SCRIPT"
nohup /bin/bash -c '
    TIMEOUT_CMD=""
    command -v timeout >/dev/null 2>&1 && TIMEOUT_CMD="timeout"
    command -v gtimeout >/dev/null 2>&1 && TIMEOUT_CMD="gtimeout"
    if [ -n "$TIMEOUT_CMD" ]; then
        "$TIMEOUT_CMD" 120 /bin/bash "$1"
    else
        echo "WARNING: neither timeout nor gtimeout found; Codex running without external timeout guard" >&2
        /bin/bash "$1"
    fi
    rm -f "$2" "$1"
' _ "$LAUNCH_SCRIPT" "$PROMPT_FILE" > "$CODEX_LOG" 2>&1 &
CODEX_PID=$!
echo "$CODEX_PID" > "$PID_PATH"

cat << EOF
================================================================================
CODEX: Running in background (optional)
================================================================================
Output will be at: $OUTPUT_PATH
PID: $CODEX_PID

Before delivering, consider reading the output and merging useful findings.
================================================================================
EOF
