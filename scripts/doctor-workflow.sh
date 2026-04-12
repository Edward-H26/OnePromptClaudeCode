#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

JSON_MODE=false
STRICT_MODE=false
FAST_MODE=false
STEP_TIMEOUT_SECONDS="${DOCTOR_STEP_TIMEOUT:-180}"
REPORT_DIR="$ROOT/.claude/runtime"
REPORT_PATH="$REPORT_DIR/doctor-report.json"
RESULTS_FILE="$(mktemp -t doctor-results.XXXXXX)"
trap 'rm -f "$RESULTS_FILE"' EXIT

for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        --strict) STRICT_MODE=true ;;
        --fast) FAST_MODE=true ;;
        --timeout=*) STEP_TIMEOUT_SECONDS="${arg#--timeout=}" ;;
        --help|-h)
            cat <<EOF
Usage: $0 [options]

Options:
  --json              Emit a structured JSON summary at the end
  --strict            Treat warnings as failures (useful for CI)
  --fast              Skip slow steps (MCP, Codex smoke)
  --timeout=SECONDS   Per-step timeout (default: 180)
  --help              Show this help

Exit codes:
  0  All steps passed (warnings allowed unless --strict)
  1  At least one step failed
  2  Pre-flight dependency check failed
EOF
            exit 0
            ;;
        *)
            printf "Unknown argument: %s (use --help)\n" "$arg" >&2
            exit 2
            ;;
    esac
done

failures=0
warnings=0
step_counter=0

pass() {
    local msg="$1"
    [[ "$JSON_MODE" == false ]] && printf "PASS: %s\n" "$msg"
    record_result "pass" "$msg"
}

warn() {
    local msg="$1"
    [[ "$JSON_MODE" == false ]] && printf "WARN: %s\n" "$msg"
    warnings=$((warnings + 1))
    record_result "warn" "$msg"
}

fail() {
    local msg="$1"
    [[ "$JSON_MODE" == false ]] && printf "FAIL: %s\n" "$msg"
    failures=$((failures + 1))
    record_result "fail" "$msg"
}

record_result() {
    local status="$1"
    local msg="$2"
    python3 -c "
import json
import sys
print(json.dumps({
    'step': int(sys.argv[1]),
    'status': sys.argv[2],
    'message': sys.argv[3],
}))
" "$step_counter" "$status" "$msg" >> "$RESULTS_FILE"
}

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

run_with_timeout() {
    local seconds="$1"
    shift
    if command -v gtimeout >/dev/null 2>&1; then
        gtimeout --preserve-status "$seconds" "$@"
    elif command -v timeout >/dev/null 2>&1; then
        timeout --preserve-status "$seconds" "$@"
    else
        perl -e '
            my $timeout = shift @ARGV;
            my $pid = fork();
            if ($pid == 0) { exec @ARGV; exit 127; }
            local $SIG{ALRM} = sub { kill "TERM", $pid; sleep 2; kill "KILL", $pid; exit 124; };
            alarm $timeout;
            waitpid $pid, 0;
            exit($? >> 8);
        ' "$seconds" "$@"
    fi
}

run_step() {
    local label="$1"
    local fn="$2"
    step_counter=$((step_counter + 1))
    local step_start
    step_start=$(date +%s)

    [[ "$JSON_MODE" == false ]] && printf "[Step %s] %s\n" "$step_counter" "$label"

    set +e
    if declare -f "$fn" >/dev/null 2>&1; then
        "$fn"
    else
        run_with_timeout "$STEP_TIMEOUT_SECONDS" bash -c "$fn" 2>&1
    fi
    local rc=$?
    set -e

    local step_end
    step_end=$(date +%s)
    local duration=$((step_end - step_start))

    if [[ "$rc" -eq 124 ]]; then
        fail "Step '$label' timed out after ${STEP_TIMEOUT_SECONDS}s"
    elif [[ "$rc" -ne 0 ]]; then
        fail "Step '$label' exited with code $rc"
    fi

    [[ "$JSON_MODE" == false ]] && printf "    duration: %ss\n" "$duration"
}

preflight() {
    local missing=0
    for cmd in bash python3 git jq node rsync; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            printf "PREFLIGHT FAIL: required command '%s' not in PATH\n" "$cmd" >&2
            missing=$((missing + 1))
        fi
    done
    if [[ "$missing" -gt 0 ]]; then
        printf "Install missing dependencies before running doctor-workflow.sh\n" >&2
        exit 2
    fi
    if [[ ! -d "$ROOT/.claude" ]]; then
        printf "PREFLIGHT FAIL: %s/.claude directory is missing\n" "$ROOT" >&2
        exit 2
    fi
    mkdir -p "$REPORT_DIR"
}

preflight

source "$ROOT/scripts/lib/doctor-steps.sh"

run_step "Deploy to \$HOME/.claude" doctorDeployToHome
run_step "Static audit" doctorStaticAudit
run_step "Skill symlink health" doctorSymlinkHealth
run_step "Hook executable permissions" doctorHookPermissions
run_step "Shared plugin health" doctorPluginHealth

if [[ "$FAST_MODE" == false ]]; then
    run_step "MCP health" doctorMcpHealth
    run_step "Codex read-only smoke" doctorCodexSmoke
fi

run_step "Git surface check" doctorGitSurface
run_step "Local JSON safety and runtime hygiene" doctorJsonSafety

if declare -f doctorBrowserTooling >/dev/null 2>&1; then
    run_step "Browser tooling readiness" doctorBrowserTooling
fi

if declare -f doctorSkillsParity >/dev/null 2>&1; then
    run_step "Skills filesystem parity" doctorSkillsParity
fi

python3 - "$RESULTS_FILE" "$REPORT_PATH" "$failures" "$warnings" <<'PY'
import json
import sys
from pathlib import Path
from datetime import datetime, timezone

results_path = Path(sys.argv[1])
report_path = Path(sys.argv[2])
failures = int(sys.argv[3])
warnings = int(sys.argv[4])

steps = []
if results_path.exists():
    for line in results_path.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            steps.append(json.loads(line))
        except json.JSONDecodeError:
            continue

report = {
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "failures": failures,
    "warnings": warnings,
    "status": "fail" if failures > 0 else ("warn" if warnings > 0 else "pass"),
    "steps": steps,
}
report_path.write_text(json.dumps(report, indent=2) + "\n")
PY

if [[ "$JSON_MODE" == true ]]; then
    cat "$REPORT_PATH"
else
    printf "\n"
    printf "Doctor summary: %s failure(s), %s warning(s)\n" "$failures" "$warnings"
    printf "Report written to: %s\n" "$REPORT_PATH"
fi

if [[ "$failures" -gt 0 ]]; then
    exit 1
fi

if [[ "$STRICT_MODE" == true ]] && [[ "$warnings" -gt 0 ]]; then
    [[ "$JSON_MODE" == false ]] && printf "Strict mode: treating %s warning(s) as failure\n" "$warnings"
    exit 1
fi
