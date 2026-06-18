# CLAUDE.md

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

# Important:

- **Git**: never run `git commit`, `git push`, or `git reset --hard`, and never add `Co-Authored-By` trailers. The user is the sole author of every commit and push.
- **Prose style**: no em dash and no en dash. Use commas or restructure the sentence.
- **Refactor discipline (senior-engineer standard)**: apply these to code you write or touch; stay surgical on unrelated code and propose larger refactors instead of rewriting them silently.
  - **Extract shared logic.** If a function, constant, or type is used in two or more places, or is general enough to reuse, lift it into a dedicated module or shared file (for example a `lib/`, `utils/`, or `shared/` file) and import it. Do not copy-paste logic across files.
  - **One responsibility per unit.** Keep each function focused on a single job. Split a function that spans many concerns or is hard to scan into smaller, well-named functions.
  - **Optimize for readability.** Names should reveal intent without a comment. If you had to pause to understand a block, rename or restructure it before reaching for a comment.
  - **Comment the why, not the what.** Add a short comment only on important or non-obvious logic (a tricky algorithm, a workaround, an invariant, a security or ordering constraint). Do not narrate self-explanatory code, and avoid inline comments unless they prevent a real misread.
  - **Leave it cleaner.** Delete the orphans your change creates (unused imports, variables, functions), and match the surrounding file's style even if you would do it differently.

---

## Additional Guidance

- Testing and verification: @CLAUDE-testing.md
- UI-heavy and website work: @CLAUDE-website-workflow.md
