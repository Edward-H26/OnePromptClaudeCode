# Complete Workflow Reference

> Single source of truth for all skills, commands, agents, MCP servers, plugins, hooks, and prompt templates.

## Workflow Overview

This workflow follows a structured sprint cycle: **Think, Plan, Build, Review, Test, Ship, Reflect**. Each phase has dedicated skills that feed into the next. Skills are activated automatically via keyword triggers or manually via slash commands.

**Global config**: On some local setups, a user-scoped Claude home directory may be symlinked to this project directory. This is a machine-specific convention, not a requirement of the published repo.
**Repo-local multi-model flow**: `/multi-plan` and `/multi-execute` use the bundled Codex bridge plus installed plugin agents. The Codex bridge now writes repo-local runtime state under `.claude/runtime/codex/`.
**Published surface**: This repo tracks the workflow content it runs. All shipped skills live as local SKILL.md directories under `.claude/skills/`; no vendored upstream sources are required.
**Live readiness**: Use `bash scripts/doctor-workflow.sh` for plugin, MCP, and Codex runtime checks. Use `bash scripts/audit-workflow.sh` for static repo-surface validation.
**Plugin split**: The tracked shared config enables only the repo-stable baseline. Auth-sensitive, duplicate, or machine-fragile integrations such as GitHub, context7, plugin-provided Figma/Playwright MCP servers, `superpowers`, and `huggingface-skills` belong in `.claude/settings.local.json`. Use `.claude/settings.local.example.json` as the tracked starting point for those local overrides; it lists the optional plugins but leaves them disabled until a local machine explicitly enables them. Project-scoped shared MCP servers belong in the tracked [`.mcp.json`](/Users/edwardhu/Desktop/agent/claude/.mcp.json). `bash scripts/doctor-workflow.sh` now auto-creates or merges `.claude/settings.local.json` from that tracked example on first run. If doctor warns about enabled plugins that are also blocklisted in ignored local state, clear the stale local blocklist entry before relying on that plugin.

---

## Skills Reference

### Planning Skills

| Skill | Trigger | What it does |
|---|---|---|
| `office-hours` | `/office-hours` | Pre-development brainstorming. YC Office Hours forcing questions before code. Produces a design doc, never code. |
| `plan-eng-review` | `/plan-eng-review` or ask for "eng review" | Architecture review with diagrams, data flow, edge cases, test matrices. |
| `plan-design-review` | `/plan-design-review` or ask for "design review" | Design dimension evaluation rated 0-10. Detects AI slop. |

### Development Skills

| Skill | Trigger | What it does |
|---|---|---|
| `backend-dev-guidelines` | auto on backend code | Layered architecture, BaseController, services, repositories, middleware, testing. |
| `frontend-dev-guidelines` | auto on frontend code | React patterns, Suspense, TanStack Query/Router, file organization, TypeScript. |
| `search-first` | ask to "search first" | Explore existing code before writing new code. Codebase search methodology. |
| `code-refactor` | ask to refactor | Grep + Edit workflow for bulk refactoring with verification. |
| `ui-styling` | auto on UI/CSS work | shadcn/ui components, Tailwind CSS, canvas-based design, 40+ fonts. |

### Review Skills

| Skill | Trigger | What it does |
|---|---|---|
| `review` | `/review-staff` | Staff engineer code review with findings-first output for this repo. |
| `design-review` | `/design-review` or ask for "design review fix" | Design audit with repo-local fixes and before/after screenshots when available. |
| `refine` | `/refine` or ask to "refine the code" | Evaluator-optimizer loop: generate, critique, apply, re-critique. Bounded at 3 rounds. |
| `remotion` | `/remotion` or ask to "create a video" / "render a composition" | Active-mode skill for programmatic video with Remotion. Scaffolds via `create-video`, writes React compositions, renders MP4s without per-step confirmation. Optional media-mcp + mcp-app integrations. |

### Testing Skills

