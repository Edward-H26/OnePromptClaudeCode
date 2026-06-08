"""[2/9] Hook script path resolution.

Verifies that all hook commands in settings.json reference scripts that exist on disk
and that repo-local shared scripts are actually tracked in git.
"""
import json
import os
import re
import subprocess
from pathlib import Path

root = Path(".")
repo_claude = root / ".claude"
home_claude = Path.home() / ".claude"
settings = json.loads((repo_claude / "settings.json").read_text())
hooks = settings.get("hooks", {})
tracked_files = set(
    subprocess.check_output(["git", "-C", str(root), "ls-files"], text=True).splitlines()
)


def candidate_paths(script_path: str) -> list[Path]:
    path = Path(script_path)
    candidates: list[Path] = []

    if path.is_absolute():
        try:
            relative_to_home = path.relative_to(home_claude)
        except ValueError:
            relative_to_home = None

        if relative_to_home is not None:
            candidates.append(repo_claude / relative_to_home)
        candidates.append(path)
    else:
        candidates.append(root / path)

    return candidates

missing = []
home_dir_refs = []
untracked_repo_scripts = []
ignored_hook_mentions = []
for event, entries in hooks.items():
    for entry in entries:
        for hook in entry.get("hooks", []):
            cmd = hook.get("command", "")
            resolved = cmd.replace("${CLAUDE_PROJECT_DIR:-$PWD}", str(root.resolve()))
            resolved = resolved.replace("$CLAUDE_PROJECT_DIR", str(root.resolve()))
            resolved = resolved.replace("$PWD", str(root.resolve()))
            resolved = resolved.replace("~/", os.path.expanduser("~/"))
            if str(home_claude) in resolved:
                home_dir_refs.append((event, cmd))
            scripts = re.findall(r'(/\S+\.sh|(?:^|\s)(\S+\.sh))', resolved)
            for match in scripts:
                script_path = match[0].strip() if match[0].strip().startswith("/") else match[1].strip()
                script_path = script_path.strip("\"'")
                if not script_path:
                    continue
                if not script_path.startswith("/"):
                    script_path = str(root / script_path)
                candidates = candidate_paths(script_path)
                existing_candidates = [path for path in candidates if path.is_file()]
                if not existing_candidates:
                    missing.append((event, script_path))
                    continue
                for candidate in existing_candidates:
                    try:
                        rel_candidate = candidate.resolve().relative_to(root.resolve()).as_posix()
                    except ValueError:
                        continue
                    if rel_candidate not in tracked_files:
                        untracked_repo_scripts.append((event, rel_candidate))

if missing:
    print("Hook commands reference missing scripts:")
    for event, path in missing:
        print(f"  [{event}] {path}")
    raise SystemExit(1)

status_line = settings.get("statusLine", {})
status_cmd = status_line.get("command", "")
if status_cmd:
    resolved = status_cmd.replace("${CLAUDE_PROJECT_DIR:-$PWD}", str(root.resolve()))
    resolved = resolved.replace("$CLAUDE_PROJECT_DIR", str(root.resolve()))
    resolved = resolved.replace("$PWD", str(root.resolve()))
    resolved = resolved.replace("~/", os.path.expanduser("~/"))
    if str(home_claude) in resolved:
        home_dir_refs.append(("statusLine", status_cmd))
    scripts = re.findall(r'(/\S+\.sh|(?:^|\s)(\S+\.sh))', resolved)
    for match in scripts:
        script_path = match[0].strip() if match[0].strip().startswith("/") else match[1].strip()
        script_path = script_path.strip("\"'")
        if not script_path:
            continue
        if not script_path.startswith("/"):
            script_path = str(root / script_path)
        if not any(path.is_file() for path in candidate_paths(script_path)):
            print(f"Status line command references missing script: {script_path}")
            raise SystemExit(1)

if home_dir_refs:
    print("Shared settings should not depend on $HOME/.claude paths:")
    for event, command in home_dir_refs:
        print(f"  [{event}] {command}")
    raise SystemExit(1)

doc_paths = [
    root / "README.md",
    repo_claude / "WORKFLOW-REFERENCE.md",
    repo_claude / "hooks" / "README.md",
]
hooks_dir = repo_claude / "hooks"
if hooks_dir.exists():
    for hook_path in hooks_dir.glob("*.sh"):
        rel_hook = hook_path.relative_to(root).as_posix()
        if rel_hook in tracked_files:
            continue
        result = subprocess.run(
            ["git", "-C", str(root), "check-ignore", "-q", rel_hook],
            check=False,
        )
        if result.returncode != 0:
            continue
        for doc_path in doc_paths:
            if not doc_path.exists():
                continue
            if hook_path.name in doc_path.read_text():
                ignored_hook_mentions.append(
                    (doc_path.relative_to(root).as_posix(), hook_path.name, rel_hook)
                )

if ignored_hook_mentions:
    print("Docs mention ignored hook prototypes as active workflow hooks:")
    for doc_path, hook_name, rel_hook in sorted(set(ignored_hook_mentions)):
        print(f"  [{doc_path}] {hook_name} is ignored at {rel_hook}")
    raise SystemExit(1)

if untracked_repo_scripts:
    print("Hook commands reference repo-local scripts that are not tracked in git:")
    for event, rel_path in sorted(set(untracked_repo_scripts)):
        print(f"  [{event}] {rel_path}")
    raise SystemExit(1)
