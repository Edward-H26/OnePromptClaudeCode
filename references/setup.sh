#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOS=(
    "https://github.com/garrytan/gstack.git"
    "https://github.com/ashcastelinocs124/super-ralph.git"
    "https://github.com/affaan-m/everything-claude-code"
    "https://github.com/oil-oil/codex.git"
    "https://github.com/nextlevelbuilder/ui-ux-pro-max-skill.git"
)

prune_curated_reference_artifacts() {
    local repo_name="$1"
    local target_dir="$2"
    local rel_path

    case "$repo_name" in
        gstack)
            for rel_path in "agents/openai.yaml" "bin/gstack-global-discover" "browse/dist" "bun.lock" "docs/images" "node_modules"; do
                rm -rf "$target_dir/$rel_path"
            done
            ;;
        super-ralph)
            for rel_path in "learnings.md" "node_modules"; do
                rm -rf "$target_dir/$rel_path"
            done
            touch "$target_dir/learnings.md"
            ;;
        everything-claude-code)
            for rel_path in ".env.example" ".opencode/package-lock.json" ".opencode/plugins" "assets" "docs/ja-JP/plugins" "docs/zh-CN/plugins" "node_modules" "plugins"; do
                rm -rf "$target_dir/$rel_path"
            done
            ;;
        codex)
            for rel_path in "node_modules" ".runtime"; do
                rm -rf "$target_dir/$rel_path"
            done
            ;;
        ui-ux-pro-max-skill)
            for rel_path in "cli" "preview" "screenshots" "docs" ".github" ".claude" ".claude-plugin" ".factory" ".shared" "node_modules"; do
                rm -rf "$target_dir/$rel_path"
            done
            ;;
    esac
}

sync_reference() {
    local name="$1"
    local tmpdir="$2"
    local target="$3"

    case "$name" in
        ui-ux-pro-max-skill)
            local final_target="$SCRIPT_DIR/ui-ux-pro-max"
            echo "Syncing $name/src/ui-ux-pro-max to references/ui-ux-pro-max..." >&2
            rsync -a --delete "$tmpdir/src/ui-ux-pro-max/" "$final_target/"
            ;;
        *)
            echo "Syncing $name to references/$name..." >&2
            rsync -a --delete --exclude='.git/' "$tmpdir/" "$target/"
            prune_curated_reference_artifacts "$name" "$target"
            ;;
    esac
}

for url in "${REPOS[@]}"; do
    name="$(basename "$url" .git)"
    target="$SCRIPT_DIR/$name"
    tmpdir="$(mktemp -d)"

    echo "Fetching $name..." >&2
    git clone --depth 1 "$url" "$tmpdir" 2>&1

    sync_reference "$name" "$tmpdir" "$target"

    rm -rf "$tmpdir"
    echo "Done: $name" >&2
done

echo "" >&2
echo "Setup complete. Reference content is now under references/." >&2
echo "Review the changes and commit them to track the updated content." >&2
