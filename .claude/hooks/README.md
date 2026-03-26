# Hooks

Claude Code hooks that enable skill auto-activation, file tracking, workflow reminders, and validation.

---

## What Are Hooks?

Hooks are scripts that run at specific points in Claude's workflow:
- **UserPromptSubmit**: When user submits a prompt
- **PostToolUse**: After a tool completes
- **Stop**: When Claude finishes responding

**Key insight:** Hooks can modify prompts and track state. In this repo, they should remain advisory unless a concrete validation failure exists.

---

## Hook Execution Order

Hooks fire in the order they appear in `.claude/settings.json`:

**UserPromptSubmit:**
1. `task-orchestrator-hook.sh` - Detects analysis vs coding tasks, injects concise workflow reminders
2. `auto-codex-trigger.sh` - Optionally launches Codex in background for coding tasks
3. `skill-activation-prompt.sh` - Suggests relevant skills based on prompt keywords

**PostToolUse (Edit|MultiEdit|Write):**
1. `post-tool-use-tracker.sh` - Records file changes, detects project structure
2. `tsc-check.sh` - Runs TypeScript compilation check on modified repos

**PostToolUse (Bash|Skill|Chrome MCP):**
1. `workflow-step-tracker.sh` - Tracks optional workflow signals such as Codex kickoff, read-only Codex review, simplification review, and browser verification

**Stop:**
1. `stop-build-check-enhanced.sh` - Re-runs build checks on all affected repos
2. `workflow-completion-gate.sh` - Emits reminders and cleans stale cache state

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

### `lib/patterns.sh`
Shared regex patterns sourced by auto-codex-trigger.sh and task-orchestrator-hook.sh:
- `ANALYSIS_PATTERN` - Matches analysis/research prompts (audit, review, explain, etc.)
- `CODING_PATTERN` - Matches coding task prompts (fix, implement, build, etc.)
- `PURE_QUESTION_PATTERN` - Matches question-form prompts
- `CODING_CONTEXT_PATTERN` - Matches code-related file extensions and terminology
- `EXPLICIT_IMPLEMENTATION_PATTERN` - Distinguishes concrete file or code edits from broad audit language

---

## Hook Details

### task-orchestrator-hook (UserPromptSubmit)

**Purpose:** Detects whether a prompt is analysis-only or a coding task. Injects a compact reminder about exploration, minimal edits, relevant skills, and verification.

**Analysis mode:** If the prompt matches `ANALYSIS_PATTERN` without concrete edit intent, outputs a short analysis reminder.

**Coding mode:** Outputs concise workflow guidance and points to the most relevant local skills.

### auto-codex-trigger (UserPromptSubmit)

**Purpose:** Automatically launches Codex for coding tasks in the background.

**Skip conditions:** Greetings, prompts < 15 chars, memory operations, missing `jq`, analysis-only tasks, pure questions without coding actions.

**Coding task detection:** A prompt is considered a coding task only when it clears the analysis guard and then matches `CODING_PATTERN` or code-related file extensions or terms (`CODING_CONTEXT_PATTERN`).

### skill-activation-prompt (UserPromptSubmit)

**Purpose:** Auto-suggests relevant skills based on prompt keywords and intent patterns.

Reads `skill-rules.json`, matches prompt against each skill's `promptTriggers` (keywords + intentPatterns), respects `keywordExclusions`, and groups results by priority (critical, high, medium, low).

### post-tool-use-tracker (PostToolUse)

**Purpose:** Tracks file modifications for downstream hooks. Skips `.md`, `.mdx`, `.markdown` files.

Creates: `edited-files.log`, `affected-repos.txt`, `commands.txt` in `tsc-cache/SESSION_ID/`.
`commands.txt` stores tracked TSC commands only.

### tsc-check (PostToolUse)

**Purpose:** Runs TypeScript compilation check on repos affected by file edits.

