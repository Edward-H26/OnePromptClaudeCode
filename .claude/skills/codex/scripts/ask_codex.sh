#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ask_codex.sh <task> [options]
  ask_codex.sh -t <task> [options]

Task input:
  <task>                       First positional argument is the task text
  -t, --task <text>            Alias for positional task (backward compat)
  (stdin)                      Pipe task text via stdin if no arg/flag given

File context (optional, repeatable):
  -f, --file <path>            Priority file path

Multi-turn:
      --session <id>           Resume a previous session (thread_id from prior run)

Options:
  -w, --workspace <path>       Workspace directory (default: current directory)
      --model <name>           Model override
      --reasoning <level>      Reasoning effort: low, medium, high (default: medium)
      --sandbox <mode>         Sandbox mode override
      --read-only              Read-only sandbox (no file changes)
      --full-auto              Full-auto mode (default)
  -o, --output <path>          Output file path
  -h, --help                   Show this help

Output (on success):
  session_id=<thread_id>       Use with --session for follow-up calls
  output_path=<file>           Path to response markdown

Examples:
  # New task (positional)
  ask_codex.sh "Add error handling to api.ts" -f src/api.ts

  # With explicit workspace
  ask_codex.sh "Fix the bug" -w /other/repo

  # Continue conversation
  ask_codex.sh "Also add retry logic" --session <id>
USAGE
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERROR] Missing required command: $1" >&2
    exit 1
  fi
}

trim_whitespace() {
  awk 'BEGIN { RS=""; ORS="" } { gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, ""); print }' <<<"$1"
}

to_abs_if_exists() {
  local target="$1"
  if [[ -e "$target" ]]; then
    local dir
    dir="$(cd "$(dirname "$target")" && pwd)"
    echo "$dir/$(basename "$target")"
    return
  fi
  echo "$target"
}

