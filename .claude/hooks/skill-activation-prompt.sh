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

if command -v python3 >/dev/null 2>&1; then
    MATCHES=$(PROMPT_LOWER="$PROMPT_LOWER" RULES_PATH="$RULES_PATH" python3 - <<'PYEOF'
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
    MATCHES=$(jq -r --arg prompt "$PROMPT_LOWER" '
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
    ' "$RULES_PATH" 2>/dev/null)
fi

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
