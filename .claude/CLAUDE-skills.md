> **Parent**: [CLAUDE.md](./CLAUDE.md) | **Related**: [testing-verification](./skills/testing-verification/SKILL.md), [website-workflow](./skills/website-workflow/SKILL.md), [WORKFLOW-REFERENCE.md](./WORKFLOW-REFERENCE.md)

# Harness Overview (CLAUDE-skills.md)

This file is the map of this Claude Code harness: every skill, command, MCP server, hook and plugin, each explained in plain words with when to use it, and where they overlap or conflict.

Counts: **95 skills · 72 commands · 15 agents · 4 hooks · 2 MCP servers (shipped with the repo) · 15 plugins (12 on)**.
Check: `python3 -c "import json; print(len(json.load(open('.claude/skills/skill-rules.json'))['skills']))"`

Status: every skill is on demand. `task-orchestrator-hook.sh` lists a skill only when the prompt hits its keywords or intent patterns in `skills/skill-rules.json`, and each one can also be started by hand with its `/command`. No skill is marked `alwaysActive` at the moment.

---

## 1. Skills

### Design (11)
Useful whenever UI is written. They overlap; see "Overlaps and conflicts" below.

- **frontend-design**: gives a new interface a distinctive visual direction, typography and taste, without the template look. Use when starting a new page or component and setting its tone.
- **impeccable**: designs, redesigns, reviews and polishes whole interfaces (sites, dashboards, forms, design systems). Use when an interface needs to be raised in quality overall.
- **ui-ux-pro-max**: a large UI/UX knowledge base (dozens of styles, hundreds of palettes, font pairings, UX rules). Use when looking for style, color or font ideas.
- **design-taste-frontend**: front-end work for landing pages, portfolios and redesigns that removes the "AI look" and picks a direction on its own. Use for landing pages and portfolios.
- **high-end-visual-design**: builds sites the way a high-end design studio would and blocks cheap defaults. Use when the result should feel premium and commercial.
- **redesign-existing-projects**: upgrades an existing site or app to high-end quality, finding and replacing generic patterns. Use when refreshing an old site.
- **minimalist-ui**: minimal editorial style (warm monochrome, flat bento, no gradients or heavy shadows). Use when a minimal style is wanted.
- **gpt-taste**: advanced UX/UI with GSAP motion (AIDA structure, scroll animation). Use for strong motion and scroll storytelling.
- **shadcn-ui**: shadcn/ui component patterns (install, forms with Zod, theming, accessible components). Use when building with shadcn.
- **web-accessibility**: accessibility to WCAG (ARIA, keyboard navigation, screen readers). Use when a page has to meet accessibility standards.
- **web-design-guidelines**: reviews UI code against web interface guidelines. Use for a guideline review once the UI is written.

### Academic writing (3)
Paper-quality skills, useful for every paper. For a whole paper, **start with `academic-pipeline`** (research, writing and review in one flow).

- **academic-pipeline**: chains research, writing, review and revision into one 10-stage pipeline, and is **the main entry point for writing a paper**. Use to go from research to a finished draft in one flow.
- **research-paper-writing**: improves English ML/CV/NLP paper writing (structure, paragraphs, writing for reviewers). Use for English papers at top venues.
- **nature-polishing**: polishes Chinese or rough English into Nature-style English, and can fix LaTeX layout. Use to polish an English draft or fix LaTeX layout.

### Code discipline (1)
The "lazy senior engineer" rules that make the AI write only the code it needs, in the same spirit as Simplicity First in `CLAUDE.md`.

- **ponytail**: before writing code, climb the YAGNI ladder (reuse, then the standard library, then native features, then one line, then the minimal implementation), and never simplify away validation, security or accessibility. `/ponytail lite|full|ultra|off` sets the intensity. The prompt hook injects its ruleset once per session and again after each compaction; use `/ponytail ultra` to go further.