resolve_file_ref() {
  local workspace="$1" raw="$2" cleaned
  cleaned="$(trim_whitespace "$raw")"
  [[ -z "$cleaned" ]] && { echo ""; return; }
  if [[ "$cleaned" =~ ^(.+)#L[0-9]+$ ]]; then cleaned="${BASH_REMATCH[1]}"; fi
  if [[ "$cleaned" =~ ^(.+):[0-9]+(-[0-9]+)?$ ]]; then cleaned="${BASH_REMATCH[1]}"; fi
  if [[ "$cleaned" != /* ]]; then cleaned="$workspace/$cleaned"; fi
  to_abs_if_exists "$cleaned"
}

toml_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

bootstrap_codex_home() {
  local target_home="$1"
  local source_home="$2"
  local rel_path=""

  [[ -z "$target_home" ]] && return 0
  mkdir -p "$target_home"

  [[ -z "$source_home" ]] && return 0
  [[ "$target_home" == "$source_home" ]] && return 0

  for rel_path in config.toml auth.json oauth.json credentials.json; do
    if [[ -r "$source_home/$rel_path" ]] && [[ ! -e "$target_home/$rel_path" ]]; then
      cp "$source_home/$rel_path" "$target_home/$rel_path" 2>/dev/null || true
    fi
  done
}

write_failure_output() {
  local message="$1"
  {
    printf "Codex execution failed.\n\n"
    printf "%s\n" "$message"
  } > "$output_path"
}

append_file_refs() {
  local raw="$1" item
  IFS=',' read -r -a items <<< "$raw"
  for item in "${items[@]}"; do
    local trimmed
    trimmed="$(trim_whitespace "$item")"
    [[ -n "$trimmed" ]] && file_refs+=("$trimmed")
  done
}

# --- Parse arguments ---

workspace="${PWD}"
task_text=""
model=""
reasoning_effort=""
sandbox_mode=""
read_only=false
full_auto=true
output_path=""
session_id=""
file_refs=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -w|--workspace)   workspace="${2:-}"; shift 2 ;;
    -t|--task)        task_text="${2:-}"; shift 2 ;;
    -f|--file|--focus) append_file_refs "${2:-}"; shift 2 ;;
    --model)          model="${2:-}"; shift 2 ;;
    --reasoning)      reasoning_effort="${2:-}"; shift 2 ;;
    --sandbox)        sandbox_mode="${2:-}"; full_auto=false; shift 2 ;;
    --read-only)      read_only=true; full_auto=false; shift ;;
    --full-auto)      full_auto=true; shift ;;
    --session)        session_id="${2:-}"; shift 2 ;;
    -o|--output)      output_path="${2:-}"; shift 2 ;;
    -h|--help)        usage; exit 0 ;;
    -*)               echo "[ERROR] Unknown option: $1" >&2; usage >&2; exit 1 ;;
    *)                if [[ -z "$task_text" ]]; then task_text="$1"; shift; else echo "[ERROR] Unexpected argument: $1" >&2; usage >&2; exit 1; fi ;;
  esac
done

require_cmd codex
require_cmd jq

# --- Validate inputs ---

if [[ ! -d "$workspace" ]]; then
  echo "[ERROR] Workspace does not exist: $workspace" >&2; exit 1
fi
workspace="$(cd "$workspace" && pwd)"

if [[ -z "$task_text" && ! -t 0 ]]; then
  task_text="$(cat)"
fi
task_text="$(trim_whitespace "$task_text")"

if [[ -z "$task_text" ]]; then
  echo "[ERROR] Request text is empty. Pass a positional arg, --task, or stdin." >&2; exit 1
fi

# --- Resolve repo-local Codex runtime paths ---

project_dir="${CLAUDE_PROJECT_DIR:-$workspace}"
codex_runtime_root="${AUTO_CODEX_RUNTIME_ROOT:-$project_dir/.claude/runtime/codex}"
codex_runs_dir="${AUTO_CODEX_RUNTIME_DIR:-$codex_runtime_root/runs}"
codex_log_dir="$codex_runtime_root/log"

if [[ -z "${CODEX_HOME:-}" ]]; then
  CODEX_HOME="${AUTO_CODEX_HOME:-$codex_runtime_root/home}"
fi
export CODEX_HOME

mkdir -p "$CODEX_HOME" "$codex_runs_dir" "$codex_log_dir"
bootstrap_codex_home "$CODEX_HOME" "${AUTO_CODEX_SOURCE_HOME:-${HOME:-}/.codex}"

# --- Prepare output path ---

if [[ -z "$output_path" ]]; then
  timestamp="$(date -u +"%Y%m%d-%H%M%S")"
  output_path="$codex_runs_dir/${timestamp}.md"
fi
mkdir -p "$(dirname "$output_path")"

# --- Build file context block ---

file_block=""
if (( ${#file_refs[@]} > 0 )); then
  file_block=$'\nPriority files (read these first before making changes):'
  resolved_count=0
  for ref in "${file_refs[@]}"; do
    resolved="$(resolve_file_ref "$workspace" "$ref")"
    [[ -z "$resolved" ]] && continue
    exists_tag="missing"
    [[ -e "$resolved" ]] && exists_tag="exists"
    file_block+=$'\n- '"${resolved} (${exists_tag})"
    resolved_count=$((resolved_count + 1))
  done
  if [[ $resolved_count -eq 0 ]]; then
    echo "[WARNING] None of the ${#file_refs[@]} file reference(s) could be resolved" >&2
  fi
fi

# --- Build prompt ---

prompt="$task_text"
if [[ -n "$file_block" ]]; then
  prompt+=$'\n'"$file_block"
fi

# --- Determine reasoning effort ---

if [[ -z "$reasoning_effort" ]]; then
  reasoning_effort="medium"
fi

reasoning_effort_toml="$(toml_escape "$reasoning_effort")"
codex_log_dir_toml="$(toml_escape "$codex_log_dir")"

# --- Build codex command ---

if [[ -n "$session_id" ]]; then
  # Resume mode: continue a previous session
  cmd=(
    codex exec resume
    -c "model_reasoning_effort=\"$reasoning_effort_toml\""
    -c "skip_git_repo_check=true"
    -c 'history.persistence="none"'
    -c "log_dir=\"$codex_log_dir_toml\""
  )
  if [[ "$read_only" == true ]] || [[ -n "$sandbox_mode" ]] || [[ "$full_auto" == true ]] || [[ -n "$model" ]]; then
    echo "[WARNING] Resume mode ignores sandbox, model, and full-auto overrides." >&2
  fi
  cmd+=("$session_id")
else
  # New session
  cmd=(
    codex exec
    --cd "$workspace"
    --skip-git-repo-check
    --json
    -c "model_reasoning_effort=\"$reasoning_effort_toml\""
    -c 'history.persistence="none"'
    -c "log_dir=\"$codex_log_dir_toml\""
  )
  if [[ "$read_only" == true ]]; then
    cmd+=(--sandbox read-only)
  elif [[ -n "$sandbox_mode" ]]; then
    cmd+=(--sandbox "$sandbox_mode")
  elif [[ "$full_auto" == true ]]; then
    cmd+=(--full-auto)
  fi
  [[ -n "$model" ]] && cmd+=(-m "$model")
  cmd+=("$prompt")
fi

# --- Progress watcher function ---

print_progress() {
  local line="$1"
  local item_type cmd_str preview
  # Fast string checks before calling jq
  case "$line" in
    *'"item.started"'*'"command_execution"'*)
      cmd_str=$(printf '%s' "$line" | jq -r '.item.command // empty' 2>/dev/null | sed 's|^/bin/zsh -lc ||; s|^/bin/bash -c ||' | cut -c1-100)
      [[ -n "$cmd_str" ]] && echo "[codex] > $cmd_str" >&2
      ;;
    *'"item.completed"'*'"agent_message"'*)
      preview=$(printf '%s' "$line" | jq -r '.item.text // empty' 2>/dev/null | head -1 | cut -c1-120)
      [[ -n "$preview" ]] && echo "[codex] $preview" >&2
      ;;
  esac
}

# --- Execute and capture output ---

stderr_file="$(mktemp)"
json_file="$(mktemp)"
text_file="$(mktemp)"
prompt_file="$(mktemp)"
trap 'rm -f "$stderr_file" "$json_file" "$text_file" "$prompt_file"' EXIT

printf "%s" "$prompt" > "$prompt_file"

run_codex() {
  local os
  os="$(uname -s)"

  if [[ "$os" == "Darwin" ]]; then
    if script -q /dev/null true >/dev/null 2>&1; then
      script -q /dev/null /bin/bash -c \
        "cd $(printf '%q' "$workspace") && $(printf '%q ' "${cmd[@]}") < $(printf '%q' "$prompt_file") 2>$(printf '%q' "$stderr_file")"
      return
    fi
  else
    if script -q -c "true" /dev/null >/dev/null 2>&1; then
      script -q -c \
        "cd $(printf '%q' "$workspace") && $(printf '%q ' "${cmd[@]}") < $(printf '%q' "$prompt_file") 2>$(printf '%q' "$stderr_file")" \
        /dev/null
      return
    fi
  fi

  (cd "$workspace" && "${cmd[@]}" < "$prompt_file" 2>"$stderr_file")
}

run_exit=0

set +e
if [[ -n "$session_id" ]]; then
  run_codex | while IFS= read -r line; do
      cleaned="${line//$'\r'/}"
      cleaned="${cleaned//$'\004'/}"
      cleaned="${cleaned//$'\010'/}"
      cleaned="${cleaned#^D}"
      [[ -z "$cleaned" ]] && continue
      printf '%s\n' "$cleaned" >> "$text_file"
      preview="${cleaned:0:120}"
      echo "[codex] $preview" >&2
    done
  run_exit=${PIPESTATUS[0]}
else
  run_codex | while IFS= read -r line; do
      cleaned="${line//$'\r'/}"
      cleaned="${cleaned//$'\004'/}"
      cleaned="${cleaned//$'\010'/}"
      cleaned="${cleaned#^D}"
      [[ -z "$cleaned" ]] && continue
      [[ "$cleaned" != *"{"* ]] && continue
      cleaned="{${cleaned#*\{}"
      printf '%s\n' "$cleaned" >> "$json_file"
      case "$cleaned" in
        *'"item.started"'*|*'"item.completed"'*) print_progress "$cleaned" ;;
      esac
    done
  run_exit=${PIPESTATUS[0]}
fi
set -e

stderr_preview=""
if [[ -s "$stderr_file" ]]; then
  stderr_preview="$(sed -n '1,40p' "$stderr_file")"
fi

if [[ $run_exit -ne 0 ]]; then
  if printf '%s' "$stderr_preview" | grep -qi 'Missing bearer or basic authentication'; then
    write_failure_output "Codex authentication is unavailable for the repo-local runtime at $CODEX_HOME.

If this machine already uses Codex elsewhere, copy or bootstrap the required auth files into that repo-local home, or run:

CODEX_HOME=\"$CODEX_HOME\" codex login"
  elif printf '%s' "$stderr_preview" | grep -qi 'cannot access session files'; then
    write_failure_output "Codex could not access its session files.

This repo expects a writable repo-local Codex home. Verify that $CODEX_HOME exists and is writable, then retry."
  else
    write_failure_output "${stderr_preview:-Codex exited without a readable error message.}"
  fi

  if [[ -n "$stderr_preview" ]]; then
    printf '%s\n' "$stderr_preview" >&2
  fi
  exit 1
fi

if [[ -s "$stderr_file" ]] && grep -q '\[ERROR\]' "$stderr_file" 2>/dev/null; then
  write_failure_output "${stderr_preview:-Codex reported an internal error.}"
  cat "$stderr_file" >&2
  exit 1
fi

if [[ -s "$stderr_file" ]]; then
  cat "$stderr_file" >&2
fi

# --- Process output based on mode ---

if [[ -n "$session_id" ]]; then
  thread_id="$session_id"
  if [[ -s "$text_file" ]]; then
    cat "$text_file" > "$output_path"
  else
    echo "(no response from codex)" > "$output_path"
  fi
else
  thread_id="$(jq -r 'select(.type == "thread.started") | .thread_id' < "$json_file" | head -1)"

  {
    jq -r '
      select(.type == "item.completed" and .item.type == "command_execution")
      | .item
      | ((.command // "") | gsub("^/bin/zsh -lc "; "") | gsub("^/bin/bash -c "; "")) as $cmd
      | select($cmd | test("^[\"'"'"']?(sed |cat |head |tail |nl |rg |grep |awk |wc |find |ls )") | not)
      | "### Shell: `" + ($cmd[0:200]) + "`\n" + (.aggregated_output // "" | .[0:500])
    ' < "$json_file" 2>/dev/null

    jq -r '
      select(.type == "item.completed" and .item.type == "tool_call")
      | .item
      | if .name == "write_file" then
          "### File written: " + (.arguments | fromjson | .path // "unknown")
        elif .name == "patch_file" then
          "### File patched: " + (.arguments | fromjson | .path // "unknown")
        elif .name == "shell" then
          "### Shell: `" + (.arguments | fromjson | .command // "unknown")[0:200] + "`\n" + (.output // "" | .[0:500])
        else empty
        end
    ' < "$json_file" 2>/dev/null

    jq -r '
      select(.type == "item.completed" and .item.type == "agent_message") | .item.text
    ' < "$json_file" 2>/dev/null
  } > "$output_path"

  if [[ ! -s "$output_path" ]]; then
    echo "(no response from codex)" > "$output_path"
  fi
fi

# --- Output results ---

if [[ -n "$thread_id" ]]; then
  echo "session_id=$thread_id"
else
  echo "[WARNING] No session_id returned from Codex (output may be malformed)" >&2
fi
echo "output_path=$output_path"