| Skill | Trigger | What it does |
|---|---|---|
| `webapp-testing` | ask to test a local webapp | Python-driven Playwright workflow for local app lifecycle, screenshots, and browser verification. |
| `qa` | ask about "browser QA" or "test the app" | Browser-based QA: test app, find bugs, apply minimal fixes, and re-verify. |
| `qa-only` | `/qa-only` | Same as qa but report-only, no code changes. |

### Debugging Skills

| Skill | Trigger | What it does |
|---|---|---|
| `investigate` | `/investigate` | Systematic debugging with hypothesis testing. Stops after 3 failed fixes. |

### Shipping Skills

| Skill | Trigger | What it does |
|---|---|---|

### Safety Skills

| Skill | Trigger | What it does |
|---|---|---|

### AI/Agent Skills

| Skill | Trigger | What it does |
|---|---|---|
| `codex` (oiloil) | `/codex` or auto-trigger | Delegate coding tasks to Codex CLI via bundled `ask_codex.sh`. Also provides cross-model review modes (review/challenge/consult) via direct `codex` CLI. |

### Research and Content Skills

| Skill | Trigger | What it does |
|---|---|---|
| `deep-research` | `/deep-research` or ask for "deep research" | Multi-source research workflow using WebFetch/WebSearch with synthesis rules. |
| `aiq-research` | ask about "AI-Q", "Nemotron research", "deep research blueprint" | NVIDIA AI-Q Blueprint delegation for enterprise multi-document research with citations. |
| `professional-research-writing` | always active | Writing style guide: participial phrases, sentence construction, paragraph structure. Dash prohibition. |

### Utility Skills

| Skill | Trigger | What it does |
|---|---|---|
| `chrome-devtools` | ask about Chrome DevTools | Node.js scripts for Chrome DevTools Protocol: navigate, screenshot, console, evaluate, network. |

---

## Commands Reference

| Command | Purpose | Usage |
|---|---|---|
| `/design-review` | UI review and fixes | `/design-review <scope>` |
| `/office-hours` | Pre-dev brainstorming | `/office-hours <idea description>` |
| `/qa-only` | Browser QA report only | `/qa-only <url or instructions>` |
| `/plan-eng-review` | Architecture plan review | `/plan-eng-review <plan or prompt>` |
| `/plan-design-review` | Design plan review | `/plan-design-review <plan or prompt>` |
| `/review-staff` | Staff engineer review | `/review-staff <focus area>` |
| `/refine` | Evaluator-optimizer refinement loop | `/refine <scope>` |
| `/remotion` | Scaffold / edit / render Remotion video | `/remotion <instruction>` |
| `/investigate` | Root-cause debugging | `/investigate <bug description>` |
| `/codex` | Coding delegation and cross-model review (oiloil) | `/codex review`, `/codex challenge`, `/codex <task>` |
| `/build-fix` | Fix build errors | `/build-fix` |

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
| `ralph-*` (5 sub-agents) | 

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
| **context7** | Up-to-date library documentation | `resolve-library-id`, `query-docs` |
| **Scholar Gateway** | Academic paper search | `semanticSearch` |
| **PDF Viewer** | Display and read PDFs | `display_pdf`, `read_pdf_bytes` |

---

## Plugins

| Plugin | What it provides |
|---|---|
| `superpowers` | Optional local plugin for brainstorming, writing plans, TDD, debugging, dispatching agents, code review, verification |
| `feature-dev` | Guided feature development with codebase exploration and architecture agents |
| `code-review` | PR-style code review with confidence-based filtering. Local blocklist state can make it unavailable even when enabled in tracked config. |
| `code-simplifier` | Code simplification for clarity and maintainability |
| `frontend-design` | Production-grade frontend interface generation |
| `figma` | Optional local plugin when you want the plugin variant instead of the already-configured `claude.ai Figma` connector |
| `github` | Optional local plugin for GitHub issue, PR, and repository workflows. Requires local GitHub auth when used. |
| `playwright` | Optional local browser automation plugin when you want the plugin MCP instead of the repo-local/browser tooling already available |
| `huggingface-skills` | Optional local plugin for HF model training, dataset management, and Gradio apps |
| `context7` | Optional local library documentation lookup plugin |
| `pyright-lsp` | Python type checking |
| `typescript-lsp` | TypeScript language server |

