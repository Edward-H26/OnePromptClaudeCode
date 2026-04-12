#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

JSON_MODE=false
STRICT_MODE=false
FAST_MODE=false
STEP_TIMEOUT_SECONDS="${AUDIT_STEP_TIMEOUT:-180}"
REPORT_DIR="$ROOT/.claude/runtime"
REPORT_PATH="$REPORT_DIR/audit-report.json"
LOG_DIR="$REPORT_DIR/audit-logs"
RESULTS_FILE="$(mktemp -t audit-results.XXXXXX)"
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
  --fast              Skip heavier subaudits (hook smokes, ghost-tracked scan)
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

preflight() {
    local missing=0
    for cmd in bash python3 git jq; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            printf "PREFLIGHT FAIL: required command '%s' not in PATH\n" "$cmd" >&2
            missing=$((missing + 1))
        fi
    done
    if [[ "$missing" -gt 0 ]]; then
        printf "Install missing dependencies before running audit-workflow.sh\n" >&2
        exit 2
    fi
    mkdir -p "$REPORT_DIR" "$LOG_DIR"
}

preflight

source ".claude/hooks/lib/patterns.sh"
source ".claude/hooks/lib/utils.sh"
source ".claude/hooks/lib/plugin-state.sh"
source ".claude/hooks/lib/runtime-state.sh"
source "$ROOT/scripts/lib/audit-helpers.sh"
source "$ROOT/scripts/lib/audit-steps.sh"

for fn in auditShellSyntax auditSymlinkIntegrity auditHookSmokes \
          auditPluginAlignment expect_match expect_no_match expect_true \
          run_skill_activation run_skill_activation_no_env \
          run_task_orchestrator run_auto_codex_trigger_with_stub \
          run_check_careful run_check_freeze run_tsc_hook_regression \
          run_ask_codex_with_stub \
          plugin_settings_path plugin_local_settings_path \
          plugin_installed_path plugin_blocklist_path \
          plugin_has_install_state plugin_enabled_names \
          plugin_installed_names plugin_blocklisted_names \
          plugin_available_names plugin_is_available; do
    if declare -f "$fn" >/dev/null 2>&1; then
        export -f "$fn"
    fi
done

step_counter=0
failures=0
warnings=0

