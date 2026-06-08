"""[8/9] Ignored sensitive-state summary.

Scans ignored files for credential-like patterns, grouped by top-level
directory. Advisory only, never fails.
"""
import os
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
    re.compile(r"sk-[A-Za-z0-9_-]{20,}"),
    re.compile(r"-----BEGIN (RSA|DSA|EC|OPENSSH|PRIVATE KEY)-----"),
    re.compile(r"api[_-]?key", re.IGNORECASE),
    re.compile(r"authToken", re.IGNORECASE),
    re.compile(r"sessionSecret", re.IGNORECASE),
    re.compile(r"Bearer\s+[A-Za-z0-9._-]{20,}"),
]

MAX_BYTES = int(os.environ.get("IGNORED_AUDIT_MAX_BYTES", "1048576"))
TEXT_SUFFIXES = {
    ".cjs",
    ".conf",
    ".env",
    ".ini",
    ".js",
    ".json",
    ".jsonl",
    ".log",
    ".md",
    ".mjs",
    ".ps1",
    ".py",
    ".sh",
    ".toml",
    ".txt",
    ".yaml",
    ".yml",
}
ALWAYS_SKIP_SUFFIXES = {
    ".pyc",
    ".pyo",
}
HIGH_RISK_NAME_PATTERN = re.compile(
    r"(^|[./_-])"
    r"(auth|credential|credentials|env|key|secret|secrets|token|tokens)"
    r"([./_-]|$)",
    re.IGNORECASE,
)
SKIP_DIRS = {
    ".git",
    ".pytest_cache",
    ".ruff_cache",
    "__pycache__",
    "cache",
    "node_modules",
    "out",
}


def should_scan(path: Path, rel_path: str) -> tuple[bool, str]:
    parts = set(path.parts)
    if parts & SKIP_DIRS and not HIGH_RISK_NAME_PATTERN.search(rel_path):
        return False, "generated"

    if path.suffix.lower() in ALWAYS_SKIP_SUFFIXES:
        return False, "generated"

    if (
        path.suffix.lower() not in TEXT_SUFFIXES
        and not HIGH_RISK_NAME_PATTERN.search(rel_path)
    ):
        return False, "non_text"

    try:
        size = path.stat().st_size
    except OSError:
        return False, "stat_error"

    if size > MAX_BYTES and not HIGH_RISK_NAME_PATTERN.search(rel_path):
        return False, "large"

    return True, ""


hits = Counter()
unexpected_first_party_hits = []
skipped = Counter()
scanned = 0
allowlisted_prefixes = (
    ".claude/runtime/",
    ".claude/metrics/",
    ".claude/projects/",
    ".claude/file-history/",
    ".claude/history.jsonl",
    ".claude/plugins/",
    ".claude/debug/",
    ".claude/shell-snapshots/",
    ".claude/statsig/",
    ".claude/todos/",
    ".claude/ide/",
    ".claude/session-data/",
    ".claude/homunculus/",
    ".claude/checkpoints/",
    ".claude/skills/codex/.runtime/",
    ".claude/settings.local.json",
    ".claude.json",
    ".credentials.json",
    "backups/",
    "cache/",
    "chrome/",
    "file-history/",
    "history.jsonl",
    "image-cache/",
    "paste-cache/",
    "plans/",
    "plugins/",
    "projects/",
    "references/",
    "sessions/",
    "session-env/",
    "telemetry/",
    "video/",
)
for rel_path in ignored_files:
    path = root / rel_path
    if not path.is_file():
        continue
    should_scan_file, reason = should_scan(path, rel_path)
    if not should_scan_file:
        skipped[reason] += 1
        continue
    try:
        text = path.read_text(errors="ignore")
    except OSError:
        skipped["read_error"] += 1
        continue
    scanned += 1
    if any(pattern.search(text) for pattern in patterns):
        top_level = rel_path.split("/", 1)[0]
        hits[top_level] += 1
        if not rel_path.startswith(allowlisted_prefixes):
            unexpected_first_party_hits.append(rel_path)

print(f"Ignored files scanned: {scanned}")
if skipped:
    skipped_summary = ", ".join(
        f"{name}={count}" for name, count in sorted(skipped.items())
    )
    print(f"Ignored files skipped: {skipped_summary}")

if hits:
    print("Ignored sensitive-like files detected and kept out of the public surface:")
    for top_level, count in hits.most_common():
        print(f"  {top_level}: {count}")
else:
    print("No ignored sensitive-like files detected.")

if unexpected_first_party_hits:
    print("Unexpected ignored first-party sensitive-like files worth reviewing:")
    for rel_path in sorted(unexpected_first_party_hits)[:40]:
        print(f"  {rel_path}")
    if len(unexpected_first_party_hits) > 40:
        print(f"  ... and {len(unexpected_first_party_hits) - 40} more")
