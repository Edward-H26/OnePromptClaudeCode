# OnePromptClaudeCode

**One prompt is all you need.**

A complete Claude Code workflow that covers the entire software development lifecycle. Clone it, start coding, and never write a prompt from scratch again.

26 skill entries. 20 commands. 14 agents. 10 local hooks. 4 templates. 11+ shared MCP servers. 600+ auto-triggers.

Built for beginners. Scales for power users.

---

## Why This Exists

Every Claude Code user hits the same wall:

1. Writing the same prompts from scratch on every project
2. Finding great community tools (gstack, Superpowers, everything-claude-code) but struggling to combine them
3. Missing features they don't even know exist

OnePromptClaudeCode solves all three. It integrates the best of the Claude Code ecosystem into one workflow with a 600+ keyword trigger engine that activates the right skills automatically.

---

## Quick Start

```bash
git clone https://github.com/Edward-H26/OnePromptClaudeCode.git
cd OnePromptClaudeCode
bash scripts/doctor-workflow.sh        # verify hooks, skills, and settings
claude
```

That is the repo setup. `bash scripts/doctor-workflow.sh` auto-creates or merges `.claude/settings.local.json` from the tracked `.claude/settings.local.example.json`, so a fresh clone does not require a manual local-settings copy step. Shared Remotion MCP servers now live in the tracked [`.mcp.json`](/Users/edwardhu/Desktop/agent/claude/.mcp.json), which keeps project-scoped tool wiring out of machine-local settings. The tracked baseline still enables only the repo-stable plugin set; auth-sensitive, duplicate, or machine-fragile integrations such as GitHub, context7, Figma plugin MCP, Playwright plugin MCP, and `superpowers` stay disabled in the example until the local machine is actually configured for them. Run `bash scripts/doctor-workflow.sh` on a fresh clone to confirm the live workflow is ready, and clear any stale local plugin blocklist test entries if the doctor warns about them. After workflow changes, run `bash scripts/audit-workflow.sh`.

---

## How It Works

The workflow watches what you do and activates the right tools automatically:

| You do this | This activates |
|---|---|
| Edit a React file | `frontend-dev-guidelines` |
| Write tests | `tdd-workflow` |
| Touch auth code | `security-review` |
| Open a Playwright spec | `e2e-testing` |
| Ask about Docker | `docker-patterns` |

Zero prompts to write. Minimal repo setup. Machine-local plugin installs and auth still need to be healthy.

---

## Runtime Prerequisites

- Install the shared Claude Code baseline plugin set once on the machine that uses this repo.
- Add auth-sensitive, duplicate, or machine-fragile plugin integrations in `.claude/settings.local.json`, not the shared tracked config.
- `bash scripts/doctor-workflow.sh` auto-seeds `.claude/settings.local.json` from the tracked example on first run, then preserves local overrides on later merges.
- Ensure required MCP connectors and auth are healthy for the tools you actually use.
- If you want the optional Codex background workflow, make sure `codex` is installed and authenticated.
- Run `bash scripts/doctor-workflow.sh` after clone, and again after workflow or plugin changes.

### Utility scripts

| Script | Purpose |
|---|---|
| `scripts/doctor-workflow.sh` | Full health check of hooks, skills, MCP servers, plugins; auto-seeds `settings.local.json` from the example. |
| `scripts/audit-workflow.sh` | Audit pass: lint hooks, scan permissions, verify gitignore coverage. Run after workflow changes. |
| `scripts/merge-local-settings.sh` | Merge `settings.local.example.json` into `settings.local.json` (user values win on conflict, new blocks added, timestamped backup). Use `--yes` to skip the diff prompt. |
| `scripts/cleanup-runtime.sh` | Garbage-collect stale runtime artifacts (locks > 30d, transcripts > 60d, runtime dirs > 14d). Dry-run by default; `--execute` to apply; `--archive=DIR` to move instead of delete. |

---

## What's Inside

### At a Glance

