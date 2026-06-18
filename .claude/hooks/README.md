# Hooks

Claude Code hooks that enable skill auto-activation, type and lint checks, and workflow reminders. All 4 hooks are repo-local and wired in `.claude/settings.json`.

---

## Prerequisites

- **jq** (required): All hooks depend on jq for JSON parsing. Hooks degrade silently if jq is missing. Install via `brew install jq` (macOS), `apt-get install jq` (Linux), or `winget install stedolan.jq` / `choco install jq` (Windows).
- **bash 4+** (recommended): Hooks use associative arrays and modern bash features.

---

## What Are Hooks?

Hooks are scripts that run at specific points in Claude's workflow:
- **UserPromptSubmit**: When the user submits a prompt
- **PostToolUse**: After a tool completes
- **Stop**: When Claude finishes responding
- **SessionStart**: When a session begins

**Key insight:** Hooks can inject context and track state. In this repo they remain advisory unless a concrete validation failure exists.

---

## Hook Execution Order

Hooks fire in the order they appear in `.claude/settings.json`:

**UserPromptSubmit:**
1. `task-orchestrator-hook.sh` - Detects analysis vs coding tasks, injects concise workflow reminders, runs the skill-activation engine, and flags vague prompts for clarification

**PostToolUse (Edit|MultiEdit|Write):**
1. `post-edit-check.sh` - Runs the TypeScript check, the native linter, and a Python check on edited files, and records the edit log

**Stop:**
1. `workflow-completion-gate.sh` - Emits a browser-verification reminder for frontend edits and cleans stale cache state

**SessionStart:**
1. `session-start.sh` - Validates tools, bootstraps local settings, and injects baseline repo context

---

## Shared Libraries

### `lib/utils.sh`
Shared utility functions sourced by multiple hooks:
- `is_project_dir(dir)` - Checks for project markers (tsconfig, package.json, go.mod, etc.)
- `get_repo_for_file(path)` - Resolves file path to its parent project/repo
- `repo_cache_key(repo)` - Produces nested-repo-safe cache keys for hook artifacts
- `get_tsc_command(repo_path)` - Determines the correct tsc command for a project
- `validate_and_run_tsc(cmd)` - Validates and executes tsc commands safely
- `atomic_sort_unique(file)` - Atomically sorts and deduplicates a file (uses directory-based locking)
- `safe_rm_cache(dir)` - Safely removes tsc-cache directories (validates path prefix)
- `sanitize_session_id(id)` - Strips a session id down to filesystem-safe characters
- `resolve_claude_home()` - Resolves the active repo-local `.claude/` root with a safe fallback

### `lib/patterns.sh`
Shared regex patterns sourced by `task-orchestrator-hook.sh`:
- `ANALYSIS_PATTERN` - Matches analysis/research prompts (audit, review, explain, etc.)
- `CODING_PATTERN` - Matches coding task prompts (fix, implement, build, etc.)
- `PURE_QUESTION_PATTERN` - Matches question-form prompts
- `CODING_CONTEXT_PATTERN` - Matches code-related file extensions and terminology
- `EXPLICIT_IMPLEMENTATION_PATTERN` - Distinguishes concrete file or code edits from broad audit language
- `WORKFLOW_IMPLEMENTATION_PATTERN` - Treats workflow/config edits as concrete implementation intent

### `lib/plugin-state.sh`
Shared plugin state helpers sourced by `task-orchestrator-hook.sh` and audit tooling:
- `plugin_enabled_names()` - Lists plugins enabled in `.claude/settings.json`
- `plugin_installed_names()` - Lists locally installed plugins when `plugins/installed_plugins.json` exists
- `plugin_blocklisted_names()` - Lists locally blocklisted plugins when `plugins/blocklist.json` exists
- `plugin_available_names()` - Lists plugins both enabled and locally available
- `plugin_is_available(name)` - Checks whether a plugin should be treated as available

The shared tracked config keeps the baseline plugin set intentionally small. Auth-sensitive, duplicate, or machine-fragile plugin integrations should be added in `.claude/settings.local.json` so repo health checks stay reproducible.

### `lib/runtime-state.sh`
Shared repo-local runtime path helpers used by the audit tooling:
- `workflow_runtime_root()` - Resolves the repo-local runtime root under `.claude/runtime/`

### `lib/hook-metrics.sh`
Shared instrumentation helpers sourced by `session-start.sh`:
- `record_hook_invocation(hook_name)` - Appends a single JSONL line to `.claude/runtime/hook-metrics.jsonl`
- `resolve_claude_home()` - Resolves the active repo-local `.claude/` root and falls back safely when a hook is invoked outside the repo

---

## Hook Details

### task-orchestrator-hook (UserPromptSubmit)

**Purpose:** Detects whether a prompt is analysis-only or a coding task, injects a compact reminder, runs the skill-activation engine, and flags vague prompts.

**Analysis mode:** If the prompt matches `ANALYSIS_PATTERN` without concrete edit intent, outputs a short analysis reminder followed by the skill-activation check.

