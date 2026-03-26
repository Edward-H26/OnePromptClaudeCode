#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "[1/9] Shell syntax"
bash -n .claude/hooks/*.sh .claude/hooks/lib/*.sh references/*.sh scripts/audit-workflow.sh
for gstack_bin in .claude/skills/gstack/*/bin/*.sh; do
    [ -f "$gstack_bin" ] && bash -n "$gstack_bin"
done

echo "[2/9] Hook script path resolution"
python3 - << "PY"
import json, os, re
from pathlib import Path

root = Path(".")
settings = json.loads((root / ".claude" / "settings.json").read_text())
hooks = settings.get("hooks", {})

missing = []
for event, entries in hooks.items():
    for entry in entries:
        for hook in entry.get("hooks", []):
            cmd = hook.get("command", "")
            resolved = cmd.replace("$CLAUDE_PROJECT_DIR", str(root.resolve()))
            scripts = re.findall(r'(/\S+\.sh|(?:^|\s)(\S+\.sh))', resolved)
            for match in scripts:
                script_path = match[0].strip() if match[0].strip().startswith("/") else match[1].strip()
                if not script_path:
                    continue
                if not script_path.startswith("/"):
                    script_path = str(root / script_path)
                if not os.path.isfile(script_path):
                    missing.append((event, script_path))

if missing:
    print("Hook commands reference missing scripts:")
    for event, path in missing:
        print(f"  [{event}] {path}")
    raise SystemExit(1)
PY

echo "[3/9] JSON parse and skill inventory"
python3 - << "PY"
import json
from pathlib import Path

root = Path(".")
skills_dir = root / ".claude" / "skills"
skill_rules_path = skills_dir / "skill-rules.json"

for path in [root / ".claude" / "settings.json", skill_rules_path]:
    with path.open() as handle:
        json.load(handle)

skill_rules = json.loads(skill_rules_path.read_text())
rule_skills = set(skill_rules.get("skills", {}))
skill_dirs = {
    path.name
    for path in skills_dir.iterdir()
    if (path.is_dir() or path.is_symlink()) and (path / "SKILL.md").exists()
}

manual_only = {"super-ralph"}
missing_rules = sorted(skill_dirs - rule_skills - manual_only)
missing_dirs = sorted(rule_skills - skill_dirs - manual_only)

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
    skills_dir / "gstack" / "SKILL.md",
    skills_dir / "super-ralph" / "SKILL.md",
]:
    if not required.exists():
        print(f"Missing required local skill entry: {required.as_posix()}")
        raise SystemExit(1)

reference_dirs = [
    root / "references" / "gstack",
    root / "references" / "super-ralph",
    root / "references" / "everything-claude-code",
]
missing_references = [path for path in reference_dirs if not path.exists()]
if missing_references:
    print("Missing required vendored reference directories:")
    for path in missing_references:
        print(f"  {path.as_posix()}")
    print("Run bash references/setup.sh to restore the tracked vendored workflow sources.")
    raise SystemExit(1)
PY

echo "[4/9] Hook prompt classification and cache-key safety"
source ".claude/hooks/lib/patterns.sh"
source ".claude/hooks/lib/utils.sh"
source ".claude/hooks/lib/plugin-state.sh"

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

CACHE_KEY="$(repo_cache_key "packages/app")"
if [[ -z "$CACHE_KEY" ]] || [[ "$CACHE_KEY" == *"/"* ]]; then
    echo "Unsafe repo cache key: $CACHE_KEY" >&2
    exit 1
fi

echo "[5/9] Local stale-reference scan"
python3 - << "PY"
from pathlib import Path
import re

root = Path(".")
paths = []
external_prefixes = [
    ".claude/skills/gstack/",
    ".claude/skills/browse/",
    ".claude/skills/careful/",
    ".claude/skills/design-consultation/",
    ".claude/skills/design-review/",
    ".claude/skills/document-release/",
    ".claude/skills/freeze/",
    ".claude/skills/gstack-upgrade/",
    ".claude/skills/guard/",
    ".claude/skills/investigate/",
    ".claude/skills/office-hours/",
    ".claude/skills/plan-ceo-review/",
    ".claude/skills/plan-design-review/",
    ".claude/skills/plan-eng-review/",
    ".claude/skills/qa/",
    ".claude/skills/qa-only/",
    ".claude/skills/retro/",
    ".claude/skills/review/",
    ".claude/skills/setup-browser-cookies/",
    ".claude/skills/ship/",
    ".claude/skills/unfreeze/",
    ".claude/skills/super-ralph/agents/",
    ".claude/skills/super-ralph/commands/",
    ".claude/skills/super-ralph/skills/",
    "references/gstack/",
    "references/super-ralph/",
    "references/everything-claude-code/",
]
external_prefixes.extend(
    f".claude/skills/{name}/" for name in [
        "agentic-engineering",
        "autonomous-loops",
        "claude-api",
        "deep-research",
        "deployment-patterns",
        "docker-patterns",
        "e2e-testing",
        "eval-harness",
        "liquid-glass-design",
        "postgres-patterns",
        "python-patterns",
        "python-testing",
        "search-first",
        "security-review",
        "security-scan",
        "strategic-compact",
        "tdd-workflow",
        "verification-loop",
    ]
)
scan_roots = [
    root / ".claude",
    root / "references",
]

for scan_root in scan_roots:
    if not scan_root.exists():
        continue
    for path in scan_root.rglob("*.md"):
        text_path = path.as_posix()
        if any(text_path.startswith(prefix) for prefix in external_prefixes):
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

echo "[6/9] Plugin alignment and public surface"
TMP_PLUGIN_STATE_DIR="$(mktemp -d)"
plugin_enabled_names > "$TMP_PLUGIN_STATE_DIR/enabled"
plugin_available_names > "$TMP_PLUGIN_STATE_DIR/available"
plugin_blocklisted_names > "$TMP_PLUGIN_STATE_DIR/blocklisted"

if plugin_has_install_state; then
    plugin_installed_names > "$TMP_PLUGIN_STATE_DIR/installed"
    INSTALLED_BUT_DISABLED="$(comm -23 "$TMP_PLUGIN_STATE_DIR/installed" "$TMP_PLUGIN_STATE_DIR/enabled" || true)"
    if [[ -n "$INSTALLED_BUT_DISABLED" ]]; then
        echo "Note: installed but not enabled plugins:"
        while IFS= read -r name; do
            [[ -z "$name" ]] && continue
            echo "  $name"
        done <<< "$INSTALLED_BUT_DISABLED"
    fi

    ENABLED_BUT_UNAVAILABLE="$(comm -23 "$TMP_PLUGIN_STATE_DIR/enabled" "$TMP_PLUGIN_STATE_DIR/available" || true)"
    if [[ -n "$ENABLED_BUT_UNAVAILABLE" ]]; then
        echo "Note: enabled plugins not locally available:"
        while IFS= read -r name; do
            [[ -z "$name" ]] && continue
            reason="not installed locally"
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

python3 - << "PY"
import json
import subprocess
from pathlib import Path

root = Path(".")

gitignore_check = subprocess.run(
    ["git", "-C", str(root), "check-ignore", ".superpowers/"],
    text=True,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
)
if gitignore_check.returncode != 0:
    print("Missing gitignore coverage for .superpowers/")
    raise SystemExit(1)

optional_build_artifacts = [
    (root / "references" / "gstack" / "browse" / "dist" / "browse",
     "vendored gstack browse binary not built. Run: cd references/gstack/browse && npm run build"),
    (root / ".claude" / "skills" / "chrome-devtools" / "scripts" / "node_modules",
     "chrome-devtools deps not installed. Run: cd .claude/skills/chrome-devtools/scripts && npm install"),
]
missing_optional = [(p, msg) for p, msg in optional_build_artifacts if not p.exists()]
if missing_optional:
    print("Note: optional build artifacts are absent (expected on fresh clones):")
    for _, msg in missing_optional:
        print(f"  {msg}")

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

echo "[7/9] Secret-pattern scan on public surface"
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

allow_paths = {"scripts/audit-workflow.sh"}

public_files = subprocess.check_output(
    ["git", "-C", str(root), "ls-files", "-co", "--exclude-standard"],
    text=True,
).splitlines()

first_party_hits = []
vendored_hits = []
for rel_path in public_files:
    if rel_path in allow_paths:
        continue
    if rel_path.startswith(".claude/skills/gstack/test/"):
        continue
    path = root / rel_path
    if path.is_dir():
        continue
    if not path.is_file():
        continue
    try:
        text = path.read_text()
    except (UnicodeDecodeError, OSError):
        continue
    for pattern in patterns:
        if pattern.search(text):
            if rel_path.startswith("references/"):
                vendored_hits.append(rel_path)
            else:
                first_party_hits.append(rel_path)
            break

if vendored_hits:
    print("Note: vendored reference content contains credential-like example material:")
    for rel_path in vendored_hits[:40]:
        print(f"  {rel_path}")
    if len(vendored_hits) > 40:
        print(f"  ... and {len(vendored_hits) - 40} more")

if first_party_hits:
    print("Secret-pattern hits in first-party workflow files:")
    for rel_path in first_party_hits:
        print(f"  {rel_path}")
    raise SystemExit(1)
PY

echo "[8/9] Ignored sensitive-state summary"
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

echo "[9/9] Public surface summary"
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
