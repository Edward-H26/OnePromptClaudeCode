#!/usr/bin/env bash
# One-time post-clone installer. Idempotent. Safe to re-run.
#
# Makes this repo the canonical source for ~/.claude/hooks, ~/.claude/skills, and
# ~/.claude/settings.json so that Claude Code sessions in OTHER projects also pick
# up the repo's hooks, skills, and global env vars. Existing real files are backed
# up to ~/.claude/.backup-<ts>/.
#
# Usage:
#   bash scripts/install.sh            # dry-run: show what would change
#   bash scripts/install.sh --check    # dry-run: show what would change
#   bash scripts/install.sh --apply    # apply with backup
#   bash scripts/install.sh --router   # register the skill router globally
#   bash scripts/install.sh --revert   # restore from the most recent backup

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
        --router) MODE="router" ;;
        --revert) MODE="revert" ;;
        --help|-h)
            sed -n "2,14p" "${BASH_SOURCE[0]}" | sed "s/^# //;s/^#//"
            exit 0
            ;;
        *) echo "Unknown flag: $arg" >&2; exit 2 ;;
    esac
done

[[ "$REPO_CLAUDE/hooks" == "$HOME_CLAUDE/hooks" ]] && { echo "install.sh: repo IS ~/.claude; nothing to deploy." ; exit 0 ; }
[[ -d "$REPO_CLAUDE/hooks" && -d "$REPO_CLAUDE/skills" && -f "$REPO_CLAUDE/settings.json" ]] || { echo "install.sh: $REPO_CLAUDE does not look like a Claude Code config root (missing hooks/, skills/, or settings.json)." >&2 ; exit 1 ; }

# --router is the "keep my own ~/.claude/settings.json" path: link the skills so
# Claude Code can see them from any project, then register the router there with
# this checkout's absolute path. The path is machine-specific by nature, which is
# why it is written here and never into the tracked .claude/settings.json.
if [[ "$MODE" == "router" ]]; then
    HOOK="$REPO_CLAUDE/hooks/task-orchestrator-hook.sh"
    USER_SETTINGS="$HOME_CLAUDE/settings.json"
    [[ -x "$HOOK" ]] || { echo "install.sh: $HOOK is missing or not executable." >&2 ; exit 1 ; }
    command -v python3 >/dev/null 2>&1 || { echo "install.sh: --router needs python3." >&2 ; exit 1 ; }

    if [[ ! -e "$HOME_CLAUDE/skills" ]]; then
        mkdir -p "$HOME_CLAUDE"
        ln -snf "$REPO_CLAUDE/skills" "$HOME_CLAUDE/skills"
        echo "install.sh: linked ~/.claude/skills -> $REPO_CLAUDE/skills"
    elif [[ ! -L "$HOME_CLAUDE/skills" || "$(readlink "$HOME_CLAUDE/skills")" != "$REPO_CLAUDE/skills" ]]; then
        echo "install.sh: ~/.claude/skills already exists and does not point here."
        echo "install.sh: run --apply to back it up and relink, or fix it by hand."
    fi

    if [[ -L "$USER_SETTINGS" ]]; then
        echo "install.sh: $USER_SETTINGS is a symlink, so --router cannot add a machine-local path." >&2
        echo "install.sh: use --revert first if you want to keep your own settings file." >&2
        exit 1
    fi
    [[ -f "$USER_SETTINGS" ]] || { mkdir -p "$HOME_CLAUDE" ; printf '{}\n' > "$USER_SETTINGS" ; }

    HOOK_PATH="$HOOK" SETTINGS_PATH="$USER_SETTINGS" python3 - <<'PY'
import json
import os
from collections import OrderedDict

hook = os.environ["HOOK_PATH"]
path = os.environ["SETTINGS_PATH"]
# Stand down when the project registers the router itself, so the config repo
# does not print the activation block twice.
command = ('[ -x "${CLAUDE_PROJECT_DIR:-$PWD}/.claude/hooks/task-orchestrator-hook.sh" ] '
           f'|| "{hook}"')

with open(path, encoding="utf-8") as f:
    data = json.load(f, object_pairs_hook=OrderedDict)

groups = data.setdefault("hooks", OrderedDict()).setdefault("UserPromptSubmit", [])
existing = [h for g in groups for h in g.get("hooks", [])
            if "task-orchestrator-hook.sh" in h.get("command", "")]
if existing:
    for hook_entry in existing:      # refresh the path in case the checkout moved
        hook_entry["command"] = command
        hook_entry.setdefault("timeout", 10)
    action = "refreshed"
else:
    groups.append(OrderedDict([("hooks", [OrderedDict([
        ("type", "command"), ("command", command), ("timeout", 10)])])]))
    action = "registered"

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
print(f"install.sh: router {action} in {path}")
print(f"install.sh: -> {hook}")
PY
    exit 0
fi

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

if [[ "$MODE" == "revert" ]]; then
    LATEST="$(ls -1dt "$HOME_CLAUDE"/.backup-* 2>/dev/null | head -1 || true)"
    [[ -n "$LATEST" ]] || { echo "install.sh: no backup directory found in $HOME_CLAUDE" >&2 ; exit 1 ; }
    echo "install.sh: restoring from $LATEST"
    for f in hooks skills settings.json; do
        if [[ -L "$LATEST/$f" ]]; then
            echo "install.sh: REFUSING to restore $LATEST/$f because it is a symlink (potential tampering)." >&2
            continue
        fi
        if [[ -e "$LATEST/$f" ]]; then
            [[ -L "$HOME_CLAUDE/$f" ]] && rm -f "$HOME_CLAUDE/$f"
            mv "$LATEST/$f" "$HOME_CLAUDE/$f"
            echo "install.sh: restored ~/.claude/$f"
        fi
    done
    rmdir "$LATEST" 2>/dev/null || true
    rm -f "$MARKER_FILE"
    echo "install.sh: revert complete."
    exit 0
fi

mkdir -p "$HOME_CLAUDE" "$MARKER_DIR"

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

HOOKS_STATE=$(check_target "$HOME_CLAUDE/hooks" "$REPO_CLAUDE/hooks")
# Claude Code only discovers user-scope skills under ~/.claude/skills, so without
# this link a fresh clone gets the hooks and settings but none of the skills.
SKILLS_STATE=$(check_target "$HOME_CLAUDE/skills" "$REPO_CLAUDE/skills")
SETTINGS_STATE=$(check_target "$HOME_CLAUDE/settings.json" "$REPO_CLAUDE/settings.json")

echo "install.sh: ~/.claude/hooks -> $HOOKS_STATE"
echo "install.sh: ~/.claude/skills -> $SKILLS_STATE"
echo "install.sh: ~/.claude/settings.json -> $SETTINGS_STATE"

if [[ "$HOOKS_STATE" == "ok" && "$SKILLS_STATE" == "ok" && "$SETTINGS_STATE" == "ok" ]]; then
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

deploy_target "$HOME_CLAUDE/hooks" "$REPO_CLAUDE/hooks" "hooks" "$HOOKS_STATE"
deploy_target "$HOME_CLAUDE/skills" "$REPO_CLAUDE/skills" "skills" "$SKILLS_STATE"
deploy_target "$HOME_CLAUDE/settings.json" "$REPO_CLAUDE/settings.json" "settings.json" "$SETTINGS_STATE"

touch "$MARKER_FILE"

echo ""
echo "install.sh: deploy complete."
echo "install.sh: marker: $MARKER_FILE"
echo "install.sh: backup: $BACKUP_DIR (empty if nothing was replaced)"
echo "install.sh: revert via: bash scripts/install.sh --revert"
