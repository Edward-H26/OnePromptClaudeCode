# Complete Workflow Reference

> Single source of truth for all skills, commands, agents, MCP servers, plugins, hooks, and prompt templates.

## Workflow Overview

This workflow follows a structured sprint cycle: **Think, Plan, Build, Review, Test, Ship, Reflect**. Each phase has dedicated skills that feed into the next. Skills are activated automatically via keyword triggers or manually via slash commands.

**Global config**: On some local setups, a user-scoped Claude home directory may be symlinked to this project directory. This is a machine-specific convention, not a requirement of the published repo.
**Repo-local multi-model flow**: `/multi-plan` and `/multi-execute` use the bundled Codex bridge plus installed plugin agents. The Codex bridge now writes repo-local runtime state under `.claude/runtime/codex/`.
**Published surface**: This repo tracks the workflow content it runs, including bundled `super-ralph`, bundled `ui-styling` assets, repo-local wrapper skills, and the vendored upstream sources under `references/` that those wrappers and a smaller set of vendored passthrough skills may consult. Reference refreshes are curated and prune upstream runtime-only artifacts that are not part of this repo's published workflow surface.
**Live readiness**: Use `bash scripts/doctor-workflow.sh` for plugin, MCP, and Codex runtime checks. Use `bash scripts/audit-workflow.sh` for static repo-surface validation.
**Plugin split**: The tracked shared config enables only the repo-stable baseline. Auth-sensitive or duplicate integrations such as GitHub, context7, or plugin-provided Figma/Playwright MCP servers belong in `.claude/settings.local.json`. Use `.claude/settings.local.example.json` as the tracked starting point for those local overrides; it lists the optional plugins but leaves them disabled until a local machine explicitly enables them. If `bash scripts/doctor-workflow.sh` warns about enabled plugins that are also blocklisted in ignored local state, clear the stale local blocklist entry before relying on that plugin.

---

## Skills Reference

### Planning Skills

| Skill | Trigger | What it does |
|---|---|---|
| `office-hours` | `/office-hours` | Pre-development brainstorming. YC Office Hours forcing questions before code. Produces a design doc, never code. |
| `plan-ceo-review` | `/plan-ceo-review` or ask for "ceo review" | Product strategy review. Four scope modes: expansion, hold, selective expansion, reduction. |
| `plan-eng-review` | `/plan-eng-review` or ask for "eng review" | Architecture review with diagrams, data flow, edge cases, test matrices. |
| `plan-design-review` | `/plan-design-review` or ask for "design review" | Design dimension evaluation rated 0-10. Detects AI slop. |
| `design-consultation` | `/design-consultation` or ask for "design consultation" | Full design system generation with competitive research and mockups. |

### Development Skills

| Skill | Trigger | What it does |
|---|---|---|
| `backend-dev-guidelines` | auto on backend code | Layered architecture, BaseController, services, repositories, middleware, testing. |
| `frontend-dev-guidelines` | auto on frontend code | React patterns, Suspense, TanStack Query/Router, file organization, TypeScript. |
| `python-patterns` | auto on Python code | PEP 8, type hints, idioms, async patterns. |
| `docker-patterns` | ask about Docker | Dockerfile best practices, multi-stage builds, compose, image optimization. |
| `postgres-patterns` | ask about PostgreSQL | Queries, indexing, migrations, performance tuning, schema design. |
| `deployment-patterns` | ask about deployment | CI/CD, staging, rollback, blue-green, canary strategies. |
| `search-first` | ask to "search first" | Explore existing code before writing new code. Codebase search methodology. |
| `code-refactor` | ask to refactor | Grep + Edit workflow for bulk refactoring with verification. |
| `ui-styling` | auto on UI/CSS work | shadcn/ui components, Tailwind CSS, canvas-based design, 40+ fonts. |
| `ui-ux-pro-max` | ask about design decisions | 67 UI styles, 161 color palettes, 57 font pairings, 99 UX guidelines, 25 chart types. Design system generation across 15+ stacks. |
| `shadcn-ui` | ask about shadcn/ui | shadcn/ui component composition, theming, registry workflow, and OKLCH tokens. |
| `liquid-glass-design` | ask for "glass design" | Modern glassmorphic UI: translucent layers, depth, frosted effects. |

