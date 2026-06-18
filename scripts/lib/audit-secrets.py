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
    re.compile(r"\bsk-[A-Za-z0-9_-]{20,}"),
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
allowed_vendored_example_paths = {
    "references/everything-claude-code/.kiro/skills/deployment-patterns/SKILL.md",
    "references/everything-claude-code/.kiro/skills/docker-patterns/SKILL.md",
    "references/everything-claude-code/commands/update-docs.md",
    "references/everything-claude-code/examples/django-api-CLAUDE.md",
    "references/everything-claude-code/examples/go-microservice-CLAUDE.md",
    "references/everything-claude-code/examples/rust-api-CLAUDE.md",
    "references/everything-claude-code/skills/deployment-patterns/SKILL.md",
    "references/everything-claude-code/skills/django-verification/SKILL.md",
    "references/everything-claude-code/skills/docker-patterns/SKILL.md",
}

public_files = subprocess.check_output(
    ["git", "-C", str(root), "ls-files", "-co", "--exclude-standard"],
    text=True,
).splitlines()
ghost_tracked_files = subprocess.check_output(
    ["git", "-C", str(root), "ls-files", "--cached", "-i", "--exclude-standard"],
    text=True,
).splitlines()
scan_files = sorted({*public_files, *ghost_tracked_files})

first_party_hits = []
allowed_vendored_hits = []
unexpected_vendored_hits = []
ghost_tracked_hits = []
ghost_tracked_set = {path for path in ghost_tracked_files if path.strip()}
for rel_path in scan_files:
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
            if rel_path in ghost_tracked_set:
                ghost_tracked_hits.append(rel_path)
            elif rel_path in allowed_vendored_example_paths:
                allowed_vendored_hits.append(rel_path)
            elif rel_path.startswith("references/"):
                unexpected_vendored_hits.append(rel_path)
            else:
                first_party_hits.append(rel_path)
            break

if allowed_vendored_hits:
    print("Allowed vendored reference files contain credential-like example material:")
    for rel_path in allowed_vendored_hits[:40]:
        print(f"  {rel_path}")
    if len(allowed_vendored_hits) > 40:
        print(f"  ... and {len(allowed_vendored_hits) - 40} more")

if unexpected_vendored_hits:
    print("Unexpected credential-like hits in vendored references:")
    for rel_path in unexpected_vendored_hits:
        print(f"  {rel_path}")
    raise SystemExit(1)

if ghost_tracked_hits:
    print("Credential-like hits in tracked-but-ignored files:")
    for rel_path in ghost_tracked_hits:
        print(f"  {rel_path}")
    raise SystemExit(1)

if first_party_hits:
    print("Secret-pattern hits in first-party workflow files:")
    for rel_path in first_party_hits:
        print(f"  {rel_path}")
    raise SystemExit(1)
