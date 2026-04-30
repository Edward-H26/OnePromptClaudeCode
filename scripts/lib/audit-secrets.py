"""[7/9] Secret-pattern scan on public surface.

Scans all tracked files for credential-like patterns. Vendored reference content
gets a warning; first-party hits are a hard failure.
"""
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
    re.compile(r"hf_[A-Za-z0-9]{30,}"),
    re.compile(r"sk-ant-[A-Za-z0-9_-]{20,}"),
    re.compile(r"glpat-[A-Za-z0-9_-]{20,}"),
    re.compile(r"AIza[0-9A-Za-z\\-_]{35}"),
]

allow_paths = {"scripts/audit-workflow.sh", "scripts/lib/audit-secrets.py"}

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
