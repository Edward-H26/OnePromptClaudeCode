#!/bin/bash
# SessionStart hook for the matcher "compact". Claude Code adds this script's
# stdout to Claude's context right after a compaction, so the session continues
# from saved state and not from the summary alone. It prints, as facts:
#   1. the project's handoff file (.claude/handoff.md, HANDOFF.md or docs/HANDOFF.md),
#   2. the newest files of the project's memory folder, and the first part of the
#      newest one named *current-state* or *handoff*,
#   3. recent git commits and uncommitted changes, when the folder is a git repository.

# Context above 10,000 characters is replaced by a file path and a short preview.
LIMIT=9000

input=""
[ -t 0 ] || input=$(cat 2>/dev/null)
dir=""
if command -v jq >/dev/null 2>&1; then
    dir=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
fi
dir="${dir:-${CLAUDE_PROJECT_DIR:-$PWD}}"

mtime() { stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$1" 2>/dev/null; }

# head -c can cut a multi-byte character in half; drop the broken bytes.
valid_utf8() {
    if command -v iconv >/dev/null 2>&1; then iconv -c -f UTF-8 -t UTF-8 2>/dev/null; else cat; fi
}

{
    echo "The conversation was compacted at $(date '+%Y-%m-%d %H:%M'). The saved state of $dir follows. It was written before the compaction and can hold details that the summary lacks."

    for f in "$dir/.claude/handoff.md" "$dir/HANDOFF.md" "$dir/docs/HANDOFF.md"; do
        if [[ -f "$f" && ! -L "$f" ]]; then
            echo
            echo "Handoff file $f (modified $(mtime "$f")), first part:"
            head -c 4500 "$f"
            echo
            break
        fi
    done

    mem="$HOME/.claude/projects/$(printf '%s' "$dir" | sed 's/[^A-Za-z0-9]/-/g')/memory"
    if [[ -d "$mem" ]]; then
        newest=$(ls -t "$mem" 2>/dev/null | grep -v '^MEMORY\.md$' | head -5)
        if [[ -n "$newest" ]]; then
            echo
            echo "Memory files changed most recently in $mem:"
            while IFS= read -r name; do
                echo "- $name (modified $(mtime "$mem/$name"))"
            done <<< "$newest"
        fi
        state=$(ls -t "$mem" 2>/dev/null | grep -i -E 'current-state|handoff' | head -1)
        if [[ -n "$state" ]]; then
            echo
            echo "First part of the state file $mem/$state (modified $(mtime "$mem/$state")):"
            head -c 3000 "$mem/$state"
            echo
        fi
    fi

    if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo
        echo "Recent commits:"
        git -C "$dir" log --oneline -8 2>/dev/null
        changes=$(git -C "$dir" status --short 2>/dev/null | head -15)
        if [[ -n "$changes" ]]; then
            echo "Uncommitted changes (first 15):"
            echo "$changes"
        fi
    fi
} | head -c "$LIMIT" | valid_utf8
exit 0
