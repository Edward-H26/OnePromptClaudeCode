#!/usr/bin/env bash
# Modular doctor step functions for doctor-workflow.sh.
# Sourced by the main orchestrator; expects $ROOT, global counters
# (failures, warnings), and helper functions (pass, warn, fail,
# require_cmd, print_file_head) to be defined in the caller scope.

doctorRepoLocalSurface() {
    local missing=0
    for dir in hooks skills agents commands prompt-templates; do
        if [[ ! -d "$ROOT/.claude/$dir" ]]; then
            printf "  Missing repo-local directory: %s\n" "$ROOT/.claude/$dir"
            missing=1
        fi
    done

    for f in settings.json CLAUDE.md CLAUDE-testing.md CLAUDE-website-workflow.md CLAUDE-skills.md WORKFLOW-REFERENCE.md README.md; do
        if [[ ! -f "$ROOT/.claude/$f" ]]; then
            printf "  Missing repo-local file: %s\n" "$ROOT/.claude/$f"
            missing=1
        fi
    done

    if [[ "$missing" -ne 0 ]]; then
        fail "Repo-local workflow surface is incomplete"
        return 1
    fi

    pass "Repo-local workflow surface is present; no \$HOME/.claude sync required"
}

doctorStaticAudit() {
    local audit_log
    audit_log="$(mktemp)"
    if bash "$ROOT/scripts/audit-workflow.sh" >"$audit_log" 2>&1; then
        pass "Static workflow audit passed"
    else
        fail "Static workflow audit failed"
        print_file_head "$audit_log"
    fi
    rm -f "$audit_log"
}

doctorSymlinkHealth() {
    local BROKEN=""
    while IFS= read -r symlink; do
        if [[ ! -e "$symlink" ]]; then
            BROKEN="${BROKEN}  ${symlink}\n"
        fi
    done < <(find .claude/skills -type l -not -path "*/node_modules/*" 2>/dev/null)
    if [[ -n "$BROKEN" ]]; then
        fail "Broken skill symlinks detected"
        printf '%b' "$BROKEN"
    else
        pass "All skill symlinks resolve"
    fi
}