### Review Skills

| Skill | Trigger | What it does |
|---|---|---|
| `review` | `/review-staff` | Staff engineer code review with findings-first output for this repo. |
| `design-review` | `/design-review` or ask for "design review fix" | Design audit with repo-local fixes and before/after screenshots when available. |
| `security-review` | auto on security changes | OWASP patterns: secrets, input validation, SQL injection, XSS, CSRF, auth, rate limiting. |
| `security-scan` | ask for "security scan" | Claude Code config audit using AgentShield or manual checklist. Severity grades A-F. |

### Testing Skills

| Skill | Trigger | What it does |
|---|---|---|
| `tdd-workflow` | auto on test writing | RED-GREEN-REFACTOR cycle, unit/integration/E2E patterns, 80%+ coverage target. |
| `e2e-testing` | auto on E2E/Playwright | Playwright patterns, Page Object Model, flaky test strategies, CI/CD. |
| `webapp-testing` | ask to test a local webapp | Python-driven Playwright workflow for local app lifecycle, screenshots, and browser verification. |
| `qa` | `/qa` | Browser-based QA: test app, find bugs, apply minimal fixes, and re-verify. |
| `qa-only` | `/qa-only` | Same as qa but report-only, no code changes. |
| `verification-loop` | auto on verification | 6-phase verification: build, type, lint, test, security, diff. |
| `eval-harness` | ask about evals | Evaluation frameworks for testing agent and model quality. |

### Debugging Skills

| Skill | Trigger | What it does |
|---|---|---|
| `systematic-debugging` | auto on bugs/errors | 4-phase root cause methodology with red flags and rationalization checklist. |
| `investigate` | `/investigate` | Systematic debugging with hypothesis testing. Stops after 3 failed fixes. |

### Shipping Skills

| Skill | Trigger | What it does |
|---|---|---|
| `ship` | `/ship` | Release-readiness pipeline: sync base, test, coverage audit, version bump, changelog, and final user handoff before any user-run commit or push. |
| `document-release` | `/document-release` | Auto-update project docs (README, ARCHITECTURE, CONTRIBUTING) to match shipped changes. |
| `retro` | `/retro` | Weekly retrospective with metrics, per-person breakdowns, shipping streaks, test health. |

### Safety Skills

| Skill | Trigger | What it does |
|---|---|---|
| `careful` | `/careful` or "be careful" | Warns before destructive commands: rm -rf, DROP TABLE, force-push, git reset. Session-scoped. |
| `freeze` | `/freeze` | Restricts file edits to a single directory. Prevents accidental changes during debugging. |
| `unfreeze` | `/unfreeze` | Removes /freeze edit restrictions. |
| `guard` | `/guard` or "full safety" | Combined: activates both /careful and /freeze. |

### AI/Agent Skills

| Skill | Trigger | What it does |
|---|---|---|
| `codex` (oiloil) | `/codex` or auto-trigger | Delegate coding tasks to Codex CLI via bundled `ask_codex.sh`. Also provides cross-model review modes (review/challenge/consult) via direct `codex` CLI. |
| `gstack codex` | internal to gstack workflow | Enhanced cross-model review within gstack. Adds telemetry, GitHub/GitLab platform detection, plan file integration, and session management. Used internally by `/review-staff`. |
| `agentic-engineering` | ask about "agent development" | Agent development patterns: tool use, loops, error handling, context management. |
| `autonomous-loops` | ask about "autonomous loop" | Continuous agent loop patterns for self-running iterative workflows. |
| `claude-api` | ask about "Claude API" | Claude API and Anthropic SDK patterns for programmatic integration. |

### Research and Content Skills

