"""[3/9] JSON parse and skill inventory.

Validates JSON configs, skill-rules alignment, required files, reference dirs,
README inventory counts, placeholder detection, and markdown link integrity.
"""
import json
import re
import subprocess
from pathlib import Path

root = Path(".")
skills_dir = root / ".claude" / "skills"
skill_rules_path = skills_dir / "skill-rules.json"

parsed_json = {}
for path in [root / ".claude" / "settings.json", root / ".claude" / "settings.local.example.json", skill_rules_path]:
    if not path.exists():
        print(f"Required config file not found: {path.as_posix()}")
        raise SystemExit(1)
    with path.open() as handle:
        parsed_json[path.name] = json.load(handle)

enabled_mcpjson_servers = parsed_json["settings.json"].get("enabledMcpjsonServers") or []
if enabled_mcpjson_servers:
    mcp_json_path = root / ".mcp.json"
    if not mcp_json_path.exists():
        print("settings.json enables project MCP servers, but .mcp.json is missing.")
        raise SystemExit(1)
    with mcp_json_path.open() as handle:
        mcp_json = json.load(handle)
    declared_mcp_servers = set((mcp_json.get("mcpServers") or {}).keys())
    missing_mcp_servers = sorted(set(enabled_mcpjson_servers) - declared_mcp_servers)
    if missing_mcp_servers:
        print("settings.json enables project MCP servers that are absent from .mcp.json:")
        for server_name in missing_mcp_servers:
            print(f"  {server_name}")
        raise SystemExit(1)

tracked_files = subprocess.check_output(["git", "ls-files"], text=True).splitlines()
tracked_file_set = set(tracked_files)

settings_local_example = parsed_json["settings.local.example.json"]
if "permissions" in settings_local_example:
    print(".claude/settings.local.example.json should not carry machine-local permission overrides.")
    raise SystemExit(1)

machine_local_path_pattern = re.compile(r"(/Users/|/home/|[A-Za-z]:\\\\Users\\\\)")


def find_machine_local_path(value, path="root"):
    if isinstance(value, dict):
        for key, item in value.items():
            hit = find_machine_local_path(item, f"{path}.{key}")
            if hit:
                return hit
    elif isinstance(value, list):
        for index, item in enumerate(value):
            hit = find_machine_local_path(item, f"{path}[{index}]")
            if hit:
                return hit
    elif isinstance(value, str) and machine_local_path_pattern.search(value):
        return path
    return None


machine_local_hit = find_machine_local_path(settings_local_example)
if machine_local_hit:
    print(
        ".claude/settings.local.example.json should not embed machine-local absolute paths:"
        f" {machine_local_hit}"
    )
    raise SystemExit(1)

optional_example_plugins = {
    "context7@claude-plugins-official",
    "figma@claude-plugins-official",
    "github@claude-plugins-official",
    "playwright@claude-plugins-official",
    "superpowers@claude-plugins-official",
    "huggingface-skills@claude-plugins-official",
}
enabled_example_plugins = {
    name
    for name, value in (settings_local_example.get("enabledPlugins") or {}).items()
    if value is True
}
unsafe_example_plugins = sorted(optional_example_plugins & enabled_example_plugins)
if unsafe_example_plugins:
    print(".claude/settings.local.example.json should leave optional plugins disabled by default:")
    for name in unsafe_example_plugins:
        print(f"  {name}")
    raise SystemExit(1)

skill_rules = parsed_json["skill-rules.json"]
rule_skills = set(skill_rules.get("skills", {}))
skill_dirs = {
    path.name
    for path in skills_dir.iterdir()
    if (path.is_dir() or path.is_symlink()) and (path / "SKILL.md").exists()
}

missing_rules = sorted(skill_dirs - rule_skills)
missing_dirs = sorted(rule_skills - skill_dirs)

if missing_rules:
    print("Tracked skills missing skill-rules entries:")
    for name in missing_rules:
        print(f"  {name}")
    raise SystemExit(1)

if missing_dirs:
    print("skill-rules entries missing tracked skill directories:")
    for name in missing_dirs:
        print(f"  {name}")
    raise SystemExit(1)

for required in [
    skills_dir / "codex" / "scripts" / "ask_codex.sh",
    skills_dir / "codex" / "scripts" / "ask_codex.ps1",
    skills_dir / "webapp-testing" / "scripts" / "browser_navigate.py",
    skills_dir / "webapp-testing" / "scripts" / "with_server.py",
]:
    if not required.exists():
        print(f"Missing required local skill entry: {required.as_posix()}")
        raise SystemExit(1)
    rel_required = required.relative_to(root).as_posix()
    if rel_required not in tracked_file_set:
        print(f"Required workflow file exists locally but is not tracked in git: {rel_required}")
        raise SystemExit(1)

