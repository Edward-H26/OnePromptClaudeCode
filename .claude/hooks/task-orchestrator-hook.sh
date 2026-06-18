#!/bin/bash
set -e

command -v jq >/dev/null 2>&1 || exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/patterns.sh"
source "$SCRIPT_DIR/lib/plugin-state.sh"
source "$SCRIPT_DIR/lib/utils.sh"
CLAUDE_HOME_DIR="$(resolve_claude_home)"
export CLAUDE_CONFIG_DIR="$CLAUDE_HOME_DIR"

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || echo "")
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

prompt_matches() {
    local pattern="$1"
    printf "%s\n" "$PROMPT_LOWER" | grep -qiE "$pattern"
}

security_review_needed() {
    prompt_matches "(^|[^[:alnum:]_])(auth|authentication|authorization|secret|secrets|token|tokens|credential|credentials|api key|permission|permissions|database|sql|query|queries|file i/o|filesystem|external integration|mcp|webhook|oauth|session|cookie|cookies|input validation|endpoint|endpoints)([^[:alnum:]_]|$)"
}

print_security_review_reminder() {
    cat <<'EOF'
================================================================================
SECURITY REVIEW REMINDER
================================================================================
This task appears to touch auth, secrets, input validation, API endpoints,
permissions, database queries, file I/O, or external integrations.
Use /security-review when the final change would benefit from a security pass.
================================================================================

EOF
}

