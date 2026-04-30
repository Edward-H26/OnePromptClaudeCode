#!/bin/bash
# Hook coverage metrics library
# Each hook that sources this file can call:
#     record_hook_invocation "<hook-name>" [status]
# to append a JSONL line to .claude/runtime/hook-metrics.jsonl so doctor-workflow
# and audit-workflow can report whether sensors are firing, per Fowler's
# harness-engineering guidance on sensor observability.

record_hook_invocation() {
    local hook_name="$1"
    local status="${2:-ok}"
    local home_dir="${CLAUDE_HOME_DIR:-}"
    if [[ -z "$home_dir" ]]; then
        if command -v resolve_claude_home >/dev/null 2>&1; then
            home_dir="$(resolve_claude_home 2>/dev/null || echo "")"
        fi
    fi
    [[ -z "$home_dir" ]] && return 0
    local log_dir="$home_dir/runtime"
    local log_file="$log_dir/hook-metrics.jsonl"
    mkdir -p "$log_dir" 2>/dev/null || return 0
    local ts
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '{"ts":"%s","hook":"%s","status":"%s"}\n' "$ts" "$hook_name" "$status" >> "$log_file" 2>/dev/null || true
}
