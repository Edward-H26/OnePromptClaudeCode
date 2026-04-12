#!/usr/bin/env python3
"""Validate that README.md counts match the actual filesystem inventory.

Prevents documentation drift by parsing the "At a Glance" table and the
top-of-file summary line, then comparing each count to a live count of
skills, commands, agents, hooks, and templates.

Exits 0 when everything matches, 1 on any mismatch.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
README = ROOT / "README.md"


def count_skills() -> int:
    skills_dir = ROOT / ".claude" / "skills"
    if not skills_dir.exists():
        return 0
    entries = []
    for item in skills_dir.iterdir():
        if item.name == "skill-rules.json":
            continue
        if item.is_dir():
            entries.append(item.name)
        elif item.is_symlink() and item.exists():
            entries.append(item.name)
    return len(entries)


def count_commands() -> int:
    cmd_dir = ROOT / ".claude" / "commands"
    if not cmd_dir.exists():
        return 0
    return sum(1 for p in cmd_dir.glob("*.md") if p.name != "README.md")


def count_agents() -> int:
    agents_dir = ROOT / ".claude" / "agents"
    if not agents_dir.exists():
        return 0
    return sum(1 for p in agents_dir.glob("*.md") if p.name != "README.md")


def count_hooks() -> tuple[int, int]:
    local_dir = ROOT / ".claude" / "hooks"
    local = len(list(local_dir.glob("*.sh"))) if local_dir.exists() else 0
    gstack_dir = ROOT / ".claude" / "skills" / "gstack"
    gstack = 0
    if gstack_dir.exists():
        gstack = len(list(gstack_dir.glob("*/bin/check-*.sh")))
    return local, gstack


def count_templates() -> int:
    tpl_dir = ROOT / ".claude" / "prompt-templates"
    if not tpl_dir.exists():
        return 0
    return sum(1 for p in tpl_dir.glob("*.md") if p.name != "README.md")


def parse_readme_summary(text: str) -> dict[str, int]:
    pattern = re.compile(
        r"(\d+)\s*skill\s*entries?\s*\.\s*"
        r"(\d+)\s*commands?\s*\.\s*"
        r"(\d+)\s*agents?\s*\.\s*"
        r"(\d+)\s*local\s*hooks?\s*\.\s*"
        r"(\d+)\s*templates?",
        re.IGNORECASE,
    )
    match = pattern.search(text)
    if not match:
        return {}
    return {
        "skills": int(match.group(1)),
        "commands": int(match.group(2)),
        "agents": int(match.group(3)),
        "hooks": int(match.group(4)),
        "templates": int(match.group(5)),
    }


def parse_at_a_glance_table(text: str) -> dict[str, int]:
    rows = re.findall(r"\|\s*\*\*([A-Za-z ]+)\*\*\s*\|\s*([0-9]+)", text)
    mapping = {}
    for label, count in rows:
        key = label.strip().lower()
        if key.endswith("s"):
            key = key.rstrip("s")
        if key in {"skill", "command", "agent", "template"}:
            mapping[key + "s"] = int(count)
        elif key == "hook":
            mapping["hooks"] = int(count)
    return mapping


def main() -> int:
    if not README.exists():
        print(f"FAIL: README.md not found at {README}", file=sys.stderr)
        return 1

    text = README.read_text()
    summary = parse_readme_summary(text)
    glance = parse_at_a_glance_table(text)

    local_hooks, gstack_hooks = count_hooks()
    actual = {
        "skills": count_skills(),
        "commands": count_commands(),
        "agents": count_agents(),
        "hooks": local_hooks + gstack_hooks,
        "templates": count_templates(),
    }

    mismatches = []

    if not summary:
        print("WARN: Could not parse README top-of-file count summary.")
    else:
        for key, expected in summary.items():
            if key == "hooks":
                got = local_hooks
            else:
                got = actual[key]
            if expected != got:
                mismatches.append(
                    f"README summary claims {expected} {key} but filesystem has {got}"
                )

    if not glance:
        print("WARN: Could not parse README 'At a Glance' table.")
    else:
        for key, expected in glance.items():
            got = actual[key]
            if expected != got:
                mismatches.append(
                    f"README 'At a Glance' claims {expected} {key} but filesystem has {got}"
                )

    print(
        "Filesystem counts: "
        f"skills={actual['skills']} commands={actual['commands']} "
        f"agents={actual['agents']} hooks={actual['hooks']} "
        f"(local={local_hooks} + gstack={gstack_hooks}) "
        f"templates={actual['templates']}"
    )

    if mismatches:
        print("\nREADME parity issues:")
        for msg in mismatches:
            print(f"  - {msg}")
        print("\nUpdate README.md to match filesystem or justify the deliberate difference.")
        return 1

    print("README counts match filesystem inventory.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
