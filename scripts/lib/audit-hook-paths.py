"""[2/9] Hook script path resolution.

Verifies that all hook commands in settings.json reference scripts that exist on disk.
"""
import json
import os
import re
from pathlib import Path

root = Path(".")
settings = json.loads((root / ".claude" / "settings.json").read_text())
hooks = settings.get("hooks", {})

missing = []
for event, entries in hooks.items():
    for entry in entries:
        for hook in entry.get("hooks", []):
            cmd = hook.get("command", "")
            resolved = cmd.replace("$CLAUDE_PROJECT_DIR", str(root.resolve()))
            resolved = resolved.replace("~/", os.path.expanduser("~/"))
            scripts = re.findall(r'(/\S+\.sh|(?:^|\s)(\S+\.sh))', resolved)
            for match in scripts:
                script_path = match[0].strip() if match[0].strip().startswith("/") else match[1].strip()
                if not script_path:
                    continue
                if not script_path.startswith("/"):
                    script_path = str(root / script_path)
                if not os.path.isfile(script_path):
                    missing.append((event, script_path))

if missing:
    print("Hook commands reference missing scripts:")
    for event, path in missing:
        print(f"  [{event}] {path}")
    raise SystemExit(1)
