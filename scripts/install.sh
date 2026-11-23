#!/usr/bin/env bash
# One-time post-clone installer. Idempotent. Safe to re-run.
#
# Makes this repo the canonical source for ~/.claude: settings.json links to the
# tracked user-scope .claude/settings.user.json, and hooks, skills, agents,
# commands, CLAUDE.md, statusline.sh and output-styles link to their copies here,
# so every project runs the same setup and any change Claude Code saves to user
# settings lands in this checkout. Existing real files are backed up to
# ~/.claude/.backup-<ts>/.
#
# Usage:
#   bash scripts/install.sh            # dry-run: show what would change
#   bash scripts/install.sh --check    # dry-run: show what would change
#   bash scripts/install.sh --apply    # apply with backup

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
REPO_CLAUDE="$REPO_ROOT/.claude"
HOME_CLAUDE="$HOME/.claude"
MARKER_DIR="$REPO_CLAUDE/runtime"
MARKER_FILE="$MARKER_DIR/.deployed-to-home"

MODE="check"
for arg in "$@"; do
    case "$arg" in
        --check) MODE="check" ;;
        --apply) MODE="apply" ;;
        --help|-h)
            sed -n "2,14p" "${BASH_SOURCE[0]}" | sed "s/^# //;s/^#//"
            exit 0
            ;;
        *) echo "Unknown flag: $arg" >&2; exit 2 ;;
    esac
done

[[ "$REPO_CLAUDE/hooks" == "$HOME_CLAUDE/hooks" ]] && { echo "install.sh: repo IS ~/.claude; nothing to deploy." ; exit 0 ; }
[[ -d "$REPO_CLAUDE/hooks" && -d "$REPO_CLAUDE/skills" && -f "$REPO_CLAUDE/settings.json" && -f "$REPO_CLAUDE/settings.user.json" ]] || { echo "install.sh: $REPO_CLAUDE does not look like a Claude Code config root (missing hooks/, skills/, settings.json, or settings.user.json)." >&2 ; exit 1 ; }

if [[ "$MODE" != "check" ]]; then
    mkdir -p "$MARKER_DIR"
    LOCK_DIR="$MARKER_DIR/install.sh.lock"
    LOCK_WAITS=0
    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        if [[ $LOCK_WAITS -ge 30 ]]; then
            echo "install.sh: another install.sh is running (lock at $LOCK_DIR). Wait or remove the lock." >&2
            exit 1
        fi
        sleep 1
        LOCK_WAITS=$((LOCK_WAITS + 1))
    done
    trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
fi

mkdir -p "$HOME_CLAUDE" "$MARKER_DIR"

# Each entry is "<name under ~/.claude>:<name under this repo's .claude>".
# settings.json takes the user-scope file because .claude/settings.json is this
# repo's own project settings. Claude Code only discovers user-scope skills under
# ~/.claude/skills, so without that link no skill here loads in other projects.
LINKS=(
    "hooks:hooks"
    "skills:skills"
    "settings.json:settings.user.json"
    "statusline.sh:statusline.sh"
    "output-styles:output-styles"
    "CLAUDE.md:CLAUDE.md"
    "agents:agents"
    "commands:commands"
)

check_target() {
    local home_path="$1"
    local repo_path="$2"
    if [[ -L "$home_path" && "$(readlink "$home_path")" == "$repo_path" ]]; then
        echo "ok"
    elif [[ -e "$home_path" || -L "$home_path" ]]; then
        echo "drift"
    else
        echo "missing"
    fi
}

STATES=()
ALL_OK=true
for link in "${LINKS[@]}"; do
    state=$(check_target "$HOME_CLAUDE/${link%%:*}" "$REPO_CLAUDE/${link#*:}")
    STATES+=("$state")
    [[ "$state" == "ok" ]] || ALL_OK=false
    echo "install.sh: ~/.claude/${link%%:*} -> $state"
done

if [[ "$ALL_OK" == "true" ]]; then
    if [[ "$MODE" == "apply" ]]; then
        touch "$MARKER_FILE"
    fi
    echo "install.sh: already deployed. Nothing to do."
    exit 0
fi

if [[ "$MODE" == "check" ]]; then
    echo "install.sh: --check mode. Re-run with --apply to apply."
    exit 0
fi

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME_CLAUDE/.backup-$TS"
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

deploy_target() {
    local home_path="$1"
    local repo_path="$2"
    local label="$3"
    local state="$4"
    case "$state" in
        ok) return 0 ;;
        drift)
            mv "$home_path" "$BACKUP_DIR/$label"
            echo "install.sh: backed up ~/.claude/$label -> $BACKUP_DIR/$label"
            ;;
    esac
    ln -snf "$repo_path" "$home_path"
    echo "install.sh: linked ~/.claude/$label -> $repo_path"
}

for i in "${!LINKS[@]}"; do
    link="${LINKS[$i]}"
    deploy_target "$HOME_CLAUDE/${link%%:*}" "$REPO_CLAUDE/${link#*:}" "${link%%:*}" "${STATES[$i]}"
done

touch "$MARKER_FILE"

echo ""
echo "install.sh: deploy complete."
echo "install.sh: marker: $MARKER_FILE"
echo "install.sh: backup: $BACKUP_DIR (empty if nothing was replaced)"
