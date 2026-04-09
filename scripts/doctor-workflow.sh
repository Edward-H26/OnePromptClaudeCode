#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0
warnings=0

pass() { printf "PASS: %s\n" "$1"; }
warn() { printf "WARN: %s\n" "$1"; warnings=$((warnings + 1)); }
fail() { printf "FAIL: %s\n" "$1"; failures=$((failures + 1)); }

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        fail "Missing required command: $1"
        return 1
    fi
}

print_file_head() {
    local path="$1"
    if [[ -f "$path" ]]; then
        sed -n "1,80p" "$path"
    fi
}

source "$ROOT/scripts/lib/doctor-steps.sh"

echo "[1/9] Deploy to ~/.claude"
doctorDeployToHome

echo "[2/9] Static audit"
doctorStaticAudit

echo "[3/9] Skill symlink health"
doctorSymlinkHealth

echo "[4/9] Hook executable permissions"
doctorHookPermissions

echo "[5/9] Shared plugin health"
doctorPluginHealth

echo "[6/9] MCP health"
doctorMcpHealth

echo "[7/9] Codex read-only smoke"
doctorCodexSmoke

echo "[8/9] Git surface check"
doctorGitSurface

echo "[9/9] Local JSON safety and runtime hygiene"
doctorJsonSafety

echo
printf "Doctor summary: %s failure(s), %s warning(s)\n" "$failures" "$warnings"

if [[ "$failures" -gt 0 ]]; then
    exit 1
fi
