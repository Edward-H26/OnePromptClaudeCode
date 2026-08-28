# OnePromptClaudeCode

**One prompt is all you need.**

A complete Claude Code workflow that covers the entire software development lifecycle. Clone it, start coding, and never write a prompt from scratch again.

95 skill entries. 71 commands. 14 agents. 4 local hooks. 4 templates. 10 shared MCP servers. 600+ auto-triggers.

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

That gets the workflow running **inside this repo only**. Claude Code discovers
user-scope skills under `~/.claude/skills`, so until you link them, no skill here
loads in your other projects and the router never fires there. Two ways to go
global, depending on how much of `~/.claude` you want this repo to own:

```bash
bash scripts/install.sh --router       # keep your own ~/.claude/settings.json (recommended)
bash scripts/install.sh --apply        # let this repo own ~/.claude/{hooks,skills,settings.json}
bash scripts/install.sh --check        # preview what --apply would change
bash scripts/install.sh --revert       # undo --apply, restoring the most recent backup
```

`--router` links `~/.claude/skills` here and adds one `UserPromptSubmit` entry to
your existing `~/.claude/settings.json` pointing at this checkout. It is idempotent
and rewrites the path if you move the checkout. The absolute path lives only in
that machine-local file; tracked settings stay path-portable, which
`scripts/audit-workflow.sh` enforces.

`--apply` is the heavier option: it symlinks hooks, skills, and settings, backing
up existing real files to `~/.claude/.backup-<timestamp>/` first.

That is the repo setup. `bash scripts/doctor-workflow.sh` auto-creates or merges `.claude/settings.local.json` from the tracked `.claude/settings.local.example.json`, so a fresh clone does not require a manual local-settings copy step. Shared Remotion MCP servers now live in the tracked [`.mcp.json`](.mcp.json), which keeps project-scoped tool wiring out of machine-local settings. The tracked baseline still enables only the repo-stable plugin set; auth-sensitive, duplicate, or machine-fragile integrations such as GitHub, context7, Figma plugin MCP, Playwright plugin MCP, and `superpowers` stay disabled in the example until the local machine is actually configured for them. Run `bash scripts/doctor-workflow.sh` on a fresh clone to confirm the live workflow is ready, and clear any stale local plugin blocklist test entries if the doctor warns about them. After workflow changes, run `bash scripts/audit-workflow.sh`.

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
| **Agents** | 14 | Specialized local agents for complex tasks |
| **Hooks** | 4 | Automated skill activation, type/lint checks, and workflow hooks (all local) |
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
| `ponytail` | always active (`/ponytail lite/full/ultra/off`) | Lazy senior-dev mode: minimal solution via the YAGNI ladder, never cutting validation, security, or accessibility |

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
| `task-orchestrator-hook.sh` | On prompt | Detects analysis vs coding tasks, injects guidance, runs the skill-activation engine, and flags vague prompts for clarification |
| `post-edit-check.sh` | After Edit/MultiEdit/Write | Runs TypeScript checks on affected repos, the native linter (ruff/eslint/biome/shellcheck) on edited files, a Python check (pyright or ruff) on edited `.py` files, and records the edit log |
| `workflow-completion-gate.sh` | Session stop | Reminds to verify frontend changes in the browser, and cleans stale cache |
| `session-start.sh` | Session start | Validates required local tools, bootstraps local settings, and injects baseline repo context |

### Skill routing lanes

`.claude/skills/skill-rules.json` has a top-level `lanes` block that keeps the
research and frontend skill families from firing on each other's prompts. Each
lane scores itself against the prompt; the lane that outscores the others owns
it, and skills tagged with a different `lane` are dropped. A tie means no lane
wins and every match stays visible, so a bad guess can only hide a skill, never
surface an irrelevant one. Skills with no `lane` (`qa`, `review`, `ponytail`,
`investigate`, `testing-verification`) always survive.

Ranking within a match is separate from lanes. A skill marked `"alternate": true`
is a second choice for a job another installed skill owns, so it drops one tier
whenever that owner also matched, and keeps its own rank when it is the only
thing that matched. That is what turns a flat list into a lead plus a bench:

