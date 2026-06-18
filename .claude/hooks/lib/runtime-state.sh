#!/bin/bash

expand_shell_path() {
    local raw_path="$1"

    case "$raw_path" in
        "~")
            printf '%s\n' "$HOME"
            ;;
        "~/"*)
            printf '%s/%s\n' "$HOME" "${raw_path:2}"
            ;;
        *)
            printf '%s\n' "$raw_path"
            ;;
    esac
}

workflow_runtime_root() {
    local config_dir="${CLAUDE_CONFIG_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}/.claude}"
    expand_shell_path "${CLAUDE_WORKFLOW_RUNTIME_DIR:-$config_dir/runtime}"
}

gstack_state_dir() {
    local fallback
    fallback="$(workflow_runtime_root)/gstack"
    expand_shell_path "${CLAUDE_PLUGIN_DATA:-${GSTACK_STATE_DIR:-$fallback}}"
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

