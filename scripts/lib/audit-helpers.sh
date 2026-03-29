#!/usr/bin/env bash
# Shell helper functions for audit-workflow.sh
# Sourced by the main orchestrator, not executed directly.

expect_match() {
    local text="$1"
    local pattern="$2"
    local label="$3"

    if ! printf "%s\n" "$text" | grep -qiE "$pattern"; then
        echo "Expected match failed: $label" >&2
        exit 1
    fi
}

expect_no_match() {
    local text="$1"
    local pattern="$2"
    local label="$3"

    if printf "%s\n" "$text" | grep -qiE "$pattern"; then
        echo "Unexpected match: $label" >&2
        exit 1
    fi
}

expect_true() {
    local command="$1"
    local label="$2"

    if ! eval "$command"; then
        echo "Expected true failed: $label" >&2
        exit 1
    fi
}

run_skill_activation() {
    local prompt="$1"
    jq -n --arg prompt "$prompt" --arg session_id "audit" '{prompt: $prompt, session_id: $session_id}' |
        CLAUDE_PROJECT_DIR="$ROOT" bash "$ROOT/.claude/hooks/skill-activation-prompt.sh"
}

run_skill_activation_no_env() {
    local prompt="$1"
    jq -n --arg prompt "$prompt" --arg session_id "audit" '{prompt: $prompt, session_id: $session_id}' |
        env -u CLAUDE_PROJECT_DIR bash "$ROOT/.claude/hooks/skill-activation-prompt.sh"
}

run_task_orchestrator() {
    local prompt="$1"
    jq -n --arg prompt "$prompt" --arg session_id "audit" '{prompt: $prompt, session_id: $session_id}' |
        CLAUDE_PROJECT_DIR="$ROOT" bash "$ROOT/.claude/hooks/task-orchestrator-hook.sh"
}

run_auto_codex_trigger_with_stub() {
    local prompt="$1"
    local stub_dir
    stub_dir="$(mktemp -d)"

    cat > "$stub_dir/codex" <<'EOF'
#!/bin/bash
exit 0
EOF

    cat > "$stub_dir/ask_codex.sh" <<'EOF'
#!/bin/bash
set -e

output_path=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            output_path="${2:-}"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

if [[ -n "$output_path" ]]; then
    printf "stub\n" > "$output_path"
fi
EOF

    chmod +x "$stub_dir/codex" "$stub_dir/ask_codex.sh"

    jq -n --arg prompt "$prompt" --arg session_id "audit" '{prompt: $prompt, session_id: $session_id}' |
        PATH="$stub_dir:$PATH" \
        CLAUDE_PROJECT_DIR="$ROOT" \
        AUTO_CODEX_SCRIPT="$stub_dir/ask_codex.sh" \
        bash "$ROOT/.claude/hooks/auto-codex-trigger.sh"
}

run_check_careful() {
    local input="$1"
    local state_dir="$2"

    printf "%s" "$input" |
        CLAUDE_PROJECT_DIR="$ROOT" \
        CLAUDE_PLUGIN_DATA="$state_dir" \
        bash "$ROOT/.claude/skills/gstack/careful/bin/check-careful.sh"
}

run_check_freeze() {
    local input="$1"
    local state_dir="$2"

    printf "%s" "$input" |
        CLAUDE_PROJECT_DIR="$ROOT" \
        CLAUDE_PLUGIN_DATA="$state_dir" \
        bash "$ROOT/.claude/skills/gstack/freeze/bin/check-freeze.sh"
}

run_tsc_hook_regression() {
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    mkdir -p "$tmp_dir/.claude/hooks/lib" "$tmp_dir/.claude/tsc-cache/test" "$tmp_dir/app" "$tmp_dir/pkg"
    cp "$ROOT/.claude/hooks/tsc-check.sh" "$tmp_dir/.claude/hooks/"
    cp "$ROOT/.claude/hooks/lib/utils.sh" "$tmp_dir/.claude/hooks/lib/"

    cat > "$tmp_dir/jq" <<'EOF'
#!/bin/sh
exec /usr/bin/jq "$@"
EOF

    cat > "$tmp_dir/npx" <<'EOF'
#!/bin/sh
printf 'src/example.ts:1:1 - error TS1000: simulated failure\n' >&2
exit 1
EOF

    chmod +x "$tmp_dir/jq" "$tmp_dir/npx"

    for repo in "$tmp_dir" "$tmp_dir/app" "$tmp_dir/pkg"; do
        cat > "$repo/package.json" <<'EOF'
{}
EOF
        cat > "$repo/tsconfig.json" <<'EOF'
{}
EOF
    done

    local hook_input
    hook_input="$(jq -n \
        --arg app "$tmp_dir/app/example.ts" \
        --arg pkg "$tmp_dir/pkg/example.ts" \
        '{tool_name:"MultiEdit", session_id:"test", tool_input:{edits:[{file_path:$app},{file_path:$pkg}]}}'
    )"

    set +e
    PATH="$tmp_dir:$PATH" \
        CLAUDE_PROJECT_DIR="$tmp_dir" \
        bash "$tmp_dir/.claude/hooks/tsc-check.sh" <<< "$hook_input" >/dev/null 2>"$tmp_dir/stderr.log"
    local hook_status=$?
    set -e

    if [[ "$hook_status" -eq 0 ]]; then
        echo "tsc-check regression hook should fail when stubbed tsc reports errors" >&2
        rm -rf "$tmp_dir"
        exit 1
    fi

    local affected_path="$tmp_dir/.claude/tsc-cache/test/affected-repos.txt"
    if [[ ! -f "$affected_path" ]]; then
        echo "tsc-check regression hook did not write affected-repos.txt" >&2
        rm -rf "$tmp_dir"
        exit 1
    fi

    local affected_contents
    affected_contents="$(cat "$affected_path")"
    local expected
    expected="$(printf "app\npkg")"
    if [[ "$affected_contents" != "$expected" ]]; then
        echo "tsc-check should persist one repo per line in affected-repos.txt" >&2
        printf 'Expected:\n%s\nActual:\n%s\n' "$expected" "$affected_contents" >&2
        rm -rf "$tmp_dir"
        exit 1
    fi

    rm -rf "$tmp_dir"
}

run_ask_codex_with_stub() {
    local stub_dir
    stub_dir="$(mktemp -d)"
    mkdir -p "$stub_dir/source-home"

    cat > "$stub_dir/codex" <<'EOF'
#!/bin/bash
set -e
printf '%s\n' "$*" > "${STUB_ARGS_FILE:?}"
if [[ "${1:-}" == "exec" && "${2:-}" == "resume" ]]; then
    printf "resume response\n"
    exit 0
fi
cat <<'JSON'
{"type":"thread.started","thread_id":"stub-thread"}
{"type":"item.completed","item":{"type":"agent_message","text":"stub response"}}
JSON
EOF
    chmod +x "$stub_dir/codex"

    local output
    output="$(
        PATH="$stub_dir:$PATH" \
        STUB_ARGS_FILE="$stub_dir/args.txt" \
        CLAUDE_PROJECT_DIR="$ROOT" \
        AUTO_CODEX_HOME="$stub_dir/codex-home" \
        AUTO_CODEX_RUNTIME_DIR="$stub_dir/runs" \
        AUTO_CODEX_SOURCE_HOME="$stub_dir/source-home" \
        bash "$ROOT/.claude/skills/codex/scripts/ask_codex.sh" "$@"
    )"

    printf '%s\nARGS_FILE=%s/args.txt\n' "$output" "$stub_dir"
}