| Component | Count | Description |
|---|---|---|
| **Skills** | 26 | Bundled workflow skill entries available directly from the tracked repo |
| **Commands** | 20 | Slash commands for planning, implementation, review, QA, and release handoff |
| **Agents** | 14 | Specialized local agents for complex tasks |
| **Hooks** | 10 | Automated safety, tracking, and validation hooks (all local) |
| **Templates** | 4 | Reusable prompt templates for common workflows |
| **MCP Servers** | 11+ | Figma, GitHub, Playwright, HuggingFace, and other shared or user-scoped connectors |

### Development Lifecycle

The workflow follows a structured sprint cycle: **Think, Plan, Build, Review, Test, Ship, Reflect**.

| Phase | What happens | Key commands |
|---|---|---|
| **Think** | YC-style brainstorming | `/office-hours` |
| **Plan** | Architecture review and design plan review | `/plan-eng-review`, `/plan-design-review` |
| **Review** | Staff engineer code review, OWASP security scanning | `/review-staff`, `/codex review` |
| **Test** | Browser QA, webapp-testing | `/qa-only` (report-only) or invoke the `qa` skill via keyword |

### Safety

| Command | What it does |
|---|---|
| `/careful` | Warns before destructive commands (rm -rf, DROP TABLE, force-push) |
| `/freeze` | Locks file edits to a single directory |
| `/guard` | Activates both /careful and /freeze |
| Auto-deny | Blocks git commit, git push, rm -rf, and force reset |

---

## Skills Reference

### Planning

| Skill | Trigger | What it does |
|---|---|---|
| `office-hours` | `/office-hours` | YC Office Hours forcing questions before code |
| `plan-eng-review` | ask for "eng review" | Architecture review with diagrams and test matrices |
| `plan-design-review` | ask for "design review" | Design evaluation rated 0-10 |

### Development

| Skill | Trigger | What it does |
|---|---|---|
| `backend-dev-guidelines` | auto on backend code | Layered architecture, services, repositories, middleware |
| `frontend-dev-guidelines` | auto on frontend code | React patterns, Suspense, TanStack Query/Router |
| `python-patterns` | auto on Python code | PEP 8, type hints, async patterns |
| `docker-patterns` | ask about Docker | Multi-stage builds, compose, image optimization |
| `postgres-patterns` | ask about PostgreSQL | Queries, indexing, migrations, performance tuning |
| `deployment-patterns` | ask about deployment | CI/CD, blue-green, canary strategies |
| `ui-styling` | auto on UI/CSS work | shadcn/ui, Tailwind CSS, 40+ fonts |
| `ui-ux-pro-max` | ask about design decisions | 67 UI styles, 161 palettes, 57 fonts, 99 UX guidelines, 25 chart types |
| `shadcn-ui` | ask about shadcn/ui | shadcn/ui component composition, theming, registry, OKLCH tokens |
| `code-refactor` | ask to refactor | Grep + Edit workflow for bulk refactoring |

### Review and Testing

| Skill | Trigger | What it does |
|---|---|---|
| `review` | `/review-staff` | Staff engineer code review |
| `security-review` | auto on security changes | OWASP patterns, secrets, injection, auth |
| `security-scan` | ask for "security scan" | Claude Code config audit, severity grades A-F |
| `tdd-workflow` | auto on test writing | RED-GREEN-REFACTOR, 80%+ coverage |
| `e2e-testing` | auto on Playwright | Page Object Model, flaky test strategies |
| `webapp-testing` | ask to test a local webapp | Python-driven Playwright workflow for local app and browser verification |
| `qa` | `/qa` | Browser QA: find bugs, fix them, generate tests |
| `verification-loop` | auto on verification | 6-phase: build, type, lint, test, security, diff |

### AI/Agent and Autonomous

