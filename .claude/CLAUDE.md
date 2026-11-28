# CLAUDE.md

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask, as the Questions rule below sorts it.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask, as the Questions rule below sorts it.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

Ponytail by default: once the problem is understood, stop at the first rung that holds. Does the code need to exist at all? Is it already in this codebase? Does the standard library or a native platform feature do it? Does an installed dependency solve it? Can it be one line? Only then write the minimum code that works. Never simplify away validation at a trust boundary, data-loss handling, security, accessibility or anything that was asked for.

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
- **Questions**: sort every open choice before acting on it. (a) A choice that is hard to undo, outward-facing or costly, or that changes results, scope or a done criterion, is the user's: the lead asks with AskUserQuestion in the same turn it comes up (an agent's question too, never parked at the end of a long reply), with two to four concrete options, the recommended one first and the advisor's view beside its own, and the part that depends on the answer waits. (b) Every other choice is the agent's: it consults the advisor first, then takes the recommended option, goes on, and records the choice, the reason and how to undo it in the delivery note and the rulings file, so the user can overturn it. (c) A teammate or subagent never asks the user. It consults the advisor first, then sends the question to the lead with its options, its default and the advisor's view; the lead consults the advisor too and decides the question itself when it falls under (b), and keeps working on what does not depend on the answer. A blanket approval such as "按照推荐的来" covers only the options presented at that time.
- **Advisor on every task**: every agent except `explorer` and `runner`, which never call it, consults the advisor when it is useful, not by count: at the start of a task before committing to an approach, whenever a choice is uncertain, a design is in doubt or an error repeats, and at the end before calling the work done. Routine steps go without it. Report what the advisor found, with its design beside your own, and act on it or say why not.
- **Model roles**: a role agent takes its model and effort from its file in `.claude/agents`; an effort passed on the Agent call overrides that file, so pass none or the same. Give every other Agent call its model and effort, since an agent does not inherit the session's level. Reading, searching and running commands: Haiku 5.5 at max (`explorer`, `runner`). Design notes, with no code: Fable 5.2 at xhigh (`designer`). Large code (several modules, or code that results depend on): Opus 5.5 at xhigh (`builder`, the other agents in `.claude/agents`, and any built-in or plugin agent). Small edits and small code from an exact spec: Sonnet 5.5 at max (`writer`). Verification of a delivery: Opus 5.5 at xhigh (`verifier`). Final verification, once per push on the exact tree that ships: Fable 5.2 at max (`checker`). Paper prose stays on Fable max. Hand-offs go through a context pack: before a `designer`, `builder` or `verifier` starts, an `explorer` writes what the task needs (paths, line ranges, short quotes, definitions, call sites, the tests that cover the code, open facts) to a .txt file the brief names, and the costlier agent reads that pack first, then reads whole only the code it changes (or, for a verifier, the diff and every changed file), and does not reread what the pack quotes. A cache is per model, so the saving is that the costly model reads a short pack instead of the code. Agents of one role get the same opening (rules, brief, pack) with what differs last, because only the same model with the same prefix shares a cached prompt. Spawn only the roles a task needs and do small tasks directly. A one-shot job (a context pack, a lookup, a single command run) is spawned without a name, so the agent ends when it returns; only an agent that will get follow-up messages (a builder, a verifier) gets a name. The lead stops every named agent with TaskStop once it is done: a builder and its verifier after PASS, any other agent as soon as its result is in. Consult the advisor as the rule "Advisor on every task" says.
- **Delivery**: before work starts, write what done means for it. Finished work is handed over with a delivery note: what was delivered and where, how each done criterion was verified (the commands, their output, and the hash of the tree or file they ran on, or "none"), what is not included, and open questions. The `verifier` checks it against the done criteria and answers PASS or FAIL with numbered fixes, each tagged important, nit or pre-existing. One verifier stays with a delivery through all its rounds. A later round reruns the checks on the new tree, names its hash, and rereads only what changed since the last round. Three FAIL rounds stop the delivery and go to the lead. Before a push the `checker` gives one verdict on the integrated tree, and a `runner` runs the full suite for it. Every agent keeps an append-only progress file that records each finding as it is made and ends in a current `Next:` line, so a usage limit, a crash or a compaction loses nothing and a successor continues from it. The lead saves every brief to a file, checks the progress files at each poll, and cuts a resume pack from the transcript of any agent whose file is missing or stale. After PASS the work is frozen, and a later change is a new task with its own done criteria. One delivery, one builder: after PASS the builder and the verifier are closed, and the next task goes to a fresh agent that reads the delivery note and the board file, because a long-lived agent is compacted again and again and every compaction drops detail.
- **Rulings file**: when several agents share work, every decision of the user or the lead goes, the moment it is made, as one line into the project's append-only rulings file (time, question, decision). A message reaches a busy agent only after its current turn, so every agent reads the new lines of that file before each step and right before it delivers. It notes the last line it read in its progress file (for example "rulings read to line 1895") and next reads only the lines after it. At its start it reads the file once and searches the whole file for the names of its own items. After a compaction drops the earlier lines from its context, it rereads once from the start it noted. The file is only appended to, never edited, so the new lines carry every new decision. The delivery note lists every question the work raised with the ruling line it applied, and the verifier fails work that applies an older decision.
- **Verification**: done is proven by running the change, not by reading it.
  - Run the change end to end on the path that ships (the app, the command, the driver, the exact file the user opens), through the project's `verify` skill where one exists. Prefer end-to-end tests, then property tests (invariants, round trips, idempotency, equivalence with a naive version), then differential tests (old against new on the same inputs, with a written list of approved differences). A passing unit test alone does not prove a feature.
  - Cheap checks run first: lint, types, the tests of the changed code, then the smoke run. The full suite and slow statistical tests run once on the integrated tree before a push, not after every change.
  - A check still failing after three fix rounds stops the work and goes to the user. A flaky test is never rerun until green, padded with sleeps or skipped: find its cause, or delete it and write down why.
  - A change never edits the check that judges it. The done criteria and the checks come from the base, and a change to a check is a task of its own. A verdict holds only for the tree or file it read, named by its hash, and any later edit voids it.
  - A bug that a check should have caught becomes a diff-triggered checklist item (its trigger, its check, the incident behind it) once it has happened twice. Items that stop firing are pruned.
