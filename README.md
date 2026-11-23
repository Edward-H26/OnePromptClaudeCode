# OnePromptClaudeCode

**One prompt is all you need.**

A complete Claude Code workflow that covers the entire software development lifecycle. Clone it, start coding, and never write a prompt from scratch again.

95 skill entries. 71 commands. 7 agents. 8 local hooks. 4 templates. 10 shared MCP servers.

Built for beginners. Scales for power users.

---

## Why This Exists

Every Claude Code user hits the same wall:

1. Writing the same prompts from scratch on every project
2. Finding great community tools (gstack, Superpowers, everything-claude-code) but struggling to combine them
3. Missing features they don't even know exist

OnePromptClaudeCode solves all three. It integrates the best of the Claude Code ecosystem into one workflow in which Claude searches the installed skills and picks the right ones for each task.

---

## Quick Start

```bash
git clone https://github.com/Edward-H26/OnePromptClaudeCode.git
cd OnePromptClaudeCode
bash scripts/doctor-workflow.sh        # verify hooks, skills, and settings
claude
```

That gets the workflow running **inside this repo only**. Claude Code discovers
user-scope skills under `~/.claude/skills`, so until you link them, no skill here
loads in your other projects. To go global, let this repo own `~/.claude`:

```bash
bash scripts/install.sh --apply        # let this repo own ~/.claude (settings, hooks, skills and more)
bash scripts/install.sh --check        # preview what --apply would change
```

`--apply` links `~/.claude/settings.json` to the tracked
user-scope [`.claude/settings.user.json`](.claude/settings.user.json), and links
hooks, skills, agents, commands, `CLAUDE.md`, `statusline.sh` and `output-styles`
to this checkout, backing up existing real files to `~/.claude/.backup-<timestamp>/`
first. Every machine set up this way runs the same configuration, and any change
Claude Code saves to user settings lands in this checkout, ready to commit.
`.claude/settings.json` stays this repo's project settings. The user-scope file
turns on Code Mode, which needs Claude Code 2.1.326 or later from the native
installer and asks once per machine to confirm.

