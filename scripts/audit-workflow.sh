#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "[1/8] Shell syntax"
bash -n .claude/hooks/*.sh .claude/hooks/lib/*.sh references/*.sh scripts/audit-workflow.sh

echo "[2/8] JSON parse and skill inventory"
python3 - << "PY"
import json
from pathlib import Path

root = Path(".")
skills_dir = root / ".claude" / "skills"
skill_rules_path = skills_dir / "skill-rules.json"

for path in [
    root / ".claude" / "settings.json",
    skill_rules_path,
]:
    with path.open() as handle:
        json.load(handle)

skill_rules = json.loads(skill_rules_path.read_text())
rule_skills = set(skill_rules.get("skills", {}))
skill_dirs = {
    path.name
    for path in skills_dir.iterdir()
    if path.is_dir() and (path / "SKILL.md").exists()
}

manual_only = {"gstack"}
missing_rules = sorted(skill_dirs - rule_skills - manual_only)
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
PY

echo "[3/8] Hook prompt classification and cache-key safety"
source ".claude/hooks/lib/patterns.sh"
source ".claude/hooks/lib/utils.sh"

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

run_skill_activation() {
    local prompt="$1"
    jq -n --arg prompt "$prompt" --arg session_id "audit" '{prompt: $prompt, session_id: $session_id}' |
        CLAUDE_PROJECT_DIR="$ROOT" bash "$ROOT/.claude/hooks/skill-activation-prompt.sh"
}

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
for expected_skill in skill-developer security-review security-scan; do
    if ! printf "%s\n" "$SKILL_OUTPUT" | grep -q "$expected_skill"; then
        echo "Missing expected skill activation: $expected_skill" >&2
        exit 1
    fi
done

CACHE_KEY="$(repo_cache_key "packages/app")"
if [[ -z "$CACHE_KEY" ]] || [[ "$CACHE_KEY" == *"/"* ]]; then
    echo "Unsafe repo cache key: $CACHE_KEY" >&2
    exit 1
fi

echo "[4/8] Local stale-reference scan"
python3 - << "PY"
from pathlib import Path
import re

root = Path(".")
paths = []
scan_roots = [
    root / ".claude",
    root / "references",
]

for scan_root in scan_roots:
    if not scan_root.exists():
        continue
    for path in scan_root.rglob("*.md"):
        text_path = path.as_posix()
        if text_path.startswith(".claude/skills/gstack/"):
            continue
        if text_path.startswith(".claude/skills/super-ralph/"):
            continue
        paths.append(path)

banned = {
    "auth-route-debugger": [],
    "auth-route-tester": [],
    "~/.claude/bin/codeagent-wrapper": [],
    "~/.claude/.ccg/prompts": [],
    "mcp__ace-tool__": [],
    "TaskOutput(": [],
}

for path in paths:
    text = path.read_text(errors="ignore")
    for token in banned:
        if token in text:
            banned[token].append(path.as_posix())

offenders = {token: hits for token, hits in banned.items() if hits}
if offenders:
    for token, hits in offenders.items():
        print(f"{token}:")
        for hit in hits:
            print(f"  {hit}")
    raise SystemExit(1)

owned_paths = [
    root / ".claude" / "agents",
    root / ".claude" / "commands",
    root / ".claude" / "prompt-templates",
]

stale_tokens = {
    ".claude/rules/": [],
    "SOUL.md": [],
    "calendar-suggest.js": [],
    "ECC quality pipeline": [],
    "HARD GATE: Do not proceed": [],
    "commit, push, create PR": [],
}

for owned_path in owned_paths:
    if not owned_path.exists():
        continue
    for path in owned_path.rglob("*.md"):
        text = path.read_text(errors="ignore")
        for token in stale_tokens:
            if token in text:
                stale_tokens[token].append(path.as_posix())

stale_offenders = {token: hits for token, hits in stale_tokens.items() if hits}
if stale_offenders:
    for token, hits in stale_offenders.items():
        print(f"{token}:")
        for hit in hits:
            print(f"  {hit}")
    raise SystemExit(1)

target_files = [
    *sorted((root / ".claude" / "commands").glob("*.md")),
    *sorted((root / ".claude" / "prompt-templates").glob("*.md")),
    root / ".claude" / "README.md",
    root / ".claude" / "WORKFLOW-REFERENCE.md",
]

pattern = re.compile(r"\.claude/skills/([^\s`\"')]+)")
broken_refs = []

for path in target_files:
    if not path.exists():
        continue
    text = path.read_text(errors="ignore")
    for match in pattern.finditer(text):
        rel = match.group(1).rstrip(".,:")
        if any(marker in rel for marker in ["*", "<", ">", "[", "]", "{", "}", ":"]):
            continue
        if not (root / ".claude" / "skills" / rel).exists():
            broken_refs.append((path.as_posix(), rel))

if broken_refs:
    print("Broken local skill references:")
    for path, rel in broken_refs:
        print(f"  {path}: {rel}")
    raise SystemExit(1)
PY

echo "[5/8] Plugin alignment and public surface"
python3 - << "PY"
import json
import subprocess
from pathlib import Path

root = Path(".")
settings = json.loads((root / ".claude" / "settings.json").read_text())
installed_path = root / "plugins" / "installed_plugins.json"

if installed_path.exists():
    installed = json.loads(installed_path.read_text()).get("plugins", {})
    enabled = set(settings.get("enabledPlugins", {}))
    installed_names = set(installed)
    missing = sorted(installed_names - enabled)
    if missing:
        print("Installed but not enabled plugins:")
        for name in missing:
            print(f"  {name}")
        raise SystemExit(1)

    blocklist_path = root / "plugins" / "blocklist.json"
    if blocklist_path.exists():
        blocklisted = {
            entry.get("plugin")
            for entry in json.loads(blocklist_path.read_text()).get("plugins", [])
            if entry.get("plugin")
        }
        blocked_enabled = sorted(enabled & blocklisted)
        if blocked_enabled:
            print("Runtime warning: enabled plugins currently appear in ignored local blocklist state:")
            for name in blocked_enabled:
                print(f"  {name}")

public_files = subprocess.check_output(
    ["git", "-C", str(root), "ls-files", "-co", "--exclude-standard"],
    text=True,
).splitlines()

disallowed_prefixes = [
    "social/",
    ".claude.json",
    ".claude/ide/",
    "plugins/",
    "projects/",
    "sessions/",
    "file-history/",
    "history.jsonl",
    "backups/",
]

bad = [path for path in public_files if any(path.startswith(prefix) for prefix in disallowed_prefixes)]

disallowed_extensions = {".mp4", ".mov", ".avi", ".mkv", ".webm", ".zip", ".tar", ".gz"}
bad.extend(
    path for path in public_files
    if any(path.endswith(ext) for ext in disallowed_extensions)
)

LARGE_FILE_THRESHOLD = 500_000
for rel_path in public_files:
    path = root / rel_path
    if path.is_file() and path.stat().st_size > LARGE_FILE_THRESHOLD:
        bad.append(f"{rel_path} ({path.stat().st_size // 1024}KB)")

if bad:
    print("Unexpected public files:")
    for path in sorted(set(bad)):
        print(f"  {path}")
    raise SystemExit(1)
PY

echo "[6/8] Secret-pattern scan on public surface"
python3 - << "PY"
import re
import subprocess
from pathlib import Path

root = Path(".")
patterns = [
    re.compile(r"authToken\s*[:=]\s*[\"'][^\"']+[\"']", re.IGNORECASE),
    re.compile(r"ghp_[A-Za-z0-9]{36}"),
    re.compile(r"github_pat_[A-Za-z0-9_]{82}"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"sk-[A-Za-z0-9]{20,}"),
    re.compile(r"-----BEGIN (RSA|DSA|EC|OPENSSH|PRIVATE KEY)-----"),
    re.compile(r"xoxb-[0-9]+-[0-9]+-[A-Za-z0-9]+"),
    re.compile(r"xoxp-[0-9]+-[0-9]+-[0-9]+-[a-f0-9]+"),
    re.compile(r"mongodb\+srv://[^@\s]+:[^@\s]+@"),
    re.compile(r"postgres://[^@\s]+:[^@\s]+@"),
    re.compile(r"mysql://[^@\s]+:[^@\s]+@"),
]

allow_paths = {
    ".claude/skills/gstack/ARCHITECTURE.md",
    ".claude/skills/deployment-patterns/SKILL.md",
    ".claude/skills/docker-patterns/SKILL.md",
    "scripts/audit-workflow.sh",
}

public_files = subprocess.check_output(
    ["git", "-C", str(root), "ls-files", "-co", "--exclude-standard"],
    text=True,
).splitlines()

hits = []
for rel_path in public_files:
    if rel_path in allow_paths:
        continue
    path = root / rel_path
    if path.is_dir():
        continue
    try:
        text = path.read_text()
    except UnicodeDecodeError:
        continue
    for pattern in patterns:
        if pattern.search(text):
            hits.append(rel_path)
            break

if hits:
    print("Secret-pattern hits:")
    for rel_path in hits:
        print(f"  {rel_path}")
    raise SystemExit(1)
PY

echo "[7/8] Ignored sensitive-state summary"
python3 - << "PY"
import re
import subprocess
from collections import Counter
from pathlib import Path

root = Path(".")
public_files = set(
    subprocess.check_output(
        ["git", "-C", str(root), "ls-files", "-co", "--exclude-standard"],
        text=True,
    ).splitlines()
)

patterns = [
    re.compile(r"ghp_[A-Za-z0-9]{36}"),
    re.compile(r"github_pat_[A-Za-z0-9_]{20,}"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"sk-[A-Za-z0-9]{20,}"),
    re.compile(r"-----BEGIN (RSA|DSA|EC|OPENSSH|PRIVATE KEY)-----"),
    re.compile(r"api[_-]?key", re.IGNORECASE),
    re.compile(r"authToken", re.IGNORECASE),
    re.compile(r"sessionSecret", re.IGNORECASE),
    re.compile(r"Bearer\s+[A-Za-z0-9._-]{20,}"),
]

hits = Counter()
for path in root.rglob("*"):
    if not path.is_file():
        continue
    rel_path = path.as_posix()
    if rel_path.startswith("./"):
        rel_path = rel_path[2:]
    if rel_path in public_files or rel_path.startswith(".git/"):
        continue
    try:
        text = path.read_text(errors="ignore")
    except OSError:
        continue
    if any(pattern.search(text) for pattern in patterns):
        top_level = rel_path.split("/", 1)[0]
        hits[top_level] += 1

if hits:
    print("Ignored sensitive-like files detected and kept out of the public surface:")
    for top_level, count in hits.most_common():
        print(f"  {top_level}: {count}")
else:
    print("No ignored sensitive-like files detected.")
PY

echo "[8/8] Public surface summary"
python3 - << "PY"
import subprocess
from collections import Counter

public_files = subprocess.check_output(
    ["git", "ls-files", "-co", "--exclude-standard"],
    text=True,
).splitlines()

print(f"Public files: {len(public_files)}")
counts = Counter(path.split("/", 1)[0] for path in public_files)
for top_level, count in sorted(counts.items()):
    print(f"  {top_level}: {count}")
PY

echo "Workflow audit passed."
