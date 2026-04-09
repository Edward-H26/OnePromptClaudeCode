#!/bin/bash
set -e

command -v jq >/dev/null 2>&1 || exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/patterns.sh"
source "$SCRIPT_DIR/lib/runtime-state.sh"
source "$SCRIPT_DIR/lib/utils.sh"
CLAUDE_HOME_DIR="$(resolve_claude_home)"

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

if [[ -z "$PROMPT" ]]; then
    exit 0
fi

CODEX_SCRIPT="${AUTO_CODEX_SCRIPT:-$CLAUDE_HOME_DIR/skills/codex/scripts/ask_codex.sh}"
if [[ ! -x "$CODEX_SCRIPT" ]]; then
    echo "WARNING: Codex script not found or not executable at $CODEX_SCRIPT" >&2
    exit 0
fi

if ! command -v codex >/dev/null 2>&1; then
    echo "WARNING: codex command not found in PATH" >&2
    exit 0
fi

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
AUTO_CODEX_HOME="$(codex_home_dir)"
RUNTIME_DIR="$(codex_runs_dir)"
mkdir -p "$RUNTIME_DIR"
ARTIFACT_DIR="$(mktemp -d "$RUNTIME_DIR/auto-${TIMESTAMP}-XXXXXX")"
OUTPUT_PATH="$ARTIFACT_DIR/output.md"
CODEX_LOG="$ARTIFACT_DIR/run.log"
PID_PATH="$ARTIFACT_DIR/run.pid"

# Codex run artifacts are self-contained and consumed immediately; shorter
# retention (7d) than the 14d threshold used by tsc-cache and doctor checks.
find "$RUNTIME_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
SESSION_ID="$(sanitize_session_id "${SESSION_ID:-default}")"
STEPS_DIR="$CLAUDE_HOME_DIR/tsc-cache/$SESSION_ID/workflow-steps"
mkdir -p "$STEPS_DIR"
mkdir -p "$STEPS_DIR/codex-kickoff" 2>/dev/null || true

PROMPT_FILE="$(mktemp)" || { echo "Failed to create temp file" >&2; exit 1; }
LAUNCH_SCRIPT="$(mktemp)" || { rm -f "$PROMPT_FILE"; echo "Failed to create temp file" >&2; exit 1; }
printf '%s' "$PROMPT" > "$PROMPT_FILE"
cat > "$LAUNCH_SCRIPT" <<'LAUNCH'
#!/bin/bash
export CLAUDE_PROJECT_DIR="$1"
export AUTO_CODEX_HOME="$2"
export AUTO_CODEX_RUNTIME_DIR="$3"
"$4" -t "$(cat "$5")" -w "$1" -o "$6"
LAUNCH
chmod +x "$LAUNCH_SCRIPT"
nohup /bin/bash -c '
    LAUNCH_SCRIPT="$1"; PROMPT_FILE="$2"
    WORKSPACE="$3"; CODEX_HOME="$4"; RUNTIME="$5"
    CODEX_SCRIPT="$6"; OUTPUT="$7"; TIMEOUT_SECS="$8"
    TIMEOUT_CMD=""
    command -v timeout >/dev/null 2>&1 && TIMEOUT_CMD="timeout"
    command -v gtimeout >/dev/null 2>&1 && TIMEOUT_CMD="gtimeout"
    if [ -n "$TIMEOUT_CMD" ]; then
        "$TIMEOUT_CMD" "$TIMEOUT_SECS" /bin/bash "$LAUNCH_SCRIPT" "$WORKSPACE" "$CODEX_HOME" "$RUNTIME" "$CODEX_SCRIPT" "$PROMPT_FILE" "$OUTPUT"
    else
        echo "WARNING: neither timeout nor gtimeout found; Codex running without external timeout guard" >&2
        /bin/bash "$LAUNCH_SCRIPT" "$WORKSPACE" "$CODEX_HOME" "$RUNTIME" "$CODEX_SCRIPT" "$PROMPT_FILE" "$OUTPUT"
    fi
    rm -f "$PROMPT_FILE" "$LAUNCH_SCRIPT"
' _ "$LAUNCH_SCRIPT" "$PROMPT_FILE" "$WORKSPACE" "$AUTO_CODEX_HOME" "$RUNTIME_DIR" "$CODEX_SCRIPT" "$OUTPUT_PATH" "${CODEX_TIMEOUT:-120}" > "$CODEX_LOG" 2>&1 &
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
