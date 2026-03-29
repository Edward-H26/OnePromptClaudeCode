# Oneshot Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a prehook that lets users choose between oneshot (fully autonomous) and brainstorm (interactive) mode before Super Ralph begins.

**Architecture:** A new Phase -2 asks one question. A `MODE` variable gates every `AskUserQuestion` call in Phases -1 through 0. In oneshot mode, Ralph self-decides using query analysis and safe defaults.

**Tech Stack:** Markdown skill files, no code dependencies.

---

### Task 1: Add Phase -2 Mode Selection to SKILL.md

**Files:**
- Modify: `skills/super-ralph/SKILL.md:26-40` (Quick Reference section)
- Modify: `skills/super-ralph/SKILL.md:64-161` (before Phase -1 Brainstorm)

**Step 1: Update Quick Reference to show Mode Selection**

In `skills/super-ralph/SKILL.md`, find the Quick Reference block (lines 26-40). Replace:

```
User Query
  → Brainstorm: interactive Q&A to explore intent, scope, edge cases (AskUserQuestion loop)
```

With:

```
User Query
  → Mode Selection: oneshot (fully autonomous) or brainstorm (interactive) — single AskUserQuestion
  → IF brainstorm: interactive Q&A to explore intent, scope, edge cases (AskUserQuestion loop)
  → IF oneshot: auto-analyze query, infer intent/scope/constraints, write BRAINSTORM_SUMMARY silently
```

**Step 2: Add Phase -2 section before Phase -1**

Insert a new section between the "IMPORTANT: Fully Autonomous After Pre-Flight" block (ends line 62) and "Phase -1: Brainstorm" (starts line 64). The new section:

```markdown
## Phase -2: Mode Selection (BLOCKING — very first prehook)

The first and possibly only question Super Ralph asks. Determines whether the rest of the setup is interactive or autonomous.

### How it works

Ask one `AskUserQuestion`:

\```
question: "How should I approach this?"
header: "Mode"
options:
  - label: "Oneshot"
    description: "I'll handle everything autonomously — no questions, just deliver"
  - label: "Brainstorm"
    description: "Let's explore the idea together step by step"
  - label: "Chat about this"
    description: "Stop — I want to discuss this before deciding"
multiSelect: false
\```

Store the answer as `MODE`:
- **"Oneshot"** → `MODE = oneshot`
- **"Brainstorm"** → `MODE = brainstorm`

### What MODE controls

| MODE | Behavior |
|------|----------|
| `brainstorm` | All phases run interactively as documented below (existing behavior, unchanged) |
| `oneshot` | All phases still run, but every `AskUserQuestion` gate is replaced with autonomous self-decision. No further user interaction until final delivery. |

### Oneshot defaults

When `MODE = oneshot`, the orchestrator uses these defaults instead of asking:

| Phase | Default |
|-------|---------|
| Brainstorm | Analyze query, infer intent/scope/constraints, write BRAINSTORM_SUMMARY |
| Intent Profile | Default to middle tier: solid and correct + my team + weeks to months |
| Tooling | Auto-select recommended toolset based on BRAINSTORM_SUMMARY |
| Pre-Flight | Current directory writable, no read-only, nothing off-limits, MAX_RETRIES=6 |

---
```

**Step 3: Verify the new section renders correctly**

Run: `head -120 skills/super-ralph/SKILL.md`
Expected: Phase -2 appears between the autonomous note and Phase -1.

**Step 4: Commit**

```bash
git add skills/super-ralph/SKILL.md
git commit -m "feat: add Phase -2 Mode Selection to SKILL.md"
```

---

### Task 2: Add MODE conditionals to Phase -1 (Brainstorm)

**Files:**
- Modify: `skills/super-ralph/SKILL.md` — Phase -1 section (currently lines 64-161)

**Step 1: Add MODE gate at the start of Phase -1**

After the Phase -1 heading and its intro paragraph, insert:

```markdown
### MODE gate

- **If `MODE = brainstorm`:** run the interactive flow below as documented.
- **If `MODE = oneshot`:** skip all `AskUserQuestion` calls. Instead:
  1. Analyze the user's query to infer intent, scope, constraints, edge cases, and users.
  2. Write the `BRAINSTORM_SUMMARY` autonomously based on your analysis.
  3. Do NOT show the summary or ask for confirmation — proceed directly to Phase -0.75.
  4. If the query is ambiguous, make reasonable assumptions and document them in the summary's "Key Decisions" section.
```

**Step 2: Commit**

```bash
git add skills/super-ralph/SKILL.md
git commit -m "feat: add MODE gate to Phase -1 Brainstorm"
```

---

### Task 3: Add MODE conditionals to Phase -0.75 (Intent Profile)

**Files:**
- Modify: `skills/super-ralph/SKILL.md` — Phase -0.75 section (currently lines 164-278)

**Step 1: Add MODE gate at the start of Phase -0.75**

After the Phase -0.75 heading and its intro paragraph, insert:

```markdown
### MODE gate

- **If `MODE = brainstorm`:** ask the 3 questions below interactively.
- **If `MODE = oneshot`:** skip all `AskUserQuestion` calls. Instead:
  1. Infer priority, audience, and lifespan from the query and BRAINSTORM_SUMMARY.
  2. When ambiguous, default to the middle tier: **solid and correct + my team + weeks to months**.
  3. Build the `INTENT_PROFILE` and `JUDGE_RUBRIC` from the inferred values.
  4. Proceed directly to Phase -0.5.
```

