"""[9/9] Public surface summary.

Prints a breakdown of public (tracked + untracked non-ignored) files by top-level directory.
"""
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
