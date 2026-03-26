# References

This directory holds setup scripts for external reference repositories used by the workflow. Vendored bundles in `.claude/skills/` are sourced from these clones.

## Repositories

| Repository | Source | Syncs to |
|---|---|---|
| **gstack** (`garrytan/gstack`) | Workflow skill framework with browse, review, ship, QA, and other development skills | `.claude/skills/gstack/` |
| **super-ralph** (`ashcastelinocs124/super-ralph`) | Autonomous multi-agent execution bundle | `.claude/skills/super-ralph/` |
| **everything-claude-code** (`affaan-m/everything-claude-code`) | Community reference material for Claude Code patterns and configuration | Local reference only (not synced) |

## Setup

Clone all reference repos and sync vendored bundles:

```bash
bash references/setup.sh
```

The cloned repos are gitignored and local to your machine. Run the script again to pull updates and re-sync.

## Updating

To pull latest changes and re-sync vendored bundles into `.claude/skills/`:

```bash
bash references/update-references.sh
```

This updates all reference clones, then rsyncs gstack and super-ralph into their respective `.claude/skills/` directories (excluding `.git/`).

## Acknowledgments

OnePromptClaudeCode integrates and builds upon the work of the following projects and contributors:

| Project | Author | What it provides |
|---|---|---|
| [gstack](https://github.com/garrytan/gstack) | @garrytan | Think-Plan-Build-Review-Test-Ship-Reflect cycle, 15 specialist skills, 6 power tools |
| [Super Ralph](https://github.com/ashcastelinocs124/super-ralph) | @ashcastelinocs124 | Autonomous agentic loop with self-debugging agents (tester, judge, worker, debugger, merger) |
| [everything-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | @hesreallyhim | Comprehensive reference collection of Claude Code patterns and community resources |
| Codex skill | @oiloil | Cross-model review using OpenAI's Codex CLI |
| autoresearch | Karpathy-inspired | Autonomous ML research loop for iterative experiment automation |
| Agentic Engineering / Eval Harness | Cognition's ECC | Eval-driven development and agent quality gate patterns |
| Continuous Claude | @AnandChowdhary | Continuous PR loop pattern for autonomous development cycles |
| Infinite Agentic Loop | @disler | Self-running agent pattern for hands-free iterative workflows |
| Ralphinho | @enitrat | RFC-driven DAG orchestration for multi-agent coordination |
| Official Plugins | Anthropic | Superpowers, feature-dev, code-review, code-simplifier, frontend-design, Figma, Playwright, GitHub, HuggingFace |
| shadcn/ui | shadcn | Component patterns and theming |
| Context7 | Context7 | Live library documentation lookup |

This workflow would not exist without these projects. What we built is the integration layer: the 400+ keyword trigger engine, the hook system, the safety guardrails, and the wiring that makes all of these work together as one.
