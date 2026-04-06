#!/bin/bash
# Super Ralph — Install Script
# Installs the entire Super Ralph agentic loop into Claude Code.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ashcastelinocs124/super-ralph/main/install.sh | bash
#   — or —
#   git clone https://github.com/ashcastelinocs124/super-ralph.git && cd super-ralph && bash install.sh

set -euo pipefail

RALPH_DIR="${RALPH_DIR:-$HOME/super-ralph}"
CLAUDE_DIR="$HOME/.claude"

echo "=== Super Ralph Installer ==="
echo ""

# Step 1: Clone if not already present
if [ -d "$RALPH_DIR/.git" ]; then
  echo "[1/3] Super Ralph repo found at $RALPH_DIR — pulling latest..."
  git -C "$RALPH_DIR" pull --ff-only 2>/dev/null || echo "  (pull skipped — local changes detected)"
else
  echo "[1/3] Cloning Super Ralph..."
  git clone https://github.com/ashcastelinocs124/super-ralph.git "$RALPH_DIR"
fi

# Step 2: Link skill, agents, and commands into Claude Code
echo "[2/3] Installing into Claude Code..."
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands"

# Skill (orchestrator)
ln -sf "$RALPH_DIR/skills/super-ralph" "$CLAUDE_DIR/skills/super-ralph"
echo "  ✓ Skill: super-ralph"

# Agents
for f in "$RALPH_DIR"/agents/ralph-*.md; do
  ln -sf "$f" "$CLAUDE_DIR/agents/$(basename "$f")"
  echo "  ✓ Agent: $(basename "$f" .md)"
done

# Commands (/super-ralph and /ralph)
for f in "$RALPH_DIR"/commands/*.md; do
  ln -sf "$f" "$CLAUDE_DIR/commands/$(basename "$f")"
  echo "  ✓ Command: /$(basename "$f" .md)"
done

# Step 3: Verify
echo "[3/3] Verifying installation..."
ERRORS=0

[ -f "$CLAUDE_DIR/skills/super-ralph/SKILL.md" ] && echo "  ✓ Skill installed" || { echo "  ✗ Skill missing"; ERRORS=$((ERRORS+1)); }
[ -f "$CLAUDE_DIR/agents/ralph-judge.md" ] && echo "  ✓ Agents installed" || { echo "  ✗ Agents missing"; ERRORS=$((ERRORS+1)); }
[ -f "$CLAUDE_DIR/commands/ralph.md" ] && echo "  ✓ Commands installed" || { echo "  ✗ Commands missing"; ERRORS=$((ERRORS+1)); }

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "=== Super Ralph installed successfully ==="
  echo ""
  echo "Usage:"
  echo "  /ralph <query>        — oneshot: zero questions, auto-accept permissions, Ralph decides everything"
  echo "  /super-ralph <query>  — asks oneshot vs brainstorm, you choose how much control to keep"
else
  echo "=== Installation had errors — check above ==="
fi
