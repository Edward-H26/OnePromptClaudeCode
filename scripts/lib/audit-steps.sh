#!/usr/bin/env bash
# Modular audit step functions for audit-workflow.sh.
# Sourced by the main orchestrator; expects $ROOT, hook libraries,
# and audit-helpers.sh to be loaded in the caller scope.

auditShellSyntax() {
    bash -n .claude/hooks/*.sh .claude/hooks/lib/*.sh references/*.sh scripts/*.sh
    for gstack_bin in .claude/skills/gstack/*/bin/*.sh; do
        [ -f "$gstack_bin" ] && bash -n "$gstack_bin"
    done
    while IFS= read -r skill_script; do
        bash -n "$skill_script"
    done < <(find .claude/skills -path "*/scripts/*.sh" -type f | sort)

    for direct_exec in \
        .claude/skills/chrome-devtools/scripts/install.sh \
        .claude/skills/chrome-devtools/scripts/install-deps.sh \
        .claude/skills/web-artifacts-builder/scripts/init.sh \
        .claude/skills/web-artifacts-builder/scripts/bundle.sh
    do
        if [[ ! -x "$direct_exec" ]]; then
            echo "Expected executable script: $direct_exec" >&2
            exit 1
        fi
    done

    for hook_script in .claude/hooks/*.sh; do
        if [[ -f "$hook_script" ]] && [[ ! -x "$hook_script" ]]; then
            echo "Hook script not executable: $hook_script" >&2
            exit 1
        fi
    done
}

auditSymlinkIntegrity() {
    local BROKEN_SYMLINKS=""
    while IFS= read -r symlink; do
        if [[ ! -e "$symlink" ]]; then
            BROKEN_SYMLINKS="${BROKEN_SYMLINKS}  ${symlink}\n"
        fi
    done < <(find .claude/skills -type l -not -path "*/node_modules/*" 2>/dev/null)
    if [[ -n "$BROKEN_SYMLINKS" ]]; then
        echo "Broken symlinks in .claude/skills/:" >&2
        printf '%b' "$BROKEN_SYMLINKS" >&2
        exit 1
    fi
}

auditHookSmokes() {
    expect_match "audit the workflow for bugs" "$ANALYSIS_PATTERN" "analysis prompt"
    expect_match "fix the failing route handler" "$CODING_PATTERN" "coding prompt"
    expect_match "solve the plugin drift and harden the workflow" "$CODING_PATTERN" "workflow coding prompt"
    expect_match "what is the current plan" "$PURE_QUESTION_PATTERN" "pure question"
    expect_match "update src/app.ts to handle auth" "$CODING_CONTEXT_PATTERN" "coding context"
    expect_match "fix hooks in settings.json and update the file" "$EXPLICIT_IMPLEMENTATION_PATTERN" "explicit implementation prompt"
    expect_match "go through the workflow and improve the process" "$WORKFLOW_IMPLEMENTATION_PATTERN" "workflow implementation override"
    expect_no_match "remember this preference for next time" "$CODING_PATTERN" "memory prompt"
    expect_true 'printf "%s\n" "go through the workflow and find all issues, then improve the process" | grep -qiE "$ANALYSIS_PATTERN" && printf "%s\n" "go through the workflow and find all issues, then improve the process" | grep -qiE "$WORKFLOW_IMPLEMENTATION_PATTERN"' "workflow audit prompt triggers implementation override"
    expect_true 'printf "%s\n" "audit the workflow and fix hooks in settings.json" | grep -qiE "$ANALYSIS_PATTERN" && printf "%s\n" "audit the workflow and fix hooks in settings.json" | grep -qiE "$EXPLICIT_IMPLEMENTATION_PATTERN"' "analysis prompt with concrete edit intent"

    local SKILL_OUTPUT

    SKILL_OUTPUT="$(run_skill_activation "What is the relationship between the modules?")"
    if printf "%s\n" "$SKILL_OUTPUT" | grep -q "ship"; then
        echo "Unexpected ship activation for relationship prompt" >&2
        exit 1
    fi

    SKILL_OUTPUT="$(run_skill_activation "Please retrofit this config explanation.")"
    if printf "%s\n" "$SKILL_OUTPUT" | grep -q "retro"; then
        echo "Unexpected retro activation for retrofit prompt" >&2
        exit 1
    fi

    SKILL_OUTPUT="$(run_skill_activation "Can you check the theme of this report?")"
    if printf "%s\n" "$SKILL_OUTPUT" | grep -q "ui-styling"; then
        echo "Unexpected ui-styling activation for theme-in-prose prompt" >&2
        exit 1
    fi

    SKILL_OUTPUT="$(run_skill_activation "Audit the Claude workflow hooks, settings.json, gitignore, plugins, and secrets exposure.")"
    for expected_skill in search-first skill-developer security-review security-scan; do
        if ! printf "%s\n" "$SKILL_OUTPUT" | grep -q "$expected_skill"; then
            echo "Missing expected skill activation: $expected_skill" >&2
            exit 1
        fi
    done

    SKILL_OUTPUT="$(run_skill_activation "Implement a secure route testing workflow in .claude hooks and update gitignore for runtime state.")"
    for expected_skill in skill-developer security-review security-scan; do
        if ! printf "%s\n" "$SKILL_OUTPUT" | grep -q "$expected_skill"; then
            echo "Missing expected implementation-scope skill activation: $expected_skill" >&2
            exit 1
        fi
    done
    if printf "%s\n" "$SKILL_OUTPUT" | grep -q "backend-dev-guidelines"; then
        echo "Unexpected backend skill activation for workflow-hardening prompt" >&2
        exit 1
    fi

    SKILL_OUTPUT="$(run_skill_activation_no_env "Audit the Claude workflow hooks and settings.json.")"
    if ! printf "%s\n" "$SKILL_OUTPUT" | grep -q "skill-developer"; then
        echo "skill-activation-prompt.sh should work without CLAUDE_PROJECT_DIR" >&2
        exit 1
    fi

    SKILL_OUTPUT="$(run_skill_activation "Implement a secure full-stack feature with React frontend, API routes, database migration, Docker deployment, and browser verification.")"
    for expected_skill in frontend-dev-guidelines backend-dev-guidelines security-review verification-loop; do
        if ! printf "%s\n" "$SKILL_OUTPUT" | grep -q "$expected_skill"; then
            echo "Missing expected feature skill activation: $expected_skill" >&2
            exit 1
        fi
    done

    SKILL_OUTPUT="$(run_skill_activation "Debug the failing TypeScript route handler and find the root cause of the regression.")"
    if ! printf "%s\n" "$SKILL_OUTPUT" | grep -q "systematic-debugging"; then
        echo "Missing expected debug skill activation: systematic-debugging" >&2
        exit 1
    fi

    SKILL_OUTPUT="$(run_skill_activation "Implement this Figma-inspired landing page in React with polished UI styling and browser QA.")"
    for expected_skill in frontend-dev-guidelines ui-styling qa; do
        if ! printf "%s\n" "$SKILL_OUTPUT" | grep -q "$expected_skill"; then
            echo "Missing expected design skill activation: $expected_skill" >&2
            exit 1
        fi
    done

    SKILL_OUTPUT="$(run_skill_activation "Prepare a release-ready handoff, run verification, update the changelog, and get this ready to ship.")"
    for expected_skill in ship verification-loop; do
        if ! printf "%s\n" "$SKILL_OUTPUT" | grep -q "$expected_skill"; then
            echo "Missing expected release skill activation: $expected_skill" >&2
            exit 1
        fi
    done

    SKILL_OUTPUT="$(run_skill_activation "Test the local webapp with Playwright Python, verify the browser flow, and capture screenshots.")"
    for expected_skill in webapp-testing e2e-testing; do
        if ! printf "%s\n" "$SKILL_OUTPUT" | grep -q "$expected_skill"; then
            echo "Missing expected local webapp test skill activation: $expected_skill" >&2
            exit 1
        fi
    done

    local TMP_GSTACK_STATE
    TMP_GSTACK_STATE="$(mktemp -d)"

    local CAREFUL_OUTPUT
    CAREFUL_OUTPUT="$(run_check_careful '{"tool_input":{"command":"rm -rf tmp"}}' "$TMP_GSTACK_STATE")"
    if [[ "$CAREFUL_OUTPUT" != "{}" ]]; then
        echo "careful hook should be inert until activated" >&2
        exit 1
    fi

    printf "active\n" > "$TMP_GSTACK_STATE/careful-mode.txt"
    CAREFUL_OUTPUT="$(run_check_careful '{"tool_input":{"command":"rm -rf tmp"}}' "$TMP_GSTACK_STATE")"
    if ! printf "%s\n" "$CAREFUL_OUTPUT" | grep -q '"permissionDecision":"ask"'; then
        echo "careful hook should warn when activated" >&2
        exit 1
    fi

    CAREFUL_OUTPUT="$(run_check_careful '{"tool_input":{"command":"rm -rf node_modules"}}' "$TMP_GSTACK_STATE")"
    if [[ "$CAREFUL_OUTPUT" != "{}" ]]; then
        echo "careful hook should allow safe cache cleanup targets" >&2
        exit 1
    fi

    local FREEZE_OUTPUT
    printf "%s/\n" "$ROOT/.claude" > "$TMP_GSTACK_STATE/freeze-dir.txt"
    FREEZE_OUTPUT="$(run_check_freeze "{\"tool_input\":{\"file_path\":\"$ROOT/.claude/settings.json\"}}" "$TMP_GSTACK_STATE")"
    if [[ "$FREEZE_OUTPUT" != "{}" ]]; then
        echo "freeze hook should allow edits inside the boundary" >&2
        exit 1
    fi

    FREEZE_OUTPUT="$(run_check_freeze "{\"tool_input\":{\"edits\":[{\"file_path\":\"$ROOT/.claude/settings.json\"},{\"file_path\":\"$ROOT/.claude/hooks/README.md\"}]}}" "$TMP_GSTACK_STATE")"
    if [[ "$FREEZE_OUTPUT" != "{}" ]]; then
        echo "freeze hook should allow MultiEdit paths inside the boundary" >&2
        exit 1
    fi

    FREEZE_OUTPUT="$(run_check_freeze "{\"tool_input\":{\"file_path\":\"$ROOT/README.md\"}}" "$TMP_GSTACK_STATE")"
    if ! printf "%s\n" "$FREEZE_OUTPUT" | grep -q '"permissionDecision":"deny"'; then
        echo "freeze hook should block edits outside the boundary" >&2
        exit 1
    fi

    FREEZE_OUTPUT="$(run_check_freeze "{\"tool_input\":{\"edits\":[{\"file_path\":\"$ROOT/.claude/settings.json\"},{\"file_path\":\"$ROOT/README.md\"}]}}" "$TMP_GSTACK_STATE")"
    if ! printf "%s\n" "$FREEZE_OUTPUT" | grep -q '"permissionDecision":"deny"'; then
        echo "freeze hook should block MultiEdit paths outside the boundary" >&2
        exit 1
    fi

    local TMP_SPACE_DIR
    TMP_SPACE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/freeze test.XXXXXX")"
    printf "%s/\n" "$TMP_SPACE_DIR" > "$TMP_GSTACK_STATE/freeze-dir.txt"
    FREEZE_OUTPUT="$(run_check_freeze "{\"tool_input\":{\"file_path\":\"$TMP_SPACE_DIR/example.ts\"}}" "$TMP_GSTACK_STATE")"
    if [[ "$FREEZE_OUTPUT" != "{}" ]]; then
        echo "freeze hook should preserve boundaries that contain spaces" >&2
        rm -rf "$TMP_SPACE_DIR"
        exit 1
    fi
    rm -rf "$TMP_SPACE_DIR"

    rm -rf "$TMP_GSTACK_STATE"

    run_tsc_hook_regression

    if ! bash "$ROOT/.claude/skills/web-artifacts-builder/scripts/init.sh" --help >/dev/null; then
        echo "web-artifacts init helper should support --help" >&2
        exit 1
    fi

    if ! bash "$ROOT/.claude/skills/web-artifacts-builder/scripts/bundle.sh" --help >/dev/null; then
        echo "web-artifacts bundle helper should support --help" >&2
        exit 1
    fi

    if ! python3 "$ROOT/.claude/skills/webapp-testing/scripts/browser_navigate.py" --help >/dev/null; then
        echo "browser_navigate.py should support --help" >&2
        exit 1
    fi

    if ! python3 "$ROOT/.claude/skills/webapp-testing/scripts/with_server.py" --help >/dev/null; then
        echo "with_server.py should support --help" >&2
        exit 1
    fi

    local TASK_OUTPUT
    TASK_OUTPUT="$(run_task_orchestrator "What is the current plan?")"
    if [[ -n "$TASK_OUTPUT" ]]; then
        echo "Pure informational question should not trigger coding guidance" >&2
        exit 1
    fi

    TASK_OUTPUT="$(run_task_orchestrator "Review the workflow and explain the problems without making changes.")"
    if ! printf "%s\n" "$TASK_OUTPUT" | grep -q "Analysis Mode"; then
        echo "Analysis prompt should trigger analysis mode guidance" >&2
        exit 1
    fi

    if command -v zsh >/dev/null 2>&1; then
        zsh -lc '
            source ".claude/hooks/lib/plugin-state.sh"
            plugin_enabled_names >/dev/null
            plugin_available_names >/dev/null

            source ".claude/hooks/lib/utils.sh"
            tmp_file="$(mktemp)"
            printf "b\na\n" > "$tmp_file"
            atomic_sort_unique "$tmp_file"
            expected=$(printf "a\nb")
            actual=$(cat "$tmp_file")
            rm -f "$tmp_file"
            [[ "$actual" == "$expected" ]]
        ' || {
            echo "zsh helper smoke test failed" >&2
            exit 1
        }
    fi

    local AUTO_OUTPUT_ONE AUTO_OUTPUT_TWO AUTO_PATH_ONE AUTO_PATH_TWO AUTO_DIR_ONE AUTO_DIR_TWO
    AUTO_OUTPUT_ONE="$(run_auto_codex_trigger_with_stub "Update the hook scripts and settings.json to harden the workflow.")"
    AUTO_OUTPUT_TWO="$(run_auto_codex_trigger_with_stub "Update the hook scripts and settings.json to harden the workflow.")"
    AUTO_PATH_ONE="$(printf "%s\n" "$AUTO_OUTPUT_ONE" | awk -F': ' '/Output will be at:/ {print $2}')"
    AUTO_PATH_TWO="$(printf "%s\n" "$AUTO_OUTPUT_TWO" | awk -F': ' '/Output will be at:/ {print $2}')"
    AUTO_DIR_ONE="$(dirname "$AUTO_PATH_ONE")"
    AUTO_DIR_TWO="$(dirname "$AUTO_PATH_TWO")"

    if [[ -z "$AUTO_PATH_ONE" ]] || [[ -z "$AUTO_PATH_TWO" ]] || [[ "$AUTO_DIR_ONE" == "$AUTO_DIR_TWO" ]]; then
        echo "auto-codex-trigger.sh should create unique artifact directories" >&2
        exit 1
    fi

    sleep 1
    for auto_dir in "$AUTO_DIR_ONE" "$AUTO_DIR_TWO"; do
        if [[ ! -f "$auto_dir/run.log" ]] || [[ ! -f "$auto_dir/run.pid" ]]; then
            echo "Missing expected auto-codex artifact files in $auto_dir" >&2
            exit 1
        fi
    done

    local ASK_OUTPUT ASK_PATH ASK_ARGS_FILE
    ASK_OUTPUT="$(run_ask_codex_with_stub "Summarize the repo layout" --read-only -o "$ROOT/.claude/runtime/codex/audit-smoke.md")"
    ASK_PATH="$(printf "%s\n" "$ASK_OUTPUT" | awk -F= '/^output_path=/ {print $2}')"
    ASK_ARGS_FILE="$(printf "%s\n" "$ASK_OUTPUT" | awk -F= '/^ARGS_FILE=/ {print $2}')"
    if [[ -z "$ASK_PATH" ]] || [[ ! -f "$ASK_PATH" ]] || ! grep -q "stub response" "$ASK_PATH"; then
        echo "ask_codex.sh should capture JSON mode output from Codex" >&2
        exit 1
    fi
    if ! printf "%s\n" "$ASK_OUTPUT" | grep -q '^session_id=stub-thread$'; then
        echo "ask_codex.sh should emit session_id for new sessions" >&2
        exit 1
    fi
    if [[ ! -f "$ASK_ARGS_FILE" ]] || ! grep -q -- '--json' "$ASK_ARGS_FILE"; then
        echo "ask_codex.sh should request JSON mode for new sessions" >&2
        exit 1
    fi

    ASK_OUTPUT="$(run_ask_codex_with_stub "Follow up" --session stub-session --read-only -o "$ROOT/.claude/runtime/codex/audit-resume.md")"
    ASK_PATH="$(printf "%s\n" "$ASK_OUTPUT" | awk -F= '/^output_path=/ {print $2}')"
    ASK_ARGS_FILE="$(printf "%s\n" "$ASK_OUTPUT" | awk -F= '/^ARGS_FILE=/ {print $2}')"
    if [[ -z "$ASK_PATH" ]] || [[ ! -f "$ASK_PATH" ]] || ! grep -q "resume response" "$ASK_PATH"; then
        echo "ask_codex.sh should capture resume-mode output from Codex" >&2
        exit 1
    fi
    if ! printf "%s\n" "$ASK_OUTPUT" | grep -q '^session_id=stub-session$'; then
        echo "ask_codex.sh should preserve the caller session_id for resume mode" >&2
        exit 1
    fi
    if [[ ! -f "$ASK_ARGS_FILE" ]] || ! grep -q '^exec resume ' "$ASK_ARGS_FILE"; then
        echo "ask_codex.sh should use codex exec resume for resumed sessions" >&2
        exit 1
    fi
    if grep -q -- '--json' "$ASK_ARGS_FILE" || grep -q -- '--sandbox' "$ASK_ARGS_FILE"; then
        echo "ask_codex.sh should not pass unsupported resume flags" >&2
        exit 1
    fi

    SKILL_OUTPUT="$(run_skill_activation "How do these modules relate to each other?")"
    if printf "%s\n" "$SKILL_OUTPUT" | grep -q "ship"; then
        echo "Unexpected ship activation for relation prompt" >&2
        exit 1
    fi

    SKILL_OUTPUT="$(run_skill_activation "Refresh the browser page to see the latest changes.")"
    if printf "%s\n" "$SKILL_OUTPUT" | grep -q "security-review"; then
        echo "Unexpected security-review activation for browser refresh prompt" >&2
        exit 1
    fi

    SKILL_OUTPUT="$(run_skill_activation "What did we discuss in the last session?")"
    if printf "%s\n" "$SKILL_OUTPUT" | grep -q "backend-dev-guidelines"; then
        echo "Unexpected backend skill activation for conversation prompt" >&2
        exit 1
    fi

    local CACHE_KEY
    CACHE_KEY="$(repo_cache_key "packages/app")"
    if [[ -z "$CACHE_KEY" ]] || [[ "$CACHE_KEY" == *"/"* ]]; then
        echo "Unsafe repo cache key: $CACHE_KEY" >&2
        exit 1
    fi
}

auditPluginAlignment() {
    local TMP_PLUGIN_STATE_DIR
    TMP_PLUGIN_STATE_DIR="$(mktemp -d)"
    plugin_enabled_names > "$TMP_PLUGIN_STATE_DIR/enabled"
    plugin_available_names > "$TMP_PLUGIN_STATE_DIR/available"
    plugin_blocklisted_names > "$TMP_PLUGIN_STATE_DIR/blocklisted"

    if plugin_has_install_state; then
        plugin_installed_names > "$TMP_PLUGIN_STATE_DIR/installed"
        local INSTALLED_BUT_DISABLED
        INSTALLED_BUT_DISABLED="$(comm -23 "$TMP_PLUGIN_STATE_DIR/installed" "$TMP_PLUGIN_STATE_DIR/enabled" || true)"
        if [[ -n "$INSTALLED_BUT_DISABLED" ]]; then
            echo "Note: installed but not enabled plugins:"
            while IFS= read -r name; do
                [[ -z "$name" ]] && continue
                echo "  $name"
            done <<< "$INSTALLED_BUT_DISABLED"
        fi

        local ENABLED_BUT_UNAVAILABLE
        ENABLED_BUT_UNAVAILABLE="$(comm -23 "$TMP_PLUGIN_STATE_DIR/enabled" "$TMP_PLUGIN_STATE_DIR/available" || true)"
        if [[ -n "$ENABLED_BUT_UNAVAILABLE" ]]; then
            echo "Note: enabled plugins not locally available:"
            while IFS= read -r name; do
                [[ -z "$name" ]] && continue
                local reason="not installed locally"
                if grep -Fxq "$name" "$TMP_PLUGIN_STATE_DIR/blocklisted"; then
                    reason="blocklisted in ignored local state"
                fi
                echo "  $name ($reason)"
            done <<< "$ENABLED_BUT_UNAVAILABLE"
        fi
    else
        echo "Note: local plugin install state is absent; enabled plugins are treated as declarative config only."
    fi

    rm -rf "$TMP_PLUGIN_STATE_DIR"
}
