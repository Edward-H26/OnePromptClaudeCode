"""[5/9] Local stale-reference scan.

Checks for banned tokens, stale references in owned files,
and broken skill path references in commands and templates.
"""
import re
import subprocess
from pathlib import Path

root = Path(".")
public_paths = set(
    subprocess.check_output(
        ["git", "-C", str(root), "ls-files", "-co", "--exclude-standard"],
        text=True,
    ).splitlines()
)
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
        if text_path not in public_paths:
            continue
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
