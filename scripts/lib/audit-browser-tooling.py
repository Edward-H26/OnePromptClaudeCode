#!/usr/bin/env python3
"""Verify browser tooling documentation stays consistent.

Checks that CLAUDE-website-workflow.md and CLAUDE-testing.md present the
preferred browser tool first when multiple options are mentioned. The
preferred tool is configurable via the PREFERRED_BROWSER_TOOL env var
and defaults to "chrome-devtools".

Exits 0 on pass, 1 when the preferred tool does not appear before its
secondary alternative in a file that mentions both.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
FILES = [
    ROOT / ".claude" / "CLAUDE-website-workflow.md",
    ROOT / ".claude" / "CLAUDE-testing.md",
]
PREFERRED = os.environ.get("PREFERRED_BROWSER_TOOL", "chrome-devtools").lower()
SECONDARY = "playwright" if PREFERRED == "chrome-devtools" else "chrome-devtools"


def first_mention(text: str, needle: str) -> int:
    lower = text.lower()
    idx = lower.find(needle)
    return idx


def main() -> int:
    issues = []
    for path in FILES:
        if not path.exists():
            continue
        text = path.read_text()
        pref_idx = first_mention(text, PREFERRED)
        sec_idx = first_mention(text, SECONDARY)
        rel = path.relative_to(ROOT)
        if pref_idx < 0 and sec_idx < 0:
            print(f"NOTE: {rel} mentions neither {PREFERRED} nor {SECONDARY}")
            continue
        if pref_idx < 0:
            issues.append(
                f"{rel} mentions {SECONDARY} but not {PREFERRED} (preferred tool)"
            )
            continue
        if sec_idx < 0:
            print(f"PASS: {rel} mentions {PREFERRED} only")
            continue
        if sec_idx < pref_idx:
            issues.append(
                f"{rel} mentions {SECONDARY} before {PREFERRED} "
                f"(positions {sec_idx} vs {pref_idx})"
            )
        else:
            print(f"PASS: {rel} mentions {PREFERRED} before {SECONDARY}")

    if issues:
        print("\nBrowser tooling order issues:")
        for msg in issues:
            print(f"  - {msg}")
        print(
            "\nUpdate the docs so the preferred browser tool "
            f"({PREFERRED}) appears first, or override via "
            "PREFERRED_BROWSER_TOOL=playwright if intentional."
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