- **Generalize, never hard-code**: code and its tests work for the next similar case, not only the one in front of you.
  - A value comes from its source (the data, the schema, the config, the declaration of the asset or dataset, the size of the container), not from a literal. A constant that has to exist is named once, in one place, with its source or its reason.
  - Layouts are responsive and proportional: relative units (`%`, `rem`, `fr`, `clamp()`, viewport units), flex and grid, and breakpoints set by the content. No fixed pixel sizes or absolute positions for content. Check the narrowest and the widest target width.
  - Code built on one dataset, asset or task runs on the next similar one through what that one declares. No name, count, path, column or threshold of one dataset appears in shared code. Prove it on a second dataset or a synthetic fixture.
  - Tests assert properties and relations (invariants, round trips, orderings, bounds derived from the input), not outputs copied from one run. A pinned expected value states where it comes from.
  - No special case for a test: never branch on a test name, a seed, a file or a known answer. A fix that makes one case pass and no other is not a fix.
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

Make the logical relation between sentences and between paragraphs explicit, mainly through substance. Add a connector only where the logic needs one.

- Paragraphs: each one links to what comes before and after it, has one clear point, and follows a clear logic. Its first sentence establishes its place in the argument (the topic sentence as signpost). The summary judgment comes first and the evidence follows. Paragraphs relate as a vector (contrast, specification, deepening, mechanism), not as a parallel list. Never write "one paragraph on A, one paragraph on B, Together, these". End a paragraph with an analytic statement, never with narration left hanging.
- Sentences: each one continues, turns or deepens the sentence before it. Never use "First, Second, Third" or similar rigid enumeration. Where a connector is needed, use ones such as "Furthermore", "Additionally", "Moreover" and "In addition". Every "this", "these" and "it" has an antecedent that is clear at once. The chain of reasoning skips no step. Cohesion comes from logic, not from repeated keywords.

**3. Tone and register**

- No boosters: really, very, hugely, remarkably, strikingly, notably.
- No hedging as politeness: I think, I feel, in my opinion, to be honest.
- No stakes-raising adverbs: Unsurprisingly, Interestingly, Indeed, Of course, Naturally.
- No exclamation marks, no rhetorical questions, no suspense constructions.
- No editorializing: a results passage does not evaluate the data. The numbers speak.
- The writing favors our work and is compelling, within what the evidence supports.
- Present tense for findings, past tense for events.
- Watch for nominalization: "this analysis examines", not "the examination of this analysis".

**4. Hard bans on words and constructions**

- The semicolon and the colon, as far as possible. Wherever a period can break the sentence, use a period. The em dash and the en dash are banned everywhere by the Prose style rule.
- Bullet points.
- "namely" and "arm".
- "Together", anywhere.
- "genuinely", "honestly", "straightforward" and words of that kind.
- Filler adverbs: "crucially", "importantly", "indeed".

---

## Additional Guidance

- Skills: before starting a task, search the installed skills (the skill list of the session and ~/.claude/skills) for the ones that fit it, use them, and name the skills used in the reply.
- Testing and verification: `testing-verification` skill
- UI-heavy and website work: `website-workflow` skill
