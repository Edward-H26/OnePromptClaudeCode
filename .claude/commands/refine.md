---
description: Evaluator-optimizer refinement loop (generate, critique, apply, re-critique)
argument-hint: "The target file, feature, or change description to refine"
---

Run a bounded evaluator-optimizer loop on the target described in `$ARGUMENTS`.

## Loop

Iterate up to 3 rounds. Each round:

1. **Review**: invoke `.claude/skills/review/SKILL.md` (or `/review-staff`) against the current state of the target. Record the findings with file path and line number for each issue.
2. **Decide**: if the reviewer returned no issues, exit the loop and report success. Otherwise continue.
3. **Apply**: fix every reviewer finding. Minimal, contained edits per the Senior Engineer rule. No speculative refactors.
4. **Verify**: re-run the smallest useful check that proves the fix did not regress anything (the matching type check, lint, or unit test — not a full build).

## Stop conditions

- Reviewer returns "no issues" for this round — emit `REFINE: converged after N rounds`.
- Three rounds elapsed — emit `REFINE: exhausted after 3 rounds` and list remaining issues.
- A fix breaks the verification step — stop, report the regression, and do not auto-revert.

## Anti-patterns to avoid

- Do NOT widen scope mid-loop. Refine only what `$ARGUMENTS` names.
- Do NOT commit or push at any round. The final reporter will summarize the diff.
- Do NOT reject reviewer findings without evidence. Technical rebuttal must cite a file or spec.

## Deliverable

At exit, report:
- Rounds used
- Issues resolved per round
- Remaining issues (if loop exhausted)
- Files touched across all rounds