### Core (24)
The original development, research, review and tool skills, started by keywords or by `/command`.

**Development**
- **backend-dev-guidelines**: Node/Express/TypeScript back-end conventions. Use when writing back-end routes or services.
- **frontend-dev-guidelines**: React/TypeScript front-end patterns (Suspense, TanStack). Use when writing React components or data fetching.
- **ui-styling**: shadcn/ui and Tailwind component styling. Use when adjusting styles or layout.
- **code-refactor**: bulk renames, replacements and API-call changes. Use for large renames across files.

**Research, debugging and review**
- **deep-research**: a 13-agent deep research team (systematic reviews, meta-analysis, fact checks). Use when a rigorous multi-source research report is needed.
- **investigate**: systematic root-cause debugging (test hypotheses, stop after 3 failures). Use when tracking down a bug's root cause.
- **review**: senior-engineer code review (`/review-staff`) that finds production bugs CI missed. Use to review code before merging.
- **search-first**: search the existing code before writing. Use to learn the code before changing it.
- **refine**: an evaluate-and-optimize loop (generate, critique, revise, critique again, at most 3 rounds). Use when finished work should get one more round of polish, and only when the user asks for it.

**Planning and QA**
- **office-hours**: brainstorming and requirement clarification before coding (YC Office Hours style). Use when the need is not clear yet and the approach should be talked through first.
- **plan-design-review**: a senior designer scores the plan and flags AI clichés. Use to review a design plan.
- **plan-eng-review**: an engineering-manager style architecture review (data flow, edge cases, test matrix). Use to review an implementation plan.
- **design-review**: visual review, atomic fix commits and before/after screenshots. Use to check UI after changing it.
- **qa**: browser QA plus automatic regression tests. Use to test and fix a web page's behavior.
- **qa-only**: a QA report only, with no code changes. Use when only a test report is wanted.

**Tools and plugin wrappers**
- **chrome-devtools**: drives Chrome (screenshots, network, Lighthouse). Use for browser debugging, performance and screenshots.
- **webapp-testing**: tests a local web app with Python Playwright. Use for end-to-end tests of a local site.
- **playwright**: hands off to the Playwright plugin. Use for cross-browser automation.
- **figma**: hands off to the Figma plugin. Use to read or write Figma designs.
- **github**: hands off to the GitHub plugin. Use for repositories, PRs, issues and CI.
- **context7**: hands off to the context7 plugin. Use to look up a library's current documentation.
- **superpowers**: hands off to the Superpowers plugin (brainstorming, TDD, debugging, review). Use for a structured engineering process.
- **remotion**: makes videos in code with Remotion, a React video framework. Use for programmatic video.

### Academic (21)
A full research pipeline, triggered on demand. Note that several ways to write a whole paper sit side by side (see "Overlaps and conflicts").

