---
description: Run autonomous ML research experiments using Karpathy's autoresearch framework
argument-hint: Research goal (e.g., "improve attention mechanism", "optimize learning rate schedule")
---

You are running an autonomous ML research session using the autoresearch framework.

## Research Goal
$ARGUMENTS

## Configuration

Present these parameters to the user and ask them to confirm or adjust before starting:

**Core:**
- **Goal**: $ARGUMENTS
- **Turns**: unlimited (0 = run until stopped). Set a number to limit.
- **Workspace**: `~/autoresearch`
- **Checkpointing**: local snapshots in `<workspace>/.autoresearch/`

**Strategy:**
- **Focus**: `all` (options: `architecture`, `optimizer`, `hyperparams`, `data`, `all`)
- **Risk**: `medium` (options: `conservative`, `medium`, `aggressive`)
- **Complexity tolerance**: `strict` (reject complex changes for tiny gains)
- **Min improvement**: `0.001` val_bpb

**Infrastructure:**
- **Device**: `auto`
- **Max VRAM**: none (no constraint)
- **Dataset**: default (climbmix-400b-shuffle)

**Reporting:**
- **Verbosity**: `normal`
- **Report every**: 5 turns
- **Save report**: yes (to `<workspace>/report.md`)

Ask the user: "Confirm these settings or tell me what to change. Once confirmed, I will begin the autonomous research loop."

## After User Confirms

1. **Setup**: Check if workspace exists. If not, run:
   ```
   bash "$CLAUDE_PROJECT_DIR/.claude/skills/autoresearch/scripts/setup.sh" --workspace <workspace>
   ```

2. **Baseline**: Run the unmodified train.py as baseline (first entry in results.tsv).

3. **Loop**: Follow the autoresearch skill loop protocol (see `$CLAUDE_PROJECT_DIR/.claude/skills/autoresearch/SKILL.md`):
   - Read state, form hypothesis, snapshot train.py, train, evaluate, keep/discard, log, report, repeat.

4. **Finish**: When turns are exhausted or user stops, write the final report to `<workspace>/report.md` and display the summary.

## Important

- Do NOT stop to ask permission during the loop. Continue autonomously.
- Do NOT modify prepare.py. Only train.py.
- One hypothesis per experiment. Isolate variables.
- Always create a local snapshot before running. Always restore the snapshot on discard.
- If a run crashes, attempt a trivial fix once. If it fails again, log as crash and move on.