run_with_timeout_audit() {
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

record_step() {
    local status="$1"
    local label="$2"
    local duration="$3"
    local log_path="${4:-}"
    python3 -c "
import json
import sys
print(json.dumps({
    'step': int(sys.argv[1]),
    'label': sys.argv[2],
    'status': sys.argv[3],
    'duration_ms': int(sys.argv[4]),
    'log': sys.argv[5] or None,
}))
" "$step_counter" "$label" "$status" "$duration" "$log_path" >> "$RESULTS_FILE"
}

run_step() {
    local label="$1"
    shift
    step_counter=$((step_counter + 1))
    local log_path="$LOG_DIR/step-${step_counter}.log"
    local step_start_ms
    step_start_ms=$(python3 -c "import time; print(int(time.time()*1000))")

    [[ "$JSON_MODE" == false ]] && printf "[%s/%s] %s\n" "$step_counter" "$TOTAL_STEPS" "$label"

    set +e
    if declare -f "$1" >/dev/null 2>&1; then
        local fn_name="$1"
        shift
        "$fn_name" "$@" >"$log_path" 2>&1
    else
        run_with_timeout_audit "$STEP_TIMEOUT_SECONDS" "$@" >"$log_path" 2>&1
    fi
    local rc=$?
    set -e

    local step_end_ms
    step_end_ms=$(python3 -c "import time; print(int(time.time()*1000))")
    local duration_ms=$((step_end_ms - step_start_ms))

    if [[ "$JSON_MODE" == false ]]; then
        sed -n '1,40p' "$log_path"
    fi

    if [[ "$rc" -eq 124 ]]; then
        failures=$((failures + 1))
        [[ "$JSON_MODE" == false ]] && printf "FAIL: Step '%s' timed out after %ss\n" "$label" "$STEP_TIMEOUT_SECONDS"
        record_step "fail" "$label" "$duration_ms" "$log_path"
    elif [[ "$rc" -ne 0 ]]; then
        failures=$((failures + 1))
        [[ "$JSON_MODE" == false ]] && printf "FAIL: Step '%s' exited with code %s (log: %s)\n" "$label" "$rc" "$log_path"
        record_step "fail" "$label" "$duration_ms" "$log_path"
    else
        record_step "pass" "$label" "$duration_ms" "$log_path"
    fi
}

if [[ "$FAST_MODE" == true ]]; then
    TOTAL_STEPS=11
else
    TOTAL_STEPS=14
fi

run_step "Shell syntax" auditShellSyntax
run_step "Symlink integrity" auditSymlinkIntegrity
run_step "Hook script path resolution" python3 "$ROOT/scripts/lib/audit-hook-paths.py"
run_step "JSON parse and skill inventory" python3 "$ROOT/scripts/lib/audit-inventory.py"

if [[ "$FAST_MODE" == false ]]; then
    run_step "Hook prompt classification and helper smokes" auditHookSmokes
fi

run_step "Local stale-reference scan" python3 "$ROOT/scripts/lib/audit-stale-refs.py"
run_step "Plugin alignment and public surface" bash -c "auditPluginAlignment && python3 $ROOT/scripts/lib/audit-plugins.py"
run_step "Secret-pattern scan on public surface" python3 "$ROOT/scripts/lib/audit-secrets.py"

if [[ "$FAST_MODE" == false ]]; then
    run_step "Ghost-tracked file audit" python3 "$ROOT/scripts/lib/audit-ghost-tracked.py"
fi

run_step "Ignored sensitive-state summary" python3 "$ROOT/scripts/lib/audit-ignored.py"
run_step "Public surface summary" python3 "$ROOT/scripts/lib/audit-surface.py"

run_step "README parity (filesystem counts)" python3 "$ROOT/scripts/lib/audit-readme-parity.py"

if [[ "$FAST_MODE" == false ]]; then
    run_step "Browser tooling consistency" python3 "$ROOT/scripts/lib/audit-browser-tooling.py"
fi

run_step "Cross-validation summary" python3 -c "
from pathlib import Path
root = Path('.')
skills = {p.name for p in (root / '.claude' / 'skills').iterdir() if (p.is_dir() or p.is_symlink()) and (p.name != 'skill-rules.json')}
agents = {p.stem for p in (root / '.claude' / 'agents').glob('*.md') if p.name != 'README.md'}
commands = {p.stem for p in (root / '.claude' / 'commands').glob('*.md') if p.name != 'README.md'}
hooks = list((root / '.claude' / 'hooks').glob('*.sh'))
templates = {p.stem for p in (root / '.claude' / 'prompt-templates').glob('*.md') if p.name != 'README.md'}
print(f'  Skills: {len(skills)}, Agents: {len(agents)}, Commands: {len(commands)}, Hooks: {len(hooks)}, Templates: {len(templates)}')
"

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
    if [[ "$failures" -eq 0 ]]; then
        printf "Workflow audit passed. Warnings: %s. Report: %s\n" "$warnings" "$REPORT_PATH"
    else
        printf "Workflow audit FAILED: %s failure(s), %s warning(s). Report: %s\n" "$failures" "$warnings" "$REPORT_PATH"
    fi
fi

if [[ "$failures" -gt 0 ]]; then
    exit 1
fi

if [[ "$STRICT_MODE" == true ]] && [[ "$warnings" -gt 0 ]]; then
    [[ "$JSON_MODE" == false ]] && printf "Strict mode: %s warning(s) treated as failure\n" "$warnings"
    exit 1
fi