| Skill | Trigger | What it does |
|---|---|---|
| `super-ralph` | `/super-ralph` | Fully autonomous multi-agent development (brainstorm or oneshot) |
| `codex` (oiloil) | `/codex` and optional background auto-trigger | Delegate coding to Codex CLI via `ask_codex.sh`, plus cross-model review (review/challenge/consult) |
| `gstack codex` | internal to `/review-staff` | Enhanced cross-model review with telemetry, platform detection, and plan file integration |
| `autoresearch` | `/autoresearch` | Karpathy-style ML experiment loops |
| `agentic-engineering` | ask about "agent development" | Agent development patterns |

### Research and Content

| Skill | Trigger | What it does |
|---|---|---|
| `deep-research` | `/deep-research` or ask for "deep research" | Multi-source research with synthesis |
| `professional-research-writing` | always active | Writing style guide |
| `pdf-processing-pro` | auto on PDF work | PDF extraction, forms, tables, OCR |
| `web-artifacts-builder` | ask for a self-contained HTML artifact | Bundle React, Tailwind, and shadcn/ui output into a single HTML artifact |

---

## Selected Commands

The repo tracks 20 slash commands. Common entry points are listed below.

| Command | Purpose |
|---|---|
| `/office-hours` | Pre-dev brainstorming |
| `/qa` | Browser QA testing + bug fixing |
| `/review-staff` | Staff engineer code review |
| `/investigate` | Root-cause debugging |
| `/codex` | Cross-model review (review/challenge/consult) |
| `/super-ralph` | Autonomous multi-agent execution (brainstorm or oneshot) |
| `/autoresearch` | ML experiment loop |
| `/careful` | Safety guardrails |
| `/freeze` | Restrict edit scope |
| `/guard` | Enable careful + freeze |
| `/build-fix` | Auto-fix build errors |
| `/quality-gate` | Quality gating |
| `/checkpoint` | Session checkpoint |
| `/dev-docs` | Generate dev docs |

---

## Agents

14 specialized agents handle complex tasks:

| Agent | Purpose |
|---|---|
| `architect` | Architecture design |
| `build-error-resolver` | Automated build error resolution |
| `code-refactor-master` | Large-scale code transformations |
| `database-reviewer` | Schema, query, migration review |
| `documentation-system` | Documentation generation |
| `frontend-developer` | React component development |
| `frontend-error-fixer` | TypeScript, React, CSS error resolution |
| `plan-reviewer` | Implementation plan validation |
| `research-search-system` | Multi-source research with synthesis |
| `task-orchestrator` | Task decomposition |
| `ui-ux-designer` | UI/UX design decisions |
| `architecture-review-system` | Architecture review and improvement |
| `auto-error-resolver` | Automated error resolution post-hook |
| `context-manager` | Conversation context and state management |

---

## Hooks System

Automated hooks run at every stage of your workflow:

| Hook | When | What it does |
|---|---|---|
| `check-careful.sh` | Before Bash | Warns before destructive commands (gstack skill) |
| `check-freeze.sh` | Before Edit/MultiEdit/Write | Blocks edits outside frozen directory (gstack skill) |
| `check-mcp.sh` | Before MCP tools | Records every MCP invocation, warns on mutating endpoints |
| `task-orchestrator-hook.sh` | On prompt | Detects analysis vs coding tasks |
| `skill-activation-prompt.sh` | On prompt | Suggests skills via 600+ keyword triggers |
| `auto-codex-trigger.sh` | On prompt | Auto-launches Codex in background for coding tasks |
| `memory-bootstrap.sh` | On prompt | Surfaces repo-local memory when it exists |
| `post-tool-use-tracker.sh` | After Edit/MultiEdit/Write | Tracks edited files |
| `tsc-check.sh` | After Edit/MultiEdit/Write | Runs TypeScript checks |
| `lint-check.sh` | After Edit/MultiEdit/Write | Runs project-native linter (ruff/eslint/biome/shellcheck) on edited files |
| `workflow-step-tracker.sh` | After Bash/Skill/MCP | Marks workflow completion |
| `session-start.sh` | Session start | Validates required local tools, bootstraps local settings, and injects baseline repo context |
| `session-end.sh` | Session close | Appends session-close summary, rotates sessions log |
| `pre-compact.sh` | Before context compaction | Snapshots in-progress state to `runtime/last-precompact.md` |
| `stop-build-check-enhanced.sh` | Session stop | Re-runs all checks |
| `workflow-completion-gate.sh` | Session stop | Advisory reminders, cleanup |