print_skill_activation_check() {
    local rules_path="$CLAUDE_HOME_DIR/skills/skill-rules.json"
    [[ -f "$rules_path" ]] || return 0

    local matches=""
    if command -v python3 >/dev/null 2>&1; then
        matches=$(PROMPT_LOWER="$PROMPT_LOWER" RULES_PATH="$rules_path" python3 - <<'PYEOF'
import json
import os
import re
import sys

prompt = os.environ.get("PROMPT_LOWER", "").lower()
rules_path = os.environ.get("RULES_PATH", "")

try:
    with open(rules_path) as f:
        data = json.load(f)
except Exception:
    sys.exit(0)

def keyword_hit(kw, text):
    kw_lower = kw.lower()
    if kw_lower not in text:
        return False
    pat = r"(?:^|[^a-z0-9_])" + re.escape(kw_lower) + r"(?:[^a-z0-9_]|$)"
    return re.search(pat, text) is not None

def pattern_hit(pat, text):
    try:
        return re.search(pat, text, re.IGNORECASE) is not None
    except re.error:
        return False

lines = []
for name, rule in data.get("skills", {}).items():
    pt = rule.get("promptTriggers")
    if pt is None and not rule.get("alwaysActive", False):
        continue
    priority = rule.get("priority", "low")
    keywords = (pt or {}).get("keywords", [])
    patterns = (pt or {}).get("intentPatterns", [])
    excludes = (pt or {}).get("keywordExclusions", [])

    always = rule.get("alwaysActive", False)
    matched = False
    if always:
        matched = True
    else:
        for kw in keywords:
            if keyword_hit(kw, prompt):
                matched = True
                break
        if not matched:
            for p in patterns:
                if pattern_hit(p, prompt):
                    matched = True
                    break

    if not matched:
        continue

    if excludes:
        excluded = False
        for ek in excludes:
            if keyword_hit(ek, prompt):
                excluded = True
                break
        if excluded:
            continue

    lines.append(f"{priority}|{name}")

sys.stdout.write("\n".join(lines))
PYEOF
)
    else
        matches=$(jq -r --arg prompt "$PROMPT_LOWER" '
            def regex_escape:
                gsub("([][(){}.*+?^$|\\\\-])"; "\\\\\\1");
            def keyword_match($prompt; $keyword):
                ("(^|[^[:alnum:]_])" + ($keyword | ascii_downcase | regex_escape) + "([^[:alnum:]_]|$)") as $pattern |
                try ($prompt | test($pattern; "i")) catch false;
            .skills | to_entries[] |
            select(.value.promptTriggers != null) |
            select(
                (.value.alwaysActive // false) or
                (
                    ((.value.promptTriggers.keywords // []) | any(. as $kw | keyword_match($prompt; $kw))) or
                    ((.value.promptTriggers.intentPatterns // []) | any(. as $pat | try ($prompt | test($pat; "i")) catch false))
                )
            ) |
            "\(.value.priority)|\(.key)"
        ' "$rules_path" 2>/dev/null)
    fi

    [[ -z "$matches" ]] && return 0

    local critical=""
    local high=""
    local medium=""
    local low=""
    while IFS='|' read -r priority name; do
        case "$priority" in
            critical) critical="${critical}  -> ${name}\n" ;;
            high)     high="${high}  -> ${name}\n" ;;
            medium)   medium="${medium}  -> ${name}\n" ;;
            low)      low="${low}  -> ${name}\n" ;;
        esac
    done <<< "$matches"

    local output=""
    output="${output}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    output="${output}SKILL ACTIVATION CHECK\n"
    output="${output}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
    if [[ -n "$critical" ]]; then
        output="${output}CRITICAL SKILLS (REQUIRED):\n${critical}\n"
    fi
    if [[ -n "$high" ]]; then
        output="${output}RECOMMENDED SKILLS:\n${high}\n"
    fi
    if [[ -n "$medium" ]]; then
        output="${output}SUGGESTED SKILLS:\n${medium}\n"
    fi
    if [[ -n "$low" ]]; then
        output="${output}OPTIONAL SKILLS:\n${low}\n"
    fi
    output="${output}ACTION: Use Skill tool BEFORE responding\n"
    output="${output}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf '%b\n' "$output"
}

print_clarify_first() {
    local word_count
    word_count=$(printf "%s" "$PROMPT" | tr -s '[:space:]' ' ' | sed 's/^ //;s/ $//' | grep -o ' ' | wc -l | tr -d ' ')
    word_count=$((word_count + 1))
    [[ -z "$PROMPT" ]] && word_count=0

    local is_vague=false
    if [[ "$word_count" -gt 0 && "$word_count" -le 5 ]]; then
        is_vague=true
    fi
    local trimmed
    trimmed=$(printf "%s" "$PROMPT_LOWER" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/[[:punct:]]*$//')
    if [[ "$trimmed" =~ ^(fix|update|change|改|弄)$ ]]; then
        is_vague=true
    fi

    if [[ "$is_vague" == "true" ]]; then
        printf '%s\n' "CLARIFY FIRST: request looks ambiguous, ask 1-2 clarifying questions before implementing."
    fi
}

run_skill_and_clarify() {
    print_skill_activation_check
    print_clarify_first
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

if prompt_matches "$MEMORY_OR_PREFERENCE_PATTERN" &&
    [[ "$HAS_EXPLICIT_IMPLEMENTATION" != "true" ]]; then
    exit 0
fi

if [[ "$IS_PURE_INFORMATIONAL" == "true" ]] && [[ "$IS_ANALYSIS_ONLY" != "true" ]]; then
    exit 0
fi

if [[ "$IS_ANALYSIS_ONLY" == "true" ]]; then
if security_review_needed; then
    print_security_review_reminder
fi
cat << 'EOF'

================================================================================
TASK ORCHESTRATOR ACTIVE (Analysis Mode)
================================================================================

This appears to be an analysis or research task.
Focus on exploration, source-backed findings, and clear recommendations.

EOF
run_skill_and_clarify
exit 0
fi

if security_review_needed; then
    print_security_review_reminder
fi

PLUGIN_LINES=""
AVAILABLE_PLUGINS="$(plugin_available_names 2>/dev/null || true)"

append_plugin_line() {
    local plugin_name="$1"
    local description="$2"

    if printf "%s\n" "$AVAILABLE_PLUGINS" | grep -Fxq "$plugin_name"; then
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
- backend-dev-guidelines for backend code
- frontend-dev-guidelines for React and TypeScript code
- ui-styling for component styling and layout work
- code-refactor for bulk renames and pattern replacement
- investigate for systematic root-cause debugging
- review for staff-level code review via /review-staff
- qa, qa-only, and webapp-testing for browser verification
- refine for the evaluator-optimizer loop

$PLUGIN_SECTION
Evaluator-optimizer loop:
- After the implementation is complete and all checks pass, run /refine to close the loop with a generate to critique to apply to re-critique pass (bounded at 3 rounds).
- Skip /refine only for trivial one-line changes or when the task explicitly forbids it.

================================================================================
"

run_skill_and_clarify
