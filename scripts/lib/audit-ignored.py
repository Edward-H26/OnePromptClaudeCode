"""[8/9] Ignored sensitive-state summary.

Scans ignored files for credential-like patterns, grouped by top-level
directory. Advisory only, never fails.
"""
import re
import subprocess
from collections import Counter
from pathlib import Path

root = Path(".")
ignored_files = subprocess.check_output(
    ["git", "-C", str(root), "ls-files", "-oi", "--exclude-standard"],
    text=True,
).splitlines()

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
for rel_path in ignored_files:
    path = root / rel_path
    if not path.is_file():
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