That is the repo setup. `bash scripts/doctor-workflow.sh` auto-creates or merges `.claude/settings.local.json` from the tracked `.claude/settings.local.example.json`, so a fresh clone does not require a manual local-settings copy step. Shared Remotion MCP servers now live in the tracked [`.mcp.json`](.mcp.json), which keeps project-scoped tool wiring out of machine-local settings. The tracked settings enable the plugin set the maintainer uses day to day, including context7, Figma, Playwright, Chrome DevTools MCP, `superpowers`, security-guidance and [show-your-work](https://github.com/iamumeransari/claude-show-your-work) (pictures and videos of Claude's work in Ghostty or kitty, from the `iamumeransari` marketplace on its `releases` branch); GitHub, Hugging Face and Greptile stay off. On a machine where one of them is not installed or signed in, turn it off in `.claude/settings.local.json`, whose values win over the shared config. Run `bash scripts/doctor-workflow.sh` on a fresh clone to confirm the live workflow is ready, and clear any stale local plugin blocklist test entries if the doctor warns about them. After workflow changes, run `bash scripts/audit-workflow.sh`.

---

## How It Works

Claude chooses the skills itself: before starting a task it searches the installed skills (the session's skill list and `~/.claude/skills`) for the ones that fit, uses them, and names them in the reply, as the Skills line of `.claude/CLAUDE.md` says. For example:

| You do this | Claude can use |
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
- Turn off, in `.claude/settings.local.json`, any shared plugin this machine has not installed or signed in to.
- `bash scripts/doctor-workflow.sh` auto-seeds `.claude/settings.local.json` from the tracked example on first run, then preserves local overrides on later merges.
- Ensure required MCP connectors and auth are healthy for the tools you actually use.
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
| **Skills** | 95 | Bundled workflow skill entries available directly from the tracked repo |
| **Commands** | 71 | Slash commands for planning, implementation, review, QA, and release handoff |
| **Agents** | 7 | Specialized local agents for complex tasks |
| **Hooks** | 8 | Type/lint checks and workflow hooks (all local) |
| **Templates** | 4 | Reusable prompt templates for common workflows |
| **MCP Servers** | 10 | Figma, GitHub, context7, Chrome DevTools, Playwright, and other shared or user-scoped connectors |

### Development Lifecycle

The workflow follows a structured sprint cycle: **Think, Plan, Build, Review, Test, Ship, Reflect**.

| Phase | What happens | Key commands |
|---|---|---|
| **Think** | YC-style brainstorming | `/office-hours` |
| **Plan** | Architecture review and design plan review | `/plan-eng-review`, `/plan-design-review` |
| **Review** | Staff engineer code review, OWASP security scanning | `/review-staff` |
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
| `ponytail` | always active through `.claude/CLAUDE.md` (`/ponytail lite/full/ultra/off`) | Lazy senior-dev mode: minimal solution via the YAGNI ladder, never cutting validation, security, or accessibility |

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

The repo tracks 71 slash commands. Common entry points are listed below.

| Command | Purpose |
|---|---|
| `/office-hours` | Pre-dev brainstorming |
| `/qa` | Browser QA testing + bug fixing |
| `/review-staff` | Staff engineer code review |
| `/investigate` | Root-cause debugging |
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

7 role agents handle delegated work:

| Agent | Purpose |
|---|---|
| `designer` | Design notes with no code (Fable 5.2, xhigh) |
| `builder` | Large code: research code and implementation that needs judgment (Opus 5.5, xhigh) |
| `writer` | Small edits and small code from an exact spec (Sonnet 5.5, max) |
| `verifier` | PASS or FAIL verification of one delivery by running it (Opus 5.5, xhigh) |
| `checker` | Final verification once per push on the exact tree that ships (Fable 5.2, max) |
| `explorer` | Read-only search, and the context pack that costlier agents start from (Haiku 5.5, max) |
| `runner` | Runs tests, builds and commands exactly as given and reports the result (Haiku 5.5, max) |

---

## Hooks System

Automated hooks run at every stage of your workflow:

| Hook | When | What it does |
|---|---|---|
| `post-edit-check.sh` | After Edit/MultiEdit/Write | Runs TypeScript checks on affected repos, the native linter (ruff/eslint/biome/shellcheck) on edited files, a Python check (pyright or ruff) on edited `.py` files, and records the edit log |
| `workflow-completion-gate.sh` | Session stop | Reminds to verify frontend changes in the browser, and cleans stale cache |
| `session-start.sh` | Session start | Validates required local tools, bootstraps local settings, and injects baseline repo context |
| `compact-keep.sh` | Before compaction | Tells the compaction summary what to keep |
| `compact-restore.sh` | After compaction | Reads the handoff file, the newest memory files and recent commits back into context |
| `post-tool-use-tracker.sh` | After Edit/MultiEdit/Write | Logs edited files and queues TypeScript checks for the affected repos |
| `workflow-step-tracker.sh` | After Bash, Skill and browser tools | Records workflow-step markers for the session |
| `stop-build-check-enhanced.sh` | Session stop | Reruns the queued TypeScript checks and reports any errors |

`.claude/settings.json` wires the first five hooks for this repo. `.claude/settings.user.json` wires the last three, plus the compaction pair, for every project once `install.sh --apply` links it.

---

## MCP Servers

| Server | Capabilities |
|---|---|
| **Figma** | Read designs, screenshots, diagrams, Code Connect |
| **GitHub** | Repos, issues, PRs, reviews |
| **Playwright** | Browser automation, testing |
| **chrome** | Browser automation with screenshots |
| **chrome-devtools** | DevTools protocol: console, network, performance traces, Lighthouse |
| **context7** | Live library documentation |
| **computer-use** | Desktop screenshots and native-app control |
| **remotion-docs** | Remotion documentation lookup |
| **remotion-app** | Remotion project scaffolding and rendering |
| **Google Drive** | claude.ai connector for Drive files |
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
  settings.user.json     # User-scope settings that install.sh --apply links to ~/.claude
  output-styles/         # Output styles linked by install.sh --apply
  runtime/               # Repo-local ignored runtime state for safety and workflow artifacts
  agents/                # 7 role agent definitions
  commands/              # 71 slash commands
  hooks/                 # 8 local hook scripts
  prompt-templates/      # 4 reusable templates
  skills/                # 95 skill entries
    skill-rules.json     # Skill list the audit and doctor match against the skill folders
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
| autoresearch | Karpathy-inspired | Autonomous ML research loops |
| Agentic Engineering | Cognition's ECC | Eval-driven development patterns |
| Continuous Claude | @AnandChowdhary | Continuous PR loop pattern |
| Infinite Agentic Loop | @disler | Self-running agent pattern |
| Ralphinho | @enitrat | RFC-driven DAG orchestration |
| Official Plugins | Anthropic | Superpowers, feature-dev, code-review, code-simplifier, frontend-design, context7, Figma, Playwright, Chrome DevTools MCP, security-guidance |
| shadcn/ui | shadcn | Component patterns |
| Context7 | Context7 | Library documentation |
| [CCFA-Skills](https://github.com/mikubaka88/CCFA-Skills) | @mikubaka88 | The 17 `ccf-*` skills for CCF conference research, vendored under MIT (see `.claude/skills/CCFA-SKILLS-LICENSE`) |

---

## License

MIT
