#!/bin/bash
set -e

command -v jq >/dev/null 2>&1 || exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/patterns.sh"

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || echo "")
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

HAS_EXPLICIT_IMPLEMENTATION=false
if echo "$PROMPT_LOWER" | grep -qiE "$EXPLICIT_IMPLEMENTATION_PATTERN"; then
    HAS_EXPLICIT_IMPLEMENTATION=true
elif echo "$PROMPT_LOWER" | grep -qiE "$WORKFLOW_IMPLEMENTATION_PATTERN"; then
    HAS_EXPLICIT_IMPLEMENTATION=true
fi

IS_ANALYSIS_ONLY=false
if echo "$PROMPT_LOWER" | grep -qiE "$ANALYSIS_PATTERN"; then
    if [[ "$HAS_EXPLICIT_IMPLEMENTATION" != "true" ]]; then
        IS_ANALYSIS_ONLY=true
    fi
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

cat << 'EOF'

================================================================================
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

Installed plugins worth using when relevant:
- context7 for live documentation lookup
- code-review and code-simplifier for targeted review and cleanup passes
- frontend-design for stronger UI implementation guidance
- playwright and figma for browser and design workflows
- mongodb for MongoDB-specific MCP and skill flows

Codex is optional:
- If auto-codex-trigger ran, review its output before finishing.
- If it did not run, continue normally. Do not invent missing mandatory steps.

================================================================================
EOF
