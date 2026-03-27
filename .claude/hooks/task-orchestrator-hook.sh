#!/bin/bash
set -e

command -v jq >/dev/null 2>&1 || exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/patterns.sh"
source "$SCRIPT_DIR/lib/plugin-state.sh"

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || echo "")
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

prompt_matches() {
    local pattern="$1"
    printf "%s\n" "$PROMPT_LOWER" | grep -qiE "$pattern"
}

HAS_EXPLICIT_IMPLEMENTATION=false
if prompt_matches "$EXPLICIT_IMPLEMENTATION_PATTERN"; then
    HAS_EXPLICIT_IMPLEMENTATION=true
elif prompt_matches "$WORKFLOW_IMPLEMENTATION_PATTERN"; then
    HAS_EXPLICIT_IMPLEMENTATION=true
fi

IS_PURE_INFORMATIONAL=false
if prompt_matches "$PURE_QUESTION_PATTERN"; then
    if [[ "$HAS_EXPLICIT_IMPLEMENTATION" != "true" ]] &&
        ! prompt_matches "$CODING_PATTERN" &&
        ! prompt_matches "$CODING_CONTEXT_PATTERN"; then
        IS_PURE_INFORMATIONAL=true
    fi
fi

IS_ANALYSIS_ONLY=false
if prompt_matches "$ANALYSIS_PATTERN"; then
    if [[ "$HAS_EXPLICIT_IMPLEMENTATION" != "true" ]]; then
        IS_ANALYSIS_ONLY=true
    fi
fi

if [[ "$IS_PURE_INFORMATIONAL" == "true" ]] && [[ "$IS_ANALYSIS_ONLY" != "true" ]]; then
    exit 0
fi

if [[ "$IS_ANALYSIS_ONLY" == "true" ]]; then
cat << 'EOF'

================================================================================
TASK ORCHESTRATOR ACTIVE (Analysis Mode)
================================================================================

This appears to be an analysis or research task.
Focus on exploration, source-backed findings, and clear recommendations.

EOF
exit 0
fi

PLUGIN_LINES=""

append_plugin_line() {
    local plugin_name="$1"
    local description="$2"

    if plugin_is_available "$plugin_name"; then
        PLUGIN_LINES="${PLUGIN_LINES}- ${description}\n"
    fi
}

append_plugin_line "context7@claude-plugins-official" "context7 for live documentation lookup"
append_plugin_line "code-review@claude-plugins-official" "code-review for targeted review passes"
append_plugin_line "code-simplifier@claude-plugins-official" "code-simplifier for cleanup passes"
append_plugin_line "feature-dev@claude-plugins-official" "feature-dev for code exploration and architecture agents"
append_plugin_line "frontend-design@claude-plugins-official" "frontend-design for stronger UI implementation guidance"
append_plugin_line "github@claude-plugins-official" "github for repository and pull request workflows"
append_plugin_line "playwright@claude-plugins-official" "playwright for browser workflows"
append_plugin_line "figma@claude-plugins-official" "figma for design workflows"
append_plugin_line "mongodb@mongodb-plugins" "mongodb for MongoDB-specific MCP and skill flows"
append_plugin_line "superpowers@claude-plugins-official" "superpowers for additional agent and review workflows"

if [[ -n "$PLUGIN_LINES" ]]; then
    PLUGIN_SECTION="Installed plugins worth using when relevant:\n${PLUGIN_LINES}"
else
    PLUGIN_SECTION="Installed plugin availability varies by local state.\n"
fi

printf '%b\n' "================================================================================
TASK ORCHESTRATOR ACTIVE
================================================================================

Use this as concise guidance for coding tasks:

1. Inspect the relevant files before editing.
2. Identify the task domain and activate the right skills.
3. Keep edits minimal and aligned with existing patterns.
4. Verify with the smallest useful set of checks.
5. For UI work, use available browser tooling when feasible.

Helpful skills in this repo:
- search-first for repo exploration before editing
- professional-research-writing for docs and explanations
- backend-dev-guidelines for backend code
- frontend-dev-guidelines for React and TypeScript code
- ui-styling for component styling and layout work
- systematic-debugging for failures and regressions
- verification-loop for structured verification
- security-review and security-scan for auth, secrets, permissions, and workflow audits
- e2e-testing for browser-driven verification work
- skill-developer for hooks, skills, and workflow configuration

Vendored workflows:
- /super-ralph for the bundled autonomous multi-agent workflow

$PLUGIN_SECTION
Codex is optional:
- If auto-codex-trigger ran, review its output before finishing.
- If it did not run, continue normally. Do not invent missing mandatory steps.

================================================================================
"
