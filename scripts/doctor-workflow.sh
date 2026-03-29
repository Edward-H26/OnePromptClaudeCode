#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0
warnings=0

pass() {
    printf "PASS: %s\n" "$1"
}

warn() {
    printf "WARN: %s\n" "$1"
    warnings=$((warnings + 1))
}

fail() {
    printf "FAIL: %s\n" "$1"
    failures=$((failures + 1))
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        fail "Missing required command: $1"
        return 1
    fi
}

print_file_head() {
    local path="$1"
    if [[ -f "$path" ]]; then
        sed -n "1,80p" "$path"
    fi
}

echo "[1/5] Static audit"
audit_log="$(mktemp)"
if bash "$ROOT/scripts/audit-workflow.sh" >"$audit_log" 2>&1; then
    pass "Static workflow audit passed"
else
    fail "Static workflow audit failed"
    print_file_head "$audit_log"
fi
rm -f "$audit_log"

echo "[2/5] Shared plugin health"
if require_cmd claude; then
    plugin_log="$(mktemp)"
    if claude plugin list >"$plugin_log" 2>&1; then
        set +e
        plugin_parser_output="$(
            python3 - "$ROOT/.claude/settings.json" "$ROOT/.claude/settings.local.json" "$plugin_log" <<'PY'
import json
import re
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
local_settings_path = Path(sys.argv[2])
plugin_log_path = Path(sys.argv[3])

shared_enabled = {
    name
    for name, value in json.loads(settings_path.read_text()).get("enabledPlugins", {}).items()
    if value is True
}

local_enabled = set()
if local_settings_path.exists():
    local_enabled = {
        name
        for name, value in json.loads(local_settings_path.read_text()).get("enabledPlugins", {}).items()
        if value is True
    }

enabled = shared_enabled | local_enabled
local_optional = {
    "context7@claude-plugins-official",
    "figma@claude-plugins-official",
    "github@claude-plugins-official",
    "playwright@claude-plugins-official",
}

text = plugin_log_path.read_text()
blocks = [block for block in re.split(r"\n\s*\n", text) if "❯" in block]
statuses = {}
for block in blocks:
    lines = [line.rstrip() for line in block.splitlines() if line.strip()]
    plugin = None
    status = ""
    for line in lines:
        if "❯" in line:
            plugin = line.split("❯", 1)[1].strip()
        if "Status:" in line:
            status = line.split("Status:", 1)[1].strip()
    if plugin:
        statuses[plugin] = status

failures = []
warnings = []

for plugin in sorted(enabled):
    status = statuses.get(plugin)
    if status is None:
        message = f"missing from `claude plugin list`: {plugin}"
        if plugin in shared_enabled:
            failures.append(message)
        else:
            warnings.append(message)
    elif "failed to load" in status.lower():
        message = f"failed to load: {plugin}"
        if plugin in shared_enabled:
            failures.append(message)
        elif plugin in local_optional:
            warnings.append(f"{message} (optional local plugin)")
        else:
            warnings.append(message)
    elif "enabled" in status.lower():
        if plugin in local_enabled and plugin not in shared_enabled:
            print(f"PASS: local enabled plugin available: {plugin}")
        else:
            print(f"PASS: enabled plugin available: {plugin}")
    else:
        warnings.append(f"enabled plugin reported non-ready status: {plugin} ({status})")

for plugin, status in sorted(statuses.items()):
    if plugin not in enabled and "failed to load" in status.lower():
        warnings.append(f"installed but broken plugin outside shared config: {plugin}")

for message in warnings:
    print(f"WARN: {message}")

if failures:
    for message in failures:
        print(f"FAIL: {message}")
    sys.exit(1)
PY
        )"
        plugin_parser_status=$?
        set -e
        if [[ -n "$plugin_parser_output" ]]; then
            printf "%s\n" "$plugin_parser_output"
            warnings=$((warnings + $(printf "%s\n" "$plugin_parser_output" | grep -c '^WARN:' || true)))
        fi

        if [[ "$plugin_parser_status" -eq 0 ]]; then
            pass "Shared plugin set is loadable"
        else
            fail "Shared plugin load check failed"
            print_file_head "$plugin_log"
        fi
    else
        fail "`claude plugin list` failed"
        print_file_head "$plugin_log"
    fi

    local_settings_warnings="$(
        python3 - "$ROOT/.claude/settings.local.json" "$ROOT/plugins/installed_plugins.json" <<'PY'
