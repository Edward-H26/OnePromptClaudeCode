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
        CLAUDE_PROJECT_DIR="$ROOT" bash "$ROOT/.claude/hooks/task-orchestrator-hook.sh"
}

run_skill_activation_no_env() {
    local prompt="$1"
    jq -n --arg prompt "$prompt" --arg session_id "audit" '{prompt: $prompt, session_id: $session_id}' |
        env -u CLAUDE_PROJECT_DIR bash "$ROOT/.claude/hooks/task-orchestrator-hook.sh"
}

run_task_orchestrator() {
    local prompt="$1"
    jq -n --arg prompt "$prompt" --arg session_id "audit" '{prompt: $prompt, session_id: $session_id}' |
        CLAUDE_PROJECT_DIR="$ROOT" bash "$ROOT/.claude/hooks/task-orchestrator-hook.sh"
}

run_git_guard() {
    local command="$1"
    jq -n \
        --arg command "$command" \
        '{tool_name:"Bash", tool_input:{command:$command}}' |
        CLAUDE_PROJECT_DIR="$ROOT" bash "$ROOT/.claude/hooks/git-guard.sh"
}

run_session_start_smoke() {
    local source="${1:-}"
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    mkdir -p "$tmp_dir/.claude/hooks/lib" "$tmp_dir/.claude/runtime" "$tmp_dir/.claude/skills"
    cp "$ROOT/.claude/hooks/session-start.sh" "$tmp_dir/.claude/hooks/"
    cp "$ROOT/.claude/hooks/lib/utils.sh" "$tmp_dir/.claude/hooks/lib/"
    cp "$ROOT/.claude/hooks/lib/hook-metrics.sh" "$tmp_dir/.claude/hooks/lib/"
    cp "$ROOT/.claude/settings.local.example.json" "$tmp_dir/.claude/"

    cat > "$tmp_dir/.claude/MEMORY.md" <<'EOF'
# Repo Memory
Use repo-local workflow files.
EOF

    cat > "$tmp_dir/.claude/runtime/last-precompact.md" <<'EOF'
# Pre-compact snapshot
- edited: README.md
EOF

    local hook_input
    hook_input="$(jq -n --arg session_id "audit" --arg source "$source" '{session_id:$session_id, source:$source}')"
    local output
    output="$(
        CLAUDE_PROJECT_DIR="$tmp_dir" \
        bash "$tmp_dir/.claude/hooks/session-start.sh" <<< "$hook_input"
    )"
    local status=$?
    if [[ "$status" -ne 0 ]]; then
        rm -rf "$tmp_dir"
        return "$status"
    fi

    if [[ ! -f "$tmp_dir/.claude/settings.local.json" ]]; then
        echo "session-start should bootstrap settings.local.json in a fresh clone" >&2
        rm -rf "$tmp_dir"
        exit 1
    fi

    printf '%s\n' "$output"
    rm -rf "$tmp_dir"
}

run_tsc_hook_regression() {
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    mkdir -p "$tmp_dir/.claude/hooks/lib" "$tmp_dir/.claude/skills" "$tmp_dir/.claude/tsc-cache/test" "$tmp_dir/app" "$tmp_dir/pkg"
    cp "$ROOT/.claude/hooks/post-edit-check.sh" "$tmp_dir/.claude/hooks/"
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
        bash "$tmp_dir/.claude/hooks/post-edit-check.sh" <<< "$hook_input" >/dev/null 2>"$tmp_dir/stderr.log"
    local hook_status=$?
    set -e

    if [[ "$hook_status" -eq 0 ]]; then
        echo "post-edit-check regression hook should fail when stubbed tsc reports errors" >&2
        rm -rf "$tmp_dir"
        exit 1
    fi

    local affected_path="$tmp_dir/.claude/tsc-cache/test/affected-repos.txt"
    if [[ ! -f "$affected_path" ]]; then
        echo "post-edit-check regression hook did not write affected-repos.txt" >&2
        rm -rf "$tmp_dir"
        exit 1
    fi

    local affected_contents
    affected_contents="$(cat "$affected_path")"
    local expected
    expected="$(printf "app\npkg")"
    if [[ "$affected_contents" != "$expected" ]]; then
        echo "post-edit-check should persist one repo per line in affected-repos.txt" >&2
        printf 'Expected:\n%s\nActual:\n%s\n' "$expected" "$affected_contents" >&2
        rm -rf "$tmp_dir"
        exit 1
    fi

    rm -rf "$tmp_dir"
}

