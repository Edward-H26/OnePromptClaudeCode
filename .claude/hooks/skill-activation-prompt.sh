#!/bin/bash
set -e
command -v jq >/dev/null 2>&1 || { echo "WARNING: jq not found, skipping skill activation" >&2; exit 0; }

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || echo "")

if [[ -z "$PROMPT" ]]; then
    exit 0
fi

PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"
CLAUDE_HOME_DIR="$(resolve_claude_home)"
RULES_PATH="$CLAUDE_HOME_DIR/skills/skill-rules.json"
if [[ ! -f "$RULES_PATH" ]]; then
    exit 0
fi

MATCHES=$(jq -r --arg prompt "$PROMPT_LOWER" '
    def regex_escape:
        gsub("([][(){}.*+?^$|\\\\-])"; "\\\\\\1");
    def keyword_match($prompt; $keyword):
        ("(^|[^[:alnum:]_])" + ($keyword | ascii_downcase | regex_escape) + "([^[:alnum:]_]|$)") as $pattern |
        try ($prompt | test($pattern; "i")) catch false;
    .skills | to_entries[] |
    select(.value.promptTriggers != null) |
    {
        name: .key,
        priority: .value.priority,
        keywords: (.value.promptTriggers.keywords // []),
        patterns: (.value.promptTriggers.intentPatterns // []),
        excludeKeywords: (.value.promptTriggers.keywordExclusions // []),
        alwaysActive: (.value.alwaysActive // false)
    } |
    select(
        (.alwaysActive == true) or
        (
            (
                (.keywords | any(. as $kw | keyword_match($prompt; $kw))) or
                (.patterns | any(. as $pat | try ($prompt | test($pat; "i")) catch false))
            ) and
            (
                (.excludeKeywords | length == 0) or
                (.excludeKeywords | all(. as $ek | keyword_match($prompt; $ek) | not))
            )
        )
    ) |
    "\(.priority)|\(.name)"
' "$RULES_PATH" 2>/dev/null)

if [[ -z "$MATCHES" ]]; then
    exit 0
fi

CRITICAL=""
HIGH=""
MEDIUM=""
LOW=""

while IFS='|' read -r priority name; do
    case "$priority" in
        critical) CRITICAL="${CRITICAL}  -> ${name}\n" ;;
        high)     HIGH="${HIGH}  -> ${name}\n" ;;
        medium)   MEDIUM="${MEDIUM}  -> ${name}\n" ;;
        low)      LOW="${LOW}  -> ${name}\n" ;;
    esac
done <<< "$MATCHES"

OUTPUT=""
OUTPUT="${OUTPUT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
OUTPUT="${OUTPUT}SKILL ACTIVATION CHECK\n"
OUTPUT="${OUTPUT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

if [[ -n "$CRITICAL" ]]; then
    OUTPUT="${OUTPUT}CRITICAL SKILLS (REQUIRED):\n${CRITICAL}\n"
fi
if [[ -n "$HIGH" ]]; then
    OUTPUT="${OUTPUT}RECOMMENDED SKILLS:\n${HIGH}\n"
fi
if [[ -n "$MEDIUM" ]]; then
    OUTPUT="${OUTPUT}SUGGESTED SKILLS:\n${MEDIUM}\n"
fi
if [[ -n "$LOW" ]]; then
    OUTPUT="${OUTPUT}OPTIONAL SKILLS:\n${LOW}\n"
fi

OUTPUT="${OUTPUT}ACTION: Use Skill tool BEFORE responding\n"
OUTPUT="${OUTPUT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

printf '%b\n' "$OUTPUT"