**Pure informational mode:** If the prompt is only a question and does not imply edits, exits quietly instead of injecting coding-task guidance.

**Memory or preference mode:** If the prompt is only a memory or preference note without concrete implementation intent, exits quietly.

**Coding mode:** Outputs concise workflow guidance, points to the most relevant local skills, and only lists plugins that are locally available.

**Skill activation:** Reads `skill-rules.json`, matches the prompt against each skill's `promptTriggers` (keywords + intentPatterns), respects `keywordExclusions`, and groups results by priority (critical, high, medium, low). Falls back to `$PWD` when `CLAUDE_PROJECT_DIR` is not exported.

**Clarify first:** When the prompt is vague (five words or fewer, or only a bare verb such as fix/update/change/改/弄 with no specifics), appends a short reminder to ask one or two clarifying questions before implementing.

### post-edit-check (PostToolUse, Edit|MultiEdit|Write)

**Purpose:** Validates edited files and records the change set so the Stop hook can read it.

- **TypeScript:** Runs a compilation check on repos affected by `.ts`, `.tsx`, `.js`, `.jsx` edits. Caches the detected TSC command per repo using sanitized repo keys so nested repos such as `packages/app` do not break file creation. Writes `affected-repos.txt`, `commands.txt`, and `last-errors.txt` under `tsc-cache/SESSION_ID/`, and exits non-zero when TypeScript errors are found.
- **Lint:** Detects the native linter for each edited file (ruff, flake8, eslint, biome, shellcheck) by walking the file's parent directories for a matching config, runs it on the edited file only, and folds any violation into the exit code.
- **Python:** For each edited `.py` file, runs `pyright` when available, otherwise `ruff check`, and folds any failure into the exit code.
- **Edit log:** Appends a `<tool_name>\t<path>` line per edited file to `edited-files.log`.

### workflow-completion-gate (Stop)

**Purpose:** Emits a browser-verification reminder when `edited-files.log` shows `.tsx`, `.jsx`, `.css`, or `.scss` edits, then removes `tsc-cache` session directories older than 14 days. Always exits 0.

### session-start (SessionStart)

**Purpose:** Validates required local tools, auto-bootstraps `.claude/settings.local.json` from the tracked example on first use, emits baseline repo-local `additionalContext`, and reinjects the saved pre-compact snapshot when `source=compact`.

---

## Environment Variables

| Variable | Default | Used By | Description |
|----------|---------|---------|-------------|
| `CLAUDE_PROJECT_DIR` | `$PWD` | All hooks | Root project directory |
| `SESSION_ID` | `default` | post-edit-check, workflow-completion-gate | Session identifier for cache isolation |
| `FORCE_DETECT` | (unset) | post-edit-check | When set, bypasses cached TSC command and re-detects |

---

## Known Limitations

- **TSC cache staleness**: The cached TSC command per repo does not auto-invalidate when tsconfig.json changes. Set `FORCE_DETECT=1` to force re-detection after config changes.
- **Plugin availability is snapshot-based**: `plugin_available_names()` reads plugin state at hook invocation time. Plugins installed or removed mid-session may not be reflected until the next hook fires.
- **Pre-commit safety**: Run `git diff --cached` and `bash scripts/audit-workflow.sh` before committing to verify no secrets or unintended files are staged.

---

## Troubleshooting

**Hook not firing:**
- Verify the hook is in `.claude/settings.json` under the correct event
- Check the script is executable: `chmod +x "$CLAUDE_PROJECT_DIR/.claude/hooks/SCRIPT.sh"`
- Test the script directly: `CLAUDE_PROJECT_DIR="$PWD" bash "$PWD/.claude/hooks/SCRIPT.sh" <<< '{"prompt":"test"}'`

**"PostToolUse:Edit hook blocking error":**
- Run `bash -n "$PWD/.claude/hooks/lib/utils.sh"` to check for syntax errors
- Check that `jq` is installed: `command -v jq`
- Look at post-edit-check.sh output: the error might be a TypeScript, lint, or Python failure, not a hook error

**Workflow reminder output:**
- This is advisory output from `workflow-completion-gate.sh`
- Type, lint, and Python failures are still handled by `post-edit-check.sh`
- Stale sessions auto-clean after 14 days

**Hook stalls or hangs:**
- Check for stale lock files: `find "$PWD/.claude/tsc-cache" -name '*.lock' -print`
- Remove a stale empty lock directory manually with `rmdir` if needed after checking that no hook process is still running

**Temporarily disable a specific hook:**
- Comment out the hook entry in `.claude/settings.json` under the appropriate event key
- Or rename the script: `mv hook.sh hook.sh.disabled`
- To disable all hooks temporarily: set `"hooks": {}` in `.claude/settings.json` (remember to restore)

**Debugging hook output:**
- Hooks write to stderr for visibility. Redirect to a file to capture: `echo '{"prompt":"test","session_id":"debug"}' | bash hook.sh 2>hook-debug.log`
- For PostToolUse hooks, include `tool_name` and `tool_input` in the JSON
- Enable verbose bash tracing: temporarily add `set -x` at the top of the script