---

## Hooks System

The 10 locally-maintained tracked hook scripts live in `.claude/hooks/`. All hooks are repo-local. The `auto-codex-trigger.sh` script remains on disk but is intentionally un-wired (disabled) until the Codex CLI is authenticated; re-add it to the `UserPromptSubmit` block in `settings.json` to re-enable.

| Hook | When | What it does |
|---|---|---|
| **PreToolUse** | Before MCP tools | `check-mcp.sh`: Records every MCP invocation to hook-metrics.jsonl for audit trail |
| **UserPromptSubmit** | On prompt | `task-orchestrator-hook.sh`: Detects analysis vs coding, injects guidance |
| **UserPromptSubmit** | On prompt | `skill-activation-prompt.sh`: Suggests skills based on keyword matching |
| **PostToolUse** | After Edit/MultiEdit/Write | `post-tool-use-tracker.sh`: Tracks edited files for downstream hooks |
| **PostToolUse** | After Edit/MultiEdit/Write | `tsc-check.sh`: Runs TypeScript checks on modified files |
| **PostToolUse** | After Edit/MultiEdit/Write | `lint-check.sh`: Runs native linter (ruff/eslint/biome/shellcheck) on edited files |
| **Stop** | Session end | `stop-build-check-enhanced.sh`: Re-runs TSC checks at session end |
| **Stop** | Session end | `workflow-completion-gate.sh`: Advisory reminders, cleans stale cache |
| **SessionStart** | New session | `session-start.sh`: Validates required local tools, auto-bootstraps local settings, and re-injects baseline repo rules |

---

## Prompt Templates

Available at `.claude/prompt-templates/`:

These are repo-local starting points, not hard-gated control flows. They must stay aligned with this repo's no-commit, no-push, and minimal-change rules.

| Template | Purpose | Key placeholders |
|---|---|---|
| `feature-implementation.md` | Full multi-agent feature implementation with orchestration and API integration mode | `[TASK]`, `[DIRECTORY]`, `[API]`, `[AUTH_METHOD]` |
| `debug.md` | Root-cause debugging via `/investigate` and scoped repo edits | `[BUG]`, `[DIRECTORY]`, `[MODULE_DIR]` |
| `code-quality.md` | Code review, refactoring, and security audit (3 modes) | `[DIRECTORY]`, `[SCOPE]`, `[GOAL]`, `[MODE]` |
| `gstack-sprint.md` | Full Think-Plan-Build-Review-Test-Ship sprint | `[GOAL]`, `[CONSTRAINTS]`, `[TARGET_URL]` |
| `design-to-code.md` | Figma/design to production code pipeline | `[FIGMA_URL]`, `[DESIGN_DESCRIPTION]`, `[TARGET_STACK]` |

---

## Quick Reference Card

| Phase | Key Skills | Key Commands |
|---|---|---|
| **Think** | office-hours, plan-ceo-review | `/office-hours` |
| **Plan** | plan-eng-review, plan-design-review, design-consultation | `/multi-plan`, `/plan-eng-review`, `/plan-design-review` |
| **Build** | backend/frontend-dev-guidelines, code-refactor | `/build-fix`, `/orchestrate` |
| **Review** | review, design-review, codex | `/review-staff`, `/codex review` |
| **Test** | qa, qa-only, webapp-testing | `/qa`, `/qa-only` |
| **Ship** | ship, document-release | `/ship` |
| **Reflect** | retro | `/retro` |
| **Safety** | settings.json deny rules + git-guard hook | `Bash(git commit:*)` / `Bash(git push:*)` denies, plus `Bash(rm -rf:*)` deny |
| **Debug** | investigate | `/investigate` |
| **Autonomous** | autonomous-loops | `/orchestrate`, `/multi-execute` |
