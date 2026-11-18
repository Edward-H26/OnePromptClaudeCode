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
- **Commit messages**: a commit message drafted for the user is two or three short sentences, each starting with a verb such as Add, Fix, Implement or Remove followed by what it acts on (`Add the final text of design v2. Remove the preliminary passages. Fix the model statements.`). The first sentence is the subject line. No explanatory prose, no "nothing else changes", no file lists, no hashes, no long descriptive subject. One commit per logical change.
- **Prose style**: no em dash and no en dash. Use commas or restructure the sentence.
- **Plan**: for work with more than two steps, write the whole plan before starting, so every upcoming step is visible: in the opening lines of the reply when one session does the work, and in a board file on disk when several agents share it. Write each step as what is done to what and what counts as finished (for example "D08c key 4-6: rerun reasoning trap, SAVeR and GLEAN, then compare with v3"). The task tools stay off, because their reminders print the whole shared task list into the context of every agent that shares it.
- **Say the plan first**: after each prompt that asks for work, before the first tool call, write one to three short lines on what you will do and what you will leave alone. In focus mode only the final message stays visible, so for work with more than two steps the final message lists each step with its state (done, in progress, not started).
- **Ask with AskUserQuestion**: when a decision is the user's (an ambiguous request, a choice between approaches, anything costly, destructive or outward-facing), ask with AskUserQuestion as soon as the question comes up, with two to four concrete options and the recommended one first. Do not guess, do not leave the question at the end of a long reply, and do not start the part that depends on the answer before it comes.
- **Model roles**: every agent that reads or writes files without coding runs on Haiku: `explorer` finds files and lines, `runner` runs tests and commands and reports, `writer` writes routine content from an exact spec. Every agent that codes runs on Opus 5.5 at xhigh: `builder`, the other agents in `.claude/agents`, and any built-in or plugin agent, which `CLAUDE_CODE_SUBAGENT_MODEL` defaults to Opus. Paper prose stays on Fable max. Every delivery goes to `checker` (Fable 5.2 at medium), and the main session accepts. On an Agent call that names no role, pass the model and the effort (Opus and xhigh for code, Haiku for reading and writing), because an agent on another model does not inherit the session's level. Spawn only the roles a task needs and do small tasks directly. Consult the advisor before committing to an approach on hard work, when an error repeats, and before calling work done, not on routine steps.
- **Delivery**: before work starts, write what done means for it. Finished work is handed over with a delivery note: what was delivered and where, how each done criterion was verified with the evidence, what is not included, and open questions. A different agent checks it against the done criteria and answers PASS or FAIL with numbered fixes. After PASS the work is delivered and frozen. A later change is a new task with its own done criteria, never a silent edit of delivered work. One delivery, one agent: after PASS the agent that did the work is closed, and the next task goes to a fresh agent that reads the delivery note and the board file. A long-lived agent grows its context until it is compacted again and again, and every compaction drops detail.
- **Show your work**: whenever you build, change or check something visual (a page, component, layout, animation, chart, diagram, generated image, slide or video), show it in the chat with the show-your-work tools before you report it: `show_image` for screenshots (several at once for options or screen widths, with `compare` set to the before shot for a fix) and `show_video` for anything that moves, scrolls or is clicked through, recorded with Playwright. Give each one a title, the changes and the checks. When a subagent or teammate made the files, the main session shows them. If the tools are not loaded (another terminal, or the plugin is off), say so once and give a one-line `open` command for the files instead.
- **Refactor discipline (senior-engineer standard)**: apply these to code you write or touch; stay surgical on unrelated code and propose larger refactors instead of rewriting them silently.
  - **Extract shared logic.** If a function, constant, or type is used in two or more places, or is general enough to reuse, lift it into a dedicated module or shared file (for example a `lib/`, `utils/`, or `shared/` file) and import it. Do not copy-paste logic across files.
  - **One responsibility per unit.** Keep each function focused on a single job. Split a function that spans many concerns or is hard to scan into smaller, well-named functions.
  - **Optimize for readability.** Names should reveal intent without a comment. If you had to pause to understand a block, rename or restructure it before reaching for a comment.
  - **Comment the why, not the what.** Add a short comment only on important or non-obvious logic (a tricky algorithm, a workaround, an invariant, a security or ordering constraint). Do not narrate self-explanatory code, and avoid inline comments unless they prevent a real misread.
  - **Leave it cleaner.** Delete the orphans your change creates (unused imports, variables, functions), and match the surrounding file's style even if you would do it differently.

---

# Academic Writing

These rules govern every piece of academic prose in every project on this machine: papers, proposals, reports, abstracts, rebuttals, and documents written for mentors or reviewers. Chat replies, code and commit messages keep the rules above. Apply the rules while drafting, then check the finished text against each of them before handing it over.

**Terms and style**

- Use only terms that are established at top venues or in the field. Never coin a word or a phrase. When a term might be coined, find it in published papers or replace it with the standard term.
- American spelling and grammar throughout.
- Write in the style and vocabulary of top-venue papers. The text must read fluently and flow well.

**1. Information density**

- Every sentence carries weight by doing one of three things: it advances the argument, introduces evidence, or specifies a mechanism. Delete a sentence that does none of the three.
- No throat-clearing: "It is important to note that", "It should be mentioned that", "Worth highlighting is".
- No mechanical signposts: "This raises the question of", "In what follows", "Having established X, we now turn to Y", "This section discusses".
- Never open a paragraph by recapping the conclusion of the previous one.
- No empty endings such as "this contributes to our understanding of". State what is contributed.
- No circling: a paragraph never restates what it has just said. This holds for every paragraph.

**2. Logical cohesion**

Make the logical relation between sentences and between paragraphs explicit, through substance and not through connectors.

- Paragraphs: each one links to what comes before and after it, has one clear point, and follows a clear logic. Its first sentence establishes its place in the argument (the topic sentence as signpost). The summary judgment comes first and the evidence follows. Paragraphs relate as a vector (contrast, specification, deepening, mechanism), not as a parallel list. Never write "one paragraph on A, one paragraph on B, Together, these". End a paragraph with an analytic statement, never with narration left hanging.
- Sentences: each one continues, turns or deepens the sentence before it. Never use "First, Second, Third" or similar rigid enumeration. Use "Furthermore", "Additionally", "Moreover" and "In addition". Every "this", "these" and "it" has an antecedent that is clear at once. The chain of reasoning skips no step. Cohesion comes from logic, not from repeated keywords.

**3. Tone and register**

- American spelling and grammar only.
- No boosters: really, very, hugely, remarkably, strikingly, notably.
- No hedging as politeness: I think, I feel, in my opinion, to be honest.
- No stakes-raising adverbs: Unsurprisingly, Interestingly, Indeed, Of course, Naturally.
- No exclamation marks, no rhetorical questions, no suspense constructions.
- No editorializing: a results passage does not evaluate the data. The numbers speak.
- The writing favors our work and is compelling, within what the evidence supports.
- Present tense for findings, past tense for events.
- Watch for nominalization: "this analysis examines", not "the examination of this analysis".

**4. Hard bans on words and constructions**

- The em dash, the semicolon and the colon. Wherever a period can break the sentence, use a period.
- Bullet points.
- "namely" and "arm".
- "Together", anywhere.
- "genuinely", "honestly", "straightforward" and words of that kind.
- Filler adverbs: "crucially", "importantly", "indeed".

---

## Additional Guidance

- Testing and verification: `testing-verification` skill
- UI-heavy and website work: `website-workflow` skill