| Skill | Trigger | What it does |
|---|---|---|
| `deep-research` | ask for "deep research" | Multi-source research workflow using WebFetch/WebSearch with synthesis rules. |
| `autoresearch` | `/autoresearch` | Karpathy's autoresearch framework: iterative train.py modification, hypothesis testing, result logging. |
| `professional-research-writing` | always active | Writing style guide: participial phrases, sentence construction, paragraph structure. Dash prohibition. |
| `pdf-processing-pro` | auto on PDF work | PDF text extraction, form analysis, table extraction, OCR. |
| `web-artifacts-builder` | ask for a self-contained HTML artifact | Bundle React, Tailwind, and shadcn/ui output into a single HTML artifact. |

### Utility Skills

| Skill | Trigger | What it does |
|---|---|---|
| `skill-developer` | ask about skills/hooks | Meta-skill for creating and managing Claude Code skills, hooks, commands, agents. |
| `strategic-compact` | at phase boundaries | Strategic context compaction. Decision guide for when to compact. |
| `super-ralph` | `/super-ralph` | Local wrapper skill that dispatches into the bundled autonomous workflow under `.claude/skills/super-ralph/`. Supports oneshot mode for zero-setup execution. |
| `chrome-devtools` | ask about Chrome DevTools | Node.js scripts for Chrome DevTools Protocol: navigate, screenshot, console, evaluate, network. |
| `browse` | ask to "open browser" | Repo-local browser workflow that uses the tooling available in this environment. |
| `setup-browser-cookies` | ask about browser cookies | Import cookies from Chrome, Arc, Brave, Edge for authenticated testing. |
| `gstack-upgrade` | ask to "upgrade gstack" | Refreshes the vendored gstack snapshot tracked in this repo. |

---

## Commands Reference

| Command | Purpose | Usage |
|---|---|---|
| `/design-consultation` | Design-system planning | `/design-consultation <brief>` |
| `/design-review` | UI review and fixes | `/design-review <scope>` |
| `/office-hours` | Pre-dev brainstorming | `/office-hours <idea description>` |
| `/ship` | Release readiness | `/ship` (auto-detects base branch) |
| `/qa` | Browser QA testing | `/qa <url or instructions>` |
| `/qa-only` | Browser QA report only | `/qa-only <url or instructions>` |
| `/careful` | Safety guardrails | `/careful` (session-scoped) |
| `/freeze` | Restrict edit scope | `/freeze <directory>` |
| `/unfreeze` | Remove edit restrictions | `/unfreeze` |
| `/guard` | Enable careful plus freeze | `/guard <directory>` |
| `/plan-ceo-review` | Product scope review | `/plan-ceo-review <plan or prompt>` |
| `/plan-eng-review` | Architecture plan review | `/plan-eng-review <plan or prompt>` |
| `/plan-design-review` | Design plan review | `/plan-design-review <plan or prompt>` |
| `/review-staff` | Staff engineer review | `/review-staff <focus area>` |
| `/investigate` | Root-cause debugging | `/investigate <bug description>` |
| `/retro` | Retrospective | `/retro <period>` |
| `/document-release` | Update docs | `/document-release` |
| `/codex` | Coding delegation and cross-model review (oiloil) | `/codex review`, `/codex challenge`, `/codex <task>` |
| `/simplify` | Code simplification review | `/simplify <focus area>` |
| `/autoresearch` | ML experiment loop | `/autoresearch <hypothesis>` |
| `/super-ralph` | Autonomous execution (brainstorm or oneshot) | `/super-ralph <task>` |
| `/orchestrate` | Multi-agent orchestration | `/orchestrate <task description>` |
| `/multi-plan` | Repo-local multi-model planning | `/multi-plan <scope>` |
| `/multi-execute` | Repo-local multi-model execution | `/multi-execute <plan>` |
| `/quality-gate` | Quality gating | `/quality-gate` |
| `/build-fix` | Fix build errors | `/build-fix` |
| `/checkpoint` | Session checkpoint | `/checkpoint` |
| `/dev-docs` | Generate dev docs | `/dev-docs` |
| `/dev-docs-update` | Update dev docs | `/dev-docs-update` |
| `/route-research-for-testing` | Research routes | `/route-research-for-testing` |

