#!/bin/bash

plugin_settings_path() {
    local project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
    echo "$project_dir/.claude/settings.json"
}

plugin_installed_path() {
    local project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
    echo "$project_dir/plugins/installed_plugins.json"
}

plugin_blocklist_path() {
    local project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
    echo "$project_dir/plugins/blocklist.json"
}

plugin_has_install_state() {
    [[ -f "$(plugin_installed_path)" ]]
}

plugin_enabled_names() {
    local settings_path
    settings_path="$(plugin_settings_path)"
    [[ -f "$settings_path" ]] || return 0

    jq -r '
        .enabledPlugins // {} |
        to_entries[] |
        select(.value == true) |
        .key
    ' "$settings_path" 2>/dev/null | sort -u
}

plugin_installed_names() {
    local installed_path
    installed_path="$(plugin_installed_path)"
    [[ -f "$installed_path" ]] || return 0

    jq -r '
        .plugins // {} |
        keys[]
    ' "$installed_path" 2>/dev/null | sort -u
}

plugin_blocklisted_names() {
    local blocklist_path
    blocklist_path="$(plugin_blocklist_path)"
    [[ -f "$blocklist_path" ]] || return 0

    jq -r '
        .plugins // [] |
        .[] |
        .plugin // empty
    ' "$blocklist_path" 2>/dev/null | sort -u
}

plugin_available_names() {
    local tmp_dir
    tmp_dir="$(mktemp -d)" || return 1
    local return_code=0

    if ! plugin_enabled_names > "$tmp_dir/enabled"; then
        return_code=$?
    fi

    if [[ $return_code -eq 0 ]]; then
        if plugin_has_install_state; then
            if ! plugin_installed_names > "$tmp_dir/installed"; then
                return_code=$?
            elif ! comm -12 "$tmp_dir/enabled" "$tmp_dir/installed" > "$tmp_dir/candidates"; then
                return_code=$?
            fi
        elif ! cp "$tmp_dir/enabled" "$tmp_dir/candidates"; then
            return_code=$?
        fi
    fi

    if [[ $return_code -eq 0 ]]; then
        if [[ -f "$(plugin_blocklist_path)" ]]; then
            if ! plugin_blocklisted_names > "$tmp_dir/blocklisted"; then
                return_code=$?
            else
                comm -23 "$tmp_dir/candidates" "$tmp_dir/blocklisted"
                return_code=$?
            fi
        else
            cat "$tmp_dir/candidates"
            return_code=$?
        fi
    fi

    rm -rf "$tmp_dir" 2>/dev/null || true
    return $return_code
}

plugin_unavailable_enabled_names() {
    local tmp_dir
    tmp_dir="$(mktemp -d)" || return 1
    local return_code=0

    if ! plugin_enabled_names > "$tmp_dir/enabled"; then
        return_code=$?
    elif ! plugin_available_names > "$tmp_dir/available"; then
        return_code=$?
    else
        comm -23 "$tmp_dir/enabled" "$tmp_dir/available"
        return_code=$?
    fi

    rm -rf "$tmp_dir" 2>/dev/null || true
    return $return_code
}

plugin_is_available() {
    local plugin_name="$1"
    plugin_available_names | grep -Fxq "$plugin_name"
}
