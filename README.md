# OnePromptClaudeCode

**One prompt is all you need.**

A complete Claude Code workflow that covers the entire software development lifecycle. Clone it, start coding, and never write a prompt from scratch again.

54 skills. 21 commands. 16 agents. 10 hooks. 6 templates. 12+ MCP servers. 400+ auto-triggers.

Built for beginners. Scales for power users.

---

## Why This Exists

Every Claude Code user hits the same wall:

1. Writing the same prompts from scratch on every project
2. Finding great community tools (gstack, Superpowers, everything-claude-code) but struggling to combine them
3. Missing features they don't even know exist

OnePromptClaudeCode solves all three. It integrates the best of the Claude Code ecosystem into one workflow with a 400+ keyword trigger engine that activates the right skills automatically.

---

## Quick Start

```bash
git clone https://github.com/Edward-H26/OnePromptClaudeCode.git
cd OnePromptClaudeCode
claude
```

That's it. Skills suggest themselves. Hooks catch your mistakes. Agents handle the complex parts.

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
| Type `/ship` | Full release pipeline |

Zero commands to memorize. Zero prompts to write. Zero configuration.

---

## What's Inside

### At a Glance

| Component | Count | Description |
|---|---|---|
| **Skills** | 54 | Auto-activated by 400+ keyword triggers |
| **Commands** | 21 | Slash commands for every workflow phase |
| **Agents** | 16 | Specialized agents for complex tasks |
| **Hooks** | 10 | Automated safety and quality gates |
| **Templates** | 6 | Reusable prompt templates for common workflows |
| **MCP Servers** | 12+ | Figma, GitHub, Playwright, MongoDB, HuggingFace, and more |

### Development Lifecycle

The workflow follows a structured sprint cycle: **Think, Plan, Build, Review, Test, Ship, Reflect**.

| Phase | What happens | Key commands |
|---|---|---|
| **Think** | YC-style brainstorming, product strategy review | `/office-hours` |
| **Plan** | Architecture review, design consultation, eng review | `/plan-eng-review`, `/plan-design-review` |
| **Build** | Auto-skills for React, Node, Python, Docker, PostgreSQL | `/build-fix`, `/orchestrate` |
| **Review** | Staff engineer code review, OWASP security scanning | `/review-staff`, `/codex review` |
| **Test** | TDD, Playwright E2E, browser QA that fixes what it finds | `/qa`, `/quality-gate` |
| **Ship** | One-command release pipeline with changelog | `/ship` |
| **Reflect** | Weekly retrospectives with shipping metrics | `/retro` |

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
| `plan-ceo-review` | ask for "ceo review" | Product strategy review with 4 scope modes |
| `plan-eng-review` | ask for "eng review" | Architecture review with diagrams and test matrices |
| `plan-design-review` | ask for "design review" | Design evaluation rated 0-10 |
| `design-consultation` | ask for "design consultation" | Full design system generation |

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
| `code-refactor` | ask to refactor | Grep + Edit workflow for bulk refactoring |

### Review and Testing

| Skill | Trigger | What it does |
|---|---|---|
| `review` | `/review-staff` | Staff engineer code review |
| `security-review` | auto on security changes | OWASP patterns, secrets, injection, auth |
| `security-scan` | ask for "security scan" | Claude Code config audit, severity grades A-F |
| `tdd-workflow` | auto on test writing | RED-GREEN-REFACTOR, 80%+ coverage |
| `e2e-testing` | auto on Playwright | Page Object Model, flaky test strategies |
| `qa` | `/qa` | Browser QA: find bugs, fix them, generate tests |
| `verification-loop` | auto on verification | 6-phase: build, type, lint, test, security, diff |

### AI/Agent and Autonomous

| Skill | Trigger | What it does |
|---|---|---|
| `super-ralph` | `/super-ralph` | Fully autonomous multi-agent development |
| `codex` | `/codex` | Cross-model review using OpenAI's Codex CLI |
| `autoresearch` | `/autoresearch` | Karpathy-style ML experiment loops |
| `autonomous-loops` | ask about "autonomous loop" | Continuous agent loop patterns |
| `agentic-engineering` | ask about "agent development" | Agent development patterns |

### Research and Content

| Skill | Trigger | What it does |
|---|---|---|
| `deep-research` | ask for "deep research" | Multi-source research with synthesis |
| `professional-research-writing` | always active | Writing style guide |
| `pdf-processing-pro` | auto on PDF work | PDF extraction, forms, tables, OCR |

---

## Commands

| Command | Purpose |
|---|---|
| `/office-hours` | Pre-dev brainstorming |
| `/ship` | Release readiness pipeline |
| `/qa` | Browser QA testing + bug fixing |
| `/review-staff` | Staff engineer code review |
| `/investigate` | Root-cause debugging |
| `/codex` | Cross-model review (review/challenge/consult) |
| `/super-ralph` | Autonomous multi-agent execution |
| `/orchestrate` | Sequential agent orchestration |
| `/autoresearch` | ML experiment loop |
| `/careful` | Safety guardrails |
| `/freeze` | Restrict edit scope |
| `/guard` | Enable careful + freeze |
| `/retro` | Weekly retrospective |
| `/build-fix` | Auto-fix build errors |
| `/quality-gate` | Quality gating |
| `/checkpoint` | Session checkpoint |
| `/dev-docs` | Generate dev docs |
| `/multi-plan` | Multi-model planning |
| `/multi-execute` | Multi-model execution |

