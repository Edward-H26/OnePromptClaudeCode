#!/bin/bash
# Super Ralph — Uninstall Script
# Removes all Super Ralph files from Claude Code.

set -euo pipefail

RALPH_DIR="${RALPH_DIR:-$HOME/super-ralph}"
CLAUDE_DIR="$HOME/.claude"

echo "=== Super Ralph Uninstaller ==="
echo ""

rm -f "$CLAUDE_DIR/skills/super-ralph" && echo "✓ Removed skill" || true
rm -f "$CLAUDE_DIR/agents/ralph-"*.md && echo "✓ Removed agents" || true
rm -f "$CLAUDE_DIR/commands/ralph.md" "$CLAUDE_DIR/commands/super-ralph.md" && echo "✓ Removed commands" || true

echo ""
read -p "Also delete the repo at $RALPH_DIR? [y/N] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  rm -rf "$RALPH_DIR"
  echo "✓ Deleted $RALPH_DIR"
fi

echo ""
echo "=== Super Ralph uninstalled ==="
