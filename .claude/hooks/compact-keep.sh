#!/bin/bash
# PreCompact hook. Claude Code uses this script's stdout as instructions for the
# compaction summary (limit 10,000 characters per hook). A project can add its
# own lines in <project>/.claude/compact-keep.md.

input=""
[ -t 0 ] || input=$(cat 2>/dev/null)
dir=""
if command -v jq >/dev/null 2>&1; then
    dir=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
fi
dir="${dir:-${CLAUDE_PROJECT_DIR:-$PWD}}"

cat <<'EOF'
Keep these in the summary, in this order, with exact wording where it matters:
1. The user's latest request and every standing instruction given in this session. Quote the user's own words for rulings, approvals and refusals, with the date of each.
2. Decisions made and the reason for each. Say which designs the user approved and which are only proposed. List every question still open with the user, word for word.
3. Task state: what is delivered and accepted, what is in progress with its exact next step, and what has not started. Give the done criteria of each task.
4. Agents: for each running or finished agent, its id or name, role, model, what it owns, its last report, and what it is waiting for.
5. Exact identifiers: absolute file paths, commands that worked, decision and stage numbers, measured numbers, URLs.
6. Verification state: what was verified and how, with the evidence, and what is still unverified. Known failures and their causes.
7. Mistakes made and corrected in this session, so that they are not repeated.
8. The files on disk that hold the state (handoff notes, boards, decision logs, memory files), as paths. Point to them and do not copy their content.
Leave out tool output dumps, file contents that can be read again, and plans that were replaced.
EOF

extra="$dir/.claude/compact-keep.md"
if [[ -f "$extra" && ! -L "$extra" ]]; then
    echo
    echo "Project additions:"
    head -c 3000 "$extra"
fi
exit 0