---

## Agents Reference

| Agent | Purpose | When to use |
|---|---|---|
| `architect` | Architecture design | Designing system architecture with implementation focus |
| `architecture-review-system` | Architecture review | Reviewing existing architecture for issues |
| `build-error-resolver` | Fix build errors | Automated build error resolution |
| `auto-error-resolver` | Fix errors post-hook | Auto-triggered by tsc-check when errors exceed threshold |
| `code-refactor-master` | Bulk refactoring | Large-scale code transformations |
| `context-manager` | Context management | Managing conversation context and state |
| `database-reviewer` | Database review | Reviewing schemas, queries, migrations, indexes |
| `documentation-system` | Generate docs | Creating or updating project documentation |
| `frontend-developer` | Frontend work | Building React components, pages, layouts |
| `frontend-error-fixer` | Fix frontend errors | Resolving TypeScript, React, CSS errors |
| `plan-reviewer` | Review plans | Validating implementation plans before execution |
| `research-search-system` | Deep research | Multi-source research with synthesis |
| `task-orchestrator` | Task breakdown | Decomposing complex tasks into steps |
| `ui-ux-designer` | Design work | UI/UX design decisions and implementation |
| `ralph-*` (5 sub-agents) | Super-ralph system | Part of the bundled `super-ralph` workflow, not standalone agents |

---

## MCP Tooling

Availability depends on the local Claude installation, enabled plugins, ignored local plugin state, and any user-scoped MCP setup outside this repo.

| Server | Capabilities | Key tools |
|---|---|---|
| **Figma** | Read designs, get screenshots, create diagrams, Code Connect | `get_design_context`, `get_screenshot`, `generate_diagram` |
| **GitHub** | Repository search, issues, pull requests, and reviews | `search_repositories`, `create_pull_request`, `list_issues` |
| **Playwright** | Browser automation, click, fill, screenshot, evaluate | `browser_navigate`, `browser_click`, `browser_snapshot` |
| **Hugging Face** | Model/dataset/paper search, training jobs | `hub_repo_search`, `paper_search`, `dynamic_space` |
| **filesystem** | Read/write files across allowed directories | `read_file`, `write_file`, `search_files` |
| **memory** | Persistent entity/relation graph | `create_entities`, `search_nodes`, `add_observations` |
| **chrome** | Chrome browser automation with screenshots | `navigate`, `read_page`, `javascript_tool`, `gif_creator` |
| **puppeteer** | Headless browser automation (overlaps with Chrome and Playwright; prefer those for new workflows) | `puppeteer_navigate`, `puppeteer_click`, `puppeteer_screenshot` |
| **context7** | Up-to-date library documentation | `resolve-library-id`, `query-docs` |
| **Scholar Gateway** | Academic paper search | `semanticSearch` |
| **PDF Viewer** | Display and read PDFs | `display_pdf`, `read_pdf_bytes` |

---

## Plugins

| Plugin | What it provides |
|---|---|
| `superpowers` | Brainstorming, writing plans, TDD, debugging, dispatching agents, code review, verification |
| `feature-dev` | Guided feature development with codebase exploration and architecture agents |
| `code-review` | PR-style code review with confidence-based filtering. Local blocklist state can make it unavailable even when enabled in tracked config. |
| `code-simplifier` | Code simplification for clarity and maintainability |
| `frontend-design` | Production-grade frontend interface generation |
| `figma` | Optional local plugin when you want the plugin variant instead of the already-configured `claude.ai Figma` connector |
| `github` | Optional local plugin for GitHub issue, PR, and repository workflows. Requires local GitHub auth when used. |
| `playwright` | Optional local browser automation plugin when you want the plugin MCP instead of the repo-local/browser tooling already available |
| `huggingface-skills` | HF model training, dataset management, Gradio apps |
| `context7` | Optional local library documentation lookup plugin |
| `pyright-lsp` | Python type checking |
| `typescript-lsp` | TypeScript language server |

---

## Hooks System

