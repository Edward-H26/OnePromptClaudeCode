#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

EXECUTE=false
ARCHIVE_DIR=""
STALE_DAYS_LOCKS=30
STALE_DAYS_TRANSCRIPTS=60

for arg in "$@"; do
    case "$arg" in
        --execute) EXECUTE=true ;;
        --archive=*) ARCHIVE_DIR="${arg#--archive=}" ;;
        --help|-h)
            cat <<EOF
Usage: $0 [options]

Dry-run by default. Nothing is deleted unless --execute is passed.

Options:
  --execute                Apply the planned changes (default: dry-run)
  --archive=DIR            Move old transcripts to DIR instead of deleting
  --help                   Show this help

Scope:
  - Removes empty subdirectories under session-env/, .claude/tasks/,
    and plugins/data/
  - Truncates .lock and run.log files older than ${STALE_DAYS_LOCKS} days
  - Reports (does not auto-delete) JSONL transcripts older than
    ${STALE_DAYS_TRANSCRIPTS} days under projects/

Safety:
  - Refuses to touch any path that is tracked in git
  - Operates only on gitignored paths listed above
EOF
            exit 0
            ;;
        *)
            printf "Unknown argument: %s (use --help)\n" "$arg" >&2
            exit 2
            ;;
    esac
done

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf "FAIL: required command '%s' not found\n" "$1" >&2
        exit 2
    fi
}

require_cmd git
require_cmd find

verify_ignored() {
    local path="$1"
    if ! git check-ignore -q "$path" 2>/dev/null; then
        printf "SKIP: %s is not gitignored, refusing to touch\n" "$path" >&2
        return 1
    fi
    return 0
}

say() {
    if [[ "$EXECUTE" == true ]]; then
        printf "DO:  %s\n" "$1"
    else
        printf "DRY: %s\n" "$1"
    fi
}

remove_empty_dirs() {
    local base="$1"
    [[ -d "$base" ]] || return 0
    local count=0
    while IFS= read -r -d '' dir; do
        if [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
            if verify_ignored "$dir"; then
                say "remove empty dir $dir"
                if [[ "$EXECUTE" == true ]]; then
                    rmdir "$dir" 2>/dev/null || true
                fi
                count=$((count + 1))
            fi
        fi
    done < <(find "$base" -mindepth 1 -maxdepth 2 -type d -print0 2>/dev/null)
    printf "  scanned %s for empty subdirs (%s found)\n" "$base" "$count"
}

truncate_stale_files() {
    local base="$1"
    local pattern="$2"
    local days="$3"
    [[ -d "$base" ]] || return 0
    local count=0
    while IFS= read -r -d '' file; do
        if verify_ignored "$file"; then
            say "truncate stale $file (older than ${days}d)"
            if [[ "$EXECUTE" == true ]]; then
                : > "$file"
            fi
            count=$((count + 1))
        fi
    done < <(find "$base" -type f -name "$pattern" -mtime +"$days" -print0 2>/dev/null)
    printf "  scanned %s for %s older than %sd (%s found)\n" "$base" "$pattern" "$days" "$count"
}

report_old_transcripts() {
    local base="$1"
    local days="$2"
    [[ -d "$base" ]] || return 0
    local count=0
    while IFS= read -r -d '' file; do
        if [[ -n "$ARCHIVE_DIR" ]]; then
            if verify_ignored "$file"; then
                mkdir -p "$ARCHIVE_DIR"
                say "archive $file -> $ARCHIVE_DIR/"
                if [[ "$EXECUTE" == true ]]; then
                    mv "$file" "$ARCHIVE_DIR/"
                fi
            fi
        else
            printf "OLD: %s (older than %sd, pass --archive=DIR to move)\n" "$file" "$days"
        fi
        count=$((count + 1))
    done < <(find "$base" -type f -name "*.jsonl" -mtime +"$days" -print0 2>/dev/null)
    printf "  scanned %s for *.jsonl older than %sd (%s found)\n" "$base" "$days" "$count"
}

printf "Cleanup target: %s\n" "$ROOT"
if [[ "$EXECUTE" == false ]]; then
    printf "Mode: DRY-RUN (pass --execute to apply)\n"
else
    printf "Mode: EXECUTE (changes will be applied)\n"
fi
printf "\n"

printf "[1/4] Empty subdirectories\n"
remove_empty_dirs "$ROOT/session-env"
remove_empty_dirs "$ROOT/.claude/tasks"
remove_empty_dirs "$ROOT/plugins/data"

printf "\n[2/4] Stale .lock files (older than ${STALE_DAYS_LOCKS}d)\n"
truncate_stale_files "$ROOT/.claude/tasks" "*.lock" "$STALE_DAYS_LOCKS"
truncate_stale_files "$ROOT/.claude/skills" "*.lock" "$STALE_DAYS_LOCKS"

printf "\n[3/4] Stale run.log files (older than ${STALE_DAYS_LOCKS}d)\n"
truncate_stale_files "$ROOT/.claude/tasks" "run.log" "$STALE_DAYS_LOCKS"
truncate_stale_files "$ROOT/.claude/skills" "run.log" "$STALE_DAYS_LOCKS"

printf "\n[4/4] Old JSONL transcripts (older than ${STALE_DAYS_TRANSCRIPTS}d)\n"
report_old_transcripts "$ROOT/projects" "$STALE_DAYS_TRANSCRIPTS"

printf "\nDone.\n"
