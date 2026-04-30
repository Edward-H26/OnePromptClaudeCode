#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

JSON_MODE=false
STRICT_MODE=false
FAST_MODE=false
DEPS_MODE=false
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
        --deps) DEPS_MODE=true ;;
        --timeout=*) STEP_TIMEOUT_SECONDS="${arg#--timeout=}" ;;
        --help|-h)
            cat <<EOF
Usage: $0 [options]

Options:
  --json              Emit a structured JSON summary at the end
  --strict            Treat warnings as failures (useful for CI)
  --fast              Skip slow steps (MCP, Codex smoke)
  --deps              Run dependency vulnerability scan (npm/pip/cargo audit)
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

    if [[ "$JSON_MODE" == false ]]; then
        printf "    duration: %ss\n" "$duration"
    fi
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

doctorDependencyAudit() {
    local found=0
    local issues=0
    if [[ -f "$ROOT/package.json" ]]; then
        found=1
        if command -v npm >/dev/null 2>&1; then
            local npm_out npm_rc
            npm_out=$(cd "$ROOT" && npm audit --audit-level=high 2>&1); npm_rc=$?
            if [[ $npm_rc -gt 1 ]]; then
                warn "npm audit failed to run (rc=$npm_rc)"
                issues=$((issues + 1))
            elif echo "$npm_out" | grep -qE "found [1-9][0-9]* (high|critical)"; then
                warn "npm audit reported high/critical vulnerabilities"
                issues=$((issues + 1))
            else
                pass "npm audit: no high/critical vulnerabilities"
            fi
        fi
    fi
    if [[ -f "$ROOT/pyproject.toml" || -f "$ROOT/requirements.txt" ]]; then
        found=1
        if command -v pip-audit >/dev/null 2>&1; then
            local pip_out pip_rc
            if [[ -f "$ROOT/requirements.txt" ]]; then
                pip_out=$(pip-audit -r "$ROOT/requirements.txt" 2>&1); pip_rc=$?
            else
                pip_out=$(cd "$ROOT" && pip-audit . 2>&1); pip_rc=$?
            fi
            if [[ $pip_rc -gt 1 ]]; then
                warn "pip-audit failed to run (rc=$pip_rc)"
                issues=$((issues + 1))
            elif echo "$pip_out" | grep -qE "Found [1-9]"; then
                warn "pip-audit reported vulnerabilities"
                issues=$((issues + 1))
            else
                pass "pip-audit: clean"
            fi
        fi
    fi
    if [[ -f "$ROOT/Cargo.toml" ]]; then
        found=1
        if command -v cargo-audit >/dev/null 2>&1; then
            local cargo_out cargo_rc
            cargo_out=$(cd "$ROOT" && cargo audit 2>&1); cargo_rc=$?
            if [[ $cargo_rc -gt 1 ]]; then
                warn "cargo-audit failed to run (rc=$cargo_rc)"
                issues=$((issues + 1))
            elif echo "$cargo_out" | grep -qE "Vulnerabilities found"; then
                warn "cargo-audit reported vulnerabilities"
                issues=$((issues + 1))
            else
                pass "cargo audit: clean"
            fi
        fi
    fi
    if [[ $found -eq 0 ]]; then
        pass "No dependency manifests found to audit"
    fi
}

doctorHookMetrics() {
    local claude_home="${CLAUDE_HOME_DIR:-$HOME/.claude}"
    local metrics_file="$claude_home/runtime/hook-metrics.jsonl"
    if [[ ! -f "$metrics_file" ]]; then
        pass "Hook metrics file not yet created (no instrumented hook has fired this session)"
        return 0
    fi
    local line_count
    line_count=$(wc -l < "$metrics_file" 2>/dev/null | tr -d ' ')
    local unique_hooks
    unique_hooks=$(python3 -c "
import json, sys
seen = set()
try:
    with open('$metrics_file') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                seen.add(json.loads(line).get('hook', ''))
            except Exception:
                pass
except Exception:
    pass
print(len(seen))
" 2>/dev/null || echo "0")
    pass "Hook metrics: $line_count invocation(s) recorded across $unique_hooks distinct hook(s)"
}

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

run_step "Hook coverage metrics" doctorHookMetrics

if [[ "$DEPS_MODE" == true ]]; then
    run_step "Dependency vulnerability audit" doctorDependencyAudit
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