- **academic-paper**: a 12-agent paper-writing pipeline with 11 modes. One of the main ways to write a whole English paper.
- **academic-paper-reviewer**: simulates 5 reviewers (an editor, 3 reviewers and a devil's advocate). Use to review your own paper before submission.
- **citation-check-skill**: checks whether citations are real, with vision and web lookup. Use to catch references the AI made up.
- **research-writing-skill**: Chinese-first writing, polishing and rebuttals. Use when writing a paper in Chinese.
- **nature-academic-search**: multi-source literature search and reference management (PubMed, CrossRef, arXiv). Use to find literature and manage references.
- **nature-citation**: adds Nature/CNS citations to a paragraph automatically. Use to fill in citations.
- **office-academic-skill**: a Chinese-first Word/PPT academic workflow (close-reading reports, group-meeting slides, DOCX/PPTX). Use for Chinese academic presentation material.
- **scientific-figure-making**: publication-quality figures with figures4papers. Use for a paper's data figures.
- **scientific-toolkit-skill**: a scientific computing toolbox (MATLAB/Octave, Python analysis, signal processing). Use for data analysis or scientific computing.
- **paper-spine**: the PaperSpine pipeline's main entry point, which writes a paper from scratch to LaTeX, PDF or Word. Use to write a paper the PaperSpine way.
- **paper-spine-*** (11: `-audit`, `-build`, `-citation`, `-humanize`, `-intake`, `-latex`, `-research`, `-rewrite`, `-translate`, `-ui`, `-update`): PaperSpine's internal steps. They follow the main entry point and are not used on their own.

### CCF conference research (17)
The CCFA family, vendored under MIT (see `skills/CCFA-SKILLS-LICENSE`), for papers aimed at CCF-ranked conferences. `ccf-pipeline-orchestrator` plans the stages and hands work to the others; `ccf-common` holds their shared rules.

- **ccf-common**: shared governance for the family: routing, task modes, handoffs, `ccfa.yaml` and artifact contracts.
- **ccf-pipeline-orchestrator**: plans and coordinates a paper project's stages, gates, artifacts and handoffs.
- **ccf-project-scaffolder**: creates the project folders, the LaTeX template and `ccfa.yaml`.
- **ccf-idea-optimizer**: turns a rough research direction into a concrete problem, gap, method and evidence plan.
- **ccf-idea-reviewer**: scores, ranks and triages early ideas against prior work and venue fit.
- **ccf-literature-searcher**: searches and screens related work, datasets, benchmarks and citation candidates.
- **ccf-literature-monitor**: watches arXiv, OpenReview and conference feeds for new work that overlaps an idea.
- **ccf-experiment-designer**: decides the datasets, baselines, metrics and ablations, and what each result table should show.
- **ccf-paper-writer**: drafts, rewrites, revises and polishes manuscript prose within the supplied scope and evidence.
- **ccf-paper-to-exemplar**: turns conference paper PDFs into writing exemplar cards for `ccf-paper-writer`.
- **ccf-humanization**: a preflight pass that makes publication prose read naturally, never the main task.
- **ccf-visual-composer**: renders and redesigns figures, visual tables and method diagrams.
- **ccf-integrity-auditor**: checks claim support, numeric and terminology consistency, and whether figures and text agree.
- **ccf-paper-reviewer**: assessment only: full reviews, scores, reviewer reports and readiness judgments.
- **ccf-rebuttal-writer**: rebuttals, author responses, response letters and resubmission plans.
- **ccf-submission-checker**: checks the venue's template, page, anonymity and camera-ready rules and the LaTeX/PDF build.
- **ccf-skill-forger**: designs, updates and audits CCFA skills and their documentation.

The `ccf-*` family and the other research skills above are listed to the model by name only (`skillOverrides` set to `name-only` in `settings.json`) to save tokens. They still start from the hook's suggestions or when named.

### Design, moved to on demand (4)
Design and diagram skills that used to be always on.

- **image-to-code**: image-first site building: generate a design image, analyze it, then rebuild it as a site (it depends on image generation, which may not fully run here). Use when a design image should become code.
- **industrial-brutalist-ui**: a raw industrial style (Swiss typography with terminal aesthetics). Use for that specific hard-edged style.
- **fireworks-tech-graph**: natural language to technical diagrams (architecture, flow, sequence), exported as SVG and PNG. Use to draw architecture or flow diagrams.
- **diagram-design**: technical and product diagrams as HTML and SVG that can pick up brand colors. Use for diagrams in a brand style.

### Code discipline commands (5)
Command-style members of the ponytail family, started with `/ponytail-*`.

- **ponytail-review**: reviews the current diff for over-engineering and returns a deletion list. Use after writing, to cut excess.
- **ponytail-audit**: reviews the **whole repository** for over-engineering, not just the diff, and ranks what can be deleted or simplified. Use to slim down a whole codebase.
- **ponytail-debt**: collects the simplification debts marked `ponytail:` in the code into a list. Use to take stock of deliberate shortcuts.
- **ponytail-gain**: shows ponytail's measured savings (less code, lower cost, faster). Use to see what it saved.
- **ponytail-help**: a quick reference for every ponytail mode and command. Use when you forget how it works.

### GSAP animation (8)
GreenSock's official animation skills, all on demand (triggered by keywords such as `gsap`, `scroll`, or `动画`, Chinese for "animation").

- **gsap-core**: the core API: `gsap.to`/`from`, easing, stagger, responsive and reduced-motion handling. The entry point for JavaScript web animation.
- **gsap-react**: GSAP in React and Next: `useGSAP`, refs, cleanup on unmount. Use for React animation.
- **gsap-frameworks**: GSAP in Vue, Svelte and Nuxt: lifecycles, scoping, cleanup. Use for Vue or Svelte animation.
- **gsap-scrolltrigger**: scroll-driven animation, pinning, scrub and parallax. Use for scroll animation.
- **gsap-plugins**: GSAP plugins (ScrollSmoother, Flip, Draggable, SplitText, SVG and more). Use when a specific plugin is needed.
- **gsap-timeline**: timeline sequencing: `gsap.timeline`, position parameters, nesting. Use to sequence animations.
- **gsap-utils**: the `gsap.utils` helpers: clamp, mapRange, random, snap, interpolate. Use for the utility functions.
- **gsap-performance**: animation performance: prefer transforms, avoid layout thrashing, keep 60fps. Use when an animation stutters.

---

## 2. Commands (72)

How it works: **typing `/name` calls the skill of the same name** (almost all are one to one). Four names differ:
- `/backend-dev` → backend-dev-guidelines
- `/frontend-dev` → frontend-dev-guidelines
- `/review-staff` → review
- `/build-fix` → fixes build and type errors incrementally

Every skill also has a `/command` of the same name for starting it by hand.

---

## 3. MCP servers

- **Shipped with the repo (they travel with it and are enabled):** `remotion-docs` (Remotion documentation) and `remotion-app` (works on a Remotion project).
- **Per machine (from the machine's own config, plugins or account, not in the repo):** context7, Playwright, Chrome DevTools and Figma come from their plugins; claude.ai connectors come with the account; any other server, such as Blender, is added on that machine with `claude mcp add`.

---

## 4. Hooks (4, wired in settings.json)

One hook per moment:

1. **session-start.sh** (SessionStart, when a session opens): bootstraps the local settings, injects the repo rules and restores the compaction snapshot.
2. **task-orchestrator-hook.sh** (UserPromptSubmit, when you send a message): decides the intent (analysis, coding or a plain question), lists the skills to use (from `skill-rules.json`), reminds Claude to clarify when the prompt is vague, suggests `/security-review` for auth-related prompts, and sends the standing guidance (the orchestrator block and the ponytail ruleset) once per session and again after each compaction rather than with every prompt. Removing the ponytail skill turns its ruleset off.
3. **post-edit-check.sh** (PostToolUse, after a file is edited): runs checks by file type (tsc for TS/JS, pyright and ruff for Python, the matching linter for others) and records the changed files.
4. **workflow-completion-gate.sh** (Stop, when an answer ends): reminds Claude to verify in a browser when front-end files changed, and clears caches older than 14 days.

> Two more helper scripts are gitignored but still in use: `git-guard.sh` (blocks commit and push; the audit smoke test depends on it) and `session-rules-reinject.sh` (re-injects the rules when restoring after a compaction). Do not delete them.

---

## 5. Plugins (15 in enabledPlugins, 12 on)

On: `pyright-lsp` and `typescript-lsp` (language servers and type checks), `frontend-design` (stronger UI implementation), `feature-dev` (code exploration and architecture agents), `code-review` (targeted review), `code-simplifier` (cleanup and simplification), `superpowers` (structured engineering workflows), `context7` (library documentation), `figma` (Figma designs), `playwright` (browser automation), `chrome-devtools-mcp` (Chrome debugging and performance) and `security-guidance` (security warnings plus an LLM review of each turn's diff, run on Sonnet through `SECURITY_REVIEW_MODEL`).

Off: `github`, `huggingface-skills` and `greptile`.

context7 and figma each need a one-time sign-in through `/mcp`.

---

## 6. Overlaps and conflicts (important)

When too many skills overlap, the AI picks the wrong one more easily. These groups matter most:

1. **Several ways to write a whole paper**: `paper-spine` (12 skills), `academic-paper`, `research-paper-writing`, and the `ccf-*` family for CCF conferences. **Start with `academic-pipeline`** (research, writing and review in one flow), and use the `ccf-*` family for CCF venues.
2. **Two overlapping diagram skills**: `fireworks-tech-graph` and `diagram-design` both draw architecture and schematic diagrams; both stay, the first for technical diagrams and the second for brand-styled ones. Research data figures all go through `scientific-figure-making`.
3. **Reviewing papers**: use `academic-paper-reviewer` (the topic moved to the academic family), or `ccf-paper-reviewer` for CCF venues.
4. **Academic slides**: use `office-academic-skill`.
5. **Deep research**: use `deep-research`.
6. **Five general design skills**: `frontend-design`, `impeccable`, `ui-ux-pro-max`, `design-taste-frontend` and `high-end-visual-design` all "make the UI look good" and overlap heavily. One of them is usually enough.
7. **Two shadcn skills**: `shadcn-ui` and `ui-styling` both cover shadcn and Tailwind.
8. **Style skills with clashing tastes**: `minimalist-ui` (minimal), `industrial-brutalist-ui` (brutalist) and `gpt-taste` (motion) are only for when that style has been chosen.
9. **Browser and QA overlap**: `chrome-devtools`, `playwright` and `webapp-testing` all drive a browser; `qa`, `qa-only`, `design-review` and `web-design-guidelines` all touch QA and review. Not conflicting, but redundant.
10. **Complementary, not conflicting (keep both)**: `nature-citation` (adds citations) and `citation-check-skill` (checks citations) do different jobs.

---

## 7. Maintenance and technical notes

- After changing the number of skills, commands, hooks or templates, update the counts in `README.md` (the audit checks them), then run `bash scripts/audit-workflow.sh` and `bash scripts/doctor-workflow.sh` and confirm both pass.
- Whether a skill is always listed or on demand is decided entirely by `alwaysActive` in `skills/skill-rules.json`. Changing that JSON changes the behavior, with no hook edits.
- **Source vs runtime**: tracked are `.claude/CLAUDE*.md`, `hooks/`, `commands/`, `prompt-templates/`, `agents/`, `skills/` and `settings.json`; gitignored are `plugins/`, `projects/`, `.claude/runtime/`, `.claude.json`, `settings.local.json`, `mods/` and `.claude/skills/synced/`. `skills/ui-styling/canvas-fonts/` is part of the design workflow and is tracked on purpose.
- **Plugins**: the shared `settings.json` enables the maintainer's plugin set, including ones that need a sign-in. On a machine that lacks one, turn it off in `.claude/settings.local.json`, whose values win over the shared config.
- **Personal rules**: preferences that should stay off the public repo, such as a reply language, go in `~/.claude/rules/` on that machine, which Claude Code loads in every project.
- **`effortLevel` semantics**: `max` in `settings.json` only applies to the current session unless `CLAUDE_CODE_EFFORT_LEVEL` is also set in `env`. Setting both ties the intent to persistence. See https://code.claude.com/docs/en/model-config#adjust-effort-level
- **Streaming and thinking**: Anthropic recommends batch processing for thinking budgets above 32K tokens. Claude Code streams interactively, so keep `MAX_THINKING_TOKENS` at 32000 or below to avoid a `Stream idle timeout` during long thinking. See https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
