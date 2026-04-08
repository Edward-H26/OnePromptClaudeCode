"""Ghost-tracked file audit.

Detects files that match gitignore rules but remain in the git index
because they were committed before the rules were added. These files
are publicly visible despite the gitignore intent to exclude them.
"""
import subprocess
from pathlib import Path

root = Path(".")

ghost_files = subprocess.check_output(
    ["git", "-C", str(root), "ls-files", "--cached", "-i", "--exclude-standard"],
    text=True,
).splitlines()

ghost_files = [f for f in ghost_files if f.strip()]

if ghost_files:
    by_dir = {}
    for f in ghost_files:
        top = f.split("/", 1)[0]
        by_dir.setdefault(top, []).append(f)

    print("Ghost-tracked files found (match gitignore but still in index):")
    for top_dir in sorted(by_dir):
        print(f"  {top_dir}/: {len(by_dir[top_dir])} files")
    print(f"\nTotal: {len(ghost_files)} ghost-tracked files.")
    print("Fix: git ls-files --cached -i --exclude-standard | xargs git rm --cached")
    raise SystemExit(1)