---

## Agents

16 specialized agents handle complex tasks:

| Agent | Purpose |
|---|---|
| `architect` | Architecture design |
| `build-error-resolver` | Automated build error resolution |
| `chief-of-staff` | Project management and coordination |
| `code-refactor-master` | Large-scale code transformations |
| `database-reviewer` | Schema, query, migration review |
| `documentation-system` | Documentation generation |
| `frontend-developer` | React component development |
| `frontend-error-fixer` | TypeScript, React, CSS error resolution |
| `plan-reviewer` | Implementation plan validation |
| `research-search-system` | Multi-source research with synthesis |
| `task-orchestrator` | Task decomposition |
| `ui-ux-designer` | UI/UX design decisions |

---

## Hooks System

Automated hooks run at every stage of your workflow:

| Hook | When | What it does |
|---|---|---|
| `check-careful.sh` | Before Bash | Warns before destructive commands |
| `check-freeze.sh` | Before Edit/Write | Blocks edits outside frozen directory |
| `task-orchestrator-hook.sh` | On prompt | Detects analysis vs coding tasks |
| `skill-activation-prompt.sh` | On prompt | Suggests skills via 400+ keyword triggers |
| `post-tool-use-tracker.sh` | After Edit/Write | Tracks edited files |
| `tsc-check.sh` | After Edit/Write | Runs TypeScript checks |
| `workflow-step-tracker.sh` | After Bash/Skill/MCP | Marks workflow completion |
| `stop-build-check-enhanced.sh` | Session end | Re-runs all checks |
| `workflow-completion-gate.sh` | Session end | Advisory reminders, cleanup |

---

## MCP Servers

| Server | Capabilities |
|---|---|
| **Figma** | Read designs, screenshots, diagrams, Code Connect |
| **GitHub** | Repos, issues, PRs, reviews |
| **Playwright** | Browser automation, testing |
| **MongoDB** | Query, aggregate, schema, CRUD |
| **Hugging Face** | Model/dataset/paper search, training |
| **filesystem** | Read/write files |
| **memory** | Persistent entity/relation graph |
| **chrome** | Browser automation with screenshots |
| **context7** | Live library documentation |
| **Scholar Gateway** | Academic paper search |
| **PDF Viewer** | PDF display and reading |

---

## Prompt Templates

Ready-to-use templates at `.claude/prompt-templates/`:

| Template | Purpose | Placeholders |
|---|---|---|
| `feature-implementation.md` | Multi-agent feature development | `[TASK]`, `[DIRECTORY]`, `[API]` |
| `debug.md` | Root-cause debugging with safety scoping | `[BUG]`, `[DIRECTORY]` |
| `code-quality.md` | Code review, refactoring, security audit | `[DIRECTORY]`, `[MODE]` |
| `super-ralph.md` | Fully autonomous multi-agent implementation | `[TASK]`, `[DIRECTORY]` |
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
  agents/                # 16 agent definitions
  commands/              # 21 slash commands
  hooks/                 # 10 automated hook scripts
  prompt-templates/      # 6 reusable templates
  skills/                # 54 skill directories
    skill-rules.json     # 400+ keyword trigger engine
    gstack/              # Vendored gstack bundle
    super-ralph/         # Vendored super-ralph bundle
    [32 local skills]    # Backend, frontend, testing, etc.
    [20 symlinks]        # Aliases to gstack sub-skills
references/              # Setup scripts for upstream repos
social/                  # Social media assets and demo video
```

---

## Updating Vendored Bundles

gstack and super-ralph are vendored from upstream repos. To update:

```bash
bash references/update-references.sh
```

This pulls latest changes and re-syncs into `.claude/skills/`.

---

## Acknowledgments

This workflow integrates and builds upon the work of incredible community projects:

| Project | Author | Contribution |
|---|---|---|
| [gstack](https://github.com/garrytan/gstack) | @garrytan | Think-Plan-Build-Review-Test-Ship-Reflect cycle |
| [Super Ralph](https://github.com/ashcastelinocs124/super-ralph) | @ashcastelinocs124 | Autonomous multi-agent execution |
| [everything-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | @hesreallyhim | Claude Code patterns and community resources |
| Codex skill | @oiloil | Cross-model review via Codex CLI |
| autoresearch | Karpathy-inspired | Autonomous ML research loops |
| Agentic Engineering | Cognition's ECC | Eval-driven development patterns |
| Continuous Claude | @AnandChowdhary | Continuous PR loop pattern |
| Infinite Agentic Loop | @disler | Self-running agent pattern |
| Ralphinho | @enitrat | RFC-driven DAG orchestration |
| Official Plugins | Anthropic | Superpowers, feature-dev, code-review, Figma, Playwright, HuggingFace |
| shadcn/ui | shadcn | Component patterns |
| Context7 | Context7 | Library documentation |

---

## License

MIT
