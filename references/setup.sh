#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOS=(
    "https://github.com/garrytan/gstack.git"
    "https://github.com/ashcastelinocs124/super-ralph.git"
    "https://github.com/affaan-m/everything-claude-code"
)

for url in "${REPOS[@]}"; do
    name="$(basename "$url" .git)"
    target="$SCRIPT_DIR/$name"
    tmpdir="$(mktemp -d)"

    echo "Fetching $name..." >&2
    git clone --depth 1 "$url" "$tmpdir" 2>&1

    echo "Syncing $name to references/$name..." >&2
    rsync -a --delete --exclude='.git/' "$tmpdir/" "$target/"

    rm -rf "$tmpdir"
    echo "Done: $name" >&2
done

echo "" >&2
echo "Setup complete. Reference content is now under references/." >&2
echo "Review the changes and commit them to track the updated content." >&2
