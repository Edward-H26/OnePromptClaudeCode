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
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir" 2>/dev/null' RETURN

    plugin_enabled_names > "$tmp_dir/enabled"

    if plugin_has_install_state; then
        plugin_installed_names > "$tmp_dir/installed"
        comm -12 "$tmp_dir/enabled" "$tmp_dir/installed" > "$tmp_dir/candidates"
    else
        cp "$tmp_dir/enabled" "$tmp_dir/candidates"
    fi

    if [[ -f "$(plugin_blocklist_path)" ]]; then
        plugin_blocklisted_names > "$tmp_dir/blocklisted"
        comm -23 "$tmp_dir/candidates" "$tmp_dir/blocklisted"
    else
        cat "$tmp_dir/candidates"
    fi
}

plugin_unavailable_enabled_names() {
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir" 2>/dev/null' RETURN

    plugin_enabled_names > "$tmp_dir/enabled"
    plugin_available_names > "$tmp_dir/available"
    comm -23 "$tmp_dir/enabled" "$tmp_dir/available"
}

plugin_is_available() {
    local plugin_name="$1"
    plugin_available_names | grep -Fxq "$plugin_name"
}
