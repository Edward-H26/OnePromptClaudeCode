#!/bin/bash
# Super Ralph — Auto-Permission Setup
# Merges Super Ralph's required tool permissions into your project's .claude/settings.json
# so sub-agents never block on permission prompts.
#
# Usage:
#   bash path/to/super-ralph/scripts/setup-permissions.sh [project-dir]
#   (defaults to current directory if no argument given)

set -euo pipefail

PROJECT_DIR="${1:-.}"
SETTINGS_DIR="$PROJECT_DIR/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# Ralph's required permissions
RALPH_PERMISSIONS=(
  'Bash(mkdir:*)'
  'Bash(find:*)'
  'Bash(ls:*)'
  'Bash(cat:*)'
  'Bash(rm:*)'
  'Bash(cp:*)'
  'Bash(mv:*)'
  'Bash(touch:*)'
  'Bash(chmod:*)'
  'Bash(cd:*)'
  'Bash(pwd:*)'
  'Bash(echo:*)'
  'Bash(head:*)'
  'Bash(tail:*)'
  'Bash(wc:*)'
  'Bash(diff:*)'
  'Bash(sort:*)'
  'Bash(uniq:*)'
  'Bash(grep:*)'
  'Bash(sed:*)'
  'Bash(awk:*)'
  'Bash(git:*)'
  'Bash(python*)'
  'Bash(pip*)'
  'Bash(node*)'
  'Bash(npm*)'
  'Bash(npx*)'
  'Bash(yarn*)'
  'Bash(pnpm*)'
  'Bash(bun*)'
  'Bash(cargo*)'
  'Bash(go *)'
  'Bash(make*)'
  'Bash(pytest*)'
  'Bash(jest*)'
  'Bash(vitest*)'
  'Bash(mocha*)'
  'Bash(ruby*)'
  'Bash(bundle*)'
  'Bash(rspec*)'
  'Bash(swift*)'
  'Bash(rustc*)'
  'Bash(gcc*)'
  'Bash(g++*)'
  'Bash(clang*)'
  'Bash(java*)'
  'Bash(mvn*)'
  'Bash(gradle*)'
  'Bash(dotnet*)'
  'Bash(docker*)'
  'Read'
  'Edit'
  'Write'
  'Glob'
  'Grep'
  'Agent'
)

# Ensure .claude directory exists
mkdir -p "$SETTINGS_DIR"

if [ ! -f "$SETTINGS_FILE" ]; then
  # No settings file — create one from scratch
  echo '{"permissions":{"allow":[]}}' > "$SETTINGS_FILE"
fi

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required. Install with: brew install jq (macOS) or apt-get install jq (Linux)"
  exit 1
fi

# Build JSON array of permissions to add
PERMS_JSON=$(printf '%s\n' "${RALPH_PERMISSIONS[@]}" | jq -R . | jq -s .)

# Merge into existing settings (deduplicate)
UPDATED=$(jq --argjson new_perms "$PERMS_JSON" '
  .permissions //= {} |
  .permissions.allow //= [] |
  .permissions.allow = (.permissions.allow + $new_perms | unique)
' "$SETTINGS_FILE")

echo "$UPDATED" > "$SETTINGS_FILE"

ADDED_COUNT=$(echo "$PERMS_JSON" | jq length)
echo "Super Ralph permissions configured in $SETTINGS_FILE"
echo "Added/verified $ADDED_COUNT tool permission rules."
echo ""
echo "Sub-agents will now run without permission prompts."