doctorHookPermissions() {
    local NON_EXEC=""
    for hook_script in .claude/hooks/*.sh; do
        if [[ -f "$hook_script" ]] && [[ ! -x "$hook_script" ]]; then
            NON_EXEC="${NON_EXEC}  ${hook_script}\n"
        fi
    done
    if [[ -n "$NON_EXEC" ]]; then
        fail "Non-executable hook scripts found"
        printf '%b' "$NON_EXEC"
    else
        pass "All hook scripts are executable"
    fi
}

doctorPluginHealth() {
    if ! require_cmd claude; then
        return
    fi

    local plugin_log
    plugin_log="$(mktemp)"
    if claude plugin list >"$plugin_log" 2>&1; then
        set +e
        local plugin_parser_output
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
    "superpowers@claude-plugins-official",
    "huggingface-skills@claude-plugins-official",
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
        local plugin_parser_status=$?
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
        fail "\`claude plugin list\` failed"
        print_file_head "$plugin_log"
    fi

    local local_settings_warnings
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
    "superpowers@claude-plugins-official",
    "huggingface-skills@claude-plugins-official",
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

    local plugin_state_warnings
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

    local marketplace_log
    marketplace_log="$(mktemp)"
    if claude plugin marketplace list >"$marketplace_log" 2>&1; then
        if grep -qE 'Source: Directory \(/tmp/' "$marketplace_log"; then
            warn "A plugin marketplace points into /tmp. That source is machine-local and not reproducible. Remove it with: claude plugin marketplace remove <name>"
            print_file_head "$marketplace_log"
        else
            pass "Configured plugin marketplaces avoid /tmp sources"
        fi
    else
        warn "\`claude plugin marketplace list\` could not be checked"
    fi
    rm -f "$plugin_log" "$marketplace_log"
}

doctorMcpHealth() {
    if ! require_cmd claude; then
        return
    fi

    local mcp_log
    mcp_log="$(mktemp)"
    if claude mcp list >"$mcp_log" 2>&1; then
        set +e
        local mcp_parser_output
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
enabled_mcp_servers = set(json.loads(settings_path.read_text()).get("enabledMcpjsonServers") or [])

if local_settings_path.exists():
    local_settings = json.loads(local_settings_path.read_text())
    enabled |= {
        name
        for name, value in local_settings.get("enabledPlugins", {}).items()
        if value is True
    }
    enabled_mcp_servers |= set(local_settings.get("enabledMcpjsonServers") or [])

plugin_keys = {
    "plugin:context7:context7:": "context7@claude-plugins-official",
    "plugin:figma:figma:": "figma@claude-plugins-official",
    "plugin:github:github:": "github@claude-plugins-official",
    "plugin:playwright:playwright:": "playwright@claude-plugins-official",
}

direct_mcp_plugins = {
    "context7": "context7@claude-plugins-official",
    "github": "github@claude-plugins-official",
    "playwright": "playwright@claude-plugins-official",
}

optional_claude_ai = {
    "claude.ai Google Calendar",
    "claude.ai Gmail",
    "claude.ai Scholar Gateway",
    "claude.ai Tavily",
}

optional_plugin_prefixes = {
    "plugin:chrome-devtools-mcp:chrome-devtools:",
    "plugin:greptile:greptile:",
}

optional_direct_mcp = {
    "remotion-docs",
    "remotion-app",
}

def plugin_key_for_line(line: str):
    for prefix, plugin_name in plugin_keys.items():
        if prefix in line:
            return plugin_name
    return None

def direct_server_for_line(line: str) -> str | None:
    if ":" not in line:
        return None
    name = line.split(":", 1)[0].strip()
    if name.startswith("claude.ai ") or name.startswith("plugin"):
        return None
    return name or None

def is_optional_claude_ai(line: str) -> bool:
    return any(line.startswith(prefix) for prefix in optional_claude_ai)

def is_enabled_direct_server(line: str) -> bool:
    name = direct_server_for_line(line)
    if not name:
        return False
    plugin_name = direct_mcp_plugins.get(name)
    if plugin_name and plugin_name in enabled:
        return True
    return name in enabled_mcp_servers

def direct_hint(line: str) -> str:
    name = direct_server_for_line(line)
    if name == "context7":
        return " (local docs MCP; web lookup remains available when this server is down)"
    if name == "playwright":
        return " (local browser MCP; chrome-devtools or browser tooling can still work)"
    if name in optional_direct_mcp:
        return " (project-scoped optional MCP; only needed for Remotion workflows)"
    return ""

text = mcp_log_path.read_text().splitlines()
failures = []
warnings = []
notes = []
passes = []

for line in text:
    line = line.strip()
    if " - ✓ Connected" in line:
        passes.append(line)
    elif " - ! Needs authentication" in line:
        plugin_name = plugin_key_for_line(line)
        if plugin_name is not None and plugin_name not in enabled:
            continue
        if plugin_name is None and any(prefix in line for prefix in optional_plugin_prefixes):
            notes.append(f"{line} (installed outside the repo-declared plugin set)")
            continue
        if direct_server_for_line(line) and not is_enabled_direct_server(line):
            notes.append(f"{line} (not enabled by this repo)")
            continue
        if is_optional_claude_ai(line):
            notes.append(f"{line} (optional, authenticate via claude.ai account settings)")
        else:
            warnings.append(f"{line}{direct_hint(line)}")
    elif "plugin:" in line and " - ✗ Failed to connect" in line:
        plugin_name = plugin_key_for_line(line)
        if plugin_name is not None and plugin_name not in enabled:
            continue
        if plugin_name is None and any(prefix in line for prefix in optional_plugin_prefixes):
            notes.append(f"{line} (installed outside the repo-declared plugin set)")
            continue
        hint = ""
        if "plugin:github:github:" in line:
            hint = " (optional plugin MCP; usually missing GitHub auth or token wiring)"
        elif "plugin:playwright:playwright:" in line:
            hint = " (optional plugin MCP; repo-local Playwright tooling can still work without it)"
        elif "plugin:context7:context7:" in line:
            hint = " (optional plugin MCP; web lookup remains available even when this plugin is down)"
        warnings.append(f"{line}{hint}")
    elif direct_server_for_line(line) and " - ✗ Failed to connect" in line:
        if is_enabled_direct_server(line):
            warnings.append(f"{line}{direct_hint(line)}")
        else:
            notes.append(f"{line} (not enabled by this repo)")
    elif line.startswith("claude.ai ") and " - ✗ Failed to connect" in line:
        if is_optional_claude_ai(line):
            notes.append(f"{line} (optional)")
        else:
            warnings.append(line)

for line in passes:
    print(f"PASS: {line}")
for line in notes:
    print(f"NOTE: {line}")
for line in warnings:
    print(f"WARN: {line}")

if failures:
    for line in failures:
        print(f"FAIL: {line}")
    sys.exit(1)
PY
        )"
        local mcp_parser_status=$?
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
        fail "\`claude mcp list\` failed"
        print_file_head "$mcp_log"
    fi
    rm -f "$mcp_log"
}


doctorGitSurface() {
    local status_output
    status_output="$(git status --short)"
    if [[ -n "$status_output" ]]; then
        warn "Working tree has tracked or untracked changes"
        printf "%s\n" "$status_output"
    else
        pass "Working tree is clean"
    fi
}

doctorBrowserTooling() {
    local chrome_scripts="$ROOT/.claude/skills/chrome-devtools/scripts"
    local has_chrome_modules=false
    local has_playwright_plugin=false

    if [[ -d "$chrome_scripts/node_modules" ]]; then
        has_chrome_modules=true
        pass "chrome-devtools Puppeteer scripts are installed ($chrome_scripts/node_modules)"
    elif [[ -d "$chrome_scripts" ]]; then
        warn "chrome-devtools scripts exist but node_modules missing; run: cd $chrome_scripts && npm install"
    fi

    if [[ -f "$ROOT/.claude/settings.json" ]]; then
        if python3 -c "
import json, sys
data = json.loads(open(sys.argv[1]).read())
plugins = data.get('enabledPlugins', {})
key = 'playwright@claude-plugins-official'
sys.exit(0 if plugins.get(key) is True else 1)
" "$ROOT/.claude/settings.json" 2>/dev/null; then
            has_playwright_plugin=true
            pass "Playwright plugin is enabled in shared settings"
        fi
    fi

    if [[ -f "$ROOT/.claude/settings.local.json" ]]; then
        if python3 -c "
import json, sys
from pathlib import Path
p = Path(sys.argv[1])
if not p.exists():
    sys.exit(1)
data = json.loads(p.read_text())
plugins = data.get('enabledPlugins', {}) or {}
key = 'playwright@claude-plugins-official'
sys.exit(0 if plugins.get(key) is True else 1)
" "$ROOT/.claude/settings.local.json" 2>/dev/null; then
            has_playwright_plugin=true
            pass "Playwright plugin is enabled in local settings override"
        fi
    fi

    if [[ "$has_chrome_modules" == false ]] && [[ "$has_playwright_plugin" == false ]]; then
        warn "Neither chrome-devtools scripts nor Playwright plugin is ready; install one before browser verification"
    fi
}

doctorSkillsParity() {
    local skills_dir="$ROOT/.claude/skills"
    local rules_file="$skills_dir/skill-rules.json"

    if [[ ! -f "$rules_file" ]]; then
        warn "skill-rules.json missing at $rules_file"
        return
    fi

    local parity_output
    parity_output="$(python3 - "$skills_dir" "$rules_file" <<'PY'
import json
import sys
from pathlib import Path

skills_dir = Path(sys.argv[1])
rules_path = Path(sys.argv[2])

fs_skills = {p.name for p in skills_dir.iterdir() if p.is_dir() or (p.is_symlink() and p.exists())}
fs_skills.discard("skill-rules.json")

try:
    rules = json.loads(rules_path.read_text())
except json.JSONDecodeError as exc:
    print(f"FAIL: skill-rules.json is not valid JSON: {exc}")
    sys.exit(1)

rules_skills = set()
if isinstance(rules, dict):
    if "skills" in rules and isinstance(rules["skills"], dict):
        rules_skills = set(rules["skills"].keys())
    else:
        rules_skills = {k for k in rules.keys() if not k.startswith("_")}

missing_on_fs = sorted(rules_skills - fs_skills)
missing_in_rules = sorted(fs_skills - rules_skills)

if missing_on_fs:
    print("FAIL: skill-rules.json references skills not present on filesystem:")
    for name in missing_on_fs:
        print(f"  - {name}")

if missing_in_rules:
    print("WARN: filesystem skills not referenced in skill-rules.json:")
    for name in missing_in_rules:
        print(f"  - {name}")

if not missing_on_fs and not missing_in_rules:
    print(f"PASS: {len(fs_skills)} skills match skill-rules.json")
PY
    )"

    if [[ -z "$parity_output" ]]; then
        warn "skills parity check produced no output"
        return
    fi

    printf "%s\n" "$parity_output"
    if printf "%s" "$parity_output" | grep -q "^FAIL:"; then
        fail "skills filesystem parity mismatch"
    elif printf "%s" "$parity_output" | grep -q "^WARN:"; then
        warn "skills filesystem drift (non-fatal)"
    fi
}

doctorJsonSafety() {
    local LOCAL_JSON_SAFETY=true
    for local_json in .claude/session-aliases.json plugins/blocklist.json plugins/installed_plugins.json; do
        if [[ -f "$local_json" ]]; then
            if ! python3 -c "
import json, sys
data = json.loads(open(sys.argv[1]).read())
def check(obj, path=''):
    if isinstance(obj, dict):
        for k in obj:
            if k in ('__proto__', 'constructor', '__defineGetter__', '__defineSetter__'):
                print(f'  Unsafe key: {path}.{k}' if path else f'  Unsafe key: {k}')
                return True
            if check(obj[k], f'{path}.{k}' if path else k):
                return True
    return False
sys.exit(1 if check(data) else 0)
" "$local_json" 2>/dev/null; then
                LOCAL_JSON_SAFETY=false
                warn "Prototype pollution key in $local_json"
            fi
        fi
    done
    if $LOCAL_JSON_SAFETY; then
        pass "Local JSON files safe from prototype pollution vectors"
    fi

    local STALE_DIRS=""
    for runtime_dir in .claude/runtime .claude/tsc-cache; do
        if [[ -d "$runtime_dir" ]]; then
            local stale_count
            stale_count=$(find "$runtime_dir" -mindepth 1 -maxdepth 1 -type d -mtime +14 2>/dev/null | wc -l | tr -d ' ')
            if [[ "$stale_count" -gt 0 ]]; then
                STALE_DIRS="${STALE_DIRS}  $runtime_dir: $stale_count directories older than 14 days\n"
            fi
        fi
    done
    if [[ -n "$STALE_DIRS" ]]; then
        warn "Stale runtime directories found"
        printf '%b' "$STALE_DIRS"
    else
        pass "No stale runtime directories"
    fi
}
