"""[6/9] Plugin alignment and public surface (continued).

Validates gitignore coverage, curated reference ignores,
optional build artifacts, public surface content, and large file detection.
"""
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

for ignored_path in [".claude/runtime/", ".claude/settings.local.json", ".credentials.json"]:
    gitignore_check = subprocess.run(
        ["git", "-C", str(root), "check-ignore", ignored_path],
        text=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    if gitignore_check.returncode != 0:
        print(f"Missing gitignore coverage for {ignored_path}")
        raise SystemExit(1)

intentional_reference_ignores = {
    "references/everything-claude-code/.env.example": ["/references/everything-claude-code/.env.example"],
    "references/everything-claude-code/.opencode/plugins/index.ts": ["/references/everything-claude-code/.opencode/plugins/"],
    "references/everything-claude-code/docs/ja-JP/plugins/README.md": ["/references/everything-claude-code/docs/*/plugins/"],
    "references/everything-claude-code/plugins/README.md": ["/references/everything-claude-code/plugins/"],
    "references/gstack/agents/openai.yaml": ["/references/gstack/agents/openai.yaml"],
    "references/gstack/bin/gstack-global-discover": ["/references/gstack/bin/gstack-global-discover", "bin/gstack-global-discover"],
    "references/gstack/browse/dist": ["/references/gstack/browse/dist/", "browse/dist/"],
    "references/super-ralph/learnings.md": ["/references/super-ralph/learnings.md", "learnings.md"],
}

for rel_path, expected_patterns in intentional_reference_ignores.items():
    full_path = root / rel_path
    if not full_path.exists():
        continue
    check = subprocess.run(
        ["git", "-C", str(root), "check-ignore", "--no-index", "-v", rel_path],
        text=True,
        capture_output=True,
    )
    if check.returncode != 0:
        print(f"Missing explicit curated ignore for {rel_path}")
        raise SystemExit(1)
    if not any(pattern in check.stdout for pattern in expected_patterns):
        print(f"Curated ignore for {rel_path} is being matched by the wrong rule:")
        print(check.stdout.strip())
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
    ".credentials.json",
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
KNOWN_LARGE_DATA_FILES = {
    "references/ui-ux-pro-max/data/google-fonts.csv",
}
for rel_path in public_files:
    if rel_path in KNOWN_LARGE_DATA_FILES:
        continue
    path = root / rel_path
    if path.is_file() and path.stat().st_size > LARGE_FILE_THRESHOLD:
        bad.append(f"{rel_path} ({path.stat().st_size // 1024}KB)")

if bad:
    print("Unexpected public files:")
    for path in sorted(set(bad)):
        print(f"  {path}")
    raise SystemExit(1)