import json
import sys
from pathlib import Path

settings_local_path = Path(sys.argv[1])
installed_path = Path(sys.argv[2])
optional_plugins = {
    "context7@claude-plugins-official",
    "figma@claude-plugins-official",
    "github@claude-plugins-official",
    "playwright@claude-plugins-official",
}

enabled_local = set()
if settings_local_path.exists():
    settings_local = json.loads(settings_local_path.read_text())
    enabled_local = {
        name
        for name, value in (settings_local.get("enabledPlugins") or {}).items()
        if value is True
    }
    if "permissions" in settings_local:
        print("WARN: .claude/settings.local.json contains a permissions block. Keep machine-local overrides focused on plugin enablement unless you intentionally need extra local policy.")

if installed_path.exists():
    installed = set((json.loads(installed_path.read_text()).get("plugins") or {}).keys())
    missing_local = sorted(optional_plugins & installed - enabled_local)
    if missing_local:
        print(
            "NOTE: optional plugins are installed locally but remain disabled in .claude/settings.local.json: "
            + ", ".join(missing_local)
        )
PY
    )"
    if [[ -n "$local_settings_warnings" ]]; then
        printf "%s\n" "$local_settings_warnings"
        warnings=$((warnings + $(printf "%s\n" "$local_settings_warnings" | grep -c '^WARN:' || true)))
    fi

    plugin_state_warnings="$(
        python3 - "$ROOT/.claude/settings.json" "$ROOT/plugins/blocklist.json" <<'PY'
import json
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
blocklist_path = Path(sys.argv[2])

enabled = {
    name
    for name, value in json.loads(settings_path.read_text()).get("enabledPlugins", {}).items()
    if value is True
}

if not blocklist_path.exists():
    raise SystemExit(0)

blocklist = json.loads(blocklist_path.read_text())
for entry in blocklist.get("plugins", []):
    plugin = entry.get("plugin")
    reason = (entry.get("reason") or "").strip()
    text = (entry.get("text") or "").strip()
    if plugin not in enabled:
        continue
    lower = f"{reason} {text}".lower()
    if "test" in lower:
        print(
            "WARN: enabled shared plugin is still present in ignored local blocklist "
            f"with a test marker: {plugin} ({reason or 'no reason'})"
        )
PY
    )"
    if [[ -n "$plugin_state_warnings" ]]; then
        printf "%s\n" "$plugin_state_warnings"
        warnings=$((warnings + $(printf "%s\n" "$plugin_state_warnings" | grep -c '^WARN:' || true)))
    fi

    marketplace_log="$(mktemp)"
    if claude plugin marketplace list >"$marketplace_log" 2>&1; then
        if grep -qE 'Source: Directory \(/tmp/' "$marketplace_log"; then
            warn "A plugin marketplace points into /tmp. That source is machine-local and not reproducible. Remove it with: claude plugin marketplace remove <name>"
            print_file_head "$marketplace_log"
        else
            pass "Configured plugin marketplaces avoid /tmp sources"
        fi
    else
        warn "`claude plugin marketplace list` could not be checked"
    fi
    rm -f "$plugin_log" "$marketplace_log"
fi

echo "[3/5] MCP health"
if require_cmd claude; then
    mcp_log="$(mktemp)"
    if claude mcp list >"$mcp_log" 2>&1; then
        set +e
        mcp_parser_output="$(
            python3 - "$ROOT/.claude/settings.json" "$ROOT/.claude/settings.local.json" "$mcp_log" <<'PY'
import json
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
local_settings_path = Path(sys.argv[2])
mcp_log_path = Path(sys.argv[3])

enabled = {
    name
    for name, value in json.loads(settings_path.read_text()).get("enabledPlugins", {}).items()
    if value is True
}

if local_settings_path.exists():
    enabled |= {
        name
        for name, value in json.loads(local_settings_path.read_text()).get("enabledPlugins", {}).items()
        if value is True
    }