The 8 locally-maintained hook scripts live in `.claude/hooks/`. The 2 PreToolUse hooks below are provided by the bundled gstack workflow under `.claude/skills/gstack/`, but this repo now keeps their activation state under `.claude/runtime/gstack/`.

| Hook | When | What it does |
|---|---|---|
| **PreToolUse** | Before Bash | `check-careful.sh` (gstack): Warns before destructive commands when `.claude/runtime/gstack/careful-mode.txt` is active |
| **PreToolUse** | Before Edit/MultiEdit/Write | `check-freeze.sh` (gstack): Blocks edits outside the repo-local freeze boundary in `.claude/runtime/gstack/freeze-dir.txt` |
| **UserPromptSubmit** | On prompt | `task-orchestrator-hook.sh`: Detects analysis vs coding, injects guidance |
| **UserPromptSubmit** | On prompt | `auto-codex-trigger.sh`: Auto-launches Codex in background for coding tasks |
| **UserPromptSubmit** | On prompt | `skill-activation-prompt.sh`: Suggests skills based on keyword matching |
| **PostToolUse** | After Edit/MultiEdit/Write | `post-tool-use-tracker.sh`: Tracks edited files for downstream hooks |
| **PostToolUse** | After Edit/MultiEdit/Write | `tsc-check.sh`: Runs TypeScript checks on modified files |
| **PostToolUse** | After Bash/Skill/MCP | `workflow-step-tracker.sh`: Marks workflow completion markers |
| **Stop** | Session end | `stop-build-check-enhanced.sh`: Re-runs TSC checks at session end |
| **Stop** | Session end | `workflow-completion-gate.sh`: Advisory reminders, cleans stale cache |

---

## Prompt Templates

Available at `.claude/prompt-templates/`:

These are repo-local starting points, not hard-gated control flows. They must stay aligned with this repo's no-commit, no-push, and minimal-change rules.

| Template | Purpose | Key placeholders |
|---|---|---|
| `feature-implementation.md` | Full multi-agent feature implementation with orchestration and API integration mode | `[TASK]`, `[DIRECTORY]`, `[API]`, `[AUTH_METHOD]` |
| `debug.md` | Root-cause debugging with safety scoping (/freeze, /investigate) | `[BUG]`, `[DIRECTORY]`, `[MODULE_DIR]` |
| `code-quality.md` | Code review, refactoring, and security audit (3 modes) | `[DIRECTORY]`, `[SCOPE]`, `[GOAL]`, `[MODE]` |
| `super-ralph.md` | Fully autonomous multi-agent implementation (brainstorm or oneshot) | `[TASK]`, `[DIRECTORY]`, `[CONSTRAINTS]` |
| `gstack-sprint.md` | Full Think-Plan-Build-Review-Test-Ship sprint | `[GOAL]`, `[CONSTRAINTS]`, `[TARGET_URL]` |
| `design-to-code.md` | Figma/design to production code pipeline | `[FIGMA_URL]`, `[DESIGN_DESCRIPTION]`, `[TARGET_STACK]` |

---

## Quick Reference Card

| Phase | Key Skills | Key Commands |
|---|---|---|
| **Think** | office-hours, plan-ceo-review | `/office-hours` |
| **Plan** | plan-eng-review, plan-design-review, design-consultation | `/multi-plan`, `/plan-eng-review`, `/plan-design-review` |
| **Build** | backend/frontend-dev-guidelines, docker/postgres-patterns | `/build-fix`, `/orchestrate` |
| **Review** | review, design-review, security-review, codex | `/review-staff`, `/codex review` |
| **Test** | tdd-workflow, e2e-testing, qa, verification-loop | `/qa`, `/quality-gate` |
| **Ship** | ship, document-release | `/ship` |
| **Reflect** | retro | `/retro` |
| **Safety** | careful, freeze, guard | `/careful`, `/freeze`, `/guard`, `/unfreeze` |
| **Debug** | systematic-debugging, investigate | `/investigate` |
| **Autonomous** | super-ralph (brainstorm/oneshot), autonomous-loops | `/super-ralph`, `/orchestrate` |
