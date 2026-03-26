#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")/.claude"

sync_reference() {
    local source_dir="$1"
    local target_dir="$2"

    mkdir -p "$target_dir"
    rsync -a --delete --exclude ".git/" "$source_dir/" "$target_dir/"
}

REPOS=(
    "https://github.com/garrytan/gstack.git"
    "https://github.com/ashcastelinocs124/super-ralph.git"
    "https://github.com/affaan-m/everything-claude-code"
)

for url in "${REPOS[@]}"; do
    name="$(basename "$url" .git)"
    target="$SCRIPT_DIR/$name"

    if [[ -d "$target/.git" ]]; then
        echo "Updating $name..." >&2
        git -C "$target" pull --ff-only 2>&1
    else
        echo "Cloning $name..." >&2
        git clone "$url" "$target" 2>&1
    fi
done

if [[ -d "$SCRIPT_DIR/gstack" ]]; then
    echo "Syncing gstack into .claude/skills/gstack/..." >&2
    sync_reference "$SCRIPT_DIR/gstack" "$CLAUDE_DIR/skills/gstack"
    echo "gstack skills synced." >&2
fi

if [[ -d "$SCRIPT_DIR/super-ralph" ]]; then
    echo "Syncing super-ralph into .claude/skills/super-ralph/..." >&2
    sync_reference "$SCRIPT_DIR/super-ralph" "$CLAUDE_DIR/skills/super-ralph"
    echo "super-ralph skills synced." >&2
fi

echo "Setup complete. Run this script again to update." >&2
