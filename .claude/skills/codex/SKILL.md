---
name: codex
description: Delegate coding tasks to Codex CLI for execution, or discuss implementation approaches with it. CodeX is a cost-effective, strong coder — great for batch refactoring, code generation, multi-file changes, test writing, and multi-turn implementation tasks. Use when the plan is clear and needs hands-on coding. Claude handles architecture, strategy, copywriting, and ambiguous problems better.
---

# CodeX — Your Codex Coding Partner

Delegate coding execution to Codex CLI. CodeX turns clear plans into working code.

## Critical rules

- For delegated coding work, use the bundled shell script. The direct `codex` CLI is reserved for the read-only review, challenge, and consult modes documented below.
- Run the script ONCE per task. If it succeeds (exit code 0), read the output file and proceed. Do NOT re-run or retry.
- Do NOT read or inspect the script source code. Treat it as a black box.
- ALWAYS quote file paths containing brackets, spaces, or special characters when passing to the script (e.g. `--file "src/app/[locale]/page.tsx"`). Unquoted `[...]` triggers zsh glob expansion.
- **Keep the task prompt focused.** Aim for under ~500 words. Describe WHAT to do and key constraints, not step-by-step HOW. CodeX is an autonomous agent with full workspace access — it reads files, explores code, and figures out implementation details on its own.
- **Never paste file contents into the prompt.** Use `--file` to point CodeX to key files — it reads them directly. Duplicating file contents in the prompt wastes tokens and adds no value.
- **Don't reference or describe the SKILL.md itself in the prompt.** CodeX doesn't need to know about this skill's configuration.

## How to call the script

The script path is:

```
$CLAUDE_PROJECT_DIR/.claude/skills/codex/scripts/ask_codex.sh
```

Minimal invocation:

```bash
"$CLAUDE_PROJECT_DIR/.claude/skills/codex/scripts/ask_codex.sh" "Your request in natural language"
```

With file context:

```bash
"$CLAUDE_PROJECT_DIR/.claude/skills/codex/scripts/ask_codex.sh" "Refactor these components to use the new API" \
  --file src/components/UserList.tsx \
  --file src/components/UserDetail.tsx
```

Multi-turn conversation (continue a previous session):

```bash
"$CLAUDE_PROJECT_DIR/.claude/skills/codex/scripts/ask_codex.sh" "Also add retry logic with exponential backoff" \
  --session <session_id from previous run>
```

The script prints on success:

```
session_id=<thread_id>
output_path=<path to markdown file>
```

Read the file at `output_path` to get CodeX's response. Save `session_id` if you plan follow-up calls.

## Decision policy

Call CodeX when at least one of these is true:

- The implementation plan is clear and needs coding execution.
- The task involves batch refactoring, code generation, or repetitive changes.
- Multiple files need coordinated modifications following a defined pattern.
- You want a practitioner's perspective on whether a plan is feasible.
- The task is cost-sensitive and doesn't require deep architectural reasoning.
- Writing or updating tests based on existing code.
- Simple-to-moderate bug fixes where the root cause is identified.

## Workflow

1. Design the solution and identify the key files involved.
2. Run the script with a clear, concise task description. Tell CodeX the goal and constraints, not step-by-step implementation details — it figures those out itself. For discussion, use a question-oriented task with `--read-only`.
3. Pass relevant files with `--file` (2-6 high-signal entry points; CodeX has full workspace access and will discover related files on its own).
4. Read the output — CodeX executes changes and reports what it did.
5. Review the changes in your workspace.

For multi-step projects, use `--session <id>` to continue with full conversation history. For independent parallel tasks, start separate background shell runs only when the current environment supports that workflow cleanly.

## Options

- `--workspace <path>` — Target workspace directory (defaults to current directory).
- `--file <path>` — Point CodeX to key entry-point files (repeatable, workspace-relative or absolute). Don't duplicate their contents in the prompt.
- `--session <id>` — Resume a previous session for multi-turn conversation.
- `--model <name>` — Override model (default: uses Codex config).
- `--reasoning <level>` — Reasoning effort: `low`, `medium`, `high` (default: `medium`). Use `high` for code review, debugging, complex refactoring, or root cause analysis.
- `--sandbox <mode>` — Override sandbox policy (default: workspace-write via full-auto).
- `--read-only` — Read-only mode for pure discussion/analysis, no file changes.

---

## Cross-Model Review Modes (via direct `codex` CLI)

These modes are read-only cross-model checks. They complement the `ask_codex.sh` delegation workflow above and do not replace it for coding execution.

### Prerequisites

Verify Codex CLI is available:
```bash
CODEX_BIN=$(which codex 2>/dev/null || echo "")
[ -z "$CODEX_BIN" ] && echo "NOT_FOUND" || echo "FOUND: $CODEX_BIN"
```

If `NOT_FOUND`: tell the user to install via `npm install -g @openai/codex`.

### Mode 1: Review (pass/fail gate)

Run an independent code review against the current branch diff.

```bash
codex review --base <base-branch> -c 'model_reasoning_effort="xhigh"' --enable web_search_cached
```

With custom focus (e.g., security):
```bash
codex review "focus on security" --base <base-branch> -c 'model_reasoning_effort="xhigh"' --enable web_search_cached
```

**Gate logic**: If output contains `[P1]`, the gate is **FAIL**. Otherwise **PASS**.

Present output verbatim inside:
```
CODEX SAYS (code review):
════════════════════════════════════════════════════════════
<full codex output, verbatim>
════════════════════════════════════════════════════════════
GATE: PASS/FAIL    Tokens: N
```

**Cross-model comparison**: If Claude's own `/review` was already run in this conversation, compare findings:
```
CROSS-MODEL ANALYSIS:
  Both found: [overlapping findings]
  Only Codex found: [unique to Codex]
  Only Claude found: [unique to Claude]
  Agreement rate: X%
```

### Mode 2: Challenge (adversarial)

Codex tries to break your code, finding edge cases, race conditions, security holes.

```bash
codex exec "<adversarial prompt>" -s read-only -c 'model_reasoning_effort="xhigh"' --enable web_search_cached
```

Default prompt: "Review the changes on this branch. Your job is to find ways this code will fail in production. Think like an attacker and a chaos engineer. Find edge cases, race conditions, security holes, resource leaks, failure modes, and silent data corruption paths. Be adversarial. Be thorough."

### Mode 3: Consult (session continuity)

Ask Codex anything with session continuity for follow-ups.

New session:
```bash
codex exec "<prompt>" -s read-only -c 'model_reasoning_effort="xhigh"' --enable web_search_cached
```

Resume session:
```bash
codex exec resume <session-id> "<prompt>" -s read-only -c 'model_reasoning_effort="xhigh"' --enable web_search_cached
```

### When to use which mode

| Trigger | Mode |
|---|---|
| "codex review", "second opinion on this diff" | Review |
| "codex challenge", "try to break this" | Challenge |
| "ask codex", "consult codex", "codex <question>" | Consult |
| ask_codex.sh for coding tasks, refactoring, test writing | Delegation (above) |

### Rules for cross-model modes

- Never modify files. These modes are read-only.
- Present output verbatim. Do not truncate or summarize.
- Add synthesis after, not instead of, the raw output.
- 5-minute timeout on all Bash calls to codex.