| Prompt | Leads | Bench |
|---|---|---|
| 帮我写 NeurIPS 的 rebuttal | `ccf-rebuttal-writer` | `academic-paper-reviewer` |
| 帮我做一个落地页，要好看有质感 | `ui-styling`, `impeccable` | `gpt-taste`, `minimalist-ui`, `high-end-visual-design`, … |
| 帮我画一个系统架构图 | `diagram-design` | `fireworks-tech-graph` |
| 用浏览器打开页面截个图 | `qa` | `chrome-devtools` |
| nature 期刊润色和引用检查 | `nature-polishing`, `nature-citation` | none, so no demotion |

**Three tiers, cheapest first.** Each only runs when the one above it found
nothing, so the expensive tier never taxes a prompt the cheap ones can place:

| Tier | What it is | Cost |
|---|---|---|
| 1. Keywords | the `skill-rules.json` table | ~120 ms |
| 2. Session memory | what this session last matched | ~110 ms |
| 3. Reasoning pass | a model reads the prompt and names skills | ~4.5 s |

**Tier 2, follow-ups.** A prompt like "把按钮改成蓝色", "再改改", or "继续" names
no skill, and no keyword list can fix that, so the hook remembers what each
session last matched under `.claude/runtime/skill-context/<session-id>` and
re-surfaces it, labelled as carried, when the current prompt matches nothing on
its own. A direct match always wins over a carried one, a matching prompt
overwrites the memory, sessions never share it, and a session with no history
recommends nothing rather than guessing. Entries expire after a day.

**Tier 3, the reasoning pass** (`hooks/lib/llm-skill-router.sh`). For a prompt
whose domain words are not in the table and whose session has no context, a
nested `claude -p` reads it and names the skills, and its one-line paraphrase is
surfaced as `READ AS:` to orient the work. It is gated hard: prompts under 10
characters and plain questions never reach it, and `CLAUDE_SKILL_ROUTER_LLM=0`
turns it off. Only skill names that exist in `skill-rules.json` survive; the
free-text paraphrase is labelled as a paraphrase rather than an instruction,
because it is derived from prompt text and can echo whatever the prompt carried.
Three details are load-bearing and each was found by a failing run: the
classifier runs with `disableAllHooks` so it cannot re-enter this hook, its
reasoning env is pinned (inheriting the session's xhigh effort and 128k thinking
budget stretched the same call from 4 s to 30-55 s), and `CLAUDE_CONFIG_DIR` is
restored to the session's original value, since the repo's `.claude/` holds no
credentials and a nested CLI launched with it answers "Not logged in".

Change routing by editing `skill-rules.json`, not the hook. Adding a skill means
adding its rule, its `lane` if it belongs to one, and `alternate` if something
else already owns that job. Watch for over-broad triggers: a bare generic word
(`pipeline`, `nature`, `review`, `existing`) or a page noun like 首页 fires on
prompts that have nothing to do with the skill.

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
  runtime/               # Repo-local ignored runtime state for safety and workflow artifacts
  agents/                # 14 local agent definitions
  commands/              # 71 slash commands
  hooks/                 # 4 local hook scripts
  prompt-templates/      # 4 reusable templates
  skills/                # 95 skill entries
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
| autoresearch | Karpathy-inspired | Autonomous ML research loops |
| Agentic Engineering | Cognition's ECC | Eval-driven development patterns |
| Continuous Claude | @AnandChowdhary | Continuous PR loop pattern |
| Infinite Agentic Loop | @disler | Self-running agent pattern |
| Ralphinho | @enitrat | RFC-driven DAG orchestration |
| Official Plugins | Anthropic | Superpowers, feature-dev, code-review, Figma, Playwright, GitHub, HuggingFace |
| shadcn/ui | shadcn | Component patterns |
| Context7 | Context7 | Library documentation |
| [CCFA-Skills](https://github.com/mikubaka88/CCFA-Skills) | @mikubaka88 | The 17 `ccf-*` skills for CCF conference research, vendored under MIT (see `.claude/skills/CCFA-SKILLS-LICENSE`) |

---

## License

MIT