plugin_keys = {
    "plugin:context7:context7:": "context7@claude-plugins-official",
    "plugin:figma:figma:": "figma@claude-plugins-official",
    "plugin:github:github:": "github@claude-plugins-official",
    "plugin:playwright:playwright:": "playwright@claude-plugins-official",
}

def plugin_key_for_line(line: str):
    for prefix, plugin_name in plugin_keys.items():
        if prefix in line:
            return plugin_name
    return None

text = mcp_log_path.read_text().splitlines()
failures = []
warnings = []
passes = []

for line in text:
    line = line.strip()
    if " - ✓ Connected" in line:
        passes.append(line)
    elif " - ! Needs authentication" in line:
        plugin_name = plugin_key_for_line(line)
        if plugin_name is not None and plugin_name not in enabled:
            continue
        warnings.append(line)
    elif "plugin:" in line and " - ✗ Failed to connect" in line:
        plugin_name = plugin_key_for_line(line)
        if plugin_name is not None and plugin_name not in enabled:
            continue
        hint = ""
        if "plugin:github:github:" in line:
            hint = " (optional plugin MCP; usually missing GitHub auth or token wiring)"
        elif "plugin:playwright:playwright:" in line:
            hint = " (optional plugin MCP; repo-local Playwright tooling can still work without it)"
        elif "plugin:context7:context7:" in line:
            hint = " (optional plugin MCP; web lookup remains available even when this plugin is down)"
        warnings.append(f"{line}{hint}")
    elif line.startswith("claude.ai ") and " - ✗ Failed to connect" in line:
        failures.append(line)

for line in passes:
    print(f"PASS: {line}")
for line in warnings:
    print(f"WARN: {line}")

if failures:
    for line in failures:
        print(f"FAIL: {line}")
    sys.exit(1)
PY
        )"
        mcp_parser_status=$?
        set -e
        if [[ -n "$mcp_parser_output" ]]; then
            printf "%s\n" "$mcp_parser_output"
            warnings=$((warnings + $(printf "%s\n" "$mcp_parser_output" | grep -c '^WARN:' || true)))
        fi

        if [[ "$mcp_parser_status" -eq 0 ]]; then
            pass "Required shared MCP servers are reachable"
        else
            fail "Shared MCP connectivity check failed"
            print_file_head "$mcp_log"
        fi
    else
        fail "`claude mcp list` failed"
        print_file_head "$mcp_log"
    fi
    rm -f "$mcp_log"
fi

echo "[4/5] Codex read-only smoke"
if require_cmd codex; then
    codex_runtime_root="$ROOT/.claude/runtime/codex"
    codex_output="$codex_runtime_root/doctor-smoke.md"
    codex_stdout="$(mktemp)"
    codex_stderr="$(mktemp)"
    mkdir -p "$codex_runtime_root"

    if CLAUDE_PROJECT_DIR="$ROOT" \
        AUTO_CODEX_HOME="$codex_runtime_root/home" \
        AUTO_CODEX_RUNTIME_DIR="$codex_runtime_root/runs" \
        bash "$ROOT/.claude/skills/codex/scripts/ask_codex.sh" \
        --read-only \
        -w "$ROOT" \
        -o "$codex_output" \
        "Reply with only the text ok." \
        >"$codex_stdout" 2>"$codex_stderr"; then
        if grep -qi '^ok$' "$codex_output"; then
            pass "Codex read-only smoke test passed"
        else
            warn "Codex ran, but the output was not the expected smoke-test text"
            print_file_head "$codex_output"
        fi
    else
        fail "Codex read-only smoke test failed"
        print_file_head "$codex_stderr"
        print_file_head "$codex_output"
    fi

    rm -f "$codex_stdout" "$codex_stderr"
fi

echo "[5/5] Git surface check"
status_output="$(git status --short)"
if [[ -n "$status_output" ]]; then
    warn "Working tree has tracked or untracked changes"
    printf "%s\n" "$status_output"
else
    pass "Working tree is clean"
fi

echo
printf "Doctor summary: %s failure(s), %s warning(s)\n" "$failures" "$warnings"

if [[ "$failures" -gt 0 ]]; then
    exit 1
fi
