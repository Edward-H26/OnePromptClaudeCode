#!/usr/bin/env python3
"""Harness coverage scorecard.

Evaluates whether each edit-eligible file type in the repo has a matching
PostToolUse sensor wired in .claude/settings.json. Emits a compact table
plus an overall coverage percentage. Exits non-zero when coverage falls
below the threshold so the audit workflow treats drift as a hard failure.

Per Fowler's harness-engineering: measure whether sensors fire for every
class of change, not just whether a sensor exists somewhere.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from subprocess import check_output

ROOT = Path(".").resolve()
SETTINGS = ROOT / ".claude" / "settings.json"

SENSORS = [
    {
        "name": "tsc-check",
        "hook_name": "tsc-check.sh",
        "file_types": {".ts", ".tsx", ".js", ".jsx"},
        "purpose": "TypeScript type check",
    },
    {
        "name": "lint-check",
        "hook_name": "lint-check.sh",
        "file_types": {".ts", ".tsx", ".js", ".jsx", ".py", ".sh", ".mjs", ".cjs"},
        "purpose": "Linter on edit",
    },
    {
        "name": "post-tool-use-tracker",
        "hook_name": "post-tool-use-tracker.sh",
        "file_types": {"*"},
        "purpose": "Edit audit trail",
    },
    {
        "name": "check-mcp",
        "hook_name": "check-mcp.sh",
        "file_types": {"*"},
        "purpose": "MCP invocation audit",
    },
    {
        "name": "memory-bootstrap",
        "hook_name": "memory-bootstrap.sh",
        "file_types": {"*"},
        "purpose": "Memory index injection",
    },
]

TRACKED_EXTENSIONS = {
    ".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs",
    ".py", ".sh", ".bash",
    ".md", ".json", ".yaml", ".yml", ".toml",
    ".css", ".scss",
    ".html",
    ".go", ".rs", ".java", ".kt", ".swift",
}


def load_hooks() -> dict[str, list[str]]:
    if not SETTINGS.exists():
        return {}
    try:
        data = json.loads(SETTINGS.read_text())
    except json.JSONDecodeError:
        return {}
    wired: dict[str, list[str]] = {}
    for event, entries in (data.get("hooks") or {}).items():
        for entry in entries:
            matcher = entry.get("matcher", "*")
            for hook in entry.get("hooks", []):
                cmd = hook.get("command", "")
                basename = cmd.strip().split("/")[-1].split()[0]
                wired.setdefault(basename, []).append(f"{event}[{matcher}]")
    return wired


def count_tracked_extensions() -> dict[str, int]:
    counts: dict[str, int] = {}
    try:
        output = check_output(["git", "ls-files"], cwd=ROOT, text=True)
    except Exception:
        return counts
    for path in output.splitlines():
        suffix = Path(path).suffix.lower()
        if suffix in TRACKED_EXTENSIONS:
            counts[suffix] = counts.get(suffix, 0) + 1
    return counts


def main() -> int:
    wired = load_hooks()
    ext_counts = count_tracked_extensions()

    rows = []
    covered_ext: set[str] = set()
    for sensor in SENSORS:
        status = "wired" if sensor["hook_name"] in wired else "missing"
        events = ", ".join(wired.get(sensor["hook_name"], []))
        rows.append((sensor["name"], sensor["purpose"], status, events))
        if status == "wired":
            if "*" in sensor["file_types"]:
                covered_ext.update(TRACKED_EXTENSIONS)
            else:
                covered_ext.update(sensor["file_types"])

    total_files = sum(ext_counts.values()) or 1
    covered_files = sum(
        count for ext, count in ext_counts.items() if ext in covered_ext
    )
    coverage_pct = round((covered_files / total_files) * 100, 1)

    print("=== Harness Coverage Scorecard ===")
    print()
    print(f"{'Sensor':<24} {'Purpose':<26} {'Status':<10} Events")
    print("-" * 90)
    for name, purpose, status, events in rows:
        print(f"{name:<24} {purpose:<26} {status:<10} {events}")
    print()
    print(f"Tracked files in audited extensions: {total_files}")
    print(f"Files covered by at least one wired sensor: {covered_files}")
    print(f"Coverage: {coverage_pct}%")

    threshold = float(os.environ.get("HARNESS_COVERAGE_THRESHOLD", "50.0"))
    if coverage_pct < threshold:
        print(
            f"FAIL: coverage below {threshold}% threshold, "
            "add sensors for uncovered file types"
        )
        return 1
    print("OK: coverage meets threshold")
    return 0


if __name__ == "__main__":
    sys.exit(main())
