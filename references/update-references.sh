#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$AGENT_DIR/.claude"
EXPECTED_SYMLINK="$HOME/.claude"

sync_reference() {
    local source_dir="$1"
    local target_dir="$2"

    mkdir -p "$target_dir"
    rsync -a --delete --exclude ".git/" "$source_dir/" "$target_dir/"
}

if [[ -L "$EXPECTED_SYMLINK" ]]; then
    ACTUAL_TARGET="$(readlink "$EXPECTED_SYMLINK")"
    if [[ "$ACTUAL_TARGET" != "$CLAUDE_DIR" ]]; then
        echo "WARNING: ~/.claude points to $ACTUAL_TARGET instead of $CLAUDE_DIR" >&2
    fi
elif [[ -d "$EXPECTED_SYMLINK" ]]; then
    echo "WARNING: ~/.claude is a directory, not a symlink to $CLAUDE_DIR" >&2
fi

REPOS=(
    "$SCRIPT_DIR/gstack"
    "$SCRIPT_DIR/super-ralph"
    "$SCRIPT_DIR/everything-claude-code"
)

for repo in "${REPOS[@]}"; do
    if [[ -d "$repo/.git" ]]; then
        echo "Updating $(basename "$repo")..." >&2
        git -C "$repo" pull --ff-only 2>&1
    else
        echo "Warning: $repo not cloned yet. Run setup.sh first." >&2
    fi
done

if [[ -d "$SCRIPT_DIR/gstack" ]]; then
    echo "Syncing gstack into .claude/skills/gstack/..." >&2
    sync_reference "$SCRIPT_DIR/gstack" "$CLAUDE_DIR/skills/gstack"
fi

if [[ -d "$SCRIPT_DIR/super-ralph" ]]; then
    echo "Syncing super-ralph into .claude/skills/super-ralph/..." >&2
    sync_reference "$SCRIPT_DIR/super-ralph" "$CLAUDE_DIR/skills/super-ralph"
fi

echo "All references updated." >&2
