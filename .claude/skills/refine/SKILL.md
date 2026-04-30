---
name: refine
description: Repo-local wrapper for the evaluator-optimizer refinement loop. Review, apply, verify, and re-critique in bounded rounds instead of making ad-hoc fixes.
---

# Refine

Use this wrapper when the task is "tighten up", "polish", or "iterate on" an existing target that is already close to done. The loop favors small verified passes over large rewrites.

## When to Invoke

- A change has landed but a reviewer flagged issues and you want a structured follow-up pass
- You have a PR or patch that is almost ready and need a converge-or-stop pass before shipping
- You have 2-3 specific issues to address and want each fix re-checked before the next one starts

Do not invoke for:

- Fresh feature work (use the planning skills first)
- Bug hunting without a named target (use `superpowers:systematic-debugging` instead)
- Global refactors (use `code-refactor` for bulk edits)

## Routing

The actual loop lives in the `/refine` slash command at `.claude/commands/refine.md`. This wrapper exists so the skill-activation hook surfaces the loop when the user's prompt matches refine-style intent, even if they did not type the slash command.

| Trigger shape | What happens |
|---------------|--------------|
| User types `/refine <target>` | The command file executes the bounded loop directly |
| Prompt matches refine keywords or intent patterns | This skill is surfaced as a suggestion, and the user can accept by invoking `/refine` |

## Loop Summary (inherited from the command)

1. Review the target against the repo conventions and the Senior Engineer rule
2. Decide: converged means exit; otherwise continue
3. Apply the minimal fix for each finding
4. Verify with the smallest useful check (type, lint, or unit test) before the next round
5. Bound at 3 rounds. Exit with a clear convergence or exhaustion status

## Repo Rules

- Do not commit or push at any round. The user owns commit and push.
- Do not widen scope mid-loop. Refine only what was named.
- No em dash or en dash in any written report from the loop. Use commas.