---

## MCP Servers

| Server | Capabilities |
|---|---|
| **Figma** | Read designs, screenshots, diagrams, Code Connect |
| **GitHub** | Repos, issues, PRs, reviews |
| **Playwright** | Browser automation, testing |
| **Hugging Face** | Model/dataset/paper search, training |
| **filesystem** | Read/write files |
| **memory** | Persistent entity/relation graph |
| **chrome** | Browser automation with screenshots |
| **context7** | Live library documentation |
| **Scholar Gateway** | Academic paper search |
| **PDF Viewer** | PDF display and reading |
| **Optional user-scoped connectors** | Additional project-specific services outside the shared repo config |

---

## Prompt Templates

Ready-to-use templates at `.claude/prompt-templates/`:

| Template | Purpose | Placeholders |
|---|---|---|
| `feature-implementation.md` | Multi-agent feature development | `[TASK]`, `[DIRECTORY]`, `[API]` |
| `debug.md` | Root-cause debugging with safety scoping | `[BUG]`, `[DIRECTORY]` |
| `code-quality.md` | Code review, refactoring, security audit | `[DIRECTORY]`, `[MODE]` |
| `super-ralph.md` | Fully autonomous multi-agent implementation (brainstorm or oneshot) | `[TASK]`, `[DIRECTORY]` |
| `gstack-sprint.md` | Full Think-Plan-Build-Review-Test-Ship sprint | `[GOAL]`, `[TARGET_URL]` |
| `design-to-code.md` | Figma/design to production code pipeline | `[FIGMA_URL]`, `[TARGET_STACK]` |

---

## Project Structure

```
.claude/
  CLAUDE.md              # Core rules and coding style
  CLAUDE-testing.md      # Testing methodology
  CLAUDE-skills.md       # Skills inventory reference
  WORKFLOW-REFERENCE.md  # Complete reference (single source of truth)
  settings.json          # Permissions, hooks, plugins, env
  runtime/               # Repo-local ignored runtime state for safety and Codex
  agents/                # 14 local agent definitions
  commands/              # 20 slash commands
  hooks/                 # 10 local hook scripts
  prompt-templates/      # 4 reusable templates
  skills/                # 26 skill entries
    skill-rules.json     # 400+ keyword trigger engine
    [local skills]       # Backend, frontend, testing, research, and utility skills
social/                  # Social media assets and demo video
```

---

## Acknowledgments

This workflow integrates and builds upon the work of incredible community projects:

| Project | Author | Contribution |
|---|---|---|
| [gstack](https://github.com/garrytan/gstack) | @garrytan | Think-Plan-Build-Review-Test-Ship-Reflect cycle |
| [Super Ralph](https://github.com/ashcastelinocs124/super-ralph) | @ashcastelinocs124 | Autonomous multi-agent execution |
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | @affaan-m | Claude Code patterns and community resources |
| Codex skill | @oiloil | Cross-model review via Codex CLI |
| autoresearch | Karpathy-inspired | Autonomous ML research loops |
| Agentic Engineering | Cognition's ECC | Eval-driven development patterns |
| Continuous Claude | @AnandChowdhary | Continuous PR loop pattern |
| Infinite Agentic Loop | @disler | Self-running agent pattern |
| Ralphinho | @enitrat | RFC-driven DAG orchestration |
| Official Plugins | Anthropic | Superpowers, feature-dev, code-review, Figma, Playwright, GitHub, HuggingFace |
| shadcn/ui | shadcn | Component patterns |
| Context7 | Context7 | Library documentation |

---

## License

MIT
