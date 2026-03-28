#!/bin/bash

workflow_runtime_root() {
    local project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
    echo "${CLAUDE_WORKFLOW_RUNTIME_DIR:-$project_dir/.claude/runtime}"
}

gstack_state_dir() {
    local fallback
    fallback="$(workflow_runtime_root)/gstack"
    echo "${CLAUDE_PLUGIN_DATA:-${GSTACK_STATE_DIR:-$fallback}}"
}

gstack_analytics_dir() {
    echo "$(gstack_state_dir)/analytics"
}

gstack_careful_flag_path() {
    echo "$(gstack_state_dir)/careful-mode.txt"
}

gstack_freeze_path() {
    echo "$(gstack_state_dir)/freeze-dir.txt"
}

codex_runtime_root() {
    local fallback
    fallback="$(workflow_runtime_root)/codex"
    echo "${AUTO_CODEX_RUNTIME_ROOT:-$fallback}"
}

codex_home_dir() {
    echo "${AUTO_CODEX_HOME:-$(codex_runtime_root)/home}"
}

codex_runs_dir() {
    echo "${AUTO_CODEX_RUNTIME_DIR:-$(codex_runtime_root)/runs}"
}
