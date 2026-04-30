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
PROMPT_LOCK_DIR=""

release_prompt_lock() {
    if [[ -n "$PROMPT_LOCK_DIR" ]]; then
        rmdir "$PROMPT_LOCK_DIR" 2>/dev/null || true
        PROMPT_LOCK_DIR=""
    fi
}
trap release_prompt_lock EXIT

# UserPromptSubmit may be registered in both user-global and project settings
# which causes this hook to fire twice in parallel. Two concurrent codex
# children then race on OAuth refresh against a shared auth.json and yield
# 401 refresh_token_reused. Gate startup on an atomic per-prompt lock, then
# release it once the background child has launched.
PROMPT_HASH=$(printf '%s' "$PROMPT" | shasum -a 256 2>/dev/null | cut -c1-16)
if [[ -n "$PROMPT_HASH" ]]; then
    LOCK_ROOT="$RUNTIME_DIR/.locks"
    mkdir -p "$LOCK_ROOT" 2>/dev/null || true
    LOCK_DIR="$LOCK_ROOT/$PROMPT_HASH"
    if ! mkdir "$LOCK_DIR" 2>/dev/null; then
        LOCK_MTIME=$(stat -f %m "$LOCK_DIR" 2>/dev/null || stat -c %Y "$LOCK_DIR" 2>/dev/null || echo 0)
        LOCK_AGE=$(( $(date +%s) - LOCK_MTIME ))
        if (( LOCK_AGE < 600 )); then
            exit 0
        fi
        rm -rf "$LOCK_DIR" 2>/dev/null
        mkdir "$LOCK_DIR" 2>/dev/null || exit 0
    fi
    PROMPT_LOCK_DIR="$LOCK_DIR"
    find "$LOCK_ROOT" -maxdepth 1 -mindepth 1 -type d -mmin +60 -exec rm -rf {} + 2>/dev/null || true
fi

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
    if ! [[ "$TIMEOUT_SECS" =~ ^[0-9]+$ ]] || [ "$TIMEOUT_SECS" -le 0 ]; then
        TIMEOUT_SECS=3600
    fi
    run_with_timeout() {
        if command -v timeout >/dev/null 2>&1; then
            timeout "$TIMEOUT_SECS" "$@"
            return
        fi
        if command -v gtimeout >/dev/null 2>&1; then
            gtimeout "$TIMEOUT_SECS" "$@"
            return
        fi
        if command -v perl >/dev/null 2>&1; then
            perl -e '"'"'
                use strict;
                use warnings;
                my $timeout = shift @ARGV;
                my @cmd = @ARGV;
                local $SIG{ALRM} = sub { die "timeout\n" };
                alarm $timeout;
                exec @cmd or die "exec failed: $!\n";
            '"'"' "$TIMEOUT_SECS" "$@"
            return
        fi
        echo "WARNING: no timeout/gtimeout/perl available; Codex running without external timeout guard" >&2
        "$@"
    }
    run_with_timeout /bin/bash "$LAUNCH_SCRIPT" "$WORKSPACE" "$CODEX_HOME" "$RUNTIME" "$CODEX_SCRIPT" "$PROMPT_FILE" "$OUTPUT"
    rm -f "$PROMPT_FILE" "$LAUNCH_SCRIPT"
' _ "$LAUNCH_SCRIPT" "$PROMPT_FILE" "$WORKSPACE" "$AUTO_CODEX_HOME" "$RUNTIME_DIR" "$CODEX_SCRIPT" "$OUTPUT_PATH" "${AUTO_CODEX_TIMEOUT_SECONDS:-${CODEX_TIMEOUT:-3600}}" > "$CODEX_LOG" 2>&1 &
CODEX_PID=$!
echo "$CODEX_PID" > "$PID_PATH"

FEEDBACK_DIR="$STEPS_DIR/codex-feedback"
mkdir -p "$FEEDBACK_DIR"
FEEDBACK_RECORD="$FEEDBACK_DIR/$(basename "$ARTIFACT_DIR").json"
if ! jq -cn \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg output_path "$OUTPUT_PATH" \
    --arg log_path "$CODEX_LOG" \
    --arg pid_path "$PID_PATH" \
    --arg pid "$CODEX_PID" \
    --arg artifact_dir "$ARTIFACT_DIR" \
    "{ts:\$ts,output_path:\$output_path,log_path:\$log_path,pid_path:\$pid_path,pid:\$pid,artifact_dir:\$artifact_dir}" \
    > "$FEEDBACK_RECORD" 2>/dev/null; then
    echo "WARNING: could not record Codex feedback handoff at $FEEDBACK_RECORD" >&2
fi
release_prompt_lock

cat << EOF
================================================================================
CODEX: Running in background (optional)
================================================================================
Output will be at: $OUTPUT_PATH
PID: $CODEX_PID

Required Codex feedback handoff:
Show the complete Codex output from $OUTPUT_PATH to the user before final response.
The stop hook will also surface completed Codex output automatically.
================================================================================
EOF
