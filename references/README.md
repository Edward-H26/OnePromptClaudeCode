# References

This directory holds vendored upstream workflow repositories whose content is tracked in git. Repo-local wrapper skills and a smaller set of vendored passthrough skill entries may consult these snapshots as background material, so this content remains part of the published workflow surface and required on a fresh clone.

## Repositories

| Repository | Source | Purpose |
|---|---|---|
| **gstack** (`garrytan/gstack`) | Workflow skill framework with browse, review, ship, QA, and other development skills | Provides gstack-backed skills |
| **super-ralph** (`ashcastelinocs124/super-ralph`) | Autonomous multi-agent execution bundle | Provides Super Ralph agents and workflow |
| **codex** (`oil-oil/codex`) | Codex CLI skill for delegating coding tasks and cross-model review | Provides the codex skill (ask_codex.sh, review/challenge/consult modes) |
| **everything-claude-code** (`affaan-m/everything-claude-code`) | Community reference material for Claude Code patterns and configuration | Provides reference skills (deep-research, e2e-testing, etc.) |

## Updating from Upstream

To refresh the vendored snapshots from upstream repositories:

```bash
bash references/setup.sh
```

This clones each repo to a temp directory, syncs the content (excluding `.git/`), and updates the tracked vendored files. After running, review the changes and commit them.

## Acknowledgments

OnePromptClaudeCode integrates and builds upon the work of the following projects and contributors:

| Project | Author | What it provides |
|---|---|---|
| [gstack](https://github.com/garrytan/gstack) | @garrytan | Think-Plan-Build-Review-Test-Ship-Reflect cycle, 15 specialist skills, 6 power tools |
| [Super Ralph](https://github.com/ashcastelinocs124/super-ralph) | @ashcastelinocs124 | Autonomous agentic loop with self-debugging agents (tester, judge, worker, debugger, merger) |
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | @affaan-m | Comprehensive reference collection of Claude Code patterns and community resources |
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