**Step 2: Commit**

```bash
git add skills/super-ralph/SKILL.md
git commit -m "feat: add MODE gate to Phase -0.75 Intent Profile"
```

---

### Task 4: Add MODE conditionals to Phase -0.5 (Tooling Discovery)

**Files:**
- Modify: `skills/super-ralph/SKILL.md` — Phase -0.5 section (currently lines 280-409)

**Step 1: Add MODE gate at the start of Phase -0.5**

After the Phase -0.5 heading and its intro paragraph, insert:

```markdown
### MODE gate

- **If `MODE = brainstorm`:** scan and present recommendations interactively as documented below.
- **If `MODE = oneshot`:** skip all `AskUserQuestion` calls. Instead:
  1. Run the scan (Step 1) as normal.
  2. Run the matching (Step 2) as normal.
  3. Auto-select the recommended toolset — equivalent to the user picking "Recommended set" and then "Looks good — proceed."
  4. Build `TOOLING_CONFIG` and proceed directly to Phase 0.
```

**Step 2: Commit**

```bash
git add skills/super-ralph/SKILL.md
git commit -m "feat: add MODE gate to Phase -0.5 Tooling Discovery"
```

---

### Task 5: Add MODE conditionals to Phase 0 (Pre-Flight Scoping)

**Files:**
- Modify: `skills/super-ralph/SKILL.md` — Phase 0 section (currently lines 412-487)

**Step 1: Add MODE gate at the start of Phase 0**

After the Phase 0 heading and its intro paragraph, insert:

```markdown
### MODE gate

- **If `MODE = brainstorm`:** ask the 4 questions below interactively.
- **If `MODE = oneshot`:** skip all `AskUserQuestion` calls. Use these defaults:
  1. **Writable directories:** Current directory and subdirectories.
  2. **Read-only context:** None — figure it out.
  3. **Off-limits:** Nothing off-limits.
  4. **MAX_RETRIES:** 6 (3 normal + debug + 3 more).
  5. Build `WORKSPACE_RULES` from these defaults and proceed directly to Phase 1.
```

**Step 2: Commit**

```bash
git add skills/super-ralph/SKILL.md
git commit -m "feat: add MODE gate to Phase 0 Pre-Flight Scoping"
```

---

### Task 6: Update commands/super-ralph.md

**Files:**
- Modify: `commands/super-ralph.md`

**Step 1: Add oneshot to the workflow description**

In `commands/super-ralph.md`, replace:

```markdown
1. Brainstorm (interactive Q&A to explore intent, scope, and edge cases with the user)
```

With:

```markdown
1. Mode Selection (oneshot or brainstorm — single question)
2. Brainstorm (if brainstorm mode: interactive Q&A; if oneshot: auto-analyzed)
```

And renumber the subsequent items.

**Step 2: Commit**

```bash
git add commands/super-ralph.md
git commit -m "docs: add oneshot mode to super-ralph command description"
```

---

### Task 7: Update README.md

**Files:**
- Modify: `README.md`

**Step 1: Add Oneshot Mode section after Brainstorming**

After the "Brainstorming" section (ends around line 84) and before "Intent-Driven Judging" (starts line 88), insert:

```markdown
## Oneshot Mode

For users who know what they want and trust Ralph's judgment, oneshot mode skips all interactive setup. Ralph asks one question — "Oneshot or Brainstorm?" — then handles everything autonomously:

- **Analyzes your query** to infer intent, scope, and constraints (no Q&A)
- **Defaults to balanced settings** — solid quality, team audience, weeks-to-months lifespan
- **Auto-selects tools** from available skills and agents
- **Scopes workspace** to current directory with 6 retries
- **Delivers silently** — no narration until the final result

Use brainstorm mode when your request is ambiguous or you want to shape the approach. Use oneshot when it's clear-cut and you just want results.

---
```

**Step 2: Update "How It Works" diagram**

In the "How It Works" code block (lines 18-32), add mode selection as step 0:

```
Super Ralph:
  0. Mode     ── oneshot (fully autonomous) or brainstorm (interactive)?
  0.5 Brainstorm ── interactive Q&A to explore your intent, scope, and edge cases (brainstorm mode)
                    OR auto-analysis of query (oneshot mode)
```

**Step 3: Update Architecture diagram**

In "The Loop" block (lines 42-59), prepend:

```
  -> Mode Selection: oneshot or brainstorm (single question)
```

**Step 4: Update Design Principles**

In the Design Principles section (lines 396-408), update the "One-shot autonomy" bullet:

```markdown
- **Oneshot mode** -- a single prehook lets users skip all interactive setup. Ralph self-decides brainstorm answers, intent profile, tooling, and workspace scope using safe defaults and query analysis. Full pipeline still runs, just without human gates.
```

**Step 5: Commit**

```bash
git add README.md
git commit -m "docs: document oneshot mode in README"
```

---

### Task 8: Update memory.md with new state

**Files:**
- Modify: `memory.md`

**Step 1: Update current state**

Add to the current state section:

```markdown
- Oneshot mode: Phase -2 prehook asks oneshot vs brainstorm; oneshot auto-decides all setup phases
```

**Step 2: Commit**

```bash
git add memory.md
git commit -m "docs: update memory with oneshot mode"
```