readme = (root / "README.md").read_text()
command_count = len([path for path in (root / ".claude" / "commands").glob("*.md") if path.name != "README.md"])
agent_count = len([path for path in (root / ".claude" / "agents").glob("*.md") if path.name != "README.md"])
hook_count = len(
    [
        path for path in (root / ".claude" / "hooks").glob("*.sh")
        if path.as_posix() in tracked_file_set
    ]
)
template_count = len([path for path in (root / ".claude" / "prompt-templates").glob("*.md") if path.name != "README.md"])
skill_count = len(skill_dirs)

expected_fragments = [
    f"{skill_count} skill entries. {command_count} commands. {agent_count} agents. {hook_count} local hooks. {template_count} templates.",
    f"| **Skills** | {skill_count} |",
    f"| **Agents** | {agent_count} |",
    f"| **Commands** | {command_count} |",
    f"commands/              # {command_count} slash commands",
    f"skills/                # {skill_count} skill entries",
]

for fragment in expected_fragments:
    if fragment not in readme:
        print(f"README.md is missing expected inventory text: {fragment}")
        raise SystemExit(1)

permissions = parsed_json["settings.json"].get("permissions") or {}
permission_buckets = {
    "allow": set(permissions.get("allow") or []),
    "ask": set(permissions.get("ask") or []),
    "deny": set(permissions.get("deny") or []),
}

overlaps = []
bucket_names = sorted(permission_buckets)
for index, left in enumerate(bucket_names):
    for right in bucket_names[index + 1:]:
        shared = sorted(permission_buckets[left] & permission_buckets[right])
        if shared:
            overlaps.append((left, right, shared))

if overlaps:
    print("Permission rules must not be duplicated across allow/ask/deny buckets:")
    for left, right, shared in overlaps:
        print(f"  {left} vs {right}:")
        for rule in shared:
            print(f"    {rule}")
    raise SystemExit(1)

placeholder_hits = []
for rel_path in tracked_files:
    path = root / rel_path
    if not path.is_file():
        continue
    try:
        text = path.read_text()
    except (UnicodeDecodeError, OSError):
        continue
    if text.strip() == "404: Not Found":
        placeholder_hits.append(rel_path)

if placeholder_hits:
    print("Tracked files contain placeholder 404 content:")
    for rel_path in placeholder_hits:
        print(f"  {rel_path}")
    raise SystemExit(1)

link_pattern = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
broken_links = []
for rel_path in tracked_files:
    if not rel_path.endswith(".md") or rel_path.startswith("references/"):
        continue
    path = root / rel_path
    if not path.exists():
        continue
    text = path.read_text(errors="ignore")
    for link in link_pattern.findall(text):
        if link.startswith(("http://", "https://", "#", "mailto:")):
            continue
        target = link.split("#", 1)[0]
        if not target:
            continue
        resolved = (path.parent / target).resolve()
        try:
            resolved.relative_to(root.resolve())
        except ValueError:
            broken_links.append((rel_path, link, "escapes repo root"))
            continue
        if not resolved.exists():
            broken_links.append((rel_path, link, "missing target"))

if broken_links:
    print("Broken first-party markdown links:")
    for rel_path, link, reason in broken_links:
        print(f"  {rel_path}: {link} ({reason})")
    raise SystemExit(1)

proto_pollution_keys = {"__proto__", "constructor", "__defineGetter__", "__defineSetter__"}
tracked_json_files = [
    root / ".claude" / "settings.json",
    root / ".claude" / "settings.local.example.json",
    skill_rules_path,
]

def check_proto_keys(obj, path=""):
    if isinstance(obj, dict):
        for key in obj:
            if key in proto_pollution_keys:
                return f"{path}.{key}" if path else key
            result = check_proto_keys(obj[key], f"{path}.{key}" if path else key)
            if result:
                return result
    elif isinstance(obj, list):
        for i, item in enumerate(obj):
            result = check_proto_keys(item, f"{path}[{i}]")
            if result:
                return result
    return None

for json_path in tracked_json_files:
    if not json_path.exists():
        continue
    data = json.loads(json_path.read_text())
    hit = check_proto_keys(data)
    if hit:
        print(f"Prototype pollution key found in {json_path.as_posix()}: {hit}")
        raise SystemExit(1)

agent_names = [p.stem.lower() for p in (root / ".claude" / "agents").glob("*.md") if p.name != "README.md"]
if len(agent_names) != len(set(agent_names)):
    dupes = [name for name in agent_names if agent_names.count(name) > 1]
    print(f"Duplicate agent names: {sorted(set(dupes))}")
    raise SystemExit(1)

command_names_list = [p.stem.lower() for p in (root / ".claude" / "commands").glob("*.md") if p.name != "README.md"]
if len(command_names_list) != len(set(command_names_list)):
    dupes = [name for name in command_names_list if command_names_list.count(name) > 1]
    print(f"Duplicate command names: {sorted(set(dupes))}")
    raise SystemExit(1)