Only triggers for `.ts`, `.tsx`, `.js`, `.jsx` files. Caches the detected TSC command per repo.
Cache artifacts use sanitized repo keys so nested repos such as `packages/app` do not break file creation.

### workflow-step-tracker (PostToolUse)

**Purpose:** Tracks optional workflow signals via directory markers:
- `codex-kickoff/` - Created when `ask_codex.sh` runs without `--read-only`
- `simplify-review/` - Created when a simplify or code-simplifier review is detected
- `codex-eval/` - Created when `ask_codex.sh` runs with `--read-only`
- `chrome-verification/` - Created when browser tooling is used

### stop-build-check-enhanced (Stop)

**Purpose:** Re-runs tracked TSC checks on all affected repos when Claude finishes responding. Uses `AUTO_ERROR_THRESHOLD` (default: 5) to decide between suggesting auto-error-resolver (for many errors) or inline fix suggestions (for few errors).

### workflow-completion-gate (Stop)

**Purpose:** Emits workflow reminders and cleans stale cache state. It no longer blocks completion for stale, tool-specific workflow steps that may not exist in every environment.

Also cleans up stale `tsc-cache` sessions older than 7 days.

---

## Environment Variables

| Variable | Default | Used By | Description |
|----------|---------|---------|-------------|
| `CLAUDE_PROJECT_DIR` | `$PWD` | All hooks | Root project directory |
| `SESSION_ID` | `default` | All hooks | Session identifier for cache isolation |
| `AUTO_ERROR_THRESHOLD` | `5` | stop-build-check-enhanced | Errors >= threshold triggers auto-error-resolver agent |
| `FORCE_DETECT` | (unset) | tsc-check | When set, bypasses cached TSC command and re-detects |

---

## Troubleshooting

**Hook not firing:**
- Verify the hook is in `.claude/settings.json` under the correct event
- Check the script is executable: `chmod +x "$CLAUDE_PROJECT_DIR/.claude/hooks/SCRIPT.sh"`
- Test the script directly: `echo '{"prompt":"test"}' | bash "$CLAUDE_PROJECT_DIR/.claude/hooks/SCRIPT.sh"`

**"PostToolUse:Edit hook blocking error":**
- Run `bash -n "$CLAUDE_PROJECT_DIR/.claude/hooks/lib/utils.sh"` to check for syntax errors
- Check that `jq` is installed: `command -v jq`
- Look at tsc-check.sh output: the error might be a TypeScript compilation failure, not a hook error

**Workflow reminder output:**
- This is advisory output from `workflow-completion-gate.sh`
- Type failures are still handled by the validation hooks
- Stale sessions auto-clean after 7 days

**Codex not triggering:**
- Check that `codex` command is in PATH: `command -v codex`
- Check that `ask_codex.sh` exists and is executable
- Verify the prompt isn't being classified as "analysis-only" by the pattern matching

**Hook stalls or hangs:**
- Check for stale lock files: `ls -la $CLAUDE_PROJECT_DIR/.claude/tsc-cache/**/*.lock`
- Remove stale locks manually (locks older than 1 minute are auto-cleaned by `atomic_sort_unique`, but you can `rm -rf` any `.lock` directory)
- Kill orphan background processes: `ps aux | grep 'tsc-check\|auto-codex-trigger' | grep -v grep`

**Temporarily disable a specific hook:**
- Comment out the hook entry in `.claude/settings.json` under the appropriate event key
- Or rename the script: `mv hook.sh hook.sh.disabled`
- To disable all hooks temporarily: set `"hooks": {}` in `.claude/settings.json` (remember to restore)

**Debugging hook output:**
- Hooks write to stderr for visibility. Redirect to a file to capture: `echo '{"prompt":"test","session_id":"debug"}' | bash hook.sh 2>hook-debug.log`
- For PostToolUse hooks, include `tool_name` and `tool_input` in the JSON
- Enable verbose bash tracing: temporarily add `set -x` at the top of the script
